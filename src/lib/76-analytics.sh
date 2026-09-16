#!/usr/bin/env bash
# src/lib/76-analytics.sh — Analytics collection
# Part of Phase 1: Enterprise Features
# shellcheck disable=SC2034
set -euo pipefail

ANALYTICS_DIR="${ANALYTICS_DIR:-$HOME/.local/share/opencode/analytics}"
ANALYTICS_EVENTS="${ANALYTICS_DIR}/events.jsonl"

# ── Event Tracking ───────────────────────────────────────────────────────────

# Track an event
_analytics_track() {
  local event_type="${1:-}"
  local event_name="${2:-}"
  local properties="${3:-}"
  
  mkdir -p "$ANALYTICS_DIR"
  
  echo "{\"timestamp\": \"$(date -u +%Y-%m-%dT%H:%M:%SZ)\", \"type\": \"$event_type\", \"name\": \"$event_name\", \"properties\": \"$properties\"}" \
    >> "$ANALYTICS_EVENTS"
}

# Track skill usage
_analytics_track_skill() {
  local skill_name="${1:-}"
  local action="${2:-}"
  local duration="${3:-0}"
  
  _analytics_track "skill" "$action" "{\"skill\": \"$skill_name\", \"duration\": $duration}"
}

# Track agent action
_analytics_track_agent() {
  local agent_name="${1:-}"
  local action="${2:-}"
  local result="${3:-}"
  
  _analytics_track "agent" "$action" "{\"agent\": \"$agent_name\", \"result\": \"$result\"}"
}

# ── Analytics Queries ────────────────────────────────────────────────────────

# Get event count by type
_analytics_count_by_type() {
  if [ ! -f "$ANALYTICS_EVENTS" ]; then
    echo "0"
    return
  fi
  
  if command -v jq &>/dev/null; then
    jq -r '.type' "$ANALYTICS_EVENTS" 2>/dev/null | sort | uniq -c | sort -rn
  fi
}

# Get event count by name
_analytics_count_by_name() {
  if [ ! -f "$ANALYTICS_EVENTS" ]; then
    echo "0"
    return
  fi
  
  if command -v jq &>/dev/null; then
    jq -r '.name' "$ANALYTICS_EVENTS" 2>/dev/null | sort | uniq -c | sort -rn
  fi
}

# Get events for time period
_analytics_events_period() {
  local start_date="${1:-}"
  local end_date="${2:-}"
  
  if [ ! -f "$ANALYTICS_EVENTS" ]; then
    return 0
  fi
  
  if [ -z "$start_date" ]; then
    cat "$ANALYTICS_EVENTS" 2>/dev/null
    return
  fi
  
  if command -v jq &>/dev/null; then
    jq --arg start "$start_date" --arg end "$end_date" \
      'select(.timestamp >= $start and .timestamp <= $end)' \
      "$ANALYTICS_EVENTS" 2>/dev/null
  fi
}

# ── Analytics Dashboard ──────────────────────────────────────────────────────

# Show analytics dashboard
_analytics_dashboard() {
  section "Analytics Dashboard"
  
  if [ ! -f "$ANALYTICS_EVENTS" ]; then
    info "No analytics data"
    return 0
  fi
  
  local total_events
  total_events=$(wc -l < "$ANALYTICS_EVENTS" 2>/dev/null || echo "0")
  
  echo "Total events: $total_events"
  echo
  echo "Events by type:"
  _analytics_count_by_type
  echo
  echo "Events by name:"
  _analytics_count_by_name
}

# ── Export ───────────────────────────────────────────────────────────────────

# Export analytics data
_analytics_export() {
  local format="${1:-json}"
  local output="${2:-/tmp/opencode-analytics-export.json}"
  
  if [ ! -f "$ANALYTICS_EVENTS" ]; then
    warn "No analytics data to export"
    return 1
  fi
  
  case "$format" in
    json)
      cp "$ANALYTICS_EVENTS" "$output"
      ;;
    csv)
      if command -v jq &>/dev/null; then
        jq -r '[.timestamp, .type, .name, .properties] | @csv' \
          "$ANALYTICS_EVENTS" > "$output" 2>/dev/null
      fi
      ;;
  esac
  
  log "Analytics exported to $output"
}

# ── CLI Interface ────────────────────────────────────────────────────────────

cmd_analytics() {
  local subcmd="${1:-help}"
  shift || true
  
  case "$subcmd" in
    track)        _analytics_track "$@" ;;
    track-skill)  _analytics_track_skill "$@" ;;
    track-agent)  _analytics_track_agent "$@" ;;
    count-type)   _analytics_count_by_type ;;
    count-name)   _analytics_count_by_name ;;
    period)       _analytics_events_period "$@" ;;
    dashboard)    _analytics_dashboard ;;
    export)       _analytics_export "$@" ;;
    help|*)
      cat <<'EOF'
Usage: opencode analytics <command> [args]

Commands:
  track <type> <name> [properties]   Track an event
  track-skill <name> <action>        Track skill usage
  track-agent <name> <action>        Track agent action
  count-type                         Count events by type
  count-name                         Count events by name
  period <start> [end]               Get events for period
  dashboard                          Show analytics dashboard
  export [format] [output]           Export analytics data
EOF
      ;;
  esac
}
