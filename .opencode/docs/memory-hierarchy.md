# Memory Hierarchy — Single Source of Truth

**Date:** 2026-08-17
**Scope:** one authoritative memory layout across the `opencode_initializer` substrate (coprocessor, swarm, setup WAL, matt-pocock, Muninn/MemoryLayer).
**Confidence:** HIGH — every path below is cited from the actual source file.

---

## 1. The problem

Five memory concepts coexist without one authoritative order (GAP-5/GAP-6 in
`.opencode/docs/ai-native-optimization-2026-08-17.md`):

1. coprocessor WAL → Specs → Artifacts (3-tier)
2. swarm `.swarm/spec.md` + `.swarm/knowledge.jsonl` + evidence
3. `37-wal.sh` dual WAL (setup checkpoint + agent journal)
4. matt-pocock `CONTEXT.md` / ADR
5. Muninn / MemoryLayer semantic stores

When these disagree, an agent has no rule for which one wins. This document
fixes that: it declares **one** precedence order and classifies the rest as
*feeding* layers.

---

## 2. The authoritative hierarchy (precedence, highest first)

| Tier | Location | What it holds | Wins when |
|------|----------|---------------|-----------|
| **0 — Artifacts** | source code, tests, configs (the repo tree) | the actual, executed truth | always — "artifacts override specs" |
| **1 — Spec** | `.swarm/spec.md` | the settled intent (FR-###/SC-###) | when code is ambiguous about *what was meant* |
| **2 — Knowledge** | `.swarm/knowledge.jsonl` | durable, reviewed lessons (curator-promoted) | when reasoning about *how to work*, not *what is true* |
| **3 — Agent WAL** | `~/.cache/opencode/wal.jsonl` | per-session journal (SHA-256 hash-chain) | never over tiers 0–2; it is a log, not a truth |

Rationale (from `src/lib/37-wal.sh` and `.opencode/skills/coprocessor/SKILL.md`):

- **Artifacts are ground truth.** The coprocessor rule is explicit: "Prefer
  reading from artifacts over spec when a conflict exists. Update specs when
  artifacts change." Code that *runs* is the highest authority because it is
  what actually executes, regardless of what any doc claims.
- **Spec is intent, not implementation.** `.swarm/spec.md` records *what was
  decided to build*. It is authoritative for *intent* questions ("why does this
  exist") and subordinate for *reality* questions ("what does it actually do").
- **Knowledge is curated experience.** `.swarm/knowledge.jsonl` holds
  reviewer/curator-promoted lessons. It guides *process*, never overrides the
  artifact a lesson is about.
- **WAL is append-only memory.** `~/.cache/opencode/wal.jsonl` is the coprocessor
  "WAL" tier — a session journal, hash-chained for tamper-evidence
  (`prev_hash`/`hash`, `src/lib/37-wal.sh:63`). It is the *most volatile* and
  therefore the *weakest* authority.

---

## 3. Feeding layers (NOT competing truths)

These layers *inform* the hierarchy above but never contradict it. When they
disagree with tiers 0–2, tiers 0–2 win.

| Layer | Location | Role | Cited from |
|-------|----------|------|-----------|
| **CONTEXT.md / ADR** | `<project>/CONTEXT.md`, `<project>/docs/adr/` | shared-language domain glossary + decisions; token-reduction lever | `.opencode/skills/matt-pocock/domain-modeling/SKILL.md` |
| **Specs (coprocessor)** | `docs/specs/` | persistent design docs (coprocessor "Specs" tier) | `.opencode/skills/coprocessor/SKILL.md:21` |
| **Setup WAL** | `~/.cache/opencode-setup/wal.md` | bootstrap progress checkpoint (DONE: N/M modules) | `src/lib/37-wal.sh:7` |
| **Muninn / MemoryLayer** | ChromaDB / MemoryLayer stores | semantic recall for resumption and cross-session context | `AGENTS.md` (Muninn MCP) |

Key distinction:

- **`CONTEXT.md`/ADR are a *dictionary*, not a *ledger*.** They define
  vocabulary and record decisions so every session reasons with the same words.
  They reduce tokens; they do not adjudicate facts. Grown lazily via
  `grill-with-docs` / `domain-modeling` (see §5).
- **The setup WAL is a *resume cursor*.** `~/.cache/opencode-setup/wal.md`
  tracks which of the 46+ modules finished, so a re-run can resume. It is
  machine-managed (`src/lib/37-wal.sh:29`) and irrelevant to domain truth.
- **Muninn/MemoryLayer are *retrieval caches*.** They surface "what did we
  decide last time" for a fast start, but any recalled fact must be re-verified
  against tiers 0–1 before acting on it.

---

## 4. Resolution rule (single sentence)

> If two layers disagree, the **lower-numbered tier in §2** wins, and the losing
> layer is treated as stale and updated to match — never the reverse.

Applied examples:

- Artifact says partial cancellation exists; `CONTEXT.md` says it doesn't →
  trust the artifact, fix `CONTEXT.md` (and add/update an ADR).
- `.swarm/spec.md` says "FR-007 test coverage"; code has no tests → spec is the
  intent, code is incomplete (spec wins for *intent*, code wins for *reality*).
- `~/.cache/opencode/wal.jsonl` recalls a decision that contradicts the artifact
  → the artifact is right; the WAL entry is historical context only.

---

## 5. How to grow the shared-language layer

Per matt-pocock `domain-modeling`, `CONTEXT.md` is created at project init
(`src/lib/17-project.sh`) and grown *lazily*:

1. When a term is used ambiguously, sharpen it to one canonical term.
2. Write it into `CONTEXT.md` the moment it crystallises.
3. Record any hard-to-reverse decision as an ADR under `docs/adr/`
   (`0001-….md` naming, see `domain-modeling/SKILL.md` §File structure).

The `grill-with-docs` skill drives the interview that produces both glossary
entries and ADRs in one pass.

---

## 6. Files cited

- `src/lib/37-wal.sh` — dual WAL paths + SHA-256 hash-chain
- `.opencode/skills/coprocessor/SKILL.md` — 3-tier memory + "artifacts override specs"
- `.opencode/skills/matt-pocock/domain-modeling/SKILL.md` — CONTEXT.md/ADR file structure
- `.swarm/spec.md` — settled spec (FR-###/SC-###)
- `.swarm/knowledge.jsonl` — curated knowledge
- `src/lib/17-project.sh` — CONTEXT.md generation at init
- `.opencode/docs/ai-native-optimization-2026-08-17.md` — GAP-5/GAP-6 origin
