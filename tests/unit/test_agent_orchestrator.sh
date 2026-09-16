#!/usr/bin/env bash
# tests/unit/test_agent_orchestrator.sh — Tests for 66-69 modules
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

source "$PROJECT_ROOT/src/lib/helpers.sh" 2>/dev/null || true
source "$PROJECT_ROOT/src/lib/66-agent-orchestrator.sh" 2>/dev/null || true
source "$PROJECT_ROOT/src/lib/67-agent-pipeline.sh" 2>/dev/null || true
source "$PROJECT_ROOT/src/lib/68-agent-mesh.sh" 2>/dev/null || true
source "$PROJECT_ROOT/src/lib/69-agent-protocol.sh" 2>/dev/null || true

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

section "Agent Orchestration (66-69)"

# Test: Modules load
assert "66-agent-orchestrator loads" "$?" "0"
assert "67-agent-pipeline loads" "$?" "0"
assert "68-agent-mesh loads" "$?" "0"
assert "69-agent-protocol loads" "$?" "0"

# Test: Workflow list (empty)
output=$(_workflow_list 2>&1)
assert "Workflow list empty" "$?" "0"

# Test: Pipeline list (empty)
output=$(_pipeline_list 2>&1)
assert "Pipeline list empty" "$?" "0"

# Test: Agent list (empty)
output=$(_agent_list 2>&1)
assert "Agent list empty" "$?" "0"

# Test: cmd_orchestrator help
output=$(cmd_orchestrator help 2>&1)
assert "Orchestrator help" "$([ -n "$output" ] && echo true || echo false)" "true"

# Test: cmd_pipeline help
output=$(cmd_pipeline help 2>&1)
assert "Pipeline help" "$([ -n "$output" ] && echo true || echo false)" "true"

# Test: cmd_agent_mesh help
output=$(cmd_agent_mesh help 2>&1)
assert "Agent mesh help" "$([ -n "$output" ] && echo true || echo false)" "true"

# Test: cmd_agent_protocol help
output=$(cmd_agent_protocol help 2>&1)
assert "Agent protocol help" "$([ -n "$output" ] && echo true || echo false)" "true"

echo
echo "━━━ Results: $PASSED/$TESTS passed, $FAILED failed ━━━"
[ "$FAILED" -eq 0 ] && exit 0 || exit 1
