#!/usr/bin/env bash
# lib/34-observability.sh — Grafana + Prometheus observability stack
# Requires: Docker, MODE, infra.yml
# Config: ~/.config/opencode-setup/setup.conf
#   EXTERNAL_OBSERVABILITY=true  — skip local setup, use external stack
#   EXTERNAL_GRAFANA_URL=...     — external Grafana URL
#   EXTERNAL_PROMETHEUS_URL=...  — external Prometheus URL
#   OTEL_EXPORTER_ENABLED=true   — OpenTelemetry collector
#   OTEL_EXPORTER_ENDPOINT=...   — OTel endpoint (grpc/http)
set -euo pipefail

_step_skip step_observability && return 0

section "Observability Stack (Prometheus + Grafana)"

# ── Check for external observability config ─────────────────────────────────
CONFIG_FILE="$HOME/.config/opencode-setup/setup.conf"
EXTERNAL_OBSERVABILITY=false
EXTERNAL_GRAFANA_URL=""
EXTERNAL_PROMETHEUS_URL=""

if [ -f "$CONFIG_FILE" ]; then
  # shellcheck disable=SC1090
  source "$CONFIG_FILE" 2>/dev/null || true
fi

if [ "${EXTERNAL_OBSERVABILITY:-false}" = "true" ]; then
  if [ -n "${EXTERNAL_GRAFANA_URL:-}" ]; then
    info "EXTERNAL_OBSERVABILITY=true — using external Grafana at $EXTERNAL_GRAFANA_URL"
  else
    info "EXTERNAL_OBSERVABILITY=true — skipping local observability setup"
  fi
  if [ -n "${EXTERNAL_PROMETHEUS_URL:-}" ]; then
    info "External Prometheus at $EXTERNAL_PROMETHEUS_URL"
  fi
  log "Local Prometheus/Grafana NOT installed (external stack configured)"
  _step_done step_observability
  return 0
fi

# ── Check for corporate OTel collector ────────────────────────────────────
OTEL_EXPORTER_ENABLED="${OTEL_EXPORTER_ENABLED:-false}"
OTEL_EXPORTER_ENDPOINT="${OTEL_EXPORTER_ENDPOINT:-}"
if [ "${OTEL_EXPORTER_ENABLED:-false}" = "true" ] && [ -n "${OTEL_EXPORTER_ENDPOINT:-}" ]; then
  info "OTel exporter configured → ${OTEL_EXPORTER_ENDPOINT}"
  _set_config "OTEL_EXPORTER_ENABLED" "true"
  _set_config "OTEL_EXPORTER_ENDPOINT" "$OTEL_EXPORTER_ENDPOINT"
fi

INFRA_CONFIG="$HOME/.config/opencode/infra.yml"
SERVICES_DIR="$HOME/.config/opencode"
PROMETHEUS_YML="$SERVICES_DIR/prometheus.yml"
mkdir -p "$SERVICES_DIR"

NODE_PORT="${NODE_EXPORTER_PORT:-9100}"
METRICS_PORT="${METRICS_EXPORTER_PORT:-9464}"
# Resolve docker host IP for Linux (host.docker.internal only works on Mac/Win)
DOCKER_HOST=$(ip -4 addr show docker0 2>/dev/null | grep -oE 'inet [0-9.]+' | awk '{print $2}' || echo "host.docker.internal")

# ── Create/update prometheus.yml ──────────────────────────────────────────
log "Generating $PROMETHEUS_YML"
cat >"$PROMETHEUS_YML" <<PROMCONF
global:
  scrape_interval: 15s

scrape_configs:
  - job_name: 'node'
    static_configs:
      - targets: ['${DOCKER_HOST}:${NODE_PORT}']

  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']

  - job_name: 'opencode'
    static_configs:
      - targets: ['${DOCKER_HOST}:${METRICS_PORT}']
    metrics_path: /metrics
PROMCONF
  log "prometheus.yml written"

# ── Add prometheus + grafana to infra.yml if missing ───────────────────────
if [ -f "$INFRA_CONFIG" ]; then
  HAS_PROM=$(grep -c "prom/prometheus" "$INFRA_CONFIG" 2>/dev/null || echo 0)
  HAS_GRAFANA=$(grep -c "grafana/grafana" "$INFRA_CONFIG" 2>/dev/null || echo 0)

  if [ "$HAS_PROM" -eq 0 ] || [ "$HAS_GRAFANA" -eq 0 ]; then
    log "Adding observability services to $INFRA_CONFIG"

    if [ "$HAS_PROM" -eq 0 ]; then
      # Portable awk rewrite (multi-line sed 'a\' is GNU-only)
      awk -v port="${PROMETHEUS_PORT:-9090}" '{
        print
        if ($0 ~ /^services:/) {
          print ""
          print "  prometheus:"
          print "    image: prom/prometheus:latest"
          print "    container_name: opencode-prometheus"
          print "    ports: [\"127.0.0.1:" port ":9090\"]"
          print "    volumes:"
          print "      - ./prometheus.yml:/etc/prometheus/prometheus.yml"
          print "      - opencode_prometheus_data:/prometheus"
          print "    command: --config.file=/etc/prometheus/prometheus.yml"
          print "    restart: unless-stopped"
        }
      }' "$INFRA_CONFIG" > "$INFRA_CONFIG.tmp" && mv "$INFRA_CONFIG.tmp" "$INFRA_CONFIG"
    fi

    if [ "$HAS_GRAFANA" -eq 0 ]; then
      awk -v port="${GRAFANA_PORT:-3001}" -v password="${GRAFANA_PASSWORD:-admin}" -v script_dir="$SCRIPT_DIR" '{
        print
        if ($0 ~ /^services:/) {
          print ""
          print "  grafana:"
          print "    image: grafana/grafana:latest"
          print "    container_name: opencode-grafana"
          print "    ports: [\"127.0.0.1:" port ":3000\"]"
          print "    environment:"
          print "      GF_SECURITY_ADMIN_USER: admin"
          print "      GF_SECURITY_ADMIN_PASSWORD: " password
          print "      GF_INSTALL_PLUGINS: grafana-piechart-panel"
          print "    volumes:"
          print "      - opencode_grafana_data:/var/lib/grafana"
          print "      - " script_dir "/src/grafana/provisioning:/etc/grafana/provisioning"
          print "      - " script_dir "/src/grafana/dashboards:/etc/grafana/dashboards"
          print "    restart: unless-stopped"
        }
      }' "$INFRA_CONFIG" > "$INFRA_CONFIG.tmp" && mv "$INFRA_CONFIG.tmp" "$INFRA_CONFIG"
    fi

    HAS_PROM_VOL=$(grep -c "opencode_prometheus_data" "$INFRA_CONFIG" 2>/dev/null || echo 0)
    HAS_GRAFANA_VOL=$(grep -c "opencode_grafana_data" "$INFRA_CONFIG" 2>/dev/null || echo 0)

    if [ "$HAS_PROM_VOL" -eq 0 ]; then
      awk '{ print } /^volumes:/ { print "  opencode_prometheus_data:" }' \
        "$INFRA_CONFIG" > "$INFRA_CONFIG.tmp" && mv "$INFRA_CONFIG.tmp" "$INFRA_CONFIG"
    fi
    if [ "$HAS_GRAFANA_VOL" -eq 0 ]; then
      awk '{ print } /^volumes:/ { print "  opencode_grafana_data:" }' \
        "$INFRA_CONFIG" > "$INFRA_CONFIG.tmp" && mv "$INFRA_CONFIG.tmp" "$INFRA_CONFIG"
    fi

    log "Observability services added to infra.yml"
  else
    log "Observability services already in infra.yml"
  fi
else
  warn "No infra.yml found — run setup.sh --with-observability first"
fi

_step_done step_observability
