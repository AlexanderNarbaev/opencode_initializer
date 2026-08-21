# Конфигурация

## Обзор

OpenCode Initializer использует несколько конфигурационных файлов для управления различными аспектами системы.

## Основные файлы конфигурации

### opencode.json

Основной конфигурационный файл OpenCode.

**Расположение:** `~/.config/opencode/opencode.json`

**Структура:**
```json
{
  "model": "deepseek/deepseek-v4-pro",
  "small_model": "deepseek/deepseek-v4-flash",
  "default_agent": "build",
  "provider": {
    "deepseek": {
      "fallback": ["zai", "opencode", "xai", "minimax"]
    }
  },
  "agent": {
    "build": {
      "mode": "primary",
      "model": "deepseek/deepseek-v4-pro",
      "temperature": 0.6
    },
    "plan": {
      "mode": "primary",
      "model": "deepseek/deepseek-v4-flash",
      "temperature": 0.1
    }
  },
  "plugin": [
    "opencode-codegraph",
    "opencode-dcp",
    "opencode-auto-fallback",
    "opencode-goal-mode",
    "opencode-goal-plugin",
    "opencode-orchestrator",
    "opencode-swarm",
    "opencode-supermemory",
    "opencode-token-tracker",
    "opencode-vibeguard"
  ],
  "mcp": {
    "context7": {
      "type": "local",
      "command": ["c7-mcp-server"],
      "enabled": true
    },
    "codegraph": {
      "type": "local",
      "command": ["codegraph"],
      "enabled": true
    }
  },
  "lsp": {
    "typescript": {
      "command": ["typescript-language-server", "--stdio"],
      "extensions": [".ts", ".tsx", ".js", ".jsx"],
      "enabled": true
    },
    "python": {
      "command": ["pyright-langserver", "--stdio"],
      "extensions": [".py"],
      "enabled": true
    }
  }
}
```

### bundle.json

Shared config для всех харнессов.

**Расположение:** `~/.config/opencode/bundle.json`

**Структура:**
```json
{
  "version": 1,
  "managed_by": "opencode_initializer@55-context-bundle",
  "plugins": {
    "context": "opencode-context",
    "router": "opencode-router"
  },
  "principles": [
    "all-harnesses-share-config",
    "plugins-complement-core",
    "context-is-shared-resource"
  ]
}
```

### setup.conf

Пersistent settings для setup.sh и dev CLI.

**Расположение:** `~/.config/opencode-setup/setup.conf`

**Структура:**
```bash
# Провайдеры
DEEPSEEK_API_KEY=your_key_here
OPENAI_API_KEY=your_key_here

# Настройки установки
SKIP_DOTFILES=false
SKIP_DEVBOX=false
SKIP_GUI=false

# Зеркала
USE_RUSSIAN_MIRRORS=false
```

## Переменные окружения

### Основные

| Переменная | Описание | По умолчанию |
|------------|----------|--------------|
| OPENCODE_MODEL | Модель по умолчанию | deepseek/deepseek-v4-pro |
| OPENCODE_SMALL_MODEL | Малая модель | deepseek/deepseek-v4-flash |
| OPENCODE_DEFAULT_AGENT | Агент по умолчанию | build |

### Провайдеры

| Переменная | Описание |
|------------|----------|
| DEEPSEEK_API_KEY | API ключ DeepSeek |
| OPENAI_API_KEY | API ключ OpenAI |
| ANTHROPIC_API_KEY | API ключ Anthropic |
| GOOGLE_API_KEY | API ключ Google |

### Установка

| Переменная | Описание | По умолчанию |
|------------|----------|--------------|
| SKIP_DOTFILES | Пропустить dotfiles | false |
| SKIP_DEVBOX | Пропустить Devbox | false |
| SKIP_GUI | Пропустить GUI | false |
| SKIP_CONTEXT_BUNDLE | Пропустить context bundle | false |
| SKIP_GRACE | Пропустить GRACE семантику | false |
| SKIP_CACHING | Пропустить кэширование | false |

### Контекст

| Переменная | Описание | По умолчанию |
|------------|----------|--------------|
| GRACE_HOME | Директория GRACE | ~/.config/opencode/grace |
| HAR_HOME | Директория har | ~/.local/share/har |
| HAR_CACHE | Кэш har | ~/.cache/har |

## Конфигурация провайдеров

### DeepSeek

```json
{
  "provider": {
    "deepseek": {
      "api_key": "your_key",
      "base_url": "https://api.deepseek.com",
      "models": ["deepseek-v4-pro", "deepseek-v4-flash"],
      "fallback": ["zai", "opencode", "xai", "minimax"]
    }
  }
}
```

### OpenAI

```json
{
  "provider": {
    "openai": {
      "api_key": "your_key",
      "base_url": "https://api.openai.com/v1",
      "models": ["gpt-5.5", "gpt-5.4-mini"],
      "fallback": ["anthropic", "google"]
    }
  }
}
```

### Anthropic

```json
{
  "provider": {
    "anthropic": {
      "api_key": "your_key",
      "base_url": "https://api.anthropic.com",
      "models": ["claude-opus-4.8", "claude-sonnet-4.6"],
      "fallback": ["openai", "google"]
    }
  }
}
```

## Конфигурация MCP серверов

### Локальные серверы

```json
{
  "mcp": {
    "context7": {
      "type": "local",
      "command": ["c7-mcp-server"],
      "enabled": true
    },
    "codegraph": {
      "type": "local",
      "command": ["codegraph"],
      "enabled": true
    },
    "filesystem": {
      "type": "local",
      "command": ["mcp-server-filesystem"],
      "enabled": true
    }
  }
}
```

### Удалённые серверы

```json
{
  "mcp": {
    "github": {
      "type": "remote",
      "url": "https://api.github.com/mcp",
      "enabled": true
    }
  }
}
```

## Конфигурация LSP серверов

```json
{
  "lsp": {
    "typescript": {
      "command": ["typescript-language-server", "--stdio"],
      "extensions": [".ts", ".tsx", ".js", ".jsx"],
      "enabled": true
    },
    "python": {
      "command": ["pyright-langserver", "--stdio"],
      "extensions": [".py"],
      "enabled": true
    },
    "go": {
      "command": ["gopls"],
      "extensions": [".go"],
      "enabled": true
    },
    "rust": {
      "command": ["rust-analyzer"],
      "extensions": [".rs"],
      "enabled": true
    }
  }
}
```

## Конфигурация плагинов

### Включение/отключение плагинов

```json
{
  "plugin": [
    "opencode-codegraph",
    "opencode-dcp",
    "opencode-auto-fallback",
    "opencode-goal-mode",
    "opencode-goal-plugin",
    "opencode-orchestrator",
    "opencode-swarm",
    "opencode-supermemory",
    "opencode-token-tracker",
    "opencode-vibeguard"
  ]
}
```

### Конфигурация плагинов

```json
{
  "plugin": [
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
  ]
}
```

## Конфигурация агентов

### Primary агенты

```json
{
  "agent": {
    "build": {
      "mode": "primary",
      "model": "deepseek/deepseek-v4-pro",
      "temperature": 0.6,
      "permission": {
        "bash": "allow",
        "edit": "allow",
        "read": "allow"
      }
    },
    "plan": {
      "mode": "primary",
      "model": "deepseek/deepseek-v4-flash",
      "temperature": 0.1,
      "permission": {
        "bash": "deny",
        "edit": "deny",
        "read": "allow"
      }
    }
  }
}
```

### Subagents

```json
{
  "agent": {
    "general": {
      "mode": "subagent",
      "model": "deepseek/deepseek-v4-pro",
      "temperature": 0.2
    },
    "explore": {
      "mode": "subagent",
      "model": "deepseek/deepseek-v4-flash",
      "temperature": 0.1
    }
  }
}
```
