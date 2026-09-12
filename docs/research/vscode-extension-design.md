# OpenCode Initializer — VS Code Extension (Research)

## Overview

This document outlines the design for a VS Code extension that integrates
opencode_initializer directly into the editor.

## Features

### 1. One-Click Setup
- Run `opencode-init --full` from VS Code command palette
- Progress bar in status bar
- Output in dedicated terminal

### 2. Status Bar Integration
- Show current environment status
- Quick access to health check
- Provider connection status

### 3. Tree View
- **Services** — PostgreSQL, Redis, Qdrant status
- **Providers** — AI provider connection status
- **MCP Servers** — MCP server status
- **Tests** — Run tests from sidebar

### 4. Commands
| Command | Description |
|---------|-------------|
| `opencode-init.full` | Run full installation |
| `opencode-init.health` | Run health check |
| `opencode-init.test` | Run all tests |
| `opencode-init.testCore` | Run core tests |
| `opencode-init.security` | Run security scan |
| `opencode-init.benchmark` | Run benchmark |
| `opencode-init.sync` | Sync updates |
| `opencode-init.gui` | Open GUI dashboard |

### 5. Settings
```json
{
  "opencodeInit.projectRoot": "${workspaceFolder}",
  "opencodeInit.autoHealth": true,
  "opencodeInit.autoSync": false,
  "opencodeInit.parallel": 4,
  "opencodeInit.skipModules": []
}
```

### 6. Tasks
```json
{
  "version": "2.0.0",
  "tasks": [
    {
      "type": "shell",
      "command": "./setup.sh --full",
      "label": "opencode-init: Full Install"
    },
    {
      "type": "shell",
      "command": "./setup.sh --health",
      "label": "opencode-init: Health Check"
    },
    {
      "type": "shell",
      "command": "bash tests/unit/test_core.sh",
      "label": "opencode-init: Run Tests"
    }
  ]
}
```

## Implementation Plan

### Phase 1: Basic Extension
- [ ] Create extension scaffolding
- [ ] Implement command execution
- [ ] Add status bar integration
- [ ] Add output channel

### Phase 2: Tree View
- [ ] Services tree provider
- [ ] Providers tree provider
- [ ] MCP servers tree provider
- [ ] Tests tree provider

### Phase 3: Advanced Features
- [ ] Auto-health on workspace open
- [ ] Diagnostic integration
- [ ] Settings UI
- [ ] Webview dashboard

## Tech Stack
- TypeScript
- VS Code Extension API
- Node.js child_process for shell execution

## Repository Structure
```
vscode-opencode-init/
├── src/
│   ├── extension.ts
│   ├── commands/
│   ├── providers/
│   └── utils/
├── package.json
├── tsconfig.json
└── README.md
```
