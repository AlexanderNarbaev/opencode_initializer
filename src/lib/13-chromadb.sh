#!/usr/bin/env bash
# lib/13-chromadb.sh — ChromaDB server + user service (STEP 10)
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

  # Install user service for ChromaDB auto-start (with token auth + RAG)
  # Note: the readiness wait is covered by the inline start + heartbeat check above.
  _service_install "chromadb" "$HOME/.local/bin/chroma run --path $HOME/.local/share/chroma --port 8000 --host 127.0.0.1" \
    "ChromaDB vector database for Muninn memory + codebase RAG" \
    "CHROMA_SERVER_NOFILE=65536" \
    'CHROMA_SERVER_CORS_ALLOW_ORIGINS=["*"]' \
    "CHROMA_SERVER_AUTHN_PROVIDER=chromadb.auth.token_authn.TokenAuthServerProvider" \
    "CHROMA_SERVER_AUTHN_CREDENTIALS=local-dev-token" \
    "CHROMA_SERVER_AUTHZ_PROVIDER=chromadb.auth.simple_rbac.SimpleRBACAuthorizationProvider" || warn "ChromaDB service install failed"
  if _service_status chromadb; then
    log "ChromaDB service active"
  else
    log "ChromaDB service installed"
  fi
fi
