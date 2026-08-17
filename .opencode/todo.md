# Mission: AI-Native Development System Optimization

## M1: SSOT Routing Table | status: completed
### T1.1: Canonical routing SSOT | agent:Worker
- [x] S1.1.1: Create `src/data/routing.json` (complexity + task + agent profiles, incl. `testing` profile, cost_per_1k)
- [x] S1.1.2: Refactor `src/lib/36-model-router.sh` to read routing.json (offline fallback preserved)
- [x] S1.1.3: Refactor `scripts/ai-router.sh` to read routing.json + reconcile `testing` divergence (settled on deepseek/deepseek-v4-flash)
- [x] S1.1.4: Create `tests/unit/test_routing.sh`

## M2: Context-Aware MCP/LSP Selection | status: completed
### T2.1: Context selector module | agent:Worker
- [x] S2.1.1: Create `src/lib/52-context-selector.sh` (task-scoped MCP/LSP selection)
- [x] S2.1.2: Create `tests/unit/test_context_selector.sh`
- [x] S2.1.3: Create `src/data/mcp-profiles.json` (task/file-type → MCP+LSP manifest)
- [x] S2.1.4: Wire `src/lib/18-opencode-json.sh` to consume mcp-profiles.json
- [x] S2.1.5: Create `tests/unit/test_mcp_profiles.sh`

## M3: Wire Harnesses into Lifecycle | status: completed
### T3.1: Sandcastle CI reproducibility | agent:Worker
- [x] S3.1.1: Add `dev sandcastle review` subcommand (implement→review, hooks + timeouts)
- [x] S3.1.2: Add `.github/workflows/sandcastle-review.yml`
### T3.2: dsh plugin automation starter | agent:Worker
- [x] S3.2.1: Populate `cordis.yml` starter in `49-deepseek-harness.sh`
### T3.3: Tests | agent:Worker
- [x] S3.3.1: Create `tests/unit/test_sandcastle_review.sh` + `tests/unit/test_dsh_plugins.sh`

## M4: Shared Language + Memory SSOT | status: completed
### T4.1: CONTEXT.md generator | agent:Worker
- [x] S4.1.1: Extend `src/lib/17-project.sh` to generate starter `CONTEXT.md` (idempotent)
### T4.2: Memory hierarchy SSOT | agent:Worker
- [x] S4.2.1: Create `.opencode/docs/memory-hierarchy.md`
### T4.3: Tests | agent:Worker
- [x] S4.3.1: Extend `tests/unit/test_project.sh` with CONTEXT.md assertions (+8)

## M5: Automation | status: completed
### T5.1: Auto-skills module | agent:Worker
- [x] S5.1.1: Create `src/lib/53-auto-skills.sh` (context-based skill auto-triggering)
### T5.2: Task distributor module | agent:Worker
- [x] S5.2.1: Create `src/lib/54-task-distributor.sh` (agent distribution + parallel dispatch)
- [x] S5.2.2: Create `tests/unit/test_task_distributor.sh` (70 assertions)
- [x] S5.2.3: Wrap `pre-session-check.sh` as a `42-hooks.sh` pre-session hook
- [x] S5.2.4: Add `dev docs` generator + `tests/unit/test_dev_docs.sh`
- [x] S5.2.5: Create `tests/unit/test_auto_skills.sh`

## M6: Final Verification | status: completed | depends:M1,M2,M3,M4,M5
### T6.1: Reviewer full-system verification | agent:Reviewer
- [x] S6.1.1: bash -n on all modified/new modules
- [x] S6.1.2: Run specific unit tests (serial: routing, context_selector, task_distributor, sandcastle_review, dsh_plugins, project)
- [x] S6.1.3: Verify git status reflects all files; mark all M1-M5 subtasks [x]
