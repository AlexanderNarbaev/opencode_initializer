#!/usr/bin/env bash
# tests/unit/test_config.sh — Tests for configuration module
set -uo pipefail

PASS=0; FAIL=0; TOTAL=0
_script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

# shellcheck source=/dev/null
source "$_script_dir/src/lib/helpers.sh" 2>/dev/null || true
# shellcheck source=/dev/null
source "$_script_dir/src/lib/00-core.sh" 2>/dev/null || true
# shellcheck source=/dev/null
source "$_script_dir/src/lib/00x-config.sh" 2>/dev/null || true

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

echo "─── Configuration Module Tests ───"
echo

# ── Test 1: Module exists and has valid syntax ──────────────────────────────
echo "1. Module structure"
assert_exit "00x-config.sh exists" "0" "[ -f $_script_dir/src/lib/00x-config.sh ]"
assert_exit "00x-config.sh syntax OK" "0" "bash -n $_script_dir/src/lib/00x-config.sh"

# ── Test 2: Functions defined ───────────────────────────────────────────────
echo
echo "2. Functions defined"
assert_exit "_config_init defined" "0" "type _config_init"
assert_exit "_config_load defined" "0" "type _config_load"
assert_exit "_config_get defined" "0" "type _config_get"
assert_exit "_config_set defined" "0" "type _config_set"
assert_exit "_config_validate defined" "0" "type _config_validate"
assert_exit "_config_show defined" "0" "type _config_show"
assert_exit "_config_reset defined" "0" "type _config_reset"

# ── Test 3: Configuration initialization ────────────────────────────────────
echo
echo "3. Configuration initialization"
_config_init 2>/dev/null
assert_exit "config directory exists" "0" "[ -d \"$_CONFIG_DIR\" ]"

# ── Test 4: Configuration get/set ───────────────────────────────────────────
echo
echo "4. Configuration get/set"
_config_set "TEST_KEY" "test_value" 2>/dev/null
result=$(_config_get "TEST_KEY" "" 2>/dev/null)
assert_eq "config get returns value" "test_value" "$result"

# ── Test 5: Configuration validation ────────────────────────────────────────
echo
echo "5. Configuration validation"
assert_exit "config validate passes" "0" "_config_validate"

echo
echo "━━━ Results: $PASS/$TOTAL passed, $FAIL failed ━━━"
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
