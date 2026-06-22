---
layout: default
title: Справка — opencode_initializer
description: 100+ ссылок на официальную документацию, репозитории и источники.
---

[← На главную](index.md) · [Руководство](guide.md) · [База знаний](KNOWLEDGE.md)

# Справка — официальная документация и внешние ресурсы

## OpenCode и экосистема

| Ресурс | URL |
|--------|-----|
| OpenCode CLI | [opencode.ai/docs](https://opencode.ai/docs) |
| OpenCode GitHub | [github.com/opencode-ai](https://github.com/opencode-ai) |
| Model Context Protocol | [modelcontextprotocol.io](https://modelcontextprotocol.io/) |
| MCP спецификация | [spec.modelcontextprotocol.io](https://spec.modelcontextprotocol.io/) |

## AI-провайдеры

| Провайдер | API-ключи | Документация | Статус |
|-----------|-----------|-------------|--------|
| DeepSeek | [platform.deepseek.com](https://platform.deepseek.com/) | [api-docs.deepseek.com](https://api-docs.deepseek.com/) | [status.deepseek.com](https://status.deepseek.com/) |
| OpenCode Go | [opencode.ai/auth](https://opencode.ai/auth) | — | — |
| xAI Grok | [console.x.ai](https://console.x.ai/) | [docs.x.ai](https://docs.x.ai/) | — |
| MiMo | — | — | — |
| Moonshot | [platform.moonshot.cn](https://platform.moonshot.cn/) | [moonshot.cn/docs](https://moonshot.cn/docs) | — |
| MiniMax | [platform.minimax.io](https://platform.minimax.io/) | [minimax.io/docs](https://minimax.io/docs) | — |

## MCP-серверы

### Активные по умолчанию (npm)

| Сервер | Пакет npm | GitHub |
|--------|-----------|--------|
| context7 | [c7-mcp-server](https://www.npmjs.com/package/c7-mcp-server) | — |
| context7-official | [@upstash/context7-mcp](https://www.npmjs.com/package/@upstash/context7-mcp) | — |
| filesystem | [@modelcontextprotocol/server-filesystem](https://www.npmjs.com/package/@modelcontextprotocol/server-filesystem) | [servers](https://github.com/modelcontextprotocol/servers) |
| agentic-tools | [@pimzino/agentic-tools-mcp](https://www.npmjs.com/package/@pimzino/agentic-tools-mcp) | — |
| codegraph | [@colbymchenry/codegraph](https://www.npmjs.com/package/@colbymchenry/codegraph) | — |
| playwright | [@playwright/mcp](https://www.npmjs.com/package/@playwright/mcp) | [microsoft/playwright-mcp](https://github.com/microsoft/playwright-mcp) |
| agent-browser | [agent-browser-mcp-server](https://www.npmjs.com/package/agent-browser-mcp-server) | — |
| loopsense | [@loopsense/mcp](https://www.npmjs.com/package/@loopsense/mcp) | — |
| sequential-thinking | [@modelcontextprotocol/server-sequential-thinking](https://www.npmjs.com/package/@modelcontextprotocol/server-sequential-thinking) | [servers](https://github.com/modelcontextprotocol/servers) |
| memorylayer | [@scitrera/memorylayer-mcp-server](https://www.npmjs.com/package/@scitrera/memorylayer-mcp-server) | — |
| chrome-devtools | [chrome-devtools-mcp](https://www.npmjs.com/package/chrome-devtools-mcp) | — |
| memory | [@modelcontextprotocol/server-memory](https://www.npmjs.com/package/@modelcontextprotocol/server-memory) | [servers](https://github.com/modelcontextprotocol/servers) |
| redis | [@modelcontextprotocol/server-redis](https://www.npmjs.com/package/@modelcontextprotocol/server-redis) | [servers](https://github.com/modelcontextprotocol/servers) |

### Активные по умолчанию (Python/uvx)

| Сервер | PyPI | GitHub |
|--------|------|--------|
| git | [mcp-server-git](https://pypi.org/project/mcp-server-git/) | [modelcontextprotocol/servers](https://github.com/modelcontextprotocol/servers) |
| fetch | [mcp-server-fetch](https://pypi.org/project/mcp-server-fetch/) | [modelcontextprotocol/servers](https://github.com/modelcontextprotocol/servers) |
| time | [mcp-server-time](https://pypi.org/project/mcp-server-time/) | [modelcontextprotocol/servers](https://github.com/modelcontextprotocol/servers) |
| sqlite | [mcp-server-sqlite](https://pypi.org/project/mcp-server-sqlite/) | [modelcontextprotocol/servers](https://github.com/modelcontextprotocol/servers) |
| excalidraw | [excalidraw-architect-mcp](https://pypi.org/project/excalidraw-architect-mcp/) | — |

### С ключом API

| Сервер | Пакет | GitHub |
|--------|-------|--------|
| github | [@modelcontextprotocol/server-github](https://www.npmjs.com/package/@modelcontextprotocol/server-github) | [servers](https://github.com/modelcontextprotocol/servers) |
| postgres | [@modelcontextprotocol/server-postgres](https://www.npmjs.com/package/@modelcontextprotocol/server-postgres) | [servers](https://github.com/modelcontextprotocol/servers) |
| gitlab | [mcp-server-gitlab](https://www.npmjs.com/package/mcp-server-gitlab) | [modelcontextprotocol/servers](https://github.com/modelcontextprotocol/servers) |
| google-maps | [mcp-server-google-maps](https://www.npmjs.com/package/mcp-server-google-maps) | [modelcontextprotocol/servers](https://github.com/modelcontextprotocol/servers) |
| brave-search | [brave-search-mcp](https://www.npmjs.com/package/brave-search-mcp) | — |
| notion | [@notionhq/notion-mcp-server](https://www.npmjs.com/package/@notionhq/notion-mcp-server) | — |

### Remote

| Сервер | URL |
|--------|-----|
| sentry | [mcp.sentry.dev/mcp](https://mcp.sentry.dev/mcp) |
| grep | [mcp.grep.app](https://mcp.grep.app) |

## Плагины OpenCode

| Плагин | npm |
|--------|-----|
| opencode-codegraph | [npm](https://www.npmjs.com/package/opencode-codegraph) |
| opencode-orchestrator | [npm](https://www.npmjs.com/package/opencode-orchestrator) |
| opencode-token-tracker | [npm](https://www.npmjs.com/package/opencode-token-tracker) |
| opencode-notify | [npm](https://www.npmjs.com/package/opencode-notify) |
| opencode-pty | [npm](https://www.npmjs.com/package/opencode-pty) |
| opencode-ignore | [npm](https://www.npmjs.com/package/opencode-ignore) |
| opencode-snip | [npm](https://www.npmjs.com/package/opencode-snip) |
| opencode-snippets | [npm](https://www.npmjs.com/package/opencode-snippets) |
| envsitter-guard | [npm](https://www.npmjs.com/package/envsitter-guard) |
| opencode-command-inject | [npm](https://www.npmjs.com/package/opencode-command-inject) |
| opencode-dcp | [npm: @tarquinen/opencode-dcp](https://www.npmjs.com/package/@tarquinen/opencode-dcp) |
| opencode-auto-fallback | [npm](https://www.npmjs.com/package/opencode-auto-fallback) |
| opencode-goal-mode | [npm](https://www.npmjs.com/package/opencode-goal-mode) |
| opencode-swarm | [npm](https://www.npmjs.com/package/opencode-swarm) |
| opencode-vibeguard | [npm](https://www.npmjs.com/package/opencode-vibeguard) |
| opencode-daytona | [npm](https://www.npmjs.com/package/opencode-daytona) |
| opencode-devcontainers | [npm](https://www.npmjs.com/package/opencode-devcontainers) |
| opencode-worktree | [npm](https://www.npmjs.com/package/opencode-worktree) |
| opencode-scheduler | [npm](https://www.npmjs.com/package/opencode-scheduler) |
| opencode-background-agents | [npm](https://www.npmjs.com/package/opencode-background-agents) |
| opencode-skillful | [npm: @zenobius/opencode-skillful](https://www.npmjs.com/package/@zenobius/opencode-skillful) |
| opencode-goal-plugin | [npm](https://www.npmjs.com/package/opencode-goal-plugin) |
| opencode-conductor | [npm](https://www.npmjs.com/package/opencode-conductor) |
| opencode-supermemory | [npm](https://www.npmjs.com/package/opencode-supermemory) |
| opencode-websearch-cited | [npm](https://www.npmjs.com/package/opencode-websearch-cited) |
| opencode-zellij-namer | [npm](https://www.npmjs.com/package/opencode-zellij-namer) |
| opencode-morph-plugin | [npm: @morphllm/opencode-morph-plugin](https://www.npmjs.com/package/@morphllm/opencode-morph-plugin) |
| opencode-firecrawl | [npm: @lyculs/opencode-firecrawl](https://www.npmjs.com/package/@lyculs/opencode-firecrawl) |
| opencode-otel | [npm: @devtheops/opencode-plugin-otel](https://www.npmjs.com/package/@devtheops/opencode-plugin-otel) |

## LSP-серверы

| LSP | Язык | Документация |
|-----|------|-------------|
| gopls | Go | [pkg.go.dev/golang.org/x/tools/gopls](https://pkg.go.dev/golang.org/x/tools/gopls) |
| rust-analyzer | Rust | [rust-analyzer.github.io](https://rust-analyzer.github.io/) |
| typescript-language-server | TypeScript/JS | [github.com/typescript-language-server](https://github.com/typescript-language-server/typescript-language-server) |
| pyright | Python | [github.com/microsoft/pyright](https://github.com/microsoft/pyright) |
| omnisharp / csharp-ls | C# | [github.com/OmniSharp/omnisharp-roslyn](https://github.com/OmniSharp/omnisharp-roslyn) |
| yaml-language-server | YAML | [github.com/redhat-developer/yaml-language-server](https://github.com/redhat-developer/yaml-language-server) |
| marksman | Markdown | [github.com/artempyanykh/marksman](https://github.com/artempyanykh/marksman) |
| taplo | TOML | [github.com/tamasfe/taplo](https://github.com/tamasfe/taplo) |
| lua-language-server | Lua | [github.com/LuaLS/lua-language-server](https://github.com/LuaLS/lua-language-server) |
| zls | Zig | [github.com/zigtools/zls](https://github.com/zigtools/zls) |
| bash-language-server | Bash | [github.com/bash-lsp/bash-language-server](https://github.com/bash-lsp/bash-language-server) |
| dockerfile-language-server | Dockerfile | [github.com/rcjsuen/dockerfile-language-server-nodejs](https://github.com/rcjsuen/dockerfile-language-server-nodejs) |
| vscode-langservers (CSS+HTML+JSON) | Web | [github.com/hrsh7th/vscode-langservers-extracted](https://github.com/hrsh7th/vscode-langservers-extracted) |

## Языки и менеджеры

| Инструмент | Документация |
|-----------|-------------|
| Java (Adoptium) | [adoptium.net](https://adoptium.net/) |
| SDKMAN | [sdkman.io](https://sdkman.io/) |
| n (Node.js) | [github.com/tj/n](https://github.com/tj/n) |
| uv (Python) | [docs.astral.sh/uv](https://docs.astral.sh/uv/) |
| Go | [go.dev/doc](https://go.dev/doc/) |
| rustup | [rustup.rs](https://rustup.rs/) |
| .NET | [dotnet.microsoft.com](https://dotnet.microsoft.com/) |

## Локальные LLM

| Инструмент | Документация | GitHub |
|-----------|-------------|--------|
| Ollama | [ollama.com](https://ollama.com/) | [github.com/ollama/ollama](https://github.com/ollama/ollama) |
| vLLM | [docs.vllm.ai](https://docs.vllm.ai/) | [github.com/vllm-project/vllm](https://github.com/vllm-project/vllm) |
| SGLang | [sglang.readthedocs.io](https://sglang.readthedocs.io/) | [github.com/sgl-project/sglang](https://github.com/sgl-project/sglang) |
| Open WebUI | [docs.openwebui.com](https://docs.openwebui.com/) | [github.com/open-webui/open-webui](https://github.com/open-webui/open-webui) |
| LlamaEdge | [wasmedge.org](https://wasmedge.org/) | [github.com/WasmEdge/WasmEdge](https://github.com/WasmEdge/WasmEdge) |
| GPUStack | [docs.gpustack.ai](https://docs.gpustack.ai/) | [github.com/gpustack/gpustack](https://github.com/gpustack/gpustack) |

## Векторные БД и память

| Инструмент | Документация |
|-----------|-------------|
| ChromaDB | [docs.trychroma.com](https://docs.trychroma.com/) |
| Qdrant | [qdrant.tech/documentation](https://qdrant.tech/documentation/) |
| Weaviate | [weaviate.io/developers](https://weaviate.io/developers) |
| Milvus | [milvus.io/docs](https://milvus.io/docs) |
| FAISS | [github.com/facebookresearch/faiss](https://github.com/facebookresearch/faiss) |
| Pinecone | [docs.pinecone.io](https://docs.pinecone.io/) |
| Muninn | [github.com/EliasOulkadi/muninn](https://github.com/EliasOulkadi/muninn) |
| RAGFlow | [ragflow.io/docs](https://ragflow.io/docs/) |

## Безопасность

| Инструмент | Документация |
|-----------|-------------|
| Trivy | [aquasecurity.github.io/trivy](https://aquasecurity.github.io/trivy/) |
| Qodana | [jetbrains.com/qodana](https://www.jetbrains.com/qodana/) |
| OWASP Top 10 | [owasp.org/Top10](https://owasp.org/Top10/) |

## CI/CD и автоматизация

| Инструмент | Документация |
|-----------|-------------|
| n8n | [docs.n8n.io](https://docs.n8n.io/) |
| GitHub Actions | [docs.github.com/actions](https://docs.github.com/actions) |
| GitLab CI | [docs.gitlab.com/ee/ci](https://docs.gitlab.com/ee/ci/) |

## Инструменты разработчика

| Инструмент | Документация |
|-----------|-------------|
| clawrouter | [npm: @blockrun/clawrouter](https://www.npmjs.com/package/@blockrun/clawrouter) |
| agents-md-sync | [npm: agents-md-sync](https://www.npmjs.com/package/agents-md-sync) |

## Экосистема навыков

| Ресурс | URL |
|--------|-----|
| Shokunin | [github.com/EliasOulkadi/shokunin](https://github.com/EliasOulkadi/shokunin) |
| Superpowers | [github.com/obra/superpowers](https://github.com/obra/superpowers) |
| Caveman | [github.com/anthonystepvoy/caveman-opencode](https://github.com/anthonystepvoy/caveman-opencode) |

## Проект

| Ресурс | URL |
|--------|-----|
| GitHub | [github.com/AlexanderNarbaev/opencode_initializer](https://github.com/AlexanderNarbaev/opencode_initializer) |
| GitVerse | [gitverse.ru/alexander.narbayev/opencode_initializer](https://gitverse.ru/alexander.narbayev/opencode_initializer) |
| GitHub Pages | [alexandernarbaev.github.io/opencode_initializer](https://alexandernarbaev.github.io/opencode_initializer/) |
