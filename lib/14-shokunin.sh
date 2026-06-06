#!/usr/bin/env bash
# lib/14-shokunin.sh — Shokunin + Superpowers + Caveman (STEP 11)
# Requires: MODE, PROJECT_DIR
set -euo pipefail

if ([ "$MODE" = "full" ] || [ "$MODE" = "reinit" ]) && _gate "INTERACTIVE_DO_SHOKUNIN"; then
  section "Shokunin + Superpowers + Caveman"
  if [ ! -d "$HOME/.shokunin" ]; then
    bash <(curl -sL https://raw.githubusercontent.com/EliasOulkadi/shokunin/master/install.sh) -y 2>/dev/null || true
    log "Shokunin installed"
    # Fix shokunin profile to not echo on load (P10k compat)
    SHOKUNIN_PROFILE="$HOME/.shokunin/scripts/linux/profile.sh"
    [ -f "$SHOKUNIN_PROFILE" ] && sed -i 's/echo "Shokunin AI Ecosystem loaded"/# echo "Shokunin AI Ecosystem loaded"/' "$SHOKUNIN_PROFILE" 2>/dev/null || true
  fi
  _step_done step_shokunin

  mkdir -p "$HOME/.config/opencode/skills/superpowers"
  SUPERPOWERS_TMP=$(mktemp -d /tmp/superpowers.XXXXXX)
  git clone --depth=1 https://github.com/obra/superpowers.git "$SUPERPOWERS_TMP" 2>/dev/null || true
  [ -d "$SUPERPOWERS_TMP/skills" ] && cp -r "$SUPERPOWERS_TMP/skills" "$HOME/.config/opencode/skills/superpowers" 2>/dev/null || true
  rm -rf "$SUPERPOWERS_TMP"

  # Caveman skill
  if [ ! -d "$HOME/.caveman-opencode" ]; then
    git clone https://github.com/anthonystepvoy/caveman-opencode.git "$HOME/.caveman-opencode" 2>/dev/null || true
  fi
  if [ -d "$HOME/.caveman-opencode" ]; then
    mkdir -p "$PROJECT_DIR/.opencode/skills/caveman" 2>/dev/null || mkdir -p "$HOME/agi/.opencode/skills/caveman" 2>/dev/null || true
    cp "$HOME/.caveman-opencode/skills/caveman.md" "$PROJECT_DIR/.opencode/skills/caveman/SKILL.md" 2>/dev/null || cp "$HOME/.caveman-opencode/skills/caveman.md" "$HOME/agi/.opencode/skills/caveman/SKILL.md" 2>/dev/null || true
    log "Caveman skill installed"
  fi
fi
