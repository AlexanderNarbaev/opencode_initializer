#!/usr/bin/env bash
# lib/37-wal.sh — Write-Ahead Log / checkpoint system
# Replaces binary progress file with structured markdown log.
# Requires: _wal_checkpoint, _wal_decide from 00-core.sh
set -euo pipefail

WAL_FILE="${HOME}/.cache/opencode-setup/wal.md"
WAL_TOTAL_MODULES="${WAL_TOTAL_MODULES:-39}"

_wal_init() {
  local now
  now=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
  mkdir -p "$(dirname "$WAL_FILE")"
  cat > "$WAL_FILE" <<WALEOF
# WAL — opencode_initializer State
_Updated: ${now}_

## Active Phase
DONE: 0/${WAL_TOTAL_MODULES} modules

## Protected (DO NOT TOUCH)
- ${WAL_FILE} — managed by setup.sh, do not edit manually
- ~/.cache/opencode-setup/progress — legacy, rewritten from WAL on resume

## Recent Decisions
<!-- _wal_decide entries append here -->

## Next Step
- Run setup to begin bootstrap
WALEOF
  log "WAL initialized: $WAL_FILE"
}

if [ "$MODE" = "full" ] || [ "$MODE" = "reinit" ] || [ "$MODE" = "update" ]; then
  _wal_init

  # ── Restore progress from WAL for resume ──────────────────────────────────
  if [ -f "$WAL_FILE" ]; then
    _done=$(grep -oP 'DONE: \K\d+' "$WAL_FILE" 2>/dev/null || echo "0")
    log "WAL resume: ${_done}/${WAL_TOTAL_MODULES} modules done"
  fi
fi
