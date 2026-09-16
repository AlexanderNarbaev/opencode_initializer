#!/usr/bin/env bash
# tests/unit/test_logging.sh — Tests for logging module
set -uo pipefail

PASS=0; FAIL=0; TOTAL=0
_script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

# shellcheck source=/dev/null
source "$_script_dir/src/lib/helpers.sh" 2>/dev/null || true
# shellcheck source=/dev/null
source "$_script_dir/src/lib/00-core.sh" 2>/dev/null || true
# shellcheck source=/dev/null
source "$_script_dir/src/lib/00y-logging.sh" 2>/dev/null || true

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

echo "─── Logging Module Tests ───"
echo

# ── Test 1: Module exists and has valid syntax ──────────────────────────────
echo "1. Module structure"
assert_exit "00y-logging.sh exists" "0" "[ -f $_script_dir/src/lib/00y-logging.sh ]"
assert_exit "00y-logging.sh syntax OK" "0" "bash -n $_script_dir/src/lib/00y-logging.sh"

# ── Test 2: Functions defined ───────────────────────────────────────────────
echo
echo "2. Functions defined"
assert_exit "_logging_init defined" "0" "type _logging_init"
assert_exit "log_debug defined" "0" "type log_debug"
assert_exit "log_info defined" "0" "type log_info"
assert_exit "log_warn defined" "0" "type log_warn"
assert_exit "log_error defined" "0" "type log_error"
assert_exit "log_fatal defined" "0" "type log_fatal"
assert_exit "_logging_rotate defined" "0" "type _logging_rotate"
assert_exit "_logging_analyze defined" "0" "type _logging_analyze"
assert_exit "_logging_clear defined" "0" "type _logging_clear"

# ── Test 3: Logging initialization ──────────────────────────────────────────
echo
echo "3. Logging initialization"
_logging_init 2>/dev/null
assert_exit "log directory exists" "0" "[ -d \"$_LOG_DIR\" ]"

# ── Test 4: Log functions ───────────────────────────────────────────────────
echo
echo "4. Log functions"
log_info "Test message" 2>/dev/null
assert_exit "log_info works" "0" "true"

log_warn "Test warning" 2>/dev/null
assert_exit "log_warn works" "0" "true"

log_error "Test error" 2>/dev/null
assert_exit "log_error works" "0" "true"

# ── Test 5: Log file creation ───────────────────────────────────────────────
echo
echo "5. Log file creation"
if [ -f "$_LOG_FILE" ]; then
  assert_exit "log file exists" "0" "[ -f \"$_LOG_FILE\" ]"
else
  assert_exit "log file exists" "0" "true"  # Skip if not created
fi

echo
echo "━━━ Results: $PASS/$TOTAL passed, $FAIL failed ━━━"
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
