# OpenCode Initializer — Cloud IDE Support

## Overview

This document describes support for Cloud IDEs including:
- **GitHub Codespaces** — GitHub's cloud development environment
- **Gitpod** — Open-source cloud development environment
- **VS Code Remote** — VS Code remote development

## GitHub Codespaces

### Configuration File

Create `.devcontainer/devcontainer.json`:

```json
{
  "name": "OpenCode Initializer",
  "image": "mcr.microsoft.com/devcontainers/base:ubuntu",
  "features": {
    "ghcr.io/devcontainers/features/docker-in-docker:2": {},
    "ghcr.io/devcontainers/features/node:1": {},
    "ghcr.io/devcontainers/features/python:1": {},
    "ghcr.io/devcontainers/features/go:1": {},
    "ghcr.io/devcontainers/features/rust:1": {}
  },
  "postCreateCommand": "./setup.sh --full",
  "forwardPorts": [4200, 5432, 6379, 6333, 9090, 3000],
  "customizations": {
    "vscode": {
      "extensions": [
        "ms-vscode.vscode-json",
        "tamasfe.even-better-toml",
        "timonwong.shellcheck",
        "foxundermoon.shell-format"
      ]
    }
  }
}
```

### Usage

1. Open repository in GitHub
2. Click "Code" → "Codespaces" → "Create codespace"
3. Wait for setup to complete
4. Run `./setup.sh --health` to verify

## Gitpod

### Configuration File

Create `.gitpod.yml`:

```yaml
tasks:
  - name: Setup Development Environment
    init: |
      ./setup.sh --full
    command: |
      ./setup.sh --health

ports:
  - port: 4200
    onOpen: notify
    name: GUI Dashboard
  - port: 5432
    onOpen: ignore
    name: PostgreSQL
  - port: 6379
    onOpen: ignore
    name: Redis
  - port: 6333
    onOpen: ignore
    name: Qdrant
  - port: 9090
    onOpen: ignore
    name: Prometheus
  - port: 3000
    onOpen: ignore
    name: Grafana

vscode:
  extensions:
    - tamasfe.even-better-toml
    - timonwong.shellcheck
    - foxundermoon.shell-format
```

### Usage

1. Open `https://gitpod.io/#https://github.com/AlexanderNarbaev/opencode_initializer`
2. Wait for setup to complete
3. Access GUI at port 4200

## VS Code Remote

### Configuration File

Create `.vscode/settings.json`:

```json
{
  "remote.containers.defaultExtensions": [
    "ms-vscode.vscode-json",
    "tamasfe.even-better-toml",
    "timonwong.shellcheck",
    "foxundermoon.shell-format"
  ]
}
```

### Usage

1. Install VS Code Remote - Containers extension
2. Open repository in VS Code
3. Click "Reopen in Container"
4. Wait for setup to complete

## Implementation

### New Files

```
.devcontainer/
├── devcontainer.json    # GitHub Codespaces config
├── Dockerfile           # Custom container image
└── scripts/
    └── setup.sh         # Container setup script

.gitpod.yml              # Gitpod config
.vscode/
└── settings.json        # VS Code settings
```

### Dockerfile

```dockerfile
FROM mcr.microsoft.com/devcontainers/base:ubuntu

# Install dependencies
RUN apt-get update && apt-get install -y \
    bash \
    curl \
    git \
    docker.io \
    && rm -rf /var/lib/apt/lists/*

# Copy project
COPY . /workspace/opencode_initializer
WORKDIR /workspace/opencode_initializer

# Run setup
RUN ./setup.sh --full
```

## Benefits

1. **Instant Setup** — No local installation required
2. **Consistent Environment** — Same setup for all developers
3. **Pre-configured** — All tools ready to use
4. **Accessible** — Works from any device with a browser
5. **Collaborative** — Easy to share development environments

## Future Enhancements

1. **Gitpod Prebuilds** — Faster startup times
2. **Codespaces Custom Images** — Optimized container images
3. **Remote SSH** — Connect to remote servers
4. **Cloud Storage** — Persistent storage across sessions
