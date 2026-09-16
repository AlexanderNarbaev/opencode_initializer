# Security Scanning Module (00k-security-scan.sh)

> **Version:** v3.5.0  
> **File:** `src/lib/00k-security-scan.sh`  
> **Dependencies:** `helpers.sh`, `00-core.sh`

## Overview

Security scanning module for detecting secrets, verifying integrity, auditing permissions, and scanning dependencies for vulnerabilities.

## Functions

### Secret Scanning

#### `_scan_secrets(directory)`
Scans directory for secrets and credentials.

```bash
_scan_secrets "/path/to/project"
# Output: List of detected secrets with file:line:masked_content
```

**Detected Patterns:**
- OpenAI API keys (`sk-...`)
- Anthropic API keys (`sk-ant-...`)
- Google API keys (`AIza...`)
- AWS Access Keys (`AKIA...`)
- GitHub Tokens (`ghp_...`, `gho_...`)
- Private keys (`-----BEGIN PRIVATE KEY-----`)
- Passwords in config files

### Integrity Verification

#### `_verify_integrity(file)`
Verifies file integrity using SHA256 checksums.

```bash
_verify_integrity "/path/to/file"
# Returns: 0 if integrity valid, 1 if compromised
```

### Permission Audit

#### `_audit_permissions(directory)`
Audits file permissions for security issues.

```bash
_audit_permissions "/path/to/project"
# Output: List of permission issues
```

**Detected Issues:**
- World-writable files
- SUID/SGID files
- Root-owned files in user directories

### Dependency Scanning

#### `_scan_dependencies(directory)`
Scans for vulnerable dependencies.

```bash
_scan_dependencies "/path/to/project"
# Output: List of vulnerable dependencies
```

**Supported Files:**
- `package.json` (npm)
- `requirements.txt` (pip)
- `go.mod` (Go)
- `Cargo.toml` (Rust)

### Security Report

#### `_generate_security_report()`
Generates comprehensive security report.

```bash
_generate_security_report
# Creates: ~/.cache/opencode-setup/security-report.json
```

### Pre-commit Hook

#### `_install_pre_commit_hook()`
Installs pre-commit hook for secret detection.

```bash
_install_pre_commit_hook
# Creates: .git/hooks/pre-commit
```

## Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `_SECRET_PATTERNS` | Array of secret patterns | See source |
| `_EXCLUDE_PATTERNS` | Array of exclude patterns | See source |

## Usage

```bash
# Source the module
source src/lib/helpers.sh
source src/lib/00-core.sh
source src/lib/00k-security-scan.sh

# Show help
_security_scan_help

# Scan for secrets
_scan_secrets "/path/to/project"

# Audit permissions
_audit_permissions "/path/to/project"

# Scan dependencies
_scan_dependencies "/path/to/project"

# Generate security report
_generate_security_report

# Install pre-commit hook
_install_pre_commit_hook
```

## Secret Patterns

### API Keys
- OpenAI: `sk-[a-zA-Z0-9]{48}`
- Anthropic: `sk-ant-[a-zA-Z0-9]{48}`
- Google: `AIza[a-zA-Z0-9_-]{35}`
- AWS: `AKIA[0-9A-Z]{16}`

### Tokens
- GitHub PAT: `ghp_[a-zA-Z0-9]{36}`
- GitHub OAuth: `gho_[a-zA-Z0-9]{36}`
- Hugging Face: `hf_[a-zA-Z0-9]{34}`

### Private Keys
- RSA: `-----BEGIN RSA PRIVATE KEY-----`
- EC: `-----BEGIN EC PRIVATE KEY-----`
- DSA: `-----BEGIN DSA PRIVATE KEY-----`
- OpenSSH: `-----BEGIN OPENSSH PRIVATE KEY-----`

## Pre-commit Hook

The pre-commit hook:
1. Scans staged files for secrets
2. Blocks commit if secrets detected
3. Provides bypass option (`--no-verify`)

```bash
# Install hook
_install_pre_commit_hook

# Commit with hook
git commit -m "feat: add new feature"
# ❌ Commit blocked: secrets detected
#    Use 'git commit --no-verify' to bypass (not recommended)
```

## See Also

- [core.md](core.md) - Core infrastructure
- [apm.md](apm.md) - APM preparation
- [helpers.md](helpers.md) - Helper functions
