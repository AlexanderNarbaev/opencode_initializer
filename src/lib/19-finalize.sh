#!/usr/bin/env bash
# lib/19-finalize.sh — Finalization: Git config, PATH persistence, .zshrc fix, auth reminder, dev CLI, verification (STEPS 15-19)
# Requires: MODE, GIT_NAME, GIT_EMAIL, all *_KEY vars, SECRETS_FILE, SCRIPTS_DIR
set -euo pipefail

# ── STEP 15: Git config ─────────────────────────────────────────────────────
if [ "$MODE" = "full" ] || [ "$MODE" = "reinit" ]; then
  section "Git configuration"
  [ -n "$GIT_NAME" ] && git config --global user.name "$GIT_NAME"
  [ -n "$GIT_EMAIL" ] && git config --global user.email "$GIT_EMAIL"
  git config --global init.defaultBranch main 2>/dev/null || true
  git config --global pull.rebase true 2>/dev/null || true
  log "Git configured"
fi

# ── STEP 16: PATH persistence — single clean source ─────────────────────────
if [ "$MODE" = "full" ] || [ "$MODE" = "reinit" ]; then
  section "PATH persistence"

  PATH_LINE="export PATH=\"\$HOME/.npm-global/bin:\$HOME/.local/bin:\$HOME/.n/bin:\$HOME/.bun/bin:\$HOME/.cargo/bin:\$HOME/.jbang/bin:\$HOME/.dotnet:\$HOME/.dotnet/tools:\$HOME/go/bin:/usr/local/go/bin:\$PATH\""
  N_PREFIX_LINE="export N_PREFIX=\"\$HOME/.n\""
  SDKMAN_LINE="export SDKMAN_DIR=\"\$HOME/.sdkman\" ; [[ -s \"\$SDKMAN_DIR/bin/sdkman-init.sh\" ]] && source \"\$SDKMAN_DIR/bin/sdkman-init.sh\""
  SHOKUNIN_LINE="[ -f \"\$HOME/.shokunin/scripts/linux/profile.sh\" ] && source \"\$HOME/.shokunin/scripts/linux/profile.sh\" 2>/dev/null"
  BUN_LINE="export BUN_INSTALL=\"\$HOME/.bun\""
  DOTNET_LINE="export DOTNET_ROOT=\"\$HOME/.dotnet\""
  SECRETS_SOURCE="[ -f \"\$HOME/.config/opencode/secrets.env\" ] && source \"\$HOME/.config/opencode/secrets.env\""

  # Store API keys in secrets.env (chmod 600), NOT in .bashrc/.zshrc
  touch "$SECRETS_FILE" && chmod 600 "$SECRETS_FILE"
  sed -i "/DEEPSEEK_API_KEY=/d" "$SECRETS_FILE" 2>/dev/null || true
  sed -i "/OPENCODE_API_KEY=/d" "$SECRETS_FILE" 2>/dev/null || true
  sed -i "/XAI_API_KEY=/d" "$SECRETS_FILE" 2>/dev/null || true
  sed -i "/MIMO_API_KEY=/d" "$SECRETS_FILE" 2>/dev/null || true
  sed -i "/MOONSHOT_API_KEY=/d" "$SECRETS_FILE" 2>/dev/null || true
  sed -i "/MINIMAX_API_KEY=/d" "$SECRETS_FILE" 2>/dev/null || true
  sed -i "/GITHUB_TOKEN=/d" "$SECRETS_FILE" 2>/dev/null || true
  sed -i "/GITLAB_TOKEN=/d" "$SECRETS_FILE" 2>/dev/null || true
  sed -i "/GITVERSE_TOKEN=/d" "$SECRETS_FILE" 2>/dev/null || true
  sed -i "/GOOGLE_MAPS_API_KEY=/d" "$SECRETS_FILE" 2>/dev/null || true
  [ -n "${DEEPSEEK_KEY:-}" ] && echo "export DEEPSEEK_API_KEY=\"$DEEPSEEK_KEY\"" >> "$SECRETS_FILE"
  [ -n "${API_KEY:-}" ] && echo "export OPENCODE_API_KEY=\"$API_KEY\"" >> "$SECRETS_FILE"
  [ -n "${XAI_KEY:-}" ] && echo "export XAI_API_KEY=\"$XAI_KEY\"" >> "$SECRETS_FILE"
  [ -n "${MIMO_KEY:-}" ] && echo "export MIMO_API_KEY=\"$MIMO_KEY\"" >> "$SECRETS_FILE"
  [ -n "${MOONSHOT_KEY:-}" ] && echo "export MOONSHOT_API_KEY=\"$MOONSHOT_KEY\"" >> "$SECRETS_FILE"
  [ -n "${MINIMAX_KEY:-}" ] && echo "export MINIMAX_API_KEY=\"$MINIMAX_KEY\"" >> "$SECRETS_FILE"
  [ -n "${GITHUB_TOKEN:-}" ] && echo "export GITHUB_TOKEN=\"$GITHUB_TOKEN\"" >> "$SECRETS_FILE"
  [ -n "${GITLAB_TOKEN:-}" ] && echo "export GITLAB_TOKEN=\"$GITLAB_TOKEN\"" >> "$SECRETS_FILE"
  [ -n "${GITVERSE_TOKEN:-}" ] && echo "export GITVERSE_TOKEN=\"$GITVERSE_TOKEN\"" >> "$SECRETS_FILE"
  [ -n "${GOOGLE_MAPS_KEY:-}" ] && echo "export GOOGLE_MAPS_API_KEY=\"$GOOGLE_MAPS_KEY\"" >> "$SECRETS_FILE"
  # Export for current shell so opencode verification works immediately
  [ -n "${DEEPSEEK_KEY:-}" ] && export DEEPSEEK_API_KEY="$DEEPSEEK_KEY"
  [ -n "${API_KEY:-}" ] && export OPENCODE_API_KEY="$API_KEY"
  [ -n "${XAI_KEY:-}" ] && export XAI_API_KEY="$XAI_KEY"
  [ -n "${MIMO_KEY:-}" ] && export MIMO_API_KEY="$MIMO_KEY"
  [ -n "${MOONSHOT_KEY:-}" ] && export MOONSHOT_API_KEY="$MOONSHOT_KEY"
  [ -n "${MINIMAX_KEY:-}" ] && export MINIMAX_API_KEY="$MINIMAX_KEY"
  [ -n "${GITLAB_TOKEN:-}" ] && export GITLAB_TOKEN="$GITLAB_TOKEN"
  [ -n "${GITVERSE_TOKEN:-}" ] && export GITVERSE_TOKEN="$GITVERSE_TOKEN"
  [ -n "${GOOGLE_MAPS_KEY:-}" ] && export GOOGLE_MAPS_API_KEY="$GOOGLE_MAPS_KEY"
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

# ── STEP 17: Fix .zshrc + P10k instant prompt ───────────────────────────────
if [ "$MODE" = "full" ] || [ "$MODE" = "reinit" ]; then
  section "Fixing .zshrc & P10k compatibility"

  P10K_FILE="$HOME/.p10k.zsh"
  if [ -f "$P10K_FILE" ]; then
    sed -i 's/POWERLEVEL9K_INSTANT_PROMPT=verbose/POWERLEVEL9K_INSTANT_PROMPT=quiet/' "$P10K_FILE" 2>/dev/null || true
    log "P10k: instant prompt set to quiet"
  fi

  SHOKUNIN_PROFILE="$HOME/.shokunin/scripts/linux/profile.sh"
  if [ -f "$SHOKUNIN_PROFILE" ] && grep -q 'echo "Shokunin' "$SHOKUNIN_PROFILE" 2>/dev/null; then
    sed -i 's/echo "Shokunin AI Ecosystem loaded"/# echo "Shokunin AI Ecosystem loaded"/' "$SHOKUNIN_PROFILE" 2>/dev/null || true
    log "Shokunin: console echo suppressed (P10k compat)"
  fi
fi

# ── STEP 18: Auth reminder ──────────────────────────────────────────────────
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

# ── STEP 18b: Config file + dev CLI ─────────────────────────────────────────
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

  DEV_SRC="${SCRIPTS_DIR:-$HOME/opencode_initializer}/dev.sh"
  DEV_DST="$HOME/.local/bin/dev"
  if [ -f "$DEV_SRC" ]; then
    mkdir -p "$HOME/.local/bin"
    cp "$DEV_SRC" "$DEV_DST" && chmod +x "$DEV_DST" && log "dev CLI installed: ~/.local/bin/dev"
  fi
fi

# ── STEP 19: Verification ───────────────────────────────────────────────────
section "Verification"
PASS=0; FAIL=0
_check() { if eval "$2" &>/dev/null; then log "$1 — OK"; PASS=$((PASS+1)); else warn "$1 — MISSING"; FAIL=$((FAIL+1)); fi; }

_check "Docker"        "docker --version"
_check "Java"          "java -version 2>&1 | head -1"
_check "Go"            "go version"
_check "Rust"          "rustc --version"
_check ".NET"          "dotnet --version"
_check "Node.js"       "node --version"
_check "Python 3.14"   "python3.14 --version"
_check "OpenCode"      "opencode --version"
_check "uv"            "uv --version"
_check "bun"           "bun --version"
_check "Gradle"        "gradle --version 2>&1 | head -2"
_check "Maven"         "mvn --version 2>&1 | head -1"
_check "Kotlin"        "kotlin -version 2>/dev/null"
_check "Zig"           "zig version 2>/dev/null || echo 'not installed'"
_check "jbang"         "jbang --version"
_check "Git"           "git --version"
_check "zsh"           "zsh --version"
_check "Chrome"        "google-chrome-stable --version 2>/dev/null | head -1"
_check "opencode.json" "python3 -c \"import json; json.load(open('$HOME/.config/opencode/opencode.json'))\" 2>/dev/null"
_check ".zshrc valid"  "python3 -c \"open('$HOME/.zshrc').read()\" 2>/dev/null"

# MCP verification
for mcp in context7 filesystem agentic-tools codegraph playwright agent-browser loopsense github postgres sequential-thinking memorylayer chrome-devtools git memory fetch time redis brave-search websearch; do
  case $mcp in
    context7)      _check "MCP context7"       "which c7-mcp-server" ;;
    filesystem)    _check "MCP filesystem"     "npm list -g @modelcontextprotocol/server-filesystem &>/dev/null" ;;
    agentic-tools) _check "MCP agentic-tools"  "npm list -g @pimzino/agentic-tools-mcp &>/dev/null" ;;
    codegraph)     _check "MCP codegraph"      "which codegraph" ;;
    playwright)    _check "MCP playwright"     "npm list -g @playwright/mcp &>/dev/null" ;;
    agent-browser) _check "MCP agent-browser"  "npm list -g agent-browser-mcp-server &>/dev/null || which agent-browser-mcp-server" ;;
    loopsense)     _check "MCP loopsense"      "npm list -g @loopsense/mcp &>/dev/null" ;;
    github)        _check "MCP github"         "npm list -g @modelcontextprotocol/server-github &>/dev/null" ;;
    postgres)      _check "MCP postgres"       "npm list -g @modelcontextprotocol/server-postgres &>/dev/null" ;;
    sequential-thinking) _check "MCP sequential-thinking" "npm list -g @modelcontextprotocol/server-sequential-thinking &>/dev/null" ;;
    memorylayer)    _check "MCP memorylayer"     "npm list -g @scitrera/memorylayer-mcp-server &>/dev/null" ;;
    chrome-devtools) _check "MCP chrome-devtools" "npm list -g chrome-devtools-mcp &>/dev/null" ;;
    git)            _check "MCP git"              "which mcp-server-git 2>/dev/null || uvx mcp-server-git --version &>/dev/null" ;;
    memory)         _check "MCP memory"           "npm list -g @modelcontextprotocol/server-memory &>/dev/null" ;;
    fetch)          _check "MCP fetch"            "uvx mcp-server-fetch --help &>/dev/null" ;;
    time)           _check "MCP time"             "uvx mcp-server-time --help &>/dev/null" ;;
    redis)          _check "MCP redis"            "npm list -g @modelcontextprotocol/server-redis &>/dev/null" ;;
    brave-search)   _check "MCP brave-search"     "npm list -g brave-search-mcp &>/dev/null" ;;
    websearch)      _check "MCP websearch"       "npm list -g mcp-searxng &>/dev/null" ;;
  esac
done

  _check "MCP sqlite"              "uvx mcp-server-sqlite --help &>/dev/null"
  _check "MCP excalidraw"          "uvx excalidraw-architect-mcp --help &>/dev/null"
  _check "MCP context7-official"   "npm list -g @upstash/context7-mcp &>/dev/null"
  _check "MCP notion"              "npm list -g @notionhq/notion-mcp-server &>/dev/null"

  _check "Plugin daytona"          "npm list -g opencode-daytona &>/dev/null"
  _check "Plugin background-agents" "npm list -g opencode-background-agents &>/dev/null"
  _check "Plugin scheduler"         "npm list -g opencode-scheduler &>/dev/null"
  _check "Plugin firecrawl"         "npm list -g @lyculs/opencode-firecrawl &>/dev/null"
  _check "Plugin otel"              "npm list -g @devtheops/opencode-plugin-otel &>/dev/null"

_check "Muninn skills"      "[ -f ~/.config/opencode/skills/memory-read/SKILL.md ]"
  _check "Skills code-review"      "[ -f \"$PROJECT_DIR/.opencode/skills/code-review-checklist/SKILL.md\" ]"
  _check "Skills deployment"       "[ -f \"$PROJECT_DIR/.opencode/skills/deployment-checklist/SKILL.md\" ]"
  _check "Skills testing-strategy" "[ -f \"$PROJECT_DIR/.opencode/skills/testing-strategy/SKILL.md\" ]"
  _check "Skills context-switching" "[ -f \"$PROJECT_DIR/.opencode/skills/context-switching/SKILL.md\" ]"
_check "ChromaDB server"    "curl -sf http://127.0.0.1:8000/api/v2/heartbeat &>/dev/null"
_check "LiteLLM gateway"    "curl -sf http://localhost:4000/health/liveliness &>/dev/null"
_check "litellm"            "command -v litellm"

# Web search verification
_check "SearXNG container"  "docker ps --format '{{.Names}}' 2>/dev/null | grep -q searxng"
_check "SearXNG API"        "curl -sf http://localhost:8080/search?q=test &>/dev/null"
_check "Sanitizer proxy"    "curl -sf http://localhost:8888/search?q=test &>/dev/null"

echo
log "Verification: $PASS passed, $FAIL failed"
echo -e "  Providers: ${#PROVIDER_REGISTRY[@]} registered"

echo -e "${GREEN}============================================================${NC}"
echo -e "${GREEN}       BOOTSTRAP COMPLETE (${SCRIPT_VERSION}) · Mode: $MODE${NC}"
echo -e "${GREEN}============================================================${NC}"
echo "  Log file:  $LOG_FILE"
echo "  Health:    bash ~/setup.sh --health"
echo "  Fix zsh:   bash ~/setup.sh --fix-zshrc"
echo "  Fix MCP:   bash ~/setup.sh --fix-config"
echo "  Start:     cd $PROJECT_DIR && opencode"
echo "  dev CLI:   dev health | dev install <pkg> | dev update"
_step_done step_finalize
