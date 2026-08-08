# T1.4: Agent Harness & SDD Readiness Audit
> **Scope:** 17-project.sh (608), 37-wal.sh, pre-session-check.sh, .opencode/skills/, AGENTS.md template
> **Date:** 2026-08-08 | **Baseline:** f36326f (v2.0.3)

---

## What a NEW project gets after `setup.sh --new`

After running the harness, a new project receives:

1. **Directory structure:** `docs/`, `wal/`, `.opencode/{agents,skills,commands,context}`, `infra/`, `templates/`
2. **AGENTS.md** (lines 136-608 of 17-project.sh) — comprehensive system prompt with:
   - Dual-Process Reasoning (S1/S2)
   - Memory Hierarchy (L2 WAL / L3 Specs / L4 Artifacts)
   - WAL Protocol: Status / Active / Protected format
   - CO-STAR output contract
   - Memory Anchor Protocol `[CTX: ...]`
3. **WAL state.yaml** — session journal scaffold
4. **INDEX.md** — knowledge base map
5. **Skills scaffold:** 4 empty skill directories (code-review-checklist, deployment-checklist, testing-strategy, context-switching)
6. **Docker compose** — infra services (if enabled)
7. **secrets.env** — API key template
8. **plugins.json** — 24 plugins (5 always, 9 conditional, 10 on-demand)

---

## S1.4.1: SDD Workflow Readiness (specify -> plan -> tasks -> implement -> verify)

### Per Red Book & spec-kit/OpenSpec standards:

| Capability | Target | Current State | Gap |
|-----------|--------|---------------|-----|
| spec:// URI addressing | Every requirement has a stable URI | None | CRITICAL |
| Spec templates | proposal.md, tasks.md, design.md, spec.md | .opencode/skills/ has specify/plan/execute SKILL.md files (loaded at runtime, not in project) | MEDIUM |
| SDD workflow commands | /specify -> /plan -> /tasks -> /implement | Skills exist but as agent instructions, not as project-level workflow | MEDIUM |
| Traceability | FR-### IDs linked to code via spec:// | None | CRITICAL |
| Sync-from-Code | AI reads git diff -> proposes spec update | None | CRITICAL |
| "Ограничения" in WAL | WAL has protected section | WAL format includes "Protected" line | GOOD |

### Analysis

**What works:**
- AGENTS.md template is genuinely good. The "Protected" line in WAL format (line 171: `🛑 Protected: <critical constraints, fragile zones, irreversible decisions>`) IS the Red Book "Ограничения" concept. Well-designed.
- Skills directory scaffold exists but is empty — agent instructions come from the global `.opencode/skills/` at install time, not from the project.
- WAL state.yaml has `protected:` and `decisions:` sections — aligned with Red Book checkpoint concept.

**What's missing (CRITICAL for v3.0):**
1. **No specs/ directory in project scaffold.** New project has no place for specifications. Red Book says this is the L3 memory layer.
2. **No spec templates.** User must create specs from scratch. spec-kit provides `spec-template.md`, `plan-template.md`, `tasks-template.md`.
3. **No spec:// URI scheme.** Without stable requirement addresses, agent correction costs 10x more tokens (per Red Book Chapter 2).
4. **No SDD workflow automation.** Skills `specify`/`plan`/`execute` exist as agent prompts, but the project-level workflow (commands, templates, traceability) is absent.

### Recommendations
- Add `specs/` directory + `specs/templates/{spec,plan,tasks}.md` to 17-project.sh scaffold
- Implement spec:// URI scheme in project AGENTS.md
- Add `/specify`, `/plan`, `/tasks` slash-commands to `.opencode/commands/`
- Add `Sync-from-Code` protocol to WAL/AGENTS.md

---

## S1.4.2: Memory Hierarchy (WAL correctness)

### Comparison: Red Book vs Our Implementation

| Aspect | Red Book Target | Current Implementation | Gap |
|--------|----------------|----------------------|-----|
| WAL checkpoint vs log | Overwritten each session | `wal/state.yaml` - overwritten on init but append in practice | PARTIAL |
| WAL structure | Phase, Constraints, Done, Next, Issues | Status, Active, Protected | CLOSE |
| "Решения, а не факты" | Why + alternatives + revisit-condition | `decisions: []` in WAL — just a list, no structure | MEDIUM |
| Visibility rule | Only files survive both | AGENTS.md mentions files as IPC | GOOD |
| Agent vs chat WAL | Different precision levels | Single WAL format | GAP |

### Analysis

The AGENTS.md WAL format (L161-173) is surprisingly well-aligned with Red Book:
```
📍 Status: <one concise sentence>
🚀 Active: <current task or next step>
🛑 Protected: <critical constraints>
```

This IS the checkpoint concept (concise, not a log). The "Protected" section IS the Red Book "Ограничения". 

**Gap:** The WAL doesn't enforce "decisions, not facts" — the `decisions: []` list has no structure for rationale/alternatives/revisit-condition.

**Gap:** The `wal/state.yaml` is initialized but there's no mechanism to ENSURE agents actually update it at session end (37-wal.sh only manages the setup WAL, not project WAL).

### Recommendations
- Add structured decision template to WAL: `{decision, rationale, alternatives, revisit_condition}`
- Add pre-session WAL check to AGENTS.md boot sequence (already has "read WAL" but not enforced)
- Add `wal.jsonl` append for audit trail + `state.yaml` overwrite for checkpoint (two-tier WAL)

---

## S1.4.3: Skills & Agent Instructions

### Current state
- `.opencode/skills/` has 4 empty directories (17-project.sh:101)
- Global skills (specify, plan, execute, coprocessor, brainstorm, etc.) live in `~/.config/opencode/skills/` — installed by 12-mcp-lsp.sh or 14-shokunin.sh
- No project-level skill templates — user must write from scratch

### Gap for SDD
- After `setup.sh --new`, project has no working SDD workflow. Skills exist globally but the project doesn't know about them.
- spec-kit solves this by generating `.claude/commands/` (slash-commands) + `specs/` directory during project init.
- OpenSpec solves this via `openspec init` which creates `openspec/` directory with proposal/tasks/design templates.

### Recommendations
- Generate `.opencode/commands/{specify,plan,tasks,implement}.md` in project scaffold
- Populate skill directories with SDD workflow instructions (not empty stubs)
- Add `openspec init`-style bootstrap: `dev project init --sdd` creates full SDD harness

---

## Summary

| Dimension | Score | Key Gap |
|-----------|:-----:|---------|
| SDD workflow readiness | 3/10 | No specs/, no spec:// URI, no templates, no traceability |
| WAL / Memory hierarchy | 6/10 | Format is close to Red Book; missing "decisions not facts" structure |
| Agent instructions | 5/10 | Good AGENTS.md; empty skill stubs; no project-level commands |
| Overall harness | 4/10 | Solid foundation, but not SDD-ready for a new project |

**v3.0 priorities:**
1. CRITICAL: Add `specs/` directory + spec templates to project scaffold
2. CRITICAL: Implement spec:// URI scheme in AGENTS.md + WAL
3. HIGH: Generate `.opencode/commands/` with SDD slash-commands
4. HIGH: Structured decision template in WAL
5. MEDIUM: Sync-from-Code protocol in AGENTS.md
