#!/usr/bin/env bash
set -euo pipefail
# Audit Chain Module - Hash-chained audit trail
# Provides immutable audit logging with SHA-256 chaining

_AUDIT_DIR="${HOME}/.cache/opencode/audit"
_AUDIT_FILE="${_AUDIT_DIR}/audit.jsonl"

# Initialize audit directory
audit_init() {
  mkdir -p "$_AUDIT_DIR"
}

# Append audit entry with hash chain
audit_log() {
  local action="$1"
  local details="$2"
  local timestamp
  timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
  
  # Get previous hash
  local prev_hash="0000000000000000000000000000000000000000000000000000000000000000"
  if [ -f "$_AUDIT_FILE" ]; then
    prev_hash=$(tail -1 "$_AUDIT_FILE" | jq -r '.hash // empty' 2>/dev/null || echo "$prev_hash")
  fi
  
  # Calculate hash
  local entry="{\"timestamp\":\"$timestamp\",\"action\":\"$action\",\"details\":\"$details\",\"prev_hash\":\"$prev_hash\"}"
  local hash
  hash=$(echo -n "$entry" | sha256sum | cut -d' ' -f1)
  
  # Append to audit log
  echo "{\"timestamp\":\"$timestamp\",\"action\":\"$action\",\"details\":\"$details\",\"prev_hash\":\"$prev_hash\",\"hash\":\"$hash\"}" >> "$_AUDIT_FILE"
}

# Verify audit chain integrity
audit_verify() {
  if [ ! -f "$_AUDIT_FILE" ]; then
    echo "No audit log found"
    return 0
  fi
  
  local prev_hash="0000000000000000000000000000000000000000000000000000000000000000"
  while IFS= read -r line; do
    local stored_prev
    stored_prev=$(echo "$line" | jq -r '.prev_hash')
    if [ "$stored_prev" != "$prev_hash" ]; then
      echo "Audit chain broken at: $line"
      return 1
    fi
    prev_hash=$(echo "$line" | jq -r '.hash')
  done < "$_AUDIT_FILE"
  
  echo "Audit chain valid"
  return 0
}

export -f audit_init audit_log audit_verify