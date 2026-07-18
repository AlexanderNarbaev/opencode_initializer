#!/usr/bin/env bash
# provider-check.sh — Verify connectivity to all configured AI providers
set -euo pipefail
RED="[0;31m"; GREEN="[0;32m"; YELLOW="[1;33m"; NC="[0m"
check() {
  local name="$1" url="$2" model="${3:-}" key="${4:-}"
  printf "  %-20s " "$name"
  if [ -z "$key" ]; then echo -e "${YELLOW}SKIP (no key)${NC}"; return; fi
  local resp=$(curl -s --connect-timeout 8 --max-time 15 -X POST "$url" -H "Content-Type: application/json" -H "Authorization: Bearer $key" -d "{\"model\":\"$model\",\"messages\":[{\"role\":\"user\",\"content\":\"hi\"}],\"max_tokens\":3}" 2>&1)
  if echo "$resp" | grep -q "\"content\"\|\"text\""; then echo -e "${GREEN}OK${NC}"
  elif echo "$resp" | grep -qi "invalid.*key\|unauthorized\|authentication"; then echo -e "${YELLOW}AUTH FAIL${NC}"
  else echo -e "${RED}FAIL${NC}"; fi
}
echo "=== Provider Health Check ==="
check "DeepSeek"  "https://api.deepseek.com/v1/chat/completions" "deepseek-chat" "${DEEPSEEK_API_KEY:-}"
check "z.ai"      "https://api.z.ai/api/paas/v4/chat/completions" "glm-5.2" "${ZAI_API_KEY:-}"
check "Moonshot"  "https://api.moonshot.cn/v1/chat/completions" "kimi-k2.7-code" "${MOONSHOT_API_KEY:-}"
check "MiniMax"   "https://api.minimax.io/v1/chat/completions" "MiniMax-M3" "${MINIMAX_API_KEY:-}"
check "xAI"       "https://api.x.ai/v1/chat/completions" "grok-4.3" "${XAI_API_KEY:-}"
check "OpenAI"    "https://api.openai.com/v1/chat/completions" "gpt-5.5" "${OPENAI_API_KEY:-}"
check "Groq"      "https://api.groq.com/openai/v1/chat/completions" "llama-4-maverick" "${GROQ_API_KEY:-}"
check "Ollama"    "http://localhost:11434/v1/chat/completions" "llama3.2" "ollama"
check "LiteLLM"   "http://localhost:4000/v1/chat/completions" "gpt-4" "sk-litellm"
echo "Done."
