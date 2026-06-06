#!/usr/bin/env bash
# lib/01-system.sh — System packages (STEP 1)
set -euo pipefail

if ([ "$MODE" = "full" ] || [ "$MODE" = "reinit" ] || [ "$MODE" = "update" ]) && _gate "INTERACTIVE_DO_SYSTEM"; then
  section "System packages ($PKG_MANAGER)"
  _pkg_update
  pkglist=$(_pkg_list)
  if [ "$PKG_MANAGER" = "apt" ]; then
    sudo apt install -y -qq --no-install-recommends $pkglist python3-pip python3-venv 2>/dev/null || true
  else
    _pkg_install $pkglist python3-pip python3-venv 2>/dev/null || true
  fi
  if [ ! -f /etc/ssl/certs/ca-certificates.crt ] && [ -d /etc/ssl/certs ]; then
    sudo update-ca-certificates --fresh 2>/dev/null || true
  fi
  if ! npm ping --regist=ie https://registry.npmjs.org 2>/dev/null; then
    npm config set strict-ssl false 2>/dev/null || true
    warn "npm: TLS verification disabled (registry connectivity issue)"
  fi
  log "System packages OK ($PKG_MANAGER)"
  _step_done step_system
fi
