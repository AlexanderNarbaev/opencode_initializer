#!/usr/bin/env bash
# lib/16-llm.sh — GPU/LLM runtimes: Ollama, vLLM, SGLang, Open WebUI (STEP 12b)
# Requires: MODE
set -euo pipefail

if ([ "$MODE" = "full" ] || [ "$MODE" = "reinit" ]) && _gate "INTERACTIVE_DO_LLM"; then
  section "Local LLM runtimes"
  HAS_GPU=false
  lspci 2>/dev/null | grep -qiE 'nvidia|amd/ati|virtio-gpu' && HAS_GPU=true
  nvidia-smi &>/dev/null && HAS_GPU=true
  $HAS_GPU && log "GPU detected — enabling GPU-accelerated runtimes" || warn "No GPU found — CPU-only mode (Ollama works, vLLM skipped)"

  # Ollama — works with or without GPU
  if ! command -v ollama &>/dev/null; then
    info "Installing Ollama..."
    command -v zstd &>/dev/null || sudo apt-get install -y zstd 2>/dev/null || true
    _curl "https://ollama.ai/install.sh" /tmp/ollama-install.sh 2>/dev/null && bash /tmp/ollama-install.sh 2>/dev/null && log "Ollama installed" || warn "Ollama install failed"
    rm -f /tmp/ollama-install.sh
    command -v ollama &>/dev/null && { ollama pull qwen3:1.8b 2>/dev/null & log "Ollama: pulling qwen3:1.8b (background)"; }
  else
    log "Ollama already installed"
  fi

  # Open WebUI — chat interface for Ollama (Docker-based)
  if command -v docker &>/dev/null && ! docker ps --format '{{.Names}}' 2>/dev/null | grep -q 'open-webui'; then
    info "Installing Open WebUI (Docker)..."
    docker run -d --name open-webui --restart unless-stopped \
      -p 3300:8080 -v open-webui:/app/backend/data \
      --add-host=host.docker.internal:host-gateway \
      ghcr.io/open-webui/open-webui:main 2>/dev/null && log "Open WebUI: http://localhost:3300" || warn "Open WebUI failed"
  fi

  # vLLM — GPU-only, for high-performance inference
  if $HAS_GPU && ! command -v vllm &>/dev/null; then
    info "Installing vLLM (GPU inference server)..."
    pipx install vllm 2>/dev/null && log "vLLM installed" || warn "vLLM install failed (requires NVIDIA GPU + CUDA)"
  fi

  # SGLang — efficient structured generation
  if $HAS_GPU && ! command -v sglang &>/dev/null; then
    info "Installing SGLang..."
    pipx install "sglang[all]" 2>/dev/null && log "SGLang installed" || warn "SGLang install failed"
  fi

  # LlamaEdge — lightweight WasmEdge-based runner (CPU-friendly)
  if ! command -v wasmedge &>/dev/null; then
    curl -sSf https://raw.githubusercontent.com/WasmEdge/WasmEdge/master/utils/install.sh 2>/dev/null | bash -s -- -v 0.15.1 2>/dev/null && log "WasmEdge installed" || warn "WasmEdge skipped"
  fi

  log "LLM runtimes configured"
  _step_done step_llm
fi
