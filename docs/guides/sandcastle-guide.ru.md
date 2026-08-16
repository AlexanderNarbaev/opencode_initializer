# Руководство по Sandcastle

> [EN](sandcastle-guide.md) | [RU](sandcastle-guide.ru.md)

## Обзор

[Sandcastle](https://github.com/mattpocock/sandcastle) оркестрирует AI-агентов кодинга в изолированных песочницах (Docker/Podman/Vercel). Провайдеры взаимозаменяемы; поддерживает стратегии веток и lifecycle-хуки через API `sandcastle.run()`.

Устанавливается модулем `50-sandcastle.sh` (проектно-скопированный — требует `PROJECT_DIR`).

## Провайдеры песочниц

| Провайдер | Требование |
|-----------|------------|
| docker | Запущенный Docker daemon |
| podman | Установленный Podman |
| no-sandbox | нет (агенты работают на хосте) |

Модуль автоматически определяет лучший доступный провайдер.

## Установка

```bash
# Внутри вашего проекта
npm install --save-dev @ai-hero/sandcastle
npx @ai-hero/sandcastle init     # создаёт .sandcastle/
```

## Скаффолд

Скаффолд создаёт:

- `.sandcastle/main.ts` — раннер агента
- `.sandcastle/prompt.md` — промпт задачи (поддерживает шаблонизацию `{{PLACEHOLDER}}`)

```typescript
// .sandcastle/main.ts
import { run, claudeCode } from "@ai-hero/sandcastle";
import { docker } from "@ai-hero/sandcastle/sandboxes/docker";
// import { podman } from "@ai-hero/sandcastle/sandboxes/podman";
// import { noSandbox } from "@ai-hero/sandcastle/sandboxes/no-sandbox";

const sandbox = docker();

await run({
  agent: claudeCode("claude-opus-4-8"),
  sandbox,
  promptFile: ".sandcastle/prompt.md",
});
```

## Аутентификация

Укажите учётные данные в `.sandcastle/.env`:

```bash
CLAUDE_CODE_OAUTH_TOKEN=    # через `claude setup-token`
# или
ANTHROPIC_API_KEY=
```

## Запуск

```bash
npx tsx .sandcastle/main.ts
```

## Пропуск

Это проектно-скопированный модуль — пропускается, когда `PROJECT_DIR` не задан или Node.js отсутствует.
