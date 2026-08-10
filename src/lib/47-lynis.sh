#!/usr/bin/env bash
# lib/47-lynis.sh — Lynis security audit integration + weekly cronjob (STEP 47)
# Sources: DeepSeek chat "Аудит и установка в Ubuntu" (2026-07-15)
# Lynis: CIS benchmark scanner, hardening index target ≥80
set -euo pipefail

_step_skip step_lynis && return 0

section "Lynis — Security Audit Scanner"

_lynis_install() {
  if command -v lynis &>/dev/null; then
    log "Lynis already installed: $(lynis --version 2>/dev/null | head -1)"
    return 0
  fi
  _spin_start "Installing Lynis"
  # Supply-chain hardened: download key → verify → add repo
  _curl -fsSL "https://packages.cisofy.com/keys/cisofy-software-public.key" | \
    sudo gpg --dearmor -o /usr/share/keyrings/cisofy-archive-keyring.gpg 2>/dev/null || {
    _spin_stop "✗"
    warn "Lynis GPG key download failed — skipping Lynis"
    return 0
  }
  echo "deb [signed-by=/usr/share/keyrings/cisofy-archive-keyring.gpg] https://packages.cisofy.com/community/lynis/deb/ stable main" | \
    sudo tee /etc/apt/sources.list.d/cisofy-lynis.list >/dev/null
  sudo apt-get update -qq && sudo apt-get install -y -qq lynis
  _spin_stop "✓"
  log "Lynis installed"
}

_lynis_audit() {
  if ! command -v lynis &>/dev/null; then
    warn "Lynis not installed — skipping audit"
    return 0
  fi
  section "Lynis Security Audit"
  local report_file="${HOME}/.cache/opencode-setup/lynis-$(date +%Y%m%d-%H%M%S).log"
  _spin_start "Running Lynis quick audit"
  sudo lynis audit system --quick --no-colors 2>/dev/null | tee "$report_file" || true
  _spin_stop "✓"
  local hardening_index
  hardening_index=$(grep "Hardening index" "$report_file" | grep -oE '[0-9]+' | head -1 || echo "0")
  if [ "${hardening_index:-0}" -ge 80 ]; then
    log "Lynis hardening index: $hardening_index (target ≥80) — GOOD"
  else
    warn "Lynis hardening index: ${hardening_index:-unknown} (target ≥80) — review report: $report_file"
  fi
}

_lynis_setup_cron() {
  local cron_file="/etc/cron.weekly/lynis-audit"
  if [ -f "$cron_file" ]; then
    log "Lynis weekly cron already configured"
    return 0
  fi
  sudo tee "$cron_file" >/dev/null <<'CRON'
#!/bin/bash
# Weekly Lynis security audit — installed by opencode_initializer 47-lynis.sh
/usr/sbin/lynis audit system --cronjob --no-colors > /var/log/lynis-weekly.log 2>&1
CRON
  sudo chmod +x "$cron_file"
  log "Lynis weekly cron installed: $cron_file"
}

# Main
_lynis_install
_lynis_audit
_lynis_setup_cron

_step_done step_lynis
log "Lynis audit scanner active"
