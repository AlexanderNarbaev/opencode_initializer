#!/usr/bin/env bash
# src/lib/00x-config.sh — Unified Configuration System (v15.1.0)
# Provides centralized configuration management with validation and migration.
set -euo pipefail

# ── Configuration paths ──────────────────────────────────────────────────────
_CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/opencode-setup"
_CONFIG_FILE="${_CONFIG_DIR}/setup.conf"
_CONFIG_TOML="${_CONFIG_DIR}/setup.toml"
_CONFIG_JSON="${_CONFIG_DIR}/config.json"
_CONFIG_BACKUP="${_CONFIG_DIR}/backup"
_CONFIG_VERSION="1.0.0"

# ── Configuration schema (parallel indexed arrays — macOS bash 3.2 safe) ──────
_CONFIG_KEYS=(
  POSTGRES_PORT REDIS_PORT QDRANT_PORT PROMETHEUS_PORT GRAFANA_PORT
  NODE_EXPORTER_PORT MEMORYLAYER_PORT KAFKA_PORT NEO4J_PORT MINIO_PORT
  SEARXNG_PORT OPEN_WEBUI_PORT
  PARALLEL_INSTALL DOWNLOAD_CACHE SECURITY_SCAN AUTO_UPDATE VERBOSE DRY_RUN
  DL_CACHE SETUP_DIR DATA_DIR
)
_CONFIG_DEFAULTS=(
  5432 6379 6333 9090 3001
  9100 61001 9092 7474 9000
  8888 3300
  true true true true false false
  "$HOME/.cache/opencode-setup" "$HOME/.config/opencode-setup" "$HOME/.local/share/opencode"
)

_config_schema_default() {
  local key="$1" i
  for (( i=0; i<${#_CONFIG_KEYS[@]}; i++ )); do
    if [ "${_CONFIG_KEYS[$i]}" = "$key" ]; then
      echo "${_CONFIG_DEFAULTS[$i]}"
      return 0
    fi
  done
  return 1
}

# ── Initialize configuration ─────────────────────────────────────────────────
_config_init() {
  mkdir -p "$_CONFIG_DIR"
  mkdir -p "$_CONFIG_BACKUP"
  
  if [ ! -f "$_CONFIG_FILE" ]; then
    _config_generate_default
  fi
}

# ── Generate default configuration ───────────────────────────────────────────
_config_generate_default() {
  cat > "$_CONFIG_FILE" <<EOF
# OpenCode Initializer Configuration
# Version: $_CONFIG_VERSION
# Generated: $(date -u +"%Y-%m-%dT%H:%M:%SZ")

# ── Services ──────────────────────────────────────────────────────────────────
POSTGRES_PORT=$(_config_schema_default POSTGRES_PORT)
REDIS_PORT=$(_config_schema_default REDIS_PORT)
QDRANT_PORT=$(_config_schema_default QDRANT_PORT)
PROMETHEUS_PORT=$(_config_schema_default PROMETHEUS_PORT)
GRAFANA_PORT=$(_config_schema_default GRAFANA_PORT)
NODE_EXPORTER_PORT=$(_config_schema_default NODE_EXPORTER_PORT)
MEMORYLAYER_PORT=$(_config_schema_default MEMORYLAYER_PORT)
KAFKA_PORT=$(_config_schema_default KAFKA_PORT)
NEO4J_PORT=$(_config_schema_default NEO4J_PORT)
MINIO_PORT=$(_config_schema_default MINIO_PORT)
SEARXNG_PORT=$(_config_schema_default SEARXNG_PORT)
OPEN_WEBUI_PORT=$(_config_schema_default OPEN_WEBUI_PORT)

# ── Features ──────────────────────────────────────────────────────────────────
PARALLEL_INSTALL=$(_config_schema_default PARALLEL_INSTALL)
DOWNLOAD_CACHE=$(_config_schema_default DOWNLOAD_CACHE)
SECURITY_SCAN=$(_config_schema_default SECURITY_SCAN)
AUTO_UPDATE=$(_config_schema_default AUTO_UPDATE)
VERBOSE=$(_config_schema_default VERBOSE)
DRY_RUN=$(_config_schema_default DRY_RUN)

# ── Paths ─────────────────────────────────────────────────────────────────────
DL_CACHE=$(_config_schema_default DL_CACHE)
SETUP_DIR=$(_config_schema_default SETUP_DIR)
DATA_DIR=$(_config_schema_default DATA_DIR)
EOF
  
  log "Generated default configuration: $_CONFIG_FILE"
}

# ── Load configuration ───────────────────────────────────────────────────────
_config_load() {
  _config_init
  
  if [ -f "$_CONFIG_FILE" ]; then
    # shellcheck source=/dev/null
    source "$_CONFIG_FILE" 2>/dev/null || true
    log "Loaded configuration: $_CONFIG_FILE"
  fi
}

# ── Get configuration value ──────────────────────────────────────────────────
_config_get() {
  local key="$1"
  local default="${2:-}"
  
  # Check environment variable first
  if [ -n "${!key:-}" ]; then
    echo "${!key}"
    return 0
  fi
  
  # Check configuration file
  if [ -f "$_CONFIG_FILE" ]; then
    local value
    value=$(grep "^${key}=" "$_CONFIG_FILE" 2>/dev/null | cut -d'=' -f2- | tr -d '"' || echo "")
    if [ -n "$value" ]; then
      echo "$value"
      return 0
    fi
  fi
  
  # Return default
  echo "$default"
}

# ── Set configuration value ──────────────────────────────────────────────────
_config_set() {
  local key="$1"
  local value="$2"
  
  _config_init
  
  # Backup current configuration
  if [ -f "$_CONFIG_FILE" ]; then
    cp "$_CONFIG_FILE" "$_CONFIG_BACKUP/setup.conf.$(date +%Y%m%d%H%M%S)"
  fi
  
  # Update or add configuration
  if grep -q "^${key}=" "$_CONFIG_FILE" 2>/dev/null; then
    # Update existing
    sed -i "s|^${key}=.*|${key}=${value}|" "$_CONFIG_FILE"
  else
    # Add new
    echo "${key}=${value}" >> "$_CONFIG_FILE"
  fi
  
  log "Set configuration: $key=$value"
}

# ── Validate configuration ───────────────────────────────────────────────────
_config_validate() {
  local errors=0
  
  _config_init
  
  # Check required keys
  for key in "${_CONFIG_KEYS[@]}"; do
    local value
    value=$(_config_get "$key" "")
    if [ -z "$value" ]; then
      warn "Missing configuration: $key"
      errors=$((errors + 1))
    fi
  done
  
  # Validate ports
  local ports=("POSTGRES_PORT" "REDIS_PORT" "QDRANT_PORT" "PROMETHEUS_PORT" "GRAFANA_PORT")
  for port_key in "${ports[@]}"; do
    local port
    port=$(_config_get "$port_key" "")
    if [ -n "$port" ]; then
      if ! [[ "$port" =~ ^[0-9]+$ ]] || [ "$port" -lt 1 ] || [ "$port" -gt 65535 ]; then
        warn "Invalid port: $port_key=$port"
        errors=$((errors + 1))
      fi
    fi
  done
  
  if [ "$errors" -eq 0 ]; then
    log "Configuration validation passed"
    return 0
  else
    err "Configuration validation failed: $errors errors"
    return 1
  fi
}

# ── Show configuration ───────────────────────────────────────────────────────
_config_show() {
  _config_init
  
  section "Configuration"
  echo "File: $_CONFIG_FILE"
  echo "Version: $_CONFIG_VERSION"
  echo ""
  
  if [ -f "$_CONFIG_FILE" ]; then
    cat "$_CONFIG_FILE"
  else
    echo "No configuration found. Run 'opencode init' first."
  fi
}

# ── Reset configuration ──────────────────────────────────────────────────────
_config_reset() {
  _config_init
  
  # Backup current configuration
  if [ -f "$_CONFIG_FILE" ]; then
    cp "$_CONFIG_FILE" "$_CONFIG_BACKUP/setup.conf.$(date +%Y%m%d%H%M%S)"
    log "Backed up configuration"
  fi
  
  # Generate new default configuration
  _config_generate_default
  
  log "Configuration reset to defaults"
}

# ── Export functions ──────────────────────────────────────────────────────────
export -f _config_init _config_load _config_get _config_set _config_validate \
  _config_show _config_reset _config_generate_default 2>/dev/null || true
