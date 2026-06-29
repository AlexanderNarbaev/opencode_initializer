#!/usr/bin/env bash
# lib/16-llm.sh — GPU/LLM runtimes: Ollama, vLLM, SGLang, Open WebUI (STEP 12b)
# Requires: MODE
set -euo pipefail

if ([ "$MODE" = "full" ] || [ "$MODE" = "reinit" ]) && _gate "INTERACTIVE_DO_LLM"; then
  section "Local LLM runtimes"

  # ── Hardware auto-detection ──────────────────────────────────────────────
  detect_hardware() {
    HAS_GPU=false; HAS_NVIDIA_GPU=false; HAS_AMD_GPU=false; HAS_INTEL_GPU=false; HAS_NPU=false

    # NVIDIA GPU
    if lspci 2>/dev/null | grep -qiE 'nvidia|3D controller.*NVIDIA'; then
      HAS_NVIDIA_GPU=true; HAS_GPU=true
      log "NVIDIA GPU detected"
      nvidia-smi --query-gpu=driver_version --format=csv,noheader 2>/dev/null && log "NVIDIA driver: $(nvidia-smi --query-gpu=driver_version --format=csv,noheader 2>/dev/null)" || true
    fi

    # AMD GPU (ROCm)
    if lspci 2>/dev/null | grep -qiE 'amd/ati|Advanced Micro Devices' || \
       [ -d /opt/rocm ] || [ -d /opt/amdgpu ]; then
      HAS_AMD_GPU=true; HAS_GPU=true
      log "AMD GPU detected (ROCm compatible)"
      [ -f /opt/rocm/.info/version ] && log "ROCm: $(cat /opt/rocm/.info/version)" || true
    fi

    # Intel GPU (OneAPI/Arc)
    if lspci 2>/dev/null | grep -qiE 'Intel.*Graphics|Intel.*Arc'; then
      HAS_INTEL_GPU=true; HAS_GPU=true
      log "Intel GPU detected (OneAPI compatible)"
    fi

    # NPU (AMD Ryzen AI, Intel Meteor Lake)
    if lspci 2>/dev/null | grep -qiE 'IPU|Neural|NPU|Ryzen AI' || \
       [ -e /dev/accel/accel0 ] || [ -e /dev/dri/renderD128 ]; then
      HAS_NPU=true
      log "NPU detected (AMD Ryzen AI / Intel Meteor Lake)"
    fi

    # Apple Silicon (M1/M2/M3 — macOS only)
    if [ "$(uname -s)" = "Darwin" ] && sysctl -n machdep.cpu.brand_string 2>/dev/null | grep -qi 'Apple'; then
      HAS_GPU=true
      log "Apple Silicon detected (Metal/MPS acceleration)"
    fi

    # Determine optimal backend
    if $HAS_NVIDIA_GPU; then
      OPTIMAL_BACKEND="vllm"
    elif $HAS_AMD_GPU; then
      OPTIMAL_BACKEND="ollama"
    elif $HAS_INTEL_GPU; then
      OPTIMAL_BACKEND="ollama"
    elif $HAS_NPU; then
      OPTIMAL_BACKEND="llama.cpp"
    else
      OPTIMAL_BACKEND="ollama"
    fi

    export HAS_NVIDIA_GPU HAS_AMD_GPU HAS_INTEL_GPU HAS_NPU OPTIMAL_BACKEND

    # Write hardware profile for LiteLLM routing
    mkdir -p ~/.config/litellm
    python3 -c "
import json, os
home = os.path.expanduser('~')
with open(os.path.join(home, '.config/litellm/hardware.json'), 'w') as f:
    json.dump({
        'nvidia_gpu': $HAS_NVIDIA_GPU,
        'amd_gpu': $HAS_AMD_GPU,
        'intel_gpu': $HAS_INTEL_GPU,
        'npu': $HAS_NPU,
        'optimal_backend': '$OPTIMAL_BACKEND',
        'is_wsl2': '${WSL_DISTRO_NAME:+true}',
        'arch': '$(uname -m)'
    }, f, indent=2)
    " 2>/dev/null || warn "hardware.json write failed"

    log "Optimal backend: $OPTIMAL_BACKEND"
  }

  detect_hardware

  # ── Backend-specific installs ────────────────────────────────────────────

  # Ollama — universal (NVIDIA CUDA, AMD ROCm, Intel OneAPI, CPU)
  if ! command -v ollama &>/dev/null; then
    info "Installing Ollama..."
    command -v zstd &>/dev/null || sudo apt-get install -y zstd 2>/dev/null || true
    _curl "https://ollama.ai/install.sh" /tmp/ollama-install.sh 2>/dev/null && bash /tmp/ollama-install.sh 2>/dev/null && log "Ollama installed" || warn "Ollama install failed"
    rm -f /tmp/ollama-install.sh
    if command -v ollama &>/dev/null; then
      if $HAS_GPU; then
        ollama pull qwen3:14b 2>/dev/null & log "Ollama: pulling qwen3:14b (GPU-optimized, background)"
      else
        ollama pull qwen3:1.7b 2>/dev/null && log "Ollama: qwen3:1.7b pulled" || warn "Ollama: qwen3:1.7b pull failed"
      fi
    fi
  else
    log "Ollama already installed"
  fi

  # ── Ollama user-level systemd service ────────────────────────────────────
  if command -v ollama &>/dev/null; then
    mkdir -p ~/.config/systemd/user

    OLLAMA_BIN=""
    if snap list ollama &>/dev/null 2>&1; then
      OLLAMA_BIN="/snap/bin/ollama"
    elif which ollama &>/dev/null 2>&1; then
      OLLAMA_BIN="$(which ollama)"
    fi

    if [ -n "$OLLAMA_BIN" ]; then
      cat > ~/.config/systemd/user/ollama.service << 'SVC'
[Unit]
Description=Ollama — Local LLM Runtime
After=network.target

[Service]
Type=simple
Environment=OLLAMA_HOST=127.0.0.1:11434
ExecStart=OLLAMA_BIN_PLACEHOLDER serve
Restart=on-failure
RestartSec=5

[Install]
WantedBy=default.target
SVC
      sed -i "s|OLLAMA_BIN_PLACEHOLDER|$OLLAMA_BIN|g" ~/.config/systemd/user/ollama.service

      systemctl --user daemon-reload 2>/dev/null || true
      systemctl --user enable ollama.service 2>/dev/null || true
      systemctl --user start ollama.service 2>/dev/null || true
      log "Ollama user systemd service installed"
    fi
  fi

  # Open WebUI — only install if GPU detected or user explicitly chose LLM
  if $HAS_GPU || [ "${INTERACTIVE_DO_LLM:-}" = "true" ]; then
    if command -v docker &>/dev/null && ! docker ps --format '{{.Names}}' 2>/dev/null | grep -q 'open-webui'; then
      info "Installing Open WebUI (Docker)..."
      docker run -d --name open-webui --restart unless-stopped \
        -p 3300:8080 -v open-webui:/app/backend/data \
        --add-host=host.docker.internal:host-gateway \
        ghcr.io/open-webui/open-webui:main 2>/dev/null && log "Open WebUI: http://localhost:3300" || warn "Open WebUI failed"
    fi
  fi

  # vLLM — NVIDIA GPU only, for high-performance inference
  if $HAS_NVIDIA_GPU && ! command -v vllm &>/dev/null; then
    info "Installing vLLM (NVIDIA GPU inference server)..."
    pipx install vllm 2>/dev/null && log "vLLM installed" || warn "vLLM install failed (requires NVIDIA GPU + CUDA)"
  fi

  # SGLang — GPU-only, efficient structured generation
  if $HAS_GPU && ! command -v sglang &>/dev/null; then
    info "Installing SGLang..."
    pipx install "sglang[all]" 2>/dev/null && log "SGLang installed" || warn "SGLang install failed"
  fi

  # llama.cpp — CPU-optimized, best for NPU/no-GPU scenarios
  if ! $HAS_GPU && ! command -v llama.cpp &>/dev/null; then
    info "Installing llama.cpp (CPU-optimized inference)..."
    if command -v brew &>/dev/null; then
      brew install llama.cpp 2>/dev/null && log "llama.cpp installed (brew)" || warn "llama.cpp brew install failed"
    else
      git clone --depth 1 https://github.com/ggerganov/llama.cpp /tmp/llama.cpp-build 2>/dev/null && \
        make -C /tmp/llama.cpp-build -j"$(nproc)" llama-cli 2>/dev/null && \
        cp /tmp/llama.cpp-build/llama-cli ~/.local/bin/ && log "llama.cpp built" || warn "llama.cpp build failed"
      rm -rf /tmp/llama.cpp-build
    fi
  fi

  # LlamaEdge — lightweight WasmEdge-based runner (CPU-friendly)
  if ! command -v wasmedge &>/dev/null; then
    curl -sSf https://raw.githubusercontent.com/WasmEdge/WasmEdge/master/utils/install.sh 2>/dev/null | bash -s -- -v 0.15.1 2>/dev/null && log "WasmEdge installed" || warn "WasmEdge skipped"
  fi

  # ── Multimodal: Speech Recognition (whisper.cpp) ─────────────────────────
  if ! command -v whisper-cli &>/dev/null; then
    info "Installing whisper.cpp (speech-to-text)..."
    git clone --depth 1 https://github.com/ggerganov/whisper.cpp /tmp/whisper.cpp-build 2>/dev/null && \
      (cd /tmp/whisper.cpp-build && bash ./models/download-ggml-model.sh base 2>/dev/null && \
       make -j"$(nproc)" 2>/dev/null && cp main ~/.local/bin/whisper-cli) && \
      log "whisper.cpp installed (base model)" || warn "whisper.cpp build failed"
    rm -rf /tmp/whisper.cpp-build
  else
    log "whisper.cpp already installed"
  fi

  # ── Multimodal: Image Generation (stable-diffusion.cpp) ──────────────────
  # CPU-only by default; GPU-accelerated if NVIDIA detected
  if ! $HAS_NVIDIA_GPU && ! command -v sd &>/dev/null; then
    info "Installing stable-diffusion.cpp (CPU image generation)..."
    git clone --depth 1 https://github.com/leejet/stable-diffusion.cpp /tmp/sd.cpp-build 2>/dev/null && \
      (cd /tmp/sd.cpp-build && mkdir -p build && cd build && \
       cmake .. -DSD_SYSTEM_GGML=OFF 2>/dev/null && \
       cmake --build . --config Release -j"$(nproc)" 2>/dev/null && \
       cp bin/sd ~/.local/bin/) && log "stable-diffusion.cpp installed" || warn "sd.cpp build failed"
    rm -rf /tmp/sd.cpp-build
  fi

  # ── Multimodal: Pull vision model for Ollama ─────────────────────────────
  if command -v ollama &>/dev/null; then
    if ! ollama list 2>/dev/null | grep -q 'llava'; then
      info "Pulling vision model (llava:7b)..."
      ollama pull llava:7b 2>/dev/null & log "Ollama: pulling llava:7b (vision, background)"
    fi
  fi

  # ── ONNX Runtime ─────────────────────────────────────────────────────────
  if ! python3 -c "import onnxruntime" 2>/dev/null; then
    info "Installing ONNX Runtime (cross-platform inference)..."
    pipx install onnxruntime 2>/dev/null && log "ONNX Runtime installed" || \
    pip install --user onnxruntime 2>/dev/null && log "ONNX Runtime installed (pip)" || \
    warn "ONNX Runtime install failed"
  fi

  MODEL_CACHE="$HOME/.cache/opencode-setup/models"
  mkdir -p "$MODEL_CACHE"
  if [ ! -f "$MODEL_CACHE/all-MiniLM-L6-v2.onnx" ]; then
    info "Downloading ONNX embedding model (MiniLM-L6)..."
    _curl "https://huggingface.co/sentence-transformers/all-MiniLM-L6-v2/resolve/main/onnx/model.onnx" \
      "$MODEL_CACHE/all-MiniLM-L6-v2.onnx" 2>/dev/null && log "ONNX model cached" || warn "ONNX model download failed"
  fi

  log "LLM runtimes configured"
  _step_done step_llm
fi
