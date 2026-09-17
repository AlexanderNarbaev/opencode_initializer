# ADR-010: Security Model

## Status
Accepted

## Context
AI agents execute code in real systems, creating security risks. OWASP AST10 identifies critical threats for agentic systems.

## Decision
Implement multi-layer security:
1. **Isolation** — Docker containers with seccomp, readonly filesystem
2. **Secret management** — HashiCorp Vault integration, short-lived credentials
3. **Policy enforcement** — OPA/Rego for access control
4. **Audit logging** — Hash-chained WAL, comprehensive logging
5. **PII protection** — Automated PII detection and redaction

## Consequences
- **Positive:** Secure agent execution in production
- **Positive:** Compliance with security standards
- **Positive:** Full auditability of agent actions
- **Negative:** Increased complexity
- **Negative:** Performance overhead for security checks

## Related
- Governance: `src/lib/43-governance.sh`
- Audit: `src/lib/44-audit.sh`
- PII guard: `src/lib/45-pii-guard.sh`
- Security docs: `docs/architecture/security-model-2026.md`
