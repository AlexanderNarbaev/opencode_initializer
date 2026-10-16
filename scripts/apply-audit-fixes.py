#!/usr/bin/env python3
"""apply-audit-fixes.py — apply post-reboot audit fixes (2026-10-16, audit ses_ebbaf7eb8ff)

P1. Remove the 2 genuinely unloadable plugins (no resolvable entrypoint in the
    published packages): opencode-worktree, opencode-cache-switch.
P2. Pin every remaining plugin to the registry-verified exact version so no config
    entry floats on @latest at launch (npm latest as of 2026-10-16).
P3. Drop config keys V1.19 explicitly ignores (compaction.prune, compaction.tail_turns,
    experimental.openTelemetry) so the file stops emitting normalization warnings,
    and remove dead legacy `providers` blocks shadowed by native `provider`.
Applies to the global config, the repo config, and every project config.
Idempotent; backups kept.
"""
import json, re, os, glob, datetime

ts = datetime.datetime.now().strftime("%Y%m%dT%H%M%S")

# npm `latest` verified 2026-10-16 by the audit subagent
PINS = {
    "opencode-swarm": "7.197.3",
    "opencode-codegraph": "0.1.38",
    "opencode-goal-plugin": "0.11.0",
    "opencode-supermemory": "2.0.17",
    "opencode-orchestrator": "2.0.15",
    "@tarquinen/opencode-dcp": "3.2.0",
    "opencode-auto-fallback": "0.4.61",
    "opencode-vibeguard": "0.1.0",
    "opencode-devcontainers": "0.5.1",
    "opencode-scheduler": "1.3.0",
    "opencode-background-agents": "0.1.1",
    "opencode-conductor": "1.0.6",
    "opencode-zellij-namer": "1.1.3",
    "opencode-websearch-cited": "1.2.0",
    "opencode-token-tracker": "2.0.0",
    "opencode-daytona": "0.1.1",
    "opencode-cache-injector": "1.0.0",
    "opencode-context-watch": "1.0.0",
    "opencode-models-discovery": "1.10.0",
}
DROP = {"opencode-worktree", "opencode-cache-switch"}

def fix(path):
    raw = open(path).read()
    d = json.loads(re.sub(r"^\s*//.*$", "", raw, flags=re.M))
    notes = []

    pk = "plugin" if "plugin" in d else "plugins"
    if pk in d:
        newp = []
        for e in d[pk]:
            nm = e[0] if isinstance(e, list) and e else (e.get("package") if isinstance(e, dict) else e)
            base = re.sub(r"@[\d.]+$", "", nm or "")
            if base in DROP:
                notes.append(f"dropped unloadable {base}"); continue
            ver = PINS.get(base)
            pinned = f"{base}@{ver}" if ver else base
            if isinstance(e, list) and len(e) == 2 and isinstance(e[1], dict):
                newp.append([pinned, e[1]])
            else:
                newp.append(pinned)
        d[pk] = newp

    comp = d.get("compaction")
    if isinstance(comp, dict):
        for dead in ("prune", "tail_turns"):
            if dead in comp:
                comp.pop(dead); notes.append(f"dropped compaction.{dead} (ignored by V1.19)")
    exp = d.get("experimental")
    if isinstance(exp, dict) and "openTelemetry" in exp:
        exp.pop("openTelemetry"); notes.append("dropped experimental.openTelemetry (ignored)")

    if "providers" in d and "provider" in d:
        d.pop("providers"); notes.append("dropped legacy providers block shadowed by provider")

    open(path + f".bak-audit-{ts}", "w").write(raw)
    open(path, "w").write(json.dumps(d, indent=2))
    return notes

for p in [os.path.expanduser("~/.config/opencode/opencode.json"),
          "/home/alexandr-narbaev/Projects/opencode_initializer/opencode.json"] + sorted(
        glob.glob(os.path.expanduser("~/Projects/*/opencode.json"))):
    if os.path.exists(p):
        try:
            n = fix(p)
            print(f"{p}: {'; '.join(n) if n else 'ok'}")
        except Exception as e:
            print(f"ERR {p}: {e}")
print("DONE")