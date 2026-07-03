#!/usr/bin/env bash
# src/lib/00-core.sh — core infrastructure shared across all lib modules
# Sources: src/lib/helpers.sh must be sourced before this file
# shellcheck disable=SC2034  # variables used by sourced modules
set -euo pipefail

# ── Version ──────────────────────────────────────────────────────────────────
SCRIPT_VERSION="${SCRIPT_VERSION:-v2.0.0}"

# ── OS validation ────────────────────────────────────────────────────────────
if [ -f /etc/os-release ]; then
  . /etc/os-release 2>/dev/null || true
  case "${ID:-}" in
    ubuntu|debian|linuxmint|pop|elementary|zorin) ;;
    *) warn "Untested OS: ${ID:-unknown} ${VERSION_ID:-} — continuing (Ubuntu/Debian expected)" ;;
  esac
  info "OS: ${PRETTY_NAME:-$ID} ($(uname -m))"
fi

# ── Architecture detection ──────────────────────────────────────────────────
ARCH=$(uname -m)
case "$ARCH" in
  x86_64|amd64) ARCH="amd64"; GO_ARCH="${GO_ARCH:-linux-amd64}"; ARCH_TYPE="x64";;
  aarch64|arm64) ARCH="arm64"; GO_ARCH="${GO_ARCH:-linux-arm64}"; ARCH_TYPE="aarch64";;
  *) warn "Unknown architecture: $ARCH — using amd64 as fallback"; ARCH="amd64"; GO_ARCH="${GO_ARCH:-linux-amd64}"; ARCH_TYPE="x64";;
esac
info "Architecture: $ARCH ($ARCH_TYPE)"

# ── Package manager detection ────────────────────────────────────────────────
PKG_MANAGER=""
if command -v apt-get &>/dev/null; then PKG_MANAGER="apt"
elif command -v dnf &>/dev/null; then PKG_MANAGER="dnf"
elif command -v pacman &>/dev/null; then PKG_MANAGER="pacman"
elif command -v apk &>/dev/null; then PKG_MANAGER="apk"
elif command -v zypper &>/dev/null; then PKG_MANAGER="zypper"
elif command -v brew &>/dev/null; then PKG_MANAGER="brew"
fi
info "Package manager: ${PKG_MANAGER:-unknown}"

_pkg_install() {
  case "$PKG_MANAGER" in
    apt)    sudo apt-get install -y -qq "$@" 2>/dev/null ;;
    dnf)    sudo dnf install -y "$@" 2>/dev/null ;;
    pacman) sudo pacman -S --noconfirm "$@" 2>/dev/null ;;
    apk)    sudo apk add "$@" 2>/dev/null ;;
    zypper) sudo zypper install -y "$@" 2>/dev/null ;;
    brew)   brew install "$@" 2>/dev/null ;;
    *)      warn "No package manager found — install tools manually" ;;
  esac
}

_pkg_update() {
  case "$PKG_MANAGER" in
    apt) sudo apt-get update -qq 2>/dev/null ;;
    dnf) sudo dnf check-update 2>/dev/null || true ;;
    pacman) sudo pacman -Sy 2>/dev/null ;;
    apk) sudo apk update 2>/dev/null ;;
    zypper) sudo zypper refresh 2>/dev/null ;;
    brew) brew update 2>/dev/null ;;
  esac
}

_pkg_list() {
  case "$PKG_MANAGER" in
    apt)    echo "build-essential curl wget git software-properties-common apt-transport-https ca-certificates gnupg lsb-release unzip zip jq htop tree zsh fzf fd-find eza lazygit zoxide bat fonts-inter fonts-paratype netcat-openbsd bind9-dnsutils libcairo2-dev libpango1.0-dev libgdk-pixbuf-xlib-2.0-dev libffi-dev shared-mime-info ripgrep chromium-chromedriver postgresql-client redis-tools" ;;
    dnf)    echo "@development-tools curl wget git dnf-plugins-core ca-certificates gnupg2 unzip zip jq htop tree zsh fzf fd-find eza lazygit zoxide bat ripgrep" ;;
    pacman) echo "base-devel curl wget git ca-certificates gnupg unzip zip jq htop tree zsh fzf fd eza lazygit zoxide bat ripgrep" ;;
    apk)    echo "build-base curl wget git ca-certificates gnupg unzip zip jq htop tree zsh fzf fd eza lazygit zoxide bat ripgrep" ;;
    zypper) echo "-t pattern devel_basis curl wget git ca-certificates gnupg unzip zip jq htop tree zsh fzf fd eza lazygit zoxide bat ripgrep" ;;
    brew)   echo "curl wget git gnupg unzip jq htop tree zsh fzf fd eza lazygit zoxide bat ripgrep" ;;
  esac
}

# ── Mirror system — try primary, then RU-friendly fallbacks ─────────────────
_set_dns() {
  if [ -f /etc/resolv.conf ] && ! grep -q '77.88.8.8' /etc/resolv.conf 2>/dev/null; then
    echo "nameserver 77.88.8.8" | sudo tee -a /etc/resolv.conf >/dev/null 2>&1 || true
    echo "nameserver 77.88.8.1" | sudo tee -a /etc/resolv.conf >/dev/null 2>&1 || true
  fi
}

_install_ca_certs() {
  local ca_dir="/usr/local/share/ca-certificates/extra"
  _sudo mkdir -p "$ca_dir" 2>/dev/null || true
  local RUTUBE_CA="https://gu-st.ru/content/158/2020-12-30/2020-12-30-certificate.cer"
  local CF_CA="https://developers.cloudflare.com/ssl/static/origin_ca_rsa_root.pem"
  local installed=0
  if [ ! -f "$ca_dir/ru_digital.crt" ]; then
    curl -fsSL --connect-timeout 10 --max-time 30 "$RUTUBE_CA" 2>/dev/null | _sudo tee "$ca_dir/ru_digital.crt" >/dev/null 2>&1 && installed=1 || true
  fi
  if [ ! -f "$ca_dir/cloudflare_origin.crt" ]; then
    curl -fsSL --connect-timeout 10 --max-time 30 "$CF_CA" 2>/dev/null | _sudo tee "$ca_dir/cloudflare_origin.crt" >/dev/null 2>&1 && installed=1 || true
  fi
  if command -v update-ca-certificates &>/dev/null && [ "$installed" = "1" ]; then
    _sudo update-ca-certificates --fresh 2>/dev/null || true
  fi
}

_mirror_url() {
  local url
  for url in "$@"; do
    curl -fsSL --connect-timeout 5 --max-time 10 --resolve "$(echo "$url" | sed 's|https://||;s|/.*||'):443:77.88.8.8" "$url" -o /dev/null 2>/dev/null && { echo "$url"; return 0; }
    curl -fsSL --connect-timeout 5 --max-time 10 --resolve "$(echo "$url" | sed 's|https://||;s|/.*||'):443:1.1.1.1" "$url" -o /dev/null 2>/dev/null && { echo "$url"; return 0; }
    curl -fsSL --connect-timeout 5 --max-time 10 "$url" -o /dev/null 2>/dev/null && { echo "$url"; return 0; }
  done
  echo "$1"; return 1
}

# Comprehensive mirror list: primary → RU mirror → Chinese mirror → global fallback
GITHUB_MIRROR=$(_mirror_url \
  "https://github.com" \
  "https://ghproxy.com/https://github.com" \
  "https://github.com" 2>/dev/null || echo "https://github.com")

NPM_REGISTRY=$(_mirror_url \
  "https://registry.npmjs.org" \
  "https://registry.npmmirror.com" \
  "https://registry.yarnpkg.com" 2>/dev/null || echo "https://registry.npmjs.org")

PYPI_MIRROR=$(_mirror_url \
  "https://pypi.org/simple" \
  "https://mirror.yandex.ru/mirrors/pypi/simple" \
  "https://pypi.tuna.tsinghua.edu.cn/simple" 2>/dev/null || echo "https://pypi.org/simple")

DOCKER_MIRROR=$(_mirror_url \
  "https://hub.docker.com" \
  "https://mirror.yandex.ru/mirrors/docker" \
  "https://docker.mirrors.ustc.edu.cn" 2>/dev/null || echo "https://hub.docker.com")

GO_MIRROR=$(_mirror_url \
  "https://go.dev" \
  "https://goproxy.cn" \
  "https://goproxy.io" 2>/dev/null || echo "https://go.dev")

RUSTUP_MIRROR=$(_mirror_url \
  "https://static.rust-lang.org/rustup" \
  "https://mirrors.ustc.edu.cn/rust-static/rustup" \
  "https://rsproxy.cn/rustup" 2>/dev/null || echo "https://static.rust-lang.org/rustup")

ZIG_MIRROR=$(_mirror_url \
  "https://ziglang.org/download" \
  "https://mirrors.ustc.edu.cn/ziglang.org/download" 2>/dev/null || echo "https://ziglang.org/download")

JAVA_MIRROR=$(_mirror_url \
  "https://api.adoptium.net" \
  "https://mirror.yandex.ru/adoptium" 2>/dev/null || echo "https://api.adoptium.net")

export NPM_CONFIG_REGISTRY="$NPM_REGISTRY"
export PIP_INDEX_URL="$PYPI_MIRROR"
export GOPROXY="${GO_PROXY:-https://goproxy.cn,direct}"
export RUSTUP_DIST_SERVER="$RUSTUP_MIRROR"

# ── Progress tracking — resume after failure ────────────────────────────────
PROGRESS="$DL_CACHE/progress"
_step_skip() { grep -qxF "$1" "$PROGRESS" 2>/dev/null && { log "Skip: ${2:-$1} (completed earlier)"; return 0; }; return 1; }
_step_done() { [ "${DRY_RUN:-false}" = "true" ] && return 0; echo "$1" >> "$PROGRESS"; }

# ── WAL (Write-Ahead Log) checkpoint system ──────────────────────────────────
WAL_FILE="${HOME}/.cache/opencode-setup/wal.md"
WAL_MODULE_COUNT=0
_WAL_TOTAL="${WAL_TOTAL:-39}"

_wal_checkpoint() {
  local step_name="${1:-}"
  local module_key="${2:-}"
  [ "${DRY_RUN:-false}" = "true" ] && return 0
  WAL_MODULE_COUNT=$((WAL_MODULE_COUNT + 1))
  if [ -f "$WAL_FILE" ]; then
    local now
    now=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    sed -i "s|_Updated:.*|_Updated: ${now}|" "$WAL_FILE" 2>/dev/null || true
    sed -i "s|DONE: [0-9]\+/${_WAL_TOTAL}|DONE: ${WAL_MODULE_COUNT}/${_WAL_TOTAL}|" "$WAL_FILE" 2>/dev/null || true
    if [ -n "$step_name" ]; then
      sed -i "/^## Next Step/,/^$/{s|^- .*|- ${step_name}|}" "$WAL_FILE" 2>/dev/null || true
    fi
    # Mirror legacy progress for resume compatibility
    echo "$module_key" >> "$PROGRESS" 2>/dev/null || true
  fi
}

_wal_decide() {
  local decision="$1" rationale="${2:-}"
  [ "${DRY_RUN:-false}" = "true" ] && return 0
  if [ -f "$WAL_FILE" ]; then
    local entry
    if [ -n "$rationale" ]; then
      entry="- ${decision} — ${rationale}"
    else
      entry="- ${decision}"
    fi
    sed -i "/^## Recent Decisions/a ${entry}" "$WAL_FILE" 2>/dev/null || true
  fi
  log "Decision: $decision"
}

# ── Progress spinner for long operations ────────────────────────────────────
_spin() {
  local pid=$1 msg="${2:-Working}" i=0
  local spin='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
  while kill -0 "$pid" 2>/dev/null; do
    printf "\r  ${CYAN}%s${NC} %s" "${spin:$((i++ % 10)):1}" "$msg"
    sleep 0.1
  done
  printf "\r\033[K"
}

# ── MCP registry (used in install, health check, verification) ─────────────
declare -A MCP_PACKAGES=(
  [context7]="c7-mcp-server"
  [context7-official]="@upstash/context7-mcp"
  [filesystem]="@modelcontextprotocol/server-filesystem"
  [agentic-tools]="@pimzino/agentic-tools-mcp"
  [codegraph]="@colbymchenry/codegraph"
  [playwright]="@playwright/mcp"
  [agent-browser]="agent-browser-mcp-server"
  [loopsense]="@loopsense/mcp"
  [github]="@modelcontextprotocol/server-github"
  [postgres]="@modelcontextprotocol/server-postgres"
  [gitlab]="mcp-server-gitlab"
  [google-maps]="mcp-server-google-maps"
  [sequential-thinking]="@modelcontextprotocol/server-sequential-thinking"
  [memorylayer]="@scitrera/memorylayer-mcp-server"
  [chrome-devtools]="chrome-devtools-mcp"
  [memory]="@modelcontextprotocol/server-memory"
  [redis]="@modelcontextprotocol/server-redis"
  [brave-search]="brave-search-mcp"
  [sqlite]="mcp-server-sqlite"
  [excalidraw]="excalidraw-architect-mcp"
  [notion]="@notionhq/notion-mcp-server"
  [websearch]="mcp-searxng"
  [open-orchestra]="open-orchestra"
)
# NOTE: git, fetch, time MCPs are Python packages — installed via uvx/pip (not npm)
#       mcp-server-git, mcp-server-fetch, mcp-server-time on npm are security canaries!

# ── Interactive gate helper ─────────────────────────────────────────────────
_gate() {
  local flag_var="$1"
  if [ "$MODE" = "full" ] && [ -n "${INTERACTIVE_DO_SYSTEM:-}" ]; then
    local flag_val="${!flag_var}"
    [ "$flag_val" = "y" ] && return 0 || return 1
  fi
  return 0
}

# ── Dry-run mode ────────────────────────────────────────────────────────────
if [ "${DRY_RUN:-false}" = "true" ]; then
  _dry() { info "[DRY] $*"; return 0; }
else
  _dry() { "$@"; }
fi

# ── PATH exports ────────────────────────────────────────────────────────────
NPM_GLOBAL="$HOME/.npm-global"
N_PREFIX="$HOME/.n"
CORE_PATH="$NPM_GLOBAL/bin:$HOME/.local/bin:$HOME/.n/bin:$HOME/.bun/bin:$HOME/.cargo/bin:$HOME/.jbang/bin:$HOME/.dotnet:$HOME/go/bin:/usr/local/go/bin"
export PATH="$CORE_PATH:$PATH"
export N_PREFIX="$N_PREFIX"
npm config set prefix "$NPM_GLOBAL" 2>/dev/null || true
OPENCODE_VER="${OPENCODE_VER:-latest}"

# ── Version pinning (R13: Reproducibility) ──────────────────────────────────
# All tool versions are pinned here for reproducible installs.
# Override via env vars or setup.conf if needed.
NODE_VER="${NODE_VER:-24}"
PYTHON_VER="${PYTHON_VER:-3.14}"
GO_VER="${GO_VER:-1.26}"
RUST_VER="${RUST_VER:-1.96}"
JAVA_VER="${JAVA_VER:-25}"
DOTNET_VER="${DOTNET_VER:-10}"
ZIG_VER="${ZIG_VER:-0.15.1}"
BUN_VER="${BUN_VER:-1.3}"
OPENCODE_CLI_VER="${OPENCODE_CLI_VER:-1.17}"
export NODE_VER PYTHON_VER GO_VER RUST_VER JAVA_VER DOTNET_VER ZIG_VER BUN_VER OPENCODE_CLI_VER

# ── Isolated Circuit Mode ────────────────────────────────────────────────────
# When enabled, all LLM providers use local OpenAI-compatible servers.
# Set via: --isolated flag, ISOLATED_CIRCUIT=true in setup.conf, or env var.
ISOLATED_CIRCUIT="${ISOLATED_CIRCUIT:-}"
[ -z "$ISOLATED_CIRCUIT" ] && [ -f "$HOME/.config/opencode-setup/setup.conf" ] && \
  . "$HOME/.config/opencode-setup/setup.conf" 2>/dev/null && \
  ISOLATED_CIRCUIT="${ISOLATED_CIRCUIT:-}"
[ -z "$ISOLATED_CIRCUIT" ] && ISOLATED_CIRCUIT="${OPencode_ISOLATED_CIRCUIT:-}"
[ -z "$ISOLATED_CIRCUIT" ] && ISOLATED_CIRCUIT="false"
case "${ISOLATED_CIRCUIT,,}" in true|1|yes|on|enabled) ISOLATED_CIRCUIT="true";; *) ISOLATED_CIRCUIT="false";; esac
export ISOLATED_CIRCUIT

# ── i18n: Russian CLI output if LANG=ru* (R18: Accessibility) ───────────────
CLI_LANG="${CLI_LANG:-${LANG:-}}"
case "$CLI_LANG" in ru*) CLI_LANG="ru";; *) CLI_LANG="en";; esac
export CLI_LANG

OPencode_LOCAL_ENDPOINT="${OPencode_LOCAL_ENDPOINT:-http://localhost:4000/v1}"
export OPencode_LOCAL_ENDPOINT
