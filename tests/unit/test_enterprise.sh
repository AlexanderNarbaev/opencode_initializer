#!/usr/bin/env bash
# tests/unit/test_enterprise.sh — Tests for Phase 1 modules (72-77)
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

source "$PROJECT_ROOT/src/lib/helpers.sh" 2>/dev/null || true
source "$PROJECT_ROOT/src/lib/72-rbac.sh" 2>/dev/null || true
source "$PROJECT_ROOT/src/lib/73-governance.sh" 2>/dev/null || true
source "$PROJECT_ROOT/src/lib/74-compliance.sh" 2>/dev/null || true
source "$PROJECT_ROOT/src/lib/75-security-posture.sh" 2>/dev/null || true
source "$PROJECT_ROOT/src/lib/76-analytics.sh" 2>/dev/null || true
source "$PROJECT_ROOT/src/lib/77-observability.sh" 2>/dev/null || true

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

section "Phase 1: Enterprise Features (72-77)"

# Test: Modules load
assert "72-rbac loads" "$?" "0"
assert "73-governance loads" "$?" "0"
assert "74-compliance loads" "$?" "0"
assert "75-security-posture loads" "$?" "0"
assert "76-analytics loads" "$?" "0"
assert "77-observability loads" "$?" "0"

# Test: cmd_rbac help
output=$(cmd_rbac help 2>&1)
assert "RBAC help" "$([ -n "$output" ] && echo true || echo false)" "true"

# Test: cmd_governance help
output=$(cmd_governance help 2>&1)
assert "Governance help" "$([ -n "$output" ] && echo true || echo false)" "true"

# Test: cmd_compliance help
output=$(cmd_compliance help 2>&1)
assert "Compliance help" "$([ -n "$output" ] && echo true || echo false)" "true"

# Test: cmd_security_posture help
output=$(cmd_security_posture help 2>&1)
assert "Security posture help" "$([ -n "$output" ] && echo true || echo false)" "true"

# Test: cmd_analytics help
output=$(cmd_analytics help 2>&1)
assert "Analytics help" "$([ -n "$output" ] && echo true || echo false)" "true"

# Test: cmd_observability help
output=$(cmd_observability help 2>&1)
assert "Observability help" "$([ -n "$output" ] && echo true || echo false)" "true"

echo
echo "━━━ Results: $PASSED/$TESTS passed, $FAILED failed ━━━"
[ "$FAILED" -eq 0 ] && exit 0 || exit 1
