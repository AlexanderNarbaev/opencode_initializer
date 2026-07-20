#!/usr/bin/env bash
# Auto-start kimi proxy on system boot (systemd user service + cron fallback)
# Called from 99-upstream-sync.sh

PROXY_SCRIPT="/home/alexandr-narbaev/Projects/opencode_initializer/scripts/kimi-anthropic-proxy.py"
DAEMON="/home/alexandr-narbaev/Projects/opencode_initializer/scripts/kimi-proxy-fork.py"
LOG_DIR="/home/alexandr-narbaev/Projects/opencode_initializer"
USER_HOME="$HOME"

# 1. systemd user service (Linux + systemd)
if [ "$(uname -s)" = "Linux" ] && command -v systemctl >/dev/null 2>&1; then
  mkdir -p "$USER_HOME/.config/systemd/user"
  cat > "$USER_HOME/.config/systemd/user/kimi-proxy.service" <<EOF
[Unit]
Description=Kimi Anthropic Proxy for opencode
After=network-online.target
Wants=network-online.target

[Service]
Type=forking
EnvironmentFile=$USER_HOME/.config/opencode/secrets.env
Environment=KIMI_PROXY_PORT=9876
ExecStart=$DAEMON
Restart=on-failure
RestartSec=3
StandardOutput=append:$LOG_DIR/.kimi-proxy.log
StandardError=append:$LOG_DIR/.kimi-proxy.log

[Install]
WantedBy=default.target
EOF
  systemctl --user daemon-reload 2>/dev/null && \
  systemctl --user enable kimi-proxy.service 2>/dev/null && \
  log "kimi-proxy systemd service enabled (starts on user login)"
fi

# 2. WSL / non-systemd fallback: add to ~/.zshrc
ZSHRC="$USER_HOME/.zshrc"
if [ -f "$ZSHRC" ] && ! grep -q "kimi-proxy-fork" "$ZSHRC" 2>/dev/null; then
  cat >> "$ZSHRC" <<EOF

# Auto-start Kimi Anthropic Proxy (if not running)
if ! pgrep -f kimi-anthropic-proxy.py > /dev/null 2>&1; then
  if [ -x "$DAEMON" ]; then
    source "$USER_HOME/.config/opencode/secrets.env" 2>/dev/null
    nohup $DAEMON >/dev/null 2>&1 < /dev/null &
  fi
fi
EOF
  log "kimi-proxy autostart added to ~/.zshrc"
fi

# 3. Start now if not running
if ! pgrep -f kimi-anthropic-proxy.py > /dev/null 2>&1; then
  source "$USER_HOME/.config/opencode/secrets.env" 2>/dev/null
  nohup $DAEMON >/dev/null 2>&1 < /dev/null &
  sleep 2
  if pgrep -f kimi-anthropic-proxy.py > /dev/null 2>&1; then
    log "kimi-proxy started (PID $(pgrep -f kimi-anthropic-proxy.py | head -1))"
  else
    warn "kimi-proxy failed to start"
  fi
fi