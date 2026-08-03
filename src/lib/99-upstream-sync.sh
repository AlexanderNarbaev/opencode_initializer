#!/usr/bin/env bash
# lib/99-upstream-sync.sh — Sync upstream git submodules & version pins
set -euo pipefail

if ([ "$MODE" = "full" ] || [ "$MODE" = "reinit" ] || [ "$MODE" = "update" ]) && _gate "INTERACTIVE_DO_UPSTREAM_SYNC"; then
  section "Upstream Sync (submodules + version pins)"

  # ── 1. Initialize git submodules ──────────────────────────────────────────
  if [ -f "$SCRIPT_DIR/.gitmodules" ] && [ -d "$SCRIPT_DIR/.git" ]; then
    info "Syncing upstream git submodules..."
    git -C "$SCRIPT_DIR" submodule update --init --recursive --depth 1 2>&1 | tail -5 || \
      warn "Some submodules failed to initialize (non-fatal)"
    log "Upstream submodules synced"
  else
    info "No .gitmodules or not a git checkout — skipping submodule sync"
  fi

  # ── 2. Refresh pinned versions from npm/GitHub ──────────────────────────
  info "Checking upstream versions..."
  if [ -f "$SCRIPT_DIR/src/lib/version-check.sh" ]; then
    bash "$SCRIPT_DIR/src/lib/version-check.sh" 2>&1 | tail -10 || \
      warn "version-check.sh reported issues"
  fi

  # ── 4. Ensure best-practices skills are installed ───────────────────────
  if [ "${BEST_PRACTICES_ENABLED:-true}" != "false" ] && [ -f "$SCRIPT_DIR/src/lib/40-best-practices.sh" ]; then
    info "Best practices skills: enabled (default)"
    bash "$SCRIPT_DIR/src/lib/40-best-practices.sh" 2>&1 | tail -5 || true
  fi

  _step_done step_upstream_sync
fi