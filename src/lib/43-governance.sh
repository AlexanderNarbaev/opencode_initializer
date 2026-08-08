#!/usr/bin/env bash
# lib/43-governance.sh — Model Governance: per-project allowlist/blocklist (STEP 43)
# Implements: model-policy.json with 3 modes (allow-all/allowlist/corporate)
# Used by: 18-opencode-json.sh (provider generation), pre-session-check.sh (validation)
# See: audit finding G20, docs/plans/v3.0-vision.md §5
set -euo pipefail

_step_skip step_governance && return 0

section "Model Governance — Policy Configuration"

# ── Policy file locations (per-project overrides global) ────────────────────
GLOBAL_POLICY="${HOME}/.config/opencode/model-policy.json"
PROJECT_POLICY="${PROJECT_DIR:-}/.opencode/model-policy.json"

# ── Default policy (allow-all mode) ─────────────────────────────────────────
_default_policy() {
  cat << 'POLICY'
{
  "version": "1.0.0",
  "deployment_profile": "personal",
  "mode": "allow-all",
  "allowlist": { "providers": [], "models": [] },
  "blocklist": { "providers": [], "models": [] },
  "rate_limits": { "max_requests_per_hour": 0 },
  "_comment": "mode: allow-all | allowlist | corporate. allow-all = no restrictions. allowlist = only listed. corporate = allowlist + audit + PII guard."
}
POLICY
}

# ── Corporate profile policy (strict) ──────────────────────────────────────
_corporate_policy() {
  cat << 'POLICY'
{
  "version": "1.0.0",
  "deployment_profile": "corporate",
  "mode": "corporate",
  "allowlist": {
    "providers": ["deepseek", "zai", "opencode", "ollama", "vllm", "sglang"],
    "models": []
  },
  "blocklist": {
    "providers": [],
    "models": []
  },
  "rate_limits": { "max_requests_per_hour": 500 },
  "audit": { "enabled": true, "log_tool_calls": true, "log_model_calls": true },
  "pii_guard": { "enabled": true, "redact_in_logs": true },
  "_comment": "Corporate mode: restricted providers, enforced audit trail, PII sanitizer active."
}
POLICY
}

# ── Air-gapped profile policy ───────────────────────────────────────────────
_airgap_policy() {
  cat << 'POLICY'
{
  "version": "1.0.0",
  "deployment_profile": "airgapped",
  "mode": "allowlist",
  "allowlist": {
    "providers": ["ollama", "vllm", "sglang"],
    "models": []
  },
  "blocklist": {
    "providers": ["deepseek", "zai", "openai", "anthropic", "google", "mistral", "groq", "together", "cohere", "fireworks", "cerebras", "perplexity", "xai", "mimo", "minimax", "openrouter", "alibaba", "deepinfra"],
    "models": []
  },
  "rate_limits": { "max_requests_per_hour": 0 },
  "audit": { "enabled": false },
  "pii_guard": { "enabled": false },
  "_comment": "Air-gap mode: local providers only. All cloud providers blocked."
}
POLICY
}

# ── Hybrid profile policy ───────────────────────────────────────────────────
_hybrid_policy() {
  cat << 'POLICY'
{
  "version": "1.0.0",
  "deployment_profile": "hybrid",
  "mode": "allowlist",
  "allowlist": {
    "providers": ["deepseek", "zai", "opencode", "ollama", "vllm", "sglang"],
    "models": []
  },
  "blocklist": {
    "providers": [],
    "models": []
  },
  "rate_limits": { "max_requests_per_hour": 200 },
  "audit": { "enabled": true, "log_tool_calls": false },
  "pii_guard": { "enabled": false },
  "_comment": "Hybrid mode: cloud + local, light audit, no PII guard. For mixed-use environments."
}
POLICY
}

# ── Generate policy file if missing ─────────────────────────────────────────
_generate_policy() {
  local target="${1:-$GLOBAL_POLICY}"
  local profile="${DEPLOYMENT_PROFILE:-personal}"
  local dir
  dir="$(dirname "$target")"
  mkdir -p "$dir"

  case "$profile" in
    corporate) _corporate_policy > "$target" ;;
    airgapped) _airgap_policy > "$target" ;;
    hybrid)    _hybrid_policy > "$target" ;;
    *)         _default_policy > "$target" ;;
  esac
  chmod 644 "$target" 2>/dev/null || true
  log "Model policy generated: $target (profile: $profile)"
}

# ── Install: create default policy if none exists ───────────────────────────
if [ ! -f "$GLOBAL_POLICY" ]; then
  _generate_policy "$GLOBAL_POLICY"
fi

# ── Per-project policy (overrides global) ───────────────────────────────────
if [ -n "${PROJECT_DIR:-}" ] && [ -d "$PROJECT_DIR" ] && [ ! -f "$PROJECT_POLICY" ]; then
  _generate_policy "$PROJECT_POLICY"
fi

# ── Export policy path for other modules ────────────────────────────────────
MODEL_POLICY="${PROJECT_POLICY}"
[ ! -f "$MODEL_POLICY" ] && MODEL_POLICY="$GLOBAL_POLICY"
export MODEL_POLICY

# ── Helper: check if a provider is allowed under current policy ─────────────
# Usage: _governance_check_provider <provider_name>
# Returns: 0 if allowed, 1 if blocked
# Used by: pre-session-check.sh
_governance_check_provider() {
  local provider="$1"
  local policy_file="${MODEL_POLICY:-$GLOBAL_POLICY}"

  [ ! -f "$policy_file" ] && return 0  # No policy = allow all

  local mode
  mode=$(jq -r '.mode // "allow-all"' "$policy_file" 2>/dev/null || echo "allow-all")

  case "$mode" in
    "allow-all") return 0 ;;
    "allowlist")
      if jq -e --arg p "$provider" '.allowlist.providers | index($p)' "$policy_file" >/dev/null 2>&1; then
        return 0
      fi
      warn "Governance: $provider NOT in allowlist (policy: $policy_file)"
      return 1
      ;;
    "corporate")
      if jq -e --arg p "$provider" '.allowlist.providers | index($p)' "$policy_file" >/dev/null 2>&1; then
        return 0
      fi
      if jq -e --arg p "$provider" '.blocklist.providers | index($p)' "$policy_file" >/dev/null 2>&1; then
        warn "Governance: $provider BLOCKED by corporate policy"
        return 1
      fi
      warn "Governance: $provider not in corporate allowlist"
      return 1
      ;;
  esac
  return 0
}

_step_done step_governance
log "Model governance configured — policy: $MODEL_POLICY"
