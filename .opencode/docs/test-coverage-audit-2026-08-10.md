# Test Coverage Audit — opencode_initializer v3.2.0

> **Date:** 2026-08-10 | **Auditor:** Planner (S2 analysis)  
> **Scope:** `src/lib/*.sh` (52 modules) + `src/modes/*.sh` (6 modes) + `scripts/*` (15 scripts)  
> **Method:** Static cross-reference of every source file against `tests/{unit,integration,e2e}/`

---

## 1. Executive Summary

| Metric | Value |
|--------|-------|
| Source modules | 52 (49 numbered + helpers + pre-session-check + version-check) |
| Test files (functional) | 58 (47 unit + 6 integration + 5 e2e) |
| Modules with dedicated test | **41/52 (79%)** |
| Modules with ZERO test coverage | **11/52 (21%)** |
| Test depth: shallow (grep-only) | ~35% of unit tests |
| Test depth: medium (helpers sourced) | ~40% of unit tests |
| Test depth: deep (module sourced, real execution) | ~25% of unit tests |
| Modes tested | 0/6 (0%) — health.sh has incidental references only |
| Scripts tested | 3/15 (20%) |
| Docker/containers in tests | **NONE** — all tests are pure static analysis or isolated sourcing |

---

## 2. Coverage Matrix: Module → Test Status

### 2.1. FULLY UNTESTED modules (ZERO dedicated test)

| # | Module | Lines | Functions | Risk | Why untested |
|---|--------|-------|-----------|------|------------|
| 1 | **42-hooks.sh** | 134 | 10 | HIGH | Lifecycle hooks framework: PII gate, policy check, audit. No test. |
| 2 | **44-audit.sh** | 158 | 5 | HIGH | Audit trail: SHA-256 hash-chain, WAL rotation, event types. No test. |
| 3 | **47-lynis.sh** | 71 | 3 | MEDIUM | CIS scanner installer. No test. |
| 4 | **48-auditd.sh** | 62 | 2 | MEDIUM | Kernel audit daemon. No test. |
| 5 | **15-security.sh** | 75 | 0* | LOW | Trivy+Qodana installer (step-only). |
| 6 | **20-autoupdate.sh** | 89 | 0* | LOW | topgrade + systemd timer (step-only). |
| 7 | **22-webui-service.sh** | 69 | 0* | LOW | Open WebUI user service (step-only). |
| 8 | **23-just.sh** | 68 | 0* | LOW | just task runner (step-only). |
| 9 | **31-cockpit.sh** | 29 | 0* | LOW | Cockpit delegation (step-only). |
| 10 | **35-gui.sh** | 54 | 0* | LOW | Web GUI installer (step-only). |
| 11 | **pre-session-check.sh** | 164 | 1 | MEDIUM | Provider/model validation before sessions. Has `_check_provider()` but no test. |

> *Modules marked 0 functions are "step-only" modules. Still deserve at least existence+syntax+DRY_RUN tests.

### 2.2. SHALLOW tested modules (grep-only, no function execution)

| Module | Test file | What's tested |
|--------|-----------|---------------|
| 01-system.sh | test_system.sh | Existence, syntax, has apt/PKG_MANAGER |
| 02-docker.sh | test_python_docker.sh | Has docker-compose |
| 03-chrome.sh | test_tools.sh | Existence, syntax (shared test with 04,17) |
| 04-zsh.sh | test_tools.sh | Existence, syntax, has oh-my-zsh, p10k |
| 05-java.sh | test_java.sh | Existence, syntax, has Adoptium, SDKMAN, Zig |
| 06-node.sh | test_node_mcp.sh | Existence, syntax (shared test) |
| 07-python.sh | test_python_docker.sh | Has uv, Docker compose |
| 08-go.sh | test_go.sh | Syntax, has version, fallback logic |
| 09-rust.sh | test_rust.sh | Existence, syntax, has rustup |
| 10-dotnet.sh | test_dotnet.sh | Existence, syntax, has dotnet-install |
| 11-opencode.sh | test_opencode.sh | Existence, syntax |
| 12-mcp-lsp.sh | test_mcp_registry.sh | Existence, syntax, MCP/LSP counts, node MCP check |
| 13-chromadb.sh | test_chromadb.sh | Existence, syntax, has systemd |
| 14-shokunin.sh | test_download_verify.sh | Only `bash -n` loop check (not dedicated) |
| 16-llm.sh | test_llm.sh | Existence, syntax, has Ollama, vLLM, SGLang |
| 17-project.sh | test_tools.sh | Has compose (shared test) |
| 27-dotfiles.sh | test_dotfiles.sh | Existence, syntax, has chezmoi |
| 28-devbox.sh | test_download_verify.sh | Only `bash -n` loop check |
| 29-mise.sh | test_mise.sh | Existence, syntax |
| 30-infra.sh | test_infra.sh | Existence, syntax, has PostgreSQL, Qdrant, Redis, Prometheus |
| 34-observability.sh | test_observability.sh | Existence, syntax, has Prometheus, Grafana, ports 9090/3001 |
| 35-gui.sh | test_gui.sh | Existence, syntax, has port 4200, HTML references (deep grep) |
| 38-ide-plugins.sh | test_ide_plugins.sh | Existence, syntax, has DevoxxGenie, Cline, Tabby, Copilot |
| 40-best-practices.sh | test_best_practices.sh | Existence, syntax, has linting/pre-commit |
| 41-constitution.sh | test_sdd_commands.sh | Constitution mentioned in SDD commands test (not dedicated) |
| 99-upstream-sync.sh | test_upstream_sync.sh | Existence, syntax |
| version-check.sh | – | Only `bash -n` in loop |

### 2.3. MEDIUM tested modules (helpers sourced, real functions but limited scope)

| Module | Test file | Assertions | What's tested |
|--------|-----------|------------|---------------|
| helpers.sh | test_helpers.sh | 33 | log/warn/info/section output, _curl, _retry, _npm_install, _sudo, cleanup |
| 00-core.sh | test_core.sh | 43 | SCRIPT_VERSION, ARCH, PKG_MANAGER, OS detection, progress, interactive, DRY_RUN, _set_dns |
| helpers.sh (sub) | test_download_verify.sh | 9 | _download_verify existence, curl|sh absence |
| helpers.sh (sub) | test_safe_rm.sh | ~5 | _safe_rm behavior (directory, file, dry-run) |
| helpers.sh (sub) | test_wal_race.sh | 11 | _wal_locked_append race test (10 parallel writers) |
| helpers.sh (sub) | test_error_strategy.sh | 6 | _trap_cleanup, err behavior, warn behavior, trap integration |

### 2.4. DEEP tested modules (full function execution with isolation)

| Module | Test file | Assertions | What's tested |
|--------|-----------|------------|---------------|
| 26-providers.sh | test_providers.sh | 56 | All 23 providers: deepseek, opencode, zai(GLM-5.2), openrouter, xai, anthropic, google, mistral, groq, together, cohere, fireworks, cerebras, perplexity, alibaba, deepinfra, ollama, vllm, sglang, fallback chains |
| 43-governance.sh | test_governance.sh | 45 | Real sourcing: policy creation, _provider_allowed, _model_allowed, 18-opencode-json integration, backward compat |
| 45-pii-guard.sh | test_pii_guard.sh | 36 | Real sourcing: email, phone(+7/8), INN(10+12), credit card, API key, IP, SNILS, passport, multi-PII, clean, redact, registry count |
| 33-services.sh | test_services.sh | 23 | Real sourcing: port resolution, service modes, 4 profiles |
| 32-isolated.sh | test_isolated.sh | 23 | Declare -A compat, Ollama+vLLM+SGLang existence |
| 46-offline-bundle.sh | test_offline_bundle.sh | 17 | Real sourcing: bundle creation, SHA-256 manifest, profile handling |
| 26-providers.sh (sub) | test_provider_ssot.sh | 16 | Cross-file: 26-providers ↔ 18-opencode-json ↔ opencode.json |
| 36-model-router.sh | test_model_router.sh | 15 | Task-based selection, 8 profiles, cost table |
| 19-finalize.sh | test_finalize.sh | 16 | Git config, PATH, secret files, P10k fix |
| 24-websearch.sh | test_websearch.sh | ~3 | SearXNG + sanitizer existence |

---

## 3. Modes Test Coverage

| Mode | Tested? | References |
|------|---------|------------|
| ci.sh | NO | None |
| fix-zshrc.sh | NO | None |
| health.sh | INCIDENTAL | test_mcp_registry.sh (1 mention) |
| interactive.sh | NO | None |
| new.sh | NO | None |
| upgrade.sh | NO | None |

> **Risk:** Modes are the public API of setup.sh. Zero mode-specific tests exist.

---

## 4. Scripts Test Coverage

| Script | Type | Tested? | Test file |
|--------|------|---------|-----------|
| embed-proxy.py | Python | YES | test_embed_proxy.sh |
| provider-check.sh | Bash | YES | test_provider_check.sh, test_provider_ssot.sh |
| oc-json.sh | Bash | IMPLICIT | test_opencode_json.sh |
| ai-router.sh | Bash | NO | None |
| pii-guard.py | Python | NO | None |
| oc-tui.sh | Bash | NO | None |
| oc-metrics.py | Python | NO | None |
| oc-rpc.sh | Bash | NO | None |
| oc-sdk.py | Python | NO | None |
| sync-agents.py | Python | NO | None |
| sync-providers.py | Python | NO | None |
| check-setup-lines.sh | Bash | NO | None |
| deploy-pages.sh | Bash | NO | None |
| fix-sublime-apt-key.sh | Bash | NO | None |
| sync-projects.sh | Bash | NO | None |

---

## 5. Test Methodology Classification

### 5.1. Static Analysis (grep-only) — ~70% of unit tests
- `grep` assertions on source text
- `bash -n` syntax validation
- Stub functions for output (log, warn, info)
- No actual module code execution

### 5.2. Semi-integration (Real sourcing, isolated) — ~25% of unit tests
- `source` the module under test in isolated `mktemp` HOME
- Real function execution with stubbed dependencies
- Both happy path and edge case testing

### 5.3. Full Integration — 6 tests
- test_args.sh (49 assertions): argument parsing
- test_help.sh (28 assertions): help output
- test_modules.sh (243 assertions): module loading + structure
- test_opencode_json_gen.sh (87 assertions): JSON generation
- test_airgap_bundle.sh: offline bundle
- test_dry_run.sh: dry-run mode

### 5.4. Docker/Testcontainer — NONE
No test uses Docker. Infrastructure correctness is never verified in CI.

---

## 6. Priority List — Modules Needing Tests

### CRITICAL (before any production use):

| Rank | Module | Reason | Type |
|:----:|--------|--------|------|
| 1 | 42-hooks.sh | 10 functions, PII gate, policy check, audit hooks | Semi-integration |
| 2 | 44-audit.sh | SHA-256 hash-chain, WAL rotation, event types | Unit + integration |
| 3 | 47-lynis.sh | CIS scanner installer | Existence+syntax+DRY_RUN |
| 4 | 48-auditd.sh | Kernel audit rules | Existence+syntax+DRY_RUN |

### HIGH (significant risk):

| Rank | Module | Reason |
|:----:|--------|--------|
| 5 | pre-session-check.sh | Pre-flight validation, 164 lines |
| 6 | 20-autoupdate.sh | topgrade + systemd timer |
| 7 | 15-security.sh | Trivy+Qodana install |
| 8 | 31-cockpit.sh | Cockpit TUI delegation |

### SHALLOW TESTS needing deepening:

| Module | Current test | Gap |
|--------|-------------|-----|
| helpers.sh | 33 assertions | _spin_start/stop, _progress, _run_spin, _blur, _download_verify behavior, _wal_locked_append behavior untested in helpers context |
| 12-mcp-lsp.sh | 10 assertions | Only counts MCP servers; LSP install logic, Bun paths untested |
| 30-infra.sh | 8 assertions | Docker compose structure only; no service health checks |
| 34-observability.sh | 9 assertions | Dashboard provisioning, Node Exporter, OTel untested |
| 99-upstream-sync.sh | ~3 assertions | Sync logic completely untested |

---

## 7. Recommendations

### Short-term:
1. Add tests for 42-hooks.sh — PII gate, policy check, audit hooks
2. Add tests for 44-audit.sh — event format, hash-chain, rotation
3. Add tests for pre-session-check.sh — _check_provider()
4. Deepen test_helpers.sh — spin, progress, wal_locked_append behavior

### Medium-term:
5. Add mode-specific tests (health.sh, ci.sh at minimum)
6. Add tests for key scripts (pii-guard.py, ai-router.sh, oc-tui.sh)
7. Convert 10 shallow (grep-only) tests to real sourcing tests

### Long-term:
8. Add Docker-based integration tests (PostgreSQL+Qdrant+Redis health)
9. Add E2E smoke test: `setup.sh --dry-run --mode ci` in CI
10. Consider mutation testing for audit/governance/hooks modules

### Test Architecture:
- Standardize 3 test templates: shallow (grep), medium (source helpers), deep (source module)
- Use TMPDIR isolation consistently
- Add assertion counts to ALL test files
- Document pre-existing failures (as done with test_wal_race.sh)

---

## 8. Appendix: Complete Test File Inventory

### Unit Tests (47 files):
test_bash32_compat.sh(58) test_best_practices.sh(~5) test_chromadb.sh(~3) test_cockpit.sh(3) test_core.sh(43) test_dotfiles.sh(~3) test_dotnet.sh(~3) test_download_verify.sh(9) test_dryrun_dns.sh(11) test_embed_proxy.sh(11) test_error_strategy.sh(6) test_finalize.sh(16) test_go.sh(11) test_governance.sh(45) test_gui.sh(33) test_helpers.sh(33) test_ide_plugins.sh(15) test_infra.sh(8) test_infra_only.sh(~3) test_isolated.sh(23) test_java.sh(~3) test_linux_platform.sh(~5) test_llm.sh(~3) test_mcp_registry.sh(10) test_mirrors.sh(14) test_mise.sh(~3) test_model_router.sh(15) test_node_mcp.sh(~5) test_observability.sh(9) test_offline_bundle.sh(17) test_opencode.sh(~3) test_opencode_json.sh(11) test_pii_guard.sh(36) test_plugins_registry.sh(27) test_provider_check.sh(7) test_provider_ssot.sh(16) test_providers.sh(56) test_python_docker.sh(~5) test_rag.sh(~3) test_rust.sh(~3) test_safe_rm.sh(~5) test_sdd_commands.sh(26) test_services.sh(23) test_system.sh(~5) test_tools.sh(~5) test_upstream_sync.sh(~3) test_wal_race.sh(11) test_websearch.sh(~3)

### Integration Tests (6 files):
test_airgap_bundle.sh test_args.sh(49) test_dry_run.sh test_help.sh(28) test_modules.sh(243) test_opencode_json_gen.sh(87)

### E2E Tests (5 files, framework-only):
test_critical_path.sh test_deployment_profiles.sh test_dev_cli.sh test_finalize.sh test_full_install.sh

---

> **Generated:** 2026-08-10 by Planner. Also saved to `.opencode/docs/`.
> **Next step:** Commander should decide which gap to address first (recommendation: 42-hooks.sh + 44-audit.sh for CRITICAL wave).
