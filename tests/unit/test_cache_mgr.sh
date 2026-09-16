#!/usr/bin/env bash
# tests/unit/test_cache_mgr.sh — Tests for cache manager module
set -uo pipefail

PASS=0; FAIL=0; TOTAL=0
_script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

# shellcheck source=/dev/null
source "$_script_dir/src/lib/helpers.sh" 2>/dev/null || true
# shellcheck source=/dev/null
source "$_script_dir/src/lib/00-core.sh" 2>/dev/null || true
# shellcheck source=/dev/null
source "$_script_dir/src/lib/00e-cache-mgr.sh" 2>/dev/null || true

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

echo "─── Cache Manager Tests ───"
echo

# ── Test 1: Module exists and has valid syntax ──────────────────────────────
echo "1. Module structure"
assert_exit "00e-cache-mgr.sh exists" "0" "[ -f $_script_dir/src/lib/00e-cache-mgr.sh ]"
assert_exit "00e-cache-mgr.sh syntax OK" "0" "bash -n $_script_dir/src/lib/00e-cache-mgr.sh"

# ── Test 2: Functions defined ───────────────────────────────────────────────
echo
echo "2. Functions defined"
assert_exit "_cache_init defined" "0" "type _cache_init"
assert_exit "_cache_key defined" "0" "type _cache_key"
assert_exit "_cache_hit defined" "0" "type _cache_hit"
assert_exit "_cache_get defined" "0" "type _cache_get"
assert_exit "_cache_store defined" "0" "type _cache_store"
assert_exit "_cache_download defined" "0" "type _cache_download"
assert_exit "_cache_cleanup defined" "0" "type _cache_cleanup"
assert_exit "_cache_stats defined" "0" "type _cache_stats"
assert_exit "_cache_help defined" "0" "type _cache_help"

# ── Test 3: Variables defined ───────────────────────────────────────────────
echo
echo "3. Variables defined"
assert_exit "_CACHE_ROOT defined" "0" "[ -n \"$_CACHE_ROOT\" ]"
assert_exit "_CACHE_MAX_AGE_DAYS defined" "0" "[ -n \"$_CACHE_MAX_AGE_DAYS\" ]"
assert_exit "_CACHE_MAX_SIZE_MB defined" "0" "[ -n \"$_CACHE_MAX_SIZE_MB\" ]"

# ── Test 4: Help function works ─────────────────────────────────────────────
echo
echo "4. Help function"
help_output=$(_cache_help 2>&1)
assert_contains "help shows functions" "_cache_init" "$help_output"
assert_contains "help shows variables" "CACHE_MAX_AGE_DAYS" "$help_output"

# ── Test 5: Cache initialization ────────────────────────────────────────────
echo
echo "5. Cache initialization"
_cache_init 2>/dev/null
assert_exit "cache directory exists" "0" "[ -d \"$_CACHE_ROOT\" ]"
assert_exit "cache index exists" "0" "[ -f \"$_CACHE_INDEX\" ]"

# ── Test 6: Cache key generation ────────────────────────────────────────────
echo
echo "6. Cache key generation"
key=$(_cache_key "https://example.com/test.tar.gz" 2>/dev/null)
assert_exit "cache key generated" "0" "[ -n \"$key\" ]"
assert_eq "cache key length" "16" "${#key}"

echo
echo "━━━ Results: $PASS/$TOTAL passed, $FAIL failed ━━━"
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
