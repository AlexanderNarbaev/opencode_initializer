#!/usr/bin/env bash
# src/lib/84-learning.sh — Continuous learning from feedback
# Part of Phase 3: Agent Harness
# shellcheck disable=SC2034
set -euo pipefail

LEARNING_DIR="${LEARNING_DIR:-$HOME/.local/share/opencode/learning}"
LEARNING_FEEDBACK="${LEARNING_DIR}/feedback.jsonl"
LEARNING_MODEL="${LEARNING_DIR}/model.json"

# ── Feedback Collection ──────────────────────────────────────────────────────

# Record feedback
_learning_feedback() {
  local task_id="${1:-}"
  local agent_id="${2:-}"
  local rating="${3:-}"
  local comment="${4:-}"
  
  mkdir -p "$LEARNING_DIR"
  
  echo "{\"timestamp\": \"$(date -u +%Y-%m-%dT%H:%M:%SZ)\", \"task_id\": \"$task_id\", \"agent_id\": \"$agent_id\", \"rating\": $rating, \"comment\": \"$comment\"}" \
    >> "$LEARNING_FEEDBACK"
  
  log "Feedback recorded: task=$task_id rating=$rating"
}

# Get feedback summary
_learning_feedback_summary() {
  if [ ! -f "$LEARNING_FEEDBACK" ]; then
    info "No feedback data"
    return 0
  fi
  
  local total=0
  local sum=0
  
  while IFS= read -r line; do
    if command -v jq &>/dev/null; then
      local rating
      rating=$(echo "$line" | jq -r '.rating // 0' 2>/dev/null)
      total=$((total + 1))
      sum=$((sum + rating))
    fi
  done < "$LEARNING_FEEDBACK"
  
  if [ "$total" -gt 0 ]; then
    local avg=$((sum / total))
    echo "Feedback Summary:"
    echo "  Total feedback: $total"
    echo "  Average rating: $avg/10"
  else
    echo "No feedback data"
  fi
}

# ── Learning Model ───────────────────────────────────────────────────────────

# Update learning model
_learning_update_model() {
  local skill_name="${1:-}"
  local improvement="${2:-}"
  
  mkdir -p "$LEARNING_DIR"
  
  if [ ! -f "$LEARNING_MODEL" ]; then
    echo '{"skills":{}}' > "$LEARNING_MODEL"
  fi
  
  if command -v jq &>/dev/null; then
    jq --arg skill "$skill_name" --arg imp "$improvement" \
      '.skills[$skill] = {"improvement": $imp, "updated_at": "'$(date -u +%Y-%m-%dT%H:%M:%SZ)'"}' \
      "$LEARNING_MODEL" > "$LEARNING_MODEL.tmp"
    mv "$LEARNING_MODEL.tmp" "$LEARNING_MODEL"
  fi
  
  log "Learning model updated: $skill_name"
}

# Get learning recommendations
_learning_recommendations() {
  if [ ! -f "$LEARNING_MODEL" ]; then
    info "No learning data"
    return 0
  fi
  
  if command -v jq &>/dev/null; then
    jq -r '.skills | to_entries[] | "\(.key): \(.value.improvement)"' \
      "$LEARNING_MODEL" 2>/dev/null
  fi
}

# ── Skill Improvement ────────────────────────────────────────────────────────

# Analyze skill performance
_learning_analyze_skill() {
  local skill_name="${1:-}"
  
  if [ -z "$skill_name" ]; then
    err "Skill name required"
  fi
  
  # Count feedback for skill
  if [ ! -f "$LEARNING_FEEDBACK" ]; then
    echo "No feedback for $skill_name"
    return 0
  fi
  
  local count=0
  local sum=0
  
  while IFS= read -r line; do
    if command -v jq &>/dev/null; then
      local agent_id rating
      agent_id=$(echo "$line" | jq -r '.agent_id // ""' 2>/dev/null)
      rating=$(echo "$line" | jq -r '.rating // 0' 2>/dev/null)
      
      if [ "$agent_id" = "$skill_name" ]; then
        count=$((count + 1))
        sum=$((sum + rating))
      fi
    fi
  done < "$LEARNING_FEEDBACK"
  
  if [ "$count" -gt 0 ]; then
    local avg=$((sum / count))
    echo "Skill: $skill_name"
    echo "  Feedback count: $count"
    echo "  Average rating: $avg/10"
  else
    echo "No feedback for $skill_name"
  fi
}

# ── CLI Interface ────────────────────────────────────────────────────────────

cmd_learning() {
  local subcmd="${1:-help}"
  shift || true
  
  case "$subcmd" in
    feedback)      _learning_feedback "$@" ;;
    summary)       _learning_feedback_summary ;;
    update)        _learning_update_model "$@" ;;
    recommend)     _learning_recommendations ;;
    analyze)       _learning_analyze_skill "$@" ;;
    help|*)
      cat <<'EOF'
Usage: opencode learning <command> [args]

Commands:
  feedback <task> <agent> <rating> [comment]  Record feedback
  summary                                     Get feedback summary
  update <skill> <improvement>                Update learning model
  recommend                                   Get recommendations
  analyze <skill>                             Analyze skill performance
EOF
      ;;
  esac
}
