#!/usr/bin/env bash
# src/lib/62-skill-registry.sh — Skill discovery, install, publish
# Part of Phase 0: Skill Management System
# shellcheck disable=SC2034
set -euo pipefail

# ── Skill Registry Configuration ──────────────────────────────────────────────
SKILL_REGISTRY_URL="${SKILL_REGISTRY_URL:-https://registry.opencode.ai}"
SKILL_REGISTRY_CACHE="${SKILL_REGISTRY_CACHE:-$HOME/.cache/opencode/skills}"
SKILL_REGISTRY_INDEX="${SKILL_REGISTRY_CACHE}/index.json"
SKILL_INSTALL_DIR="${SKILL_INSTALL_DIR:-$HOME/.config/opencode/skills}"
SKILL_REGISTRY_TIMEOUT="${SKILL_REGISTRY_TIMEOUT:-30}"

# ── Skill Metadata ───────────────────────────────────────────────────────────
# Using regular arrays for bash 3.2 compatibility
SKILL_REGISTRY_KEYS=()
SKILL_REGISTRY_VALUES=()
SKILL_VERSIONS_KEYS=()
SKILL_VERSIONS_VALUES=()
SKILL_INSTALLED_KEYS=()
SKILL_INSTALLED_VALUES=()

# ── Registry Operations ──────────────────────────────────────────────────────

# Fetch skill index from registry
_skill_registry_fetch_index() {
  local force="${1:-false}"
  
  if [ "$force" = "false" ] && [ -f "$SKILL_REGISTRY_INDEX" ]; then
    local age=$(( $(date +%s) - $(stat -c %Y "$SKILL_REGISTRY_INDEX" 2>/dev/null || echo 0) ))
    if [ "$age" -lt 3600 ]; then
      log "Using cached skill index (${age}s old)"
      return 0
    fi
  fi
  
  info "Fetching skill index from $SKILL_REGISTRY_URL"
  mkdir -p "$SKILL_REGISTRY_CACHE"
  
  if command -v curl &>/dev/null; then
    curl -sS --max-time "$SKILL_REGISTRY_TIMEOUT" \
      "$SKILL_REGISTRY_URL/api/v1/skills" \
      -o "$SKILL_REGISTRY_INDEX" 2>/dev/null || {
      warn "Failed to fetch skill index, using cache"
      return 1
    }
  elif command -v wget &>/dev/null; then
    wget -q --timeout="$SKILL_REGISTRY_TIMEOUT" \
      "$SKILL_REGISTRY_URL/api/v1/skills" \
      -O "$SKILL_REGISTRY_INDEX" 2>/dev/null || {
      warn "Failed to fetch skill index, using cache"
      return 1
    }
  else
    warn "Neither curl nor wget available, cannot fetch index"
    return 1
  fi
  
  log "Skill index updated"
}

# Search skills by query
_skill_registry_search() {
  local query="${1:-}"
  local limit="${2:-20}"
  
  if [ -z "$query" ]; then
    err "Search query required"
  fi
  
  _skill_registry_fetch_index || true
  
  if [ ! -f "$SKILL_REGISTRY_INDEX" ]; then
    warn "No skill index available"
    return 1
  fi
  
  # Search in index (name, description, tags)
  if command -v jq &>/dev/null; then
    jq -r --arg q "$query" --argjson limit "$limit" '
      .skills[] |
      select(
        (.name // "" | ascii_downcase | contains($q | ascii_downcase)) or
        (.description // "" | ascii_downcase | contains($q | ascii_downcase)) or
        (.tags // [] | map(ascii_downcase) | any(contains($q | ascii_downcase)))
      ) |
      "\(.name)@\(.version) — \(.description // "no description")"
    ' "$SKILL_REGISTRY_INDEX" 2>/dev/null | head -n "$limit"
  else
    grep -i "$query" "$SKILL_REGISTRY_INDEX" 2>/dev/null | head -n "$limit"
  fi
}

# List all available skills
_skill_registry_list() {
  local limit="${1:-50}"
  
  _skill_registry_fetch_index || true
  
  if [ ! -f "$SKILL_REGISTRY_INDEX" ]; then
    warn "No skill index available"
    return 1
  fi
  
  if command -v jq &>/dev/null; then
    jq -r --argjson limit "$limit" '
      .skills[:$limit][] |
      "\(.name)@\(.version) — \(.description // "no description")"
    ' "$SKILL_REGISTRY_INDEX" 2>/dev/null
  else
    cat "$SKILL_REGISTRY_INDEX" 2>/dev/null | head -n "$limit"
  fi
}

# Get skill info
_skill_registry_info() {
  local skill_name="${1:-}"
  
  if [ -z "$skill_name" ]; then
    err "Skill name required"
  fi
  
  _skill_registry_fetch_index || true
  
  if [ ! -f "$SKILL_REGISTRY_INDEX" ]; then
    warn "No skill index available"
    return 1
  fi
  
  if command -v jq &>/dev/null; then
    jq --arg name "$skill_name" '
      .skills[] | select(.name == $name)
    ' "$SKILL_REGISTRY_INDEX" 2>/dev/null
  else
    grep "\"$skill_name\"" "$SKILL_REGISTRY_INDEX" 2>/dev/null
  fi
}

# ── Skill Install ────────────────────────────────────────────────────────────

# Install a skill from registry
_skill_install() {
  local skill_spec="${1:-}"
  local force="${2:-false}"
  
  if [ -z "$skill_spec" ]; then
    err "Skill specification required. Usage: opencode skill install <spec> (e.g., code-review@1.2.0)"
  fi
  
  # Parse skill spec: name@version or @scope/name@version
  local skill_name skill_version
  if [[ "$skill_spec" =~ ^@([^/]+)/([^@]+)@(.+)$ ]]; then
    skill_name="${BASH_REMATCH[1]}/${BASH_REMATCH[2]}"
    skill_version="${BASH_REMATCH[3]}"
  elif [[ "$skill_spec" =~ ^@([^/]+)/([^@]+)$ ]]; then
    skill_name="${BASH_REMATCH[1]}/${BASH_REMATCH[2]}"
    skill_version="latest"
  elif [[ "$skill_spec" =~ ^([^@]+)@(.+)$ ]]; then
    skill_name="${BASH_REMATCH[1]}"
    skill_version="${BASH_REMATCH[2]}"
  else
    skill_name="$skill_spec"
    skill_version="latest"
  fi
  
  info "Installing skill: $skill_name@$skill_version"
  
  # Check if already installed
  local install_path="$SKILL_INSTALL_DIR/$skill_name"
  if [ -d "$install_path" ] && [ "$force" = "false" ]; then
    local installed_version
    installed_version=$(cat "$install_path/VERSION" 2>/dev/null || echo "unknown")
    warn "Skill $skill_name@$installed_version already installed"
    info "Use 'opencode skill install $skill_spec --force' to reinstall"
    return 0
  fi
  
  # Download skill
  mkdir -p "$install_path"
  
  local download_url="$SKILL_REGISTRY_URL/api/v1/skills/$skill_name/download"
  if [ "$skill_version" != "latest" ]; then
    download_url="$download_url?version=$skill_version"
  fi
  
  if command -v curl &>/dev/null; then
    curl -sS --max-time "$SKILL_REGISTRY_TIMEOUT" \
      "$download_url" | tar xz -C "$install_path" 2>/dev/null || {
      rm -rf "$install_path"
      err "Failed to download skill $skill_name"
    }
  elif command -v wget &>/dev/null; then
    wget -q --timeout="$SKILL_REGISTRY_TIMEOUT" \
      -O - "$download_url" | tar xz -C "$install_path" 2>/dev/null || {
      rm -rf "$install_path"
      err "Failed to download skill $skill_name"
    }
  fi
  
  # Record installation
  echo "$skill_version" > "$install_path/VERSION"
  date -u +%Y-%m-%dT%H:%M:%SZ > "$install_path/INSTALLED_AT"
  
  log "Skill $skill_name@$skill_version installed to $install_path"
}

# Uninstall a skill
_skill_uninstall() {
  local skill_name="${1:-}"
  
  if [ -z "$skill_name" ]; then
    err "Skill name required"
  fi
  
  local install_path="$SKILL_INSTALL_DIR/$skill_name"
  
  if [ ! -d "$install_path" ]; then
    warn "Skill $skill_name not found"
    return 1
  fi
  
  rm -rf "$install_path"
  log "Skill $skill_name uninstalled"
}

# List installed skills
_skill_list_installed() {
  if [ ! -d "$SKILL_INSTALL_DIR" ]; then
    info "No skills installed"
    return 0
  fi
  
  find "$SKILL_INSTALL_DIR" -maxdepth 2 -name "VERSION" -print0 2>/dev/null | while IFS= read -r -d '' version_file; do
    dir=$(dirname "$version_file")
    name=$(basename "$dir")
    version=$(cat "$version_file")
    echo "$name@$version"
  done | sort
}

# ── Skill Publish ────────────────────────────────────────────────────────────

# Publish a skill to registry
_skill_publish() {
  local skill_dir="${1:-.}"
  local workspace="${2:-}"
  
  if [ ! -f "$skill_dir/SKILL.md" ]; then
    err "No SKILL.md found in $skill_dir"
  fi
  
  # Validate skill structure
  _skill_validate "$skill_dir" || err "Skill validation failed"
  
  # Read skill metadata
  local skill_name skill_version
  skill_name=$(grep -m1 "^name:" "$skill_dir/SKILL.md" 2>/dev/null | sed 's/name: *//' || echo "")
  skill_version=$(grep -m1 "^version:" "$skill_dir/SKILL.md" 2>/dev/null | sed 's/version: *//' || echo "0.1.0")
  
  if [ -z "$skill_name" ]; then
    err "Skill name not found in SKILL.md"
  fi
  
  info "Publishing skill: $skill_name@$skill_version"
  
  # Create archive
  local archive="/tmp/opencode-skill-$skill_name-$skill_version.tar.gz"
  tar czf "$archive" -C "$skill_dir" . 2>/dev/null || err "Failed to create archive"
  
  # Upload to registry
  local publish_url="$SKILL_REGISTRY_URL/api/v1/skills/publish"
  if [ -n "$workspace" ]; then
    publish_url="$publish_url?workspace=$workspace"
  fi
  
  if command -v curl &>/dev/null; then
    curl -sS --max-time "$SKILL_REGISTRY_TIMEOUT" \
      -X POST \
      -F "skill=@$archive" \
      "$publish_url" 2>/dev/null || {
      rm -f "$archive"
      err "Failed to publish skill"
    }
  else
    rm -f "$archive"
    err "curl required for publishing"
  fi
  
  rm -f "$archive"
  log "Skill $skill_name@$skill_version published"
}

# Validate skill structure
_skill_validate() {
  local skill_dir="${1:-.}"
  local errors=0
  
  # Check required files
  if [ ! -f "$skill_dir/SKILL.md" ]; then
    warn "Missing SKILL.md"
    ((errors++))
  fi
  
  # Check SKILL.md structure
  if [ -f "$skill_dir/SKILL.md" ]; then
    if ! grep -q "^# " "$skill_dir/SKILL.md"; then
      warn "SKILL.md missing title (H1)"
      ((errors++))
    fi
    
    if ! grep -qi "description" "$skill_dir/SKILL.md"; then
      warn "SKILL.md missing description"
      ((errors++))
    fi
  fi
  
  # Check for dangerous patterns
  if grep -rq "rm -rf /" "$skill_dir/" 2>/dev/null; then
    warn "Dangerous pattern found: rm -rf /"
    ((errors++))
  fi
  
  if grep -rq "curl.*|.*bash" "$skill_dir/" 2>/dev/null; then
    warn "Unsafe pattern found: curl | bash"
    ((errors++))
  fi
  
  return $errors
}

# ── CLI Interface ────────────────────────────────────────────────────────────

cmd_skill() {
  local subcmd="${1:-help}"
  shift || true
  
  case "$subcmd" in
    search)   _skill_registry_search "$@" ;;
    list)     _skill_list_installed "$@" ;;
    available) _skill_registry_list "$@" ;;
    info)     _skill_registry_info "$@" ;;
    install)  _skill_install "$@" ;;
    uninstall) _skill_uninstall "$@" ;;
    publish)  _skill_publish "$@" ;;
    validate) _skill_validate "$@" ;;
    help|*)
      cat <<'EOF'
Usage: opencode skill <command> [args]

Commands:
  search <query>           Search skills in registry
  list                     List installed skills
  available [limit]        List available skills
  info <name>              Get skill info
  install <spec>           Install skill (e.g., code-review@1.2.0)
  uninstall <name>         Uninstall skill
  publish [dir] [workspace] Publish skill to registry
  validate [dir]           Validate skill structure
EOF
      ;;
  esac
}
