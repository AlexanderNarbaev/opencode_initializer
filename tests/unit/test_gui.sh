#!/usr/bin/env bash
# Test GUI server and dashboard
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
TESTS_PASS=0; TESTS_FAIL=0

assert() {
  local desc="$1" condition="$2"
  if (eval "$condition") &>/dev/null; then TESTS_PASS=$((TESTS_PASS + 1)); else TESTS_FAIL=$((TESTS_FAIL + 1)); echo "    FAIL: $desc" >&2; fi
}

S="$PROJECT_DIR/src/gui/server.js"
I="$PROJECT_DIR/src/gui/index.html"

assert "server.js exists" "[ -f '$S' ]"
assert "index.html exists" "[ -f '$I' ]"

assert "server.js has SESSIONS_DIR" "grep -q 'SESSIONS_DIR' '$S'"
assert "server.js has getSessions" "grep -q 'getSessions()' '$S'"
assert "server.js has getGPUInfo" "grep -q 'getGPUInfo()' '$S'"
assert "server.js has getMetrics" "grep -q 'getMetrics()' '$S'"
assert "server.js has handleSessions" "grep -q 'handleSessions' '$S'"
assert "server.js has handleGPU" "grep -q 'handleGPU' '$S'"
assert "server.js has handleMetrics" "grep -q 'handleMetrics' '$S'"
assert "server.js has /api/sessions route" "grep -q '/api/sessions' '$S'"
assert "server.js has /api/gpu route" "grep -q '/api/gpu' '$S'"
assert "server.js has /api/metrics route" "grep -q '/api/metrics' '$S'"

assert "index.html has sessionsGrid" "grep -q 'sessionsGrid' '$I'"
assert "index.html has gpuGrid" "grep -q 'gpuGrid' '$I'"
assert "index.html has metricsGrid" "grep -q 'metricsGrid' '$I'"
assert "index.html has renderSessions" "grep -q 'renderSessions' '$I'"
assert "index.html has renderGPU" "grep -q 'renderGPU' '$I'"
assert "index.html has renderMetrics" "grep -q 'renderMetrics' '$I'"

# Verify Node.js syntax
output=$(node --check "$S" 2>&1) && assert "server.js passes node --check" "true" || assert "server.js passes node --check" "false"

echo "test_gui: $TESTS_PASS passed, $TESTS_FAIL failed"

[ "$TESTS_FAIL" -eq 0 ] || exit 1
