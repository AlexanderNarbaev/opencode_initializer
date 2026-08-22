#!/usr/bin/env bash
set -euo pipefail

_step_skip step_gui && return 0

section "Web GUI — Management Interface"

GUI_PORT="${GUI_PORT:-4200}"
GUI_DIR="$SCRIPT_DIR/src/gui"

if [ ! -f "$GUI_DIR/server.js" ]; then
  warn "GUI server not found at $GUI_DIR/server.js — skipping"
  _step_done step_gui
  return 0
fi

if ! command -v node &>/dev/null; then
  warn "Node.js not installed — skipping GUI setup"
  _step_done step_gui
  return 0
fi

_progress "gui" "Setting up OpenCode GUI service on port $GUI_PORT..."

log "GUI server found at $GUI_DIR/server.js"

# Cross-platform user service (systemd user unit / launchd LaunchAgent)
_service_install "opencode-gui" "$(command -v node) $GUI_DIR/server.js" \
  "OpenCode GUI — Web Management Interface" \
  "PATH=$HOME/.local/bin:$HOME/.n/bin:$HOME/.bun/bin:/usr/local/bin:/usr/bin:/bin" \
  "GUI_PORT=$GUI_PORT" || warn "GUI service install failed"

log "OpenCode GUI service installed and started on port $GUI_PORT"
_step_done step_gui
