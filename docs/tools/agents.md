# Агенты — роли и конфигурация

10 AI-агентов с разными ролями, моделями и правами доступа.

## Конфигурация

```json
{
  "agent": {
    "pm": {
      "model": "opencode-go/glm-5.1",
      "permissions": { "edit": false, "write": false, "bash": false }
    },
    "analyst": {
      "model": "opencode-go/glm-5.1",
      "permissions": { "edit": false, "write": false, "bash": false }
    },
    "architect": {
      "model": "opencode-go/glm-5.1",
      "permissions": { "edit": false, "write": false, "bash": false }
    },
    "developer": {
      "model": "deepseek/deepseek-v4-pro",
      "permissions": { "edit": true, "write": true, "bash": true }
    },
    "qa": {
      "model": "opencode-go/minimax-m2.7",
      "permissions": { "edit": true, "write": true, "bash": true }
    },
    "security": {
      "model": "opencode-go/glm-5",
      "permissions": { "edit": false, "write": false, "bash": false }
    },
    "devops": {
      "model": "deepseek/deepseek-v4-pro",
      "permissions": { "edit": true, "write": true, "bash": true }
    },
    "reviewer": {
      "model": "opencode-go/qwen3.6-plus",
      "permissions": { "edit": false, "write": false, "bash": false }
    },
    "researcher": {
      "model": "deepseek/deepseek-v4-pro",
      "permissions": { "edit": false, "write": false, "bash": false }
    },
    "designer": {
      "model": "opencode-go/minimax-m2.7",
      "permissions": { "edit": false, "write": false, "bash": false }
    }
  }
}
```

## Таблица ролей

| Агент | Модель | Доступ | Задача | Вызов |
|-------|--------|--------|--------|-------|
| pm | glm-5.1 | read-only | Требования, приоритеты | `@pm` |
| analyst | glm-5.1 | read-only | Анализ кодовой базы | `@analyst` |
| architect | glm-5.1 | read-only | Проектирование | `@architect` |
| developer | deepseek-v4-pro | full | Написание кода | `@developer` |
| qa | minimax-m2.7 | full | Тесты | `@qa` |
| security | glm-5 | read-only | Уязвимости | `@security` |
| devops | deepseek-v4-pro | full | Docker, CI/CD | `@devops` |
| reviewer | qwen3.6-plus | read-only | Код-ревью | `@reviewer` |
| researcher | deepseek-v4-pro | read-only | Исследования | `@researcher` |
| designer | minimax-m2.7 | read-only | UI/UX | `@designer` |

## Почему такое разделение

**Разные модели под разные задачи:**
- DeepSeek V4 Pro лучше всего пишет код → developer, devops
- GLM-5.1 лучше анализирует и проектирует → pm, analyst, architect
- MiniMax M2.7 быстрый и дешёвый → qa, designer
- Qwen3.6-Plus хорош в ревью → reviewer

**Разные права доступа:**
- read-only агенты НЕ МОГУТ изменить код или выполнить bash-команды
- Это значит что даже если модель "галлюцинирует" опасную команду — она не выполнится
- 7 из 10 агентов read-only — принцип минимальных привилегий

**Экономия:**
- read-only агенты используют меньше токенов (не нужно резервировать контекст под запись)
- Аналитические агенты на glm-5.1 через подписку OpenCode Go дешевле чем DeepSeek Pro

## Примеры использования

```bash
@developer "Добавь эндпоинт POST /api/auth/login с JWT"
@qa "Напиши тесты для AuthController"
@security "Проверь безопасность модуля auth"
@reviewer "Проверь PR #42"
@architect "Спроектируй переход на event-driven архитектуру"
@analyst "Найди все места где используется устаревший API"
@devops "Добавь healthcheck в Dockerfile"
@researcher "Сравни gRPC vs REST для микросервисов"
@designer "Создай landing page для продукта"
@pm "Разбей фичу 'платежи' на задачи"
```

## Промпты агентов

Каждый агент имеет свой системный промпт (см. [system-prompts.md](../prompts/system-prompts.md)):

- **pm:** user story → acceptance criteria → priority → effort
- **analyst:** находка → расположение → влияние → рекомендация
- **architect:** минимум 2 варианта с trade-off анализом
- **developer:** код без комментариев, guard clauses, стиль проекта
- **qa:** unit > integration > e2e, happy path + edge cases
- **security:** OWASP Top 10, CWE, код до/после
- **devops:** healthcheck, resource limits, secrets management
- **reviewer:** корректность, безопасность, производительность, читаемость
- **researcher:** проблема → варианты → сравнение → рекомендация
- **designer:** палитра, grid, clamp(), shadcn/ui, Lucide
