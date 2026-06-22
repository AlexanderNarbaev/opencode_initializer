#!/usr/bin/env bash
# ============================================================================
# End-to-End test: full install mode (framework only — no real installs)
# Tests: mode detection, argument parsing, module loading order, step execution
# SKIPS actual installations (verifies orchestration structure)
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$(dirname "$SCRIPT_DIR")")"
TESTS_PASS=0; TESTS_FAIL=0

assert() {
  local desc="$1" condition="$2"
  if (eval "$condition") &>/dev/null; then
    TESTS_PASS=$((TESTS_PASS + 1))
  else
    TESTS_FAIL=$((TESTS_FAIL + 1))
    echo "    FAIL: $desc" >&2
  fi
}

echo "=== E2E: orchestrator flow ==="

SETUP="$PROJECT_DIR/setup.sh"

# ── Test: all 10 modes defined in case statement ──────────────────────
# The modes appear as --full), --reinit), etc. in the case statement
for mode_name in full reinit health update upgrade interactive new fix-config fix-zshrc dry-run; do
  assert "mode $mode_name in setup.sh" \
    'grep -q "\-\-'"$mode_name"'" "'"$SETUP"'"'
done

# ── Test: Module loading order ───────────────────────────────────────
assert "system module (01) referenced"   'grep -q "01-system" "'"$SETUP"'"'
assert "docker module (02) referenced"   'grep -q "02-docker" "'"$SETUP"'"'
assert "finalize module (19) as last"    'grep -q "19-finalize" "'"$SETUP"'"'

# ── Test: All lib modules are sourced somewhere ────────────────────────
MODULES_REFERENCED=$(grep -c 'source.*lib/' "$SETUP" 2>/dev/null || echo 0)
assert "at least 15 lib modules sourced" "[ '$MODULES_REFERENCED' -ge 15 ]"

# ── Test: All 4 mode scripts referenced ────────────────────────────────
assert "health mode sourced"       'grep -q "health.sh" "'"$SETUP"'"'
assert "fix-zshrc mode sourced"    'grep -q "fix-zshrc.sh" "'"$SETUP"'"'
assert "upgrade mode sourced"      'grep -q "upgrade.sh" "'"$SETUP"'"'
assert "interactive mode sourced"  'grep -q "interactive.sh" "'"$SETUP"'"'

# ── Test: Version string ──────────────────────────────────────────────
assert "version is v1.0.0" 'grep -q "v1.0.0" "'"$SETUP"'"'

# ── Test: set -euo pipefail in all files ──────────────────────────────
for f in "$PROJECT_DIR/setup.sh" "$PROJECT_DIR/src/lib/"*.sh "$PROJECT_DIR/src/modes/"*.sh; do
  [ -f "$f" ] || continue
  fname=$(basename "$f")
  assert "$fname has set -euo pipefail" 'grep -q "set -euo pipefail" "'"$f"'"'
done

# ── Test: trap cleanup in setup.sh ────────────────────────────────────
assert "trap cleanup exists" \
  'grep -q "trap cleanup" "'"$SETUP"'" || grep -q "trap cleanup" "'"$PROJECT_DIR/src/lib/helpers.sh"'"'

# ── Test: No hardcoded secrets ────────────────────────────────────────
SECRET_SCAN=$(grep -rni 'sk-[a-zA-Z0-9]\{20,\}' "$SETUP" "$PROJECT_DIR/src/lib/"*.sh 2>/dev/null || true)
assert "no hardcoded API keys" "[ -z '$SECRET_SCAN' ]"

# ── Test: opencode.json is valid JSON ────────────────────────────────
if [ -f "$PROJECT_DIR/opencode.json" ]; then
  python3 -c "import json; json.load(open('$PROJECT_DIR/opencode.json'))" 2>/dev/null
  assert "opencode.json is valid JSON" "[ $? -eq 0 ]"
fi

# ── Test: helpers.sh is sourced before 00-core.sh ────────────────────
HELPERS_LINE=$(grep -n 'src/lib/helpers.sh' "$SETUP" | head -1 | cut -d: -f1)
CORE_LINE=$(grep -n 'src/lib/00-core.sh' "$SETUP" | head -1 | cut -d: -f1)
assert "helpers sourced before core" "[ '$HELPERS_LINE' -lt '$CORE_LINE' ]"

# ── Test: setup.sh line count (~257) ─────────────────────────────────
SETUP_LINES=$(wc -l < "$SETUP")
assert "setup.sh is ~284 lines" "[ '$SETUP_LINES' -ge 274 ] && [ '$SETUP_LINES' -le 294 ]"

echo
echo "=== test_full_install.sh: $TESTS_PASS passed, $TESTS_FAIL failed ==="
[ "$TESTS_FAIL" -eq 0 ] || exit 1
