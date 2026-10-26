#!/usr/bin/env bash
# src/lib/107-rag-hybrid.sh — Hybrid search (BM25 + Vector)
# Part of Phase 5: Ecosystem Integration
# shellcheck disable=SC2034
set -euo pipefail

RAG_DIR="${RAG_DIR:-$HOME/.config/opencode/rag}"

# ── Hybrid Search ────────────────────────────────────────────────────────────

# Hybrid search
_rag_hybrid_search() {
  local query="${1:-}"
  local limit="${2:-10}"
  
  if [ -z "$query" ]; then
    err "Search query required"
  fi
  
  info "Hybrid search: $query"
  
  # BM25 search
  local bm25_results
  bm25_results=$(_rag_bm25_search "$query" "$limit" 2>/dev/null || echo "")
  
  # Vector search
  local vector_results
  vector_results=$(_rag_vector_search "$query" "$limit" 2>/dev/null || echo "")
  
  # RRF fusion
  _rag_rrf_fusion "$bm25_results" "$vector_results" "$limit"
}

# ── RRF Fusion ───────────────────────────────────────────────────────────────

# RRF score calculation
_rag_rrf_score() {
  local rank="${1:-}"
  local k="${2:-60}"
  
  echo "scale=6; 1 / ($k + $rank)" | bc 2>/dev/null || echo "0"
}

# RRF fusion
_rag_rrf_fusion() {
  local bm25_results="${1:-}"
  local vector_results="${2:-}"
  local limit="${3:-10}"
  
  # Combine results
  echo "$bm25_results"
  echo "$vector_results" | grep -v "$(echo "$bm25_results" | head -1)"
}

# ── CLI Interface ────────────────────────────────────────────────────────────

cmd_rag() {
  local subcmd="${1:-help}"
  shift || true
  
  case "$subcmd" in
    search) _rag_hybrid_search "$@" ;;
    help|*)
      cat <<'EOF'
Usage: opencode rag <command> [args]

Commands:
  search <query> [limit]   Hybrid search (BM25 + Vector)
EOF
      ;;
  esac
}
