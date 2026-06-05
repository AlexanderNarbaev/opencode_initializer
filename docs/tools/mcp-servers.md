[← На главную](../index.md) · [Все инструменты](../index.md#навигация) · [Справка](../reference.md)

# MCP-серверы — подробное руководство

> 🟢 Начинающим &nbsp; 🟡 Практикующим
>
> [Официальная спецификация MCP](https://modelcontextprotocol.io/) · [MCP серверы на GitHub](https://github.com/modelcontextprotocol/servers)

MCP (Model Context Protocol) — протокол, позволяющий AI-агенту взаимодействовать с внешними инструментами. Без MCP агент «слеп»: видит только ваш запрос. С MCP — читает файлы, запускает браузер, анализирует код, ищет в базах данных.

<details open>
<summary><b>🟢 Что такое MCP — простое объяснение</b></summary>

Представьте что AI-агент — это разработчик, который сидит в пустой комнате с терминалом. Всё что он может — отвечать на ваши вопросы, опираясь только на свою память. MCP-серверы — это «инструменты», которые вы даёте разработчику:

- **filesystem** — доступ к папке с проектом (может читать и редактировать файлы)
- **codegraph** — карта кода (видит кто кого вызывает)
- **playwright** — браузер (может открыть сайт и проверить что всё работает)
- **context7** — документация (знает актуальные API библиотек)
- **memorylayer** — записная книжка (помнит что было в прошлых сессиях)

Без MCP агент может только «думать». С MCP — «думать и делать».

</details>

## Активные по умолчанию

### context7 — Документация библиотек в реальном времени

**Пакет:** `c7-mcp-server`  
**Команда:** `c7-mcp-server`

Даёт агенту доступ к живой документации популярных библиотек (React, Next.js, Prisma, Spring Boot и сотни других).

**Пример работы:**
```
Пользователь: "Добавь авторизацию через NextAuth с Prisma"
Без Context7: агент генерирует код на основе training data (мог устареть)
С Context7: агент читает актуальную доку NextAuth, использует правильные API
```

**Почему критичен:** модели обучаются на данных 6-12 месячной давности. API библиотек меняется быстрее. Context7 даёт актуальную информацию.

**Альтернативы:** ручной поиск в Google, встроенная память модели (ограничена датой обучения).

---

### filesystem — Доступ к файлам проекта

**Пакет:** `@modelcontextprotocol/server-filesystem`  
**Команда:** `npx -y @modelcontextprotocol/server-filesystem <project_dir>`

Позволяет агенту читать, искать и редактировать файлы в проекте.

**Пример:**
```json
{
  "filesystem": {
    "type": "local",
    "command": ["npx", "-y", "@modelcontextprotocol/server-filesystem", "/home/user/projects"],
    "enabled": true
  }
}
```

**Что умеет:**
- `read_text_file` — прочитать файл
- `write_file` — записать файл
- `list_directory` — список файлов в директории
- `search_files` — поиск по шаблону
- `grep` — поиск по содержимому
- `edit_file` — точечное редактирование строк

---

### agentic-tools — Иерархическая память задач

**Пакет:** `@pimzino/agentic-tools-mcp`  
**Команда:** `npx -y @pimzino/agentic-tools-mcp`  
**Инструментов:** 38

Сохраняет прогресс по задачам в иерархической структуре: проект → задача → подзадача.

**Возможности:**
- `create_project` — создать проект
- `create_task` — создать задачу с приоритетом, сложностью, зависимостями
- `create_subtask` — разбить задачу на подзадачи
- `update_task` — обновить статус, прогресс
- `get_next_task_recommendation` — что делать дальше
- `analyze_task_complexity` — оценка сложности
- `search_memories` / `create_memory` — поиск и сохранение знаний

**Пример:**
```
create_task {
  name: "Добавить OAuth2 авторизацию",
  priority: 8,
  complexity: 7,
  dependsOn: ["task-001"],
  tags: ["auth", "security", "backend"]
}
```

---

### codegraph — Граф вызовов и навигация

**Пакет:** `@colbymchenry/codegraph`  
**Команда:** `codegraph serve --mcp`

Строит граф вызовов функций. Агент видит кто кого вызывает, отслеживает поток данных.

**Инструменты:**
- `codegraph_context` — контекст по задаче (главный инструмент)
- `codegraph_search` — поиск символов
- `codegraph_node` — детали символа (сигнатура, callers/callees)
- `codegraph_trace` — путь вызова от A до B
- `codegraph_impact` — что сломается если изменить символ
- `codegraph_explore` — исследовать группу связанных символов
- `codegraph_explain_function` — глубокий анализ функции (сложность, taint, безопасность)
- `codegraph_review` — security + impact анализ изменений

**Без codegraph:** агент ищет grep'ом — медленно, неточно, без понимания связей.

---

### playwright — Браузерное тестирование

**Пакет:** `@playwright/mcp`  
**Команда:** `npx -y @playwright/mcp`

Полный контроль над браузером: открытие страниц, клики, заполнение форм, скриншоты.

**Инструменты:**
- `browser_navigate` — открыть URL
- `browser_snapshot` — accessibility tree страницы
- `browser_click`, `browser_type`, `browser_fill` — взаимодействие
- `browser_take_screenshot` — скриншот (элемента или всей страницы)
- `browser_evaluate` — выполнить JavaScript
- `browser_network_requests` — перехват сетевых запросов
- `browser_tabs` — управление вкладками

---

### agent-browser — Расширенная браузерная автоматизация

**Пакет:** `agent-browser-mcp-server`  
**Команда:** `npx -y agent-browser-mcp-server`

60+ инструментов для управления браузером. Шире Playwright — включает PDF, cookie, storage, network routing.

**Уникальные возможности (отсутствуют в Playwright MCP):**
- `browser_pdf` — сохранить страницу как PDF
- `browser_network` (route/unroute) — мокировать API-ответы
- `browser_profiler` — CPU profiling страницы
- `browser_trace` — CDP tracing
- `browser_record` — запись видео сессии
- `browser_state` — сохранение/загрузка состояния браузера
- `browser_diff` — сравнение скриншотов/снапшотов

---

### loopsense — Наблюдение за изменениями

**Пакет:** `@loopsense/mcp`  
**Команда:** `npx -y @loopsense/mcp`

Отслеживает файлы, процессы, CI/CD, URL и уведомляет агента об изменениях.

**Watchers:**
- `watch_file` — отслеживание изменений файлов (chokidar)
- `watch_process` — запуск и мониторинг процессов
- `watch_ci` — GitHub Actions
- `watch_url` — HTTP polling
- `watch_webhook` — приём входящих вебхуков

**Пример:** агент изменил файл — loopsense сообщает об ошибке компиляции — агент исправляет.

---

### sequential-thinking — Пошаговое рассуждение

**Пакет:** `@modelcontextprotocol/server-sequential-thinking`  
**Команда:** `npx -y @modelcontextprotocol/server-sequential-thinking`

Структурирует мышление агента: гипотеза → проверка → ревизия → вывод.

**Параметры:**
- `thought` — шаг рассуждения
- `thoughtNumber` — номер шага
- `totalThoughts` — оценка общего количества шагов
- `nextThoughtNeeded` — нужен ли следующий шаг
- `isRevision` — это пересмотр предыдущего?
- `branchFromThought` — точка ветвления

---

### memorylayer — Персистентная память

**Пакет:** `@scitrera/memorylayer-mcp-server`  
**Команда:** `npx -y @scitrera/memorylayer-mcp-server`  
**Инструментов:** 38

Сохраняет знания между сессиями. Агент помнит предпочтения, прошлые решения, контекст проектов.

**Ключевые инструменты:**
- `memory_remember` — сохранить факт (эпизодический/семантический/процедурный)
- `memory_recall` — семантический поиск
- `memory_reflect` — синтез и обобщение
- `memory_session_start` / `memory_session_end` — границы сессии
- `memory_briefing` — сводка недавней активности
- `chat_thread_create` / `chat_thread_append` — история диалогов

---

## Отключённые (опциональные)

### github — GitHub API

**Пакет:** `@modelcontextprotocol/server-github`  
**Команда:** `npx -y @modelcontextprotocol/server-github`

Требует `GITHUB_TOKEN`. Позволяет создавать issues, PR, читать репозитории.

### postgres — PostgreSQL

**Пакет:** `@modelcontextprotocol/server-postgres`  
**Команда:** `npx -y @modelcontextprotocol/server-postgres`

Требует PostgreSQL и строку подключения. Инспекция схемы, выполнение запросов.

### sentry — Мониторинг ошибок (remote)

**URL:** `https://mcp.sentry.dev/mcp`  
Удалённый MCP от Sentry. Требует аккаунт Sentry.

### grep — Поиск по open-source (remote)

**URL:** `https://mcp.grep.app`  
Поиск примеров кода в миллионах репозиториев.
