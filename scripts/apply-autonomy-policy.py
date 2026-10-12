#!/usr/bin/env python3
"""apply-autonomy-policy.py (2026-10-12)

1) Applies the 1M-context / single-free-model policy to EVERY project config under ~/Projects.
2) Removes autonomy blockers reported by agents:
   - AUTHORITY_UNKNOWN_AGENT / SCOPE_BINDING_AMBIGUOUS  -> AuthorityConfig allow-all + scope_guard off
   - SCOPE_NOT_DECLARED / "no plan task id resolved"     -> require_declared_scope=false
   - delegation "Insufficient Balance"                   -> delegation_gate=false
   Keeps minimal safety: scope: 'security-only'.

Config keys verified against opencode-swarm dist/config/schema.d.ts:
  delegation_gate: boolean; scope_guard: boolean (default);
  require_declared_scope: boolean (default); scope: 'all'|'security-only';
  AuthorityConfigSchema / AgentAuthorityRuleSchema.

Patches: each <project>/opencode.json (plugins entry for opencode-swarm) AND
         each <project>/.opencode/opencode-swarm.json (policy file the plugin loads).
Idempotent; backups *.bak-<ts>.
"""
import json, re, os, glob, datetime

TS = datetime.datetime.now().strftime("%Y%m%dT%H%M%S")
CTX = 1_000_000
CLEANUP = 500_000
FREE_MODEL = "mimo/mimo-v2.6-pro"
HOME = os.path.expanduser("~")

SWARM_POLICY = {
    "delegation_gate": False,
    "require_declared_scope": False,
    "scope_guard": False,
    "scope": "security-only",
    "authority": {
        "default": "allow",
        "rules": [
            {"agent": "*", "action": "*", "effect": "allow"},
        ],
    },
    "gates": {"balanced": False, "require_scope": False},
}

CTX_POLICY = {
    "model": FREE_MODEL,
    "limit_context": CTX,
    "compaction_threshold": CLEANUP,
}


def load_jsonc(path):
    raw = open(path).read()
    return json.loads(re.sub(r"^\s*//.*$", "", raw, flags=re.M)), raw


def patch_config(path):
    d, raw = load_jsonc(path)
    open(path + f".bak-{TS}", "w").write(raw)
    changed = []

    # --- context/model policy ---
    d["model"] = FREE_MODEL
    agents = d.get("agents", d.get("agent", {}))
    n = 0
    for a in agents.values():
        if isinstance(a, dict) and "model" in a:
            del a["model"]; n += 1
    prov, mod = FREE_MODEL.split("/", 1)
    provs = d.setdefault("providers", d.setdefault("provider", {}))
    entry = provs.setdefault(prov, {}).setdefault("models", {}).setdefault(mod, {})
    entry.setdefault("limit", {})["context"] = CTX
    comp = d.setdefault("compaction", {})
    comp["auto"] = True
    comp["threshold"] = CLEANUP
    comp.setdefault("reserved", 10_000)
    changed.append(f"context/model (agents stripped: {n})")

    # --- swarm plugin autonomy policy in plugins entry ---
    plugins = d.get("plugins", d.get("plugin", []))
    hit = False
    for i, e in enumerate(plugins):
        name = e[0] if isinstance(e, list) else (e.get("package") if isinstance(e, dict) else e)
        if name == "opencode-swarm":
            if isinstance(e, list):
                opts = e[1] if len(e) == 2 and isinstance(e[1], dict) else {}
                opts.update({k: v for k, v in SWARM_POLICY.items() if k not in ("authority",)})
                opts["authority"] = SWARM_POLICY["authority"]
                plugins[i] = [name, opts]
            elif isinstance(e, dict):
                opts = e.setdefault("options", {})
                opts.update({k: v for k, v in SWARM_POLICY.items()})
            hit = True
    if not hit:
        plugins.append(["opencode-swarm", dict(SWARM_POLICY)])
        changed.append("swarm plugin entry added")
    else:
        changed.append("swarm plugin policy updated")
    if "plugins" in d:
        d["plugins"] = plugins
    else:
        d["plugin"] = plugins

    open(path, "w").write(json.dumps(d, indent=2))
    return changed


def patch_swarm_file(proj):
    p = os.path.join(proj, ".opencode", "opencode-swarm.json")
    os.makedirs(os.path.dirname(p), exist_ok=True)
    if os.path.exists(p):
        open(p + f".bak-{TS}", "w").write(open(p).read())
    open(p, "w").write(json.dumps(SWARM_POLICY, indent=2))
    return p


def main():
    cfgs = [os.path.join(HOME, ".config", "opencode", "opencode.json")]
    cfgs += sorted(glob.glob(os.path.join(HOME, "Projects", "*", "opencode.json")))
    for path in cfgs:
        if not os.path.exists(path):
            continue
        try:
            ch = patch_config(path)
            print(f"PATCHED {path}: {'; '.join(ch)}")
        except Exception as ex:
            print(f"ERROR {path}: {ex}")
    for proj in sorted(glob.glob(os.path.join(HOME, "Projects", "*"))):
        if os.path.isdir(proj):
            p = patch_swarm_file(proj)
            print(f"POLICY  {p}")
    print("DONE — restart opencode to load policy")


if __name__ == "__main__":
    main()
