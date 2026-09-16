#!/usr/bin/env bash
# src/lib/00m-plugin-discovery.sh — Plugin Discovery & Registry (v4.4.0)
# Automatically discovers and registers new plugins from npm, GitHub, and community sources.
set -euo pipefail

# ── Plugin registry configuration ────────────────────────────────────────────
_PLUGIN_REGISTRY="${DL_CACHE}/plugin-registry.json"
_PLUGIN_DISCOVERY_LOG="${DL_CACHE}/plugin-discovery.log"

# ── Known plugin sources ────────────────────────────────────────────────────
# Format: "source:category:priority"
# Using function-based lookup for bash 3.2 compatibility
_PLUGIN_PACKAGES=(
  "opencode" "@opencode-ai"
  "@modelcontextprotocol" "@upstash" "@colbymchenry" "@playwright" "@pimzino" "@scitrera" "@notionhq"
  "@anthropic-ai" "@openai" "@google-ai"
  "@vikrant82" "agent-browser" "chrome-devtools" "brave-search" "mcp-searxng" "excalidraw" "open-orchestra"
)

_plugin_source_get() {
  case "$1" in
    # OpenCode ecosystem
    opencode) echo "official:core:1" ;;
    @opencode-ai) echo "official:core:1" ;;
    # MCP servers
    @modelcontextprotocol) echo "official:mcp:1" ;;
    @upstash) echo "community:mcp:2" ;;
    @colbymchenry) echo "community:mcp:2" ;;
    @playwright) echo "official:mcp:1" ;;
    @pimzino) echo "community:mcp:2" ;;
    @scitrera) echo "community:mcp:2" ;;
    @notionhq) echo "official:mcp:1" ;;
    # AI providers
    @anthropic-ai) echo "official:provider:1" ;;
    @openai) echo "official:provider:1" ;;
    @google-ai) echo "official:provider:1" ;;
    # Tools
    @vikrant82) echo "community:cache:2" ;;
    agent-browser) echo "community:browser:3" ;;
    chrome-devtools) echo "official:browser:1" ;;
    brave-search) echo "official:search:1" ;;
    mcp-searxng) echo "community:search:2" ;;
    excalidraw) echo "community:diagram:2" ;;
    open-orchestra) echo "community:orchestration:3" ;;
    *) echo "" ;;
  esac
}

# ── Discover plugins from npm ───────────────────────────────────────────────
# Usage: _discover_npm_plugins [query] [limit]
# Searches npm for OpenCode-compatible plugins.
_discover_npm_plugins() {
  local query="${1:-opencode}"
  local limit="${2:-50}"

  section "Discovering npm plugins: $query"

  if ! command -v npm &>/dev/null; then
    warn "npm not found"
    return 1
  fi

  local results
  results=$(npm search "$query" --json 2>/dev/null | head -n "$limit" || true)

  if [ -z "$results" ]; then
    warn "No results found"
    return 1
  fi

  # Parse and categorize
  echo "$results" | python3 -c "
import json, sys

try:
    packages = json.load(sys.stdin)
except:
    packages = []

for pkg in packages[:50]:
    name = pkg.get('name', '')
    version = pkg.get('version', '0.0.0')
    description = pkg.get('description', '')
    
    # Categorize
    category = 'other'
    if 'mcp' in name.lower() or 'modelcontextprotocol' in name.lower():
        category = 'mcp'
    elif 'opencode' in name.lower():
        category = 'opencode'
    elif 'ai' in name.lower() or 'llm' in name.lower():
        category = 'ai'
    elif 'cache' in name.lower():
        category = 'cache'
    elif 'browser' in name.lower() or 'playwright' in name.lower():
        category = 'browser'
    
    print(f'{name}|{version}|{category}|{description[:80]}')
" 2>/dev/null || true
}

# ── Discover plugins from GitHub ────────────────────────────────────────────
# Usage: _discover_github_plugins [query] [limit]
# Searches GitHub for OpenCode-compatible plugins.
_discover_github_plugins() {
  local query="${1:-opencode-plugin}"
  local limit="${2:-30}"

  section "Discovering GitHub plugins: $query"

  if ! command -v gh &>/dev/null; then
    warn "gh (GitHub CLI) not found"
    return 1
  fi

  local results
  results=$(gh search repos "$query" --limit "$limit" --json name,owner,description,stargazersCount 2>/dev/null || true)

  if [ -z "$results" ]; then
    warn "No results found"
    return 1
  fi

  echo "$results" | python3 -c "
import json, sys

try:
    repos = json.load(sys.stdin)
except:
    repos = []

for repo in repos[:30]:
    name = repo.get('name', '')
    owner = repo.get('owner', {}).get('login', '')
    desc = repo.get('description', '')[:80]
    stars = repo.get('stargazersCount', 0)
    
    print(f'{owner}/{name}|{stars}|{desc}')
" 2>/dev/null || true
}

# ── Update plugin registry ──────────────────────────────────────────────────
# Usage: _update_plugin_registry
# Fetches latest versions of all known plugins.
_update_plugin_registry() {
  section "Updating Plugin Registry"

  local now
  now=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

  # Initialize registry
  cat > "$_PLUGIN_REGISTRY" <<EOF
{
  "version": "1.0.0",
  "updated": "$now",
  "plugins": {
EOF

  local first=true
  local total=0
  local updated=0

  for pkg in "${_PLUGIN_PACKAGES[@]}"; do
    local source_info
    source_info=$(_plugin_source_get "$pkg")
    [ -z "$source_info" ] && continue
    IFS=':' read -r source category priority <<< "$source_info"

    # Get current version from npm
    local current_version
    current_version=$(npm view "$pkg" version 2>/dev/null || echo "unknown")

    if [ "$current_version" != "unknown" ]; then
      if [ "$first" = "true" ]; then
        first=false
      else
        echo "," >> "$_PLUGIN_REGISTRY"
      fi

      cat >> "$_PLUGIN_REGISTRY" <<EOF
    "$pkg": {
      "version": "$current_version",
      "source": "$source",
      "category": "$category",
      "priority": $priority
    }
EOF
      updated=$((updated + 1))
    fi

    total=$((total + 1))
  done

  cat >> "$_PLUGIN_REGISTRY" <<EOF
  },
  "stats": {
    "total": $total,
    "updated": $updated
  }
}
EOF

  log "Plugin registry updated: $updated/$total plugins"
}

# ── Install recommended plugins ─────────────────────────────────────────────
# Usage: _install_recommended_plugins [--category mcp|cache|browser|all]
# Installs plugins based on category and priority.
_install_recommended_plugins() {
  local category="${1:-all}"

  section "Installing Recommended Plugins (category: $category)"

  local installed=0
  local failed=0

  for pkg in "${_PLUGIN_PACKAGES[@]}"; do
    local source_info
    source_info=$(_plugin_source_get "$pkg")
    [ -z "$source_info" ] && continue
    IFS=':' read -r source cat priority <<< "$source_info"

    # Filter by category
    if [ "$category" != "all" ] && [ "$cat" != "$category" ]; then
      continue
    fi

    # Check if already installed
    if npm list -g "$pkg" >/dev/null 2>&1; then
      log "  ✓ $pkg (already installed)"
      continue
    fi

    # Install
    info "  Installing $pkg..."
    if npm install -g "$pkg@latest" --prefer-offline >/dev/null 2>&1; then
      log "  ✓ $pkg installed"
      installed=$((installed + 1))
    else
      warn "  ✗ $pkg failed"
      failed=$((failed + 1))
    fi
  done

  log "Plugins installed: $installed, failed: $failed"
}

# ── Plugin health check ─────────────────────────────────────────────────────
# Usage: _plugin_health_check
# Checks status of all registered plugins.
_plugin_health_check() {
  section "Plugin Health Check"

  local total=0
  local installed=0
  local missing=0

  for pkg in "${_PLUGIN_PACKAGES[@]}"; do
    total=$((total + 1))

    if npm list -g "$pkg" >/dev/null 2>&1; then
      local version
      version=$(npm list -g "$pkg" --depth=0 2>/dev/null | grep "$pkg" | awk -F@ '{print $NF}' || echo "?")
      log "  ✓ $pkg@$version"
      installed=$((installed + 1))
    else
      warn "  ✗ $pkg (missing)"
      missing=$((missing + 1))
    fi
  done

  log "Plugin health: $installed/$total installed, $missing missing"
}

# ── Export functions ─────────────────────────────────────────────────────────
export -f _discover_npm_plugins _discover_github_plugins _update_plugin_registry \
  _install_recommended_plugins _plugin_health_check 2>/dev/null || true
