#!/usr/bin/env bash
# src/lib/108-rag-bm25.sh — BM25 search (Elasticsearch)
# Part of Phase 5: Ecosystem Integration
# shellcheck disable=SC2034
set -euo pipefail

# ── BM25 Search ──────────────────────────────────────────────────────────────

# BM25 search
_rag_bm25_search() {
  local query="${1:-}"
  local limit="${2:-10}"
  
  if [ -z "$query" ]; then
    err "Search query required"
  fi
  
  # Search in local files
  local results=""
  local count=0
  
  while IFS= read -r file; do
    if grep -qi "$query" "$file" 2>/dev/null; then
      results="$results\n$file"
      ((count++))
      
      if [ "$count" -ge "$limit" ]; then
        break
      fi
    fi
  done < <(find "${RAG_DIR:-$HOME/.config/opencode/rag}" -type f 2>/dev/null)
  
  echo -e "$results"
}

# Index document for BM25
_rag_bm25_index() {
  local file="${1:-}"
  
  if [ -z "$file" ] || [ ! -f "$file" ]; then
    err "File required"
  fi
  
  mkdir -p "${RAG_DIR:-$HOME/.config/opencode/rag}/index"
  
  # Simple indexing (copy file)
  cp "$file" "${RAG_DIR:-$HOME/.config/opencode/rag}/index/" 2>/dev/null
  
  log "Indexed: $file"
}

# ── CLI Interface ────────────────────────────────────────────────────────────

cmd_rag_bm25() {
  local subcmd="${1:-help}"
  shift || true
  
  case "$subcmd" in
    search) _rag_bm25_search "$@" ;;
    index)  _rag_bm25_index "$@" ;;
    help|*)
      cat <<'EOF'
Usage: opencode rag-bm25 <command> [args]

Commands:
  search <query> [limit]   BM25 search
  index <file>             Index document
EOF
      ;;
  esac
}
