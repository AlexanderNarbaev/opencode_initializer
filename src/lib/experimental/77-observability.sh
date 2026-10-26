#!/usr/bin/env bash
# src/lib/77-observability.sh — Observability stack
# Part of Phase 1: Enterprise Features
# shellcheck disable=SC2034
set -euo pipefail

OBSERVABILITY_DIR="${OBSERVABILITY_DIR:-$HOME/.config/opencode/observability}"
OBSERVABILITY_METRICS="${OBSERVABILITY_DIR}/metrics.json"
OBSERVABILITY_ALERTS="${OBSERVABILITY_DIR}/alerts.json"

# ── Metrics Collection ───────────────────────────────────────────────────────

# Initialize observability
_observability_init() {
  mkdir -p "$OBSERVABILITY_DIR"
  
  if [ ! -f "$OBSERVABILITY_METRICS" ]; then
    cat > "$OBSERVABILITY_METRICS" <<'EOF'
{
  "metrics": {
    "skills_installed": 0,
    "skills_executed": 0,
    "agents_registered": 0,
    "workflows_run": 0,
    "tasks_completed": 0,
    "errors_count": 0,
    "avg_response_time": 0
  },
  "updated_at": null
}
EOF
  fi
}

# Update a metric
_observability_metric_set() {
  local metric_name="${1:-}"
  local metric_value="${2:-0}"
  
  _observability_init
  
  if command -v jq &>/dev/null; then
    jq --arg name "$metric_name" --argjson value "$metric_value" \
      '.metrics[$name] = $value | .updated_at = "'$(date -u +%Y-%m-%dT%H:%M:%SZ)'"' \
      "$OBSERVABILITY_METRICS" > "$OBSERVABILITY_METRICS.tmp"
    mv "$OBSERVABILITY_METRICS.tmp" "$OBSERVABILITY_METRICS"
  fi
}

# Increment a metric
_observability_metric_incr() {
  local metric_name="${1:-}"
  local increment="${2:-1}"
  
  _observability_init
  
  if command -v jq &>/dev/null; then
    jq --arg name "$metric_name" --argjson incr "$increment" \
      '.metrics[$name] = ((.metrics[$name] // 0) + $incr) | .updated_at = "'$(date -u +%Y-%m-%dT%H:%M:%SZ)'"' \
      "$OBSERVABILITY_METRICS" > "$OBSERVABILITY_METRICS.tmp"
    mv "$OBSERVABILITY_METRICS.tmp" "$OBSERVABILITY_METRICS"
  fi
}

# Get metric value
_observability_metric_get() {
  local metric_name="${1:-}"
  
  _observability_init
  
  if command -v jq &>/dev/null; then
    jq -r --arg name "$metric_name" '.metrics[$name] // 0' \
      "$OBSERVABILITY_METRICS" 2>/dev/null
  fi
}

# Get all metrics
_observability_metrics() {
  _observability_init
  
  if command -v jq &>/dev/null; then
    jq '.metrics' "$OBSERVABILITY_METRICS" 2>/dev/null
  fi
}

# ── Alerts ───────────────────────────────────────────────────────────────────

# Create an alert
_observability_alert_create() {
  local alert_name="${1:-}"
  local metric="${2:-}"
  local threshold="${3:-0}"
  local condition="${4:-gt}"
  local action="${5:-log}"
  
  _observability_init
  
  if [ ! -f "$OBSERVABILITY_ALERTS" ]; then
    echo '{"alerts":[]}' > "$OBSERVABILITY_ALERTS"
  fi
  
  if command -v jq &>/dev/null; then
    jq --arg name "$alert_name" --arg metric "$metric" --argjson threshold "$threshold" \
       --arg cond "$condition" --arg action "$action" \
      '.alerts += [{"name": $name, "metric": $metric, "threshold": $threshold, "condition": $cond, "action": $action, "enabled": true}]' \
      "$OBSERVABILITY_ALERTS" > "$OBSERVABILITY_ALERTS.tmp"
    mv "$OBSERVABILITY_ALERTS.tmp" "$OBSERVABILITY_ALERTS"
  fi
  
  log "Alert created: $alert_name"
}

# Check alerts
_observability_alerts_check() {
  if [ ! -f "$OBSERVABILITY_ALERTS" ]; then
    return 0
  fi
  
  _observability_init
  
  if command -v jq &>/dev/null; then
    jq -r '.alerts[] | select(.enabled == true) | "\(.name): \(.metric) \(.condition) \(.threshold)"' \
      "$OBSERVABILITY_ALERTS" 2>/dev/null | while read -r alert; do
      info "Alert: $alert"
    done
  fi
}

# List alerts
_observability_alerts_list() {
  if [ ! -f "$OBSERVABILITY_ALERTS" ]; then
    info "No alerts configured"
    return 0
  fi
  
  if command -v jq &>/dev/null; then
    jq -r '.alerts[] | "\(.name) — \(.metric) \(.condition) \(.threshold) [\(if .enabled then "enabled" else "disabled" end)]"' \
      "$OBSERVABILITY_ALERTS" 2>/dev/null
  fi
}

# ── Dashboard ────────────────────────────────────────────────────────────────

# Show observability dashboard
_observability_dashboard() {
  section "Observability Dashboard"
  
  _observability_init
  
  echo "Metrics:"
  if command -v jq &>/dev/null; then
    jq -r '.metrics | to_entries[] | "  \(.key): \(.value)"' \
      "$OBSERVABILITY_METRICS" 2>/dev/null
  fi
  
  echo
  echo "Last updated:"
  if command -v jq &>/dev/null; then
    jq -r '.updated_at // "never"' "$OBSERVABILITY_METRICS" 2>/dev/null
  fi
}

# ── Health Check ─────────────────────────────────────────────────────────────

# Run health check
_observability_health() {
  section "Health Check"
  
  local status="healthy"
  local checks=()
  
  # Check memory usage
  local mem_usage
  mem_usage=$(free -m 2>/dev/null | awk '/Mem:/ {printf "%.0f", $3/$2*100}' || echo "0")
  if [ "$mem_usage" -gt 90 ]; then
    checks+=("❌ Memory usage: ${mem_usage}%")
    status="degraded"
  else
    checks+=("✅ Memory usage: ${mem_usage}%")
  fi
  
  # Check disk usage
  local disk_usage
  disk_usage=$(df -h / 2>/dev/null | awk 'NR==2 {print $5}' | tr -d '%' || echo "0")
  if [ "$disk_usage" -gt 90 ]; then
    checks+=("❌ Disk usage: ${disk_usage}%")
    status="degraded"
  else
    checks+=("✅ Disk usage: ${disk_usage}%")
  fi
  
  # Check services
  for service in postgres redis qdrant; do
    if systemctl is-active "$service" &>/dev/null; then
      checks+=("✅ $service: running")
    else
      checks+=("⚠️ $service: not running")
    fi
  done
  
  # Output
  for check in "${checks[@]}"; do
    echo "  $check"
  done
  
  echo
  echo "Overall status: $status"
}

# ── CLI Interface ────────────────────────────────────────────────────────────

cmd_observability() {
  local subcmd="${1:-help}"
  shift || true
  
  case "$subcmd" in
    init)          _observability_init ;;
    metric-set)    _observability_metric_set "$@" ;;
    metric-incr)   _observability_metric_incr "$@" ;;
    metric-get)    _observability_metric_get "$@" ;;
    metrics)       _observability_metrics ;;
    alert-create)  _observability_alert_create "$@" ;;
    alert-check)   _observability_alerts_check ;;
    alert-list)    _observability_alerts_list ;;
    dashboard)     _observability_dashboard ;;
    health)        _observability_health ;;
    help|*)
      cat <<'EOF'
Usage: opencode observability <command> [args]

Commands:
  init                                    Initialize observability
  metric-set <name> <value>               Set a metric
  metric-incr <name> [increment]          Increment a metric
  metric-get <name>                       Get metric value
  metrics                                 Get all metrics
  alert-create <name> <metric> <threshold> [condition] [action]
  alert-check                             Check alerts
  alert-list                              List alerts
  dashboard                               Show dashboard
  health                                  Run health check
EOF
      ;;
  esac
}
