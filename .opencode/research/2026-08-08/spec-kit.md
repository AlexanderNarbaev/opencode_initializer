# Дайджест: GitHub Spec-Kit — Анализ для пересборки opencode_initializer

> **Источник:** https://github.com/github/spec-kit (commit 684b3d8)
> **Дата анализа:** 2026-08-08T14:00Z | **Исследователь:** Planner (T2.1)
> **Объём:** README, spec-driven.md, AGENTS.md, 4 шаблона, 3 команды, sdd.md

---

## 1. Философия SDD по spec-kit

### Корневая идея: «Спецификация как исполняемый артефакт»

Spec-Driven Development **инвертирует** традиционную модель: код больше не «король». Спецификация — первичный артефакт, код — её выражение в конкретном языке/фреймворке.

> «Specifications don't serve code — code serves specifications.» — spec-driven.md

**Три ключевых принципа:**
1. **Intent-driven development**: спецификация определяет *что* и *почему*, а не *как*
2. **Multi-step refinement**: не one-shot генерация, а итеративное уточнение: идея → PRD-диалог → спецификация → план → задачи → реализация
3. **AI как транслятор**: AI понимает спецификацию и генерирует из неё код; структура процесса предотвращает хаос

### Почему SDD важен сейчас

- **AI-возможности достигли порога**: NL-спецификации надёжно генерируют рабочий код
- **Экспоненциальный рост сложности**: десятки сервисов — ручное выравнивание намерений и реализации невозможно
- **Скорость изменений**: пивоты — норма; SDD превращает их из сбоев в нормальный workflow

---

## 2. Полный workflow: 8 команд

### Основной конвейер (Core Commands)

| # | Команда | Роль | Вход | Выход |
|---|---------|------|------|-------|
| 1 | `/speckit.constitution` | Принципы проекта | Идея/ценности от пользователя | `memory/constitution.md` (MUST/SHOULD правила) |
| 2 | `/speckit.specify` | Спецификация | NL-описание фичи | `specs/[###-feature]/spec.md` (User Stories, FR-###, SC-###, edge cases) |
| 3 | `/speckit.clarify` | Уточнение (опц.) | `spec.md` | Обновлённый `spec.md` (1–5 вопросов → ответы) |
| 4 | `/speckit.plan` | Технический план | `spec.md` + стек | `plan.md`, `research.md`, `data-model.md`, `contracts/`, `quickstart.md` |
| 5 | `/speckit.tasks` | Декомпозиция | `plan.md` + `spec.md` | `tasks.md` (фазы: Setup→Foundational→Stories→Polish) |
| 6 | `/speckit.analyze` | Валидация (опц.) | `spec.md` + `plan.md` + `tasks.md` | Отчёт coverage/inconsistency/ambiguity (CRITICAL/HIGH/MEDIUM/LOW) |
| 7 | `/speckit.implement` | Реализация | `tasks.md` | Код + тесты (TDD, фаза за фазой) |
| 8 | `/speckit.converge` | Синхронизация | Код vs spec/plan/tasks | Обновлённый `tasks.md` (append оставшейся работы) |

### Файловая структура после `specify init`

```
my-project/
├── .specify/
│   ├── templates/          # Шаблоны (ядро/расширения/пресеты/оверрайды)
│   ├── memory/constitution.md
│   └── integrations/       # Манифесты (SHA-256 per file)
├── specs/[###-feature]/
│   ├── spec.md, plan.md, tasks.md
│   ├── research.md, data-model.md, quickstart.md
│   ├── contracts/, checklists/
└── .claude/commands/       # Слеш-команды агента
```

---

## 3. Структура шаблонов и трассировка требований

### spec-template.md — обязательные секции

| Секция | Содержание |
|--------|------------|
| **User Scenarios & Testing** | User Stories с приоритетами (P1/P2/P3), Acceptance Scenarios (Given/When/Then), Independent Test |
| **Edge Cases** | Граничные и ошибочные сценарии |
| **Functional Requirements (FR-###)** | MUST/SHOULD требования с уникальными ID |
| **Success Criteria (SC-###)** | Измеримые, технологически-нейтральные критерии |
| **Assumptions** | Допущения о пользователях, окружении, scope |

### Трассировка: FR-### → SC-### → User Story → Acceptance Scenario → Task
`/speckit.analyze` проверяет: каждое FR должно иметь ≥1 задачи, каждая задача — отображаться на FR/story.

### tasks-template.md — фазы и маркеры

1. **Phase 1: Setup** — инициализация проекта
2. **Phase 2: Foundational** — БЛОКИРУЕТ все user stories
3. **Phase 3+: User Stories** — по фазе на story, с `[US1]`/`[US2]` метками
4. **Phase N: Polish** — кросс-каттинг

- `[P]` = можно параллелить (разные файлы, нет зависимостей)
- TDD: тесты ПЕРВЫМИ, должны FAIL, затем реализация

---

## 4. Интеграция с агентами

### Архитектура: 30+ агентов через plugin-систему

```
src/specify_cli/integrations/
├── __init__.py          # INTEGRATION_REGISTRY
├── base.py              # MarkdownIntegration, TomlIntegration, SkillsIntegration...
├── claude/              # Claude (MarkdownIntegration)
├── gemini/              # Gemini CLI (TomlIntegration)
├── codex/               # Codex CLI (SkillsIntegration — директории SKILL.md)
├── copilot/             # GitHub Copilot (кастомный IntegrationBase)
└── ...                  # Ещё 26+
```

### Как работает `specify init`
1. Копирует шаблоны в `.specify/templates/`
2. Генерирует агент-специфичные команды: слеш-команды (`/speckit.*`) или skills (`speckit-*/SKILL.md`)
3. `IntegrationManifest` записывает SHA-256 каждого файла → безопасный uninstall

### Расширяемость (4-уровневый приоритет)
1. `.specify/templates/overrides/` — локальные оверрайды
2. `.specify/presets/templates/` — пресеты (меняют формат/стиль)
3. `.specify/extensions/templates/` — расширения (новые команды)
4. `.specify/templates/` — ядро

**Extensions** = новые возможности (Jira, code review). **Presets** = кастомизация (compliance, язык). **Bundles** = ролевые наборы (PM, Developer, Security Researcher).

---

## 5. Что КРИТИЧНО перенять в opencode_initializer

### Текущее состояние (v2.0.3)
Уже есть: `17-project.sh` (AGENTS.md, skills, WAL, docker-compose), skills `specify/plan/execute/clarify/critic-gate/phase-wrap/loop/council`, `37-wal.sh`, `40-best-practices.sh`.

### Gap-матрица (12 пунктов)

| # | Gap | Статус | Приоритет |
|---|-----|--------|:--------:|
| 1 | **constitution.md** — принципы проекта, governance, MUST/SHOULD | ❌ | 🔴 v3.0 |
| 2 | **FR-###/SC-### с ID** — структурированная трассировка требований | ❌ | 🔴 v3.0 |
| 3 | **specs/ дерево** — изоляция фич с полным набором артефактов | ⚠️ (.opencode/ — сессионный, не фича) | 🔴 v3.0 |
| 4 | **checklists как gate** — автоматическая блокировка implement при FAIL | ❌ | 🟡 v3.1 |
| 5 | **`/analyze`** — кросс-артефактный coverage-анализ с severity | ⚠️ (critic-gate — без матрицы) | 🟡 v3.1 |
| 6 | **`/converge`** — сверка кода со spec/plan/tasks, append задач | ❌ | 🟡 v3.1 |
| 7 | **[US], [P]-маркеры** — user-story-трассировка в задачах | ⚠️ (M/T/S — без story-меток) | 🟡 v3.1 |
| 8 | **data-model.md + contracts/** — обязательные Phase 1 артефакты | ⚠️ (ad-hoc) | 🟢 v3.2 |
| 9 | **`specify init` bootstrap** — SDD-инфраструктура одной командой | ⚠️ (17-project.sh — не SDD) | 🟢 v3.2 |
| 10 | **Extension/Preset система** — plugin-архитектура шаблонов | ❌ | 🟢 v3.2 |
| 11 | **taskstoissues** — GitHub Issues sync | ❌ | 🔵 v4.0 |
| 12 | **TDD в implement** — форсирование «тесты до кода» | ⚠️ | 🔵 v4.0 |

---

## 6. Оценка: сила и слабость

### Сильные стороны spec-kit ✅

- **Полный замкнутый цикл**: 8 команд от идеи до converge
- **Формальная трассировка**: FR→SC→Story→Task→Code с coverage-анализом
- **30+ интеграций**: plugin-архитектура без изменения ядра
- **4-уровневая расширяемость**: Overrides→Presets→Extensions→Core
- **Манифест-безопасность**: SHA-256 трекинг, безопасный uninstall
- **TDD из коробки**: implement форсирует тесты до кода
- **Checklist-gate**: автоматическая блокировка implement при FAIL
- **Converge для brownfield**: решение проблемы рассинхрона
- **CLI specify**: самодостаточный Python-пакет

### Слабые стороны spec-kit ❌ → Наши преимущества ✅

| Слабость spec-kit | Наше решение |
|-------------------|-------------|
| Python-only CLI (Python 3.11+, uv) | Bash-native setup.sh — одна команда |
| Нет изоляции провайдеров/моделей | 22 провайдера + model-router (`36-model-router.sh`) |
| Нет PII/аудита | Нужно добавить в v3.0 |
| Нет WAL / session journal | `37-wal.sh` — уже есть |
| Нет multi-agent оркестрации | `dispatching-parallel-agents`, `council`, 4-агентная модель |
| Нет air-gap / isolated circuit | `32-isolated.sh` — уникальная фича |
| Нет observability | `34-observability.sh` + Grafana/Prometheus |
| Нет docker-инфраструктуры | `30-infra.sh`, `33-services.sh` — из коробки |
| Нет RAG | `21-rag.sh` + Qdrant + MemoryLayer |

### Итоговая стратегия для v3.0

**Перенять SDD-цикл** (constitution → specify → clarify → plan → tasks → analyze → implement → converge), **адаптировать под shell/bash**, **дополнить нашими уникальными возможностями** (multi-model routing, isolated circuit, WAL, infra-as-code, аудит, RAG).

---

## Источники

| Файл | URL |
|------|-----|
| README.md | https://github.com/github/spec-kit |
| spec-driven.md | https://github.com/github/spec-kit/blob/main/spec-driven.md |
| AGENTS.md | https://github.com/github/spec-kit/blob/main/AGENTS.md |
| concepts/sdd.md | https://github.com/github/spec-kit/blob/main/docs/concepts/sdd.md |
| spec-template.md | https://github.com/github/spec-kit/blob/main/templates/spec-template.md |
| plan-template.md | https://github.com/github/spec-kit/blob/main/templates/plan-template.md |
| tasks-template.md | https://github.com/github/spec-kit/blob/main/templates/tasks-template.md |
| commands/clarify.md | https://github.com/github/spec-kit/blob/main/templates/commands/clarify.md |
| commands/implement.md | https://github.com/github/spec-kit/blob/main/templates/commands/implement.md |
| commands/analyze.md | https://github.com/github/spec-kit/blob/main/templates/commands/analyze.md |
