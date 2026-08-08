#!/usr/bin/env bash
# lib/37-wal.sh — Write-Ahead Log / checkpoint system
# Replaces binary progress file with structured markdown log.
# Requires: _wal_checkpoint, _wal_decide from 00-core.sh
set -euo pipefail

WAL_FILE="${HOME}/.cache/opencode-setup/wal.md"
WAL_AGENT_FILE="${HOME}/.cache/opencode/wal.jsonl"
WAL_TOTAL_MODULES="${WAL_TOTAL_MODULES:-46}"

_wal_init() {
  local now previous_done=0
  now=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
  mkdir -p "$(dirname "$WAL_FILE")"

  # Preserve previous progress for resume
  if [ -f "$WAL_FILE" ]; then
    previous_done=$(grep -oE 'DONE: [0-9]+' "$WAL_FILE" 2>/dev/null | grep -oE '[0-9]+' || echo "0")
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
# Format: {"ts":"ISO8601","domain":"...","decision":"...","rationale":"...","impact":[...],"confidence":<float>,"mode":"S1|S2","prev_hash":"...","hash":"..."}
# Hash-chain (S5.2.3.2): each entry links to previous via SHA-256 for tamper-evidence
_wal_agent_log() {
  local domain="${1:-unknown}"
  local decision="${2:-}"
  local rationale="${3:-}"
  local confidence="${4:-0.85}"
  local mode="${5:-S1}"
  local now impact_json prev_hash entry_hash
  now=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
  impact_json="[]"
  mkdir -p "$(dirname "$WAL_AGENT_FILE")"

  # Hash-chain: get previous hash
  prev_hash="genesis"
  if [ -f "$WAL_AGENT_FILE" ] && [ -s "$WAL_AGENT_FILE" ]; then
    prev_hash=$(tail -1 "$WAL_AGENT_FILE" | jq -r '.hash // "genesis"' 2>/dev/null || echo "genesis")
  fi

  # Compute entry hash: SHA-256(prev + ts + domain + decision + confidence)
  entry_hash=$(echo -n "${prev_hash}${now}${domain}${decision}${confidence}" | sha256sum | awk '{print $1}')

  local entry_line
  entry_line=$(printf '{"ts":"%s","domain":"%s","decision":"%s","rationale":"%s","impact":%s,"confidence":%s,"mode":"%s","prev_hash":"%s","hash":"%s"}' \
    "$now" "$domain" "$decision" "$rationale" "$impact_json" "$confidence" "$mode" "$prev_hash" "$entry_hash")
  _wal_locked_append "$WAL_AGENT_FILE" "$entry_line"
}

# ── WAL rotation: gzip archive when >10MB (S5.2.3.3) ───────────────────────
WAL_MAX_SIZE_MB="${WAL_MAX_SIZE_MB:-10}"
WAL_ARCHIVE_DIR="${WAL_ARCHIVE_DIR:-${HOME}/.cache/opencode-setup/wal-archive}"

_wal_rotate() {
  local wal="${1:-$WAL_AGENT_FILE}"
  [ ! -f "$wal" ] && return 0
  local size
  size=$(stat -c %s "$wal" 2>/dev/null || echo 0)
  local max_bytes=$((WAL_MAX_SIZE_MB * 1024 * 1024))
  if [ "$size" -gt "$max_bytes" ]; then
    local archive_name
    archive_name="wal-$(date -u +%Y%m%d-%H%M%S)"
    mkdir -p "$WAL_ARCHIVE_DIR"
    gzip -c "$wal" > "$WAL_ARCHIVE_DIR/${archive_name}.jsonl.gz" 2>/dev/null && \
      log "WAL rotated: ${archive_name}.jsonl.gz ($((size / 1024))KB)" && \
      : > "$wal"
  fi
}

# ── PII redacted event (S5.2.4.3) — convenience for 45-pii-guard.sh ─────────
_wal_pii_redacted() {
  local detector_count="${1:-0}" details="${2:-auto-redacted}"
  _wal_agent_log "pii_redacted" "PII sanitized: ${detector_count} instance(s)" "$details" "1.0" "S1"
}

if [ "$MODE" = "full" ] || [ "$MODE" = "reinit" ] || [ "$MODE" = "update" ]; then
  _wal_init
  _done=$(grep -oE 'DONE: [0-9]+' "$WAL_FILE" 2>/dev/null | grep -oE '[0-9]+' || echo "0")
  log "WAL resume: ${_done}/${WAL_TOTAL_MODULES} modules done"
fi
