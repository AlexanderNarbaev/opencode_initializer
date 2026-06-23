#!/usr/bin/env bash
# lib/13-chromadb.sh — ChromaDB server + systemd service (STEP 10)
# Requires: MODE
set -euo pipefail

if ([ "$MODE" = "full" ] || [ "$MODE" = "reinit" ]) && _gate "INTERACTIVE_DO_CHROMA"; then
  section "ChromaDB server"
  CHROMA_DATA="$HOME/.local/share/chroma"
  mkdir -p "$CHROMA_DATA"

  # Start chroma server if not already running
  if ! curl -sf http://127.0.0.1:8000/api/v2/heartbeat &>/dev/null; then
    chroma run --path "$CHROMA_DATA" --port 8000 --host 127.0.0.1 &>/dev/null &
    disown $!
    CHROMA_PID=$!
    sleep 2
    if curl -sf http://127.0.0.1:8000/api/v2/heartbeat &>/dev/null; then
      log "ChromaDB server started (PID $CHROMA_PID, port 8000)"
    else
      warn "ChromaDB server failed to start"
    fi
  else
    log "ChromaDB server already running"
  fi
  _step_done step_chromadb

  # Install systemd user service for ChromaDB auto-start (with token auth + RAG)
  mkdir -p "$HOME/.config/systemd/user"
  cat > "$HOME/.config/systemd/user/chromadb.service" << 'CHROMSVC'
[Unit]
Description=ChromaDB vector database for Muninn memory + codebase RAG
After=network.target

[Service]
Type=simple
Environment=CHROMA_SERVER_NOFILE=65536
Environment=CHROMA_SERVER_CORS_ALLOW_ORIGINS="*"
Environment=CHROMA_SERVER_AUTHN_PROVIDER="chromadb.auth.token_authn.TokenAuthServerProvider"
Environment=CHROMA_SERVER_AUTHN_CREDENTIALS="local-dev-token"
Environment=CHROMA_SERVER_AUTHZ_PROVIDER="chromadb.auth.simple_rbac.SimpleRBACAuthorizationProvider"
ExecStart=%h/.local/bin/chroma run --path %h/.local/share/chroma --port 8000 --host 127.0.0.1 --log-path %h/.local/share/chroma/logs
ExecStartPost=/bin/bash -c 'for i in $(seq 1 30); do curl -sf http://127.0.0.1:8000/api/v2/heartbeat 2>/dev/null && exit 0; sleep 1; done; exit 1'
Restart=on-failure
RestartSec=5

[Install]
WantedBy=default.target
CHROMSVC
  systemctl --user daemon-reload 2>/dev/null || true
  systemctl --user enable chromadb.service 2>/dev/null || true
  if systemctl --user is-active chromadb.service &>/dev/null; then
    log "ChromaDB systemd service active"
  else
    systemctl --user start chromadb.service 2>/dev/null || true
    log "ChromaDB systemd service installed"
  fi
fi
