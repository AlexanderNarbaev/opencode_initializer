# Архитектура

## Обзор

OpenCode Initializer — это универсальный бутстрап для AI-разработки, который автоматизирует установку и настройку инструментов для работы с ИИ.

## Компоненты

### Модули (src/lib/)
- 62 модуля для установки и настройки
- Нумерация 00-60 + хелперы
- Каждый модуль отвечает за конкретный компонент

### Агенты
- 57 агентов (7 primary + 50 subagents)
- Build, Plan, Architect, Goal + специалисты
- Автоматическое распределение задач

### Плагины
- 32 opencode-* пакета
- Контекст, память, безопасность, мониторинг
- Динамическое прунинг контекста

### MCP/LSP
- 16 MCP серверов
- 12 LSP серверов
- Автоматическое подключение по расширению файла

### Навыки
- 43 навыка (26 SDD + 17 Matt Pocock)
- Автоматическая активация по контексту
- Контрактное программирование

## Поток выполнения

```
Пользователь → OpenCode (CLI/TUI/Desktop)
  → Подключает LSP по расширению файлов
  → Стартует MCP-серверы из mcp:{}
  → Загружает plugins (hooks)
  → Подгружает skills (description → auto-trigger)
  → Определяет primary agent (default_agent)
  → Primary agent:
      ├── tools (bash, edit, MCP tools, LSP tools)
      ├── subagents (@coder, @reviewer, @goal-planner...)
      └── skills (skill("tdd"))
  → Subagents:
      ├── tools
      └── может делегировать дальше
```

## Контекстная оптимизация

### Модули контекста
- **52-context-selector.sh** — контекстно-зависимый выбор MCP/LSP
- **53-auto-skills.sh** — автоматическая активация навыков
- **54-task-distributor.sh** — интеллектуальное распределение задач
- **55-context-bundle.sh** — opencode-context + opencode-router
- **56-grace-semantics.sh** — GRACE семантические контракты
- **57-context-guard.sh** — защита контекста
- **58-provider-discovery.sh** — обнаружение провайдеров
- **59-local-memory.sh** — локальная память
- **60-caching.sh** — кэширование

### Принципы
1. **Контекстно-зависимый MCP/LSP** — загружаются только нужные серверы
2. **Автоматическая активация навыков** — скиллы активируются по контексту
3. **Интеллектуальное распределение задач** — автоматическая декомпозиция
4. **Оптимизация токенов** — только полезный контекст
5. **GRACE семантика** — контракты как исполняемый контекст

## Self-Harness парадигма

На основе исследования [Self-Harness: Harnesses That Improve Themselves](https://www.alphaxiv.org/abs/2606.09498v3):

### Трёхэтапный цикл самоулучшения

1. **Weakness Mining** — анализ паттернов ошибок
   - Сбор failed execution traces
   - Кластеризация по failure signature
   - Terminal cause + behavioral status + reusable mechanism

2. **Harness Proposal** — генерация предложений
   - Текущий харнес + evidence bundle
   - K distinct proposal bundles
   - Минимальные, целенаправленные изменения

3. **Proposal Validation** — регрессионное тестирование
   - Тестирование на held-in split (проверка исправления)
   - Тестирование на held-out split (проверка отсутствия регрессии)
   - Принятие только если улучшение на одном split без регрессии на другом

### Применение в проекте

```bash
# Weakness Mining — анализ ошибок
har grace hallucination <context> <output>

# Harness Proposal — генерация предложений
har grace contract <file>
har grace clarity <file>

# Proposal Validation — валидация
har grace position <file>
har grace focus <file> <query>
```

### Модель-специфичная оптимизация

- **MiniMax M2.5** — управление артефактами
- **Qwen3.5** — восстановление из петель ошибок
- **GLM-5** — сохранение окружения между сессиями

## Харнессы

### DeepSeek Harness (dsh)
- Plugin architecture на базе Cordis
- Профили: web, headless, tui
- Интеграция с OpenCode через bash tool

### Sandcastle
- Оркестрация агентов в изолированных песочницах
- Провайдеры: Docker, Podman, Vercel
- Branch strategies для git интеграции

### OpenCode Desktop
- Tauri-обёртка над OpenCode core
- Общее состояние с CLI через ~/.config/opencode/
- Поддержка всех плагинов и навыков

## GRACE семантика

### Контракты
- `.grace.yaml` sidecar файлы
- Intent, invariants, position, dependencies
- Читаемые человеком, проверяемые моделью

### Ясность
- Оценка промпта 0..100
- Acceptance criteria, constraints, examples
- Penalizing vague words

### Позиционный контекст
- Imports, size, dependents
- Компенсация для SLM (малых моделей)

### Sparse focus
- Только релевантные строки + N контекст
- Токен-сейвер для больших файлов

### Нормализация
- Deterministic, depth-bounded
- 200-char truncation для строк

### Проверка галлюцинаций
- Capitalized name mismatch detection
- Entity-presence guard

## Безопасность

### PII Guard
- 9 детекторов (email, phone, INN, passport, credit card, IP, API key)
- Pre-LLM-request gate

### Audit Trail
- 7 WAL event types
- SHA-256 hash-chain
- Rotation >10MB → gzip+Qdrant

### Model Governance
- model-policy.json allowlist/blocklist
- 3 modes: allow-all, allowlist, corporate

## Мониторинг

### Token Tracking
- opencode-token-tracker
- Per-agent и per-task telemetry
- Cost dashboard

### Observability
- Grafana + Prometheus + Node Exporter
- Auto-provisioned datasource
- Infrastructure overview dashboard

## CI/CD

### GitHub Actions
- test.yml — тесты
- shellcheck.yml — линтинг
- security.yml — безопасность
- build.yml — сборка
- docs.yml — документация
- sandcastle-review.yml — ревью

### Тесты
- Unit тесты (80+ файлов)
- Integration тесты
- E2E тесты
- Syntax проверки

## Развертывание

### Профили
- personal — персональный
- corporate — корпоративный
- air-gapped — офлайн
- hybrid — гибридный

### Команды
```bash
bash setup.sh --full      # Полная установка
bash setup.sh --reinit    # Переустановка
bash setup.sh --health    # Проверка здоровья
har apply-all             # Применить ко всем проектам
```
