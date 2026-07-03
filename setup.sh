#!/usr/bin/env bash
# ============================================================================
#  Ultimate Dev Machine Bootstrap v2.0.0 — Modular
set -euo pipefail
IFS=$'\n\t'
shopt -s inherit_errexit 2>/dev/null || true

# ── Bootstrap: resolve script dir (supports curl|bash and local runs) ───────
if [ -f "$(cd "$(dirname "$0")" 2>/dev/null && pwd)/src/lib/helpers.sh" ]; then
  SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
elif [ -f "$HOME/opencode_initializer/src/lib/helpers.sh" ]; then
  SCRIPT_DIR="$HOME/opencode_initializer"
elif [ -f "$HOME/setup.sh" ] && [ -f "$(dirname "$(readlink -f "$HOME/setup.sh" 2>/dev/null || echo "$HOME/setup.sh")")/src/lib/helpers.sh" ]; then
  SCRIPT_DIR="$(dirname "$(readlink -f "$HOME/setup.sh" 2>/dev/null || echo "$HOME/setup.sh")")"
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

# ── Logging — tee all output to timestamped log ─────────────────────────────
SETUP_LOG="${HOME}/.cache/opencode-setup/setup-$(date +%Y%m%d-%H%M%S).log"
mkdir -p "$(dirname "$SETUP_LOG")"
exec > >(tee -a "$SETUP_LOG") 2>&1
log "Setup log: $SETUP_LOG"

# ── CLI argument parsing ────────────────────────────────────────────────────
MODE="full"
NEW_PROJECT_DIR=""
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
  --moonshot-key)
    MOONSHOT_KEY="$2"
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
  -p, --project-dir   Project directory (default: ~/projects)
  -k, --api-key       OpenCode Go API key
  --deepseek-key      DeepSeek API key
  --zai-key           z.ai GLM API key
  --openrouter-key    OpenRouter API key
  --xai-key           xAI Grok API key
  --mimo-key          Xiaomi MiMo API key
  --moonshot-key      Moonshot (Kimi K2.6) API key
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
  --dotfiles-skip     Skip chezmoi dotfiles manager installation
  --with-postgres     Enable PostgreSQL 18 in Docker (needed for memory/plugins)
  --with-qdrant       Enable Qdrant vector DB (needed for code search / RAG)
  --with-redis        Enable Redis 7 cache (needed for sessions / PubSub)
  --with-kafka        Enable Kafka message broker (needed for event streaming)
  --with-neo4j        Enable Neo4j graph DB (needed for knowledge graph)
  --with-minio        Enable MinIO S3 storage (needed for artifacts)
  --with-all-infra    Enable all Docker infrastructure services
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
    exit 0
    ;;
  *) err "Unknown: $1. Use -h for help." ;;
esac done

# ── Early-exit modes ─────────────────────────────────────────────────────────
if [ "$MODE" = "health" ]; then source "$SCRIPT_DIR/src/modes/health.sh"; fi
if [ "$MODE" = "ci" ]; then source "$SCRIPT_DIR/src/modes/ci.sh"; fi
if [ "$MODE" = "fix-zshrc" ]; then source "$SCRIPT_DIR/src/modes/fix-zshrc.sh"; fi
if [ "$MODE" = "upgrade" ]; then source "$SCRIPT_DIR/src/modes/upgrade.sh"; fi
if [ "$MODE" = "interactive" ]; then source "$SCRIPT_DIR/src/modes/interactive.sh"; fi

# ── Sudo — authenticate before any sudo operations ──────────────────────────
[ "$EUID" -eq 0 ] && err "Do not run as root."
if [ -z "${SUDO_PASS:-}" ] && [ "$MODE" != "new" ] && [ "$MODE" != "fix-config" ]; then
  read -r -s -p "Sudo password (cached): " SUDO_PASS 2>/dev/null || true
  echo
fi
if [ -n "${SUDO_PASS:-}" ]; then
  echo "$SUDO_PASS" | sudo -S true 2>/dev/null || err "Wrong sudo password"
  sudo -v 2>/dev/null || true
fi

# ── DNS + CA certs — after interactive (which may change MODE to full) ──────
if [ "$MODE" = "full" ] || [ "$MODE" = "reinit" ] || [ "$MODE" = "update" ]; then
  _set_dns
  _install_ca_certs
fi

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
TOTAL_STEPS=33
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
  source "$module"
  _wal_checkpoint "$step_name" "$step_key"
  log "$step_name — done"
}

_run_step step_system "System packages" "$SCRIPT_DIR/src/lib/01-system.sh"
_run_step step_docker "Docker Engine" "$SCRIPT_DIR/src/lib/02-docker.sh"
[ "${INFRA_SERVICES:-}" != "" ] && _run_step step_infra "Infrastructure Services" "$SCRIPT_DIR/src/lib/30-infra.sh"
_run_step step_chrome "Google Chrome" "$SCRIPT_DIR/src/lib/03-chrome.sh"
_run_step step_zsh "ZSH + Oh My Zsh" "$SCRIPT_DIR/src/lib/04-zsh.sh"
_run_step step_java "Java 25" "$SCRIPT_DIR/src/lib/05-java.sh"
_run_step step_node "Node.js 24" "$SCRIPT_DIR/src/lib/06-node.sh"
_run_step step_python "Python 3.14 + uv" "$SCRIPT_DIR/src/lib/07-python.sh"
_run_step step_go "Go 1.26" "$SCRIPT_DIR/src/lib/08-go.sh"
_run_step step_rust "Rust 1.96" "$SCRIPT_DIR/src/lib/09-rust.sh"
_run_step step_dotnet ".NET 10" "$SCRIPT_DIR/src/lib/10-dotnet.sh"

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

_run_step step_opencode "OpenCode CLI" "$SCRIPT_DIR/src/lib/11-opencode.sh"
_run_step step_mcp "MCP + LSP + Plugins" "$SCRIPT_DIR/src/lib/12-mcp-lsp.sh"
_run_step step_chromadb "ChromaDB + Muninn" "$SCRIPT_DIR/src/lib/13-chromadb.sh"
_run_step step_shokunin "Shokunin + Superpowers" "$SCRIPT_DIR/src/lib/14-shokunin.sh"
_run_step step_security "Trivy + Qodana" "$SCRIPT_DIR/src/lib/15-security.sh"
_run_step step_llm "Ollama + vLLM" "$SCRIPT_DIR/src/lib/16-llm.sh"
_run_step step_project "Project structure" "$SCRIPT_DIR/src/lib/17-project.sh"
_run_step step_json "opencode.json" "$SCRIPT_DIR/src/lib/18-opencode-json.sh"
_run_step step_wal "WAL Checkpoint" "$SCRIPT_DIR/src/lib/37-wal.sh"
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
  _run_step step_litellm "LiteLLM API Gateway" "$SCRIPT_DIR/src/lib/25-litellm.sh" &
  wait
else
  _run_step step_rag "RAG System (optional)" "$SCRIPT_DIR/src/lib/21-rag.sh"
  _run_step step_webui "Open WebUI service" "$SCRIPT_DIR/src/lib/22-webui-service.sh"
  _run_step step_mise "mise tool manager" "$SCRIPT_DIR/src/lib/29-mise.sh"
  _run_step step_just "just task runner" "$SCRIPT_DIR/src/lib/23-just.sh"
  _run_step step_websearch "Web Search Engine" "$SCRIPT_DIR/src/lib/24-websearch.sh"
  _run_step step_litellm "LiteLLM API Gateway" "$SCRIPT_DIR/src/lib/25-litellm.sh"
fi
_run_step step_providers "Multi-Provider Config" "$SCRIPT_DIR/src/lib/26-providers.sh"
[ "${SKIP_DOTFILES:-false}" != "true" ] && _run_step step_dotfiles "Dotfiles (chezmoi)" "$SCRIPT_DIR/src/lib/27-dotfiles.sh"
[ "${SKIP_DEVBOX:-false}" != "true" ] && _run_step step_devbox "Devbox (Nix)" "$SCRIPT_DIR/src/lib/28-devbox.sh"
[ "${SKIP_GUI:-false}" != "true" ] && _run_step step_gui "Web GUI Interface" "$SCRIPT_DIR/src/lib/35-gui.sh"
[ "${OBSERVABILITY_ENABLED:-false}" = "true" ] && _run_step step_observability "Observability Stack" "$SCRIPT_DIR/src/lib/34-observability.sh"
_run_step step_model_router "Model Routing Intelligence" "$SCRIPT_DIR/src/lib/36-model-router.sh"

echo ""
echo -e "  ${GREEN}╔══════════════════════════════════════╗${NC}"
echo -e "  ${GREEN}║   Bootstrap complete ($SCRIPT_VERSION)${NC}"
echo -e "  ${GREEN}║   Steps: $CURRENT_STEP/$TOTAL_STEPS${NC}"
echo -e "  ${GREEN}║   Log:   $LOG_FILE${NC}"
echo -e "  ${GREEN}║   Run:   dev health${NC}"
echo -e "  ${GREEN}╚══════════════════════════════════════╝${NC}"
echo ""
