# M2 → M3 Cross-Reference: все research-рекомендации в одном месте

> **Дата:** 2026-08-08 | **Автор:** Planner | **Назначение:** входной документ для T3.1 (Gap Matrix)

---

## Сводка: что все 5 источников говорят внедрить

### 🔴 P0 — Безопасность и корпоративный контур (из всех источников)

| # | Рекомендация | Источник | Куда |
|:--|-------------|----------|------|
| 1 | **Lifecycle hooks** (before/after tool execution) | competitive.md, redbook.md | новый модуль hooks.sh |
| 2 | **Prompt injection protection** | ai-native-infra.md | 24-websearch.sh + новый gateway |
| 3 | **Gateway-level политики** (model allowlist/blocklist, per-project, per-user) | competitive.md, ai-native-infra.md | 36-model-router.sh → model-gateway.sh |
| 4 | **ACL-aware RAG retrieval** | ai-native-infra.md | 21-rag.sh |
| 5 | **Audit trail** (structured, SOC2-ready, не просто JSONL) | competitive.md, ai-native-infra.md | 37-wal.sh → audit.sh |

### 🟡 P1 — SDD-native workflow (spec-kit + OpenSpec + redbook)

| # | Рекомендация | Источник | Куда |
|:--|-------------|----------|------|
| 6 | **constitution.md** — принципы проекта, governance | spec-kit.md | 17-project.sh |
| 7 | **spec.md формат** — FR/SC/NFR, GIVEN/WHEN/THEN, delta-секции | spec-kit.md, openspec.md | skills/specify + 17-project.sh |
| 8 | **plan.md + tasks.md** — декомпозиция с маркерами [P] | spec-kit.md | skills/plan + skills/execute |
| 9 | **spec:// URI-адресация** — ссылки на секции спеку | redbook.md | 17-project.sh |
| 10 | **Delta-based changes** (ADDED/MODIFIED/REMOVED) | openspec.md | skills/specify |
| 11 | **Commit с Решения/Отброшено/Ограничения** | redbook.md | 40-best-practices.sh |

### 🟢 P2 — Developer Experience (competitive + redbook)

| # | Рекомендация | Источник | Куда |
|:--|-------------|----------|------|
| 12 | **Sub-agent dispatch из TUI** (@ mention) | competitive.md | opencode.json agents |
| 13 | **Agent SDK** — кастомные агенты пользователем | competitive.md | новый модуль agent-sdk.sh |
| 14 | **Team collaboration** (/share сессий) | competitive.md | 35-gui.sh или новый |
| 15 | **Scheduled agent tasks** (systemd timers для агентских задач) | competitive.md | 20-autoupdate.sh → agent-scheduler.sh |

### 🔵 P3 — Observability & AI-Infra (ai-native-infra + redbook)

| # | Рекомендация | Источник | Куда |
|:--|-------------|----------|------|
| 16 | **LLM observability** — tool call tracing, cost signals, eval metrics | ai-native-infra.md | 34-observability.sh |
| 17 | **Model cascading** (cheap→expensive fallback) | ai-native-infra.md | 36-model-router.sh |
| 18 | **Семантическое кэширование** | ai-native-infra.md | 36-model-router.sh |
| 19 | **WAL как checkpoint с Delta-секциями** | redbook.md | 37-wal.sh |
| 20 | **Hybrid search** (dense + sparse) для RAG | ai-native-infra.md | 21-rag.sh |
| 21 | **GPU sharing / multi-tenant изоляция** | ai-native-infra.md | 32-isolated.sh |

---

## Консолидированный список новых модулей v3.0

| Модуль | Назначение | Приоритет | Источники |
|--------|-----------|:---------:|-----------|
| `hooks.sh` | Lifecycle hooks (before/after tool, events) | 🔴 P0 | competitive, redbook |
| `model-gateway.sh` | Model allowlist/blocklist, per-project policies | 🔴 P0 | competitive, ai-infra |
| `audit.sh` | Structured audit trail (SOC2-ready) | 🔴 P0 | competitive, ai-infra |
| `agent-sdk.sh` | Custom agent creation toolkit | 🟢 P2 | competitive |
| `agent-scheduler.sh` | Scheduled agent tasks via systemd | 🟢 P2 | competitive |
| `spec-kit.sh` | SDD bootstrap (constitution + spec/plan/tasks templates) | 🟡 P1 | spec-kit, openspec |

---

## Удаляемые / заменяемые модули

| Модуль | Судьба | Причина |
|--------|--------|---------|
| `38-ide-plugins.sh` | Заменить на agent-sdk.sh | Copilot+DevoxxGenie → native agent SDK |
| `37-wal.sh` | Расширить → audit.sh | WAL → полноценный audit trail |
| `36-model-router.sh` | Расширить → model-gateway.sh | routing → routing + политики + cascading + кэш |

---

## Модули, которые остаются без изменений

32 из 43 модулей сохраняются как есть (языковой тулинг, Docker, ZSH, безопасность, RAG-ядро, Cockpit, GUI, WebUI, SearXNG, dotfiles, chezmoi, Devbox, mise).

---

## Ключевой архитектурный инсайт (из competitive.md)

> opencode_initializer — не coding agent, а **платформа**. Конкуренты (Claude Code, Codex, Kimi) — агенты. Мы — инфраструктура, на которой агенты работают. v3.0 должен добавить то, чего нет у конкурентов как платформы: lifecycle hooks, audit trail, model governance — и сохранить уникальные козыри (22 provider, isolated circuit, RAG, cockpit, infra-as-code).
