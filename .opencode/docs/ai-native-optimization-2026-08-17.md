# AI-Native Development System Optimization — Deep Research Report

**Date:** 2026-08-17
**Scope:** `opencode_initializer` (52-module bootstrap harness) + its agent/memory/MCP/routing substrate
**Author:** Planner (research + documentation)
**Method:** local file inspection (cited by path) + 4 external sources fetched and cached to `.opencode/docs/`
**Confidence:** HIGH — all external claims verified against official READMEs/docs fetched this session.

---

## 1. Executive Summary

The machine hosts a **feature-complete but under-optimized** AI-native development system. It already has every major *capability* (model routing, sandboxed agents, plugin harness, quality gates, memory) — but the capabilities are (a) **overlapping and un-unified**, (b) **statically wired** (always-on), and (c) **orphaned** (installed but not invoked by the workflow). This mirrors the prior report's finding (`sdd-coprocessor-analysis-2026-08-16.md`): the problem is not *missing pieces*, it is **missing selection, wiring, and consolidation**.

The five optimization axes break down as:

| Axis | Current State | Primary Gap |
|------|--------------|-------------|
| **Context Management** | 3-tier memory + dual WAL + compaction agent | 5+ competing memory systems; no token budget; no shared-language (`CONTEXT.md`) layer |
| **Task Distribution** | 16+27 agents, swarm models, sandcastle, 3 routing tables | 3 un-unified routing configs; sandcastle/dsh orphaned; no cost-aware dispatch |
| **MCP/LSP Optimization** | 23 MCP servers + 13 LSP, always-on | Zero per-task/per-file-type selection → constant context + startup + token tax |
| **Automation** | pre-session-check, systemd timers, skills auto-invoke | No task→skill routing; dsh plugin hooks unused; manual pre-session |
| **Quality & Reproducibility** | 63 unit + 5 int + 4 e2e, swarm gates, SHA-256 chain | `model-policy.json` allow-all; sandcastle hooks unused for CI; manual docs |

**Central recommendation:** consolidate the three routing tables into one SSOT, introduce **dynamic MCP/LSP selection** (the single highest-leverage context win), and **wire the already-installed harnesses** (dsh, sandcastle) into the lifecycle instead of leaving them installed-but-inert.

---

## 2. Research Sources

| Source | Type | Confidence | Key takeaway for optimization |
|--------|------|-----------|-------------------------------|
| https://github.com/deepseek-ai/deepseek-harness | official README (fetched) | HIGH | "Everything is a plugin" (Cordis) → lifecycle/automation is *composable*, not monolithic. MIT, developer preview (breaking changes). |
| https://github.com/mattpocock/sandcastle | official README (fetched) | HIGH | `sandcastle.run()` = isolated, parallel, branch-strategy, hook-gated agents with structured output & timeouts — a reproducibility primitive. |
| https://github.com/mattpocock/skills | official README (fetched) | HIGH | Anti-process-ownership; 4 failure modes → grilling, shared-language `CONTEXT.md` (token-reducer), feedback loops, deep-module design. User- vs model-invoked split. |
| https://opencode.ai/docs (agents/permissions/tools) | official docs (cached 2026-08-08) | HIGH | `permission` with glob/wildcard (incl. `mymcp_*: deny`), `steps` cap, hidden subagents, `small_model` compaction, per-agent `task` gating. |

Plus local artifacts: `.opencode/architecture.md`, `opencode.json`, `.opencode/opencode-swarm.json`, `scripts/ai-router.json`, `src/lib/36-model-router.sh`, `src/lib/37-wal.sh`, `src/lib/49-deepseek-harness.sh`, `src/lib/50-sandcastle.sh`, `src/lib/pre-session-check.sh`, `.opencode/model-policy.json`.

---

## 3. Current State Analysis

### 3.1 Context Management

**What exists (verified):**
- **3-tier memory hierarchy** — `.opencode/skills/coprocessor/SKILL.md`: WAL → Specs → Artifacts, "artifacts override specs".
- **Dual WAL** — `src/lib/37-wal.sh`: `~/.cache/opencode-setup/wal.md` (setup checkpoint) **and** `~/.cache/opencode/wal.jsonl` (agent journal, SHA-256 hash-chain via `prev_hash`/`hash`).
- **Compaction primitive** — `opencode.json` defines a hidden `compaction` primary agent (`deepseek/deepseek-v4-flash`, `temperature 0.1`) and a `small_model` (`deepseek/deepseek-v4-flash`) used for compaction/summarization.
- **Memory Anchor protocol** — coprocessor `[CTX: domain]` prefix for compaction-safe resumption.

**Key gap:** five memory concepts coexist without one SSOT (coprocessor WAL/Specs/Artifacts; swarm `.swarm/knowledge.jsonl` + evidence; `37-wal.sh` dual WAL; matt-pocock `CONTEXT.md`/ADR; MemoryLayer/Muninn). The matt-pocock shared-language technique — the *single strongest token-reduction lever* (concise domain vocabulary → fewer thinking tokens, consistent names, faster navigation) — is **not applied** to any project (no per-project `CONTEXT.md`).

### 3.2 Task Distribution

**What exists:**
- **Agents**: `opencode.json` → `build`/`plan` (primary), `general`/`explore`/`code-reviewer`/`compaction` (subagents). `.opencode/opencode-swarm.json` → 11 swarm roles mapped to models. `~/.config/opencode/agents/` → 27 `goal-*` review agents.
- **Routing (3 overlapping tables)**:
  1. `src/lib/36-model-router.sh` → `task-profiles.json` (8 profiles: coding/reasoning/fast/agentic/budget/vision/isolated/ru_cn).
  2. `scripts/ai-router.json` → complexity rules (simple/medium/complex) + task routing + agent map.
  3. `.opencode/opencode-swarm.json` → swarm agent→model map.
- **Parallel execution**: swarm lanes (`dispatch_lanes`), sandcastle `run()` for "parallelizing multiple AFK agents" + "review pipelines".

**Key gap:** three routing configs say *different things* (e.g. `ai-router.json` routes `testing` → `xai/grok-4.3`, while swarm maps `test_engineer` → `opencode/gpt-5-nano`, and `36-model-router.sh` has no testing profile). No single source of truth, and **cost data (`cost_per_1k`) is present but not wired to actual dispatch** — routing is advisory, not enforced.

### 3.3 MCP/LSP Optimization

**What exists:** `opencode.json` declares **23 MCP servers** (mostly `type: local`, `enabled: true`; a handful disabled). `src/lib/12-mcp-lsp.sh` installs 24 MCP + 15 plugins + 13 LSP with Bun-bin cold-start paths.

**Key gap (highest-leverage):** MCP/LSP loading is **static and always-on**. Every enabled MCP server's full tool list is injected into the system prompt of *every* session, regardless of task or file type. OpenCode supports per-agent tool gating (`mymcp_*: deny`, glob/wildcard permissions — see `opencode_ai_docs_agents.md`), and `enabled: false` per server — **but neither is used to make selection task- or file-type-aware**. The 13 LSP servers are likewise unconditional.

### 3.4 Automation

**What exists:** `pre-session-check.sh` (provider/model validation, sourced in `.zshrc`); systemd timers + topgrade (`20-autoupdate.sh`); `42-hooks.sh` lifecycle-hook framework; OpenCode skills auto-invoke by `description`; skill auto-acquisition (`npx skills add`).

**Key gap:** there is **no task→skill routing table** (skills auto-trigger purely on description match), **no auto-agent-selection** beyond OpenCode's built-in subagent-description matching, the **dsh "everything-is-a-plugin" hooks are unconfigured** (`49-deepseek-harness.sh` writes an empty `cordis.yml`), and pre-session validation is a manual `.zshrc` source rather than a hook.

### 3.5 Quality & Reproducibility

**What exists:** 63 unit + 5 integration + 4 e2e tests (480+ assertions); CI (ShellCheck + syntax + unit); swarm verification gates (drift/hallucination/mutation/SAST/lint/`pre_check_batch`); `44-audit.sh` SHA-256 hash-chain; `_download_verify()` supply-chain checks; sandcastle lifecycle hooks + per-step timeouts + structured `Output` + completion signals.

**Key gap:** `model-policy.json` is `allow-all` (personal profile) — governance exists but is inert. Sandcastle's **hook-gated, timeout-bounded, structured-output** reproducibility primitives are not used in CI. Documentation (`docs/`) is hand-maintained, not generated.

---

## 4. Gaps & Opportunities (numbered)

- **GAP-1 (HIGH) — Static, always-on MCP/LSP.** 23 MCP + 13 LSP load unconditionally → context bloat, startup latency, token cost. Opportunity: task/file-type-aware selection via `enabled` flags + per-agent `mymcp_*` permissions + LSP enable/disable.
- **GAP-2 (HIGH) — Three un-unified routing tables.** `36-model-router.sh` / `ai-router.json` / `opencode-swarm.json` diverge. Opportunity: one SSOT (`routing.json`) that all three read from.
- **GAP-3 (HIGH) — Cost data not enforced.** `cost_per_1k` present but advisory. Opportunity: wire cost/budget into dispatch + `model-policy.json` `rate_limits`.
- **GAP-4 (MEDIUM) — Harnesses installed-but-inert.** dsh (empty `cordis.yml`) and sandcastle (scaffold only) are not part of any workflow. Opportunity: wire sandcastle into CI reproducibility; configure dsh plugin hooks for automation.
- **GAP-5 (MEDIUM) — No shared-language `CONTEXT.md` layer.** matt-pocock's top token-reduction technique absent. Opportunity: generate per-project `CONTEXT.md` at init (`17-project.sh` / `41-constitution.sh`).
- **GAP-6 (MEDIUM) — Memory SSOT unresolved.** (Carries over from prior report GAP-5.) Opportunity: one authoritative memory layout doc.
- **GAP-7 (LOW-MEDIUM) — Manual pre-session & docs.** pre-session is `.zshrc`-sourced; docs hand-written. Opportunity: hook-based pre-session + docs generation from module tables.

---

## 5. Implementation Recommendations

### R1 — Single SSOT routing table (closes GAP-2, GAP-3)
Create `src/data/routing.json` as the canonical source; make `36-model-router.sh`, `scripts/ai-router.sh`, and swarm config all read/derive from it. Add a `testing` profile (currently missing) and enforce `rate_limits` from `model-policy.json`. Reconcile the `testing → xai/grok-4.3` vs `test_engineer → gpt-5-nano` divergence.

### R2 — Dynamic MCP/LSP selection (closes GAP-1, highest leverage)
Add a per-task MCP/LSP manifest (`src/data/mcp-profiles.json`) mapping task types/file types → required MCP servers + LSPs, and generate per-project `opencode.json` with correct `enabled` flags + per-agent `mymcp_*` permissions (using OpenCode's documented glob/wildcard gating). Leave heavyweight servers (`chrome-devtools`, `playwright`, `excalidraw`) disabled-by-default and enable only for UI/diagram tasks.

### R3 — Wire harnesses into the lifecycle (closes GAP-4)
- **Sandcastle → CI reproducibility:** add a `.github/workflows/sandcastle-review.yml` (or `dev sandcastle review`) that runs `sandcastle.run()` implement→review on a branch with lifecycle hooks + timeouts, gating merge on the review result.
- **dsh → automation:** populate `cordis.yml` with a starter plugin set (pre-session-check, PII guard, WAL checkpoint) so "everything is a plugin" is actually exercised.

### R4 — Per-project shared-language `CONTEXT.md` (closes GAP-5)
Extend `17-project.sh` (or `41-constitution.sh`) to generate a starter `CONTEXT.md` (domain glossary) at project init; document the `grill-with-docs`/`domain-modeling` flow as the way to grow it. This is the single highest token-efficiency win per matt-pocock.

### R5 — Consolidate memory SSOT (closes GAP-6)
Document ONE authoritative layout in `.opencode/docs/memory-hierarchy.md`: Artifacts > `.swarm/spec.md` + `.swarm/knowledge.jsonl` > agent WAL (`~/.cache/opencode/wal.jsonl`); classify `CONTEXT.md`/ADR (matt-pocock), setup WAL, and Muninn/MemoryLayer as *feeding* layers, not competing truths.

### R6 — Hook-based pre-session + docs generation (closes GAP-7)
Wrap `pre-session-check.sh` as an OpenCode/`42-hooks.sh` pre-session hook (auto, not manual `.zshrc`); add a `dev docs` generator that derives RU/EN tables from module headers.

---

## 6. Integration Strategy (phased)

| Phase | Deliverable | Depends on | Risk |
|-------|-------------|-----------|------|
| **P0 — SSOT routing** | `src/data/routing.json` + refactor 3 readers | — | Low (additive; keep old files as thin shims) |
| **P1 — Dynamic MCP/LSP** | `mcp-profiles.json` + `opencode.json` generator honoring `enabled`/permissions | P0 | Medium (must not break 23-server baseline; keep `full` mode = all-on) |
| **P2 — Harness wiring** | sandcastle CI workflow + dsh `cordis.yml` starter | — (independent) | Low |
| **P3 — Shared language** | `CONTEXT.md` generator + memory SSOT doc | — (independent) | Low |
| **P4 — Automation** | hook-based pre-session + docs generator | P1, P3 | Low |

P0 and P2/P3 are independent and can proceed in parallel; P1 depends on P0; P4 depends on P1/P3. Each phase is testable in isolation (bash unit tests for generators, syntax + dry-run for CI workflow).

---

## 7. Files Cited

- `.opencode/skills/coprocessor/SKILL.md` — 3-tier memory + memory-anchor protocol
- `.opencode/architecture.md` — service graph (16 agent roles, 21 MCP, migration CI)
- `opencode.json` — 23 MCP servers, agents, `compaction`/`small_model` (lines 3-4, 477-660, 668-740)
- `.opencode/opencode-swarm.json` — 11 swarm agent→model mappings
- `.opencode/model-policy.json` — `allow-all` / personal profile
- `scripts/ai-router.json` / `scripts/ai-router.sh` — complexity + task routing
- `src/lib/36-model-router.sh` — 8 task profiles (`task-profiles.json`)
- `src/lib/37-wal.sh` — dual WAL + SHA-256 hash-chain
- `src/lib/49-deepseek-harness.sh` — dsh install + empty `cordis.yml`
- `src/lib/50-sandcastle.sh` — sandcastle install/scaffold/provider-detect
- `src/lib/12-mcp-lsp.sh` — 24 MCP + 15 plugins + 13 LSP install
- `src/lib/pre-session-check.sh` — manual provider/model validation
- `.opencode/docs/github_com_deepseek-ai_deepseek-harness.md` (fetched)
- `.opencode/docs/github_com_mattpocock_sandcastle.md` (fetched)
- `.opencode/docs/github_com_mattpocock_skills.md` (fetched)
- `.opencode/docs/opencode_ai_docs_agents.md` (cached) — permissions/glob/wildcard gating
- `.opencode/docs/sdd-coprocessor-analysis-2026-08-16.md` — prior framework report (gaps still open)
