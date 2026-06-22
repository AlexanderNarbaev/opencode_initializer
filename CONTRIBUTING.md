# Contributing to OpenCode Initializer

Thank you for considering contributing! This document outlines the process and guidelines.

## Code of Conduct

Please read our [Code of Conduct](CODE_OF_CONDUCT.md) before contributing.

## Development Setup

```bash
# Clone the repository
git clone https://github.com/AlexanderNarbaev/opencode_initializer.git
cd opencode_initializer

# Verify syntax of all scripts
for f in setup.sh dev.sh src/lib/*.sh src/modes/*.sh; do bash -n "$f"; done

# Run the test suite
bash tests/run_tests.sh

# Run ShellCheck (install first: apt install shellcheck)
shellcheck setup.sh src/lib/*.sh src/modes/*.sh
```

## How to Contribute

1. **Fork** the repository (GitHub or GitVerse)
2. **Create** a feature branch: `git checkout -b feat/my-feature`
3. **Make** your changes following the code style below
4. **Test** thoroughly:
   ```bash
   bash tests/run_tests.sh           # All tests must pass
   bash -n src/lib/your-module.sh        # Syntax check
   ```
5. **Commit** with conventional commit message
6. **Push** and submit a Pull Request

## Code Style

### Bash Conventions
- **Target**: Bash 4.0+ (POSIX-compatible wherever possible)
- **Indentation**: 2 spaces (no tabs)
- **Variables**: `snake_case`, global constants in `UPPER_CASE`
- **Functions**: `snake_case()`, documented with a one-line comment before definition
- **Strings**: Prefer single quotes, use double quotes only when expansion is needed
- **Error handling**: `set -euo pipefail` at top of every script
- **Line length**: Soft limit at 120 characters

### Module Structure
Every module in `src/lib/` must follow this pattern:
```bash
#!/usr/bin/env bash
# src/lib/NN-name.sh — Short description (STEP N)
set -euo pipefail

if ([ "$MODE" = "full" ] || [ "$MODE" = "reinit" ] || [ "$MODE" = "update" ]) && _gate "INTERACTIVE_DO_NAME"; then
  section "Section title"
  # ... implementation ...
  _step_done step_name
fi
```

### Use Infrastructure
- `_curl()` — curl with 5 retries, cache, and mirror fallback (never raw curl)
- `_retry()` — retry any command
- `_npm_install()` — npm install with pack cache and bun fallback (never raw npm install -g)
- `_sudo()` — sudo with credential caching
- `log/warn/err/info/section` — consistent logging with color output
- `_step_skip/_step_done` — progress tracking

### Secrets Policy
**Never hardcode secrets.** API keys and tokens must be:
- Passed via CLI arguments (`--deepseek-key`, `-k`, etc.)
- Stored in `~/.config/opencode/secrets.env` (chmod 600)
- Never committed to the repository

## Adding a New Component

When adding a new package, tool, MCP server, plugin, or LSP server, you must modify **all** of these files:

### For an MCP Server
1. **`src/lib/00-core.sh`** — Add to `MCP_PACKAGES` associative array
2. **`src/lib/12-mcp-lsp.sh`** — Auto-installed via registry iteration
3. **`src/lib/18-opencode-json.sh`** — Add detection block in Python generator
4. **`src/modes/health.sh`** — Add `_check` entry
5. **`src/lib/19-finalize.sh`** — Add verification case in MCP loop
6. **`src/lib/pre-session-check.sh`** — Add to MCP status loop
7. **`tests/unit/test_mcp_registry.sh`** — Add to expected list

### For a Plugin
1. **`src/lib/12-mcp-lsp.sh`** — Add `npm install -g` line
2. **`src/lib/18-opencode-json.sh`** — Add `pkg_installed()` check
3. **`src/modes/health.sh`** — Add `_check` entry
4. **`tests/unit/test_mcp_registry.sh`** — Add to plugin checks

### For an LSP Server
1. **`src/lib/12-mcp-lsp.sh`** — Add install command
2. **`src/lib/18-opencode-json.sh`** — Add `lsp_check()` call
3. **`src/modes/health.sh`** — Add `_check` entry
4. **`tests/integration/test_opencode_json_gen.sh`** — Add to LSP checks

## Testing

### Test Levels
- **Unit** (`tests/unit/`) — grep-based assertions on file structure
- **Integration** (`tests/integration/`) — CLI argument parsing, module loading order
- **E2E** (`tests/e2e/`) — Full setup.sh behavior verification

### Running Tests
```bash
# Run everything
bash tests/run_tests.sh

# Run specific test
bash tests/unit/test_mcp_registry.sh

# Syntax check only
for f in setup.sh dev.sh src/lib/*.sh src/modes/*.sh; do bash -n "$f" && echo "OK: $f"; done
```

### Writing Tests
Tests use a consistent `assert()` pattern:
```bash
TESTS_PASS=0; TESTS_FAIL=0
assert() {
  local desc="$1" condition="$2"
  if (eval "$condition") &>/dev/null; then
    TESTS_PASS=$((TESTS_PASS + 1))
  else
    TESTS_FAIL=$((TESTS_FAIL + 1))
    echo "    FAIL: $desc" >&2
  fi
}
# Usage:
assert "Description of check" 'grep -q "pattern" "$TARGET_FILE"'
```

## Commit Messages

Follow [Conventional Commits](https://www.conventionalcommits.org/):

| Type | When to use |
|------|------------|
| `feat:` | New feature or capability |
| `fix:` | Bug fix |
| `docs:` | Documentation changes |
| `test:` | Test additions or fixes |
| `refactor:` | Code restructuring (no behavior change) |
| `chore:` | Maintenance (CI, deps, etc.) |

Scope prefix (optional but recommended): `feat(A):` for Block A changes, `fix(zsh):` for ZSH fixes, etc.

## Release Process

1. All tests pass (`bash tests/run_tests.sh`)
2. ShellCheck passes (`shellcheck setup.sh src/lib/*.sh src/modes/*.sh`)
3. Version bumped in `src/lib/00-core.sh` (`SCRIPT_VERSION`)
4. Changelog updated in `CHANGELOG.md`
5. Tagged: `git tag -a v1.0.0 -m "v1.0.0: description"`
6. Pushed to both remotes (GitHub + GitVerse)

## Pull Request Checklist

- [ ] Code follows style guide (2-space indent, snake_case)
- [ ] No hardcoded secrets
- [ ] All new features have corresponding tests
- [ ] `bash -n` passes on all modified files
- [ ] `bash tests/run_tests.sh` passes
- [ ] `AGENTS.md` updated if architecture changes
- [ ] Commit messages follow conventional format

## Questions?

Open an issue on [GitHub](https://github.com/AlexanderNarbaev/opencode_initializer/issues) or reach out on [OpenCode Discord](https://discord.gg/opencode).
