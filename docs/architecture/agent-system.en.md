# Agent System Architecture

## Overview

The opencode_initializer agent system implements the **Universal AI Coprocessor** pattern with 15 specialized agents orchestrated through a shared-state IPC model. Each agent carries a `[CTX: domain]` memory anchor for context resumption after compaction.

## Agent Taxonomy

### Primary Agents (autonomous, with full tool access)

| Agent | [CTX] | Role | Reasoning | Model |
|-------|-------|------|-----------|-------|
| **build** | build | Code generation, editing, refactoring | S1 / S2 | deepseek-v4-pro |
| **plan** | plan | Architecture, planning, design | S2 only | glm-5.2 |
| **compaction** | compact | Context summarization, pruning | S1 | deepseek-v4-flash |

### Subagent Workers (task-dispatched, read-scoped or write-scoped)

| Agent | [CTX] | Role | Reasoning | Model |
|-------|-------|------|-----------|-------|
| **general** | general | General-purpose task handling | S1 / S2 | deepseek-v4-pro |
| **explore** | explore | Read-only codebase exploration | S1 | deepseek-v4-flash |
| **scout** | scout | Fast symbol/file/pattern discovery | S1 | deepseek-v4-flash |
| **researcher** | research | Web search, documentation lookup | S1 | deepseek-v4-flash |
| **code-reviewer** | review | Code quality, deprecation, API checks | S2 | glm-5.2 |
| **reviewer** | review | Adversarial bug/regression review | S2 | glm-5.2 |
| **security-auditor** | security | Secrets, injection, port scanning | S2 | deepseek-v4-pro |
| **test-engineer** | test | Test authoring, edge cases, TDD | S1 | deepseek-v4-flash |
| **critic** | critic | Devil's advocate, contradiction detection | S2 | deepseek-v4-pro |
| **sme** | sme | Domain expertise, citation sourcing | S2 | deepseek-v4-flash |
| **docs** | docs | Documentation writing, verification | S1 | deepseek-v4-flash |
| **orchestrator** | orch | Task decomposition, parallel dispatch | S2 | glm-5.2 |

## Dual-Process Mapping

### System 1 (Fast — pattern match, latency < 5s)

System 1 agents handle single-file edits, grep/glob searches, symbol lookups, and template-based output. They operate with `temperature: 0.1` and `deepseek-v4-flash` for minimal latency.

- **build** (simple edits) — CO-STAR output, atomic edits
- **compaction** — preserve key decisions, discard redundant context
- **explore** — read-only grep/glob/codegraph discovery
- **scout** — fast file/symbol/pattern finding
- **researcher** — web search, docs fetch, source citation
- **test-engineer** — test generation, edge case coverage
- **docs** — documentation generation, command verification

### System 2 (Slow — methodical, unbounded)

System 2 agents handle multi-file refactors, dependency analysis, architectural decisions, adversarial review, and novel design. They operate with `temperature: 0.1–0.3` and `deepseek-v4-pro`/`glm-5.2`.

- **plan** — dependency analysis, architecture proposals, Source Ladder claims
- **build** (complex edits >3 files) — multi-file refactoring
- **general** (complex tasks) — delegated investigation
- **code-reviewer** — API contract verification, deprecation flags
- **reviewer** — bug hunting, regression analysis, file:line references
- **security-auditor** — injection vectors, secrets scanning
- **critic** — assumption challenging, confidence rating
- **sme** — deep domain expertise, authoritative sourcing
- **orchestrator** — task decomposition, dependency tracking

### Escalation Rule

Build agent escalates from S1 to S2 when:
- Edit fails twice on the same target
- More than 3 files touched
- Uncertainty exceeds 30%
- User says "think about it"

## Orchestration Flow

```
                    +───────────────+
                    |  orchestrator  |
                    |  [CTX: orch]   |
                    +───────┬───────+
                            │
              Decompose task into subtasks
                            │
          +─────────────────┼─────────────────+
          │                 │                 │
          ▼                 ▼                 ▼
    +──────────+      +──────────+      +──────────+
    │  build   │      │   plan   │      │ research │
    │[CTX:build│      │[CTX:plan]│      │[CTX:res] │
    +──────────+      +──────────+      +──────────+
          │                 │                 │
          ▼                 ▼                 ▼
    Code changes      Architecture      Source docs
          │                 │                 │
          └─────────────────┼─────────────────┘
                            │
                    Aggregate results
                            │
          +─────────────────┼─────────────────+
          │                 │                 │
          ▼                 ▼                 ▼
    +──────────+      +──────────+      +──────────+
    │ reviewer │      │  critic  │      │security-a│
    │[CTX:rev] │      │[CTX:crit]│      │[CTX:sec] │
    +──────────+      +──────────+      +──────────+
          │                 │                 │
          └─────────────────┼─────────────────┘
                            │
                    Synthesize final answer
```

### Dispatch Rules

1. **orchestrator** receives the top-level goal
2. It decomposes into independent subtasks (parallelizable)
3. Each subtask maps to the best-fit agent:
   - Code changes → **build**
   - Architecture design → **plan**
   - Investigation → **explore** / **scout** / **researcher**
   - Review → **reviewer** / **code-reviewer** / **security-auditor**
   - Testing → **test-engineer**
   - Challenge → **critic**
   - Domain knowledge → **sme**
   - Documentation → **docs**
4. Results are aggregated, conflicts resolved, final answer synthesized
5. Every dispatch is journaled to WAL

## Memory Hierarchy

```
  ┌─────────────────────────────────────────────────────────┐
  │                    MEMORY HIERARCHY                       │
  ├─────────────┬─────────────────┬──────────────────────────┤
  │   TIER 1    │     TIER 2      │          TIER 3          │
  │    WAL      │     Specs       │        Artifacts          │
  │  (session)  │  (persistent)   │      (ground truth)       │
  ├─────────────┼─────────────────┼──────────────────────────┤
  │ wal.jsonl   │ docs/specs/     │  Code, tests, configs    │
  │ ~/.cache/   │ AGENTS.md       │  opencode.json          │
  │ opencode/   │ Skills          │  *.sh, *.ts, *.rs        │
  ├─────────────┼─────────────────┼──────────────────────────┤
  │ Appendix-   │ Read before      │ Override specs when     │
  │ only journal │ domain tasks    │ conflicts exist         │
  │ Checkpoint   │ Write after     │ Update specs when       │
  │ every 10     │ architectural   │ artifacts change        │
  │ turns        │ decisions       │                         │
  └─────────────┴─────────────────┴──────────────────────────┘
```

### WAL Protocol (Tier 1)

- Location: `~/.cache/opencode/wal.jsonl`
- Format: JSONL entries with `ts`, `domain`, `decision`, `rationale`, `impact`, `confidence`, `mode`
- Checkpoint triggers: tool error, model switch, architectural decision, every 10 turns
- Compact agent reads WAL to preserve key decisions during context compression

### Specs (Tier 2)

- Location: `docs/specs/`, `AGENTS.md`, `.opencode/skills/`
- Read before any task touching their domain
- Written after architectural decisions
- Second priority after ground-truth artifacts

### Artifacts (Tier 3)

- Location: source files, configs, tests
- **Ground truth** — overrides stale specs
- All agents read before action, verify after write
- `.opencode/state/` for ephemeral inter-agent coordination

## Source Ladder Implementation

All agents follow the Source Ladder for claim verification:

| Tier | Source Type | Examples | Agent Usage |
|------|-------------|----------|-------------|
| **L1** | Official docs | context7, devdocs, man pages | researcher, plan, sme |
| **L2** | Authoritative secondary | RFCs, language specs, library author blogs | sme, plan |
| **L3** | Encyclopedias | MDN, Wikipedia, StackOverflow top-answer | researcher |
| **L4** | Model knowledge | Training data (last resort) | Flagged `[MK]` |

### Implementation Rules

1. **plan agent** verifies ALL claims against L1-L3 before writing specs
2. **researcher** cites sources with tier tags: `[L1]` through `[L4]`
3. **sme** flags when outside expertise, falls back to L1-L3 citation
4. **reviewer** / **code-reviewer** apply L1 for API contract verification
5. **critic** flags speculative claims (confidence < 80%) with `[speculative]`
6. Never mix tiers — one claim, one source tier

## Hard Gates (All Agents)

- Never emit secrets. Redact with `***`.
- Never delete code without understanding. Escalate to S2.
- Never skip WAL. Journal every consequential decision.
- Never speculate as fact. Tag `[speculative]` when confidence < 80%.
- Never trust user-provided paths blindly. Validate before operation.

## Session Start Ritual

1. Read last 20 lines of `~/.cache/opencode/wal.jsonl`
2. Read `AGENTS.md` and active `.opencode/skills/`
3. Emit `[CTX: <domain>]` anchor
4. Begin work
