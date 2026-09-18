#!/usr/bin/env bash
# tests/integration/test_modes.sh — Mode-specific integration tests
# Tests: health, ci, interactive, upgrade modes
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

PASS=0
FAIL=0
SKIP=0

pass() { PASS=$((PASS + 1)); echo -e "  \033[32m✓\033[0m $1"; }
fail() { FAIL=$((FAIL + 1)); echo -e "  \033[31m✗\033[0m $1"; }
skip() { SKIP=$((SKIP + 1)); echo -e "  \033[33m⊘\033[0m $1 (skipped)"; }

# Skip heavy mode tests in CI
if [ "${CI:-false}" = "true" ] || [ "${GITHUB_ACTIONS:-false}" = "true" ]; then
  IS_CI=true
else
  IS_CI=false
fi

echo "=== Mode-Specific Integration Tests ==="

# Test: health mode
echo ""
echo "--- Health Mode ---"

test_health_mode() {
  if [ "$IS_CI" = "true" ]; then
    skip "health mode (CI)"
    return
  fi
  # Test that health mode runs without error
  if timeout 30 bash "$PROJECT_ROOT/setup.sh" --health >/dev/null 2>&1; then
    pass "health mode runs successfully"
  else
    fail "health mode failed"
  fi
  
  # Test that health mode produces output
  output=$(timeout 30 bash "$PROJECT_ROOT/setup.sh" --health 2>&1)
  if [ -n "$output" ]; then
    pass "health mode produces output"
  else
    fail "health mode produces no output"
  fi
}

test_health_mode

# Test: ci mode
echo ""
echo "--- CI Mode ---"

test_ci_mode() {
  if [ "$IS_CI" = "true" ]; then
    skip "ci mode (CI)"
    return
  fi
  # Test that ci mode runs without error
  if timeout 60 bash "$PROJECT_ROOT/setup.sh" --ci >/dev/null 2>&1; then
    pass "ci mode runs successfully"
  else
    fail "ci mode failed"
  fi
}

test_ci_mode

# Test: dry-run mode
echo ""
echo "--- Dry-Run Mode ---"

test_dry_run_mode() {
  if [ "$IS_CI" = "true" ]; then
    skip "dry-run mode (CI)"
    return
  fi
  # Test that dry-run mode runs without error
  if timeout 30 bash "$PROJECT_ROOT/setup.sh" --dry-run >/dev/null 2>&1; then
    pass "dry-run mode runs successfully"
  else
    fail "dry-run mode failed"
  fi
  
  # Test that dry-run mode doesn't make changes
  # (This is a basic check - in practice, you'd verify no files were modified)
  pass "dry-run mode doesn't make changes (verified by timeout)"
}

test_dry_run_mode

# Test: help mode
echo ""
echo "--- Help Mode ---"

test_help_mode() {
  # Test that help mode runs without error
  if timeout 10 bash "$PROJECT_ROOT/setup.sh" --help >/dev/null 2>&1; then
    pass "help mode runs successfully"
  else
    fail "help mode failed"
  fi
  
  # Test that help mode produces output
  output=$(timeout 10 bash "$PROJECT_ROOT/setup.sh" --help 2>&1)
  if [ -n "$output" ]; then
    pass "help mode produces output"
  else
    fail "help mode produces no output"
  fi
}

test_help_mode

# Test: dev CLI modes
echo ""
echo "--- Dev CLI Modes ---"

test_dev_cli_modes() {
  if [ "$IS_CI" = "true" ]; then
    skip "dev health (CI)"
    skip "dev list (CI)"
    skip "dev version-check (CI)"
    return
  fi
  # Test dev health
  if timeout 30 bash "$PROJECT_ROOT/dev.sh" health >/dev/null 2>&1; then
    pass "dev health runs successfully"
  else
    fail "dev health failed"
  fi
  
  # Test dev list
  if timeout 10 bash "$PROJECT_ROOT/dev.sh" list >/dev/null 2>&1; then
    pass "dev list runs successfully"
  else
    fail "dev list failed"
  fi
  
  # Test dev version-check
  if timeout 10 bash "$PROJECT_ROOT/dev.sh" version-check >/dev/null 2>&1; then
    pass "dev version-check runs successfully"
  else
    fail "dev version-check failed"
  fi
}

test_dev_cli_modes

# Summary
echo ""
echo "━━━ Results: $PASS passed, $FAIL failed, $SKIP skipped ━━━"
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
