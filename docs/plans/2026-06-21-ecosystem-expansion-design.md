# Design: Ecosystem Expansion v35.4

**Date:** 2026-06-21
**Status:** draft
**Target version:** v35.4

## Goal

Expand opencode_initializer to cover the full OpenCode ecosystem — new MCP servers, plugins, skills, agents, and config improvements — while maintaining code quality, idempotency, and test coverage.

## Scope

### In scope
- 6 new MCP servers: git, memory, fetch, time, redis, brave-search
- 18 new plugins: daytona, devcontainers, worktree, scheduler, background-agents, skillful, goal-plugin, conductor, workspace, shell-strategy, md-table-formatter, morph-fast-apply, zellij-namer, supermemory, dynamic-context-pruning, type-inject, websearch-cited, firecrawl
- 46 additional Superpowers skills (full clone)
- 3 custom project skills: code-review-checklist, deployment-checklist, testing-strategy
- 6 new agents: docs-writer, security-auditor, debugger, go-dev, rust-dev, ts-dev
- Agent permission system overhaul (new OpenCode permission model)
- Provider fallback chains
- Health/verification/test updates for all new components

### Out of scope
- External service integrations requiring user accounts: Slack, Wakatime, Sentry Monitor
- helicone-session, opencode-openai-codex-auth, opencode-gemini-auth, antigravity-auth (auth plugins requiring user accounts)
- oh-my-opencode (replaces built-in tools — too invasive)
- octto/micode (separate apps, not plugins)

## New Components

### MCP Servers

| Key | Package | Command | Type | Gating |
|-----|---------|---------|------|--------|
| git | mcp-server-git | `uvx mcp-server-git` | local (uvx) | uvx available |
| memory | @modelcontextprotocol/server-memory | npx/bun | local | always |
| fetch | @modelcontextprotocol/server-fetch | npx/bun | local | always |
| time | @modelcontextprotocol/server-time | npx/bun (uvx fallback) | local | always |
| redis | @modelcontextprotocol/server-redis | npx/bun | local | always |
| brave-search | @anthropic/mcp-server-brave-search | npx/bun | local | BRAVE_API_KEY present |

Git MCP uses `uvx` (Python package). Detect `uvx` availability; fallback to `pip install`.

### Plugins

**Infrastructure (4):**
- `opencode-daytona` — sandbox isolation
- `opencode-devcontainers` — multi-branch devcontainer
- `opencode-worktree` — git worktrees
- `opencode-scheduler` — recurring jobs via systemd

**AI Enhancement (5):**
- `opencode-background-agents` — async delegation
- `opencode-skillful` — lazy skill loading
- `opencode-goal-plugin` — session-scoped /goal
- `opencode-conductor` — context→spec→plan→implement
- `opencode-workspace` — multi-agent orchestration

**Quality of Life (4):**
- `opencode-shell-strategy` — non-interactive shell
- `opencode-md-table-formatter` — markdown tables
- `opencode-morph-fast-apply` — faster code editing
- `opencode-zellij-namer` — session naming

**Memory/Context (4):**
- `opencode-supermemory` — persistent memory
- `opencode-dynamic-context-pruning` — token optimization
- `opencode-type-inject` — TypeScript/Svelte types
- `opencode-websearch-cited` — web search with citations

**Utility (1):**
- `opencode-firecrawl` — web scraping

### Skills

Clone ALL Superpowers skills (not just 16) — full tree copy. Add 3 project skills:
- `code-review-checklist` — PR review checklist
- `deployment-checklist` — deploy verification
- `testing-strategy` — test approach selection

### Agents

| Agent | Model | Mode | Permissions |
|-------|-------|------|-------------|
| docs-writer | deepseek-v4-flash | subagent | edit:allow, bash:deny |
| security-auditor | deepseek-v4-pro | subagent | edit:deny, bash:deny |
| debugger | deepseek-v4-pro | subagent | edit:allow, bash:allow |
| go-dev | deepseek-v4-pro | subagent | edit:allow, bash:allow |
| rust-dev | deepseek-v4-pro | subagent | edit:allow, bash:allow |
| ts-dev | deepseek-v4-flash | subagent | edit:allow, bash:allow |

### Config Improvements

1. **Agent permissions** — use new `permission` field instead of legacy `tools`
2. **Agent modes** — explicit `primary`/`subagent` modes
3. **Task permissions** — control which agents can invoke which subagents
4. **Provider fallback** — `fallback_chain` in provider config
5. **Hidden agents** — mark internal agents as hidden

## Implementation Order (19 steps)

1. MCP Registry — add 6 new entries to `MCP_PACKAGES`
2. MCP Install — install logic for new MCPs (including uvx detection)
3. MCP Config — opencode.json generation for new MCPs
4. Plugins Install — add new npm packages
5. Plugins Config — conditional enablement in opencode.json
6. Superpowers Skills — full clone (not partial)
7. Custom Skills — project-specific skills
8. New Agents — 6 new agent files
9. Agent Permissions — new permission model in config
10. Provider Fallback — fallback chains
11. Config Overhaul — task permissions, hidden agents, modes
12. Verification — update checked components list
13. Health Checks — cover new MCPs, plugins, LSPs
14. Pre-session Check — update MCP list
15. Version Check — version tracking for new packages
16. Tests: MCP Registry — update expected lists
17. Tests: opencode.json — new assertions
18. ShellCheck — pass on all .sh files
19. Dry-run — full no-op test

## Affected Files

| File | Changes |
|------|---------|
| lib/00-core.sh | MCP_PACKAGES + new entries |
| lib/12-mcp-lsp.sh | Install logic for new MCPs + plugins |
| lib/14-shokunin.sh | Full superpowers clone |
| lib/17-project.sh | New agents + custom skills |
| lib/18-opencode-json.sh | MCP config, plugin config, permissions overhaul |
| lib/19-finalize.sh | Updated verification checks |
| modes/health.sh | New component health checks |
| lib/pre-session-check.sh | Updated MCP list |
| lib/version-check.sh | New package version checks |
| tests/unit/test_mcp_registry.sh | Updated expected counts |
| tests/integration/test_opencode_json_gen.sh | New assertions |
| setup.sh | Version bump to v35.4 |

## Rollback

- Individual steps are idempotent via progress file
- Each module has `_step_skip` / `_step_done` mechanism
- MCP packages use `|| true` to tolerate failures
- Config generation preserves existing user choices

## Verification

- `bash -n` syntax check on all .sh files
- `shellcheck` on all .sh files
- `tests/run_tests.sh` — full test suite
- `--dry-run` — no-op preview
- `--health` — 60+ diagnostics
