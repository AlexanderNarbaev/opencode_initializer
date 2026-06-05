---
layout: default
title: Плагины OpenCode — безопасность и производительность
description: 7 плагинов: stranger-danger, damage-control, codegraph, dcp, auto-fallback, lazy-loader, orchestra. Цепочка безопасности.
---

[Главная](../index.md) · [Справка](../reference.md)

# Плагины OpenCode

Плагины работают внутри OpenCode и влияют на его поведение. В отличие от MCP (внешние инструменты), плагины — часть самого агента.

## Цепочка безопасности

```
stranger-danger → damage-control → codegraph → dcp → auto-fallback
     (вход)        (выход)         (анализ)   (память)  (отказоуст.)
```

---

### opencode-codegraph (всегда активен)

Пакет: `opencode-codegraph`

Автоматически обогащает диалог графом вызовов. Экономия контекста: 5x (200 токенов вместо 1000).

```json
"plugin": ["opencode-codegraph"]
```

---

### opencode-dcp — Dynamic Context Pruning

Пакет: `@tarquinen/opencode-dcp`

Сжимает контекст при переполнении. Экономия: 62% стоимости запросов.

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

| Ситуация | Действие |
|----------|----------|
| Меньше 20K токенов | Сжатие не требуется |
| 20K-48K | Агрессивное сжатие старых сообщений |
| Больше 48K | Защита последних 40K, сжатие остального |

---

### opencode-stranger-danger — защита входа

Пакет: `@gitdamnit/opencode-stranger-danger`

Фильтрует PII и секреты из промптов. Блокирует prompt-инъекции.

Что фильтрует: API-ключи, токены, пароли, email, телефоны, попытки injection.

---

### opencode-damage-control — 144 защитных паттерна

Пакет: `opencode-damage-control`

Блокирует опасные команды до выполнения.

```json
["opencode-damage-control", {
  "guardrails": {
    "input": {
      "piiFiltering": true,
      "promptInjectionPrevention": true
    },
    "deterministicPolicies": {
      "blockedCommands": ["rm -rf /", "DROP TABLE", "terraform destroy"],
      "blockedPaths": ["~/.ssh", "~/.aws", ".env"]
    }
  },
  "audit": {
    "logTamperResistant": true,
    "logRetentionDays": 365
  }
}]
```

Категории блокировок: удаление системы (12), базы данных (18), инфраструктура (24), файловая система (15), чувствительные пути (25).

---

### opencode-auto-fallback — автопереключение

Пакет: `opencode-auto-fallback`

Порядок переключения: DeepSeek → OpenCode Go → xAI → MiMo → Moonshot → MiniMax.

---

### opencode-lazy-loader — отложенная загрузка

Пакет: `opencode-lazy-loader`

Ускорение холодного старта на 30-50%.

---

### open-orchestra — оркестрация агентов

Пакет: `open-orchestra`

Координирует параллельную работу агентов: architect → developer → reviewer → qa.
