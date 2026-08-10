# Корпоративный AI Gateway Proxy

> [EN](ai-gateway-proxy.md) | [RU](ai-gateway-proxy.ru.md)

## Обзор

Для корпоративных сред, где прямой доступ к внешним AI-провайдерам ограничен, opencode_initializer поддерживает маршрутизацию всего LLM-трафика через корпоративный AI Gateway (Envoy, Kong, NGINX и др.).

## Архитектура

```
Developer IDE (Cursor/VS Code/OpenCode)
    ↓
Corporate AI Gateway (Envoy/Kong)
    ↓ DLP + PII + Compliance
    ↓
External AI Providers (DeepSeek/OpenAI/Anthropic/...)
```

## Настройка

### Переменные окружения

| Переменная | Описание | Пример |
|----------|-------------|---------|
| `OPENCODE_PROXY_URL` | Глобальный URL прокси для всех провайдеров | `https://ai-gateway.corp.com/v1` |
| `OPENCODE_PROXY_DEEPSEEK` | Переопределение для конкретного провайдера | `https://ai-gateway.corp.com/deepseek/v1` |
| `OPENCODE_PROXY_OPENAI` | Переопределение для конкретного провайдера | `https://ai-gateway.corp.com/openai/v1` |
| `OPENCODE_PROXY_ANTHROPIC` | Переопределение для конкретного провайдера | `https://ai-gateway.corp.com/anthropic/v1` |
| `OPENCODE_PROXY_GOOGLE` | Переопределение для конкретного провайдера | `https://ai-gateway.corp.com/google/v1` |

### Быстрый старт

```bash
# Установите в .env или export
export OPENCODE_PROXY_URL="https://ai-gateway.corp.example.com/v1"

# Запустите установку — все провайдеры будут маршрутизироваться через прокси
bash setup.sh --full
```

### Конфигурация opencode.json

Прокси также можно настроить напрямую в `opencode.json`:

```json
{
  "provider": {
    "deepseek": {
      "options": {
        "baseURL": "https://ai-gateway.corp.example.com/deepseek/v1"
      }
    }
  }
}
```

## Контроль соответствия (Compliance)

Шлюз должен обеспечивать:

1. **DLP-конвейер**: обнаружение PII, сканирование секретов, обнаружение кода
2. **Классификация данных**: от Д-0 (публичные) до Д-5 (ограниченного доступа)
3. **Аудиторский след**: логирование всех запросов/ответов в SIEM
4. **Токенизация**: замена PII на токены перед отправкой внешним провайдерам
5. **Anti-Jailbreak**: NVIDIA NeMo Guardrails или аналоги

## Российские нормативные требования

- **152-ФЗ**: Защита персональных данных — PII должны быть токенизированы
- **98-ФЗ**: Коммерческая тайна — код и бизнес-данные не должны покидать периметр
- **Рекомендации Kaspersky**: следовать корпоративному чек-листу безопасности AI
