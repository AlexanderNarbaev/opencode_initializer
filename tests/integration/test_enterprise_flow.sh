#!/usr/bin/env bash
# tests/integration/test_enterprise_flow.sh — Integration test: Enterprise flow
# Tests: 72-rbac → 73-governance → 74-compliance → 75-security → 76-analytics → 77-observability
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

section "Integration: Enterprise Flow (72-77)"

# Test 1: Initialize RBAC
_rbac_init 2>/dev/null
[ -f "$HOME/.config/opencode/rbac/roles.json" ] && rbac_init="pass" || rbac_init="fail"
assert "RBAC initialized" "$rbac_init" "pass"

# Test 2: List roles
output=$(_rbac_list_roles 2>&1)
assert "Roles listed" "$([ -n "$output" ] && echo true || echo false)" "true"

# Test 3: Check permission
result=$(_rbac_check_permission "admin" "*" 2>&1)
assert "Admin has all permissions" "$result" "true"

# Test 4: Initialize governance
_governance_init 2>/dev/null
[ -f "$HOME/.config/opencode/governance/rules.json" ] && gov_init="pass" || gov_init="fail"
assert "Governance initialized" "$gov_init" "pass"

# Test 5: List governance rules
output=$(_governance_list_rules 2>&1)
assert "Governance rules listed" "$([ -n "$output" ] && echo true || echo false)" "true"

# Test 6: Audit logging
_governance_audit "test" "user" "action" "resource" "success" 2>/dev/null
[ -f "$HOME/.config/opencode/governance/audit.jsonl" ] && audit_log="pass" || audit_log="fail"
assert "Audit logging works" "$audit_log" "pass"

# Test 7: Compliance score
score=$(_compliance_score "soc2" 2>&1)
assert "Compliance score calculated" "$([ -n "$score" ] && echo true || echo false)" "true"

# Test 8: Track analytics event
_analytics_track "test" "integration" "key=value" 2>/dev/null
[ -f "$HOME/.local/share/opencode/analytics/events.jsonl" ] && analytics_track="pass" || analytics_track="fail"
assert "Analytics tracking works" "$analytics_track" "pass"

# Test 9: Initialize observability
_observability_init 2>/dev/null
[ -f "$HOME/.config/opencode/observability/metrics.json" ] && obs_init="pass" || obs_init="fail"
assert "Observability initialized" "$obs_init" "pass"

# Test 10: Set and get metric
_observability_metric_set "test_metric" 42 2>/dev/null
result=$(_observability_metric_get "test_metric" 2>&1)
assert "Metric set and retrieved" "$result" "42"

# Cleanup
rm -rf "$HOME/.config/opencode/rbac"
rm -rf "$HOME/.config/opencode/governance"
rm -rf "$HOME/.config/opencode/compliance"
rm -rf "$HOME/.local/share/opencode/analytics"
rm -rf "$HOME/.config/opencode/observability"

echo
echo "━━━ Integration Results: $PASSED/$TESTS passed, $FAILED failed ━━━"
[ "$FAILED" -eq 0 ] && exit 0 || exit 1
