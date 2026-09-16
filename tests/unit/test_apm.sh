#!/usr/bin/env bash
# tests/unit/test_apm.sh — Tests for APM preparation module
set -uo pipefail

PASS=0; FAIL=0; TOTAL=0
_script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

# shellcheck source=/dev/null
source "$_script_dir/src/lib/helpers.sh" 2>/dev/null || true
# shellcheck source=/dev/null
source "$_script_dir/src/lib/00-core.sh" 2>/dev/null || true
# shellcheck source=/dev/null
source "$_script_dir/src/lib/00f-apm.sh" 2>/dev/null || true

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

echo "─── APM Preparation Tests ───"
echo

# ── Test 1: Module exists and has valid syntax ──────────────────────────────
echo "1. Module structure"
assert_exit "00f-apm.sh exists" "0" "[ -f $_script_dir/src/lib/00f-apm.sh ]"
assert_exit "00f-apm.sh syntax OK" "0" "bash -n $_script_dir/src/lib/00f-apm.sh"

# ── Test 2: Functions defined ───────────────────────────────────────────────
echo
echo "2. Functions defined"
assert_exit "_apm_generate defined" "0" "type _apm_generate"
assert_exit "_apm_generate_minimal defined" "0" "type _apm_generate_minimal"
assert_exit "_apm_export_sbom defined" "0" "type _apm_export_sbom"
assert_exit "_apm_install defined" "0" "type _apm_install"
assert_exit "_apm_help defined" "0" "type _apm_help"

# ── Test 3: Variables defined ───────────────────────────────────────────────
echo
echo "3. Variables defined"
assert_exit "_APM_YML defined" "0" "[ -n \"$_APM_YML\" ]"
assert_exit "_APM_SCHEMA_VERSION defined" "0" "[ -n \"$_APM_SCHEMA_VERSION\" ]"
assert_exit "_APM_PACKAGE_NAME defined" "0" "[ -n \"$_APM_PACKAGE_NAME\" ]"

# ── Test 4: Help function works ─────────────────────────────────────────────
echo
echo "4. Help function"
help_output=$(_apm_help 2>&1)
assert_contains "help shows functions" "_apm_generate" "$help_output"
assert_contains "help shows variables" "APM_YML" "$help_output"

# ── Test 5: Minimal APM generation ──────────────────────────────────────────
echo
echo "5. Minimal APM generation"
test_apm="/tmp/test-apm-$$-minimal.yml"
_apm_generate_minimal "$test_apm" 2>/dev/null
assert_exit "minimal apm.yml created" "0" "[ -f \"$test_apm\" ]"
if [ -f "$test_apm" ]; then
  apm_content=$(cat "$test_apm")
  assert_contains "apm.yml has name" "name:" "$apm_content"
  assert_contains "apm.yml has version" "version:" "$apm_content"
  rm -f "$test_apm"
fi

echo
echo "━━━ Results: $PASS/$TOTAL passed, $FAIL failed ━━━"
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
