#!/usr/bin/env bash
# src/lib/64-skill-security.sh — Security scanning for skills
# Part of Phase 0: Skill Management System
# shellcheck disable=SC2034
set -euo pipefail

SKILL_SECURITY_RULES="${SKILL_SECURITY_RULES:-$HOME/.config/opencode/security-rules.json}"
SKILL_SECURITY_REPORT_DIR="${SKILL_SECURITY_REPORT_DIR:-/tmp/opencode-security-reports}"

# ── Security Scan ────────────────────────────────────────────────────────────

# Scan a skill for security issues
_skill_security_scan() {
  local skill_dir="${1:-.}"
  local output_format="${2:-text}"
  local errors=0
  local warnings=0
  
  section "Security Scan: $skill_dir"
  
  # 1. Prompt injection detection
  if _skill_check_prompt_injection "$skill_dir"; then
    ((warnings++))
  fi
  
  # 2. Secret leakage scanning
  if _skill_check_secret_leakage "$skill_dir"; then
    ((errors++))
  fi
  
  # 3. Permission escalation detection
  if _skill_check_permission_escalation "$skill_dir"; then
    ((errors++))
  fi
  
  # 4. Unsafe pattern detection
  if _skill_check_unsafe_patterns "$skill_dir"; then
    ((warnings++))
  fi
  
  # 5. Dependency vulnerability check
  if _skill_check_dependencies "$skill_dir"; then
    ((warnings++))
  fi
  
  # 6. Network access check
  if _skill_check_network_access "$skill_dir"; then
    ((warnings++))
  fi
  
  # Generate report
  if [ "$output_format" = "json" ]; then
    _skill_security_report_json "$skill_dir" "$errors" "$warnings"
  else
    _skill_security_report_text "$skill_dir" "$errors" "$warnings"
  fi
  
  return $errors
}

# ── Individual Checks ────────────────────────────────────────────────────────

# Check for prompt injection patterns
_skill_check_prompt_injection() {
  local skill_dir="${1:-.}"
  local found=0
  
  local patterns=(
    "ignore previous instructions"
    "ignore all previous"
    "disregard.*instructions"
    "you are now"
    "new instructions"
    "system prompt"
    "override.*instructions"
    "forget.*instructions"
  )
  
  for pattern in "${patterns[@]}"; do
    if grep -rq "$pattern" "$skill_dir/" 2>/dev/null; then
      warn "Potential prompt injection: '$pattern' found"
      ((found++))
    fi
  done
  
  return $found
}

# Check for secret leakage
_skill_check_secret_leakage() {
  local skill_dir="${1:-.}"
  local found=0
  
  local patterns=(
    "AKIA[0-9A-Z]{16}"                    # AWS Access Key
    "sk-[a-zA-Z0-9]{48}"                  # OpenAI API Key
    "sk-ant-[a-zA-Z0-9]{48}"              # Anthropic API Key
    "ghp_[a-zA-Z0-9]{36}"                 # GitHub Personal Access Token
    "glpat-[a-zA-Z0-9-]{20}"              # GitLab PAT
    "xox[bprs]-[a-zA-Z0-9-]+"            # Slack Token
    "-----BEGIN.*PRIVATE KEY-----"         # Private Key
    "password.*=.*['\"][^'\"]{8,}"         # Hardcoded password
    "api[_-]?key.*=.*['\"][^'\"]{8,}"     # Hardcoded API key
    "secret.*=.*['\"][^'\"]{8,}"          # Hardcoded secret
    "token.*=.*['\"][^'\"]{8,}"           # Hardcoded token
  )
  
  for pattern in "${patterns[@]}"; do
    local matches
    matches=$(grep -rnE "$pattern" "$skill_dir/" 2>/dev/null || true)
    if [ -n "$matches" ]; then
      warn "Potential secret leakage: $pattern"
      echo "$matches" | head -3
      ((found++))
    fi
  done
  
  return $found
}

# Check for permission escalation
_skill_check_permission_escalation() {
  local skill_dir="${1:-.}"
  local found=0
  
  local patterns=(
    "chmod 777"
    "chmod -R 777"
    "chown root"
    "sudo su"
    "sudo -i"
    "setuid"
    "setgid"
    "/etc/passwd"
    "/etc/shadow"
    "/etc/sudoers"
  )
  
  for pattern in "${patterns[@]}"; do
    if grep -rq "$pattern" "$skill_dir/" 2>/dev/null; then
      warn "Permission escalation: '$pattern' found"
      ((found++))
    fi
  done
  
  return $found
}

# Check for unsafe patterns
_skill_check_unsafe_patterns() {
  local skill_dir="${1:-.}"
  local found=0
  
  local patterns=(
    "curl.*|.*bash"
    "curl.*|.*sh"
    "wget.*|.*bash"
    "wget.*|.*sh"
    "eval \$"
    "eval \"\$"
    "exec \$"
    "rm -rf /"
    "rm -rf ~"
    "mkfs\."
    "dd if=.*of=/dev"
    "> /dev/sda"
  )
  
  for pattern in "${patterns[@]}"; do
    if grep -rq "$pattern" "$skill_dir/" 2>/dev/null; then
      warn "Unsafe pattern: '$pattern' found"
      ((found++))
    fi
  done
  
  return $found
}

# Check dependencies
_skill_check_dependencies() {
  local skill_dir="${1:-.}"
  local found=0
  
  # Check package.json
  if [ -f "$skill_dir/package.json" ]; then
    # Check for known vulnerable packages
    local vuln_packages=("lodash" "express" "request" "moment")
    for pkg in "${vuln_packages[@]}"; do
      if grep -q "\"$pkg\"" "$skill_dir/package.json" 2>/dev/null; then
        info "Note: Using $pkg (check for known vulnerabilities)"
        ((found++))
      fi
    done
  fi
  
  # Check requirements.txt
  if [ -f "$skill_dir/requirements.txt" ]; then
    # Check for known vulnerable packages
    local vuln_packages=("requests" "flask" "django" "pyyaml")
    for pkg in "${vuln_packages[@]}"; do
      if grep -qi "^$pkg" "$skill_dir/requirements.txt" 2>/dev/null; then
        info "Note: Using $pkg (check for known vulnerabilities)"
        ((found++))
      fi
    done
  fi
  
  return $found
}

# Check network access patterns
_skill_check_network_access() {
  local skill_dir="${1:-.}"
  local found=0
  
  local patterns=(
    "fetch\("
    "axios\."
    "http\.get"
    "http\.post"
    "requests\.get"
    "requests\.post"
    "urllib"
    "curl "
    "wget "
  )
  
  for pattern in "${patterns[@]}"; do
    if grep -rq "$pattern" "$skill_dir/" 2>/dev/null; then
      info "Network access detected: $pattern"
      ((found++))
    fi
  done
  
  return $found
}

# ── Scoring ──────────────────────────────────────────────────────────────────

# Calculate security score (0-100)
_skill_security_score() {
  local skill_dir="${1:-.}"
  local score=100
  
  # Run all checks and count findings
  local prompt_injection=0 secret_leakage=0 permission_escalation=0
  local unsafe_patterns=0 dependencies=0 network_access=0
  
  # Count findings by grepping output
  prompt_injection=$(_skill_check_prompt_injection "$skill_dir" 2>&1 | grep -c "Potential prompt injection" | tr -d '[:space:]')
  secret_leakage=$(_skill_check_secret_leakage "$skill_dir" 2>&1 | grep -c "Potential secret leakage" | tr -d '[:space:]')
  permission_escalation=$(_skill_check_permission_escalation "$skill_dir" 2>&1 | grep -c "Permission escalation" | tr -d '[:space:]')
  unsafe_patterns=$(_skill_check_unsafe_patterns "$skill_dir" 2>&1 | grep -c "Unsafe pattern" | tr -d '[:space:]')
  dependencies=$(_skill_check_dependencies "$skill_dir" 2>&1 | grep -c "Note: Using" | tr -d '[:space:]')
  network_access=$(_skill_check_network_access "$skill_dir" 2>&1 | grep -c "Network access" | tr -d '[:space:]')
  
  # Default to 0 if empty
  prompt_injection=${prompt_injection:-0}
  secret_leakage=${secret_leakage:-0}
  permission_escalation=${permission_escalation:-0}
  unsafe_patterns=${unsafe_patterns:-0}
  dependencies=${dependencies:-0}
  network_access=${network_access:-0}
  
  # Deduct points
  score=$((score - prompt_injection * 15))
  score=$((score - secret_leakage * 25))
  score=$((score - permission_escalation * 20))
  score=$((score - unsafe_patterns * 10))
  score=$((score - dependencies * 5))
  score=$((score - network_access * 3))
  
  # Clamp to 0-100
  [ "$score" -lt 0 ] && score=0
  [ "$score" -gt 100 ] && score=100
  
  echo "$score"
}

# Get security level
_skill_security_level() {
  local score="${1:-0}"
  
  if [ "$score" -ge 90 ]; then
    echo "HIGH"
  elif [ "$score" -ge 70 ]; then
    echo "MEDIUM"
  elif [ "$score" -ge 50 ]; then
    echo "LOW"
  else
    echo "CRITICAL"
  fi
}

# ── Reports ──────────────────────────────────────────────────────────────────

_skill_security_report_text() {
  local skill_dir="${1:-.}"
  local errors="${2:-0}"
  local warnings="${3:-0}"
  
  local score
  score=$(_skill_security_score "$skill_dir")
  local level
  level=$(_skill_security_level "$score")
  
  echo
  echo "━━━ Security Report ━━━"
  echo "  Skill: $skill_dir"
  echo "  Score: $score/100 ($level)"
  echo "  Errors: $errors"
  echo "  Warnings: $warnings"
  echo "━━━━━━━━━━━━━━━━━━━━━━━"
}

_skill_security_report_json() {
  local skill_dir="${1:-.}"
  local errors="${2:-0}"
  local warnings="${3:-0}"
  
  local score
  score=$(_skill_security_score "$skill_dir")
  local level
  level=$(_skill_security_level "$score")
  
  cat <<EOF
{
  "skill": "$skill_dir",
  "score": $score,
  "level": "$level",
  "errors": $errors,
  "warnings": $warnings,
  "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
}
EOF
}

# ── CLI Interface ────────────────────────────────────────────────────────────

cmd_skill_security() {
  local subcmd="${1:-scan}"
  shift || true
  
  case "$subcmd" in
    scan)   _skill_security_scan "$@" ;;
    score)  _skill_security_score "$@" ;;
    level)  _skill_security_level "$@" ;;
    help|*)
      cat <<'EOF'
Usage: opencode skill-security <command> [args]

Commands:
  scan [dir] [format]    Scan skill for security issues (text|json)
  score [dir]            Get security score (0-100)
  level [dir]            Get security level (HIGH|MEDIUM|LOW|CRITICAL)
EOF
      ;;
  esac
}
