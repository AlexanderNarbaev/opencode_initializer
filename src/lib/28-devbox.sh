#!/usr/bin/env bash
# lib/28-devbox.sh — Devbox (Nix-based isolated dev environments)
set -euo pipefail

_step_skip step_devbox && return 0

section "Devbox — Isolated Dev Environments"

if ! command -v devbox &>/dev/null; then
  _progress "devbox" "Installing Nix-based dev environment manager..."
  _spin_start "Downloading devbox"
  curl -fsSL https://get.jetify.com/devbox | bash -s -- -f 2>/dev/null && \
    _spin_stop "✓" && log "Devbox installed" || { _spin_stop "✗"; warn "Devbox install failed"; }
fi

# Generate devbox.json template in project dir
if command -v devbox &>/dev/null && [ -n "${PROJECT_DIR:-}" ] && [ -d "$PROJECT_DIR" ]; then
  if [ ! -f "$PROJECT_DIR/devbox.json" ]; then
    cat > "$PROJECT_DIR/devbox.json" << 'DEVBOX'
{
  "$schema": "https://raw.githubusercontent.com/jetify-com/devbox/main/.schema/devbox.schema.json",
  "packages": [
    "nodejs@latest",
    "python@latest",
    "go@latest",
    "rustup@latest",
    "bun@latest"
  ],
  "shell": {
    "init_hook": [
      "echo 'Devbox environment activated'"
    ]
  }
}
DEVBOX
    log "Generated devbox.json in $PROJECT_DIR"
  fi
fi

_step_done step_devbox
