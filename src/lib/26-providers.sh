#!/usr/bin/env bash
# lib/26-providers.sh — Multi-provider registry (15+ LLM providers)
set -euo pipefail

_step_skip step_providers && return 0

section "Multi-Provider Configuration"

# Provider registry: short_name | api_key_env | cli_flag | description | free_tier
declare -A PROVIDER_REGISTRY
PROVIDER_REGISTRY=(
  [deepseek]="DEEPSEEK_API_KEY|--deepseek-key|DeepSeek V4 Pro|yes"
  [opencode]="OPENCODE_API_KEY|-k|OpenCode Go proxy|yes"
  [xai]="XAI_API_KEY|--xai-key|xAI Grok 3|no"
  [mimo]="MIMO_API_KEY|--mimo-key|Xiaomi MiMo V2|yes"
  [moonshot]="MOONSHOT_API_KEY|--moonshot-key|Moonshot Kimi K2.6|no"
  [minimax]="MINIMAX_API_KEY|--minimax-key|MiniMax M3|no"
  [openai]="OPENAI_API_KEY|--openai-key|OpenAI GPT-5|no"
  [anthropic]="ANTHROPIC_API_KEY|--anthropic-key|Anthropic Claude 4|no"
  [google]="GOOGLE_API_KEY|--google-key|Google Gemini 2.5|yes"
  [mistral]="MISTRAL_API_KEY|--mistral-key|Mistral Large 3|no"
  [groq]="GROQ_API_KEY|--groq-key|Groq Cloud (fast inference)|yes"
  [together]="TOGETHER_API_KEY|--together-key|Together AI|yes"
  [cohere]="COHERE_API_KEY|--cohere-key|Cohere Command R+|yes"
  [fireworks]="FIREWORKS_API_KEY|--fireworks-key|Fireworks AI|no"
  [cerebras]="CEREBRAS_API_KEY|--cerebras-key|Cerebras (fast inference)|no"
  [perplexity]="PERPLEXITY_API_KEY|--perplexity-key|Perplexity (online search)|no"
)

AVAILABLE_PROVIDERS=""
for provider in "${!PROVIDER_REGISTRY[@]}"; do
  IFS='|' read -r env_var _cli_flag _desc _free <<< "${PROVIDER_REGISTRY[$provider]}"
  key_val="${!env_var:-}"
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
