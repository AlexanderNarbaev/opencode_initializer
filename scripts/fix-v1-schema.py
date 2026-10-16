#!/usr/bin/env python3
"""fix-v1-schema.py — final V1 (opencode 1.19.0) schema conformance.
1) plugin entries: V2 object {package, options} -> V1 tuple [name, options]
2) model limit requires both context and output keys.
Idempotent; backups."""
import json, re, os, datetime
p = os.path.expanduser("~/.config/opencode/opencode.json")
raw = open(p).read()
ts = datetime.datetime.now().strftime("%Y%m%dT%H%M%S")
open(p + f".bak-v1schema-{ts}", "w").write(raw)
d = json.loads(re.sub(r"^\s*//.*$", "", raw, flags=re.M))

# 1) plugin entries -> V1 tuple form
key = "plugin" if "plugin" in d else "plugins"
fixed = []
for e in d.get(key, []):
    if isinstance(e, dict):
        name = e.get("package") or e.get("name")
        opts = e.get("options")
        fixed.append([name, opts] if opts else name)
    else:
        fixed.append(e)
d[key] = fixed

# 2) model limit must include output
OUT = 65_536
for pk in ("provider", "providers"):
    for pname, pv in (d.get(pk) or {}).items():
        for mname, mv in (pv.get("models") or {}).items():
            lim = mv.setdefault("limit", {})
            lim.setdefault("context", 1_000_000)
            lim.setdefault("output", OUT)

open(p, "w").write(json.dumps(d, indent=2))
print("plugin entries:", len(d[key]))
print("first tuple:", d[key][1] if len(d[key]) > 1 and isinstance(d[key][1], list) else "n/a")
print("V1 schema fix applied")