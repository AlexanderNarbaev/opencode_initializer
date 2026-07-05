#!/usr/bin/env bash
# lib/30-infra.sh — Docker Infrastructure Layer (PostgreSQL, Qdrant, Redis, Prometheus, Grafana, MemoryLayer, Kafka, Neo4j, MinIO)
# Requires: MODE, Docker, INFRA_SERVICES
set -euo pipefail

_step_skip step_infra && return 0

section "Infrastructure Services (Docker)"

INFRA_CONFIG="${INFRA_CONFIG:-$HOME/.config/opencode/infra.yml}"
SERVICES_DIR="$HOME/.config/opencode"
mkdir -p "$SERVICES_DIR"

# ── Define available services ─────────────────────────────────────────────
declare -A INFRA_SERVICE_MAP=(
  [postgres]="PostgreSQL 17 (port 5432)"
  [qdrant]="Qdrant vector DB (port 6333)"
  [redis]="Redis 7 cache (port 6379)"
  [kafka]="Kafka message broker (port 9092)"
  [neo4j]="Neo4j graph DB (port 7474)"
  [minio]="MinIO S3 storage (port 9000)"
  [prometheus]="Prometheus monitoring (port 9090)"
  [grafana]="Grafana dashboards (port 3001)"
  [memorylayer]="MemoryLayer AI memory server (port 61001)"
)

# ── Determine which services to enable ────────────────────────────────────
ENABLED_SERVICES=""

# CLI flags override
if [ -n "${INFRA_SERVICES:-}" ]; then
  ENABLED_SERVICES="$INFRA_SERVICES"
fi

# ── Interactive selection if no flags ─────────────────────────────────────
if [ -z "$ENABLED_SERVICES" ] && [ "${INTERACTIVE_DO_INFRA:-}" = "true" ]; then
  echo ""
  echo "Infrastructure Services (Docker):"
  echo "  These are shared across all projects on this machine."
  echo ""
  for svc in "${!INFRA_SERVICE_MAP[@]}"; do
    read -r -p "  Enable ${INFRA_SERVICE_MAP[$svc]}? [y/N]: " ans
    if [ "${ans,,}" = "y" ]; then
      ENABLED_SERVICES="${ENABLED_SERVICES}${svc} "
    fi
  done
  echo ""
fi

# ── Auto-enable core services if no selection ─────────────────────────────
if [ -z "$ENABLED_SERVICES" ] && ([ "$MODE" = "full" ] || [ "$MODE" = "reinit" ]); then
  ENABLED_SERVICES="postgres qdrant redis prometheus grafana memorylayer"
  info "Default infra services: postgres, qdrant, redis, prometheus, grafana, memorylayer"
fi

[ -z "$ENABLED_SERVICES" ] && log "No infra services selected — skipping" && return 0

# ── Generate docker-compose config ─────────────────────────────────────────
log "Generating $INFRA_CONFIG"

cat > "$INFRA_CONFIG" << 'COMPOSE_HEADER'
# opencode_platform — Infrastructure Services
# Managed by: cockpit infra up/down
# Config: ~/.config/opencode/infra.yml

services:
COMPOSE_HEADER

for svc in $ENABLED_SERVICES; do
  case "$svc" in
    postgres)
      cat >> "$INFRA_CONFIG" << 'POSTGRES'
  postgres:
    image: postgres:17-alpine
    container_name: opencode-postgres
    environment:
      POSTGRES_DB: opencode
      POSTGRES_USER: opencode
      POSTGRES_PASSWORD: ${PG_PASSWORD:-opencode_dev}
    ports: ["127.0.0.1:5432:5432"]
    volumes: [opencode_pgdata:/var/lib/postgresql/data]
    restart: unless-stopped
POSTGRES
      ;;
    qdrant)
      cat >> "$INFRA_CONFIG" << 'QDRANT'
  qdrant:
    image: qdrant/qdrant:latest
    container_name: opencode-qdrant
    ports: ["127.0.0.1:6333:6333", "127.0.0.1:6334:6334"]
    volumes: [opencode_qdrant_data:/qdrant/storage]
    restart: unless-stopped
QDRANT
      ;;
    redis)
      cat >> "$INFRA_CONFIG" << 'REDIS'
  redis:
    image: redis:7-alpine
    container_name: opencode-redis
    ports: ["127.0.0.1:6379:6379"]
    volumes: [opencode_redis_data:/data]
    command: redis-server --save 60 1 --loglevel warning
    restart: unless-stopped
REDIS
      ;;
    kafka)
      cat >> "$INFRA_CONFIG" << 'KAFKA'
  kafka:
    image: bitnami/kafka:latest
    container_name: opencode-kafka
    ports: ["127.0.0.1:9092:9092"]
    environment:
      KAFKA_CFG_NODE_ID: 1
      KAFKA_CFG_PROCESS_ROLES: broker,controller
      KAFKA_CFG_CONTROLLER_QUORUM_VOTERS: 1@localhost:9093
      KAFKA_CFG_LISTENERS: PLAINTEXT://:9092,CONTROLLER://:9093
      KAFKA_CFG_ADVERTISED_LISTENERS: PLAINTEXT://localhost:9092
      KAFKA_CFG_CONTROLLER_LISTENER_NAMES: CONTROLLER
      KAFKA_CFG_LISTENER_SECURITY_PROTOCOL_MAP: CONTROLLER:PLAINTEXT,PLAINTEXT:PLAINTEXT
    volumes: [opencode_kafka_data:/bitnami/kafka]
    restart: unless-stopped
KAFKA
      ;;
    neo4j)
      cat >> "$INFRA_CONFIG" << 'NEO4J'
  neo4j:
    image: neo4j:5-community
    container_name: opencode-neo4j
    environment:
      NEO4J_AUTH: neo4j/${NEO4J_PASSWORD:-opencode_dev}
    ports:
      - "127.0.0.1:7474:7474"
      - "127.0.0.1:7687:7687"
    volumes: [opencode_neo4j_data:/data]
    restart: unless-stopped
NEO4J
      ;;
    minio)
      cat >> "$INFRA_CONFIG" << 'MINIO'
  minio:
    image: minio/minio:latest
    container_name: opencode-minio
    environment:
      MINIO_ROOT_USER: minioadmin
      MINIO_ROOT_PASSWORD: ${MINIO_PASSWORD:-minioadmin}
    ports:
      - "127.0.0.1:9000:9000"
      - "127.0.0.1:9001:9001"
    volumes: [opencode_minio_data:/data]
    command: server /data --console-address ":9001"
    restart: unless-stopped
MINIO
      ;;
    prometheus)
      cat >> "$INFRA_CONFIG" << 'PROMETHEUS'
  prometheus:
    image: prom/prometheus:latest
    container_name: opencode-prometheus
    ports: ["127.0.0.1:9090:9090"]
    volumes:
      - $HOME/.config/opencode/prometheus.yml:/etc/prometheus/prometheus.yml
      - opencode_prometheus_data:/prometheus
    command: --config.file=/etc/prometheus/prometheus.yml
    restart: unless-stopped
PROMETHEUS
      ;;
    grafana)
      cat >> "$INFRA_CONFIG" << GRAFANA
  grafana:
    image: grafana/grafana:latest
    container_name: opencode-grafana
    ports: ["127.0.0.1:3001:3000"]
    environment:
      GF_SECURITY_ADMIN_USER: admin
      GF_SECURITY_ADMIN_PASSWORD: \${GRAFANA_PASSWORD:-admin}
      GF_INSTALL_PLUGINS: grafana-piechart-panel
    volumes:
      - opencode_grafana_data:/var/lib/grafana
      - ${SCRIPT_DIR}/src/grafana/provisioning:/etc/grafana/provisioning
      - ${SCRIPT_DIR}/src/grafana/dashboards:/etc/grafana/dashboards
    restart: unless-stopped
GRAFANA
      ;;
    memorylayer)
      cat >> "$INFRA_CONFIG" << 'MEMORYLAYER'
  memorylayer:
    image: scitrera/memorylayer-server:latest
    container_name: opencode-memorylayer
    network_mode: host
    user: root
    volumes: [opencode_memorylayer_data:/data]
    restart: unless-stopped
MEMORYLAYER
      ;;
  esac
done

cat >> "$INFRA_CONFIG" << 'COMPOSE_FOOTER'

volumes:
COMPOSE_FOOTER

for svc in $ENABLED_SERVICES; do
  case "$svc" in
    postgres) echo "  opencode_pgdata:" >> "$INFRA_CONFIG" ;;
    qdrant)   echo "  opencode_qdrant_data:" >> "$INFRA_CONFIG" ;;
    redis)    echo "  opencode_redis_data:" >> "$INFRA_CONFIG" ;;
    kafka)        echo "  opencode_kafka_data:" >> "$INFRA_CONFIG" ;;
    neo4j)        echo "  opencode_neo4j_data:" >> "$INFRA_CONFIG" ;;
    minio)        echo "  opencode_minio_data:" >> "$INFRA_CONFIG" ;;
    prometheus)   echo "  opencode_prometheus_data:" >> "$INFRA_CONFIG" ;;
    grafana)      echo "  opencode_grafana_data:" >> "$INFRA_CONFIG" ;;
    memorylayer)  echo "  opencode_memorylayer_data:" >> "$INFRA_CONFIG" ;;
  esac
done

log "Infra config written to $INFRA_CONFIG ($(echo "$ENABLED_SERVICES" | wc -w) services)"

# ── Smart detection: check what's already running ─────────────────────────
RUNNING_COUNT=0; STOPPED_COUNT=0
for svc in $ENABLED_SERVICES; do
  container="opencode-$svc"
  if docker ps --format '{{.Names}}' 2>/dev/null | grep -qx "$container"; then
    log "Already running: $container"
    RUNNING_COUNT=$((RUNNING_COUNT + 1))
  else
    STOPPED_COUNT=$((STOPPED_COUNT + 1))
  fi
done

if [ $RUNNING_COUNT -gt 0 ]; then
  info "$RUNNING_COUNT service(s) already running"
fi
if [ $STOPPED_COUNT -eq 0 ]; then
  log "All infra services already running — nothing to start"
  _step_done step_infra
  return 0
fi

# ── Start services ────────────────────────────────────────────────────────
info "Starting $STOPPED_COUNT infra service(s)..."
docker compose -f "$INFRA_CONFIG" up -d --wait 2>/dev/null && \
  log "Infra services started" || \
  warn "Some services failed to start — check: docker compose -f $INFRA_CONFIG ps"

_step_done step_infra
