#!/usr/bin/env bash
# src/lib/21-rag.sh — RAG System installation (Corporate Knowledge Assistant)
set -euo pipefail

if ([ "$MODE" = "full" ] || [ "$MODE" = "reinit" ]) && _gate "INTERACTIVE_DO_RAG"; then
  section "RAG System — Corporate Knowledge Assistant"

  RAG_DIR="${RAG_DIR:-$HOME/Projects/rag-system}"
  RAG_REPO="https://github.com/AlexanderNarbaev/rag-system.git"

  info "Cloning RAG System to $RAG_DIR..."
  if [ -d "$RAG_DIR/.git" ]; then
    git -C "$RAG_DIR" pull --rebase 2>/dev/null && log "RAG: updated" || warn "RAG: pull failed"
  else
    mkdir -p "$(dirname "$RAG_DIR")"
    _retry git clone "$RAG_REPO" "$RAG_DIR" && log "RAG: cloned" || warn "RAG: clone failed"
  fi

  info "Installing ETL Python dependencies..."
  if [ -f "$RAG_DIR/etl/requirements_etl.txt" ]; then
    pip install -r "$RAG_DIR/etl/requirements_etl.txt" 2>/dev/null && log "RAG ETL deps" || warn "RAG ETL deps failed"
  fi

  info "Installing Proxy Python dependencies..."
  if [ -f "$RAG_DIR/proxy/requirements_proxy.txt" ]; then
    pip install -r "$RAG_DIR/proxy/requirements_proxy.txt" 2>/dev/null && log "RAG Proxy deps" || warn "RAG Proxy deps failed"
  fi

  _step_done step_rag
fi
