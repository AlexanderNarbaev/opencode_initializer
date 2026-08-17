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

## M2: Dynamic MCP/LSP Selection | status: in_progress
### T2.1: Create MCP/LSP profile manifest | agent:Worker
- [ ] S2.1.1: Create `src/data/mcp-profiles.json` (task/file-type → required MCP + LSP) | size:M
- [ ] S2.1.2: Mark heavyweight servers (chrome-devtools, playwright, excalidraw) disabled-by-default | size:S

### T2.2: Wire profiles into opencode.json generation | agent:Worker
- [ ] S2.2.1: Extend `18-opencode-json.sh` to honor `enabled` flags + per-agent `mymcp_*` permissions | size:L
- [ ] S2.2.2: Preserve `full` mode = all-on baseline | size:S

### T2.3: Unit tests for MCP profiles | agent:Worker
- [ ] S2.3.1: Create `tests/unit/test_mcp_profiles.sh` (assert selective enable/disable) | size:M

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

## M5: Automation (pre-session + docs) | status: pending | depends:M2,M4
### T5.1: Hook-based pre-session | agent:Worker
- [ ] S5.1.1: Wrap `pre-session-check.sh` as a `42-hooks.sh` pre-session hook | size:M

### T5.2: Docs generation | agent:Worker
- [ ] S5.2.1: Add `dev docs` generator deriving RU/EN tables from module headers | size:L

### T5.3: Tests | agent:Worker
- [ ] S5.3.1: Create `tests/unit/test_dev_docs.sh` | size:M

## M6: Final Verification | status: pending | depends:M1,M2,M3,M4,M5
### T6.1: Full verification | agent:Reviewer
- [ ] S6.1.1: Run all unit tests (bash -n + tests/run_tests.sh)
- [ ] S6.1.2: Verify git clean + pushed
