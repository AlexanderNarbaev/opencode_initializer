#!/usr/bin/env bash
# ============================================================================
#  Ultimate Dev Machine Bootstrap v2.0.0 — Modular
set -euo pipefail
IFS=$'\n\t'
shopt -s inherit_errexit 2>/dev/null || true

# ── Bootstrap: resolve script dir (supports curl|bash and local runs) ───────
# Portable readlink -f (helpers.sh is not sourced yet — keep in sync with it)
_readlink_f() {
  local target="$1"
  if readlink -f "$target" >/dev/null 2>&1; then
    readlink -f "$target"
    return 0
  fi
  # BSD fallback: follow the symlink chain manually
  local dir link
  while [ -L "$target" ]; do
    dir="$(cd "$(dirname "$target")" 2>/dev/null && pwd)"
    link="$(readlink "$target")"
    case "$link" in
      /*) target="$link" ;;
      *)  target="$dir/$link" ;;
    esac
  done
  if [ -d "$target" ]; then
    (cd "$target" 2>/dev/null && pwd)
  else
    echo "$(cd "$(dirname "$target")" 2>/dev/null && pwd)/$(basename "$target")"
  fi
}

if [ -f "$(cd "$(dirname "$0")" 2>/dev/null && pwd)/src/lib/helpers.sh" ]; then
  SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
elif [ -f "$HOME/opencode_initializer/src/lib/helpers.sh" ]; then
  SCRIPT_DIR="$HOME/opencode_initializer"
elif [ -f "$HOME/setup.sh" ] && [ -f "$(dirname "$(_readlink_f "$HOME/setup.sh")")/src/lib/helpers.sh" ]; then
  SCRIPT_DIR="$(dirname "$(_readlink_f "$HOME/setup.sh")")"
else
  # Running from curl|bash — auto-clone the repo
  REPO_URL="https://github.com/AlexanderNarbaev/opencode_initializer.git"
  CACHE_DIR="${HOME}/.cache/opencode-setup/repo"
  if [ -d "$CACHE_DIR/.git" ]; then
    git -C "$CACHE_DIR" pull --ff-only -q 2>/dev/null || true
  else
    mkdir -p "$(dirname "$CACHE_DIR")"
    git clone --depth 1 -q "$REPO_URL" "$CACHE_DIR" 2>/dev/null || {
      echo "ERROR: Cannot clone $REPO_URL — check network"
      exit 1
    }
  fi
  SCRIPT_DIR="$CACHE_DIR"
  # Re-exec from local copy so $0 is a real path
  exec bash "$SCRIPT_DIR/setup.sh" "$@"
fi
export SCRIPT_DIR

# ── Source infrastructure (must be first) ────────────────────────────────────
source "$SCRIPT_DIR/src/lib/helpers.sh"
source "$SCRIPT_DIR/src/lib/00-core.sh"
source "$SCRIPT_DIR/src/lib/00d-parallel.sh"
source "$SCRIPT_DIR/src/lib/00e-cache-mgr.sh"
source "$SCRIPT_DIR/src/lib/00f-apm.sh"
source "$SCRIPT_DIR/src/lib/00g-apm-integration.sh"
source "$SCRIPT_DIR/src/lib/00h-multi-agent.sh"
source "$SCRIPT_DIR/src/lib/00i-mirrors.sh"
source "$SCRIPT_DIR/src/lib/00j-auto-sync.sh"
source "$SCRIPT_DIR/src/lib/00k-security-scan.sh"
source "$SCRIPT_DIR/src/lib/00l-benchmark.sh"

# ── Logging — tee all output to timestamped log ─────────────────────────────
SETUP_LOG="${HOME}/.cache/opencode-setup/setup-$(date +%Y%m%d-%H%M%S).log"
mkdir -p "$(dirname "$SETUP_LOG")"
exec > >(tee -a "$SETUP_LOG") 2>&1
log "Setup log: $SETUP_LOG"

# ── CLI argument parsing ────────────────────────────────────────────────────
MODE="full"
NEW_PROJECT_DIR=""
# shellcheck disable=SC2034  # API key vars assigned from CLI args, exported for child processes at ~L490
while [[ $# -gt 0 ]]; do case $1 in
  --full)
    MODE="full"
    shift
    ;;
  --reinit)
    MODE="reinit"
    shift
    ;;
  --new)
    MODE="new"
    NEW_PROJECT_DIR="${2:-}"
    [ -z "$NEW_PROJECT_DIR" ] && {
      warn "Usage: --new <dir>"
      exit 1
    }
    shift 2
    ;;
  --health)
    MODE="health"
    shift
    ;;
  --update)
    MODE="update"
    shift
    ;;
  --upgrade)
    MODE="upgrade"
    shift
    ;;
  --interactive)
    MODE="interactive"
    shift
    ;;
  --ci)
    MODE="ci"
    shift
    ;;
  --isolated)
    ISOLATED_CIRCUIT="true"
    shift
    ;;
  --no-isolated)
    ISOLATED_CIRCUIT="false"
    shift
    ;;
  --airgap)
    ISOLATED_CIRCUIT="true"
    MODE="airgap"
    shift
    ;;
  --config)
    CONFIG_TOML="$2"
    shift 2
    ;;
  --print-config)
    MODE="print-config"
    shift
    ;;
  --skip)
    SKIP_FLAGS="$2"
    shift 2
    ;;
  --parallel)
    PARALLEL_INSTALL=true
    PARALLEL_MAX_JOBS="${2:-$(nproc 2>/dev/null || echo 4)}"
    shift 2
    ;;
  --no-parallel)
    PARALLEL_INSTALL=false
    shift
    ;;
  --apm)
    GENERATE_APM=true
    shift
    ;;
  --multi-agent)
    GENERATE_MULTI_AGENT=true
    shift
    ;;
  --copilot)
    GENERATE_COPILOT=true
    shift
    ;;
  --claude)
    GENERATE_CLAUDE=true
    shift
    ;;
  --cursor)
    GENERATE_CURSOR=true
    shift
    ;;
  --vscode)
    GENERATE_VSCODE=true
    shift
    ;;
  --mirrors)
    CONFIGURE_MIRRORS=true
    MIRROR_REGION="${2:-auto}"
    shift 2
    ;;
  --sync)
    RUN_SYNC=true
    shift
    ;;
  --sync-force)
    RUN_SYNC=true
    SYNC_FORCE=true
    shift
    ;;
  --auto-sync)
    START_AUTO_SYNC=true
    shift
    ;;
  --security-scan)
    RUN_SECURITY_SCAN=true
    shift
    ;;
  --install-hooks)
    INSTALL_SECURITY_HOOKS=true
    shift
    ;;
  --benchmark)
    RUN_BENCHMARK=true
    shift
    ;;
  --force)
    FORCE_REINSTALL=true
    shift
    ;;
  --dry-run)
    MODE="dry-run"
    DRY_RUN=true
    shift
    ;;
  --fix-config)
    MODE="fix-config"
    shift
    ;;
  --fix-zshrc)
    MODE="fix-zshrc"
    shift
    ;;
  -p | --project-dir)
    PROJECT_DIR="$2"
    shift 2
    ;;
  -k | --api-key)
    API_KEY="$2"
    shift 2
    ;;
  --deepseek-key)
    DEEPSEEK_KEY="$2"
    shift 2
    ;;
  --zai-key)
    ZAI_KEY="$2"
    shift 2
    ;;
  --openrouter-key)
    OPENROUTER_KEY="$2"
    shift 2
    ;;
  --xai-key)
    XAI_KEY="$2"
    shift 2
    ;;
  --mimo-key)
    MIMO_KEY="$2"
    shift 2
    ;;
  --minimax-key)
    MINIMAX_KEY="$2"
    shift 2
    ;;
  --openai-key)
    OPENAI_API_KEY="$2"
    shift 2
    ;;
  --anthropic-key)
    ANTHROPIC_API_KEY="$2"
    shift 2
    ;;
  --google-key)
    GOOGLE_API_KEY="$2"
    shift 2
    ;;
  --mistral-key)
    MISTRAL_API_KEY="$2"
    shift 2
    ;;
  --groq-key)
    GROQ_API_KEY="$2"
    shift 2
    ;;
  --together-key)
    TOGETHER_API_KEY="$2"
    shift 2
    ;;
  --cohere-key)
    COHERE_API_KEY="$2"
    shift 2
    ;;
  --fireworks-key)
    FIREWORKS_API_KEY="$2"
    shift 2
    ;;
  --cerebras-key)
    CEREBRAS_API_KEY="$2"
    shift 2
    ;;
  --perplexity-key)
    PERPLEXITY_API_KEY="$2"
    shift 2
    ;;
  --alibaba-key)
    ALIBABA_KEY="$2"
    shift 2
    ;;
  --deepinfra-key)
    DEEPINFRA_KEY="$2"
    shift 2
    ;;
  --github-token)
    GITHUB_TOKEN="$2"
    shift 2
    ;;
  --gitlab-token)
    GITLAB_TOKEN="$2"
    shift 2
    ;;
  --gitverse-token)
    GITVERSE_TOKEN="$2"
    shift 2
    ;;
  --google-maps-key)
    GOOGLE_MAPS_KEY="$2"
    shift 2
    ;;
  --fzf-key)
    FZF_KEY="$2"
    shift 2
    ;;
  --devbox-skip)
    SKIP_DEVBOX=true
    shift
    ;;
  --skip-caching)
    SKIP_CACHING=true
    shift
    ;;
  --dotfiles-skip)
    SKIP_DOTFILES=true
    shift
    ;;
  --with-postgres)
    INFRA_SERVICES="${INFRA_SERVICES:-}postgres "
    shift
    ;;
  --with-qdrant)
    INFRA_SERVICES="${INFRA_SERVICES:-}qdrant "
    shift
    ;;
  --with-redis)
    INFRA_SERVICES="${INFRA_SERVICES:-}redis "
    shift
    ;;
  --with-kafka)
    INFRA_SERVICES="${INFRA_SERVICES:-}kafka "
    shift
    ;;
  --with-neo4j)
    INFRA_SERVICES="${INFRA_SERVICES:-}neo4j "
    shift
    ;;
  --with-minio)
    INFRA_SERVICES="${INFRA_SERVICES:-}minio "
    shift
    ;;
  --with-all-infra)
    INFRA_SERVICES="postgres qdrant redis kafka neo4j minio"
    shift
    ;;
  --with-observability)
    INFRA_SERVICES="${INFRA_SERVICES:-}prometheus grafana "
    OBSERVABILITY_ENABLED=true
    shift
    ;;
  --with-prometheus)
    INFRA_SERVICES="${INFRA_SERVICES:-}prometheus "
    OBSERVABILITY_ENABLED=true
    shift
    ;;
  --with-grafana)
    INFRA_SERVICES="${INFRA_SERVICES:-}grafana "
    OBSERVABILITY_ENABLED=true
    shift
    ;;
  -n | --git-name)
    GIT_NAME="$2"
    shift 2
    ;;
  -e | --git-email)
    GIT_EMAIL="$2"
    shift 2
    ;;
  -s | --sudo-pass)
    echo "[DEPRECATED] -s/--sudo-pass is deprecated. Use 'read -s' interactively or SUDO_PASS env variable." >&2
    SUDO_PASS="$2"
    shift 2
    ;;
  -h | --help)
    cat <<'USAGE'
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
  --ci                Headless CI/CD mode: OpenCode CLI + essential MCPs only

Options:
  --airgap            Air-gap mode: set ISOLATED_CIRCUIT, bootstrap from offline bundle
  --config FILE       Load configuration from TOML file (precedence: CLI > env > toml > defaults)
  --print-config      Print resolved configuration and exit
  --isolated          Enable Isolated Circuit Mode (local LLM only, no cloud)
  --no-isolated       Disable Isolated Circuit Mode
  -p, --project-dir   Project directory (default: ~/projects)
  -k, --api-key       OpenCode Go API key
  --deepseek-key      DeepSeek API key
  --zai-key           z.ai GLM API key
  --openrouter-key    OpenRouter API key
  --xai-key           xAI Grok API key
  --mimo-key          Xiaomi MiMo API key
  --minimax-key       MiniMax M3 API key
  --openai-key        OpenAI API key
  --anthropic-key     Anthropic Claude API key
  --google-key        Google Gemini API key
  --mistral-key       Mistral API key
  --groq-key          Groq Cloud API key
  --together-key      Together AI API key
  --cohere-key        Cohere API key
  --fireworks-key     Fireworks AI API key
  --cerebras-key      Cerebras API key
  --perplexity-key    Perplexity API key
  --alibaba-key       Alibaba Qwen API key
  --deepinfra-key     DeepInfra API key
  --github-token      GitHub personal access token (for MCP, gh CLI, etc.)
  --gitlab-token      GitLab personal access token (for GitLab MCP)
  --gitverse-token    GitVerse personal access token (for GitVerse Pages)
  --google-maps-key   Google Maps API key (for location-aware MCP)
  -n, --git-name      Git user name
  -e, --git-email     Git user email
  --fzf-key           FZF key binding for zsh (default: ^T)
  --devbox-skip       Skip Devbox (Nix-based isolated dev environments)
  --skip-caching      Skip Prompt Caching Stack (opencode-cache-* plugins)
  --dotfiles-skip     Skip chezmoi dotfiles manager installation
  --with-postgres     Enable PostgreSQL 18 in Docker (needed for memory/plugins)
  --with-qdrant       Enable Qdrant vector DB (needed for code search / RAG)
  --with-redis        Enable Redis 7 cache (needed for sessions / PubSub)
  --with-kafka        Enable Kafka message broker (needed for event streaming)
  --with-neo4j        Enable Neo4j graph DB (needed for knowledge graph)
  --with-minio        Enable MinIO S3 storage (needed for artifacts)
  --with-all-infra    Enable all Docker infrastructure services
  --dry-run           Preview mode: show what would be installed, make no changes
  -s, --sudo-pass     [DEPRECATED] Sudo password (use SUDO_PASS env or read -s instead)
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
    exit 0
    ;;
  *) err "Unknown: $1. Use -h for help." ;;
esac
done

# ── Early-exit modes ─────────────────────────────────────────────────────────
if [ "$MODE" = "health" ]; then source "$SCRIPT_DIR/src/modes/health.sh"; fi
if [ "$MODE" = "ci" ]; then source "$SCRIPT_DIR/src/modes/ci.sh"; fi
if [ "$MODE" = "fix-zshrc" ]; then source "$SCRIPT_DIR/src/modes/fix-zshrc.sh"; fi
if [ "$MODE" = "fix-config" ]; then
  if [ "${DRY_RUN:-false}" = "true" ]; then
    info "[DRY] fix-config — would regenerate ~/.config/opencode/opencode.json"
    exit 0
  fi
  source "$SCRIPT_DIR/src/lib/18-opencode-json.sh"
  section "Done — opencode.json regenerated"
  info "Restart OpenCode to apply changes."
  exit 0
fi
if [ "$MODE" = "print-config" ]; then
  info "Resolved configuration:"
  echo "  MODE=$MODE"
  echo "  PROJECT_DIR=$PROJECT_DIR"
  echo "  GIT_NAME=$GIT_NAME"
  echo "  GIT_EMAIL=$GIT_EMAIL"
  echo "  DEPLOYMENT_PROFILE=$DEPLOYMENT_PROFILE"
  echo "  ISOLATED_CIRCUIT=$ISOLATED_CIRCUIT"
  echo "  INFRA_SERVICES=${INFRA_SERVICES:-}"
  echo "  NODE_VER=$NODE_VER"
  echo "  PYTHON_VER=$PYTHON_VER"
  echo "  GO_VER=$GO_VER"
  [ -n "${CONFIG_TOML:-}" ] && _toml_print_resolved "$CONFIG_TOML"
  exit 0
fi
if [ "$MODE" = "upgrade" ]; then source "$SCRIPT_DIR/src/modes/upgrade.sh"; fi
if [ "$MODE" = "interactive" ]; then source "$SCRIPT_DIR/src/modes/interactive.sh"; fi

# ── Sudo — authenticate before any sudo operations ──────────────────────────
# Fix (P0.1): bash `read -p` writes prompt to STDERR, and `2>/dev/null` was
# swallowing that prompt — making this hang forever with no visible indicator.
# New: try passwordless sudo first, then env, then TTY prompt with -t 30 timeout.
[ "$EUID" -eq 0 ] && err "Do not run as root."

_sudo_prompt_ok() {
  # 1) passwordless sudo (NOPASSWD / already cached)
  if sudo -n true 2>/dev/null; then return 0; fi
  # 2) SUDO_PASS from env
  if [ -n "${SUDO_PASS:-}" ] && printf '%s\n' "$SUDO_PASS" | sudo -S true 2>/dev/null; then
    return 0
  fi
  # 3) Interactive — only on real TTY, with 30s timeout, prompt visible on stderr
  if [ -t 0 ]; then
    printf >&2 "Sudo password (cached, 30s timeout): "
    if IFS= read -r -s -t 30 SUDO_PASS; then
      printf >&2 "\n"
      if [ -n "${SUDO_PASS:-}" ] && printf '%s\n' "$SUDO_PASS" | sudo -S true 2>/dev/null; then
        return 0
      fi
    else
      printf >&2 "\n[sudo prompt timed out]\n"
    fi
  fi
  return 1
}

case "$MODE" in
  new|fix-config|health|ci|fix-zshrc) ;;
  *)
    if ! _sudo_prompt_ok; then
      err "sudo unavailable. Run with --no-sudo (CI), set SUDO_PASS env, or configure NOPASSWD."
    fi
    ;;
esac
sudo -v 2>/dev/null || true

# ── DNS + CA certs — after interactive (which may change MODE to full) ──────
if [ "$MODE" = "full" ] || [ "$MODE" = "reinit" ] || [ "$MODE" = "update" ]; then
  _set_dns
  _install_ca_certs
fi

# ── Preflight: network check + WSL2 fix ─────────────────────────────────────
section "Network check"
NET_OK=true
info "Testing connectivity to key services..."

if [ "${DRY_RUN:-false}" = "true" ]; then
  info "[DRY] skip WSL2 DNS fix (8.8.8.8/1.1.1.1)"
elif [ ! -t 1 ] && ! sudo -n true 2>/dev/null; then
  info "[NON-INTERACTIVE] skipping DNS write (no sudo password available)"
elif [ -f /etc/resolv.conf ] && ! grep -qE '8\.8\.8\.8|1\.1\.1\.1' /etc/resolv.conf 2>/dev/null; then
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
  _check_net && log "WSL2 network recovered" || {
    warn "Network still limited — using apt fallbacks"
    NET_OK=false
  }
fi

if [ -n "${WSL_DISTRO_NAME:-}" ]; then
  PROXY_ENV=$(cmd.exe /c "reg query \"HKCU\\Software\\Microsoft\\Windows\\CurrentVersion\\Internet Settings\" /v ProxyServer" 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+:[0-9]+' || true)
  if [ -n "${PROXY_ENV:-}" ]; then
    export HTTPS_PROXY="http://${PROXY_ENV}" HTTP_PROXY="http://${PROXY_ENV}"
    info "WSL2 proxy detected: $PROXY_ENV"
    _check_net && log "Proxy connectivity OK"
  fi
fi

for svc in "https://github.com" "https://registry.npmjs.org" "https://get.sdkman.io" "https://astral.sh" "https://go.dev"; do
  name=$(echo "$svc" | awk -F/ '{print $3}')
  _curl "$svc" >/dev/null 2>&1 || {
    warn "$name unreachable — using apt"
    [ "$name" = "github.com" ] && NET_OK=false
  }
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
    cat >"$WSL_CONF_FILE" <<'WSLCONF'
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
    sudo tee "$WSL_DIST_CONF" <<'WSLDIST' >/dev/null
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

# ── Auth + project dir ──────────────────────────────────────────────────────
PROJECT_DIR="${PROJECT_DIR:-$HOME/projects}"
export PROJECT_DIR
API_KEY="${API_KEY:-}"
DEEPSEEK_KEY="${DEEPSEEK_KEY:-}"
GITHUB_TOKEN="${GITHUB_TOKEN:-}"
GITLAB_TOKEN="${GITLAB_TOKEN:-}"
GOOGLE_MAPS_KEY="${GOOGLE_MAPS_KEY:-}"
if [ -z "${DEEPSEEK_KEY:-}" ] && [ "$MODE" != "health" ] && [ "$MODE" != "fix-zshrc" ] && [ "$MODE" != "fix-config" ] && [ "$MODE" != "interactive" ]; then
  info "No DeepSeek API key provided. Some AI features will be unavailable."
  info "Get a free key at https://platform.deepseek.com/ — model: deepseek-v4-pro"
  info "Use --deepseek-key <key> or set DEEPSEEK_API_KEY env var to enable."
fi
export DEEPSEEK_API_KEY="${DEEPSEEK_KEY:-}"
export ZAI_API_KEY="${ZAI_KEY:-}"
export OPENROUTER_API_KEY="${OPENROUTER_KEY:-}"
export XAI_API_KEY="${XAI_KEY:-}"
export MIMO_API_KEY="${MIMO_KEY:-}"
export MINIMAX_API_KEY="${MINIMAX_KEY:-}"
export OPENAI_API_KEY="${OPENAI_API_KEY:-}"
export ANTHROPIC_API_KEY="${ANTHROPIC_API_KEY:-}"
export GOOGLE_API_KEY="${GOOGLE_API_KEY:-}"
export MISTRAL_API_KEY="${MISTRAL_API_KEY:-}"
export GROQ_API_KEY="${GROQ_API_KEY:-}"
export TOGETHER_API_KEY="${TOGETHER_API_KEY:-}"
export COHERE_API_KEY="${COHERE_API_KEY:-}"
export FIREWORKS_API_KEY="${FIREWORKS_API_KEY:-}"
export CEREBRAS_API_KEY="${CEREBRAS_API_KEY:-}"
export PERPLEXITY_API_KEY="${PERPLEXITY_API_KEY:-}"
export ALIBABA_API_KEY="${ALIBABA_KEY:-}"
export DEEPINFRA_API_KEY="${DEEPINFRA_KEY:-}"
export GITVERSE_TOKEN="${GITVERSE_TOKEN:-}"
export FZF_KEY="${FZF_KEY:-}"
GIT_NAME="${GIT_NAME:-}"
GIT_EMAIL="${GIT_EMAIL:-}"
INFRA_SERVICES="${INFRA_SERVICES:-}"

# ── TOML config loading (precedence: CLI > env > toml > defaults) ──────────
CONFIG_TOML="${CONFIG_TOML:-}"
if [ -n "$CONFIG_TOML" ]; then
  if [ ! -f "$CONFIG_TOML" ]; then
    err "Config file not found: $CONFIG_TOML"
  fi
  info "Loading config from: $CONFIG_TOML"
  _toml_load "$CONFIG_TOML"
  # Re-apply TOML values to shell variables (TOML exports UPPERCASE)
  GIT_NAME="${GIT_NAME:-${USER_GIT_NAME:-}}"
  GIT_EMAIL="${GIT_EMAIL:-${USER_GIT_EMAIL:-}}"
  PROJECT_DIR="${PROJECT_DIR:-${USER_PROJECT_DIR:-}}"
  DEPLOYMENT_PROFILE="${DEPLOYMENT_PROFILE:-${META_PROFILE:-}}"
  ISOLATED_CIRCUIT="${ISOLATED_CIRCUIT:-${FEATURES_ISOLATED_CIRCUIT:-}}"
  # Services
  [ "${SERVICES_POSTGRES:-}" = "true" ] && INFRA_SERVICES="${INFRA_SERVICES:-}postgres "
  [ "${SERVICES_QDRANT:-}" = "true" ] && INFRA_SERVICES="${INFRA_SERVICES:-}qdrant "
  [ "${SERVICES_REDIS:-}" = "true" ] && INFRA_SERVICES="${INFRA_SERVICES:-}redis "
  [ "${SERVICES_KAFKA:-}" = "true" ] && INFRA_SERVICES="${INFRA_SERVICES:-}kafka "
  [ "${SERVICES_NEO4J:-}" = "true" ] && INFRA_SERVICES="${INFRA_SERVICES:-}neo4j "
  [ "${SERVICES_MINIO:-}" = "true" ] && INFRA_SERVICES="${INFRA_SERVICES:-}minio "
  [ "${SERVICES_OBSERVABILITY:-}" = "true" ] && INFRA_SERVICES="${INFRA_SERVICES:-}prometheus grafana " && OBSERVABILITY_ENABLED=true
  # Skip flags
  SKIP_DEVBOX="${SKIP_DEVBOX:-${FEATURES_SKIP_DEVBOX:-false}}"
  SKIP_CACHING="${SKIP_CACHING:-${FEATURES_SKIP_CACHING:-false}}"
  SKIP_DOTFILES="${SKIP_DOTFILES:-${FEATURES_SKIP_DOTFILES:-false}}"
  # API keys (TOML is last resort — prefer env vars or CLI)
  DEEPSEEK_KEY="${DEEPSEEK_KEY:-${PROVIDERS_DEEPSEEK_KEY:-}}"
  OPENAI_API_KEY="${OPENAI_API_KEY:-${PROVIDERS_OPENAI_KEY:-}}"
  ANTHROPIC_API_KEY="${ANTHROPIC_API_KEY:-${PROVIDERS_ANTHROPIC_KEY:-}}"
  GOOGLE_API_KEY="${GOOGLE_API_KEY:-${PROVIDERS_GOOGLE_KEY:-}}"
  MISTRAL_API_KEY="${MISTRAL_API_KEY:-${PROVIDERS_MISTRAL_KEY:-}}"
  GROQ_API_KEY="${GROQ_API_KEY:-${PROVIDERS_GROQ_KEY:-}}"
  TOGETHER_API_KEY="${TOGETHER_API_KEY:-${PROVIDERS_TOGETHER_KEY:-}}"
  COHERE_API_KEY="${COHERE_API_KEY:-${PROVIDERS_COHERE_KEY:-}}"
  FIREWORKS_API_KEY="${FIREWORKS_API_KEY:-${PROVIDERS_FIREWORKS_KEY:-}}"
  CEREBRAS_API_KEY="${CEREBRAS_API_KEY:-${PROVIDERS_CEREBRAS_KEY:-}}"
  PERPLEXITY_API_KEY="${PERPLEXITY_API_KEY:-${PROVIDERS_PERPLEXITY_KEY:-}}"
  ALIBABA_API_KEY="${ALIBABA_API_KEY:-${PROVIDERS_ALIBABA_KEY:-}}"
  DEEPINFRA_API_KEY="${DEEPINFRA_API_KEY:-${PROVIDERS_DEEPINFRA_KEY:-}}"
  XAI_API_KEY="${XAI_API_KEY:-${PROVIDERS_XAI_KEY:-}}"
  MIMO_API_KEY="${MIMO_API_KEY:-${PROVIDERS_MIMO_KEY:-}}"
  MINIMAX_API_KEY="${MINIMAX_API_KEY:-${PROVIDERS_MINIMAX_KEY:-}}"
  OPENROUTER_API_KEY="${OPENROUTER_API_KEY:-${PROVIDERS_OPENROUTER_KEY:-}}"
  ZAI_API_KEY="${ZAI_API_KEY:-${PROVIDERS_ZAI_KEY:-}}"
  GITHUB_TOKEN="${GITHUB_TOKEN:-${PROVIDERS_GITHUB_TOKEN:-}}"
  GITLAB_TOKEN="${GITLAB_TOKEN:-${PROVIDERS_GITLAB_TOKEN:-}}"
  GITVERSE_TOKEN="${GITVERSE_TOKEN:-${PROVIDERS_GITVERSE_TOKEN:-}}"
  GOOGLE_MAPS_KEY="${GOOGLE_MAPS_KEY:-${PROVIDERS_GOOGLE_MAPS_KEY:-}}"
  # Tools version overrides
  NODE_VER="${NODE_VER:-${TOOLS_NODE_VER:-}}"
  PYTHON_VER="${PYTHON_VER:-${TOOLS_PYTHON_VER:-}}"
  GO_VER="${GO_VER:-${TOOLS_GO_VER:-}}"
  RUST_VER="${RUST_VER:-${TOOLS_RUST_VER:-}}"
  JAVA_VER="${JAVA_VER:-${TOOLS_JAVA_VER:-}}"
  DOTNET_VER="${DOTNET_VER:-${TOOLS_DOTNET_VER:-}}"
  ZIG_VER="${ZIG_VER:-${TOOLS_ZIG_VER:-}}"
  BUN_VER="${BUN_VER:-${TOOLS_BUN_VER:-}}"
  OPENCODE_CLI_VER="${OPENCODE_CLI_VER:-${TOOLS_OPENCODE_VER:-}}"
  log "Config loaded from $CONFIG_TOML"
fi

# ── Mode banner ─────────────────────────────────────────────────────────────
echo -e "${GREEN}============================================================${NC}"
echo -e "${GREEN}     Ultimate Dev Machine Bootstrap ${SCRIPT_VERSION}${NC}"
echo -e "${GREEN}     Mode: $MODE${NC}"
echo -e "${GREEN}     Log:  $SETUP_LOG${NC}"
echo -e "${GREEN}============================================================${NC}"

# ── Execute steps ───────────────────────────────────────────────────────────
TOTAL_STEPS=49
CURRENT_STEP=0

_run_step() {
  local step_key="$1" step_name="$2" module="$3"
  CURRENT_STEP=$((CURRENT_STEP + 1))
  if _step_skip "$step_key" 2>/dev/null; then return 0; fi
  _progress "$CURRENT_STEP/$TOTAL_STEPS" "$step_name"
  if [ "${DRY_RUN:-false}" = "true" ]; then
    info "[DRY] $step_name ($module)"
    return 0
  fi
  # shellcheck disable=SC1090
  local step_output step_exit
  step_output="$(set +e; source "$module" 2>&1)" || step_exit=$?
  if [ "${step_exit:-0}" -ne 0 ]; then
    # Extract last meaningful error line for diagnostics
    local error_line
    error_line="$(echo "$step_output" | grep -E "(ERROR|error|Error|FAILED|failed|Failed|command not found|Permission denied)" | tail -1)"
    if [ -n "$error_line" ]; then
      warn "$step_name — FAILED at: $error_line"
    else
      warn "$step_name — FAILED (exit code: $step_exit)"
    fi
    # Mark as PARTIAL so next run knows to retry
    _wal_checkpoint "$step_name" "$step_key" "PARTIAL"
    return 1
  fi
  _wal_checkpoint "$step_name" "$step_key" "DONE"
  log "$step_name — done"
}

# ── Project-only init mode (--new <dir>) — exits after completion ───────────
if [ "$MODE" = "new" ]; then source "$SCRIPT_DIR/src/modes/new.sh"; fi

_run_step step_system "System packages" "$SCRIPT_DIR/src/lib/01-system.sh"
_run_step step_docker "Docker Engine" "$SCRIPT_DIR/src/lib/02-docker.sh"
[ "${INFRA_SERVICES:-}" != "" ] && _run_step step_services "Service Configuration Layer" "$SCRIPT_DIR/src/lib/33-services.sh"
[ "${INFRA_SERVICES:-}" != "" ] && _run_step step_infra "Infrastructure Services" "$SCRIPT_DIR/src/lib/30-infra.sh"
_run_step step_chrome "Google Chrome" "$SCRIPT_DIR/src/lib/03-chrome.sh"
_run_step step_zsh "ZSH + Oh My Zsh" "$SCRIPT_DIR/src/lib/04-zsh.sh"
_run_step step_java "Java 25 LTS" "$SCRIPT_DIR/src/lib/05-java.sh"
_run_step step_node "Node.js 24" "$SCRIPT_DIR/src/lib/06-node.sh"
_run_step step_python "Python 3.14.6 + uv" "$SCRIPT_DIR/src/lib/07-python.sh"
_run_step step_go "Go 1.26.5" "$SCRIPT_DIR/src/lib/08-go.sh"
_run_step step_rust "Rust 1.97.1" "$SCRIPT_DIR/src/lib/09-rust.sh"
_run_step step_dotnet ".NET 10.0.302" "$SCRIPT_DIR/src/lib/10-dotnet.sh"

# ── Clean old configs ────────────────────────────────────────────────────────
if [ "$MODE" = "full" ] || [ "$MODE" = "reinit" ]; then
  section "Cleaning old configs & stale agents"
  # F2.4: Do NOT delete OpenCode runtime cache (~/.cache/opencode) or
  # state (~/.local/share/opencode) — these are needed for session resume.
  # Only remove the old opencode.json config (migrated to ~/.config/opencode/).
  rm -f ~/opencode.json
  mkdir -p ~/.config/opencode
  for scout_path in \
    "$PROJECT_DIR/.opencode/agents/scout.md" \
    "$HOME/.config/opencode/agents/scout.md" \
    "$HOME/.opencode/agents/scout.md"; do
    [ -f "$scout_path" ] && rm -f "$scout_path" && warn "Removed stale agent: $scout_path"
  done
  log "Old configs cleaned"
fi

_run_step step_opencode "OpenCode CLI" "$SCRIPT_DIR/src/lib/11-opencode.sh"
_run_step step_mcp "MCP + LSP + Plugins" "$SCRIPT_DIR/src/lib/12-mcp-lsp.sh"
_run_step step_chromadb "ChromaDB + Muninn" "$SCRIPT_DIR/src/lib/13-chromadb.sh"
_run_step step_shokunin "Shokunin + Superpowers" "$SCRIPT_DIR/src/lib/14-shokunin.sh"
_run_step step_security "Trivy + Qodana" "$SCRIPT_DIR/src/lib/15-security.sh"
_run_step step_llm "Ollama + vLLM" "$SCRIPT_DIR/src/lib/16-llm.sh"
_run_step step_project "Project structure" "$SCRIPT_DIR/src/lib/17-project.sh"
_run_step step_json "opencode.json" "$SCRIPT_DIR/src/lib/18-opencode-json.sh"
_run_step step_wal "WAL Checkpoint" "$SCRIPT_DIR/src/lib/37-wal.sh"
_run_step step_ide_plugins "IDE AI Plugins" "$SCRIPT_DIR/src/lib/38-ide-plugins.sh"
_run_step step_finalize "Finalize + Verify" "$SCRIPT_DIR/src/lib/19-finalize.sh"
_run_step step_autoupdate "Auto-update system" "$SCRIPT_DIR/src/lib/20-autoupdate.sh"
# ── Parallel: independent optional modules (R17: Performance) ────────────────
if [ "${DRY_RUN:-false}" != "true" ] && [ "${PARALLEL_INSTALL:-true}" = "true" ]; then
  info "Installing optional modules in parallel..."
  _run_step step_rag "RAG System (optional)" "$SCRIPT_DIR/src/lib/21-rag.sh" &
  _run_step step_webui "Open WebUI service" "$SCRIPT_DIR/src/lib/22-webui-service.sh" &
  _run_step step_mise "mise tool manager" "$SCRIPT_DIR/src/lib/29-mise.sh" &
  _run_step step_just "just task runner" "$SCRIPT_DIR/src/lib/23-just.sh" &
  _run_step step_websearch "Web Search Engine" "$SCRIPT_DIR/src/lib/24-websearch.sh" &
  wait
else
  _run_step step_rag "RAG System (optional)" "$SCRIPT_DIR/src/lib/21-rag.sh"
  _run_step step_webui "Open WebUI service" "$SCRIPT_DIR/src/lib/22-webui-service.sh"
  _run_step step_mise "mise tool manager" "$SCRIPT_DIR/src/lib/29-mise.sh"
  _run_step step_just "just task runner" "$SCRIPT_DIR/src/lib/23-just.sh"
  _run_step step_websearch "Web Search Engine" "$SCRIPT_DIR/src/lib/24-websearch.sh"
fi
_run_step step_providers "Multi-Provider Config" "$SCRIPT_DIR/src/lib/26-providers.sh"
_run_step step_isolated "Isolated Circuit Mode" "$SCRIPT_DIR/src/lib/32-isolated.sh"
[ "${SKIP_DOTFILES:-false}" != "true" ] && _run_step step_dotfiles "Dotfiles (chezmoi)" "$SCRIPT_DIR/src/lib/27-dotfiles.sh"
[ "${SKIP_DEVBOX:-false}" != "true" ] && _run_step step_devbox "Devbox (Nix)" "$SCRIPT_DIR/src/lib/28-devbox.sh"
[ "${SKIP_GUI:-false}" != "true" ] && _run_step step_gui "Web GUI Interface" "$SCRIPT_DIR/src/lib/35-gui.sh"
[ "${SKIP_COCKPIT:-false}" != "true" ] && _run_step step_cockpit "Cockpit TUI" "$SCRIPT_DIR/src/lib/31-cockpit.sh"
[ "${OBSERVABILITY_ENABLED:-false}" = "true" ] && _run_step step_observability "Observability Stack" "$SCRIPT_DIR/src/lib/34-observability.sh"
_run_step step_model_router "Model Routing Intelligence" "$SCRIPT_DIR/src/lib/36-model-router.sh"
_run_step step_context_selector "Context-Aware MCP/LSP Selector" "$SCRIPT_DIR/src/lib/52-context-selector.sh"
_run_step step_auto_skills "Auto-Triggering Skills" "$SCRIPT_DIR/src/lib/53-auto-skills.sh"
_run_step step_task_distributor "Task Distribution Intelligence" "$SCRIPT_DIR/src/lib/54-task-distributor.sh"
_run_step step_context_bundle "Context & Token Bundle" "$SCRIPT_DIR/src/lib/55-context-bundle.sh"
_run_step step_grace_semantics "GRACE Semantics" "$SCRIPT_DIR/src/lib/56-grace-semantics.sh"
_run_step step_caching "Prompt Caching Stack" "$SCRIPT_DIR/src/lib/60-caching.sh"
_run_step step_context_guard "Context Guard (compression)" "$SCRIPT_DIR/src/lib/57-context-guard.sh"
_run_step step_provider_discovery "Provider Auto-Discovery" "$SCRIPT_DIR/src/lib/58-provider-discovery.sh"
_run_step step_local_memory "Local Memory (opencode-mem, opt-in)" "$SCRIPT_DIR/src/lib/59-local-memory.sh"
_run_step step_daytona "Daytona Environment Practice" "$SCRIPT_DIR/src/lib/61-daytona.sh"
[ "${BEST_PRACTICES_ENABLED:-true}" != "false" ] && _run_step step_best_practices "Best Practices Skills (smixs)" "$SCRIPT_DIR/src/lib/40-best-practices.sh"
_run_step step_upstream_sync "Upstream Sync (submodules + pins)" "$SCRIPT_DIR/src/lib/99-upstream-sync.sh"

# ── Future modules (Wave 2-3 registration — sourced but not executed yet) ────
# These modules will be wired into _run_step by their owners in subsequent waves.
# Source guards ensure they load only when the module file exists (offline-safe).
[ -f "$SCRIPT_DIR/src/lib/41-constitution.sh" ] && source "$SCRIPT_DIR/src/lib/41-constitution.sh" || true
[ -f "$SCRIPT_DIR/src/lib/42-hooks.sh" ] && source "$SCRIPT_DIR/src/lib/42-hooks.sh" || true
[ -f "$SCRIPT_DIR/src/lib/43-governance.sh" ] && source "$SCRIPT_DIR/src/lib/43-governance.sh" || true
[ -f "$SCRIPT_DIR/src/lib/44-audit.sh" ] && source "$SCRIPT_DIR/src/lib/44-audit.sh" || true
[ -f "$SCRIPT_DIR/src/lib/45-pii-guard.sh" ] && source "$SCRIPT_DIR/src/lib/45-pii-guard.sh" || true
[ -f "$SCRIPT_DIR/src/lib/46-offline-bundle.sh" ] && source "$SCRIPT_DIR/src/lib/46-offline-bundle.sh" || true
[ -f "$SCRIPT_DIR/src/lib/47-lynis.sh" ] && source "$SCRIPT_DIR/src/lib/47-lynis.sh" || true
[ -f "$SCRIPT_DIR/src/lib/48-auditd.sh" ] && source "$SCRIPT_DIR/src/lib/48-auditd.sh" || true
[ -f "$SCRIPT_DIR/src/lib/49-deepseek-harness.sh" ] && source "$SCRIPT_DIR/src/lib/49-deepseek-harness.sh" || true
[ -f "$SCRIPT_DIR/src/lib/50-sandcastle.sh" ] && source "$SCRIPT_DIR/src/lib/50-sandcastle.sh" || true
[ -f "$SCRIPT_DIR/src/lib/51-opencode-desktop.sh" ] && source "$SCRIPT_DIR/src/lib/51-opencode-desktop.sh" || true

# ── Air-gap mode: trigger offline bundle if available ────────────────────────
if [ "$MODE" = "airgap" ]; then
  section "Air-Gap Bootstrap"
  info "ISOLATED_CIRCUIT=true — running offline bundle bootstrap"
  if declare -f _offline_bundle_run &>/dev/null; then
    _offline_bundle_run
  else
    warn "46-offline-bundle.sh not found — skipping offline bundle execution"
    info "Ensure the offline bundle is available at ~/.cache/opencode-setup/offline-bundle/"
  fi
fi

# ── Process skip flags (v3.5.0) ──────────────────────────────────────────────
if [ -n "${SKIP_FLAGS:-}" ]; then
  section "Skip Flags"
  _process_skip_flags "$SKIP_FLAGS"
fi

# ── APM preparation (v3.5.0) ────────────────────────────────────────────────
if [ "${GENERATE_APM:-false}" = "true" ]; then
  section "APM Preparation"
  _apm_install
  _apm_generate_policy
fi

# ── Multi-agent targets (v4.0.0) ────────────────────────────────────────────
if [ "${GENERATE_MULTI_AGENT:-false}" = "true" ]; then
  section "Multi-Agent Targets"
  _generate_all_targets "${PROJECT_DIR:-.}"
elif [ "${GENERATE_COPILOT:-false}" = "true" ]; then
  section "GitHub Copilot Instructions"
  _generate_copilot_instructions "${PROJECT_DIR:-.}"
elif [ "${GENERATE_CLAUDE:-false}" = "true" ]; then
  section "Claude Settings"
  _generate_claude_settings "${PROJECT_DIR:-.}"
elif [ "${GENERATE_CURSOR:-false}" = "true" ]; then
  section "Cursor Settings"
  _generate_cursor_settings "${PROJECT_DIR:-.}"
elif [ "${GENERATE_VSCODE:-false}" = "true" ]; then
  section "VS Code Settings"
  _generate_vscode_settings "${PROJECT_DIR:-.}"
fi

# ── Cache cleanup (v3.5.0) ──────────────────────────────────────────────────
if [ "${DRY_RUN:-false}" != "true" ]; then
  _cache_cleanup 2>/dev/null || true
fi

# ── Mirror configuration (v4.1.0) ───────────────────────────────────────────
if [ "${CONFIGURE_MIRRORS:-false}" = "true" ]; then
  section "Mirror Configuration"
  if [ "$MIRROR_REGION" = "auto" ]; then
    _configure_all_mirrors
  else
    _configure_all_mirrors "$MIRROR_REGION"
  fi
fi

# ── Auto-sync (v4.1.0) ─────────────────────────────────────────────────────
if [ "${RUN_SYNC:-false}" = "true" ]; then
  section "Auto-Sync"
  if [ "${SYNC_FORCE:-false}" = "true" ]; then
    _full_sync --force
  else
    _full_sync
  fi
fi

# ── Start auto-sync daemon (v4.1.0) ─────────────────────────────────────────
if [ "${START_AUTO_SYNC:-false}" = "true" ]; then
  section "Auto-Sync Daemon"
  _auto_sync_daemon &
  log "Auto-sync daemon started (PID: $!)"
fi

# ── Security scan (v4.2.0) ──────────────────────────────────────────────────
if [ "${RUN_SECURITY_SCAN:-false}" = "true" ]; then
  section "Security Scan"
  _generate_security_report "${PROJECT_DIR:-.}"
fi

# ── Install security hooks (v4.2.0) ─────────────────────────────────────────
if [ "${INSTALL_SECURITY_HOOKS:-false}" = "true" ]; then
  section "Security Hooks"
  _install_pre_commit_hook "${PROJECT_DIR:-.}/.git"
fi

# ── Benchmark (v4.3.0) ──────────────────────────────────────────────────────
if [ "${RUN_BENCHMARK:-false}" = "true" ]; then
  section "Performance Benchmark"
  _run_benchmark
fi

echo ""
echo -e "  ${GREEN}╔══════════════════════════════════════╗${NC}"
echo -e "  ${GREEN}║   Bootstrap complete ($SCRIPT_VERSION)${NC}"
echo -e "  ${GREEN}║   Steps: $CURRENT_STEP/$TOTAL_STEPS${NC}"
echo -e "  ${GREEN}║   Log:   ${SETUP_LOG:-not started}${NC}"
echo -e "  ${GREEN}║   Run:   dev health${NC}"
echo -e "  ${GREEN}╚══════════════════════════════════════╝${NC}"
echo ""
