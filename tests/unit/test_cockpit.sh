#!/usr/bin/env bash
# Test cockpit binary
set -euo pipefail

TESTS_PASS=0; TESTS_FAIL=0

assert() {
  local desc="$1" condition="$2"
  if (eval "$condition") &>/dev/null; then TESTS_PASS=$((TESTS_PASS + 1)); else TESTS_FAIL=$((TESTS_FAIL + 1)); echo "    FAIL: $desc" >&2; fi
}

BIN="$HOME/.local/bin/cockpit"
assert "cockpit binary exists" "[ -f '$BIN' ]"
assert "cockpit is executable" "[ -x '$BIN' ]"
assert "cockpit is ELF binary" "file '$BIN' | grep -q ELF"
echo "test_cockpit: $TESTS_PASS passed, $TESTS_FAIL failed"
