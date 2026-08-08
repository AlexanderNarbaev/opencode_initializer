# ISO27001 Compliance Mapping — opencode_initializer v3.0

> **Based on:** T1.5 audit, SOC2 checklist, v3.0 architecture
> **Target:** ISO27001:2022 Annex A controls applicable to AI dev harness

---

## A.9 — Access Control

| Control | Requirement | v3.0 Implementation | Module |
|---------|-------------|---------------------|--------|
| **A.9.2.1** | User registration & de-registration | `secrets.env` per-user, chmod 600; per-project `opencode.json` | 19-finalize.sh |
| **A.9.2.2** | User access provisioning | Provider API keys per-user, not shared | 18-opencode-json.sh |
| **A.9.2.3** | Management of privileged access rights | `_sudo()` with here-string (not pipe), no hardcoded passwords | helpers.sh |
| **A.9.2.4** | Secret authentication information | Auto-generated passwords → `secrets.env`, never in code | 30-infra.sh |
| **A.9.4.1** | Information access restriction | `model-policy.json` per-project allowlist/blocklist | 43-governance.sh |
| **A.9.4.2** | Secure log-on procedures | API keys via env vars, never in CLI history | setup.sh |

---

## A.12 — Operations Security

| Control | Requirement | v3.0 Implementation | Module |
|---------|-------------|---------------------|--------|
| **A.12.4.1** | Event logging | 7 WAL event types (model_call, tool_call, provider_switch, pii_redacted, checkpoint, error, session_boundary) | 44-audit.sh |
| **A.12.4.2** | Protection of log information | WAL chmod 600, SHA-256 hash chain, append-only | 44-audit.sh |
| **A.12.4.3** | Administrator & operator logs | Separate WAL per session (`ses_N`), JSONL format | 37-wal.sh |
| **A.12.4.4** | Clock synchronisation | ISO8601 timestamps in all WAL events | 37-wal.sh |
| **A.12.5.1** | Installation of software on operational systems | `curl|sh` → download + SHA256 verify for all 6 affected modules | M5.1.2 |
| **A.12.6.1** | Technical vulnerability management | Daily Trivy + Qodana scan via systemd timer | 15-security.sh |
| **A.12.6.2** | Restrictions on software installation | `model-policy.json` restricts providers/models | 43-governance.sh |
| **A.12.7.1** | Information systems audit controls | WAL hash chain + periodic archive → Qdrant | 44-audit.sh |

---

## A.14 — System Acquisition, Development & Maintenance

| Control | Requirement | v3.0 Implementation | Module |
|---------|-------------|---------------------|--------|
| **A.14.1.1** | Information security requirements analysis | SDD workflow: constitution → specify security NFR → plan → implement | 41-constitution.sh |
| **A.14.1.2** | Securing application services on public networks | SearXNG sanitizer proxy: no internal hosts/IP/PII | 24-websearch.sh |
| **A.14.1.3** | Protecting application services transactions | Sanitizer strips API keys from prompt/response logs | 45-pii-guard.sh |
| **A.14.2.1** | Secure development policy | AGENTS.md: source ladder, no secrets in code, verification gates | 17-project.sh |
| **A.14.2.5** | System security testing | SBOM (CycloneDX), pre-commit Trivy hook, CI security workflow | M5.4.1 |
| **A.14.2.8** | System security testing | ShellCheck CI + bash -n gate (existing v2.0.3) | .github/workflows |

---

## A.16 — Information Security Incident Management

| Control | Requirement | v3.0 Implementation | Module |
|---------|-------------|---------------------|--------|
| **A.16.1.1** | Responsibilities & procedures | `health.sh` diagnostics (119 checks), WAL error events | modes/health.sh |
| **A.16.1.4** | Assessment & decision on events | `WAL_MODULE_COUNT` race detection, dry-run guards | 00-core.sh |
| **A.16.1.5** | Response to incidents | `_run_step()` try/catch pattern (not just `set -e`) | M5.3.1 |

---

## A.17 — Information Security Continuity

| Control | Requirement | v3.0 Implementation | Module |
|---------|-------------|---------------------|--------|
| **A.17.1.2** | Implementing continuity | `dev backup create|list|restore` (v2.0.3) | dev.sh |
| **A.17.2.1** | Availability of processing facilities | Docker healthchecks (PostgreSQL, Qdrant, Redis, Grafana) | 30-infra.sh |

---

## A.18 — Compliance

| Control | Requirement | v3.0 Implementation | Module |
|---------|-------------|---------------------|--------|
| **A.18.1.1** | Identification of applicable legislation | GDPR Art.32/Art.35 mapping in PII guard | 45-pii-guard.sh |
| **A.18.1.3** | Protection of records | WAL rotation + Qdrant archive, chmod 600 | 44-audit.sh |
| **A.18.1.5** | Regulation of cryptographic controls | SHA-256 for supply chain verification, WAL hash chain | M5.1.2 |

---

## GDPR Readiness

| Article | Requirement | v3.0 Status |
|---------|-------------|:----------:|
| Art. 5.1(c) | Data minimisation | 9 PII detectors strip unnecessary personal data before LLM requests |
| Art. 5.1(f) | Integrity & confidentiality | SHA-256 hash chain, chmod 600 secrets, sanitized logs |
| Art. 30 | Records of processing | WAL `pii_redacted` events track all sanitization activity |
| Art. 32 | Security of processing | Trivy, SBOM, pre-commit hooks, model governance |
| Art. 33 | Breach notification | WAL `error` events, health diagnostics (119 checks) |
| Art. 35 | Data protection impact assessment (DPIA) | Audit trail + PII guard + air-gap profile = DPIA evidence package |

---

## Maturity by Annex

| Annex | Controls applicable | v2.0.3 | v3.0 Target |
|-------|:---:|:---:|:---:|
| A.9 Access Control | 6 | 3/6 | **5/6** |
| A.12 Operations | 8 | 2/8 | **7/8** |
| A.14 Development | 6 | 2/6 | **5/6** |
| A.16 Incident | 3 | 1/3 | **3/3** |
| A.17 Continuity | 2 | 1/2 | **2/2** |
| A.18 Compliance | 3 | 1/3 | **3/3** |
| GDPR (Art. 5-35) | 6 | 2/6 | **5/6** |
| **Overall** | **34 controls** | **12/34** | **30/34** |
