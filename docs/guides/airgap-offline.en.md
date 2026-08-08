# Air-Gap & Offline Installation

v3.0.0 provides complete air-gap support: offline bootstrapping, `dev bundle` commands, and Isolated Circuit Mode.

## Quick Start

```bash
# On an online machine — create an offline bundle
dev bundle create /mnt/usb/opencode-bundle.tar.gz

# On the air-gapped machine
bash setup.sh --airgap --bundle /mnt/usb/opencode-bundle.tar.gz
```

## Creating an Offline Bundle

```bash
# Create a bundle with all dependencies
dev bundle create /path/to/bundle.tar.gz

# List bundle contents
dev bundle list /path/to/bundle.tar.gz

# Verify SHA-256 manifest
dev bundle verify /path/to/bundle.tar.gz
```

The bundle includes:
- All 49 modules (`src/lib/*.sh`)
- Orchestrator (`setup.sh`) and CLI (`dev.sh`)
- MCP/LSP server binaries (from Bun cache)
- LLM model files (if `--include-models` flag)
- Dependency caches (npm, pip, Go modules)
- SHA-256 manifest for every file

## Installation from Bundle

```bash
# Full offline install
bash setup.sh --airgap --bundle /path/to/bundle.tar.gz

# With API keys (pre-configured, no network needed)
bash setup.sh --airgap --bundle bundle.tar.gz \
  --deepseek-key "sk-..." --github-token "ghp_..."
```

## Isolated Circuit Mode

Air-gapped LLM operation with local backends:

```bash
# Enable during install
bash setup.sh --full --isolated

# Or enable post-install
dev isolated on

# Check current state
dev isolated status
```

Supported local backends:

| Backend | Port | Endpoint |
|---------|------|----------|
| Ollama | 11434 | `http://localhost:11434/v1` |
| vLLM | 8000 | `http://localhost:8000/v1` |
| SGLang | 30000 | `http://localhost:30000/v1` |

### What Gets Gated

When `ISOLATED_CIRCUIT=true`:

| Gate | Effect |
|------|--------|
| `version-check.sh` | Skipped — no network to compare versions |
| `20-autoupdate.sh` | topgrade + unattended-upgrades disabled |
| `00-core.sh: _set_dns()` | No-op under `DRY_RUN` |
| `dev doctor` | Provider checks limited to local endpoints |
| `model-policy.json` | Auto-set to `mode: "allowlist"` with local providers only |

## Supply-Chain Verification

Every bundle artifact is verified via SHA-256:

```bash
# _download_verify() — used by 46-offline-bundle.sh
_download_verify "https://example.com/tool.sh" "tool.sh" "abc123..."

# Bundle manifest
cat bundle-manifest.sha256
# abc123...  setup.sh
# def456...  src/lib/00-core.sh
# ...
```

## See Also

- [Deployment Profiles](deployment-profiles/) — 4 profile types
- [Security & Compliance](../reference/security-compliance/) — PII, audit, SBOM
- [Model Governance](../reference/governance/) — allowlist/blocklist
