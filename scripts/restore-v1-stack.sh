#!/usr/bin/env bash
# restore-v1-stack.sh — restore the fully-working V1 runtime (all community plugins
# load) while keeping OpenCode V2 staged for auto-switch when plugins ship V2 releases.
# Verified 2026-10-16: no V2 plugin releases exist on npm (codegraph 1.2.0, dcp 3.4.1,
# swarm 1.1.0, vibeguard 1.0.33, goal-plugin 0.11.0 — all V1 API).
set -uo pipefail
export PATH="$HOME/.npm-global/bin:$HOME/.local/bin:$PATH"
STG="$HOME/.local/share/opencode-v2-staging"
TS=$(date +%Y%m%dT%H%M%S)

echo "== 1. preserve V2 binary =="
if command -v opencode >/dev/null; then
  opencode --version
  cp -n "$(command -v opencode)" "$STG/opencode-v2-binary" 2>/dev/null || true
fi

echo "== 2. install V1 runtime as default =="
npm uninstall -g @opencode/cli >/dev/null 2>&1
npm install -g opencode-ai@1.19.0 >/dev/null 2>&1
echo "opencode -> $(opencode --version 2>&1)"

echo "== 3. make V2 available as opencode-v2 =="
if [ -f "$STG/opencode-v2-binary" ]; then
  ln -sf "$STG/opencode-v2-binary" "$HOME/.npm-global/bin/opencode-v2"
  echo "opencode-v2 -> $(opencode-v2 --version 2>&1)"
fi

echo "== 4. restore V1-shaped config merged with current policy =="
CFG="$HOME/.config/opencode/opencode.json"
V1B=$(ls -t "$CFG".v1.bak-* "$CFG".bak-* 2>/dev/null | head -1)
cp "$CFG" "$CFG.bak-$TS"
if [ -n "$V1B" ]; then
  cp "$V1B" "$CFG"
  echo "restored base: $V1B"
fi
python3 - "$CFG" <<'PYEOF'
import json, re, sys
p = sys.argv[1]
d = json.loads(re.sub(r'^\s*//.*$','',open(p).read(),flags=re.M))
# keep V1 shape but enforce current policy
d["model"] = "mimo/mimo-v2.6-pro"
for k in ("agent","agents"):
    for a in d.get(k,{}).values():
        if isinstance(a,dict): a.pop("model", None)
prov = d.setdefault("provider", d.get("providers", {}))
prov.setdefault("mimo",{}).setdefault("models",{}).setdefault("mimo-v2.6-pro",{}).setdefault("limit",{})["context"]=1_000_000
c = d.setdefault("compaction",{}); c["auto"]=True; c["threshold"]=500_000
BROKEN={"opencode-cache-ttl","@vikrant82/opencode-cache-keepalive","@skybluejacket/opencode-context-compress","opencode-context-guard","opencode-context","opencode-cache-hit","opencode-provider-manager","opencode-router"}
key = "plugin" if "plugin" in d else "plugins"
def nm(e): return e[0] if isinstance(e,list) else (e.get("package") if isinstance(e,dict) else e)
d[key] = [e for e in d[key] if nm(e) not in BROKEN]
open(p,"w").write(json.dumps(d,indent=2))
print(f"policy applied; plugins={len(d[key])}")
PYEOF

echo "== 5. smoke =="
opencode --version && echo "SMOKE OK"
echo "DONE — restart OpenCode sessions to load V1 runtime with full plugin set"
