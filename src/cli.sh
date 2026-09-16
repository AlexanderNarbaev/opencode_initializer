#!/usr/bin/env bash
# src/cli.sh — OpenCode Initializer CLI
# Unified command-line interface for all modules.
set -euo pipefail

# ── CLI Configuration ────────────────────────────────────────────────────────
CLI_VERSION="15.1.0"
CLI_NAME="opencode"
CLI_DESCRIPTION="OpenCode Initializer — AI-native development platform"

# ── Source modules ────────────────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/helpers.sh" 2>/dev/null || true
source "$SCRIPT_DIR/lib/00-core.sh" 2>/dev/null || true

# ── CLI Help ──────────────────────────────────────────────────────────────────
cli_help() {
  cat <<EOF
$CLI_DESCRIPTION (v$CLI_VERSION)

Usage: $CLI_NAME [command] [options]

Commands:
  init          Initialize OpenCode environment
  install       Install modules and dependencies
  status        Show system status
  config        Manage configuration
  security      Security scanning and audit
  cache         Cache management
  template      Template management
  skill         Skill management
  agent         Agent orchestration
  help          Show this help

Options:
  --help, -h    Show this help
  --version, -v Show version
  --verbose     Enable verbose output
  --dry-run     Dry run mode
  --force       Force operation

Examples:
  $CLI_NAME init                    # Initialize environment
  $CLI_NAME install --all           # Install all modules
  $CLI_NAME status                  # Show system status
  $CLI_NAME security scan           # Run security scan
  $CLI_NAME cache clear             # Clear cache
  $CLI_NAME template list           # List templates
  $CLI_NAME skill list              # List skills
  $CLI_NAME agent run workflow.yaml # Run agent workflow
EOF
}

# ── CLI Version ───────────────────────────────────────────────────────────────
cli_version() {
  echo "$CLI_NAME v$CLI_VERSION"
}

# ── CLI Status ────────────────────────────────────────────────────────────────
cli_status() {
  section "System Status"
  
  echo "Version: $CLI_VERSION"
  echo "Modules: $(ls "$SCRIPT_DIR/lib/"*.sh 2>/dev/null | wc -l)"
  echo "Tests: $(find "$SCRIPT_DIR/../tests" -name '*.sh' 2>/dev/null | wc -l)"
  echo "Documentation: $(find "$SCRIPT_DIR/../docs" -name '*.md' 2>/dev/null | wc -l)"
  
  echo ""
  section "Configuration"
  
  if [ -f "$HOME/.config/opencode-setup/setup.conf" ]; then
    echo "Config: $HOME/.config/opencode-setup/setup.conf"
  else
    echo "Config: Not found"
  fi
  
  if [ -f "$HOME/.config/opencode-setup/setup.toml" ]; then
    echo "TOML: $HOME/.config/opencode-setup/setup.toml"
  else
    echo "TOML: Not found"
  fi
  
  echo ""
  section "Services"
  
  local services=("postgres" "redis" "qdrant" "prometheus" "grafana")
  for svc in "${services[@]}"; do
    local port
    port=$(_get_service_port "$svc" 2>/dev/null || echo "")
    if [ -n "$port" ]; then
      if _port_is_free "$port" 2>/dev/null; then
        echo "  $svc: stopped (port $port)"
      else
        echo "  $svc: running (port $port)"
      fi
    fi
  done
}

# ── CLI Init ──────────────────────────────────────────────────────────────────
cli_init() {
  section "Initializing OpenCode Environment"
  
  # Create directories
  mkdir -p "$HOME/.config/opencode-setup"
  mkdir -p "$HOME/.cache/opencode-setup"
  mkdir -p "$HOME/.local/share/opencode"
  
  # Create default configuration
  if [ ! -f "$HOME/.config/opencode-setup/setup.conf" ]; then
    cat > "$HOME/.config/opencode-setup/setup.conf" <<EOF
# OpenCode Initializer Configuration
# Generated: $(date -u +"%Y-%m-%dT%H:%M:%SZ")

# Services
POSTGRES_PORT=5432
REDIS_PORT=6379
QDRANT_PORT=6333
PROMETHEUS_PORT=9090
GRAFANA_PORT=3001

# Features
PARALLEL_INSTALL=true
DOWNLOAD_CACHE=true
SECURITY_SCAN=true
EOF
    echo "✓ Created configuration: $HOME/.config/opencode-setup/setup.conf"
  else
    echo "✓ Configuration already exists"
  fi
  
  # Initialize cache
  if command -v _cache_init &>/dev/null; then
    _cache_init 2>/dev/null || true
    echo "✓ Initialized cache"
  fi
  
  echo ""
  echo "OpenCode environment initialized successfully!"
  echo "Run '$CLI_NAME status' to see system status."
}

# ── CLI Install ───────────────────────────────────────────────────────────────
cli_install() {
  local target="${1:-all}"
  
  section "Installing: $target"
  
  case "$target" in
    all)
      echo "Installing all modules..."
      # Source parallel module and run installation
      if [ -f "$SCRIPT_DIR/lib/00d-parallel.sh" ]; then
        source "$SCRIPT_DIR/lib/00d-parallel.sh"
        echo "Parallel installation enabled"
      fi
      ;;
    core)
      echo "Installing core modules..."
      ;;
    *)
      echo "Unknown target: $target"
      echo "Available targets: all, core, services, tools"
      return 1
      ;;
  esac
}

# ── CLI Config ────────────────────────────────────────────────────────────────
cli_config() {
  local action="${1:-show}"
  
  case "$action" in
    show)
      section "Configuration"
      if [ -f "$HOME/.config/opencode-setup/setup.conf" ]; then
        cat "$HOME/.config/opencode-setup/setup.conf"
      else
        echo "No configuration found. Run '$CLI_NAME init' first."
      fi
      ;;
    edit)
      ${EDITOR:-vi} "$HOME/.config/opencode-setup/setup.conf"
      ;;
    reset)
      rm -f "$HOME/.config/opencode-setup/setup.conf"
      echo "Configuration reset. Run '$CLI_NAME init' to create new configuration."
      ;;
    *)
      echo "Unknown action: $action"
      echo "Available actions: show, edit, reset"
      return 1
      ;;
  esac
}

# ── CLI Security ──────────────────────────────────────────────────────────────
cli_security() {
  local action="${1:-scan}"
  
  case "$action" in
    scan)
      section "Security Scan"
      if command -v _scan_secrets &>/dev/null; then
        _scan_secrets "." 2>/dev/null || true
      else
        echo "Security module not loaded"
      fi
      ;;
    audit)
      section "Permission Audit"
      if command -v _audit_permissions &>/dev/null; then
        _audit_permissions "." 2>/dev/null || true
      else
        echo "Security module not loaded"
      fi
      ;;
    *)
      echo "Unknown action: $action"
      echo "Available actions: scan, audit"
      return 1
      ;;
  esac
}

# ── CLI Cache ─────────────────────────────────────────────────────────────────
cli_cache() {
  local action="${1:-status}"
  
  case "$action" in
    status)
      section "Cache Status"
      if command -v _cache_stats &>/dev/null; then
        _cache_stats 2>/dev/null || true
      else
        echo "Cache module not loaded"
      fi
      ;;
    clear)
      section "Clearing Cache"
      if command -v _cache_cleanup &>/dev/null; then
        _cache_cleanup 2>/dev/null || true
        echo "Cache cleared"
      else
        echo "Cache module not loaded"
      fi
      ;;
    *)
      echo "Unknown action: $action"
      echo "Available actions: status, clear"
      return 1
      ;;
  esac
}

# ── CLI Template ──────────────────────────────────────────────────────────────
cli_template() {
  local action="${1:-list}"
  
  case "$action" in
    list)
      section "Available Templates"
      if command -v _template_list &>/dev/null; then
        _template_list 2>/dev/null || true
      else
        echo "Template module not loaded"
      fi
      ;;
    *)
      echo "Unknown action: $action"
      echo "Available actions: list"
      return 1
      ;;
  esac
}

# ── CLI Skill ─────────────────────────────────────────────────────────────────
cli_skill() {
  local action="${1:-list}"
  
  case "$action" in
    list)
      section "Available Skills"
      if command -v _skill_list &>/dev/null; then
        _skill_list 2>/dev/null || true
      else
        echo "Skill module not loaded"
      fi
      ;;
    *)
      echo "Unknown action: $action"
      echo "Available actions: list"
      return 1
      ;;
  esac
}

# ── CLI Agent ─────────────────────────────────────────────────────────────────
cli_agent() {
  local action="${1:-status}"
  
  case "$action" in
    status)
      section "Agent Status"
      echo "Agent orchestration module"
      echo "Use '$CLI_NAME agent run <workflow>' to run workflows"
      ;;
    *)
      echo "Unknown action: $action"
      echo "Available actions: status"
      return 1
      ;;
  esac
}

# ── Main CLI Entry Point ──────────────────────────────────────────────────────
main() {
  local command="${1:-help}"
  shift || true
  
  case "$command" in
    help|--help|-h)
      cli_help
      ;;
    version|--version|-v)
      cli_version
      ;;
    status)
      cli_status "$@"
      ;;
    init)
      cli_init "$@"
      ;;
    install)
      cli_install "$@"
      ;;
    config)
      cli_config "$@"
      ;;
    security)
      cli_security "$@"
      ;;
    cache)
      cli_cache "$@"
      ;;
    template)
      cli_template "$@"
      ;;
    skill)
      cli_skill "$@"
      ;;
    agent)
      cli_agent "$@"
      ;;
    *)
      echo "Unknown command: $command"
      echo "Run '$CLI_NAME help' for usage information."
      exit 1
      ;;
  esac
}

# Run main function
main "$@"
