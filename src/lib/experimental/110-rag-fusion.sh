#!/usr/bin/env bash
# src/lib/110-rag-fusion.sh — RRF fusion
# Part of Phase 5: Ecosystem Integration
# shellcheck disable=SC2034
set -euo pipefail

# ── RRF Fusion ───────────────────────────────────────────────────────────────

# RRF score
_rag_rrf_score() {
  local rank="${1:-}"
  local k="${2:-60}"
  
  echo "scale=6; 1 / ($k + $rank)" | bc 2>/dev/null || echo "0"
}

# Fuse results
_rag_fusion_results() {
  local bm25_results="${1:-}"
  local vector_results="${2:-}"
  local limit="${3:-10}"
  
  # Combine and deduplicate
  echo -e "$bm25_results"
  echo -e "$vector_results" | sort -u | head -n "$limit"
}

# ── CLI Interface ────────────────────────────────────────────────────────────

cmd_rag_fusion() {
  local subcmd="${1:-help}"
  shift || true
  
  case "$subcmd" in
    score)  _rag_rrf_score "$@" ;;
    fuse)   _rag_fusion_results "$@" ;;
    help|*)
      cat <<'EOF'
Usage: opencode rag-fusion <command> [args]

Commands:
  score <rank> [k]                              Calculate RRF score
  fuse <bm25_results> <vector_results> [limit]  Fuse results
EOF
      ;;
  esac
}
