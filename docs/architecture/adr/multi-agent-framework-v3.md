# Multi-Agent Continuous Development Framework v3.0 — ADR

**Status:** ACCEPTED  
**Date:** 2026-07-18  
**Decision:** Adopt the Universal Multi-Agent Continuous Development Framework v3.0 as the operating model for all projects under ~/Projects/.

## Context
The opencode_initializer project and its sibling projects (opora, agi, rag-system, ThePath, etc.) require a unified, self-sustaining development methodology that:
- Enables parallel agentic development streams
- Enforces strict quality gates (tests, security, docs)
- Persists all state for pause/resume
- Maintains bilingual documentation (EN + RU)
- Prevents drift between code and docs

## Decision
Adopt the 10-agent-role framework with artifact-based truth, wave-based execution, and automatic checkpointing after every meaningful action.

## Agent Roles
| Role | Responsibility |
|------|---------------|
| Strategic Steering Committee | Prioritization, architecture alignment,  blocks |
| Parallel Implementation Swarm | Atomic task execution, refactoring, PRs |
| UX/UI Design Agents | Research, wireframes, design systems, design-code consistency |
| Dual-Guardian Validators | Test coverage ≥80%, security audit, performance regression |
| Infrastructure Sentinel | CI/CD monitoring, auto-healing |
| Doc-Sync Reflector | Bilingual docs (EN+RU), zero code-docs drift |
| Tool Orchestrator | CodeGraph, LSP, MCP, ChromaDB, Memory, multi-model router |
| Focus & Session Manager | ≤4h task decomposition, timeboxing, checkpointing |

## Consequences
- All projects MUST maintain current_wave.md and session_checkpoint.json
- Every task completion triggers commit + push + checkpoint
- Docs must be updated in both EN and RU within same PR
- [STRATEGIC_NEEDED] gates require human input before proceeding

