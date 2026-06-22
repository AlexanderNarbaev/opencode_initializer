#!/usr/bin/env bash
# lib/20-autoupdate.sh — Auto-update system: topgrade + systemd timer + version check (STEP 20)
# Requires: MODE, CORE_PATH
set -euo pipefail

if ([ "$MODE" = "full" ] || [ "$MODE" = "reinit" ] || [ "$MODE" = "update" ]) && _gate "INTERACTIVE_DO_SYSTEM"; then
  section "Auto-update system (topgrade + timer)"

  # ── topgrade — universal package updater ──────────────────────────────────
  if ! command -v topgrade &>/dev/null; then
    if command -v cargo &>/dev/null; then
      timeout 300 cargo install topgrade 2>/dev/null && log "topgrade installed (cargo)" || warn "topgrade cargo install failed"
    fi
    command -v topgrade &>/dev/null || { _sudo apt-get install -y -qq topgrade 2>/dev/null && log "topgrade installed (apt)"; } || warn "topgrade not installed"
  else
    log "topgrade $(topgrade --version 2>/dev/null || echo 'installed')"
  fi

  # ── abtop — AI session monitor (htop for AI agents) ─────────────────────
  if ! command -v abtop &>/dev/null; then
    command -v cargo &>/dev/null && timeout 180 cargo install abtop 2>/dev/null && log "abtop installed" || warn "abtop install skipped"
  else
    log "abtop $(abtop --version 2>/dev/null || echo 'installed')"
  fi

  # ── Systemd timer for weekly updates ─────────────────────────────────────
  if command -v systemctl &>/dev/null; then
    SYSTEMD_USER_DIR="$HOME/.config/systemd/user"
    mkdir -p "$SYSTEMD_USER_DIR"

    cat > "$SYSTEMD_USER_DIR/opencode-update.service" << 'SVC'
[Unit]
Description=OpenCode Dev Machine Weekly Auto-Update
After=network-online.target
Wants=network-online.target

[Service]
Type=oneshot
ExecStartPre=/bin/mkdir -p %h/.cache/opencode-setup
ExecStart=/bin/sh -c 'if [ -x "$HOME/.cargo/bin/topgrade" ]; then $HOME/.cargo/bin/topgrade --yes --no-retry --skip-notify; elif command -v topgrade >/dev/null; then topgrade --yes --no-retry --skip-notify; else echo "topgrade not found" >&2; fi'
ExecStartPost=/bin/bash -c 'echo "$(date -Iseconds) topgrade completed" >> %h/.cache/opencode-setup/update.log'
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=default.target
SVC

    cat > "$SYSTEMD_USER_DIR/opencode-update.timer" << 'TMR'
[Unit]
Description=Weekly auto-update for dev machine (Sun 04:00)
RefuseManualStart=no
RefuseManualStop=no

[Timer]
OnCalendar=Sun 04:00
Persistent=true
RandomizedDelaySec=600

[Install]
WantedBy=timers.target
TMR

    systemctl --user daemon-reload 2>/dev/null || true
    systemctl --user enable opencode-update.timer 2>/dev/null || true
    systemctl --user start opencode-update.timer 2>/dev/null || true
    log "auto-update timer enabled (weekly Sun 04:00)"
  fi

  # ── unattended-upgrades for daily security patches ──────────────────────
  if command -v apt-get &>/dev/null; then
    _sudo apt-get install -y -qq unattended-upgrades 2>/dev/null || true
    if [ -f /etc/apt/apt.conf.d/50unattended-upgrades ]; then
      _sudo dpkg-reconfigure -f noninteractive unattended-upgrades 2>/dev/null || true
      log "unattended-upgrades active (daily security)"
    fi
  fi

  _step_done step_autoupdate
fi
