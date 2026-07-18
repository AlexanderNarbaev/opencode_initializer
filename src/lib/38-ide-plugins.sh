#!/usr/bin/env bash
# lib/38-ide-plugins.sh — AI plugins for JetBrains IDEs, VS Code, and compatible editors
# Detects installed IDEs and installs AI coding plugins (DevoxxGenie, Copilot, etc.)
# Reference: https://plugins.jetbrains.com | https://marketplace.visualstudio.com
set -euo pipefail

_step_skip step_ide_plugins && return 0
section "IDE AI Plugins"
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

# ── AI Plugins ─────────────────────────────────────────────────────────
JETBRAINS_AI_PLUGINS=(
  "24169-devoxxgenie:DevoxxGenie"
  "com.github.copilot:GitHub Copilot"
)
VSCODE_AI_EXTENSIONS=(
  "GitHub.copilot"
  "GitHub.copilot-chat"
  "Continue.continue"
)

jetbrains_count=0
vscode_count=0

# JetBrains
while IFS= read -r ide_bin; do
  [ -z "$ide_bin" ] && continue
  ide_name=$(basename "$(dirname "$(dirname "$ide_bin")")" 2>/dev/null || echo "JetBrains")
  info "JetBrains: $ide_name"
  for pd in "${JETBRAINS_AI_PLUGINS[@]}"; do
    pid="${pd%%:*}"
    pdesc="${pd#*:}"
    "$ide_bin" installPlugins "$pid" 2>/dev/null && log "  $pdesc" || warn "  skip: $pid"
  done
  jetbrains_count=$((jetbrains_count + 1))
done < <(find_jetbrains_ides)

# VS Code
if command -v code &>/dev/null; then
  info "VS Code"
  for eid in "${VSCODE_AI_EXTENSIONS[@]}"; do
    code --install-extension "$eid" --force 2>/dev/null && log "  $eid" || warn "  skip: $eid"
  done
  vscode_count=1
fi

[ $jetbrains_count -gt 0 ] || [ $vscode_count -gt 0 ] && \
  log "AI plugins: $jetbrains_count JetBrains + $vscode_count VS Code" || \
  info "No IDEs detected"

shopt -u nullglob 2>/dev/null || true
_step_done step_ide_plugins
