#!/usr/bin/env bash
# Unit test: S1.3.3 — _trap_cleanup() error strategy (_SETUP_ERROR_STRICT)
# Verifies: strict=0 warn+continue, strict=1 FATAL+exit, _CLEANUP_FILES[] cleanup
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$(dirname "$SCRIPT_DIR")")"
PASS=0; FAIL=0

check() {
  local desc="$1"; shift
  if "$@" &>/dev/null; then
    PASS=$((PASS + 1))
  else
    echo "  FAIL: $desc" >&2
    FAIL=$((FAIL + 1))
  fi
}

check_code() {
  local desc="$1" expected="$2" actual="$3"
  if [ "$actual" -eq "$expected" ]; then
    PASS=$((PASS + 1))
  else
    echo "  FAIL: $desc (expected $expected, got $actual)" >&2
    FAIL=$((FAIL + 1))
  fi
}

TMPD=$(mktemp -d /tmp/test_error_strategy.XXXXXX)
trap 'rm -rf "$TMPD"' EXIT

# 37-wal.sh has top-level `if [ "$MODE" = "full" ]` guard — set MODE to avoid triggering
export MODE=test
# Source helpers to get _trap_cleanup
source "$PROJECT_DIR/src/lib/helpers.sh"

echo "=== Testing _trap_cleanup() error strategy ==="

# ── T1: _SETUP_ERROR_STRICT=0 → warn, continue (subshell code 0) ──────────
strict0_code=0
( _SETUP_ERROR_STRICT=0; (exit 42); _trap_cleanup "test-module" ) 2>/dev/null || strict0_code=$?
check_code "T1: strict=0 returns 0 (continue)" 0 "$strict0_code"

# ── T2: _SETUP_ERROR_STRICT=1 → FATAL, exit with code ─────────────────────
strict1_code=0
# false sets $?=1; _trap_cleanup reads it and exits with that code when strict=1
( _SETUP_ERROR_STRICT=1; false; _trap_cleanup "test-module" ) 2>/dev/null || strict1_code=$?
check_code "T2: strict=1 exits with non-zero after false" 1 "$strict1_code"

# ── T3: _CLEANUP_FILES[] cleanup ──────────────────────────────────────────
cleanup_file="$TMPD/cleanup_test_file"
touch "$cleanup_file"
_CLEANUP_FILES=("$cleanup_file")
( _SETUP_ERROR_STRICT=0; (exit 1); _trap_cleanup "test-module" ) 2>/dev/null || true
check "T3: _CLEANUP_FILES element deleted" test ! -e "$cleanup_file"

# ── T4: multiple _CLEANUP_FILES all cleaned ───────────────────────────────
f1="$TMPD/cf_multi_1"; f2="$TMPD/cf_multi_2"; f3="$TMPD/cf_multi_3"
touch "$f1" "$f2" "$f3"
_CLEANUP_FILES=("$f1" "$f2" "$f3")
( _SETUP_ERROR_STRICT=0; (exit 1); _trap_cleanup "test-module" ) 2>/dev/null || true
all_gone=true
[ -e "$f1" ] && all_gone=false
[ -e "$f2" ] && all_gone=false
[ -e "$f3" ] && all_gone=false
check "T4: all 3 _CLEANUP_FILES deleted" test "$all_gone" = true

# ── T5: _CLEANUP_FILES unset → no crash ───────────────────────────────────
unset _CLEANUP_FILES
strict5_code=0
( _SETUP_ERROR_STRICT=0; (exit 1); _trap_cleanup "test-module" ) 2>/dev/null || strict5_code=$?
check_code "T5: no _CLEANUP_FILES → no crash" 0 "$strict5_code"

# ── T6: default (unset _SETUP_ERROR_STRICT) → strict=0 behaviour ──────────
default_code=0
( unset _SETUP_ERROR_STRICT; (exit 3); _trap_cleanup "test-module" ) 2>/dev/null || default_code=$?
check_code "T6: default (unset) behaves as strict=0" 0 "$default_code"

echo "RESULTS: $PASS pass, $FAIL fail"
exit $FAIL
