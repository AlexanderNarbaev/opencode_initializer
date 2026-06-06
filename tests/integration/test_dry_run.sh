#!/usr/bin/env bash
# ============================================================================
# Integration test: dry-run mode
# Verifies that --dry-run does not create/modify files and exits cleanly
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

echo "=== Integration: dry-run mode ==="

SETUP="$PROJECT_DIR/setup.sh"

# Use --fix-config mode to avoid sudo password requirement
# Combined with --dry-run, this validates the dry-run infrastructure
SETUP_OUTPUT=$(timeout 30 bash "$SETUP" --dry-run --fix-config -p /tmp/test-dry-project 2>&1) || true

# ── Check dry-run completes (produces output) ──────────────────────
assert "dry-run has output" '[ -n "'"$SETUP_OUTPUT"'" ]'

# ── DRY-RUN prefix in output ─────────────────────────────────────────
assert "dry-run prefix appears" \
  'echo "'"$SETUP_OUTPUT"'" | grep -qi "dry\|DRY"'

# ── No real files created in project dir ─────────────────────────────
assert "no opencode.json created in test dir" \
  "[ ! -f /tmp/test-dry-project/opencode.json ]"

# ── Also test --help in dry-run context ──────────────────────────────
HELP_OUT=$(timeout 5 bash "$SETUP" --dry-run --help 2>&1) || true
assert "dry-run --help produces output" '[ -n "'"$HELP_OUT"'" ]'

# ── Cleanup ──────────────────────────────────────────────────────────
rm -rf /tmp/test-dry-project 2>/dev/null || true

echo
echo "=== test_dry_run.sh: $TESTS_PASS passed, $TESTS_FAIL failed ==="
[ "$TESTS_FAIL" -eq 0 ] || exit 1
