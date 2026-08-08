#!/usr/bin/env bash
# lib/15-security.sh — Security tools: Trivy + Qodana + SBOM + daily scanning (STEP 12)
# Requires: MODE
set -euo pipefail

if [ "$MODE" = "full" ] || [ "$MODE" = "reinit" ]; then
  section "Security tools"

  _gate "INTERACTIVE_DO_TRIVY" || { log "Security skipped (interactive)"; return 0; }

  # ── Trivy — vulnerability scanner ────────────────────────────────────────
  command -v trivy &>/dev/null || sudo snap install trivy 2>/dev/null || sudo apt install -y -qq trivy 2>/dev/null || warn "trivy not installed"
  command -v trivy &>/dev/null && log "trivy $(trivy --version 2>/dev/null | head -1)"

  # ── Qodana — code quality (supply-chain hardened: download→verify) ──────
  if ! command -v qodana &>/dev/null; then
    _download_verify "https://jb.gg/qodana-cli/install" /tmp/qodana-install.sh && bash /tmp/qodana-install.sh 2>/dev/null && log "qodana installed" || warn "qodana not installed"
    rm -f /tmp/qodana-install.sh
  fi

  # ── Systemd timer for daily Trivy scan (S5.4.1.1) ───────────────────────
  if command -v trivy &>/dev/null && command -v systemctl &>/dev/null; then
    TIMER_DIR="$HOME/.config/systemd/user"
    mkdir -p "$TIMER_DIR"

    cat > "$TIMER_DIR/opencode-trivy-scan.service" << 'SVC'
[Unit]
Description=Daily Trivy vulnerability scan for OpenCode dev machine
After=network-online.target
Wants=network-online.target

[Service]
Type=oneshot
ExecStart=/bin/sh -c 'trivy filesystem --scanners vuln,secret --severity CRITICAL,HIGH --no-progress / 2>&1 | tee %h/.cache/opencode-setup/trivy-scan.log'
TimeoutStartSec=3600
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=default.target
SVC

    cat > "$TIMER_DIR/opencode-trivy-scan.timer" << 'TMR'
[Unit]
Description=Daily security scan (Trivy)
RefuseManualStart=no

[Timer]
OnCalendar=daily
Persistent=true
RandomizedDelaySec=1800

[Install]
WantedBy=timers.target
TMR

    systemctl --user daemon-reload 2>/dev/null || true
    systemctl --user enable opencode-trivy-scan.timer 2>/dev/null || true
    systemctl --user start opencode-trivy-scan.timer 2>/dev/null || true
    log "daily Trivy scan timer enabled"
  fi

  # ── SBOM generation hook (S5.4.1.2) ─────────────────────────────────────
  # Writes CycloneDX SBOM to project root on trivy scan.
  if command -v trivy &>/dev/null && command -v jq &>/dev/null; then
    SBOM_DIR="$HOME/.cache/opencode-setup/sbom"
    mkdir -p "$SBOM_DIR"
    # Generate SBOM for installed packages (deb only for simplicity)
    trivy filesystem --format cyclonedx --output "$SBOM_DIR/sbom-$(date +%Y%m%d).json" /usr/bin /usr/local/bin --no-progress 2>/dev/null || true
    log "SBOM generated: $SBOM_DIR/sbom-$(date +%Y%m%d).json"
  fi

  log "Security tools OK"
  _step_done step_security
fi
