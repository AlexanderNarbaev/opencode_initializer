# OpenCode Initializer — Repo History & Lost Practices

> **Generated:** 2026-10-16 · **Repo:** `/home/alexandr-narbaev/Projects/opencode_initializer`
> **Method:** git archaeology (528 commits, 8 tags, 10 refs) + on-disk forensics. Every row below cites a
> commit hash, a file path with line number, or a reproducible command output.
> **Headline finding:** the repo's *history* is intact and well-tagged. What was lost is
> **(a)** 73 tracked files deleted during the 2026-09-14 cleanup, **(b)** an entire wave of
> "delivered" Software Factory modules that are inert (sourced, never executed, zero tests, one
> flagship tool numerically broken), **(c)** a live-config fragment set destroyed by test clobbering,
> and **(d)** the *plan-checkbox tracking discipline* that made six roadmap documents unverifiable.

---

## A) TIMELINE

### Numbers

| Metric | Value | Command |
|---|---:|---|
| Commits (all refs) | **528** | `git log --oneline --all \| wc -l` |
| Commits on `main` | **419** | `git rev-list --count main` |
| Tags | **8** | `git tag` |
| First commit | `9c853aa4` 2026-06-22 "v1.0.0: Initial public release" | `git log --reverse` |
| `main` HEAD | **`0694cf12`** 2026-10-16 "fix(plugins): drop V2-only opencode-dcp from V1 config per SME finding" | `git log -1` |
| `github/main` | `e7f973dd` 2026-10-16 | 1 commit behind |
| `origin/main`, `gitverse/main` | `099da4ee` 2026-10-12 | **8 commits behind — the entire 2026-10-16 V1 runtime restoration is unpushed** |

### Branches

```
local:   archive/pre-cleanup-v14             035b33e0  2026-09-12 23:23 +0300
         backup/v1.0.1-reliability-hardening  95647918  2026-06-24 00:37 +0300
         main                                 0694cf12  2026-10-16           (checked out)
remote:  github/main                          e7f973dd  2026-10-16
         github/analysis-of-the-ci/…-9db21     10decc59  2026-09-21   (merged via d0d78a15)
         github/archive/pre-cleanup-v14       035b33e0  2026-09-12
         origin/main, origin/archive/…        099da4ee  2026-10-12   ← STALE
         gitverse/main                        099da4ee  2026-10-12   ← STALE
         gitverse/master                      749c66ee  2026-05-30   ← frozen pre-public master
         gh-pages                             8bd89d8a  2026-09-17
```

### Tags (chronological)

| Tag | Date | Subject |
|---|---|---|
| `v33.9` | 2026-06-05 | v33.9: Fix critical schema crash (dcp/damageControl → plugin tuple), version consistency |
| `v33.10` | 2026-06-05 | ZSH overhaul, Google Chrome, GitHub MCP token, dynamic providers |
| `v35.0` | 2026-06-19 | RU mirrors, 8 new plugins, gopls, Ollama via snap, tests |
| `archive/pre-v1.0.0` | 2026-06-22 | v36.0.1: Critical fixes, docs overhaul, CI setup, full project initialization |
| `v1.0.0` | 2026-06-22 | Initial public release (`0747921d`) |
| `v1.0.1` | 2026-06-22 | Critical audit fixes + research improvements (`b7a373ef`) |
| `v2.0.0` | 2026-07-03 | Stable Release (`89895f95`) |
| `v2.1.0` | 2026-09-12 | `chore(release): 2.1.0 [skip ci]` (`6ede5f29`) |

**Version-line discontinuity (evidence of a lost release ritual):** tags run
`v33.9 → v36.0.1 → v1.0.0 → v2.1.0`, while `SCRIPT_VERSION`, `package.json`, `README.md` and
`CHANGELOG.md` all say **`v15.0.0`**. The `v16.0.0` claim exists **only** in the commit subject of
`c9db6c59` and in `docs/waves/PR_DESCRIPTION.md` — no tag, no CHANGELOG entry. `CHANGELOG.md:1` newest
entry is `[15.0.0] … (2026-09-16)`. The repo has shipped 3 version lines (v15, v16 "Software Factory",
V1-restoration) with **zero tags after 2026-09-12**.

### Milestone phases

| Phase | Evidence | Date | What happened |
|---|---|---|---|
| **v33.x → v36.0.1** | tags `v33.9`…`archive/pre-v1.0.0` | 2026-06-05 → 06-22 | Monolithic-numbered releases, module explosion |
| **v1.0.1 reliability hardening** | branch tip `95647918` | 2026-06-23 → 06-24 | MkDocs Material site, GitVerse Pages, i18n switcher, ChromaDB readiness, LSP pinning — **all merged** |
| **v2.x** | `v2.0.0` (07-03), `v2.1.0` (09-12) | Jul–Sep | Stable line; `6ede5f29` is an ancestor of `main` |
| **v4 → v14** | `1a0720dc`…`9eba3413` | Jun→Sep | Plugin Discovery + Context Manager + Workflow Automation (v4.4), APM+CloudSync+GUI (v7), CUE/age/SLSA/chaos (v10), Renovate/Scorecard/Nix/OTel (v9), chezmoi + K8s/Terraform research (v12–v14) |
| **pre-cleanup-v14 snapshot** | `035b33e0` | **2026-09-12** | Branch cut *before* a mass cleanup. Still an ancestor of `main` (0 unmerged commits) |
| **THE CLEANUP** | `edae11b3` "chore: cleanup — remove temporary files, rename docs without dates" | **2026-09-14** | Deletes `.opencode/{status,sync-issues,todo}.md` and `work-log.md`. Over the following commits **73 tracked files vanish** (see B1) |
| **v15 rebirth (planning wave)** | `ff1bfd0e`, `647d1079`, `e8e1442a`, `e72242ac`, `7858c3df` | 2026-09-14 → 09-16 | The 6 strategic planning docs were born here (`VISION-2027.md`, `DEVELOPMENT-PLAN-2027.md`, `AIPDLC-INTEGRATION.md`, `DEEP-INTEGRATION-PLAN.md`, `MASTER-IMPLEMENTATION-PLAN.md`, `IMPLEMENTATION-PLAN-2026.md`) |
| **v15 execution (Phases 0–6)** | `2ca86735`…`67c216d3`, checkpoint `3e6cda2f` | 2026-09-16 | 55 modules in one day: 62–65 Skills, 66–71 Agent Orchestration, 72–77 Enterprise, 78–82 Ecosystem, 83–90 Agent Harness, 91–100 Harness Core, 101–110 PLA+RAG, 111–116 Production Hardening |
| **v15 hardening** | `039ac206`…`f67b6498` | 2026-09-16 | ShellCheck sweep, CI fixes, integration tests, benchmarks, docs parity |
| **v15.1 CLI/config/logging** | `b65c7d71`, `77b11917`, `96a2786d` | 2026-09-16 | `test_*` core-module suite, CLI interface, TOML config, logging |
| **8-wave transformation (v15)** | `TRANSFORMATION_COMPLETE_SUMMARY.md`, branch `feature/wave-transformation` | 09-21 → 09-28 | 20 commits, 13 new modules, "12/12 gaps closed". **Wave 7 "Plugin system" = PENDING** |
| **V1 → V16 Software Factory** | **`c9db6c59`** "feat: Software Factory Transformation v16.0.0" | **2026-10-02** | Largest single commit in history: **11,460 files, 2,808,070 insertions** — it accidentally committed `node_modules/` and rendered every doc page to a PNG under `docs/assets/images/social/` |
| **Software-Factory wave integration + git hygiene** | **`2b8726ff`** | **2026-10-12** | Lands the wave modules (`01-error-recovery.sh`, `02-wal-fix.sh`, `33-spec-registry.sh`, `34-token-cache.sh`, `35-debt-intent-registry.sh`, `45-maintainability-score.sh`, `50`–`54` HumanLayer) + `specs/`, `discipline/`, `plans/`; removes **2,801,917 lines** of `node_modules/` (11,209 files changed) |
| **dev.sh + CI fix chain** | `6894fca6`, `c1273501`, `6924cad9`, `ca1d07af` | 2026-10-12 17:04→17:32 | sudo-gate exemption for read-only modes, `dev version-check` exit code, ephemeral container ports, perf-threshold raise to 1000 ms |
| **hygiene + bounded probes** | `fa859587`, `0f6239bd` | 2026-10-12 18:45 | Deletes `.opencode/register_live_plugins.py` + 12 `agents/openai.yaml` stubs; `VC_BUDGET` timeouts on network probes |
| **config alignment** | `099da4ee` | 2026-10-12 19:18 | Repo `opencode.json` pinned to `@upstash/context7-mcp@4.3.0`, `github-mcp-server` on `ghcr.io`; drops 4 unpublished plugins. **Last commit pushed to `origin`/`gitverse`** |
| **1M-context policy** | **`78ed7c14`** | 2026-10-12 23:02 | Unified 1M context window + single-model policy |
| **autonomy policy** | **`b4e4ae92`** | 2026-10-12 23:08 | Autonomy + 1M-context policy propagated across all projects |
| **V1 runtime restoration** | **`319a88f9`** | **2026-10-16 13:29** | OpenCode V2 (2.0.27) cannot load V1 community plugins → `restore-v1-stack.sh`, `fix-v1-all-projects.py`, `fix-v1-schema.py`, `fix-dcp-options.py`, `fix-plugin-configs.sh`, `continuous-loop.sh` (317 new lines). Prunes 8 unported plugins |
| **context-1M fix** | **`e3748415`** | **2026-10-16 13:31** | `fix-context-1m.py` — disables legacy dcp compression, sets V1-valid compaction |
| **repo config → V1 shape + healing scripts** | `e7f973dd` | 2026-10-16 13:32 | Repo-level `opencode.json` realigned; healing scripts committed |
| **drop V2-only `opencode-dcp`** | **`0694cf12`** (HEAD) | **2026-10-16 13:35** | Removes `opencode-dcp` from the V1 config per SME finding; kept only in the staged V2 variant |

### ADRs

`docs/architecture/adr/` contains **only 2 files**, both dated July 2026:

- `hybrid-ai-architecture.md`
- `multi-agent-framework-v3.md`

`AGENTS.md` "Permanent Goals" simultaneously references `docs/architecture/adr/`, `docs/adr/`,
`docs/runbook/` and `docs/changelog/` — four different locations for one artifact class.
**ADR practice effectively stopped in July 2026** despite a "Multi-Agent Framework v3.0" ADR dated
2026-07-18 and three subsequent release lines.

### 8-wave transformation summary (from `TRANSFORMATION_COMPLETE_SUMMARY.md`)

| Wave | Commits | Modules | Gaps claimed |
|---|---:|---|---|
| Wave 0 | 4 | 0 | F1 (error recovery), F2 (WAL race) |
| Wave 1 | 5 | 50–54 | HumanLayer 4-stage design layer |
| Wave 2 | 2 | 33 + 8 specs | VibeVM `spec://` URI system |
| Wave 3 | 1 | 35 | Debt & intent tracking |
| Wave 4 | 1 | 34 | Token economics (L1/L2 cache) |
| Wave 5 | 1 | 45 | Maintainability scoring CI gate |
| Wave 6 | 4 | 41–44 | H1, H4, A5, F3, A2, S1, S2, A1 |
| **Wave 7** | **1** | **PENDING** | **Plugin system — never built** |
| TOTAL | 19 | 13 new | "12 planned gaps closed" |

Wave 7 backlog verbatim (`TRANSFORMATION_COMPLETE_SUMMARY.md:255-259`): `plugin-registry.sh`,
`plugin-manager.sh` CLI, hook system (pre-install / post-install / pre-run / post-run), and 5 starter
plugins: **codegraph, dcp, auto-fallback, goal-mode, vibeguard**.

**Status today:** `opencode-codegraph`, `opencode-auto-fallback`, `opencode-vibeguard` are live in
`~/.config/opencode/opencode.json`; **`opencode-dcp` and `opencode-goal-mode` were removed** by
`319a88f9`/`0694cf12` during the V1 restoration. Partial hook coverage exists as `src/lib/42-hooks.sh`;
there is **no** `plugin-registry.sh` and **no** `plugin-manager.sh` CLI (only `79-plugin-manager.sh`
from the Phase-2 bulk drop and `00m-plugin-discovery.sh`).

---

## B) LOST / ABANDONED PRACTICES

### B1. The "unmerged branches" — a false premise, and what is actually gone

Both candidate branches are **fully merged**. Verified:

```
$ git log main..archive/pre-cleanup-v14 --oneline | wc -l             → 0
$ git log main..backup/v1.0.1-reliability-hardening --oneline | wc -l → 0
$ git merge-base --is-ancestor archive/pre-cleanup-v14 main             → true
$ git merge-base --is-ancestor backup/v1.0.1-reliability-hardening main → true
$ git diff main...archive/pre-cleanup-v14 --stat                       → EMPTY
$ git diff main...backup/v1.0.1-reliability-hardening --stat           → EMPTY
```

- `archive/pre-cleanup-v14` (`035b33e0`, 2026-09-12) is **an ancestor of `main`**, 0 unmerged commits.
- `backup/v1.0.1-reliability-hardening` (`95647918`, 2026-06-24) is also an ancestor; nothing from it
  was ever removed.

**Nothing is recoverable *because of* the branches — everything deleted is recoverable *from* them.**
`git show archive/pre-cleanup-v14:<path>` works for all 73 files. The branches' real value is that
they are a **dated snapshot of the pre-cleanup corpus**.

#### The 73 tracked files deleted between `035b33e0` and `0694cf12`

`git diff 035b33e0..main --name-only --diff-filter=D | wc -l` → **73**
`git diff 035b33e0..main --shortstat` → **639 files changed, 36,962 insertions, 13,341 deletions**

| Group | Count | Examples | Highest-value item |
|---|---:|---|---|
| `.opencode/synthesis/2026-08-08/` | 4 | `gap-matrix.md`, `cross-reference.md`, `sdd-workflow.md`, `corporate-airgap-profile.md` | **`gap-matrix.md`** — the Gap Matrix v3.0 (F1–F12, C1–C3, H1–H5, F3.1–F3.11, M1…) with source, severity, target wave, effort per row |
| `.opencode/audit/2026-08-08/` | 5 | `01-core-architecture.md` … `05-corporate-airgap.md` | the 5-part audit the gap matrix was synthesized from |
| `.opencode/research/2026-08-08/` | 5 | `openspec.md` (16 KB), `ai-native-infra.md`, `redbook.md`, `spec-kit.md`, `competitive.md` | upstream-spec research that `docs/DEEP-INTEGRATION-PLAN.md:9-27` cites but can no longer link |
| `.opencode/docs/` | 30+ | `gap-analysis-2026-08-08.md`, `ai-native-optimization-2026-08-17.md`, `sdd-coprocessor-analysis-2026-08-16.md`, `system-design_space*.md`, `oleg_guru_redbook_ru_*.md`, `github_com_moonshotai_kimi-code.md`, `test-coverage-audit-2026-08-10.md` | **`test-coverage-audit-2026-08-10.md`** — a static cross-reference of every module against every test; the exact analysis `docs/IMPROVEMENT-PLAN.md:20-40` re-derives |
| `.opencode/*.md` (state) | 6 | `work-log.md` (1,091 lines), `project-context-full.md` (193), `project-memory.md` (64), `status.md`, `todo.md`, `interview-2026-09-11.md` (85) | **`work-log.md`** — the single largest operational record in the repo: per-task CREATE/MODIFY/VERIFY entries with commit hashes and test counts |
| `.opencode/register_live_plugins.py` | 1 | deleted by `fa859587` (2026-10-12) | idempotent npm-verify-then-append plugin registrar, 58 lines |
| `.opencode/skills/**/agents/openai.yaml` | 16 | matt-pocock stubs + `codebase-review-swarm/agents/openai.yaml` | stubs — low value |
| `.opencode/skills/codebase-review-swarm/scripts/` | 2 | `init-review-run.py` (134 L), `validate-skill-package.py` (62 L) | **`init-review-run.py`** — bootstraps the 12 artifact JSONL + 6 ledger MD that `references/review-protocol-v8.2.md` (27 KB) requires |
| `.opencode/archive/_tmp_test_auto_skills.sh` | 1 | test scratch | none |

**Live risk right now:** `git status` shows **11 tracked `.opencode/docs/` files deleted from the
working tree but NOT committed** (`test-coverage-audit-2026-08-10.md`,
`system-design_space_tracks_.md`, `www_alphaxiv_org_abs_260609498v3.md`,
`raw_githubusercontent_com_github_spec-kit_main_*` ×4,
`raw_githubusercontent_com_Fission-AI_OpenSpec_main_*` ×3,
`jimmysong_io_tags_ai_.md`). They are one `git checkout -- .opencode/docs/` away from being gone.

### B2. `~/Desktop/OpenCodeInitializer/workspace (1)` — already landed, mostly

**This workspace is NOT a source of lost content for `plans/`, `discipline/`, `specs/`.** Verified
byte-identical:

```
$ diff -r "workspace (1)/specs" ./specs                       → no differences  (8 spec.json)
$ diff -q  "workspace (1)/plans/wave-0-foundation-fixes.md" \
          ./plans/wave-0-foundation-fixes.md                  → identical
$ diff -r "workspace (1)/discipline" ./discipline             → no differences  (debt.jsonl, intent.jsonl)
$ git status --porcelain -- plans discipline specs            → CLEAN (all 11 files tracked)
```

They landed in **`2b8726ff`** (2026-10-12): 8 `specs/*.spec.json` (feat/flow/stack/tool/mcp/lang/doc/app
= the VibeVM `spec://` catalog from Wave 2), 2 `discipline/registry/*.jsonl` (Wave 3 ledgers), and
`plans/wave-0-foundation-fixes.md`.

Its git branches are also absorbed:

| Branch | Tip | Unmerged vs. its own `feature/wave-transformation` |
|---|---|---:|
| `feature/wave-transformation` (HEAD there) | `5a7eef5` 2026-10-04 | — |
| `wave/0-foundation-fixes` | `79e716c` 2026-09-17 | **0** commits |
| `qwen-code-…-9db21` | `10decc5` 2026-09-21 | **1** commit — `docs/waves/PR_DESCRIPTION.md` (+140 lines), already merged into `main` via `d0d78a15` |

**What the workspace *does* still uniquely hold:** the pre-cleanup `.opencode/` corpus — 30+ research /
audit / synthesis docs, `work-log.md`, `project-context-full.md`, `interview-2026-09-11.md`,
`register_live_plugins.py`, `codebase-review-swarm/scripts/{init-review-run,validate-skill-package}.py`
— i.e. exactly the B1 loss set, recoverable from there **or** from `archive/pre-cleanup-v14`.

**What *is* still open in `plans/wave-0-foundation-fixes.md` (41 lines, status "IN PROGRESS", never
flipped):** 5 gates that are still defensible today —
1. 17 broken doc links (Wave 0 §1) → since fixed by `41852aa4`, `b2af45cd`;
2. **Error Recovery Framework** — `_retry`, continue-on-error, graceful degradation (→ `01-error-recovery.sh`, but see B5);
3. **WAL Race Condition Fix** — file locking + atomic writes (→ `02-wal-fix.sh`, but see B5);
4. **Provider Registry Cleanup** — de-duplicate `26-providers.sh` vs `18-opencode-json.sh`, remove dead `minimax` code (Gap C1/C2, **still open**);
5. `mkdocs build --strict` with 0 warnings (`1c2bc8e0` **disabled** strict mode instead of fixing warnings).

### B3. The Software Factory modules are inert — "12/12 gaps closed" is false

This is the most consequential finding and it is fully reproducible.

`setup.sh:966-979` sources the 13 Software Factory modules but **never calls `_run_step` on any of them**:

```bash
# setup.sh:969-979
if [ "${SOFTWARE_FACTORY_ENABLED:-true}" != "false" ]; then
  for _sf_mod in \
    33-spec-registry 34-token-cache 35-debt-intent-registry \
    41-model-policy 42-pii-guard 43-audit-chain 44-offline-bundle \
    45-maintainability-score \
    50-product-review 51-architecture-doc 52-program-design \
    53-vertical-slices 54-agent-handoff; do
    [ -f "$SCRIPT_DIR/src/lib/${_sf_mod}.sh" ] && source "$SCRIPT_DIR/src/lib/${_sf_mod}.sh" || true
  done
fi
```

`setup.sh` contains **57 `_run_step` calls**; none of them is a Software Factory module. Verified
runtime behaviour:

| Module | `_run_step`? | tests referencing it? | Standalone execution |
|---|---|---:|---|
| `33-spec-registry.sh` | no | **0** | **FAILS** — `bash src/lib/33-spec-registry.sh list` → `line 43: log_warn: command not found` (helpers never sourced on the direct-exec path) |
| `34-token-cache.sh` | no | **0** | dispatcher at `:456` produces no output; L2 cache dir `~/.cache/opencode/tokens` **does not exist** |
| `35-debt-intent-registry.sh` | no | **0** | **works** — `bash src/lib/35-debt-intent-registry.sh stats` → `Debt: 5 total, 1 open / Intent: 5 total, 5 active` |
| `45-maintainability-score.sh` | no | **0** | **BROKEN** — see below |
| `50-product-review.sh` … `54-agent-handoff.sh` | no | **0** | never invoked |

**`45-maintainability-score.sh` is numerically broken.** Reproduced:

```
$ source src/lib/helpers.sh; source src/lib/45-maintainability-score.sh
$ calculate_maintainability_score . text
src/lib/45-maintainability-score.sh: line 120: 3.00: arithmetic syntax error: invalid arithmetic operator (error token is ".00")
src/lib/45-maintainability-score.sh: line 190: 0
0: arithmetic syntax error in expression (error token is "0")
src/lib/45-maintainability-score.sh: line 245: ((: 0
0 : arithmetic syntax error in expression (error token is "0 ")
src/lib/45-maintainability-score.sh: line 343: [: : integer expected
  MAINTAINABILITY SCORE: /100
  STATUS: CRITICAL
Script exited with code 3
```

Root cause: the `$(cmd || echo 0)` idiom where `cmd` has *already printed* output —
`:187` `local functions=$(grep -c "^[a-z_]*() {" "$script" 2>/dev/null || echo 0)` yields `"0\n0"` when
`grep -c` finds nothing and exits 1; `:189-190` then does `$((total_functions + functions))` on `"0\n0"`.
Same class at `:120` (`bc` emits a decimal into an integer accumulator) and `:245`.

**Contradiction with the record:** `TRANSFORMATION_COMPLETE_SUMMARY.md:212` reports
"Maintainability Score: 78 — Baseline established" and `:196` claims a CI gate
"Блокировка merge при score < 70". Reality:
- `grep -rn 'maintainability' .github/workflows/` → **no matches** (no CI gate exists);
- `grep -cE 'debt|intent|maintainability|spec-registry|token-cache' dev.sh` → **0** (no CLI entrypoint);
- the score tool exits 3 with an empty score.

The same gap applies to the other claimed CLIs. `TRANSFORMATION_COMPLETE_SUMMARY.md:150-158` advertises
`opencode debt add --id …`, `opencode intent record --decision …`. `dev.sh`'s dispatch table
(`dev.sh:1029-1052`) has `install|remove|update|health|list|config|config-from|self-update|
version-check|autoupdate|infra|plugins|observability|gui|metrics|isolated|models|doctor|state|backup|
bundle|sandcastle|daytona|docs|skills|context` — **no `debt`, `intent`, `spec`, `maintainability`**.
`registry_cli` (`35-debt-intent-registry.sh:97`) and `spec_cli` (`33-spec-registry.sh:502`) are
reachable only by executing the module file directly.

`discipline/registry/debt.jsonl` is still `created: 2026-01-01T00:00:00Z` for all 5 entries with
`DEBT-001` ("Missing Design Layer", severity high) `status: open` — i.e. the ledger the tooling writes
has never been touched.

**Summary:** 13 modules ≈ 4,000 lines landed in `2b8726ff`, and **0 of them are reachable from
`setup.sh` or `dev.sh`, and 0 have a test.** The gap-closure claim is unfalsifiable as written.

### B4. Planned-but-unlanded in `docs/`

All six planning docs are on `main`. Their checkbox discipline is dead — this is the key finding:

| Doc | Lines | `[ ]` unchecked | `[x]` checked | Reality vs. the plan |
|---|---:|---:|---:|---|
| `docs/VISION-2027.md` | 170 | 0 | 0 | Narrative; **status "DRAFT — Pending stakeholder validation" since 2026-09-14 — never validated** |
| `docs/DEVELOPMENT-PLAN-2027.md` | 651 | **48** | **0** | Modules 62–77 were built in `2ca86735`/`872ea4bc`/`695ea71a`, yet all 48 boxes remain `[ ]` |
| `docs/MASTER-IMPLEMENTATION-PLAN.md` | 587 | **31** | 0 | "New Modules 62-129" — 62–119 exist; boxes unchecked |
| `docs/IMPLEMENTATION-PLAN-2026.md` | 315 | **24** | 0 | `test.yml`, `.shellcheckrc`, `examples/`, `docs/api/cli-reference.md` all exist; boxes unchecked |
| `docs/IMPROVEMENT-PLAN.md` | 269 | 0 | 0 | "ANALYSIS COMPLETE" (2026-09-16), never converted into tickets |
| `docs/DEEP-INTEGRATION-PLAN.md` | 636 | 0 | 0 | 50+ sources; the pattern catalogue was never turned into build items |

**Concrete artifacts that genuinely did NOT land:**

| Planned artifact | Cited at | Actual state |
|---|---|---|
| `scripts/skill-registry.py` — registry client | `DEVELOPMENT-PLAN-2027.md:54` | absent |
| `scripts/skill-scanner.py` — static skill analysis | `:78` | absent; `src/lib/64-skill-security.sh` + `src/data/security-rules.json` do exist |
| `scripts/eval-runner.py` — scenario execution | `:106` | absent; `src/data/eval-scenarios.json` + `65-skill-eval.sh` exist |
| `scripts/workflow-runner.py` — workflow engine | `:145` | absent; `src/data/workflows/default.yaml` exists |
| `scripts/agent-discovery.py` — service discovery | `:165` | absent; `68-agent-mesh.sh` exists |
| `scripts/context-indexer.py` | `:186` | absent; `70-context-engine.sh` exists |
| `scripts/audit-analyzer.py` | `:210` | absent; `43-audit-chain.sh` / `44-audit.sh` exist |
| `scripts/metrics-collector.py` | `:250` | absent; `77-observability.sh` / `scripts/oc-metrics.py` exist |
| `src/data/roles.json` — 5 default RBAC roles | `:209` | absent; `72-rbac.sh` exists |
| `src/data/compliance/` — SOC2/ISO templates | `:230` | absent; `74-compliance.sh` exists |
| `examples/{skill-creation,agent-workflow,rbac-setup}.sh` | `IMPLEMENTATION-PLAN-2026.md:259-261` | absent; 6 other examples exist |
| `benchmark_{modules,skills,agents}.sh` | `:249-251` | absent; `test_perf_regression.sh`, `test_security_benchmark.sh` exist |
| Wave 7: `plugin-registry.sh`, `plugin-manager.sh` CLI, hook system, 5 starter plugins | `TRANSFORMATION_COMPLETE_SUMMARY.md:255-259` | not built |
| `Constitution.md` (Gap SK1/SK2) | `TRANSFORMATION_COMPLETE_SUMMARY.md:269` | **still absent** — `find . -iname 'constitution*.md'` → 0 results |
| Trivy scheduled scan (Gap A3) | `:268` | still absent — `security.yml:13-32` has `trivy` and `trivy-advisory` jobs but **no `schedule:` trigger**; only PR/push |
| Provider-registry unification (Gap C1/C2) | `:270` | **partially** addressed — `src/data/providers.json` is now a real SSOT rendered by `26-providers.sh`/`18-opencode-json.sh`; the `26-` vs `18-` duplication noted in `plans/wave-0-foundation-fixes.md` §4 remains |

**Highest-value *ideas* (not artifacts) still on the shelf:**

1. **`DEEP-INTEGRATION-PLAN.md:9-27`** ranks the highest-leverage patterns: **SCEI** (layered prompts
   for cache reuse), **Hybrid RAG** (BM25 + vector), **PLA** micro-prompt pipeline, **Smart LLM router**
   (difficulty-based, cost optimization), **Tool Catalog Compiler** (MCP/OpenAPI compression),
   **Local AI code review** (Ollama, no cloud), **AI-Native uncertainty governance**.
   Modules `83`, `91`, `101-106`, `107-110` exist as *shells*; `tests/unit/test_pla_rag.sh` asserts
   only that they **load**, not that they work.
2. **`DEEP-INTEGRATION-PLAN.md:313-316`** — **Crush TUI frontend**, n8n workflow automation, Dify
   agent platform, MCP gateway: four *product surfaces*, zero present in `src/`.
3. **`MASTER-IMPLEMENTATION-PLAN.md:351-354`** — perf / security / scalability / production readiness
   modelled as a **gate**, not as another module. This is precisely the practice lost in B3.
4. **`IMPROVEMENT-PLAN.md:20-40`** — the module→test coverage gap table. It is still accurate today for
   the `00d-00v` family (`00v-age-encryption`, `00q-template-engine` have no dedicated test) **and now
   also applies to all 13 Software Factory modules.**

### B5. Config fragments destroyed by clobber incidents

Compared live `~/.config/opencode/opencode.json` (13,155 B) against the two incident files
(jsonc-tolerant parse).

#### `opencode.json.custom-bak` (18,571 B, **2026-07-26**, mode 0600)

| Fragment | Detail | Lost? |
|---|---|---|
| **`provider.moonshotai`** | `"Moonshot Kimi (via local proxy)"`, `baseURL: http://127.0.0.1:9876/v1`, `apiKey: "not-needed-proxy-injects-key"`, npm `@ai-sdk/openai-compatible`, `fallback: ["deepseek"]`. Models: **`kimi-k3` — `limit.context: 1,000,000`, `output: 65,536`**, `kimi-k2.7-code` (262,144), `kimi-k2.7-code-highspeed` (262,144); all `reasoning: true`, **`tool_call: false`** | **YES — and absent from the SSOT too.** `src/data/providers.json` has 22 providers, none named `moonshotai`. This is the **only 1,000,000-token context model definition in the entire system** |
| **`provider.zai`** | `baseURL: https://api.z.ai/api/paas/v4`, `glm-5.2` / `glm-5-turbo` | YES from live config (repo template still has it) |
| **`provider.xai`** | `grok-4.3` / `grok-4.20-0309-non-reasoning` | YES from live config (repo template still has it) |
| **`tui`** | `{"show_token_count": true, "show_cost": true, "show_tool_usage": true}` | **YES — there is no `tui` key at all in the live config** (`grep -n '^  "' opencode.json` confirms) |
| **`experimental`** | `{"mcp_timeout": 45000, "openTelemetry": true, "mcp_warm_start": true, "token_counter": true, "performance_stats": true, "context_tracker": true}` | **YES — the live `experimental` block (`opencode.json:337-340`) keeps only `context_selector_dir` + `task_distributor_dir`.** All 6 perf/telemetry flags gone |
| `autoupdate: true` | | superseded by live `"update": "auto"` → not a real loss |
| `compaction.tail_turns: 3`, `reserved: 8000` | live is `tail_turns: 2`, `reserved: 10000` | deliberate (1M-window tuning in `e3748415`) |
| `mcp.context7-official` | local `~/.bun/bin/context7-mcp` | YES from live config |
| `plugin: opencode-dcp` | tuple with `compress`/`prune` options | deliberately removed by `0694cf12` |

#### `opencode.json.clobbered-by-tests-163634` (20,672 B, 2026-10-12 16:33)

| Fragment | Detail | Lost? |
|---|---|---|
| **`mcp.websearch`** | `npx -y mcp-searxng`, `"enabled": true`, `env.SEARXNG_URL = http://localhost:8888` | **YES — not in live config.** The only 2 `searxng` mentions in any config file. `brave-search` MCP *is* live, so this is the **self-hosted** search path — and module `25-searxng.sh` already installs that service |
| **`tui`** | token / cost / tool-usage overlays | YES (same as above) |
| **`experimental`** | the same 6 perf flags | YES |
| **13 plugins present here, absent live** | `opencode-cache-hit`, `opencode-cache-ttl`, `@vikrant82/opencode-cache-keepalive`, `@skybluejacket/opencode-context-compress`, `opencode-context-guard`, `opencode-context`, `opencode-router`, `opencode-provider-manager`, `opencode-morph-plugin`, `opencode-firecrawl`, `opencode-plugin-otel`, `opencode-goal-mode`, `opencode-dcp` | 4 dropped on purpose in `099da4ee` as **unpublished** (`goal-mode`, `morph-plugin`, `firecrawl`, `plugin-otel`); the context/cache family was pruned by `fix-plugin-configs.sh` in `319a88f9` as unported V1-API |
| `permission` | — | live version is *newer* (`*.env`: deny, `doom_loop`: ask) — no loss |

#### Root cause (the lost *practice*)

The live config is a single global JSON with **no schema-aware merge layer**, while
`restore-v1-stack.sh`, `fix-v1-all-projects.py`, `fix-v1-schema.py`, `fix-plugin-configs.sh`,
`fix-dcp-options.py` and `fix-context-1m.py` all rewrite it **wholesale**. Symptoms:

- **22 timestamped backups** now live in `~/.config/opencode/` (`opencode.json.bak-20261012T220408`
  … `.bak-ctx1m-20261016T133124`, `.clobbered-20260808`, `.jsonc.removed-20261012`, `.restored-20261012`,
  `.v1.bak-*`), plus **8 more in the repo root** (`opencode.json.bak-v1all-…`, `.bak-dcp-…`,
  `.bak-dcpdrop-…`, `.bak-ctx1m-…`) — all untracked (`git status` → 23 `??` entries).
- Two of those repo-root backups are **byte-identical pairs** (`bak-dcp-20261016T132022` and
  `bak-dcp-20261016T132025`, md5 `5d5c2b03`), showing a re-run of a destructive script.
- The clobber was **caused by the test suite** (filename `…clobbered-by-tests-163634`): a test wrote
  the user's real config path instead of a temp one. That test-hygiene defect was fixed for the
  affected test but **no guard was added** to prevent recurrence.

---

## TOP-5 RESTORATION LIST (ranked by value ÷ effort)

### 1. Make the 13 inert Software Factory modules reachable and tested — **value: HIGH / effort: S**

- **Why #1:** it is the only item that converts *already-written* work into working product. Today
  `setup.sh:969-979` sources 13 modules and calls none; `dev.sh` exposes no entrypoint; 9 of them have
  **zero** tests; and the flagship tool `calculate_maintainability_score` **exits 3 with an empty score**
  (B3). This is what makes "12/12 gaps closed" in `TRANSFORMATION_COMPLETE_SUMMARY.md:212` unfalsifiable.
- **Source:** `src/lib/{33,34,35,45,50,51,52,53,54}-*.sh` (already in `main` via `2b8726ff`);
  defects reproduced live.
- **First step (≈4 h):**
  1. Fix the `$(cmd || echo 0)` float/multiline defects in `45-maintainability-score.sh` at `:120`,
     `:187`, `:190`, `:245` (use `$(cmd | tail -1)` or `|| true` + explicit default) and make
     `calculate_maintainability_score . text` return a real integer and exit 0.
  2. Add `spec_cli`/`registry_cli`/`maintainability` dispatch to `dev.sh:1029-1052`
     (`dev spec list|check-citations`, `dev debt list`, `dev intent record`, `dev maintainability`).
  3. Fix `33-spec-registry.sh` direct-exec by sourcing `helpers.sh` before the `BASH_SOURCE` dispatch
     at `:598`.
  4. Add `tests/unit/test_software_factory.sh` asserting existence + syntax + load for all 13 (the
     pattern used by `test_harness.sh:18,46`), plus one behavioural assertion each for 33/34/35/45.

### 2. Adopt schema-aware merge + mandatory timestamped backup for `~/.config/opencode/opencode.json` — **value: HIGH / effort: S**

- **Why #2:** this single practice would have prevented **three** incidents already on disk
  (`clobbered-20260808`, `clobbered-by-tests-163634`, the `custom-bak` fragment loss). 30 loose
  `.bak-*` files across two directories are the symptom of a hand-patched file with no SSOT.
- **Source:** evidence in `~/.config/opencode/` and the repo root; commits `319a88f9`, `e3748415`,
  `0694cf12`; scripts `fix-plugin-configs.sh`, `fix-v1-schema.py`, `fix-context-1m.py`.
- **First step:** add `scripts/merge-opencode-config.py` — deep-merge the live file with a tracked
  `config/layer.local.json` overlay (provider / mcp / plugin / tui / experimental), write
  `opencode.json.bak-<UTC>` before every write, and validate against
  `https://opencode.ai/config.json`. Route all six existing rewriters through it. Then restore the
  **zero-risk pure additions** from `custom-bak`: the `tui` block and the 6 `experimental` flags.
  Finally, add a test-hygiene guard asserting no test writes outside `TMPDIR` for this path.

### 3. Restore the `moonshotai` 1M-context Kimi provider into the SSOT — **value: HIGH / effort: XS**

- **Why #3:** it is the only **1,000,000-token context** model definition anywhere in the system and
  the empirical basis for the 1M-context policy landed in `78ed7c14` / `b4e4ae92` / `e3748415`. It is
  also a **local** endpoint (`127.0.0.1:9876`), so it costs no API budget.
- **Source:** `~/.config/opencode/opencode.json.custom-bak:78-124` (full JSON available).
- **First step:** add a `"moonshotai"` entry to `src/data/providers.json` with
  `base_url: "http://127.0.0.1:9876/v1"`, `sdk: "openai-compatible"`, `fallback: ["deepseek"]`, and
  `limit.context: 1000000`; add an assertion to `tests/unit/test_provider_ssot.sh`; re-render via
  `bash setup.sh --fix-config`.
- **Caveat:** `tool_call: false` on all three Kimi models — unusable as the primary agent model, only
  as a long-context reader. Restoring it is about regaining the *documented evidence* for the 1M policy.

### 4. Recover the 2026-08 research corpus into `docs/research/` — **value: MED-HIGH / effort: XS**

- **Why:** 73 tracked files were deleted at the 2026-09-14 cleanup; the four most decision-relevant
  survive only in git history. `docs/DEEP-INTEGRATION-PLAN.md` and `docs/MASTER-IMPLEMENTATION-PLAN.md`
  cite them but can no longer link them, so the evidence chain is broken.
- **Source:** `git show archive/pre-cleanup-v14:<path>` for
  `.opencode/synthesis/2026-08-08/gap-matrix.md` (Gap Matrix v3.0),
  `.opencode/work-log.md` (1,091 lines — the largest operational record in the repo),
  `.opencode/audit/2026-08-08/01-05-*.md`,
  `.opencode/research/2026-08-08/openspec.md`,
  `.opencode/docs/test-coverage-audit-2026-08-10.md`,
  `.opencode/docs/ai-native-optimization-2026-08-17.md`,
  `.opencode/project-context-full.md`.
- **First step:** `git archive archive/pre-cleanup-v14 .opencode/synthesis .opencode/audit .opencode/research | tar -x -C <tmp>`,
  promote the six files above into `docs/research/2026-08/`, and add them to `mkdocs.yml` nav under
  **Working Documents** (the pattern established by Wave 4 of `b77ff56`).
- **Also (2 min):** `git checkout -- .opencode/docs/` to restore the 11 tracked-but-deleted files, and
  delete the 8 untracked `opencode.json.bak-*` copies from the repo root once #2 lands.

### 5. Re-open the plan checkboxes — make the roadmap machine-checkable — **value: MED / effort: S**

- **Why:** `DEVELOPMENT-PLAN-2027.md` (48 `[ ]`), `MASTER-IMPLEMENTATION-PLAN.md` (31) and
  `IMPLEMENTATION-PLAN-2026.md` (24) all show **0 `[x]`** even though most of their deliverables
  shipped on 2026-09-16. Anyone reading them today underestimates what exists and cannot tell which
  ~20 items are genuinely open. This is the single largest source of *perceived* lost practice — and,
  combined with B3, it is how inert modules got reported as delivered.
- **First step:** one reconciliation pass — mark shipped items (modules 62–119 exist; `test.yml`,
  `.shellcheckrc`, `examples/`, `docs/api/cli-reference.md` exist), leave the truly-missing set
  (the 10 Python companions + `roles.json` + `compliance/` + Wave 7 + `Constitution.md` + Trivy timer),
  then add `scripts/check-plan-sync.sh` to `tests/run_tests.sh` asserting every `[ ]` maps to a real
  missing path. Same script should assert every `_run_step`'d module has a `tests/unit/test_<name>.sh`.

---

### Runners-up (recorded, not ranked)

- **`.opencode/skills/codebase-review-swarm/scripts/init-review-run.py`** (134 lines) and
  `validate-skill-package.py` (62 lines), deleted by `fa859587` under the heading "remove unused skill
  agent stubs" — `git show fa859587^:<path>`. They are not stubs: `init-review-run.py` bootstraps the
  12 artifact JSONL + 6 ledger MD that `references/review-protocol-v8.2.md` (27 KB) requires. ~15 min.
- **`mcp.websearch` (mcp-searxng @ `localhost:8888`)** from `opencode.json.clobbered-by-tests-163634:397-408`
  — a self-hosted search path already paid for by module `25-searxng.sh`; ~30 min; pairs naturally
  with #2.
- **`register_live_plugins.py`** (58 lines, `git show fa859587^:.opencode/register_live_plugins.py`) —
  idempotent, npm-verify-then-append registrar. Its hardcoded `ADD` list is now stale, but the
  *practice* ("never hand-edit the plugin array") belongs in #2's merge script.
- **Gap A3 — Trivy scheduled scan.** `security.yml:13-32` runs Trivy on PR/push only; no `schedule:`
  trigger. A `cron:` + `workflow_dispatch:` addition closes the last named operational gap.
- **`Constitution.md` (Gap SK1/SK2)** — `find . -iname 'constitution*.md'` → 0 results. Needed for
  the traceability claim in `AGENTS.md`.
- **Release ritual** — no tag since `v2.1.0` (2026-09-12) despite three shipped version lines
  (v15, v16, V1-restoration). `semantic-release` is configured (`.releaserc.json`) but inert.
- **Stale state files** — `current_wave.md` still reads "v3.3.0 … Last updated: 2026-08-24";
  `session_checkpoint.json` reads `v15.0.0`, `modules: 146`, `unit 116 / integration 12 / e2e 5`,
  `last_commit: e2ed7fd`. Real counts today: **115 unit `.sh` + 2 unit `.py`, 12 integration, 6 e2e,
  161 modules in `src/lib/`**. `session_checkpoint.json` is now in `.gitignore` — the wave/checkpoint
  ritual was retired with no replacement.
- **Unpushed work** — `origin/main` and `gitverse/main` are **8 commits behind** `099da4ee`, so the
  entire 2026-10-16 V1 runtime restoration exists on exactly one remote.