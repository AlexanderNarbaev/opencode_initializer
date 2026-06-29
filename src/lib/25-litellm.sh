#!/usr/bin/env bash
# lib/25-litellm.sh — OpenAI-compatible local API gateway (LiteLLM proxy)
set -euo pipefail

_step_skip step_litellm && return 0

section "OpenAI-compatible API Gateway (LiteLLM)"

# Install LiteLLM via pipx (or pip as fallback)
if ! command -v litellm &>/dev/null; then
  info "Installing LiteLLM (OpenAI-compatible proxy for local LLMs)..."
  pipx install litellm 2>/dev/null && log "LiteLLM installed" || {
    warn "pipx install failed, trying pip..."
    pip install --user litellm 2>/dev/null && log "LiteLLM installed (pip)" || warn "LiteLLM install failed"
  }
fi

# Generate config: auto-detect running backends
mkdir -p ~/.config/litellm

# Detect Ollama models
OLLAMA_MODELS="qwen3:1.8b"
if command -v ollama &>/dev/null; then
  OLLAMA_MODELS=$(ollama list 2>/dev/null | awk 'NR>1{print $1}' | tr '\n' ',' | sed 's/,$//')
  [ -z "$OLLAMA_MODELS" ] && OLLAMA_MODELS="qwen3:0.6b"
fi

cat > ~/.config/litellm/config.yaml << 'YAML'
general_settings:
  master_key: os.environ/LITELLM_MASTER_KEY
  database_url: os.environ/LITELLM_DATABASE_URL

model_list:
YAML

# Register Ollama models
for model in $(echo "$OLLAMA_MODELS" | tr ',' ' '); do
  cat >> ~/.config/litellm/config.yaml << YAML
  - model_name: ollama/${model}
    litellm_params:
      model: ollama/${model}
      api_base: http://localhost:11434
YAML
done

# Register vLLM if available
if command -v vllm &>/dev/null; then
  cat >> ~/.config/litellm/config.yaml << YAML
  - model_name: vllm-self-hosted
    litellm_params:
      model: openai/default
      api_base: http://localhost:8000/v1
YAML
fi

# Register multimodal models
if command -v whisper-cli &>/dev/null; then
  cat >> ~/.config/litellm/config.yaml << YAML
  - model_name: whisper-1
    litellm_params:
      model: openai/whisper-1
      api_base: http://localhost:8081/v1
YAML
fi

if command -v ollama &>/dev/null && ollama list 2>/dev/null | grep -q 'llava'; then
  cat >> ~/.config/litellm/config.yaml << YAML
  - model_name: ollama/llava:7b
    litellm_params:
      model: ollama/llava:7b
      api_base: http://localhost:11434
YAML
fi

cat >> ~/.config/litellm/config.yaml << YAML

litellm_version: 1

router_settings:
  routing_strategy: usage-based
  enable_pre_call_checks: true
  allowed_fails: 3
  num_retries: 2
  fallbacks:
    - ollama/qwen3:0.6b
YAML

log "LiteLLM config written: ~/.config/litellm/config.yaml"

# Install systemd user service for auto-start
mkdir -p ~/.config/systemd/user
cat > ~/.config/systemd/user/litellm.service << 'SVC'
[Unit]
Description=LiteLLM — OpenAI-compatible Local API Gateway
After=network.target ollama.service
Wants=ollama.service

[Service]
Type=simple
Environment=LITELLM_MASTER_KEY=sk-local-dev-key-change-me
ExecStart=%h/.local/bin/litellm --config %h/.config/litellm/config.yaml --port 4000
Restart=on-failure
RestartSec=5

[Install]
WantedBy=default.target
SVC

systemctl --user daemon-reload 2>/dev/null || true
systemctl --user enable litellm.service 2>/dev/null || true
systemctl --user start litellm.service 2>/dev/null || true

log "LiteLLM API: http://localhost:4000/v1 (OpenAI-compatible)"
log "Test: curl http://localhost:4000/v1/models"

_step_done step_litellm
