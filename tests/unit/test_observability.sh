#!/usr/bin/env bash
# Test 34-observability.sh module
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
TESTS_PASS=0; TESTS_FAIL=0

assert() {
  local desc="$1" condition="$2"
  if (eval "$condition") &>/dev/null; then TESTS_PASS=$((TESTS_PASS + 1)); else TESTS_FAIL=$((TESTS_FAIL + 1)); echo "    FAIL: $desc" >&2; fi
}

C="$PROJECT_DIR/src/lib/34-observability.sh"
assert "34-observability.sh exists" "[ -f '$C' ]"
assert "34-observability.sh syntax valid" "bash -n '$C'"
assert "has Prometheus" "grep -q 'prometheus' '$C'"
assert "has Grafana" "grep -q 'grafana' '$C'"
assert "has port 9090" "grep -q '9090' '$C'"
assert "has port 3001" "grep -q '3001' '$C'"
assert "has observability step" "grep -q 'step_observability' '$C'"

# ── setup.sh references ──────────────────────────────────────────────────────
S="$PROJECT_DIR/setup.sh"
assert "setup.sh references 34-observability.sh" "grep -q '34-observability' '$S'"
assert "setup.sh has OBSERVABILITY_ENABLED check" "grep -q 'OBSERVABILITY_ENABLED' '$S'"

echo "test_observability: $TESTS_PASS passed, $TESTS_FAIL failed"
