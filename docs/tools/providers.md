---
layout: default
title: AI-провайдеры — сравнение и рекомендации
description: 6 AI-провайдеров: DeepSeek, OpenCode Go, xAI, MiMo, Moonshot, MiniMax. Цены, сравнение, когда какой использовать.
---

[Главная](../index.md) · [Справка](../reference.md)

# Провайдеры AI

[DeepSeek API](https://api-docs.deepseek.com/) · [xAI Docs](https://docs.x.ai/) · [Moonshot Docs](https://moonshot.cn/docs)

## Что выбрать

| Бюджет | Модель | Цена/мес |
|--------|--------|----------|
| $0 | Ollama локально | Бесплатно |
| $5 | DeepSeek V4 Flash | ~$5 |
| $25 | DeepSeek V4 Pro + Flash | ~$25 |
| $50 | Pro + Flash + xAI + MiMo | ~$50 |
| $150+ | Все 6 + GPU-кластер | $150+ |

---

## Таблица сравнения

| Провайдер | Модель | Вход $/1M | Выход $/1M | Контекст | РФ | Качество |
|-----------|--------|-----------|------------|----------|-----|----------|
| **DeepSeek** | v4-pro | $2.00 | $8.00 | 128K/64K | Да | Отлично |
| **DeepSeek** | v4-flash | $0.14 | $0.56 | 128K/16K | Да | Хорошо |
| OpenCode Go | glm-5.1 | подписка | подписка | 128K/16K | Ограничено | Хорошо |
| xAI | grok-3-beta | $5.00 | $15.00 | 128K/16K | VPN | Хорошо |
| MiMo | mi-1.5 | $0.20 | $0.60 | 32K/8K | Да | Средне |
| Moonshot | kimi-k2.6 | $1.00 | $4.00 | 1M/16K | Да | Хорошо |
| MiniMax | m3 | $0.15 | $0.60 | 128K/16K | Да | Средне |

---

## DeepSeek V4 Pro — основной

Почему:

- Лучшее цена/качество: бенчмарки кода на уровне GPT-5, цена в 2-3x ниже
- 64K выходных токенов (конкуренты: 16K)
- Доступен из РФ без VPN
- Flash-версия в 15x дешевле для рутинных задач

### Когда Pro vs Flash

| Задача | Модель | Причина |
|--------|--------|---------|
| Генерация кода | Pro | Нужно качество |
| Рефакторинг | Pro | Сложная логика |
| Архитектура | Pro | Глубокий анализ |
| Автодополнение | Flash | Быстро, дёшево |
| Поиск по коду | Flash | Не требует reasoning |
| Документация | Flash | Шаблонная работа |
| Тесты | Flash | Много повторяющегося кода |

---

## OpenCode Go

Модели: glm-5.1, glm-5, qwen3.6-plus, minimax-m2.7

Распределение ролей:

| Модель | Роли |
|--------|------|
| glm-5.1 | pm, analyst, architect |
| glm-5 | security |
| qwen3.6-plus | reviewer |
| minimax-m2.7 | qa, designer |

---

## Когда какой провайдер

| Ситуация | Провайдер | Почему |
|----------|-----------|--------|
| Основная работа | DeepSeek V4 Pro | Лучший баланс |
| Фоновые задачи | DeepSeek V4 Flash | Дёшево |
| Анализ, архитектура | OpenCode Go glm-5.1 | Специализация |
| Документация | xAI grok-3-beta | Стиль |
| Длинные документы (1M) | Moonshot kimi-k2.6 | Уникальный контекст |
| Максимальная экономия | MiniMax m3 | Самая низкая цена |
| DeepSeek упал | Auto-fallback → любой | Непрерывность |

---

## Конфигурация

```json
{
  "model": "deepseek/deepseek-v4-pro",
  "small_model": "deepseek/deepseek-v4-flash",
  "provider": {
    "deepseek": { "options": { "timeout": 600000, "chunkTimeout": 60000, "setCacheKey": true } },
    "opencode": { "options": { "timeout": 600000, "chunkTimeout": 60000, "setCacheKey": true } },
    "xai": { "options": { "timeout": 600000, "chunkTimeout": 60000, "setCacheKey": true } },
    "mimo": { "options": { "timeout": 600000, "chunkTimeout": 60000, "setCacheKey": true } },
    "moonshot": { "options": { "timeout": 600000, "chunkTimeout": 60000, "setCacheKey": true } },
    "minimax": { "options": { "timeout": 600000, "chunkTimeout": 60000, "setCacheKey": true } }
  }
}
```

Параметры: timeout 600000 (10 мин), chunkTimeout 60000 (1 мин), setCacheKey (кэширование).
