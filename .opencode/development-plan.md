# OpenCode Initializer — План развития v3.4.0 → v4.0.0
# Дата: 2026-09-11
# Статус: DRAFT — требует обсуждения с пользователем

## Executive Summary

**Текущее состояние:** v3.3.0 — рабочий инсталлятор с 76 модулями, 24 MCP серверами,
12 LSP серверами, 21 плагином, 22 провайдерами. Решает базовую проблему настройки
AI-среды разработчика.

**Конечная цель:** OpenSource продукт для международного сообщества. Фреймворк-платформа,
объединяющая лучшие практики AI-ассистированной разработки.

**Уникальная позиция:** Единственный инструмент, объединяющий настройку машины +
контекст агентов + инфраструктуру + governance. Конкуренты делают либо одно, либо другое.

**Синергия с Microsoft APM:** APM = контекст агентов (apm.yml, lockfile, multi-agent).
opencode_initializer = настройка машины + инфраструктура. Вместе они покрывают весь стек.

---

## Фаза 1: Исправление текущих болей (v3.4.0) — 2-4 недели

### 1.1 TOML конфиг + интерактивный режим
**Приоритет: ВЫСОКИЙ**
**Текущий статус: В процессе (TODO M3)**

Что сделать:
- [ ] `_toml_get FILE SECTION KEY` helper в 00-core.sh (python3 tomllib, без PyYAML)
- [ ] `_toml_load FILE` → flat env vars для downstream потребления
- [ ] `setup.toml` шаблон с документированной схемой
- [ ] `--config=FILE` флаг в setup.sh и dev.sh
- [ ] `--print-config` флаг: вывести разрешенные значения (CLI > env > toml > defaults)
- [ ] Прецедент: CLI > env > toml > defaults
- [ ] Интерактивный режим с промптами (Homebrew wait_for_user паттерн)
- [ ] Тесты: parse, precedence, missing-file handling
- [ ] Документация: EN + RU

Пример setup.toml:
```toml
[meta]
version = "1.0"
schema = "opencode-init/v1"
name = "alex-laptop"

[user]
name = "Alex Narbaev"
email = "alex@example.com"
shell = "zsh"

[features]
docker = true
postgres = "17"
nodejs = "24"
python = "3.14"
rust = false
install_gui = true

[services]
postgres = true
qdrant = true
redis = true
prometheus = true
grafana = true
memorylayer = true

[providers]
deepseek = true
opencode = true
minimax = true
mimo = true
```

### 1.2 Исправление Docker портов (已完成 частично)
**Приоритет: ВЫСОКИЙ**
**Текущий статус: DONE (2026-08-28)**

Что сделано:
- [x] Pre-flight port-conflict detection в 30-infra.sh
- [x] Auto-shift через _find_free_port (bump-by-10000+50)
- [x] Persist в setup.conf
- [x] qdrant gRPC port env-overridable (QDRANT_GRPC_PORT)
- [x] dev state --strict для обнаружения дрейфа

Что осталось:
- [ ] Исправить pre-existing bug: literal GITHUB_PERSONAL_ACCESS_TOKEN в 18-opencode-json.sh:318
- [ ] Добавить retry логику при docker compose up (если порт занят, попробовать следующий)

### 1.3 Ускорение установки
**Приоритет: СРЕДНИЙ**
**Текущий статус: NOT STARTED**

Что сделать:
- [ ] Параллельная установка модулей (flock для WAL)
- [ ] Кеширование загрузок (tarball cache в ~/.cache/opencode-setup/)
- [ ] Зеркала для CN/RU (ghproxy.com уже есть, но не для всех)
- [ ] Инкрементальная установка (пропуск уже установленных компонентов)
- [ ] `--skip` флаги для отдельных модулей
- [ ] Dry-run для оценки времени установки

### 1.4 Исправление opencode.json дрейфа (DONE)
**Приоритет: ВЫСОКИЙ**
**Текущий статус: DONE (2026-08-28)**

Что сделано:
- [x] Diff-before-write в 18-opencode-json.sh
- [x] SHA-256 сравнение, UNCHANGED/DIFF маркеры
- [x] DRY_RUN=1 поддержка
- [x] Secret-masking (3 patterns: JSON, YAML, env-var leak)
- [x] Determinism fix (sort task_profiles[].mcp и disabled)

---

## Фаза 2: Интеграция с APM экосистемой (v3.5.0) — 4-6 недель

### 2.1 APM как механизм распространения
**Приоритет: ВЫСОКИЙ**
**Причина: Microsoft APM становится де-факто стандартом для agent config**

Что сделать:
- [ ] Создать `apm.yml` манифест для opencode_initializer
- [ ] Поддержка `apm install opencode_initializer` как альтернатива curl|bash
- [ ] Интеграция с `apm-policy.yml` для enterprise governance
- [ ] SBOM экспорт (CycloneDX/SPDX)
- [ ] Lockfile для воспроизводимости

Пример apm.yml:
```yaml
name: opencode_initializer
version: 3.4.0
description: AI-Native SDD Harness for developer machines

dependencies:
  # Agent context
  - name: superpowers
    source: github:obra/superpowers
    version: ">=1.0.0"
  - name: disruptor-skills
    source: github:smixs/disruptor-skills
    version: ">=1.0.0"

  # MCP servers
  - name: context7
    source: npm:@upstash/context7-mcp
  - name: codegraph
    source: npm:@colbymchenry/codegraph

  # Skills
  - name: brainstorm
    source: local:.opencode/skills/brainstorm
  - name: plan
    source: local:.opencode/skills/plan

mcp_servers:
  context7:
    command: ["c7-mcp-server"]
  codegraph:
    command: ["codegraph", "serve", "--mcp"]

providers:
  deepseek:
    api_key: "${DEEPSEEK_API_KEY}"
  opencode:
    api_key: "${OPENCODE_API_KEY}"
```

### 2.2 AgentRC интеграция
**Приоритет: СРЕДНИЙ**
**Причина: AgentRC генерирует контекст из кодовой базы**

Что сделать:
- [ ] Интеграция `agentrc generate` в workflow opencode_initializer
- [ ] Автоматическая генерация AGENTS.md из кодовой базы
- [ ] AI-readiness score для проектов
- [ ] Drift detection в CI (контекст устарел?)

### 2.3 Multi-agent target support
**Приоритет: СРЕДНИЙ**
**Причина: Один конфиг должен работать с Copilot, Claude, Cursor, OpenCode**

Что сделать:
- [ ] Поддержка генерации .github/copilot-instructions.md
- [ ] Поддержка генерации .claude/settings.json
- [ ] Поддержка генерации .cursor/settings.json
- [ ] Единый конфиг → несколько targets

---

## Фаза 3: Архитектурные улучшения (v3.6.0) — 4-6 недель

### 3.1 Audit F1: Per-step fault tolerance
**Приоритет: СРЕДНИЙ**
**Текущий статус: TODO M4**

Что сделать:
- [ ] Обернуть `_run_step` в subshell: `(set +e; source "$module")`
- [ ] Capture exit code; on failure, mark step as `PARTIAL` (not `done`)
- [ ] При повторном запуске, `PARTIAL` шаги перезапускаются
- [ ] Лог: `warn "step_X FAILED at line N — re-run will retry"`

### 3.2 Audit F2: WAL race condition
**Приоритет: СРЕДНИЙ**
**Текущий статус: TODO M5**

Что сделать:
- [ ] `_wal_locked_append` уже использует flock (helpers.sh)
- [ ] Проверить что параллельные модули (21-rag, 22-webui, 29-mise, 23-just, 24-websearch) безопасны
- [ ] Fallback для систем без flock (macOS): mkdir-based lock
- [ ] Стресс-тест: 5 concurrent `_wal_checkpoint` writes

### 3.3 Модульная архитектура
**Приоритет: НИЗКИЙ**
**Причина: Текущая архитектура работает, но масштабируется плохо**

Что сделать (длинный горизонт):
- [ ] Перейти от нумерованных модулей к plugin-based архитектуре
- [ ] Каждый модуль — отдельный файл с метаданными (requires, provides, conflicts)
- [ ] Dependency resolution вместо жесткого порядка
- [ ] Hot-reload модулей без перезапуска setup.sh

---

## Фаза 4: Качество и тестирование (v3.7.0) — 4-6 недель

### 4.1 80%+ deep tests
**Приоритет: ВЫСОКИЙ**
**Текущий статус: ~35% shallow, ~40% medium, ~25% deep**

Что сделать:
- [ ] Переписать 35% shallow tests на deep (реально запускать код)
- [ ] Добавить Docker-based тесты (PostgreSQL, Redis, Qdrant)
- [ ] Добавить mode-specific тесты (health, ci, interactive, upgrade)
- [ ] Добавить E2E smoke test в CI: `setup.sh --dry-run --mode ci`
- [ ] Добавить интеграционные тесты для 18-opencode-json.sh (реально генерировать и валидировать)
- [ ] Добавить тесты для 11 модулей с нулевым покрытием (42-hooks.sh, 44-audit.sh, etc.)

### 4.2 Документация
**Приоритет: СРЕДНИЙ**

Что сделать:
- [ ] Обновить README.md/README.ru.md (устаревшие счетчики)
- [ ] Обновить architecture.md (ссылается на "24 модуля", сейчас 76)
- [ ] Добавить ADR (Architecture Decision Records) для каждого решения
- [ ] Добавить runbook для типовых операций
- [ ] Добавить troubleshooting guide

---

## Фаза 5: Продуктовые фичи (v4.0.0) — 8-12 недель

### 5.1 AI-native distro
**Приоритет: ВЫСОКИЙ (видение)**
**Причина: Заполнение зазора — никто не объединяет OS + agent context**

Что сделать:
- [ ] Opinionated defaults (как Omakub, но AI-first)
- [ ] One command, fully configured
- [ ] Community extensions (EXTENSIONS.md паттерн)
- [ ] Marketplace для навыков и плагинов

### 5.2 Spec-Driven Development methodology
**Приоритет: СРЕДНИЙ**
**Причина: Позиционирование как methodology enabler, не просто инсталлятор**

Что сделать:
- [ ] URI-addressable prompts (как VibeVM)
- [ ] Boot-time context assembly
- [ ] Decentralized registry для спецификаций
- [ ] Lockfile для воспроизводимости контекста

### 5.3 Enterprise features
**Приоритет: НИЗКИЙ (длинный горизонт)**

Что сделать:
- [ ] Org-wide policies (apm-policy.yml)
- [ ] CI gates для agent context
- [ ] Compliance reporting (SOC2, ISO27001)
- [ ] Audit dashboard (Grafana)

---

## Приоритеты (матрица)

| Задача | Влияние | Сложность | Приоритет |
|--------|---------|-----------|-----------|
| TOML конфиг | Высокое | Средняя | P0 |
| Ускорение установки | Высокое | Средняя | P0 |
| APM интеграция | Высокое | Высокая | P1 |
| 80%+ deep tests | Высокое | Высокая | P1 |
| Audit F1/F2 | Среднее | Средняя | P2 |
| AgentRC интеграция | Среднее | Средняя | P2 |
| Multi-agent targets | Среднее | Высокая | P2 |
| Модульная архитектура | Низкое | Очень высокая | P3 |
| AI-native distro | Высокое | Очень высокая | P3 |
| Enterprise features | Низкое | Очень высокая | P3 |

---

## Риски

| Риск | Вероятность | Влияние | Митигация |
|------|-------------|---------|-----------|
| Microsoft APM доминирует | Средняя | Высокое | Интеграция, а не конкуренция |
| Быстрая эволюция AI ландшафта | Высокая | Среднее | Модульная архитектура, быстрые релизы |
| Безопасность (prompt injection) | Средняя | Высокое | Security scanning, PII guard, audit |
| Фрагментация стандартов | Средняя | Среднее | Поддержка нескольких стандартов (APM, AGENTS.md, Agent Skills) |
| Solo developer burnout | Средняя | Высокое | Open source community, документация |

---

## Следующие шаги (немедленные)

1. **Обсудить этот план с пользователем** — приоритеты, таймлайн, ресурсы
2. **Начать TOML конфиг** (P0) — самая высокая отдача при средней сложности
3. **Исправить literal PAT bug** в 18-opencode-json.sh:318 (быстрый win)
4. **Обновить session_checkpoint.json** (устарел на 16 дней)
5. **Обновить architecture.md** (ссылается на "24 модуля", сейчас 76)