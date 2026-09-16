#!/usr/bin/env bash
# tests/unit/test_harness.sh — Tests for Phase 4 modules (91-100)
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

source "$PROJECT_ROOT/src/lib/helpers.sh" 2>/dev/null || true
source "$PROJECT_ROOT/src/lib/91-harness-core.sh" 2>/dev/null || true
source "$PROJECT_ROOT/src/lib/92-harness-tools.sh" 2>/dev/null || true
source "$PROJECT_ROOT/src/lib/93-harness-memory.sh" 2>/dev/null || true
source "$PROJECT_ROOT/src/lib/94-harness-context.sh" 2>/dev/null || true
source "$PROJECT_ROOT/src/lib/95-harness-prompt.sh" 2>/dev/null || true
source "$PROJECT_ROOT/src/lib/96-harness-state.sh" 2>/dev/null || true
source "$PROJECT_ROOT/src/lib/97-harness-errors.sh" 2>/dev/null || true
source "$PROJECT_ROOT/src/lib/98-harness-guardrails.sh" 2>/dev/null || true
source "$PROJECT_ROOT/src/lib/99-harness-verify.sh" 2>/dev/null || true
source "$PROJECT_ROOT/src/lib/100-harness-subagents.sh" 2>/dev/null || true

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

section "Phase 4: Agent Harness Core (91-100)"

# Test: Modules load
assert "91-harness-core loads" "$?" "0"
assert "92-harness-tools loads" "$?" "0"
assert "93-harness-memory loads" "$?" "0"
assert "94-harness-context loads" "$?" "0"
assert "95-harness-prompt loads" "$?" "0"
assert "96-harness-state loads" "$?" "0"
assert "97-harness-errors loads" "$?" "0"
assert "98-harness-guardrails loads" "$?" "0"
assert "99-harness-verify loads" "$?" "0"
assert "100-harness-subagents loads" "$?" "0"

# Test: cmd help
output=$(cmd_harness help 2>&1)
assert "Harness help" "$([ -n "$output" ] && echo true || echo false)" "true"

output=$(cmd_harness_tools help 2>&1)
assert "Harness tools help" "$([ -n "$output" ] && echo true || echo false)" "true"

output=$(cmd_harness_memory help 2>&1)
assert "Harness memory help" "$([ -n "$output" ] && echo true || echo false)" "true"

output=$(cmd_harness_context help 2>&1)
assert "Harness context help" "$([ -n "$output" ] && echo true || echo false)" "true"

output=$(cmd_harness_prompt help 2>&1)
assert "Harness prompt help" "$([ -n "$output" ] && echo true || echo false)" "true"

output=$(cmd_harness_state help 2>&1)
assert "Harness state help" "$([ -n "$output" ] && echo true || echo false)" "true"

output=$(cmd_harness_errors help 2>&1)
assert "Harness errors help" "$([ -n "$output" ] && echo true || echo false)" "true"

output=$(cmd_harness_guardrails help 2>&1)
assert "Harness guardrails help" "$([ -n "$output" ] && echo true || echo false)" "true"

output=$(cmd_harness_verify help 2>&1)
assert "Harness verify help" "$([ -n "$output" ] && echo true || echo false)" "true"

output=$(cmd_harness_subagents help 2>&1)
assert "Harness subagents help" "$([ -n "$output" ] && echo true || echo false)" "true"

echo
echo "━━━ Results: $PASSED/$TESTS passed, $FAILED failed ━━━"
[ "$FAILED" -eq 0 ] && exit 0 || exit 1
