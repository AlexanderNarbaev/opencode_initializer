#!/usr/bin/env bash
# Test 26-providers.sh module — provider registry with z.ai, OpenRouter, etc.
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
TESTS_PASS=0; TESTS_FAIL=0
TMP_DIR=$(mktemp -d)
trap 'rm -rf "$TMP_DIR"' EXIT

assert() {
  local desc="$1" condition="$2"
  if (eval "$condition") &>/dev/null; then TESTS_PASS=$((TESTS_PASS + 1)); else TESTS_FAIL=$((TESTS_FAIL + 1)); echo "    FAIL: $desc" >&2; fi
}

C="$PROJECT_DIR/src/lib/26-providers.sh"
assert "26-providers.sh exists" "[ -f '$C' ]"
assert "26-providers.sh syntax valid" "bash -n '$C'"

# ── Cloud providers ──────────────────────────────────────────────────────────
assert "has deepseek" "grep -q 'deepseek' '$C'"
assert "has opencode" "grep -q 'opencode' '$C'"
assert "has zai (GLM)" "grep -q 'zai' '$C'"
assert "has zai GLM-5.2" "grep -q 'GLM-5.2' '$C'"
assert "has openrouter" "grep -q 'openrouter' '$C'"
assert "has openrouter 100+ models" "grep -q '100+ models' '$C'"
assert "has xai" "grep -q 'xai' '$C'"
assert "has Grok 4.3" "grep -q 'Grok 4.3' '$C'"
assert "has moonshot" "grep -q 'moonshot' '$C'"
assert "has Kimi K2.7 Code" "grep -q 'Kimi K2.7 Code' '$C'"
assert "has anthropic" "grep -q 'anthropic' '$C'"
assert "has Claude Opus 4.8" "grep -q 'Claude Opus 4.8' '$C'"
assert "has google" "grep -q 'google' '$C'"
assert "has Gemini 3.5 Flash" "grep -q 'Gemini 3.5 Flash' '$C'"
assert "has openai" "grep -q 'openai' '$C'"
assert "has mistral" "grep -q 'mistral' '$C'"
assert "has groq" "grep -q 'groq' '$C'"
assert "has together" "grep -q 'together' '$C'"
assert "has cohere" "grep -q 'cohere' '$C'"
assert "has fireworks" "grep -q 'fireworks' '$C'"
assert "has cerebras" "grep -q 'cerebras' '$C'"
assert "has perplexity" "grep -q 'perplexity' '$C'"
assert "has alibaba" "grep -q 'alibaba' '$C'"
assert "has Qwen3.7" "grep -q 'Qwen3.7' '$C'"
assert "has deepinfra" "grep -q 'deepinfra' '$C'"
assert "has minimax" "grep -q 'minimax' '$C'"
assert "has mimo" "grep -q 'mimo' '$C'"

# ── Local providers ──────────────────────────────────────────────────────────
assert "has ollama" "grep -q 'ollama' '$C'"
assert "has litellm" "grep -q 'litellm' '$C'"
assert "has vllm" "grep -q 'vllm' '$C'"
assert "has sglang" "grep -q 'sglang' '$C'"

# ── Isolated circuit ─────────────────────────────────────────────────────────
assert "has ISOLATED_CIRCUIT check" "grep -q 'ISOLATED_CIRCUIT' '$C'"
assert "has local-only mode" "grep -q 'local providers only' '$C'"

# ── API key env vars ─────────────────────────────────────────────────────────
assert "has ZAI_API_KEY" "grep -q 'ZAI_API_KEY' '$C'"
assert "has OPENROUTER_API_KEY" "grep -q 'OPENROUTER_API_KEY' '$C'"
assert "has ALIBABA_API_KEY" "grep -q 'ALIBABA_API_KEY' '$C'"
assert "has DEEPINFRA_API_KEY" "grep -q 'DEEPINFRA_API_KEY' '$C'"

# ── CLI flags ────────────────────────────────────────────────────────────────
assert "has --zai-key flag" "grep -F -- '--zai-key' '$C'"
assert "has --openrouter-key flag" "grep -F -- '--openrouter-key' '$C'"
assert "has --alibaba-key flag" "grep -F -- '--alibaba-key' '$C'"
assert "has --deepinfra-key flag" "grep -F -- '--deepinfra-key' '$C'"

# ── opencode.json has z.ai ───────────────────────────────────────────────────
J="$PROJECT_DIR/opencode.json"
assert "opencode.json has zai provider" "grep -q 'zai' '$J'"
assert "opencode.json has zai in deepseek fallback" "python3 -c \"import json; c=json.load(open('$J')); assert 'zai' in c['provider']['deepseek']['fallback']\""
assert "opencode.json has zai provider config" "python3 -c \"import json; c=json.load(open('$J')); assert 'zai' in c['provider']\""
assert "opencode.json zai has fallback" "python3 -c \"import json; c=json.load(open('$J')); assert 'fallback' in c['provider']['zai']\""

# ── 18-opencode-json.sh has new providers ────────────────────────────────────
O="$PROJECT_DIR/src/lib/18-opencode-json.sh"
assert "18-opencode-json.sh has zai" "grep -q 'zai' '$O'"
assert "18-opencode-json.sh has openrouter" "grep -q 'openrouter' '$O'"
assert "18-opencode-json.sh has alibaba" "grep -q 'alibaba' '$O'"
assert "18-opencode-json.sh has deepinfra" "grep -q 'deepinfra' '$O'"
assert "18-opencode-json.sh has ZAI_API_KEY" "grep -q 'ZAI_API_KEY' '$O'"
assert "18-opencode-json.sh has OPENROUTER_API_KEY" "grep -q 'OPENROUTER_API_KEY' '$O'"
assert "18-opencode-json.sh has ALIBABA_API_KEY" "grep -q 'ALIBABA_API_KEY' '$O'"
assert "18-opencode-json.sh has DEEPINFRA_API_KEY" "grep -q 'DEEPINFRA_API_KEY' '$O'"
assert "18-opencode-json.sh has glm-5.2 model" "grep -q 'glm-5.2' '$O'"
assert "18-opencode-json.sh has grok-4.3 model" "grep -q 'grok-4.3' '$O'"
assert "18-opencode-json.sh has kimi-k2.7-code model" "grep -q 'kimi-k2.7-code' '$O'"
assert "18-opencode-json.sh has claude-opus-4-8" "grep -q 'claude-opus-4-8' '$O'"
assert "18-opencode-json.sh has zai baseURL" "grep -q 'api.z.ai' '$O'"
assert "18-opencode-json.sh has openrouter baseURL" "grep -q 'openrouter.ai' '$O'"

echo "test_providers: $TESTS_PASS passed, $TESTS_FAIL failed"
