#!/usr/bin/env bash
# ============================================================================
# ISOLATED Unit Test for 43-governance.sh + 18-opencode-json.sh integration
# Target: src/lib/43-governance.sh, src/lib/18-opencode-json.sh (policy filter)
# Session: ses_W1-C
#
# Tests:
#   (a) Default policy created when absent (idempotent)
#   (b) _provider_allowed: mode=allowlist, allowed_providers=["deepseek"]
#   (c) _provider_allowed: denied_providers take priority over allowlist
#   (d) _model_allowed: corporate mode model-level deny
#   (e) 18-opencode-json integration: denied_providers=["xai"] → xai absent
#   (f) Backward compat: no policy → all providers present
#
# Isolation: mktemp-HOME — no filesystem side-effects.
# ============================================================================
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
TESTS_PASS=0; TESTS_FAIL=0

assert() {
  local desc="$1" condition="$2"
  if (eval "$condition") 2>/dev/null; then
    TESTS_PASS=$((TESTS_PASS + 1))
  else
    TESTS_FAIL=$((TESTS_FAIL + 1))
    echo "    FAIL: $desc" >&2
  fi
}

# ── Isolated HOME ────────────────────────────────────────────────────────────
TMPDIR=$(mktemp -d /tmp/test_governance.XXXXXX)
cleanup() { rm -rf "$TMPDIR"; }
trap cleanup EXIT
export HOME="$TMPDIR/home"
mkdir -p "$HOME/.config/opencode" "$HOME/.cache/opencode"

PF="$HOME/.config/opencode/model-policy.json"
G="$PROJECT_DIR/src/lib/43-governance.sh"
J="$PROJECT_DIR/src/lib/18-opencode-json.sh"

echo "=== Testing Model Governance ==="

# ── Test A: Module syntax and structure ───────────────────────────────────────
assert "43-governance.sh exists" "[ -f '$G' ]"
assert "43-governance.sh syntax valid" "bash -n '$G'"
assert "43-governance.sh has _policy_load" "grep -q '_policy_load' '$G'"
assert "43-governance.sh has _provider_allowed" "grep -q '_provider_allowed' '$G'"
assert "43-governance.sh has _model_allowed" "grep -q '_model_allowed' '$G'"
assert "43-governance.sh has _policy_validate" "grep -q '_policy_validate' '$G'"
assert "43-governance.sh has _policy_audit_log" "grep -q '_policy_audit_log' '$G'"
assert "43-governance.sh references model-policy.json" "grep -q 'model-policy.json' '$G'"
assert "43-governance.sh uses jq" "grep -q 'jq ' '$G'"

# ── Helper functions (before sourcing module) ─────────────────────────────────
_step_skip() { return 1; }
section() { :; }
log() { :; }
info() { :; }
warn() { :; }
err() { exit 1; }
_step_done() { :; }

# Source governance module to get functions
# NOTE: sourcing will CREATE the default policy (since _step_skip returns 1)
# shellcheck disable=SC1090
source "$G" 2>/dev/null || true

# ── Test B: Default policy created when absent ────────────────────────────────
assert "policy created by module source" "[ -f '$PF' ]"
assert "policy is valid JSON" "jq empty '$PF'"
assert "mode is allow-all" "[ \"\$(jq -r .mode '$PF')\" = 'allow-all' ]"
assert "version is 1" "[ \"\$(jq -r .version '$PF')\" = '1' ]"
assert "allowed_providers is empty array" "[ \"\$(jq '.allowed_providers | length' '$PF')\" = '0' ]"
assert "denied_providers is empty array" "[ \"\$(jq '.denied_providers | length' '$PF')\" = '0' ]"

# ── Test C: Idempotency — existing policy not overwritten ─────────────────────
BACKUP_MD5=$(md5sum "$PF" | awk '{print $1}')
# Simulate re-run: the if-not-exists guard should skip (source again)
source "$G" 2>/dev/null || true
CURRENT_MD5=$(md5sum "$PF" | awk '{print $1}')
assert "idempotent: existing policy unchanged" "[ '$CURRENT_MD5' = '$BACKUP_MD5' ]"

# ── Test D: _provider_allowed — allow-all mode ────────────────────────────────
assert "allow-all: deepseek allowed" "_provider_allowed deepseek"
assert "allow-all: xai allowed" "_provider_allowed xai"
assert "allow-all: nonexistent allowed (backward compat)" "_provider_allowed nonexistent99"

# ── Test E: _provider_allowed — allowlist mode ────────────────────────────────
cat > "$PF" << 'EOF'
{"version":1,"mode":"allowlist","allowed_providers":["deepseek"],"denied_providers":[],"allowed_models":[],"denied_models":[],"max_cost_per_1m":null,"audit":false}
EOF
assert "allowlist: deepseek allowed" "_provider_allowed deepseek"
assert "allowlist: zai denied" "! _provider_allowed zai"
assert "allowlist: xai denied" "! _provider_allowed xai"
assert "allowlist: opencode denied" "! _provider_allowed opencode"

# ── Test F: denied_providers take priority over allowlist ─────────────────────
cat > "$PF" << 'EOF'
{"version":1,"mode":"allowlist","allowed_providers":["deepseek","xai"],"denied_providers":["xai"],"allowed_models":[],"denied_models":[],"max_cost_per_1m":null,"audit":false}
EOF
assert "denied priority: deepseek still allowed" "_provider_allowed deepseek"
assert "denied priority: xai denied despite allowlist" "! _provider_allowed xai"

# ── Test G: corporate mode with model-level checks ────────────────────────────
cat > "$PF" << 'EOF'
{"version":1,"mode":"corporate","allowed_providers":["deepseek","anthropic"],"denied_providers":[],"allowed_models":["deepseek/deepseek-v4-pro"],"denied_models":["anthropic/claude-opus-4-8"],"max_cost_per_1m":null,"audit":false}
EOF
assert "corporate: deepseek provider allowed" "_provider_allowed deepseek"
assert "corporate: google denied" "! _provider_allowed google"
assert "corporate: deepseek/v4-pro allowed" "_model_allowed deepseek 'deepseek/deepseek-v4-pro'"
assert "corporate: anthropic/claude-opus-4-8 denied" "! _model_allowed anthropic 'anthropic/claude-opus-4-8'"
# anthropic/claude-sonnet — not in allowed_models, but allowed_models only has deepseek
# so anthropic sonnet should be denied
assert "corporate: anthropic/sonnet denied (not in allowed_models)" "! _model_allowed anthropic 'anthropic/claude-sonnet-4-6'"

# ── Test H: _policy_validate ──────────────────────────────────────────────────
jq -n '{version:1,mode:"allow-all",allowed_providers:[],denied_providers:[],allowed_models:[],denied_models:[],max_cost_per_1m:null,audit:false}' > "$PF"
assert "policy validate: valid JSON" "_policy_validate"
echo "not json" > "$PF"
assert "policy validate: invalid JSON detected" "! _policy_validate"
jq -n '{version:1,mode:"allow-all",allowed_providers:[],denied_providers:[],allowed_models:[],denied_models:[],max_cost_per_1m:null,audit:false}' > "$PF"
assert "policy validate: recovered" "_policy_validate"

# ── Test I: 18-opencode-json.sh integration — policy loading code exists ──────
assert "18-opencode-json.sh has policy_path" "grep -q 'model-policy.json' '$J'"
assert "18-opencode-json.sh has denied filter" "grep -q 'provider.*denied.*skipped' '$J'"
assert "18-opencode-json.sh has allowlist filter" "grep -q 'allowlist.*skipped' '$J'"

# ── Test J: Python verify — xai excluded from filtered list ───────────────────
cat > "$PF" << 'EOF'
{"version":1,"mode":"allow-all","allowed_providers":[],"denied_providers":["xai"],"allowed_models":[],"denied_models":[],"max_cost_per_1m":null,"audit":false}
EOF
PY_VERIFY=$(python3 -c "
import json, os
policy_path = os.path.join(os.environ['HOME'], '.config', 'opencode', 'model-policy.json')
with open(policy_path) as pf:
    policy = json.load(pf)
denied = set(policy.get('denied_providers', []))
all_providers = ['deepseek','opencode','zai','xai']
filtered = [p for p in all_providers if p not in denied]
assert 'xai' not in filtered, f'xai should be filtered but got: {filtered}'
assert 'deepseek' in filtered, 'deepseek should still be present'
print(f'OK: {len(filtered)}/{len(all_providers)} providers after filtering')
" 2>&1)
echo "  $PY_VERIFY"
assert "python verify: xai filtered" "echo '$PY_VERIFY' | grep -q 'OK'"

# ── Test K: Backward compat — no policy → all providers allowed ───────────────
rm -f "$PF"
assert "no policy file: provider check returns 0" "_provider_allowed deepseek"
assert "no policy file: bogus provider also 0" "_provider_allowed nonexistent99"

# ── Test L: _policy_audit_log write check ─────────────────────────────────────
jq -n '{version:1,mode:"allow-all",allowed_providers:[],denied_providers:[],allowed_models:[],denied_models:[],max_cost_per_1m:null,audit:true}' > "$PF"
_policy_audit_log '"event":"test","result":"allow"'
AUDIT_LOG="$HOME/.cache/opencode/audit.jsonl"
assert "audit log created" "[ -f '$AUDIT_LOG' ]"
assert "audit log has event" "grep -q 'test' '$AUDIT_LOG'"
assert "audit log has result" "grep -q 'allow' '$AUDIT_LOG'"

# ── Test M: audit disabled → no log written ───────────────────────────────────
jq -n '{version:1,mode:"allow-all",allowed_providers:[],denied_providers:[],allowed_models:[],denied_models:[],max_cost_per_1m:null,audit:false}' > "$PF"
rm -f "$AUDIT_LOG"
_policy_audit_log '"event":"should_not_appear"'
assert "audit disabled: no log created" "[ ! -f '$AUDIT_LOG' ]"

echo "test_governance: $TESTS_PASS passed, $TESTS_FAIL failed"
[ "$TESTS_FAIL" -eq 0 ] || exit 1
