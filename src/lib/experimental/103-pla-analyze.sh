#!/usr/bin/env bash
# src/lib/103-pla-analyze.sh — Analysis layer
# Part of Phase 5: Ecosystem Integration
# shellcheck disable=SC2034
set -euo pipefail

# ── Analysis Operations ──────────────────────────────────────────────────────

# Analyze code
_pla_analyze_code() {
  local file="${1:-}"
  
  if [ -z "$file" ] || [ ! -f "$file" ]; then
    err "File required"
  fi
  
  local lines
  lines=$(wc -l < "$file")
  local words
  words=$(wc -w < "$file")
  local chars
  chars=$(wc -c < "$file")
  
  echo "Code Analysis:"
  echo "  Lines: $lines"
  echo "  Words: $words"
  echo "  Characters: $chars"
  
  # Count functions
  local functions
  functions=$(grep -c "function\|def \|func " "$file" 2>/dev/null || echo "0")
  echo "  Functions: $functions"
  
  # Count comments
  local comments
  comments=$(grep -c "^#\|^//\|^/\*" "$file" 2>/dev/null || echo "0")
  echo "  Comments: $comments"
}

# Analyze dependencies
_pla_analyze_deps() {
  local file="${1:-}"
  
  if [ -z "$file" ] || [ ! -f "$file" ]; then
    err "File required"
  fi
  
  if [ -f "$file/package.json" ]; then
    echo "Node.js dependencies:"
    if command -v jq &>/dev/null; then
      jq -r '.dependencies // {} | keys[]' "$file/package.json" 2>/dev/null
    fi
  elif [ -f "$file/requirements.txt" ]; then
    echo "Python dependencies:"
    cat "$file/requirements.txt" 2>/dev/null
  fi
}

# ── CLI Interface ────────────────────────────────────────────────────────────

cmd_pla_analyze() {
  local subcmd="${1:-help}"
  shift || true
  
  case "$subcmd" in
    code) _pla_analyze_code "$@" ;;
    deps) _pla_analyze_deps "$@" ;;
    help|*)
      cat <<'EOF'
Usage: opencode pla-analyze <command> [args]

Commands:
  code <file>    Analyze code structure
  deps <dir>     Analyze dependencies
EOF
      ;;
  esac
}
