#!/usr/bin/env bash
# src/lib/116-load-balancer.sh — Load balancing
# Part of Phase 6: Production Hardening
# shellcheck disable=SC2034
set -euo pipefail

# ── Load Balancer Operations ─────────────────────────────────────────────────

# Check load balancer status
_lb_status() {
  info "Load balancer status"
  
  # Check nginx
  if command -v nginx &>/dev/null; then
    if systemctl is-active nginx &>/dev/null; then
      echo "  ✓ Nginx: running"
    else
      echo "  ✗ Nginx: not running"
    fi
  else
    echo "  ⚠ Nginx: not installed"
  fi
  
  # Check haproxy
  if command -v haproxy &>/dev/null; then
    if systemctl is-active haproxy &>/dev/null; then
      echo "  ✓ HAProxy: running"
    else
      echo "  ✗ HAProxy: not running"
    fi
  else
    echo "  ⚠ HAProxy: not installed"
  fi
}

# ── CLI Interface ────────────────────────────────────────────────────────────

cmd_lb() {
  local subcmd="${1:-status}"
  shift || true
  
  case "$subcmd" in
    status) _lb_status ;;
    help|*)
      cat <<'EOF'
Usage: opencode lb <command>

Commands:
  status   Check load balancer status
EOF
      ;;
  esac
}
