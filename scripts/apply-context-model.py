#!/usr/bin/env python3
"""apply-context-model.py — unified context/model policy (2026-10-12)

Requirements:
  1. Context window = 1,000,000 tokens everywhere (model limit.description is the source
     of truth: cleanup thresholds are DERIVED from the model's declared context window).
  2. Cleanup/compaction kicks in at ~>=50% of the model window.
  3. Main agent + ALL subagents use ONE model; default = any free model (preference:
     mimo -> opencode-go -> opencode -> first available provider model).

Applies to: ~/.config/opencode/opencode.json (global) and repo opencode.json (project).
Idempotent; JSONC-aware (full-line // comments stripped on read, preserved style rewritten).
Backups: <file>.bak-<timestamp>.
"""
import json, re, sys, datetime, os

CTX = 1_000_000          # 1M tokens everywhere
CLEANUP_FRACTION = 0.5   # compaction at >= 50% of model window
PREFERENCE = ["mimo", "opencode-go", "opencode"]  # free-first preference order

TS = datetime.datetime.now().strftime("%Y%m%dT%H%M%S")
targets = [
    os.path.expanduser("~/.config/opencode/opencode.json"),
    "/home/alexandr-narbaev/Projects/opencode_initializer/opencode.json",
]


def load_jsonc(path):
    raw = open(path).read()
    return json.loads(re.sub(r"^\s*//.*$", "", raw, flags=re.M)), raw


def pick_model(d):
    provs = d.get("providers", d.get("provider", {}))
    # providers here carry settings/fallback only (models come from the catalog),
    # so use known free-tier model IDs, free-first preference order.
    known_free = {"mimo": "mimo-v2.6-pro", "opencode-go": "grok-code", "opencode": "auto"}
    for pref in PREFERENCE:
        if pref in provs and pref in known_free:
            return f"{pref}/{known_free[pref]}"
    for name in provs:
        if name in known_free:
            return f"{name}/{known_free[name]}"
    return None


def main():
    for path in targets:
        if not os.path.exists(path):
            print(f"SKIP (missing): {path}")
            continue
        d, raw = load_jsonc(path)
        os.rename(path, path + f".bak-{TS}") if False else None
        open(path + f".bak-{TS}", "w").write(raw)

        model = pick_model(d)
        if model is None:
            print(f"SKIP (no providers/models found): {path}")
            continue

        # 1. ONE model for everything: root default; agents inherit (remove per-agent model)
        d["model"] = model
        agents = d.get("agents", d.get("agent", {}))
        stripped = 0
        for name, a in agents.items():
            if isinstance(a, dict) and "model" in a:
                del a["model"]
                stripped += 1

        # 2. Model description is the source of truth: declare 1M context limit on the model
        prov, mod = model.split("/", 1)
        provs = d.get("providers", d.get("provider", {}))
        entry = provs.setdefault(prov, {}).setdefault("models", {}).setdefault(mod, {})
        lim = entry.setdefault("limit", {})
        lim["context"] = CTX

        # 3. Compaction/cleanup at >=50% of the model window
        comp = d.setdefault("compaction", {})
        comp["auto"] = True
        if "threshold" in comp or True:
            comp["threshold"] = int(CTX * CLEANUP_FRACTION)  # 500k
        comp.setdefault("reserved", 10_000)
        comp["context_window"] = CTX  # informational: derivable value

        # 4. DCP compress/prune options scaled to 1M (plugins tuple or {package,options})
        plugins = d.get("plugins", d.get("plugin", []))
        new_plugins = []
        for e in plugins:
            if isinstance(e, list) and len(e) == 2 and e[0] == "opencode-dcp":
                opts = e[1]
                c = opts.setdefault("compress", {})
                c["minContextLimit"] = int(CTX * CLEANUP_FRACTION)   # 500k
                c["maxContextLimit"] = CTX                           # 1M
                p = opts.setdefault("prune", {})
                p["minTokens"] = int(CTX * CLEANUP_FRACTION)         # 500k
                p["protectTokens"] = 100_000
                e = ["opencode-dcp", opts]
            elif isinstance(e, dict) and e.get("package") == "opencode-dcp":
                opts = e.setdefault("options", {})
                c = opts.setdefault("compress", {})
                c["minContextLimit"] = int(CTX * CLEANUP_FRACTION)
                c["maxContextLimit"] = CTX
                p = opts.setdefault("prune", {})
                p["minTokens"] = int(CTX * CLEANUP_FRACTION)
                p["protectTokens"] = 100_000
            new_plugins.append(e)
        if new_plugins:
            key = "plugins" if "plugins" in d else "plugin"
            d[key] = new_plugins

        open(path, "w").write(json.dumps(d, indent=2))
        print(f"PATCHED: {path}")
        print(f"  model (root+agents): {model}  (per-agent models stripped: {stripped})")
        print(f"  model limit.context: {CTX:,}")
        print(f"  compaction.threshold: {int(CTX * CLEANUP_FRACTION):,} (>=50% cleanup)")
        print(f"  backup: {path}.bak-{TS}")

    print("DONE")


if __name__ == "__main__":
    main()
