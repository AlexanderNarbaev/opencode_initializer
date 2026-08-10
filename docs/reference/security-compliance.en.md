# Security & Compliance

v3.0.0 adds PII sanitization, audit trail with SHA-256 hash-chain, supply-chain hardening, and compliance documentation.

## PII Sanitizer (45-pii-guard.sh)

9 detectors run before every LLM request:

| Detector | Pattern | Example |
|----------|---------|---------|
| Email | `user@domain.tld` | `john@example.com` |
| Phone (RU) | `+7 \d{10}` | `+7 999 123-45-67` |
| INN | `\d{10}\|\d{12}` | `7707083893` |
| SNILS | `\d{3}-\d{3}-\d{3} \d{2}` | `123-456-789 01` |
| Passport (RU) | `\d{4} \d{6}` | `4510 123456` |
| Credit Card | `\d{13,19}` (Luhn check) | `4111 1111 1111 1111` |
| IP Address | `\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}` | `192.168.1.1` |
| API Key | `sk-[a-zA-Z0-9]{32,}` | `sk-abc123...` |
| Password in code | `password\s*=\s*['\"]` | `password = "secret"` |

### Usage

```bash
# Scan a file
dev pii scan ~/projects/myapp/src/main.py

# Scan with redaction
dev pii scan --redact ~/projects/myapp/src/main.py

# Standalone Python script
python3 scripts/pii-guard.py scan file.txt
python3 scripts/pii-guard.py scan --redact file.txt
```

Redacted output replaces detected values with `[REDACTED:email]`, `[REDACTED:phone]`, etc.

## Audit Trail (44-audit.sh)

### Event Types

| Event | Trigger |
|-------|---------|
| `model_call` | Every LLM API call |
| `tool_call` | Every tool invocation |
| `provider_switch` | Automatic fallback or manual switch |
| `pii_redacted` | PII detector fired |
| `config_change` | `model-policy.json` or `opencode.json` modified |
| `policy_violation` | Blocked provider/model access |
| `session_boundary` | Session start/end |

### Hash-Chain

Each audit entry includes `prev_hash` linking to the previous entry:

```jsonl
{"ts":"...","event":"model_call","prev_hash":"000000...","hash":"abc123..."}
{"ts":"...","event":"tool_call","prev_hash":"abc123...","hash":"def456..."}
```

Tampering with any entry invalidates the entire chain.

### Rotation

```bash
# Automatic: >10MB → compress + archive
# Manual:
dev audit rotate
```

Rotated files: `audit-2026-08-08.jsonl.gz` archived to Qdrant for semantic search.

## Supply-Chain Hardening

All `curl|sh` patterns replaced:

| Before | After |
|--------|-------|
| `curl ... \| bash` | `_download_verify url file sha256 && bash file` |
| `curl ... \| sh` | `_download_verify url file sha256 && sh file` |
| `wget ... -O - \| bash` | `_download_verify url file sha256 && bash file` |

`_download_verify()` (helpers.sh):
- Downloads with 5 retries (exponential backoff)
- Verifies SHA-256 against expected value
- Fails hard on mismatch
- Respects `DRY_RUN` flag

## SBOM (Software Bill of Materials)

CycloneDX format, generated on demand:

```bash
dev bundle create --sbom /path/to/sbom.json
```

Includes all dependencies: npm packages, Go modules, Python packages, Docker images.

## Security Scanning

```bash
# Trivy — container vulnerability scanner
trivy fs --scanners vuln,secret,misconfig /path/to/project

# Qodana — code quality analysis
qodana scan --project-dir /path/to/project

# CI integration (.github/workflows/security.yml)
# Runs on push/schedule, blocks on CRITICAL/HIGH
```

## Compliance Documentation

- [SOC2 Checklist](../compliance/soc2-checklist.md) — CC5.2 (provider allowlist), CC7.2 (WAL monitoring), CC8.2 (audit trail)
- [ISO27001 Mapping](../compliance/iso27001-mapping.md) — A.9 (access control), A.12 (operations security), A.14 (system acquisition), A.18 (compliance)

## See Also

- [Model Governance](governance.md) — `model-policy.json` schema
- [Deployment Profiles](../guides/deployment-profiles.md) — security per profile
- [Air-Gap & Offline](../guides/airgap-offline.md) — isolated circuit mode
