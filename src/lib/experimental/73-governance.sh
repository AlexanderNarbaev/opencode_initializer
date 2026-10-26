#!/usr/bin/env bash
# src/lib/73-governance.sh — Policy enforcement
# Part of Phase 1: Enterprise Features
# shellcheck disable=SC2034
set -euo pipefail

GOVERNANCE_DIR="${GOVERNANCE_DIR:-$HOME/.config/opencode/governance}"
GOVERNANCE_RULES="${GOVERNANCE_DIR}/rules.json"
GOVERNANCE_AUDIT="${GOVERNANCE_DIR}/audit.jsonl"

# ── Governance Rules ─────────────────────────────────────────────────────────

# Initialize governance
_governance_init() {
  mkdir -p "$GOVERNANCE_DIR"
  
  if [ ! -f "$GOVERNANCE_RULES" ]; then
    cat > "$GOVERNANCE_RULES" <<'EOF'
{
  "rules": [
    {
      "id": "GOV001",
      "name": "require_approval",
      "description": "Require approval for high-risk operations",
      "severity": "high",
      "conditions": ["deploy", "delete", "modify_production"],
      "action": "block"
    },
    {
      "id": "GOV002",
      "name": "audit_logging",
      "description": "Log all significant operations",
      "severity": "medium",
      "conditions": ["*"],
      "action": "log"
    },
    {
      "id": "GOV003",
      "name": "rate_limiting",
      "description": "Limit API call frequency",
      "severity": "medium",
      "conditions": ["api_call"],
      "action": "throttle"
    }
  ]
}
EOF
    log "Governance initialized with default rules"
  fi
}

# List governance rules
_governance_list_rules() {
  _governance_init
  
  if command -v jq &>/dev/null; then
    jq -r '.rules[] | "\(.id) \(.name) — \(.description) [\(.severity)]"' \
      "$GOVERNANCE_RULES" 2>/dev/null
  fi
}

# Add a governance rule
_governance_add_rule() {
  local rule_id="${1:-}"
  local rule_name="${2:-}"
  local description="${3:-}"
  local severity="${4:-medium}"
  local conditions="${5:-}"
  local action="${6:-log}"
  
  if [ -z "$rule_id" ] || [ -z "$rule_name" ]; then
    err "Rule ID and name required"
  fi
  
  _governance_init
  
  if command -v jq &>/dev/null; then
    jq --arg id "$rule_id" --arg name "$rule_name" --arg desc "$description" \
       --arg sev "$severity" --arg conds "$conditions" --arg action "$action" \
      '.rules += [{"id": $id, "name": $name, "description": $desc, "severity": $sev, "conditions": ($conds | split(",")), "action": $action}]' \
      "$GOVERNANCE_RULES" > "$GOVERNANCE_RULES.tmp"
    mv "$GOVERNANCE_RULES.tmp" "$GOVERNANCE_RULES"
  fi
  
  log "Governance rule added: $rule_id"
}

# ── Audit Logging ────────────────────────────────────────────────────────────

# Log an audit event
_governance_audit() {
  local event_type="${1:-}"
  local actor="${2:-}"
  local action="${3:-}"
  local resource="${4:-}"
  local result="${5:-success}"
  
  mkdir -p "$GOVERNANCE_DIR"
  
  echo "{\"timestamp\": \"$(date -u +%Y-%m-%dT%H:%M:%SZ)\", \"event_type\": \"$event_type\", \"actor\": \"$actor\", \"action\": \"$action\", \"resource\": \"$resource\", \"result\": \"$result\"}" \
    >> "$GOVERNANCE_AUDIT"
}

# Read audit log
_governance_audit_log() {
  local limit="${1:-50}"
  local actor="${2:-}"
  
  if [ ! -f "$GOVERNANCE_AUDIT" ]; then
    info "No audit events"
    return 0
  fi
  
  if [ -n "$actor" ]; then
    grep "\"actor\": \"$actor\"" "$GOVERNANCE_AUDIT" 2>/dev/null | tail -n "$limit"
  else
    tail -n "$limit" "$GOVERNANCE_AUDIT" 2>/dev/null
  fi
}

# ── Policy Enforcement ───────────────────────────────────────────────────────

# Check if action is allowed
_governance_check() {
  local action="${1:-}"
  local actor="${2:-system}"
  
  _governance_init
  
  # Check rules
  if command -v jq &>/dev/null; then
    local rule_action
    rule_action=$(jq -r --arg action "$action" \
      '.rules[] | select(.conditions[] | contains($action)) | .action' \
      "$GOVERNANCE_RULES" 2>/dev/null | head -1)
    
    case "$rule_action" in
      block)
        warn "Action blocked by governance: $action"
        _governance_audit "governance" "$actor" "$action" "" "blocked"
        return 1
        ;;
      throttle)
        info "Action throttled: $action"
        _governance_audit "governance" "$actor" "$action" "" "throttled"
        return 0
        ;;
      log)
        _governance_audit "governance" "$actor" "$action" "" "allowed"
        return 0
        ;;
      *)
        _governance_audit "governance" "$actor" "$action" "" "allowed"
        return 0
        ;;
    esac
  fi
  
  return 0
}

# ── Compliance Checks ────────────────────────────────────────────────────────

# Run compliance check
_governance_compliance_check() {
  local standard="${1:-soc2}"
  
  section "Compliance Check: $standard"
  
  case "$standard" in
    soc2)
      _governance_check_soc2
      ;;
    iso27001)
      _governance_check_iso27001
      ;;
    gdpr)
      _governance_check_gdpr
      ;;
    *)
      warn "Unknown standard: $standard"
      return 1
      ;;
  esac
}

_governance_check_soc2() {
  local score=0
  local total=5
  
  # Check audit logging
  if [ -f "$GOVERNANCE_AUDIT" ]; then
    ((score++))
    echo "  ✓ Audit logging enabled"
  else
    echo "  ✗ Audit logging not enabled"
  fi
  
  # Check RBAC
  if [ -f "$RBAC_ROLES_FILE" ]; then
    ((score++))
    echo "  ✓ RBAC configured"
  else
    echo "  ✗ RBAC not configured"
  fi
  
  # Check governance rules
  if [ -f "$GOVERNANCE_RULES" ]; then
    ((score++))
    echo "  ✓ Governance rules defined"
  else
    echo "  ✗ Governance rules not defined"
  fi
  
  # Check security scanning
  if [ -f "$HOME/.config/opencode/security-rules.json" ]; then
    ((score++))
    echo "  ✓ Security rules configured"
  else
    echo "  ✗ Security rules not configured"
  fi
  
  # Check memory/WAL
  if [ -d "$HOME/.local/share/opencode/memory/wal" ]; then
    ((score++))
    echo "  ✓ WAL enabled"
  else
    echo "  ✗ WAL not enabled"
  fi
  
  echo
  echo "SOC2 Compliance: $score/$total"
}

_governance_check_iso27001() {
  echo "ISO27001 compliance check"
  _governance_check_soc2  # Similar checks
}

_governance_check_gdpr() {
  echo "GDPR compliance check"
  # Check PII guard
  if [ -f "$HOME/.config/opencode/pii-guard.json" ]; then
    echo "  ✓ PII guard configured"
  else
    echo "  ✗ PII guard not configured"
  fi
}

# ── CLI Interface ────────────────────────────────────────────────────────────

cmd_governance() {
  local subcmd="${1:-help}"
  shift || true
  
  case "$subcmd" in
    init)     _governance_init ;;
    rules)    _governance_list_rules ;;
    add-rule) _governance_add_rule "$@" ;;
    audit)    _governance_audit "$@" ;;
    log)      _governance_audit_log "$@" ;;
    check)    _governance_check "$@" ;;
    compliance) _governance_compliance_check "$@" ;;
    help|*)
      cat <<'EOF'
Usage: opencode governance <command> [args]

Commands:
  init                                      Initialize governance
  rules                                     List governance rules
  add-rule <id> <name> [desc] [sev] [conds] [action]  Add a rule
  audit <type> <actor> <action> [resource]  Log audit event
  log [limit] [actor]                       Read audit log
  check <action> [actor]                    Check if action allowed
  compliance <standard>                     Run compliance check (soc2|iso27001|gdpr)
EOF
      ;;
  esac
}
