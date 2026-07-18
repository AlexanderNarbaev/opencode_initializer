#!/usr/bin/env bash
set -euo pipefail
PROJECT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
TESTS_PASS=0; TESTS_FAIL=0
assert() { local d="$1" c="$2"; if (eval "$c") &>/dev/null; then TESTS_PASS=$((TESTS_PASS+1)); else TESTS_FAIL=$((TESTS_FAIL+1)); echo "    FAIL: $d" >&2; fi }
M="$PROJECT_DIR/src/lib/38-ide-plugins.sh"
assert "exists" "[ -f $M ]"
assert "syntax" "bash -n $M"
assert "has DevoxxGenie" "grep -q 24169-devoxxgenie $M"
assert "has Cline" "grep -q 28247 $M"
assert "has Tabby" "grep -q 22379 $M"
assert "no GitHub Copilot" "! grep -q github.copilot $M"
assert "has Veai mention" "grep -qi veai $M"
assert "has GigaIDE detection" "grep -q GigaIDE $M"
assert "has CPU model qwen3" "grep -q qwen3 $M"
assert "has GigaChat model" "grep -qi gigachat $M"
assert "has air-gapped note" "grep -q ISOLATED_CIRCUIT $M"
assert "has Aider CLI" "grep -q aider $M"
assert "has Cline CLI" "grep -q cline $M"
assert "has ollama recommendations" "grep -q ollama pull $M"
assert "has find_jetbrains function" "grep -q find_jetbrains $M"
echo "test_ide_plugins: $TESTS_PASS passed, $TESTS_FAIL failed"
