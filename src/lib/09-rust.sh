#!/usr/bin/env bash
# lib/09-rust.sh — Rust via rustup (STEP 6b)
set -euo pipefail

if ([ "$MODE" = "full" ] || [ "$MODE" = "reinit" ] || [ "$MODE" = "update" ]) && _gate "INTERACTIVE_DO_RUST"; then
  section "Rust"
  if ! command -v rustc &>/dev/null; then
    RUSTUP_SCRIPT=$(mktemp /tmp/rustup-init.XXXXXX.sh)
    if _curl "https://sh.rustup.rs" "$RUSTUP_SCRIPT" 2>/dev/null; then
      sh "$RUSTUP_SCRIPT" -y --default-toolchain stable 2>/dev/null && log "Rust installed" || warn "Rust install failed"
      rm -f "$RUSTUP_SCRIPT"
      export PATH="$HOME/.cargo/bin:$PATH"
    else
      warn "Rust download failed — trying apt fallback"
      sudo apt-get install -y -qq cargo rustc 2>/dev/null && log "Rust from apt" || warn "Rust unavailable — install manually"
    fi
  else
    log "Rust $(rustc --version 2>/dev/null | cut -d' ' -f2) already installed"
  fi
  _step_done step_rust
fi
