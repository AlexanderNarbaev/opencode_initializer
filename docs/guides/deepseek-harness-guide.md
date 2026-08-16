# DeepSeek Harness Guide

## Overview

[DeepSeek Harness](https://github.com/deepseek-ai/deepseek-harness) (`dsh`) is DeepSeek's open-source agent harness — *"everything is a plugin"*, powered by the [Cordis](https://github.com/deepseek-ai/deepseek-harness) framework. It provides a plugin-based architecture and a Web UI for orchestrating AI agents.

Installed by `49-deepseek-harness.sh`.

!!! note "Developer preview"
    DeepSeek Harness is in developer preview — compatibility-breaking changes are expected. MIT license.

## Prerequisites

- **Node.js 24** (installed by `06-node.sh`)

The module skips installation when Node.js is absent or when `dsh` is already on `PATH`.

## Installation

```bash
npm install -g @deepseek-ai/dsh@latest
```

## Configuration

The default plugin profile is written to `~/.config/deepseek-harness/cordis.yml`:

```yaml
# DeepSeek Harness — default plugin profile (managed by opencode_initializer)
# dsh is "everything is a plugin" (Cordis). Mount additional plugins here.
```

Extend it with additional plugins per the upstream [config catalog](https://github.com/deepseek-ai/deepseek-harness/blob/master/docs/config-catalog.md).

## Web UI

The Web UI is served at `http://127.0.0.1:3080` by default. Override the port with `DSH_WEB_PORT`.

```bash
npx @deepseek-ai/dsh web
# or start the systemd user service
systemctl --user start deepseek-harness.service
```

## Health Check

```bash
dsh --version                          # installed version
curl -fsS http://127.0.0.1:3080        # Web UI up?
```

## Skip

Set `SKIP_DEEPSEEK_HARNESS=true` to skip this module during setup.
