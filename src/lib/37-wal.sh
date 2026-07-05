#!/usr/bin/env bash
# lib/37-wal.sh — Write-Ahead Log / checkpoint system
# Replaces binary progress file with structured markdown log.
# Requires: _wal_checkpoint, _wal_decide from 00-core.sh
set -euo pipefail

WAL_FILE="${HOME}/.cache/opencode-setup/wal.md"
WAL_AGENT_FILE="${HOME}/.cache/opencode/wal.jsonl"
WAL_TOTAL_MODULES="${WAL_TOTAL_MODULES:-39}"

_wal_init() {
  local now previous_done=0
  now=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
  mkdir -p "$(dirname "$WAL_FILE")"

  # Preserve previous progress for resume
  if [ -f "$WAL_FILE" ]; then
    previous_done=$(grep -oP 'DONE: \K\d+' "$WAL_FILE" 2>/dev/null || echo "0")
  fi

  cat > "$WAL_FILE" <<WALEOF
# WAL — opencode_initializer State
_Updated: ${now}_

## Active Phase
DONE: ${previous_done}/${WAL_TOTAL_MODULES} modules

## Protected (DO NOT TOUCH)
- ${WAL_FILE} — managed by setup.sh, do not edit manually
- ~/.cache/opencode-setup/progress — legacy, rewritten from WAL on resume

## Recent Decisions
<!-- _wal_decide entries append here -->

## Next Step
- Run setup to begin bootstrap
WALEOF
  log "WAL initialized: $WAL_FILE (resumed from ${previous_done}/${WAL_TOTAL_MODULES})"
}

# ── Agent WAL (JSONL) — session journal for AI agents ──────────────────────
# Protocol: AGENTS.md / coprocessor SKILL.md
# Format: {"ts":"ISO8601","domain":"...","decision":"...","rationale":"...","impact":[...],"confidence":<float>,"mode":"S1|S2"}
_wal_agent_log() {
  local domain="${1:-unknown}"
  local decision="${2:-}"
  local rationale="${3:-}"
  local confidence="${4:-0.85}"
  local mode="${5:-S1}"
  local now impact_json
  now=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
  impact_json="[]"
  mkdir -p "$(dirname "$WAL_AGENT_FILE")"
  printf '{"ts":"%s","domain":"%s","decision":"%s","rationale":"%s","impact":%s,"confidence":%s,"mode":"%s"}\n' \
    "$now" "$domain" "$decision" "$rationale" "$impact_json" "$confidence" "$mode" >> "$WAL_AGENT_FILE"
}

if [ "$MODE" = "full" ] || [ "$MODE" = "reinit" ] || [ "$MODE" = "update" ]; then
  _wal_init
  _done=$(grep -oP 'DONE: \K\d+' "$WAL_FILE" 2>/dev/null || echo "0")
  log "WAL resume: ${_done}/${WAL_TOTAL_MODULES} modules done"
fi
