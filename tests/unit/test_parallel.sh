#!/usr/bin/env bash
# tests/unit/test_parallel.sh — Tests for parallel execution module
set -uo pipefail

PASS=0; FAIL=0; TOTAL=0
_script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

# shellcheck source=/dev/null
source "$_script_dir/src/lib/helpers.sh" 2>/dev/null || true
# shellcheck source=/dev/null
source "$_script_dir/src/lib/00-core.sh" 2>/dev/null || true
# shellcheck source=/dev/null
source "$_script_dir/src/lib/00d-parallel.sh" 2>/dev/null || true

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

echo "─── Parallel Execution Tests ───"
echo

# ── Test 1: Module exists and has valid syntax ──────────────────────────────
echo "1. Module structure"
assert_exit "00d-parallel.sh exists" "0" "[ -f $_script_dir/src/lib/00d-parallel.sh ]"
assert_exit "00d-parallel.sh syntax OK" "0" "bash -n $_script_dir/src/lib/00d-parallel.sh"

# ── Test 2: Functions defined ───────────────────────────────────────────────
echo
echo "2. Functions defined"
assert_exit "_parallel_run_layer defined" "0" "type _parallel_run_layer"
assert_exit "_parallel_wait_all defined" "0" "type _parallel_wait_all"
assert_exit "_parallel_install defined" "0" "type _parallel_install"
assert_exit "_process_skip_flags defined" "0" "type _process_skip_flags"
assert_exit "_should_install defined" "0" "type _should_install"
assert_exit "_mark_installed defined" "0" "type _mark_installed"
assert_exit "_parallel_help defined" "0" "type _parallel_help"

# ── Test 3: Variables defined ───────────────────────────────────────────────
echo
echo "3. Variables defined"
assert_exit "_PARALLEL_MAX_JOBS defined" "0" "[ -n \"${_PARALLEL_MAX_JOBS:-}\" ]"

# ── Test 4: Help function works ─────────────────────────────────────────────
echo
echo "4. Help function"
help_output=$(_parallel_help 2>&1)
assert_contains "help shows functions" "_parallel_run_layer" "$help_output"
assert_contains "help shows variables" "PARALLEL_MAX_JOBS" "$help_output"

# ── Test 5: Mark installed works ────────────────────────────────────────────
echo
echo "5. Mark installed"
test_module="test-parallel-module-$$"
_mark_installed "$test_module" 2>/dev/null
assert_exit "mark_installed creates file" "0" "[ -f ${DL_CACHE}/installed/$test_module ]"
rm -f "${DL_CACHE}/installed/$test_module" 2>/dev/null

echo
echo "━━━ Results: $PASS/$TOTAL passed, $FAIL failed ━━━"
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
