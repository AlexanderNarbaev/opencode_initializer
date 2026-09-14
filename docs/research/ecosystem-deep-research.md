# Deep Ecosystem Research — OpenCode v35.4 → v36.0

**Date:** 2026-06-21 | **Sources:** 7 parallel agents × npm/GitHub/PyPI/docs/APIs

---

## 1. CRITICAL: npm Security Canaries (MUST FIX IMMEDIATELY)

| Package (npm) | Status | Issue |
|---|---|---|
| **mcp-server-git** | 🔴 Security canary | postinstall-скрипт — НЕ ИСПОЛЬЗОВАТЬ |
| **mcp-server-fetch** | 🔴 Security canary | postinstall-скрипт — НЕ ИСПОЛЬЗОВАТЬ |
| **mcp-server-time** | 🔴 Unpublished | Удалён из реестра |
| **mcp-server-chart** | 🔴 Name squatting | "npm package name robbery" |

Эти MCP серверы — Python-пакеты, устанавливаются через `uvx`/`pipx`, НЕ через npm.
**В коде уже исправлено:** `lib/12-mcp-lsp.sh` использует `uvx`/`pip`, но в `lib/00-core.sh` `MCP_PACKAGES` они всё ещё есть для общего цикла npm-установок. Нужно убрать git/fetch/time из MCP_PACKAGES или добавить исключение.

---

## 2. npm: Новые найденные пакеты (не в текущей установке)

### Плагины для добавления

| Package | Version | Description | Priority |
|---|---|---|---|
| **@upstash/context7-mcp** | 3.2.1 | Official Context7 MCP (замена c7-mcp-server) | HIGH |
| **@notionhq/notion-mcp-server** | 2.4.0 | Official Notion MCP | MEDIUM |
| **@devtheops/opencode-plugin-otel** | 1.2.0 | OpenTelemetry telemetry | MEDIUM |
| **opencode-poe-auth** | 0.0.4 | Poe OAuth authentication | LOW |
| **opencode-gitlab-auth** | 2.1.0 | GitLab OAuth plugin | LOW |
| **@opencode-ai/sdk** | 1.17.9 | Official TypeScript SDK | REF |
| **ai-sdk-provider-opencode-sdk** | 3.0.6 | AI SDK v6 provider for OpenCode | REF |

### Несуществующие / переименованные (подтверждено)

| Пакет | Статус | Альтернатива |
|---|---|---|
| @anthropic/mcp-server-brave-search | ❌ Не существует | → `brave-search-mcp` ✅ |
| @anthropic/mcp-server-gitlab | ❌ Не существует | → `mcp-server-gitlab` (PyPI) |
| @anthropic/mcp-server-google-maps | ❌ Не существует | → `mcp-server-google-maps` (PyPI) |
| opencode-firecrawl | ❌ Не существует | → `@lyculs/opencode-firecrawl` ✅ |
| maslul | ❌ Не существует | → Нет альтернативы |
| opencode-dcp | ❌ Не существует | → Удалён из кода |
| opencode-envsitter-guard | ❌ Не существует | → Удалён из кода |

---

## 3. MCP Серверы: Новые рекомендации

### Critical Gaps (HIGH — добавить обязательно)

| # | MCP Server | Package | Install | Без API ключа | Почему |
|---|---|---|---|---|---|
| 1 | **SQLite** | `mcp-server-sqlite` | uvx | ✅ | Самая распространённая локальная БД |
| 2 | **Desktop Commander** | `@wonderwhy-er/desktop-commander` | npm | ✅ | Терминал + diff/patch + файлы |
| 3 | **SearXNG** | `mcp-searxng` | npm | ✅ (self-host) | Приватный веб-поиск |
| 4 | **Kubernetes** | `mcp-server-kubernetes` | npm | ✅ | Docker/K8s управление |

### Important Additions (MEDIUM)

| # | MCP Server | Package | Requires |
|---|---|---|---|
| 5 | **Sentry** | `@sentry/mcp-server` | Sentry API key |
| 6 | **Excalidraw** | `excalidraw-architect-mcp` | ❌ None — диаграммы |
| 7 | **Storybook** | `@storybook/mcp` | Storybook |
| 8 | **Notion** | `@notionhq/notion-mcp-server` | Notion API key |

---

## 4. GitHub AI Tools: Топ находки

### Must-include (поддержка OpenCode подтверждена)

| # | Tool | Stars | Что даёт | Интеграция |
|---|---|---|---|---|
| 1 | **ECC** | 219k | Agent harness: навыки, память, безопасность | MCP/plugin |
| 2 | **cc-switch** | 105k | Desktop GUI для OpenCode (Tauri/Rust) | App |
| 3 | **claude-mem** | 83k | Персистентная память между сессиями | MCP/skill |
| 4 | **Graphify** | 70k | Knowledge graph по кодовой базе | MCP/plugin |
| 5 | **OH-My-OpenAgent** | 63k | Multi-agent ОС: 11 агентов, 54 хука, 5 MCP | Plugin |

### MCP-совместимые платформы

| # | Tool | Stars | Тип |
|---|---|---|---|
| 6 | **n8n** | 193k | Workflow automation (MCP client + server) |
| 7 | **Dify** | 146k | Agentic workflows (MCP) |
| 8 | **Browser Use** | 99k | Web automation for AI agents |
| 9 | **UI/UX Pro Max** | 94k | UI/UX skill for AI coding |

---

## 5. Модели и Провайдеры: Оптимальная конфигурация

### Ключевой инсайт: DeepSeek прямой API в 4× дешевле Zen

| Модель | Прямой API (input/output) | Zen (input/output) | Экономия |
|---|---|---|---|
| DeepSeek V4 Pro | $0.435 / $0.87 | $1.74 / $3.48 | **4×** |
| DeepSeek V4 Flash | $0.14 / $0.28 | $0.14 / $0.28 | 1× |

### Оптимальная конфигурация (минимальные расходы)

```json
{
  "model": "deepseek/deepseek-v4-pro",
  "small_model": "deepseek/deepseek-v4-flash",
  "provider": {
    "deepseek": {},
    "minimax": {},
    "xai": {}
  }
}
```

**Месячный бюджет:** ~$5-15 (за счёт 98% экономии на disk cache)

### Fallback chain
```
DeepSeek V4 Pro → MiniMax M3 ($0.30/50% скидка) → DeepSeek V4 Flash → MiMo-V2.5 Free
```

### Бесплатные модели Zen (резерв)
- DeepSeek V4 Flash Free
- MiMo-V2.5 Free
- North Mini Code Free
- Nemotron 3 Ultra Free

---

## 6. Агенты и Оркестрация

### Текущее состояние
- 16 агентов в `lib/17-project.sh`
- 14 Superpowers навыков (все актуальны, v6.0.3)
- 3 кастомных project-навыка (примитивные, нужно заменить)

### Рекомендации по агентам

```jsonc
{
  "agent": {
    "build": {
      "mode": "primary",
      "model": "deepseek/deepseek-v4-pro",
      "temperature": 0.3,
      "permission": {
        "edit": "allow",
        "bash": { "*": "ask", "git *": "allow", "npm *": "allow" },
        "task": { "*": "allow" },
        "read": { "*.env": "deny", "*": "allow" }
      }
    },
    "plan": {
      "mode": "primary",
      "model": "deepseek/deepseek-v4-flash",
      "temperature": 0.1,
      "permission": { "edit": "deny", "bash": "deny", "task": { "researcher": "allow" } }
    },
    "code-reviewer": {
      "mode": "subagent",
      "model": "deepseek/deepseek-v4-pro",
      "temperature": 0.1,
      "permission": { "edit": "deny", "bash": "deny", "task": "deny" }
    },
    "researcher": {
      "mode": "subagent",
      "model": "deepseek/deepseek-v4-flash",
      "temperature": 0.2,
      "permission": { "edit": "deny", "bash": "deny", "webfetch": "allow" }
    }
  }
}
```

---

## 7. Навыки (Skills)

### Новые навыки для добавления

| Навык | Назначение | Приоритет |
|---|---|---|
| **context-switching** | Восстановление контекста при переключении задач | HIGH |
| **dependency-update** | Безопасное обновление зависимостей | MEDIUM |
| **api-design-review** | Рецензирование API дизайна | LOW |

### Навыки для замены

| Текущий | Проблема | Замена |
|---|---|---|
| code-review-checklist | Примитивный markdown-чеклист | Полноценный навык с TDD |
| deployment-checklist | Примитивный markdown-чеклист | Полноценный навык с TDD |
| testing-strategy | Примитивный markdown-чеклист | Полноценный навык с TDD |
| caveman | Внешняя зависимость, нестандартный формат | Удалить или заменить |

---

## 8. Память и Контекст

### Unified Memory Stack (рекомендация)

```
Session (working):
  MemoryLayer MCP: working memory (25-38 tools)
  YAML WAL: структурированный дайджест

Long-term:
  ChromaDB: векторы (384d) — быстрый recall
  MemoryLayer: граф + семантика — deep search
  Agentic Tools: задачи — structured memory
```

### Memory hooks для opencode.json
```json
{
  "hooks": {
    "SessionStart": ["memory-read skill", "check WAL"],
    "PreCompact": ["memory_session_commit", "update WAL"],
    "PostToolUse": ["memory_remember при изменении артефактов"],
    "SessionEnd": ["memory_session_end(commit=true)"]
  }
}
```

### Улучшения ChromaDB
- Аутентификация (токен)
- RAG коллекция для кодовой базы
- Гибридный recall: векторный ChromaDB + keyword grep + графовый codegraph

---

## 9. План действий v36.0

### Фаза 1: CRITICAL FIXES (немедленно)

- [x] ~~mcp-server-git/fetch/time — уже используют uvx в lib/12-mcp-lsp.sh~~
- [ ] Убрать git/fetch/time из MCP_PACKAGES (или добавить skip для npm-установки)
- [ ] Переименовать @anthropic/mcp-server-gitlab → mcp-server-gitlab (PyPI)
- [ ] Переименовать @anthropic/mcp-server-google-maps → mcp-server-google-maps (PyPI)

### Фаза 2: NEW MCP SERVERS

- [ ] Добавить SQLite MCP (`mcp-server-sqlite`, uvx)
- [ ] Добавить Excalidraw MCP (диаграммы, без API ключа)
- [ ] Заменить c7-mcp-server → @upstash/context7-mcp (официальный)

### Фаза 3: MODEL & PROVIDER OPTIMIZATION

- [ ] Переключить primary на прямой DeepSeek API (4× экономия)
- [ ] Добавить MiniMax M3 как fallback
- [ ] Обновить _build_providers() с новыми ценами

### Фаза 4: AGENT PERMISSION OVERHAUL

- [ ] Добавить bash permission patterns (git:allow, npm:allow, rm:deny)
- [ ] Добавить task permission routing
- [ ] Настроить read:deny для .env файлов

### Фаза 5: SKILLS UPGRADE

- [ ] Заменить 3 примитивных project-навыка на полноценные
- [ ] Добавить context-switching навык
- [ ] Удалить caveman или заменить

### Фаза 6: MEMORY UNIFICATION

- [ ] YAML WAL вместо Markdown
- [ ] Memory hooks в opencode.json
- [ ] ChromaDB коллекция для RAG по кодовой базе

### Фаза 7: NEW PLUGINS & TOOLS

- [ ] @upstash/context7-mcp (официальный)
- [ ] @notionhq/notion-mcp-server (опционально)
- [ ] @devtheops/opencode-plugin-otel (телеметрия)
- [ ] OH-My-OpenAgent (опционально, для power users)

---

## Appendix: Полный список проверенных пакетов

### Существуют и актуальны (56 из 67)

**Плагины (28):** open-orchestra, opencode-codegraph, opencode-token-tracker, opencode-swarm, opencode-auto-fallback, opencode-goal-mode, opencode-vibeguard, opencode-daytona, opencode-background-agents, opencode-scheduler, opencode-supermemory, opencode-conductor, opencode-goal-plugin, @zenobius/opencode-skillful, @morphllm/opencode-morph-plugin, @lyculs/opencode-firecrawl, opencode-zellij-namer, opencode-websearch-cited, opencode-devcontainers, opencode-worktree, opencode-notify, opencode-pty, opencode-ignore, opencode-snip, opencode-snippets, opencode-command-inject, opencode-orchestrator, brave-search-mcp, @upstash/context7-mcp, @devtheops/opencode-plugin-otel

**MCP (20):** c7-mcp-server, @modelcontextprotocol/server-filesystem, @pimzino/agentic-tools-mcp, @colbymchenry/codegraph, @playwright/mcp, agent-browser-mcp-server, @loopsense/mcp, @modelcontextprotocol/server-github, @modelcontextprotocol/server-postgres, @modelcontextprotocol/server-sequential-thinking, @scitrera/memorylayer-mcp-server, chrome-devtools-mcp, @modelcontextprotocol/server-memory, @modelcontextprotocol/server-redis, @notionhq/notion-mcp-server, mcp-server-docker, mcp-server-sqlite, mcp-server-commands, @wonderwhy-er/desktop-commander, mcp-searxng

### Не существуют (11): maslul, opencode-dcp, opencode-firecrawl, opencode-envsitter-guard, @anthropic/mcp-server-brave-search, @anthropic/mcp-server-gitlab, @anthropic/mcp-server-google-maps, mcp-server-pdf, mcp-server-puppeteer, mcp-server-rag, mcp-server-time (unpublished)

### Опасные (3): mcp-server-git (canary), mcp-server-fetch (canary), mcp-server-chart (squatting)
