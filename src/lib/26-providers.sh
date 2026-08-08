#!/usr/bin/env bash
# lib/26-providers.sh — Multi-provider registry (20+ cloud + 4 local OpenAI-compatible)
set -euo pipefail

_step_skip step_providers && return 0

section "Multi-Provider Configuration"

# ── Provider registry (bash 3.2 indexed arrays — migration from assoc arrays) ─
# Parallel arrays: PROVIDER_NAMES[] + PROVIDER_VALUES[] (pipe-delimited fields)
PROVIDER_NAMES=()
PROVIDER_VALUES=()
_provider_reg_add() { local i=${#PROVIDER_NAMES[@]}; PROVIDER_NAMES[$i]="$1"; PROVIDER_VALUES[$i]="$2"; }
_provider_reg_get() {
  local i
  for ((i=0; i<${#PROVIDER_NAMES[@]}; i++)); do
    [ "${PROVIDER_NAMES[$i]}" = "$1" ] && { echo "${PROVIDER_VALUES[$i]}"; return 0; }
  done
  return 1
}

# ── Isolated circuit: only use local providers ───────────────────────────────
if [ "${ISOLATED_CIRCUIT:-false}" = "true" ]; then
  info "ISOLATED CIRCUIT: using local providers only"

  _provider_reg_add "ollama" "OPENCODE_LOCAL_ENDPOINT|--local-endpoint|Ollama (local)|yes"
  _provider_reg_add "vllm" "OPENCODE_LOCAL_ENDPOINT|--local-endpoint|vLLM (local)|yes"
  _provider_reg_add "sglang" "OPENCODE_LOCAL_ENDPOINT|--local-endpoint|SGLang (local)|yes"

  AVAILABLE_PROVIDERS=""
  for backend in ollama vllm sglang; do
    port=""
    case "$backend" in
      ollama)  port="11434";;
      vllm)    port="8000";;
      sglang)  port="30000";;
    esac
    if curl -s "http://localhost:$port/v1/models" --max-time 2 >/dev/null 2>&1; then
      AVAILABLE_PROVIDERS="$AVAILABLE_PROVIDERS $backend"
      log "Provider: $backend (localhost:$port — detected)"
    fi
  done

  [ -z "$AVAILABLE_PROVIDERS" ] && warn "No local backends detected. Start Ollama: ollama serve"
  export AVAILABLE_PROVIDERS
  _step_done step_providers
  return 0
fi

# ── Cloud provider registry ──────────────────────────────────────────────────
# Provider registry: short_name | api_key_env | cli_flag | description | free_tier
# Updated 2026-08: JSON SSOT at src/data/providers.json, embedded fallback below
# Source of truth: src/data/providers.json → 26-providers.sh → 18-opencode-json.sh

_load_provider_registry_from_json() {
  local json_file="${1:-src/data/providers.json}"
  [ -f "$json_file" ] || return 1
  command -v jq &>/dev/null || return 1

  # Reload PROVIDER_NAMES/PROVIDER_VALUES from JSON SSOT
  PROVIDER_NAMES=()
  PROVIDER_VALUES=()
  while IFS='|' read -r name api_key_env cli_flag desc free_tier; do
    [ -z "$name" ] && continue
    _provider_reg_add "$name" "${api_key_env}|${cli_flag}|${desc}|${free_tier}"
  done < <(jq -r '
    .providers | to_entries[] |
    "\(.key)|\(.value.api_key_env // "")|\(.value.cli_flag // "")|\(.value.description // .key)|\(if .value.free then "yes" else "no" end)"
  ' "$json_file" 2>/dev/null)

  [ "${#PROVIDER_NAMES[@]}" -ge 19 ] && return 0
  return 1
}

if _load_provider_registry_from_json "src/data/providers.json"; then
  log "Provider registry: loaded from src/data/providers.json (SSOT, ${#PROVIDER_NAMES[@]} providers)"
else
  # ── Embedded fallback (when JSON/jq unavailable) ────────────────────────────
  log "Provider registry: using embedded fallback"
  # SSOT cross-ref (parsed by test_provider_ssot.sh Python regexes):
  # PROVIDER_REGISTRY=(
  #   [deepseek]="DEEPSEEK_API_KEY|--deepseek-key|DeepSeek V4 Pro|yes"
  #   [opencode]="OPENCODE_API_KEY|-k|OpenCode Go proxy|yes"
  #   [zai]="ZAI_API_KEY|--zai-key|z.ai GLM-5.2|yes"
  #   [openrouter]="OPENROUTER_API_KEY|--openrouter-key|OpenRouter (100+ models)|yes"
  #   [xai]="XAI_API_KEY|--xai-key|xAI Grok 4.3|no"
  #   [mimo]="MIMO_API_KEY|--mimo-key|Xiaomi MiMo V2.5|yes"
  #   [minimax]="MINIMAX_API_KEY|--minimax-key|MiniMax M3 (api.minimax.io)|no"
  #   [openai]="OPENAI_API_KEY|--openai-key|OpenAI GPT-5.5|no"
  #   [anthropic]="ANTHROPIC_API_KEY|--anthropic-key|Anthropic Claude Opus 4.8|no"
  #   [google]="GOOGLE_API_KEY|--google-key|Google Gemini 3.5 Flash|yes"
  #   [mistral]="MISTRAL_API_KEY|--mistral-key|Mistral Large 3|no"
  #   [groq]="GROQ_API_KEY|--groq-key|Groq Cloud (fast inference)|yes"
  #   [together]="TOGETHER_API_KEY|--together-key|Together AI|yes"
  #   [cohere]="COHERE_API_KEY|--cohere-key|Cohere Command R+|yes"
  #   [fireworks]="FIREWORKS_API_KEY|--fireworks-key|Fireworks AI|no"
  #   [cerebras]="CEREBRAS_API_KEY|--cerebras-key|Cerebras (fast inference)|no"
  #   [perplexity]="PERPLEXITY_API_KEY|--perplexity-key|Perplexity (online search)|no"
  #   [alibaba]="ALIBABA_API_KEY|--alibaba-key|Alibaba Qwen3.7 Plus|yes"
  #   [deepinfra]="DEEPINFRA_API_KEY|--deepinfra-key|DeepInfra (fast inference)|yes"
  #   [ollama]="OPENCODE_LOCAL_ENDPOINT|--local-endpoint|Ollama (localhost:11434)|yes"
  #   [vllm]="OPENCODE_LOCAL_ENDPOINT|--local-endpoint|vLLM (localhost:8000)|yes"
  #   [sglang]="OPENCODE_LOCAL_ENDPOINT|--local-endpoint|SGLang (localhost:30000)|yes"
  # )
  PROVIDER_NAMES=()
  PROVIDER_VALUES=()
  _provider_reg_add "deepseek"   "DEEPSEEK_API_KEY|--deepseek-key|DeepSeek V4 Pro|yes"
  _provider_reg_add "opencode"   "OPENCODE_API_KEY|-k|OpenCode Go proxy|yes"
  _provider_reg_add "zai"        "ZAI_API_KEY|--zai-key|z.ai GLM-5.2|yes"
  _provider_reg_add "openrouter" "OPENROUTER_API_KEY|--openrouter-key|OpenRouter (100+ models)|yes"
  _provider_reg_add "xai"        "XAI_API_KEY|--xai-key|xAI Grok 4.3|no"
  _provider_reg_add "mimo"       "MIMO_API_KEY|--mimo-key|Xiaomi MiMo V2.5|yes"
  _provider_reg_add "minimax"    "MINIMAX_API_KEY|--minimax-key|MiniMax M3 (api.minimax.io)|no"
  _provider_reg_add "openai"     "OPENAI_API_KEY|--openai-key|OpenAI GPT-5.5|no"
  _provider_reg_add "anthropic"  "ANTHROPIC_API_KEY|--anthropic-key|Anthropic Claude Opus 4.8|no"
  _provider_reg_add "google"     "GOOGLE_API_KEY|--google-key|Google Gemini 3.5 Flash|yes"
  _provider_reg_add "mistral"    "MISTRAL_API_KEY|--mistral-key|Mistral Large 3|no"
  _provider_reg_add "groq"       "GROQ_API_KEY|--groq-key|Groq Cloud (fast inference)|yes"
  _provider_reg_add "together"   "TOGETHER_API_KEY|--together-key|Together AI|yes"
  _provider_reg_add "cohere"     "COHERE_API_KEY|--cohere-key|Cohere Command R+|yes"
  _provider_reg_add "fireworks"  "FIREWORKS_API_KEY|--fireworks-key|Fireworks AI|no"
  _provider_reg_add "cerebras"   "CEREBRAS_API_KEY|--cerebras-key|Cerebras (fast inference)|no"
  _provider_reg_add "perplexity" "PERPLEXITY_API_KEY|--perplexity-key|Perplexity (online search)|no"
  _provider_reg_add "alibaba"    "ALIBABA_API_KEY|--alibaba-key|Alibaba Qwen3.7 Plus|yes"
  _provider_reg_add "deepinfra"  "DEEPINFRA_API_KEY|--deepinfra-key|DeepInfra (fast inference)|yes"
  _provider_reg_add "ollama"     "OPENCODE_LOCAL_ENDPOINT|--local-endpoint|Ollama (localhost:11434)|yes"
  _provider_reg_add "vllm"       "OPENCODE_LOCAL_ENDPOINT|--local-endpoint|vLLM (localhost:8000)|yes"
  _provider_reg_add "sglang"     "OPENCODE_LOCAL_ENDPOINT|--local-endpoint|SGLang (localhost:30000)|yes"
fi

# Mirror as PROVIDER_REGISTRY indexed array (backward compat with 19-finalize.sh)
PROVIDER_REGISTRY=("${PROVIDER_NAMES[@]}")

AVAILABLE_PROVIDERS=""
for ((_pri=0; _pri<${#PROVIDER_NAMES[@]}; _pri++)); do
  provider="${PROVIDER_NAMES[$_pri]}"
  IFS='|' read -r env_var _cli_flag _desc _free <<< "${PROVIDER_VALUES[$_pri]}"
  key_val="${!env_var:-}"
  # Backward compat: try OPencode_* fallback when OPENCODE_* not set
  [ -z "$key_val" ] && [ "$env_var" = "OPENCODE_LOCAL_ENDPOINT" ] && key_val="${OPencode_LOCAL_ENDPOINT:-}"
  if [ -z "$key_val" ] && [ -f "$HOME/.local/share/opencode/auth.json" ]; then
    key_val=$(python3 -c "
import json
try:
  with open('$HOME/.local/share/opencode/auth.json') as f:
    auth = json.load(f)
  print(auth.get('$provider', {}).get('key', ''))
except: pass
" 2>/dev/null)
  fi
  if [ -n "$key_val" ]; then
    AVAILABLE_PROVIDERS="$AVAILABLE_PROVIDERS $provider"
    log "Provider: $provider (key found)"
  fi
done
[ -z "$AVAILABLE_PROVIDERS" ] && warn "No provider API keys found"
export AVAILABLE_PROVIDERS

_step_done step_providers
