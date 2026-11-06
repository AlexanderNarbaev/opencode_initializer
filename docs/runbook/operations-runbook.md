# OpenCode Initializer — Operations Runbook

## Table of Contents
1. [Quick Reference](#quick-reference)
2. [Installation](#installation)
3. [Health Checks](#health-checks)
4. [Troubleshooting](#troubleshooting)
5. [Maintenance](#maintenance)
6. [Emergency Procedures](#emergency-procedures)

---

## Quick Reference

### Essential Commands
```bash
# Full installation
./setup.sh --full

# Health check
./setup.sh --health

# Dry run (check without installing)
./setup.sh --dry-run

# Update everything
./setup.sh --sync

# Security scan
./setup.sh --security-scan

# Performance benchmark
./setup.sh --benchmark

# Start GUI dashboard
./setup.sh --gui-start

# View logs
tail -f ~/.local/state/opencode-init/setup.log
```

### Version Information
```bash
./setup.sh --version
cat package.json | grep version
```

---

## Installation

### First-Time Installation
```bash
# 1. Clone repository
git clone https://github.com/AlexanderNarbaev/opencode_initializer.git
cd opencode_initializer

# 2. Run full installation
./setup.sh --full

# 3. Verify installation
./setup.sh --health
```

### Custom Configuration
```bash
# 1. Copy template
cp src/data/setup.toml.template setup.toml

# 2. Edit configuration
vim setup.toml

# 3. Install with custom config
./setup.sh --full --config=setup.toml
```

### Skip Specific Modules
```bash
# Skip devbox and GUI
./setup.sh --full --skip devbox,gui

# Skip multiple modules
./setup.sh --full --skip devbox,gui,caching,chromadb
```

### Parallel Installation
```bash
# Use 8 parallel jobs
./setup.sh --full --parallel 8

# Disable parallel (sequential)
./setup.sh --full --no-parallel
```

---

## Health Checks

### System Health
```bash
# Full health check
./setup.sh --health

# Check specific components
docker ps                    # Docker services
systemctl --user status opencode  # OpenCode service
```

### Service Health
```bash
# PostgreSQL
pg_isready -h localhost -p 5432

# Redis
redis-cli ping

# Qdrant
curl http://localhost:6333/healthz

# Prometheus
curl http://localhost:9090/-/healthy

# Grafana
curl http://localhost:3000/api/health
```

### Log Locations
```bash
# Main log
~/.local/state/opencode-init/setup.log

# WAL (Write-Ahead Log)
~/.local/state/opencode-init/wal.log

# Docker logs
docker logs postgres
docker logs redis
docker logs qdrant
```

---

## Troubleshooting

### Problem: Installation Fails

**Symptom:** `setup.sh` exits with error

**Solution:**
```bash
# 1. Check logs
tail -50 ~/.local/state/opencode-init/setup.log

# 2. Check WAL for partial state
cat ~/.local/state/opencode-init/wal.log

# 3. Resume from last checkpoint
./setup.sh --full  # Will skip completed steps

# 4. Force reinstall specific module
./setup.sh --full --force
```

### Problem: Docker Services Won't Start

**Symptom:** `docker ps` shows no containers

**Solution:**
```bash
# 1. Check Docker status
sudo systemctl status docker

# 2. Start Docker
sudo systemctl start docker

# 3. Check for port conflicts
sudo lsof -i :5432  # PostgreSQL
sudo lsof -i :6379  # Redis
sudo lsof -i :6333  # Qdrant

# 4. Restart infrastructure
cd ~/.local/share/opencode-init/infra
docker compose down
docker compose up -d
```

### Problem: Port Conflicts

**Symptom:** `Error: Port 5432 already in use`

**Solution:**
```bash
# 1. Find process using port
sudo lsof -i :5432

# 2. Kill process or change port in setup.toml
[ports]
postgres = 5433

# 3. Restart services
./setup.sh --health
```

### Problem: WAL Race Condition

**Symptom:** `Error: WAL write failed`

**Solution:**
```bash
# 1. Check WAL file
cat ~/.local/state/opencode-init/wal.log

# 2. Clear WAL and retry
rm ~/.local/state/opencode-init/wal.log
./setup.sh --full

# 3. If persistent, check disk space
df -h ~/.local/state/
```

### Problem: Module Installation Fails

**Symptom:** Specific module fails during installation

**Solution:**
```bash
# 1. Skip failing module
./setup.sh --full --skip <module-name>

# 2. Check module dependencies
grep "_deps()" src/lib/<module>.sh

# 3. Install dependencies manually
# (module-specific instructions in module file)

# 4. Retry with force
./setup.sh --full --force
```

### Problem: Tests Fail

**Symptom:** `test_*.sh` exits with non-zero

**Solution:**
```bash
# 1. Run specific test
bash tests/unit/test_core.sh

# 2. Check test output
bash tests/unit/test_core.sh 2>&1 | tail -20

# 3. Run all tests
for t in tests/unit/test_*.sh; do
  echo "--- $(basename $t) ---"
  bash "$t" 2>&1 | tail -3
done
```

---

## Maintenance

### Daily Tasks
```bash
# Check for updates
./setup.sh --sync

# Security scan
./setup.sh --security-scan

# Check disk usage
du -sh ~/.local/share/opencode-init/
du -sh ~/.cache/opencode-init/
```

### Weekly Tasks
```bash
# Full benchmark
./setup.sh --benchmark

# Clean old cache
./setup.sh --cache-cleanup

# Update documentation
./setup.sh --sync-force
```

### Monthly Tasks
```bash
# Review security report
cat ~/.local/state/opencode-init/security-report.json

# Check for new plugin versions
./setup.sh --discover-plugins

# Update session checkpoint
./setup.sh --health
```

### Backup Configuration
```bash
# Export configuration
cp setup.toml setup.toml.backup.$(date +%Y%m%d)

# Export to cloud
./setup.sh --cloud-upload

# Import from cloud
./setup.sh --cloud-download
```

---

## Emergency Procedures

### Complete Reset
```bash
# 1. Stop all services
docker compose -f ~/.local/share/opencode-init/infra/docker-compose.yml down

# 2. Remove state
rm -rf ~/.local/state/opencode-init/

# 3. Remove cache
rm -rf ~/.cache/opencode-init/

# 4. Reinstall
./setup.sh --full
```

### Rollback to Previous Version
```bash
# 1. Checkout previous version
git log --oneline -10
git checkout <previous-commit>

# 2. Reinstall
./setup.sh --full

# 3. Return to latest
git checkout main
```

### Fix Corrupted Database
```bash
# 1. Stop PostgreSQL
docker stop postgres

# 2. Backup data
cp -r ~/.local/share/opencode-init/infra/pgdata ~/.local/share/opencode-init/infra/pgdata.backup

# 3. Remove corrupted data
rm -rf ~/.local/share/opencode-init/infra/pgdata

# 4. Restart
docker compose -f ~/.local/share/opencode-init/infra/docker-compose.yml up -d postgres

# 5. Restore from backup if needed
# (pg_restore or manual migration)
```

### Emergency Contacts
- **GitHub Issues:** https://github.com/AlexanderNarbaev/opencode_initializer/issues
- **Documentation:** https://alexandernarbaev.github.io/opencode_initializer/

---

## Appendix

### Environment Variables
| Variable | Description | Default |
|----------|-------------|---------|
| `OPENCODE_INIT_CONFIG` | Config file path | `setup.toml` |
| `OPENCODE_INIT_LOG_LEVEL` | Log level | `info` |
| `OPENCODE_INIT_PARALLEL` | Parallel jobs | `4` |
| `OPENCODE_INIT_MIRRORS` | Mirror region | `global` |

### File Locations
| Path | Description |
|------|-------------|
| `~/.local/state/opencode-init/` | State files |
| `~/.local/share/opencode-init/` | Data files |
| `~/.cache/opencode-init/` | Cache files |
| `~/.config/opencode/` | OpenCode config |

### Port Allocation
| Service | Port | Override |
|---------|------|----------|
| PostgreSQL | 5432 | `PORTS_POSTGRES` |
| Redis | 6379 | `PORTS_REDIS` |
| Qdrant | 6333 | `PORTS_QDRANT` |
| Prometheus | 9090 | `PORTS_PROMETHEUS` |
| Grafana | 3000 | `PORTS_GRAFANA` |
| GUI | 4200 | `GUI_PORT` |
| WebUI | 3080 | `PORTS_WEBUI` |


---

## DeepSeek Harness (DSH) profile

The machine runs DSH 0.2.1-rc.5 as the primary agent harness (`dsh web` on
`http://127.0.0.1:3080`). Its configuration is reproducible from this repo:

```bash
bash scripts/dsh-setup.sh --check    # read-only verification (default)
bash scripts/dsh-setup.sh --apply    # render templates + link skills + validate
bash scripts/dsh-setup.sh --dry-run  # print planned actions
```

What the script manages under `$DSH_HOME` (default `~/.dsh`):

| Path | Content |
|---|---|
| `profiles/web/cordis.patch.yml` | rendered from `src/data/dsh/cordis.patch.web.yml`: DeepSeek default route, token-plan alternates, three MCP servers, dark theme |
| `AGENTS.md` | user-global instructions, rendered from `src/data/dsh/AGENTS.md` |
| `skills` → `~/.config/opencode/skills` | shared skill library (43 skills; DSH shows 49 with its bundled `dsh-badge`) |
| `mcp/memory.json` | knowledge-graph storage for the `memory` MCP server |

Model routes (cost-first):

- `xiaomi-token-plan-sgp/mimo-v2.6-pro` — default (prepaid MiMo token plan, 1M context);
  `mimo-v2.6-flash` for quick work.
- `llm-pi-ai` alternates: `minimax` (MiniMax token plan). DeepSeek remains a selectable
  route (`deepseek-official/deepseek-v4-pro` / `deepseek-flash`) but is **not** the default:
  it is pay-as-you-go with a $10/month budget.
- DeepSeek discovery reads `DEEPSEEK_API_KEY` from the launch environment, so start
  `dsh web` from a shell that sourced `~/.config/opencode/secrets.env`.

MCP servers (hot-reloadable, no restart): `context7` (library docs),
`sequential_thinking`, and `memory`; tools appear as `mcp__<server>__<tool>`.
Editing `cordis.patch.yml` triggers DSH's HMR recomposition; the running session
keeps its history and gains the new tools on the next turn.

Community plugins (curated in `src/data/dsh/plugins.txt`, installed by
`scripts/dsh-setup.sh --apply --plugins` and hot-loaded by HMR):

| Plugin | What it adds |
|---|---|
| `dshmarket` | in-app marketplace: browse/search/install community plugins |
| `dsh-cost-meter` | per-session cost, daily spend, history, token-plan quotas |
| `dsh-context` | context dashboard/command: what the context is made of |
| `dsh-diff-approval` | pending-edit review with whole-file diff, Keep/Revert |
| `dsh-free-search` | keyless multi-engine search (`multi_search`, `research`, …) |
| `@yolk_vat-y/dsh-project-memory` | persistent project memory: docs, symbols, tasks, lessons |

```bash
# check everything (templates + skills + plugins + composition)
bash scripts/dsh-setup.sh --check

# reproduce the machine state, including plugins
dsh plugin --profile web add dshmarket dsh-cost-meter ...   # or:
bash scripts/dsh-setup.sh --apply --plugins
```

The built-in Discover page can also consume the public catalog index
`https://cdn.jsdelivr.net/npm/dsh-plugin-catalog/index.json` (format 1), which
is faster than the GitHub Pages mirrors. Client-side plugin UI appears after a
page refresh; server-side tools/skills are available immediately.

Verification:

```bash
dsh --profile web --dump-config | grep -E 'id: (mcp-|agent-default-model|dsh-market|cost-meter|dsh-context|diff-approval|web-search-free|project-memory)'
bash scripts/dsh-setup.sh --check
```

DSH is upgraded with `npm install -g @deepseek-ai/dsh@<version>` (the current
install is 0.2.1-rc.5). The install resolves ~86 dependencies through the npm
mirror; when the registry is slow, retry rather than falling back to an older
version. Restarting `dsh web` keeps sessions on disk, so they resume after the
upgrade; the profile patch above survives upgrades.

---

## Cost policy and model routing

The machine runs on two **prepaid token plans**; DeepSeek is the only metered
provider and is capped at **$10/month** (pay-as-you-go).

| Route | Role | Marginal cost |
|---|---|---|
| `xiaomi-token-plan-sgp/mimo-v2.6-pro` | default for coding, agentic work, planning | 0 (prepaid) |
| `xiaomi-token-plan-sgp/mimo-v2.6-flash` | fast lookups, compaction, small edits, testing | 0 (prepaid) |
| `minimax-coding-plan/MiniMax-M3` | deep reasoning, reviews, architecture, debugging | 0 (prepaid) |
| `deepseek/deepseek-flash` | last-resort fallback only | metered (budgeted) |
| `deepseek/deepseek-v4-pro` | deliberate escalation only | metered (budgeted) |

OpenCode enforces this with `enabled_providers` (`xiaomi-token-plan-sgp`,
`minimax-coding-plan`, `deepseek`) plus `policies` that **deny** `opencode-go`
(expired key), `opencode` and `minimax` (metered routes). Per-agent models are set
in `~/.config/opencode/opencode.json` (`build` → MiMo Pro, `plan`/`reviewer` →
MiniMax-M3, `explore`/`compaction`/`docs` → MiMo Flash). `src/data/routing.json`
mirrors the same matrix for `ai-router.sh` and `dev models`.

DSH defaults to MiMo Pro; DeepSeek stays available in the model selector but is
never the default.

Spend tracking:

```bash
python3 scripts/ai-usage.py                 # last 30 days, human table
python3 scripts/ai-usage.py --days 7 --json # machine-readable
python3 scripts/ai-usage.py --budget 10     # DeepSeek budget override
```

It reads `~/.config/opencode/logs/token-tracker/tokens.jsonl`, separates
**billable spend** from **prepaid plan value**, prints the DeepSeek budget gauge,
and exits `1` once the budget is reached (cron/monitoring friendly).

---

## CI on GitHub and GitVerse

Both remotes are first-class: `origin` (GitHub) and `gitverse` (GitVerse, SSH).
Push with `git push origin main && git push gitverse main`.

### What the workflows do

| Workflow | What runs | Notes |
|---|---|---|
| `test.yml` | `tests/run_tests.sh --section unit / integration / e2e` + python tests | The master runner adds the privilege sandbox (PATH shims for `sudo`/`apt-get`/`gpg`/…) and a per-test timeout, so a hanging test fails loudly instead of blocking the job. |
| `lint.yml` / `shellcheck.yml` | ShellCheck at **severity=error** over modules/tests/tracked shell files | Install is portable: preinstalled binary → apt → `pip --break-system-packages` → dedicated venv (PEP 668 images). |
| `security.yml` | Trivy CRITICAL/HIGH on the repo and `package-lock.json` | Dev-only transitive advisories are pinned through `overrides` in `package.json` (path-scoped when two major lines are involved). |
| `docs.yml` | `mkdocs build --strict` + GitHub Pages deploy | Pages status must be `built`; the published H1 must match the canonical version. |
| `build.yml` | `bun build --compile` of the GUI | |

### Pre-push checklist

```bash
bash tests/run_tests.sh                 # 378 passing on a clean checkout
bash scripts/check-doc-counts.sh        # counts in README/AGENTS/docs match code
bash scripts/check-docs-parity.sh       # EN/RU pairs complete
bash scripts/check-setup-lines.sh       # README line count == setup.sh
bash scripts/audit-module-reachability.sh --baseline src/data/dead-modules.baseline
shellcheck -S error $(git ls-files '*.sh')
```

### GitVerse specifics

- GitVerse Actions runs the same workflows on an `act`-based container
  (`gitverse/runner-image:ubuntu-latest`). It does **not** preinstall
  `shellcheck`, and `pip install --user` is blocked by PEP 668 — the install
  step in both lint workflows handles that.
- Containers there often run as **root**; tests that rely on permission denial
  (e.g. `chmod 000` + `cat`) skip themselves when `id -u` is 0, and the test job
  exports `OPENCODE_ALLOW_ROOT=1` because `setup.sh` refuses to run as root
  otherwise (a human running `sudo bash setup.sh` still gets the guard).
- Tests must not read captured output through early-exit pipelines
  (`echo "$VAR" | grep -q`, `printf '%s' "$VAR" | grep -q`): under `pipefail`
  the producer dies of SIGPIPE and the assertion flips at random. Use
  `grep -q PATTERN <<< "$VAR"`; `tests/unit/test_pipefail_sigpipe.sh` ratchets it.
- Public API (verified 2026-10-26): base `https://api.gitverse.ru` (no `/api/v1`
  prefix), headers `Authorization: Bearer <token>` and
  `Accept: application/vnd.gitverse.object+json;version=1`. Examples:

```bash
curl -s -H "Authorization: Bearer $GITVERSE_TOKEN" \
     -H "Accept: application/vnd.gitverse.object+json;version=1" \
     https://api.gitverse.ru/user

curl -s -H "Authorization: Bearer $GITVERSE_TOKEN" \
     -H "Accept: application/vnd.gitverse.object+json;version=1" \
     https://api.gitverse.ru/repos/AlexandrNarbaev/opencode_initializer/actions/runs

# job log (plain text)
curl -s -H "Authorization: Bearer $GITVERSE_TOKEN" \
     -H "Accept: application/vnd.gitverse.object+json;version=1" \
     https://api.gitverse.ru/repos/AlexandrNarbaev/opencode_initializer/actions/jobs/<job_id>/logs
```

- GitVerse CI is advisory for merges; GitHub is the authoritative gate.
- Pages deployment is GitHub-only by design: the `upload-pages-artifact` and
  `deploy-pages` steps are guarded by `github.server_url == 'https://github.com'`,
  and GitVerse publishes through its own `build-and-deploy-pages` workflow.
  The MkDocs **build** still runs on every mirror push, so a broken docs tree
  fails there too.
- As of 2026-10-28 the full `test.yml` matrix (unit, integration, python, e2e,
  container, benchmarks) is green on both remotes; see the run history on
  either repository.
