---
layout: default
title: AI-агенты — роли, модели, права
description: 10 AI-агентов для OpenCode: developer, architect, qa, security, devops, reviewer, researcher, designer, pm, analyst.
---

[Главная](../index.md) · [Промпты](../prompts/system-prompts.md)

# Агенты

10 AI-агентов с разными ролями, моделями и правами доступа.

## Таблица ролей

| Агент | Модель | Доступ | Задача |
|-------|--------|--------|--------|
| developer | deepseek-v4-pro | full | Написание кода |
| architect | glm-5.1 | read-only | Проектирование |
| qa | minimax-m2.7 | full | Тестирование |
| security | glm-5 | read-only | Уязвимости |
| devops | deepseek-v4-pro | full | Docker, CI/CD |
| reviewer | qwen3.6-plus | read-only | Код-ревью |
| researcher | deepseek-v4-pro | read-only | Исследования |
| designer | minimax-m2.7 | read-only | UI/UX |
| pm | glm-5.1 | read-only | Требования |
| analyst | glm-5.1 | read-only | Анализ базы |

## Почему такое разделение

**Разные модели:** DeepSeek V4 Pro — код, GLM-5.1 — анализ, MiniMax M2.7 — тесты.

**Разные права:** 7 из 10 агентов read-only. Даже если модель «галлюцинирует» опасную команду — не выполнится.

**Экономия:** read-only агенты дешевле (не резервируют контекст под запись).

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
```

Каждый агент имеет свой оптимизированный промпт. [См. промпты](../prompts/system-prompts.md).
