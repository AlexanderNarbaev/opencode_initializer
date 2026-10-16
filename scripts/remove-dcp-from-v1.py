#!/usr/bin/env python3
"""remove-dcp-from-v1.py — SME finding 2026-10-16: opencode-dcp 2.x is a V2-ONLY
package (no 1.x releases; depends on @opencode/plugin; README requires
OpenCode 2.0+). It cannot load under the V1 1.19.0 runtime and its presence in
the V1 config produces "failed to load plugin" errors. V1 compaction is
configured natively (auto/tail_turns/reserved), so removing the entry is the
correct fix; the staged V2 config keeps it for the future V2 lane.
Idempotent; backups kept.
"""
import json, re, os, glob, datetime
ts = datetime.datetime.now().strftime("%Y%m%dT%H%M%S")

def clean(path):
    raw = open(path).read()
    d = json.loads(re.sub(r"^\s*//.*$", "", raw, flags=re.M))
    pk = "plugin" if "plugin" in d else "plugins"
    if pk not in d:
        return 0
    before = len(d[pk])
    d[pk] = [e for e in d[pk]
             if (e[0] if isinstance(e, list) and e else
                 (e.get("package") if isinstance(e, dict) else e)) != "opencode-dcp"]
    removed = before - len(d[pk])
    if removed:
        open(path + f".bak-dcpdrop-{ts}", "w").write(raw)
        open(path, "w").write(json.dumps(d, indent=2))
    return removed

total = 0
for p in [os.path.expanduser("~/.config/opencode/opencode.json")] + sorted(
        glob.glob(os.path.expanduser("~/Projects/*/opencode.json"))):
    if os.path.exists(p):
        r = clean(p)
        total += r
        if r:
            print(f"removed opencode-dcp: {p}")
print(f"total removed: {total}")

# staged V2 config keeps dcp (it is the V2-native context pruner)
stg = os.path.expanduser("~/.local/share/opencode-v2-staging/opencode.v2.json")
if os.path.exists(stg):
    d = json.loads(re.sub(r"^\s*//.*$", "", open(stg).read(), flags=re.M))
    pk = "plugins" if "plugins" in d else "plugin"
    has = any((e[0] if isinstance(e, list) and e else
               (e.get("package") if isinstance(e, dict) else e)) == "opencode-dcp"
              for e in d.get(pk, []))
    print(f"staged V2 config keeps opencode-dcp: {has}")
print("DONE — restart opencode sessions")