#!/usr/bin/env bash
# ============================================================================
# Master Test Runner — runs all test suites for opencode_initializer
#
# Safety model (see tests/test_sandbox.sh for the rationale):
#   * By default the runner prepends shims for privilege-escalating binaries
#     to PATH, so a test that sources a real module cannot install anything,
#     prompt for a password, or hang the terminal on an interactive box.
#   * RUN_PRIVILEGED=1 (or --privileged) turns the sandbox OFF.
#   * RUN_E2E=1 (or --e2e) additionally runs the heavy end-to-end suite.
#   * Every test is wrapped in a timeout so a TTY-owning child cannot wedge
#     the run again.
#
# Usage: bash tests/run_tests.sh [--e2e] [--privileged] [--timeout N] [-h]
# ============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
export SKIP_MIRROR_RESOLVE=true  # skip expensive network mirror probes in tests

RUN_E2E="${RUN_E2E:-0}"
RUN_PRIVILEGED="${RUN_PRIVILEGED:-0}"
TEST_TIMEOUT="${TEST_TIMEOUT:-300}"
ONLY_SECTION=""

usage() {
  cat <<'USAGE'
Master test runner for opencode_initializer.

Usage: bash tests/run_tests.sh [options]

Options:
  --e2e               also run tests/e2e/ (heavy; same as RUN_E2E=1)
  --privileged        disable the privilege sandbox (same as RUN_PRIVILEGED=1)
                      WARNING: tests may install packages and change the host
  --timeout N         per-test timeout in seconds (default: 300)
  --section NAME      run only one section: syntax|unit|integration|e2e
  -h, --help          show this help

Environment: RUN_E2E, RUN_PRIVILEGED, TEST_TIMEOUT are honoured as defaults.

Exit code: 0 when every executed test passed, 1 otherwise.
USAGE
}

while [ $# -gt 0 ]; do
  case "$1" in
    --e2e)          RUN_E2E=1 ;;
    --privileged)   RUN_PRIVILEGED=1 ;;
    --timeout)      shift; TEST_TIMEOUT="${1:?--timeout needs a value}" ;;
    --timeout=*)    TEST_TIMEOUT="${1#*=}" ;;
    --section)      shift; ONLY_SECTION="${1:?--section needs a value}" ;;
    --section=*)    ONLY_SECTION="${1#*=}" ;;
    -h|--help)      usage; exit 0 ;;
    *)              echo "Unknown option: $1 (try --help)" >&2; exit 2 ;;
  esac
  shift
done

export RUN_E2E RUN_PRIVILEGED TEST_TIMEOUT

# shellcheck source=tests/test_sandbox.sh
. "$SCRIPT_DIR/test_sandbox.sh"
sandbox_init
sandbox_activate
trap sandbox_cleanup EXIT

# timeout(1) is coreutils; macOS ships gtimeout. Fall back to no timeout.
TIMEOUT_BIN=""
for _candidate in timeout gtimeout; do
  if command -v "$_candidate" >/dev/null 2>&1; then TIMEOUT_BIN="$_candidate"; break; fi
done
if [ -z "$TIMEOUT_BIN" ]; then
  echo "  ⚠ no timeout(1) found — a hanging test will hang the suite" >&2
fi

run_with_timeout() {
  if [ -n "$TIMEOUT_BIN" ]; then
    "$TIMEOUT_BIN" "$TEST_TIMEOUT" "$@"
  else
    "$@"
  fi
}

PASS=0; FAIL=0; SKIP=0; TOTAL=0

# Print whatever the sandbox intercepted while a test was running.
report_intercepts() {
  local since="$1"
  local new
  new="$(sandbox_log_since "$since")"
  [ -n "$new" ] || return 0
  echo "$new" | sed 's/^/    ⚠ intercepted: /' >&2
}

run_test() {
  local name="$1" cmd="$2"
  TOTAL=$((TOTAL + 1))
  printf "  %-55s " "$name"
  local before output rc
  before="$(sandbox_log_lines)"
  output=$(run_with_timeout bash -c "$cmd" 2>&1) && rc=0 || rc=$?
  if [ "$rc" -eq 0 ]; then
    echo "PASS"
    PASS=$((PASS + 1))
  elif [ "$rc" -eq 124 ] || [ "$rc" -eq 137 ]; then
    echo "TIMEOUT (${TEST_TIMEOUT}s)"
    FAIL=$((FAIL + 1))
    echo "$output" | tail -20 | sed 's/^/    /' >&2
  else
    echo "FAIL"
    FAIL=$((FAIL + 1))
    echo "$output" | tail -40 | sed 's/^/    /' >&2
  fi
  report_intercepts "$before"
}

run_test_file() {
  local name="$1" file="$2"
  TOTAL=$((TOTAL + 1))
  printf "  %-55s " "$name"
  local before output rc
  before="$(sandbox_log_lines)"
  output=$(run_with_timeout bash "$file" 2>&1) && rc=0 || rc=$?
  if [ "$rc" -eq 0 ]; then
    echo "PASS"
    PASS=$((PASS + 1))
  elif [ "$rc" -eq 124 ] || [ "$rc" -eq 137 ]; then
    echo "TIMEOUT (${TEST_TIMEOUT}s)"
    FAIL=$((FAIL + 1))
    echo "$output" | tail -20 | sed 's/^/    /' >&2
  else
    echo "FAIL"
    FAIL=$((FAIL + 1))
    echo "$output" | tail -40 | sed 's/^/    /' >&2
  fi
  report_intercepts "$before"
}

want_section() {
  [ -z "$ONLY_SECTION" ] && return 0
  [ "$ONLY_SECTION" = "$1" ]
}

echo "============================================================"
echo "  OpenCode Initializer Test Suite"
echo "  Project: $PROJECT_DIR"
echo "  Sandbox: $([ "$TEST_SANDBOX_ACTIVE" = "1" ] && echo ON || echo OFF)"
echo "  Per-test timeout: ${TEST_TIMEOUT}s"
echo "============================================================"

# ── Syntax Checks ─────────────────────────────────────────────────────────
if want_section syntax; then
echo
echo "=== Syntax Tests (bash -n) ==="

for f in "$PROJECT_DIR/setup.sh" "$PROJECT_DIR/dev.sh" "$PROJECT_DIR/src/lib/"*.sh "$PROJECT_DIR/src/modes/"*.sh; do
  [ -f "$f" ] || continue
  run_test "Syntax: $(basename "$f")" "bash -n '$f'"
done

for f in "$SCRIPT_DIR"/unit/*.sh "$SCRIPT_DIR"/integration/*.sh "$SCRIPT_DIR"/e2e/*.sh; do
  [ -f "$f" ] || continue
  run_test "Syntax: tests/$(echo "$f" | sed "s|$SCRIPT_DIR/||")" "bash -n '$f'"
done

# Python syntax checks
for f in "$PROJECT_DIR/scripts/"*.py; do
  [ -f "$f" ] || continue
  run_test "Syntax: $(basename "$f")" "python3 -m py_compile '$f'"
done

# Go syntax checks
if command -v gofmt &>/dev/null; then
  for f in "$PROJECT_DIR/src/cockpit/"*.go; do
    [ -f "$f" ] || continue
    run_test "Go fmt: $(basename "$f")" "gofmt -l '$f' | wc -l | grep -q '^0$'"
  done
fi
fi

# ── Unit Tests ────────────────────────────────────────────────────────────
if want_section unit; then
echo
echo "=== Unit Tests ==="

for f in "$SCRIPT_DIR/unit/"*.sh; do
  [ -f "$f" ] || continue
  run_test_file "$(basename "$f")" "$f"
done
fi

# ── Integration Tests ─────────────────────────────────────────────────────
if want_section integration; then
echo
echo "=== Integration Tests ==="

for f in "$SCRIPT_DIR/integration/"*.sh; do
  [ -f "$f" ] || continue
  run_test_file "$(basename "$f")" "$f"
done
fi

# ── E2E Tests ─────────────────────────────────────────────────────────────
if want_section e2e; then
echo
if [ "$RUN_E2E" = "1" ]; then
  echo "=== End-to-End Tests (RUN_E2E=1) ==="
  for f in "$SCRIPT_DIR/e2e/"*.sh; do
    [ -f "$f" ] || continue
    run_test_file "$(basename "$f")" "$f"
  done
else
  _e2e_count=$(find "$SCRIPT_DIR/e2e" -maxdepth 1 -name 'test_*.sh' 2>/dev/null | wc -l | tr -d ' ')
  SKIP=$((SKIP + _e2e_count))
  echo "=== End-to-End Tests ==="
  echo "  SKIP ${_e2e_count} e2e file(s) — re-run with --e2e (RUN_E2E=1)"
fi
fi

# ── Results ───────────────────────────────────────────────────────────────
echo
echo "============================================================"
printf "  Results: %d passed, %d failed, %d skipped, %d total\n" "$PASS" "$FAIL" "$SKIP" "$TOTAL"
echo "============================================================"

if [ "$TEST_SANDBOX_ACTIVE" = "1" ] && [ -s "$TEST_SANDBOX_LOG" ]; then
  echo
  echo "  Unique privileged commands the suite tried to run (all intercepted):"
  sort "$TEST_SANDBOX_LOG" | uniq -c | sort -rn | head -20 | sed 's/^/    /'
fi

[ "$FAIL" -eq 0 ] || exit 1