# Плагины OpenCode — подробное руководство

Плагины работают внутри OpenCode и влияют на его поведение. В отличие от MCP (внешние инструменты), плагины — часть самого агента.

## Цепочка безопасности

```
stranger-danger → damage-control → codegraph → dcp → auto-fallback
     (вход)        (выход)         (анализ)   (память)  (отказоуст.)
```

---

## opencode-codegraph

**Всегда активен.** Автоматически обогащает диалог графом вызовов проекта.

```json
"plugin": ["opencode-codegraph"]
```

**Эффект:** агент видит структуру кода за ~200 токенов вместо ~1000 токенов grep-вывода. Экономия контекста: 5×.

---

## opencode-dcp — Dynamic Context Pruning

**Пакет:** `@tarquinen/opencode-dcp`

Сжимает контекст когда диалог становится слишком длинным.

```json
["opencode-dcp", {
  "compress": {
    "enabled": true,
    "minContextLimit": 20000,
    "maxContextLimit": 48000,
    "autoCompaction": true
  },
  "prune": {
    "enabled": true,
    "protectTokens": 40000,
    "minTokens": 20000
  }
}]
```

**Пороги и логика:**

| Ситуация | Действие |
|----------|----------|
| < 20K токенов | Сжатие не требуется |
| 20K–48K | Агрессивное сжатие старых сообщений |
| > 48K | Защита последних 40K, сжатие остального |

**Экономия:** 48K лимит вместо 128K → каждый запрос к DeepSeek V4 Pro стоит $0.096 вместо $0.256 (экономия 62%).

---

## opencode-stranger-danger — Защита входа

**Пакет:** `@gitdamnit/opencode-stranger-danger`

Фильтрует PII и секреты из промптов. Блокирует prompt-инъекции.

```json
"opencode-stranger-danger"
```

**Что фильтрует:**
- API-ключи (`sk-...`, `ghp_...`, etc)
- Токены (JWT, OAuth)
- Пароли в коде
- Email, телефоны, адреса
- Попытки prompt injection

**Без него:** секреты из запроса уходят провайдеру и попадают в логи.

---

## opencode-damage-control — 144 защитных паттерна

**Пакет:** `opencode-damage-control`

Блокирует опасные команды до их выполнения.

```json
["opencode-damage-control", {
  "guardrails": {
    "input": {
      "piiFiltering": true,
      "promptInjectionPrevention": true
    },
    "deterministicPolicies": {
      "blockedCommands": [
        "rm -rf /",
        "DROP TABLE",
        "terraform destroy"
      ],
      "blockedPaths": [
        "~/.ssh",
        "~/.aws",
        ".env"
      ]
    }
  },
  "audit": {
    "logTamperResistant": true,
    "logRetentionDays": 365
  }
}]
```

**Категории блокировок:**

| Категория | Примеры | Паттернов |
|-----------|---------|-----------|
| Удаление системы | `rm -rf /`, `dd if=/dev/zero` | 12 |
| Базы данных | `DROP TABLE`, `TRUNCATE` | 18 |
| Инфраструктура | `terraform destroy`, `kubectl delete ns` | 24 |
| Файловая система | `chmod 777 /`, fork bomb | 15 |
| Чувствительные пути | `~/.ssh`, `~/.aws`, `.env` | 25 |

---

## opencode-auto-fallback — Автопереключение провайдеров

**Пакет:** `opencode-auto-fallback`

Если основной провайдер недоступен — переключает на следующий.

```json
"opencode-auto-fallback"
```

**Порядок переключения:**
1. DeepSeek V4 Pro (основной)
2. OpenCode Go (glm-5.1)
3. xAI (grok-3-beta)
4. MiMo (mi-1.5)
5. Moonshot (kimi-k2.6)
6. MiniMax (m3)

---

## opencode-lazy-loader — Отложенная загрузка

**Пакет:** `opencode-lazy-loader`

Не загружает все плагины при старте — только когда нужны.

```json
"opencode-lazy-loader"
```

**Эффект:** ускорение холодного старта OpenCode на 30-50%.

---

## open-orchestra — Оркестрация агентов

**Пакет:** `open-orchestra`

Координирует работу нескольких агентов параллельно.

```json
"open-orchestra"
```

**Сценарий:**
```
@orchestra "Спроектируй и реализуй API для авторизации"
  → architect: проектирует схему
  → developer: пишет код
  → reviewer: проверяет
  → qa: пишет тесты
```
