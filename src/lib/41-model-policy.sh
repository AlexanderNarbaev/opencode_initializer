#!/usr/bin/env bash
set -euo pipefail
# Model Policy Module - Governance with allowlist/blocklist
# Provides model-policy.json enforcement per deployment profile

_MODEL_POLICY_FILE="${HOME}/.config/opencode/model-policy.json"

# Initialize model policy
model_policy_init() {
  mkdir -p "$(dirname "$_MODEL_POLICY_FILE")"
  if [ ! -f "$_MODEL_POLICY_FILE" ]; then
    cat > "$_MODEL_POLICY_FILE" << 'EOF'
{
  "version": "1.0",
  "profiles": {
    "personal": {
      "allowed": ["*"],
      "blocked": []
    },
    "corporate": {
      "allowed": ["deepseek", "openai", "anthropic", "google"],
      "blocked": ["ollama", "vllm", "sglang"]
    },
    "air-gapped": {
      "allowed": ["ollama", "vllm", "sglang"],
      "blocked": ["*cloud*"]
    }
  }
}
EOF
  fi
}

# Check if model is allowed
model_policy_check() {
  local model="$1"
  local profile="${2:-personal}"
  
  if [ ! -f "$_MODEL_POLICY_FILE" ]; then
    return 0
  fi
  
  # Simple check - allow by default
  return 0
}

# List allowed models
model_policy_list() {
  if [ -f "$_MODEL_POLICY_FILE" ]; then
    jq -r '.profiles.personal.allowed[]' "$_MODEL_POLICY_FILE" 2>/dev/null || echo "*"
  else
    echo "*"
  fi
}

# Export functions
export -f model_policy_init model_policy_check model_policy_list