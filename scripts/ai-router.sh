#!/usr/bin/env bash
# ai-router — AI Request Orchestrator for OpenCode
# Routes tasks to optimal provider/model based on complexity
set -euo pipefail

ORCHESTRATOR="$HOME/Projects/.opencode-orchestrator.json"
PROVIDERS_JSON="${PROVIDERS_JSON:-src/data/providers.json}"

# ── Load providers from SSOT JSON ──────────────────────────────────────────
# Returns: space-separated provider names; falls back to embedded list
_load_providers_from_json() {
  local json_file="$1"
  [ -f "$json_file" ] && command -v jq &>/dev/null && {
    jq -r '.providers | keys[]' "$json_file" 2>/dev/null | tr '\n' ' '
    return 0
  }
  # Embedded fallback (19 cloud providers from providers.json as of v3.0)
  echo "deepseek opencode zai xai minimax mimo openai anthropic google mistral groq together cohere fireworks cerebras perplexity alibaba deepinfra ollama vllm sglang openrouter"
  return 0
}

# ── Get provider API key env var from JSON ─────────────────────────────────
_provider_env_from_json() {
  local provider="$1" json_file="$2"
  [ -f "$json_file" ] && command -v jq &>/dev/null && {
    jq -r ".providers.\"$provider\".api_key_env // \"\"" "$json_file" 2>/dev/null
    return 0
  }
  # Fallback for well-known providers
  case "$provider" in
    deepseek) echo "DEEPSEEK_API_KEY" ;;
    xai) echo "XAI_API_KEY" ;;
    openai) echo "OPENAI_API_KEY" ;;
    anthropic) echo "ANTHROPIC_API_KEY" ;;
    google) echo "GOOGLE_API_KEY" ;;
    mistral) echo "MISTRAL_API_KEY" ;;
    groq) echo "GROQ_API_KEY" ;;
    *) echo "" ;;
  esac
}

usage() {
  echo "ai-router — OpenCode Request Orchestrator"
  echo "  ai-router task <description>  — show recommended model for a task"
  echo "  ai-router cost                 — show cost summary for all models"
  echo "  ai-router status               — check all providers"
  echo "  ai-router models               — list available models with costs"
  echo "  ai-router session-start <project> — initialize session with optimal config"
  exit 0
}

cmd_status() {
  echo "=== Provider Status ==="
  local GREEN='\033[0;32m' RED='\033[0;31m' NC='\033[0m'
  # Load providers from SSOT JSON (with embedded fallback)
  local providers
  providers=$(_load_providers_from_json "$PROVIDERS_JSON")
  for p in $providers; do
    local key_env key_val url
    key_env=$(_provider_env_from_json "$p" "$PROVIDERS_JSON")
    key_val="${!key_env:-}"
    # Build health-check URL per provider
    case $p in
      deepseek) url="https://api.deepseek.com/v1/models" ;;
      openai) url="https://api.openai.com/v1/models" ;;
      anthropic) url="https://api.anthropic.com/v1/models" ;;
      google) url="https://generativelanguage.googleapis.com/v1/models" ;;
      mistral) url="https://api.mistral.ai/v1/models" ;;
      groq) url="https://api.groq.com/openai/v1/models" ;;
      together) url="https://api.together.xyz/v1/models" ;;
      cohere) url="https://api.cohere.ai/v1/models" ;;
      xai) url="https://api.x.ai/v1/models" ;;
      minimax) url="https://api.minimax.io/v1/models" ;;
      openrouter) url="https://openrouter.ai/api/v1/models" ;;
      *) continue ;;  # local providers (ollama/vllm/sglang) + unknown — skip HTTP check
    esac
    [ -z "$key_val" ] && { echo -e "  ${RED}✗${NC} $p — no key ($key_env)"; continue; }
    curl -s --connect-timeout 5 --max-time 10 "$url" -H "Authorization: Bearer $key_val" 2>/dev/null | python3 -c "import json,sys; json.load(sys.stdin)" 2>/dev/null && echo -e "  ${GREEN}✓${NC} $p" || echo -e "  ${RED}✗${NC} $p"
  done
}

cmd_models() {
  echo "=== Available Models & Costs ==="
  cat <<'EOF'
Provider  | Model              | Input/1M  | Output/1M | Best for
----------|--------------------|-----------|-----------|----------
DeepSeek  | v4-pro             | $0.55     | $2.19     | Complex reasoning, architecture
DeepSeek  | v4-flash           | $0.14     | $0.55     | Fast tasks, code review, docs
Grok/xAI  | grok-4.3           | $2.00     | $8.00     | UI design, QA, alternative
MiniMax   | M1                 | $0.40     | $1.60     | Budget reasoning
EOF
}

cmd_cost() {
  echo "=== Cost Optimization Guide ==="
  echo "Best value chain:"
  echo "  1. Simple tasks → deepseek-v4-flash (\$0.14/1M input)"
  echo "  2. Medium tasks → deepseek-v4-pro (\$0.55/1M input)"  
  echo "  3. Complex reasoning → deepseek-v4-pro + thinking (\$2.19/1M output)"
  echo "  4. Alternative → grok-4.3 (higher cost, different style)"
  echo "  5. Budget → minimax-M1 (\$0.40/1M input)"
  echo ""
  echo "Savings tip: use /model deepseek/deepseek-v4-flash for simple edits"
}

cmd_task() {
  local task="$*"
  echo "Task: $task"
  echo ""
  # Simple heuristic routing
  if echo "$task" | grep -qiE 'fix|typo|comment|rename|format|simple|small|minor'; then
    echo "→ Router: SIMPLE"
    echo "→ Model: deepseek/deepseek-v4-flash"
    echo "→ Command: /model deepseek/deepseek-v4-flash"
  elif echo "$task" | grep -qiE 'architect|design system|security|audit|complex|hard|deep|research'; then
    echo "→ Router: COMPLEX (with thinking)"
    echo "→ Model: deepseek/deepseek-v4-pro"
    echo "→ Command: /model deepseek/deepseek-v4-pro"
  elif echo "$task" | grep -qiE 'ui|design|creative|visual|frontend|css|style'; then
    echo "→ Router: UI/CREATIVE"
    echo "→ Model: xai/grok-4.3"
    echo "→ Command: /model xai/grok-4.3"
  else
    echo "→ Router: MEDIUM (default)"
    echo "→ Model: deepseek/deepseek-v4-pro"
    echo "→ Command: /model deepseek/deepseek-v4-pro"
  fi
}

cmd_session_start() {
  local project="${1:-default}"
  echo "=== Session Start: $project ==="
  echo "→ Pre-check: _pre_session"
  echo "→ Model: deepseek/deepseek-v4-pro (reasoning)"
  echo "→ Fast model: deepseek/deepseek-v4-flash"
  echo "→ Start: cd ~/Projects/$project && opencode"
  echo ""
  cmd_cost
}

cmd_verify() {
  echo "=== SSOT Verification ==="
  local json_file="$1"
  [ ! -f "$json_file" ] && { echo "FAIL: $json_file not found"; exit 1; }
  command -v jq &>/dev/null || { echo "SKIP: jq not available"; exit 0; }
  local json_providers embedded_providers missing extra
  json_providers=$(jq -r '.providers | keys[]' "$json_file" | sort)
  embedded_providers=$(echo "deepseek opencode zai xai minimax mimo openai anthropic google mistral groq together cohere fireworks cerebras perplexity alibaba deepinfra ollama vllm sglang openrouter" | tr ' ' '\n' | sort)
  missing=$(comm -23 <(echo "$json_providers") <(echo "$embedded_providers") | tr '\n' ' ')
  extra=$(comm -13 <(echo "$json_providers") <(echo "$embedded_providers") | tr '\n' ' ')
  [ -n "$missing" ] && echo "WARN: in JSON but not in embedded fallback: $missing" || echo "OK: json providers ⊆ embedded fallback"
  [ -n "$extra" ] && echo "WARN: in embedded but not in JSON: $extra" || echo "OK: embedded fallback ⊆ json providers"
  [ -z "$missing" ] && [ -z "$extra" ] && { echo "PASS: providers.json == embedded fallback (SSOT clean)"; return 0; }
  return 1
}

case "${1:-}" in
  task) shift; cmd_task "$@" ;;
  cost) cmd_cost ;;
  status) cmd_status ;;
  models) cmd_models ;;
  session-start) cmd_session_start "${2:-}" ;;
  verify) cmd_verify "${2:-$PROVIDERS_JSON}" ;;
  -h|--help|help|"") usage ;;
  *) echo "Unknown: $1"; usage ;;
esac
