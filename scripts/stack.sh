#!/usr/bin/env bash
# stack.sh — manage the local agentic-stack services (qdrant, postgres, redis,
# chromadb) that back the qdrant/postgres MCP servers.
#
# This machine may already run the legacy containers created by earlier setup.sh
# runs (`opencode-qdrant`, `opencode-postgres`, ...). The script therefore works
# in two modes:
#   * adopted  — containers with the `opencode-<svc>` names already exist: they
#                are inspected/started/stopped by name (no recreate, no data loss)
#   * compose  — nothing exists yet: `docker compose -f deploy/agentic-stack up -d`
#
# Usage:
#   bash scripts/stack.sh status          # health table for every service
#   bash scripts/stack.sh check           # exit 1 if a required service is down
#   bash scripts/stack.sh up [svc...]     # start (all by default)
#   bash scripts/stack.sh down [svc...]   # stop
#   bash scripts/stack.sh logs <svc>      # tail logs
#   bash scripts/stack.sh env             # connection URLs for MCP configs
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
COMPOSE_DIR="$SCRIPT_DIR/deploy/agentic-stack"
COMPOSE_FILE="$COMPOSE_DIR/docker-compose.yml"

# service -> port (host, loopback)
SERVICES="qdrant:6333 postgres:5432 redis:6379 chromadb:8000"
REQUIRED="qdrant postgres"

have_docker() { command -v docker >/dev/null 2>&1 && docker info >/dev/null 2>&1; }

container_of() { echo "opencode-$1"; }

state_of() { # svc -> running|stopped|missing
  local c; c="$(container_of "$1")"
  if ! have_docker; then echo "no-docker"; return; fi
  if docker inspect "$c" >/dev/null 2>&1; then
    if [ "$(docker inspect -f '{{.State.Running}}' "$c" 2>/dev/null)" = "true" ]; then echo "running"; else echo "stopped"; fi
  else
    echo "missing"
  fi
}

port_probe() { # port -> ok|closed
  if command -v curl >/dev/null 2>&1; then
    curl -s -o /dev/null --max-time 2 "http://127.0.0.1:$1" && { echo ok; return; }
  fi
  # no curl answer: fall back to a TCP open check
  (exec 3<>"/dev/tcp/127.0.0.1/$1") 2>/dev/null && { exec 3>&-; echo ok; } || echo closed
}

cmd_status() {
  printf '%-10s %-14s %-8s %s\n' SERVICE CONTAINER STATE PORT
  for entry in $SERVICES; do
    svc="${entry%%:*}"; port="${entry##*:}"
    printf '%-10s %-14s %-8s %s\n' "$svc" "$(container_of "$svc")" "$(state_of "$svc")" "$(port_probe "$port")"
  done
}

cmd_check() {
  rc=0
  if ! have_docker; then echo "stack: docker daemon unavailable"; return 1; fi
  for svc in $REQUIRED; do
    st="$(state_of "$svc")"
    if [ "$st" != "running" ]; then echo "stack: $svc is $st" >&2; rc=1; fi
  done
  [ "$rc" -eq 0 ] && echo "stack: required services running"
  return "$rc"
}

cmd_up() {
  have_docker || { echo "stack: docker daemon unavailable" >&2; return 1; }
  if [ "$#" -gt 0 ]; then svcs="$*"; else svcs="$(echo "$SERVICES" | tr ' ' '\n' | cut -d: -f1)"; fi
  for svc in $svcs; do
    c="$(container_of "$svc")"
    if docker inspect "$c" >/dev/null 2>&1; then
      docker start "$c" >/dev/null && echo "started $c"
    else
      ( cd "$COMPOSE_DIR" && docker compose -f "$COMPOSE_FILE" up -d "$svc" )
    fi
  done
}

cmd_down() {
  have_docker || { echo "stack: docker daemon unavailable" >&2; return 1; }
  if [ "$#" -gt 0 ]; then svcs="$*"; else svcs="$(echo "$SERVICES" | tr ' ' '\n' | cut -d: -f1)"; fi
  for svc in $svcs; do
    c="$(container_of "$svc")"
    if docker inspect "$c" >/dev/null 2>&1; then docker stop "$c" >/dev/null && echo "stopped $c"; fi
  done
}

cmd_logs() {
  local svc="${1:?usage: stack.sh logs <service>}"
  docker logs --tail 80 -f "$(container_of "$svc")"
}

cmd_env() {
  echo "QDRANT_URL=http://127.0.0.1:6333"
  echo "QDRANT_COLLECTION=opencode-memory"
  echo "POSTGRES_URL=postgresql://opencode:opencode@127.0.0.1:5432/opencode"
  echo "REDIS_URL=redis://127.0.0.1:6379/0"
  echo "CHROMADB_URL=http://127.0.0.1:8000"
}

case "${1:-status}" in
  status) cmd_status ;;
  check) cmd_check ;;
  up) shift; cmd_up "$@" ;;
  down) shift; cmd_down "$@" ;;
  logs) shift; cmd_logs "$@" ;;
  env) cmd_env ;;
  -h|--help) sed -n '2,22p' "$0" | sed 's/^# \{0,1\}//' ;;
  *) echo "Unknown: $1 (use: status|check|up|down|logs|env)" >&2; exit 2 ;;
esac
