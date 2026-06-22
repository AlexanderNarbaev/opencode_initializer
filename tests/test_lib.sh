#!/usr/bin/env bash
# Shared test library for opencode_initializer tests

PASS=0
FAIL=0

assert() {
  local msg="$1"
  local condition="$2"
  if eval "$condition" &>/dev/null; then
    echo "  ✅ $msg"
    ((PASS++))
  else
    echo "  ❌ $msg"
    ((FAIL++))
  fi
}

cleanup_test() {
  echo ""
  echo "Results: $PASS passed, $FAIL failed"
  if [ "$FAIL" -gt 0 ]; then
    echo "❌ SOME TESTS FAILED"
    exit 1
  else
    echo "✅ All tests passed"
  fi
}
