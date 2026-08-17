#!/usr/bin/env bash
# lib/55-context-bundle.sh — Extended Context & Token Plugins (STEP 55)
# Installs additional opencode-* plugins that extend context management,
# token optimization, and provider routing — on top of the 18 plugins
# installed by setup.sh's default array. All under opencode_initializer's
# "one organism" policy: plugins complement, never replace, the core.
#
# Plugins added:
#   opencode-context  — semantic code search with ranked matches & snippets
#   opencode-router   — Slack/Telegram bridge + directory routing
#
# Plus shared config in ~/.config/opencode/bundle.json so other harnesses
# (dsh, sandcastle) can read the same provider/model map.
set -euo pipefail

_step_skip step_context_bundle && return 0

# Opt-out (matches SKIP_DOTFILES / SKIP_DEVBOX / SKIP_GUI convention)
[ "${SKIP_CONTEXT_BUNDLE:-false}" = "true" ] && { info "Context bundle skipped (SKIP_CONTEXT_BUNDLE=true)"; return 0; }

section "Context & Token Bundle — Extended OpenCode Plugins"

# ── opencode-context: semantic code search ────────────────────────────────────
_install_opencode_context() {
  if [ -x "$(command -v opencode-context 2>/dev/null)" ]; then
    log "opencode-context already present"
    return 0
  fi
  _spin_start "Installing opencode-context (semantic code search)"
  if npm install -g opencode-context@latest --prefer-offline 2>/dev/null; then
    _spin_stop "✓"
    log "opencode-context installed"
    return 0
  fi
  _spin_stop "✗"
  warn "opencode-context install failed"
  return 1
}

# ── opencode-router: Slack/Telegram bridge + directory routing ──────────────
_install_opencode_router() {
  if [ -x "$(command -v opencode-router 2>/dev/null)" ]; then
    log "opencode-router already present"
    return 0
  fi
  _spin_start "Installing opencode-router (Slack/Telegram bridge)"
  if npm install -g opencode-router@latest --prefer-offline 2>/dev/null; then
    _spin_stop "✓"
    log "opencode-router installed"
    return 0
  fi
  _spin_stop "✗"
  warn "opencode-router install failed"
  return 1
}

# ── Shared bundle config ─────────────────────────────────────────────────────
# ~/.config/opencode/bundle.json — read by dsh, sandcastle, and other harnesses
# so provider/model map is consistent across the whole "one organism".
_write_bundle_config() {
  local cfg="${XDG_CONFIG_HOME:-$HOME/.config}/opencode/bundle.json"
  mkdir -p "$(dirname "$cfg")"
  cat > "$cfg" <<'EOF'
{
  "version": 1,
  "managed_by": "opencode_initializer@55-context-bundle",
  "plugins": {
    "context": "opencode-context",
    "router":  "opencode-router"
  },
  "principles": [
    "all-harnesses-share-config",
    "plugins-complement-core",
    "context-is-shared-resource"
  ]
}
EOF
  log "Wrote $cfg"
}

# ── Health check ─────────────────────────────────────────────────────────────
_check_context_bundle() {
  local ok=true
  if ! command -v opencode-context >/dev/null 2>&1; then warn "opencode-context missing"; ok=false; fi
  if ! command -v opencode-router  >/dev/null 2>&1; then warn "opencode-router missing";  ok=false; fi
  $ok && log "Context bundle: OK" || return 1
}

# ── Configure: register in opencode.json plugin array ───────────────────────
# Idempotent: skips if both entries already present.
_configure_context_bundle() {
  local cfg="${XDG_CONFIG_HOME:-$HOME/.config}/opencode/opencode.json"
  [ -f "$cfg" ] || { warn "opencode.json not found"; return 1; }

  # Insert before the closing ']' of the plugin array.
  if grep -q '"opencode-context"' "$cfg" && grep -q '"opencode-router"' "$cfg"; then
    log "Context bundle already in plugin array"
    return 0
  fi

  # Use python for safe JSON edit.
  python3 - <<PYEOF
import json, pathlib
p = pathlib.Path("$cfg")
data = json.loads(p.read_text())
plugins = data.get("plugin", [])
if "opencode-context" not in plugins:
    plugins.append("opencode-context")
if "opencode-router"  not in plugins:
    plugins.append("opencode-router")
data["plugin"] = plugins
p.write_text(json.dumps(data, indent=2) + "\n")
print("ADDED: opencode-context + opencode-router to plugin array")
PYEOF

  log "Context bundle registered in plugin array"
}

# ── Main ─────────────────────────────────────────────────────────────────────
_install_opencode_context || true
_install_opencode_router  || true
_write_bundle_config
_configure_context_bundle
_check_context_bundle || true