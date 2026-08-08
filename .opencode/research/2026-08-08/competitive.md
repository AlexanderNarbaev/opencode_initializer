# Конкурентная матрица AI Coding Agents — v3.0 (август 2026)

> **Контекст:** opencode_initializer позиционируется как universal dev machine bootstrap: одна команда `bash setup.sh` → готовая AI-усиленная dev-машина с полным agentic harness. Сравниваем с ведущими AI coding agents: что есть у них, чего нет у нас, и наоборот.

## Источники

| Конкурент | GitHub/Документация |
|-----------|---------------------|
| OpenAI Codex CLI | https://github.com/openai/codex, https://developers.openai.com/codex |
| Anthropic Claude Code | https://docs.anthropic.com/en/docs/claude-code/overview |
| Kimi Code CLI | https://github.com/MoonshotAI/kimi-code, https://moonshotai.github.io/kimi-code/ |
| Aider | https://aider.chat/docs/, https://github.com/Aider-AI/aider |
| OpenCode (SST/Anomaly) | https://github.com/anomalyco/opencode, https://opencode.ai/docs |
| Cursor | https://docs.cursor.com/agent/overview |

---

## Матрица возможностей

| Измерение | **opencode_initializer** | Codex CLI | Claude Code | Kimi Code | Aider | OpenCode (SST) | Cursor |
|:----------|:---:|:---:|:---:|:---:|:---:|:---:|:---:|
| **Spec-driven workflow** | 🔶 (skills specify/plan/execute) | ❌ | 🔶 (plan mode) | ❌ | 🔶 (architect mode) | 🔶 (plan agent) | ❌ |
| **Sub-agents / оркестрация** | 🔶 (.opencode agents, Planner/Worker/Reviewer) | ❌ | ✅ (sub-agents, Agent SDK, background) | 🔶 (coder/explore/plan) | ❌ | ✅ (build/plan/general/explore/scout + custom) | ✅ (agent + background) |
| **Память (session/cross-session)** | 🔶 (WAL + MemoryLayer, ручная) | ❌ | ✅ (CLAUDE.md auto-memory, persistent) | ❌ | 🔶 (conversation cache) | 🔶 (AGENTS.md) | 🔶 (cursorrules) |
| **Хуки / кастомизация** | ❌ (нет lifecycle hooks) | ❌ | ✅ (hooks: before/after tool, events) | ✅ (lifecycle hooks) | ❌ | ✅ (hooks: tool.execute) | ❌ |
| **MCP / инструменты** | ✅ (24 MCP + 13 LSP) | ✅ | ✅ | ✅ (AI-native /mcp-config) | ❌ | ✅ (MCP + custom tools) | ✅ |
| **Sandbox / permissions** | 🔶 (ISOLATED_CIRCUIT, нет per-tool perms) | ✅ (approvals) | ✅ (CLI permissions) | 🔶 (approvals) | ❌ | ✅ (granular allow/ask/deny) | 🔶 |
| **Multi-provider / multi-model** | ✅ (22 cloud + 3 local) | 🔶 (OpenAI models) | 🔶 (Claude + 3rd-party) | 🔶 (Kimi + compatible) | ✅ (17+ провайдеров) | 🔶 (any provider) | 🔶 (multi-model) |
| **Air-gap / локальные модели** | ✅ (Isolated Circuit: Ollama/vLLM/SGLang) | ❌ | 🔶 (local через 3rd-party) | ❌ | ✅ (Ollama, LM Studio, локальные) | 🔶 (любые OpenAI-совместимые) | ❌ |
| **TUI / GUI** | ✅ (Cockpit 7-tab TUI + Web GUI :4200) | 🔶 (terminal + desktop app) | 🔶 (terminal + desktop app) | ✅ (оптимизированный TUI) | 🔶 (terminal) | ✅ (terminal TUI + desktop app) | ❌ (IDE-only) |
| **CI/CD интеграция** | ✅ (GitHub Actions: test, shellcheck, docs) | ❌ | ✅ (GitHub Actions, GitLab CI, Slack) | ❌ | ❌ | ❌ | ❌ |
| **Аудит / логирование** | 🔶 (WAL JSONL, нет native audit) | ❌ | 🔶 (session logs) | ❌ | 🔶 (git-based) | ❌ | ❌ |
| **Цена / privacy** | ✅ (open source, self-hosted) | 🔶 (Apache 2.0, требует OpenAI) | 🔶 (subscription, open source CLI) | 🔶 (MIT, требует Kimi) | ✅ (open source, BYOK) | ✅ (open source, BYOK) | ❌ (proprietary) |
| **IDE интеграция** | 🔶 (38-ide-plugins: DevoxxGenie + Copilot) | ✅ (VS Code, Cursor, Windsurf) | ✅ (VS Code, JetBrains, Desktop, Web) | ✅ (ACP: Zed, JetBrains) | 🔶 (watch mode) | 🔶 (IDE extension) | ✅ (full IDE) |
| **Infra/platform сервисы** | ✅ (PG, Qdrant, Redis, Prometheus, Grafana, MemoryLayer) | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |
| **Project bootstrapping** | ✅ (AGENTS.md, WAL, agents, docker-compose) | 🔶 (codex init) | 🔶 (claude init) | ❌ | ❌ | ✅ (/init) | ❌ |
| **Team / collaboration** | ❌ | ❌ | ✅ (/share, Slack, Channels, Dispatch) | ❌ | ❌ | ✅ (/share) | ❌ |
| **Remote / mobile доступ** | ❌ | 🔶 (web version) | ✅ (Remote Control, mobile, --teleport) | ❌ | 🔶 (browser) | 🔶 (desktop app beta) | ❌ |
| **Scheduled / cloud tasks** | 🔶 (systemd timer autoupdate) | ❌ | ✅ (Routines, scheduled, /loop) | ❌ | ❌ | ❌ | ✅ (background agents) |
| **RAG / knowledge retrieval** | ✅ (ETL + proxy + Qdrant + Gemma) | ❌ | 🔶 (MCP-based) | ❌ | ❌ | ❌ | ❌ |
| **Готовых языков / тулинг** | ✅ (8 языков одной командой) | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |

**Легенда:** ✅ сильная сторона | 🔶 частично/базово | ❌ отсутствует

---

## Ключевые выводы: где мы проигрываем сильнее всего

### 1. 🚨 Lifecycle hooks — критический пробел
**Claude Code**, **Kimi Code** и **OpenCode (SST)** имеют хуки жизненного цикла инструментов — `before/after` на вызовы bash, edit, read. Это основа для:
- Аудита (логирование каждого вызова)
- Compliance (блокировка опасных операций)
- Автоматизации (форматирование после edit, lint перед commit)
- Corporate sandbox (PreExecutionHook → reject если модель пытается читать секреты)

У нас хуков нет. Без них корпоративный профиль неполноценен.

### 2. 🚨 Sub-agent оркестрация — мы в роли наблюдателя
**Claude Code** имеет Agent SDK + background agents + sub-agents из коробки. **OpenCode (SST)** имеет build/plan/general/explore/scout + кастомные агенты. **Kimi Code** — coder/explore/plan. **Cursor** — agent mode + background agents.

У нас агенты определены статически в `.opencode/agents/` и `.opencode/skills/`, но нет:
- Рантайм-диспетчеризации сабагентов из TUI (@ mention)
- Механизма оркестрации волн (Planner→Worker→Reviewer — только в AGENTS.md как конвенция)
- Agent SDK для создания кастомных агентов

### 3. 🚨 Remote/mobile доступ — у нас ноль
**Claude Code**: Remote Control (phone/browser), Slack, Dispatch, `/desktop`, `--teleport`. **Codex**: web version. **Kimi Code**: только локально. **OpenCode**: desktop app beta.

Мы — чисто локальный проект. Для корпоративных контуров это плюс (air-gap), но для энтузиастов — упущение.

### 4. 🔶 Team collaboration — отсутствует
**Claude Code**: `/share` + Slack + Channels (Telegram, Discord, iMessage, webhooks). **OpenCode (SST)**: `/share`. У нас — `chezmoi` для конфигов, но нет нативного sharing-а сессий или коллаборации.

### 5. 🔶 Scheduled/cloud tasks — базово
**Claude Code**: Routines (cloud), Desktop scheduled tasks, `/loop`. **Cursor**: background agents. У нас — systemd-таймер для `topgrade`, но не для агентских задач. Нет «каждое утро делай ревью PR-ов».

---

## Наши уникальные преимущества (нет ни у кого из конкурентов)

1. **Infrastructure as Code из коробки** — PostgreSQL + Qdrant + Redis + Prometheus + Grafana + MemoryLayer одним `docker compose up`. Конкуренты только редактируют код, мы разворачиваем платформу.

2. **22 провайдера с авто-конфигурацией** — включая z.ai (RU/CN), OpenRouter (100+ моделей), Alibaba, DeepInfra. Ни один конкурент не конфигурирует столько провайдеров автоматически.

3. **Isolated Circuit Mode** — целенаправленный air-gap режим с локальными LLM (Ollama/vLLM/SGLang) и OpenAI-совместимым API. Конкуренты могут подключать локальные модели, но у них нет dedicated режима с автоматическим переключением инфраструктуры.

4. **RAG-система как часть платформы** — полный пайплайн: ETL → embedding proxy → Qdrant → Gemma. Конкуренты полагаются на MCP для retrieval, мы даём production-grade RAG из коробки.

5. **Cockpit TUI + Web GUI** — управление всей инфраструктурой (сервисы, порты, health) из одного TUI/Web. У конкурентов TUI только для кодинга, не для управления сервисами.

6. **Полный тулинг для 8 языков** — одной командой: Java 25, Node 24, Python 3.14, Go 1.26, Rust 1.97.1, .NET 10, Zig, Bun. Плюс Zsh/P10k/14 plugins, chezmoi, Devbox, mise. Конкуренты этого не делают вообще.

7. **Открытый исходный код, self-hosted, без vendor lock-in** — в отличие от Cursor (проприетарный), Codex (OpenAI), Claude Code (Anthropic subscription). Пользователь волен выбирать любые модели и провайдеров.

---

## Стратегический вывод

**opencode_initializer занимает нишу, которую конкуренты не покрывают**: dev machine bootstrap + agentic harness + infrastructure platform. Конкуренты — это coding agents (терминальные/IDE), мы — платформа, на которой эти agents работают.

**Главный пробел для v3.0**: хуки (lifecycle hooks) и улучшенная оркестрация сабагентов. Без хуков корпоративный профиль (audit, compliance, PII protection) неполон. Без оркестрации — мы не можем конкурировать с Claude Code Agent SDK для сложных multi-agent сценариев.

**Главная сила для v3.0**: мы единственные, кто даёт полную инфраструктуру (БД, RAG, observability, модельный роутинг) из коробки. Если добавить хуки + оркестрацию + SDD-цикл — мы становимся единственной платформой, покрывающей полный цикл от dev-машины до production-grade agentic infrastructure.

---

## Рекомендация для синтеза (M3)

1. Заимствовать **lifecycle hooks** из Claude Code/Kimi Code (before/after tool execution)
2. Заимствовать **Agent SDK / sub-agent dispatch** из Claude Code/OpenCode SST
3. Заимствовать **spec-driven workflow** из spec-kit/OpenSpec (specify → plan → tasks → implement → verify)
4. Усилить **audit trail** (WAL как structured audit log, не просто journal)
5. Добавить **scheduled agent tasks** (аналог Claude Code Routines, но self-hosted через systemd timers)
6. Удержать уникальные: infra-as-code, 22 providers, isolated circuit, RAG, cockpit TUI, 8 языков

*Дата: 2026-08-08 | Исследователь: Planner | Источники: официальные GitHub README и documentation pages всех конкурентов*
