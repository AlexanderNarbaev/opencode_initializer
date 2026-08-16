# SDD & AI Coprocessor Framework Analysis

**Date:** 2026-08-16
**Scope:** opencode_initializer project + all sibling projects under `/home/alexandr-narbaev/Projects/`
**Author:** Planner (research + documentation)
**Confidence:** HIGH (all claims verified against files on disk, cited by path)

---

## 1. Executive Summary

The `opencode_initializer` project hosts a **mature, but under-propagated, Specification-Driven Development (SDD) framework** built on top of the `opencode-swarm` plugin. The framework is realized as ~26 `MODE` skills (the *workflow layer*) plus one `coprocessor` skill (the *reasoning-protocol layer*).

**The central finding:** the framework is comprehensive *inside* this repository but exists in **isolation**. An accepted ADR (`docs/architecture/adr/2026-07-18-multi-agent-framework-v3.md`) declares this framework "the operating model for all projects under `~/Projects/`" — yet all 8 sibling projects carry only 4 generic skills and **zero** of the SDD/coprocessor skills. The ADR decision has not been executed.

**Second finding:** there are **four overlapping spec/SDD frameworks** active on this machine with no decision guide telling an agent (or human) which to use when.

---

## 2. Current State — What Exists

### 2.1 The Coprocessor (reasoning-protocol layer)

`.opencode/skills/coprocessor/SKILL.md` — a universal behavioral protocol that wraps every agent's reasoning:

| Protocol | Purpose |
|----------|---------|
| **Dual-Process Reasoning** | System 1 (fast edits) vs System 2 (slow analysis); escalate after 2 failures / >3 files / >30% uncertainty. Tag `#S1`/`#S2`. |
| **3-Tier Memory Hierarchy** | WAL (`~/.cache/opencode/wal.jsonl`) → Specs (`docs/specs/`) → Artifacts (code/tests). Artifacts override specs. |
| **Shared State = IPC** | Files are the communication protocol. Read-before-act, verify-after-write. `.opencode/state/` for inter-agent coordination. |
| **Keyboard Auto-Correction** | RU↔EN layout mismatch (`руддщ`→`hello`). Silent on read, confirm ambiguous, log `[KB]`. |
| **CO-STAR Output Contract** | Context → Objective → Steps → Thinking → Answer → References. Skip for trivial. |
| **Memory Anchor Protocol** | Every response starts `[CTX: domain]` for compaction-safe resumption. |
| **Source Ladder** | Official docs `[L1]` → authoritative secondary `[L2]` → encyclopedias `[L3]` → model knowledge `[L4]`. |
| **Hard Gates** | No secrets; never delete un-understood code; never skip WAL; `[speculative]` tag < 80% confidence. |

### 2.2 The SDD Lifecycle (workflow layer)

26 `MODE` skills under `.opencode/skills/`, each "loaded on demand by the architect stub in `src/agents/architect.ts`" (the opencode-swarm plugin). The canonical lifecycle:

```
DISCOVER → CLARIFY → BRAINSTORM → SPECIFY → CLARIFY-SPEC → PLAN
  → CRITIC-GATE → EXECUTE → PHASE-WRAP  (→ LOOP, repeat with compounding)
```

| Mode | Skill file | Core function |
|------|-----------|----------------|
| DISCOVER | `discover/SKILL.md` | Read-only repo discovery + governance mapping (`project-instructions.md`, `CONTRIBUTING.md`) |
| CLARIFY | `clarify/SKILL.md` | 4-stage clarification funnel (inventory → classify → critic sounding board → decision packet) |
| BRAINSTORM | `brainstorm/SKILL.md` | 7-phase structured dialogue for fuzzy requirements |
| SPECIFY | `specify/SKILL.md` | Spec generation (FR-###/SC-###, WHAT/WHY only) + mandatory QA-gate dialogue |
| CLARIFY-SPEC | `clarify-spec/SKILL.md` | Resolve `[NEEDS CLARIFICATION]` markers one-at-a-time |
| PLAN | `plan/SKILL.md` | Task decomposition, granularity rules, traceability, QA-gate persistence |
| CRITIC-GATE | `critic-gate/SKILL.md` | Independent plan review before execution (APPROVED/NEEDS_REVISION/REJECTED) |
| EXECUTE | `execute/SKILL.md` | 20-step per-task QA pipeline (diff→syntax→placeholder→imports→lint→build→pre_check_batch→reviewer→test_engineer→regression-sweep→test-drift) |
| PHASE-WRAP | `phase-wrap/SKILL.md` | Retrospective + drift/hallucination/mutation gates + phase_complete |
| PRE-PHASE-BRIEFING | `pre-phase-briefing/SKILL.md` | Read prior retrospective + CODEBASE REALITY CHECK (fanned-out explorer lanes) |
| RESUME | `resume/SKILL.md` | Safe continuation from `.swarm/plan.md` |
| LOOP | `loop/SKILL.md` | Compound engineering loop (brainstorm→plan→build→review→improve) with 6 stop conditions |
| CONSULT | `consult/SKILL.md` | SME advisory (max 3/phase) |
| COUNCIL | `council/SKILL.md` | 3-agent General Council (generalist/skeptic/domain expert) |
| DEEP_DIVE | `deep-dive/SKILL.md` | Read-only codebase audit (parallel explorers → 2 reviewers → critic) |
| DEEP_RESEARCH | `deep-research/SKILL.md` | Cited external research (retrieval loop → sme synthesis → dual review → critic) |
| DESIGN_DOCS | `design-docs/SKILL.md` | Language-agnostic design docs (domain/technical-spec/behavior-spec + traceability) |
| ISSUE_INGEST | `issue-ingest/SKILL.md` | GitHub issue → localized root cause → spec |
| COMMIT-PR | `commit-pr/SKILL.md` | 12-invariant audit + release fragments + validation suite + PR lifecycle |
| SWARM-PR-REVIEW / SWARM-PR-FEEDBACK | `swarm-pr-*` | Graph-guided PR review + feedback resolution |
| RUNNING-TESTS / WRITING-TESTS | `running-tests`, `writing-tests` | Test execution safety + authoring guidance |
| ENGINEERING-CONVENTIONS | `engineering-conventions/SKILL.md` | 12 non-negotiable invariants for opencode-swarm internals |

**Persisted state:** `.swarm/` directory (`spec.md`, `plan.json`, `plan.md`, `context.md`, `knowledge.jsonl`, `evidence/`, `session/`, `loop/`).

### 2.3 The matt-pocock Toolkit (17 skills)

A complementary, lighter-weight SDD flow under `.opencode/skills/matt-pocock/`:

- **Spec side:** `to-spec` (conversation → spec → issue tracker), `to-tickets` (spec → tracer-bullet tickets with blocking edges), `wayfinder` (huge work → decision-ticket map).
- **Design side:** `codebase-design`, `domain-modeling` (CONTEXT.md + ADR + glossary), `improve-codebase-architecture`.
- **Build side:** `tdd` (red→green loop + seams), `implement`, `prototype`.
- **Review side:** `code-review`, `diagnosing-bugs`, `grilling`/`grill-me`/`grill-with-docs`, `resolving-merge-conflicts`, `research`, `wizard`.

### 2.4 Two Parallel Global Skill Ecosystems (`~/.config/opencode/skills/`)

| Ecosystem | Skills | Origin / orientation |
|-----------|--------|----------------------|
| **superpowers** (14) | brainstorming, writing-plans, executing-plans, subagent-driven-development, test-driven-development, systematic-debugging, verification-before-completion, requesting/receiving-code-review, dispatching-parallel-agents, using-git-worktrees, finishing-a-development-branch, writing-skills, using-superpowers | Claude Code origin, generic agent hygiene |
| **smixs** (13) | disruptor (meta-orchestrator), designing-with-7w3, write-spec, slicing-into-tracer-bullets, delivering-mvp-fleet, converging-and-polishing, unvibe-review, spawning-reviewers, architecture-guardrails, qa-demo-stand, setup-server, setting-up-domain-model, + mentor, humanizer-ru | Idea→production pipeline |

### 2.5 The "constitution" step (from AGENTS.md, not wired)

AGENTS.md line 24 declares the v3.0 SDD lifecycle as `constitution → specify → clarify → plan → tasks → implement → verify → converge`. The `constitution` step is implemented by `src/lib/41-constitution.sh`, which generates `memory/constitution.md` at project init. **But none of the MODE skills reference `constitution.md`** (verified by grep — zero matches). The step exists in the setup layer and in generated docs, but is disconnected from the swarm workflow.

---

## 3. Gaps & Improvement Opportunities

### GAP-1 — ADR not executed (CRITICAL)
`docs/architecture/adr/2026-07-18-multi-agent-framework-v3.md` mandates the framework for all `~/Projects/`, but sibling projects have only 4 generic skills (`code-review-checklist`, `context-switching`, `deployment-checklist`, `testing-strategy`). No SDD, no coprocessor.

### GAP-2 — Four overlapping frameworks, no selection guide (HIGH)
`coprocessor` / `swarm MODE` / `matt-pocock` / `superpowers` / `smixs` all define "spec", "plan", "brainstorm", "TDD" differently:
- swarm `spec.md` (FR/SC, WHAT-only) vs matt-pocock spec (Problem/Solution/User Stories/Implementation Decisions) vs 7w3 `write-spec` vs superpowers `writing-plans`.
- No document answers "which framework for which project/task type."

### GAP-3 — Coprocessor is orphaned (MEDIUM-HIGH)
`grep -rl "CO-STAR\|\[CTX:\]\|coprocessor\|Memory Anchor\|Source Ladder" .opencode/skills/` returns **only** `coprocessor/SKILL.md`. The reasoning protocol is defined but not invoked by any MODE skill or the architect prompt. Its memory hierarchy (`docs/specs/`) also diverges from the swarm's (`.swarm/spec.md`) and matt-pocock's (`CONTEXT.md` + ADRs).

### GAP-4 — Constitution disconnected (MEDIUM)
The `constitution → …` lifecycle in AGENTS.md has no skill-side counterpart. `41-constitution.sh` writes the file; nothing reads it in the workflow (PRE-PHASE-BRIEFING or DISCOVER should load it as a governance source).

### GAP-5 — Competing memory systems (MEDIUM)
At least five distinct "memory" concepts coexist: coprocessor WAL/Specs/Artifacts; swarm `.swarm/knowledge.jsonl` + evidence; 37-wal.sh dual WAL (`~/.cache/opencode-setup/wal.md` + `~/.cache/opencode/wal.jsonl`); matt-pocock CONTEXT.md/ADR; MemoryLayer (Muninn) skills. No single source of truth documented.

### GAP-6 — No machine-level propagation mechanism (MEDIUM)
The project has `scripts/sync-agents.py`, `scripts/sync-providers.py`, `99-upstream-sync.sh` — but no equivalent for **skills**. The cross-project sync plan (`docs/plans/2026-07-18-cross-project-sync-plan.md`) tracks `opencode.json` + `AGENTS.md` presence, not skills.

### GAP-7 — Skill mirror drift risk (LOW-MEDIUM)
`engineering-conventions/SKILL.md` documents a `.opencode`↔`.claude` mirror contract for swarm skills, but the global ecosystems (superpowers, smixs) and sibling projects have no such contract — drift between machine-wide and per-project skills is unmanaged.

---

## 4. Recommendations — Applying to All Projects on This Machine

### R1 — Execute the ADR: tiered framework propagation

Adopt a **three-tier** propagation model, matching the projects' activity level from the cross-project sync plan:

| Tier | Projects | What they get |
|------|----------|---------------|
| **T1 — Full SDD** | opencode_initializer, opora, agi, rag-system | Full swarm MODE skills + coprocessor + matt-pocock + `.swarm/` |
| **T2 — Coprocessor-only** | opora-landing, ThePath, expert_profile | `coprocessor` + `AGENTS.md` governance + `memory/constitution.md`; swarm MODE optional |
| **T3 — Passive** | DeepSeek, AlexandrNarbaev, rag-system-bak | `AGENTS.md` + `coprocessor` only (no `.swarm/`) |

**Mechanism:** extend the existing `99-upstream-sync.sh` / `scripts/sync-agents.py` pattern with a `sync-skills.py` that copies the canonical `.opencode/skills/` from `opencode_initializer` into sibling projects' `.opencode/skills/`, honoring a per-project manifest (like the `.claude`↔`.opencode` mirror contract in `src/config/skill-mirrors.ts`).

### R2 — Write a "Framework Selection Matrix" (one canonical doc)

Create `docs/framework-selection.md` (or `.opencode/docs/`) mapping scenario → framework:

| Scenario | Use |
|----------|-----|
| Multi-phase, gated, review-heavy feature in an active repo | swarm MODE lifecycle (`/swarm`) |
| Fuzzy idea needing dialogue before spec | swarm BRAINSTORM, or smixs `designing-with-7w3` |
| Quick spec→tickets for a tracker-driven team | matt-pocock `to-spec` → `to-tickets` |
| Standalone reasoning hygiene on any task | `coprocessor` (always-on) |
| Read-only audit / external research | swarm DEEP_DIVE / DEEP_RESEARCH |
| Idea→shipping product pipeline | smixs `disruptor` |

This collapses the four frameworks into one decision path.

### R3 — Wire the Coprocessor into the MODE skills

Add to each MODE skill's preamble (or the architect stub) a single line: *"Outputs follow the coprocessor protocol: `[CTX: domain]` anchor, CO-STAR for non-trivial answers, `[L1-L4]` source tags."* This makes the reasoning layer load-bearing instead of orphaned, and aligns the memory-anchor protocol with the swarm's `.swarm/context.md`.

### R4 — Wire `constitution.md` into the lifecycle

In `discover/SKILL.md` and `pre-phase-briefing/SKILL.md`, add `memory/constitution.md` to the governance-file scan (alongside `project-instructions.md`/`CONTRIBUTING.md`). This closes the `constitution → specify → …` loop declared in AGENTS.md.

### R5 — Consolidate the memory hierarchy

Document ONE authoritative layout: **Artifacts (code/tests) > `.swarm/spec.md` + `.swarm/knowledge.jsonl` (specs/decisions) > WAL (`~/.cache/opencode/wal.jsonl`, session journal)**. Mark `docs/specs/` (coprocessor) and `CONTEXT.md`/ADR (matt-pocock) as *project-documentation* layers that feed the spec, not competing truths.

### R6 — Add a skill mirror contract for global skills

Extend `src/config/skill-mirrors.ts` (or a lighter manifest) to cover the global `superpowers` and `smixs` ecosystems, so `bun run drift:check` can detect when a project-local skill shadows or diverges from a global one.

---

## 5. Files Cited

- `.opencode/skills/coprocessor/SKILL.md` — reasoning protocol (79 lines)
- `.opencode/skills/{discover,clarify,brainstorm,specify,clarify-spec,plan,critic-gate,execute,phase-wrap,pre-phase-briefing,resume,loop,consult,council,deep-dive,deep-research,design-docs,issue-ingest,commit-pr,swarm-pr-review,swarm-pr-feedback,running-tests,writing-tests,engineering-conventions}/SKILL.md` — SDD lifecycle
- `.opencode/skills/matt-pocock/{wizard,to-spec,to-tickets,tdd,codebase-design,domain-modeling,implement,wayfinder,research,prototype,grill-me,code-review,diagnosing-bugs,improve-codebase-architecture,resolving-merge-conflicts,grilling,grill-with-docs}/SKILL.md` — matt-pocock toolkit
- `docs/architecture/adr/2026-07-18-multi-agent-framework-v3.md` — the unexecuted ADR
- `docs/architecture/adr/2026-07-18-hybrid-ai-architecture.md`
- `docs/plans/2026-07-18-cross-project-sync-plan.md` — cross-project sync
- `src/lib/41-constitution.sh` — constitution generator
- `src/lib/37-wal.sh` — dual WAL definitions
- `~/.config/opencode/skills/{superpowers,smixs}/` — global ecosystems
- `~/.config/opencode/agents/` — 27 goal-* review agents
- Sibling projects' `.opencode/skills/` (agi, ThePath, opora, rag-system, opora-landing, expert_profile) — only 4 generic skills each
