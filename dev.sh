#!/usr/bin/env bash
# dev — post-install CLI for managing the dev environment
#   dev install <component>  — install a new component
#   dev remove <component>   — remove a component
#   dev update               — update all tools + run migrations
#   dev health               — full diagnostic
#   dev list                 — list installed components

set -euo pipefail
SCRIPTS_DIR="$(cd "$(dirname "$0")" && pwd)"

source "$SCRIPTS_DIR/src/lib/helpers.sh"
CONFIG_FILE="${HOME}/.config/opencode-setup/setup.conf"
[ -f "$CONFIG_FILE" ] && source "$CONFIG_FILE"

usage() {
  echo "dev — Dev Machine Manager"
  echo "  dev install <pkg>     Install component"
  echo "  dev remove  <pkg>     Remove component"
  echo "  dev update            Update all + run migrations + self-update"
  echo "  dev health            Full diagnostic"
  echo "  dev list              List installed components"
  echo "  dev config            Edit setup config"
  echo "  dev self-update       Update dev CLI from git (pull + install)"
  echo "  dev infra up [svc]    Start infra services (postgres, qdrant, redis, kafka, neo4j, minio)"
  echo "  dev infra down [svc]  Stop infra services"
  echo "  dev infra status      Show infra service status"
  echo "  dev observability up|down|status  Manage Prometheus + Grafana"
  echo "  dev gui start|stop|status  Manage GUI web interface"
  echo "  dev plugins list      List plugins by tier and status"
  echo "  dev isolated on|off|status  Toggle isolated circuit mode (local-only LLM)"
}

cmd_list() {
  echo "Installed components:"
  for lib in "$SCRIPTS_DIR/src/lib"/0[0-9]-*.sh; do
    [ -f "$lib" ] || continue
    local name=$(basename "$lib" .sh | sed 's/^[0-9][0-9]-//')
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
  _pkg_update && log "packages updated" || warn "update failed"

  section "npm global packages"
  npm update -g 2>/dev/null || true
  for pkg in opencode-ai c7-mcp-server agent-browser-mcp-server opencode-codegraph open-orchestra; do
    npm install -g "$pkg@latest" --prefer-offline 2>/dev/null && log "npm: $pkg" || warn "npm: $pkg failed"
  done

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
  section "Installing $pkg"
  case "$pkg" in
    docker)    bash "$SCRIPTS_DIR/setup.sh" --reinit -s "${SUDO_PASS:-}" 2>/dev/null ;;
    java)      bash "$SCRIPTS_DIR/setup.sh" --reinit -s "${SUDO_PASS:-}" 2>/dev/null ;;
    node)      bash "$SCRIPTS_DIR/setup.sh" --reinit -s "${SUDO_PASS:-}" 2>/dev/null ;;
    python)    bash "$SCRIPTS_DIR/setup.sh" --reinit -s "${SUDO_PASS:-}" 2>/dev/null ;;
    go)        bash "$SCRIPTS_DIR/setup.sh" --reinit -s "${SUDO_PASS:-}" 2>/dev/null ;;
    rust)      bash "$SCRIPTS_DIR/setup.sh" --reinit -s "${SUDO_PASS:-}" 2>/dev/null ;;
    dotnet)    bash "$SCRIPTS_DIR/setup.sh" --reinit -s "${SUDO_PASS:-}" 2>/dev/null ;;
    opencode)  bash "$SCRIPTS_DIR/setup.sh" --reinit -s "${SUDO_PASS:-}" 2>/dev/null ;;
    mcp)       bash "$SCRIPTS_DIR/setup.sh" --reinit -s "${SUDO_PASS:-}" 2>/dev/null ;;
    llm)       bash "$SCRIPTS_DIR/setup.sh" --reinit -s "${SUDO_PASS:-}" 2>/dev/null ;;
    autoupdate) bash "$SCRIPTS_DIR/setup.sh" --reinit -s "${SUDO_PASS:-}" 2>/dev/null ;;
    *)         warn "Unknown: $pkg. Available: docker java node python go rust dotnet opencode mcp llm autoupdate" ;;
  esac
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

cmd_self_update() {
  section "Self-update dev CLI + setup.sh"
  if [ -d "$SCRIPTS_DIR/.git" ]; then
    git -C "$SCRIPTS_DIR" pull --rebase 2>/dev/null && log "git pull OK" || warn "git pull failed (check network)"
    cp "$SCRIPTS_DIR/dev.sh" "$HOME/.local/bin/dev" 2>/dev/null && chmod +x "$HOME/.local/bin/dev" && log "dev CLI updated"
    cp "$SCRIPTS_DIR/setup.sh" "$HOME/setup.sh" 2>/dev/null && chmod +x "$HOME/setup.sh" && log "setup.sh updated"
    bash "$SCRIPTS_DIR/setup.sh" --fix-config 2>/dev/null && log "opencode.json regenerated"
    # Run pending migrations
    for mig in "$SCRIPTS_DIR/migrations/"*.sh; do
      [ -f "$mig" ] || continue
      local ts=$(basename "$mig" .sh)
      if [ ! -f "$DL_CACHE/.mig-$ts" ]; then
        info "Migration: $(basename "$mig")"
        bash "$mig" && echo "$ts" > "$DL_CACHE/.mig-$ts" && log "Migration: $ts OK" || warn "Migration: $ts FAILED"
      fi
    done
  else
    warn "Not a git repo — manual update: cd $SCRIPTS_DIR && git pull"
  fi
}

cmd_version_check() {
  source "$SCRIPTS_DIR/src/lib/version-check.sh"
  _check_versions
}

cmd_autoupdate() {
  section "Full system update (topgrade)"
  if command -v topgrade &>/dev/null; then
    topgrade --yes --no-retry --skip-notify
    log "autoupdate complete"
    echo "$(date -Iseconds) manual topgrade" >> "$DL_CACHE/update.log"
  else
    warn "topgrade not installed. Install: cargo install topgrade"
    cmd_update
  fi
}

cmd_infra() {
  INFRA_CONFIG="$HOME/.config/opencode/infra.yml"
  action="${2:-status}"
  target="${3:-}"

  case "$action" in
    up)
      if [ ! -f "$INFRA_CONFIG" ]; then
        err "No infra config found. Run: setup.sh --with-all-infra  to create it"
      fi
      section "Starting infra services..."
      if [ -n "$target" ]; then
        docker compose -f "$INFRA_CONFIG" up -d --wait "$target" 2>/dev/null && \
          log "Started: $target" || warn "Failed to start $target"
      else
        docker compose -f "$INFRA_CONFIG" up -d --wait 2>/dev/null && \
          log "All infra services started" || warn "Some services failed"
      fi
      ;;
    down)
      if [ ! -f "$INFRA_CONFIG" ]; then
        err "No infra config found"
      fi
      section "Stopping infra services..."
      if [ -n "$target" ]; then
        docker compose -f "$INFRA_CONFIG" stop "$target" 2>/dev/null && \
          log "Stopped: $target" || warn "Failed to stop $target"
      else
        docker compose -f "$INFRA_CONFIG" down 2>/dev/null && \
          log "All infra services stopped" || warn "Failed to stop"
      fi
      ;;
    status|"")
      section "Infra Services Status"
      if [ -f "$INFRA_CONFIG" ]; then
        docker compose -f "$INFRA_CONFIG" ps 2>/dev/null || echo "  No services running"
      else
        echo "  No infra config. Run: setup.sh --with-all-infra"
      fi
      ;;
    *) err "Unknown: dev infra $action. Use: up|down|status" ;;
  esac
}

cmd_plugins() {
  PLUGINS_JSON="$HOME/.config/opencode/plugins.json"
  action="${2:-list}"
  target="${3:-}"

  case "$action" in
    list|ls)
      section "Plugin Registry ($PLUGINS_JSON)"
      if [ -f "$PLUGINS_JSON" ]; then
        python3 -c "
import json, os
with open('$PLUGINS_JSON') as f:
    data = json.load(f)
print('ALWAYS (enabled unconditionally):')
for p in data['tiers']['always']:
    print(f'  \033[32m●\033[0m {p}')
print()
print('CONDITIONAL (enabled when deps met):')
for p, cfg in sorted(data['tiers']['conditional'].items()):
    deps = ', '.join(cfg.get('depends', []))
    auto = 'auto' if cfg.get('auto_enable') else 'manual'
    status = '\033[32menabled\033[0m' if cfg.get('enabled') else '\033[90mdisabled\033[0m'
    print(f'  {status} {p} (deps: [{deps}], {auto})')
print()
print('ON-DEMAND (manual enable only):')
for p in data['tiers']['on_demand']:
    print(f'  \033[90m○\033[0m {p}')
" 2>&1
      else
        warn "No plugins.json found at $PLUGINS_JSON"
        echo "  Run: setup.sh --reinit  to regenerate"
      fi
      ;;
    *) err "Unknown: dev plugins $action. Use: list" ;;
  esac
}

cmd_observability() {
  INFRA_CONFIG="$HOME/.config/opencode/infra.yml"
  action="${2:-status}"

  case "$action" in
    up)
      if [ ! -f "$INFRA_CONFIG" ]; then
        err "No infra config found. Run: setup.sh --with-observability  to create it"
      fi
      section "Starting observability services (Prometheus + Grafana)..."
      if ! grep -q "prom/prometheus" "$INFRA_CONFIG" 2>/dev/null; then
        err "Prometheus not in infra.yml. Run: setup.sh --with-observability"
      fi
      docker compose -f "$INFRA_CONFIG" up -d --wait prometheus grafana 2>/dev/null && \
        log "Observability services started (Prometheus :9090, Grafana :3001)" || \
        warn "Some observability services failed to start"
      ;;
    down)
      if [ ! -f "$INFRA_CONFIG" ]; then
        err "No infra config found"
      fi
      section "Stopping observability services..."
      docker compose -f "$INFRA_CONFIG" stop prometheus grafana 2>/dev/null && \
        log "Observability services stopped" || \
        warn "Failed to stop observability services"
      ;;
    status|"")
      section "Observability Services Status"
      if [ -f "$INFRA_CONFIG" ]; then
        if grep -q "prom/prometheus" "$INFRA_CONFIG" 2>/dev/null; then
          docker compose -f "$INFRA_CONFIG" ps prometheus grafana 2>/dev/null || echo "  No observability services running"
        else
          echo "  Observability services not configured. Run: setup.sh --with-observability"
        fi
      else
        echo "  No infra config. Run: setup.sh --with-all-infra"
      fi
      ;;
    *) err "Unknown: dev observability $action. Use: up|down|status" ;;
  esac
}

cmd_gui() {
  local action="${2:-status}"
  case "$action" in
    start)
      section "Starting OpenCode GUI"
      systemctl --user start opencode-gui.service 2>/dev/null && log "GUI started on port 4200" || err "Failed to start GUI. Check: systemctl --user status opencode-gui"
      ;;
    stop)
      section "Stopping OpenCode GUI"
      systemctl --user stop opencode-gui.service 2>/dev/null && log "GUI stopped" || warn "GUI not running"
      ;;
    status|"")
      systemctl --user status opencode-gui.service 2>/dev/null || warn "GUI service not installed. Run: setup.sh --full"
      ;;
    *) err "Unknown: dev gui $action. Use: start|stop|status" ;;
  esac
}

cmd_isolated() {
  local action="${2:-status}"
  local CONFIG="$HOME/.config/opencode-setup/setup.conf"
  mkdir -p "$(dirname "$CONFIG")"

  case "$action" in
    on|enable)
      section "Enabling Isolated Circuit Mode"
      if grep -q "^ISOLATED_CIRCUIT=" "$CONFIG" 2>/dev/null; then
        sed -i 's/^ISOLATED_CIRCUIT=.*/ISOLATED_CIRCUIT=true/' "$CONFIG"
      else
        echo "ISOLATED_CIRCUIT=true" >> "$CONFIG"
      fi
      export ISOLATED_CIRCUIT=true
      log "Isolated circuit: ENABLED"
      info "All LLM providers now use local OpenAI-compatible servers."
      info "Recommended: ensure Ollama or LiteLLM is running."

      # Regenerate opencode.json with local providers
      if command -v opencode &>/dev/null; then
        source "$SCRIPTS_DIR/src/lib/18-opencode-json.sh" 2>/dev/null || true
        log "opencode.json regenerated with local providers"
      fi
      ;;
    off|disable)
      section "Disabling Isolated Circuit Mode"
      if grep -q "^ISOLATED_CIRCUIT=" "$CONFIG" 2>/dev/null; then
        sed -i 's/^ISOLATED_CIRCUIT=.*/ISOLATED_CIRCUIT=false/' "$CONFIG"
      else
        echo "ISOLATED_CIRCUIT=false" >> "$CONFIG"
      fi
      export ISOLATED_CIRCUIT=false
      log "Isolated circuit: DISABLED"
      info "Cloud providers (DeepSeek, OpenAI, etc.) are now available."
      info "Set API keys via: ~/.config/opencode/secrets.env"

      # Regenerate opencode.json with cloud providers
      if command -v opencode &>/dev/null; then
        source "$SCRIPTS_DIR/src/lib/18-opencode-json.sh" 2>/dev/null || true
        log "opencode.json regenerated with cloud providers"
      fi
      ;;
    status|"")
      section "Isolated Circuit Status"
      local current="${ISOLATED_CIRCUIT:-false}"
      [ -z "$current" ] && [ -f "$CONFIG" ] && . "$CONFIG" 2>/dev/null && current="${ISOLATED_CIRCUIT:-false}"
      case "${current,,}" in true|1|yes|on|enabled) current="true";; *) current="false";; esac

      if [ "$current" = "true" ]; then
        echo "  Isolated Circuit: ${GREEN}ENABLED${NC}"
        echo "  All LLM providers use local OpenAI-compatible servers."
        echo "  Local endpoint: ${OPencode_LOCAL_ENDPOINT:-http://localhost:4000/v1}"
        echo ""
        echo "  Running backends:"
        for backend in ollama:11434 litellm:4000 vllm:8000 sglang:30000; do
          name="${backend%%:*}"
          port="${backend##*:}"
          if ss -tlnp 2>/dev/null | grep -q ":$port "; then
            echo "    ${GREEN}●${NC} $name (port $port) — running"
          else
            echo "    ○ $name (port $port) — not running"
          fi
        done
      else
        echo "  Isolated Circuit: DISABLED"
        echo "  Cloud providers available."
      fi
      ;;
    *) err "Unknown: dev isolated $action. Use: on|off|status" ;;
  esac
}

case "${1:-}" in
  install)  cmd_install "${2:-}" ;;
  remove)   cmd_remove "${2:-}" ;;
  update)   cmd_update ;;
  health)   cmd_health ;;
  list|ls)  cmd_list ;;
  config)   cmd_config ;;
  self-update) cmd_self_update ;;
  version-check) cmd_version_check ;;
  autoupdate) cmd_autoupdate ;;
  infra)     cmd_infra "${@}" ;;
  plugins)   cmd_plugins "${@}" ;;
  observability) cmd_observability "${@}" ;;
  gui)       cmd_gui "${@}" ;;
  isolated)  cmd_isolated "${@}" ;;
  -h|--help|help|"") usage ;;
  *)        err "Unknown: $1. Use: dev install|remove|update|health|list|config|self-update|version-check|autoupdate|infra|plugins|observability" ;;
esac
