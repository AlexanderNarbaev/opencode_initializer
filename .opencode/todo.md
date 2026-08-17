# Mission: AI-Native Development System Optimization

## M1: SSOT Routing Table | status: completed
### T1.1: Create canonical routing SSOT | agent:Worker
- [x] S1.1.1: Create `src/data/routing.json` (complexity + task + agent profiles, incl. `testing` profile) | size:M
- [x] S1.1.2: Embed `cost_per_1k` + `rate_limits` from model-policy.json | size:S

### T1.2: Refactor 36-model-router.sh to read routing.json | agent:Worker
- [x] S1.2.1: Replace embedded `task-profiles.json` heredoc with jq/sed read of routing.json | size:M
- [x] S1.2.2: Keep backward-compat fallback (offline/no-jq) | size:S

### T1.3: Refactor scripts/ai-router.sh to read routing.json | agent:Worker
- [x] S1.3.1: Point `_load_providers_from_json` at routing.json | size:S
- [x] S1.3.2: Reconcile `testing → deepseek-v4-flash` vs `test_engineer → gpt-5-nano` divergence | size:S

### T1.4: Unit tests for routing SSOT | agent:Worker
- [x] S1.4.1: Create `tests/unit/test_routing.sh` (assert profiles parse + fallback) | size:M

## M2: Dynamic MCP/LSP Selection | status: completed
### T2.1: Create MCP/LSP profile manifest | agent:Worker
- [x] S2.1.1: Create `src/data/mcp-profiles.json` (task/file-type → required MCP + LSP) | size:M
- [x] S2.1.2: Mark heavyweight servers (chrome-devtools, playwright, excalidraw, agent-browser) disabled-by-default | size:S

### T2.2: Wire profiles into opencode.json generation | agent:Worker
- [x] S2.2.1: Extend `18-opencode-json.sh` (`apply_mcp_profiles` honoring `disabled_by_default` + per-agent `mymcp_*` gating) | size:L
- [x] S2.2.2: Preserve `full` mode = all-on baseline (`full_mode_all_on` / `MCP_ALL_ON`) | size:S

### T2.3: Unit tests for MCP profiles | agent:Worker
- [x] S2.3.1: Create `tests/unit/test_mcp_profiles.sh` (assert selective enable/disable) | size:M

### T2.4: Context-aware selector module (complementary runtime) | agent:Worker
- [x] S2.4.1: Create `src/lib/52-context-selector.sh` + `tests/unit/test_context_selector.sh` | size:L

## M3: Wire Harnesses into Lifecycle | status: completed
### T3.1: Sandcastle CI reproducibility | agent:Worker
- [x] S3.1.1: Add `dev sandcastle review` subcommand (implement→review on branch, hooks + timeouts) | size:L
- [x] S3.1.2: Add `.github/workflows/sandcastle-review.yml` gating merge | size:M

### T3.2: dsh plugin automation starter | agent:Worker
- [x] S3.2.1: Populate `cordis.yml` starter (pre-session-check, PII guard, WAL checkpoint) | size:M

### T3.3: Tests | agent:Worker
- [x] S3.3.1: Create `tests/unit/test_sandcastle_review.sh` + `test_dsh_plugins.sh` | size:M

## M4: Shared Language + Memory SSOT | status: completed
### T4.1: CONTEXT.md generator | agent:Worker
- [x] S4.1.1: Extend `17-project.sh` to generate starter `CONTEXT.md` (domain glossary) | size:M
- [x] S4.1.2: Document `grill-with-docs`/`domain-modeling` growth flow | size:S

### T4.2: Memory hierarchy SSOT doc | agent:Worker
- [x] S4.2.1: Create `.opencode/docs/memory-hierarchy.md` (Artifacts > spec > WAL; feeding layers) | size:S

### T4.3: Tests | agent:Worker
- [x] S4.3.1: Extend `tests/unit/test_project.sh` with CONTEXT.md generation assertions | size:S

### T4.4: Auto-skills + task-distributor modules | agent:Worker
- [x] S4.4.1: Create `src/lib/53-auto-skills.sh` + `tests/unit/test_auto_skills.sh` | size:L
- [x] S4.4.2: Create `src/lib/54-task-distributor.sh` + `tests/unit/test_task_distributor.sh` | size:L

## M5: Automation (pre-session + docs) | status: completed
### T5.1: Hook-based pre-session | agent:Worker
- [x] S5.1.1: Wrap `pre-session-check.sh` as a `42-hooks.sh` pre-session hook | size:M

### T5.2: Docs generation | agent:Worker
- [x] S5.2.1: Add `dev docs` generator deriving RU/EN tables from module headers | size:L

### T5.3: Tests | agent:Worker
- [x] S5.3.1: Create `tests/unit/test_dev_docs.sh` | size:M

## M6: Final Verification | status: completed
### T6.1: Full verification | agent:Reviewer
- [x] S6.1.1: Run all unit tests (bash -n + targeted test files — all pass) | size:L
- [x] S6.1.2: Verify git clean + pushed | size:S

## M7: Context, Token & Cost Management Stack | status: completed
> Research: .opencode/docs/context-token-cost-plan-2026-08-17.md

### T7.1: Prompt caching stack (P0) | agent:Worker
- [x] S7.1.1: Create `src/lib/56-caching.sh` — install cache-injector + cache-switch + cache-ttl + @vikrant82/opencode-cache-keepalive + opencode-cache-hit | size:L
- [x] S7.1.2: Wire `_run_step step_caching` into setup.sh orchestrator (after 55-context-bundle) | size:S
- [x] S7.1.3: Add `_configure_cache()` — validate `metadata.user_id` per active provider (read routing.json) | size:M
- [x] S7.1.4: Create `tests/unit/test_caching.sh` (binaries + plugin-array + syntax + subshell-source) | size:M

### T7.2: Context compression beyond dcp (P1) | agent:Worker
- [x] S7.2.1: Create `src/lib/57-context-guard.sh` — @skybluejacket/opencode-context-compress + opencode-context-guard + opencode-context-watch | size:L
- [x] S7.2.2: Wire `_run_step step_context_guard` into setup.sh | size:S
- [x] S7.2.3: Create `tests/unit/test_context_guard.sh` | size:M

### T7.3: Provider auto-discovery (P1) | agent:Worker
- [x] S7.3.1: Create `src/lib/58-provider-discovery.sh` — opencode-models-discovery + opencode-provider-manager (bin `opm`) | size:M
- [x] S7.3.2: Wire `_run_step step_provider_discovery` into setup.sh | size:S
- [x] S7.3.3: Create `tests/unit/test_provider_discovery.sh` | size:M

### T7.4: Unified cost dashboard (P2, custom) | agent:Worker | depends:T7.1
- [x] S7.4.1: Extend `scripts/oc-metrics.py` — add `opencode_token_cost_*` + `opencode_cache_hit_*` metrics (read token-tracker + cache-hit JSONL + routing.json cost_table) | size:L
- [x] S7.4.2: Add `token-costs` npm package + daily refresh cron into `20-autoupdate.sh` (price SSOT) | size:S
- [x] S7.4.3: Extend `scripts/oc-tui.sh` with a cost/cache view | size:M
- [x] S7.4.4: Create `tests/unit/test_cost_dashboard.sh` (metrics endpoint emits cost series) | size:M

### T7.5: Wire installed-but-dormant plugins (P0) | agent:Worker
- [x] S7.5.1: Register `opencode-token-tracker` + `opencode-orchestrator` + `opencode-daytona` into plugin array (installed via npm -g but inert) | size:S
- [x] S7.5.2: Update `18-opencode-json.sh` plugin tier list + `version-check.sh` so re-runs stay consistent | size:M

### T7.6: dsh + sandcastle integration (P3) | agent:Worker | depends:T7.1
- [x] S7.6.1: Extend `bundle.json` (55-context-bundle) with `context_token_cost` block (cache/compress/provider map) | size:M
- [x] S7.6.2: Add cache/context plugin stubs to dsh `cordis.yml` comments + sandcastle env passthrough | size:S

### T7.7: Local memory + security (P3, air-gap) | agent:Worker
- [x] S7.7.1: Create `src/lib/59-local-memory.sh` — opencode-mem (local-only, ONNX) gated behind `SKIP_LOCAL_MEMORY` | size:M
- [x] S7.7.2: Add `opencode-landstrip` (Landlock) to `15-security.sh` | size:S
- [x] S7.7.3: Create `tests/unit/test_local_memory.sh` | size:M

### T7.8: Final verification | agent:Reviewer | depends:T7.1,T7.2,T7.3,T7.4,T7.5,T7.6,T7.7
- [x] S7.8.1: Run `bash -n` on all new modules + targeted test files (serial, one at a time) | size:L
- [x] S7.8.2: Verify opencode.json valid + all wired plugins resolve (`opencode agent list` count) | size:M
- [x] S7.8.3: Verify git clean + pushed | size:S
