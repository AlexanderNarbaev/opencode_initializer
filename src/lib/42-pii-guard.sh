#!/usr/bin/env bash
set -euo pipefail
# PII Guard Module - Sanitizes PII before LLM requests
# 9 detector classes: email, phone, INN, SNILS, passport, credit card, IP, API key, name

_PII_PATTERNS=(
  'email:[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}'
  'phone:\+?[0-9]{10,15}'
  'inn:[0-9]{10,12}'
  'snils:[0-9]{3}-[0-9]{3}-[0-9]{3} [0-9]{2}'
  'passport:[0-9]{4} [0-9]{6}'
  'credit_card:[0-9]{4}[- ]?[0-9]{4}[- ]?[0-9]{4}[- ]?[0-9]{4}'
  'ip:[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}'
  'api_key:(sk-|xai-|tp-|dtn_|ghp_|github_pat_)[a-zA-Z0-9]+'
)

# Sanitize text by replacing PII with placeholders
pii_sanitize() {
  local text="$1"
  local sanitized="$text"
  
  for pattern in "${_PII_PATTERNS[@]}"; do
    local name="${pattern%%:*}"
    local regex="${pattern#*:}"
    sanitized=$(echo "$sanitized" | sed -E "s/$regex/[REDACTED_${name^^}]/g")
  done
  
  echo "$sanitized"
}

# Check if text contains PII
pii_detect() {
  local text="$1"
  
  for pattern in "${_PII_PATTERNS[@]}"; do
    local regex="${pattern#*:}"
    if echo "$text" | grep -qE "$regex"; then
      return 0
    fi
  done
  
  return 1
}

export -f pii_sanitize pii_detect