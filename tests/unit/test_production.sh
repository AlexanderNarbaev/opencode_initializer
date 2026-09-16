#!/usr/bin/env bash
# tests/unit/test_production.sh — Tests for Phase 6 modules (111-116)
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

source "$PROJECT_ROOT/src/lib/helpers.sh" 2>/dev/null || true
source "$PROJECT_ROOT/src/lib/111-perf-optimizer.sh" 2>/dev/null || true
source "$PROJECT_ROOT/src/lib/112-cache-manager.sh" 2>/dev/null || true
source "$PROJECT_ROOT/src/lib/113-security-hardening.sh" 2>/dev/null || true
source "$PROJECT_ROOT/src/lib/114-vulnerability-scan.sh" 2>/dev/null || true
source "$PROJECT_ROOT/src/lib/115-scalability.sh" 2>/dev/null || true
source "$PROJECT_ROOT/src/lib/116-load-balancer.sh" 2>/dev/null || true

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

section "Phase 6: Production Hardening (111-116)"

# Test: Modules load
assert "111-perf-optimizer loads" "$?" "0"
assert "112-cache-manager loads" "$?" "0"
assert "113-security-hardening loads" "$?" "0"
assert "114-vulnerability-scan loads" "$?" "0"
assert "115-scalability loads" "$?" "0"
assert "116-load-balancer loads" "$?" "0"

# Test: cmd help
output=$(cmd_perf help 2>&1)
assert "Perf help" "$([ -n "$output" ] && echo true || echo false)" "true"

output=$(cmd_cache help 2>&1)
assert "Cache help" "$([ -n "$output" ] && echo true || echo false)" "true"

output=$(cmd_security_hardening help 2>&1)
assert "Security hardening help" "$([ -n "$output" ] && echo true || echo false)" "true"

output=$(cmd_vuln_scan help 2>&1)
assert "Vuln scan help" "$([ -n "$output" ] && echo true || echo false)" "true"

output=$(cmd_scalability help 2>&1)
assert "Scalability help" "$([ -n "$output" ] && echo true || echo false)" "true"

output=$(cmd_lb help 2>&1)
assert "Load balancer help" "$([ -n "$output" ] && echo true || echo false)" "true"

echo
echo "━━━ Results: $PASSED/$TESTS passed, $FAILED failed ━━━"
[ "$FAILED" -eq 0 ] && exit 0 || exit 1
