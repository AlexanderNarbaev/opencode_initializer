#!/usr/bin/env bash
# ============================================================================
# ISOLATED Unit Test for src/data/mcp-profiles.json (M2 MCP/LSP SSOT)
# Target: src/data/mcp-profiles.json
#
# Schema (current): { disabled_by_default[], full_mode_all_on, task_profiles{}, file_lsp{}, lsp_default[] }
#
# Tests:
#   (a) File exists + valid JSON
#   (b) disabled_by_default marks browser-bound servers off (GAP-1)
#   (c) full_mode_all_on = true (all-on baseline preserved, S2.2.2)
#   (d) task_profiles present (coding/reasoning/fast/agentic/research/testing)
#   (e) fast profile minimal; agentic/research enable heavyweight servers
#   (f) file_lsp maps common extensions
#   (g) lsp_default fallback present
# ============================================================================
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
TESTS_PASS=0; TESTS_FAIL=0
MANIFEST="$PROJECT_DIR/src/data/mcp-profiles.json"

assert() {
  local desc="$1" condition="$2"
  if (eval "$condition") 2>/dev/null; then
    TESTS_PASS=$((TESTS_PASS + 1))
  else
    TESTS_FAIL=$((TESTS_FAIL + 1))
    echo "    FAIL: $desc" >&2
  fi
}

echo "=== Testing src/data/mcp-profiles.json ==="

# ── (a) File + validity ──────────────────────────────────────────────────────
assert "mcp-profiles.json exists" "[ -f '$MANIFEST' ]"
assert "mcp-profiles.json is valid JSON" "python3 -c \"import json; json.load(open('$MANIFEST'))\""

# ── (b) disabled_by_default (GAP-1) ──────────────────────────────────────────
assert "has disabled list (disabled_by_default or heavyweight)" "python3 -c \"
import json; d=json.load(open('$MANIFEST'))
key = 'disabled_by_default' if 'disabled_by_default' in d else 'heavyweight'
assert key in d and isinstance(d[key], list)
\""
for s in chrome-devtools playwright excalidraw agent-browser; do
  assert "$s is disabled-by-default" "python3 -c \"
import json; d=json.load(open('$MANIFEST'))
key = 'disabled_by_default' if 'disabled_by_default' in d else 'heavyweight'
assert '$s' in d[key]
\""
done

# ── (c) full mode all-on baseline (S2.2.2) ───────────────────────────────────
assert "full_mode_all_on is true" "python3 -c \"import json; d=json.load(open('$MANIFEST')); assert d['full_mode_all_on'] == True\""

# ── (d) task_profiles ────────────────────────────────────────────────────────
for t in coding reasoning fast agentic research testing; do
  assert "has task profile: $t" "python3 -c \"import json; d=json.load(open('$MANIFEST')); assert '$t' in d['task_profiles']\""
done
assert "every profile has mcp + lsp keys" "python3 -c \"
import json; d=json.load(open('$MANIFEST'))
for k,v in d['task_profiles'].items():
    assert 'mcp' in v and 'lsp' in v, f'{k}: missing mcp/lsp'
\""

# ── (e) fast minimal; agentic/research enable heavyweight ────────────────────
assert "fast profile is minimal (filesystem only)" "python3 -c \"
import json; d=json.load(open('$MANIFEST'))
assert d['task_profiles']['fast']['mcp'] == ['filesystem']
\""
assert "agentic profile enables playwright" "python3 -c \"
import json; d=json.load(open('$MANIFEST'))
assert 'playwright' in d['task_profiles']['agentic']['mcp']
\""
assert "research profile enables chrome-devtools" "python3 -c \"
import json; d=json.load(open('$MANIFEST'))
assert 'chrome-devtools' in d['task_profiles']['research']['mcp']
\""

# ── (f) file_lsp map ─────────────────────────────────────────────────────────
assert "file_lsp maps .ts → typescript" "python3 -c \"import json; d=json.load(open('$MANIFEST')); assert d['file_lsp']['.ts'] == 'typescript'\""
assert "file_lsp maps .py → pyright" "python3 -c \"import json; d=json.load(open('$MANIFEST')); assert d['file_lsp']['.py'] == 'pyright'\""
assert "file_lsp maps .sh → bash" "python3 -c \"import json; d=json.load(open('$MANIFEST')); assert d['file_lsp']['.sh'] == 'bash'\""
assert "file_lsp maps .go → gopls" "python3 -c \"import json; d=json.load(open('$MANIFEST')); assert d['file_lsp']['.go'] == 'gopls'\""

# ── (g) lsp_default fallback ─────────────────────────────────────────────────
assert "lsp_default is a non-empty list" "python3 -c \"import json; d=json.load(open('$MANIFEST')); assert isinstance(d['lsp_default'], list) and len(d['lsp_default']) >= 1\""

# ── Report ───────────────────────────────────────────────────────────────────
echo "test_mcp_profiles: $TESTS_PASS passed, $TESTS_FAIL failed"
[ "$TESTS_FAIL" -eq 0 ] || exit 1
