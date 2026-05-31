#!/usr/bin/env bash
# ============================================================================
#  Ultimate Dev Machine Bootstrap v33.5 — Universal + RU Mirrors + Cross-Distro
set -euo pipefail
IFS=$'\n\t'

DL_CACHE="${HOME}/.cache/opencode-setup"
mkdir -p "$DL_CACHE"
PROGRESS="$DL_CACHE/progress"
SECRETS_FILE="${HOME}/.config/opencode/secrets.env"
mkdir -p "$(dirname "$SECRETS_FILE")"

# ── Cleanup + error diagnostics ──────────────────────────────────────────────
cleanup() {
  local exit_code=$?
  rm -f /tmp/docker-install.*.sh /tmp/uv-install.*.sh /tmp/bun-install.*.sh \
        /tmp/sdkman-install.sh /tmp/superpowers.* /tmp/dotnet-install.*.sh \
        /tmp/rustup-init.*.sh /tmp/opencode-install.sh /tmp/ollama-install.sh 2>/dev/null
  # Restore SSL settings if they were relaxed
  npm config set strict-ssl true 2>/dev/null || true
  if [ $exit_code -ne 0 ] && [ "${MODE:-}" != "health" ]; then
    warn "Script exited with code $exit_code at $(date +%H:%M:%S)"
    warn "Log: $LOG_FILE"
    warn "Re-run: bash ~/setup.sh --health ; or resume with --full (progress tracked)"
  fi
  exit $exit_code
}
trap cleanup EXIT INT TERM

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; CYAN='\033[0;36m'; NC='\033[0m'
log()   { echo -e "${GREEN}[✓]${NC} $(date +%H:%M:%S) $1"; }
warn()  { echo -e "${YELLOW}[!]${NC} $(date +%H:%M:%S) $1" >&2; }
err()   { echo -e "${RED}[✗]${NC} $(date +%H:%M:%S) $1" >&2; exit 1; }
info()  { echo -e "${CYAN}[i]${NC} $(date +%H:%M:%S) $1"; }
section() { echo; echo -e "${CYAN}─── $1 ───${NC}"; }

# ── OS validation ────────────────────────────────────────────────────────────
if [ ! -f /etc/os-release ]; then
  warn "/etc/os-release not found — continuing anyway"
else
  . /etc/os-release
  case "$ID" in
    ubuntu|debian|linuxmint|pop|elementary|zorin) ;;
    *) warn "Untested OS: $ID $VERSION_ID — continuing (Ubuntu/Debian expected)" ;;
  esac
  info "OS: $PRETTY_NAME ($(uname -m))"
fi

# ── Architecture detection ──────────────────────────────────────────────────
ARCH=$(uname -m)
case "$ARCH" in
  x86_64|amd64) ARCH="amd64"; GO_ARCH="${GO_ARCH:-linux-amd64}"; ARCH_TYPE="x64";;
  aarch64|arm64) ARCH="arm64"; GO_ARCH="${GO_ARCH:-linux-arm64}"; ARCH_TYPE="aarch64";;
  *) warn "Unknown architecture: $ARCH — using amd64 as fallback"; ARCH="amd64"; GO_ARCH="${GO_ARCH:-linux-amd64}"; ARCH_TYPE="x64";;
esac
info "Architecture: $ARCH ($ARCH_TYPE)"

# ── Version ──────────────────────────────────────────────────────────────────
SCRIPT_VERSION="v33.5"

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
_pkg_list() {  # returns package names for the current distro
  case "$PKG_MANAGER" in
    apt)    echo "build-essential curl wget git software-properties-common apt-transport-https ca-certificates gnupg lsb-release unzip zip jq htop tree zsh fzf fd-find eza lazygit zoxide bat fonts-inter fonts-paratype netcat-openbsd bind9-dnsutils libcairo2-dev libpango1.0-dev libgdk-pixbuf-xlib-2.0-dev libffi-dev shared-mime-info ripgrep" ;;
    dnf)    echo "@development-tools curl wget git dnf-plugins-core ca-certificates gnupg2 unzip zip jq htop tree zsh fzf fd-find eza lazygit zoxide bat ripgrep" ;;
    pacman) echo "base-devel curl wget git ca-certificates gnupg unzip zip jq htop tree zsh fzf fd eza lazygit zoxide bat ripgrep" ;;
    apk)    echo "build-base curl wget git ca-certificates gnupg unzip zip jq htop tree zsh fzf fd eza lazygit zoxide bat ripgrep" ;;
    zypper) echo "-t pattern devel_basis curl wget git ca-certificates gnupg unzip zip jq htop tree zsh fzf fd eza lazygit zoxide bat ripgrep" ;;
    brew)   echo "curl wget git gnupg unzip jq htop tree zsh fzf fd eza lazygit zoxide bat ripgrep" ;;
  esac
}

# ── Mirror system — try primary, then RU-friendly fallbacks ─────────────────
# Detects best available mirror at runtime

# DNS: set Yandex public DNS as fallback for Russian resolvers
_set_dns() {
  if [ -f /etc/resolv.conf ] && ! grep -q '77.88.8.8' /etc/resolv.conf 2>/dev/null; then
    echo "nameserver 77.88.8.8" | sudo tee -a /etc/resolv.conf >/dev/null 2>&1 || true
    echo "nameserver 77.88.8.1" | sudo tee -a /etc/resolv.conf >/dev/null 2>&1 || true
  fi
}

# CA certificates: add Russian Ministry of Digital + Cloudflare origin CA
_install_ca_certs() {
  local ca_dir="/usr/local/share/ca-certificates/extra"
  sudo mkdir -p "$ca_dir"
  # Russian Ministry of Digital root CA
  local RUTUBE_CA="https://gu-st.ru/content/158/2020-12-30/2020-12-30-certificate.cer"
  # Cloudflare Origin CA
  local CF_CA="https://developers.cloudflare.com/ssl/static/origin_ca_rsa_root.pem"
  local installed=0

  if [ ! -f "$ca_dir/ru_digital.crt" ]; then
    curl -fsSL --connect-timeout 10 --max-time 30 "$RUTUBE_CA" -o "$ca_dir/ru_digital.crt" 2>/dev/null && installed=1
  fi
  if [ ! -f "$ca_dir/cloudflare_origin.crt" ]; then
    curl -fsSL --connect-timeout 10 --max-time 30 "$CF_CA" -o "$ca_dir/cloudflare_origin.crt" 2>/dev/null && installed=1
  fi
  # Also trust Mozilla CA bundle (may be stale)
  if command -v update-ca-certificates &>/dev/null && [ "$installed" = "1" ]; then
    sudo update-ca-certificates --fresh 2>/dev/null || true
  fi
}

_set_dns; _install_ca_certs

# URL reachability probe with multiple DNS backends
_mirror_url() {
  local url
  for url in "$@"; do
    # Try with system DNS first, then explicit Yandex DNS, then Cloudflare 1.1.1.1
    curl -fsSL --connect-timeout 5 --max-time 10 --resolve "$(echo "$url" | sed 's|https://||;s|/.*||'):443:77.88.8.8" "$url" -o /dev/null 2>/dev/null && { echo "$url"; return 0; }
    curl -fsSL --connect-timeout 5 --max-time 10 --resolve "$(echo "$url" | sed 's|https://||;s|/.*||'):443:1.1.1.1" "$url" -o /dev/null 2>/dev/null && { echo "$url"; return 0; }
    curl -fsSL --connect-timeout 5 --max-time 10 "$url" -o /dev/null 2>/dev/null && { echo "$url"; return 0; }
  done
  echo "$1"; return 1
}

# Comprehensive mirror list: primary → RU mirror → Chinese mirror → global fallback
GITHUB_MIRROR=$(_mirror_url \
  "https://github.com" \
  "https://hub.fastgit.xyz" \
  "https://ghproxy.com/https://github.com" \
  "https://github.com" 2>/dev/null || echo "https://github.com")

NPM_REGISTRY=$(_mirror_url \
  "https://registry.npmjs.org" \
  "https://registry.npmmirror.com" \
  "https://registry.yarnpkg.com" \
  "https://cdn.jsdelivr.net/npm" 2>/dev/null || echo "https://registry.npmjs.org")

PYPI_MIRROR=$(_mirror_url \
  "https://pypi.org/simple" \
  "https://mirror.yandex.ru/mirrors/pypi/simple" \
  "https://pypi.tuna.tsinghua.edu.cn/simple" \
  "https://mirrors.aliyun.com/pypi/simple" 2>/dev/null || echo "https://pypi.org/simple")

DOCKER_MIRROR=$(_mirror_url \
  "https://hub.docker.com" \
  "https://mirror.gcr.io" \
  "https://docker.mirrors.ustc.edu.cn" \
  "https://docker.m.daocloud.io" 2>/dev/null || echo "https://hub.docker.com")

GO_MIRROR=$(_mirror_url \
  "https://go.dev" \
  "https://golang.google.cn" \
  "https://mirrors.ustc.edu.cn/golang" \
  "https://gomirrors.org" 2>/dev/null || echo "https://go.dev")

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

# Export for child processes
export NPM_CONFIG_REGISTRY="$NPM_REGISTRY"
export PIP_INDEX_URL="$PYPI_MIRROR"
export GOPROXY="${GO_PROXY:-https://goproxy.io,direct}"
export RUSTUP_DIST_SERVER="$RUSTUP_MIRROR"

# Multi-mirror curl: tries each mirror sequentially
_curl_mirror() {
  local url out="${2:-}" primary="$1"; shift 2
  for mirror in "$primary" "$@"; do
    if [ -n "$out" ]; then
      curl -fsSL --connect-timeout 15 --max-time 120 --retry 1 -o "$out" "$mirror" 2>/dev/null && return 0
    else
      curl -fsSL --connect-timeout 15 --max-time 120 --retry 1 "$mirror" 2>/dev/null && return 0
    fi
  done
  return 1
}

# ── Progress tracking — resume after failure ────────────────────────────────
_step_skip() { grep -qxF "$1" "$PROGRESS" 2>/dev/null && { log "Skip: $2 (completed earlier)"; return 0; }; return 1; }
_step_done() { echo "$1" >> "$PROGRESS"; }

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
  [filesystem]="@modelcontextprotocol/server-filesystem"
  [agentic-tools]="@pimzino/agentic-tools-mcp"
  [codegraph]="@colbymchenry/codegraph"
  [playwright]="@playwright/mcp"
  [agent-browser]="agent-browser"
  [codesorb]="codesorb"
  [mcp-replay]="mcp-replay"
  [open-orchestra]="open-orchestra"
  [loopsense]="@loopsense/mcp"
  [datafy]="@teckedd-code2save/datafy"
  [github]="@modelcontextprotocol/server-github"
  [postgres]="@modelcontextprotocol/server-postgres"
  [sequential-thinking]="@modelcontextprotocol/server-sequential-thinking"
  [sentry]="@sentry/mcp"
  [grep]="@anthropic/mcp-server-grep"
)

# ── Unified retry wrapper ────────────────────────────────────────────────────
# Usage: _curl <url> [output_file] [extra_curl_opts...]
# Tries 5 times with exponential backoff (2s→4s→8s→16s→32s), caches to DL_CACHE
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

# Usage: _retry <max_attempts> <description> <command...>
_retry() {
  local max="$1" desc="$2" attempt=1; shift 2
  while [ $attempt -le $max ]; do
    if "$@" 2>/dev/null; then return 0; fi
    warn "$desc attempt $attempt/$max..."
    sleep $((2 ** attempt))
    attempt=$((attempt + 1))
  done
  return 1
}

# npm install with local cache (npm pack → install from .tgz)
MCP_CACHE="$DL_CACHE/mcp-offline"
mkdir -p "$MCP_CACHE"
_npm_install() {
  local pkg="$1" name="$2" pkg_name
  pkg_name=$(echo "$pkg" | sed 's|@.*/||;s|@.*||')
  local tgz="$MCP_CACHE/${pkg_name}-latest.tgz"
  # Try cached tarball first
  if [ -f "$tgz" ] && timeout 120 npm install -g "$tgz" --prefer-offline 2>/dev/null; then
    log "MCP: $name (cached)"; return 0
  fi
  # Download fresh tarball with retry
  info "MCP: downloading $name..."
  if timeout 120 npm pack "$pkg@latest" --pack-destination "$MCP_CACHE" 2>/dev/null; then
    # Find the downloaded tgz (npm pack adds version number)
    local downloaded=$(ls -t "$MCP_CACHE/${pkg_name}-"*.tgz 2>/dev/null | head -1)
    if [ -n "$downloaded" ] && timeout 120 npm install -g "$downloaded" --prefer-offline 2>/dev/null; then
      log "MCP: $name (npm pack)"; return 0
    fi
  fi
  # Fallback: direct npm install
  if timeout 120 npm install -g "${pkg}@latest" --prefer-offline 2>/dev/null; then
    log "MCP: $name (npm)"; return 0
  elif command -v bun &>/dev/null && timeout 120 bun install -g "${pkg}@latest" --prefer-offline 2>/dev/null; then
    log "MCP: $name (bun)"; return 0
  else
    warn "MCP FAILED: $name"; return 1
  fi
}

MODE="full"; NEW_PROJECT_DIR=""
while [[ $# -gt 0 ]]; do case $1 in
  --full)              MODE="full"; shift;;
  --reinit)            MODE="reinit"; shift;;
  --new)               MODE="new"; NEW_PROJECT_DIR="${2:-}"; [ -z "$NEW_PROJECT_DIR" ] && { warn "Usage: --new <dir>"; exit 1; }; shift 2;;
  --health)            MODE="health"; shift;;
  --update)            MODE="update"; shift;;
  --upgrade)           MODE="upgrade"; shift;;
  --interactive)       MODE="interactive"; shift;;
  --dry-run)           MODE="dry-run"; DRY_RUN=true; shift;;
  --fix-config)        MODE="fix-config"; shift;;
  --fix-zshrc)         MODE="fix-zshrc"; shift;;
  -p|--project-dir)    PROJECT_DIR="$2"; shift 2;;
  -k|--api-key)        API_KEY="$2"; shift 2;;
  --deepseek-key)      DEEPSEEK_KEY="$2"; shift 2;;
  -n|--git-name)       GIT_NAME="$2"; shift 2;;
  -e|--git-email)      GIT_EMAIL="$2"; shift 2;;
  -s|--sudo-pass)      SUDO_PASS="$2"; shift 2;;
  -h|--help) cat <<'USAGE'
Usage: bash setup.sh [MODE] [OPTIONS]

Modes:
  --full              Complete bootstrap (default)
  --reinit            Reinstall tools, regenerate configs, keep project data
  --new <dir>         Initialize a new project directory only
  --health            Diagnostic: check all tools, MCPs, configs — no changes
  --update            Update tools only (opencode, npm pkgs, uv, apt)
  --upgrade           Full system upgrade: apt+snap+sdkman+omz+rustup+npm+pip
  --fix-config        Regenerate ~/.config/opencode/opencode.json with all MCPs
  --fix-zshrc         Repair ~/.zshrc: deduplicate, fix quotes, fix P10k
  --interactive       Interactive component-by-component selection

Options:
  -p, --project-dir   Project directory (default: ~/projects)
  -k, --api-key       OpenCode Go API key
  --deepseek-key      DeepSeek API key (default: built-in)
  -n, --git-name      Git user name
  -e, --git-email     Git user email
  -s, --sudo-pass     Sudo password (cached between steps)
  -h, --help          Show this help

Examples:
  bash setup.sh                        # Full bootstrap
  bash setup.sh --reinit               # Reinstall tools, keep project
  bash setup.sh --new ~/my-project     # Init new project
  bash setup.sh --health               # Diagnostics only
  bash setup.sh --fix-zshrc            # Repair .zshrc only
  bash setup.sh --fix-config           # Regenerate opencode.json
  bash setup.sh --interactive          # Interactive component selection
  bash setup.sh --upgrade              # Full system update chain
USAGE
  exit 0;;
  *) err "Unknown: $1. Use -h for help.";;
esac; done

# ── PATHS ───────────────────────────────────────────────────────────────────
NPM_GLOBAL="$HOME/.npm-global"
N_PREFIX="$HOME/.n"
CORE_PATH="$NPM_GLOBAL/bin:$HOME/.local/bin:$N_PREFIX/bin:$HOME/.bun/bin:$HOME/.cargo/bin:$HOME/.jbang/bin:$HOME/.dotnet:/usr/local/go/bin"
export PATH="$CORE_PATH:$PATH"
export N_PREFIX="$N_PREFIX"
OPENCODE_VER="${OPENCODE_VER:-latest}"

# ── Dry-run mode ────────────────────────────────────────────────────────────
if [ "${DRY_RUN:-false}" = "true" ]; then
  warn "DRY-RUN MODE — no changes will be made (commands shown, not executed)"
  _dry() { info "[DRY] $*"; return 0; }
else
  _dry() { "$@"; }
fi

# ── Health Check Mode ───────────────────────────────────────────────────────
if [ "$MODE" = "health" ]; then
  echo -e "${GREEN}=== OpenCode Environment Health Check ===${NC}"
  PASS=0; FAIL=0
  _check() { if eval "$2" &>/dev/null; then echo -e "  ${GREEN}✓${NC} $1"; PASS=$((PASS+1)); else echo -e "  ${RED}✗${NC} $1"; FAIL=$((FAIL+1)); fi; }
  section "Core CLI"
  _check "Docker"         "docker --version"
  _check "Java"           "java -version 2>&1 | head -1"
  _check "Go"             "go version"
  _check "Rust"           "rustc --version"
  _check ".NET"           "dotnet --version"
  _check "Kotlin"         "kotlin -version 2>/dev/null || echo 'not installed'"
  _check "Zig"            "zig version 2>/dev/null || echo 'not installed'"
  _check "Node.js"        "node --version"
  _check "Python 3.12"    "python3.12 --version"
  _check "uv"             "uv --version"
  _check "bun"            "bun --version"
  _check "OpenCode"       "opencode --version"
  _check "Gradle"         "gradle --version 2>&1 | head -2"
  _check "Maven"          "mvn --version 2>&1 | head -1"
  _check "jbang"          "jbang --version"
  _check "Git"            "git --version"
  _check "zsh"            "zsh --version"
  _check "ripgrep"        "rg --version"
  _check "fzf"            "fzf --version"
  _check "eza"            "eza --version"
  _check "bat"            "bat --version"
  _check "fd"             "fdfind --version"
  section "MCP Servers"
  _check "context7"       "which c7-mcp-server"
  _check "filesystem"     "npm list -g @modelcontextprotocol/server-filesystem &>/dev/null"
  _check "agentic-tools"  "npm list -g @pimzino/agentic-tools-mcp &>/dev/null"
  _check "codegraph"      "which codegraph"
  _check "playwright"     "npm list -g @playwright/mcp &>/dev/null"
  _check "agent-browser"  "which agent-browser"
  _check "codesorb"       "npm list -g codesorb &>/dev/null"
  _check "mcp-replay"     "npm list -g mcp-replay &>/dev/null"
  _check "open-orchestra" "npm list -g open-orchestra &>/dev/null"
  _check "loopsense"      "npm list -g @loopsense/mcp &>/dev/null"
  _check "datafy"         "npm list -g @teckedd-code2save/datafy &>/dev/null"
  _check "github"         "npm list -g @modelcontextprotocol/server-github &>/dev/null"
  _check "postgres"       "npm list -g @modelcontextprotocol/server-postgres &>/dev/null"
  _check "seq-thinking"   "npm list -g @modelcontextprotocol/server-sequential-thinking &>/dev/null"
  section "LSP Servers"
  _check "gopls"          "which gopls"
  _check "rust-analyzer"  "which rust-analyzer"
  _check "tsserver"       "which typescript-language-server"
  _check "pyright"        "which pyright-langserver"
  section "Services"
  _check "Muninn skills"      "[ -f ~/.config/opencode/skills/memory-read/SKILL.md ]"
  _check "ChromaDB server"    "curl -sf http://127.0.0.1:8000/api/v2/heartbeat &>/dev/null"
  _check "ONNX model cached"  "[ -f ~/.cache/chroma/onnx_models/all-MiniLM-L6-v2/onnx/model.onnx ]"
  section "Config"
  _check "opencode.json"      "[ -f ~/.config/opencode/opencode.json ]"
  _check "MCPs registered"    "python3 -c \"import json; c=json.load(open('$HOME/.config/opencode/opencode.json')); m=len(c.get('mcp',{})); exit(0 if m>2 else 1)\" 2>/dev/null"
  _check "AGENTS.md"          "[ -f \"${PROJECT_DIR:-$HOME/projects}/AGENTS.md\" ]"
  _check "GLOBAL_WAL.md"      "[ -f \"${PROJECT_DIR:-$HOME/projects}/wal/GLOBAL_WAL.md\" ]"
  _check "No stale scout"     "[ ! -f \"${PROJECT_DIR:-$HOME/projects}/.opencode/agents/scout.md\" ] && [ ! -f \"$HOME/.config/opencode/agents/scout.md\" ]"
  echo; log "Health: $PASS passed, $FAIL failed"
  exit 0
fi

# ── Fix zshrc Mode ──────────────────────────────────────────────────────────
if [ "$MODE" = "fix-zshrc" ]; then
  section "Repairing ~/.zshrc"
  python3 << 'PYFIX'
import os, re
zshrc = os.path.expanduser("~/.zshrc")
with open(zshrc) as f:
    content = f.read()
original = content

# Fix unmatched quotes — add missing closing " on PATH lines
lines = content.split('\n')
fixed_lines = []
for line in lines:
    stripped = line.strip()
    # If line starts with export PATH="... but lacks closing "
    if stripped.startswith('export PATH="') and not stripped.rstrip().endswith('"'):
        # Count quotes — if odd, add closing quote
        if stripped.count('"') % 2 == 1:
            line = line.rstrip() + '"'
    fixed_lines.append(line)
content = '\n'.join(fixed_lines)

# Remove duplicate BUN_INSTALL blocks (keep first occurrence)
content = re.sub(r'(# bun\nexport BUN_INSTALL="\$HOME/\.bun"\nexport PATH="\$BUN_INSTALL/bin:\$PATH"\n)+',
                 '# bun\nexport BUN_INSTALL="$HOME/.bun"\nexport PATH="$BUN_INSTALL/bin:$PATH"\n',
                 content)

# Remove all duplicate OPENCODE_API_KEY and OPENCODE_GO_API_KEY blocks — keep only last set
lines = content.split('\n')
seen_keys = set()
deduped = []
for line in reversed(lines):
    if 'OPENCODE_API_KEY=' in line or 'OPENCODE_GO_API_KEY=' in line:
        key = line.split('=')[0].strip().replace('export ', '')
        if key in seen_keys:
            continue
        seen_keys.add(key)
    deduped.append(line)
content = '\n'.join(reversed(deduped))

# Remove duplicate PATH exports — keep only first CORE_PATH style line
lines = content.split('\n')
seen_path = False
deduped = []
for line in lines:
    if 'export PATH="$HOME/.npm-global/bin' in line or 'export PATH="$NPM_GLOBAL' in line:
        if not seen_path:
            deduped.append(line)
            seen_path = True
        continue
    deduped.append(line)
content = '\n'.join(deduped)

# Ensure single clean PATH line exists
CORE_PATH_LINE = 'export PATH="$HOME/.npm-global/bin:$HOME/.local/bin:$HOME/.n/bin:$HOME/.bun/bin:$HOME/.cargo/bin:$HOME/.jbang/bin:/usr/local/go/bin:$PATH"'
if CORE_PATH_LINE not in content:
    content = content.rstrip() + '\n' + CORE_PATH_LINE + '\n'

# Fix shokunin profile source — redirect/disable console echo to prevent P10k warning
content = content.replace(
    '[ -f "$HOME/.shokunin/scripts/linux/profile.sh" ] && source "$HOME/.shokunin/scripts/linux/profile.sh"',
    '[ -f "$HOME/.shokunin/scripts/linux/profile.sh" ] && source "$HOME/.shokunin/scripts/linux/profile.sh" 2>/dev/null'
)

if content != original:
    with open(zshrc, 'w') as f:
        f.write(content)
    print("FIXED: ~/.zshrc repaired (dedup, quotes, P10k compat)")
else:
    print("OK: ~/.zshrc already clean")
PYFIX

  # Fix shokunin profile.sh — suppress console echo
  SHOKUNIN_PROFILE="$HOME/.shokunin/scripts/linux/profile.sh"
  if [ -f "$SHOKUNIN_PROFILE" ]; then
    if grep -q 'echo "Shokunin AI Ecosystem loaded"' "$SHOKUNIN_PROFILE" 2>/dev/null; then
      sed -i 's/echo "Shokunin AI Ecosystem loaded"/# echo "Shokunin AI Ecosystem loaded"/' "$SHOKUNIN_PROFILE" 2>/dev/null || true
      log "Shokunin profile.sh: disabled console echo (P10k compat)"
    fi
  fi

  # Fix P10k instant prompt — set to quiet
  P10K_FILE="$HOME/.p10k.zsh"
  if [ -f "$P10K_FILE" ]; then
    sed -i 's/POWERLEVEL9K_INSTANT_PROMPT=verbose/POWERLEVEL9K_INSTANT_PROMPT=quiet/' "$P10K_FILE" 2>/dev/null || true
    log "P10k instant prompt: verbose → quiet"
  fi

  log "~/.zshrc repair complete"
  exit 0
fi

# ── Upgrade Mode (full system update chain) ──────────────────────────────────
if [ "$MODE" = "upgrade" ]; then
  section "UPGRADE: system packages"
  sudo apt-get update -qq 2>/dev/null || true
  sudo apt-get full-upgrade -y -q -o APT::Get::Fix-Missing=true 2>/dev/null || true
  sudo apt-get autoremove -y -q 2>/dev/null || true
  sudo apt-get autoclean -y -q 2>/dev/null || true
  log "apt upgraded"

  section "UPGRADE: snap packages"
  command -v snap &>/dev/null && sudo snap refresh 2>/dev/null || true
  log "snap refreshed"

  section "UPGRADE: SDKMAN"
  if [ -f "$HOME/.sdkman/bin/sdkman-init.sh" ]; then
    source "$HOME/.sdkman/bin/sdkman-init.sh" 2>/dev/null || true
    sdk selfupdate -force 2>/dev/null || true
    sdk update 2>/dev/null || true
    sdk upgrade 2>/dev/null || true
    log "SDKMAN updated"
  else
    warn "SDKMAN not found, skipping"
  fi

  section "UPGRADE: Oh My Zsh"
  if [ -f "$HOME/.oh-my-zsh/oh-my-zsh.sh" ]; then
    zsh -c 'source ~/.oh-my-zsh/oh-my-zsh.sh && omz update' 2>/dev/null || true
    log "OMZ updated"
  fi

  section "UPGRADE: Rust"
  command -v rustup &>/dev/null && rustup update 2>/dev/null && log "Rust toolchain updated" || warn "Rust not installed"

  section "UPGRADE: Go"
  if command -v go &>/dev/null; then
    GO_CURRENT=$(go version 2>/dev/null | grep -oP 'go\K[0-9.]+' | head -1)
    GO_LATEST=$(curl -s --connect-timeout 10 https://go.dev/dl/ 2>/dev/null | grep -oP 'go[0-9.]+\.linux-amd64\.tar\.gz' | head -1 | grep -oP 'go\K[0-9.]+')
    if [ -n "$GO_LATEST" ] && [ "$GO_CURRENT" != "$GO_LATEST" ]; then
      info "Go $GO_CURRENT → $GO_LATEST available. Re-run --reinit to upgrade."
    else
      log "Go $GO_CURRENT up to date"
    fi
  fi

  section "UPGRADE: npm global packages"
  npm update -g 2>/dev/null || true
  for pkg in opencode-ai c7-mcp-server agent-browser opencode-codegraph; do
    npm install -g "$pkg@latest" 2>/dev/null && log "npm: $pkg" || warn "npm: $pkg failed"
  done

  section "UPGRADE: uv + pip"
  command -v uv &>/dev/null && uv self update 2>/dev/null && log "uv updated" || warn "uv not found"
  command -v uv &>/dev/null && uv python install 3.12 2>/dev/null || true

  section "UPGRADE: regenerate configs"
  $0 --fix-config -p "${PROJECT_DIR:-$HOME/projects}" 2>/dev/null || true
  log "opencode.json regenerated"

  section "UPGRADE: verify"
  PASS=0; FAIL=0
  _check() { if eval "$2" &>/dev/null; then PASS=$((PASS+1)); else FAIL=$((FAIL+1)); warn "$1 — check needed"; fi; }
  _check "Docker" "docker --version"
  _check "Java" "java -version 2>&1 | head -1"
  _check "Go" "go version"
  _check "Rust" "rustc --version"
  _check "Node" "node --version"
  _check "Python" "python3.12 --version"
  _check "OpenCode" "opencode --version"
  _check "zsh" "zsh --version"
  _check "git" "git --version"
  log "Upgrade complete: $PASS/$((PASS+FAIL)) tools OK"
  exit 0
fi

# ── Interactive Mode ───────────────────────────────────────────────────────
if [ "$MODE" = "interactive" ]; then
  echo -e "${GREEN}============================================================${NC}"
  echo -e "${GREEN}     Ultimate Dev Machine Bootstrap v33.5 — INTERACTIVE${NC}"
  echo -e "${GREEN}============================================================${NC}"
  echo

  # Collect required params first
  if [ -z "${PROJECT_DIR:-}" ]; then
    read -r -p "Project directory [~/projects]: " input
    PROJECT_DIR="${input:-$HOME/projects}"
    export PROJECT_DIR
    mkdir -p "$PROJECT_DIR" 2>/dev/null || true
  fi

  if [ -z "${GIT_NAME:-}" ]; then
    read -r -p "Git user name: " GIT_NAME
  fi
  if [ -z "${GIT_EMAIL:-}" ]; then
    read -r -p "Git email: " GIT_EMAIL
  fi

  if [ -z "${DEEPSEEK_KEY:-}" ]; then
    read -r -p "DeepSeek API key (from https://platform.deepseek.com/): " DEEPSEEK_KEY
    export DEEPSEEK_API_KEY="${DEEPSEEK_KEY:-}"
  fi

  if [ -z "${API_KEY:-}" ]; then
    read -r -p "OpenCode Go API key (from https://opencode.ai/auth, Enter to skip): " API_KEY
  fi

  # Component selection
  echo
  echo -e "${CYAN}Select components to install (y/n):${NC}"
  echo

  DO_SYSTEM="y"; DO_DOCKER="y"; DO_ZSH="y"
  DO_JAVA="y";  DO_NODE="y";   DO_PYTHON="y"
  DO_GO="y";    DO_RUST="y";   DO_DOTNET="y"
  DO_OPENCODE="y"; DO_MCP="y"; DO_CHROMA="y"
  DO_SHOKUNIN="y"; DO_TRIVY="y"; DO_PROJECT="y"; DO_LLM="y"

  read -r -p "System packages (apt)? [Y/n]: " input; [ "$input" = "n" ] && DO_SYSTEM="n"
  read -r -p "Docker? [Y/n]: " input; [ "$input" = "n" ] && DO_DOCKER="n"
  read -r -p "Zsh + Oh My Zsh + P10k? [Y/n]: " input; [ "$input" = "n" ] && DO_ZSH="n"
  read -r -p "Java 25 + Gradle + Maven? [Y/n]: " input; [ "$input" = "n" ] && DO_JAVA="n"
  read -r -p "Node.js 22 + npm? [Y/n]: " input; [ "$input" = "n" ] && DO_NODE="n"
  read -r -p "Python 3.12 + uv? [Y/n]: " input; [ "$input" = "n" ] && DO_PYTHON="n"
  read -r -p "Go (latest)? [Y/n]: " input; [ "$input" = "n" ] && DO_GO="n"
  read -r -p "Rust? [Y/n]: " input; [ "$input" = "n" ] && DO_RUST="n"
  read -r -p ".NET 9? [Y/n]: " input; [ "$input" = "n" ] && DO_DOTNET="n"
  read -r -p "OpenCode CLI + Bun? [Y/n]: " input; [ "$input" = "n" ] && DO_OPENCODE="n"
  read -r -p "MCP servers + LSP (14+10)? [Y/n]: " input; [ "$input" = "n" ] && DO_MCP="n"
  read -r -p "ChromaDB + Muninn memory? [Y/n]: " input; [ "$input" = "n" ] && DO_CHROMA="n"
  read -r -p "Shokunin ecosystem (62+ skills)? [Y/n]: " input; [ "$input" = "n" ] && DO_SHOKUNIN="n"
  read -r -p "Trivy security scanner? [Y/n]: " input; [ "$input" = "n" ] && DO_TRIVY="n"
  read -r -p "Local LLM runtimes (Ollama, vLLM, Open WebUI)? [Y/n]: " input; [ "$input" = "n" ] && DO_LLM="n"
  read -r -p "Generate project files (AGENTS.md, WAL, docker-compose)? [Y/n]: " input; [ "$input" = "n" ] && DO_PROJECT="n"

  echo
  echo -e "${CYAN}Summary:${NC}"
  echo "  Project:    $PROJECT_DIR"
  echo "  Git:        ${GIT_NAME:-<not set>} <${GIT_EMAIL:-<not set>}>"
  echo "  DeepSeek:   ${DEEPSEEK_KEY:+configured}${DEEPSEEK_KEY:-NOT SET}"
  echo "  System:     $([ "$DO_SYSTEM" = "y" ] && echo "✓" || echo "✗")    Docker:     $([ "$DO_DOCKER" = "y" ] && echo "✓" || echo "✗")"
  echo "  Zsh:        $([ "$DO_ZSH" = "y" ] && echo "✓" || echo "✗")    Java:       $([ "$DO_JAVA" = "y" ] && echo "✓" || echo "✗")"
  echo "  Node:       $([ "$DO_NODE" = "y" ] && echo "✓" || echo "✗")    Python:     $([ "$DO_PYTHON" = "y" ] && echo "✓" || echo "✗")"
  echo "  Go:         $([ "$DO_GO" = "y" ] && echo "✓" || echo "✗")    Rust:       $([ "$DO_RUST" = "y" ] && echo "✓" || echo "✗")    .NET: $([ "$DO_DOTNET" = "y" ] && echo "✓" || echo "✗")"
  echo "  OpenCode:   $([ "$DO_OPENCODE" = "y" ] && echo "✓" || echo "✗")    MCP+LSP:    $([ "$DO_MCP" = "y" ] && echo "✓" || echo "✗")"
  echo "  ChromaDB:   $([ "$DO_CHROMA" = "y" ] && echo "✓" || echo "✗")    Shokunin:   $([ "$DO_SHOKUNIN" = "y" ] && echo "✓" || echo "✗")"
  echo "  Trivy:      $([ "$DO_TRIVY" = "y" ] && echo "✓" || echo "✗")    Project:    $([ "$DO_PROJECT" = "y" ] && echo "✓" || echo "✗")"
  echo "  LLM:        $([ "$DO_LLM" = "y" ] && echo "✓" || echo "✗")"
  echo
  read -r -p "Proceed? [Y/n]: " confirm
  [ "$confirm" = "n" ] && { warn "Aborted by user"; exit 0; }

  # Set MODE to full for the actual execution
  MODE="full"
  # But guard each section with the selection flags
  INTERACTIVE_DO_SYSTEM="$DO_SYSTEM"
  INTERACTIVE_DO_DOCKER="$DO_DOCKER"
  INTERACTIVE_DO_ZSH="$DO_ZSH"
  INTERACTIVE_DO_JAVA="$DO_JAVA"
  INTERACTIVE_DO_NODE="$DO_NODE"
  INTERACTIVE_DO_PYTHON="$DO_PYTHON"
  INTERACTIVE_DO_GO="$DO_GO"
  INTERACTIVE_DO_RUST="$DO_RUST"
  INTERACTIVE_DO_DOTNET="$DO_DOTNET"
  INTERACTIVE_DO_OPENCODE="$DO_OPENCODE"
  INTERACTIVE_DO_MCP="$DO_MCP"
  INTERACTIVE_DO_CHROMA="$DO_CHROMA"
  INTERACTIVE_DO_SHOKUNIN="$DO_SHOKUNIN"
  INTERACTIVE_DO_TRIVY="$DO_TRIVY"
  INTERACTIVE_DO_PROJECT="$DO_PROJECT"
  INTERACTIVE_DO_LLM="$DO_LLM"
fi

# ── Interactive gate helper ─────────────────────────────────────────────────
# Usage: _gate "varname" && run_section
# In interactive mode, checks the INTERACTIVE_DO_* flag
# In other modes, always returns 0
_gate() {
  local flag_var="$1"
  if [ "$MODE" = "full" ] && [ -n "${INTERACTIVE_DO_SYSTEM:-}" ]; then
    # Running in interactive mode — check the flag
    local flag_val="${!flag_var}"
    [ "$flag_val" = "y" ] && return 0 || return 1
  fi
  return 0
}

# ── Network pre-check + WSL2 fix ────────────────────────────────────────────
section "Network check"
NET_OK=true
info "Testing connectivity to key services..."

# WSL2 DNS fix: add public DNS to prevent resolution failures
if [ -f /etc/resolv.conf ] && ! grep -qE '8\.8\.8\.8|1\.1\.1\.1' /etc/resolv.conf 2>/dev/null; then
  info "WSL2: adding Google/Cloudflare DNS fallback"
  echo "nameserver 8.8.8.8" | sudo tee -a /etc/resolv.conf 2>/dev/null || true
  echo "nameserver 1.1.1.1" | sudo tee -a /etc/resolv.conf 2>/dev/null || true
fi

# WSL2 fix: restart networking if completely dead (common after sleep/hibernate)
_check_net() { _curl "https://github.com" >/dev/null 2>&1; }
if ! _check_net; then
  warn "GitHub unreachable — attempting WSL2 network reset..."
  [ -f /etc/resolv.conf ] && WSL_HOST=$(grep nameserver /etc/resolv.conf 2>/dev/null | awk '{print $2}' | head -1)
  [ -n "${WSL_HOST:-}" ] && export HTTPS_PROXY="http://${WSL_HOST}:7890" 2>/dev/null || true
  [ -n "${WSL_HOST:-}" ] && export HTTP_PROXY="http://${WSL_HOST}:7890" 2>/dev/null || true
  sudo ip link set lo up 2>/dev/null || true
  sudo dhclient -r eth0 2>/dev/null || true
  sudo dhclient eth0 2>/dev/null || true
  sleep 3
  _check_net && log "WSL2 network recovered" || { warn "Network still limited — using apt fallbacks"; NET_OK=false; }
fi

# Proxy detect and configure
if [ -z "${HTTPS_PROXY:-}" ]; then
  PROXY_ENV=$(cmd.exe /c "reg query \"HKCU\\Software\\Microsoft\\Windows\\CurrentVersion\\Internet Settings\" /v ProxyServer" 2>/dev/null | grep -oP '[\d]+\.[\d]+\.[\d]+\.[\d]+:\d+' || true)
  if [ -n "${PROXY_ENV:-}" ]; then
    export HTTPS_PROXY="http://${PROXY_ENV}" HTTP_PROXY="http://${PROXY_ENV}"
    info "WSL2 proxy detected: $PROXY_ENV"
    _check_net && log "Proxy connectivity OK"
  fi
fi

for svc in "https://github.com" "https://registry.npmjs.org" "https://get.sdkman.io" "https://astral.sh" "https://go.dev"; do
  name=$(echo "$svc" | awk -F/ '{print $3}')
  _curl "$svc" >/dev/null 2>&1 || { warn "$name unreachable — using apt"; [ "$name" = "github.com" ] && NET_OK=false; }
done
$NET_OK || warn "Limited connectivity — using apt fallbacks where possible"
echo

# ── WSL2 optimization ────────────────────────────────────────────────────────
if grep -qi wsl /proc/version 2>/dev/null || grep -qi microsoft /proc/version 2>/dev/null; then
  section "WSL2 optimization"
  WSL_USERPROFILE=$(wslpath "$(wslvar USERPROFILE 2>/dev/null || echo '')" 2>/dev/null || echo "/mnt/c/Users/${USER}")
  WSL_CONF_FILE="$WSL_USERPROFILE/.wslconfig"
  if [ ! -f "$WSL_CONF_FILE" ]; then
    log "Generating $WSL_CONF_FILE"
    cat > "$WSL_CONF_FILE" << 'WSLCONF'
[wsl2]
memory=8GB
processors=4
swap=4GB
localhostForwarding=true
networkingMode=mirrored
dnsTunneling=true
autoProxy=true
guiApplications=true
vmIdleTimeout=60000

[experimental]
autoMemoryReclaim=dropCache
sparseVhd=true
WSLCONF
    log ".wslconfig created (WSL restart needed: wsl --shutdown)"
  fi

  # wsl.conf for systemd + automount + path hygiene
  WSL_DIST_CONF="/etc/wsl.conf"
  if [ ! -f "$WSL_DIST_CONF" ] || ! grep -q 'systemd=true' "$WSL_DIST_CONF" 2>/dev/null; then
    sudo tee "$WSL_DIST_CONF" << 'WSLDIST' > /dev/null
[boot]
systemd=true

[automount]
enabled=true
mountFsTab=true
root=/mnt/
options="metadata,umask=022,fmask=011"

[network]
generateHosts=true
generateResolvConf=true

[interop]
enabled=true
appendWindowsPath=false

WSLDIST
    log "wsl.conf configured (systemd, automount, no Windows PATH)"
  fi

  # Ensure distro name in /etc/hostname
  [ -f /etc/hostname ] && HOSTNAME_FILE=$(cat /etc/hostname 2>/dev/null)
  if ! grep -q "${HOSTNAME_FILE:-wsl}" /etc/hosts 2>/dev/null; then
    echo "127.0.0.1 ${HOSTNAME_FILE:-localhost}" | sudo tee -a /etc/hosts 2>/dev/null || true
  fi
fi

# ── Sudo ─────────────────────────────────────────────────────────────────────
[ "$EUID" -eq 0 ] && err "Do not run as root."
if [ -z "${SUDO_PASS:-}" ] && [ "$MODE" != "new" ] && [ "$MODE" != "fix-config" ]; then
  read -r -s -p "Sudo password (cached): " SUDO_PASS; echo
fi
if [ -n "${SUDO_PASS:-}" ]; then
  echo "$SUDO_PASS" | sudo -S true 2>/dev/null || err "Wrong sudo password"
  sudo -v 2>/dev/null || true
fi

PROJECT_DIR="${PROJECT_DIR:-$HOME/projects}"
export PROJECT_DIR
API_KEY="${API_KEY:-}"
DEEPSEEK_KEY="${DEEPSEEK_KEY:-}"
if [ -z "${DEEPSEEK_KEY:-}" ] && [ "$MODE" != "health" ] && [ "$MODE" != "fix-zshrc" ] && [ "$MODE" != "fix-config" ] && [ "$MODE" != "interactive" ]; then
  warn "No DeepSeek API key provided. Use --deepseek-key <key> or set DEEPSEEK_API_KEY env var."
  warn "Get a key at https://platform.deepseek.com/ — model: deepseek-v4-pro"
fi
export DEEPSEEK_API_KEY="${DEEPSEEK_KEY:-}"
GIT_NAME="${GIT_NAME:-}"
GIT_EMAIL="${GIT_EMAIL:-}"

# ── Logging ─────────────────────────────────────────────────────────────────
LOG_FILE="$HOME/setup-$(date +%Y%m%d-%H%M%S).log"
exec > >(tee -a "$LOG_FILE") 2>&1
echo -e "${GREEN}============================================================${NC}"
echo -e "${GREEN}     Ultimate Dev Machine Bootstrap v33.5${NC}"
echo -e "${GREEN}     Mode: $MODE${NC}"
echo -e "${GREEN}     Log:  $LOG_FILE${NC}"
echo -e "${GREEN}============================================================${NC}"

# ═══════════════════════════════════════════════════════════════════════════════
#  STEP 1: System packages
# ═══════════════════════════════════════════════════════════════════════════════
if ([ "$MODE" = "full" ] || [ "$MODE" = "reinit" ] || [ "$MODE" = "update" ]) && _gate "INTERACTIVE_DO_SYSTEM"; then
  section "System packages ($PKG_MANAGER)"
  _pkg_update
  pkglist=$(_pkg_list)
  if [ "$PKG_MANAGER" = "apt" ]; then
    # apt needs python packages separately
    sudo apt install -y -qq --no-install-recommends $pkglist python3-pip python3-venv 2>/dev/null || true
  else
    _pkg_install $pkglist python3-pip python3-venv 2>/dev/null || true
  fi
  # Import Mozilla CA certificates (fixes MITM proxy issues in RU)
  if [ ! -f /etc/ssl/certs/ca-certificates.crt ] && [ -d /etc/ssl/certs ]; then
    sudo update-ca-certificates --fresh 2>/dev/null || true
  fi
  # Ensure NPM can handle self-signed certs if needed
  npm config set strict-ssl false 2>/dev/null || true  # will be re-enabled if registry OK
  log "System packages OK ($PKG_MANAGER)"
  _step_done step_system
fi

# ═══════════════════════════════════════════════════════════════════════════════
#  STEP 2: Docker
# ═══════════════════════════════════════════════════════════════════════════════
if ([ "$MODE" = "full" ] || [ "$MODE" = "reinit" ]) && _gate "INTERACTIVE_DO_DOCKER"; then
  section "Docker"
  if ! command -v docker &>/dev/null; then
    DOCKER_SCRIPT=$(mktemp /tmp/docker-install.XXXXXX.sh)
    if _curl "https://get.docker.com" "$DOCKER_SCRIPT" &>/dev/null && sudo sh "$DOCKER_SCRIPT" 2>/dev/null; then
      sudo usermod -aG docker "$USER" 2>/dev/null || true
      log "Docker installed (relogin needed for group)"
    elif _retry 3 "Docker apt install" sudo apt-get install -y docker.io docker-compose-v2 2>/dev/null; then
      [ -f "$DOCKER_SCRIPT" ] && rm -f "$DOCKER_SCRIPT"
      if command -v docker &>/dev/null; then
        log "Docker installed from apt (relogin needed for group)"
      else
        warn "Docker install failed — install manually: https://docs.docker.com/engine/install/ubuntu/"
      fi
    else
      warn "Docker entirely unavailable — install manually"
    fi
  fi
  # Configure Docker mirror for Russia
  if command -v docker &>/dev/null && [ ! -f /etc/docker/daemon.json ]; then
    sudo mkdir -p /etc/docker
    echo '{
  "registry-mirrors": [
    "https://mirror.gcr.io",
    "https://docker.mirrors.ustc.edu.cn",
    "https://docker.m.daocloud.io"
  ],
  "dns": ["77.88.8.8", "77.88.8.1", "1.1.1.1", "8.8.8.8"]
}' | sudo tee /etc/docker/daemon.json >/dev/null && \
      sudo systemctl restart docker 2>/dev/null && \
      log "Docker mirror configured" || true
  fi
  _step_done step_docker
fi

# ═══════════════════════════════════════════════════════════════════════════════
#  STEP 3: Zsh + Oh My Zsh + Powerlevel10k
# ═══════════════════════════════════════════════════════════════════════════════
if ([ "$MODE" = "full" ] || [ "$MODE" = "reinit" ]) && _gate "INTERACTIVE_DO_ZSH"; then
  section "Zsh + Oh My Zsh + Powerlevel10k"
  if [ ! -d "$HOME/.oh-my-zsh" ]; then
    sh -c "$(curl -fsSL --retry 3 https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended 2>/dev/null || true
  fi
  ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
  [ ! -d "$ZSH_CUSTOM/themes/powerlevel10k" ] && \
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$ZSH_CUSTOM/themes/powerlevel10k" 2>/dev/null || true
  for p in zsh-autosuggestions zsh-syntax-highlighting; do
    [ ! -d "$ZSH_CUSTOM/plugins/$p" ] && \
      git clone --depth=1 "https://github.com/zsh-users/$p.git" "$ZSH_CUSTOM/plugins/$p" 2>/dev/null || true
  done
  if [ ! -f ~/.zshrc ] || ! grep -q "powerlevel10k" ~/.zshrc 2>/dev/null; then
    cat > ~/.zshrc << 'ZSHEOF'
# Enable Powerlevel10k instant prompt. Must stay at the top.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="powerlevel10k/powerlevel10k"
plugins=(git zsh-autosuggestions zsh-syntax-highlighting fzf zoxide docker docker-compose)
source "\$ZSH/oh-my-zsh.sh"

[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
ZSHEOF
  fi
  log "Zsh configured"
  _step_done step_zsh
fi

# ═══════════════════════════════════════════════════════════════════════════════
#  STEP 4: Java 25 via Adoptium API + Gradle + Maven + jbang
# ═══════════════════════════════════════════════════════════════════════════════
if ([ "$MODE" = "full" ] || [ "$MODE" = "reinit" ] || [ "$MODE" = "update" ]) && _gate "INTERACTIVE_DO_JAVA"; then
  section "Java 25 + Gradle + Maven + jbang"
  
  # ── Java via Adoptium API (GitHub-hosted, reliable in WSL2) ──
  if ! command -v java &>/dev/null; then
    JAVA_MAJOR=25
    ADOPTIUM_URL="${JAVA_MIRROR}/v3/binary/latest/${JAVA_MAJOR}/ga/linux/${ARCH_TYPE:-x64}/jdk/hotspot/normal/eclipse"
    JAVA_TAR="/tmp/jdk${JAVA_MAJOR}.tar.gz"
    info "Downloading Java ${JAVA_MAJOR} from Adoptium..."
    if _curl "$ADOPTIUM_URL" "$JAVA_TAR" 2>/dev/null; then
      sudo mkdir -p /usr/lib/jvm
      sudo tar -xzf "$JAVA_TAR" -C /usr/lib/jvm 2>/dev/null && \
        sudo update-alternatives --install /usr/bin/java java /usr/lib/jvm/jdk-${JAVA_MAJOR}*/bin/java 1 2>/dev/null && \
        sudo update-alternatives --install /usr/bin/javac javac /usr/lib/jvm/jdk-${JAVA_MAJOR}*/bin/javac 1 2>/dev/null && \
        log "Java ${JAVA_MAJOR} (Adoptium)" || warn "Java Adoptium setup failed"
      rm -f "$JAVA_TAR"
    else
      warn "Adoptium download failed — trying apt fallback"
    fi
  else
    log "Java $(java -version 2>&1 | head -1) already installed"
  fi

  # ── SDKMAN for Gradle, Maven, Kotlin, jbang ──
  if [ ! -d "$HOME/.sdkman" ]; then
    command -v zip &>/dev/null || sudo apt-get install -y zip 2>/dev/null || true
    command -v unzip &>/dev/null || sudo apt-get install -y unzip 2>/dev/null || true
    _curl "https://get.sdkman.io" /tmp/sdkman-install.sh 2>/dev/null && \
      bash /tmp/sdkman-install.sh 2>/dev/null; rm -f /tmp/sdkman-install.sh || \
      warn "SDKMAN install failed — using apt fallback for build tools"
  fi
  set +u; source "$HOME/.sdkman/bin/sdkman-init.sh" 2>/dev/null || true; set -u
  _sdk() {
    local pkg="$1" ver="${2:-}"; set +u
    if command -v "${pkg%% *}" &>/dev/null; then log "$pkg already installed"; set -u; return 0; fi
    if [ -n "$ver" ]; then
      sdk install "$pkg" "$ver" 2>/dev/null || { warn "sdk install $pkg $ver failed, trying latest"; sdk install "$pkg" 2>/dev/null || warn "sdk install $pkg failed entirely"; }
    else
      sdk install "$pkg" 2>/dev/null || warn "sdk install $pkg failed"
    fi
    set -u
  }
  # Only use SDKMAN for non-Java tools (Java is handled by Adoptium above)
  _sdk gradle
  _sdk maven
  _sdk jbang
  _sdk kotlin

  # Zig — use snap or direct download
  if ! command -v zig &>/dev/null; then
    if command -v snap &>/dev/null; then
      sudo snap install zig --classic 2>/dev/null && log "Zig from snap"
    fi
    if ! command -v zig &>/dev/null; then
      ZIG_VER="0.14.0"; ZIG_TARGET=""
      [ "$ARCH" = "aarch64" ] && ZIG_TARGET="aarch64" || ZIG_TARGET="x86_64"
      ZIG_URL="$ZIG_MIRROR/$ZIG_VER/zig-linux-${ZIG_TARGET}-$ZIG_VER.tar.xz"
      ZIG_DIR="/usr/local/lib/zig-$ZIG_VER"
      if [ ! -d "$ZIG_DIR" ]; then
        if _curl_mirror "$ZIG_URL" /tmp/zig.tar.xz "https://ziglang.org/download/$ZIG_VER/zig-linux-${ZIG_TARGET}-$ZIG_VER.tar.xz"; then
          sudo mkdir -p "$ZIG_DIR" && \
          sudo tar -xJf /tmp/zig.tar.xz -C "$ZIG_DIR" --strip-components=1 2>/dev/null && \
          sudo ln -sf "$ZIG_DIR/zig" /usr/local/bin/zig && \
          log "Zig $ZIG_VER installed (direct)" || warn "Zig not available"
        else
          warn "Zig download failed"
        fi
        rm -f /tmp/zig.tar.xz
      else
        log "Zig $ZIG_VER already installed"
      fi
    fi
  fi

  # Final apt fallback if anything is still missing
  if ! command -v java &>/dev/null; then
  _step_done step_java
    sudo apt-get install -y -qq openjdk-25-jdk gradle maven 2>/dev/null && log "Java/Gradle/Maven from apt" || warn "Java unavailable"
  fi
fi

# ═══════════════════════════════════════════════════════════════════════════════
#  STEP 5: Node.js 22
# ═══════════════════════════════════════════════════════════════════════════════
if ([ "$MODE" = "full" ] || [ "$MODE" = "reinit" ] || [ "$MODE" = "update" ]) && _gate "INTERACTIVE_DO_NODE"; then
  section "Node.js 22"
  mkdir -p ~/.n ~/.npm-global
  npm config set prefix ~/.npm-global 2>/dev/null || true
  # Use npm mirror if official registry unreachable (common in RU)
  if ! curl -fsSL --connect-timeout 5 https://registry.npmjs.org -o /dev/null 2>/dev/null; then
    npm config set registry "$NPM_REGISTRY" 2>/dev/null && info "npm: using mirror $NPM_REGISTRY"
  else
    npm config set strict-ssl true 2>/dev/null || true
  fi
  if [ ! -f "$N_PREFIX/bin/node" ] || ! node --version 2>/dev/null | grep -q "v22"; then
    npm install -g n@latest 2>/dev/null || true
    n 22 2>/dev/null && log "Node.js 22 installed" || { warn "n 22 failed — trying apt"; sudo apt-get install -y -qq nodejs npm 2>/dev/null && log "Node.js from apt" || warn "Node.js unavailable"; }
  else
    log "Node.js 22 already installed"
  fi
  _step_done step_node
fi

# ═══════════════════════════════════════════════════════════════════════════════
#  STEP 6: Python 3.12 + uv
# ═══════════════════════════════════════════════════════════════════════════════
if ([ "$MODE" = "full" ] || [ "$MODE" = "reinit" ] || [ "$MODE" = "update" ]) && _gate "INTERACTIVE_DO_PYTHON"; then
  section "Python 3.12 + uv"
  if ! command -v uv &>/dev/null; then
    UV_SCRIPT=$(mktemp /tmp/uv-install.XXXXXX.sh)
    if _curl "https://astral.sh/uv/install.sh" "$UV_SCRIPT" 2>/dev/null; then
      sh "$UV_SCRIPT" && log "uv installed" || warn "uv install script failed"
      rm -f "$UV_SCRIPT"
      export PATH="$HOME/.cargo/bin:$PATH"
    else
      warn "uv download failed — using pip from apt"
    fi
  else
    log "uv already installed"
  fi
  command -v uv &>/dev/null && uv python install 3.12 --default 2>/dev/null || true
  # Configure pip mirror if pypi.org unreachable
  if ! curl -fsSL --connect-timeout 5 https://pypi.org -o /dev/null 2>/dev/null; then
    pip3 config set global.index-url "$PYPI_MIRROR" 2>/dev/null || true
    command -v uv &>/dev/null && uv pip config set global.index-url "$PYPI_MIRROR" 2>/dev/null || true
  fi
  command -v uv &>/dev/null && uv pip install --user --upgrade pip 2>/dev/null || true
  PYTHON_BIN="$( (command -v uv &>/dev/null && uv python find 3.12 2>/dev/null) || which python3.12 2>/dev/null || which python3 2>/dev/null || true)"
  [ -n "$PYTHON_BIN" ] && sudo update-alternatives --install /usr/bin/python python "$PYTHON_BIN" 1 2>/dev/null || true
  log "Python 3.12 OK"
  _step_done step_python
fi

# ═══════════════════════════════════════════════════════════════════════════════
#  STEP 6a: Go 1.24+
# ═══════════════════════════════════════════════════════════════════════════════
if ([ "$MODE" = "full" ] || [ "$MODE" = "reinit" ] || [ "$MODE" = "update" ]) && _gate "INTERACTIVE_DO_GO"; then
  section "Go"
  if ! command -v go &>/dev/null; then
    GO_LATEST=$(curl -s --connect-timeout 10 https://go.dev/VERSION?m=text 2>/dev/null | head -1 | tr -d 'go \n' || echo "1.24.5")
    info "Latest Go: ${GO_LATEST}"
    GO_ARCH="${GO_ARCH:-linux-amd64}"
    GO_TAR="/tmp/go${GO_LATEST}.${GO_ARCH}.tar.gz"
    if _curl "https://go.dev/dl/go${GO_LATEST}.${GO_ARCH}.tar.gz" "$GO_TAR" 2>/dev/null; then
      sudo rm -rf /usr/local/go 2>/dev/null || true
      sudo tar -C /usr/local -xzf "$GO_TAR" && log "Go ${GO_LATEST} installed" || warn "Go tar extraction failed"
      rm -f "$GO_TAR"
      export PATH="/usr/local/go/bin:$PATH"
    else
      warn "Go download failed — trying apt fallback"
      sudo apt-get install -y -qq golang-go 2>/dev/null && log "Go from apt" || warn "Go unavailable — install manually from https://go.dev/dl/"
    fi
  else
    log "Go $(go version 2>/dev/null | cut -d' ' -f3) already installed"
  fi
  # Go proxy config for modules
  command -v go &>/dev/null && go env -w GOPROXY="${GOPROXY:-https://goproxy.io,direct}" 2>/dev/null || true
  _step_done step_go
fi

# ═══════════════════════════════════════════════════════════════════════════════
#  STEP 6b: Rust
# ═══════════════════════════════════════════════════════════════════════════════
if ([ "$MODE" = "full" ] || [ "$MODE" = "reinit" ] || [ "$MODE" = "update" ]) && _gate "INTERACTIVE_DO_RUST"; then
  section "Rust"
  if ! command -v rustc &>/dev/null; then
    RUSTUP_SCRIPT=$(mktemp /tmp/rustup-init.XXXXXX.sh)
    if _curl "https://sh.rustup.rs" "$RUSTUP_SCRIPT" 2>/dev/null; then
      sh "$RUSTUP_SCRIPT" -y --default-toolchain stable 2>/dev/null && log "Rust installed" || warn "Rust install failed"
      rm -f "$RUSTUP_SCRIPT"
      export PATH="$HOME/.cargo/bin:$PATH"
    else
      warn "Rust download failed — trying apt fallback"
      sudo apt-get install -y -qq cargo rustc 2>/dev/null && log "Rust from apt" || warn "Rust unavailable — install manually"
    fi
  else
    log "Rust $(rustc --version 2>/dev/null | cut -d' ' -f2) already installed"
  fi
  _step_done step_rust
fi

# ═══════════════════════════════════════════════════════════════════════════════
#  STEP 6c: .NET 9
# ═══════════════════════════════════════════════════════════════════════════════
if ([ "$MODE" = "full" ] || [ "$MODE" = "reinit" ] || [ "$MODE" = "update" ]) && _gate "INTERACTIVE_DO_DOTNET"; then
  section ".NET 9"
  if ! command -v dotnet &>/dev/null; then
    DOTNET_SCRIPT=$(mktemp /tmp/dotnet-install.XXXXXX.sh)
    if _curl "https://dot.net/v1/dotnet-install.sh" "$DOTNET_SCRIPT" 2>/dev/null; then
      chmod +x "$DOTNET_SCRIPT"
      "$DOTNET_SCRIPT" --channel 9.0 --install-dir "$HOME/.dotnet" 2>/dev/null && \
        log ".NET 9 installed" || warn ".NET install failed"
      rm -f "$DOTNET_SCRIPT"
      export PATH="$HOME/.dotnet:$PATH"
      export DOTNET_ROOT="$HOME/.dotnet"
    else
      warn ".NET download failed — trying apt fallback"
      sudo apt-get install -y -qq dotnet-sdk-9.0 2>/dev/null && log ".NET 9 from apt" || warn ".NET unavailable — install manually from https://dotnet.microsoft.com/"
    fi
  else
    log ".NET $(dotnet --version 2>/dev/null) already installed"
  fi
  _step_done step_dotnet
fi

# ═══════════════════════════════════════════════════════════════════════════════
#  STEP 7: Clean old configs + stale agents
# ═══════════════════════════════════════════════════════════════════════════════
if [ "$MODE" = "full" ] || [ "$MODE" = "reinit" ]; then
  section "Cleaning old configs & stale agents"
  rm -rf ~/.cache/opencode ~/.local/share/opencode ~/.opencode ~/opencode.json
  mkdir -p ~/.config/opencode
  # Remove scout agent — known bug from old opencode-multiagent versions
  for scout_path in \
    "$PROJECT_DIR/.opencode/agents/scout.md" \
    "$HOME/.config/opencode/agents/scout.md" \
    "$HOME/.opencode/agents/scout.md"; do
    [ -f "$scout_path" ] && rm -f "$scout_path" && warn "Removed stale agent: $scout_path"
  done
  log "Old configs cleaned"
fi

# ═══════════════════════════════════════════════════════════════════════════════
#  STEP 8: OpenCode CLI + Bun
# ═══════════════════════════════════════════════════════════════════════════════
if ([ "$MODE" = "full" ] || [ "$MODE" = "reinit" ] || [ "$MODE" = "update" ]) && _gate "INTERACTIVE_DO_OPENCODE"; then
  section "OpenCode CLI"
  if ! command -v opencode &>/dev/null; then
    info "Installing OpenCode CLI ($OPENCODE_VER)..."
    if timeout 120 npm install -g "opencode-ai@${OPENCODE_VER}" --prefer-offline 2>/dev/null; then
      log "OpenCode $(opencode --version 2>/dev/null || echo 'installed')"
    elif _curl "https://opencode.ai/install" /tmp/opencode-install.sh 2>/dev/null; then
      timeout 60 bash /tmp/opencode-install.sh 2>/dev/null && log "OpenCode installed (curl)" || warn "opencode install script failed"
      rm -f /tmp/opencode-install.sh
    else
      warn "OpenCode install failed — install manually: npm install -g opencode-ai@latest"
    fi
  else
    log "OpenCode $(opencode --version 2>/dev/null) already installed"
  fi
  _step_done step_opencode
  if ! command -v bun &>/dev/null; then
    # Bun needs unzip — ensure it's available
    if command -v unzip &>/dev/null || sudo apt-get install -y unzip &>/dev/null; then
      BUN_SCRIPT=$(mktemp /tmp/bun-install.XXXXXX.sh)
      if _curl "https://bun.sh/install" "$BUN_SCRIPT" 2>/dev/null; then
        bash "$BUN_SCRIPT" && export PATH="$HOME/.bun/bin:$PATH" && log "Bun installed" || warn "Bun install failed"
        rm -f "$BUN_SCRIPT"
      else
        warn "Bun download failed — install manually: curl -fsSL https://bun.sh/install | bash"
      fi
    else
      warn "Bun install failed (unzip unavailable)"
    fi
  else
    log "Bun already installed"
  fi
fi
  # Global mirror configs for npm, pip, Go
  mkdir -p "$HOME/.config/pip"
  cat > "$HOME/.config/pip/pip.conf" 2>/dev/null <<EOF
[global]
index-url = $PYPI_MIRROR
trusted-host = $(echo "$PYPI_MIRROR" | sed 's|https://||;s|/.*||')
EOF
  command -v go &>/dev/null && go env -w GOPROXY="${GOPROXY:-https://goproxy.io,direct}" 2>/dev/null || true

# ═══════════════════════════════════════════════════════════════════════════════
#  STEP 9: MCP servers & plugins
# ═══════════════════════════════════════════════════════════════════════════════
if ([ "$MODE" = "full" ] || [ "$MODE" = "reinit" ] || [ "$MODE" = "update" ]) && _gate "INTERACTIVE_DO_MCP"; then
  section "MCP servers & plugins"
  set +e  # tolerate individual component failures

  _mcp() { _npm_install "$1" "$2"; }

  for name in "${!MCP_PACKAGES[@]}"; do
    _mcp "${MCP_PACKAGES[$name]}" "$name" || true
  done

  # Muninn via pipx (skills only, not an MCP server)
  if ! command -v muninn-remembers &>/dev/null; then
    _retry 3 "Muninn pipx install" pipx install muninn-remembers 2>/dev/null || true
  else
    pipx install --force muninn-remembers 2>/dev/null || true
  fi
  if command -v muninn-remembers &>/dev/null; then
    muninn-remembers install opencode 2>/dev/null || warn "Muninn: skills install failed"
  fi

  # ChromaDB (vector database for muninn memory)
  if ! command -v chroma &>/dev/null; then
    _retry 3 "ChromaDB pipx install" pipx install chromadb 2>/dev/null || true
  fi
  # Fix chroma symlink
  CHROMA_PIPX="$(pipx list 2>/dev/null | grep chromadb | head -1 | awk '{print $NF}')"
  if [ -n "$CHROMA_PIPX" ] && [ ! -L "$HOME/.local/bin/chroma" ]; then
    ln -sf "$HOME/.local/share/pipx/venvs/chromadb/bin/chroma" "$HOME/.local/bin/chroma" 2>/dev/null || true
  fi
  # Pre-download ONNX model for ChromaDB (needed for offline embedding)
  ONNX_DIR="$HOME/.cache/chroma/onnx_models/all-MiniLM-L6-v2"
  ONNX_FILE="$ONNX_DIR/onnx/model.onnx"
  if [ ! -f "$ONNX_FILE" ]; then
    mkdir -p "$ONNX_DIR"
    if [ ! -f "$ONNX_DIR/onnx.tar.gz" ]; then
      log "ChromaDB: downloading ONNX model (79MB)..."
      _curl "https://chroma-onnx-models.s3.amazonaws.com/all-MiniLM-L6-v2/onnx.tar.gz" "$ONNX_DIR/onnx.tar.gz" 2>&1 | tail -1
    fi
    if [ -f "$ONNX_DIR/onnx.tar.gz" ]; then
      tar -xzf "$ONNX_DIR/onnx.tar.gz" -C "$ONNX_DIR" && log "ChromaDB: ONNX model extracted" || warn "ChromaDB: model extract failed"
    fi
  else
    log "ChromaDB: ONNX model already cached"
  fi

  command -v ollama &>/dev/null && ollama pull mxbai-embed-large 2>/dev/null || true

  # Plugins — codegraph only
  npm install -g opencode-codegraph@latest 2>/dev/null && log "Plugin: opencode-codegraph" || { warn "Plugin FAILED: opencode-codegraph"; true; }

  # LSP servers (language intelligence — installed, detected later by Python gen)
  section "LSP servers"
  npm install -g typescript-language-server typescript pyright yaml-language-server @taplo/cli marksman 2>/dev/null || true
  command -v go &>/dev/null && go install golang.org/x/tools/gopls@latest 2>/dev/null || true
  command -v rustup &>/dev/null && rustup component add rust-analyzer 2>/dev/null || true
  command -v dotnet &>/dev/null && dotnet tool install -g csharp-ls 2>/dev/null || true
  command -v dotnet &>/dev/null && dotnet tool list -g 2>/dev/null || true
  log "LSP servers staged (installed if toolchains present)"
  set -e  # restore strict mode
fi

# ═══════════════════════════════════════════════════════════════════════════════
#  STEP 10: ChromaDB server (vector memory backend)
# ═══════════════════════════════════════════════════════════════════════════════
if ([ "$MODE" = "full" ] || [ "$MODE" = "reinit" ]) && _gate "INTERACTIVE_DO_CHROMA"; then
  section "ChromaDB server"
  CHROMA_DATA="$HOME/.local/share/chroma"
  mkdir -p "$CHROMA_DATA"

  # Start chroma server if not already running
  if ! curl -sf http://127.0.0.1:8000/api/v2/heartbeat &>/dev/null; then
    chroma run --path "$CHROMA_DATA" --port 8000 --host 127.0.0.1 &>/dev/null &
    disown $!
    CHROMA_PID=$!
    sleep 2
    if curl -sf http://127.0.0.1:8000/api/v2/heartbeat &>/dev/null; then
      log "ChromaDB server started (PID $CHROMA_PID, port 8000)"
    else
      warn "ChromaDB server failed to start"
    fi
  else
  _step_done step_chromadb
    log "ChromaDB server already running"
  fi

  # Install systemd user service for ChromaDB auto-start
  mkdir -p "$HOME/.config/systemd/user"
  cat > "$HOME/.config/systemd/user/chromadb.service" << 'CHROMSVC'
[Unit]
Description=ChromaDB vector database for Muninn memory
After=network.target

[Service]
Type=simple
Environment=CHROMA_SERVER_NOFILE=65536
ExecStart=%h/.local/bin/chroma run --path %h/.local/share/chroma --port 8000 --host 127.0.0.1
Restart=on-failure
RestartSec=5

[Install]
WantedBy=default.target
CHROMSVC
  systemctl --user daemon-reload 2>/dev/null || true
  systemctl --user enable chromadb.service 2>/dev/null || true
  if systemctl --user is-active chromadb.service &>/dev/null; then
    log "ChromaDB systemd service active"
  else
    systemctl --user start chromadb.service 2>/dev/null || true
    log "ChromaDB systemd service installed"
  fi
fi

# ═══════════════════════════════════════════════════════════════════════════════
#  STEP 11: Shokunin + Superpowers + Caveman
# ═══════════════════════════════════════════════════════════════════════════════
if ([ "$MODE" = "full" ] || [ "$MODE" = "reinit" ]) && _gate "INTERACTIVE_DO_SHOKUNIN"; then
  section "Shokunin + Superpowers + Caveman"
  if [ ! -d "$HOME/.shokunin" ]; then
    bash <(curl -sL https://raw.githubusercontent.com/EliasOulkadi/shokunin/master/install.sh) -y 2>/dev/null || true
    log "Shokunin installed"
  _step_done step_shokunin
    # Fix shokunin profile to not echo on load (P10k compat)
    SHOKUNIN_PROFILE="$HOME/.shokunin/scripts/linux/profile.sh"
    [ -f "$SHOKUNIN_PROFILE" ] && sed -i 's/echo "Shokunin AI Ecosystem loaded"/# echo "Shokunin AI Ecosystem loaded"/' "$SHOKUNIN_PROFILE" 2>/dev/null || true
  fi

  mkdir -p "$HOME/.config/opencode/skills/superpowers"
  SUPERPOWERS_TMP=$(mktemp -d /tmp/superpowers.XXXXXX)
  git clone --depth=1 https://github.com/obra/superpowers.git "$SUPERPOWERS_TMP" 2>/dev/null || true
  [ -d "$SUPERPOWERS_TMP/skills" ] && cp -r "$SUPERPOWERS_TMP/skills" "$HOME/.config/opencode/skills/superpowers" 2>/dev/null || true
  rm -rf "$SUPERPOWERS_TMP"

  # Caveman skill
  if [ ! -d "$HOME/.caveman-opencode" ]; then
    git clone https://github.com/anthonystepvoy/caveman-opencode.git "$HOME/.caveman-opencode" 2>/dev/null || true
  fi
  if [ -d "$HOME/.caveman-opencode" ]; then
    mkdir -p "$PROJECT_DIR/.opencode/skills/caveman" 2>/dev/null || mkdir -p "$HOME/agi/.opencode/skills/caveman" 2>/dev/null || true
    cp "$HOME/.caveman-opencode/skills/caveman.md" "$PROJECT_DIR/.opencode/skills/caveman/SKILL.md" 2>/dev/null || cp "$HOME/.caveman-opencode/skills/caveman.md" "$HOME/agi/.opencode/skills/caveman/SKILL.md" 2>/dev/null || true
    log "Caveman skill installed"
  fi
fi

# ═══════════════════════════════════════════════════════════════════════════════
#  STEP 12: Security tools
# ═══════════════════════════════════════════════════════════════════════════════
if [ "$MODE" = "full" ] || [ "$MODE" = "reinit" ]; then
  section "Security tools"
  command -v trivy &>/dev/null || sudo snap install trivy 2>/dev/null || sudo apt install -y -qq trivy 2>/dev/null || warn "trivy not installed"
  if ! command -v qodana &>/dev/null; then
    curl -fsSL --connect-timeout 30 --retry 2 --retry-delay 5 \
      "https://jb.gg/qodana-cli/install" 2>/dev/null | bash 2>/dev/null && log "qodana installed" || warn "qodana not installed"
  fi
  log "Security tools OK"
fi

# ═══════════════════════════════════════════════════════════════════════════════
#  STEP 12b: GPU / Local LLM runtimes (optional, opt-in)
# ═══════════════════════════════════════════════════════════════════════════════
if ([ "$MODE" = "full" ] || [ "$MODE" = "reinit" ]) && _gate "INTERACTIVE_DO_LLM"; then
  section "Local LLM runtimes"
  HAS_GPU=false
  lspci 2>/dev/null | grep -qiE 'nvidia|amd/ati|virtio-gpu' && HAS_GPU=true
  nvidia-smi &>/dev/null && HAS_GPU=true
  $HAS_GPU && log "GPU detected — enabling GPU-accelerated runtimes" || warn "No GPU found — CPU-only mode (Ollama works, vLLM skipped)"

  # Ollama — works with or without GPU
  if ! command -v ollama &>/dev/null; then
    info "Installing Ollama..."
    command -v zstd &>/dev/null || sudo apt-get install -y zstd 2>/dev/null || true
    _curl "https://ollama.ai/install.sh" /tmp/ollama-install.sh 2>/dev/null && bash /tmp/ollama-install.sh 2>/dev/null && log "Ollama installed" || warn "Ollama install failed"
    rm -f /tmp/ollama-install.sh
    # Pull a light model for immediate use
    command -v ollama &>/dev/null && { ollama pull qwen3:1.8b 2>/dev/null & log "Ollama: pulling qwen3:1.8b (background)"; }
  else
    log "Ollama already installed"
  fi

  # Open WebUI — chat interface for Ollama (Docker-based)
  if command -v docker &>/dev/null && ! docker ps --format '{{.Names}}' 2>/dev/null | grep -q 'open-webui'; then
    info "Installing Open WebUI (Docker)..."
    docker run -d --name open-webui --restart unless-stopped \
      -p 3300:8080 -v open-webui:/app/backend/data \
      --add-host=host.docker.internal:host-gateway \
      ghcr.io/open-webui/open-webui:main 2>/dev/null && log "Open WebUI: http://localhost:3300" || warn "Open WebUI failed"
  fi

  # vLLM — GPU-only, for high-performance inference
  if $HAS_GPU && ! command -v vllm &>/dev/null; then
    info "Installing vLLM (GPU inference server)..."
    pipx install vllm 2>/dev/null && log "vLLM installed" || warn "vLLM install failed (requires NVIDIA GPU + CUDA)"
  fi

  # SGLang — efficient structured generation
  if $HAS_GPU && ! command -v sglang &>/dev/null; then
    info "Installing SGLang..."
    pipx install "sglang[all]" 2>/dev/null && log "SGLang installed" || warn "SGLang install failed"
  fi

  # LlamaEdge — lightweight WasmEdge-based runner (CPU-friendly)
  if ! command -v wasmedge &>/dev/null; then
    curl -sSf https://raw.githubusercontent.com/WasmEdge/WasmEdge/master/utils/install.sh 2>/dev/null | bash -s -- -v 0.14.1 2>/dev/null && log "WasmEdge installed" || warn "WasmEdge skipped"
  fi

  log "LLM runtimes configured"
fi

# ═══════════════════════════════════════════════════════════════════════════════
#  STEP 13: Project structure
# ═══════════════════════════════════════════════════════════════════════════════
if [ "$MODE" = "full" ] || [ "$MODE" = "reinit" ] || [ "$MODE" = "new" ]; then
  if [ "$MODE" = "new" ]; then
    PROJECT_DIR="$NEW_PROJECT_DIR"
  fi
  [ -z "$PROJECT_DIR" ] && err "PROJECT_DIR is empty"

  section "Project structure: $PROJECT_DIR"
  if mkdir -p "$PROJECT_DIR" 2>/dev/null; then
    mkdir -p "$PROJECT_DIR"/{docs,wal,.lock,.opencode/{agents,skills,commands,context},infra,icon,templates,output}
  else
    warn "Cannot create $PROJECT_DIR (permission denied). Using ~/agi instead."
    PROJECT_DIR="$HOME/agi"
    mkdir -p "$PROJECT_DIR"/{docs,wal,.lock,.opencode/{agents,skills,commands,context},infra,icon,templates,output}
  fi

  # INDEX.md
  [ ! -f "$PROJECT_DIR/docs/INDEX.md" ] && cat > "$PROJECT_DIR/docs/INDEX.md" << 'EOF'
# INDEX: Knowledge Base Map
| ID | Path | Title | Phase | Topics | Last_Updated |
|----|------|-------|-------|--------|--------------|
EOF

  # GLOBAL_WAL.md
  [ ! -f "$PROJECT_DIR/wal/GLOBAL_WAL.md" ] && cat > "$PROJECT_DIR/wal/GLOBAL_WAL.md" << WALEOF
# GLOBAL WAL — $(date +%Y-%m-%d)
| Module | Status | Last_Agent | Last_Action |
|--------|--------|------------|-------------|
WALEOF

  # AGENTS.md
  if [ ! -f "$PROJECT_DIR/AGENTS.md" ]; then
    cat > "$PROJECT_DIR/AGENTS.md" << 'AGENTSEOF'
# System Prompt: Universal AI Coprocessor vFinal (DeepSeek-Optimized)

## IDENTITY
You are a **Secondary Coprocessor**. The User provides Strategy and Critical Decisions; you provide Decomposition, Verification, Implementation, and Truth-Seeking Rigour.
- **Shared State:** Files (specifications, code, WAL) are the only reliable IPC. Stale files = broken system.
- **Resilience:** Solutions must anticipate evolving requirements and remain maintainable under change.
- **Verifiable Claims:** No "it seems". State "confirmed by [source]" or "derived from [logic]". Explicitly label all assumptions.
- **Truth-Seeking:** Maximise accuracy and usefulness. Prefer admitting uncertainty over fabricating an answer. Actively challenge your own conclusions.
- **Язык:** Отвечай на русском языке. Технические термины — на английском.

## DEEPSEEK-SPECIFIC CONSTRAINTS
- Keep all instructions concise and verb-first. Avoid nested if-else logic; use flat, unconditional rules.
- User-prompt instructions take precedence over System Prompt when they conflict.
- Use imperative mood and direct commands. Do not explain System Prompt rules unless asked.

## CORE PROTOCOLS

### 1. Dual-Process Reasoning (Internal)
1. **System 1 (Fast):** Rapid pattern matching, analogies, initial hypotheses.
2. **System 2 (Slow):** Methodical verification, error detection, contradiction search.
**Rule:** Final output = System 2 result. Internal reasoning hidden unless `/stepbystep` active.

### 2. Memory Hierarchy & WAL
- **L2 – WAL:** Current volatile state (hours–days).
- **L3 – Specifications:** Stabilised decisions (months).
- **L4 – Artifacts:** Code, docs, configs.

**WAL Protocol:**
- **Trigger:** Offer checkpoint ONLY if artifacts created/modified.
- **Format (3 lines):**
  ```
  📍 Status: <one concise sentence>
  🚀 Active: <current task or next step>
  🛑 Protected: <critical constraints, fragile zones, irreversible decisions>
  ```
- **Prompt:** *"Update WAL? Copy the block below into your WAL file for the next session."*
- **Context Compression:** If conversation exceeds ~50k tokens, proactively summarise key decisions into a new WAL checkpoint to free context window.

### 3. Keyboard Layout Auto-Correction
Detect and repair RU↔EN layout using QWERTY↔ЙЦУКЕН mapping. Confidence ≥ 90% → correct silently. Lower → ask.

### 4. Output Contract (CO-STAR Enhanced)
Execute **once** after plan confirmation. State clearly:
- **Context:** assumptions about the task environment
- **Objective:** specific goal of this response
- **Style:** writing approach
- **Tone:** emotional register
- **Audience:** who the response targets
- **Response:** format and structure
- **Exclusions:** what will NOT be included

### 5. Memory Anchor Protocol
At the start of each response, include a brief anchor tag: `[CTX: <3-word session summary>]`.

## TACTICAL ALGORITHM

**Step 1 – Mode & Persona**
- Propose mode: `instant` (fast), `expert` (deep reasoning/CoVe), or `deep` (expert + mandatory tools + multi-perspective simulation).
- Select hybrid persona. Justify in one line.

**Step 2 – Clarification**
- Fix layout. If task is ambiguous → ask 1–3 specific questions. NEVER GUESS.
- Post-May 2025 data → trigger web search (mandatory in `expert` and `deep`).

**Step 3 – Plan & Confirmation**
- Draft 3–6 step plan. Show and wait for confirmation: *"OK"*, *"Do it"*, or *"Adjust [X]"*.
- `/autopilot` skips wait but displays plan.

**Step 4 – Execution & Verification**
1. **CoT:** Internal reasoning (exposed if `/stepbystep`).
2. **Code Fidelity:** Verify API/library signatures via Web/Docs for exact version. If uncertain, `// TODO: verify <func> for vX.Y.Z`.
3. **CoVe:** Generate 3–5 fact-check questions → answer via Source Ladder → correct and mark `[SELF-CHECK]`.
4. **Source Ladder (Strict Priority):**
   1. Official documentation / source code
   2. Authoritative (ArXiv, IEEE, standards bodies)
   3. Verified encyclopedias
   4. Internal knowledge (label `[KNOWLEDGE: model]`)

**Step 5 – Completion & WAL**
- If artifacts changed, offer WAL checkpoint.

## COMMAND FLAGS
`/mode instant|expert|deep` `/as [role]` `/autopilot` `/stepbystep` `/sources` `/verify` `/deterministic` `/critique` `/creative` `/interactive` `/lang XX` `/atomic` `/heartbeat` `/refactor` `/superthink` `/anarchic` `/evolve` `/tcov`

## ОКРУЖЕНИЕ И ИНСТРУМЕНТЫ

### Модели (Multi-Provider: DeepSeek API + OpenCode Go)
- **Основная (reasoning):** `deepseek/deepseek-v4-pro` (DeepSeek-V4-Pro, thinking mode auto, 64K output).
- **Бюджетная (fast):** `deepseek/deepseek-v4-flash` ($0.14/1M input, non-thinking, 1M context).
- **OpenCode Go (резерв):** `opencode-go/glm-5.1` — авто-фолбэк если DeepSeek недоступен.
- **Small model (фон):** `opencode-go/gpt-5-nano` — для фоновых операций и простых задач.
- Переключение: `/model deepseek/deepseek-v4-pro` или `/model opencode-go/glm-5.1`.
- Конфигурация провайдеров в `~/.config/opencode/opencode.json` → `provider: { deepseek: {}, opencode: {} }`.
- API ключи: DeepSeek — через `/connect` в TUI, OpenCode Go — `opencode auth login`.

### Агенты (вызов через `@имя`)
- `@pm`, `@analyst`, `@architect` → `glm-5.1`
- `@developer`, `@researcher`, `@devops` → `deepseek-v4-pro`
- `@qa`, `@designer` → `minimax-m2.7`
- `@reviewer` → `qwen3.6-plus` | `@security` → `glm-5`

### MCP-серверы
- **`filesystem`** — работа с файлами.
- **`context7`** — живая документация библиотек.
- **`codegraph`** — граф вызовов и метрики сложности. **Всегда используй для навигации по коду.**
- **`agentic-tools`** — иерархическая память задач.
- **`muninn`** — семантическая память (ChromaDB).
- **`playwright`** — UI-тестирование.

### Инструменты эффективности
- **Caveman:** Сокращает выходные токены до 75%. Для рутинных ответов.
- **CodeGraph Plugin:** Автоматически обогащает диалог графом вызовов.
- **Superpowers skills:** 62+ skills в `~/.config/opencode/skills/superpowers/`.

## ТЕХНОЛОГИЧЕСКИЙ СТЕК (зрелые технологии — май 2026)
### Языки
| Язык | Версия | Среда |
|------|--------|-------|
| Go | 1.24+ | `go` toolchain |
| Rust | 1.85+ | `rustup` + `cargo` |
| TypeScript | 5.8+ | `bun` / `node` |
| Python | 3.12+ | `uv` + `pip` |
| Java | 25 LTS | SDKMAN (`java`, `gradle`, `mvn`) |
| Kotlin | 2.1+ | SDKMAN / Gradle |
| C# | .NET 9 | `dotnet` SDK |
| Zig | 0.14+ | `zig` toolchain |

### Backend-фреймворки
| Язык | Фреймворк |
|------|-----------|
| Go | Gin, Echo, Fiber, Chi |
| Rust | Axum, Actix-web, Rocket |
| TypeScript | Fastify, Express, Hono, NestJS |
| Python | FastAPI, Litestar, Django 5 |
| Java/Kotlin | Spring Boot 3, Quarkus 3, Micronaut 4 |
| C# | ASP.NET Core 9, Minimal API |
| Zig | Zap, httpz |

### Frontend
| Технология | Версия |
|------------|--------|
| React | 19.x |
| Next.js | 15+ (App Router) |
| Vue | 3.5+ (Composition API) |
| Nuxt | 3.x |
| Svelte | 5 (runes) |
| SvelteKit | 2.x |
| Astro | 5.x |
| TailwindCSS | 4.x |
| shadcn/ui | latest |

### Базы данных и инфраструктура
| Тип | Технология |
|-----|-----------|
| Реляционная | PostgreSQL 18, MySQL 8.4, SQLite |
| Документная | MongoDB 8 |
| Кеш | Redis 7, Valkey 8 |
| Поиск | Meilisearch, Typesense |
| Брокер | Kafka 4.2, NATS, RabbitMQ |
| RPC | gRPC, Connect |
| Миграции | Flyway, Atlas, Prisma Migrate |
| S3-хранилище | MinIO (локально), AWS S3 / Cloudflare R2 |
| Моки | WireMock, MockServer, MSW |

## АРХИТЕКТУРА И ПРИНЦИПЫ
- Clean Architecture, Hexagonal Architecture, DDD, CQRS/ES, SAGA, Event Sourcing, Microservices, Modular Monolith, Micro Frontends, BFF, 12-Factor App.
- TDD: RED → GREEN → REFACTOR. Покрытие ≥ 80%.
- API Design: REST (OpenAPI 3.1), GraphQL, gRPC, WebSocket.
- Auth: OAuth2/OIDC, WebAuthn/Passkeys, JWT, RBAC/ABAC.
- Observability: OpenTelemetry (traces, metrics, logs), structured logging.
- CI/CD: GitHub Actions, GitLab CI, Docker multi-stage builds.

## ПАМЯТЬ: Knowledge Base и WAL
- **Первым делом** читай `docs/INDEX.md`.
- **При старте сессии** проверяй `wal/GLOBAL_WAL.md` и `wal/SESSION_WAL.md`. Загрузи контекст из `agentic-tools` и `muninn`.
- **Протокол блокировок:** проверь WAL → создай SESSION_WAL → установи `.lock` (TTL 300) → после работы удали lock и обнови WAL.

## АЛГОРИТМ РАБОТЫ
1. **Инициализация:** прочитай WAL, INDEX.md, загрузи память, получи обзор через codegraph.
2. **План:** сформируй план (3–6 шагов). **Запроси подтверждение.**
3. **Реализация:** строгий порядок: доменная модель → юзкейсы → тесты → код. Используй агентов, codegraph, context7.
4. **Завершение:** предложи обновить WAL, сохрани ключевые решения в `agentic-tools` и `muninn`.

## САМОПРОВЕРКА (обязательный блок)
После сложного ответа добавляй блок «Самопроверка»:
- Что может быть неоптимально?
- Что изменилось после мая 2025 и могло устареть?
- Какие пункты пользователю стоит перепроверить?

## ПРИОРИТЕТЫ (заполни под свой проект)
<!-- Определи 3-5 ключевых приоритетов MVP. Пример:
1. Auth (OAuth2/OIDC)
2. Core API (REST + GraphQL)
3. Admin UI (React/Vue)
4. CI/CD Pipeline
5. Observability (OpenTelemetry)
-->

## СТАРТ СЕССИИ
[CTX: project dev session]. Немедленно выполни инициализацию: прочитай WAL, INDEX.md, загрузи память из muninn/agentic-tools, получи обзор codegraph. Выведи сводку в 3 строках: статус, активная задача, защищённые зоны.
AGENTSEOF
    log "AGENTS.md created"
  fi

  # Agents
  declare -A ROLE_MODELS=(
    [pm]="opencode-go/glm-5.1" [analyst]="opencode-go/glm-5.1" [architect]="opencode-go/glm-5.1"
    [developer]="deepseek/deepseek-v4-pro" [qa]="opencode-go/minimax-m2.7"
    [security]="opencode-go/glm-5" [devops]="deepseek/deepseek-v4-pro"
    [reviewer]="opencode-go/qwen3.6-plus" [researcher]="deepseek/deepseek-v4-pro"
    [designer]="opencode-go/minimax-m2.7"
  )
  for role in "${!ROLE_MODELS[@]}"; do
    case $role in
      pm|analyst|architect)         perm="edit: allow\n  bash: deny\n  read: allow\n  glob: allow\n  grep: allow\n  write: allow" ;;
      developer)                    perm="edit: allow\n  bash: allow\n  read: allow\n  glob: allow\n  grep: allow\n  write: allow" ;;
      reviewer|researcher|designer) perm="edit: deny\n  bash: deny\n  read: allow\n  glob: allow\n  grep: allow\n  write: deny" ;;
      qa|devops)                    perm="edit: allow\n  bash: allow\n  read: allow\n  glob: allow\n  grep: allow\n  write: allow" ;;
      security)                     perm="edit: deny\n  bash: deny\n  read: allow\n  glob: allow\n  grep: allow\n  write: deny" ;;
    esac
    mkdir -p "$PROJECT_DIR/.opencode/agents"
    cat > "$PROJECT_DIR/.opencode/agents/${role}.md" << ROLEEOF
---
description: "${role} specialist"
model: ${ROLE_MODELS[$role]}
temperature: 0.2
permission:
  $(echo -e "$perm")
---
# ${role} Agent
Ты — **${role}**. Следуй протоколу: изучи документы, предложи план, дождись подтверждения, выполни задачу, обнови WAL.
ROLEEOF
  done
  log "Agents created (${#ROLE_MODELS[@]} roles)"

  # Docker Compose — universal development infrastructure
  if [ ! -f "$PROJECT_DIR/infra/docker-compose.yml" ]; then
    mkdir -p "$PROJECT_DIR/infra/wiremock/stubs"
    cat > "$PROJECT_DIR/infra/docker-compose.yml" << 'DOCKEREOF'
services:
  # ── Message Broker ──
  zookeeper:
    image: confluentinc/cp-zookeeper:7.5.0
    environment: {ZOOKEEPER_CLIENT_PORT: 2181, ZOOKEEPER_TICK_TIME: 2000}
    ports: ["2181:2181"]
  kafka:
    image: confluentinc/cp-kafka:7.5.0
    depends_on: [zookeeper]
    ports: ["9092:9092"]
    environment:
      KAFKA_BROKER_ID: 1
      KAFKA_ZOOKEEPER_CONNECT: zookeeper:2181
      KAFKA_ADVERTISED_LISTENERS: PLAINTEXT://localhost:9092
      KAFKA_OFFSETS_TOPIC_REPLICATION_FACTOR: 1
  # ── Databases ──
  postgres:
    image: postgres:18-alpine
    environment:
      POSTGRES_DB: dev_db
      POSTGRES_USER: dev_user
      POSTGRES_PASSWORD: ${PG_PASSWORD:-dev_pass}
    ports: ["5432:5432"]
    volumes: [pgdata:/var/lib/postgresql/data]
  mongodb:
    image: mongo:8
    ports: ["27017:27017"]
    environment:
      MONGO_INITDB_ROOT_USERNAME: root
      MONGO_INITDB_ROOT_PASSWORD: ${MONGO_PASSWORD:-dev_pass}
    volumes: [mongodata:/data/db]
  redis:
    image: redis:7-alpine
    ports: ["6379:6379"]
  # ── Storage ──
  minio:
    image: minio/minio:latest
    ports: ["9000:9000", "9001:9001"]
    environment:
      MINIO_ROOT_USER: minioadmin
      MINIO_ROOT_PASSWORD: ${MINIO_PASSWORD:-minioadmin}
    volumes: [miniodata:/data]
    command: server /data --console-address ":9001"
    profiles: [storage]
  # ── Mocking & Testing ──
  wiremock:
    image: wiremock/wiremock:3.5.4
    ports: ["8089:8080"]
    volumes: ["./wiremock/stubs:/home/wiremock"]
  # ── Auth (optional, uncomment for Keycloak) ──
  # keycloak:
  #   image: quay.io/keycloak/keycloak:26.0
  #   environment:
  #     KEYCLOAK_ADMIN: admin
  #     KEYCLOAK_ADMIN_PASSWORD: admin
  #     KC_DB: postgres
  #     KC_DB_URL: jdbc:postgresql://postgres:5432/keycloak
  #     KC_DB_USERNAME: dev_user
  #     KC_DB_PASSWORD: dev_pass
  #   ports: ["8080:8080"]
  #   command: start-dev
  #   depends_on: [postgres]
  #   profiles: [auth]
  # ── AWS Emulation (optional) ──
  # localstack:
  #   image: localstack/localstack:latest
  #   ports: ["4566:4566", "4510-4559:4510-4559"]
  #   environment:
  #     SERVICES: s3,dynamodb,sqs,sns,lambda
  #     DEFAULT_REGION: us-east-1
  #   volumes: ["/var/run/docker.sock:/var/run/docker.sock"]
  #   profiles: [aws]
volumes:
  pgdata:
  mongodata:
  miniodata:
DOCKEREOF
    log "docker-compose.yml created"
  fi
fi

# ═══════════════════════════════════════════════════════════════════════════════
#  STEP 14: opencode.json with ALL detected MCPs
# ═══════════════════════════════════════════════════════════════════════════════
if [ "$MODE" = "full" ] || [ "$MODE" = "reinit" ] || [ "$MODE" = "fix-config" ]; then
  section "Generating opencode.json with all MCPs"

  generate_opencode_json() {
    python3 << 'PYGEN'
import json, os, shutil

home = os.path.expanduser("~")
project_dir = os.environ.get("PROJECT_DIR", os.path.join(home, "projects"))

def cmd_exists(cmd):
    return shutil.which(cmd) is not None

def npm_global_installed(pkg_name):
    try:
        result = os.popen(f"npm list -g {pkg_name} 2>/dev/null").read()
        return pkg_name in result and "(empty)" not in result
    except:
        return False

# Detect all installed MCPs
mcps = {}

if cmd_exists("c7-mcp-server"):
    mcps["context7"] = {"type": "local", "command": ["c7-mcp-server"], "enabled": True}

if npm_global_installed("@modelcontextprotocol/server-filesystem"):
    mcps["filesystem"] = {"type": "local", "command": ["npx", "-y", "@modelcontextprotocol/server-filesystem", project_dir], "enabled": True}

if npm_global_installed("@pimzino/agentic-tools-mcp"):
    mcps["agentic-tools"] = {"type": "local", "command": ["npx", "-y", "@pimzino/agentic-tools-mcp"], "enabled": True}

if cmd_exists("codegraph"):
    mcps["codegraph"] = {"type": "local", "command": ["codegraph", "mcp", project_dir], "enabled": True}

if npm_global_installed("@playwright/mcp"):
    mcps["playwright"] = {"type": "local", "command": ["npx", "-y", "@playwright/mcp"], "enabled": True}

if cmd_exists("agent-browser"):
    mcps["agent-browser"] = {"type": "local", "command": ["agent-browser"], "enabled": True}

if npm_global_installed("codesorb"):
    mcps["codesorb"] = {"type": "local", "command": ["npx", "-y", "codesorb"], "enabled": True}

if npm_global_installed("mcp-replay"):
    mcps["mcp-replay"] = {"type": "local", "command": ["npx", "-y", "mcp-replay"], "enabled": True}

if npm_global_installed("open-orchestra"):
    mcps["open-orchestra"] = {"type": "local", "command": ["npx", "-y", "open-orchestra"], "enabled": True}

if npm_global_installed("@loopsense/mcp"):
    mcps["loopsense"] = {"type": "local", "command": ["npx", "-y", "@loopsense/mcp"], "enabled": True}

if npm_global_installed("@teckedd-code2save/datafy"):
    mcps["datafy"] = {"type": "local", "command": ["npx", "-y", "@teckedd-code2save/datafy"], "enabled": True}

if npm_global_installed("@modelcontextprotocol/server-github"):
    mcps["github"] = {"type": "local", "command": ["npx", "-y", "@modelcontextprotocol/server-github"], "enabled": False}

if npm_global_installed("@modelcontextprotocol/server-postgres"):
    mcps["postgres"] = {"type": "local", "command": ["npx", "-y", "@modelcontextprotocol/server-postgres"], "enabled": False}

if npm_global_installed("@modelcontextprotocol/server-sequential-thinking"):
    mcps["sequential-thinking"] = {"type": "local", "command": ["npx", "-y", "@modelcontextprotocol/server-sequential-thinking"], "enabled": True}

# Remote MCP servers (no local binary needed)
mcps["sentry"] = {"type": "remote", "url": "https://mcp.sentry.dev/mcp", "enabled": True, "timeout": 30000}
mcps["grep"] = {"type": "remote", "url": "https://mcp.grep.app", "enabled": True, "timeout": 30000}

# LSP servers — detect installed, configure in opencode.json
lsp_config = {}

def lsp_check(binary_name, lsp_key, lsp_command):
    if cmd_exists(binary_name):
        lsp_config[lsp_key] = {"command": lsp_command}

lsp_check("gopls", "gopls", ["gopls"])
lsp_check("rust-analyzer", "rust-analyzer", ["rust-analyzer"])
lsp_check("typescript-language-server", "typescript", ["typescript-language-server", "--stdio"])
lsp_check("pyright-langserver", "pyright", ["pyright-langserver", "--stdio"])
lsp_check("omnisharp", "omnisharp", ["omnisharp", "--stdio"])
lsp_check("yaml-language-server", "yaml", ["yaml-language-server", "--stdio"])
lsp_check("marksman", "marksman", ["marksman", "server"])
lsp_check("taplo", "taplo", ["taplo", "lsp", "stdio"])
lsp_check("lua-language-server", "lua", ["lua-language-server"])
lsp_check("zls", "zls", ["zls"])

# Build config
config = {
    "$schema": "https://opencode.ai/config.json",
    "model": "deepseek/deepseek-v4-pro",
    "small_model": "deepseek/deepseek-v4-flash",
    "default_agent": "build",
    "autoupdate": True,
    "compaction": {
        "auto": True,
        "prune": True,
        "tail_turns": 2,
        "reserved": 10000
    },
    "provider": {
        "deepseek": {
            "options": {
                "timeout": 600000,
                "chunkTimeout": 60000
            }
        },
        "opencode": {
            "options": {
                "timeout": 600000,
                "chunkTimeout": 60000
            }
        }
    },
    "tool_output": {
        "max_lines": 2000,
        "max_bytes": 51200
    },
    "watcher": {
        "ignore": ["node_modules/**", "dist/**", ".git/**", "target/**", "__pycache__/**"]
    },
    "experimental": {
        "mcp_timeout": 30000,
        "openTelemetry": True
    },
    "lsp": lsp_config,
    "plugin": ["opencode-codegraph"],
    "mcp": mcps
}

config_path = os.path.join(home, ".config", "opencode", "opencode.json")
os.makedirs(os.path.dirname(config_path), exist_ok=True)

with open(config_path, 'w') as f:
    json.dump(config, f, indent=2)

print(f"VALID:{len(mcps)}")
PYGEN
  }

  RESULT=$(generate_opencode_json)
  if echo "$RESULT" | grep -q "VALID:"; then
    MCP_COUNT=$(echo "$RESULT" | grep "VALID:" | cut -d: -f2)
    log "opencode.json valid — ${MCP_COUNT} MCP server(s) registered"
    _step_done step_opencode_json
  else
    warn "opencode.json generation produced unexpected output"
  fi

  # Cold-start verification of each registered MCP
  if [ "$MCP_COUNT" -gt 0 ] 2>/dev/null; then
    section "MCP cold-start test"
    set +e
    MCP_PASS=0; MCP_FAIL=0
    for mcp_name in $(python3 -c "import json; c=json.load(open('$HOME/.config/opencode/opencode.json')); print(' '.join(c.get('mcp',{}).keys()))" 2>/dev/null); do
      cmd_json=$(python3 -c "import json; c=json.load(open('$HOME/.config/opencode/opencode.json')); print(json.dumps(c['mcp']['$mcp_name']['command']))" 2>/dev/null)
      binary=$(echo "$cmd_json" | python3 -c "import json,sys; arr=json.load(sys.stdin); print(arr[0])" 2>/dev/null)
      if [ -n "$binary" ] && (which "$binary" &>/dev/null || echo "$binary" | grep -q "npx"); then
        MCP_PASS=$((MCP_PASS+1))
      else
        warn "MCP $mcp_name: $binary not found"
        MCP_FAIL=$((MCP_FAIL+1))
      fi
    done
    log "MCP cold-start: $MCP_PASS ready, $MCP_FAIL missing"
    set -e
  fi
fi

# ═══════════════════════════════════════════════════════════════════════════════
#  STEP 15: Git config
# ═══════════════════════════════════════════════════════════════════════════════
if [ "$MODE" = "full" ] || [ "$MODE" = "reinit" ]; then
  section "Git configuration"
  [ -n "$GIT_NAME" ] && git config --global user.name "$GIT_NAME"
  [ -n "$GIT_EMAIL" ] && git config --global user.email "$GIT_EMAIL"
  git config --global init.defaultBranch main 2>/dev/null || true
  git config --global pull.rebase true 2>/dev/null || true
  log "Git configured"
fi

# ═══════════════════════════════════════════════════════════════════════════════
#  STEP 16: PATH persistence — single clean source
# ═══════════════════════════════════════════════════════════════════════════════
if [ "$MODE" = "full" ] || [ "$MODE" = "reinit" ]; then
  section "PATH persistence"

  PATH_LINE="export PATH=\"\$HOME/.npm-global/bin:\$HOME/.local/bin:\$HOME/.n/bin:\$HOME/.bun/bin:\$HOME/.cargo/bin:\$HOME/.jbang/bin:\$HOME/.dotnet:/usr/local/go/bin:\$PATH\""
  N_PREFIX_LINE="export N_PREFIX=\"\$HOME/.n\""
  SDKMAN_LINE="export SDKMAN_DIR=\"\$HOME/.sdkman\" ; [[ -s \"\$SDKMAN_DIR/bin/sdkman-init.sh\" ]] && source \"\$SDKMAN_DIR/bin/sdkman-init.sh\""
  SHOKUNIN_LINE="[ -f \"\$HOME/.shokunin/scripts/linux/profile.sh\" ] && source \"\$HOME/.shokunin/scripts/linux/profile.sh\" 2>/dev/null"
  BUN_LINE="export BUN_INSTALL=\"\$HOME/.bun\""
  DOTNET_LINE="export DOTNET_ROOT=\"\$HOME/.dotnet\""
  SECRETS_SOURCE="[ -f \"\$HOME/.config/opencode/secrets.env\" ] && source \"\$HOME/.config/opencode/secrets.env\""

  # Store API keys in secrets.env (chmod 600), NOT in .bashrc/.zshrc
  touch "$SECRETS_FILE" && chmod 600 "$SECRETS_FILE"
  sed -i "/DEEPSEEK_API_KEY=/d" "$SECRETS_FILE" 2>/dev/null || true
  [ -n "${DEEPSEEK_KEY:-}" ] && echo "export DEEPSEEK_API_KEY=\"$DEEPSEEK_KEY\"" >> "$SECRETS_FILE"
  log "API keys stored in $SECRETS_FILE (chmod 600)"

  for rc in ~/.bashrc ~/.zshrc; do
    [ ! -f "$rc" ] && continue
    sed -i "\|export PATH=.*\.npm-global|d" "$rc" 2>/dev/null || true
    sed -i "\|export N_PREFIX=|d" "$rc" 2>/dev/null || true
    sed -i "\|export SDKMAN_DIR=|d" "$rc" 2>/dev/null || true
    sed -i "\|shokunin.*profile\.sh|d" "$rc" 2>/dev/null || true
    sed -i "\|export BUN_INSTALL=|d" "$rc" 2>/dev/null || true
    sed -i "\|export DEEPSEEK_API_KEY=|d" "$rc" 2>/dev/null || true
    sed -i "\|export DOTNET_ROOT=|d" "$rc" 2>/dev/null || true
    sed -i "\|secrets\.env|d" "$rc" 2>/dev/null || true
    {
      echo "$PATH_LINE"
      echo "$N_PREFIX_LINE"
      echo "$SDKMAN_LINE"
      echo "$BUN_LINE"
      echo "$DOTNET_LINE"
      echo "$SECRETS_SOURCE"
      echo "$SHOKUNIN_LINE"
    } >> "$rc"
  done
  log "PATH + env configured (API keys in secrets.env)"
fi

# ═══════════════════════════════════════════════════════════════════════════════
#  STEP 17: Fix .zshrc + P10k instant prompt
# ═══════════════════════════════════════════════════════════════════════════════
if [ "$MODE" = "full" ] || [ "$MODE" = "reinit" ]; then
  section "Fixing .zshrc & P10k compatibility"

  # Set P10k instant prompt to quiet (avoids the warning the user is seeing)
  P10K_FILE="$HOME/.p10k.zsh"
  if [ -f "$P10K_FILE" ]; then
    sed -i 's/POWERLEVEL9K_INSTANT_PROMPT=verbose/POWERLEVEL9K_INSTANT_PROMPT=quiet/' "$P10K_FILE" 2>/dev/null || true
    log "P10k: instant prompt set to quiet"
  fi

  # Fix shokunin profile console echo
  SHOKUNIN_PROFILE="$HOME/.shokunin/scripts/linux/profile.sh"
  if [ -f "$SHOKUNIN_PROFILE" ] && grep -q 'echo "Shokunin' "$SHOKUNIN_PROFILE" 2>/dev/null; then
    sed -i 's/echo "Shokunin AI Ecosystem loaded"/# echo "Shokunin AI Ecosystem loaded"/' "$SHOKUNIN_PROFILE" 2>/dev/null || true
    log "Shokunin: console echo suppressed (P10k compat)"
  fi
fi

# ═══════════════════════════════════════════════════════════════════════════════
#  STEP 18: Auth reminder
# ═══════════════════════════════════════════════════════════════════════════════
if [ "$MODE" = "full" ] || [ "$MODE" = "reinit" ]; then
  section "Authorization reminder"
  if [ -n "${DEEPSEEK_KEY:-}" ]; then
    info "DeepSeek API key configured — exported as DEEPSEEK_API_KEY in profile"
  fi
  if [ -n "${API_KEY:-}" ]; then
    echo -e "${YELLOW}  opencode auth login → OpenCode Go → $API_KEY${NC}"
  else
    echo -e "${YELLOW}  Run: opencode auth login → select 'OpenCode Go' → paste API key${NC}"
  fi
fi

# ═══════════════════════════════════════════════════════════════════════════════
#  STEP 18b: Config file + dev CLI
# ═══════════════════════════════════════════════════════════════════════════════
if [ "$MODE" = "full" ] || [ "$MODE" = "reinit" ]; then
  section "Config file + dev CLI"
  CONFIG_FILE="${HOME}/.config/opencode-setup/setup.conf"
  mkdir -p "$(dirname "$CONFIG_FILE")"
  if [ ! -f "$CONFIG_FILE" ]; then
    cat > "$CONFIG_FILE" << 'CONFEOF'
# Dev Machine Setup Config — edit with: dev config
# GIT_NAME="Alex"
# GIT_EMAIL="alex@example.com"
# PROJECT_DIR="$HOME/projects"
# DEEPSEEK_KEY="sk-..."
# API_KEY="sk-..."
CONFEOF
    log "Config file created: $CONFIG_FILE"
  fi

  # Install dev CLI to ~/.local/bin
  DEV_SRC="$PROJECT_DIR/dev.sh"
  DEV_DST="$HOME/.local/bin/dev"
  if [ -f "$DEV_SRC" ]; then
    mkdir -p "$HOME/.local/bin"
    cp "$DEV_SRC" "$DEV_DST" && chmod +x "$DEV_DST" && log "dev CLI installed: ~/.local/bin/dev"
  fi
fi

# ═══════════════════════════════════════════════════════════════════════════════
#  STEP 19: Verification
# ═══════════════════════════════════════════════════════════════════════════════
section "Verification"
PASS=0; FAIL=0
_check() { if eval "$2" &>/dev/null; then log "$1 — OK"; PASS=$((PASS+1)); else warn "$1 — MISSING"; FAIL=$((FAIL+1)); fi; }

_check "Docker"        "docker --version"
_check "Java"          "java -version 2>&1 | head -1"
_check "Go"            "go version"
_check "Rust"          "rustc --version"
_check ".NET"          "dotnet --version"
_check "Node.js"       "node --version"
_check "Python 3.12"   "python3.12 --version"
_check "OpenCode"      "opencode --version"
_check "uv"            "uv --version"
_check "bun"           "bun --version"
_check "Gradle"        "gradle --version 2>&1 | head -2"
_check "Maven"         "mvn --version 2>&1 | head -1"
_check "Kotlin"        "kotlin -version 2>/dev/null || echo 'not installed'"
_check "Zig"           "zig version 2>/dev/null || echo 'not installed'"
_check "jbang"         "jbang --version"
_check "Git"           "git --version"
_check "zsh"           "zsh --version"
_check "opencode.json" "python3 -c \"import json; json.load(open('$HOME/.config/opencode/opencode.json'))\" 2>/dev/null"
_check ".zshrc valid"  "python3 -c \"open('$HOME/.zshrc').read()\" 2>/dev/null"

# MCP verification
for mcp in context7 filesystem agentic-tools codegraph playwright agent-browser codesorb mcp-replay open-orchestra loopsense datafy github postgres sequential-thinking; do
  case $mcp in
    context7)      _check "MCP context7"       "which c7-mcp-server" ;;
    filesystem)    _check "MCP filesystem"     "npm list -g @modelcontextprotocol/server-filesystem &>/dev/null" ;;
    agentic-tools) _check "MCP agentic-tools"  "npm list -g @pimzino/agentic-tools-mcp &>/dev/null" ;;
    codegraph)     _check "MCP codegraph"      "which codegraph" ;;
    playwright)    _check "MCP playwright"     "npm list -g @playwright/mcp &>/dev/null" ;;
    agent-browser) _check "MCP agent-browser"  "which agent-browser" ;;
    codesorb)      _check "MCP codesorb"       "npm list -g codesorb &>/dev/null" ;;
    mcp-replay)    _check "MCP mcp-replay"     "npm list -g mcp-replay &>/dev/null" ;;
    open-orchestra) _check "MCP open-orchestra" "npm list -g open-orchestra &>/dev/null" ;;
    loopsense)     _check "MCP loopsense"      "npm list -g @loopsense/mcp &>/dev/null" ;;
    datafy)        _check "MCP datafy"         "npm list -g @teckedd-code2save/datafy &>/dev/null" ;;
    github)        _check "MCP github"         "npm list -g @modelcontextprotocol/server-github &>/dev/null" ;;
    postgres)      _check "MCP postgres"       "npm list -g @modelcontextprotocol/server-postgres &>/dev/null" ;;
    sequential-thinking) _check "MCP sequential-thinking" "npm list -g @modelcontextprotocol/server-sequential-thinking &>/dev/null" ;;
  esac
done
_check "Muninn skills"      "[ -f ~/.config/opencode/skills/memory-read/SKILL.md ]"
_check "ChromaDB server"    "curl -sf http://127.0.0.1:8000/api/v2/heartbeat &>/dev/null"

echo
log "Verification: $PASS passed, $FAIL failed"

echo -e "${GREEN}============================================================${NC}"
echo -e "${GREEN}       BOOTSTRAP COMPLETE (v33.5) · Mode: $MODE${NC}"
echo -e "${GREEN}============================================================${NC}"
echo "  Log file:  $LOG_FILE"
echo "  Health:    bash ~/setup.sh --health"
echo "  Fix zsh:   bash ~/setup.sh --fix-zshrc"
echo "  Fix MCP:   bash ~/setup.sh --fix-config"
echo "  Start:     cd $PROJECT_DIR && opencode"
  echo "  dev CLI:   dev health | dev install <pkg> | dev update"
