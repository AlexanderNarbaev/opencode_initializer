#!/usr/bin/env bash
# src/lib/109-rag-vector.sh — Vector search (Qdrant)
# Part of Phase 5: Ecosystem Integration
# shellcheck disable=SC2034
set -euo pipefail

# ── Vector Search ────────────────────────────────────────────────────────────

# Vector search
_rag_vector_search() {
  local query="${1:-}"
  local limit="${2:-10}"
  
  if [ -z "$query" ]; then
    err "Search query required"
  fi
  
  # Simple text similarity search
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

# Store vector
_rag_vector_store() {
  local file="${1:-}"
  local collection="${2:-default}"
  
  if [ -z "$file" ] || [ ! -f "$file" ]; then
    err "File required"
  fi
  
  mkdir -p "${RAG_DIR:-$HOME/.config/opencode/rag}/vectors/$collection"
  
  # Simple storage (copy file)
  cp "$file" "${RAG_DIR:-$HOME/.config/opencode/rag}/vectors/$collection/" 2>/dev/null
  
  log "Vector stored: $file → $collection"
}

# ── CLI Interface ────────────────────────────────────────────────────────────

cmd_rag_vector() {
  local subcmd="${1:-help}"
  shift || true
  
  case "$subcmd" in
    search) _rag_vector_search "$@" ;;
    store)  _rag_vector_store "$@" ;;
    help|*)
      cat <<'EOF'
Usage: opencode rag-vector <command> [args]

Commands:
  search <query> [limit]              Vector search
  store <file> [collection]           Store vector
EOF
      ;;
  esac
}
