#!/usr/bin/env bash
# dev — post-install CLI for managing the dev environment
#   dev install <component>  — install a new component
#   dev remove <component>   — remove a component
#   dev update               — update all tools + run migrations
#   dev health               — full diagnostic
#   dev list                 — list installed components

set -euo pipefail
SCRIPTS_DIR="$(cd "$(dirname "$0")" && pwd)"

source "$SCRIPTS_DIR/lib/helpers.sh"
CONFIG_FILE="${HOME}/.config/opencode-setup/setup.conf"
[ -f "$CONFIG_FILE" ] && source "$CONFIG_FILE"

usage() {
  echo "dev — Dev Machine Manager"
  echo "  dev install <pkg>     Install component"
  echo "  dev remove  <pkg>     Remove component"
  echo "  dev update            Update all + run migrations"
  echo "  dev health            Full diagnostic"
  echo "  dev list              List installed components"
  echo "  dev config            Edit setup config"
  exit 0
}

cmd_list() {
  echo "Installed components:"
  for lib in "$SCRIPTS_DIR/lib/install-"*.sh; do
    name=$(basename "$lib" .sh | sed 's/install-//')
    printf "  %-20s %s\n" "$name" "$lib"
  done
  echo
  echo "Config file: ${CONFIG_FILE:-not found}"
  echo "Cache dir:   $DL_CACHE"
  echo "Secrets:     $SECRETS_FILE"
}

cmd_config() {
  mkdir -p "$(dirname "$CONFIG_FILE")"
  ${EDITOR:-nano} "$CONFIG_FILE"
}

cmd_health() {
  bash "$SCRIPTS_DIR/setup.sh" --health
}

cmd_update() {
  section "System update"
  _sudo apt-get update -qq && _sudo apt-get upgrade -y -qq && log "apt updated"

  section "npm global packages"
  npm update -g 2>/dev/null || true
  for pkg in opencode-ai c7-mcp-server agent-browser opencode-codegraph; do
    npm install -g "$pkg@latest" --prefer-offline 2>/dev/null && log "npm: $pkg" || warn "npm: $pkg failed"
  done

  section "uv + pip"
  command -v uv &>/dev/null && uv self update 2>/dev/null && log "uv updated"

  section "Run migrations"
  for mig in "$SCRIPTS_DIR/migrations/"*.sh; do
    [ -f "$mig" ] || continue
    local ts=$(basename "$mig" .sh)
    if [ ! -f "$DL_CACHE/.mig-$ts" ]; then
      info "Running migration: $(basename "$mig")"
      bash "$mig" && echo "$ts" > "$DL_CACHE/.mig-$ts" && log "Migration: $ts OK" || warn "Migration: $ts FAILED"
    fi
  done

  bash "$SCRIPTS_DIR/setup.sh" --fix-config
  log "Update complete"
}

cmd_install() {
  local pkg="$1"
  local script="$SCRIPTS_DIR/lib/install-${pkg}.sh"
  if [ -f "$script" ]; then
    section "Installing $pkg"
    source "$script"
    log "$pkg installed"
  else
    err "Unknown component: $pkg. Try one of: $(ls "$SCRIPTS_DIR/lib/install-"*.sh 2>/dev/null | xargs -n1 basename | sed 's/install-//;s/\.sh//' | tr '\n' ' ')"
  fi
}

cmd_remove() {
  local pkg="$1"
  section "Removing $pkg"
  case "$pkg" in
    docker) _sudo apt-get remove -y docker.io docker-compose-v2 2>/dev/null && log "docker removed" || warn "not found";;
    java)   _sudo apt-get remove -y openjdk-25-jdk 2>/dev/null; _sudo rm -rf /usr/lib/jvm/jdk-25* 2>/dev/null; log "Java removed";;
    node)   _sudo apt-get remove -y nodejs 2>/dev/null; rm -rf ~/.n ~/.npm-global 2>/dev/null; log "Node.js removed";;
    python) _sudo apt-get remove -y python3 2>/dev/null; log "Python removed";;
    go)     _sudo apt-get remove -y golang-go 2>/dev/null; _sudo rm -rf /usr/local/go 2>/dev/null; log "Go removed";;
    rust)   _sudo apt-get remove -y cargo rustc 2>/dev/null; rm -rf ~/.cargo 2>/dev/null; log "Rust removed";;
    dotnet) rm -rf ~/.dotnet 2>/dev/null; log ".NET removed";;
    *)      warn "Unknown: $pkg (remove manually)";;
  esac
}

case "${1:-}" in
  install)  cmd_install "${2:-}" ;;
  remove)   cmd_remove "${2:-}" ;;
  update)   cmd_update ;;
  health)   cmd_health ;;
  list|ls)  cmd_list ;;
  config)   cmd_config ;;
  -h|--help|help|"") usage ;;
  *)        err "Unknown command: $1. Use: dev install|remove|update|health|list|config" ;;
esac
