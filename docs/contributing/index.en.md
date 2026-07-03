# Contributing

We love contributions! Here's how to help make opencode_initializer better.

## :fontawesome-solid-code: Code of Conduct

This project follows the [Contributor Covenant 2.1](https://github.com/AlexanderNarbaev/opencode_initializer/blob/main/CODE_OF_CONDUCT.md). Please read it before contributing.

## :fontawesome-solid-bug: Reporting Bugs

1. Check [existing issues](https://github.com/AlexanderNarbaev/opencode_initializer/issues)
2. Use the [bug report template](https://github.com/AlexanderNarbaev/opencode_initializer/issues/new?template=bug_report.md)
3. Include: OS, shell version, installer version, full error output

## :fontawesome-solid-lightbulb: Feature Requests

1. Check [existing issues](https://github.com/AlexanderNarbaev/opencode_initializer/issues)
2. Use the [feature request template](https://github.com/AlexanderNarbaev/opencode_initializer/issues/new?template=feature_request.md)
3. Describe: problem, proposed solution, alternatives considered

## :fontawesome-solid-code-pull-request: Pull Requests

### Setup

```bash
git clone https://github.com/AlexanderNarbaev/opencode_initializer.git
cd opencode_initializer
```

### Development Workflow

1. **Create a branch**: `git checkout -b feat/my-feature`
2. **Make changes**: Edit shell scripts, tests, docs
3. **Test**: Run the test suite
4. **Lint**: Run ShellCheck and shfmt
5. **Commit**: Follow [Conventional Commits](https://www.conventionalcommits.org/)
6. **Push**: `git push origin feat/my-feature`
7. **PR**: Create a pull request on GitHub

### Code Style

| Rule | Example |
|------|---------|
| **2-space indent** | `  local var="value"` |
| **snake_case variables** | `my_variable`, `SCRIPT_DIR` for globals |
| **`[[ ]]` over `[ ]`** | `if [[ -f "$file" ]]; then` |
| **`$(cmd)` over backticks** | `result=$(command)` |
| **`local` for all function vars** | `local name="$1"` |
| **Quoted variables** | `"$HOME"`, not `$HOME` |
| **No hardcoded secrets** | Use CLI args or env vars |
| **`set -euo pipefail`** | At top of every script |
| **`set -o inherit_errexit`** | In setup.sh |

### Testing

```bash
# Full test suite
bash tests/run_tests.sh

# Syntax check only
bash -n setup.sh
for f in src/lib/*.sh src/modes/*.sh; do bash -n "$f"; done

# ShellCheck
shellcheck setup.sh src/lib/*.sh src/modes/*.sh

# Format check
shfmt -d -i 2 -ci setup.sh src/lib/*.sh src/modes/*.sh
```

### Pre-commit Hooks

Install pre-commit for automatic checks:

```bash
pip install pre-commit
pre-commit install
```

This runs ShellCheck, shfmt, and gitleaks on every commit.

## :fontawesome-solid-book: Documentation

Documentation is built with MkDocs Material:

```bash
# Activate venv
source .venv-docs/bin/activate

# Serve locally
mkdocs serve

# Build
mkdocs build

# Deploy (maintainers only)
mkdocs gh-deploy
```

## :fontawesome-solid-list-check: PR Checklist

- [ ] Code follows style guide (2-space indent, snake_case)
- [ ] No hardcoded secrets
- [ ] New features have tests
- [ ] `bash -n` passes on all modified files
- [ ] `bash tests/run_tests.sh` passes
- [ ] `AGENTS.md` updated if architecture changes
- [ ] Commit messages follow conventional format

## :fontawesome-solid-shield-halved: Security

- **Never commit secrets.** Use CLI args or environment variables.
- **Report vulnerabilities** privately: see [SECURITY.md](https://github.com/AlexanderNarbaev/opencode_initializer/blob/main/SECURITY.md)
- **gitleaks** pre-commit hook catches common secret patterns

## :fontawesome-solid-sitemap: Project Structure

```
opencode_initializer/
├── setup.sh              # Orchestrator (561 lines)
├── dev.sh                # CLI tool
├── opencode.json         # AI config
├── mkdocs.yml            # Docs config
├── src/
│   ├── lib/              # 38 modules
│   └── modes/            # 5 mode scripts
├── tests/                # Test suites
├── docs/                 # Documentation (this site)
├── migrations/           # Database migrations
├── scripts/              # Utility scripts
├── .github/              # CI + templates
└── AGENTS.md             # AI agent instructions
```

## :fontawesome-solid-trophy: Recognition

Contributors are recognized in the [GitHub contributors graph](https://github.com/AlexanderNarbaev/opencode_initializer/graphs/contributors) and release notes.

---

:fontawesome-solid-heart: **Thank you for contributing!**

---

**See also:**
- [Architecture](../architecture/) — system design and module layout
- [Reference](../reference/) — CLI and config schema
- [Getting Started](../getting-started/) — installation and first use
