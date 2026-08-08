#!/usr/bin/env bash
# lib/44-audit.sh — Audit Trail: WAL hash-chain + rotation (STEP 44)
# Provides: 7 WAL event types, SHA-256 chain, rotation >10MB → gzip+Qdrant
# See: audit finding G10, SDD workflow spec, docs/plans/v3.0-vision.md §5
set -euo pipefail

_step_skip step_audit && return 0

section "Audit Trail — WAL Hash-Chain + Rotation"

# ── Audit event types ────────────────────────────────────────────────────────
# model_call:        LLM request sent (provider, model, tokens, timestamp)
# tool_call:         Tool execution (tool_name, args_hash, duration, result)
# provider_switch:   Fallback triggered (from_provider → to_provider, reason)
# pii_redacted:      PII detected and sanitized (detector, count, context_hash)
# checkpoint:        Session checkpoint (phase, task_count, files_touched)
# error:             Error event (code, module, message_hash)
# session_boundary:  Session start/end (session_id, model, provider)

# ── WAL file configuration ───────────────────────────────────────────────────
AUDIT_WAL="${AUDIT_WAL:-${HOME}/.cache/opencode-setup/audit.jsonl}"
AUDIT_MAX_SIZE_MB="${AUDIT_MAX_SIZE_MB:-10}"
AUDIT_ARCHIVE_DIR="${AUDIT_ARCHIVE_DIR:-${HOME}/.cache/opencode-setup/audit-archive}"

mkdir -p "$(dirname "$AUDIT_WAL")" "$AUDIT_ARCHIVE_DIR"

# ── Initialize audit directory + seed file ────────────────────────────────────
_audit_init() {
  mkdir -p "$(dirname "$AUDIT_WAL")" "$AUDIT_ARCHIVE_DIR"
  if [ ! -f "$AUDIT_WAL" ]; then
    touch "$AUDIT_WAL"
    chmod 600 "$AUDIT_WAL"
  fi
}

# ── Write audit event with hash-chain ────────────────────────────────────────
# Each event links to previous event's hash for tamper-evidence
_audit_event() {
  local event_type="$1"      # model_call|tool_call|provider_switch|pii_redacted|checkpoint|error|session_boundary
  local details="${2:-{}}"
  local ts
  ts=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

  # Get previous hash for chain
  local prev_hash="genesis"
  if [ -f "$AUDIT_WAL" ] && [ -s "$AUDIT_WAL" ]; then
    prev_hash=$(tail -1 "$AUDIT_WAL" | jq -r '.hash // "genesis"' 2>/dev/null || echo "genesis")
  fi

  # Compute event hash: SHA-256(prev_hash + ts + event_type + details)
  local event_hash
  event_hash=$(echo -n "${prev_hash}${ts}${event_type}${details}" | sha256sum | awk '{print $1}')

  # Write event as JSON line (printf avoids heredoc injection)
  printf '{"ts":"%s","type":"%s","details":%s,"prev":"%s","hash":"%s"}\n' \
    "$ts" "$event_type" "$details" "$prev_hash" "$event_hash" >> "$AUDIT_WAL"
}

# ── Rotation: compress and archive when >10MB ────────────────────────────────
_audit_rotate() {
  local size
  size=$(stat -c %s "$AUDIT_WAL" 2>/dev/null || echo 0)

  local max_bytes=$((AUDIT_MAX_SIZE_MB * 1024 * 1024))
  if [ "$size" -gt "$max_bytes" ]; then
    local archive_name
    archive_name="audit-$(date -u +%Y%m%d-%H%M%S)"
    _spin_start "Rotating audit log (${size} bytes)"
    gzip -c "$AUDIT_WAL" > "$AUDIT_ARCHIVE_DIR/${archive_name}.jsonl.gz" 2>/dev/null && \
      log "Audit archived: ${archive_name}.jsonl.gz" && \
      : > "$AUDIT_WAL"  # Truncate WAL after successful archive
    _spin_stop "✓"
  fi
}

# ── Verify hash-chain integrity ──────────────────────────────────────────────
_audit_verify_chain() {
  local wal="${1:-$AUDIT_WAL}"
  [ ! -f "$wal" ] && { warn "Audit WAL not found: $wal"; return 1; }

  local prev="genesis" count=0 failures=0
  while IFS= read -r line; do
    local ts type details event_hash expected_prev
    ts=$(echo "$line" | jq -r '.ts // ""')
    type=$(echo "$line" | jq -r '.type // ""')
    details=$(echo "$line" | jq -c '.details // {}')
    event_hash=$(echo "$line" | jq -r '.hash // ""')
    expected_prev=$(echo "$line" | jq -r '.prev // ""')

    # Verify prev link
    if [ "$expected_prev" != "$prev" ]; then
      failure=$((failures + 1))
    fi

    # Verify hash
    local computed
    computed=$(echo -n "${prev}${ts}${type}${details}" | sha256sum | awk '{print $1}')
    if [ "$computed" != "$event_hash" ]; then
      failures=$((failures + 1))
    fi

    prev="$event_hash"
    count=$((count + 1))
  done < "$wal"

  if [ "$failures" -eq 0 ]; then
    log "Audit chain VERIFIED: $count events, 0 tampered"
    return 0
  else
    warn "Audit chain TAMPERED: $failures/$count events fail verification"
    return 1
  fi
}

# ── Print audit statistics ────────────────────────────────────────────────────
_audit_stats() {
  [ ! -f "$AUDIT_WAL" ] && { info "No audit events recorded"; return 0; }

  local total
  total=$(wc -l < "$AUDIT_WAL" 2>/dev/null || echo 0)
  echo "Audit events: $total total"

  for etype in model_call tool_call provider_switch pii_redacted checkpoint error session_boundary; do
    local count
    count=$(grep -c "\"type\":\"$etype\"" "$AUDIT_WAL" 2>/dev/null | tr -d '[:space:]' || echo 0)
    [ "${count:-0}" -gt 0 ] 2>/dev/null && echo "  $etype: $count"
  done

  local last_ts
  last_ts=$(tail -1 "$AUDIT_WAL" 2>/dev/null | grep -oE '"ts":"[^"]*"' | head -1 | cut -d'"' -f4 || echo "unknown")
  echo "Last event: $last_ts"

  local total_size
  total_size=$(du -sh "$(dirname "$AUDIT_WAL")" 2>/dev/null | cut -f1 || echo "unknown")
  echo "Total size (with archives): $total_size"
}

# ── Log initial event (only if WAL is empty — idempotent) ────────────────────
if [ ! -s "$AUDIT_WAL" ]; then
  _audit_event "session_boundary" "{\"event\":\"audit_module_initialized\",\"version\":\"${SCRIPT_VERSION:-v3.0.0}\"}"
fi

# ── Run rotation check ──────────────────────────────────────────────────────
_audit_rotate

_step_done step_audit
log "Audit trail active — WAL: $AUDIT_WAL (max ${AUDIT_MAX_SIZE_MB}MB)"

# ── Exports ──────────────────────────────────────────────────────────────────
export AUDIT_WAL AUDIT_MAX_SIZE_MB
# Functions are available to setup.sh via source; export -f for subshell access
export -f _audit_init 2>/dev/null || true
export -f _audit_event 2>/dev/null || true
export -f _audit_rotate 2>/dev/null || true
export -f _audit_stats 2>/dev/null || true
export -f _audit_verify_chain 2>/dev/null || true
