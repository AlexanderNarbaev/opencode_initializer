#!/usr/bin/env bash
# lib/43-governance.sh — Model Governance: allowlist/denylist policy engine
# Requires: helpers.sh (log, warn, info, err, section), 00-core.sh (_step_skip, _step_done)
# Policy file: ~/.config/opencode/model-policy.json
# Idempotent: creates default only when absent, never overwrites.
set -euo pipefail

# ── Constants ──────────────────────────────────────────────────────────────────
GOVERNANCE_POLICY_FILE="${OPENCODE_MODEL_POLICY:-$HOME/.config/opencode/model-policy.json}"
GOVERNANCE_AUDIT_FILE="${OPENCODE_AUDIT_LOG:-$HOME/.cache/opencode/audit.jsonl}"
GOVERNANCE_DEFAULT_MODE="allow-all"

_step_skip step_governance && return 0

section "Model Governance Policy"

# ── Default policy (created only if file absent — idempotent) ─────────────────
if [ ! -f "$GOVERNANCE_POLICY_FILE" ]; then
  mkdir -p "$(dirname "$GOVERNANCE_POLICY_FILE")"
  jq -n '{version:1, mode:"allow-all", allowed_providers:[], denied_providers:[], allowed_models:[], denied_models:[], max_cost_per_1m:null, audit:false, note:"modes: allow-all | allowlist | corporate"}' > "$GOVERNANCE_POLICY_FILE"
  log "model-policy.json created (default: allow-all)"
else
  log "model-policy.json exists — preserving user configuration"
fi

# ── Core functions (sourced by setup.sh and pre-session-check.sh) ──────────────

# _policy_load: read policy file, return mode via stdout; fallback to default
_policy_load() {
  local mode
  if [ -f "$GOVERNANCE_POLICY_FILE" ]; then
    mode=$(jq -r '.mode // "allow-all"' "$GOVERNANCE_POLICY_FILE" 2>/dev/null) || true
  fi
  echo "${mode:-$GOVERNANCE_DEFAULT_MODE}"
}

# _provider_allowed <provider_name>: returns 0 if allowed, 1 if denied
_provider_allowed() {
  local provider="$1"
  [ -z "$provider" ] && return 1

  # Policy file absent → everything allowed (backward compat)
  [ ! -f "$GOVERNANCE_POLICY_FILE" ] && return 0

  # Check mode
  local mode
  mode=$(jq -r '.mode // "allow-all"' "$GOVERNANCE_POLICY_FILE" 2>/dev/null) || return 0

  case "$mode" in
    allow-all)
      return 0
      ;;
    allowlist|corporate)
      # Check denied list first (takes priority)
      if jq -e --arg p "$provider" '.denied_providers | index($p) != null' "$GOVERNANCE_POLICY_FILE" >/dev/null 2>&1; then
        return 1
      fi
      # Check allowed list
      if jq -e --arg p "$provider" '.allowed_providers | index($p) != null' "$GOVERNANCE_POLICY_FILE" >/dev/null 2>&1; then
        return 0
      fi
      # Not in allowed → denied
      return 1
      ;;
    *)
      return 0  # unknown mode → allow
      ;;
  esac
}

# _model_allowed <provider_name> [model_id]: checks provider + optional model
_model_allowed() {
  local provider="$1" model="${2:-}"

  # First check provider
  if ! _provider_allowed "$provider"; then
    return 1
  fi

  # If model specified and policy in corporate mode, check model-level deny
  if [ -n "$model" ] && [ -f "$GOVERNANCE_POLICY_FILE" ]; then
    local mode
    mode=$(jq -r '.mode // "allow-all"' "$GOVERNANCE_POLICY_FILE" 2>/dev/null) || return 0
    if [ "$mode" = "corporate" ]; then
      # Check denied models
      if jq -e --arg m "$model" '.denied_models | index($m) != null' "$GOVERNANCE_POLICY_FILE" >/dev/null 2>&1; then
        return 1
      fi
      # If allowed_models specified, model must be in list
      local allowed_count
      allowed_count=$(jq '.allowed_models | length' "$GOVERNANCE_POLICY_FILE" 2>/dev/null) || allowed_count=0
      if [ "$allowed_count" -gt 0 ]; then
        if jq -e --arg m "$model" '.allowed_models | index($m) != null' "$GOVERNANCE_POLICY_FILE" >/dev/null 2>&1; then
          return 0
        else
          return 1
        fi
      fi
    fi
  fi

  return 0
}

# _policy_validate: check policy JSON schema sanity, return 0 on valid
_policy_validate() {
  if [ ! -f "$GOVERNANCE_POLICY_FILE" ]; then
    warn "model-policy.json not found (all-allowed, no policy)"
    return 0
  fi
  if ! jq empty "$GOVERNANCE_POLICY_FILE" 2>/dev/null; then
    warn "model-policy.json: INVALID JSON — policy disabled"
    return 1
  fi
  local mode
  mode=$(jq -r '.mode // "unknown"' "$GOVERNANCE_POLICY_FILE" 2>/dev/null) || mode="unknown"
  case "$mode" in
    allow-all|allowlist|corporate) return 0 ;;
    *) warn "model-policy.json: unknown mode '$mode' (expected: allow-all|allowlist|corporate)" && return 1 ;;
  esac
}

# _policy_audit_log <event_json>: append to audit log when audit=true in policy
_policy_audit_log() {
  local event="$1"
  [ -z "$event" ] && return 0

  # Check if audit enabled
  local audit_enabled
  audit_enabled=$(jq -r '.audit // false' "$GOVERNANCE_POLICY_FILE" 2>/dev/null) || audit_enabled="false"
  [ "$audit_enabled" != "true" ] && return 0

  # Append timestamped event
  mkdir -p "$(dirname "$GOVERNANCE_AUDIT_FILE")"
  local ts
  ts=$(date -Iseconds 2>/dev/null || date +%Y-%m-%dT%H:%M:%S%z)
  echo "{\"ts\":\"$ts\",$event}" >> "$GOVERNANCE_AUDIT_FILE"
}

# ── Policy summary ────────────────────────────────────────────────────────────
if _policy_validate; then
  mode=$(_policy_load)
  allowed_denied=$(jq -r '"allowed=\(.allowed_providers | length) denied=\(.denied_providers | length)"' "$GOVERNANCE_POLICY_FILE" 2>/dev/null) || allowed_denied=""
  info "Policy mode: $mode ($allowed_denied)"
else
  warn "Policy validation failed — governance disabled"
fi

_step_done step_governance
