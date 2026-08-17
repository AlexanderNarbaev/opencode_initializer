#!/usr/bin/env bash
# lib/56-caching.sh — Prompt Caching Stack (STEP 56)
# Installs the P0 prompt-caching plugins that unlock multi-provider prompt
# caching (metadata.user_id injection), longer cache TTL, cache keepalive,
# and a live cache hit-rate sidebar. All under opencode_initializer's
# "one organism" policy: plugins complement, never replace, the core.
#
# Plugins added:
#   opencode-cache-injector          — prompt caching for many providers
#   opencode-cache-switch            — CLI (cache-switch) to pick injector provider
#   opencode-cache-ttl               — Anthropic cache 5-min TTL -> 1 hour
#   @vikrant82/opencode-cache-keepalive — keeps provider caches warm
#   opencode-cache-hit               — TUI sidebar: cache hit rate, tokens & cost
#
# Also validates the active provider against src/data/routing.json cost_table
# (metadata.user_id must map to a known provider before caching is meaningful).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

_step_skip step_caching && return 0

# Opt-out (matches SKIP_DOTFILES / SKIP_DEVBOX / SKIP_GUI convention)
[ "${SKIP_CACHING:-false}" = "true" ] && { info "Prompt caching skipped (SKIP_CACHING=true)"; return 0; }

section "Prompt Caching Stack — cache-injector + keepalive + TTL + hit tracking"

# ── opencode-cache-injector: multi-provider prompt caching ──────────────────
_install_cache_injector() {
  if npm list -g opencode-cache-injector >/dev/null 2>&1; then
    log "opencode-cache-injector already present"
    return 0
  fi
  _spin_start "Installing opencode-cache-injector (multi-provider prompt caching)"
  if npm install -g opencode-cache-injector@latest --prefer-offline >/dev/null 2>&1; then
    _spin_stop "✓"
    log "opencode-cache-injector installed"
    return 0
  fi
  _spin_stop "✗"
  warn "opencode-cache-injector install failed"
  return 1
}

# ── opencode-cache-ttl: Anthropic cache 5-min TTL -> 1 hour ─────────────────
_install_cache_ttl() {
  if npm list -g opencode-cache-ttl >/dev/null 2>&1; then
    log "opencode-cache-ttl already present"
    return 0
  fi
  _spin_start "Installing opencode-cache-ttl (5-min TTL -> 1 hour)"
  if npm install -g opencode-cache-ttl@latest --prefer-offline >/dev/null 2>&1; then
    _spin_stop "✓"
    log "opencode-cache-ttl installed"
    return 0
  fi
  _spin_stop "✗"
  warn "opencode-cache-ttl install failed"
  return 1
}

# ── opencode-cache-switch: CLI to switch cache-injector provider ────────────
_install_cache_switch() {
  if npm list -g opencode-cache-switch >/dev/null 2>&1; then
    log "opencode-cache-switch already present"
    return 0
  fi
  _spin_start "Installing opencode-cache-switch (cache-switch CLI)"
  if npm install -g opencode-cache-switch@latest --prefer-offline >/dev/null 2>&1; then
    _spin_stop "✓"
    log "opencode-cache-switch installed"
    return 0
  fi
  _spin_stop "✗"
  warn "opencode-cache-switch install failed"
  return 1
}

# ── @vikrant82/opencode-cache-keepalive: keep provider caches warm ──────────
_install_cache_keepalive() {
  if npm list -g @vikrant82/opencode-cache-keepalive >/dev/null 2>&1; then
    log "opencode-cache-keepalive already present"
    return 0
  fi
  _spin_start "Installing @vikrant82/opencode-cache-keepalive (cache keepalive)"
  if npm install -g @vikrant82/opencode-cache-keepalive@latest --prefer-offline >/dev/null 2>&1; then
    _spin_stop "✓"
    log "opencode-cache-keepalive installed"
    return 0
  fi
  _spin_stop "✗"
  warn "opencode-cache-keepalive install failed"
  return 1
}

# ── opencode-cache-hit: TUI sidebar for cache hit rate ──────────────────────
_install_cache_hit() {
  if npm list -g opencode-cache-hit >/dev/null 2>&1; then
    log "opencode-cache-hit already present"
    return 0
  fi
  _spin_start "Installing opencode-cache-hit (cache hit-rate sidebar)"
  if npm install -g opencode-cache-hit@latest --prefer-offline >/dev/null 2>&1; then
    _spin_stop "✓"
    log "opencode-cache-hit installed"
    return 0
  fi
  _spin_stop "✗"
  warn "opencode-cache-hit install failed"
  return 1
}

# ── Configure: validate active provider against cost_table ─────────────────
# S7.1.3 — reads the active model from opencode.json, extracts its provider,
# and confirms the provider has a cost_table entry in routing.json. Warns
# (never hardcodes prices) when no pricing/cache metadata is known.
_configure_cache() {
  local routing="$SCRIPT_DIR/../data/routing.json"
  local cfg="${XDG_CONFIG_HOME:-$HOME/.config}/opencode/opencode.json"
  local model provider

  [ -f "$cfg" ]     || { warn "opencode.json not found — cannot validate cache provider"; return 0; }
  [ -f "$routing" ] || { warn "routing.json not found — cannot validate cost_table"; return 0; }

  # Read active model (.model) — jq first, python3 fallback
  if command -v jq >/dev/null 2>&1; then
    model="$(jq -r '.model // empty' "$cfg" 2>/dev/null || true)"
  else
    model="$(python3 -c 'import json,sys;print(json.load(open(sys.argv[1])).get("model",""))' "$cfg" 2>/dev/null || true)"
  fi

  [ -n "$model" ] || { warn "No active model in opencode.json — skipping cache metadata validation"; return 0; }

  # Provider is the segment before the first '/'
  provider="${model%%/*}"

  if command -v jq >/dev/null 2>&1; then
    if jq -e --arg p "$provider/" '.cost_table | keys | map(startswith($p)) | any' "$routing" >/dev/null 2>&1; then
      log "Provider '$provider' has cost_table entry — cache metadata known"
    else
      warn "Provider '$provider' NOT in cost_table — no pricing/cache metadata known"
    fi
  else
    if python3 - "$routing" "$provider" >/dev/null 2>&1 <<'PYEOF'
import json, sys
routing = json.load(open(sys.argv[1]))
provider = sys.argv[2]
ct = routing.get("cost_table", {})
sys.exit(0 if any(k.startswith(provider + "/") for k in ct) else 1)
PYEOF
    then
      log "Provider '$provider' has cost_table entry — cache metadata known"
    else
      warn "Provider '$provider' NOT in cost_table — no pricing/cache metadata known"
    fi
  fi
  return 0
}

# ── Configure: register in opencode.json plugin array ───────────────────────
# Idempotent: appends each cache plugin only if absent from the plugin array.
_register_cache_plugins() {
  local cfg="${XDG_CONFIG_HOME:-$HOME/.config}/opencode/opencode.json"
  [ -f "$cfg" ] || { warn "opencode.json not found — cannot register cache plugins"; return 0; }

  python3 - <<PYEOF
import json, pathlib
p = pathlib.Path("$cfg")
data = json.loads(p.read_text())
plugins = data.get("plugin", [])
for name in ["opencode-cache-injector", "opencode-cache-switch", "opencode-cache-ttl", "@vikrant82/opencode-cache-keepalive", "opencode-cache-hit"]:
    if name not in plugins:
        plugins.append(name)
data["plugin"] = plugins
p.write_text(json.dumps(data, indent=2) + "\n")
print("ADDED: cache plugins to plugin array")
PYEOF

  log "Cache plugins registered in plugin array"
}

# ── Health check ─────────────────────────────────────────────────────────────
_check_caching() {
  local ok=true
  if ! npm list -g opencode-cache-injector >/dev/null 2>&1; then warn "opencode-cache-injector missing"; ok=false; fi
  if ! npm list -g opencode-cache-ttl       >/dev/null 2>&1; then warn "opencode-cache-ttl missing";       ok=false; fi
  if ! command -v cache-switch              >/dev/null 2>&1; then warn "cache-switch missing";              ok=false; fi
  if ! npm list -g @vikrant82/opencode-cache-keepalive >/dev/null 2>&1; then warn "opencode-cache-keepalive missing"; ok=false; fi
  if ! npm list -g opencode-cache-hit       >/dev/null 2>&1; then warn "opencode-cache-hit missing";       ok=false; fi
  $ok && log "Caching stack: OK" || return 1
}

# ── Main ─────────────────────────────────────────────────────────────────────
_install_cache_injector || true
_install_cache_ttl       || true
_install_cache_switch    || true
_install_cache_keepalive || true
_install_cache_hit       || true
_configure_cache
_register_cache_plugins
_check_caching || true
