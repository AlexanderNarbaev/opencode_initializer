# SDD Workflow Specification v3.0

> **Дата:** 2026-08-08 | **Источники:** spec-kit AGENTS.md, OpenSpec writing-specs.md, Redbook (two-process + shared-state + memory), T1.4 audit, gap-matrix G01–G04, G08
> **Цель:** Формализовать полный SDD-цикл для opencode_initializer, интегрируя лучшие практики конкурентов

---

## 1. Полный цикл: 8 фаз

```
constitution → specify → clarify → plan → tasks → implement → verify → converge
     ↑                                                                    │
     └──────────────────── feedback loop ─────────────────────────────────┘
```

| # | Фаза | Вход | Выход | Владелец |
|---|------|------|-------|----------|
| 1 | **Constitution** | Пустой проект | `constitution.md` | Человек |
| 2 | **Specify** | `constitution.md` + идея | `specs/spec.md` (FR/SC/NFR) | Человек + AI |
| 3 | **Clarify** | `spec.md` с маркерами `[CLARIFY]` | `spec.md` без маркеров | AI → Человек |
| 4 | **Plan** | `spec.md` (утверждён) | `plan.md` (M/T/S hierarchy) | AI → Человек |
| 5 | **Tasks** | `plan.md` | `.opencode/tasks.md` (атомарные S) | AI |
| 6 | **Implement** | `tasks.md` + `spec.md` | Code + tests + docs | AI |
| 7 | **Verify** | Code changes | Review findings, test results | AI (Reviewer) |
| 8 | **Converge** | Все S данной фазы = [x] | Phase complete → WAL + audit | AI (Reviewer) |

---

## 2. Формат спецификаций: FR/SC/NFR

### Структура `specs/spec.md`

```markdown
# Spec: [Feature Name]

> **Version:** 1.0.0 | **Status:** draft | **Author:** @user

## Functional Requirements (FR)

### FR-001: [Requirement Name]
**Priority:** MUST | **Depends:** none
The system SHALL [behaviour].

#### Scenario: Happy Path
- GIVEN [precondition]
- WHEN [action]
- THEN [expected outcome]

#### Scenario: Error Case
- GIVEN [precondition]
- WHEN [error action]
- THEN [error handling]

### FR-002: [Requirement Name]
...

## Success Criteria (SC)

### SC-001: [Criterion Name]
**Measured by:** [metric]
**Target:** [value]
- GIVEN [condition]
- WHEN [measurement trigger]
- THEN [metric within target]

## Non-Functional Requirements (NFR)

### NFR-001: Performance
**Target:** [e.g. p95 < 200ms]
...

### NFR-002: Security
**Target:** [e.g. OWASP Top 10 covered]
...

## Technical Decisions
| Decision | Rationale | Alternatives Considered | Revisit When |
|----------|-----------|------------------------|--------------|
| Use PostgreSQL | Mature, typed, ACID | SQLite (no concurrent writes), MongoDB (no joins) | >1000 writes/sec |

## Delta (brownfield only)
### ADDED
- FR-003: New payment flow

### MODIFIED
- FR-001: Changed timeout from 30s → 60s (VPN latency data from logs/vpn-test.csv)

### REMOVED
- FR-005: Deprecated Moonshot integration (provider discontinued)
```

### Идентификаторы

- **FR-###**: Functional Requirement (MUST/SHOULD/MAY)
- **SC-###**: Success Criterion (измеримый)
- **NFR-###**: Non-Functional Requirement (Performance, Security, Accessibility)
- **TD-###**: Technical Decision (ADR-light, с условиями пересмотра)

---

## 3. Task Decomposition: M/T/S канон

### Формат `.opencode/tasks.md`

```markdown
# Tasks: [Feature/Phase Name]

> **Source:** specs/spec.md | **Plan:** plan.md

## M1: [Milestone] | status: in_progress

### T1.1: [Task] | agent:Worker | depends:none
- [ ] S1.1.1: [Atomic subtask] | size:S | [P0]
- [ ] S1.1.2: [Atomic subtask] | size:M | [P1]

### T1.2: [Task] | agent:Worker | depends:T1.1
- [ ] S1.2.1: [Atomic subtask] | size:XS | [P0]
```

### Правила декомпозиции

| Правило | Описание |
|---------|----------|
| **Атомарность** | S = 15–60 минут работы, один файл/концепт |
| **Приоритеты** | `[P0]` security/critical path, `[P1]` core, `[P2]` quality, `[P3]` polish |
| **Размеры** | XS (5 мин), S (15 мин), M (30–60 мин), L (2+ ч → декомпозировать) |
| **Зависимости** | `depends:T1.1,T1.2` — блокирует старт пока зависимости не [x] |
| **Трассировка** | Каждый S ссылается на FR/SC: `S1.1.1: Add login endpoint [FR-001, SC-001]` |

---

## 4. Delta-секции для brownfield проектов

Для существующих проектов (не greenfield) используется delta-модель из OpenSpec:

```markdown
## Delta: Add Payment Flow
> **Change ID:** CHG-2026-001 | **Status:** proposed

### ADDED
- FR-010: Payment initialization endpoint (POST /api/payments)
- FR-011: Webhook handler for payment confirmation

### MODIFIED
- FR-003 (Order): Added `payment_id` field to Order schema
- FR-007 (Auth): Payment endpoints require `payments:write` scope

### REMOVED
- FR-005 (Moonshot): Removed deprecated Moonshot provider integration

### Impact Analysis
| File | Change | Risk |
|------|--------|------|
| src/api/orders.rs | MODIFIED: add payment_id | LOW |
| src/api/payments.rs | ADDED: new module | MEDIUM |
| src/auth/scopes.rs | MODIFIED: new scope | LOW |
| migrations/ | ADDED: payments table | MEDIUM |
```

---

## 5. Skills Map: покрытие цикла

| Фаза | Skill | Что делает |
|------|-------|------------|
| **Constitution** | `constitution` (NEW) | Генерирует `constitution.md` из ответов на вопросы о проекте |
| **Specify** | `specify` (exists) | Формализует идею → FR/SC/NFR |
| | `brainstorm` (exists) | Исследует альтернативы, edge cases |
| **Clarify** | `clarify` (exists) | Разрешает `[CLARIFY]` маркеры в spec |
| | `clarify-spec` (exists) | Валидирует spec на полноту |
| **Plan** | `plan` (exists) | Декомпозиция spec → M/T иерархия |
| | `critic-gate` (exists) | Критическая проверка плана |
| | `deep-research` (exists) | Внешнее исследование для плана |
| **Tasks** | `tasks` (NEW) | Декомпозиция M/T → атомарные S с dependencies |
| **Implement** | `execute` (exists) | Покаскадное выполнение S |
| | `loop` (exists) | Итеративная имплементация с review |
| | `writing-tests` (exists) | TDD: RED → GREEN → REFACTOR |
| | `running-tests` (exists) | Изолированный запуск тестов |
| **Verify** | `swarm-pr-review` (exists) | Deep multi-lane review |
| | `codebase-review-swarm` (exists) | Full-repo audit |
| | `phase-wrap` (exists) | Phase boundary: evidence, drift check |
| **Converge** | `converge` (NEW) | Проверка всех acceptance criteria, mark phase complete |

### Новые skills для v3.0

| Skill | Приоритет | Сложность |
|-------|:---------:|:---------:|
| `constitution` | P0 | S — шаблон + вопросы |
| `tasks` | P1 | M — декомпозиция plan → S |
| `implement` | P1 | M — code generation workflow с verify-циклом |
| `converge` | P2 | S — acceptance criteria check |

---

## 6. Shared State: файлы как IPC (Redbook Chapter 2)

### Протокол взаимодействия Человек ↔ AI

```
Человек пишет идею →
  AI генерирует spec.md (FR/SC/NFR) →
    Человек утверждает →

  AI пишет plan.md (M/T) →
    Человек утверждает →

  AI декомпозирует → tasks.md (S с dependencies) →
    Человек подтверждает приоритеты →

  AI выполняет S последовательно:
    S1.1.1 → test → verify → [x] →
    S1.1.2 → test → verify → [x] →
    T1.1 complete →
    T1.2 start (depends satisfied) →

  Reviewer проверяет acceptance criteria →
    converge → phase complete →
    WAL checkpoint → audit log
```

### Правила (из Redbook)

1. **Единственный источник истины:** Каждый факт — в ОДНОМ файле. FR-001 в spec.md, не в коде и не в WAL.
2. **WAL — checkpoint, не лог:** WAL отвечает на 5 вопросов: текущая фаза, ограничения, что сделано, следующее действие, известные проблемы.
3. **URI-адресация:** `spec://my-project/FR-001#timeout` — каждый факт адресуем.
4. **Атомарная запись:** Временный файл + rename, никогда `sed -i` на живом файле.
5. **Протокол конфликтов:** Два AI не пишут в один файл одновременно (TTL-локи: `.lock` файлы с PID + timestamp).

---

## 7. Интеграция с конкурентами

| Возможность | spec-kit | OpenSpec | Наш v3.0 |
|------------|----------|----------|----------|
| `/specify` command | ✓ | ✗ (CLI: `openspec propose`) | ✓ (через skills) |
| `/plan` command | ✓ | ✗ | ✓ |
| `/tasks` command | ✓ | ✗ | ✓ (новый skill) |
| `/implement` command | ✓ | ✗ | ✓ (execute + loop) |
| `/analyze` (coverage) | ✓ | ✗ | ✓ (converge skill) |
| Delta-based changes | ✗ | ✓ (ADDED/MODIFIED/REMOVED) | ✓ |
| Constitution.md | ✓ | ✗ | ✓ (новый) |
| FR/SC tracing | 🟡 (шаблон) | ✓ | ✓ |
| spec:// URI | ✗ | ✗ | ✓ (Redbook-inspired) |
