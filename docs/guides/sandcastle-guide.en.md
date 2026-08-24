# Sandcastle Guide

## Overview

[Sandcastle](https://github.com/mattpocock/sandcastle) orchestrates AI coding agents in isolated sandboxes (Docker/Podman/Vercel). Providers are swappable; it supports branch strategies and lifecycle hooks via the `sandcastle.run()` API.

Installed by `50-sandcastle.sh` (project-scoped — requires `PROJECT_DIR`).

## Sandbox Providers

| Provider | Requirement |
|----------|-------------|
| docker | Docker daemon running |
| podman | Podman installed |
| no-sandbox | none (agents run on the host) |

The module auto-detects the best available provider.

## Installation

```bash
# Inside your project
npm install --save-dev @ai-hero/sandcastle
npx @ai-hero/sandcastle init     # scaffolds .sandcastle/
```

## Scaffold

The scaffold creates:

- `.sandcastle/main.ts` — the agent runner
- `.sandcastle/prompt.md` — the task prompt (supports `{{PLACEHOLDER}}` templating)

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

## Authentication

Set credentials in `.sandcastle/.env`:

```bash
CLAUDE_CODE_OAUTH_TOKEN=    # via `claude setup-token`
# or
ANTHROPIC_API_KEY=
```

## Run

```bash
npx tsx .sandcastle/main.ts
```

## Skip

This is a project-scoped module — it skips when `PROJECT_DIR` is unset or Node.js is absent.
