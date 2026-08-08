#!/usr/bin/env bash
# ISOLATED Unit Test for setup.sh — T1.3: -s/--sudo-pass deprecation
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
PASS=0; FAIL=0

check() { local d="$1"; shift; if "$@"; then PASS=$((PASS+1)); else FAIL=$((FAIL+1)); echo "    FAIL: $d" >&2; fi; }

echo "=== T1.3: -s/--sudo-pass deprecation warning tests ==="

# syntax check first
check "setup.sh syntax OK" bash -n "$PROJECT_DIR/setup.sh"

# --help contains DEPRECATED marker
H=$(bash "$PROJECT_DIR/setup.sh" -h 2>&1 || true)
check "--help marks -s as deprecated"  grep -qF '[DEPRECATED]' <<< "$H"
check "--help recommends SUDO_PASS"    grep -q 'SUDO_PASS' <<< "$H"
check "--help recommends read -s"      grep -q 'read -s' <<< "$H"

# -s emits runtime deprecation
W=$(bash "$PROJECT_DIR/setup.sh" --ci -s "test" 2>&1 || true)
check "-s emits deprecation warning"   grep -qi 'deprecated' <<< "$W"

# --sudo-pass emits runtime deprecation
W2=$(bash "$PROJECT_DIR/setup.sh" --ci --sudo-pass "test" 2>&1 || true)
check "--sudo-pass emits deprecation"  grep -qi 'deprecated' <<< "$W2"

# SUDO_PASS env: NO deprecation warning
E=$(SUDO_PASS="test_env" bash "$PROJECT_DIR/setup.sh" --ci 2>&1 || true)
check "SUDO_PASS env NO deprecation"  ! grep -qi 'deprecated' <<< "$E"

# No -s flag: NO deprecation warning
N=$(bash "$PROJECT_DIR/setup.sh" --ci 2>&1 || true)
check "no -s flag no deprecation"     ! grep -qi 'deprecated' <<< "$N"

echo "  PASS: $PASS  FAIL: $FAIL"
[ "$FAIL" -gt 0 ] && { echo "TESTS FAILED: $FAIL"; exit 1; }
echo "All tests passed!"
exit 0
