# OpenCode Initializer — Полный контекст проекта
# Сохранено: 2026-09-11
# Источник: глубокий анализ всех файлов, истории, решений + интервью с пользователем

## 1. Суть проекта

**opencode_initializer** — AI-Native SDD Harness. Не просто инсталлятор, а управляемый
агентный каркас для AI-ассистированной разработки.

### Что делает
- Одна команда (`curl ... | bash -s -- --full`) разворачивает полную среду разработки
- 6 языковых тулчейнов (Java 25, Node.js 24, Python 3.14, Go 1.26, Rust, .NET 10)
- 24 MCP сервера, 12 LSP серверов, 21 плагин, 22 AI провайдера
- Инфраструктура: PostgreSQL, Redis, Qdrant, Prometheus, Grafana
- SDD workflow: Constitution → Specify → Clarify → Plan → Tasks → Implement → Verify
- Multi-agent архитектура: Commander/Planner/Worker/Reviewer с WAL координацией
- Governance: model policies, PII санитизация, audit trail (SHA-256 hash chains)
- 4 профиля развертывания: personal, corporate, air-gapped, hybrid

### Текущая версия
- v3.3.0 (2026-08-24)
- 200+ коммитов за 2 месяца (2026-06-22 → 2026-08-24)
- Соло-разработчик: Alexander Narbaev

## 2. Видение (из интервью 2026-09-11)

### Конечная цель
- **OpenSource продукт для международного сообщества**
- Также персональный инструмент/фреймворк-платформа
- Делиться экспертизой, объединять лучшие практики
- Собирать максимум из доступного сейчас

### Целевая аудитория
- Международное сообщество разработчиков

### Распространение
- GitHub + GitVerse (текущее)
- Package managers (Homebrew, apt/yum репозиторий, snap/flatpak)
- Docker/containers (Devcontainer features)
- Интеграция с Microsoft APM

### Синергия с Microsoft APM
- Смотреть на реальные сценарии использования
- Лучший вариант — синергия, при условии что всё OpenSource
- APM управляет контекстом агентов, opencode_initializer управляет машиной

### Язык документации
- Билингва (текущее): .en.md + .ru.md пары

## 3. Текущие боли

1. **opencode.json дрейфует** — генератор и on-disk файл не совпадают
   - 2 устаревших плагина (opencode-context, opencode-router)
   - 8 отсутствующих агентов
   - apiKey camelCase vs snake_case
   - Баг: literal GITHUB_PERSONAL_ACCESS_TOKEN в конфиге
   - РЕШЕНИЕ: diff-before-write реализован (2026-08-28)

2. **Медленная установка** — 30+ минут
   - Нужна оптимизация

3. **Нет TOML конфига** — хочу declarative конфиг вместо флагов
   - setup.toml с precedence: CLI > env > toml > defaults

4. **Docker сервисы не стартуют** — opencode-redis и opencode-qdrant застряли в Created
   - Порты 6379 и 6333 заняты rag-redis и rag-qdrant
   - РЕШЕНИЕ: pre-flight port-conflict detection реализован (2026-08-28)

## 4. Приоритеты v3.4.0 (ВСЕ)

- [ ] TOML конфиг + интерактивный режим
- [ ] Исправление аудита F1 (per-step fault tolerance в _run_step)
- [ ] Исправление аудита F2 (WAL race condition)
- [ ] Интеграция с APM/AgentRC
- [ ] Тесты 80%+ deep + документация

## 5. Целевой уровень тестов

- **80%+ deep tests** (сейчас ~35% shallow grep-only)
- Docker-based тесты
- Реальные провайдеры
- Полный цикл установки

## 6. Конкурентный ландшафт → Экосистема интеграций

### Стратегическое решение (2026-09-11)
**VibeVM, Microsoft APM, AgentRC, Omakub — НЕ конкуренты, а ресурсы для интеграции.**

opencode_initializer — это **мета-проект**, лучший сборник для машины разработчика.
Цель: создать лучший сборник софта для developer machine, интегрируя лучшие доступные
инструменты как подпроекты, форки, зависимости.

### Инструменты для интеграции
| Инструмент | Лицензия | Что интегрировать |
|-----------|----------|-------------------|
| Microsoft APM | MIT | apm.yml как механизм распространения контекста агентов |
| Microsoft AgentRC | MIT | Генерация контекста агентов из кодовой базы |
| VibeVM | OpenSource | Spec-driven development, URI-addressable prompts |
| Omakub | MIT | Opinionated defaults для Ubuntu bootstrapping |
| chezmoi | MIT | Dotfile management |
| Nix home-manager | MIT | Declarative user environment |
| Dev Containers | MIT | Containerized dev environments |
| AGENTS.md | Apache-2.0 | Cross-agent standard |

### Принцип интеграции
1. **Fork + customize** — форкаем и настраиваем под наши нужды
2. **Subproject** — включаем как git submodule или subtree
3. **Dependency** — используем как зависимость (npm, pip, cargo)
4. **Inspiration** — заимствуем идеи и паттерны
5. **Contribute back** — contributes upstream, если возможно

### Уникальная позиция
opencode_initializer — **сборщик и интегратор**, не конкурент.
Он объединяет лучшие инструменты в единую, работающую среду разработчика.
5. Multi-agent архитектуру

## 7. Архитектурные решения

### ADR 1: Bash как основной язык (95%+)
- Причина: универсальность, нулевые зависимости, работает везде
- Trade-off: сложнее тестировать, нет типов

### ADR 2: Нумерованные модули (00-61)
- Причина: четкий порядок, детерминированное выполнение
- Trade-off: добавление модулей требует обновления TOTAL_STEPS

### ADR 3: Source-and-Gate паттерн
- Модули 41-51 — "sourced with existence guards but not step-executed"
- Разделяет "установить инструмент" и "предоставить возможность"

### ADR 4: Files as IPC (Redbook Pattern)
- Межагентное общение через файлы, не API
- .opencode/state/ — общее состояние

### ADR 5: SSOT Data Files
- src/data/providers.json, mcp-profiles.json, routing.json — единственный источник правды

### ADR 6: macOS bash 3.2 совместимость
- Нет declare -A, нет grep -P, портируемые обертки

### ADR 7: Diff-Before-Write для генерируемых конфигов
- SHA-256 сравнение, UNCHANGED/DIFF маркеры

### ADR 8: Harness-Engineering Doctrine
- "Каждая ошибка агента становится правилом в AGENTS.md или запрограммированным гейтом"

## 8. Метрики

| Метрика | Значение |
|---------|----------|
| Версия | v3.3.0 |
| Shell модули | 76 файлов в src/lib/ |
| Оркестратор | setup.sh — 727 строк, 48 шагов |
| CLI | dev.sh — 1014 строк, 22+ субкоманд |
| Всего Shell LOC | ~12,631 |
| Тесты | 104 (91 unit, 6 integration, 5 e2e) |
| Провайдеры | 22 (19 cloud + 3 local) |
| MCP сервера | 24 |
| LSP сервера | 12 |
| Плагины | 21 |
| Навыки | 43 SKILL.md |
| Языки | 6 (Java, Node, Python, Go, Rust, .NET) |
| Платформы | 6 package managers (apt, dnf, pacman, apk, zypper, brew) |

## 9. Состояние разработческой машины

- **MECHREVO JIAOLONG Series** (蛟龙 — китайский OEM)
- AMD Ryzen 9 9955HX (16 ядер / 32 потока)
- 64 ГБ RAM
- NVIDIA GeForce RTX 5070 Ti Laptop (12 ГБ VRAM, driver 595.84, CUDA 13.2)
- 2 ТБ NVMe: KINGSTON SFYRS1000G (1 ТБ) + YMTC PC41Q-1TB-B (1 ТБ)
- Ubuntu 26.04.1 LTS, GNOME 50, Wayland
- Firmware N.1.17MRO28

### Дисковая разметка
| Устройство | Размер | ФС | Монтирование |
|-----------|--------|-----|-------------|
| nvme1n1p1 | 16 МБ | — | не отформатирован |
| nvme1n1p2 | ~932 ГБ | — | **не смонтирован** |
| nvme0n1p1 | 1.1 ГБ | vfat | /boot/efi |
| nvme0n1p2 | 469 ГБ | ext4 | / (329 ГБ used, 117 ГБ free, 74%) |
| nvme0n1p3 | 16 МБ | — | — |
| nvme0n1p4 | 476 ГБ | ntfs | /run/media/.../445038BB5038B590 (Windows) |
| nvme0n1p5 | 773 МБ | ntfs | Windows recovery |

## 10. Открытые вопросы

1. Версионирование: теги v33.x/v35.0 существуют рядом с v1.x/v2.x — что произошло?
2. session_checkpoint.json ссылается на v2.0.3 (2026-08-08) — 16 дней отставания
3. architecture.md ссылается на "24 модуля" — сейчас 76
4. Goals directory содержит только lock files, нет реальных целей
5. upstream/ содержит git submodules — какой статус синхронизации?
6. .superpowers/ directory — отношение к .opencode/skills/ неясно