#!/usr/bin/env bash
# tests/unit/test_v44_features.sh — Tests for v4.4.0 features
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TESTS_PASSED=0
TESTS_FAILED=0
TESTS_TOTAL=0

_green() { echo -e "\033[0;32m$1\033[0m"; }
_red()   { echo -e "\033[0;31m$1\033[0m"; }

assert_eq() {
  local desc="$1" expected="$2" actual="$3"
  TESTS_TOTAL=$((TESTS_TOTAL + 1))
  if [ "$expected" = "$actual" ]; then
    _green "  ✓ $desc"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    _red "  ✗ $desc — expected '$expected', got '$actual'"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi
}

assert_true() {
  local desc="$1" result="$2"
  TESTS_TOTAL=$((TESTS_TOTAL + 1))
  if [ "$result" = "0" ]; then
    _green "  ✓ $desc"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    _red "  ✗ $desc — expected success, got $result"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi
}

assert_file_exists() {
  local desc="$1" file="$2"
  TESTS_TOTAL=$((TESTS_TOTAL + 1))
  if [ -f "$file" ]; then
    _green "  ✓ $desc"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    _red "  ✗ $desc — file not found: $file"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi
}

echo "=== test_v44_features.sh ==="

# ── Test 1: Module files exist ──────────────────────────────────────────────
echo "Test 1: Module file structure"
assert_file_exists "00m-plugin-discovery.sh exists" "$SCRIPT_DIR/src/lib/00m-plugin-discovery.sh"
assert_file_exists "00n-context-mgr.sh exists" "$SCRIPT_DIR/src/lib/00n-context-mgr.sh"
assert_file_exists "00o-workflow.sh exists" "$SCRIPT_DIR/src/lib/00o-workflow.sh"

# ── Test 2: Plugin discovery functions ──────────────────────────────────────
echo "Test 2: Plugin discovery functions"
(
  source "$SCRIPT_DIR/src/lib/helpers.sh"
  source "$SCRIPT_DIR/src/lib/00-core.sh"
  source "$SCRIPT_DIR/src/lib/00m-plugin-discovery.sh"

  assert_true "_discover_npm_plugins defined" "$(type -t _discover_npm_plugins &>/dev/null && echo 0 || echo 1)"
  assert_true "_discover_github_plugins defined" "$(type -t _discover_github_plugins &>/dev/null && echo 0 || echo 1)"
  assert_true "_update_plugin_registry defined" "$(type -t _update_plugin_registry &>/dev/null && echo 0 || echo 1)"
  assert_true "_install_recommended_plugins defined" "$(type -t _install_recommended_plugins &>/dev/null && echo 0 || echo 1)"
  assert_true "_plugin_health_check defined" "$(type -t _plugin_health_check &>/dev/null && echo 0 || echo 1)"
)

# ── Test 3: Context manager functions ───────────────────────────────────────
echo "Test 3: Context manager functions"
(
  source "$SCRIPT_DIR/src/lib/helpers.sh"
  source "$SCRIPT_DIR/src/lib/00-core.sh"
  source "$SCRIPT_DIR/src/lib/00n-context-mgr.sh"

  assert_true "_context_init defined" "$(type -t _context_init &>/dev/null && echo 0 || echo 1)"
  assert_true "_get_context_limit defined" "$(type -t _get_context_limit &>/dev/null && echo 0 || echo 1)"
  assert_true "_count_tokens defined" "$(type -t _count_tokens &>/dev/null && echo 0 || echo 1)"
  assert_true "_context_add defined" "$(type -t _context_add &>/dev/null && echo 0 || echo 1)"
  assert_true "_context_trim defined" "$(type -t _context_trim &>/dev/null && echo 0 || echo 1)"
  assert_true "_context_stats defined" "$(type -t _context_stats &>/dev/null && echo 0 || echo 1)"
  assert_true "_context_clear defined" "$(type -t _context_clear &>/dev/null && echo 0 || echo 1)"
)

# ── Test 4: Workflow functions ──────────────────────────────────────────────
echo "Test 4: Workflow functions"
(
  source "$SCRIPT_DIR/src/lib/helpers.sh"
  source "$SCRIPT_DIR/src/lib/00-core.sh"
  source "$SCRIPT_DIR/src/lib/00o-workflow.sh"

  assert_true "_workflow_init defined" "$(type -t _workflow_init &>/dev/null && echo 0 || echo 1)"
  assert_true "_workflow_run defined" "$(type -t _workflow_run &>/dev/null && echo 0 || echo 1)"
  assert_true "_workflow_setup defined" "$(type -t _workflow_setup &>/dev/null && echo 0 || echo 1)"
  assert_true "_workflow_update defined" "$(type -t _workflow_update &>/dev/null && echo 0 || echo 1)"
  assert_true "_workflow_security defined" "$(type -t _workflow_security &>/dev/null && echo 0 || echo 1)"
  assert_true "_workflow_optimize defined" "$(type -t _workflow_optimize &>/dev/null && echo 0 || echo 1)"
  assert_true "_workflow_deploy defined" "$(type -t _workflow_deploy &>/dev/null && echo 0 || echo 1)"
  assert_true "_workflow_list defined" "$(type -t _workflow_list &>/dev/null && echo 0 || echo 1)"
)

# ── Test 5: Context token counting ──────────────────────────────────────────
echo "Test 5: Token counting"
(
  source "$SCRIPT_DIR/src/lib/helpers.sh"
  source "$SCRIPT_DIR/src/lib/00-core.sh"
  source "$SCRIPT_DIR/src/lib/00n-context-mgr.sh"

  # Test token counting
  tokens=$(_count_tokens "Hello world")
  assert_eq "Simple text tokens" "2" "$tokens"

  tokens=$(_count_tokens "This is a longer test message with more words")
  assert_eq "Longer text tokens" "10" "$tokens"
)

# ── Test 6: Context limits ──────────────────────────────────────────────────
echo "Test 6: Context limits"
(
  source "$SCRIPT_DIR/src/lib/helpers.sh"
  source "$SCRIPT_DIR/src/lib/00-core.sh"
  source "$SCRIPT_DIR/src/lib/00n-context-mgr.sh"

  limit=$(_get_context_limit "gpt-4o")
  assert_eq "GPT-4o limit" "128000" "$limit"

  limit=$(_get_context_limit "claude-3.5-sonnet")
  assert_eq "Claude limit" "200000" "$limit"

  limit=$(_get_context_limit "gemini-1.5-pro")
  assert_eq "Gemini limit" "1000000" "$limit"
)

# ── Test 7: Context initialization ──────────────────────────────────────────
echo "Test 7: Context initialization"
(
  source "$SCRIPT_DIR/src/lib/helpers.sh"
  source "$SCRIPT_DIR/src/lib/00-core.sh"
  source "$SCRIPT_DIR/src/lib/00n-context-mgr.sh"

  export DL_CACHE=$(mktemp -d)
  _CONTEXT_DIR="$DL_CACHE/context"
  _CONTEXT_HISTORY="$_CONTEXT_DIR/history.jsonl"
  _CONTEXT_BUDGET="$_CONTEXT_DIR/budget.json"

  _context_init

  assert_file_exists "Budget file created" "$_CONTEXT_BUDGET"

  # Verify JSON is valid
  if python3 -c "import json; json.load(open('$_CONTEXT_BUDGET'))" 2>/dev/null; then
    _green "  ✓ Budget file is valid JSON"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    _red "  ✗ Budget file is not valid JSON"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi
  TESTS_TOTAL=$((TESTS_TOTAL + 1))

  rm -rf "$DL_CACHE"
)

# ── Test 8: Workflow registry ───────────────────────────────────────────────
echo "Test 8: Workflow registry"
(
  source "$SCRIPT_DIR/src/lib/helpers.sh"
  source "$SCRIPT_DIR/src/lib/00-core.sh"
  source "$SCRIPT_DIR/src/lib/00o-workflow.sh"

  export DL_CACHE=$(mktemp -d)
  _WORKFLOW_DIR="$DL_CACHE/workflows"
  _WORKFLOW_REGISTRY="$_WORKFLOW_DIR/registry.json"

  _workflow_init

  assert_file_exists "Registry created" "$_WORKFLOW_REGISTRY"

  # Verify JSON is valid
  if python3 -c "import json; json.load(open('$_WORKFLOW_REGISTRY'))" 2>/dev/null; then
    _green "  ✓ Registry is valid JSON"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    _red "  ✗ Registry is not valid JSON"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi
  TESTS_TOTAL=$((TESTS_TOTAL + 1))

  rm -rf "$DL_CACHE"
)

# ── Test 9: Plugin health check ─────────────────────────────────────────────
echo "Test 9: Plugin health check"
(
  source "$SCRIPT_DIR/src/lib/helpers.sh"
  source "$SCRIPT_DIR/src/lib/00-core.sh"
  source "$SCRIPT_DIR/src/lib/00m-plugin-discovery.sh"

  # This test just verifies the function runs without error
  result=0
  _plugin_health_check 2>/dev/null || result=$?
  assert_true "Plugin health check runs" "$result"
)

# ── Test 10: Workflow list ──────────────────────────────────────────────────
echo "Test 10: Workflow list"
(
  source "$SCRIPT_DIR/src/lib/helpers.sh"
  source "$SCRIPT_DIR/src/lib/00-core.sh"
  source "$SCRIPT_DIR/src/lib/00o-workflow.sh"

  export DL_CACHE=$(mktemp -d)
  _WORKFLOW_DIR="$DL_CACHE/workflows"
  _WORKFLOW_REGISTRY="$_WORKFLOW_DIR/registry.json"

  result=0
  _workflow_list 2>/dev/null || result=$?
  assert_true "Workflow list runs" "$result"

  rm -rf "$DL_CACHE"
)

# ── Summary ─────────────────────────────────────────────────────────────────
echo ""
echo "=== Summary ==="
echo "Total:  $TESTS_TOTAL"
_green "Passed: $TESTS_PASSED"
if [ "$TESTS_FAILED" -gt 0 ]; then
  _red "Failed: $TESTS_FAILED"
  exit 1
else
  echo "Failed: 0"
  exit 0
fi
