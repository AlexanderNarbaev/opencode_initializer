#!/usr/bin/env bash
# lib/pre-session-check.sh — Pre-session provider & model validation
# Source this in ~/.zshrc: source ~/opencode_initializer/src/lib/pre-session-check.sh && _pre_session
# NOTE: do NOT set -euo pipefail here — this file is sourced into interactive ZSH

_pre_session() {
  local GREEN='\033[0;32m' YELLOW='\033[1;33m' RED='\033[0;31m' CYAN='\033[0;36m' BOLD='\033[1m' NC='\033[0m'
  local SECRETS="$HOME/.config/opencode/secrets.env"

  echo -e "${CYAN}=== Pre-Session Check ===${NC}"

  # ── Provider validation ──
  _check_provider() {
    local name="$1" url="$2" key="$3"
    if [ -z "$key" ]; then echo -e "  ${YELLOW}⊘${NC} $name — no key"; return 1; fi
    local resp
    resp=$(curl -s --connect-timeout 5 --max-time 10 "$url" -H "Authorization: Bearer $key" 2>/dev/null)
    if echo "$resp" | python3 -c "import json,sys; json.load(sys.stdin)" 2>/dev/null; then
      local models
      models=$(echo "$resp" | python3 -c "import json,sys; d=json.load(sys.stdin); print(len(d.get('data',[])))" 2>/dev/null)
      echo -e "  ${GREEN}✓${NC} $name — $models model(s)"
      return 0
    else
      echo -e "  ${RED}✗${NC} $name — unreachable"
      return 1
    fi
  }

  # Load secrets
  if [ -f "$SECRETS" ]; then
    set -a
    # shellcheck disable=SC1090
    source "$SECRETS" 2>/dev/null
    set +a
  fi

  # Check each provider (all 24)
  local available=0
  echo -e "${BOLD}--- Cloud Providers ---${NC}"
  _check_provider "DeepSeek"     "https://api.deepseek.com/v1/models"              "${DEEPSEEK_API_KEY:-}"       && available=$((available+1)) || true
  _check_provider "z.ai GLM"     "https://api.z.ai/api/paas/v4/models"             "${ZAI_API_KEY:-}"            && available=$((available+1)) || true
  _check_provider "OpenRouter"   "https://openrouter.ai/api/v1/models"             "${OPENROUTER_API_KEY:-}"     && available=$((available+1)) || true
  _check_provider "OpenAI"       "https://api.openai.com/v1/models"                "${OPENAI_API_KEY:-}"         && available=$((available+1)) || true
  _check_provider "Anthropic"    "https://api.anthropic.com/v1/models"             "${ANTHROPIC_API_KEY:-}"      && available=$((available+1)) || true
  _check_provider "Google"       "https://generativelanguage.googleapis.com/v1beta/models?key=${GOOGLE_API_KEY:-}" "${GOOGLE_API_KEY:-}" && available=$((available+1)) || true
  _check_provider "xAI Grok"     "https://api.x.ai/v1/models"                      "${XAI_API_KEY:-}"            && available=$((available+1)) || true
  _check_provider "Moonshot"     "https://api.moonshot.cn/v1/models"               "${MOONSHOT_API_KEY:-}"       && available=$((available+1)) || true
  _check_provider "Alibaba"      "https://dashscope.aliyuncs.com/compatible-mode/v1/models" "${ALIBABA_API_KEY:-}"  && available=$((available+1)) || true
  _check_provider "MiniMax"      "https://api.minimax.chat/v1/text/chatcompletion_v2" "${MINIMAX_API_KEY:-}"      && available=$((available+1)) || true
  _check_provider "Mistral"      "https://api.mistral.ai/v1/models"                "${MISTRAL_API_KEY:-}"        && available=$((available+1)) || true
  _check_provider "Groq"         "https://api.groq.com/openai/v1/models"           "${GROQ_API_KEY:-}"           && available=$((available+1)) || true
  _check_provider "Together"     "https://api.together.xyz/v1/models"              "${TOGETHER_API_KEY:-}"       && available=$((available+1)) || true
  _check_provider "Cohere"       "https://api.cohere.com/v1/models"                "${COHERE_API_KEY:-}"         && available=$((available+1)) || true
  _check_provider "DeepInfra"    "https://api.deepinfra.com/v1/openai/models"      "${DEEPINFRA_API_KEY:-}"      && available=$((available+1)) || true
  _check_provider "Perplexity"   "https://api.perplexity.ai/models"                "${PERPLEXITY_API_KEY:-}"     && available=$((available+1)) || true

  # ── Local backends ──
  echo -e "${BOLD}--- Local Backends ---${NC}"
  for backend in ollama:11434 litellm:4000 vllm:8000 sglang:30000; do
    name="${backend%%:*}"
    port="${backend##*:}"
    if curl -sf "http://localhost:$port/v1/models" --max-time 2 >/dev/null 2>&1; then
      local_count=$(curl -s "http://localhost:$port/v1/models" 2>/dev/null | python3 -c "import json,sys; d=json.load(sys.stdin); print(len(d.get('data',[])))" 2>/dev/null || echo "?")
      echo -e "  ${GREEN}✓${NC} $name (port $port) — $local_count model(s)"
      available=$((available+1))
    else
      echo -e "  ${YELLOW}○${NC} $name (port $port) — not running"
    fi
  done

  # ── Model recommendations ──
  echo -e "${BOLD}--- Model Recommendations ---${NC}"
  local ROUTER="$HOME/.config/opencode/model-router/recommend.sh"
  if [ -f "$ROUTER" ]; then
    echo -e "  ${CYAN}Coding:${NC}     $(bash "$ROUTER" coding 2>/dev/null | grep '^Model:' | sed 's/Model: //')"
    echo -e "  ${CYAN}Reasoning:${NC}  $(bash "$ROUTER" reasoning 2>/dev/null | grep '^Model:' | sed 's/Model: //')"
    echo -e "  ${CYAN}Fast:${NC}       $(bash "$ROUTER" fast 2>/dev/null | grep '^Model:' | sed 's/Model: //')"
    echo -e "  ${CYAN}Budget:${NC}     $(bash "$ROUTER" budget 2>/dev/null | grep '^Model:' | sed 's/Model: //')"
    echo -e "  ${CYAN}RU/CN:${NC}      $(bash "$ROUTER" ru_cn 2>/dev/null | grep '^Model:' | sed 's/Model: //')"
    echo -e "  ${CYAN}Isolated:${NC}   $(bash "$ROUTER" isolated 2>/dev/null | grep '^Model:' | sed 's/Model: //')"
  else
    echo "  Model router not installed. Run: bash setup.sh --full"
  fi

  # ── MCP status ──
  echo -e "${BOLD}--- MCP Servers ---${NC}"
  local mcp_ok=0 mcp_miss=0
  for mcp in c7-mcp-server mcp-server-filesystem agentic-tools-mcp codegraph playwright-mcp agent-browser-mcp-server chrome-devtools-mcp mcp-server-github mcp-server-postgres mcp-server-gitlab mcp-server-google-maps mcp-server-sequential-thinking memorylayer-mcp loopsense mcp-server-sqlite excalidraw-architect-mcp context7-mcp notion-mcp-server; do
    if [ -x "$HOME/.bun/bin/$mcp" ] || which "$mcp" &>/dev/null; then
      mcp_ok=$((mcp_ok+1))
    else
      echo -e "  ${RED}✗${NC} $mcp"
      mcp_miss=$((mcp_miss+1))
    fi
  done
  echo -e "  ${GREEN}${mcp_ok} ready${NC}, ${RED}${mcp_miss} missing${NC}"

  # ── Infrastructure ──
  echo -e "${BOLD}--- Infrastructure ---${NC}"
  curl -sf http://127.0.0.1:8000/api/v2/heartbeat &>/dev/null && echo -e "  ${GREEN}✓${NC} ChromaDB online" || echo -e "  ${YELLOW}○${NC} ChromaDB offline"
  docker ps --format '{{.Names}}' 2>/dev/null | grep -q opencode-memorylayer && echo -e "  ${GREEN}✓${NC} MemoryLayer online" || echo -e "  ${YELLOW}○${NC} MemoryLayer offline"
  docker ps --format '{{.Names}}' 2>/dev/null | grep -q postgres && echo -e "  ${GREEN}✓${NC} PostgreSQL online" || echo -e "  ${YELLOW}○${NC} PostgreSQL offline"
  docker ps --format '{{.Names}}' 2>/dev/null | grep -q qdrant && echo -e "  ${GREEN}✓${NC} Qdrant online" || echo -e "  ${YELLOW}○${NC} Qdrant offline"
  docker ps --format '{{.Names}}' 2>/dev/null | grep -q redis && echo -e "  ${GREEN}✓${NC} Redis online" || echo -e "  ${YELLOW}○${NC} Redis offline"

  # ── OpenCode config ──
  local cfg="$HOME/.config/opencode/opencode.json"
  if [ -f "$cfg" ]; then
    echo -e "${BOLD}--- OpenCode Config ---${NC}"
    python3 -c "
import json; d=json.load(open('$cfg'))
print(f\"  Model: {d.get('model','?')}\")
print(f\"  Small: {d.get('small_model','?')}\")
print(f\"  Providers: {len(d.get('provider',{}))}  MCPs: {len(d.get('mcp',{}))}  LSPs: {len(d.get('lsp',{}))}  Plugins: {len(d.get('plugin',[]))}\")
isolated = d.get('experimental',{}).get('model_router_dir', '')
if isolated:
    print(f\"  Model Router: {isolated}\")
" 2>/dev/null
  fi

  echo -e "${CYAN}=== ${available} provider(s) available ===${NC}"
  echo -e "${CYAN}Use 'dev models <task>' for task-specific model recommendations${NC}"
  echo
}
