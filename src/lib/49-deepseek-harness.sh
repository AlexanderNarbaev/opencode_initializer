#!/usr/bin/env bash
# lib/49-deepseek-harness.sh — DeepSeek Harness (dsh) agent harness (STEP 49)
# Sources: https://github.com/deepseek-ai/deepseek-harness
# dsh: open-source agent harness, "everything is a plugin", powered by Cordis.
# Developer preview — compatibility-breaking changes expected. MIT license.
set -euo pipefail

_step_skip step_deepseek_harness && return 0

# Opt-out flag (matches SKIP_DOTFILES / SKIP_DEVBOX / SKIP_GUI convention)
[ "${SKIP_DEEPSEEK_HARNESS:-false}" = "true" ] && { info "DeepSeek Harness skipped (SKIP_DEEPSEEK_HARNESS=true)"; return 0; }

section "DeepSeek Harness — Agent Harness"

DSH_CONFIG_DIR="${HOME}/.config/deepseek-harness"
DSH_WEB_PORT="${DSH_WEB_PORT:-3080}"

_install_deepseek_harness() {
  # Prerequisite: Node.js (06-node.sh installs Node 24)
  if ! command -v node &>/dev/null; then
    warn "Node.js not found — DeepSeek Harness requires Node.js (install via 06-node.sh). Skipping."
    return 0
  fi

  # Already installed (global bin `dsh`, else npx-resolved package)
  if command -v dsh &>/dev/null; then
    log "dsh $(dsh --version 2>/dev/null | head -1 || echo 'installed') already present"
    return 0
  fi

  _progress "dsh" "Installing DeepSeek Harness (@deepseek-ai/dsh)..."
  _spin_start "Installing @deepseek-ai/dsh"
  if timeout 180 npm install -g "@deepseek-ai/dsh@latest" --prefer-offline 2>/dev/null; then
    _spin_stop "✓"
    log "DeepSeek Harness installed: $(dsh --version 2>/dev/null | head -1 || echo 'latest')"
  else
    _spin_stop "✗"
    warn "DeepSeek Harness npm install failed — run manually: npx @deepseek-ai/dsh web"
    return 0
  fi
}

_configure_deepseek_harness() {
  mkdir -p "$DSH_CONFIG_DIR"

  # Default plugin profile (cordis.yml). dsh loads plugins from this file.
  # Plugin keys are intentionally left as commented stubs — the exact keys are
  # defined in the upstream config catalog (developer preview, breaking changes):
  #   https://github.com/deepseek-ai/deepseek-harness (docs/config-catalog.md)
  # Do NOT invent keys here; uncomment + fill exact keys once the catalog documents them.
  if [ ! -f "$DSH_CONFIG_DIR/cordis.yml" ]; then
    cat > "$DSH_CONFIG_DIR/cordis.yml" << 'CORDIS'
# DeepSeek Harness — default plugin profile (managed by opencode_initializer)
# dsh is "everything is a plugin" (Cordis). Plugins are mounted in this file.
# Web UI is served at http://127.0.0.1:3080 by default.
#
# Plugin keys are defined in the upstream config catalog — do NOT invent keys:
#   https://github.com/deepseek-ai/deepseek-harness (docs/config-catalog.md)
#
# Starter plugin stubs (uncomment + set the exact key once the catalog documents it):
#
# ── pre-session-check ──────────────────────────────────────────────────────
#   Wires provider + model + MCP validation into the harness lifecycle.
#   Mirrors src/lib/pre-session-check.sh (see opencode_initializer repo).
#   # pre-session-check: { enabled: true }
#
# ── pii-guard ─────────────────────────────────────────────────────────────
#   Pre-request PII sanitizer (9 detectors: email, phone, INN, SNILS, passport,
#   credit card, IP, API key). Mirrors scripts/pii-guard.py + 45-pii-guard.sh.
#   # pii-guard: { enabled: true }
#
# ── wal-checkpoint ────────────────────────────────────────────────────────
#   Checkpoints consequential decisions to the agent journal
#   (~/.cache/opencode/wal.jsonl, SHA-256 hash-chain). Mirrors 37-wal.sh.
#   # wal-checkpoint: { enabled: true }
CORDIS
    log "Created default plugin profile: $DSH_CONFIG_DIR/cordis.yml"
  else
    log "DeepSeek Harness config already present: $DSH_CONFIG_DIR/cordis.yml"
  fi

  # Web UI port default (env-overridable, baked into the systemd service)
  info "DeepSeek Harness Web UI port: $DSH_WEB_PORT (override via DSH_WEB_PORT)"
}

_deepseek_harness_service() {
  # Optional systemd user service for the Web UI (pattern: 22-webui-service.sh)
  local dsh_bin
  dsh_bin="$(command -v dsh 2>/dev/null || true)"
  [ -z "$dsh_bin" ] && { warn "dsh binary not found — skipping systemd service"; return 0; }

  mkdir -p "$HOME/.config/systemd/user"
  # Absolute binary path baked in (instant cold start — mirrors Bun bin path decision)
  cat > "$HOME/.config/systemd/user/deepseek-harness.service" << SVC
[Unit]
Description=DeepSeek Harness — Agent Harness Web UI
After=network.target
Wants=network.target

[Service]
Type=simple
Environment=DSH_WEB_PORT=$DSH_WEB_PORT
ExecStart=$dsh_bin web --host 127.0.0.1 --port $DSH_WEB_PORT
Restart=on-failure
RestartSec=5

[Install]
WantedBy=default.target
SVC

  systemctl --user daemon-reload 2>/dev/null || true
  systemctl --user enable deepseek-harness.service 2>/dev/null || true
  systemctl --user start deepseek-harness.service 2>/dev/null || true
  log "DeepSeek Harness systemd user service installed (port $DSH_WEB_PORT)"
}

_check_deepseek_harness() {
  # Health check — returns 0 if the binary is present (Web UI is best-effort).
  if ! command -v dsh &>/dev/null; then
    warn "dsh not installed"
    return 1
  fi
  log "dsh: $(dsh --version 2>/dev/null | head -1 || echo 'present')"
  if curl -fsS --max-time 3 "http://127.0.0.1:${DSH_WEB_PORT}" >/dev/null 2>&1; then
    log "DeepSeek Harness Web UI: http://127.0.0.1:${DSH_WEB_PORT} (up)"
  else
    info "DeepSeek Harness Web UI not running on port ${DSH_WEB_PORT} (start: systemctl --user start deepseek-harness)"
  fi
  return 0
}

# ── Main ─────────────────────────────────────────────────────────────────────
_install_deepseek_harness
if command -v dsh &>/dev/null; then
  _configure_deepseek_harness
  _deepseek_harness_service
  _check_deepseek_harness
fi

_step_done step_deepseek_harness
log "DeepSeek Harness configured — run 'npx @deepseek-ai/dsh web' or the systemd service"
