#!/usr/bin/env bash
# ============================================================================
# Integration test: module loading order and structure
# Validates all modules: naming convention, syntax, source integrity
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

echo "=== Integration: module loading ==="

# ── All lib modules pass bash -n ──────────────────────────────────────
for f in "$PROJECT_DIR/src/lib/"*.sh "$PROJECT_DIR/src/modes/"*.sh; do
  fname=$(basename "$f")
  bash -n "$f" 2>/dev/null
  assert "Syntax: $fname" "[ $? -eq 0 ]"
done

# ── helpers.sh is sourced first by setup.sh ───────────────────────────
HELPERS_LINE=$(grep -n 'src/lib/helpers.sh' "$PROJECT_DIR/setup.sh" | head -1 | cut -d: -f1)
CORE_LINE=$(grep -n 'src/lib/00-core.sh' "$PROJECT_DIR/setup.sh" | head -1 | cut -d: -f1)
assert "helpers sourced before core" "[ '$HELPERS_LINE' -lt '$CORE_LINE' ]"

# ── setup.sh references all lib modules via _run_step ─────────────────
STEP_COUNT=$(grep -c '_run_step' "$PROJECT_DIR/setup.sh" 2>/dev/null || echo 0)
assert "setup.sh has _run_step calls" "[ '$STEP_COUNT' -ge 10 ]"

# Count actual lib module files
LIB_COUNT=$(ls "$PROJECT_DIR/src/lib/"*.sh 2>/dev/null | wc -l)
assert "lib has modules" "[ '$LIB_COUNT' -ge 20 ]"

# ── Module naming convention: NN-name.sh ──────────────────────────────
for f in "$PROJECT_DIR/src/lib/"*.sh; do
  fname=$(basename "$f")
  if [ "$fname" = "helpers.sh" ] || [ "$fname" = "pre-session-check.sh" ] || [ "$fname" = "version-check.sh" ]; then
    assert "$fname is helper (no number)" "true"
  else
    assert "$fname follows NN-name pattern" \
      "echo '$fname' | grep -qE '^[0-9]{2}-.*\.sh$'"
  fi
done

# ── All mode scripts are referenced in setup.sh ──────────────────────
for mode in "$PROJECT_DIR/src/modes/"*.sh; do
  mname=$(basename "$mode")
  assert "$mname referenced in setup.sh" \
    "grep -q '$mname' '$PROJECT_DIR/setup.sh'"
done

# ── dev.sh syntax and structure ──────────────────────────────────────
bash -n "$PROJECT_DIR/dev.sh" 2>/dev/null
assert "dev.sh syntax valid" "[ $? -eq 0 ]"
assert "dev.sh sources helpers.sh" "grep -q 'src/lib/helpers.sh' '$PROJECT_DIR/dev.sh'"
assert "dev.sh has usage function" "grep -q 'usage()' '$PROJECT_DIR/dev.sh'"

# ── All files have set -euo pipefail ──────────────────────────────────
for f in "$PROJECT_DIR/setup.sh" "$PROJECT_DIR/dev.sh" "$PROJECT_DIR/src/lib/"*.sh "$PROJECT_DIR/src/modes/"*.sh; do
  fname=$(basename "$f")
  assert "$fname has set -euo pipefail" "grep -q 'set -euo pipefail' '$f'"
done

# ── All files have shebang ────────────────────────────────────────────
for f in "$PROJECT_DIR/setup.sh" "$PROJECT_DIR/dev.sh" "$PROJECT_DIR/src/lib/"*.sh "$PROJECT_DIR/src/modes/"*.sh; do
  fname=$(basename "$f")
  assert "$fname has shebang" "head -1 '$f' | grep -q '#!/usr/bin/env bash' || head -1 '$f' | grep -q '#!/bin/bash'"
done

# ── setup.sh orchestrator line count ──────────────────────────────────
SETUP_LINES=$(wc -l < "$PROJECT_DIR/setup.sh")
assert "setup.sh is ~373 lines (+/- 20)" \
  "[ '$SETUP_LINES' -ge 353 ] && [ '$SETUP_LINES' -le 393 ]"

# ── Module count matches AGENTS.md description ────────────────────────
MODES_COUNT=$(ls "$PROJECT_DIR/src/modes/"*.sh 2>/dev/null | wc -l)
assert "5 mode scripts" "[ '$MODES_COUNT' -eq 5 ]"

echo
echo "=== test_modules.sh: $TESTS_PASS passed, $TESTS_FAIL failed ==="
[ "$TESTS_FAIL" -eq 0 ] || exit 1
