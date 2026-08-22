# Full Project Audit — 2026-08-22

> Scope: code correctness, documentation accuracy, macOS compatibility, SSOT registries, orchestrator wiring. Triggered by user interview: public product, full AI stack out of the box, first-class Linux + macOS, fix-on-sight policy.

## Baseline before the audit

- Syntax: all shell/python files pass `bash -n` / `py_compile`.
- Tests: `tests/run_tests.sh` — 257 passed, 0 failed.
- Working tree contained uncommitted WIP: `56-caching.sh` → `60-caching.sh` rename (half-done: setup.sh still referenced the old path).

## Findings and resolutions

### 1. Orchestrator & SSOT (critical)

| Finding | Resolution |
|---|---|
| `setup.sh` `step_caching` referenced deleted `src/lib/56-caching.sh` — step failed on every run | Pointed to `60-caching.sh`; stale `STEP 56` header fixed |
| `56-grace-semantics.sh` never sourced nor step-executed (dead module with a passing test) | Wired via `_run_step step_grace_semantics` |
| `TOTAL_STEPS=41` vs 47 real steps | Corrected to 48 (incl. new GRACE step) |
| Missing `_step_done` in 55/58/60 — steps re-ran every time | Added `step_context_bundle` / `step_provider_discovery` / `step_caching` |
| `_run_step step_ide` vs module's `step_ide_plugins` | Unified on `step_ide_plugins` |
| `opencode.json` had stray `opencode-go` key absent from `providers.json` SSOT | Removed — 22 providers everywhere |
| No `--skip-caching` CLI flag though module read `SKIP_CACHING` | Flag added to setup.sh parser + help |
| `01b-linux-platform.sh` never sourced (contains unique PATH-sanitize / HF-mirror / NVIDIA logic, partially overlapping inline WSL setup) | Left as-is, flagged for maintainer decision |
| `migrations/20260530-v30-config.sh` lacked `set -euo pipefail` | Added |

### 2. macOS blockers (all fixed)

- New portable wrappers in `src/lib/helpers.sh`: `_md5`, `_sha256`, `_timeout`, `_sed_i`, `_file_mtime`, `_file_size`, `_readlink_f`.
- All `md5sum` / `sha256sum` / `timeout` / `sed -i` / `stat -c` call-sites migrated (helpers, 00-core, 19-finalize, 32-isolated, 16-llm, 24-websearch, 34-observability, 44-audit, 37-wal, 46-offline-bundle, dev.sh, fix-zshrc, 14-shokunin, migrations).
- GNU-only sed expressions rewritten portably (`\+`, `\s`, multiline `a\`-appends).
- `${var,,}` replaced with `tr` (dev.sh, oc-rpc.sh, e2e test).
- `grep -oP` → `grep -oE` in `.opencode/commands/analyze.sh`.
- OS guards in `47-lynis.sh` / `48-auditd.sh` (skip silently off-Linux).

### 3. Full macOS service layer (launchd + brew)

- Unified service dispatch in `src/lib/helpers.sh`: `_service_install` / `_service_start` / `_service_stop` / `_service_status` — systemd user units on Linux, LaunchAgents (`~/Library/LaunchAgents/com.opencode.*.plist`, `launchctl bootstrap gui/$UID` with `load -w` fallback) on macOS; idempotent, XML-escaped env, logs under `~/.cache/opencode-setup/logs/`.
- Migrated modules: `35-gui.sh` (:4200), `30-infra.sh` (metrics :9464), `13-chromadb.sh`, `22-webui-service.sh`, `49-deepseek-harness.sh`, `16-llm.sh` (Ollama — skip on macOS, self-managed via Ollama.app/brew).
- `dev.sh`: `cmd_gui` / `cmd_metrics` on `_service_*`; `dev isolated status` uses `lsof` on macOS instead of `ss`; `cmd_remove` gained a brew branch.
- `src/modes/health.sh`: Darwin branch (launchctl print / lsof port checks, `docker info` for Docker Desktop).
- `src/cockpit/main.go`: `fetchServices()` parses `launchctl list` on darwin.
- brew branches next to apt paths (`$PKG_MANAGER = "brew"`): 02-docker, 03-chrome, 04-zsh, 05-java (temurin cask), 06-node, 08-go, 09-rust, 10-dotnet, 11-opencode, 15-security (trivy), 16-llm (ollama), 20-autoupdate (topgrade).
- `.gitignore`: `cisofy-archive-keyring-*.gpg`; stale artifact removed from repo root.
- Follow-ups (documented, not blockers): systemd timers (20-autoupdate, 15-security) still skip on macOS (no StartCalendarInterval equivalents yet); `chrome-open()` zsh helper looks for Linux binary names only.

### 4. Version alignment

- Git ground truth: latest tag `v2.0.0` (2026-07-03), HEAD ~176 commits ahead; the whole 3.x line was never tagged.
- Canonical version set to **3.2.0**: package.json `3.0.0` → `3.2.0`, `SCRIPT_VERSION` default `v3.0.0` → `v3.2.0` (00-core, 44-audit, 46-offline-bundle), CHANGELOG gained a `[3.2.0] — 2026-08-22` entry, tests asserting `v3.0.0` updated.
- **Action left for maintainer:** create git tags (`v3.0.0`, `v3.1.0` retroactively at suitable commits, `v3.2.0` at release).

### 5. Documentation synchronization

Canonical numbers (verified against code): 64 shell files in src/lib (61 numbered + 3 helpers), 726-line orchestrator, 48 steps, 22 providers (19 cloud + 3 local), 24 MCPs, 21 plugins (29 across tiers), 13 LSPs, 12 modes, 93 test files / 257 checks, health 128+ checks in 12 sections, Cockpit 8 tabs, router 9 profiles.

- README.md / README.ru.md: all counts fixed (was: 52 modules, 685 lines, 15 plugins with a 14-item list, 8 router profiles, 11 modes, 398+ assertions, 65+ health checks, 7-tab Cockpit).
- mkdocs.yml description, docs/index, docs/architecture (C4 diagram), docs/reference, docs/guides, docs/getting-started, docs/user-guide, docs/contributing — synchronized.
- `mcpServers` → `mcp`, `plugins` → `plugin` key names fixed in reference/user-guide docs.
- Removed: legacy `docs/ru/` (6 stale pages, broken links, contradicted everything), empty `docs/en/`, stale `docs/comparison.md` duplicate.
- `docs/VERSIONS.md`: MiMo endpoint marked unverified.
- AGENTS.md: `declare -A` note corrected (zero remain — CHANGELOG 3.1.0 was right), module-56 duplicate note removed, version-drift limitation replaced with the aligned canonical version.
- Pre-commit gate `scripts/check-setup-lines.sh` is green again (726 = 726).

### 6. Verified OK (no action needed)

- All JSON registries valid (`jq empty` passes); all 22 registry providers render into opencode.json.
- `dev.sh` implements every command advertised in README/AGENTS.md.
- Migrations are idempotent; runner has one-shot markers.
- `declare -A` count in production code: 0. CHANGELOG 3.1.0 claims (`_wal_locked_append`, `_safe_rm`, `_trap_cleanup`, test files) verified true.
- No `mapfile`/`readarray`/`wait -n`/`coproc`/`declare -n` in scope.

## Test results after fixes

`bash tests/run_tests.sh` — 257 passed, 0 failed (syntax + unit + integration + e2e). MkDocs build clean.

## Remaining known limitations (updated)

- `01b-linux-platform.sh` unwired (see 1).
- 9 modules without a direct unit test (some covered indirectly).
- Git tags for the 3.x line do not exist yet.
