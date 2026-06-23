#!/usr/bin/env bash
# src/lib/22-mise.sh — mise-en-place: universal tool version manager
# Installs mise and configures it as optional alternative to per-language managers
set -euo pipefail

_step_skip step_mise && return 0

section "mise — Universal Tool Manager"

# Install mise if not present
if ! command -v mise &>/dev/null; then
  _progress "mise" "Installing mise..."
  _spin_start "Downloading mise"
  if curl -fsSL https://mise.run | sh 2>/dev/null; then
    _spin_stop "✓"
  else
    _spin_stop "✗"
    warn "mise install failed — skipping"
    return 0
  fi
  # Ensure mise is in PATH
  export PATH="$HOME/.local/bin:$PATH"
fi

# Activate mise for the current shell (not adding to .zshrc — user choice)
if [ -f "$HOME/.local/bin/mise" ]; then
  eval "$($HOME/.local/bin/mise activate bash)" 2>/dev/null || true
  log "mise $(mise --version 2>/dev/null | head -1) installed"
fi

# Install key tools via mise for version pinning (optional, alongside existing managers)
# These complement the existing installations, not replace them
if command -v mise &>/dev/null; then
  _spin_start "Installing common tools via mise"
  mise install -y node@lts python@latest go@latest 2>/dev/null || true
  _spin_stop "✓"
  log "mise tool versions cached"

  # Set global defaults (compatible with per-project overrides)
  mise use -g node@lts 2>/dev/null || true
fi

_step_done "step_mise"
log "mise configured — use 'mise bootstrap' for declarative env setup"
