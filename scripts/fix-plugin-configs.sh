#!/usr/bin/env bash
# fix-plugin-configs.sh — remove the 8 unported V1-API plugins from BOTH the live
# config and the staged V2 config that boot-activation reinstalls (root cause of
# banned plugins reappearing after every reboot). Idempotent; JSON validated.
set -uo pipefail
TS="$(date +%Y%m%dT%H%M%S)"
for CFG in "$HOME/.config/opencode/opencode.json" \
           "$HOME/.local/share/opencode-v2-staging/opencode.v2.json"; do
  [ -f "$CFG" ] || { echo "SKIP missing: $CFG"; continue; }
  cp "$CFG" "$CFG.bak-$TS"
  python3 - "$CFG" <<'PYEOF'
import json, re, sys
p = sys.argv[1]
raw = open(p).read()
d = json.loads(re.sub(r'^\s*//.*$', '', raw, flags=re.M))
BROKEN = {"opencode-cache-ttl", "@vikrant82/opencode-cache-keepalive",
          "@skybluejacket/opencode-context-compress", "opencode-context-guard",
          "opencode-context", "opencode-cache-hit",
          "opencode-provider-manager", "opencode-router"}
key = "plugins" if "plugins" in d else "plugin"
def name(e): return e[0] if isinstance(e, list) else (e.get("package") if isinstance(e, dict) else e)
before = len(d[key])
d[key] = [e for e in d[key] if name(e) not in BROKEN]
open(p, "w").write(json.dumps(d, indent=2))
print(f"{p}: plugins {before} -> {len(d[key])}")
PYEOF
  python3 - "$CFG" <<'PYEOF'
import json, re, sys
raw = open(sys.argv[1]).read()
json.loads(re.sub(r'^\s*//.*$', '', raw, flags=re.M))
print("JSON OK")
PYEOF
done
echo "DONE — restart opencode to load the clean plugin set"
