#!/usr/bin/env bash
# lib/59-local-memory.sh — Local-Only Persistent Memory (STEP 59)
# Installs opencode-mem, a local-first memory plugin (libSQL/Turso vector
# store + ONNX embeddings) that keeps conversation memory on-device — no
# cloud, no external API, fully air-gap compatible.
#
# GATED + opt-in: opencode-mem pulls heavy ONNX deps (onnxruntime-node,
# transformers), so it is NOT installed by default. Two switches:
#   SKIP_LOCAL_MEMORY=true     → hard opt-out (matches SKIP_* convention)
#   LOCAL_MEMORY_ENABLED=true  → opt-in (required to actually install)
#
# Plus shared config in ~/.config/opencode/local-memory.json so the memory
# backend stays self-describing and other harnesses can read the same map.
set -euo pipefail

_step_skip step_local_memory && return 0

# Opt-out (matches SKIP_DOTFILES / SKIP_DEVBOX / SKIP_GUI convention)
[ "${SKIP_LOCAL_MEMORY:-false}" = "true" ] && { info "Local memory skipped (SKIP_LOCAL_MEMORY=true)"; return 0; }

# Opt-in gate: opencode-mem has heavy ONNX deps — install only on request.
if [ "${LOCAL_MEMORY_ENABLED:-false}" != "true" ]; then
  info "Local memory skipped (set LOCAL_MEMORY_ENABLED=true to install opencode-mem)"
  return 0
fi

section "Local Memory — opencode-mem (local-only, air-gap)"

# ── opencode-mem: local-first persistent memory ─────────────────────────────
_install_local_memory() {
  if npm list -g opencode-mem >/dev/null 2>&1; then
    log "opencode-mem already present"
    return 0
  fi
  _spin_start "Installing opencode-mem (local-only memory, ONNX)"
  if npm install -g opencode-mem@latest --prefer-offline 2>/dev/null; then
    _spin_stop "✓"
    log "opencode-mem installed"
    return 0
  fi
  _spin_stop "✗"
  warn "opencode-mem install failed"
  return 1
}

# ── Local memory config ─────────────────────────────────────────────────────
# ~/.config/opencode/local-memory.json — self-describing backend so the memory
# layer stays readable by other harnesses (dsh, sandcastle).
_write_memory_config() {
  local cfg="${XDG_CONFIG_HOME:-$HOME/.config}/opencode/local-memory.json"
  mkdir -p "$(dirname "$cfg")"
  cat > "$cfg" <<'EOF'
{
  "version": 1,
  "managed_by": "opencode_initializer@59-local-memory",
  "backend": "libsql",
  "local_only": true
}
EOF
  log "Wrote $cfg"
}

# ── Health check ─────────────────────────────────────────────────────────────
_check_local_memory() {
  local ok=true
  if ! npm list -g opencode-mem >/dev/null 2>&1; then warn "opencode-mem missing"; ok=false; fi
  if [ ! -f "${XDG_CONFIG_HOME:-$HOME/.config}/opencode/local-memory.json" ]; then warn "local-memory.json missing"; ok=false; fi
  $ok && log "Local memory: OK" || return 1
}

# ── Main ─────────────────────────────────────────────────────────────────────
_install_local_memory || true
_write_memory_config
_check_local_memory || true
_step_done step_local_memory
