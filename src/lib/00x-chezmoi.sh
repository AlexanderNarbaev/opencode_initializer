#!/usr/bin/env bash
# src/lib/00x-chezmoi.sh — chezmoi integration for dotfile management
# https://www.chezmoi.io/
set -euo pipefail

# ── Configuration ────────────────────────────────────────────────────────────
_CHEZMOI_SOURCE="${CHEZMOI_SOURCE:-$HOME/.local/share/chezmoi}"
_CHEZMOI_CONFIG="${CHEZMOI_CONFIG:-$HOME/.config/chezmoi/chezmoi.toml}"

# ── Check chezmoi availability ───────────────────────────────────────────────
_chezmoi_check() {
  if ! command -v chezmoi &>/dev/null; then
    warn "chezmoi not installed"
    info "Install: sh -c \"\$(curl -fsLS get.chezmoi.io)\""
    return 1
  fi
  return 0
}

# ── Initialize chezmoi ──────────────────────────────────────────────────────
# Usage: _chezmoi_init [REPO_URL]
_chezmoi_init() {
  local repo_url="${1:-}"

  if ! _chezmoi_check; then return 1; fi

  if [ -d "$_CHEZMOI_SOURCE" ]; then
    log "chezmoi already initialized"
    return 0
  fi

  if [ -n "$repo_url" ]; then
    chezmoi init --apply "$repo_url"
  else
    chezmoi init
  fi

  log "chezmoi initialized"
}

# ── Add dotfile to chezmoi ───────────────────────────────────────────────────
# Usage: _chezmoi_add FILE
_chezmoi_add() {
  local file="$1"

  if ! _chezmoi_check; then return 1; fi

  if [ ! -e "$file" ]; then
    warn "File not found: $file"
    return 1
  fi

  chezmoi add "$file"
  log "Added to chezmoi: $file"
}

# ── Apply chezmoi changes ────────────────────────────────────────────────────
# Usage: _chezmoi_apply [DRY_RUN]
_chezmoi_apply() {
  local dry_run="${1:-false}"

  if ! _chezmoi_check; then return 1; fi

  if [ "$dry_run" = "true" ]; then
    chezmoi apply --dry-run
  else
    chezmoi apply
  fi

  log "chezmoi changes applied"
}

# ── Sync dotfiles with git ──────────────────────────────────────────────────
# Usage: _chezmoi_sync [MESSAGE]
_chezmoi_sync() {
  local message="${1:-Update dotfiles}"

  if ! _chezmoi_check; then return 1; fi

  # cd to chezmoi source
  pushd "$_CHEZMOI_SOURCE" >/dev/null

  # Check for changes
  if git diff --quiet && git diff --cached --quiet; then
    log "No changes to sync"
    popd >/dev/null
    return 0
  fi

  # Commit and push
  git add -A
  git commit -m "$message"
  git push

  popd >/dev/null
  log "Dotfiles synced: $message"
}

# ── Import existing dotfiles ─────────────────────────────────────────────────
# Usage: _chezmoi_import
_chezmoi_import() {
  if ! _chezmoi_check; then return 1; fi

  local dotfiles=(
    "$HOME/.bashrc"
    "$HOME/.zshrc"
    "$HOME/.gitconfig"
    "$HOME/.vimrc"
    "$HOME/.tmux.conf"
    "$HOME/.ssh/config"
  )

  for file in "${dotfiles[@]}"; do
    if [ -e "$file" ]; then
      chezmoi add "$file"
      log "Imported: $file"
    fi
  done

  log "Dotfiles imported"
}

# ── Create chezmoi template ─────────────────────────────────────────────────
# Usage: _chezmoi_template FILE
_chezmoi_template() {
  local file="$1"

  if ! _chezmoi_check; then return 1; fi

  chezmoi chattr --template "$file"
  log "Template created: $file"
}

# ── chezmoi status ──────────────────────────────────────────────────────────
# Usage: _chezmoi_status
_chezmoi_status() {
  if ! _chezmoi_check; then return 1; fi

  chezmoi status
}

# ── chezmoi diff ─────────────────────────────────────────────────────────────
# Usage: _chezmoi_diff
_chezmoi_diff() {
  if ! _chezmoi_check; then return 1; fi

  chezmoi diff
}

# ── Export functions ─────────────────────────────────────────────────────────
export -f _chezmoi_check _chezmoi_init _chezmoi_add _chezmoi_apply \
  _chezmoi_sync _chezmoi_import _chezmoi_template _chezmoi_status \
  _chezmoi_diff 2>/dev/null || true
