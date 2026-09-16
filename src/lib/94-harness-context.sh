#!/usr/bin/env bash
# src/lib/94-harness-context.sh — Context management & compaction
# Part of Phase 4: AI-Native Development
# shellcheck disable=SC2034
set -euo pipefail

HARNESS_CONTEXT_DIR="${HARNESS_CONTEXT_DIR:-$HOME/.local/share/opencode/harness/context}"

# ── Context Operations ───────────────────────────────────────────────────────

# Build context
_harness_context_build() {
  local task="${1:-}"
  local files="${2:-}"
  local max_tokens="${3:-100000}"
  
  if [ -z "$task" ]; then
    err "Task required"
  fi
  
  mkdir -p "$HARNESS_CONTEXT_DIR"
  
  local context=""
  
  # Add task
  context="Task: $task"
  
  # Add files
  if [ -n "$files" ]; then
    for file in $files; do
      if [ -f "$file" ]; then
        context="$context\n\nFile: $file\n$(cat "$file" | head -1000)"
      fi
    done
  fi
  
  # Truncate if needed
  if [ ${#context} -gt "$max_tokens" ]; then
    context=$(echo -e "$context" | head -c "$max_tokens")
  fi
  
  echo -e "$context"
}

# Compact context
_harness_context_compact() {
  local context="${1:-}"
  local target_size="${2:-50000}"
  
  if [ ${#context} -le "$target_size" ]; then
    echo "$context"
    return 0
  fi
  
  # Keep beginning and end
  local half=$((target_size / 2))
  local beginning
  beginning=$(echo "$context" | head -c "$half")
  local ending
  ending=$(echo "$context" | tail -c "$half")
  
  echo "$beginning"
  echo "... [compacted] ..."
  echo "$ending"
}

# ── CLI Interface ────────────────────────────────────────────────────────────

cmd_harness_context() {
  local subcmd="${1:-help}"
  shift || true
  
  case "$subcmd" in
    build)   _harness_context_build "$@" ;;
    compact) _harness_context_compact "$@" ;;
    help|*)
      cat <<'EOF'
Usage: opencode harness-context <command> [args]

Commands:
  build <task> [files] [max_tokens]   Build context
  compact <context> [target_size]     Compact context
EOF
      ;;
  esac
}
