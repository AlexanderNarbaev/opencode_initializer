#!/usr/bin/env bash
# lib/14-shokunin.sh — Shokunin + Superpowers (STEP 11)
# Requires: MODE, PROJECT_DIR
set -euo pipefail

if ([ "$MODE" = "full" ] || [ "$MODE" = "reinit" ]) && _gate "INTERACTIVE_DO_SHOKUNIN"; then
  section "Shokunin + Superpowers"
  if [ ! -d "$HOME/.shokunin" ]; then
    bash <(curl -sL https://raw.githubusercontent.com/EliasOulkadi/shokunin/master/install.sh) -y 2>/dev/null || true
    log "Shokunin installed"
    SHOKUNIN_PROFILE="$HOME/.shokunin/scripts/linux/profile.sh"
    [ -f "$SHOKUNIN_PROFILE" ] && sed -i 's/echo "Shokunin AI Ecosystem loaded"/# echo "Shokunin AI Ecosystem loaded"/' "$SHOKUNIN_PROFILE" 2>/dev/null || true
  fi
  _step_done step_shokunin

  mkdir -p "$HOME/.config/opencode/skills/superpowers"
  SUPERPOWERS_TMP=$(mktemp -d /tmp/superpowers.XXXXXX)
  git clone --depth=1 https://github.com/obra/superpowers.git "$SUPERPOWERS_TMP" 2>/dev/null || true
  if [ -d "$SUPERPOWERS_TMP/skills" ]; then
    mkdir -p "$HOME/.config/opencode/skills/superpowers/skills"
    cp -r "$SUPERPOWERS_TMP/skills"/* "$HOME/.config/opencode/skills/superpowers/skills/" 2>/dev/null && \
      log "Superpowers: $(ls "$HOME/.config/opencode/skills/superpowers/skills" 2>/dev/null | wc -l) skills loaded" || \
      warn "Superpowers copy failed"
  fi
  rm -rf "$SUPERPOWERS_TMP"
fi
