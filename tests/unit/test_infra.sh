#!/usr/bin/env bash
# Test 30-infra.sh module
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
TESTS_PASS=0; TESTS_FAIL=0
TMP_DIR=$(mktemp -d)
TEST_CONFIG="$TMP_DIR/infra.yml"
trap 'rm -rf "$TMP_DIR"' EXIT

assert() {
  local desc="$1" condition="$2"
  if (eval "$condition") &>/dev/null; then TESTS_PASS=$((TESTS_PASS + 1)); else TESTS_FAIL=$((TESTS_FAIL + 1)); echo "    FAIL: $desc" >&2; fi
}

export INFRA_CONFIG="$TEST_CONFIG"
export MODE="full"
export INFRA_SERVICES="postgres qdrant redis prometheus grafana memorylayer"
export PROGRESS="$TMP_DIR/progress"
export HOME="$TMP_DIR"

# Mock core functions needed by 30-infra.sh
_step_skip() { return 1; }
_step_done() { return 0; }
log() { :; }
warn() { :; }
info() { :; }
section() { :; }

source "$PROJECT_DIR/src/lib/30-infra.sh" 2>/dev/null || true

assert "Infra config file exists" "[ -f '$TEST_CONFIG' ]"
assert "PostgreSQL in config" "grep -q 'postgres' '$TEST_CONFIG'"
assert "Qdrant in config" "grep -q 'qdrant' '$TEST_CONFIG'"
assert "Redis in config" "grep -q 'redis' '$TEST_CONFIG'"
assert "Prometheus in config" "grep -q 'prometheus' '$TEST_CONFIG'"
assert "Grafana in config" "grep -q 'grafana' '$TEST_CONFIG'"
assert "MemoryLayer in config" "grep -q 'memorylayer' '$TEST_CONFIG'"
assert "Docker compose valid" "docker compose -f '$TEST_CONFIG' config --quiet 2>/dev/null"

echo "test_infra: $TESTS_PASS passed, $TESTS_FAIL failed"
