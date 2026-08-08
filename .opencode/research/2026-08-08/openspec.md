# Дайджест: Fission-AI/OpenSpec

> **Источник:** https://github.com/Fission-AI/OpenSpec (commit e50bd09)
> **Дата дайджеста:** 2026-08-08
> **Пакет:** `@fission-ai/openspec` (npm, MIT)
> **Требования:** Node.js ≥ 20.19.0
> **Модель:** `specs/` (истина) + `changes/` (дельта-предложения)

---

## 1. Философия и модель

OpenSpec построен на четырёх принципах:

```
fluid not rigid          — нет жёстких фаз, работай в любом порядке
iterative not waterfall  — учись по ходу, уточняй по мере понимания
easy not complex         — лёгкий старт, минимум церемоний
brownfield-first         — для существующих кодовых баз, не только greenfield
```

### Две зоны — ядро модели

```
openspec/
├── specs/          ← ИСТИНА: как система работает СЕЙЧАС
│   └── auth/
│       └── spec.md   (требования + сценарии)
│
├── changes/        ← ДЕЛЬТА-ПРЕДЛОЖЕНИЯ: что меняется
│   └── add-dark-mode/
│       ├── proposal.md    (почему и что)
│       ├── design.md      (как, технически)
│       ├── tasks.md       (план реализации)
│       └── specs/         (дельта-спеки — ADDED/MODIFIED/REMOVED)
│           └── ui/
│               └── spec.md
│
└── config.yaml      ← контекст проекта, правила
```

**Ключевое отличие от spec-kit**: OpenSpec НЕ требует описывать весь проект. Спеки растут органически — каждый заархивированный change вливает свою дельту в `specs/`. Первый change документирует только тот срез, который затронул.

### Жизненный цикл changes

```
/opsx:explore → /opsx:propose → /opsx:apply → /opsx:sync → /opsx:archive
   (опционально)   (план)       (реализация)  (слить дельты) (архив)
```

Архивированные changes попадают в `changes/archive/YYYY-MM-DD-<name>/` — сохраняя полный контекст: proposal, задачи, дельты.

---

## 2. Форматы файлов

### proposal.md — намерение и границы
```markdown
# Proposal: Add Dark Mode
## Intent — проблема, которую решаем
## Scope — in/out of scope
## Approach — технический подход (один абзац)
```

### specs/<capability>/spec.md — дельта-спека
```markdown
## ADDED Requirements
### Requirement: Dark Mode Toggle
The system SHALL let a user switch between light and dark themes.

#### Scenario: Respects the OS preference on first load
- GIVEN a user who has never set a theme
- WHEN they open the app on a device set to dark mode
- THEN the app renders in dark mode

## MODIFIED Requirements
### Requirement: Theme Persistence
The system SHALL persist the user's theme choice in localStorage.
(ранее было в cookie — полный новый текст требования)

## REMOVED Requirements
### Requirement: Legacy Theme API
(удаляется, причина описана)
```

Три типа дельт:
- **ADDED** — новое поведение (на archive: добавляется в specs/)
- **MODIFIED** — изменение существующего (на archive: заменяет старую версию)
- **REMOVED** — удаление (на archive: удаляется из specs/; если последнее требование capability — retire_capabilities)

Формат сценариев: **GIVEN/WHEN/THEN** с ключевыми словами RFC 2119 (SHALL/MUST/SHOULD/MAY).

### design.md — технический подход
```markdown
# Design: Add Dark Mode
## Technical Approach — контекст, библиотеки, архитектурные решения
```

### tasks.md — чек-лист реализации
```markdown
- [ ] 1.1 Add ThemeContext provider
- [ ] 1.2 Create ThemeToggle component
- [ ] 2.1 Add CSS custom properties
```

---

## 3. CLI и команды агента

OpenSpec разделён на две половины:

| Половина | Где запускается | Примеры |
|----------|----------------|---------|
| **CLI** (`openspec ...`) | Терминал | `openspec init`, `openspec list`, `openspec validate --all --json`, `openspec archive` |
| **Slash-команды** (`/opsx:...`) | Чат AI-ассистента | `/opsx:propose`, `/opsx:apply`, `/opsx:archive` |

`openspec init` генерирует skill-файлы и command-файлы в директории инструментов AI (`.claude/skills/`, `.cursor/commands/`, `.opencode/skills/` и т.д. — поддержано 30+ инструментов, включая OpenCode).

### Core-профиль (по умолчанию)
| Команда | Что делает |
|---------|-----------|
| `/opsx:explore` | Исследовать проблему, понять код, не пишет артефактов |
| `/opsx:propose` | Создать change + все planning-артефакты |
| `/opsx:apply` | Реализовать по tasks.md |
| `/opsx:update` | Обновить planning-артефакты, сохраняя когерентность |
| `/opsx:sync` | Слить дельта-спеки в specs/ |
| `/opsx:archive` | Заархивировать завершённый change |

### Expanded-профиль
`/opsx:new`, `/opsx:continue`, `/opsx:ff`, `/opsx:verify`, `/opsx:bulk-archive`, `/opsx:onboard`

### Валидация (CLI)
```bash
openspec validate --all --json        # все changes + specs
openspec validate --strict             # строгая проверка
```
Валидация проверяет: структуру секций (ADDED/MODIFIED/REMOVED), наличие SHALL/MUST, соответствие сценариев требованиям, конфликты дельт.

---

## 4. Сравнение OpenSpec ↔ spec-kit

| Измерение | OpenSpec | spec-kit (GitHub) |
|-----------|----------|-------------------|
| **Философия** | Fluid, iterative, brownfield-first | Rigid phases, greenfield-first |
| **Фазы** | Actions (propose→apply→archive), не locked | Фиксированные фазы (specify→plan→tasks→implement) |
| **Спеки** | Дельта-спеки (ADDED/MODIFIED/REMOVED) | Полные спеки (spec.md) + plan.md + tasks.md |
| **Обновление плана** | `/opsx:update` в любой момент, ripple to other artifacts | Перезапись spec → plan → tasks |
| **Запуск** | `npm install -g` + `openspec init` | Python setup, больше шаблонов |
| **Интеграция с AI** | Slash-команды через skills/commands (30+ tools) | Slash-команды + промпты (Claude Code, Copilot, Gemini, Codex) |
| **Вес** | Лёгкий, Markdown-only | Тяжелее: больше Markdown, Python, constitution.md, research.md |
| **Кросс-репо (stores)** | Beta: отдельный репо для planning, shared across teams | Нет аналога |
| **Кастомизация** | schema.yaml + templates + config.yaml (context injection) | Шаблоны в extensions/ |
| **Сильные стороны** | Brownfield, итеративность, параллельные changes, stores | Полный SDD-цикл, constitution, качество шаблонов |
| **Слабые стороны** | Бета-версия stores, нет constitution.md, зависимость от AI-ассистента | Тяжеловесность, жёсткие фазы, greenfield-bias |

### Где OpenSpec сильнее spec-kit:
1. **Brownfield-first**: дельта-подход не требует описывать всю систему upfront — спеки растут с каждым change
2. **Fluid workflow**: можно обновить design в середине реализации, и `/opsx:update` отрикошетит изменения в proposal
3. **Параллельные changes**: несколько изменений одновременно, без конфликтов — каждый в своей папке
4. **30+ AI-инструментов**: универсальная генерация skills/commands под конкретный инструмент
5. **Stores (beta)**: планирование в отдельном репо, разделяемое между продуктовыми командами

### Где OpenSpec слабее spec-kit:
1. **Нет constitution.md** — у spec-kit есть декларация принципов проекта, которая инжектится во все промпты
2. **Меньше встроенных шаблонов** — spec-kit даёт более детальные templates для research.md, data-model.md, contracts/
3. **Stores в бете** — нестабильный API, не для production
4. **Лёгкость = меньше структуры** — для крупных корпоративных проектов может не хватать формализма

---

## 5. Что перенять в opencode_initializer

### 5.1. Delta-based changes для brownfield-проектов
Наш проект `17-project.sh` (create-project) генерит структуру проекта. Сейчас он создаёт статический `AGENTS.md`. Нужно:

- Генерировать `openspec/` (или `specs/`) директорию с `changes/ + specs/` структурой
- Добавить шаблоны `proposal.md`, `design.md`, `tasks.md`, `spec.md` (дельта)
- Встроить в AGENTS.md команды: `/propose`, `/apply`, `/archive`

### 5.2. Config injection (context + rules)
```yaml
# openspec/config.yaml
context: |
  Tech stack: TypeScript, React, Node.js
  Testing: Vitest + Playwright
rules:
  proposal:
    - Include rollback plan
  specs:
    - Use Given/When/Then
```
Этот контекст инжектится во все артефакты через `<context>...</context>` теги. Для `18-opencode-json.sh` — аналог: в opencode.json добавить `project_context` или `sdd` секцию.

### 5.3. Slash-команды как skills (а не хардкод)
OpenSpec генерит `.opencode/skills/openspec-propose/SKILL.md` — и AI автоматически подхватывает. У нас уже есть навыки в `.opencode/skills/` (specify, plan, execute) — нужно привести их к модели OpenSpec: не жёсткие фазы, а actions с dependencies.

### 5.4. Review loop: propose → review → apply → verify → archive
Ключевой цикл:
- **propose**: AI пишет proposal + specs → человек REVIEWS (2 минуты)
- **apply**: AI реализует → `/opsx:verify` проверяет completeness/correctness/coherence
- **archive**: дельты вливаются в specs/

У нас review размазан по Reviewer-агенту — но нет явного human-in-the-loop перед имплементацией. Нужно встроить этот шаг.

### 5.5. Progressive rigor (lite vs full spec)
Большинство changes — lite: короткие behaviour-first требования + сценарии. Full spec — только для кросс-командных, security, migration. У нас сейчас нет градации — все changes идут через один и тот же процесс.

### 5.6. Explore-first habit
`/opsx:explore` — AI читает код, не пишет артефактов, задаёт вопросы. Это должно стать дефолтным первым шагом в нашем workflow.

---

## 6. Критика и слабые места

| Проблема | Детали |
|----------|--------|
| **Stores в бете** | Кросс-репо планирование нестабильно, API меняется. |
| **Нет версионирования дельт** | Если два changes трогают один spec — нужен ручной резолв через `/opsx:bulk-archive`. |
| **Зависимость от AI-ассистента** | Без AI слэш-команды бесполезны. CLI покрывает только setup/validate/archive. |
| **Нет constitution.md** | Нет декларативного «это наш проект — вот его принципы», который инжектится во все промпты. |
| **Лёгкость = риск недостаточной формализации** | Для regulated environments (fintech, healthcare) может не хватать traceability. |
| **Только Markdown** | Нет structured форматов (JSON Schema, OpenAPI) для валидации. Валидация — структурная (секции), не семантическая. |
| **Retire_capabilities — ручной флаг** | Удаление capability требует `.openspec.yaml` с `retire_capabilities: true` — легко забыть. |
| **OpenCode-интеграция** | OpenCode есть в списке supported tools, но команды генерируются как `/openspec-propose` (через `.agents/skills/`), а не нативные `/opsx:propose`. |

---

## 7. Итоговая оценка для v3.0

**OpenSpec — лучший кандидат на роль SDD-движка для opencode_initializer по следующим причинам:**

1. **Brownfield-first**: наши пользователи ставят харнесс на СУЩЕСТВУЮЩИЕ проекты — дельта-модель идеальна.
2. **Fluid workflow**: корпоративные пользователи не хотят жёстких фаз — им нужно обновлять планы на лету.
3. **30+ AI-инструментов**: наша аудитория использует разные ассистенты — генерация skills под каждый.
4. **Stores (когда выйдет из беты)**: для корпоративных closed-loop контуров — отдельный planning-репо, аудит-трейл.

**Что взять у spec-kit (чего нет в OpenSpec):**
- Constitution.md (декларация принципов проекта)
- Более богатые шаблоны (research.md, data-model.md, contracts/)
- Более строгую трассировку требований

**Рекомендация**: взять ядро OpenSpec (delta-changes + specs + artifacts) как базовую модель, дополнить constitution.md из spec-kit, и построить нативный OpenCode-воркфлоу (без зависимости от npm-пакета `@fission-ai/openspec` — реализовать аналогичную логику в bash/skills для `17-project.sh`).

---

## Источники
- https://github.com/Fission-AI/OpenSpec (README, AGENTS.md, docs/)
- https://raw.githubusercontent.com/Fission-AI/OpenSpec/main/docs/concepts.md
- https://raw.githubusercontent.com/Fission-AI/OpenSpec/main/docs/writing-specs.md
- https://raw.githubusercontent.com/Fission-AI/OpenSpec/main/docs/cli.md
- https://raw.githubusercontent.com/Fission-AI/OpenSpec/main/docs/workflows.md
- https://raw.githubusercontent.com/Fission-AI/OpenSpec/main/docs/opsx.md
- https://raw.githubusercontent.com/Fission-AI/OpenSpec/main/docs/existing-projects.md
- https://raw.githubusercontent.com/Fission-AI/OpenSpec/main/docs/how-commands-work.md
- https://raw.githubusercontent.com/Fission-AI/OpenSpec/main/docs/reviewing-changes.md
