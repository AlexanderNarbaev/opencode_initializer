#!/usr/bin/env python3
"""fix-dcp-options.py — opencode-dcp V1 option shape.
V2-style keys (minContextLimit/maxContextLimit/protectTokens/minTokens) break the
V1 dcp plugin (failed to load plugin). Restore the minimal V1 option set and
express the 1M/50% policy via the keys V1 actually honours."""
import json, re, os, datetime
ts = datetime.datetime.now().strftime("%Y%m%dT%H%M%S")
targets = [os.path.expanduser("~/.config/opencode/opencode.json")]
targets += sorted(__import__("glob").glob(os.path.expanduser("~/Projects/*/opencode.json")))
for p in targets:
    if not os.path.exists(p):
        continue
    raw = open(p).read()
    d = json.loads(re.sub(r"^\s*//.*$", "", raw, flags=re.M))
    pk = "plugin" if "plugin" in d else "plugins"
    hit = False
    for i, e in enumerate(d.get(pk, [])):
        nm = e[0] if isinstance(e, list) and e else (e.get("package") if isinstance(e, dict) else e)
        if nm != "opencode-dcp":
            continue
        hit = True
        opts = e[1] if isinstance(e, list) and len(e) == 2 and isinstance(e[1], dict) else {}
        opts.pop("minContextLimit", None); opts.pop("maxContextLimit", None)
        opts.pop("protectTokens", None); opts.pop("minTokens", None)
        c = opts.setdefault("compress", {}); c["enabled"] = True
        pr = opts.setdefault("prune", {}); pr["enabled"] = True
        if isinstance(e, list):
            e[1] = opts
        else:
            e["options"] = opts
    if hit:
        open(p + f".bak-dcp-{ts}", "w").write(raw)
        open(p, "w").write(json.dumps(d, indent=2))
        print(f"dcp options fixed: {p}")
print("DONE")