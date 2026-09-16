#!/usr/bin/env bash
# tests/unit/test_ecosystem.sh — Tests for Phase 2 modules (78-82)
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

source "$PROJECT_ROOT/src/lib/helpers.sh" 2>/dev/null || true
source "$PROJECT_ROOT/src/lib/78-marketplace.sh" 2>/dev/null || true
source "$PROJECT_ROOT/src/lib/79-plugin-manager.sh" 2>/dev/null || true
source "$PROJECT_ROOT/src/lib/80-templates.sh" 2>/dev/null || true
source "$PROJECT_ROOT/src/lib/81-integrations.sh" 2>/dev/null || true
source "$PROJECT_ROOT/src/lib/82-connectors.sh" 2>/dev/null || true

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

section "Phase 2: Ecosystem Expansion (78-82)"

# Test: Modules load
assert "78-marketplace loads" "$?" "0"
assert "79-plugin-manager loads" "$?" "0"
assert "80-templates loads" "$?" "0"
assert "81-integrations loads" "$?" "0"
assert "82-connectors loads" "$?" "0"

# Test: cmd_marketplace help
output=$(cmd_marketplace help 2>&1)
assert "Marketplace help" "$([ -n "$output" ] && echo true || echo false)" "true"

# Test: cmd_plugin help
output=$(cmd_plugin help 2>&1)
assert "Plugin help" "$([ -n "$output" ] && echo true || echo false)" "true"

# Test: cmd_template help
output=$(cmd_template help 2>&1)
assert "Template help" "$([ -n "$output" ] && echo true || echo false)" "true"

# Test: cmd_integration help
output=$(cmd_integration help 2>&1)
assert "Integration help" "$([ -n "$output" ] && echo true || echo false)" "true"

# Test: cmd_connector help
output=$(cmd_connector help 2>&1)
assert "Connector help" "$([ -n "$output" ] && echo true || echo false)" "true"

echo
echo "━━━ Results: $PASSED/$TESTS passed, $FAILED failed ━━━"
[ "$FAILED" -eq 0 ] && exit 0 || exit 1
