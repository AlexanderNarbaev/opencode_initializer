#!/usr/bin/env bash
# lib/32-isolated.sh — Isolated Circuit Mode (air-gapped / offline-first)
# When enabled, all LLM providers use local OpenAI-compatible servers:
#   - Ollama (localhost:11434)
#   - vLLM (localhost:8000)
#   - SGLang (localhost:30000)
# No cloud API keys required.
set -euo pipefail

_step_skip step_isolated && return 0

section "Isolated Circuit Configuration"

# ── Detection priority ─────────────────────────────────────────────────────
ISOLATED_CIRCUIT="${ISOLATED_CIRCUIT:-}"
[ -z "$ISOLATED_CIRCUIT" ] && ISOLATED_CIRCUIT="${ISOLATED_FLAG:-}"
[ -z "$ISOLATED_CIRCUIT" ] && ISOLATED_CIRCUIT="${OPENCODE_ISOLATED_CIRCUIT:-${OPencode_ISOLATED_CIRCUIT:-}}"

# Normalize to true/false
case "$(printf '%s' "${ISOLATED_CIRCUIT:-}" | tr '[:upper:]' '[:lower:]')" in
  true|1|yes|on|enabled)  ISOLATED_CIRCUIT="true" ;;
  false|0|no|off|disabled) ISOLATED_CIRCUIT="false" ;;
  "")                      ISOLATED_CIRCUIT="false" ;;  # default: off
  *)                       warn "Invalid ISOLATED_CIRCUIT value: $ISOLATED_CIRCUIT — using false"
                           ISOLATED_CIRCUIT="false" ;;
esac

export ISOLATED_CIRCUIT

# ── Air-gap gate: all external version checks skip when isolated ───────────────
# version-check.sh (sourced elsewhere) respects ISOLATED_CIRCUIT via its gate.
# 20-autoupdate.sh also gates on ISOLATED_CIRCUIT to skip systemd timer install.

# ── Local OpenAI-compatible endpoint registry ───────────────────────────────
# ── Local endpoint lookup (bash 3.2 compat: case dispatch) ─────────────────
_get_local_endpoint() {
  case "${1:-}" in
    ollama) echo "http://localhost:11434/v1" ;;
    vllm)   echo "http://localhost:8000/v1" ;;
    sglang) echo "http://localhost:30000/v1" ;;
    *)      echo "" ;;
  esac
}

# Default local endpoint (overridable via OPENCODE_LOCAL_ENDPOINT or OPencode_LOCAL_ENDPOINT)
OPENCODE_LOCAL_ENDPOINT="${OPENCODE_LOCAL_ENDPOINT:-${OPencode_LOCAL_ENDPOINT:-http://localhost:11434/v1}}"
export OPENCODE_LOCAL_ENDPOINT

# ── Auto-detect available local backends ────────────────────────────────────
AVAILABLE_LOCAL_BACKENDS=""
for backend in ollama vllm sglang; do
  port=$(echo "$(_get_local_endpoint "$backend")" | grep -oE ':[0-9]+' | head -1 | tr -d ':')
  if curl -s "$(_get_local_endpoint "$backend")/models" --max-time 2 >/dev/null 2>&1; then
    AVAILABLE_LOCAL_BACKENDS="$AVAILABLE_LOCAL_BACKENDS $backend"
    log "Local backend detected: $backend (port $port)"
  fi
done

[ -z "$AVAILABLE_LOCAL_BACKENDS" ] && log "No local backends detected (Ollama/vLLM/SGLang not running)"

# ── Detect available local models ───────────────────────────────────────────
LOCAL_MODELS=""
detect_ollama_models() {
  if command -v ollama &>/dev/null; then
    ollama list 2>/dev/null | awk 'NR>1{print $1}' | tr '\n' ' '
  fi
}

LOCAL_MODELS=$(detect_ollama_models)
[ -z "$LOCAL_MODELS" ] && LOCAL_MODELS="qwen3:0.6b"

FIRST_LOCAL_MODEL=$(echo "$LOCAL_MODELS" | awk '{print $1}')
[ -z "$FIRST_LOCAL_MODEL" ] && FIRST_LOCAL_MODEL="qwen3:0.6b"
export FIRST_LOCAL_MODEL
export LOCAL_MODELS
export OPENCODE_LOCAL_MODEL="${OPENCODE_LOCAL_MODEL:-${OPencode_LOCAL_MODEL:-$FIRST_LOCAL_MODEL}}"

if [ "$ISOLATED_CIRCUIT" = "true" ]; then
  info "ISOLATED CIRCUIT: ENABLED"
  info "  Endpoint: $OPENCODE_LOCAL_ENDPOINT"
  info "  Available backends: ${AVAILABLE_LOCAL_BACKENDS:-none}"
  info "  Available models: ${LOCAL_MODELS:-none}"
  info "  Primary model: $OPENCODE_LOCAL_MODEL"
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

# Update or add OPENCODE_LOCAL_ENDPOINT (migrate from old OPencode_ prefix if present)
if grep -q "^OPENCODE_LOCAL_ENDPOINT=" "$CONFIG_FILE" 2>/dev/null; then
  sed -i "s|^OPENCODE_LOCAL_ENDPOINT=.*|OPENCODE_LOCAL_ENDPOINT=$OPENCODE_LOCAL_ENDPOINT|" "$CONFIG_FILE"
elif grep -q "^OPencode_LOCAL_ENDPOINT=" "$CONFIG_FILE" 2>/dev/null; then
  sed -i "s|^OPencode_LOCAL_ENDPOINT=.*|OPENCODE_LOCAL_ENDPOINT=$OPENCODE_LOCAL_ENDPOINT|" "$CONFIG_FILE"
else
  echo "OPENCODE_LOCAL_ENDPOINT=$OPENCODE_LOCAL_ENDPOINT" >> "$CONFIG_FILE"
fi

_step_done step_isolated
