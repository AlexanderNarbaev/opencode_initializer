#!/usr/bin/env bash
# src/lib/23-just.sh — Just: command runner (Make alternative)
# Installs just — a handy task runner for project automation
set -euo pipefail

_step_skip step_just && return 0

section "Just — Task Runner"

if ! command -v just &>/dev/null; then
  _progress "just" "Installing task runner..."
  _spin_start "Downloading just"
  
  local just_ver="1.45.0"
  local just_url="https://github.com/casey/just/releases/download/${just_ver}/just-${just_ver}-x86_64-unknown-linux-musl.tar.gz"
  local just_tmp="/tmp/just-${just_ver}.tar.gz"
  
  if _curl "$just_url" "$just_tmp"; then
    tar -xzf "$just_tmp" -C /tmp/ just 2>/dev/null
    mkdir -p "$HOME/.local/bin"
    mv /tmp/just "$HOME/.local/bin/just" 2>/dev/null
    chmod +x "$HOME/.local/bin/just" 2>/dev/null
    _spin_stop "✓"
    log "just $(just --version 2>/dev/null | head -1) installed"
  else
    _spin_stop "✗"
    # Fallback: try cargo install
    if command -v cargo &>/dev/null; then
      cargo install just 2>/dev/null && log "just (cargo) installed" || warn "just install failed — skipping"
    else
      warn "just install failed — skipping"
    fi
    return 0
  fi
else
  log "just $(just --version 2>/dev/null | head -1) already present"
fi

# Create default justfile if none exists
if [ ! -f "$PROJECT_DIR/justfile" ] && [ ! -f "$HOME/justfile" ]; then
  cat > "$PROJECT_DIR/justfile" << 'JUSTFILE'
# default recipe — list available commands
default:
    @just --list

# Build all project components
build:
    echo "Building..."

# Run project tests
test:
    echo "Testing..."

# Lint and format code
lint:
    echo "Linting..."

# Clean build artifacts
clean:
    rm -rf build/ dist/

# Run development server
dev:
    echo "Starting dev server..."
JUSTFILE
  log "Created default justfile in $PROJECT_DIR"
fi

_step_done "step_just"
log "just configured — use 'just --list' to see available recipes"
