# Skills Organization 2026 — opencode_initializer

> **Status:** Architecture reference (living document)
> **Scope:** How the skills in `opencode_initializer` are categorized, mapped to the AIPDLC control structure, composed into pipelines, tuned for cost/latency, secured, and evolved over time.
> **Canonical version:** v3.3.0
> **Companion docs:** [LLM Fundamentals 2026](llm-fundamentals-2026.md), [AIPDLC Integration Guide](aipdlc-integration-guide.md), [Agent Role Definitions 2026](agent-roles-2026.md), [Security Model 2026](security-model-2026.md)

This document is the **skills map**: it answers "which skill runs at which point in the lifecycle, under which role, with which model, and within which security boundary." It follows the same honesty convention as the security model:

- **[SKILL]** — a real `.opencode/skills/**/SKILL.md` (or `~/.config/opencode/skills/**`) protocol that an agent loads.
- **[MODULE]** — a numbered `src/lib/*.sh` (or `scripts/*`) shell/Go/Python artifact — **not** a skill, but a skill *calls* it or is *governed* by it.
- **[DOC]** — a reference document or registry that a skill reads as ground truth.

This distinction matters throughout: several things a user might *think of* as "security skills" (governance, audit, PII) are actually **modules** (`43/44/45`), while the *skills* are the protocol layer that dispatches work toward those modules.

---

## 0. Skill Inventory at a Glance

Skills live in three tiers. Tier 1 is project-local (the AIPDLC protocol spine); Tier 2 is the `matt-pocock` workflow toolkit; Tier 3 is the globally-installed superpowers/disruptor set.

| Tier | Location | Count | Character |
|------|----------|-------|-----------|
| T1 — Project protocol skills | `.opencode/skills/*` | 26 | AIPDLC modes (`MODE: BRAINSTORM` … `MODE: PHASE-WRAP`) + swarm review/PR skills + engineering invariants |
| T2 — Workflow toolkit | `.opencode/skills/matt-pocock/*` | ~20 | single-purpose craft skills: `tdd`, `implement`, `code-review`, `diagnosing-bugs`, `research`, `grill-*`, `wizard` |
| T3 — Global enablement | `~/.config/opencode/skills/{superpowers,smixs}/*` | ~28 | cross-project methodology (brainstorming, writing-plans, 7w3, disruptor, MVP fleet) |

The **canonical** (project-owned) set is Tier 1 + the `matt-pocock` subset that Tier 1 skills invoke by name. The full name→location map is in the [Appendix](#appendix-a---full-skill-inventory).

---

## 1. Skill Categories

Skills are grouped by the *phase of work* they serve, not by their file location. Five functional categories, plus a sixth "meta" category for skills that orchestrate the other five.

```mermaid
flowchart TD
    subgraph DEV["Development Skills"]
        direction TB
        DEV1[brainstorm]:::d
        DEV2[plan]:::d
        DEV3[specify]:::d
        DEV4[implement]:::d
        DEV5[tdd]:::d
        DEV6[code-review]:::d
    end
    subgraph ARCH["Architecture Skills"]
        direction TB
        ARC1[design-docs]:::a
        ARC2[deep-dive]:::a
        ARC3[codebase-review-swarm]:::a
        ARC4[codebase-design]:::a
        ARC5[domain-modeling]:::a
    end
    subgraph OPS["Operations Skills"]
        direction TB
        OPS1[running-tests]:::o
        OPS2[writing-tests]:::o
        OPS3[commit-pr]:::o
        OPS4[phase-wrap]:::o
        OPS5[resume]:::o
    end
    subgraph RES["Research Skills"]
        direction TB
        RES1[deep-research]:::r
        RES2[discover]:::r
        RES3[consult]:::r
        RES4[research]:::r
    end
    subgraph SEC["Security / Governance"]
        direction TB
        SEC1[code-review-swarm]:::s
        SEC2[engineering-conventions]:::s
        SEC3[governance MODULE]:::s
        SEC4[audit MODULE]:::s
    end
    subgraph META["Meta / Orchestration"]
        direction TB
        MET1[loop]:::m
        MET2[council]:::m
        MET3[critic-gate]:::m
        MET4[coprocessor]:::m
        MET5[pre-phase-briefing]:::m
    end

    META --> DEV
    META --> ARCH
    META --> OPS
    META --> RES
    META --> SEC

    classDef d fill:#e3f2fd,stroke:#1565c0
    classDef a fill:#f3e5f5,stroke:#6a1b9a
    classDef o fill:#e8f5e9,stroke:#2e7d32
    classDef r fill:#fff3e0,stroke:#ef6c00
    classDef s fill:#ffebee,stroke:#c62828
    classDef m fill:#eceff1,stroke:#455a64
```

### 1.1 Development Skills

The **write path** — turn an intent into merged code.

| Skill | Tier | What it does | AIPDLC phase |
|-------|------|--------------|--------------|
| `brainstorm` | T1 | Structured discovery dialogue before any code (approach selection, spec drafting, QA-gate choice) | specify |
| `clarify` | T1 | Clarification funnel; surfaces only the decisions the user must make | specify |
| `plan` | T1 | Plan creation, task granularity, traceability, QA-gate persistence | plan |
| `specify` | T1 | Spec creation with codebase-reality checks and SME input | specify |
| `execute` | T1 | Task execution, coder-retry handling, per-task closure | implement |
| `implement` | T2 | Implement a unit of work from a spec/tickets | implement |
| `tdd` | T2 | Red → green → refactor test-first cycle | implement |
| `code-review` | T2 | Standards + Spec review since a fixed git point | review |

### 1.2 Architecture Skills

The **design / understanding path** — structure a system or audit an existing one.

| Skill | Tier | What it does | AIPDLC phase |
|-------|------|--------------|--------------|
| `design-docs` | T1 | Generate/sync `domain.md`, `technical-spec.md`, `behavior-spec.md`, `reference/` with a stable section-ID registry | design |
| `deep-dive` | T1 | Read-only codebase audit: parallel explorer waves + 2 reviewers + critic challenge | research/review |
| `codebase-review-swarm` | T1 | Rigorous full-repo review with security/QA/accessibility/performance tracks | review |
| `codebase-design` | T2 | Deep-module vocabulary; interface/seam design | design |
| `domain-modeling` | T2 | Build/sharpen `CONTEXT.md`, glossary, ADRs | design |
| `improve-codebase-architecture` | T2 | Scan for deepening opportunities, present as HTML report | review |

### 1.3 Operations Skills

The **verify / ship / continue path** — keep work correct and durable.

| Skill | Tier | What it does | AIPDLC phase |
|-------|------|--------------|--------------|
| `running-tests` | T1/T2 | Safe test-execution patterns (scope safety, failure classification) | verify |
| `writing-tests` | T1 | Authoring/organizing tests; framework rules, mock isolation | implement/verify |
| `commit-pr` | T1 | Commit/PR/release lifecycle; invariant audit, release-note fragments | ship |
| `phase-wrap` | T1 | Phase-boundary evidence, drift/hallucination gates, retrospective | ship |
| `resume` | T1 | Continue an approved plan safely from current state | plan/implement |
| `issue-ingest` | T1 | GitHub-issue intake → localization → spec | specify |
| `swarm-pr-review` / `swarm-pr-feedback` | T1 | Graph-guided PR review; feedback ingestion with skeptical source verification | review |

### 1.4 Research Skills

The **read / learn path** — gather bounded evidence from code or the world.

| Skill | Tier | What it does | AIPDLC phase |
|-------|------|--------------|--------------|
| `deep-research` | T1 | Orchestrator-worker research over external sources with dual-reviewer claim verification | research |
| `discover` | T1 | Read-only repo discovery + governance/context mapping | research |
| `consult` | T1 | Advisory answers with bounded evidence and explicit uncertainty | research |
| `research` | T2 | Investigate against high-trust primary sources; write findings to a Markdown file | research |

### 1.5 Security / Governance Skills

> **Honesty note:** the security *concepts* the LLM-architecture material names — `security-model`, `governance`, `audit` — are **not** skills. `security-model-2026.md` is a **[DOC]**; `43-governance.sh`, `44-audit.sh`, `45-pii-guard.sh`, `46-offline-bundle.sh`, `47-lynis.sh`, `48-auditd.sh` are **[MODULE]**s. The skills that *engage* security are:

| Skill | Tier | Role in security |
|-------|------|------------------|
| `code-review-swarm` | T1 | Runs the **security audit track** (quote-grounded, coverage-closed) over the repo |
| `engineering-conventions` | T1 | Non-negotiable invariants (no secrets, no raw `curl\|sh`, WAL discipline) that gate *every* other skill |
| `commit-pr` | T1 | Enforces the pre-push invariant audit + release-note workflow so secrets never reach git |
| `coprocessor` | T1 | Declares the **hard gates** every role obeys (never emit secrets, never skip WAL, `[speculative]` flags) |

The modules enforce what these skills *promise*: `45-pii-guard.sh` redacts before any LLM request, `44-audit.sh` hash-chains every tool call, `43-governance.sh` allow/denies providers. See [§5](#5-skill-security).

### 1.6 Meta / Orchestration Skills

Skills that coordinate the other skills — the AIPDLC "loop state" layer.

| Skill | Tier | What it orchestrates |
|-------|------|----------------------|
| `loop` | T1 | The compound-engineering loop: brainstorm → plan → build → review → improve, with generator/critic separation |
| `council` | T1 | Parallel multi-model council; disagreement detection and synthesis |
| `critic-gate` | T1 | Plan critic review + revision loop + hard stop before execution |
| `pre-phase-briefing` | T1 | Phase-start context assembly, evidence review, readiness checks |
| `clarify-spec` | T1 | Resolve spec-clarification markers; keep spec/plan aligned |
| `coprocessor` | T1 | The universal operating protocol (dual-process, memory hierarchy, `[CTX]` anchor) that all skills assume |

---

## 2. Skill Mapping to AIPDLC

AIPDLC (`aipdlc-integration-guide.md`) defines seven pillars: **control plane, agent roles, isolation, MCP, security, team topologies, unit economics**. Skills are the *behavioral* surface of each pillar — the pillar's modules provide the *deterministic* enforcement, and the skill provides the *model* the deterministic layer supervises.

### 2.1 Control-Plane Skills

The control plane "decides what gets executed, by whom, with what model, in what sandbox." Skills do not *implement* the control plane — they are **supervised by** it.

| Control-plane concern | Deterministic layer (`[MODULE]`) | Skill(s) that speak its contract |
|-----------------------|----------------------------------|----------------------------------|
| State / WAL | `37-wal.sh`, `00-core.sh` progress gate | `coprocessor` (WAL protocol), `resume`, `phase-wrap` |
| Task graph + deps | `54-task-distributor.sh` `distribution_rules` | `plan` (emits `depends` arrays), `to-tickets`, `wayfinder` |
| Orchestration fan-out | `66–69-agent-*.sh` | `loop`, `council`, `critic-gate` |
| Model routing | `36-model-router.sh` + `routing.json` | *(none — routing is deterministic; skills only declare their token tier, §4)* |
| Audit | `44-audit.sh` hash chain | `commit-pr`, `phase-wrap` (each emits audit events on closure) |

**Principle** (from the v3 ADR, quoted in `llm-fundamentals-2026.md` §4.1): *the Control Plane is deterministic code, not an LLM. Models propose; the plane disposes.* A skill never owns the progress file or writes the WAL directly — it goes through `_run_step` / `_step_done` / `_wal_locked_append`.

### 2.2 Agent-Role Skills

Each AIPDLC role is *bound to a skill at dispatch* by `54-task-distributor.sh` (the SSOT). The skill narrows the role's allowed behavior (§2.3 in `agent-roles-2026.md`).

| AIPDLC role | `[CTX]` anchor | Bound skills | What the skill constrains |
|-------------|---------------|--------------|---------------------------|
| **Commander** (orchestrator) | `orch` | `loop`, `council`, `critic-gate`, `phase-wrap` | decomposition, wave ordering, parallel-vs-serial, final synthesis |
| **Planner** (researcher/analyst) | `plan` | `research`, `deep-research`, `plan`, `specify`, `brainstorm` | file-level plans, TODO creation, complexity estimation |
| **Worker** (implementer) | `build` | `implement`, `tdd`, `diagnosing-bugs`, `writing-tests` | TDD cycle, test-first, scope containment |
| **Reviewer** (verifier) | `review` | `code-review`, `code-review-swarm`, `swarm-pr-review` | adversarial review, fresh-context read, verdict emission |

The role→skill binding is priority-ordered and deterministic:

```text
complex      ⇒ Commander  (skill: loop)
research     ⇒ Planner    (skill: deep-research)
planning     ⇒ Planner    (skill: plan)
review       ⇒ Reviewer   (skill: code-review)
otherwise    ⇒ Worker     (skill: implement | tdd | diagnosing-bugs …)
```

### 2.3 Isolation Skills

Isolation in AIPDLC is *environment*, not behavior. Skills do not implement isolation; they **declare the isolation tier they require**, and the deterministic layer provides it.

| Isolation tier | `[MODULE]` / `[DOC]` | Skill relationship |
|----------------|----------------------|--------------------|
| Process (shell sandbox + readonly config) | `37-wal.sh`, `32-isolated.sh` | default for all Tier-1 skills |
| Container (seccomp/apparmor) | `02-docker.sh`, `30-infra.sh` | MCP servers invoked by `running-tests`/`deep-dive` run containerized |
| Air-gap (Isolated Circuit) | `32-isolated.sh`, `46-offline-bundle.sh` | `resume`/`execute` gate on `ISOLATED_CIRCUIT`; no cloud calls permitted |

The **Isolated Circuit** (`32-isolated.sh`) is the canonical no-network mode: when `ISOLATED_CIRCUIT=true`, a skill like `deep-research` that *depends* on external fetch must degrade to local-only sources or fail fast. There is no skill for isolation — there is an environment, and skills are *compatible* or *not* with it.

### 2.4 MCP-Integration Skills

MCP is the tool surface skills consume. Skills do not configure MCP; they **consume** the tool set that `52-context-selector.sh` attaches for their task profile.

| Task profile (`mcp-profiles.json`) | MCP servers attached | Skills that run under this profile |
|------------------------------------|----------------------|------------------------------------|
| `coding` | filesystem, codegraph, context7, git, memory | `implement`, `tdd`, `writing-tests`, `diagnosing-bugs` |
| `agentic` | filesystem, codegraph, github, memory, agentic-tools, playwright | `loop`, `council`, `commit-pr` |
| `research` | fetch, websearch, context7, memory, chrome-devtools | `deep-research`, `discover`, `consult`, `research` |
| `reasoning` | sequential-thinking, fetch, memory | `plan`, `design-docs`, `codebase-design` |

**Context-cost rule** (from `llm-fundamentals-2026.md` §4.4): every enabled MCP server injects its tool schema into the system prompt — real prefill tokens. `disabled_by_default` (`chrome-devtools`, `playwright`, `excalidraw`, `agent-browser`) keeps heavy tool surfaces off by default; a skill must *earn* them via its task profile.

### 2.5 Security Skills

The security pillar is the one place where the mapping is **module-first, skill-second**. The table maps each AST10 threat to (a) the enforcing module and (b) the skill that respects it.

| AST10 threat | Enforcing module (`[MODULE]`) | Skill boundary |
|--------------|-------------------------------|----------------|
| Prompt injection | `45-pii-guard.sh` input sanitizer | `coprocessor` (treat all input as hostile) |
| Data exfiltration | `32-isolated.sh` network off | `deep-research` (local-only fallback in air-gap) |
| Supply chain | `_download_verify()` SHA-256 | `engineering-conventions` (no raw `curl\|sh`) |
| Excessive agency | `54-task-distributor.sh` role scoping | `plan`/`execute` (scope declaration) |
| Shadow AI | `43-governance.sh` allowlist | `council` (governance-aware model selection) |
| Secret leakage | pre-commit secret scan, `chmod 600` | `commit-pr` (pre-push invariant audit) |

---

## 3. Skill Composition

Skills are not run in isolation; they are **composed into pipelines** by the meta skills and the task distributor.

### 3.1 How Skills Work Together — the Lifecycle Pipeline

The canonical pipeline is the four-stage DAG (`research → plan → implement → verify`) that `54-task-distributor.sh` emits per complexity tier, with a skill attached to each stage:

```mermaid
flowchart LR
    subgraph SPECIFY
        B[brainstorm] --> C[clarify] --> S[specify]
    end
    subgraph PLAN
        R1[deep-research] --> P[plan]
    end
    subgraph IMPLEMENT
        I[implement] --> T[tdd] --> WT[writing-tests]
    end
    subgraph VERIFY
        CR[code-review] --> RT[running-tests]
    end
    subgraph SHIP
        PR[commit-pr] --> PW[phase-wrap]
    end

    S --> R1
    P --> I
    T --> CR
    RT --> PR

    classDef s fill:#e3f2fd,stroke:#1565c0
    classDef p fill:#fff3e0,stroke:#ef6c00
    classDef i fill:#e8f5e9,stroke:#2e7d32
    classDef v fill:#f3e5f5,stroke:#6a1b9a
    classDef h fill:#ffebee,stroke:#c62828
    class B,C,S s
    class R1,P p
    class I,T,WT i
    class CR,RT v
    class PR,PW h
```

Complexity tiers trim this pipeline (from `routing.json` / `54-task-distributor.sh`):

```text
simple  → [ implement:Worker ]
medium  → [ research:Planner ] → [ implement:Worker ]
complex → [ research:Planner ] → [ plan:Planner ] → [ implement:Worker ] → [ verify:Reviewer ]
```

### 3.2 Skill Dependencies

Skills form an **acyclic** dependency graph. Load-order and fan-out edges:

| Skill | Depends on (loads/assumes) |
|-------|---------------------------|
| `execute` | `plan` (a plan must exist), `resume` (safe continuation) |
| `code-review` | `implement`/`tdd` (work must exist), `running-tests` (evidence) |
| `phase-wrap` | `execute` (completed tasks), `critic-gate` (drift/hallucination verdicts) |
| `commit-pr` | `code-review`/`swarm-pr-review` (approval), `running-tests` (green suite) |
| `critic-gate` | `plan` (the plan under review), `council` (optional multi-model review) |
| `deep-dive` | `discover` (repo orientation) |
| `loop` | the *entire* pipeline — it composes brainstorm → plan → build → review → improve |

**Hard rule** (from `agent-roles-2026.md` §1.5): delegation is acyclic. A skill may fan out *down* the role ladder, never up. `Worker`-bound skills (`implement`, `tdd`) are leaves; they never re-plan or self-approve.

### 3.3 Skill Orchestration

Orchestration is *who decides which skill runs next*:

| Orchestrator | Mechanism | Scope |
|--------------|-----------|-------|
| `54-task-distributor.sh` | `distribution_rules` + `depends` DAG | per-task: maps `{task, complexity}` → `{agent, skill}` |
| `loop` skill | generator/critic separation + stop conditions | per-phase: iterates the compound loop |
| `council` skill | parallel member dispatch + disagreement synthesis | per-decision: multi-model advisory |
| `critic-gate` skill | review → revise → hard stop | per-plan: blocks execution until APPROVED |
| `pre-phase-briefing` skill | context assembly + readiness checks | per-phase: gates entry |

**Parallel fan-out** is driven by `dispatching-parallel-agents` (T3) + `54-task-distributor.sh parallel`, gated by disjoint-scope preflight (`plan_conflict_check`). Skills in a wave are **file-disjoint**; the Commander enforces wave ordering.

### 3.4 Skill Fallbacks

When a skill's primary path fails, the fallback is **structural**, not ad-hoc:

| Failure | Fallback | Owning mechanism |
|---------|----------|------------------|
| Provider failure (quota/billing) | walk the task profile's `fallback` chain | `36-model-router.sh` + `routing.json` |
| Worker edit fails twice / >3 files | escalate S1 → S2, re-route to Planner | `coprocessor` dual-process + `54-task-distributor.sh` |
| `NEEDS_REVISION` verdict | loop back to Worker with findings | `code-review` → `execute` retry loop |
| Transient non-idempotent failure | ≤2 retries with backoff, then classify | `coprocessor` failure taxonomy (transient/recoverable/user-fixable/unexpected) |
| Air-gap blocks external research | local-only degradation | `32-isolated.sh` + `deep-research` local fallback |
| `npm install` failure | `_npm_install` (npm pack → bun) | `helpers.sh` — a **module**-level fallback all skills inherit |

---

## 4. Skill Performance

Skill performance is the AIPDLC **unit-economics** pillar applied per-skill: each skill has a *token budget*, a *model profile*, and a *context footprint*.

### 4.1 Token Usage per Skill

Token ceilings follow `routing.json` `complexity_rules`, and each skill is assigned to the tier that matches its cognitive load:

| Tier | max_tokens | model | cost_per_1k | Representative skills |
|------|-----------|-------|-------------|-----------------------|
| `simple` | 2 000 | `deepseek-v4-flash` | $0.00014 | `running-tests`, `resolving-merge-conflicts`, `to-tickets` |
| `medium` | 8 000 | `deepseek-v4-pro` | $0.00055 | `implement`, `tdd`, `code-review`, `writing-tests`, `diagnosing-bugs` |
| `complex` | 64 000 | `deepseek-v4-pro` + thinking | $0.00219 | `design-docs`, `deep-dive`, `deep-research`, `codebase-review-swarm`, `council` |

**Prefill vs decode** (`llm-fundamentals-2026.md` §1.4): a review skill pays prefill on the *full diff + system prompt* every turn; a planning skill pays prefill on the *full repo orientation*; a leaf implementation skill pays prefill on a small file scope. The skill's *own instructions* (`SKILL.md`) are static prefix — the exact thing prompt caching amortizes (§4.3).

### 4.2 Cost Optimization

The levers, in order of leverage (`llm-fundamentals-2026.md` §6.2), applied to skills:

| Lever | Mechanism | Skill-level effect |
|-------|-----------|--------------------|
| **Right-size the model** | `routing.json` per-tier routing | a `simple` skill on flash is ~15× cheaper than on a thinking frontier model |
| **Free-tier-first** | `routing.json` `cost_table` marks `deepseek-v4-pro/flash`, `glm-5.2` `free: true` | the default skill spine is $0 token cost |
| **Shrink prefill** | `60-caching.sh` + `mcp-profiles.json` thinning | skills load only their task profile's MCP/LSP, never the full registry |
| **Bound output** | `thinking: true` only for `complex` | review/design skills cap output tokens; implementation skills never reason |
| **Small-model fan-out** | `small_model` for high-volume subtasks | test generation, docs, review fan out to flash |

### 4.3 Context Management

Every skill inherits the context stack (`00n-context-mgr.sh`, `70-context-engine.sh`, `83-context-engineering.sh`):

- **Prompt-cache ordering** — `SKILL.md` instructions are *static blocks first, dynamic input last*, preserving provider KV-cache prefix hits (`60-caching.sh`). This is why the harness principle "static blocks first" exists.
- **Memory anchor** — every skill response opens with `[CTX: domain]` so a role resumes after compaction without re-reading all files (`coprocessor`).
- **Tiered memory** — WAL (session) → Specs (persistent) → Artifacts (ground truth); a skill reads the *cheapest authoritative* tier.
- **Lost-in-the-middle mitigation** — critical constraints at the start *and* end of long skill instructions.
- **Context guard (compression)** — truncates/summarizes history to keep `n` small, directly cutting `O(n²)` attention cost.

### 4.4 Model Routing

Model selection is **orthogonal** to skill selection (`agent-roles-2026.md` §6.4): the Commander picks *which skill* (§2.2), the router picks *which model*.

| Task profile (`routing.json`) | Primary model | Skills routed here |
|-------------------------------|---------------|--------------------|
| `coding` | `deepseek/deepseek-v4-pro` | `implement`, `tdd`, `writing-tests` |
| `reasoning` | `anthropic/claude-opus-4-8` | `plan`, `design-docs`, `codebase-design` |
| `fast` | `deepseek/deepseek-v4-flash` | `discover`, `running-tests`, compaction |
| `agentic` | `deepseek/deepseek-v4-pro` | `loop`, `council`, `commit-pr` |
| `research` | *(research profile)* | `deep-research`, `consult`, `research` |
| `isolated` | `ollama/qwen3:32b` | any skill under `ISOLATED_CIRCUIT=true` |

Each profile carries an ordered `fallback` chain; on provider failure the router walks it before any skill notices. The `isolated` profile routes **all** skills to local-only backends — no cloud key exists in air-gap.

---

## 5. Skill Security

Skills are untrusted actors: each is a prompt that, when loaded, *changes* what the model is allowed to do. Security is enforced **around** the skill, not *inside* it.

### 5.1 Permission Boundaries

Deny-by-default, role-scoped, layered (`agent-roles-2026.md` §2.3):

| Layer | Enforcement | Skill example |
|-------|-------------|---------------|
| Hard gates (all roles) | never emit secrets; never delete code you don't understand; never skip WAL; `[speculative]` < 80% confidence | `coprocessor` declares these; every skill inherits them |
| Role scope | a role may use only its §2.2 tool set | `Worker` skills (`implement`, `tdd`) are the only unrestricted write path |
| File-scope containment | `declare_scope` / `files_touched` | `execute` writes only within the declared scope; outside writes are rejected |
| Skill gating | `distribution_rules` bind task→skill; the skill narrows allowed behavior further | `diagnosing-bugs` forbids editing before root-cause is confirmed |

### 5.2 Secret Access Control

- **Hard gate:** no skill may emit secrets; all secrets redacted with `***` in logs and output.
- **No secrets in skill files** — `SKILL.md` bodies contain instructions, never keys. Pre-commit scans block `sk-…`, `AKIA…`, `ghp_…`, `-----BEGIN PRIVATE KEY-----` patterns.
- **PII guard** (`45-pii-guard.sh`, `scripts/pii-guard.py`): 9 detector classes run **before** any LLM request a skill triggers — including `deep-research` web content and `issue-ingest` GitHub bodies.
- **Secrets arrive via CLI/env only** — `.env` gitignored, `chmod 600`, `_secrets_*` API (`90-secrets-manager.sh`) for the corporate profile.

### 5.3 Audit Logging

Every skill's consequential action is journaled — not by the skill, but by the modules the skill's role calls:

- **WAL** (`37-wal.sh`) — append-only JSONL; `{ts, domain, decision, rationale, impact, confidence, mode}`. `loop`/`phase-wrap`/`council` journal their verdicts.
- **Hash-chained audit** (`44-audit.sh`) — seven event types (`model_call`, `tool_call`, `pii_redacted`, …), rotation >10 MB → gzip + Qdrant. `commit-pr` and `swarm-pr-review` emit `tool_call`/`checkpoint` events.
- **Kernel corroboration** (`48-auditd.sh`) — an independent kernel stream a user-space attacker (including a compromised skill) cannot tamper with.

### 5.4 Trust Levels

Skills are mapped to the role trust ladder (`agent-roles-2026.md` §5.4). The *consequence of failure* is what determines how much a skill is trusted to act autonomously:

```mermaid
flowchart TD
    T0["T0 — Orchestrator<br/>loop · council · critic-gate<br/>(own loop state + final synthesis)"]
    T1["T1 — Planner<br/>plan · specify · brainstorm<br/>(produce executable contract)"]
    T2["T2 — Implementer<br/>implement · tdd · writing-tests<br/>(only unrestricted write path)"]
    T3["T3 — Verifier<br/>code-review · swarm-pr-review<br/>(independent fresh context)"]

    T0 --> T1 --> T2 --> T3
    T3 -. "adversarial counterweight" .-> T2

    classDef t fill:#e3f2fd,stroke:#1565c0
    class T0,T1,T2,T3 t
```

Trust flows **downhill** (T0 most trusted for *direction*, T3 most trusted for *correctness*). No `Worker` skill self-approves: `implement`/`tdd` output is always gated by a `Reviewer` skill (`code-review`) with independent context.

---

## 6. Skill Evolution

Skills are versioned artifacts with a lifecycle. The repo currently does **not** have a dedicated skill-versioning module, but the pattern is established and the seams exist.

### 6.1 Skill Versioning

| Dimension | Current state | Mechanism |
|-----------|---------------|-----------|
| Content version | implicit (git history) | every `SKILL.md` is git-tracked; `git log` is the version trail |
| Skill registry | `available_skills` manifest (OpenCode frontmatter `name`/`description`) | the `description` field is the discovery contract; changing it changes routing |
| Source pinning | `upstream/` submodule pins skill sources (`superpowers`, `skill-conductor`) to exact commits | supply-chain pinning, same as MCP/LSP |

**Recommended:** a `version:` frontmatter field + a `CHANGELOG` per skill family, mirrored to the docs site. The ADR/versioning discipline already used for modules (`v3.3.0` across README/CHANGELOG/`package.json`/`SCRIPT_VERSION`) should extend to the Tier-1 skill set.

### 6.2 Skill Deprecation

The existing pattern is the **retired marker**:

- `skill_retire` (slug) writes `retired.marker`; retired skills are excluded from scoring and injection.
- Deprecated skills are **not deleted** immediately — they are marked, then removed after a migration window.
- The `writing-tests`/`running-tests` shadowing across tiers (`T1` vs `matt-pocock`) is the existing case to manage: same name, two locations. Deprecation must resolve shadowing explicitly, not leave an ambiguous load order.

### 6.3 Skill Migration

Migration paths already exercised in this repo:

| From | To | Path |
|------|----|------|
| `matt-pocock/*` shadowed skill | canonical Tier-1 skill | promote to `.opencode/skills/<name>`, retire the shadow |
| External skill candidate | promoted skill | `external_skill_discover` → security gates → `external_skill_promote` (approver must be `user`) |
| Mature knowledge entries | generated skill | `skill_generate` (draft → active), `skill_apply` from `.swarm/skills/proposals` |
| Deprecated module-backed behavior | skill | move deterministic logic *out* of skills into modules; skills keep only the protocol |

**Migration invariant:** a skill's *behavioral contract* (its `description` + hard gates) is the public API. Migration must preserve the contract even when the implementation moves.

### 6.4 Skill Testing

Skills are tested like modules, at three levels:

| Level | What it verifies | Example |
|-------|------------------|---------|
| Syntax/lint | `SKILL.md` frontmatter valid, description non-empty, no secrets | pre-commit secret scan; markdown lint |
| Behavioral | the skill produces the expected artifact/verdict | `tests/unit/test_<name>.sh` for module-backed skills; eval stubs for generated skills (`skill_apply --evaluate`) |
| Integration | the skill composes correctly in its pipeline | `tests/integration/*` (module loading, opencode.json gen), `tests/e2e/*` (critical path) |

**Skill-improver loop** (`skill_improve`, `skill_opt`): repeated agent successes become skills; repeated mistakes become AGENTS.md rules or programmed gates. This is the *harness-engineering loop* — the primary mechanism by which the skill set evolves against observed behavior.

---

## Appendix A — Full Skill Inventory

### Tier 1 — Project protocol skills (`.opencode/skills/`)

| Skill | Category | AIPDLC pillar | Mode/contract |
|-------|----------|---------------|---------------|
| `brainstorm` | Development | Agent role (Planner) | `MODE: BRAINSTORM` |
| `clarify` | Development | Agent role | `MODE: CLARIFY` |
| `clarify-spec` | Meta | Control plane | `MODE: CLARIFY-SPEC` |
| `codebase-review-swarm` | Architecture / Security | Security | full-repo audit |
| `commit-pr` | Operations / Security | Unit economics | PR lifecycle |
| `consult` | Research | Agent role | `MODE: CONSULT` |
| `coprocessor` | Meta | Control plane (hard gates) | operating protocol |
| `council` | Meta | Agent role (Commander) | `MODE: COUNCIL` |
| `critic-gate` | Meta | Agent role (Commander) | `MODE: CRITIC-GATE` |
| `deep-dive` | Architecture | Agent role (Reviewer) | `MODE: DEEP_DIVE` |
| `deep-research` | Research | Agent role (Planner) | `MODE: DEEP_RESEARCH` |
| `design-docs` | Architecture | Agent role (Planner) | `MODE: DESIGN_DOCS` |
| `discover` | Research | Agent role (Planner) | `MODE: DISCOVER` |
| `engineering-conventions` | Security | Control plane | invariants |
| `execute` | Development | Agent role (Worker) | `MODE: EXECUTE` |
| `issue-ingest` | Operations | Agent role (Planner) | `MODE: ISSUE_INGEST` |
| `loop` | Meta | Agent role (Commander) | `MODE: LOOP` |
| `phase-wrap` | Operations | Unit economics | `MODE: PHASE-WRAP` |
| `plan` | Development | Agent role (Planner) | `MODE: PLAN` |
| `pre-phase-briefing` | Meta | Control plane | `MODE: PRE-PHASE BRIEFING` |
| `resume` | Operations | Control plane | `MODE: RESUME` |
| `running-tests` | Operations | Agent role (Worker) | test execution |
| `specify` | Development | Agent role (Planner) | `MODE: SPECIFY` |
| `swarm-pr-feedback` | Operations | Security | PR feedback ingestion |
| `swarm-pr-review` | Operations | Security | graph-guided PR review |
| `writing-tests` | Operations | Agent role (Worker) | test authoring |

### Tier 2 — Workflow toolkit (`.opencode/skills/matt-pocock/`)

| Skill | Category |
|-------|----------|
| `code-review`, `running-tests`, `tdd` | Development / Operations |
| `codebase-design`, `domain-modeling`, `improve-codebase-architecture`, `setting-up-domain-model` | Architecture |
| `diagnosing-bugs`, `implement`, `prototype` | Development |
| `research`, `grill-me`, `grill-with-docs`, `grilling`, `consult` | Research |
| `resolving-merge-conflicts`, `using-git-worktrees`, `wayfinder`, `to-spec`, `to-tickets`, `wizard` | Operations |
| `symbol-search` | Development (discovery) |

### Tier 3 — Global enablement (`~/.config/opencode/skills/`)

| Family | Skills | Category |
|--------|--------|----------|
| `superpowers` | `brainstorming`, `writing-plans`, `executing-plans`, `subagent-driven-development`, `dispatching-parallel-agents`, `test-driven-development`, `systematic-debugging`, `verification-before-completion`, `requesting-code-review`, `receiving-code-review`, `finishing-a-development-branch`, `using-git-worktrees`, `resolving-merge-conflicts`, `writing-skills`, `using-superpowers` | Development / Operations |
| `smixs` (disruptor) | `disruptor`, `designing-with-7w3`, `write-spec`, `slicing-into-tracer-bullets`, `delivering-mvp-fleet`, `architecture-guardrails`, `qa-demo-stand`, `setup-server`, `converging-and-polishing`, `unvibe-review`, `spawning-reviewers`, `mentor`, `setting-up-domain-model` | Architecture / Meta |
| other | `memory-read`, `memory-write`, `humanizer-ru`, `symbol-search` | Operations / utility |

---

## Appendix B — Skill ↔ Module / Doc cross-reference

| Concept named in LLM-architecture material | It is a… | Lives at |
|--------------------------------------------|----------|----------|
| `security-model` | **[DOC]** | `docs/architecture/security-model-2026.md` |
| `governance` | **[MODULE]** | `src/lib/43-governance.sh` |
| `audit` | **[MODULE]** | `src/lib/44-audit.sh` |
| `PII guard` | **[MODULE]** | `src/lib/45-pii-guard.sh`, `scripts/pii-guard.py` |
| `offline bundle` | **[MODULE]** | `src/lib/46-offline-bundle.sh` |
| `Lynis` / `auditd` | **[MODULE]** | `src/lib/47-lynis.sh`, `48-auditd.sh` |
| `isolated circuit` | **[MODULE]** | `src/lib/32-isolated.sh` |
| `model router` | **[MODULE]** | `src/lib/36-model-router.sh` + `src/data/routing.json` |
| `context selector` | **[MODULE]** | `src/lib/52-context-selector.sh` + `src/data/mcp-profiles.json` |
| `task distributor` | **[MODULE]** | `src/lib/54-task-distributor.sh` |
| `caching` | **[MODULE]** | `src/lib/60-caching.sh` |
| `memory layer` | **[MODULE]** | `src/lib/71-memory-layer.sh` |
| `sandbox` | **[MODULE]** | `src/lib/86-sandbox.sh` |
| `security policies` | **[MODULE]** | `src/lib/89-security-policies.sh` + `src/data/security-rules.json` |
| `secrets` | **[MODULE]** | `src/lib/90-secrets-manager.sh` |

**The rule of thumb:** *modules are deterministic; skills are supervised.* A skill expresses **what** the model should do; a module decides **whether** it may, **where** it runs, and **what it costs** — and records the result.

---

## See also

- [LLM Fundamentals 2026](llm-fundamentals-2026.md) — the theory this document maps to skills.
- [AIPDLC Integration Guide](aipdlc-integration-guide.md) — the seven-pillar methodology.
- [Agent Role Definitions 2026](agent-roles-2026.md) — the four-role hierarchy skills are bound to.
- [Security Model 2026](security-model-2026.md) — the threat model skills operate within.
- [Multi-Agent Framework v3 ADR](adr/multi-agent-framework-v3.md) — the operating model.
- [Architecture Index](index.en.md) — C4 diagrams and module layout.
