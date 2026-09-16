# opencode_initializer Architecture
<!-- excalidraw-architect: knowledge-graph v1 -->
<!-- direction: LR -->

## Services
- setup-sh: setup.sh Orchestrator [type: bash] [domain: core] — Main entry point (1179 lines), sources modules from lib/ and dispatches modes from modes/
- lib-modules: lib/ Modules (146) [type: bash] [domain: core] — 146 modular scripts: 00-core.sh through 119-ecosystem-integration.sh + helpers.sh + version-check.sh + pre-session-check.sh
- dev-cli: dev.sh CLI [type: bash] [domain: core] — CLI: dev install|remove|update|health|list|config|version-check|autoupdate|self-update|state|backup
- modes: modes/ Scripts (6) [type: bash] [domain: core] — 6 modes: health, ci, interactive, upgrade, fix-zshrc, new
- data-ssot: src/data/ SSOT Files [type: json] [domain: config] — 3 SSOT files: routing.json (model routing), providers.json (provider registry), mcp-profiles.json (MCP/LSP selection)
- mcp-servers: MCP Servers (24) [type: config] [domain: agents] — 24 MCP servers: filesystem, git, github, playwright, agent-browser, chrome-devtools, fetch, context7, sqlite, excalidraw, sequential-thinking, memory, agentic-tools, time, goal, google-maps, gitlab, postgres, chromadb, ollama, chrome-devtools-mcp, loopsense, codegraph, websearch
- agents: Agent Roles (16) [type: config] [domain: agents] — 16 specialized agent roles for multi-agent routing: brainstorm, plan, implement, review, debug, test, research, architect, devops, docs, security, data, frontend, backend, mobile, general
- tests: tests/ Suite [type: bash/python] [domain: quality] — 133 tests: 116 unit + 12 integration (Testcontainers) + 5 e2e + 1 doc-counts
- ci-cd: GitHub Actions CI [type: github-actions] [domain: quality] — ShellCheck + syntax + unit tests via .github/workflows/
- migrations: migrations/ [type: bash] [domain: core] — Timestamped, idempotent migrations auto-run by dev update
- opencode-json: opencode.json Config [type: json] [domain: config] — Multi-provider config with diff-before-write, DRY_RUN support, secret masking
- toml-config: setup.toml Config [type: toml] [domain: config] — Declarative config via TOML (precedence: CLI > env > toml > defaults)
- docs-site: docs/ Static Site [type: markdown] [domain: docs] — GitHub Pages documentation: README, FAQ, Troubleshooting, extended docs (EN/RU bilingual)
- plans-dir: plans/ Internal Plans [type: markdown] [domain: internal] — Development plans and specs (not published to GitHub Pages)
- research-dir: research/ Internal Research [type: markdown] [domain: internal] — Deep research notes (not published to GitHub Pages)
- cockpit: Cockpit TUI [type: go] [domain: ui] — Go/BubbleTea TUI with 8 tabs for monitoring and management
- gui: Web GUI [type: node] [domain: ui] — Node.js dashboard on port 4200 for provider status, model management, infra monitoring
- grafana: Grafana Dashboards [type: grafana] [domain: observability] — Pre-configured dashboards for OpenCode metrics, system metrics, provider health
- systemd: Systemd Services [type: systemd] [domain: ops] — 6 services: opencode-update, opencode-gui, opencode-metrics, opencode-infra, opencode-embed-proxy

## Dependencies
- setup-sh -> lib-modules : "sources"
- setup-sh -> modes : "dispatches"
- setup-sh -> toml-config : "loads (via --config)"
- dev-cli -> migrations : "runs"
- ci-cd -> tests : "runs"
- lib-modules -> opencode-json : "generates (diff-before-write)"
- lib-modules -> data-ssot : "reads (routing, providers, mcp-profiles)"
- docs-site -> opencode-json : "references"
- grafana -> systemd : "provisioned by"
- gui -> systemd : "managed by"
- cockpit -> systemd : "managed by"

## Key Patterns
- **Source-and-Gate:** Modules 41-51 are sourced with existence guards but not step-executed
- **Files as IPC:** Inter-agent communication through files (.opencode/state/)
- **SSOT Data Files:** routing.json, providers.json, mcp-profiles.json are single sources of truth
- **Diff-Before-Write:** opencode.json generator computes SHA-256, skips write if unchanged
- **WAL Atomic Writes:** _wal_checkpoint uses _wal_locked_append (flock + mkdir fallback)
- **Per-Step Fault Tolerance:** _run_step wraps modules in subshell with set +e, marks PARTIAL on failure
- **TOML Config Precedence:** CLI > env > toml > defaults
- **Port Conflict Detection:** Pre-flight checks before docker compose up, auto-shifts colliding ports
