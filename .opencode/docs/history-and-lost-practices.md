# History and Lost Practices — opencode_initializer

> Generated 2026-10-16 by research subagent (read-only archaeology over git, docs, branches,
> the second workspace copy, and clobbered config backups). Verified with reproducible commands.

## 1. Timeline — 528 commits, 8 tags, 10 refs

`main` HEAD `0694cf12` (2026-10-16); first commit `9c853aa4` (2026-06-22); 419 commits on `main`,
526 across all refs.

| Phase | Window | Anchor commits | What happened |
|---|---|---|---|
| v33.x → v36.0.1 | 2026-06-05 … 06-22 | early lineage | first-generation product (version-tag churn) |
| v1.0.x line | mid-2026 | tag `v1.0.1` | first stable release line |
| v2.x | 2026-07 | tag `v2.1.0` | config generation matured |
| v4 … v14 | 2026-07 … 09-12 | `035b33e0` (pre-cleanup snapshot) | feature accumulation; 73-file corpus still recoverable here |
| **THE CLEANUP** | 2026-09-14 | `edae11b3` | mass deletion — source of most "lost" material |
| v15 rebirth (planning) | 2026-09-15 | `ff1bfd0e` … `7858c3df` | planning docs written before code |
| v15 execution Phases 0–6 | 2026-09-16 | 55 modules committed in one day | the 64-module `src/lib/` tree |
| 8-wave transformation | 2026-09 … 10-02 | `c9db6c59` (Software Factory v16) | Wave 7 "Plugin system" left **PENDING**; `node_modules/` accidentally committed (11 179 files) |
| Wave integration + git hygiene | 2026-10-12 | `2b8726ff` | 11 wave modules + `discipline/` + `specs/` imported from `workspace (1)`; 2.8M lines of `node_modules` untracked |
| dev.sh / CI perf + fixes | 2026-10-12 | `6894fca6`, `c1273501`, `6924cad9`, `ca1d07af` | non-TTY mirror-skip, `VC_BUDGET` 25s, test timeouts |
| hygiene | 2026-10-12 | `fa859587`, `0f6239bd` | stale skill stubs removed, bounded network probes |
| config alignment | 2026-10-12 | `099da4ee` | MCP/plugin modernization, agent permission inheritance |
| 1M-context policy | 2026-10-12 | `78ed7c14` | `limit.context = 1_000_000`, compaction ≥50% |
| autonomy policy | 2026-10-12 | `b4e4ae92` | swarm gates off in all 11 projects |
| **V1 runtime restoration** | 2026-10-16 | `319a88f9` → `0694cf12` | V2 rejected every V1 plugin; reverted to V1 (which *is* npm `latest` 1.19.x) |
| context-1m fix | 2026-10-16 | `e3748415`, `2ee4e3c6`, `0694cf12` | correct V1 DCP package, plugin/MCP pinning, retired deprecated servers |

## 2. Lost practices and abandoned ideas

### B1 — The "unmerged" branches are fully merged (premise falsified)
`git log main..backup/v1.0.1-reliability-hardening` → **0 commits**; same for
`archive/pre-cleanup-v14`. Both are ancestors of `main` (128 and 397 commits behind).
`--diff-filter=D` on the backup branch → 0. **Their value is as a snapshot**: the 73 files
deleted by the cleanup are recoverable with `git show archive/pre-cleanup-v14:<path>`.

### B2 — `workspace (1)` is already integrated
`diff -r specs/discipline` → identical to `main`; all three of its branches were absorbed in
`2b8726ff`. Its unique residue is the pre-cleanup `.opencode/` corpus (30+ research/audit/synthesis
docs plus a 61 746 B `work-log.md`).

### B3 — 13 Software Factory modules are inert (**highest-value loss**)
`setup.sh:969-979` only `source`s them — **zero `_run_step` calls out of 57 steps**. Nine have no tests.
`calculate_maintainability_score .` **crashes**:
```
line 120: 3.00: arithmetic syntax error
line 190: 0\n0
line 245
SCORE: /100      exit 3
```
while `TRANSFORMATION_COMPLETE_SUMMARY.md:212` claims *"Score: 78, CI gate blocks merge < 70"*.
CI contains **no** reference to `maintainability`; `dev.sh` has no `debt`/`intent`/`spec` command.
`33-spec-registry.sh list` fails with `log_warn: command not found`.

### B4 — Plan checkboxes never tracked reality
103 `[ ]` and **0 `[x]`** across three plan documents, although most of the work shipped.

### B5 — Lost config fragments (recoverable from backups)
| Fragment | Where | Value |
|---|---|---|
| `moonshotai` provider | `~/.config/opencode/opencode.json.custom-bak` | the **only** model in the system with `limit.context: 1000000` (`kimi-k3`) — the empirical basis of the 1M policy adopted 4 days later; absent from `src/data/providers.json` |
| `tui` block | `opencode.json.clobbered-by-tests-163634` | terminal overlays — the live config has no `tui` key at all |
| 6 `experimental` perf flags | same backup | live config retained only 2 keys |
| `mcp.websearch` | same backup | `mcp-searxng` + `SEARXNG_URL=http://localhost:8888` |
| 13 plugin entries | same backup | no longer referenced by any config |

### B6 — 10 planned Python companion scripts never shipped
`skill-registry.py`, `workflow-runner.py`, `audit-analyzer.py`, … — planned in the v15 docs,
never implemented, while 58 shell modules were written instead.

## 3. Root cause of the config losses
No schema-aware merge layer for `~/.config/opencode/opencode.json`: 22 loose `.bak-*` files
accumulated and 5 different scripts rewrite the file wholesale. Every rewrite is a chance to
silently drop fragments (that is how the `moonshotai`, `tui`, `experimental`, and `websearch`
blocks were lost in the first place).

## 4. TOP-5 restoration list (value ÷ effort)

| # | Action | Source | Value | Effort |
|---|---|---|---|---|
| 1 | **Revive the 13 inert modules** + fix the arithmetic in `45-maintainability-score.sh` | B3 | HIGH | S |
| 2 | **Schema-aware merge + mandatory backup** for the global config | §3 | HIGH | S |
| 3 | **Return `moonshotai` (1M) into `src/data/providers.json`** | B5 | HIGH | XS |
| 4 | Recover the August research corpus from `035b33e0` / `archive/pre-cleanup-v14` | B1/B2 | MED-HIGH | XS |
| 5 | Re-open the 103 plan checkboxes + add `check-plan-sync.sh` | B4 | MED | S |

## Evidence
`git log --oneline --all | wc -l` → 526 · `git branch -a` → 10 refs · `git log main..archive/pre-cleanup-v14` → empty ·
`bash -c 'source src/lib/33-spec-registry.sh; <list call>'` → `log_warn: command not found` ·
`TRANSFORMATION_COMPLETE_SUMMARY.md:212` vs actual `calculate_maintainability_score` exit 3.