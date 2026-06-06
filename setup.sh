#!/usr/bin/env bash
# ============================================================================
#  Ultimate Dev Machine Bootstrap v34.0 — Modular
set -euo pipefail; IFS=$'\n\t'

# ── Source infrastructure (must be first) ────────────────────────────────────
source "$(cd "$(dirname "$0")" && pwd)/lib/helpers.sh"
source "$(cd "$(dirname "$0")" && pwd)/lib/00-core.sh"

# ── CLI argument parsing ────────────────────────────────────────────────────
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
  --xai-key)           XAI_KEY="$2"; shift 2;;
  --mimo-key)          MIMO_KEY="$2"; shift 2;;
  --moonshot-key)      MOONSHOT_KEY="$2"; shift 2;;
  --minimax-key)       MINIMAX_KEY="$2"; shift 2;;
  --github-token)      GITHUB_TOKEN="$2"; shift 2;;
  --gitlab-token)      GITLAB_TOKEN="$2"; shift 2;;
  --google-maps-key)   GOOGLE_MAPS_KEY="$2"; shift 2;;
  --fzf-key)           FZF_KEY="$2"; shift 2;;
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
  --deepseek-key      DeepSeek API key
  --xai-key           xAI Grok API key
  --mimo-key          Xiaomi MiMo API key
  --moonshot-key      Moonshot (Kimi K2.6) API key
  --minimax-key       MiniMax M3 API key
  --github-token      GitHub personal access token (for MCP, gh CLI, etc.)
  --gitlab-token      GitLab personal access token (for GitLab MCP)
  --google-maps-key   Google Maps API key (for location-aware MCP)
  -n, --git-name      Git user name
  -e, --git-email     Git user email
  --fzf-key           FZF key binding for zsh (default: ^T)
  --dry-run           Preview mode: show what would be installed, make no changes
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

# ── DNS + CA certs — only for full/reinit/update modes ──────────────────────
if [ "$MODE" = "full" ] || [ "$MODE" = "reinit" ] || [ "$MODE" = "update" ]; then
  _set_dns; _install_ca_certs
fi

# ── Early-exit modes ─────────────────────────────────────────────────────────
if [ "$MODE" = "health" ]; then    source "$SCRIPT_DIR/modes/health.sh";      fi
if [ "$MODE" = "fix-zshrc" ]; then source "$SCRIPT_DIR/modes/fix-zshrc.sh";   fi
if [ "$MODE" = "upgrade" ]; then   source "$SCRIPT_DIR/modes/upgrade.sh";     fi
if [ "$MODE" = "interactive" ]; then source "$SCRIPT_DIR/modes/interactive.sh"; fi

# ── Preflight: network check + WSL2 fix ─────────────────────────────────────
section "Network check"
NET_OK=true
info "Testing connectivity to key services..."

if [ -f /etc/resolv.conf ] && ! grep -qE '8\.8\.8\.8|1\.1\.1\.1' /etc/resolv.conf 2>/dev/null; then
  info "WSL2: adding Google/Cloudflare DNS fallback"
  echo "nameserver 8.8.8.8" | sudo tee -a /etc/resolv.conf 2>/dev/null || true
  echo "nameserver 1.1.1.1" | sudo tee -a /etc/resolv.conf 2>/dev/null || true
fi

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

PROXY_ENV=$(cmd.exe /c "reg query \"HKCU\\Software\\Microsoft\\Windows\\CurrentVersion\\Internet Settings\" /v ProxyServer" 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+:[0-9]+' || true)
if [ -n "${PROXY_ENV:-}" ]; then
  export HTTPS_PROXY="http://${PROXY_ENV}" HTTP_PROXY="http://${PROXY_ENV}"
  info "WSL2 proxy detected: $PROXY_ENV"
  _check_net && log "Proxy connectivity OK"
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

# ── Auth + project dir ──────────────────────────────────────────────────────
PROJECT_DIR="${PROJECT_DIR:-$HOME/projects}"
export PROJECT_DIR
API_KEY="${API_KEY:-}"
DEEPSEEK_KEY="${DEEPSEEK_KEY:-}"
GITHUB_TOKEN="${GITHUB_TOKEN:-}"
GITLAB_TOKEN="${GITLAB_TOKEN:-}"
GOOGLE_MAPS_KEY="${GOOGLE_MAPS_KEY:-}"
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
echo -e "${GREEN}     Ultimate Dev Machine Bootstrap ${SCRIPT_VERSION}${NC}"
echo -e "${GREEN}     Mode: $MODE${NC}"
echo -e "${GREEN}     Log:  $LOG_FILE${NC}"
echo -e "${GREEN}============================================================${NC}"

# ── Execute steps ───────────────────────────────────────────────────────────
_step_skip step_system     || source "$SCRIPT_DIR/lib/01-system.sh"
_step_skip step_docker     || source "$SCRIPT_DIR/lib/02-docker.sh"
_step_skip step_chrome     || source "$SCRIPT_DIR/lib/03-chrome.sh"
_step_skip step_zsh        || source "$SCRIPT_DIR/lib/04-zsh.sh"
_step_skip step_java       || source "$SCRIPT_DIR/lib/05-java.sh"
_step_skip step_node       || source "$SCRIPT_DIR/lib/06-node.sh"
_step_skip step_python     || source "$SCRIPT_DIR/lib/07-python.sh"
_step_skip step_go         || source "$SCRIPT_DIR/lib/08-go.sh"
_step_skip step_rust       || source "$SCRIPT_DIR/lib/09-rust.sh"
_step_skip step_dotnet     || source "$SCRIPT_DIR/lib/10-dotnet.sh"

# ── Clean old configs ────────────────────────────────────────────────────────
if [ "$MODE" = "full" ] || [ "$MODE" = "reinit" ]; then
  section "Cleaning old configs & stale agents"
  rm -rf ~/.cache/opencode ~/.local/share/opencode ~/.opencode ~/opencode.json
  mkdir -p ~/.config/opencode
  for scout_path in \
    "$PROJECT_DIR/.opencode/agents/scout.md" \
    "$HOME/.config/opencode/agents/scout.md" \
    "$HOME/.opencode/agents/scout.md"; do
    [ -f "$scout_path" ] && rm -f "$scout_path" && warn "Removed stale agent: $scout_path"
  done
  log "Old configs cleaned"
fi

_step_skip step_opencode   || source "$SCRIPT_DIR/lib/11-opencode.sh"
_step_skip step_mcp        || source "$SCRIPT_DIR/lib/12-mcp-lsp.sh"
_step_skip step_chromadb   || source "$SCRIPT_DIR/lib/13-chromadb.sh"
_step_skip step_shokunin   || source "$SCRIPT_DIR/lib/14-shokunin.sh"
_step_skip step_security   || source "$SCRIPT_DIR/lib/15-security.sh"
_step_skip step_llm        || source "$SCRIPT_DIR/lib/16-llm.sh"
_step_skip step_project    || source "$SCRIPT_DIR/lib/17-project.sh"
_step_skip step_json       || source "$SCRIPT_DIR/lib/18-opencode-json.sh"
_step_skip step_finalize   || source "$SCRIPT_DIR/lib/19-finalize.sh"

echo "Bootstrap complete ($SCRIPT_VERSION)"
