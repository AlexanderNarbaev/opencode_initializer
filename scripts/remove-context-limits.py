#!/usr/bin/env python3
"""Remove every context limit and guard from the live OpenCode configuration.

Run from the repository root:

    python3 scripts/remove-context-limits.py --dry-run
    python3 scripts/remove-context-limits.py

Removes the context window cap, auto compaction and pruning, every context
budget key (compaction thresholds, min/max context limits, protected and
reserved tokens), and the context-guard / context-watch / cache-injector
plugins. The explicit permission deny-list is kept: that is safety policy,
not a context limit.
"""

import json
import os
import shutil
import sys
import time

HOME = os.environ.get("HOME", "")
CFG_DIR = os.path.join(HOME, ".config", "opencode")
DRY = "--dry-run" in sys.argv
STAMP = time.strftime("%Y%m%dT%H%M%S")

report = []


def backup(path):
    if DRY or not os.path.exists(path):
        return
    dest = path + ".bak-ctxunlimit-" + STAMP
    shutil.copy2(path, dest)
    report.append("backup: " + dest)


def strip_jsonc(text):
    keep = []
    for line in text.splitlines():
        if line.lstrip().startswith("//"):
            continue
        keep.append(line)
    return "\n".join(keep)


def read_jsonc(path):
    handle = open(path, "r", encoding="utf-8")
    try:
        return json.loads(strip_jsonc(handle.read()))
    finally:
        handle.close()


def write_jsonc(path, data):
    if DRY:
        return
    handle = open(path, "w", encoding="utf-8")
    try:
        json.dump(data, handle, indent=2, ensure_ascii=False)
        handle.write("\n")
    finally:
        handle.close()


GUARD_KEYS = (
    "context_guard",
    "contextThreshold",
    "context_threshold",
    "max_context",
    "maxContext",
    "context_budget",
    "contextBudget",
    "token_budget",
    "reserve_tokens",
    "protectTokens",
    "minContextLimit",
    "maxContextLimit",
    "min_context_limit",
    "max_context_limit",
    "max_context_length",
)


def scrub(node, trail):
    hit = []
    if isinstance(node, dict):
        for key in list(node.keys()):
            label = trail + "." + key if trail else key
            if key in GUARD_KEYS:
                hit.append(label)
                node.pop(key, None)
            else:
                hit += scrub(node[key], label)
    elif isinstance(node, list):
        index = 0
        for item in node:
            hit += scrub(item, trail + "[" + str(index) + "]")
            index += 1
    return hit


def drop_guard_plugins(cfg):
    plugins = cfg.get("plugin")
    if not isinstance(plugins, list):
        return []
    keep = []
    dropped = []
    for entry in plugins:
        name = entry[0] if isinstance(entry, (list, tuple)) else entry
        text = name if isinstance(name, str) else ""
        if ("context-guard" in text) or ("context-watch" in text) or ("cache-injector" in text):
            dropped.append(text)
        else:
            keep.append(entry)
    if dropped:
        cfg["plugin"] = keep
    return dropped


def main():
    main_cfg = os.path.join(CFG_DIR, "opencode.json")
    if os.path.exists(main_cfg):
        cfg = read_jsonc(main_cfg)
        backup(main_cfg)
        changed = []

        limit = cfg.get("limit")
        if isinstance(limit, dict) and "context" in limit:
            changed.append("limit.context removed (was " + str(limit["context"]) + ")")
            limit.pop("context", None)
            if not limit:
                cfg.pop("limit", None)

        comp = cfg.get("compaction")
        if isinstance(comp, dict):
            if comp.get("auto") is True:
                comp["auto"] = False
                changed.append("compaction.auto -> false")
            if "prune" in comp:
                comp["prune"] = False
                changed.append("compaction.prune -> false")

        hits = scrub(cfg, "")
        if hits:
            changed.append("guard keys removed: " + ", ".join(hits))

        dropped = drop_guard_plugins(cfg)
        if dropped:
            changed.append("plugins dropped: " + ", ".join(dropped))

        if changed:
            write_jsonc(main_cfg, cfg)
            report.append("opencode.json: " + "; ".join(changed))
        else:
            report.append("opencode.json: already unrestricted")

    sidecars = [
        os.path.join(CFG_DIR, "context-guard.json"),
        os.path.join(CFG_DIR, "opencode-swarm.json"),
        os.path.join(CFG_DIR, "model-router", "config.json"),
    ]
    for path in sidecars:
        if not os.path.exists(path):
            continue
        try:
            data = read_jsonc(path)
        except Exception as exc:
            report.append("skip " + path + " (" + str(exc) + ")")
            continue
        backup(path)
        touched = False
        for key in ("enabled", "active", "guard_enabled", "enforce"):
            if key in data:
                data[key] = False
                touched = True
        for key in ("max_context", "context_limit", "threshold", "budget"):
            if key in data:
                data.pop(key, None)
                touched = True
        if touched:
            write_jsonc(path, data)
            report.append(os.path.basename(path) + ": guards disabled")
        else:
            report.append(os.path.basename(path) + ": nothing to disable")

    for line in report:
        print(line)
    if not report:
        print("nothing found")
    print("DRY-RUN" if DRY else "APPLIED")


main()