#!/usr/bin/env bash
# lib/27-dotfiles.sh — chezmoi dotfiles manager
set -euo pipefail

_step_skip step_dotfiles && return 0

section "Dotfiles Manager (chezmoi)"

if ! command -v chezmoi &>/dev/null; then
  _progress "chezmoi" "Installing dotfiles manager..."
  _spin_start "Downloading chezmoi"
  if command -v brew &>/dev/null; then
    brew install chezmoi 2>/dev/null && _spin_stop "✓" || _spin_stop "✗"
  else
    sh -c "$(_curl -fsSL https://get.chezmoi.io/ 2>/dev/null)" -- -b ~/.local/bin 2>/dev/null && \
      _spin_stop "✓" || _spin_stop "✗"
  fi
fi

# Initialize chezmoi if not already done
if command -v chezmoi &>/dev/null && [ ! -d ~/.local/share/chezmoi ]; then
  chezmoi init 2>/dev/null && log "chezmoi initialized" || warn "chezmoi init failed"
fi

_step_done step_dotfiles
