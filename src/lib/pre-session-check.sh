#!/usr/bin/env bash
# lib/pre-session-check.sh — Pre-session provider & model validation
# Source this in ~/.zshrc: source ~/opencode_initializer/src/lib/pre-session-check.sh && _pre_session
# NOTE: do NOT set -euo pipefail here — this file is sourced into interactive ZSH

_pre_session() {
  local GREEN='\033[0;32m' YELLOW='\033[1;33m' RED='\033[0;31m' CYAN='\033[0;36m' NC='\033[0m'
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

  # Check each provider
  local available=0
  _check_provider "DeepSeek"   "https://api.deepseek.com/v1/models"       "${DEEPSEEK_API_KEY:-}" && available=$((available+1)) || true
  _check_provider "OpenCodeGo" "https://api.opencode.ai/v1/models"        "${OPENCODE_API_KEY:-}"  && available=$((available+1)) || true
  _check_provider "Grok/xAI"   "https://api.x.ai/v1/models"               "${XAI_KEY:-}"           && available=$((available+1)) || true
  _check_provider "MiniMax"    "https://api.minimax.chat/v1/text/chatcompletion_v2" "${MINIMAX_KEY:-}" && available=$((available+1)) || true
  _check_provider "Moonshot"   "https://api.moonshot.cn/v1/models"        "${MOONSHOT_KEY:-}"      && available=$((available+1)) || true

  # ── Model cost estimates (per 1M tokens, June 2026) ──
  echo -e "${CYAN}--- Model Costs (per 1M tokens) ---${NC}"
  cat <<'COSTS'
  deepseek-v4-pro       $0.55  input / $2.19  output  (thinking: auto)
  deepseek-v4-flash     $0.14  input / $0.55  output  (non-thinking)
  grok-4.3              $2.00  input / $8.00  output  (fast, great code)
  minimax-M1            $0.40  input / $1.60  output  (budget reasoning)
COSTS

  # ── MCP status ──
  echo -e "${CYAN}--- MCP Servers ---${NC}"
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

  # ── ChromaDB ──
  curl -sf http://127.0.0.1:8000/api/v2/heartbeat &>/dev/null && echo -e "${GREEN}✓${NC} ChromaDB online" || echo -e "${RED}✗${NC} ChromaDB offline"

  # ── OpenCode config ──
  local cfg="$HOME/.config/opencode/opencode.json"
  if [ -f "$cfg" ]; then
    python3 -c "
import json; d=json.load(open('$cfg'))
print(f\"  Model: {d.get('model','?')}\")
print(f\"  Small: {d.get('small_model','?')}\")
print(f\"  Providers: {len(d.get('provider',{}))}  MCPs: {len(d.get('mcp',{}))}  LSPs: {len(d.get('lsp',{}))}  Plugins: {len(d.get('plugin',[]))}\")
" 2>/dev/null
  fi

  echo -e "${CYAN}=== ${available} provider(s) available ===${NC}"
  echo
}
