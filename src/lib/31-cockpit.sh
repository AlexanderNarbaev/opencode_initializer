#!/usr/bin/env bash
# lib/31-cockpit.sh — Cockpit TUI build and install
# Requires: Go 1.22+, MODE
set -euo pipefail

_step_skip step_cockpit && return 0

section "Cockpit TUI"

COCKPIT_DIR="$SCRIPT_DIR/src/cockpit"
BIN_PATH="$HOME/.local/bin/cockpit"

if [ ! -f "$BIN_PATH" ] || [ "$MODE" = "reinit" ]; then
  if command -v go &>/dev/null && [ -d "$COCKPIT_DIR" ]; then
    cd "$COCKPIT_DIR"
    if [ ! -f "go.sum" ]; then
      go mod tidy 2>/dev/null || true
    fi
    CGO_ENABLED=0 go build -ldflags="-s -w" -o "$BIN_PATH" . 2>/dev/null && \
      log "cockpit installed to $BIN_PATH" || \
      warn "cockpit build failed — check Go version (need 1.22+)"
  else
    warn "cockpit: Go not found or source missing"
  fi
else
  log "cockpit already installed"
fi

_step_done step_cockpit
