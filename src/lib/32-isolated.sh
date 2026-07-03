#!/usr/bin/env bash
# lib/32-isolated.sh — Isolated Circuit Mode (air-gapped / offline-first)
# When enabled, all LLM providers use local OpenAI-compatible servers:
#   - Ollama (localhost:11434)
#   - LiteLLM proxy (localhost:4000)
#   - vLLM (localhost:8000)
#   - SGLang (localhost:30000)
# No cloud API keys required.
set -euo pipefail

_step_skip step_isolated && return 0

section "Isolated Circuit Configuration"

# ── Detection priority ─────────────────────────────────────────────────────
ISOLATED_CIRCUIT="${ISOLATED_CIRCUIT:-}"
[ -z "$ISOLATED_CIRCUIT" ] && ISOLATED_CIRCUIT="${ISOLATED_FLAG:-}"
[ -z "$ISOLATED_CIRCUIT" ] && ISOLATED_CIRCUIT="${OPencode_ISOLATED_CIRCUIT:-}"

# Normalize to true/false
case "${ISOLATED_CIRCUIT,,}" in
  true|1|yes|on|enabled)  ISOLATED_CIRCUIT="true" ;;
  false|0|no|off|disabled) ISOLATED_CIRCUIT="false" ;;
  "")                      ISOLATED_CIRCUIT="false" ;;  # default: off
  *)                       warn "Invalid ISOLATED_CIRCUIT value: $ISOLATED_CIRCUIT — using false"
                           ISOLATED_CIRCUIT="false" ;;
esac

export ISOLATED_CIRCUIT

# ── Local OpenAI-compatible endpoint registry ───────────────────────────────
declare -A LOCAL_ENDPOINTS=(
  [ollama]="http://localhost:11434/v1"
  [litellm]="http://localhost:4000/v1"
  [vllm]="http://localhost:8000/v1"
  [sglang]="http://localhost:30000/v1"
)

# Default local endpoint (overridable via OPencode_LOCAL_ENDPOINT)
OPencode_LOCAL_ENDPOINT="${OPencode_LOCAL_ENDPOINT:-http://localhost:4000/v1}"
export OPencode_LOCAL_ENDPOINT

# ── Auto-detect available local backends ────────────────────────────────────
AVAILABLE_LOCAL_BACKENDS=""
for backend in ollama litellm vllm sglang; do
  port=$(echo "${LOCAL_ENDPOINTS[$backend]}" | grep -oP ':\d+' | head -1 | tr -d ':')
  if curl -s "${LOCAL_ENDPOINTS[$backend]}/models" --max-time 2 >/dev/null 2>&1; then
    AVAILABLE_LOCAL_BACKENDS="$AVAILABLE_LOCAL_BACKENDS $backend"
    log "Local backend detected: $backend (port $port)"
  fi
done

[ -z "$AVAILABLE_LOCAL_BACKENDS" ] && log "No local backends detected (Ollama/LiteLLM/vLLM/SGLang not running)"

# ── Detect available local models ───────────────────────────────────────────
LOCAL_MODELS=""
detect_ollama_models() {
  if command -v ollama &>/dev/null; then
    ollama list 2>/dev/null | awk 'NR>1{print $1}' | tr '\n' ' '
  fi
}
detect_litellm_models() {
  curl -s http://localhost:4000/v1/models --max-time 3 2>/dev/null | \
    python3 -c "import sys,json; d=json.load(sys.stdin); print(' '.join(m['id'] for m in d.get('data',[])))" 2>/dev/null
}

LOCAL_MODELS=$(detect_ollama_models)
[ -z "$LOCAL_MODELS" ] && LOCAL_MODELS=$(detect_litellm_models)
[ -z "$LOCAL_MODELS" ] && LOCAL_MODELS="qwen3:0.6b"

FIRST_LOCAL_MODEL=$(echo "$LOCAL_MODELS" | awk '{print $1}')
[ -z "$FIRST_LOCAL_MODEL" ] && FIRST_LOCAL_MODEL="qwen3:0.6b"
export FIRST_LOCAL_MODEL
export LOCAL_MODELS
export OPencode_LOCAL_MODEL="${OPencode_LOCAL_MODEL:-$FIRST_LOCAL_MODEL}"

if [ "$ISOLATED_CIRCUIT" = "true" ]; then
  info "ISOLATED CIRCUIT: ENABLED"
  info "  Endpoint: $OPencode_LOCAL_ENDPOINT"
  info "  Available backends: ${AVAILABLE_LOCAL_BACKENDS:-none}"
  info "  Available models: ${LOCAL_MODELS:-none}"
  info "  Primary model: $OPencode_LOCAL_MODEL"
  info "  No cloud API keys required — everything runs locally."
else
  info "Isolated circuit: DISABLED (cloud providers available)"
fi

# ── Persist to config ───────────────────────────────────────────────────────
CONFIG_FILE="$HOME/.config/opencode-setup/setup.conf"
mkdir -p "$(dirname "$CONFIG_FILE")"
touch "$CONFIG_FILE"

# Update or add ISOLATED_CIRCUIT
if grep -q "^ISOLATED_CIRCUIT=" "$CONFIG_FILE" 2>/dev/null; then
  sed -i "s/^ISOLATED_CIRCUIT=.*/ISOLATED_CIRCUIT=$ISOLATED_CIRCUIT/" "$CONFIG_FILE"
else
  echo "ISOLATED_CIRCUIT=$ISOLATED_CIRCUIT" >> "$CONFIG_FILE"
fi

# Update or add OPencode_LOCAL_ENDPOINT
if grep -q "^OPencode_LOCAL_ENDPOINT=" "$CONFIG_FILE" 2>/dev/null; then
  sed -i "s|^OPencode_LOCAL_ENDPOINT=.*|OPencode_LOCAL_ENDPOINT=$OPencode_LOCAL_ENDPOINT|" "$CONFIG_FILE"
else
  echo "OPencode_LOCAL_ENDPOINT=$OPencode_LOCAL_ENDPOINT" >> "$CONFIG_FILE"
fi

_step_done step_isolated
