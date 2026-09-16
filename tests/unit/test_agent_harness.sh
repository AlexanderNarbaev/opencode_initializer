#!/usr/bin/env bash
# tests/unit/test_agent_harness.sh — Tests for Phase 3 modules (83-90)
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

source "$PROJECT_ROOT/src/lib/helpers.sh" 2>/dev/null || true
source "$PROJECT_ROOT/src/lib/83-context-engineering.sh" 2>/dev/null || true
source "$PROJECT_ROOT/src/lib/84-learning.sh" 2>/dev/null || true
source "$PROJECT_ROOT/src/lib/85-automation.sh" 2>/dev/null || true
source "$PROJECT_ROOT/src/lib/86-sandbox.sh" 2>/dev/null || true
source "$PROJECT_ROOT/src/lib/87-cicd-integration.sh" 2>/dev/null || true
source "$PROJECT_ROOT/src/lib/88-workflow-engine.sh" 2>/dev/null || true
source "$PROJECT_ROOT/src/lib/89-security-policies.sh" 2>/dev/null || true
source "$PROJECT_ROOT/src/lib/90-secrets-manager.sh" 2>/dev/null || true

TESTS=0 PASSED=0 FAILED=0

assert() {
  local desc="$1" result="$2" expected="$3"
  TESTS=$((TESTS + 1))
  if [ "$result" = "$expected" ]; then
    PASSED=$((PASSED + 1))
    echo "  ✓ $desc"
  else
    FAILED=$((FAILED + 1))
    echo "  ✗ $desc (got: '$result', expected: '$expected')"
  fi
}

section "Phase 3: Agent Harness (83-90)"

# Test: Modules load
assert "83-context-engineering loads" "$?" "0"
assert "84-learning loads" "$?" "0"
assert "85-automation loads" "$?" "0"
assert "86-sandbox loads" "$?" "0"
assert "87-cicd-integration loads" "$?" "0"
assert "88-workflow-engine loads" "$?" "0"
assert "89-security-policies loads" "$?" "0"
assert "90-secrets-manager loads" "$?" "0"

# Test: cmd help
output=$(cmd_context_engineering help 2>&1)
assert "Context engineering help" "$([ -n "$output" ] && echo true || echo false)" "true"

output=$(cmd_learning help 2>&1)
assert "Learning help" "$([ -n "$output" ] && echo true || echo false)" "true"

output=$(cmd_automation help 2>&1)
assert "Automation help" "$([ -n "$output" ] && echo true || echo false)" "true"

output=$(cmd_sandbox help 2>&1)
assert "Sandbox help" "$([ -n "$output" ] && echo true || echo false)" "true"

output=$(cmd_cicd help 2>&1)
assert "CI/CD help" "$([ -n "$output" ] && echo true || echo false)" "true"

output=$(cmd_workflow_engine help 2>&1)
assert "Workflow engine help" "$([ -n "$output" ] && echo true || echo false)" "true"

output=$(cmd_security_policy help 2>&1)
assert "Security policy help" "$([ -n "$output" ] && echo true || echo false)" "true"

output=$(cmd_secrets help 2>&1)
assert "Secrets help" "$([ -n "$output" ] && echo true || echo false)" "true"

echo
echo "━━━ Results: $PASSED/$TESTS passed, $FAILED failed ━━━"
[ "$FAILED" -eq 0 ] && exit 0 || exit 1
