#!/usr/bin/env bash
# lib/58-provider-discovery.sh — Provider Auto-Discovery (STEP 58)
# Auto-discovers OpenAI-compatible models from local backends (ollama/lmstudio/
# localai) and provides a TUI/CLI provider manager for opencode.json. Both are
# best-effort installs under the "one organism" policy: discovered providers
# complement, never replace, the 23-provider registry in 26-providers.sh.
#
# Packages added:
#   opencode-models-discovery — auto-discovery of OpenAI-compatible models
#   opencode-provider-manager — bin `opm`; manage opencode.json providers
set -euo pipefail

_step_skip step_provider_discovery && return 0

# Opt-out (matches SKIP_DOTFILES / SKIP_DEVBOX / SKIP_GUI convention)
[ "${SKIP_PROVIDER_DISCOVERY:-false}" = "true" ] && { info "Provider auto-discovery skipped (SKIP_PROVIDER_DISCOVERY=true)"; return 0; }

section "Provider Auto-Discovery — models discovery + provider manager"

# ── opencode-models-discovery: auto-discovery of OpenAI-compatible models ────
_install_models_discovery() {
  if npm list -g opencode-models-discovery --depth=0 >/dev/null 2>&1; then
    log "opencode-models-discovery already present"
    return 0
  fi
  _spin_start "Installing opencode-models-discovery (local model auto-discovery)"
  if npm install -g opencode-models-discovery@latest --prefer-offline 2>/dev/null; then
    _spin_stop "✓"
    log "opencode-models-discovery installed"
    return 0
  fi
  _spin_stop "✗"
  warn "opencode-models-discovery install failed"
  return 1
}

# ── opencode-provider-manager: bin `opm` — manage opencode.json providers ────
_install_provider_manager() {
  if command -v opm >/dev/null 2>&1; then
    log "opencode-provider-manager (opm) already present"
    return 0
  fi
  _spin_start "Installing opencode-provider-manager (opm TUI/CLI)"
  if npm install -g opencode-provider-manager@latest --prefer-offline 2>/dev/null; then
    _spin_stop "✓"
    log "opencode-provider-manager installed"
    return 0
  fi
  _spin_stop "✗"
  warn "opencode-provider-manager install failed"
  return 1
}

# ── Configure: register in opencode.json plugin array ───────────────────────
# Idempotent: skips if both entries already present.
_register_provider_discovery_plugins() {
  local cfg="${XDG_CONFIG_HOME:-$HOME/.config}/opencode/opencode.json"
  [ -f "$cfg" ] || { warn "opencode.json not found"; return 1; }

  # Insert both packages into the plugin array if absent.
  if grep -q '"opencode-models-discovery"' "$cfg" && grep -q '"opencode-provider-manager"' "$cfg"; then
    log "Provider discovery already in plugin array"
    return 0
  fi

  # Use python for safe JSON edit.
  python3 - <<PYEOF
import json, pathlib
p = pathlib.Path("$cfg")
data = json.loads(p.read_text())
plugins = data.get("plugin", [])
if "opencode-models-discovery" not in plugins:
    plugins.append("opencode-models-discovery")
if "opencode-provider-manager" not in plugins:
    plugins.append("opencode-provider-manager")
data["plugin"] = plugins
p.write_text(json.dumps(data, indent=2) + "\n")
print("ADDED: opencode-models-discovery + opencode-provider-manager to plugin array")
PYEOF

  log "Provider discovery registered in plugin array"
}

# ── Health check ─────────────────────────────────────────────────────────────
_check_provider_discovery() {
  local ok=true
  if ! npm list -g opencode-models-discovery --depth=0 >/dev/null 2>&1; then warn "opencode-models-discovery missing"; ok=false; fi
  if ! command -v opm >/dev/null 2>&1; then warn "opencode-provider-manager (opm) missing"; ok=false; fi
  $ok && log "Provider discovery: OK" || return 1
}

# ── Main ─────────────────────────────────────────────────────────────────────
_install_models_discovery || true
_install_provider_manager  || true
_register_provider_discovery_plugins
_check_provider_discovery || true
