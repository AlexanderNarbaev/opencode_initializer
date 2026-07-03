#!/usr/bin/env bash
# lib/12-mcp-lsp.sh — MCP servers + LSP servers (STEP 13)
# Requires: MCP_PACKAGES, _npm_install, _retry
set -euo pipefail

if ([ "$MODE" = "full" ] || [ "$MODE" = "reinit" ] || [ "$MODE" = "update" ]) && _gate "INTERACTIVE_DO_MCP"; then
  section "MCP servers & plugins"
  set +e # tolerate individual component failures

  _mcp() { _npm_install "$1" "$2"; }

  for name in "${!MCP_PACKAGES[@]}"; do
    _mcp "${MCP_PACKAGES[$name]}" "$name" || true
  done

  # Python MCP servers (uvx/pipx — NOT npm canaries!)
  # Git MCP (Python, via uvx or pipx)
  if command -v uvx &>/dev/null; then
    uvx mcp-server-git --version 2>/dev/null && log "MCP git (uvx)" || pipx install mcp-server-git 2>/dev/null && log "MCP git (pipx)" || warn "MCP git: install failed"
  elif command -v pipx &>/dev/null; then
    pipx install mcp-server-git 2>/dev/null && log "MCP git (pipx)" || warn "MCP git: pipx install failed"
  fi

  # Fetch MCP (Python, via uvx or pipx)
  if command -v uvx &>/dev/null; then
    uvx mcp-server-fetch --help 2>/dev/null && log "MCP fetch (uvx)" || pipx install mcp-server-fetch 2>/dev/null && log "MCP fetch (pipx)" || warn "MCP fetch: install failed"
  elif command -v pipx &>/dev/null; then
    pipx install mcp-server-fetch 2>/dev/null && log "MCP fetch (pipx)" || warn "MCP fetch: pipx install failed"
  fi

  # Time MCP (Python, via uvx or pipx)
  if command -v uvx &>/dev/null; then
    uvx mcp-server-time --help 2>/dev/null && log "MCP time (uvx)" || pipx install mcp-server-time 2>/dev/null && log "MCP time (pipx)" || warn "MCP time: install failed"
  elif command -v pipx &>/dev/null; then
    pipx install mcp-server-time 2>/dev/null && log "MCP time (pipx)" || warn "MCP time: pipx install failed"
  fi

  # SQLite MCP (Python, via uvx)
  if command -v uvx &>/dev/null; then
    uvx mcp-server-sqlite --help 2>/dev/null && log "MCP sqlite (uvx)" || pipx install mcp-server-sqlite 2>/dev/null && log "MCP sqlite (pipx)" || warn "MCP sqlite: install failed"
  fi

  # Excalidraw MCP — diagram generation (Python, via uvx)
  if command -v uvx &>/dev/null; then
    uvx excalidraw-architect-mcp --help 2>/dev/null && log "MCP excalidraw (uvx)" || pipx install excalidraw-architect-mcp 2>/dev/null && log "MCP excalidraw (pipx)" || warn "MCP excalidraw: install failed"
  fi

  # Muninn via pipx (skills only, not an MCP server)
  if ! command -v muninn-remembers &>/dev/null; then
    _retry 3 "Muninn pipx install" pipx install muninn-remembers 2>/dev/null && log "Muninn installed" || warn "Muninn: install failed"
  else
    log "Muninn $(muninn-remembers --version 2>/dev/null || echo 'installed')"
  fi
  if command -v muninn-remembers &>/dev/null; then
    muninn-remembers install opencode 2>/dev/null && log "Muninn: opencode skills" || warn "Muninn: skills install failed"
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

  # Plugins (actively maintained)
  npm install -g opencode-codegraph@latest 2>/dev/null && log "Plugin: opencode-codegraph" || {
    warn "Plugin FAILED: opencode-codegraph"
    true
  }
  npm install -g opencode-orchestrator@latest 2>/dev/null && log "Plugin: opencode-orchestrator" || {
    warn "Plugin FAILED: opencode-orchestrator"
    true
  }
  npm install -g opencode-token-tracker@latest 2>/dev/null && log "Plugin: opencode-token-tracker" || {
    warn "Plugin FAILED: token-tracker"
    true
  }
  npm install -g opencode-notify@latest 2>/dev/null && log "Plugin: opencode-notify" || {
    warn "Plugin FAILED: opencode-notify"
    true
  }
  npm install -g opencode-pty@latest 2>/dev/null && log "Plugin: opencode-pty" || {
    warn "Plugin FAILED: opencode-pty"
    true
  }
  npm install -g opencode-ignore@latest 2>/dev/null && log "Plugin: opencode-ignore" || {
    warn "Plugin FAILED: opencode-ignore"
    true
  }
  npm install -g opencode-snip@latest 2>/dev/null && log "Plugin: opencode-snip" || {
    warn "Plugin FAILED: opencode-snip"
    true
  }
  npm install -g opencode-snippets@latest 2>/dev/null && log "Plugin: opencode-snippets" || {
    warn "Plugin FAILED: opencode-snippets"
    true
  }
  npm install -g envsitter-guard@latest 2>/dev/null && log "Plugin: envsitter-guard" || {
    warn "Plugin FAILED: envsitter-guard"
    true
  }
  npm install -g opencode-command-inject@latest 2>/dev/null && log "Plugin: opencode-command-inject" || {
    warn "Plugin FAILED: opencode-command-inject"
    true
  }
  npm install -g @tarquinen/opencode-dcp@latest 2>/dev/null && log "Plugin: opencode-dcp" || {
    warn "Plugin FAILED: dcp"
    true
  }
  npm install -g opencode-auto-fallback@latest 2>/dev/null && log "Plugin: opencode-auto-fallback" || {
    warn "Plugin FAILED: auto-fallback"
    true
  }
  npm install -g opencode-goal-mode@latest 2>/dev/null && log "Plugin: opencode-goal-mode" || {
    warn "Plugin FAILED: goal-mode"
    true
  }
  npm install -g opencode-swarm@latest 2>/dev/null && log "Plugin: opencode-swarm" || {
    warn "Plugin FAILED: swarm"
    true
  }
  npm install -g opencode-vibeguard@latest 2>/dev/null && log "Plugin: opencode-vibeguard" || {
    warn "Plugin FAILED: vibeguard"
    true
  }

  # Smart routing + AGENTS.md sync (optional dev tools)
  npm install -g @blockrun/clawrouter@latest 2>/dev/null && log "Tool: clawrouter" || {
    warn "Tool FAILED: clawrouter"
    true
  }
  npm install -g agents-md-sync@latest 2>/dev/null && log "Tool: agents-md-sync" || {
    warn "Tool FAILED: agents-md-sync"
    true
  }

  # Infrastructure plugins
  npm install -g opencode-daytona@latest 2>/dev/null && log "Plugin: daytona" || {
    warn "Plugin FAILED: daytona"
    true
  }
  npm install -g opencode-devcontainers@latest 2>/dev/null && log "Plugin: devcontainers" || {
    warn "Plugin FAILED: devcontainers"
    true
  }
  npm install -g opencode-worktree@latest 2>/dev/null && log "Plugin: worktree" || {
    warn "Plugin FAILED: worktree"
    true
  }
  npm install -g opencode-scheduler@latest 2>/dev/null && log "Plugin: scheduler" || {
    warn "Plugin FAILED: scheduler"
    true
  }

  # AI-enhancement plugins
  npm install -g opencode-background-agents@latest 2>/dev/null && log "Plugin: background-agents" || {
    warn "Plugin FAILED: background-agents"
    true
  }
  npm install -g @zenobius/opencode-skillful@latest 2>/dev/null && log "Plugin: skillful" || {
    warn "Plugin FAILED: skillful"
    true
  }
  npm install -g opencode-goal-plugin@latest 2>/dev/null && log "Plugin: goal-plugin" || {
    warn "Plugin FAILED: goal-plugin"
    true
  }
  npm install -g opencode-conductor@latest 2>/dev/null && log "Plugin: conductor" || {
    warn "Plugin FAILED: conductor"
    true
  }

  # QoL plugins
  npm install -g opencode-zellij-namer@latest 2>/dev/null && log "Plugin: zellij-namer" || {
    warn "Plugin FAILED: zellij-namer"
    true
  }
  npm install -g @morphllm/opencode-morph-plugin@latest 2>/dev/null && log "Plugin: morph-plugin" || {
    warn "Plugin FAILED: morph-plugin"
    true
  }

  # Memory/context plugins
  npm install -g opencode-supermemory@latest 2>/dev/null && log "Plugin: supermemory" || {
    warn "Plugin FAILED: supermemory"
    true
  }
  npm install -g opencode-websearch-cited@latest 2>/dev/null && log "Plugin: websearch-cited" || {
    warn "Plugin FAILED: websearch-cited"
    true
  }

  # Utility
  npm install -g @lyculs/opencode-firecrawl@latest 2>/dev/null && log "Plugin: firecrawl" || {
    warn "Plugin FAILED: firecrawl"
    true
  }

  # Telemetry & observability
  npm install -g @devtheops/opencode-plugin-otel@latest 2>/dev/null && log "Plugin: otel" || {
    warn "Plugin FAILED: otel"
    true
  }

  # Context7 official MCP (replaces community c7-mcp-server)
  npm install -g @upstash/context7-mcp@latest 2>/dev/null && log "MCP: context7-official" || {
    warn "MCP FAILED: context7-official"
    true
  }

  # Notion MCP (optional, requires API key)
  npm install -g @notionhq/notion-mcp-server@latest 2>/dev/null && log "MCP: notion" || {
    warn "MCP FAILED: notion"
    true
  }

  # LSP servers (language intelligence — installed, detected later by Python gen)
  section "LSP servers"
  npm install -g typescript-language-server typescript pyright yaml-language-server @taplo/cli bash-language-server dockerfile-language-server-nodejs vscode-langservers-extracted vscode-json-languageserver 2>/dev/null || true

  # marksman — Markdown LSP
  MARKSAN_VER="2026-05-23"
  MARKSAN_ARCH="x64"
  [ "$(uname -m)" = "aarch64" ] && MARKSAN_ARCH="arm64"
  MARKSAN_URL="https://github.com/artempyanykh/marksman/releases/download/${MARKSAN_VER}/marksman-linux-${MARKSAN_ARCH}"
  _curl "$MARKSAN_URL" "$HOME/.local/bin/marksman" && chmod +x "$HOME/.local/bin/marksman" && log "marksman ${MARKSAN_VER}" || warn "marksman failed"

  # lua-language-server — Lua LSP
  LUA_LS_VER="3.18.0"
  LUA_LS_ARCH="x64"
  [ "$(uname -m)" = "aarch64" ] && LUA_LS_ARCH="arm64"
  LUA_LS_URL="https://github.com/LuaLS/lua-language-server/releases/download/${LUA_LS_VER}/lua-language-server-${LUA_LS_VER}-linux-${LUA_LS_ARCH}.tar.gz"
  LUA_LS_TMP=$(mktemp -d /tmp/lua-ls.XXXXXX)
  _curl "$LUA_LS_URL" "$LUA_LS_TMP/lua-ls.tar.gz" && tar xzf "$LUA_LS_TMP/lua-ls.tar.gz" -C "$HOME/.local/bin" && log "lua-language-server ${LUA_LS_VER}" || warn "lua-language-server failed"
  rm -rf "$LUA_LS_TMP"

  # zls — Zig Language Server
  ZLS_VER="0.16.0"
  ZLS_ARCH="x86_64"
  [ "$(uname -m)" = "aarch64" ] && ZLS_ARCH="aarch64"
  ZLS_URL="https://github.com/zigtools/zls/releases/download/${ZLS_VER}/zls-${ZLS_ARCH}-linux.tar.gz"
  ZLS_TMP=$(mktemp -d /tmp/zls.XXXXXX)
  _curl "$ZLS_URL" "$ZLS_TMP/zls.tar.gz" && tar xzf "$ZLS_TMP/zls.tar.gz" -C "$ZLS_TMP" && cp "$ZLS_TMP/zls" "$HOME/.local/bin/zls" && chmod +x "$HOME/.local/bin/zls" && log "zls ${ZLS_VER}" || warn "zls failed"
  rm -rf "$ZLS_TMP"

  command -v go &>/dev/null && timeout 60 go install golang.org/x/tools/gopls@latest 2>/dev/null || true
  command -v rustup &>/dev/null && timeout 60 rustup component add rust-analyzer 2>/dev/null || true
  command -v dotnet &>/dev/null && timeout 60 dotnet tool install -g csharp-ls 2>/dev/null || true
  command -v dotnet &>/dev/null && timeout 10 dotnet tool list -g 2>/dev/null || true
  log "LSP servers staged (installed if toolchains present)"
  set -e # restore strict mode

  # ── Post-install verification ─────────────────────────────────────────────
  info "Verifying MCP servers..."
  _mcp_ok=0
  _mcp_miss=0
  _lsp_ok=0
  _lsp_miss=0
  for mcp in c7-mcp-server mcp-server-filesystem agentic-tools-mcp codegraph playwright-mcp agent-browser-mcp-server chrome-devtools-mcp mcp-server-github mcp-server-postgres mcp-server-sequential-thinking memorylayer-mcp; do
    if [ -x "$HOME/.bun/bin/$mcp" ] || which "$mcp" &>/dev/null; then
      _mcp_ok=$((_mcp_ok + 1))
    else
      _mcp_miss=$((_mcp_miss + 1))
      warn "MCP not found: $mcp"
    fi
  done
  info "Verifying LSP servers..."
  for lsp in gopls rust-analyzer typescript-language-server pyright-langserver yaml-language-server marksman taplo bash-language-server docker-langserver; do
    if command -v "$lsp" &>/dev/null; then
      _lsp_ok=$((_lsp_ok + 1))
    else
      _lsp_miss=$((_lsp_miss + 1))
      warn "LSP not found: $lsp"
    fi
  done
  log "MCP: ${_mcp_ok} installed, ${_mcp_miss} missing | LSP: ${_lsp_ok} installed, ${_lsp_miss} missing"

  _step_done step_mcp

  # Global mirror configs for pip, Go (only if not already configured)
  if [ ! -f "$HOME/.config/pip/pip.conf" ]; then
    mkdir -p "$HOME/.config/pip"
    cat >"$HOME/.config/pip/pip.conf" 2>/dev/null <<EOF
[global]
index-url = $PYPI_MIRROR
trusted-host = $(echo "$PYPI_MIRROR" | sed 's|https://||;s|/.*||')
EOF
  fi
  if command -v go &>/dev/null && ! go env GOPROXY 2>/dev/null | grep -q "$GOPROXY"; then
    go env -w GOPROXY="${GOPROXY:-https://goproxy.io,direct}" 2>/dev/null || true
  fi
fi
