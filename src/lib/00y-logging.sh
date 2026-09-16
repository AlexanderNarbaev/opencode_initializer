#!/usr/bin/env bash
# src/lib/00y-logging.sh — Unified Logging System (v15.1.0)
# Provides centralized logging with levels, rotation, and analysis.
set -euo pipefail

# ── Logging configuration ────────────────────────────────────────────────────
_LOG_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/opencode-setup/logs"
_LOG_FILE="${_LOG_DIR}/opencode.log"
_LOG_LEVEL="${LOG_LEVEL:-info}"
_LOG_MAX_SIZE="${LOG_MAX_SIZE:-10485760}"  # 10MB
_LOG_MAX_FILES="${LOG_MAX_FILES:-5}"
_LOG_FORMAT="${LOG_FORMAT:-text}"  # text, json

# ── Log levels ────────────────────────────────────────────────────────────────
declare -A _LOG_LEVELS=(
  ["debug"]=0
  ["info"]=1
  ["warn"]=2
  ["error"]=3
  ["fatal"]=4
)

# ── Initialize logging ───────────────────────────────────────────────────────
_logging_init() {
  mkdir -p "$_LOG_DIR"
  
  # Rotate logs if needed
  _logging_rotate
}

# ── Log message ───────────────────────────────────────────────────────────────
_logging_log() {
  local level="$1"
  local message="$2"
  local timestamp
  timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
  
  # Check if message should be logged
  local current_level_num="${_LOG_LEVELS[$_LOG_LEVEL]:-1}"
  local message_level_num="${_LOG_LEVELS[$level]:-1}"
  
  if [ "$message_level_num" -lt "$current_level_num" ]; then
    return 0
  fi
  
  # Format message
  local formatted
  case "$_LOG_FORMAT" in
    json)
      formatted="{\"timestamp\":\"$timestamp\",\"level\":\"$level\",\"message\":\"$message\"}"
      ;;
    *)
      formatted="[$timestamp] [$level] $message"
      ;;
  esac
  
  # Output to console
  case "$level" in
    debug)
      printf "${GRAY}%s${NC}\n" "$formatted" >&2
      ;;
    info)
      printf "${GREEN}%s${NC}\n" "$formatted" >&2
      ;;
    warn)
      printf "${YELLOW}%s${NC}\n" "$formatted" >&2
      ;;
    error)
      printf "${RED}%s${NC}\n" "$formatted" >&2
      ;;
    fatal)
      printf "${RED}${BOLD}%s${NC}\n" "$formatted" >&2
      ;;
  esac
  
  # Write to log file
  echo "$formatted" >> "$_LOG_FILE" 2>/dev/null || true
}

# ── Log functions ─────────────────────────────────────────────────────────────
log_debug() {
  _logging_log "debug" "$1"
}

log_info() {
  _logging_log "info" "$1"
}

log_warn() {
  _logging_log "warn" "$1"
}

log_error() {
  _logging_log "error" "$1"
}

log_fatal() {
  _logging_log "fatal" "$1"
  exit 1
}

# ── Log rotation ──────────────────────────────────────────────────────────────
_logging_rotate() {
  if [ ! -f "$_LOG_FILE" ]; then
    return 0
  fi
  
  local file_size
  file_size=$(stat -c %s "$_LOG_FILE" 2>/dev/null || echo 0)
  
  if [ "$file_size" -gt "$_LOG_MAX_SIZE" ]; then
    # Rotate log files
    for i in $(seq $((_LOG_MAX_FILES - 1)) -1 1); do
      local src="${_LOG_FILE}.${i}"
      local dst="${_LOG_FILE}.$((i + 1))"
      if [ -f "$src" ]; then
        mv "$src" "$dst"
      fi
    done
    
    # Move current log to .1
    mv "$_LOG_FILE" "${_LOG_FILE}.1"
    
    # Create new empty log file
    touch "$_LOG_FILE"
    
    log_info "Log rotated"
  fi
  
  # Remove old log files
  for i in $(seq $((_LOG_MAX_FILES + 1)) 10); do
    local old_file="${_LOG_FILE}.${i}"
    if [ -f "$old_file" ]; then
      rm -f "$old_file"
    fi
  done
}

# ── Log analysis ──────────────────────────────────────────────────────────────
_logging_analyze() {
  if [ ! -f "$_LOG_FILE" ]; then
    echo "No log file found"
    return 0
  fi
  
  section "Log Analysis"
  
  echo "Log file: $_LOG_FILE"
  echo "Size: $(du -h "$_LOG_FILE" 2>/dev/null | awk '{print $1}')"
  echo "Lines: $(wc -l < "$_LOG_FILE" 2>/dev/null || echo 0)"
  echo ""
  
  echo "Level distribution:"
  for level in debug info warn error fatal; do
    local count
    count=$(grep -c "\[$level\]" "$_LOG_FILE" 2>/dev/null || echo 0)
    printf "  %-10s %s\n" "$level" "$count"
  done
  
  echo ""
  echo "Recent errors:"
  grep "\[error\]" "$_LOG_FILE" 2>/dev/null | tail -5 || echo "  None"
}

# ── Clear logs ────────────────────────────────────────────────────────────────
_logging_clear() {
  if [ -d "$_LOG_DIR" ]; then
    rm -f "$_LOG_DIR"/*.log*
    log_info "Logs cleared"
  fi
}

# ── Export functions ──────────────────────────────────────────────────────────
export -f _logging_init log_debug log_info log_warn log_error log_fatal \
  _logging_rotate _logging_analyze _logging_clear 2>/dev/null || true
