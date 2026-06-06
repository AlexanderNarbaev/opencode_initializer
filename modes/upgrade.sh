#!/usr/bin/env bash
# modes/upgrade.sh — full system update chain
# Sources: lib/helpers.sh, lib/00-core.sh must be sourced before
set -euo pipefail

section "UPGRADE: system packages"
_pkg_update
case "$PKG_MANAGER" in
  apt) sudo apt-get full-upgrade -y -q -o APT::Get::Fix-Missing=true 2>/dev/null || true
       sudo apt-get autoremove -y -q 2>/dev/null || true
       sudo apt-get autoclean -y -q 2>/dev/null || true ;;
  dnf) sudo dnf upgrade --refresh -y 2>/dev/null || true
       sudo dnf autoremove -y 2>/dev/null || true ;;
  pacman) sudo pacman -Syu --noconfirm 2>/dev/null || true ;;
  apk) sudo apk upgrade --available 2>/dev/null || true ;;
  zypper) sudo zypper --non-interactive dup 2>/dev/null || true ;;
  brew) brew upgrade 2>/dev/null || true ;;
esac
log "$PKG_MANAGER upgraded"

section "UPGRADE: snap packages"
command -v snap &>/dev/null && sudo snap refresh 2>/dev/null || true
log "snap refreshed"

section "UPGRADE: SDKMAN"
if [ -f "$HOME/.sdkman/bin/sdkman-init.sh" ]; then
  source "$HOME/.sdkman/bin/sdkman-init.sh" 2>/dev/null || true
  sdk selfupdate -force 2>/dev/null || true
  sdk update 2>/dev/null || true
  sdk upgrade 2>/dev/null || true
  log "SDKMAN updated"
else
  warn "SDKMAN not found, skipping"
fi

section "UPGRADE: Oh My Zsh"
if [ -f "$HOME/.oh-my-zsh/oh-my-zsh.sh" ]; then
  zsh -c 'source ~/.oh-my-zsh/oh-my-zsh.sh && omz update' 2>/dev/null || true
  log "OMZ updated"
fi

section "UPGRADE: Rust"
command -v rustup &>/dev/null && rustup update 2>/dev/null && log "Rust toolchain updated" || warn "Rust not installed"

section "UPGRADE: Go"
if command -v go &>/dev/null; then
  GO_CURRENT=$(go version 2>/dev/null | grep -oP 'go\K[0-9.]+' | head -1)
  GO_LATEST=$(curl -s --connect-timeout 10 https://go.dev/dl/ 2>/dev/null | grep -oP 'go[0-9.]+\.linux-amd64\.tar\.gz' | head -1 | grep -oP 'go\K[0-9.]+')
  if [ -n "$GO_LATEST" ] && [ "$GO_CURRENT" != "$GO_LATEST" ]; then
    info "Go $GO_CURRENT → $GO_LATEST available. Re-run --reinit to upgrade."
  else
    log "Go $GO_CURRENT up to date"
  fi
fi

section "UPGRADE: npm global packages"
npm update -g 2>/dev/null || true
for pkg in opencode-ai c7-mcp-server agent-browser-mcp-server opencode-codegraph open-orchestra @tarquinen/opencode-dcp opencode-lazy-loader @gitdamnit/opencode-stranger-danger opencode-damage-control opencode-auto-fallback @blockrun/clawrouter agents-md-sync; do
  npm install -g "$pkg@latest" 2>/dev/null && log "npm: $pkg" || warn "npm: $pkg failed"
done

section "UPGRADE: uv + pip"
command -v uv &>/dev/null && uv self update 2>/dev/null && log "uv updated" || warn "uv not found"
command -v uv &>/dev/null && uv python install 3.14 2>/dev/null || true

section "UPGRADE: regenerate configs"
bash "$(dirname "$0")/../setup.sh" --fix-config -p "${PROJECT_DIR:-$HOME/projects}" 2>/dev/null || true
log "opencode.json regenerated"

section "UPGRADE: verify"
PASS=0; FAIL=0
_check() { if eval "$2" &>/dev/null; then PASS=$((PASS+1)); else FAIL=$((FAIL+1)); warn "$1 — check needed"; fi; }
_check "Docker" "docker --version"
_check "Java" "java -version 2>&1 | head -1"
_check "Go" "go version"
_check "Rust" "rustc --version"
_check "Node" "node --version"
_check "Python" "python3.14 --version"
_check "OpenCode" "opencode --version"
_check "zsh" "zsh --version"
_check "git" "git --version"
log "Upgrade complete: $PASS/$((PASS+FAIL)) tools OK"
exit 0
