#!/usr/bin/env bash
# lib/06-node.sh — Node.js 24 via n (STEP 5)
set -euo pipefail

if ([ "$MODE" = "full" ] || [ "$MODE" = "reinit" ] || [ "$MODE" = "update" ]) && _gate "INTERACTIVE_DO_NODE"; then
  section "Node.js 24"
  N_PREFIX="${N_PREFIX:-$HOME/.n}"
  mkdir -p "$N_PREFIX" ~/.npm-global
  npm config set prefix ~/.npm-global 2>/dev/null || true
  if ! curl -fsSL --connect-timeout 5 https://registry.npmjs.org -o /dev/null 2>/dev/null; then
    npm config set registry "$NPM_REGISTRY" 2>/dev/null && info "npm: using mirror $NPM_REGISTRY"
  else
    npm config set strict-ssl true 2>/dev/null || true
  fi
  if [ ! -f "$N_PREFIX/bin/node" ] || ! node --version 2>/dev/null | grep -q "v24"; then
    npm install -g n@latest --prefix "$N_PREFIX" 2>/dev/null || true
    N_PREFIX="$N_PREFIX" n 24 2>/dev/null && log "Node.js 24 installed" || { warn "n 24 failed — trying apt"; sudo apt-get install -y -qq nodejs npm 2>/dev/null && log "Node.js from apt" || warn "Node.js unavailable"; }
  else
    log "Node.js 24 already installed"
  fi
  _step_done step_node
fi
