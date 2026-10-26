#!/usr/bin/env bash
# src/lib/113-security-hardening.sh — Security hardening
# Part of Phase 6: Production Hardening
# shellcheck disable=SC2034
set -euo pipefail

# ── Security Hardening ───────────────────────────────────────────────────────

# Run security hardening
_security_hardening_run() {
  section "Security Hardening"
  
  local score=0
  local total=0
  
  # 1. Check file permissions
  ((total++))
  local world_writable
  world_writable=$(find "$HOME/.config/opencode" -perm -o+w 2>/dev/null | wc -l)
  if [ "$world_writable" -eq 0 ]; then
    ((score++))
    echo "  ✓ No world-writable files"
  else
    echo "  ✗ Found $world_writable world-writable files"
  fi
  
  # 2. Check for secrets in config
  ((total++))
  local secrets_found=0
  if grep -rq "password\|secret\|token" "$HOME/.config/opencode/" 2>/dev/null; then
    secrets_found=1
  fi
  if [ "$secrets_found" -eq 0 ]; then
    ((score++))
    echo "  ✓ No hardcoded secrets"
  else
    echo "  ✗ Potential secrets found in config"
  fi
  
  # 3. Check SSH keys
  ((total++))
  if [ -f "$HOME/.ssh/id_rsa" ] || [ -f "$HOME/.ssh/id_ed25519" ]; then
    ((score++))
    echo "  ✓ SSH keys present"
  else
    echo "  ⚠ No SSH keys found"
  fi
  
  # 4. Check firewall
  ((total++))
  if command -v ufw &>/dev/null; then
    local firewall_status
    firewall_status=$(ufw status 2>/dev/null | head -1)
    if echo "$firewall_status" | grep -qi "active"; then
      ((score++))
      echo "  ✓ Firewall active"
    else
      echo "  ⚠ Firewall inactive"
    fi
  else
    echo "  ⚠ UFW not available"
  fi
  
  echo
  echo "Security Score: $score/$total"
}

# ── CLI Interface ────────────────────────────────────────────────────────────

cmd_security_hardening() {
  local subcmd="${1:-run}"
  shift || true
  
  case "$subcmd" in
    run) _security_hardening_run ;;
    help|*)
      cat <<'EOF'
Usage: opencode security-hardening <command>

Commands:
  run   Run security hardening checks
EOF
      ;;
  esac
}
