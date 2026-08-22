#!/usr/bin/env bash
# lib/22-webui-service.sh — Open WebUI user service (systemd / launchd)
# Requires: MODE
set -euo pipefail

if ([ "$MODE" = "full" ] || [ "$MODE" = "reinit" ]) && _gate "INTERACTIVE_DO_LLM"; then
  section "Open WebUI: user service"

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

  _service_install "open-webui" "$(command -v open-webui) serve --host 127.0.0.1 --port 3000" \
    "Open WebUI — LLM Chat Interface" \
    "OLLAMA_BASE_URL=http://127.0.0.1:11434" || warn "Open WebUI service install failed"

  log "Open WebUI service installed and started"
  _step_done step_webui
fi
