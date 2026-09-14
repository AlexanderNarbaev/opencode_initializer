# Сводный план развития проектов — Июль 2026

> Сгенерирован: 2026-07-18 в рамках синхронизации всех проектов
> Цель: единое видение, приоритизация, синхронизация инструментов и документации

## Обзор проектов

| # | Проект | Тип | Статус | CI/CD | opencode.json | AGENTS.md |
|---|--------|-----|--------|-------|---------------|-----------|
| 1 | `opencode_initializer` | Dev-инфраструктура | v2.0.0 active | ✅ | ✅ | ✅ |
| 2 | `opora` | Бэкенд-платформа | active | ✅ | ✅ | ✅ |
| 3 | `opora-landing` | Лендинг (Jekyll) | active | ✅ | ✅ | ✅ |
| 4 | `agi` | Игровой AI-проект (MATRIX) | active | ✅ | ✅ | ✅ |
| 5 | `rag-system` | RAG/KM система | active | ✅ | ✅ | ✅ |
| 6 | `rag-system-bak` | RAG бэкап | archive | ✅ | ✅ | ✅ |
| 7 | `ThePath` | Consciousness spiral | active | ✅ | ✅ | ✅ |
| 8 | `DeepSeek` | Data archive | passive | ❌ | ✅ | ✅ |
| 9 | `AlexandrNarbaev` | GitHub Profile | passive | ❌ | ✅ | ✅ |

## Единые стандарты (июль 2026)

### Версии инструментов
| Инструмент | Версия | Обновлён |
|------------|--------|----------|
| Java 25 LTS (Adoptium, apt fallback: 21 LTS) | июль 2026 |
| Node.js | 24 | — |
| Python | 3.14.6 + uv | июль 2026 |
| Go | 1.26.5 | июль 2026 |
| Rust | 1.97.1 (stable) | июль 2026 |
| .NET | 10.0.302 SDK | июль 2026 |
| Zig | 0.15.2 | июль 2026 |
| Bun | 1.3.14 | июль 2026 |
| OpenCode CLI | 1.17 | — |

### AI-модели
| Роль | Модель | Контекст |
|------|--------|----------|
| Primary | `deepseek/deepseek-v4-pro` | 1M, thinking auto |
| Small/Fast | `deepseek/deepseek-v4-flash` | 1M, non-thinking |
| Agentic | `moonshotai/kimi-k3` | 1M |
| RU/CN | `zai/glm-5.2` | free tier |
| Budget | `google/gemini-3.5-flash` | — |

### Провайдеры (24)
20 cloud + 4 local. Все проекты используют единый реестр из `opencode_initializer/src/lib/26-providers.sh`.

## Приоритеты развития (Q3 2026)

### P0 — Критические
1. **opencode_initializer**: Завершить миграцию на DeepSeek V4 до 24.07.2026 (уже выполнено ✅)
2. **opencode_initializer**: CI/CD green на GitHub + GitVerse
3. **Все проекты**: Переход Moonshot Kimi K2.6 → K3 (уже выполнен ✅)
4. **Moonshot**: api.moonshot.ai (platform.kimi.ai) — ключи обновлены на актуальный endpoint

### P1 — Высокий приоритет
1. **opora**: Стабилизация core-модулей (каталог, верификация, AI-кооперация)
2. **rag-system**: Интеграция с MemoryLayer + Qdrant
3. **agi**: Завершение MATRIX V3 архитектуры, FPGA-ускорение

### P2 — Средний приоритет
1. **opora-landing**: Обновление контента под актуальные 17 модулей
2. **ThePath**: Визуализация спиральной модели сознания
3. **DeepSeek**: Каталогизация архивных данных, индексация

### P3 — Низкий приоритет
1. **AlexandrNarbaev**: Обновление профиля с актуальными проектами
2. **rag-system-bak**: Консервация, безопасное удаление через 6 мес

## Синхронизация документации

- [x] Все проекты имеют `opencode.json`
- [x] Все проекты имеют `AGENTS.md`
- [x] DeepSeek V4 во всех проектах (v3 удалён)
- [x] Moonshot K3 во всех конфигурациях
- [x] opencode_initializer: документация (README, AGENTS.md, docs/) синхронизирована

## Тестовое покрытие

| Проект | Тесты | Покрытие |
|--------|-------|----------|
| opencode_initializer | 350+ assertions | unit (12) + integration (5) + e2e (4) |
| opora | JUnit 5 + Mockito + REST Assured + Cucumber + Gatling | TBD |
| agi | TBD | TBD |
| rag-system | TBD | TBD |

## CI/CD статус

- `opencode_initializer`: GitHub Actions (test, shellcheck, docs)
- `opora`: GitHub Actions (Java CI)
- `opora-landing`: GitHub Actions (GitHub Pages deploy)
- `agi`: GitHub Actions
- `rag-system`, `rag-system-bak`: GitHub Actions
- `ThePath`: GitHub Actions
- `DeepSeek`, `AlexandrNarbaev`: без CI (пассивные проекты)

## Следующие шаги

1. Прогнать полный test suite `opencode_initializer` — `bash tests/run_tests.sh`
2. Прогнать shellcheck по всем `.sh` файлам
3. Обновить CI/CD пайплайны для поддержки новых версий (Java 25, Rust 1.97)
4. Создать автоматическую проверку `opencode.json` + `AGENTS.md` наличия во всех проектах
