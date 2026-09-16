#!/usr/bin/env bash
# tests/unit/test_security_scan.sh — Tests for security scanning module
set -uo pipefail

PASS=0; FAIL=0; TOTAL=0
_script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

# shellcheck source=/dev/null
source "$_script_dir/src/lib/helpers.sh" 2>/dev/null || true
# shellcheck source=/dev/null
source "$_script_dir/src/lib/00-core.sh" 2>/dev/null || true
# shellcheck source=/dev/null
source "$_script_dir/src/lib/00k-security-scan.sh" 2>/dev/null || true

assert_eq() {
  TOTAL=$((TOTAL + 1))
  local desc="$1" expected="$2" actual="$3"
  if [ "$expected" = "$actual" ]; then
    PASS=$((PASS + 1))
    printf "  ${GREEN}✓${NC} %s\n" "$desc"
  else
    FAIL=$((FAIL + 1))
    printf "  ${RED}✗${NC} %s\n  expected: %s\n  actual:   %s\n" "$desc" "$expected" "$actual"
  fi
}

assert_exit() {
  TOTAL=$((TOTAL + 1))
  local desc="$1" expected="$2" cmd="$3"
  local actual
  actual=0
  eval "$cmd" >/dev/null 2>&1 || actual=$?
  if [ "$expected" = "$actual" ]; then
    PASS=$((PASS + 1))
    printf "  ${GREEN}✓${NC} %s\n" "$desc"
  else
    FAIL=$((FAIL + 1))
    printf "  ${RED}✗${NC} %s\n  expected exit: %s\n  actual exit:   %s\n" "$desc" "$expected" "$actual"
  fi
}

assert_contains() {
  TOTAL=$((TOTAL + 1))
  local desc="$1" needle="$2" haystack="$3"
  if echo "$haystack" | grep -q "$needle"; then
    PASS=$((PASS + 1))
    printf "  ${GREEN}✓${NC} %s\n" "$desc"
  else
    FAIL=$((FAIL + 1))
    printf "  ${RED}✗${NC} %s\n  missing: %s\n" "$desc" "$needle"
  fi
}

echo "─── Security Scanning Tests ───"
echo

# ── Test 1: Module exists and has valid syntax ──────────────────────────────
echo "1. Module structure"
assert_exit "00k-security-scan.sh exists" "0" "[ -f $_script_dir/src/lib/00k-security-scan.sh ]"
assert_exit "00k-security-scan.sh syntax OK" "0" "bash -n $_script_dir/src/lib/00k-security-scan.sh"

# ── Test 2: Functions defined ───────────────────────────────────────────────
echo
echo "2. Functions defined"
assert_exit "_scan_secrets defined" "0" "type _scan_secrets"
assert_exit "_verify_integrity defined" "0" "type _verify_integrity"
assert_exit "_audit_permissions defined" "0" "type _audit_permissions"
assert_exit "_scan_dependencies defined" "0" "type _scan_dependencies"
assert_exit "_generate_security_report defined" "0" "type _generate_security_report"
assert_exit "_install_pre_commit_hook defined" "0" "type _install_pre_commit_hook"
assert_exit "_security_scan_help defined" "0" "type _security_scan_help"

# ── Test 3: Help function works ─────────────────────────────────────────────
echo
echo "3. Help function"
help_output=$(_security_scan_help 2>&1)
assert_contains "help shows functions" "_scan_secrets" "$help_output"
assert_contains "help shows usage" "Usage:" "$help_output"

# ── Test 4: Secret scanning ─────────────────────────────────────────────────
echo
echo "4. Secret scanning"
test_dir="/tmp/test-security-$$"
mkdir -p "$test_dir"
echo "OPENAI_KEY=sk-abcdefghijklmnopqrstuvwxyz0123456789abcdefghijklmnop" > "$test_dir/test.env"
result=$(_scan_secrets "$test_dir" 2>&1)
assert_contains "detects OpenAI key" "OPENAI_KEY" "$result"
rm -rf "$test_dir"

# ── Test 5: Permission audit ────────────────────────────────────────────────
echo
echo "5. Permission audit"
test_dir="/tmp/test-perms-$$"
mkdir -p "$test_dir"
touch "$test_dir/test.txt"
chmod 777 "$test_dir/test.txt"
result=$(_audit_permissions "$test_dir" 2>&1)
assert_contains "detects world-writable" "World-writable" "$result"
rm -rf "$test_dir"

echo
echo "━━━ Results: $PASS/$TOTAL passed, $FAIL failed ━━━"
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
