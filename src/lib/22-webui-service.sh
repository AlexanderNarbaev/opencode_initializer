#!/usr/bin/env bash
# lib/22-webui-service.sh — Open WebUI systemd user service
# Requires: MODE
set -euo pipefail

if ([ "$MODE" = "full" ] || [ "$MODE" = "reinit" ]) && _gate "INTERACTIVE_DO_LLM"; then
  section "Open WebUI: systemd service"

  if ! command -v open-webui &>/dev/null; then
    _progress "open-webui" "Installing Open WebUI..."
    _spin_start "Installing via uv"
    if command -v uv &>/dev/null; then
      uv tool install --python 3.12 open-webui 2>/dev/null || \
        pip install --user open-webui 2>/dev/null || {
          _spin_stop "✗"
          warn "Open WebUI installation failed — skipping service setup"
          _step_done step_webui
          return 0
        }
    elif command -v pipx &>/dev/null; then
      pipx install open-webui 2>/dev/null || {
        _spin_stop "✗"
        warn "Open WebUI installation failed — skipping service setup"
        _step_done step_webui
        return 0
      }
    else
      pip install --user open-webui 2>/dev/null || {
        _spin_stop "✗"
        warn "Open WebUI installation failed — skipping service setup"
        _step_done step_webui
        return 0
      }
    fi
    _spin_stop "✓"
  fi

  if ! command -v open-webui &>/dev/null; then
    warn "Open WebUI binary still not found after install attempt"
    _step_done step_webui
    return 0
  fi

  mkdir -p ~/.config/systemd/user

  cat > ~/.config/systemd/user/open-webui.service << 'SVC'
[Unit]
Description=Open WebUI — LLM Chat Interface
After=network.target
Wants=network.target

[Service]
Type=simple
Environment=OLLAMA_BASE_URL=http://127.0.0.1:11434
ExecStart=%h/.local/bin/open-webui serve --host 127.0.0.1 --port 3000
Restart=on-failure
RestartSec=5

[Install]
WantedBy=default.target
SVC

  systemctl --user daemon-reload 2>/dev/null || true
  systemctl --user enable open-webui.service 2>/dev/null || true
  systemctl --user start open-webui.service 2>/dev/null || true

  log "Open WebUI systemd service installed and started"
  _step_done step_webui
fi
