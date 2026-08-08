#!/usr/bin/env bash
# lib/helpers.sh — shared functions for setup.sh and dev CLI
set -euo pipefail

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
GRAY='\033[0;90m'
NC='\033[0m'
log() { echo -e "${GREEN}[✓]${NC} $(date +%H:%M:%S) $1"; }
warn() { echo -e "${YELLOW}[!]${NC} $(date +%H:%M:%S) $1" >&2; }
err() {
  echo -e "${RED}[✗]${NC} $(date +%H:%M:%S) $1" >&2
  exit 1
}
info() { echo -e "${CYAN}[i]${NC} $(date +%H:%M:%S) $1"; }
section() {
  echo
  echo -e "${CYAN}─── $1 ───${NC}"
}

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
    *) printf "\r\033[K" ;;
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
  local msg="$1"
  shift
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

# shellcheck disable=SC2034
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
  local url="$1" out="${2:-}" attempt=1 max=5 cache_key cache_file
  cache_key=$(echo "$url" | md5sum | awk '{print $1}')
  cache_file="$DL_CACHE/${cache_key}.dl"
  [ -n "$out" ] && [ -f "$cache_file" ] && [ $(($(date +%s) - $(stat -c %Y "$cache_file" 2>/dev/null || echo 0))) -lt 86400 ] && cp "$cache_file" "$out" 2>/dev/null && return 0
  # Corporate proxy support: HTTP_PROXY, HTTPS_PROXY, NO_PROXY env vars
  local proxy_opts=""
  [ -n "${HTTPS_PROXY:-${https_proxy:-}}" ] && proxy_opts="$proxy_opts --proxy ${HTTPS_PROXY:-${https_proxy}}"
  [ -n "${HTTP_PROXY:-${http_proxy:-}}" ] && [ -z "$proxy_opts" ] && proxy_opts="$proxy_opts --proxy ${HTTP_PROXY:-${http_proxy}}"
  # Corporate certificate support: CURL_CA_BUNDLE, REQUESTS_CA_BUNDLE
  [ -n "${CURL_CA_BUNDLE:-}" ] && [ -f "${CURL_CA_BUNDLE}" ] && proxy_opts="$proxy_opts --cacert ${CURL_CA_BUNDLE}"
  # Mirror-aware: try primary URL, then GH proxy mirror for github.com
  while [ $attempt -le $max ]; do
    if [ -n "$out" ]; then
      curl -fsSL --connect-timeout 30 --max-time 120 --retry 1 --retry-delay 3 $proxy_opts -o "$out" "$url" 2>/dev/null && {
        cp "$out" "$cache_file" 2>/dev/null || true
        return 0
      }
      # Try GitHub mirror as fallback
      if echo "$url" | grep -q 'github.com\|githubusercontent.com'; then
        local mirror_url
        mirror_url=$(echo "$url" | sed 's|https://github\.com|https://ghproxy.com/https://github.com|;s|https://raw\.githubusercontent\.com|https://ghproxy.com/https://raw.githubusercontent.com|')
        [ "$mirror_url" != "$url" ] && curl -fsSL --connect-timeout 30 --max-time 120 --retry 1 --retry-delay 3 $proxy_opts -o "$out" "$mirror_url" 2>/dev/null && {
          cp "$out" "$cache_file" 2>/dev/null || true
          return 0
        }
      fi
    else
      curl -fsSL --connect-timeout 30 --max-time 120 --retry 1 --retry-delay 3 $proxy_opts "$url" 2>/dev/null && return 0
      if echo "$url" | grep -q 'github\.com'; then
        local mirror_url
        mirror_url=$(echo "$url" | sed 's|https://github\.com|https://ghproxy.com/https://github.com|')
        [ "$mirror_url" != "$url" ] && curl -fsSL --connect-timeout 30 --max-time 120 --retry 1 $proxy_opts "$mirror_url" 2>/dev/null && return 0
      fi
    fi
    sleep $((2 ** attempt))
    attempt=$((attempt + 1))
  done
  return 1
}

_retry() {
  local max="$1" desc="$2" attempt=1
  shift 2
  while [ $attempt -le $max ]; do
    "$@" 2>/dev/null && return 0
    warn "$desc attempt $attempt/$max..."
    sleep $((2 ** attempt))
    attempt=$((attempt + 1))
  done
  return 1
}

MCP_CACHE="$DL_CACHE/mcp-offline"
mkdir -p "$MCP_CACHE"

_npm_install() {
  local pkg="$1" name="$2" pkg_name
  pkg_name=$(echo "$pkg" | sed 's|@.*/||;s|@.*||')
  local tgz="$MCP_CACHE/${pkg_name}-latest.tgz"
  [ -f "$tgz" ] && timeout 120 npm install -g "$tgz" --prefer-offline 2>/dev/null && {
    log "MCP: $name (cached)"
    return 0
  }
  if timeout 120 npm pack "$pkg@latest" --pack-destination "$MCP_CACHE" 2>/dev/null; then
    local downloaded
    downloaded=$(ls -t "$MCP_CACHE/${pkg_name}-"*.tgz 2>/dev/null | head -1)
    [ -n "$downloaded" ] && timeout 120 npm install -g "$downloaded" --prefer-offline 2>/dev/null && {
      log "MCP: $name (npm pack)"
      return 0
    }
  fi
  timeout 120 npm install -g "${pkg}@latest" --prefer-offline 2>/dev/null && {
    log "MCP: $name (npm)"
    return 0
  }
  command -v bun &>/dev/null && timeout 120 bun install -g "${pkg}@latest" --prefer-offline 2>/dev/null && {
    log "MCP: $name (bun)"
    return 0
  }
  warn "MCP FAILED: $name"
  return 1
}

_sudo() {
  local sudo_err
  sudo_err=$(mktemp /tmp/opencode-sudo-err.XXXXXX)
  if [ -n "${SUDO_PASS:-}" ]; then
    sudo -S "$@" 2>"$sudo_err" <<< "$SUDO_PASS" || { warn "sudo failed: $(head -1 "$sudo_err")"; rm -f "$sudo_err"; return 1; }
  else
    sudo "$@" 2>"$sudo_err" || { warn "sudo failed: $(head -1 "$sudo_err")"; rm -f "$sudo_err"; return 1; }
  fi
  rm -f "$sudo_err"
}

# Download a file and optionally verify its SHA256 checksum.
# Usage: _download_verify <url> <dest_path> [sha256_checksum]
#   - Downloads via _curl (retries, cache, mirror fallback)
#   - If sha256 provided: verifies and fails on mismatch, cleans up tmp
#   - If sha256 omitted: warns "unverified download" but continues (backward compat)
#   - Atomic: downloads to .tmp, then mv to dest on success
#   - Sets executable bit on dest after successful download
# Used by: 29-mise.sh, 28-devbox.sh, 16-llm.sh, 14-shokunin.sh, 04-zsh.sh
_download_verify() {
  local url="$1" dest="$2" sha256="${3:-}"
  local tmp="${dest}.tmp"

  _curl "$url" "$tmp" || { warn "Download failed: $url"; rm -f "$tmp"; return 1; }

  if [ -n "$sha256" ]; then
    if echo "$sha256  $tmp" | sha256sum -c - --status 2>/dev/null; then
      log "SHA256 verified: $dest"
    else
      err "SHA256 mismatch for $url — expected $sha256, got $(sha256sum "$tmp" | awk '{print $1}')"
      rm -f "$tmp"
      return 1
    fi
  else
    warn "Unverified download (no SHA256): $url → $dest"
  fi

  mv "$tmp" "$dest" && chmod +x "$dest" 2>/dev/null || true
  return 0
}

# ── WAL atomic append (flock-based) ───────────────────────────────────────────
# Usage: _wal_locked_append <file> <json_line>
# Acquires exclusive lock via flock (util-linux) with mkdir-fallback.
# Creates parent directory. Bash 3.2-compatible (no exec {fd}>).
# Returns 1 on missing file, 0 otherwise.
_wal_locked_append() {
  local file="$1" line="${2:-}"
  [ -z "$file" ] && { warn "_wal_locked_append: missing file argument"; return 1; }
  [ -z "$line" ] && return 0  # empty content is no-op

  mkdir -p "$(dirname "$file")" 2>/dev/null || true
  local lockfile="${file}.lock"

  # Primary: flock with explicit fd 9 (bash 3.2 safe, fd 9 chosen as unlikely collision)
  if command -v flock &>/dev/null; then
    (
      exec 9>>"$lockfile"
      if flock -w 5 -x 9 2>/dev/null; then
        printf '%s\n' "$line" >> "$file"
        exec 9>&-
        exit 0
      fi
      exec 9>&-
      exit 1
    ) && return 0
    warn "_wal_locked_append: flock timeout on $file, trying mkdir fallback"
  fi

  # Fallback: mkdir-based advisory lock (10 attempts × 0.1s = 1s total)
  local lockdir="${lockfile}.d" attempt=1 max=10
  while [ $attempt -le $max ]; do
    if mkdir "$lockdir" 2>/dev/null; then
      printf '%s\n' "$line" >> "$file"
      rmdir "$lockdir" 2>/dev/null
      return 0
    fi
    sleep 0.1
    attempt=$((attempt + 1))
  done

  # Last resort: plain append with warning (better than losing data)
  warn "_wal_locked_append: mkdir lock timeout after ${max}s — appending unlocked to $file"
  printf '%s\n' "$line" >> "$file"
  return 0
}

# ── Safe rm with critical-path guard ──────────────────────────────────────────
# Usage: _safe_rm <path...>
# Blocks deletion of: /, $HOME, $HOME/.cache, $HOME/.cache/opencode + subpaths.
# Allows all other paths (mktemp dirs, /tmp, /usr/local, build/, dist/, etc.).
# Logs blocked attempts to WAL if _wal_agent_log is available.
# Returns 1 if any path is blocked (does not delete anything if blocked).
_safe_rm() {
  local cache_opencode="${HOME}/.cache/opencode"
  local p real_p blocked msg

  for p in "$@"; do
    [ -z "$p" ] && { warn "_safe_rm: empty path argument, skipping"; continue; }
    blocked=0 msg=""

    # Resolve to absolute path (best-effort)
    if command -v realpath &>/dev/null; then
      real_p=$(realpath -m "$p" 2>/dev/null || echo "$p")
    else
      case "$p" in
        /*) real_p="$p" ;;
        *)  real_p="$(cd "$(dirname "$p")" 2>/dev/null && pwd)/$(basename "$p")" ;;
      esac
    fi

    # Guard: critical paths
    case "$real_p" in
      "/")                    blocked=1; msg="root filesystem" ;;
      "$HOME")                blocked=1; msg="HOME directory" ;;
      "${HOME}/.cache")       blocked=1; msg="~/.cache" ;;
      "$cache_opencode")      blocked=1; msg="~/.cache/opencode" ;;
      "${cache_opencode}/"*)  blocked=1; msg="under ~/.cache/opencode" ;;
    esac

    if [ "$blocked" = "1" ]; then
      warn "_safe_rm: REFUSED to delete $p ($msg)"
      command -v _wal_agent_log &>/dev/null && \
        _wal_agent_log "safe_rm" "blocked: $p ($msg)" "protected path" "1.0" "S1"
      return 1
    fi
  done

  # All paths passed guard — safe to delete
  rm -rf -- "$@"
}

# ── Canonical ERR-trap handler ────────────────────────────────────────────────
# Usage: trap '_trap_cleanup "NN-module"' ERR
# Saves exit code, reports module:line, logs to WAL, cleans _CLEANUP_FILES[].
# Configurable via _SETUP_ERROR_STRICT env:
#   0 (default) = warn + continue (return 0; does NOT swallow set -e on bash<4.4)
#   1           = exit with saved exit code
# Bash 3.2-compatible.
_trap_cleanup() {
  local code=$?   # MUST be first — capture before any command resets $?
  local module="${1:-unknown}"
  local lineno="${BASH_LINENO[0]:-?}"

  # Log to agent WAL if available
  if command -v _wal_agent_log &>/dev/null; then
    _wal_agent_log "error" "${module}:${lineno} exit ${code}" "ERR trap fired" "0.9" "S2"
  fi

  # Clean registered temp files
  local f
  for f in "${_CLEANUP_FILES[@]:-}"; do
    [ -n "$f" ] && [ -e "$f" ] && rm -rf "$f" 2>/dev/null
  done

  # Error strategy
  local strict="${_SETUP_ERROR_STRICT:-0}"
  if [ "$strict" = "1" ]; then
    warn "${module}:${lineno} FATAL (exit ${code}, _SETUP_ERROR_STRICT=${strict})"
    exit "$code"
  fi

  warn "${module}:${lineno} error (exit ${code}) — continuing"
  return 0
}
