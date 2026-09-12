# OpenCode Initializer — Plugin Marketplace (Research)

## Overview

This document outlines the design for a plugin marketplace that allows
users to discover, install, and manage plugins for opencode_initializer.

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│                  Plugin Marketplace                      │
├─────────────────────────────────────────────────────────┤
│  Registry (GitHub/GitVerse)                             │
│  ├── Plugin manifest (plugin.json)                      │
│  ├── Plugin code                                        │
│  ├── Documentation                                      │
│  └── Reviews/Ratings                                    │
├─────────────────────────────────────────────────────────┤
│  CLI (opencode-init --discover-plugins)                 │
│  ├── Search                                             │
│  ├── Install                                            │
│  ├── Update                                             │
│  └── Remove                                             │
├─────────────────────────────────────────────────────────┤
│  Plugin Runtime                                         │
│  ├── Sandbox                                            │
│  ├── Permissions                                        │
│  └── Hooks                                              │
└─────────────────────────────────────────────────────────┘
```

## Plugin Manifest

```json
{
  "name": "my-plugin",
  "version": "1.0.0",
  "description": "A sample plugin",
  "author": "Alexander Narbaev",
  "license": "MIT",
  "repository": "https://github.com/AlexanderNarbaev/opencode-init-plugin-sample",
  "keywords": ["sample", "demo"],
  "minVersion": "8.0.0",
  "hooks": {
    "pre-install": "scripts/pre-install.sh",
    "post-install": "scripts/post-install.sh",
    "pre-update": "scripts/pre-update.sh",
    "post-update": "scripts/post-update.sh"
  },
  "permissions": [
    "filesystem.read",
    "filesystem.write",
    "network.fetch",
    "shell.execute"
  ],
  "dependencies": {
    "other-plugin": "^1.0.0"
  }
}
```

## Plugin Categories

| Category | Description | Examples |
|----------|-------------|----------|
| **Languages** | Language support | Go, Rust, Python |
| **Tools** | Development tools | Docker, Kubernetes |
| **Services** | Infrastructure services | PostgreSQL, Redis |
| **Providers** | AI providers | OpenAI, Anthropic |
| **Themes** | UI themes | Dark, Light |
| **Workflows** | Automation workflows | CI/CD, Deployment |
| **Integrations** | Third-party integrations | GitHub, GitLab |

## CLI Commands

```bash
# Search plugins
opencode-init --discover-plugins "database"

# Install plugin
opencode-init --plugin-install my-plugin

# Update plugin
opencode-init --plugin-update my-plugin

# Remove plugin
opencode-init --plugin-remove my-plugin

# List installed plugins
opencode-init --plugin-list

# Show plugin info
opencode-init --plugin-info my-plugin
```

## Plugin Registry

### GitHub-Based Registry
- Plugins stored as GitHub repositories
- Manifest in `plugin.json` at root
- Tags for versioning
- GitHub Actions for validation

### Registry Index
```json
{
  "plugins": [
    {
      "name": "my-plugin",
      "version": "1.0.0",
      "description": "A sample plugin",
      "repository": "https://github.com/user/opencode-init-plugin",
      "downloads": 1000,
      "stars": 50
    }
  ],
  "lastUpdated": "2026-09-12T00:00:00Z"
}
```

## Security Model

### Permissions
- `filesystem.read` — Read files
- `filesystem.write` — Write files
- `network.fetch` — Make HTTP requests
- `shell.execute` — Execute shell commands
- `docker.manage` — Manage Docker containers

### Sandboxing
- Plugins run in isolated environment
- Limited file system access
- Network requests logged
- Shell commands audited

## Implementation Plan

### Phase 1: Basic Registry
- [ ] Define plugin manifest format
- [ ] Create registry index
- [ ] Implement basic CLI commands

### Phase 2: Plugin Runtime
- [ ] Plugin sandboxing
- [ ] Permission system
- [ ] Hook system

### Phase 3: Marketplace UI
- [ ] Web-based marketplace
- [ ] Search and browse
- [ ] Reviews and ratings
- [ ] Plugin documentation

## Future Enhancements
- Plugin dependencies
- Plugin conflicts detection
- Automatic updates
- Plugin analytics
- Revenue sharing for premium plugins
