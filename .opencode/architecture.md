# opencode_initializer Architecture
<!-- excalidraw-architect: knowledge-graph v1 -->
<!-- direction: LR -->

## Services
- setup-sh: setup.sh Orchestrator [type: bash] [domain: core] — Main entry point (284 lines), sources modules from lib/ and dispatches modes from modes/
- lib-modules: lib/ Modules (24) [type: bash] [domain: core] — 24 modular scripts: 00-core.sh through 20-autoupdate.sh (21 lib) + helpers.sh + version-check.sh + pre-session-check.sh (3 infra)
- dev-cli: dev.sh CLI [type: bash] [domain: core] — CLI: dev install|remove|update|health|list|config|version-check|autoupdate|self-update
- modes: modes/ Scripts (10) [type: bash] [domain: core] — 10 modes: 4 script files (health, fix-zshrc, upgrade, interactive) + 6 inline (full, reinit, new, update, fix-config, dry-run)
- mcp-servers: MCP Servers (21) [type: config] [domain: agents] — 21 MCP servers: filesystem, git, github, playwright, agent-browser, chrome-devtools, fetch, context7, sqlite, excalidraw, sequential-thinking, memory, agentic-tools, time, goal, google-maps, gitlab, postgres, chromadb, ollama, chrome-devtools-mcp
- agents: Agent Roles (16) [type: config] [domain: agents] — 16 specialized agent roles for multi-agent routing: brainstorm, plan, implement, review, debug, test, research, architect, devops, docs, security, data, frontend, backend, mobile, general
- tests: tests/ Suite [type: bash] [domain: quality] — Unit, integration, and e2e tests: test_critical_path.sh, test_mcp_registry.sh, test_opencode_json_gen.sh
- ci-cd: GitHub Actions CI [type: github-actions] [domain: quality] — ShellCheck + syntax + unit tests via .github/workflows/
- migrations: migrations/ [type: bash] [domain: core] — Timestamped, idempotent migrations auto-run by dev update
- opencode-json: opencode.json Config [type: json] [domain: config] — Multi-provider config: deepseek/deepseek-v4-pro, deepseek-v4-flash, opencode provider
- docs-site: docs/ Static Site [type: markdown] [domain: docs] — GitHub Pages documentation: README, FAQ, Troubleshooting, extended docs
- plans-dir: plans/ Internal Plans [type: markdown] [domain: internal] — Development plans and specs (not published to GitHub Pages)
- research-dir: research/ Internal Research [type: markdown] [domain: internal] — Deep research notes (not published to GitHub Pages)

## Dependencies
- setup-sh -> lib-modules : "sources"
- setup-sh -> modes : "dispatches"
- dev-cli -> migrations : "runs"
- ci-cd -> tests : "runs"
- lib-modules -> opencode-json : "generates"
- docs-site -> opencode-json : "references"
