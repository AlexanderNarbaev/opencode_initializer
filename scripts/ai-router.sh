#!/usr/bin/env bash
# ai-router — AI Request Orchestrator for OpenCode
# Routes tasks to optimal provider/model based on complexity
set -euo pipefail

ORCHESTRATOR="$HOME/Projects/.opencode-orchestrator.json"

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
  for p in deepseek xai minimax moonshot mimo opencode; do
    case $p in
      deepseek) url="https://api.deepseek.com/v1/models"; key="${DEEPSEEK_API_KEY:-}" ;;
      xai) url="https://api.x.ai/v1/models"; key="${XAI_KEY:-}" ;;
      minimax) url="https://api.minimax.chat/v1/text/chatcompletion_v2"; key="${MINIMAX_KEY:-}" ;;
      moonshot) url="https://api.moonshot.cn/v1/models"; key="${MOONSHOT_KEY:-}" ;;
      *) continue ;;
    esac
    [ -z "$key" ] && { echo -e "  ${RED}✗${NC} $p — no key"; continue; }
    curl -s --connect-timeout 5 --max-time 10 "$url" -H "Authorization: Bearer $key" 2>/dev/null | python3 -c "import json,sys; json.load(sys.stdin)" 2>/dev/null && echo -e "  ${GREEN}✓${NC} $p" || echo -e "  ${RED}✗${NC} $p"
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

case "${1:-}" in
  task) shift; cmd_task "$@" ;;
  cost) cmd_cost ;;
  status) cmd_status ;;
  models) cmd_models ;;
  session-start) cmd_session_start "${2:-}" ;;
  -h|--help|help|"") usage ;;
  *) echo "Unknown: $1"; usage ;;
esac
