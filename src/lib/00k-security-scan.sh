#!/usr/bin/env bash
# src/lib/00k-security-scan.sh — Security Scanner Module (v4.2.0)
# Scans for secrets, verifies download integrity, audits permissions.
set -euo pipefail

# ── Security configuration ───────────────────────────────────────────────────
_SECURITY_REPORT="${DL_CACHE}/security-report.json"
_SECURITY_SCAN_DIR="${1:-.}"

# ── Secret patterns to detect ───────────────────────────────────────────────
_SECRET_PATTERNS=(
  # API Keys
  'sk-[a-zA-Z0-9]{48}'                    # OpenAI
  'sk-ant-[a-zA-Z0-9]{48}'                # Anthropic
  'AIza[a-zA-Z0-9_-]{35}'                 # Google
  'xai-[a-zA-Z0-9]{48}'                   # xAI
  'gsk_[a-zA-Z0-9]{48}'                   # Groq
  'hf_[a-zA-Z0-9]{34}'                    # Hugging Face
  
  # Generic secrets
  'AKIA[0-9A-Z]{16}'                      # AWS Access Key
  '[0-9a-f]{40}'                           # GitHub Token (40 hex)
  'ghp_[a-zA-Z0-9]{36}'                   # GitHub Personal Access Token
  'gho_[a-zA-Z0-9]{36}'                   # GitHub OAuth Token
  'github_pat_[a-zA-Z0-9]{22}_[a-zA-Z0-9]{59}'  # GitHub Fine-grained PAT
  
  # Private keys
  '-----BEGIN (RSA |EC |DSA |OPENSSH )?PRIVATE KEY-----'
  
  # Passwords in config
  'password\s*[:=]\s*["\x27][^"\x27]{8,}'
  'passwd\s*[:=]\s*["\x27][^"\x27]{8,}'
  'secret\s*[:=]\s*["\x27][^"\x27]{8,}'
)

# ── Files to exclude from scanning ──────────────────────────────────────────
_EXCLUDE_PATTERNS=(
  '*.git'
  'node_modules'
  '__pycache__'
  '*.pyc'
  '.venv'
  'venv'
  '*.min.js'
  '*.min.css'
  'package-lock.json'
  'yarn.lock'
  'pnpm-lock.yaml'
)

# ── Scan for secrets ────────────────────────────────────────────────────────
# Usage: _scan_secrets [directory]
# Returns list of potential secrets found.
_scan_secrets() {
  local dir="${1:-.}"
  local findings=()
  local total_files=0
  local scanned_files=0

  section "Secret Scanner" >&2

  # Build exclude arguments
  local exclude_args=""
  for pattern in "${_EXCLUDE_PATTERNS[@]}"; do
    exclude_args="$exclude_args --exclude-dir=${pattern%%/*} --exclude=${pattern}"
  done

  # Scan for each pattern
  for pattern in "${_SECRET_PATTERNS[@]}"; do
    local matches
    matches=$(grep -rn $exclude_args -E "$pattern" "$dir" 2>/dev/null || true)
    
    if [ -n "$matches" ]; then
      while IFS= read -r match; do
        local file line content
        file=$(echo "$match" | cut -d: -f1)
        line=$(echo "$match" | cut -d: -f2)
        content=$(echo "$match" | cut -d: -f3-)
        
        # Mask the secret value
        local masked
        masked=$(echo "$content" | sed 's/[a-zA-Z0-9_-]\{20,\}/***REDACTED***/g')
        
        findings+=("$file:$line:$masked")
        warn "  ⚠ Potential secret in $file:$line" >&2
      done <<< "$matches"
    fi
  done

  # Report
  if [ ${#findings[@]} -eq 0 ]; then
    log "No secrets found" >&2
  else
    warn "Found ${#findings[@]} potential secrets" >&2
    for finding in "${findings[@]}"; do
      info "  $finding" >&2
    done
  fi

  echo "${#findings[@]}"
}

# ── Verify file integrity with SHA256 ───────────────────────────────────────
# Usage: _verify_integrity <file> <expected_sha256>
# Returns 0 if hash matches, 1 otherwise.
_verify_integrity() {
  local file="$1" expected="$2"
  
  if [ ! -f "$file" ]; then
    warn "File not found: $file"
    return 1
  fi

  local actual
  actual=$(sha256sum "$file" | awk '{print $1}')
  
  if [ "$actual" = "$expected" ]; then
    log "✓ Integrity verified: $file"
    return 0
  else
    warn "✗ Integrity check failed: $file"
    warn "  Expected: $expected"
    warn "  Actual:   $actual"
    return 1
  fi
}

# ── Audit file permissions ──────────────────────────────────────────────────
# Usage: _audit_permissions [directory]
# Reports files with overly permissive permissions.
_audit_permissions() {
  local dir="${1:-.}"
  local findings=0

  section "Permission Audit" >&2

  # Find world-writable files
  local world_writable
  world_writable=$(find "$dir" -type f -perm -o+w 2>/dev/null | grep -v '\.git/' || true)
  
  if [ -n "$world_writable" ]; then
    while IFS= read -r file; do
      warn "  ⚠ World-writable: $file" >&2
      findings=$((findings + 1))
    done <<< "$world_writable"
  fi

  # Find SUID/SGID files
  local suid_files
  suid_files=$(find "$dir" -type f \( -perm -u+s -o -perm -g+s \) 2>/dev/null | grep -v '\.git/' || true)
  
  if [ -n "$suid_files" ]; then
    while IFS= read -r file; do
      warn "  ⚠ SUID/SGID: $file" >&2
      findings=$((findings + 1))
    done <<< "$suid_files"
  fi

  # Find files owned by root in user directories
  local root_owned
  root_owned=$(find "$dir" -type f -user root 2>/dev/null | grep -v '\.git/' | head -20 || true)
  
  if [ -n "$root_owned" ]; then
    while IFS= read -r file; do
      warn "  ⚠ Root-owned: $file" >&2
      findings=$((findings + 1))
    done <<< "$root_owned"
  fi

  if [ "$findings" -eq 0 ]; then
    log "No permission issues found" >&2
  else
    warn "Found $findings permission issues" >&2
  fi

  echo "$findings"
}

# ── Scan for vulnerable dependencies ────────────────────────────────────────
# Usage: _scan_dependencies [directory]
# Checks package.json, requirements.txt, go.mod for known vulnerabilities.
_scan_dependencies() {
  local dir="${1:-.}"
  local vulnerabilities=0

  section "Dependency Scanner"

  # Check npm packages
  if [ -f "$dir/package.json" ]; then
    info "Scanning npm dependencies..."
    if command -v npm &>/dev/null; then
      local audit_result
      audit_result=$(cd "$dir" && npm audit --json 2>/dev/null || true)
      
      if echo "$audit_result" | grep -q '"vulnerabilities"'; then
        local vuln_count
        vuln_count=$(echo "$audit_result" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('metadata',{}).get('vulnerabilities',{}).get('total',0))" 2>/dev/null || echo "0")
        
        if [ "$vuln_count" -gt 0 ]; then
          warn "  ⚠ npm: $vuln_count vulnerabilities found"
          vulnerabilities=$((vulnerabilities + vuln_count))
        else
          log "  ✓ npm: no vulnerabilities"
        fi
      fi
    fi
  fi

  # Check Python packages
  if [ -f "$dir/requirements.txt" ] || [ -f "$dir/pyproject.toml" ]; then
    info "Scanning Python dependencies..."
    if command -v pip-audit &>/dev/null; then
      local audit_result
      audit_result=$(cd "$dir" && pip-audit --format json 2>/dev/null || true)
      
      if [ -n "$audit_result" ]; then
        local vuln_count
        vuln_count=$(echo "$audit_result" | python3 -c "import json,sys; d=json.load(sys.stdin); print(len(d.get('dependencies',[])))" 2>/dev/null || echo "0")
        
        if [ "$vuln_count" -gt 0 ]; then
          warn "  ⚠ Python: $vuln_count vulnerabilities found"
          vulnerabilities=$((vulnerabilities + vuln_count))
        else
          log "  ✓ Python: no vulnerabilities"
        fi
      fi
    else
      info "  ⏭ pip-audit not installed (pip install pip-audit)"
    fi
  fi

  # Check Go modules
  if [ -f "$dir/go.mod" ]; then
    info "Scanning Go dependencies..."
    if command -v govulncheck &>/dev/null; then
      local audit_result
      audit_result=$(cd "$dir" && govulncheck ./... 2>&1 || true)
      
      if echo "$audit_result" | grep -q "Vulnerability"; then
        warn "  ⚠ Go: vulnerabilities found"
        vulnerabilities=$((vulnerabilities + 1))
      else
        log "  ✓ Go: no vulnerabilities"
      fi
    else
      info "  ⏭ govulncheck not installed (go install golang.org/x/vuln/cmd/govulncheck@latest)"
    fi
  fi

  if [ "$vulnerabilities" -eq 0 ]; then
    log "No vulnerabilities found"
  else
    warn "Found $vulnerabilities vulnerabilities"
  fi

  echo "$vulnerabilities"
}

# ── Generate security report ────────────────────────────────────────────────
# Usage: _generate_security_report [directory]
# Creates JSON report with all security findings.
_generate_security_report() {
  local dir="${1:-.}"
  local now
  now=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

  section "Security Report Generation" >&2

  # Run scans and capture only the numeric results
  local secrets perm_issues vulns
  secrets=$(_scan_secrets "$dir" 2>/dev/null | tail -1)
  perm_issues=$(_audit_permissions "$dir" 2>/dev/null | tail -1)
  vulns=$(_scan_dependencies "$dir" 2>/dev/null | tail -1)

  # Default to 0 if empty
  secrets="${secrets:-0}"
  perm_issues="${perm_issues:-0}"
  vulns="${vulns:-0}"

  # Determine overall status
  local overall_status="PASS"
  if [ "$secrets" -gt 0 ] || [ "$perm_issues" -gt 0 ] || [ "$vulns" -gt 0 ]; then
    overall_status="FAIL"
  fi

  cat > "$_SECURITY_REPORT" <<EOF
{
  "timestamp": "$now",
  "directory": "$dir",
  "summary": {
    "secrets_found": $secrets,
    "permission_issues": $perm_issues,
    "vulnerabilities": $vulns,
    "overall_status": "$overall_status"
  },
  "details": {
    "secret_patterns_checked": ${#_SECRET_PATTERNS[@]},
    "exclude_patterns": [$(printf '"%s",' "${_EXCLUDE_PATTERNS[@]}" | sed 's/,$//')],
    "scan_directory": "$dir"
  }
}
EOF

  log "Security report: $_SECURITY_REPORT" >&2
  
  # Print summary
  echo "" >&2
  echo "  ┌─────────────────────────────────────────┐" >&2
  echo "  │         Security Scan Summary            │" >&2
  echo "  ├─────────────────────────────────────────┤" >&2
  printf "  │  Secrets found:       %-18s│\n" "$secrets" >&2
  printf "  │  Permission issues:   %-18s│\n" "$perm_issues" >&2
  printf "  │  Vulnerabilities:     %-18s│\n" "$vulns" >&2
  echo "  ├─────────────────────────────────────────┤" >&2
  printf "  │  Overall status:      %-18s│\n" "$([ "$overall_status" = "PASS" ] && echo "✅ PASS" || echo "❌ FAIL")" >&2
  echo "  └─────────────────────────────────────────┘" >&2
}

# ── Pre-commit hook ─────────────────────────────────────────────────────────
# Usage: _install_pre_commit_hook [git_dir]
# Installs a pre-commit hook that scans for secrets.
_install_pre_commit_hook() {
  local git_dir="${1:-.git}"
  local hook_file="$git_dir/hooks/pre-commit"

  section "Installing Pre-Commit Hook"

  mkdir -p "$git_dir/hooks"

  cat > "$hook_file" <<'HOOK'
#!/usr/bin/env bash
# Pre-commit hook: scan for secrets
# Installed by opencode_initializer

set -euo pipefail

echo "Running security scan..."

# Get list of staged files
staged_files=$(git diff --cached --name-only --diff-filter=ACM)

if [ -z "$staged_files" ]; then
  exit 0
fi

# Secret patterns
patterns=(
  'sk-[a-zA-Z0-9]{48}'
  'sk-ant-[a-zA-Z0-9]{48}'
  'AIza[a-zA-Z0-9_-]{35}'
  'AKIA[0-9A-Z]{16}'
  'ghp_[a-zA-Z0-9]{36}'
  '-----BEGIN.*PRIVATE KEY-----'
)

found_secrets=0

for file in $staged_files; do
  if [ -f "$file" ]; then
    for pattern in "${patterns[@]}"; do
      if grep -qE "$pattern" "$file" 2>/dev/null; then
        echo "❌ Potential secret found in: $file"
        echo "   Pattern: $pattern"
        found_secrets=1
      fi
    done
  fi
done

if [ "$found_secrets" -eq 1 ]; then
  echo ""
  echo "⚠️  Commit blocked: secrets detected"
  echo "   Use 'git commit --no-verify' to bypass (not recommended)"
  exit 1
fi

echo "✅ No secrets detected"
exit 0
HOOK

  chmod +x "$hook_file"
  log "Pre-commit hook installed: $hook_file"
}

# ── Export functions ─────────────────────────────────────────────────────────
export -f _scan_secrets _verify_integrity _audit_permissions _scan_dependencies \
  _generate_security_report _install_pre_commit_hook 2>/dev/null || true
