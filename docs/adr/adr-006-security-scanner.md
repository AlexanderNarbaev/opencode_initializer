# ADR-006: Security Scanner Architecture

## Status
Accepted

## Context
Development environments often contain hardcoded secrets, weak permissions, and vulnerable dependencies. A security scanner should catch these issues before they reach production.

## Decision
Implement a comprehensive security scanner with 4 components:
1. **Secret Detection** — Regex patterns for 15+ secret types (API keys, tokens, passwords)
2. **Integrity Verification** — SHA-256 checksums for critical files
3. **Permission Audit** — Check file permissions against security best practices
4. **Dependency Scanning** — Check for known vulnerabilities in installed packages

Output: JSON report with severity levels (critical, high, medium, low).

## Consequences
- **Positive:** Catches secrets before commit
- **Positive:** Verifies file integrity
- **Positive:** Automated security audit
- **Negative:** False positives on test fixtures
- **Negative:** Pattern-based detection has limits

## Related
- Module: `src/lib/00k-security-scan.sh`
- Tests: `tests/unit/test_security_benchmark.sh`
- CLI: `--security-scan`, `--install-hooks`
