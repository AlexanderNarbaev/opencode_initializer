# TOML Configuration

`setup.sh` supports declarative configuration via TOML files. This replaces
(or supplements) command-line flags and environment variables with a single,
version-controlled configuration file.

## Quick Start

```bash
# Copy the template
cp src/data/setup.toml.template setup.toml

# Edit for your environment
$EDITOR setup.toml

# Preview what will be installed (dry-run)
bash setup.sh --config setup.toml --dry-run

# Install with TOML config
bash setup.sh --config setup.toml
```

## Precedence

Configuration values are resolved in this order (highest priority first):

1. **CLI flags** (`--deepseek-key`, `--project-dir`, etc.)
2. **Environment variables** (`DEEPSEEK_API_KEY`, `PROJECT_DIR`, etc.)
3. **TOML file** (`setup.toml`)
4. **Defaults** (hardcoded in setup.sh)

This means you can set defaults in TOML and override specific values via
CLI or env vars without modifying the file.

## Schema

```toml
[meta]
version = "1.0"           # Schema version
profile = "personal"      # Installation profile

[user]
git_name = "Your Name"    # Git identity
git_email = "you@example.com"
shell = "zsh"             # Default shell
project_dir = "~/projects" # Project directory

[features]
docker = true             # Core features
gui = true
nodejs = true             # Language toolchains
python = true
go = true
rust = false

[features.skip]
devbox = false            # Skip specific components

[services]
postgres = true           # Infrastructure services
redis = true
qdrant = true
prometheus = true
grafana = true

[ports]
postgres = 5432           # Port overrides
redis = 6379

[providers]
deepseek_key = "..."      # API keys (prefer env vars)

[tools]
node_ver = "24"           # Version overrides
python_ver = "3.14"
```

## Environment Variable Mapping

TOML values are exported as `UPPER_CASE` env vars:

| TOML Path | Env Var |
|-----------|---------|
| `[meta] version` | `META_VERSION` |
| `[user] git_name` | `USER_GIT_NAME` |
| `[features] docker` | `FEATURES_DOCKER` |
| `[services] postgres` | `SERVICES_POSTGRES` |
| `[ports] postgres` | `PORTS_POSTGRES` |
| `[providers] deepseek_key` | `PROVIDERS_DEEPSEEK_KEY` |

## Validation

```bash
# Show resolved configuration (TOML + env + defaults)
bash setup.sh --config setup.toml --print-config
```

## Security

- API keys in TOML are stored in **plaintext**
- Prefer environment variables for sensitive values
- Use `--print-config` to verify no secrets are exposed
- The `.gitignore` excludes `setup.toml` by default

## See Also

- `src/data/setup.toml.template` — full annotated template
- `docs/guides/provider-setup.en.md` — provider configuration
- `docs/guides/state-detection.en.md` — drift detection
