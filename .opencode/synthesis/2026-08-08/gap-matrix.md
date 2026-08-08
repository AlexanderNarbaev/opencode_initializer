# Gap Matrix v3.0 — Сводная таблица находок и гэпов

> **Синтез:** аудит (5 отчётов, 843 строки) × исследование (5 дайджестов, 993 строки) × конкурентная матрица
> **Дата:** 2026-08-08 | **Автор:** Planner (T3.1)

## Легенда

| Severity | Знак | Аудитория | Знак |
|----------|:----:|----------|:----:|
| CRITICAL | 🔴 | Both | 🌐 |
| HIGH | 🟠 | Enthusiast | 🏠 |
| MEDIUM | 🟡 | Corporate | 🏢 |
| LOW | 🟢 | — | — |

## Complete Gap Matrix

| ID | Описание | Источник | Sev | Аудит. | Волна | Effort |
|----|----------|----------|:---:|:------:|:-----:|:------:|
| **F1** | No per-step error recovery — single failure stops entire bootstrap | 01-core: F1 | 🔴 | 🌐 | W1 | M |
| **F2** | Parallel install race condition on shared state (WAL, PROGRESS) | 01-core: F2 | 🔴 | 🌐 | W1 | M |
| **F3** | Double logging init — first log file lost (dead code) | 01-core: F3 | 🟠 | 🌐 | W1 | XS |
| **F4** | Non-atomic WAL checkpoint — corruption on crash/concurrency | 01-core: F4 | 🟠 | 🌐 | W1 | S |
| **F5** | Implicit module dependency order — no MODULE_LOADED check | 01-core: F5 | 🟡 | 🌐 | W1 | S |
| **F6** | Fragile _step_skip grep — substring matching risk | 01-core: F6 | 🟡 | 🌐 | W1 | XS |
| **F7** | Mirror resolution 30s+ delay on cold cache | 01-core: F7 | 🟡 | 🌐 | W1 | S |
| **F8** | setup.conf double-source overwrites ISOLATED_CIRCUIT | 01-core: F8 | 🟡 | 🌐 | W1 | XS |
| **F9** | _sudo wrapper masks all errors (2>/dev/null) | 01-core: F9 | 🟢 | 🌐 | W1 | XS |
| **F10** | _progress and _spin_start fight for terminal line | 01-core: F10 | 🟢 | 🌐 | W1 | XS |
| **F11** | Cleanup trap incomplete — hardcoded file list | 01-core: F11 | 🟢 | 🌐 | W1 | S |
| **F12** | Progress file never truncated — grows indefinitely | 01-core: F12 | 🟢 | 🌐 | W1 | XS |
| **C1** | Duplicate provider registry — 26-providers + 18-opencode-json diverged (SSOT gap) | 02-prov: C1 | 🔴 | 🌐 | W1 | M |
| **C2** | Triple minimax copy-paste in provider registry (dead code) | 02-prov: C2 | 🔴 | 🌐 | W1 | XS |
| **C3** | Incomplete cost-table — minimax missing, use models.dev as source | 02-prov: C3 | 🟠 | 🌐 | W1 | S |
| **H1** | Policy engine absent — no model allow/deny, quotas, cost caps | 02-prov: H1 | 🟠 | 🏢 | W3 | M |
| **H2** | ai-router.sh ORCHESTRATOR hardcoded path — not portable | 02-prov: H2 | 🟡 | 🌐 | W1 | XS |
| **H3** | Fallback chains untested — no integration tests for failover | 02-prov: H3 | 🟠 | 🌐 | W1 | M |
| **H4** | No model-call audit logging — token usage, provider, model untracked | 02-prov: H4 | 🟠 | 🏢 | W3 | M |
| **H5** | embed-proxy.py single-backend (Ollama only) — no vLLM/SGLang fallback | 02-prov: H5 | 🟡 | 🌐 | W1 | S |
| **M1** | provider-check.sh raw curl without _curl() retry/cache | 02-prov: M1 | 🟡 | 🌐 | W1 | XS |
| **F3.1** | MemoryLayer: network_mode=host + user=root — full host access | 03-infra: F3.1 | 🔴 | 🌐 | W1 | S |
| **F3.2** | Node Exporter: network_mode=host + pid=host — data leak vector | 03-infra: F3.2 | 🔴 | 🏢 | W1 | S |
| **F3.3** | Hardcoded default passwords (PG/Neo4j/MinIO/Grafana) | 03-infra: F3.3 | 🟠 | 🏢 | W1 | M |
| **F3.4** | Prometheus sed-based injection fragile — YAML corruption risk | 03-infra: F3.4 | 🟠 | 🌐 | W2 | M |
| **F3.5** | Docker host IP detection — silent "host.docker.internal" fallback on Linux | 03-infra: F3.5 | 🟠 | 🌐 | W1 | S |
| **F3.6** | Qdrant no authentication — open to any localhost process | 03-infra: F3.6 | 🟡 | 🏢 | W1 | S |
| **F3.7** | RAG pip installs swallow errors (2>/dev/null) | 03-infra: F3.7 | 🟡 | 🌐 | W1 | XS |
| **F3.8** | SearXNG docker run (not compose) — split management | 03-infra: F3.8 | 🟡 | 🌐 | W2 | M |
| **F3.9** | setup.conf re-sourced in service port loop | 03-infra: F3.9 | 🟡 | 🌐 | W1 | XS |
| **F3.10** | No Docker health checks for 10 services | 03-infra: F3.10 | 🟢 | 🌐 | W2 | M |
| **F3.11** | Sanitizer no log rotation — unbounded growth | 03-infra: F3.11 | 🟢 | 🏢 | W3 | XS |
| **S1** | No specs/ directory in project scaffold — SDD-core absent | 04-sdd: S1 | 🔴 | 🌐 | W2 | L |
| **S2** | SDD skills empty stubs — specify/plan/execute not in project | 04-sdd: S2 | 🔴 | 🌐 | W2 | L |
| **S3** | No spec:// URI scheme — agent correction costs 10x more tokens | 04-sdd + Redbook §2.1 | 🟠 | 🌐 | W2 | M |
| **S4** | WAL decisions unstructured — no rationale/alternatives/revisit-condition | 04-sdd + Redbook §3 | 🟠 | 🌐 | W2 | S |
| **S5** | Sync-from-Code protocol missing — code↔spec drift | 04-sdd + Redbook §3 | 🟡 | 🌐 | W2 | M |
| **S6** | No .opencode/commands/ with SDD slash-commands | 04-sdd | 🟠 | 🌐 | W2 | S |
| **A1** | ISOLATED_CIRCUIT leaks: telemetry, version checks, autoupdate unchecked | 05-corp: A1 | 🔴 | 🏢 | W3 | L |
| **A2** | No SOC2/ISO27001 audit trail: WAL not immutable, no retention | 05-corp: A2 | 🟠 | 🏢 | W3 | L |
| **A3** | Trivy/Qodana only installed, never run — no scheduled scan | 05-corp: A3 | 🟠 | 🏢 | W3 | M |
| **A4** | Sanitizer missing PII patterns: email, credit card, SSN | 05-corp: A4 | 🟡 | 🏢 | W3 | S |
| **A5** | No provider/model gate — corporate cannot restrict models | 05-corp: A5 | 🟠 | 🏢 | W3 | M |
| **A6** | Air-gap bootstrap impossible: Docker pull, npm, pip require network | 05-corp: A6 | 🟡 | 🏢 | W3 | L |
| **SK1** | Constitution.md — project principles, MUST/SHOULD governance | spec-kit gap#1 | 🟠 | 🌐 | W2 | M |
| **SK2** | FR-###/SC-### traceability — structured requirement IDs | spec-kit gap#2 | 🟠 | 🌐 | W2 | M |
| **SK3** | specs/ per-feature tree with full artifacts (spec/plan/tasks) | spec-kit gap#3 | 🔴 | 🌐 | W2 | L |
| **SK4** | Checklist gates — auto-block implement on FAIL | spec-kit gap#4 | 🟡 | 🏢 | W2 | M |
| **SK5** | /analyze — cross-artifact coverage with severity | spec-kit gap#5 | 🟡 | 🏢 | W2 | M |
| **SK6** | /converge — code↔spec sync, append remaining tasks | spec-kit gap#6 | 🟡 | 🌐 | W2 | M |
| **SK7** | [US]/[P] markers — user-story traceability in tasks | spec-kit gap#7 | 🟡 | 🏢 | W2 | S |
| **SK8** | data-model.md + contracts/ — Phase 1 mandatory artifacts | spec-kit gap#8 | 🟢 | 🏢 | W2 | M |
| **SK9** | specify init bootstrap — SDD infra in one command | spec-kit gap#9 | 🟡 | 🌐 | W2 | L |
| **SK10** | Extension/Preset plugin system for templates | spec-kit gap#10 | 🟢 | 🏢 | v3.2+ | L |
| **SK11** | taskstoissues — GitHub Issues sync | spec-kit gap#11 | 🟢 | 🏢 | v4.0 | L |
| **SK12** | TDD enforced in implement — tests before code | spec-kit gap#12 | 🟢 | 🏢 | v4.0 | M |
| **OS1** | Delta-based changes (ADDED/MODIFIED/REMOVED) for brownfield projects | OpenSpec core | 🟠 | 🌐 | W2 | L |
| **OS2** | Fluid workflow — update artifacts mid-implementation | OpenSpec action | 🟡 | 🌐 | W2 | M |
| **OS3** | Progressive rigor — lite vs full spec granularity | OpenSpec pattern | 🟡 | 🏢 | W2 | S |
| **OS4** | Explore-first habit — read code before writing artifacts | OpenSpec /opsx:explore | 🟡 | 🌐 | W2 | S |
| **OS5** | Human-in-the-loop review gate before implement | OpenSpec propose→review | 🟠 | 🏢 | W2 | M |
| **OS6** | Config injection — context + rules in all prompts | OpenSpec config.yaml | 🟡 | 🏢 | W2 | S |
| **OS7** | Slash-commands as skills — auto-generated per AI tool | OpenSpec 30+ tools | 🟡 | 🌐 | W2 | M |
| **OS8** | Parallel changes — multiple features in isolation | OpenSpec changes/ | 🟡 | 🏢 | W2 | M |
| **RB1** | spec:// URI addressing — stable requirement addresses | Redbook §2.1 | 🔴 | 🌐 | W2 | M |
| **RB2** | WAL as checkpoint (overwrite, ≤1 page, not append-only log) | Redbook §3 | 🟠 | 🌐 | W2 | S |
| **RB3** | "Decisions, not facts" — rationale + alternatives + revisit-condition | Redbook §3 | 🟠 | 🌐 | W2 | S |
| **RB4** | 4-level memory hierarchy: Head→WAL→Specs→Code | Redbook §3 | 🟠 | 🌐 | W2 | M |
| **RB5** | Sync-from-Code: human→diff→AI proposes spec update | Redbook §3 | 🟠 | 🌐 | W2 | M |
| **RB6** | IPC protocol: atomic commits, conflict markers "DO NOT TOUCH" | Redbook §2 | 🟠 | 🌐 | W2 | M |
| **RB7** | Agent vs Chat WAL precision — different formats | Redbook §3 | 🟡 | 🌐 | W3 | S |
| **RB8** | Lost-in-the-Middle-aware spec placement | Redbook §2.1 | 🟡 | 🌐 | W2 | XS |
| **AI1** | Governance Plane: quotas, budgets, audit of AI actions | AI-Native Infra §2 | 🔴 | 🏢 | W3 | L |
| **AI2** | LLM Gateway pattern: unified entry with circuit-breaker, rate-limit, cache | AI-Native Infra §3 | 🟠 | 🌐 | W3 | L |
| **AI3** | Observability 2.0: behavior signals (tool calls), cost signals | AI-Native Infra §4 | 🟠 | 🌐 | W4 | M |
| **AI4** | Context-as-Infrastructure: KV-cache reuse, context tier | AI-Native Infra §7 | 🟡 | 🌐 | W4 | L |
| **AI5** | Budget-triggered policies — cost → rate-limit → degrade | AI-Native Infra §5 | 🟠 | 🏢 | W3 | M |
| **AI6** | 8-layer observability stack (GPU→Token→Business) | AI-Native Infra §4 | 🟡 | 🏢 | W4 | L |
| **CP1** | Lifecycle hooks (before/after tool) — Claude Code/Kimi gap | Competitive §1 | 🟠 | 🏢 | W4 | L |
| **CP2** | Agent SDK / sub-agent runtime dispatch — Claude Code/OpenCode gap | Competitive §2 | 🟠 | 🌐 | W4 | L |
| **CP3** | Scheduled agent tasks (Routines-alike) — systemd timers | Competitive §5 | 🟡 | 🌐 | W4 | M |
| **CP4** | Audit trail for tool calls — full accountability | Competitive §4 | 🟠 | 🏢 | W3 | M |
| **CP5** | Team collaboration / session sharing | Competitive §4 | 🟡 | 🏠 | v4.0 | L |
| **OS9** | OpenSpec stores (cross-repo planning) — beta, not for v3.0 | OpenSpec stores | — | 🏢 | v4.0 | L |

## Severity Summary

| Severity | Count | Key Focus |
|----------|:-----:|-----------|
| CRITICAL 🔴 | 9 | Core reliability (F1, F2) + SDD absence (S1, S2, SK3) + governance gap (AI1, A1) + SSOT (C1, C2) + security (F3.1, F3.2) |
| HIGH 🟠 | 24 | Foundation quality, SDD features (constitution, traceability, spec:// URI), enterprise readiness, model governance |
| MEDIUM 🟡 | 26 | Quality-of-life, brownfield workflow, observability, progressive adoption, IPC protocol |
| LOW 🟢 | 9 | Cosmetic (F9-F12), long-term extensions (SK10-SK12, CP5) |

## Wave-to-Finding Mapping

| Wave | Theme | Count | Est. Days | Key Deliverables |
|:----:|-------|:-----:|:---------:|------------------|
| **W1** | Foundations & Fixes | 29 | 10-14 | Per-step recovery, atomic WAL, SSOT registry, infra security, auto-passwords, Docker IP fix |
| **W2** | SDD Core | 28 | 14-21 | specs/ + constitution.md + templates + commands + delta-changes + spec:// URI + WAL v2 + 17-project rebuild |
| **W3** | Enterprise & Governance | 14 | 10-14 | Policy engine (H1, A5), ISOLATED_CIRCUIT seals (A1, A6), audit trail (A2, CP4), PII patterns (A4) |
| **W4** | Hooks & Automation | 5 | 7-10 | Lifecycle hooks (CP1), Agent SDK (CP2), scheduled tasks (CP3), observability 2.0 (AI3) |
| **W5** | Release v3.0.0 | — | 5-7 | Docs, migration guide v2→v3, test suite ≥200 assertions, health-mode for new features, changelog |
| **v3.2+** | Extensions | 5 | future | Extension/Preset plugin system, TDD enforcement, taskstoissues, team sharing, cross-repo stores |

## Notes

- **Дедупликация**: C1 из 02-provider-model-layer.md дублируется в provider-layer.md (линза) — сведён в одну строку
- S3 и S4 объединены с Redbook-аналогами (RB1, RB3) — указаны оба источника
- spec-kit gaps SK11 (taskstoissues), SK12 (TDD) → v4.0 как non-core
- CP5 (team sharing), OS9 (stores) → v4.0, не блокируют v3.0
- Из 67 находок: 12 core fixes, 22 SDD buildout, 8 enterprise, 5 automation, 4 release, 16 deferred
