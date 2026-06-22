---
layout: default
title: AI-агенты — 16 ролей, модели, права
description: 16 AI-агентов для OpenCode: developer, architect, qa, security, devops, reviewer, researcher, designer, pm, analyst, docs-writer, security-auditor, debugger, go-dev, rust-dev, ts-dev.
---

[Главная](../index.md) · [Промпты](../prompts/system-prompts.md)

# Агенты

16 AI-агентов с разными ролями, моделями и правами доступа.

## Таблица ролей

| Агент | Модель | Доступ | Задача |
|-------|--------|--------|--------|
| developer | deepseek-v4-pro | full | Написание кода |
| architect | glm-5.1 | read-only | Проектирование |
| qa | minimax-m2.7 | full | Тестирование |
| security | glm-5 | read-only | Анализ уязвимостей |
| devops | deepseek-v4-pro | full | Docker, CI/CD |
| reviewer | qwen3.6-plus | read-only | Код-ревью |
| researcher | deepseek-v4-pro | read-only | Исследования |
| designer | minimax-m2.7 | read-only | UI/UX |
| pm | glm-5.1 | read-only | Требования |
| analyst | glm-5.1 | read-only | Анализ кодовой базы |
| docs-writer | deepseek-v4-flash | write (no bash) | Документация |
| security-auditor | deepseek-v4-pro | read-only | Аудит безопасности |
| debugger | deepseek-v4-pro | full | Отладка кода |
| go-dev | deepseek-v4-pro | full | Go-разработка |
| rust-dev | deepseek-v4-pro | full | Rust-разработка |
| ts-dev | deepseek-v4-flash | full | TypeScript-разработка |

## Почему такое разделение

**Разные модели:** DeepSeek V4 Pro — код, GLM-5.1 — анализ, MiniMax M2.7 — тесты.

**Разные права:** 8 из 16 агентов read-only. Даже если модель «галлюцинирует» опасную команду — не выполнится.

**Экономия:** read-only агенты дешевле (не резервируют контекст под запись).

**Специализация:** Язык-специфичные агенты (go-dev, rust-dev, ts-dev) оптимизированы под экосистемы.

## Примеры

```
@developer "Добавь эндпоинт POST /api/auth/login с JWT"
@qa "Напиши тесты для AuthController"
@security "Проверь безопасность модуля auth"
@reviewer "Проверь PR #42"
@architect "Спроектируй переход на event-driven"
@analyst "Найди где используется устаревший API"
@devops "Добавь healthcheck в Dockerfile"
@researcher "Сравни gRPC vs REST"
@designer "Создай landing page"
@pm "Разбей фичу 'платежи' на задачи"
@docs-writer "Напиши документацию для API"
@security-auditor "Полный аудит безопасности проекта"
@debugger "Найди причину утечки памяти"
@go-dev "Рефакторинг Go-сервиса"
@rust-dev "Оптимизируй критический путь на Rust"
@ts-dev "Добавь типизацию в React-компоненты"
```

Каждый агент имеет свой оптимизированный промпт. [См. промпты](../prompts/system-prompts.md).
