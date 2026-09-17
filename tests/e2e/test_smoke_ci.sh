#!/usr/bin/env bash
# tests/e2e/test_smoke_ci.sh — E2E smoke test for CI
# Runs setup.sh --dry-run --mode ci to verify the installer works
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

PASS=0
FAIL=0

pass() { PASS=$((PASS + 1)); echo -e "  \033[32m✓\033[0m $1"; }
fail() { FAIL=$((FAIL + 1)); echo -e "  \033[31m✗\033[0m $1"; }

echo "=== E2E Smoke Test: CI Mode ==="

# Test: setup.sh --dry-run --mode ci
echo ""
echo "--- Dry-Run CI Mode ---"

test_dry_run_ci() {
  local output
  local exit_code=0
  
  # Run dry-run CI mode
  output=$(timeout 120 bash "$PROJECT_ROOT/setup.sh" --dry-run --ci 2>&1) || exit_code=$?
  
  if [ "$exit_code" -eq 0 ]; then
    pass "dry-run CI mode completes successfully"
  else
    fail "dry-run CI mode failed with exit code $exit_code"
    echo "    Output: $output" | head -20
    return
  fi
  
  # Check that output contains expected sections
  if echo "$output" | grep -q "Dry Run\|DRY_RUN\|dry-run"; then
    pass "dry-run mode detected in output"
  else
    fail "dry-run mode not detected in output"
  fi
  
  # Check that no actual installation happened
  if echo "$output" | grep -q "Installing\|Downloading"; then
    fail "dry-run mode performed actual installation"
  else
    pass "dry-run mode did not perform installation"
  fi
}

test_dry_run_ci

# Test: setup.sh --help
echo ""
echo "--- Help Output ---"

test_help() {
  local output
  
  output=$(timeout 10 bash "$PROJECT_ROOT/setup.sh" --help 2>&1)
  
  if [ -n "$output" ]; then
    pass "help mode produces output"
  else
    fail "help mode produces no output"
  fi
  
  # Check that help contains expected sections
  if echo "$output" | grep -q "Usage\|Options\|Modes"; then
    pass "help contains usage information"
  else
    fail "help missing usage information"
  fi
}

test_help

# Test: dev.sh --help
echo ""
echo "--- Dev CLI Help ---"

test_dev_help() {
  local output
  
  output=$(timeout 10 bash "$PROJECT_ROOT/dev.sh" --help 2>&1)
  
  if [ -n "$output" ]; then
    pass "dev help produces output"
  else
    fail "dev help produces no output"
  fi
}

test_dev_help

# Summary
echo ""
echo "━━━ Results: $PASS passed, $FAIL failed ━━━"
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
