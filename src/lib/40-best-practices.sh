#!/usr/bin/env bash
# lib/40-best-practices.sh — Curated skills from smixs + AI tooling best practices
# Installs: humanizer-ru (Russian AI text humanizer), mentor (session insights),
# disruptor-skills (dev pipeline), ZPL-80 (prompt compression).
# References: smixs/skill-conductor pattern (5-stage lifecycle).
set -euo pipefail

if ([ "$MODE" = "full" ] || [ "$MODE" = "reinit" ]) && _gate "INTERACTIVE_DO_BEST_PRACTICES"; then
  section "Best Practices Skills (smixs curated)"

  SMIXS_SKILLS_DIR="$HOME/.config/opencode/skills/smixs"
  ZPL_PKG_DIR="$HOME/.local/share/zpl80"

  # ── 1. humanizer-ru (Russian AI text humanizer) ─────────────────────────
  if [ "${SKIP_HUMANIZER_RU:-false}" != "true" ]; then
    info "Installing humanizer-ru skill..."
    mkdir -p "$SMIXS_SKILLS_DIR/humanizer-ru"
    if [ ! -d "$SMIXS_SKILLS_DIR/humanizer-ru/.git" ]; then
      git clone --depth 1 -q https://github.com/smixs/humanizer-ru.git "$SMIXS_SKILLS_DIR/humanizer-ru" 2>/dev/null && \
        log "humanizer-ru installed" || warn "humanizer-ru install failed (non-fatal)"
    fi
  fi

  # ── 2. mentor (session insights) ─────────────────────────────────────────
  if [ "${SKIP_MENTOR:-false}" != "true" ]; then
    info "Installing mentor skill..."
    mkdir -p "$SMIXS_SKILLS_DIR/mentor"
    if [ ! -d "$SMIXS_SKILLS_DIR/mentor/.git" ]; then
      git clone --depth 1 -q https://github.com/smixs/mentor.git "$SMIXS_SKILLS_DIR/mentor" 2>/dev/null && \
        log "mentor installed" || warn "mentor install failed (non-fatal)"
    fi
  fi

  # ── 3. disruptor-skills (dev pipeline) ───────────────────────────────────
  if [ "${SKIP_DISRUPTOR:-false}" != "true" ]; then
    info "Installing disruptor-skills..."
    mkdir -p "$SMIXS_SKILLS_DIR/disruptor-skills"
    if [ ! -d "$SMIXS_SKILLS_DIR/disruptor-skills/.git" ]; then
      git clone --depth 1 -q https://github.com/smixs/disruptor-skills.git "$SMIXS_SKILLS_DIR/disruptor-skills" 2>/dev/null && \
        log "disruptor-skills installed" || warn "disruptor-skills install failed (non-fatal)"
    fi
  fi

  # ── 4. ZPL-80 (prompt compression) ───────────────────────────────────────
  if [ "${SKIP_ZPL80:-false}" != "true" ] && command -v pip3 &>/dev/null; then
    info "Installing ZPL-80 prompt compressor..."
    pip3 install --user --quiet ZPL-80 2>/dev/null && log "ZPL-80 installed" || \
      pip install --user --quiet ZPL-80 2>/dev/null && log "ZPL-80 installed" || \
      warn "ZPL-80 install skipped"
  fi

  # ── 5. skill-conductor (skill lifecycle CLI) ─────────────────────────────
  if [ "${SKIP_SKILL_CONDUCTOR:-false}" != "true" ]; then
    info "Installing skill-conductor..."
    SKILL_CONDUCTOR_BIN="$HOME/.local/bin/skill-conductor"
    if [ ! -x "$SKILL_CONDUCTOR_BIN" ]; then
      SC_TMP="$(mktemp -d)"
      git clone --depth 1 -q https://github.com/smixs/skill-conductor.git "$SC_TMP" 2>/dev/null && \
        (cd "$SC_TMP" && go build -o "$SKILL_CONDUCTOR_BIN" ./cmd/skill-conductor 2>/dev/null || \
         (cd "$SC_TMP" && bash install.sh 2>/dev/null || \
          cp -r "$SC_TMP"/* "$HOME/.local/share/skill-conductor/" 2>/dev/null)) && \
        log "skill-conductor installed at $SKILL_CONDUCTOR_BIN" || \
        warn "skill-conductor install deferred (requires Go or manual install)"
      rm -rf "$SC_TMP"
    fi
  fi

  # ── 6. Register skills with opencode ─────────────────────────────────────
  mkdir -p "$HOME/.config/opencode/skills"
  if [ -d "$SMIXS_SKILLS_DIR" ]; then
    for skill_dir in "$SMIXS_SKILLS_DIR"/*/; do
      [ -f "$skill_dir/SKILL.md" ] || continue
      skill_name="$(basename "$skill_dir")"
      ln -sfn "$skill_dir" "$HOME/.config/opencode/skills/$skill_name"
    done
    log "smixs skills linked into ~/.config/opencode/skills/"
  fi

  _step_done step_best_practices
fi