#!/usr/bin/env bash
# finish-requirements.sh — final mission fixes (2026-10-12)
# Run: bash scripts/finish-requirements.sh
# 1) health.sh false-negative fixes (SYNC-2: JSONC parse + $HOME/Projects case)
# 2) V2 plugin load fixes: disable 8 plugins that fail under OpenCode 2.0.27
#    (all at latest npm versions but still V1-API / missing entrypoints — upstream unported)
# Idempotent; backs up every file it touches.
set -uo pipefail

REPO="$(cd "$(dirname "$0")/.." && pwd)"
CFG="$HOME/.config/opencode/opencode.json"
TS="$(date +%Y%m%dT%H%M%S)"

echo "== 1. health.sh fixes =="
H="$REPO/src/modes/health.sh"
cp "$H" "$H.bak-$TS"
python3 - "$H" <<'PYEOF'
import re, sys
p = sys.argv[1]
s = open(p).read()
# JSONC-safe config parse (strip full-line // comments before json.loads)
s = s.replace(
  """python3 -c \\"import json; c=json.load(open('$HOME/.config/opencode/opencode.json')); m=len(c.get('mcp',{})); exit(0 if m>2 else 1)\\"""",
  """python3 -c \\"import json; lines=[l for l in open('$HOME/.config/opencode/opencode.json') if not l.lstrip().startswith('//')]; c=json.loads(''.join(lines)); m=len(c.get('mcp',{}) or c.get('mcp',{}).get('servers',{})); exit(0 if m>2 else 1)\\"""")
s = s.replace(
  """python3 -c \\"import json; c=json.load(open('$HOME/.config/opencode/opencode.json')); p=len(c.get('provider',{})); exit(0 if p>=2 else 1)\\"""",
  """python3 -c \\"import json; lines=[l for l in open('$HOME/.config/opencode/opencode.json') if not l.lstrip().startswith('//')]; c=json.loads(''.join(lines)); p=len(c.get('provider',{}) or c.get('providers',{})); exit(0 if p>=2 else 1)\\"""")
# case fix: real dir is ~/Projects (Linux case-sensitive)
s = s.replace('"${PROJECT_DIR:-$HOME/projects}/', '"${PROJECT_DIR:-$HOME/Projects}/')
open(p, "w").write(s)
print("health.sh patched")
PYEOF
bash -n "$H" && echo "bash -n OK" || echo "bash -n FAILED — restore from $H.bak-$TS"

echo "== 2. V2 plugin fixes =="
cp "$CFG" "$CFG.bak-$TS"
python3 - "$CFG" <<'PYEOF'
import json, re, sys
p = sys.argv[1]
raw = open(p).read()
stripped = re.sub(r'^\s*//.*$', '', raw, flags=re.M)
d = json.loads(stripped)
# Failing under V2 (opencode.log evidence):
#  - V1-API (no default export with id+setup): opencode-cache-ttl, @vikrant82/opencode-cache-keepalive,
#    @skybluejacket/opencode-context-compress, opencode-context-guard, opencode-context
#  - env clash OPENTUI_FORCE_UNICODE: opencode-cache-hit
#  - entrypoint not found: opencode-provider-manager, opencode-router
BROKEN = {"opencode-cache-ttl", "@vikrant82/opencode-cache-keepalive",
          "@skybluejacket/opencode-context-compress", "opencode-context-guard",
          "opencode-context", "opencode-cache-hit",
          "opencode-provider-manager", "opencode-router"}
def name(entry):
    return entry[0] if isinstance(entry, list) else entry
before = len(d.get("plugins", d.get("plugin", [])))
key = "plugins" if "plugins" in d else "plugin"
d[key] = [e for e in d[key] if name(e) not in BROKEN]
open(p, "w").write(json.dumps(d, indent=2))
print(f"plugins: {before} -> {len(d[key])} (removed {before - len(d[key])} unported V1-API/broken)")
print("NOTE: these 8 have no V2-compatible release on npm (checked 2026-10-12);")
print("      re-enable after upstream ports to Plugin.define({id, setup}) API.")
PYEOF
python3 -c "import json,re; raw=open('$CFG').read(); json.loads(re.sub(r'^\s*//.*$','',raw,flags=re.M)); print('config JSON OK')"

echo "== done. Backups: $H.bak-$TS, $CFG.bak-$TS =="
echo "Next: restart opencode desktop/CLI to load the pruned plugin set."
