#!/usr/bin/env bash
# lib/38-ide-plugins.sh — Open-Source AI plugins for JetBrains IDEs, VS Code, and compatible editors
# Detects installed IDEs and installs open-source AI coding plugins (NO proprietary tools)
# License: All installed plugins are Apache 2.0 or MIT — fully open-source
# Reference: https://plugins.jetbrains.com | https://marketplace.visualstudio.com
set -euo pipefail

_step_skip step_ide_plugins && return 0
section "IDE AI Plugins (Open-Source)"
shopt -s nullglob 2>/dev/null || true

# ── JetBrains IDE detection ────────────────────────────────────────────
find_jetbrains_ides() {
  local ides="" dir latest
  for dir in "$HOME/.local/share/JetBrains/Toolbox/apps/"*/; do
    [ -d "$dir" ] || continue
    latest=$(ls -1d "$dir"ch-0/*/ 2>/dev/null | sort -V | tail -1)
    [ -n "$latest" ] && [ -f "$latest/bin/idea.sh" ] && ides="$ides $latest/bin/idea.sh"
  done
  for dir in "$HOME"/idea-*/ "$HOME"/pycharm-*/ "$HOME"/webstorm-*/ "$HOME"/goland-*/; do
    [ -d "$dir" ] && [ -f "$dir/bin/idea.sh" ] && ides="$ides $dir/bin/idea.sh"
  done
  for dir in /snap/intellij-idea-community/ /snap/pycharm-community/ /snap/webstorm/; do
    [ -f "$dir/current/bin/idea.sh" ] && ides="$ides $dir/current/bin/idea.sh"
  done
  echo "$ides" | xargs -n1 2>/dev/null | sort -u
}

# ── Open-Source AI Plugins for JetBrains ────────────────────────────────
# Plugin format: "plugin_id:Name — description"
JETBRAINS_AI_PLUGINS=(
  "24169-devoxxgenie:DevoxxGenie — local LLMs, RAG, MCP, agent mode, SDD (Apache 2.0, 70K+ users)"
  "28247:Cline — AI coding agent, multi-model, local models, MCP (Apache 2.0)"
  "22379:Tabby — self-hosted code completion, local models, no cloud (Apache 2.0)"
)

# ── Open-Source AI Extensions for VS Code ───────────────────────────────
VSCODE_AI_EXTENSIONS=(
  "saoudrizwan.claude-dev:Cline — AI coding agent, Ollama support, MCP (Apache 2.0)"
  "TabbyML.vscode-tabby:Tabby — self-hosted completion, local models (Apache 2.0)"
  "ex3ndr.llama-coder:Llama Coder — Ollama-only code completion, FIM (MIT)"
  "nicepkg.aide-pro:Aide — code transformations, batch AI processing (MIT)"
  "nicepkg.gpt-runner:GPT Runner — AI preset manager, custom endpoints (MIT)"
)

# ── Open-Source CLI AI Tools ────────────────────────────────────────────
# Aider — git-aware multi-file AI edits (Apache 2.0)
if command -v uv &>/dev/null && ! command -v aider &>/dev/null; then
  info "Installing Aider (git-aware AI pair programmer)..."
  uv tool install aider-chat 2>/dev/null && log "  Aider installed" || warn "  Aider skipped"
elif command -v aider &>/dev/null; then
  log "Aider already installed"
fi

# Cline CLI — AI coding agent from terminal (Apache 2.0)
if command -v npm &>/dev/null && ! command -v cline &>/dev/null; then
  info "Installing Cline CLI..."
  npm install -g cline 2>/dev/null && log "  Cline CLI installed" || warn "  Cline CLI skipped"
elif command -v cline &>/dev/null; then
  log "Cline CLI already installed"
fi

# ── Installation: IDE Plugins ───────────────────────────────────────────
jetbrains_count=0

# JetBrains IDEs
while IFS= read -r ide_bin; do
  [ -z "$ide_bin" ] && continue
  ide_name=$(basename "$(dirname "$(dirname "$ide_bin")")" 2>/dev/null || echo "JetBrains")
  info "JetBrains IDE: $ide_name"
  for pd in "${JETBRAINS_AI_PLUGINS[@]}"; do
    pid="${pd%%:*}"
    pdesc="${pd#*:}"
    "$ide_bin" installPlugins "$pid" 2>/dev/null && log "  $pdesc" || warn "  skip: $pid"
  done
  jetbrains_count=$((jetbrains_count + 1))
done < <(find_jetbrains_ides)

# VS Code
if command -v code &>/dev/null; then
  info "VS Code: $(which code)"
  for ed in "${VSCODE_AI_EXTENSIONS[@]}"; do
    eid="${ed%%:*}"
    edesc="${ed#*:}"
    code --install-extension "$eid" --force 2>/dev/null && log "  $edesc" || warn "  skip: $eid"
  done
  vscode_count=1
else
  vscode_count=0
fi

# ── Local model recommendations ─────────────────────────────────────────
if command -v ollama &>/dev/null; then
  info "Local Ollama models for IDE plugins:"
  info "  FIM completion:  ollama pull codellama:code    (7B, <PRE>/<SUF>/<MID>)"
  info "  Code specialist: ollama pull qwen3:8b           (8B, excellent coding)"
  info "  General purpose: ollama pull llama3.2            (3B, fast chat)"
  info "  Embeddings:      ollama pull nomic-embed-text    (local RAG)"
fi

# ── Summary ─────────────────────────────────────────────────────────────
if [ $jetbrains_count -gt 0 ] || [ $vscode_count -gt 0 ]; then
  log "Open-source AI plugins: $jetbrains_count JetBrains IDE(s) + VS Code"
  log "CLI tools: aider (git-aware edits) + cline (terminal agent)"
else
  info "No IDEs detected — install IntelliJ IDEA or VS Code for AI plugin setup"
  if command -v aider &>/dev/null || command -v cline &>/dev/null; then
    log "CLI tools available: use aider/cline from terminal"
  fi
fi

shopt -u nullglob 2>/dev/null || true
_step_done step_ide_plugins
