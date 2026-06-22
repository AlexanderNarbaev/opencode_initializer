#!/usr/bin/env bash
# lib/04-zsh.sh — Zsh + Oh My Zsh + Powerlevel10k (STEP 3)
set -euo pipefail

if ([ "$MODE" = "full" ] || [ "$MODE" = "reinit" ]) && _gate "INTERACTIVE_DO_ZSH"; then
  section "Zsh + Oh My Zsh + Powerlevel10k"

  ZSH_VER=$(zsh --version 2>/dev/null | awk '{print $2}' | cut -d. -f1,2 || echo "0")
  ZSH_MAJOR=$(echo "$ZSH_VER" | cut -d. -f1)
  ZSH_MINOR=$(echo "$ZSH_VER" | cut -d. -f2)
  if [ "$ZSH_MAJOR" -lt 5 ] || { [ "$ZSH_MAJOR" -eq 5 ] && [ "$ZSH_MINOR" -lt 8 ]; }; then
    warn "zsh $ZSH_VER < 5.8 — upgrading via apt"
    sudo apt-get install -y -qq zsh 2>/dev/null || true
  fi
  log "zsh $(zsh --version 2>/dev/null | awk '{print $2}')"

  ZSH_PATH=$(which zsh)
  if [ "$SHELL" != "$ZSH_PATH" ] && grep -q "$ZSH_PATH" /etc/shells 2>/dev/null; then
    chsh -s "$ZSH_PATH" 2>/dev/null || warn "chsh failed — run manually: chsh -s $ZSH_PATH"
    log "Default shell set to zsh"
  fi

  if [ ! -d "$HOME/.oh-my-zsh" ]; then
    OMZ_URL="https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh"
    OMZ_MIRROR="https://ghproxy.com/$OMZ_URL"
    sh -c "$(curl -fsSL --connect-timeout 15 --retry 2 "$OMZ_URL" 2>/dev/null || curl -fsSL --connect-timeout 15 "$OMZ_MIRROR" 2>/dev/null)" "" --unattended 2>/dev/null || true
  fi

  ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
  GIT_CLONE_MIRROR() {
    local repo="$1" dir="$2"
    git clone --depth=1 "https://github.com/$repo.git" "$dir" 2>/dev/null || \
    git clone --depth=1 "https://ghproxy.com/https://github.com/$repo.git" "$dir" 2>/dev/null || true
  }

  [ ! -d "$ZSH_CUSTOM/themes/powerlevel10k" ] && \
    GIT_CLONE_MIRROR "romkatv/powerlevel10k" "$ZSH_CUSTOM/themes/powerlevel10k"

  for plugin in zsh-autosuggestions zsh-syntax-highlighting zsh-completions; do
    [ ! -d "$ZSH_CUSTOM/plugins/$plugin" ] && \
      GIT_CLONE_MIRROR "zsh-users/$plugin" "$ZSH_CUSTOM/plugins/$plugin"
  done

  [ ! -d "$ZSH_CUSTOM/plugins/fzf-tab" ] && \
    GIT_CLONE_MIRROR "Aloxaf/fzf-tab" "$ZSH_CUSTOM/plugins/fzf-tab"

  if [ ! -f ~/.zshrc ] || ! grep -q "powerlevel10k" ~/.zshrc 2>/dev/null; then
    if [ -f ~/.zshrc ]; then
      cp ~/.zshrc ~/.zshrc.backup."$(date +%Y%m%d-%H%M%S)"
    fi
    cat > ~/.zshrc << 'ZSHEOF'
# Enable Powerlevel10k instant prompt. Must stay at the top.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="powerlevel10k/powerlevel10k"

plugins=(
  git
  zsh-autosuggestions
  zsh-syntax-highlighting
  zsh-completions
  fzf-tab
  fzf
  zoxide
  docker
  docker-compose
  command-not-found
  extract
  z
  history
  copypath
  copyfile
  web-search
  npm
  bun
)

[ -f "$ZSH_CUSTOM/plugins/fzf-tab/fzf-tab.plugin.zsh" ] && \
  source "$ZSH_CUSTOM/plugins/fzf-tab/fzf-tab.plugin.zsh"

source "\$ZSH/oh-my-zsh.sh"

zstyle ':fzf-tab:*' fzf-command ftb-tmux-popup
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza -1 --color=always $realpath'
zstyle ':fzf-tab:complete:__zoxide_z:*' fzf-preview 'eza -1 --color=always $realpath'

[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
ZSHEOF
  fi
  log "Zsh configured"
  _step_done step_zsh
fi
