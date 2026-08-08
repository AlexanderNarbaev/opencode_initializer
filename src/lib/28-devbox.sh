#!/usr/bin/env bash
# lib/28-devbox.sh — Devbox (Nix-based isolated dev environments)
set -euo pipefail

_step_skip step_devbox && return 0

section "Devbox — Isolated Dev Environments"

if ! command -v devbox &>/dev/null; then
  _progress "devbox" "Installing Nix-based dev environment manager..."
  _spin_start "Downloading devbox"
  if _download_verify "https://get.jetify.com/devbox" /tmp/devbox-install.sh && bash /tmp/devbox-install.sh -f 2>/dev/null; then
    _spin_stop "✓" && log "Devbox installed" && rm -f /tmp/devbox-install.sh
  else
    _spin_stop "✗"; rm -f /tmp/devbox-install.sh; warn "Devbox install failed";
  fi
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
