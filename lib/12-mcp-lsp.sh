#!/usr/bin/env bash
# lib/12-mcp-lsp.sh — MCP servers + LSP servers (STEP 9)
# Requires: MCP_PACKAGES, _npm_install, _retry
set -euo pipefail

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

  # Plugins
  npm install -g opencode-codegraph@latest 2>/dev/null && log "Plugin: opencode-codegraph" || { warn "Plugin FAILED: opencode-codegraph"; true; }
  npm install -g open-orchestra@latest 2>/dev/null && log "Plugin: open-orchestra" || { warn "Plugin FAILED: open-orchestra"; true; }
  npm install -g @tarquinen/opencode-dcp@latest 2>/dev/null && log "Plugin: opencode-dcp" || { warn "Plugin FAILED: opencode-dcp"; true; }
  npm install -g opencode-lazy-loader@latest 2>/dev/null && log "Plugin: opencode-lazy-loader" || { warn "Plugin FAILED: opencode-lazy-loader"; true; }
  npm install -g @gitdamnit/opencode-stranger-danger@latest 2>/dev/null && log "Plugin: opencode-stranger-danger" || { warn "Plugin FAILED: opencode-stranger-danger"; true; }
  npm install -g opencode-damage-control@latest 2>/dev/null && log "Plugin: opencode-damage-control" || { warn "Plugin FAILED: opencode-damage-control"; true; }
  npm install -g opencode-auto-fallback@latest 2>/dev/null && log "Plugin: opencode-auto-fallback" || { warn "Plugin FAILED: opencode-auto-fallback"; true; }

  # Smart routing + AGENTS.md sync (optional dev tools)
  npm install -g @blockrun/clawrouter@latest 2>/dev/null && log "Tool: clawrouter" || { warn "Tool FAILED: clawrouter"; true; }
  npm install -g agents-md-sync@latest 2>/dev/null && log "Tool: agents-md-sync" || { warn "Tool FAILED: agents-md-sync"; true; }

  # LSP servers (language intelligence — installed, detected later by Python gen)
  section "LSP servers"
  npm install -g typescript-language-server typescript pyright yaml-language-server @taplo/cli 2>/dev/null || true

  # marksman — Markdown LSP (real one from artempyanykh/marksman, not npm marksman)
  MARKSAN_VER="2026-02-08"
  MARKSAN_URL="https://github.com/artempyanykh/marksman/releases/download/${MARKSAN_VER}/marksman-linux-x64"
  _curl "$MARKSAN_URL" "$HOME/.local/bin/marksman" && chmod +x "$HOME/.local/bin/marksman" && log "marksman ${MARKSAN_VER}" || warn "marksman failed"

  # lua-language-server — Lua LSP (from LuaLS/lua-language-server GitHub)
  LUA_LS_VER="3.17.0"
  LUA_LS_URL="https://github.com/LuaLS/lua-language-server/releases/download/${LUA_LS_VER}/lua-language-server-${LUA_LS_VER}-linux-x64.tar.gz"
  LUA_LS_TMP=$(mktemp -d /tmp/lua-ls.XXXXXX)
  _curl "$LUA_LS_URL" "$LUA_LS_TMP/lua-ls.tar.gz" && tar xzf "$LUA_LS_TMP/lua-ls.tar.gz" -C "$HOME/.local/bin" && log "lua-language-server ${LUA_LS_VER}" || warn "lua-language-server failed"
  rm -rf "$LUA_LS_TMP"

  # zls — Zig Language Server (from zigtools/zls GitHub, not npm zls utility)
  ZLS_VER="0.16.0"
  ZLS_URL="https://github.com/zigtools/zls/releases/download/${ZLS_VER}/zls-x86_64-linux.tar.gz"
  ZLS_TMP=$(mktemp -d /tmp/zls.XXXXXX)
  _curl "$ZLS_URL" "$ZLS_TMP/zls.tar.gz" && tar xzf "$ZLS_TMP/zls.tar.gz" -C "$ZLS_TMP" && cp "$ZLS_TMP/zls" "$HOME/.local/bin/zls" && chmod +x "$HOME/.local/bin/zls" && log "zls ${ZLS_VER}" || warn "zls failed"
  rm -rf "$ZLS_TMP"

  command -v go &>/dev/null && go install golang.org/x/tools/gopls@latest 2>/dev/null || true
  command -v rustup &>/dev/null && rustup component add rust-analyzer 2>/dev/null || true
  command -v dotnet &>/dev/null && dotnet tool install -g csharp-ls 2>/dev/null || true
  command -v dotnet &>/dev/null && dotnet tool list -g 2>/dev/null || true
  log "LSP servers staged (installed if toolchains present)"
  set -e  # restore strict mode

  # Global mirror configs for pip, Go (only if not already configured)
  if [ ! -f "$HOME/.config/pip/pip.conf" ]; then
    mkdir -p "$HOME/.config/pip"
    cat > "$HOME/.config/pip/pip.conf" 2>/dev/null <<EOF
[global]
index-url = $PYPI_MIRROR
trusted-host = $(echo "$PYPI_MIRROR" | sed 's|https://||;s|/.*||')
EOF
  fi
  if command -v go &>/dev/null && ! go env GOPROXY 2>/dev/null | grep -q "$GOPROXY"; then
    go env -w GOPROXY="${GOPROXY:-https://goproxy.io,direct}" 2>/dev/null || true
  fi
fi
