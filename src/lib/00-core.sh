#!/usr/bin/env bash
# src/lib/00-core.sh — core infrastructure shared across all lib modules
# Sources: src/lib/helpers.sh must be sourced before this file
# shellcheck disable=SC2034  # variables used by sourced modules
set -euo pipefail

# ── Version ──────────────────────────────────────────────────────────────────
SCRIPT_VERSION="${SCRIPT_VERSION:-v1.0.0}"

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
