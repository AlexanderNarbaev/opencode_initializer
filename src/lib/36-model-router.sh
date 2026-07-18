#!/usr/bin/env bash
# src/lib/36-model-router.sh — Model Routing Intelligence
# Task-based model selection, cost optimization, performance evaluation
set -euo pipefail

_step_skip step_model_router && return 0

section "Model Routing Intelligence"

ROUTER_DIR="$HOME/.config/opencode/model-router"
mkdir -p "$ROUTER_DIR"

# ── Task profiles ────────────────────────────────────────────────────────────
# Each profile maps a task type to the best model + fallback chain
# Models verified against models.dev (2026-07-03)

cat >"$ROUTER_DIR/task-profiles.json" <<'PROFILES'
{
  "coding": {
    "description": "Primary coding, implementation, refactoring",
    "model": "deepseek/deepseek-v4-pro",
    "small_model": "deepseek/deepseek-v4-flash",
    "fallback": ["zai/glm-5.2", "anthropic/claude-opus-4-8", "moonshotai/kimi-k2.7-code-highspeed"],
    "rationale": "DeepSeek V4 Pro: best price/performance for coding, 1M context, free tier. Moonshot highspeed for fast code iterations"
  },
  "reasoning": {
    "description": "Complex reasoning, architecture, planning",
    "model": "anthropic/claude-opus-4-8",
    "small_model": "anthropic/claude-sonnet-4-6",
    "fallback": ["zai/glm-5.2", "openai/gpt-5.5", "deepseek/deepseek-v4-pro"],
    "rationale": "Claude Opus 4.8: deepest reasoning, 1M context, tool use"
  },
  "fast": {
    "description": "Quick answers, exploration, compaction",
    "model": "deepseek/deepseek-v4-flash",
    "small_model": "deepseek/deepseek-v4-flash",
    "fallback": ["zai/glm-5-turbo", "google/gemini-3.5-flash", "groq/llama-4-maverick"],
    "rationale": "DeepSeek Flash: fastest, cheapest, 1M context, free tier"
  },
  "agentic": {
    "description": "Tool use, multi-step workflows, autonomous agents",
    "model": "moonshotai/kimi-k3",
    "small_model": "moonshotai/kimi-k2.7-code",
    "fallback": ["zai/glm-5.2", "deepseek/deepseek-v4-pro", "anthropic/claude-opus-4-8"],
    "rationale": "Kimi K3: flagship model, 1M context, best agentic tool use, open weights"
  },
  "budget": {
    "description": "Cost-sensitive tasks, bulk operations",
    "model": "zai/glm-5.2",
    "small_model": "zai/glm-5-turbo",
    "fallback": ["deepseek/deepseek-v4-flash", "google/gemini-3.5-flash", "groq/llama-4-maverick"],
    "rationale": "GLM-5.2: free tier, 1M context, open weights, strong coding"
  },
  "vision": {
    "description": "Image analysis, multimodal tasks",
    "model": "google/gemini-3.5-flash",
    "small_model": "google/gemini-3.1-flash-lite",
    "fallback": ["anthropic/claude-opus-4-8", "openai/gpt-5.5"],
    "rationale": "Gemini 3.5 Flash: best multimodal, 1M context, free tier"
  },
  "isolated": {
    "description": "Air-gapped operation (Isolated Circuit Mode)",
    "model": "ollama/qwen3:32b",
    "small_model": "ollama/qwen3:14b",
    "fallback": ["litellm/ollama/qwen3:32b", "vllm/qwen3:32b", "sglang/qwen3:32b"],
    "rationale": "Qwen3 32B: best local coding model, fits in 20GB VRAM"
  },
  "ru_cn": {
    "description": "Optimized for Russian/Chinese language tasks",
    "model": "zai/glm-5.2",
    "small_model": "zai/glm-5-turbo",
    "fallback": ["deepseek/deepseek-v4-pro", "moonshotai/kimi-k3", "alibaba/qwen3.7-plus"],
    "rationale": "GLM-5.2: best RU/CN language support, free tier, open weights"
  }
}
PROFILES

log "Task profiles written to $ROUTER_DIR/task-profiles.json"

# ── Cost table (per 1M tokens, from models.dev 2026-07) ─────────────────────

cat >"$ROUTER_DIR/cost-table.json" <<'COSTS'
{
  "deepseek/deepseek-v4-pro": {"input": 0.00, "output": 0.00, "context": 1000000, "free": true},
  "deepseek/deepseek-v4-flash": {"input": 0.00, "output": 0.00, "context": 1000000, "free": true},
  "zai/glm-5.2": {"input": 0.00, "output": 0.00, "context": 1000000, "free": true},
  "zai/glm-5-turbo": {"input": 1.20, "output": 4.00, "context": 200000, "free": false},
  "anthropic/claude-opus-4-8": {"input": 0.00, "output": 0.00, "context": 1000000, "free": true},
  "anthropic/claude-sonnet-4-6": {"input": 0.00, "output": 0.00, "context": 1000000, "free": true},
  "openai/gpt-5.5": {"input": 0.00, "output": 0.00, "context": 1050000, "free": true},
  "openai/gpt-5.4-mini": {"input": 0.00, "output": 0.00, "context": 400000, "free": true},
  "google/gemini-3.5-flash": {"input": 1.50, "output": 9.00, "context": 1048576, "free": false},
  "google/gemini-3.1-flash-lite": {"input": 0.25, "output": 1.50, "context": 1048576, "free": false},
  "xai/grok-4.3": {"input": 0.00, "output": 0.00, "context": 1000000, "free": true},
  "moonshotai/kimi-k3": {"input": 0.00, "output": 0.00, "context": 1000000, "free": true, "note": "Flagship 2.8T params, reasoning_effort:max"},
  "moonshotai/kimi-k2.7-code": {"input": 0.00, "output": 0.00, "context": 262144, "free": true},
  "moonshotai/kimi-k2.7-code-highspeed": {"input": 0.00, "output": 0.00, "context": 262144, "free": true},
  "moonshotai/kimi-k2.6": {"input": 0.00, "output": 0.00, "context": 262144, "free": true},
  "alibaba/qwen3.7-plus": {"input": 0.00, "output": 0.00, "context": 1000000, "free": true},
  "minimax/MiniMax-M3": {"input": 0.00, "output": 0.00, "context": 512000, "free": true},
  "groq/llama-4-maverick": {"input": 0.00, "output": 0.00, "context": 1000000, "free": true},
  "ollama/qwen3:32b": {"input": 0.00, "output": 0.00, "context": 131072, "free": true, "local": true},
  "ollama/qwen3:14b": {"input": 0.00, "output": 0.00, "context": 131072, "free": true, "local": true}
}
COSTS

log "Cost table written to $ROUTER_DIR/cost-table.json"

# ── Model recommendation script ─────────────────────────────────────────────

cat >"$ROUTER_DIR/recommend.sh" <<'RECOMMEND'
#!/usr/bin/env bash
# recommend.sh — Recommend best model for a task type
# Usage: recommend.sh <task-type> [--json]
# Task types: coding, reasoning, fast, agentic, budget, vision, isolated, ru_cn

set -euo pipefail
ROUTER_DIR="$(cd "$(dirname "$0")" && pwd)"
PROFILES="$ROUTER_DIR/task-profiles.json"
COSTS="$ROUTER_DIR/cost-table.json"

TASK="${1:-coding}"
JSON="${2:-}"

if [ ! -f "$PROFILES" ]; then
  echo "Error: task-profiles.json not found" >&2
  exit 1
fi

if [ "$JSON" = "--json" ]; then
  python3 -c "
import json, sys
profiles = json.load(open('$PROFILES'))
costs = json.load(open('$COSTS'))
task = '$TASK'
if task not in profiles:
    print(f'Error: unknown task type \"{task}\". Available: {\", \".join(profiles.keys())}', file=sys.stderr)
    sys.exit(1)
p = profiles[task]
model = p['model']
cost = costs.get(model, {})
result = {
    'task': task,
    'description': p['description'],
    'model': model,
    'small_model': p['small_model'],
    'fallback': p['fallback'],
    'rationale': p['rationale'],
    'cost_per_1m': cost,
}
print(json.dumps(result, indent=2))
"
else
  python3 -c "
import json
profiles = json.load(open('$PROFILES'))
costs = json.load(open('$COSTS'))
task = '$TASK'
if task not in profiles:
    print(f'Error: unknown task type \"{task}\". Available: {\", \".join(profiles.keys())}')
    exit(1)
p = profiles[task]
model = p['model']
cost = costs.get(model, {})
free = 'FREE' if cost.get('free', False) else f\"\${cost.get('input',0):.2f}/\${cost.get('output',0):.2f}\"
print(f'Task: {task}')
print(f'Description: {p[\"description\"]}')
print(f'Model: {model} ({free})')
print(f'Small: {p[\"small_model\"]}')
print(f'Fallback: {\" → \".join(p[\"fallback\"])}')
print(f'Rationale: {p[\"rationale\"]}')
print(f'Context: {cost.get(\"context\", \"?\"):,} tokens')
"
fi
RECOMMEND

chmod +x "$ROUTER_DIR/recommend.sh"
log "Recommendation script: $ROUTER_DIR/recommend.sh"

# ── Integrate with opencode.json ────────────────────────────────────────────

# If opencode.json exists, add model-router as a tool reference
OC_CONFIG="$HOME/.config/opencode/opencode.json"
if [ -f "$OC_CONFIG" ]; then
  python3 -c "
import json
with open('$OC_CONFIG') as f:
    cfg = json.load(f)
# Add router dir to env so plugins can find it
if 'experimental' not in cfg:
    cfg['experimental'] = {}
cfg['experimental']['model_router_dir'] = '$ROUTER_DIR'
with open('$OC_CONFIG', 'w') as f:
    json.dump(cfg, f, indent=2)
print('opencode.json: model_router_dir added')
" 2>/dev/null && log "opencode.json updated with model_router_dir" || warn "Failed to update opencode.json"
fi

# ── Team model preferences (R15: Team Collaboration) ────────────────────────
# Allows teams to share model preferences via chezmoi/git
cat >"$ROUTER_DIR/team-prefs.json" <<'TEAM'
{
  "_comment": "Team model preferences — share via chezmoi or git. Override task profiles for team-wide consistency.",
  "_usage": "Edit this file to set team-wide model preferences. Each task profile can be overridden.",
  "overrides": {},
  "defaults": {
    "preferred_provider": "deepseek",
    "fallback_strategy": "cost_first",
    "max_cost_per_1m_tokens": 10.0,
    "require_free_tier": false
  }
}
TEAM

log "Team preferences written to $ROUTER_DIR/team-prefs.json"

# ── Add dev CLI command ─────────────────────────────────────────────────────
info "Model routing configured. Use: $ROUTER_DIR/recommend.sh <task-type>"
info "Task types: coding, reasoning, fast, agentic, budget, vision, isolated, ru_cn"
info "Example: $ROUTER_DIR/recommend.sh coding"

_step_done step_model_router
