#!/usr/bin/env bash
# lib/helpers.sh — shared functions for setup.sh and dev CLI
set -euo pipefail

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; CYAN='\033[0;36m'; BLUE='\033[0;34m'; MAGENTA='\033[0;35m'; GRAY='\033[0;90m'; NC='\033[0m'
log()   { echo -e "${GREEN}[✓]${NC} $(date +%H:%M:%S) $1"; }
warn()  { echo -e "${YELLOW}[!]${NC} $(date +%H:%M:%S) $1" >&2; }
err()   { echo -e "${RED}[✗]${NC} $(date +%H:%M:%S) $1" >&2; exit 1; }
info()  { echo -e "${CYAN}[i]${NC} $(date +%H:%M:%S) $1"; }
section() { echo; echo -e "${CYAN}─── $1 ───${NC}"; }

# ── Progress indicators ───────────────────────────────────────────────────────
# Spinner frames for in-line animation
SPIN_CHARS='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
_spin_idx=0
_spin_pid=""

# Start a spinner: _spin_start "Installing packages..."
# Then after work done: _spin_stop "✓" or _spin_stop "✗"
_spin_start() {
  local msg="$1"
  _spin_pid=""
  printf "\r  ${CYAN}%s${NC} ${GRAY}%s${NC}" "${SPIN_CHARS:0:1}" "$msg"
  (
    local i=0
    while true; do
      printf "\r  ${CYAN}%s${NC} ${GRAY}%s${NC}" "${SPIN_CHARS:$((i % 10)):1}" "$msg"
      i=$((i + 1))
      sleep 0.1
    done
  ) &
  _spin_pid=$!
  disown $_spin_pid 2>/dev/null || true
}

_spin_stop() {
  local result="${1:- }"
  [ -n "$_spin_pid" ] && kill $_spin_pid 2>/dev/null || true
  _spin_pid=""
  case "$result" in
    "✓") printf "\r  ${GREEN}✓${NC}\n" ;;
    "✗") printf "\r  ${RED}✗${NC}\n" ;;
    *)   printf "\r\033[K" ;;
  esac
}

# One-line progress: _progress "Step 3/19" "Installing Node.js..."
# Updates the same line with progress info
_progress() {
  local step="$1" msg="$2"
  printf "\r  ${BLUE}[%s]${NC} ${GRAY}%s${NC}" "$step" "$msg"
}

# Run command with spinner: _run_spin "Installing..." cmd arg1 arg2
_run_spin() {
  local msg="$1"; shift
  _spin_start "$msg"
  if "$@" 2>/dev/null; then
    _spin_stop "✓"
    return 0
  else
    _spin_stop "✗"
    return 1
  fi
}

# Blurred progress line — for sensitive or verbose output
_blur() {
  local msg="$1" max="${2:-60}"
  printf "\r  ${MAGENTA}▌${NC} ${GRAY}%.*s...${NC}" "$max" "$msg"
}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
DL_CACHE="${HOME}/.cache/opencode-setup"
mkdir -p "$DL_CACHE"
SECRETS_FILE="${HOME}/.config/opencode/secrets.env"
mkdir -p "$(dirname "$SECRETS_FILE")"

cleanup() {
  local exit_code=$?
  rm -f /tmp/docker-install.*.sh /tmp/uv-install.*.sh /tmp/bun-install.*.sh \
        /tmp/sdkman-install.sh /tmp/superpowers.* /tmp/dotnet-install.*.sh \
        /tmp/rustup-init.*.sh /tmp/opencode-install.sh /tmp/ollama-install.sh 2>/dev/null
  npm config set strict-ssl true 2>/dev/null || true
  if [ $exit_code -ne 0 ] && [ "${MODE:-}" != "health" ]; then
    warn "Script exited with code $exit_code at $(date +%H:%M:%S)"
    warn "Log: ${LOG_FILE:-not started}"
    warn "Re-run: bash ~/setup.sh --health ; or resume with --full (progress tracked)"
  fi
  exit $exit_code
}
trap cleanup EXIT INT TERM

_curl() {
  local url="$1" out="${2:-}" opts="${3:-}" attempt=1 max=5 cache_key cache_file
  cache_key=$(echo "$url" | md5sum | awk '{print $1}')
  cache_file="$DL_CACHE/${cache_key}.dl"
  [ -n "$out" ] && [ -f "$cache_file" ] && [ $(($(date +%s) - $(stat -c %Y "$cache_file" 2>/dev/null || echo 0))) -lt 86400 ] && cp "$cache_file" "$out" 2>/dev/null && return 0
  # Mirror-aware: try primary URL, then GH proxy mirror for github.com
  while [ $attempt -le $max ]; do
    if [ -n "$out" ]; then
      curl -fsSL --connect-timeout 30 --max-time 120 --retry 1 --retry-delay 3 -o "$out" "$url" 2>/dev/null && { cp "$out" "$cache_file" 2>/dev/null || true; return 0; }
      # Try GitHub mirror as fallback
      if echo "$url" | grep -q 'github.com\|githubusercontent.com'; then
        local mirror_url
        mirror_url=$(echo "$url" | sed 's|https://github\.com|https://ghproxy.com/https://github.com|;s|https://raw\.githubusercontent\.com|https://ghproxy.com/https://raw.githubusercontent.com|')
        [ "$mirror_url" != "$url" ] && curl -fsSL --connect-timeout 30 --max-time 120 --retry 1 --retry-delay 3 -o "$out" "$mirror_url" 2>/dev/null && { cp "$out" "$cache_file" 2>/dev/null || true; return 0; }
      fi
    else
      curl -fsSL --connect-timeout 30 --max-time 120 --retry 1 --retry-delay 3 "$url" 2>/dev/null && return 0
      if echo "$url" | grep -q 'github\.com'; then
        local mirror_url
        mirror_url=$(echo "$url" | sed 's|https://github\.com|https://ghproxy.com/https://github.com|')
        [ "$mirror_url" != "$url" ] && curl -fsSL --connect-timeout 30 --max-time 120 --retry 1 "$mirror_url" 2>/dev/null && return 0
      fi
    fi
    sleep $((2 ** attempt)); attempt=$((attempt + 1))
  done
  return 1
}

_retry() {
  local max="$1" desc="$2" attempt=1; shift 2
  while [ $attempt -le $max ]; do
    "$@" 2>/dev/null && return 0
    warn "$desc attempt $attempt/$max..."
    sleep $((2 ** attempt)); attempt=$((attempt + 1))
  done
  return 1
}

MCP_CACHE="$DL_CACHE/mcp-offline"
mkdir -p "$MCP_CACHE"

_npm_install() {
  local pkg="$1" name="$2" pkg_name
  pkg_name=$(echo "$pkg" | sed 's|@.*/||;s|@.*||')
  local tgz="$MCP_CACHE/${pkg_name}-latest.tgz"
  [ -f "$tgz" ] && timeout 120 npm install -g "$tgz" --prefer-offline 2>/dev/null && { log "MCP: $name (cached)"; return 0; }
  if timeout 120 npm pack "$pkg@latest" --pack-destination "$MCP_CACHE" 2>/dev/null; then
    local downloaded=$(ls -t "$MCP_CACHE/${pkg_name}-"*.tgz 2>/dev/null | head -1)
    [ -n "$downloaded" ] && timeout 120 npm install -g "$downloaded" --prefer-offline 2>/dev/null && { log "MCP: $name (npm pack)"; return 0; }
  fi
  timeout 120 npm install -g "${pkg}@latest" --prefer-offline 2>/dev/null && { log "MCP: $name (npm)"; return 0; }
  command -v bun &>/dev/null && timeout 120 bun install -g "${pkg}@latest" --prefer-offline 2>/dev/null && { log "MCP: $name (bun)"; return 0; }
  warn "MCP FAILED: $name"; return 1
}

_sudo() {
  if [ -n "${SUDO_PASS:-}" ]; then
    echo "$SUDO_PASS" | sudo -S "$@" 2>/dev/null
  else
    sudo "$@" 2>/dev/null
  fi
}
