# AGENTS.md — opencode_initializer

> **Operating Model:** Multi-Agent Continuous Development Framework v3.0 ([ADR](./docs/architecture/adr/2026-07-18-multi-agent-framework-v3.md))
> **Current Wave:** [current_wave.md](./current_wave.md) | **Checkpoint:** [session_checkpoint.json](./session_checkpoint.json)

## What This Project Is

**OpenCode Initializer** — a one-command, AI-native bootstrap for development machines (WSL2/Linux primary, macOS best-effort). It installs and configures 8 language toolchains, Docker infrastructure, 24 MCP servers, 13 LSP servers, 21 OpenCode plugins, and 23 LLM providers, then wires them into a governed, auditable agent harness. Four deployment profiles: `personal`, `corporate`, `air-gapped`, `hybrid`.

The codebase is overwhelmingly **Bash** (orchestrator + numbered modules), with small amounts of **Go** (Cockpit TUI, `src/cockpit/`), **JavaScript** (Web GUI, `src/gui/`), and **Python** (utility scripts in `scripts/`). There is no traditional build: "build" means syntax checks + tests; the only compiled artifact is the GUI binary (`bun build --compile`).

Current status: **v3.2.0** (canonical version — README, CHANGELOG, `package.json`, `SCRIPT_VERSION` aligned). Recent work: context/token/cost management stack (modules 53–60) and the `har` meta-harness CLI.

## Язык общения

Всё общение строго на русском языке. Код и комментарии — на английском. Documentation exists in both English and Russian (suffix i18n: `docs/*.en.md` / `docs/*.ru.md`, plus `README.md` / `README.ru.md`).

## Repository Layout

```
opencode_initializer/
├── setup.sh            ← orchestrator (~726 lines, 48 steps): parses CLI, sources modules, dispatches modes
├── dev.sh              ← post-install CLI (`dev install|health|update|infra|models|bundle|backup|...`)
├── opencode.json       ← generated OpenCode config template (23 providers, MCP registry)
├── package.json        ← only builds the GUI binary; dep: @opencode-ai/plugin
├── requirements.txt    ← MkDocs docs-site dependencies only (not runtime)
├── mkdocs.yml          ← docs site config (material + i18n, EN/RU)
├── .env.example        ← API-key template (never commit real .env)
├── src/
│   ├── lib/            ← 64 shell files: numbered modules 00–60 (+99) + helpers.sh + version-check.sh + pre-session-check.sh
│   ├── modes/          ← 6 mode scripts (ci, fix-zshrc, health, interactive, new, upgrade); other modes live inline in setup.sh
│   ├── cockpit/        ← Cockpit TUI daemon (Go module, main.go)
│   ├── gui/            ← Web GUI on port 4200 (server.js + index.html)
│   ├── data/           ← SSOT registries: providers.json, mcp-profiles.json, routing.json
│   ├── grafana/        ← dashboards + provisioning
│   └── systemd/        ← opencode-metrics.service unit
├── scripts/            ← utilities: har (meta-harness CLI), ai-router.sh, embed-proxy.py, pii-guard.py,
│                         provider-check.sh, oc-{json,rpc,sdk,tui,metrics}, sync-{agents,providers,projects}, check-setup-lines.sh, deploy-pages.sh
├── tests/              ← run_tests.sh + test_lib.sh; unit/ (82 files), integration/ (6), e2e/ (5)
├── migrations/         ← timestamped, idempotent migration scripts
├── upstream/           ← git submodules: opencode, mcp-servers, searxng, superpowers, skill-conductor
├── docs/               ← MkDocs source (EN + RU), plans/, research/, architecture/adr/
└── wal/                ← state.yaml — write-ahead log state
```

## Build / Test / Lint Commands

```bash
# Syntax check everything (the primary gate)
bash -n setup.sh dev.sh
for f in src/lib/*.sh src/modes/*.sh scripts/*.sh migrations/*.sh; do bash -n "$f"; done
for f in scripts/*.py; do python3 -m py_compile "$f"; done
gofmt -l src/cockpit/*.go   # must output nothing

# Full test suite (syntax + unit + integration + e2e, one pass/fail line per file)
bash tests/run_tests.sh

# ShellCheck (CI runs it at severity=error)
shellcheck -S error setup.sh dev.sh src/lib/*.sh src/modes/*.sh

# GUI build (the only build artifact)
bun build src/gui/server.js --compile --outfile dist/opencode-gui   # or: npm run build
node --check src/gui/server.js                                       # or: npm run check

# Go cockpit
cd src/cockpit && go vet ./... && go test ./... -count=1

# Docs site
pip install -r requirements.txt   # in a venv
mkdocs serve                      # local preview; CI deploys to GitHub Pages via docs.yml

# Diagnostics / self-repair
bash setup.sh --health            # read-only diagnostics
bash setup.sh --fix-config        # regenerate opencode.json
bash setup.sh --fix-zshrc         # repair shell config
bash setup.sh --dry-run           # preview full bootstrap, no changes
```

## Runtime Architecture

### Orchestrator flow (`setup.sh`)

1. Resolves `SCRIPT_DIR` (supports local checkout, `~/setup.sh` symlink, and `curl | bash` — in the latter case it clones the repo to `~/.cache/opencode-setup/repo` and re-execs).
2. Sources `src/lib/helpers.sh` then `src/lib/00-core.sh`, tees all output to a timestamped log under `~/.cache/opencode-setup/`.
3. Parses CLI flags: modes (`--full --reinit --new --health --update --upgrade --interactive --ci --fix-config --fix-zshrc --dry-run --airgap`), ~20 `--*-key` provider keys, infra toggles (`--with-postgres|--with-qdrant|--with-redis|--with-kafka|--with-neo4j|--with-minio|--with-observability|--with-all-infra`), and skip flags.
4. Early-exit modes (`health`, `ci`, `fix-zshrc`, `fix-config`, `upgrade`, `interactive`, `new`) `source` their file from `src/modes/` (or run inline for `fix-config`).
5. Sudo is authenticated up front: passwordless → `SUDO_PASS` env → interactive TTY prompt with 30 s timeout (`-s/--sudo-pass` is deprecated).
6. Network preflight: WSL2 DNS fix (8.8.8.8/1.1.1.1), WSL2 proxy auto-detection from the Windows registry, per-service reachability checks with apt fallbacks.
7. Executes 48 numbered steps via `_run_step <key> <name> <module>`, which honors the progress file (completed steps are skipped on re-run), supports `--dry-run`, continues past failures, and writes a WAL checkpoint per step. Independent optional modules (RAG, WebUI, mise, just, SearXNG) run in parallel when `PARALLEL_INSTALL=true`.
8. Modules `41–51` are **sourced with existence guards but not executed by the orchestrator** — they provide functions (`_offline_bundle_run`, governance/audit/PII helpers) consumed by `dev.sh`, other modules, and `scripts/pii-guard.py`. `--airgap` triggers `_offline_bundle_run` when available.

### Module conventions (`src/lib/NN-name.sh`)

- Every module starts with `#!/usr/bin/env bash`, a one-line description comment, and `set -euo pipefail`.
- The body is gated on mode: `if ([ "$MODE" = "full" ] || [ "$MODE" = "reinit" ] || [ "$MODE" = "update" ]) && _gate "..."; then ... _step_done step_x; fi`.
- All HTTP goes through `_curl()` (5 retries, exponential backoff, 24 h cache); all npm through `_npm_install()` (npm pack → bun fallback); all privileged ops through `_sudo()`. Downloads are verified via `_download_verify()` (SHA-256) instead of `curl | sh`.
- Long-running mutations are idempotent and record completion via `_step_done` in `~/.cache/opencode-setup/progress`.

### Numbered module map (as of v3.x)

| Range | Responsibility |
|-------|----------------|
| `00-core.sh` | Version, bash/OS/arch detection, package-manager abstraction (apt/dnf/pacman/apk/zypper/brew), mirrors, progress, ISOLATED_CIRCUIT |
| `helpers.sh` | Logging, spinners, `_curl`, `_retry`, `_npm_install`, `_sudo`, `_safe_rm`, `_wal_locked_append`, `_trap_cleanup` |
| `01–10` | System packages, Linux platform detect, Docker, Chrome+chromedriver, ZSH/OMZ/P10k, Java 25, Node 24, Python 3.14+uv, Go 1.26, Rust, .NET 10 |
| `11–19` | OpenCode CLI + Bun, MCP/LSP/plugins, ChromaDB, Shokunin/Superpowers, Trivy/Qodana, Ollama/vLLM/SGLang, project scaffold, opencode.json generation, finalize/verify |
| `20–29` | Auto-update (topgrade + systemd timer), RAG, Open WebUI service, just, SearXNG, provider registry, chezmoi dotfiles, Devbox, mise |
| `30–36` | Infra (PostgreSQL/Qdrant/Redis/Prometheus/Grafana/MemoryLayer), Cockpit TUI, Isolated Circuit, unified service layer, observability stack, Web GUI, model router |
| `37–40` | WAL, IDE AI plugins, best-practices skills (note: there is **no** `39-shell.sh`; numbering skips it) |
| `41–51` | Constitution/spec generator, lifecycle hooks, model governance, audit trail (hash-chained WAL), PII guard, offline bundle, Lynis, auditd, DeepSeek Harness (`dsh`), Sandcastle, OpenCode Desktop — **sourced, not step-executed** (see above) |
| `52–60` | Context-aware MCP/LSP selector, auto-triggering skills, task distribution, context/token bundle, GRACE semantic contracts, context guard (compression), provider auto-discovery, local memory, prompt caching (`60-caching.sh`) |
| `99-upstream-sync.sh` | Sync providers/MCP/LSP/plugins from the `upstream/` git submodules |
| `version-check.sh`, `pre-session-check.sh` | Helpers consumed by `dev version-check` and `dev doctor` |

### Data SSOT

`src/data/providers.json`, `mcp-profiles.json`, `routing.json` are the single source of truth for providers, MCP profiles, and model routing; `26-providers.sh` and `18-opencode-json.sh` render configs from them.

### `dev` CLI (dev.sh)

Post-install management: `install/remove <component>`, `update`, `health`, `doctor` (pre-session provider validation), `list`, `config`, `self-update`, `version-check`, `autoupdate`, `infra up|down|status`, `observability`, `gui` (port 4200), `metrics` (port 9464), `plugins list`, `isolated on|off|status`, `models <task>|install|list-local`, `bundle create|list|verify`, `backup create|list|restore`, `sandcastle review|status`, `docs`. Persistent config: `~/.config/opencode-setup/setup.conf`.

### `har` meta-harness (scripts/har)

Single entrypoint unifying `opencode` + `dsh` (DeepSeek Harness) + `sandcastle` + opencode-* plugins. Note: `opencode-context` and `opencode-router` are installed via npm and registered in the default plugin tier (the historical `opencode agent list` hang is fixed in current versions — verified 2026-08-22).

## Testing Strategy

- `tests/run_tests.sh` is the master runner: `bash -n` over all shell files, `py_compile` over `scripts/*.py`, `gofmt` over `src/cockpit/*.go`, then every file in `unit/`, `integration/`, `e2e/`. Any failure exits 1.
- Unit tests are plain bash asserting on module behavior using helpers from `tests/test_lib.sh`; two unit tests are Python (`test_sync_agents.py`, `test_sync_providers.py`).
- Integration tests cover CLI args, `--dry-run`, `--help`, module loading, opencode.json generation, air-gap bundle.
- E2E tests cover critical path, deployment profiles, dev CLI, finalize, full install.
- When adding a module, add a matching `tests/unit/test_<name>.sh`.

## CI & Quality Gates (`.github/workflows/`)

- `test.yml` — syntax checks (bash/python/gofmt), go vet/test, unit+integration+e2e on push/PR to main.
- `shellcheck.yml` — ShellCheck at severity=error on `**.sh` changes (shfmt job exists but is disabled — it breaks hyphenated array keys).
- `security.yml` — Trivy (blocking on CRITICAL) + Qodana (advisory).
- `docs.yml` — MkDocs build + GitHub Pages deploy; `build.yml` — GUI binary; `sandcastle-review.yml` — automated PR review.
- Pre-commit (`.pre-commit-config.yaml`): bash syntax, ShellCheck, secret scan, no-`grep -P` guard (macOS), README line-count check, Trivy CRITICAL.

## Coding Conventions (from CONTRIBUTING.md, enforced in CI)

- Bash 4.0+ target, POSIX-compatible where possible; **macOS bash 3.2 compatibility is required** — no `declare -A` (use parallel indexed arrays or case-dispatch lookups like `_provider_reg_get`), no `grep -P` (use `grep -oE` + sed/awk).
- 2-space indent, no tabs; `snake_case` functions/variables, `UPPER_CASE` constants; single quotes unless expansion needed; soft 120-char line limit.
- `set -euo pipefail` at the top of every script; `err()` exits, `warn()` continues.
- No secrets in code — all API keys via CLI args or env only; `.env` is gitignored; secrets file permissions are chmod 600.
- Short filenames, no spaces.
- Conventional commits; PRs to `main` on GitHub (mirror: GitVerse).
- Modules keep numeric ordering; add new ones with the next free number and wire them into `setup.sh` via `_run_step` (plus a `_step_done` key, a test file, and docs).

## Security Considerations

- Never emit secrets in logs or code; redact with `***`. Pre-commit scans for key patterns.
- Supply chain: all downloads go through `_download_verify()` (SHA-256); no raw `curl | sh`.
- PII guard (`45-pii-guard.sh`, `scripts/pii-guard.py`): 9 detector classes (email, phone, INN, SNILS, passport, credit card, IP, API key) applied before LLM requests.
- Audit trail (`44-audit.sh`): hash-chained JSONL, rotation >10 MB → gzip + Qdrant archive.
- Model governance (`43-governance.sh`): `model-policy.json` allowlist/blocklist per deployment profile.
- Isolated Circuit mode (`ISOLATED_CIRCUIT=true` / `--airgap`): blocks all cloud calls; only local OpenAI-compatible backends (Ollama :11434, vLLM :8000, SGLang :30000). Canonical env prefix is `OPENCODE_*` (`OPencode_*` is a deprecated fallback).
- Lynis CIS audit (weekly cron) and auditd kernel rules are installed by modules 47/48.

## Agent Operating Protocol

The primary agent operates as a **Universal AI Coprocessor** (`.opencode/skills/coprocessor/SKILL.md`). Key protocols:

| Protocol | Summary |
|----------|---------|
| Dual-Process Reasoning | System 1 (fast edits/grep) vs System 2 (analysis, multi-file refactors); escalate after 2 failures or >3 files |
| Memory Hierarchy | WAL (session journal) → Specs → Artifacts; artifacts override stale specs |
| Shared State = IPC | Files are the communication protocol; read before action, verify after write; `.opencode/state/` for inter-agent coordination |
| Keyboard Correction | Auto-detect RU↔EN layout mismatch; log to WAL with `[KB]` |
| CO-STAR Output | Context → Objective → Steps → Thinking → Answer → References (skip for trivial outputs) |
| Memory Anchor | Start responses with `[CTX: domain]` |
| Source Ladder | Official docs > authoritative secondary > encyclopedias > model knowledge; flag `[L1]`–`[L4]` |

**Hard gates:** never emit secrets; never delete code you don't understand (analyze first); never skip WAL; never speculate without a `[speculative]` flag (<80% confidence).

## WAL Protocol

- Location: `~/.cache/opencode/wal.jsonl` (append-only JSONL).
- Checkpoint on: tool errors, model/provider switches, architectural decisions, compaction events, every ~10 turns.
- Format: `{"ts":"ISO8601","domain":"setup|health|fix|refactor|audit|explore|review|docs|debug","decision":"...","rationale":"...","impact":["file1"],"confidence":0.85,"mode":"S1|S2"}`
- Session start ritual: read last 20 WAL lines, read `AGENTS.md` + active `.opencode/skills/`, emit `[CTX: domain]` anchor, then work.

## Git Remotes

- GitHub: https://github.com/AlexanderNarbaev/opencode_initializer
- GitVerse: https://gitverse.ru/AlexandrNarbaev/opencode_initializer

## Known Limitations

- **Optimized for WSL2/Linux**; macOS paths are best-effort (needs `brew install bash grep`; Docker Desktop for infra modules; no launchd equivalents for systemd user services). Windows-native is unsupported.
- `declare -A` is fully eliminated from code (0 usages; only historical mentions in comments) — parallel indexed arrays and case-dispatch lookups are used instead.
- Canonical version: **v3.2.0** (README, CHANGELOG, `package.json`, `SCRIPT_VERSION` aligned).
- `docs/`, `site/`, `upstream/`, `.opencode/skills/` are large; prefer targeted Grep/Glob over broad walks.
