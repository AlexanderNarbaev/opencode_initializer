# Руководство по настройке провайдеров — opencode_initializer v2.0

> [EN](provider-setup.md) | [RU](provider-setup.ru.md)

## Обзор

23 AI-провайдера: 20 облачных + 3 локальных. Все настраиваются через `src/lib/26-providers.sh` и `src/lib/18-opencode-json.sh`.

## Конечные точки провайдеров (проверено 2026-07-18)

| Провайдер | Endpoint | Модель | Статус |
|----------|----------|-------|--------|
| DeepSeek | api.deepseek.com | deepseek-v4-pro | ✅ Бесплатный тариф |
| z.ai GLM | api.z.ai/api/paas/v4 | glm-5.2 | ✅ Бесплатный тариф |
| OpenRouter | openrouter.ai/api/v1 | 100+ моделей | ✅ Агрегатор |
| MiniMax | **api.minimax.io** | MiniMax-M3 | 🔧 Кредиты Token Plan |
| xAI Grok | api.x.ai | grok-4.3 | ✅ Работает |
| Alibaba Qwen | dashscope-intl.aliyuncs.com | qwen3.7-plus | ✅ Бесплатный тариф |
| DeepInfra | api.deepinfra.com | Llama-4-Maverick | ✅ Бесплатный тариф |
| Ollama | localhost:11434 | llama3.2, qwen3 | ✅ Локальный |

## Источники API-ключей

| Провайдер | Источник ключа | Переменная окружения |
|----------|-----------|-------------|
| DeepSeek | platform.deepseek.com/api_keys | DEEPSEEK_API_KEY |
| MiniMax | platform.minimax.io (Token Plan или PayG) | MINIMAX_API_KEY |
| xAI | console.x.ai | XAI_API_KEY |
| z.ai | open.bigmodel.cn | ZAI_API_KEY |
| OpenRouter | openrouter.ai/keys | OPENROUTER_API_KEY |

## Изолированный режим (Air-Gapped / Isolated Circuit)

```bash
dev isolated on           # Включить: только локальные провайдеры
ollama pull qwen3:8b      # Загрузить модель для кодинга
ollama pull llama3.2      # Быстрая чат-модель
# Только CPU: используйте llama.cpp с GGUF-моделями
# Qwen3-Coder-30B-A3B, GigaChat-20B
```

## Проверка работоспособности провайдеров

```bash
bash scripts/provider-check.sh   # Тестирует всех настроенных провайдеров
```

## Профили маршрутизации моделей

| Профиль | Модель | Назначение |
|---------|-------|----------|
| coding | deepseek-v4-pro | Основная реализация |
| agentic | deepseek-v4-pro | Использование инструментов, агенты |
| reasoning | claude-opus-4-8 | Архитектура, планирование |
| fast | deepseek-v4-flash | Быстрые ответы |
| budget | glm-5.2 | Чувствительные к стоимости задачи |
| ru_cn | glm-5.2 | Русский / китайский язык |
