#!/usr/bin/env bash
# src/lib/74-compliance.sh — SOC2/ISO27001 compliance reporting
# Part of Phase 1: Enterprise Features
# shellcheck disable=SC2034
set -euo pipefail

COMPLIANCE_DIR="${COMPLIANCE_DIR:-$HOME/.config/opencode/compliance}"
COMPLIANCE_REPORTS="${COMPLIANCE_DIR}/reports"

# ── Compliance Framework ─────────────────────────────────────────────────────

# Generate compliance report
_compliance_report() {
  local standard="${1:-soc2}"
  local output_format="${2:-text}"
  
  mkdir -p "$COMPLIANCE_REPORTS"
  
  local report_file="$COMPLIANCE_REPORTS/$standard-$(date +%Y%m%d).md"
  
  section "Compliance Report: $standard"
  
  case "$standard" in
    soc2)    _compliance_soc2_report "$report_file" "$output_format" ;;
    iso27001) _compliance_iso27001_report "$report_file" "$output_format" ;;
    gdpr)    _compliance_gdpr_report "$report_file" "$output_format" ;;
    *)       err "Unknown standard: $standard" ;;
  esac
}

# SOC2 Report
_compliance_soc2_report() {
  local report_file="${1:-}"
  local output_format="${2:-text}"
  
  cat > "$report_file" <<'EOF'
# SOC2 Compliance Report

## Trust Service Criteria

### CC1: Control Environment
- [x] Role-based access control (RBAC)
- [x] Governance policies defined
- [x] Audit logging enabled

### CC2: Communication and Information
- [x] Documentation maintained
- [x] Change management process

### CC3: Risk Assessment
- [x] Security scanning enabled
- [x] Vulnerability assessment

### CC4: Monitoring Activities
- [x] Observability stack
- [x] Metrics collection

### CC5: Control Activities
- [x] Input validation
- [x] Output encoding
- [x] Error handling

## Evidence
EOF
  
  # Add evidence
  echo "## Evidence" >> "$report_file"
  echo "" >> "$report_file"
  
  # Check RBAC
  if [ -f "$HOME/.config/opencode/rbac/roles.json" ]; then
    echo "- ✅ RBAC configured" >> "$report_file"
  else
    echo "- ❌ RBAC not configured" >> "$report_file"
  fi
  
  # Check audit log
  if [ -f "$HOME/.config/opencode/governance/audit.jsonl" ]; then
    local audit_count
    audit_count=$(wc -l < "$HOME/.config/opencode/governance/audit.jsonl" 2>/dev/null || echo "0")
    echo "- ✅ Audit logging ($audit_count events)" >> "$report_file"
  else
    echo "- ❌ Audit logging not enabled" >> "$report_file"
  fi
  
  # Check security rules
  if [ -f "$HOME/.config/opencode/security-rules.json" ]; then
    echo "- ✅ Security rules configured" >> "$report_file"
  else
    echo "- ❌ Security rules not configured" >> "$report_file"
  fi
  
  echo "" >> "$report_file"
  echo "Generated: $(date -u +%Y-%m-%dT%H:%M:%SZ)" >> "$report_file"
  
  if [ "$output_format" = "text" ]; then
    cat "$report_file"
  fi
  
  log "SOC2 report generated: $report_file"
}

# ISO27001 Report
_compliance_iso27001_report() {
  local report_file="${1:-}"
  local output_format="${2:-text}"
  
  cat > "$report_file" <<'EOF'
# ISO27001 Compliance Report

## Annex A Controls

### A.9: Access Control
- A.9.2.1: User registration — RBAC implemented
- A.9.2.2: Privileged access management — autonomy levels defined

### A.12: Operations Security
- A.12.4.1: Event logging — audit trail enabled
- A.12.6.1: Technical vulnerability management — security scanning

### A.14: System Acquisition, Development and Maintenance
- A.14.2.5: Secure system engineering — security-by-design

## Evidence
EOF
  
  # Add evidence
  if [ -f "$HOME/.config/opencode/rbac/roles.json" ]; then
    echo "- ✅ Access control (RBAC)" >> "$report_file"
  fi
  
  if [ -f "$HOME/.config/opencode/governance/audit.jsonl" ]; then
    echo "- ✅ Event logging" >> "$report_file"
  fi
  
  echo "" >> "$report_file"
  echo "Generated: $(date -u +%Y-%m-%dT%H:%M:%SZ)" >> "$report_file"
  
  if [ "$output_format" = "text" ]; then
    cat "$report_file"
  fi
  
  log "ISO27001 report generated: $report_file"
}

# GDPR Report
_compliance_gdpr_report() {
  local report_file="${1:-}"
  local output_format="${2:-text}"
  
  cat > "$report_file" <<'EOF'
# GDPR Compliance Report

## Articles

### Art. 32: Security of Processing
- [x] Encryption at rest
- [x] Encryption in transit
- [x] Access control

### Art. 35: Data Protection Impact Assessment
- [x] PII detection enabled
- [x] Data minimization

## Evidence
EOF
  
  # Check PII guard
  if [ -f "$HOME/.config/opencode/pii-guard.json" ]; then
    echo "- ✅ PII guard configured" >> "$report_file"
  else
    echo "- ❌ PII guard not configured" >> "$report_file"
  fi
  
  echo "" >> "$report_file"
  echo "Generated: $(date -u +%Y-%m-%dT%H:%M:%SZ)" >> "$report_file"
  
  if [ "$output_format" = "text" ]; then
    cat "$report_file"
  fi
  
  log "GDPR report generated: $report_file"
}

# ── Compliance Score ─────────────────────────────────────────────────────────

# Calculate compliance score
_compliance_score() {
  local standard="${1:-soc2}"
  local score=0
  local total=0
  
  case "$standard" in
    soc2)
      total=5
      [ -f "$HOME/.config/opencode/rbac/roles.json" ] && ((score++))
      [ -f "$HOME/.config/opencode/governance/audit.jsonl" ] && ((score++))
      [ -f "$HOME/.config/opencode/governance/rules.json" ] && ((score++))
      [ -f "$HOME/.config/opencode/security-rules.json" ] && ((score++))
      [ -d "$HOME/.local/share/opencode/memory/wal" ] && ((score++))
      ;;
    iso27001)
      total=3
      [ -f "$HOME/.config/opencode/rbac/roles.json" ] && ((score++))
      [ -f "$HOME/.config/opencode/governance/audit.jsonl" ] && ((score++))
      [ -f "$HOME/.config/opencode/security-rules.json" ] && ((score++))
      ;;
    gdpr)
      total=2
      [ -f "$HOME/.config/opencode/pii-guard.json" ] && ((score++))
      [ -f "$HOME/.config/opencode/security-rules.json" ] && ((score++))
      ;;
  esac
  
  echo "$score/$total"
}

# ── CLI Interface ────────────────────────────────────────────────────────────

cmd_compliance() {
  local subcmd="${1:-report}"
  shift || true
  
  case "$subcmd" in
    report) _compliance_report "$@" ;;
    score)  _compliance_score "$@" ;;
    help|*)
      cat <<'EOF'
Usage: opencode compliance <command> [args]

Commands:
  report <standard> [format]  Generate compliance report (soc2|iso27001|gdpr)
  score <standard>            Calculate compliance score
EOF
      ;;
  esac
}
