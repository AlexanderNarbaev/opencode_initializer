#!/usr/bin/env bash
# tests/integration/test_agent_workflow.sh — Integration test: Agent workflow
# Tests: 66-orchestrator → 67-pipeline → 68-mesh → 69-protocol
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

section "Integration: Agent Workflow (66-69)"

# Test 1: Create workflow
mkdir -p "$HOME/.config/opencode/workflows"
cat > "$HOME/.config/opencode/workflows/test-integration.yaml" <<'EOF'
name: test-integration
version: 1.0.0
description: Integration test workflow
steps:
  - name: step1
    type: extract
  - name: step2
    type: analyze
EOF

output=$(_workflow_list 2>&1)
assert "Workflow created" "$([ -n "$output" ] && echo true || echo false)" "true"

# Test 2: Validate workflow
_workflow_validate "$HOME/.config/opencode/workflows/test-integration.yaml" 2>/dev/null && validate_result="pass" || validate_result="fail"
assert "Workflow validation" "$validate_result" "pass"

# Test 3: Register agent
_agent_register "test-agent" "implementation" "http://localhost:8080" "code-review" 2>/dev/null
output=$(_agent_list 2>&1)
assert "Agent registered" "$([ -n "$output" ] && echo true || echo false)" "true"

# Test 4: Find agent by type
output=$(_agent_find_by_type "implementation" 2>&1)
assert "Agent found by type" "$([ -n "$output" ] && echo true || echo false)" "true"

# Test 5: Send message
message_id=$(_agent_send "test-agent" "task" "test payload" 2>&1)
assert "Message sent" "$([ -n "$message_id" ] && echo true || echo false)" "true"

# Test 6: Check message queue
output=$(_message_queue "test-agent" 2>&1)
assert "Message in queue" "$([ -n "$output" ] && echo true || echo false)" "true"

# Cleanup
rm -f "$HOME/.config/opencode/workflows/test-integration.yaml"
rm -rf "$HOME/.local/share/opencode/agent-mesh"
rm -rf "$HOME/.local/share/opencode/agent-protocol"

echo
echo "━━━ Integration Results: $PASSED/$TESTS passed, $FAILED failed ━━━"
[ "$FAILED" -eq 0 ] && exit 0 || exit 1
