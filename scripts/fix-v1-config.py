#!/usr/bin/env python3
"""fix-v1-config.py — convert live config to strict V1 shape for opencode 1.19.0.
V1 rejects V2 keys ("V2 permissions are not supported"). Renames/converts:
  permissions[] -> permission{} (shell->bash, subagent->task)
  agents->agent, mcp.servers->mcp, plugins->plugin, providers->provider
Idempotent; backup first."""
import json, re, os, datetime
p = os.path.expanduser("~/.config/opencode/opencode.json")
raw = open(p).read()
ts = datetime.datetime.now().strftime("%Y%m%dT%H%M%S")
open(p + f".bak-v1fix-{ts}", "w").write(raw)
d = json.loads(re.sub(r"^\s*//.*$", "", raw, flags=re.M))

# permissions[] -> permission{}
if "permissions" in d and isinstance(d["permissions"], list):
    perm = d.pop("permissions")
    tgt = d.setdefault("permission", {})
    MAP = {"shell": "bash", "subagent": "task", "edit": "edit", "read": "read",
           "webfetch": "webfetch", "websearch": "websearch", "glob": "glob",
           "grep": "grep", "task": "task", "external_directory": "external_directory",
           "doom_loop": "doom_loop"}
    for r in perm:
        act = MAP.get(r.get("action", ""), r.get("action", ""))
        res = r.get("resource", "*")
        eff = r.get("effect", "allow")
        if not act:
            continue
        if res == "*":
            tgt[act] = eff
        else:
            cur = tgt.get(act)
            if not isinstance(cur, dict):
                tgt[act] = {}
            tgt[act][res] = eff

if "agents" in d and "agent" not in d:
    d["agent"] = d.pop("agents")
if "plugins" in d and "plugin" not in d:
    d["plugin"] = d.pop("plugins")
if "providers" in d and "provider" not in d:
    d["provider"] = d.pop("providers")
mcp = d.get("mcp")
if isinstance(mcp, dict) and "servers" in mcp and len(mcp) <= 2:
    d["mcp"] = mcp["servers"]
# strip V2-only leftovers V1 rejects/ignores
for k in ("permissions",):
    d.pop(k, None)
open(p, "w").write(json.dumps(d, indent=2))
print("V1 shape:", sorted(d.keys()))
print("permission keys:", sorted(d.get("permission", {}).keys()))
