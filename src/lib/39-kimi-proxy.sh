#!/usr/bin/env bash
# lib/39-kimi-proxy.sh — Moonshot/Kimi Anthropic-compatible proxy (STEP 8.5)
# Bridges opencode AI SDK (OpenAI-format) → Moonshot /anthropic endpoint
# Injects: temperature=1, thinking.budget_tokens to prevent reasoning saturation.
set -euo pipefail

if ([ "$MODE" = "full" ] || [ "$MODE" = "reinit" ] || [ "$MODE" = "update" ]) && _gate "INTERACTIVE_DO_KIMI_PROXY"; then
  section "Kimi Anthropic-Proxy"

  KIMI_PROXY_PORT="${KIMI_PROXY_PORT:-9876}"
  KIMI_PROXY_DIR="$HOME/.local/share/kimi-proxy"
  KIMI_PROXY_BIN="$KIMI_PROXY_DIR/kimi-anthropic-proxy.py"

  mkdir -p "$KIMI_PROXY_DIR"

  if [ ! -f "$KIMI_PROXY_BIN" ] || [ "${KIMI_PROXY_FORCE:-false}" = "true" ]; then
    info "Installing Kimi Anthropic-Proxy..."
    cp "$SCRIPT_DIR/scripts/kimi-anthropic-proxy.py" "$KIMI_PROXY_BIN"
    chmod +x "$KIMI_PROXY_BIN"
    log "Kimi proxy installed at $KIMI_PROXY_BIN"
  else
    log "Kimi proxy already installed"
  fi

  # Symlink for PATH
  mkdir -p "$HOME/.local/bin"
  ln -sf "$KIMI_PROXY_BIN" "$HOME/.local/bin/kimi-proxy"

  # Generate systemd user service (Linux only)
  if [ "$(uname -s)" = "Linux" ] && command -v systemctl &>/dev/null && [ -d "$HOME/.config/systemd/user" ] || mkdir -p "$HOME/.config/systemd/user"; then
    cat > "$HOME/.config/systemd/user/kimi-proxy.service" << EOF
[Unit]
Description=Kimi/Moonshot Anthropic-Proxy for opencode
After=network-online.target

[Service]
Type=simple
Environment="MOONSHOT_API_KEY=${MOONSHOT_API_KEY:-}"
Environment="KIMI_PROXY_PORT=$KIMI_PROXY_PORT"
ExecStart=/usr/bin/env python3 $KIMI_PROXY_BIN
Restart=always
RestartSec=3

[Install]
WantedBy=default.target
EOF

    if systemctl --user daemon-reload 2>/dev/null; then
      systemctl --user enable kimi-proxy.service 2>/dev/null || true
      systemctl --user restart kimi-proxy.service 2>/dev/null || true
      log "systemd user service installed & started"
    fi
  fi

  # Fallback: start via nohup (works without systemd, e.g. WSL without systemd)
  if ! pgrep -f "kimi-anthropic-proxy.py" >/dev/null 2>&1; then
    info "Starting kimi-proxy on port $KIMI_PROXY_PORT (nohup)..."
    nohup env MOONSHOT_API_KEY="${MOONSHOT_API_KEY:-}" KIMI_PROXY_PORT="$KIMI_PROXY_PORT" \
      python3 "$KIMI_PROXY_BIN" > "$KIMI_PROXY_DIR/proxy.log" 2>&1 &
    sleep 1
    if pgrep -f "kimi-anthropic-proxy.py" >/dev/null 2>&1; then
      log "kimi-proxy started (PID $(pgrep -f kimi-anthropic-proxy.py | head -1))"
    else
      warn "kimi-proxy failed to start; check $KIMI_PROXY_DIR/proxy.log"
    fi
  else
    log "kimi-proxy already running (PID $(pgrep -f kimi-anthropic-proxy.py | head -1))"
  fi

  # Smoke test
  if command -v curl &>/dev/null; then
    sleep 1
    if curl -sf --max-time 5 "http://127.0.0.1:$KIMI_PROXY_PORT/v1/models" -o /dev/null 2>/dev/null; then
      log "kimi-proxy smoke test: OK on http://127.0.0.1:$KIMI_PROXY_PORT"
    else
      warn "kimi-proxy smoke test failed"
    fi
  fi

  _step_done step_kimi_proxy
fi