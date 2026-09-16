#!/usr/bin/env bash
set -euo pipefail
# OpenTelemetry integration for opencode_initializer
# https://opentelemetry.io/

# ── Environment variables ────────────────────────────────────────────────────
# Set these to enable OpenTelemetry export
# OTEL_EXPORTER_OTLP_ENDPOINT="http://localhost:4317"
# OTEL_SERVICE_NAME="opencode-initializer"
# OTEL_RESOURCE_ATTRIBUTES="deployment.environment=production"

# ── Functions ────────────────────────────────────────────────────────────────

# _otel_init — Initialize OpenTelemetry
_otel_init() {
  if [ -z "${OTEL_EXPORTER_OTLP_ENDPOINT:-}" ]; then
    return 0
  fi

  # Check if curl is available
  if ! command -v curl &>/dev/null; then
    return 0
  fi

  log "OpenTelemetry enabled: ${OTEL_EXPORTER_OTLP_ENDPOINT}"
}

# _otel_trace_start — Start a trace span
# Usage: _otel_trace_start "operation_name"
_otel_trace_start() {
  local operation="$1"
  local trace_id
  local span_id

  # Generate trace and span IDs
  trace_id=$(openssl rand -hex 16 2>/dev/null || head -c 32 /dev/urandom | od -An -tx1 | tr -d ' \n' | head -c 32)
  span_id=$(openssl rand -hex 8 2>/dev/null || head -c 16 /dev/urandom | od -An -tx1 | tr -d ' \n' | head -c 16)

  # Export to environment for child processes
  export OTEL_TRACE_ID="${trace_id}"
  export OTEL_SPAN_ID="${span_id}"
  export OTEL_SPAN_NAME="${operation}"
  export OTEL_SPAN_START="$(date +%s%N)"

  # Log span start
  if [ "${OTEL_DEBUG:-false}" = "true" ]; then
    echo "[otel] trace_id=${trace_id} span_id=${span_id} operation=${operation} start"
  fi
}

# _otel_trace_end — End a trace span
# Usage: _otel_trace_end "status" "message"
_otel_trace_end() {
  local status="${1:-OK}"
  local message="${2:-}"

  if [ -z "${OTEL_TRACE_ID:-}" ]; then
    return 0
  fi

  local end_time
  end_time="$(date +%s%N)"
  local duration_ms=0

  if [ -n "${OTEL_SPAN_START:-}" ]; then
    duration_ms=$(( (end_time - OTEL_SPAN_START) / 1000000 ))
  fi

  # Log span end
  if [ "${OTEL_DEBUG:-false}" = "true" ]; then
    echo "[otel] trace_id=${OTEL_TRACE_ID} span_id=${OTEL_SPAN_ID} operation=${OTEL_SPAN_NAME} status=${status} duration=${duration_ms}ms"
  fi

  # Send to OTLP endpoint if configured
  if [ -n "${OTEL_EXPORTER_OTLP_ENDPOINT:-}" ] && command -v curl &>/dev/null; then
    _otel_send_span "${status}" "${message}" "${duration_ms}" &
  fi

  # Clean up
  unset OTEL_TRACE_ID OTEL_SPAN_ID OTEL_SPAN_NAME OTEL_SPAN_START
}

# _otel_send_span — Send span to OTLP endpoint
_otel_send_span() {
  local status="$1"
  local message="$2"
  local duration_ms="$3"

  local status_code=0
  [ "$status" = "ERROR" ] && status_code=1

  # OTLP JSON format
  local payload
  payload=$(cat << EOF
{
  "resourceSpans": [{
    "resource": {
      "attributes": [{
        "key": "service.name",
        "value": {"stringValue": "${OTEL_SERVICE_NAME:-opencode-initializer}"}
      }]
    },
    "scopeSpans": [{
      "scope": {"name": "opencode-init"},
      "spans": [{
        "traceId": "${OTEL_TRACE_ID}",
        "spanId": "${OTEL_SPAN_ID}",
        "name": "${OTEL_SPAN_NAME}",
        "startTimeUnixNano": "${OTEL_SPAN_START}",
        "endTimeUnixNano": "$(date +%s%N)",
        "status": {
          "code": ${status_code},
          "message": "${message}"
        }
      }]
    }]
  }]
}
EOF
  )

  # Send async
  curl -s -X POST \
    -H "Content-Type: application/json" \
    -d "$payload" \
    "${OTEL_EXPORTER_OTLP_ENDPOINT}/v1/traces" \
    >/dev/null 2>&1 &
}

# _otel_metric — Record a metric
# Usage: _otel_metric "metric_name" value "unit"
_otel_metric() {
  local name="$1"
  local value="$2"
  local unit="${3:-1}"

  if [ -z "${OTEL_EXPORTER_OTLP_ENDPOINT:-}" ]; then
    return 0
  fi

  # Log metric
  if [ "${OTEL_DEBUG:-false}" = "true" ]; then
    echo "[otel] metric=${name} value=${value} unit=${unit}"
  fi
}

# Export functions
export -f _otel_init _otel_trace_start _otel_trace_end _otel_send_span _otel_metric 2>/dev/null || true
