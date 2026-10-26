#!/usr/bin/env bash
# lib/01b-linux-platform.sh — Linux platform optimizations (WSL2, PATH, HF mirror, NVIDIA)
# Sources: must be sourced after helpers.sh + 00-core.sh
set -euo pipefail

# ── WSL2 detection helper ─────────────────────────────────────────────────────
_is_wsl2() {
  grep -qiE 'microsoft|wsl' /proc/version 2>/dev/null
}

# ── 1. WSL2 systemd enablement ────────────────────────────────────────────────
_linux_platform_wsl_systemd() {
  if ! _is_wsl2; then
    info "WSL2: not detected, skip systemd config"
    return 0
  fi

  if [ -f /etc/wsl.conf ] && grep -q '^systemd=true' /etc/wsl.conf 2>/dev/null; then
    info "WSL2 systemd: already enabled"
    return 0
  fi

  # Append [boot] section only if missing; add systemd=true
  if ! grep -q '^\[boot\]' /etc/wsl.conf 2>/dev/null; then
    printf '[boot]\nsystemd=true\n' | sudo tee -a /etc/wsl.conf >/dev/null 2>&1 || true
  elif ! grep -q '^systemd=true' /etc/wsl.conf 2>/dev/null; then
    echo "systemd=true" | sudo tee -a /etc/wsl.conf >/dev/null 2>&1 || true
  fi
  info "WSL2 systemd: enabled"
}

# ── 2. PATH sanitization (remove /mnt/c/*, /mnt/wsl/* Windows paths) ──────────
_linux_platform_path_sanitize() {
  local clean_path sanitized_file
  sanitized_file="$HOME/.config/opencode-setup/path-sanitized"

  # Use coreutils if available; fall back to sed for resilience
  if command -v tr &>/dev/null && command -v grep &>/dev/null && command -v paste &>/dev/null; then
    clean_path=$(echo "$PATH" | tr ':' '\n' | grep -vE '^/mnt/' | paste -sd: 2>/dev/null)
  else
    clean_path=$(echo ":$PATH:" | sed 's|:/[^:]*/mnt/[^:]*:||g; s|^:||; s|:$||')
  fi
  [ -z "$clean_path" ] && clean_path="$PATH"

  if [ "$clean_path" != "$PATH" ]; then
    mkdir -p "$(dirname "$sanitized_file")" 2>/dev/null || true
    echo "export PATH=\"$clean_path\"" > "$sanitized_file"
    info "PATH sanitized: removed WSL Windows paths"
  else
    info "PATH: no Windows paths detected"
  fi
}

# ── 3. HuggingFace mirror selection ────────────────────────────────────────────
_linux_platform_hf_mirror() {
  local env_file hf_endpoint
  env_file="$HOME/.config/opencode-setup/env"
  hf_endpoint=""

  # Check primary first, then mirror
  if curl -sI --max-time 5 https://huggingface.co 2>&1 | grep -qE '200|301|302'; then
    hf_endpoint="https://huggingface.co"
  elif curl -sI --max-time 5 https://hf-mirror.com 2>&1 | grep -qE '200|301|302'; then
    hf_endpoint="https://hf-mirror.com"
  fi

  if [ -n "$hf_endpoint" ]; then
    mkdir -p "$(dirname "$env_file")" 2>/dev/null || true
    echo "HF_ENDPOINT=$hf_endpoint" > "$env_file"
    info "HF endpoint: $hf_endpoint"
  else
    warn "HF: neither huggingface.co nor hf-mirror.com reachable"
  fi
}

# ── 4. NVIDIA persistenced daemon ──────────────────────────────────────────────
_linux_platform_nvidia_persistenced() {
  if ! command -v nvidia-smi &>/dev/null || ! nvidia-smi &>/dev/null 2>&1; then
    info "nvidia-persistenced: no GPU detected, skip"
    return 0
  fi

  if command -v nvidia-persistenced &>/dev/null; then
    info "nvidia-persistenced: already installed"
    return 0
  fi

  local driver_major
  driver_major=$(nvidia-smi --query-gpu=driver_version --format=csv,noheader 2>/dev/null | head -1 | cut -d. -f1)

  if [ -n "$driver_major" ] && [ "$driver_major" -gt 0 ]; then
    sudo apt-get install -y -qq "nvidia-utils-${driver_major}" 2>/dev/null || \
    sudo apt-get install -y -qq nvidia-utils-* 2>/dev/null || true
  fi

  if command -v nvidia-persistenced &>/dev/null; then
    sudo systemctl enable nvidia-persistenced 2>/dev/null || true
    sudo systemctl start nvidia-persistenced 2>/dev/null || true
    info "nvidia-persistenced: configured"
  else
    warn "nvidia-persistenced: installation failed"
  fi
}

# ── Main block ─────────────────────────────────────────────────────────────────
if ([ "${MODE:-}" = "full" ] || [ "${MODE:-}" = "reinit" ] || [ "${MODE:-}" = "update" ]) && _gate "INTERACTIVE_DO_LINUX_PLATFORM"; then
  section "Linux platform optimizations"

  applied=0

  if _is_wsl2; then
    _linux_platform_wsl_systemd
    applied=$((applied + 1))
  fi

  _linux_platform_path_sanitize
  applied=$((applied + 1))

  _linux_platform_hf_mirror
  applied=$((applied + 1))

  if command -v nvidia-smi &>/dev/null; then
    _linux_platform_nvidia_persistenced
    applied=$((applied + 1))
  fi

  log "Linux platform: applied $applied optimizations"
  _step_done step_linux_platform
fi
