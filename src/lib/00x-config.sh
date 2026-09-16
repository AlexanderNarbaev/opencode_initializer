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

# ── Configuration schema ─────────────────────────────────────────────────────
declare -A _CONFIG_SCHEMA=(
  # Services
  ["POSTGRES_PORT"]="5432"
  ["REDIS_PORT"]="6379"
  ["QDRANT_PORT"]="6333"
  ["PROMETHEUS_PORT"]="9090"
  ["GRAFANA_PORT"]="3001"
  ["NODE_EXPORTER_PORT"]="9100"
  ["MEMORYLAYER_PORT"]="61001"
  ["KAFKA_PORT"]="9092"
  ["NEO4J_PORT"]="7474"
  ["MINIO_PORT"]="9000"
  ["SEARXNG_PORT"]="8888"
  ["OPEN_WEBUI_PORT"]="3300"
  
  # Features
  ["PARALLEL_INSTALL"]="true"
  ["DOWNLOAD_CACHE"]="true"
  ["SECURITY_SCAN"]="true"
  ["AUTO_UPDATE"]="true"
  ["VERBOSE"]="false"
  ["DRY_RUN"]="false"
  
  # Paths
  ["DL_CACHE"]="$HOME/.cache/opencode-setup"
  ["SETUP_DIR"]="$HOME/.config/opencode-setup"
  ["DATA_DIR"]="$HOME/.local/share/opencode"
)

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
POSTGRES_PORT=${_CONFIG_SCHEMA[POSTGRES_PORT]}
REDIS_PORT=${_CONFIG_SCHEMA[REDIS_PORT]}
QDRANT_PORT=${_CONFIG_SCHEMA[QDRANT_PORT]}
PROMETHEUS_PORT=${_CONFIG_SCHEMA[PROMETHEUS_PORT]}
GRAFANA_PORT=${_CONFIG_SCHEMA[GRAFANA_PORT]}
NODE_EXPORTER_PORT=${_CONFIG_SCHEMA[NODE_EXPORTER_PORT]}
MEMORYLAYER_PORT=${_CONFIG_SCHEMA[MEMORYLAYER_PORT]}
KAFKA_PORT=${_CONFIG_SCHEMA[KAFKA_PORT]}
NEO4J_PORT=${_CONFIG_SCHEMA[NEO4J_PORT]}
MINIO_PORT=${_CONFIG_SCHEMA[MINIO_PORT]}
SEARXNG_PORT=${_CONFIG_SCHEMA[SEARXNG_PORT]}
OPEN_WEBUI_PORT=${_CONFIG_SCHEMA[OPEN_WEBUI_PORT]}

# ── Features ──────────────────────────────────────────────────────────────────
PARALLEL_INSTALL=${_CONFIG_SCHEMA[PARALLEL_INSTALL]}
DOWNLOAD_CACHE=${_CONFIG_SCHEMA[DOWNLOAD_CACHE]}
SECURITY_SCAN=${_CONFIG_SCHEMA[SECURITY_SCAN]}
AUTO_UPDATE=${_CONFIG_SCHEMA[AUTO_UPDATE]}
VERBOSE=${_CONFIG_SCHEMA[VERBOSE]}
DRY_RUN=${_CONFIG_SCHEMA[DRY_RUN]}

# ── Paths ─────────────────────────────────────────────────────────────────────
DL_CACHE=${_CONFIG_SCHEMA[DL_CACHE]}
SETUP_DIR=${_CONFIG_SCHEMA[SETUP_DIR]}
DATA_DIR=${_CONFIG_SCHEMA[DATA_DIR]}
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
  for key in "${!_CONFIG_SCHEMA[@]}"; do
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
