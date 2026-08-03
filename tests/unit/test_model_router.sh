#!/usr/bin/env bash
set -euo pipefail
PROJECT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
TESTS_PASS=0; TESTS_FAIL=0
ROUTER="$PROJECT_DIR/src/lib/36-model-router.sh"
assert() { local d="$1" c="$2"; if (eval "$c") &>/dev/null; then TESTS_PASS=$((TESTS_PASS + 1)); else TESTS_FAIL=$((TESTS_FAIL + 1)); echo "    FAIL: $d" >&2; fi }

# Extract JSON templates
TMP=$(mktemp -d)
trap "rm -rf $TMP" EXIT
sed -n "/cat.*task-profiles.json/,/^PROFILES$/p" "$ROUTER" | sed "1d;\$d" > "$TMP/profiles.json"
sed -n "/cat.*cost-table.json/,/^COSTS$/p" "$ROUTER" | sed "1d;\$d" > "$TMP/costs.json"

# Validate JSON
assert "profiles.json is valid JSON" "python3 -c \"import json; json.load(open('$TMP/profiles.json'))\""
assert "costs.json is valid JSON" "python3 -c \"import json; json.load(open('$TMP/costs.json'))\""

# Profile checks
assert "has coding profile" "grep -q "coding" \"$TMP/profiles.json\""
assert "has reasoning profile" "grep -q "reasoning" \"$TMP/profiles.json\""
assert "has fast profile" "grep -q "fast" \"$TMP/profiles.json\""
assert "has agentic profile" "grep -q "agentic" \"$TMP/profiles.json\""
assert "has budget profile" "grep -q "budget" \"$TMP/profiles.json\""
assert "has vision profile" "grep -q "vision" \"$TMP/profiles.json\""
assert "has isolated profile" "grep -q "isolated" \"$TMP/profiles.json\""
assert "has ru_cn profile" "grep -q "ru_cn" \"$TMP/profiles.json\""

# Model checks
assert "agentic uses deepseek-v4-pro" "grep -A3 '\"agentic\"' \"$TMP/profiles.json\" | grep -q deepseek-v4-pro"
assert "coding fallback has glm-5.2" "grep -A5 '\"coding\"' \"$TMP/profiles.json\" | grep -q glm-5.2"
assert "costs has deepseek-v4-pro" "grep -q deepseek-v4-pro \"$TMP/costs.json\""
assert "costs has MiniMax-M3" "grep -q MiniMax-M3 \"$TMP/costs.json\""
assert "deepseek-v4-pro has 1000000 context" "grep deepseek-v4-pro \"$TMP/costs.json\" | grep -q 1000000"

echo "test_model_router: $TESTS_PASS passed, $TESTS_FAIL failed"
[ "$TESTS_FAIL" -eq 0 ] || exit 1
