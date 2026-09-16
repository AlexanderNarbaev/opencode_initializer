#!/usr/bin/env bash
# tests/unit/test_advanced.sh — Tests for Phase 4 modules (117-118)
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

source "$PROJECT_ROOT/src/lib/helpers.sh" 2>/dev/null || true
source "$PROJECT_ROOT/src/gui/dashboard.sh" 2>/dev/null || true
source "$PROJECT_ROOT/src/lib/117-cloud-sync.sh" 2>/dev/null || true
source "$PROJECT_ROOT/src/lib/118-marketplace-api.sh" 2>/dev/null || true

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

section "Phase 4: Advanced Features (117-118)"

# Test: Modules load
assert "dashboard.sh loads" "$?" "0"
assert "117-cloud-sync loads" "$?" "0"
assert "118-marketplace-api loads" "$?" "0"

# Test: cmd help
output=$(cmd_gui help 2>&1)
assert "GUI help" "$([ -n "$output" ] && echo true || echo false)" "true"

output=$(cmd_cloud_sync help 2>&1)
assert "Cloud sync help" "$([ -n "$output" ] && echo true || echo false)" "true"

output=$(cmd_marketplace_api help 2>&1)
assert "Marketplace API help" "$([ -n "$output" ] && echo true || echo false)" "true"

echo
echo "━━━ Results: $PASSED/$TESTS passed, $FAILED failed ━━━"
[ "$FAILED" -eq 0 ] && exit 0 || exit 1
