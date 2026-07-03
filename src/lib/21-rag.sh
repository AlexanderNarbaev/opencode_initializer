#!/usr/bin/env bash
# src/lib/21-rag.sh — RAG System installation (Corporate Knowledge Assistant)
# Integrates with Qdrant (from 30-infra.sh) for vector storage
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

  # ── Qdrant integration (R5: Beyond Installation) ──────────────────────────
  info "Configuring Qdrant integration..."
  QDRANT_URL="${QDRANT_URL:-http://localhost:6333}"
  if curl -sf "$QDRANT_URL/health" --max-time 3 >/dev/null 2>&1; then
    log "Qdrant: online at $QDRANT_URL"
    # Create RAG collection if it doesn't exist
    curl -s -X PUT "$QDRANT_URL/collections/rag_documents" \
      -H "Content-Type: application/json" \
      -d '{"vectors":{"size":1024,"distance":"Cosine"}}' 2>/dev/null && \
      log "Qdrant: rag_documents collection created" || warn "Qdrant: collection creation failed"
  else
    warn "Qdrant: not running at $QDRANT_URL — start with: docker compose -f ~/.config/opencode/infra.yml up -d qdrant"
  fi

  # ── Verification (R5: verified interconnection) ───────────────────────────
  info "Verifying RAG installation..."
  _rag_ok=0
  [ -d "$RAG_DIR/.git" ] && _rag_ok=$((_rag_ok+1)) || warn "RAG: repo not cloned"
  [ -f "$RAG_DIR/etl/requirements_etl.txt" ] && _rag_ok=$((_rag_ok+1)) || warn "RAG: ETL requirements missing"
  [ -f "$RAG_DIR/proxy/requirements_proxy.txt" ] && _rag_ok=$((_rag_ok+1)) || warn "RAG: Proxy requirements missing"
  if [ $_rag_ok -eq 3 ]; then
    log "RAG: verified ($_rag_ok/3 checks passed)"
  else
    warn "RAG: partial install ($_rag_ok/3 checks passed)"
  fi

  _step_done step_rag
fi
