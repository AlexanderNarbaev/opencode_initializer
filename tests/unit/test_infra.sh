#!/usr/bin/env bash
# Test 30-infra.sh module
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
TESTS_PASS=0; TESTS_FAIL=0

assert() {
  local desc="$1" condition="$2"
  if (eval "$condition") &>/dev/null; then TESTS_PASS=$((TESTS_PASS + 1)); else TESTS_FAIL=$((TESTS_FAIL + 1)); echo "    FAIL: $desc" >&2; fi
}

source "$PROJECT_DIR/src/lib/30-infra.sh" 2>/dev/null || true

export INFRA_CONFIG="${INFRA_CONFIG:-$HOME/.config/opencode/infra.yml}"
assert "Infra config file exists" "[ -f '$INFRA_CONFIG' ]"
assert "PostgreSQL in config" "grep -q 'postgres' '$INFRA_CONFIG'"
assert "Qdrant in config" "grep -q 'qdrant' '$INFRA_CONFIG'"
assert "Redis in config" "grep -q 'redis' '$INFRA_CONFIG'"

echo "test_infra: $TESTS_PASS passed, $TESTS_FAIL failed"
