# Design: Full Ecosystem Expansion v36.0

**Date:** 2026-06-21 | **Status:** approved
**Based on:** 7-agent deep research (docs/research/2026-06-21-ecosystem-deep-research.md)

## Goal

Apply ALL research findings from the 7-agent deep ecosystem scan to opencode_initializer — fix critical npm security issues, add new MCPs/plugins, optimize providers/models, upgrade agent permissions, replace primitive skills, and unify memory systems.

## Scope

### In scope
- **CRITICAL**: Remove npm security canaries (mcp-server-git/fetch/time) from MCP_PACKAGES
- **New MCPs** (4): SQLite (uvx), Excalidraw (uvx), @upstash/context7-mcp, @notionhq/notion-mcp-server
- **Provider optimization**: DeepSeek direct API as primary, MiniMax M3 fallback, free Zen models as reserve
- **Agent permissions**: Bash command patterns, task routing, .env file protection
- **Skills upgrade**: Replace 3 primitive markdown checklists with full skills, add context-switching
- **WAL**: YAML structure replacing Markdown
- **Memory**: ChromaDB RAG collection, memory hooks in opencode.json
- **Plugins**: @upstash/context7-mcp, @notionhq/notion-mcp-server, @devtheops/opencode-plugin-otel
- **Version bump**: v35.4 → v36.0

### Out of scope
- OH-My-OpenAgent (too heavy, user-specific)
- ECC, cc-switch, claude-mem (external tools, not OpenCode plugins)
- n8n, Dify (platforms, not dev-machine tools)
- Desktop Commander, SearXNG, Kubernetes MCPs (need infrastructure)
- Sentry MCP (needs account)

## Architecture

### Files modified (15)

```
lib/00-core.sh         — MCP_PACKAGES cleanup, version v36.0
lib/12-mcp-lsp.sh      — New MCP installs, new plugins
lib/13-chromadb.sh     — Auth + RAG collection
lib/14-shokunin.sh     — Remove caveman
lib/17-project.sh      — YAML WAL, full skills, context-switching
lib/18-opencode-json.sh — Providers, permissions, MCPs, plugins
lib/19-finalize.sh     — Verification updates
modes/health.sh        — Health checks
lib/version-check.sh   — Package version checks
lib/pre-session-check.sh — MCP list
tests/unit/test_mcp_registry.sh
tests/integration/test_opencode_json_gen.sh
tests/e2e/test_critical_path.sh
```

### Data Flow
```
MCP_PACKAGES (00-core.sh) → MCP install (12-mcp-lsp.sh) → config gen (18-opencode-json.sh) → verify (19-finalize.sh)
Provider config → _build_providers() → opencode.json
Skills (17-project.sh) → .opencode/skills/
WAL (17-project.sh) → YAML state.yaml
Memory hooks (18-opencode-json.sh) → opencode.json hooks section
```

## Key Changes Detail

### 1. MCP_PACKAGES cleanup (00-core.sh)
- REMOVE: `[git]="mcp-server-git"` — npm security canary (use uvx only)
- REMOVE: `[fetch]="mcp-server-fetch"` — npm security canary (use uvx only)
- REMOVE: `[time]="mcp-server-time"` — npm canary + unpublished (use uvx only)
- ADD: `[sqlite]="mcp-server-sqlite"` — uvx, free
- ADD: `[excalidraw]="excalidraw-architect-mcp"` — uvx, free
- ADD: `[context7-official]="@upstash/context7-mcp"` — npm, official
- ADD: `[notion]="@notionhq/notion-mcp-server"` — npm, optional

### 2. New MCP installs (12-mcp-lsp.sh)
- SQLite: `uvx mcp-server-sqlite`
- Excalidraw: `uvx excalidraw-architect-mcp`
- Context7 official: `npm install -g @upstash/context7-mcp`
- Notion: `npm install -g @notionhq/notion-mcp-server`

### 3. Provider optimization (18-opencode-json.sh)
- Primary model: remain deepseek/deepseek-v4-pro (direct API, 4x cheaper than Zen)
- Small model: deepseek/deepseek-v4-flash
- Fallback chain: deepseek → minimax → xai → opencode
- Free Zen models as final reserve

### 4. Agent permissions (18-opencode-json.sh)
- Bash: `git *: allow, npm *: allow, grep *: allow, *: ask, rm *: deny`
- Read: `*.env: deny, *.env.*: deny, *: allow`
- Task routing: build→all agents, plan→researcher+explore, reviewer→none

### 5. Skills upgrade (17-project.sh)
- Replace code-review-checklist → full skill with security/perf/maintainability/correctness
- Replace deployment-checklist → full skill with pre/post deploy
- Replace testing-strategy → full skill with pyramid/property-based/snapshot
- Add context-switching skill (restore session state)
- Remove caveman dependency

### 6. WAL → YAML (17-project.sh)
- Replace GLOBAL_WAL.md markdown table → wal/state.yaml
- Auto-generate from MemoryLayer briefing at SessionEnd
- Structure: session, artifacts, protected, decisions, next

### 7. Memory (13-chromadb.sh + 18-opencode-json.sh)
- ChromaDB: token auth, RAG collection for codebase
- Memory hooks: SessionStart, PreCompact, PostToolUse, SessionEnd

## Verification
- `bash -n` on all .sh files
- `shellcheck` pass
- `tests/run_tests.sh` — all pass
- `bash setup.sh --dry-run` — no errors
- `bash setup.sh --health` — all checks pass

## Rollback
- Each change is idempotent via progress file
- MCP_PACKAGES removal is additive (new entries only, old keys removed)
- Provider changes preserve existing API keys
- Skills are generated only if not present
