#!/usr/bin/env bash
# lib/57-context-guard.sh — Context Compression beyond dcp (STEP 57)
# Extends OpenCode's context management beyond the built-in opencode-dcp
# plugin (pruning/compression). Adds three best-effort plugins:
#
#   @skybluejacket/opencode-context-compress — model-directed manual + auto
#                                              compression (tokenizer-aware)
#   opencode-context-guard                    — STATE.md injection, planning
#                                              artifacts, git-aware guardrails
#   opencode-context-watch                    — warns when the context window
#                                              crosses a usage threshold
#
# Plus a shared config in ~/.config/opencode/context-guard.json so the
# compression/watch thresholds stay consistent under opencode_initializer's
# "one organism" policy. Plugin registration in opencode.json is centralized
# elsewhere (18-opencode-json.sh) — this module only installs + writes its
# own config, it never touches opencode.json.
set -euo pipefail

_step_skip step_context_guard && return 0

# Opt-out (matches SKIP_DOTFILES / SKIP_DEVBOX / SKIP_GUI convention)
[ "${SKIP_CONTEXT_GUARD:-false}" = "true" ] && { info "Context guard skipped (SKIP_CONTEXT_GUARD=true)"; return 0; }

section "Context Guard — Compression, Guardrails & Window Watch"

# ── Helper: is an npm package installed globally? ────────────────────────────
# These are plugins (no CLI binary), so presence is checked via the global
# node_modules tree rather than `command -v`.
_ctx_guard_installed() {
  local root
  root="$(npm root -g 2>/dev/null)" || return 1
  [ -d "$root/$1" ]
}

# ── @skybluejacket/opencode-context-compress ─────────────────────────────────
_install_context_compress() {
  if _ctx_guard_installed "@skybluejacket/opencode-context-compress"; then
    log "@skybluejacket/opencode-context-compress already present"
    return 0
  fi
  _spin_start "Installing @skybluejacket/opencode-context-compress (model-directed compression)"
  if npm install -g @skybluejacket/opencode-context-compress@latest --prefer-offline 2>/dev/null; then
    _spin_stop "✓"
    log "@skybluejacket/opencode-context-compress installed"
    return 0
  fi
  _spin_stop "✗"
  warn "@skybluejacket/opencode-context-compress install failed"
  return 1
}

# ── opencode-context-guard ───────────────────────────────────────────────────
_install_context_guard() {
  if _ctx_guard_installed "opencode-context-guard"; then
    log "opencode-context-guard already present"
    return 0
  fi
  _spin_start "Installing opencode-context-guard (STATE.md + planning guardrails)"
  if npm install -g opencode-context-guard@latest --prefer-offline 2>/dev/null; then
    _spin_stop "✓"
    log "opencode-context-guard installed"
    return 0
  fi
  _spin_stop "✗"
  warn "opencode-context-guard install failed"
  return 1
}

# ── opencode-context-watch ───────────────────────────────────────────────────
_install_context_watch() {
  if _ctx_guard_installed "opencode-context-watch"; then
    log "opencode-context-watch already present"
    return 0
  fi
  _spin_start "Installing opencode-context-watch (context window threshold watch)"
  if npm install -g opencode-context-watch@latest --prefer-offline 2>/dev/null; then
    _spin_stop "✓"
    log "opencode-context-watch installed"
    return 0
  fi
  _spin_stop "✗"
  warn "opencode-context-watch install failed"
  return 1
}

# ── Context guard config ─────────────────────────────────────────────────────
# ~/.config/opencode/context-guard.json — compression + window-watch thresholds
# read by the three plugins so behavior stays consistent across harnesses.
_write_context_guard_config() {
  local cfg="${XDG_CONFIG_HOME:-$HOME/.config}/opencode/context-guard.json"
  mkdir -p "$(dirname "$cfg")"
  cat > "$cfg" <<'EOF'
{
  "version": 1,
  "managed_by": "opencode_initializer@57-context-guard",
  "compress": { "enabled": true, "auto": true },
  "watch": { "threshold": 0.85 }
}
EOF
  log "Wrote $cfg"
}

# ── Health check ─────────────────────────────────────────────────────────────
_check_context_guard() {
  local ok=true
  if ! _ctx_guard_installed "@skybluejacket/opencode-context-compress"; then warn "@skybluejacket/opencode-context-compress missing"; ok=false; fi
  if ! _ctx_guard_installed "opencode-context-guard";  then warn "opencode-context-guard missing";  ok=false; fi
  if ! _ctx_guard_installed "opencode-context-watch";  then warn "opencode-context-watch missing";  ok=false; fi
  $ok && log "Context guard: OK" || return 1
}

# ── Main ─────────────────────────────────────────────────────────────────────
_install_context_compress || true
_install_context_guard    || true
_install_context_watch    || true
_write_context_guard_config
_check_context_guard || true
_step_done step_context_guard
