#!/usr/bin/env bash
# ISOLATED Unit Test for .github/workflows/security.yml - T2.1 advisory job
# Target: .github/workflows/security.yml | Session: ses_T21_advisory
# WARNING: THIS FILE WILL BE DELETED AFTER TEST PASSES
set -euo pipefail
TARGET=".github/workflows/security.yml"
PASS=0; FAIL=0
assert() {
  local desc="$1" condition="$2"
  if (eval "$condition") &>/dev/null; then PASS=$((PASS+1)); echo "  PASS: $desc"
  else FAIL=$((FAIL+1)); echo "  FAIL: $desc" >&2; fi
}
echo "=== T2.1: Trivy CI advisory job test ==="
assert "file exists" "[ -f '$TARGET' ]"
assert "has trivy job" "grep -q 'trivy:' '$TARGET'"
assert "main exit-code is '1'" "grep -q \"exit-code: '1'\" '$TARGET'"
assert "has trivy-advisory job" "grep -q 'trivy-advisory:' '$TARGET'"
# Count trivy-advisory: lines below until next top-level key
assert "advisory exit-code '0'" "grep -A15 'trivy-advisory:' '$TARGET' | grep -q \"exit-code: '0'\""
assert "advisory continue-on-error true" "grep -A15 'trivy-advisory:' '$TARGET' | grep -q 'continue-on-error: true'"
assert "advisory severity CRITICAL,HIGH" "grep -A15 'trivy-advisory:' '$TARGET' | grep -q \"severity: 'CRITICAL,HIGH'\""
assert "advisory scan-type fs" "grep -A15 'trivy-advisory:' '$TARGET' | grep -q \"scan-type: 'fs'\""
assert "advisory ignore-unfixed true" "grep -A15 'trivy-advisory:' '$TARGET' | grep -q 'ignore-unfixed: true'"
assert "two separate jobs exist" "test \$(grep -c 'trivy-action@master' '$TARGET') -eq 2"
echo "=== Results: $PASS PASS, $FAIL FAIL ==="
[ "$FAIL" -eq 0 ] || { echo "TESTS FAILED"; exit 1; }
echo "ALL TESTS PASSED"
