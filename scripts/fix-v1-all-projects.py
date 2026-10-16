#!/usr/bin/env python3
"""fix-v1-all-projects.py — apply V1 (opencode 1.19.0) schema conformance to the
global config AND every project config under ~/Projects.
Conversions: permissions[]->permission{}, agents->agent, plugins->plugin (tuple form),
providers->provider, mcp.servers->mcp, model limit requires context+output.
Idempotent; backups."""
import json, re, os, glob, datetime
TS = datetime.datetime.now().strftime("%Y%m%dT%H%M%S")
MAP = {"shell": "bash", "subagent": "task", "edit": "edit", "read": "read",
       "webfetch": "webfetch", "websearch": "websearch", "glob": "glob",
       "grep": "grep", "external_directory": "external_directory", "doom_loop": "doom_loop"}
BROKEN = {"opencode-cache-ttl", "@vikrant82/opencode-cache-keepalive",
          "@skybluejacket/opencode-context-compress", "opencode-context-guard",
          "opencode-context", "opencode-cache-hit",
          "opencode-provider-manager", "opencode-router"}

def convert(path):
    raw = open(path).read()
    d = json.loads(re.sub(r"^\s*//.*$", "", raw, flags=re.M))
    open(path + f".bak-v1all-{TS}", "w").write(raw)
    # permissions[] -> permission{}
    if isinstance(d.get("permissions"), list):
        tgt = d.setdefault("permission", {})
        for r in d.pop("permissions"):
            act = MAP.get(r.get("action", ""), r.get("action", ""))
            if not act:
                continue
            res, eff = r.get("resource", "*"), r.get("effect", "allow")
            if res == "*":
                tgt[act] = eff
            else:
                tgt.setdefault(act, {}) if not isinstance(tgt.get(act), dict) else None
                tgt[act][res] = eff
    # renames
    if "agents" in d and "agent" not in d: d["agent"] = d.pop("agents")
    if "plugins" in d and "plugin" not in d: d["plugin"] = d.pop("plugins")
    if "providers" in d and "provider" not in d: d["provider"] = d.pop("providers")
    d.pop("permissions", None)
    if isinstance(d.get("mcp"), dict) and "servers" in d and len(d["mcp"]) <= 2:
        d["mcp"] = d["mcp"]["servers"]
    # plugin entries -> V1 tuple/string, banned removed
    pk = "plugin" if "plugin" in d else "plugins"
    out = []
    for e in d.get(pk, []):
        if isinstance(e, dict):
            nm = e.get("package") or e.get("name")
            if nm in BROKEN: continue
            o = e.get("options")
            out.append([nm, o] if o else nm)
        elif isinstance(e, list) and e and e[0] in BROKEN:
            continue
        else:
            out.append(e)
    d[pk] = out
    # model limits need context+output
    for pp in ("provider", "providers"):
        for pv in (d.get(pp) or {}).values():
            for mv in (pv.get("models") or {}).values():
                lim = mv.setdefault("limit", {})
                lim.setdefault("context", 1_000_000)
                lim.setdefault("output", 65_536)
    open(path, "w").write(json.dumps(d, indent=2))
    return len(out)

targets = [os.path.expanduser("~/.config/opencode/opencode.json")]
targets += sorted(glob.glob(os.path.expanduser("~/Projects/*/opencode.json")))
for t in targets:
    if os.path.exists(t):
        try:
            n = convert(t)
            print(f"OK  {t}  (plugins: {n})")
        except Exception as e:
            print(f"ERR {t}: {e}")
print("DONE")