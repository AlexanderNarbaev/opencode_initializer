#!/usr/bin/env bash
# lib/48-auditd.sh — Linux kernel audit daemon + rules (STEP 48)
# Sources: DeepSeek chat "Аудит и установка в Ubuntu" (2026-07-15)
set -euo pipefail

_step_skip step_auditd && return 0

section "auditd — Kernel Audit Daemon"

_auditd_install() {
  if systemctl is-active auditd &>/dev/null; then
    log "auditd already running"
    return 0
  fi
  _spin_start "Installing auditd"
  sudo apt-get install -y -qq auditd audispd-plugins
  sudo systemctl enable auditd
  sudo systemctl start auditd
  _spin_stop "✓"
  log "auditd installed and running"
}

_auditd_apply_rules() {
  local rules_file="/etc/audit/rules.d/99-opencode.rules"
  if [ -f "$rules_file" ]; then
    log "auditd opencode rules already present"
    return 0
  fi
  section "Configuring auditd rules"
  sudo tee "$rules_file" >/dev/null <<'RULES'
# opencode_initializer — kernel audit rules
# Monitor identity changes
-w /etc/passwd -p wa -k identity
-w /etc/shadow -p wa -k identity
-w /etc/group -p wa -k identity
-w /etc/gshadow -p wa -k identity
-w /etc/sudoers -p wa -k identity
-w /etc/sudoers.d/ -p wa -k identity

# Monitor network config
-w /etc/hosts -p wa -k network
-w /etc/hostname -p wa -k network
-w /etc/resolv.conf -p wa -k network

# Monitor cron changes
-w /etc/crontab -p wa -k cron
-w /etc/cron.d/ -p wa -k cron
-w /var/spool/cron/ -p wa -k cron

# Monitor sudo usage
-a always,exit -F arch=b64 -S execve -F euid=0 -F auid>=1000 -F auid!=4294967295 -k sudo_usage
RULES
  sudo augenrules --load 2>/dev/null || sudo service auditd restart 2>/dev/null || true
  log "auditd rules applied: $rules_file"
}

# Main
_auditd_install
_auditd_apply_rules

_step_done step_auditd
log "Kernel audit daemon active"
