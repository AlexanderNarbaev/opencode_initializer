#!/usr/bin/env bash
# src/lib/00j-auto-sync.sh — Auto-Sync & Self-Update Module (v4.1.0)
# Keeps all tools, plugins, and dependencies up to date automatically.
# Runs periodic checks and updates in background.
set -euo pipefail

# ── Auto-sync configuration ──────────────────────────────────────────────────
_AUTO_SYNC_INTERVAL="${AUTO_SYNC_INTERVAL:-86400}"  # 24 hours default
_AUTO_SYNC_STATE="${DL_CACHE}/auto-sync-state.json"
_AUTO_SYNC_LOG="${DL_CACHE}/auto-sync.log"

# ── Initialize auto-sync state ──────────────────────────────────────────────
_auto_sync_init() {
  mkdir -p "$(dirname "$_AUTO_SYNC_STATE")"

  if [ ! -f "$_AUTO_SYNC_STATE" ]; then
    cat > "$_AUTO_SYNC_STATE" <<EOF
{
  "version": "1.0.0",
  "last_check": 0,
  "last_update": 0,
  "updates_available": [],
  "updates_installed": []
}
EOF
  fi
}

# ── Check for updates ───────────────────────────────────────────────────────
# Usage: _auto_sync_check
# Returns list of available updates.
_auto_sync_check() {
  _auto_sync_init

  section "Checking for updates..."

  local updates=()
  local now
  now=$(date +%s)

  # Check opencode_initializer itself
  if [ -d "$SCRIPT_DIR/.git" ]; then
    local local_hash remote_hash
    local_hash=$(git -C "$SCRIPT_DIR" rev-parse HEAD 2>/dev/null || echo "")
    git -C "$SCRIPT_DIR" fetch origin main -q 2>/dev/null || true
    remote_hash=$(git -C "$SCRIPT_DIR" rev-parse origin/main 2>/dev/null || echo "")

    if [ -n "$local_hash" ] && [ -n "$remote_hash" ] && [ "$local_hash" != "$remote_hash" ]; then
      updates+=("opencode_initializer")
      info "  ↑ opencode_initializer: update available"
    else
      log "  ✓ opencode_initializer: up to date"
    fi
  fi

  # Check Node.js packages
  local npm_packages=(
    "opencode-cache-injector"
    "opencode-cache-ttl"
    "opencode-cache-switch"
    "@vikrant82/opencode-cache-keepalive"
    "opencode-cache-hit"
  )

  for pkg in "${npm_packages[@]}"; do
    if npm list -g "$pkg" >/dev/null 2>&1; then
      local current latest
      current=$(npm list -g "$pkg" --depth=0 2>/dev/null | grep "$pkg" | awk -F@ '{print $NF}' || echo "0")
      latest=$(npm view "$pkg" version 2>/dev/null || echo "0")

      if [ "$current" != "$latest" ]; then
        updates+=("npm:$pkg")
        info "  ↑ $pkg: $current → $latest"
      else
        log "  ✓ $pkg: $current"
      fi
    fi
  done

  # Check Python packages
  local pip_packages=(
    "testcontainers"
    "qdrant-client"
    "redis"
  )

  for pkg in "${pip_packages[@]}"; do
    if pip show "$pkg" >/dev/null 2>&1; then
      local current latest
      current=$(pip show "$pkg" 2>/dev/null | grep Version | awk '{print $2}' || echo "0")
      latest=$(pip index versions "$pkg" 2>/dev/null | head -1 | awk -F'[()]' '{print $2}' || echo "0")

      if [ "$current" != "$latest" ]; then
        updates+=("pip:$pkg")
        info "  ↑ $pkg: $current → $latest"
      else
        log "  ✓ $pkg: $current"
      fi
    fi
  done

  # Update state
  if command -v python3 &>/dev/null; then
    python3 -c "
import json, sys
try:
    with open('$_AUTO_SYNC_STATE', 'r') as f:
        state = json.load(f)
except:
    state = {'version': '1.0.0', 'last_check': 0, 'last_update': 0, 'updates_available': [], 'updates_installed': []}

state['last_check'] = $now
state['updates_available'] = [$(printf '"%s",' "${updates[@]}" | sed 's/,$//')]

with open('$_AUTO_SYNC_STATE', 'w') as f:
    json.dump(state, f, indent=2)
" 2>/dev/null || true
  fi

  if [ ${#updates[@]} -eq 0 ]; then
    log "All packages up to date"
  else
    info "${#updates[@]} updates available"
  fi

  echo "${updates[@]}"
}

# ── Apply updates ───────────────────────────────────────────────────────────
# Usage: _auto_sync_apply [--force]
_auto_sync_apply() {
  local force="${1:-false}"
  local updates
  updates=$(_auto_sync_check)

  if [ -z "$updates" ]; then
    log "No updates to apply"
    return 0
  fi

  section "Applying updates..."

  local applied=0
  local failed=0

  for update in $updates; do
    IFS=':' read -r type pkg <<< "$update"

    case "$type" in
      opencode_initializer)
        if [ "$force" = "true" ] || [ "${AUTO_UPDATE_OPENCODE:-false}" = "true" ]; then
          info "Updating opencode_initializer..."
          if git -C "$SCRIPT_DIR" pull --ff-only -q 2>/dev/null; then
            log "  ✓ opencode_initializer updated"
            applied=$((applied + 1))
          else
            warn "  ✗ opencode_initializer update failed"
            failed=$((failed + 1))
          fi
        else
          info "  ⏭ opencode_initializer: skipped (use --force)"
        fi
        ;;
      npm:*)
        local pkg_name="${pkg#npm:}"
        info "Updating $pkg_name..."
        if npm install -g "$pkg_name@latest" --prefer-offline >/dev/null 2>&1; then
          log "  ✓ $pkg_name updated"
          applied=$((applied + 1))
        else
          warn "  ✗ $pkg_name update failed"
          failed=$((failed + 1))
        fi
        ;;
      pip:*)
        local pkg_name="${pkg#pip:}"
        info "Updating $pkg_name..."
        if pip install --upgrade "$pkg_name" >/dev/null 2>&1; then
          log "  ✓ $pkg_name updated"
          applied=$((applied + 1))
        else
          warn "  ✗ $pkg_name update failed"
          failed=$((failed + 1))
        fi
        ;;
    esac
  done

  # Update state
  local now
  now=$(date +%s)
  if command -v python3 &>/dev/null; then
    python3 -c "
import json
try:
    with open('$_AUTO_SYNC_STATE', 'r') as f:
        state = json.load(f)
except:
    state = {}

state['last_update'] = $now
state['updates_installed'].extend([$(printf '"%s",' "${updates[@]}" | sed 's/,$//')])

with open('$_AUTO_SYNC_STATE', 'w') as f:
    json.dump(state, f, indent=2)
" 2>/dev/null || true
  fi

  log "Updates applied: $applied, failed: $failed"
}

# ── Background auto-sync daemon ─────────────────────────────────────────────
# Usage: _auto_sync_daemon &
# Runs in background, checks for updates periodically.
_auto_sync_daemon() {
  local interval="${1:-$_AUTO_SYNC_INTERVAL}"

  info "Auto-sync daemon started (interval: ${interval}s)"

  while true; do
    sleep "$interval"
    _auto_sync_apply 2>&1 | tee -a "$_AUTO_SYNC_LOG" || true
  done
}

# ── Plugin registry update ──────────────────────────────────────────────────
# Usage: _update_plugin_registry
# Fetches latest plugin versions from npm.
_update_plugin_registry() {
  section "Updating Plugin Registry"

  local plugins=(
    "opencode-cache-injector"
    "opencode-cache-ttl"
    "opencode-cache-switch"
    "@vikrant82/opencode-cache-keepalive"
    "opencode-cache-hit"
    "@colbymchenry/codegraph"
    "@playwright/mcp"
    "@modelcontextprotocol/server-filesystem"
    "@modelcontextprotocol/server-github"
    "@modelcontextprotocol/server-postgres"
    "@modelcontextprotocol/server-redis"
    "@modelcontextprotocol/server-memory"
    "@modelcontextprotocol/server-sequential-thinking"
    "@scitrera/memorylayer-mcp-server"
    "chrome-devtools-mcp"
    "mcp-searxng"
    "excalidraw-architect-mcp"
    "brave-search-mcp"
  )

  local updated=0

  for plugin in "${plugins[@]}"; do
    if npm list -g "$plugin" >/dev/null 2>&1; then
      local current latest
      current=$(npm list -g "$plugin" --depth=0 2>/dev/null | grep "$plugin" | awk -F@ '{print $NF}' || echo "0")
      latest=$(npm view "$plugin" version 2>/dev/null || echo "0")

      if [ "$current" != "$latest" ]; then
        info "  ↑ $plugin: $current → $latest"
        if npm install -g "$plugin@latest" --prefer-offline >/dev/null 2>&1; then
          log "  ✓ $plugin updated"
          updated=$((updated + 1))
        else
          warn "  ✗ $plugin update failed"
        fi
      else
        log "  ✓ $plugin: $current"
      fi
    fi
  done

  log "Plugins updated: $updated"
}

# ── MCP server update ───────────────────────────────────────────────────────
# Usage: _update_mcp_servers
# Updates all installed MCP servers.
_update_mcp_servers() {
  section "Updating MCP Servers"

  local mcp_servers=(
    "c7-mcp-server"
    "@upstash/context7-mcp"
    "@modelcontextprotocol/server-filesystem"
    "@pimzino/agentic-tools-mcp"
    "@colbymchenry/codegraph"
    "@playwright/mcp"
    "agent-browser-mcp-server"
    "@loopsense/mcp"
    "@modelcontextprotocol/server-github"
    "@modelcontextprotocol/server-postgres"
    "mcp-server-gitlab"
    "mcp-server-google-maps"
    "@modelcontextprotocol/server-sequential-thinking"
    "@scitrera/memorylayer-mcp-server"
    "chrome-devtools-mcp"
    "@modelcontextprotocol/server-memory"
    "@modelcontextprotocol/server-redis"
    "brave-search-mcp"
    "mcp-server-sqlite"
    "excalidraw-architect-mcp"
    "@notionhq/notion-mcp-server"
    "mcp-searxng"
    "open-orchestra"
  )

  local updated=0

  for server in "${mcp_servers[@]}"; do
    if npm list -g "$server" >/dev/null 2>&1; then
      local current latest
      current=$(npm list -g "$server" --depth=0 2>/dev/null | grep "$server" | awk -F@ '{print $NF}' || echo "0")
      latest=$(npm view "$server" version 2>/dev/null || echo "0")

      if [ "$current" != "$latest" ]; then
        info "  ↑ $server: $current → $latest"
        if npm install -g "$server@latest" --prefer-offline >/dev/null 2>&1; then
          log "  ✓ $server updated"
          updated=$((updated + 1))
        else
          warn "  ✗ $server update failed"
        fi
      else
        log "  ✓ $server: $current"
      fi
    fi
  done

  log "MCP servers updated: $updated"
}

# ── Full sync ───────────────────────────────────────────────────────────────
# Usage: _full_sync [--force]
# Runs all sync operations.
_full_sync() {
  local force="${1:-false}"

  section "Full Sync"

  _configure_all_mirrors
  _mirror_health_check
  _update_plugin_registry
  _update_mcp_servers
  _auto_sync_apply "$force"

  log "Full sync complete"
}

# ── Export functions ─────────────────────────────────────────────────────────
export -f _auto_sync_init _auto_sync_check _auto_sync_apply _auto_sync_daemon \
  _update_plugin_registry _update_mcp_servers _full_sync 2>/dev/null || true
