#!/usr/bin/env python3
"""restore-dcp-v1.py — restore V1-compatible context pruning (research finding 2026-10-16)

The repo removed context pruning after `opencode-dcp` failed to load. Root cause:
`opencode-dcp` on npm is a V2-ONLY package (no 1.x line; deps @opencode/plugin).
The V1-compatible Dynamic Context Pruning plugin is @tarquinen/opencode-dcp@3.2.0
(peer @opencode-ai/plugin >=1.18.29). Re-adding it under the correct name.
Uses the V1 tuple form with 1M-scaled thresholds and 50% cleanup.
"""
import json, re, os, glob, datetime
ts = datetime.datetime.now().strftime("%Y%m%dT%H%M%S")
PKG = "@tarquinen/opencode-dcp"
OPTS = {
    "compress": {"enabled": True, "minContextLimit": 500_000,
                 "maxContextLimit": 1_000_000, "autoCompaction": True},
    "prune": {"enabled": True, "protectTokens": 100_000, "minTokens": 500_000},
}

def add(path):
    raw = open(path).read()
    d = json.loads(re.sub(r"^\s*//.*$", "", raw, flags=re.M))
    pk = "plugin" if "plugin" in d else "plugins"
    entries = d.get(pk, [])
    def nm(e):
        return e[0] if isinstance(e, list) and e else (e.get("package") if isinstance(e, dict) else e)
    # drop any stale V2-only dcp entry, add the correct V1 one
    entries = [e for e in entries if nm(e) not in ("opencode-dcp", PKG)]
    entries.append([PKG, dict(OPTS)])
    d[pk] = entries
    open(path + f".bak-dcpv1-{ts}", "w").write(raw)
    open(path, "w").write(json.dumps(d, indent=2))
    return len(entries)

for p in [os.path.expanduser("~/.config/opencode/opencode.json")] + sorted(
        glob.glob(os.path.expanduser("~/Projects/*/opencode.json"))):
    if os.path.exists(p):
        print(f"dcp(V1) installed in: {p} (plugins={add(p)})")
print("DONE — restart opencode; verify with `opencode debug config`")