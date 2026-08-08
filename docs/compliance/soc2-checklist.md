# SOC2 Compliance Checklist — opencode_initializer v3.0

> **Based on:** T1.5 corporate/air-gap audit (2026-08-08), v3.0 vision
> **Target:** SOC2 Type II readiness for AI-assisted development harness

---

## CC5.2 — Control Activities

| # | Control | v3.0 Implementation | Status |
|---|---------|---------------------|:------:|
| CC5.2.1 | Provider allowlist per project | `model-policy.json` with `allowed_providers` per deployment profile | → M5.1.3 |
| CC5.2.2 | Model allowlist per project | `model-policy.json` with `allowed_models` per project override | → M5.1.3 |
| CC5.2.3 | Cost limits per session | `OPENCODE_MAX_COST_PER_SESSION` in model-policy | → M5.3.3 |
| CC5.2.4 | Data residency enforcement | `OPENCODE_DATA_REGIONS` gate in provider selection | → M5.1.3 |
| CC5.2.5 | Per-agent model assignment | 17-project.sh agent→model mapping (existing, v2.0.3) | ✅ |

---

## CC7.2 — Monitoring of Controls

| # | Control | v3.0 Implementation | Status |
|---|---------|---------------------|:------:|
| CC7.2.1 | Audit log all tool calls | 44-audit.sh: WAL event `tool_call` (bash, read, write, edit, grep) | → M5.2.3 |
| CC7.2.2 | Audit log all model calls | 44-audit.sh: WAL event `model_call` (provider, model, tokens in/out, latency) | → M5.2.3 |
| CC7.2.3 | Audit log provider switches | 44-audit.sh: WAL event `provider_switch` (from→to, reason) | → M5.2.3 |
| CC7.2.4 | PII redaction logging | 44-audit.sh: WAL event `pii_redacted` (count, patterns matched) | → M5.2.4 |
| CC7.2.5 | Session boundary logging | WAL event `session_boundary` (start/end, task_id, mode) | → M5.2.3 |
| CC7.2.6 | Error/exception logging | WAL event `error` (tool, exit_code, message_hash) | → M5.3.1 |
| CC7.2.7 | Scheduled security scanning | Systemd timer: daily Trivy + Qodana scan with log | → M5.4.1 |

---

## CC8.2 — System Operations

| # | Control | v3.0 Implementation | Status |
|---|---------|---------------------|:------:|
| CC8.2.1 | Immutable WAL (hash chain) | SHA-256 per-entry hash linking (`prev_hash` → `this_hash`) | → M5.2.3 |
| CC8.2.2 | WAL rotation policy | >10MB → gzip compress + archive to Qdrant | → M5.2.3 |
| CC8.2.3 | WAL access control | `~/.cache/opencode/wal.jsonl` chmod 600, directory 700 | → M5.2.3 |
| CC8.2.4 | Sanitized logs (no secrets) | PII guard strips API keys, tokens, credentials before write | → M5.2.4 |
| CC8.2.5 | SBOM generation | CycloneDX SBOM via `trivy sbom` on every release | → M5.4.1 |
| CC8.2.6 | Dependency vulnerability scan | Trivy filesystem scan + OSV integration in CI | → M5.4.1 |

---

## Change Management (CC8.1)

| # | Control | v3.0 Implementation | Status |
|---|---------|---------------------|:------:|
| CM.1 | Traceable spec→task→commit | SDD workflow: FR-### in spec → task_id in plan → commit message | ✅ (v3.0 SDD) |
| CM.2 | Pre-commit security hook | `.pre-commit-config.yaml`: Trivy CRITICAL check | → M5.4.1 |
| CM.3 | Supply-chain verification | `curl|bash` → download + SHA256 verify for all 6 modules | → M5.1.2 |
| CM.4 | Config backup/restore | `dev backup create|list|restore` (existing, v2.0.3) | ✅ |

---

## Risk Assessment (CC3.2)

| Risk | Likelihood | Impact | Mitigation |
|------|:---:|:---:|------------|
| API key leak via logs | Medium | Critical | PII guard (45-pii-guard.sh) + WAL sanitization |
| Unauthorized provider usage | Medium | High | Model governance (43-governance.sh) + allowlist |
| Supply chain compromise | Low | Critical | SHA256 verification (M5.1.2) |
| Air-gap circuit leak | Medium | High | ISOLATED_CIRCUIT guard on version-check + autoupdate (M5.1.1) |
| WAL tampering | Low | High | SHA-256 hash chain (M5.2.3) |
| Default password exploit | High | Medium | Auto-generated secrets (M5.1.2) |

---

## Compliance Status Summary

| SOC2 Trust Criteria | v2.0.3 | v3.0 Target |
|---------------------|:------:|:----------:|
| CC5.2 Control Activities | 2/5 (no governance) | **4/5** |
| CC7.2 Monitoring | 1/7 (basic WAL) | **6/7** |
| CC8.2 System Operations | 1/6 (secrets.env) | **5/6** |
| CC8.1 Change Management | 2/4 (backup, trace) | **4/4** |
| CC3.2 Risk Assessment | 0/6 (no formal) | **5/6** |
| **Overall** | **1.4/5** | **4.0/5** |
