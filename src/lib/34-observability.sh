#!/usr/bin/env bash
# lib/34-observability.sh — Grafana + Prometheus observability stack
# Requires: Docker, MODE, infra.yml
set -euo pipefail

_step_skip step_observability && return 0

section "Observability Stack (Prometheus + Grafana)"

INFRA_CONFIG="$HOME/.config/opencode/infra.yml"
SERVICES_DIR="$HOME/.config/opencode"
PROMETHEUS_YML="$SERVICES_DIR/prometheus.yml"
mkdir -p "$SERVICES_DIR"

# ── Create prometheus.yml if missing ───────────────────────────────────────
if [ ! -f "$PROMETHEUS_YML" ]; then
  log "Creating $PROMETHEUS_YML"
  cat > "$PROMETHEUS_YML" << 'PROMCONF'
global:
  scrape_interval: 15s

scrape_configs:
  - job_name: 'node'
    static_configs:
      - targets: ['host.docker.internal:9100']
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']
PROMCONF
  log "prometheus.yml created"
else
  log "prometheus.yml already exists"
fi

# ── Add prometheus + grafana to infra.yml if missing ───────────────────────
if [ -f "$INFRA_CONFIG" ]; then
  HAS_PROM=$(grep -c "prom/prometheus" "$INFRA_CONFIG" 2>/dev/null || echo 0)
  HAS_GRAFANA=$(grep -c "grafana/grafana" "$INFRA_CONFIG" 2>/dev/null || echo 0)

  if [ "$HAS_PROM" -eq 0 ] || [ "$HAS_GRAFANA" -eq 0 ]; then
    log "Adding observability services to $INFRA_CONFIG"

    if [ "$HAS_PROM" -eq 0 ]; then
      sed -i '/^services:/a\
\
  prometheus:\
    image: prom/prometheus:latest\
    container_name: opencode-prometheus\
    ports: ["127.0.0.1:9090:9090"]\
    volumes:\
      - ./prometheus.yml:/etc/prometheus/prometheus.yml\
      - opencode_prometheus_data:/prometheus\
    command: --config.file=/etc/prometheus/prometheus.yml\
    restart: unless-stopped' "$INFRA_CONFIG"
    fi

    if [ "$HAS_GRAFANA" -eq 0 ]; then
      sed -i '/^services:/a\
\
  grafana:\
    image: grafana/grafana:latest\
    container_name: opencode-grafana\
    ports: ["127.0.0.1:3001:3000"]\
    environment:\
      GF_SECURITY_ADMIN_USER: admin\
      GF_SECURITY_ADMIN_PASSWORD: ${GRAFANA_PASSWORD:-admin}\
      GF_INSTALL_PLUGINS: grafana-piechart-panel\
    volumes:\
      - opencode_grafana_data:/var/lib/grafana\
      - '"$SCRIPT_DIR"'/src/grafana/provisioning:/etc/grafana/provisioning\
      - '"$SCRIPT_DIR"'/src/grafana/dashboards:/etc/grafana/dashboards\
    restart: unless-stopped' "$INFRA_CONFIG"
    fi

    HAS_PROM_VOL=$(grep -c "opencode_prometheus_data" "$INFRA_CONFIG" 2>/dev/null || echo 0)
    HAS_GRAFANA_VOL=$(grep -c "opencode_grafana_data" "$INFRA_CONFIG" 2>/dev/null || echo 0)

    if [ "$HAS_PROM_VOL" -eq 0 ]; then
      sed -i '/^volumes:/a\  opencode_prometheus_data:' "$INFRA_CONFIG"
    fi
    if [ "$HAS_GRAFANA_VOL" -eq 0 ]; then
      sed -i '/^volumes:/a\  opencode_grafana_data:' "$INFRA_CONFIG"
    fi

    log "Observability services added to infra.yml"
  else
    log "Observability services already in infra.yml"
  fi
else
  warn "No infra.yml found — run setup.sh --with-observability first"
fi

_step_done step_observability
