#!/usr/bin/env bash
# Unit tests for scripts/audit-module-reachability.sh
# Covers: report mode, --json contract, --strict, --baseline (old vs new dead modules).
set -uo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
AUDIT="$PROJECT_DIR/scripts/audit-module-reachability.sh"
BASELINE="$PROJECT_DIR/src/data/dead-modules.baseline"

PASS=0; FAIL=0
pass() { echo "  PASS: $1"; PASS=$((PASS + 1)); }
fail() { echo "  FAIL: $1"; FAIL=$((FAIL + 1)); }

echo "=== Test 1: script exists and parses ==="
[ -f "$AUDIT" ] && pass "audit script exists" || fail "audit script missing"
bash -n "$AUDIT" 2>/dev/null && pass "audit script syntax" || fail "audit script syntax"

echo
echo "=== Test 2: JSON report contract ==="
json="$(bash "$AUDIT" --json 2>/dev/null)"
echo "$json" | jq empty 2>/dev/null && pass "output is valid JSON" || fail "output is not valid JSON"
total=$(echo "$json" | jq -r '.total // 0')
reachable=$(echo "$json" | jq -r '.reachable // 0')
dead=$(echo "$json" | jq -r '.dead // 0')
[ "$total" -gt 100 ] && pass "module total reported ($total)" || fail "implausible module total: $total"
[ "$reachable" -gt 0 ] && pass "reachable modules reported ($reachable)" || fail "no reachable modules"
[ $((reachable + dead)) -eq "$total" ] && pass "reachable + dead == total" || fail "reachable + dead != total"

echo
echo "=== Test 3: known modules land on the right side ==="
echo "$json" | jq -r '.dead_modules[]' | grep -qx '62-skill-registry.sh' \
  && pass "62-skill-registry.sh reported as dead" || fail "62-skill-registry.sh not reported dead"
echo "$json" | jq -r '.dead_modules[]' | grep -qx '00-core.sh' \
  && fail "00-core.sh wrongly reported dead" || pass "00-core.sh not in dead list"
echo "$json" | jq -r '.dead_modules[]' | grep -qx 'helpers.sh' \
  && fail "helpers.sh wrongly reported dead" || pass "helpers.sh not in dead list"

echo
echo "=== Test 4: baseline semantics ==="
[ -f "$BASELINE" ] && pass "baseline file exists" || fail "baseline file missing"
bash "$AUDIT" --baseline "$BASELINE" >/dev/null 2>&1
[ $? -eq 0 ] && pass "current baseline passes" || fail "current baseline should pass"
empty="$(mktemp)"; bash "$AUDIT" --baseline "$empty" >/dev/null 2>&1
[ $? -eq 1 ] && pass "empty baseline fails (new dead detected)" || fail "empty baseline should fail"
rm -f "$empty"

echo
echo "=== Test 5: --strict ==="
bash "$AUDIT" --strict >/dev/null 2>&1
rc=$?
if [ "$dead" -gt 0 ] && [ "$rc" -eq 1 ]; then pass "--strict fails while dead code exists"
elif [ "$dead" -eq 0 ] && [ "$rc" -eq 0 ]; then pass "--strict passes (no dead code)"
else fail "--strict returned $rc with dead=$dead"; fi

echo
echo "=========================================="
echo "RESULTS: $PASS pass, $FAIL fail"
echo "=========================================="
[ "$FAIL" -eq 0 ] || exit 1
