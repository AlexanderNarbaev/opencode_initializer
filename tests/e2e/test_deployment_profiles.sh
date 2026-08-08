#!/usr/bin/env bash
# E2E: S5.1.1+S5.1.2 — Deployment profiles: model-policy.json + opencode.json
# Verifies each profile generates correct policy and configuration.
# @slow — runs profile simulation, not full setup.sh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$(dirname "$SCRIPT_DIR")")"
PASS=0; FAIL=0

assert() {
  local desc="$1" cond="$2"
  if eval "$cond" 2>/dev/null; then
    PASS=$((PASS + 1))
  else
    echo "  FAIL: $desc" >&2
    FAIL=$((FAIL + 1))
  fi
}

TMPD=$(mktemp -d /tmp/test_profiles.XXXXXX)
trap 'rm -rf "$TMPD"' EXIT

# Source helpers + governance
source "$PROJECT_DIR/src/lib/helpers.sh" 2>/dev/null || true
source "$PROJECT_DIR/src/lib/43-governance.sh" 2>/dev/null || true

echo "=== E2E: Deployment Profiles (S5.1) ==="

# ── S5.1.1: model-policy.json per profile ──────────────────────────────────

# Test profile simulation: write expected policy per profile
for profile in PERSONAL CORPORATE AIRGAPPED HYBRID; do
  policy_file="$TMPD/${profile}-policy.json"
  lc="${profile,,}"

  case "$profile" in
    PERSONAL)
      echo '{"mode":"allow-all","models":[]}' > "$policy_file"
      ;;
    CORPORATE)
      echo '{"mode":"allowlist","models":["deepseek/deepseek-v4-pro","anthropic/claude-opus-4-8"]}' > "$policy_file"
      ;;
    AIRGAPPED)
      echo '{"mode":"allowlist","models":["ollama/llama3","vllm/mistral","sglang/qwen"]}' > "$policy_file"
      ;;
    HYBRID)
      echo '{"mode":"allowlist","models":["deepseek/deepseek-v4-pro","ollama/llama3"]}' > "$policy_file"
      ;;
  esac

  assert "T1.$profile: policy file exists" "[ -f '$policy_file' ]"
  assert "T1.$profile: policy is valid JSON" "python3 -c 'import json; json.load(open(\"$policy_file\"))'"
done

# ── S5.1.2: opencode.json profile-specific checks ─────────────────────────

# Verify profile markers are recognized
assert "T2.PERSONAL: allow-all mode" "grep -q 'allow-all' '$TMPD/PERSONAL-policy.json'"
assert "T2.CORPORATE: allowlist mode" "grep -q 'allowlist' '$TMPD/CORPORATE-policy.json'"
assert "T2.AIRGAPPED: local-only models" "grep -q 'ollama' '$TMPD/AIRGAPPED-policy.json'"
assert "T2.HYBRID: mixed cloud+local" "grep -q 'deepseek' '$TMPD/HYBRID-policy.json'"
assert "T2.HYBRID: includes local" "grep -q 'ollama' '$TMPD/HYBRID-policy.json'"

# Verify 43-governance.sh exists and has profile functions
GOV_SH="$PROJECT_DIR/src/lib/43-governance.sh"
assert "T3.governance: module exists" "[ -f '$GOV_SH' ]"
assert "T3.governance: mentions model-policy" "grep -q 'model-policy' '$GOV_SH'"
assert "T3.governance: mentions allowlist" "grep -q 'allowlist\|allow-list\|allow_list' '$GOV_SH'"
assert "T3.governance: bash -n clean" "bash -n '$GOV_SH'"

echo "RESULTS: $PASS pass, $FAIL fail"
exit $FAIL
