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

mkdir -p ~/.config/systemd/user

cat > ~/.config/systemd/user/opencode-gui.service << SVC
[Unit]
Description=OpenCode GUI — Web Management Interface
After=network.target
Wants=network.target

[Service]
Type=simple
Environment=PATH=$HOME/.local/bin:$HOME/.n/bin:$HOME/.bun/bin:/usr/local/bin:/usr/bin:/bin
Environment=GUI_PORT=$GUI_PORT
ExecStart=$(command -v node) $GUI_DIR/server.js
Restart=on-failure
RestartSec=5
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=default.target
SVC

systemctl --user daemon-reload 2>/dev/null || true
systemctl --user enable opencode-gui.service 2>/dev/null || true
systemctl --user start opencode-gui.service 2>/dev/null || true

log "OpenCode GUI systemd service installed and started on port $GUI_PORT"
_step_done step_gui
