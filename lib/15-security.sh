#!/usr/bin/env bash
# lib/15-security.sh — Security tools: Trivy + Qodana (STEP 12)
# Requires: MODE
set -euo pipefail

if [ "$MODE" = "full" ] || [ "$MODE" = "reinit" ]; then
  section "Security tools"
  command -v trivy &>/dev/null || sudo snap install trivy 2>/dev/null || sudo apt install -y -qq trivy 2>/dev/null || warn "trivy not installed"
  if ! command -v qodana &>/dev/null; then
    curl -fsSL --connect-timeout 30 --retry 2 --retry-delay 5 \
      "https://jb.gg/qodana-cli/install" 2>/dev/null | bash 2>/dev/null && log "qodana installed" || warn "qodana not installed"
  fi
  log "Security tools OK"
fi
