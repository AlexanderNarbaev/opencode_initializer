#!/usr/bin/env bash
# src/lib/82-connectors.sh — Service connectors
# Part of Phase 2: Ecosystem Expansion
# shellcheck disable=SC2034
set -euo pipefail

CONNECTORS_DIR="${CONNECTORS_DIR:-$HOME/.config/opencode/connectors}"

# ── Connector Operations ─────────────────────────────────────────────────────

# Test a connector
_connector_test() {
  local connector_type="${1:-}"
  local endpoint="${2:-}"
  
  if [ -z "$connector_type" ]; then
    err "Connector type required"
  fi
  
  info "Testing connector: $connector_type"
  
  case "$connector_type" in
    http)
      if command -v curl &>/dev/null; then
        if curl -sS --max-time 5 "$endpoint" &>/dev/null; then
          echo "OK: HTTP connector working"
          return 0
        else
          echo "FAIL: HTTP connector failed"
          return 1
        fi
      fi
      ;;
    postgres)
      if command -v psql &>/dev/null; then
        echo "OK: PostgreSQL client available"
        return 0
      else
        echo "WARN: PostgreSQL client not found"
        return 1
      fi
      ;;
    redis)
      if command -v redis-cli &>/dev/null; then
        echo "OK: Redis client available"
        return 0
      else
        echo "WARN: Redis client not found"
        return 1
      fi
      ;;
    *)
      warn "Unknown connector type: $connector_type"
      return 1
      ;;
  esac
}

# List available connectors
_connector_list() {
  echo "Available connectors:"
  echo "  - http (REST APIs)"
  echo "  - postgres (PostgreSQL)"
  echo "  - redis (Redis)"
  echo "  - elasticsearch (Elasticsearch)"
  echo "  - qdrant (Qdrant vector DB)"
  echo "  - s3 (AWS S3)"
  echo "  - gcs (Google Cloud Storage)"
}

# ── CLI Interface ────────────────────────────────────────────────────────────

cmd_connector() {
  local subcmd="${1:-help}"
  shift || true
  
  case "$subcmd" in
    test) _connector_test "$@" ;;
    list) _connector_list ;;
    help|*)
      cat <<'EOF'
Usage: opencode connector <command> [args]

Commands:
  test <type> [endpoint]  Test a connector
  list                    List available connectors
EOF
      ;;
  esac
}
