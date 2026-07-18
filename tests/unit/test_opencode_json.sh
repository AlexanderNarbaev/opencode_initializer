#!/usr/bin/env bash
set -euo pipefail
PROJECT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
TESTS_PASS=0; TESTS_FAIL=0
O="$PROJECT_DIR/src/lib/18-opencode-json.sh"
assert() { local d="$1" c="$2"; if (eval "$c") &>/dev/null; then TESTS_PASS=$((TESTS_PASS+1)); else TESTS_FAIL=$((TESTS_FAIL+1)); echo "    FAIL: $d" >&2; fi }
assert "exists" "[ -f $O ]"
assert "syntax" "bash -n $O"
assert "has moonshot base_url" "grep -q api.moonshot.ai $O"
assert "has minimax base_url" "grep -q api.minimax.io $O"
assert "has z.ai base_url" "grep -q api.z.ai $O"
assert "has openrouter base_url" "grep -q openrouter.ai $O"
assert "has deepinfra base_url" "grep -q deepinfra.com $O"
assert "has kimi-k3 model" "grep -q kimi-k3 $O"
assert "has kimi-k2.7-code model" "grep -q kimi-k2.7-code $O"
assert "has MiniMax-M3 model" "grep -q MiniMax-M3 $O"
assert "has fallback_chain" "grep -q fallback_chain $O"
assert "has ISOLATED_CIRCUIT" "grep -q ISOLATED_CIRCUIT $O"
assert "has DEEPSEEK_API_KEY env" "grep -q DEEPSEEK_API_KEY $O"
assert "has MOONSHOT_API_KEY env" "grep -q MOONSHOT_API_KEY $O"
assert "has MINIMAX_API_KEY env" "grep -q MINIMAX_API_KEY $O"
echo "test_opencode_json: $TESTS_PASS passed, $TESTS_FAIL failed"
