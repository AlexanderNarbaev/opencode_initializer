# Deployment Profiles

v3.0.0 introduces 4 deployment profiles with enforced rules for different security and operational requirements.

## Configuration

Set the profile in `~/.config/opencode-setup/setup.conf`:

```bash
DEPLOYMENT_PROFILE="personal"   # default
```

Or during install:

```bash
bash setup.sh --full --profile corporate
```

## Profile Reference

| Profile | Auto-Update | Telemetry | Provider Allowlist | Audit Trail | Network |
|---------|:-----------:|:---------:|:------------------:|:-----------:|:-------:|
| **personal** | on | on | off (all allowed) | off | open |
| **corporate** | on | off | on (`model-policy.json`) | on | restricted |
| **airgapped** | off | off | on (local only) | on | none |
| **hybrid** | on (dev) / off (CI) | off | on | on | dev open, CI restricted |

### Personal

Full-auto developer workstation. All providers allowed, no audit overhead, auto-update enabled.

```json
{
  "version": 1,
  "mode": "allow-all",
  "allowed_providers": [],
  "denied_providers": [],
  "allowed_models": [],
  "denied_models": [],
  "max_cost_per_1m": null,
  "audit": false,
  "note": "modes: allow-all | allowlist | corporate"
}
```

### Corporate

Team workstation with governance. Only approved providers/models, full audit trail, PII sanitizer enabled, auto-update on (weekly).

```json
{
  "version": 1,
  "mode": "corporate",
  "allowed_providers": ["deepseek", "opencode", "openai"],
  "denied_providers": ["ollama", "vllm", "sglang"],
  "allowed_models": [],
  "denied_models": ["*"],
  "max_cost_per_1m": 30.0,
  "audit": true
}
```

### Air-Gapped

No network access. Only local providers (Ollama, vLLM, SGLang). All external calls blocked at pre-request hook. `ISOLATED_CIRCUIT` gates version-check, autoupdate, unattended-upgrades. Supply-chain: SHA-256 verify only.

```json
{
  "version": 1,
  "mode": "allowlist",
  "allowed_providers": ["ollama", "vllm", "sglang"],
  "denied_providers": ["deepseek", "opencode", "openai", "anthropic", "google", "xai", "mistral", "groq", "together", "cohere", "fireworks", "perplexity", "zai", "openrouter", "alibaba", "deepinfra", "mimo", "minimax", "cerebras"],
  "allowed_models": [],
  "denied_models": [],
  "max_cost_per_1m": null,
  "audit": true,
  "note": "air-gapped — no external providers"
}
```

### Hybrid

Online development machine + offline CI pipeline. `setup.sh --full` for dev, `setup.sh --airgap` for CI. Separate `model-policy.json` per environment.

## ISOLATED_CIRCUIT Gates

When `ISOLATED_CIRCUIT=true`:

- `version-check.sh` — skipped (no network)
- `20-autoupdate.sh` — topgrade + unattended-upgrades disabled
- `00-core.sh: _set_dns()` — respects `DRY_RUN` flag

## Supply-Chain Hardening

All `curl|sh` patterns replaced with `_download_verify()`:

```bash
_download_verify "https://example.com/tool.sh" "tool.sh" "expected_sha256"
```

Attempts download with retry, verifies SHA-256, fails hard on mismatch.

## See Also

- [Model Governance](../reference/governance.md) — policy schema and enforcement
- [Air-Gap & Offline Guide](airgap-offline.md) — `dev bundle` and offline install
- [Security & Compliance](../reference/security-compliance.md) — audit, PII, SBOM
- [SOC2 Checklist](../compliance/soc2-checklist.md) — CC5.2/CC7.2/CC8.2 mapping
