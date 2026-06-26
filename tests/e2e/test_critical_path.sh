#!/usr/bin/env bash
# tests/e2e/test_critical_path.sh — Critical path tests for opencode_initializer
# Run: bash tests/e2e/test_critical_path.sh
set -euo pipefail

RED='\033[0;31m'; GREEN='\033[0;32m'; NC='\033[0m'
PASS=0; FAIL=0
assert() { local desc="$1"; shift; if "$@" &>/dev/null; then echo -e "  ${GREEN}✓${NC} $desc"; PASS=$((PASS+1)); else echo -e "  ${RED}✗${NC} $desc"; FAIL=$((FAIL+1)); fi; }

echo "=== Critical Path Tests ==="
SCRIPTS_DIR="$(cd "$(dirname "$0")/../.." && pwd)"

section() { echo; echo -e "${GREEN}─── $1 ───${NC}"; }

# ── Syntax checks ──
section "Syntax: all scripts"
for f in "$SCRIPTS_DIR/setup.sh" "$SCRIPTS_DIR/dev.sh" "$SCRIPTS_DIR/src/lib/"*.sh "$SCRIPTS_DIR/src/modes/"*.sh "$SCRIPTS_DIR/migrations/"*.sh; do
  [ -f "$f" ] || continue
  assert "bash -n $(basename "$f")" bash -n "$f"
done

# ── Module count ──
section "Structure"
assert "setup.sh exists" [ -f "$SCRIPTS_DIR/setup.sh" ]
assert "dev.sh exists" [ -f "$SCRIPTS_DIR/dev.sh" ]
assert "lib/ has >=22 modules" [ "$(ls "$SCRIPTS_DIR/src/lib/"*.sh 2>/dev/null | wc -l)" -ge 22 ]
assert "modes/ has 5 scripts" [ "$(ls "$SCRIPTS_DIR/src/modes/"*.sh 2>/dev/null | wc -l)" -eq 5 ]
assert "migrations/ exists" [ -d "$SCRIPTS_DIR/migrations" ]
assert "workflows directory exists" [ -d "$SCRIPTS_DIR/.github/workflows" ]

# ── Core functions ──
section "Core functions (dry import)"
source "$SCRIPTS_DIR/src/lib/helpers.sh" 2>/dev/null || true
source "$SCRIPTS_DIR/src/lib/00-core.sh" 2>/dev/null || true
assert "_curl defined" type _curl &>/dev/null
assert "_retry defined" type _retry &>/dev/null
assert "_step_skip defined" type _step_skip &>/dev/null
assert "_step_done defined" type _step_done &>/dev/null
assert "_sudo defined" type _sudo &>/dev/null

# ── Module step_done completeness ──
section "Module step_done coverage"
for mod in "$SCRIPTS_DIR/src/lib/"0[1-9]-*.sh "$SCRIPTS_DIR/src/lib/"1[0-9]-*.sh "$SCRIPTS_DIR/src/lib/"20-*.sh; do
  [ -f "$mod" ] || continue
  name=$(basename "$mod")
  assert "step_done in $name" grep -q '_step_done' "$mod"
done

# ── Mirror URL sanity ──
section "Mirror URLs"
timeout 10 bash -c "source '$SCRIPTS_DIR/src/lib/00-core.sh'" 2>/dev/null || true
assert "GITHUB_MIRROR set" [ -n "${GITHUB_MIRROR:-}" ]
assert "NPM_REGISTRY set" [ -n "${NPM_REGISTRY:-}" ]
assert "PYPI_MIRROR set" [ -n "${PYPI_MIRROR:-}" ]
assert "GO_MIRROR set" [ -n "${GO_MIRROR:-}" ]
assert "GOPROXY uses goproxy" bash -c 'echo "${GOPROXY:-}" | grep -q goproxy'

# ── Help output ──
section "CLI help"
assert "setup.sh --help" bash "$SCRIPTS_DIR/setup.sh" --help 2>/dev/null
assert "dev.sh help" bash "$SCRIPTS_DIR/dev.sh" --help 2>/dev/null
assert "setup.sh modes listed" bash -c "bash '$SCRIPTS_DIR/setup.sh' --help 2>&1 | grep -q 'full\|health\|fix-config\|interactive'"

# ── opencode.json structure ──
section "opencode.json schema"
HOME=${HOME:-~}
CONFIG="$HOME/.config/opencode/opencode.json"
if [ -f "$CONFIG" ]; then
  assert "opencode.json valid JSON" python3 -c "import json; json.load(open('$CONFIG'))"
  assert "opencode.json has model" python3 -c "import json; d=json.load(open('$CONFIG')); assert 'model' in d"
  assert "opencode.json has provider" python3 -c "import json; d=json.load(open('$CONFIG')); assert 'provider' in d"
  assert "opencode.json has mcp" python3 -c "import json; d=json.load(open('$CONFIG')); assert 'mcp' in d"
  assert "opencode.json has lsp" python3 -c "import json; d=json.load(open('$CONFIG')); assert 'lsp' in d"
  assert "opencode.json has plugin" python3 -c "import json; d=json.load(open('$CONFIG')); assert 'plugin' in d"
else
  warn "opencode.json not found — skipping checks"
fi

# ── Result ──
echo
echo "Tests: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ] && echo -e "${GREEN}ALL TESTS PASSED${NC}" || echo -e "${RED}$FAIL TEST(S) FAILED${NC}"
exit $FAIL
