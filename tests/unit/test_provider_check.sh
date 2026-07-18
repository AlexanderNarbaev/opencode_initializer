#!/usr/bin/env bash
set -euo pipefail
PROJECT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
TESTS_PASS=0; TESTS_FAIL=0
assert() {
  local desc="$1" condition="$2"
  if (eval "$condition") &>/dev/null; then TESTS_PASS=$((TESTS_PASS + 1)); else TESTS_FAIL=$((TESTS_FAIL + 1)); echo "    FAIL: $desc" >&2; fi
}
P="$PROJECT_DIR/scripts/provider-check.sh"
E="$PROJECT_DIR/.env.example"
assert "exists" "[ -f $P ]"
assert "syntax" "bash -n $P"
assert "has Moonshot" "grep -q Moonshot $P"
assert "has MiniMax" "grep -q MiniMax $P"
assert "has api.moonshot.ai" "grep -q api.moonshot.ai $P"
assert "has api.minimax.io" "grep -q api.minimax.io $P"
assert ".env.example exists" "[ -f $E ]"
assert "has DEEPSEEK" "grep -q DEEPSEEK_API_KEY $E"
assert "has MOONSHOT" "grep -q MOONSHOT_API_KEY $E"
echo "test_provider_check: $TESTS_PASS passed, $TESTS_FAIL failed"
