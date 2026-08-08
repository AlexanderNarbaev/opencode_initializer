#!/usr/bin/env bash
# lib/45-pii-guard.sh — PII Sanitizer: 9 detectors for LLM request hardening (STEP 45)
# Detectors: email, phone_ru, phone_int, inn, snils, passport_ru, credit_card, ip_address, api_key_leak
# See: audit finding G13, corporate-airgap-profile.md §4, docs/plans/v3.0-vision.md §5
set -euo pipefail

_step_skip step_pii_guard && return 0

section "PII Sanitizer — Privacy Gate"

# ── PII detection patterns (POSIX ERE compatible) ────────────────────────────
# These patterns detect common PII before LLM requests
declare -A PII_PATTERNS=(
  # Russian PII
  [inn]='\b[0-9]{10}\b|\b[0-9]{12}\b'
  [snils]='\b[0-9]{3}-[0-9]{3}-[0-9]{3} [0-9]{2}\b'
  [passport_ru]='\b[0-9]{2} [0-9]{2} [0-9]{6}\b'
  [phone_ru]='\+7[0-9]{10}\b|\b8[0-9]{10}\b'

  # International
  [email]='[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}'
  [phone_int]='\+[1-9][0-9]{6,14}\b'
  [credit_card]='\b[0-9]{4}[- ]?[0-9]{4}[- ]?[0-9]{4}[- ]?[0-9]{4}\b'
  [ip_address]='\b([0-9]{1,3}\.){3}[0-9]{1,3}\b'

  # API keys (common patterns)
  [api_key_leak]='\b(sk-[A-Za-z0-9]{32,})\b|\b(AKIA[0-9A-Z]{16})\b|\b(ghp_[A-Za-z0-9]{36})\b|\b(gho_[A-Za-z0-9]{36})\b'
)

# ── PII redaction mask ───────────────────────────────────────────────────────
PII_MASK="${PII_MASK:-[REDACTED]}"

# ── Scan text for PII and return detection count ─────────────────────────────
# Usage: _pii_scan <text>
# Returns: number of PII instances found, 0 if clean
_pii_scan() {
  local text="$1" detector count=0

  for detector in "${!PII_PATTERNS[@]}"; do
    local pattern="${PII_PATTERNS[$detector]}"
    local matches
    matches=$(echo "$text" | grep -oE "$pattern" 2>/dev/null | wc -l)
    if [ "$matches" -gt 0 ]; then
      count=$((count + matches))
    fi
  done
  echo "$count"
}

# ── Redact PII from text ─────────────────────────────────────────────────────
# Usage: _pii_redact <text>
# Returns: sanitized text with PII replaced by mask
_pii_redact() {
  local text="$1" detector

  for detector in "${!PII_PATTERNS[@]}"; do
    local pattern="${PII_PATTERNS[$detector]}"
    text=$(echo "$text" | sed -E "s/${pattern}/${PII_MASK}/g" 2>/dev/null || echo "$text")
  done
  echo "$text"
}

# ── Pre-LLM request gate: scan + optionally redact ────────────────────────────
# Usage: _pii_gate <prompt_text>
# Returns: sanitized text, logs findings to audit if enabled
_pii_gate() {
  local prompt="$1"
  local findings

  findings=$(_pii_scan "$prompt")

  if [ "$findings" -gt 0 ]; then
    warn "PII Guard: $findings PII instance(s) detected in LLM request"

    # Log to audit trail if available
    if declare -f _audit_event &>/dev/null; then
      _audit_event "pii_redacted" "{\"detectors\":$findings,\"action\":\"redacted\"}"
    fi

    # Redact and return
    _pii_redact "$prompt"
    return 0
  fi

  echo "$prompt"
}

# ── Scan a file for PII ──────────────────────────────────────────────────────
# Invoked by: dev pii scan <file>
_pii_scan_file() {
  local file="$1"
  [ ! -f "$file" ] && { warn "File not found: $file"; return 1; }

  local line_num=0 total=0
  while IFS= read -r line; do
    line_num=$((line_num + 1))
    local findings
    findings=$(_pii_scan "$line")
    if [ "$findings" -gt 0 ]; then
      echo "  L$line_num: $findings PII instance(s) — ${line:0:80}..."
      total=$((total + findings))
    fi
  done < "$file"

  echo "Total: $total PII instance(s) in $file"
  return "$total"
}

_step_done step_pii_guard
log "PII sanitizer active — ${#PII_PATTERNS[@]} detectors"
