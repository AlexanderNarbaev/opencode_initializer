# Ecosystem Expansion v35.4 — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Expand opencode_initializer to full OpenCode ecosystem coverage — 6 new MCPs, 18 plugins, full Superpowers skills, 6 new agents, agent permission overhaul, provider fallback chains.

**Architecture:** Incremental changes to 12 files: MCP registry → install logic → config generation → skills → agents → verifications → tests. Each task is independently testable and idempotent.

**Tech Stack:** Bash (setup orchestration), Python (opencode.json generation), npm/bun (package installs), uvx/pipx (Python MCPs)

## Global Constraints

- `SCRIPT_VERSION` bump from `v35.3` to `v35.4` in `lib/00-core.sh:7`
- All new MCPs use `|| true` to tolerate failures (set +e block)
- All new plugins use `2>/dev/null && log ... || warn ...` pattern
- Config generation preserves existing user choices
- ShellCheck must pass on all modified .sh files
- Test assertions must be updated to reflect new component counts
- No secrets in code — all API keys via `secrets.env` detection

---

### Task 1: Bump Version + MCP Registry

**Files:**
- Modify: `lib/00-core.sh:7,168-184`

**Interfaces:**
- Produces: `MCP_PACKAGES` array with 20 entries (14 existing + 6 new)

- [ ] **Step 1: Bump SCRIPT_VERSION**

```bash
# Edit lib/00-core.sh line 7:
# OLD: SCRIPT_VERSION="${SCRIPT_VERSION:-v35.3}"
# NEW: SCRIPT_VERSION="${SCRIPT_VERSION:-v35.4}"
```

Use Edit tool: `lib/00-core.sh:7`, change `v35.3` to `v35.4`.

- [ ] **Step 2: Add 6 new MCP entries to MCP_PACKAGES**

In `lib/00-core.sh`, add to the `declare -A MCP_PACKAGES` array (before the closing `)`):

```bash
  [git]="mcp-server-git"
  [memory]="@modelcontextprotocol/server-memory"
  [fetch]="@modelcontextprotocol/server-fetch"
  [time]="@modelcontextprotocol/server-time"
  [redis]="@modelcontextprotocol/server-redis"
  [brave-search]="@anthropic/mcp-server-brave-search"
```

Use Edit tool: insert after line 183 (`[chrome-devtools]="chrome-devtools-mcp"`), before line 184 (`)`).

- [ ] **Step 3: Verify syntax and count**

Run: `bash -n lib/00-core.sh`
Expected: no output (syntax OK)

Run: `grep -c '\]=' lib/00-core.sh`
Expected: `20` (14 old + 6 new)

- [ ] **Step 4: Commit**

```bash
git add lib/00-core.sh
git commit -m "feat: bump v35.4 + add 6 MCPs to registry (git,memory,fetch,time,redis,brave-search)"
```

---

### Task 2: MCP Install Logic

**Files:**
- Modify: `lib/12-mcp-lsp.sh:10-16`

**Interfaces:**
- Consumes: `MCP_PACKAGES` array from Task 1
- Produces: All MCP packages installed (tolerate failures)

- [ ] **Step 1: Add git MCP (Python/uvx) install logic**

After the `done` line of the `for name` loop (line 15), add before `# Muninn via pipx` (line 16):

```bash
  # Git MCP (Python, via uvx or pip)
  if command -v uvx &>/dev/null; then
    uvx mcp-server-git --version 2>/dev/null && log "MCP git (uvx)" || warn "MCP git: uvx install failed"
  elif command -v pip &>/dev/null; then
    pip install --user mcp-server-git 2>/dev/null && log "MCP git (pip)" || warn "MCP git: pip install failed"
  fi
```

- [ ] **Step 2: Verify bash syntax**

Run: `bash -n lib/12-mcp-lsp.sh`
Expected: no output

- [ ] **Step 3: Commit**

```bash
git add lib/12-mcp-lsp.sh
git commit -m "feat: add git MCP install (uvx/pip fallback)"
```

---

### Task 3: MCP Config in opencode.json

**Files:**
- Modify: `lib/18-opencode-json.sh:97-168`

**Interfaces:**
- Consumes: MCP registry entries from Task 1
- Produces: opencode.json with 20 MCP entries

- [ ] **Step 1: Add git MCP detection**

After line 101 (context7 mcps entry), add:

```python
# Git MCP (via uvx or pip)
if cmd_exists("mcp-server-git"):
    mcps["git"] = {"type": "local", "command": ["uvx", "mcp-server-git"], "enabled": True}
```

- [ ] **Step 2: Add memory MCP detection**

After the git entry, add:

```python
if pkg_installed("@modelcontextprotocol/server-memory"):
    mcps["memory"] = {"type": "local", "command": local_cmd("@modelcontextprotocol/server-memory", "mcp-server-memory"), "enabled": True}
```

- [ ] **Step 3: Add fetch MCP detection**

```python
if pkg_installed("@modelcontextprotocol/server-fetch"):
    mcps["fetch"] = {"type": "local", "command": local_cmd("@modelcontextprotocol/server-fetch", "mcp-server-fetch"), "enabled": True}
```

- [ ] **Step 4: Add time MCP detection**

```python
# Time MCP (Python package via uvx preferred, npx fallback)
if cmd_exists("mcp-server-time"):
    mcps["time"] = {"type": "local", "command": ["uvx", "mcp-server-time"], "enabled": True}
elif pkg_installed("@modelcontextprotocol/server-time"):
    mcps["time"] = {"type": "local", "command": local_cmd("@modelcontextprotocol/server-time", "mcp-server-time"), "enabled": True}
```

- [ ] **Step 5: Add redis MCP detection**

```python
if pkg_installed("@modelcontextprotocol/server-redis"):
    mcps["redis"] = {"type": "local", "command": local_cmd("@modelcontextprotocol/server-redis", "mcp-server-redis"), "enabled": True}
```

- [ ] **Step 6: Add brave-search MCP detection**

After line 164 (chrome-devtools entry), add:

```python
if pkg_installed("@anthropic/mcp-server-brave-search"):
    bs_key = os.environ.get("BRAVE_API_KEY") or secrets.get("BRAVE_API_KEY", "")
    bs_entry = {"type": "local", "command": local_cmd("@anthropic/mcp-server-brave-search", "mcp-server-brave-search")}
    if bs_key:
        bs_entry["enabled"] = True
        bs_entry["env"] = {"BRAVE_API_KEY": bs_key}
    else:
        bs_entry["enabled"] = False
    mcps["brave-search"] = bs_entry
```

- [ ] **Step 7: Verify Python syntax**

Run: `python3 -c "$(sed -n '/python3 << .PYGEN./,/PYGEN/p' lib/18-opencode-json.sh | grep -v 'python3\|PYGEN')" 2>&1`
Expected: no Python syntax errors

- [ ] **Step 8: Commit**

```bash
git add lib/18-opencode-json.sh
git commit -m "feat: add 6 new MCP configs to opencode.json generator"
```

---

### Task 4: Plugins Install

**Files:**
- Modify: `lib/12-mcp-lsp.sh:68-72`

**Interfaces:**
- Produces: 18 new npm global packages installed (tolerate failures)

- [ ] **Step 1: Add infrastructure plugins install**

After line 72 (`agents-md-sync`), append:

```bash
  # Infrastructure plugins
  npm install -g opencode-daytona@latest 2>/dev/null && log "Plugin: daytona" || { warn "Plugin FAILED: daytona"; true; }
  npm install -g opencode-devcontainers@latest 2>/dev/null && log "Plugin: devcontainers" || { warn "Plugin FAILED: devcontainers"; true; }
  npm install -g opencode-worktree@latest 2>/dev/null && log "Plugin: worktree" || { warn "Plugin FAILED: worktree"; true; }
  npm install -g opencode-scheduler@latest 2>/dev/null && log "Plugin: scheduler" || { warn "Plugin FAILED: scheduler"; true; }

  # AI-enhancement plugins
  npm install -g opencode-background-agents@latest 2>/dev/null && log "Plugin: background-agents" || { warn "Plugin FAILED: background-agents"; true; }
  npm install -g opencode-skillful@latest 2>/dev/null && log "Plugin: skillful" || { warn "Plugin FAILED: skillful"; true; }
  npm install -g opencode-goal-plugin@latest 2>/dev/null && log "Plugin: goal-plugin" || { warn "Plugin FAILED: goal-plugin"; true; }
  npm install -g opencode-conductor@latest 2>/dev/null && log "Plugin: conductor" || { warn "Plugin FAILED: conductor"; true; }
  npm install -g opencode-workspace@latest 2>/dev/null && log "Plugin: workspace" || { warn "Plugin FAILED: workspace"; true; }

  # QoL plugins
  npm install -g opencode-shell-strategy@latest 2>/dev/null && log "Plugin: shell-strategy" || { warn "Plugin FAILED: shell-strategy"; true; }
  npm install -g opencode-md-table-formatter@latest 2>/dev/null && log "Plugin: md-table-formatter" || { warn "Plugin FAILED: md-table-formatter"; true; }
  npm install -g opencode-morph-fast-apply@latest 2>/dev/null && log "Plugin: morph-fast-apply" || { warn "Plugin FAILED: morph-fast-apply"; true; }
  npm install -g opencode-zellij-namer@latest 2>/dev/null && log "Plugin: zellij-namer" || { warn "Plugin FAILED: zellij-namer"; true; }

  # Memory/context plugins
  npm install -g opencode-supermemory@latest 2>/dev/null && log "Plugin: supermemory" || { warn "Plugin FAILED: supermemory"; true; }
  npm install -g opencode-dynamic-context-pruning@latest 2>/dev/null && log "Plugin: dynamic-context-pruning" || { warn "Plugin FAILED: dynamic-context-pruning"; true; }
  npm install -g opencode-type-inject@latest 2>/dev/null && log "Plugin: type-inject" || { warn "Plugin FAILED: type-inject"; true; }
  npm install -g opencode-websearch-cited@latest 2>/dev/null && log "Plugin: websearch-cited" || { warn "Plugin FAILED: websearch-cited"; true; }

  # Utility
  npm install -g opencode-firecrawl@latest 2>/dev/null && log "Plugin: firecrawl" || { warn "Plugin FAILED: firecrawl"; true; }
```

- [ ] **Step 2: Verify bash syntax**

Run: `bash -n lib/12-mcp-lsp.sh`
Expected: no output

- [ ] **Step 3: Commit**

```bash
git add lib/12-mcp-lsp.sh
git commit -m "feat: add 18 new plugins install (infra, AI, QoL, memory, utility)"
```

---

### Task 5: Plugins Config in opencode.json

**Files:**
- Modify: `lib/18-opencode-json.sh:194-240`

**Interfaces:**
- Consumes: installed plugin packages from Task 4
- Produces: opencode.json plugin array with conditional entries

- [ ] **Step 1: Add conditional plugin entries**

In the plugins section of the Python block, after `if pkg_installed("opencode-vibeguard"): plugins.append("opencode-vibeguard")` (line 240), add before the `# Build config` comment:

```python
# Infrastructure plugins
if pkg_installed("opencode-daytona"):
    plugins.append("opencode-daytona")
if pkg_installed("opencode-devcontainers"):
    plugins.append("opencode-devcontainers")
if pkg_installed("opencode-worktree"):
    plugins.append("opencode-worktree")
if pkg_installed("opencode-scheduler"):
    plugins.append("opencode-scheduler")

# AI-enhancement plugins
if pkg_installed("opencode-background-agents"):
    plugins.append("opencode-background-agents")
if pkg_installed("opencode-skillful"):
    plugins.append("opencode-skillful")
if pkg_installed("opencode-goal-plugin"):
    plugins.append("opencode-goal-plugin")
if pkg_installed("opencode-conductor"):
    plugins.append("opencode-conductor")
if pkg_installed("opencode-workspace"):
    plugins.append("opencode-workspace")

# QoL plugins
if pkg_installed("opencode-shell-strategy"):
    plugins.append("opencode-shell-strategy")
if pkg_installed("opencode-md-table-formatter"):
    plugins.append("opencode-md-table-formatter")
if pkg_installed("opencode-morph-fast-apply"):
    plugins.append("opencode-morph-fast-apply")
if pkg_installed("opencode-zellij-namer"):
    plugins.append("opencode-zellij-namer")

# Memory/context plugins
if pkg_installed("opencode-supermemory"):
    plugins.append("opencode-supermemory")
if pkg_installed("opencode-dynamic-context-pruning"):
    plugins.append("opencode-dynamic-context-pruning")
if pkg_installed("opencode-type-inject"):
    plugins.append("opencode-type-inject")
if pkg_installed("opencode-websearch-cited"):
    plugins.append("opencode-websearch-cited")

# Utility
if pkg_installed("opencode-firecrawl"):
    plugins.append("opencode-firecrawl")
```

- [ ] **Step 2: Verify Python syntax**

Run: `python3 -c "$(sed -n '/python3 << .PYGEN./,/PYGEN/p' lib/18-opencode-json.sh | grep -v 'python3\|PYGEN')" 2>&1`
Expected: no Python syntax errors

- [ ] **Step 3: Commit**

```bash
git add lib/18-opencode-json.sh
git commit -m "feat: add 18 plugin entries to opencode.json generator"
```

---

### Task 6: Full Superpowers Skills Clone

**Files:**
- Modify: `lib/14-shokunin.sh:19-21`

**Interfaces:**
- Produces: Full Superpowers skills tree in `~/.config/opencode/skills/superpowers/`

- [ ] **Step 1: Remove partial copy, do full clone**

Change lines 19-21 from:

```bash
  [ -d "$SUPERPOWERS_TMP/skills" ] && cp -r "$SUPERPOWERS_TMP/skills" "$HOME/.config/opencode/skills/superpowers" 2>/dev/null || true
  rm -rf "$SUPERPOWERS_TMP"
```

To:

```bash
  if [ -d "$SUPERPOWERS_TMP/skills" ]; then
    rm -rf "$HOME/.config/opencode/skills/superpowers/skills" 2>/dev/null || true
    cp -r "$SUPERPOWERS_TMP/skills"/* "$HOME/.config/opencode/skills/superpowers/skills/" 2>/dev/null && log "Superpowers: $(ls "$HOME/.config/opencode/skills/superpowers/skills" 2>/dev/null | wc -l) skills loaded" || warn "Superpowers copy failed"
  fi
  rm -rf "$SUPERPOWERS_TMP"
```

Note: Keep existing directory structure at `~/.config/opencode/skills/superpowers/skills/` and copy the full tree from the clone.

- [ ] **Step 2: Fix — ensure directory exists before copy**

The mkdir on line 17 creates `$HOME/.config/opencode/skills/superpowers`. But skills go into `skills/superpowers/skills/`. Adjust the copy to:

```bash
  if [ -d "$SUPERPOWERS_TMP/skills" ]; then
    mkdir -p "$HOME/.config/opencode/skills/superpowers/skills"
    cp -r "$SUPERPOWERS_TMP/skills"/* "$HOME/.config/opencode/skills/superpowers/skills/" 2>/dev/null && \
      log "Superpowers: $(ls "$HOME/.config/opencode/skills/superpowers/skills" 2>/dev/null | wc -l) skills loaded" || \
      warn "Superpowers copy failed"
  fi
  rm -rf "$SUPERPOWERS_TMP"
```

- [ ] **Step 3: Verify bash syntax**

Run: `bash -n lib/14-shokunin.sh`
Expected: no output

- [ ] **Step 4: Commit**

```bash
git add lib/14-shokunin.sh
git commit -m "feat: full superpowers skills clone (all 62+)"
```

---

### Task 7: Custom Project Skills

**Files:**
- Modify: `lib/17-project.sh:14` (project directory structure)
- Create: skills content inline

**Interfaces:**
- Produces: 3 custom skill files in project `.opencode/skills/`

- [ ] **Step 1: Create skills directory in project structure**

Change line 14 from:

```bash
    mkdir -p "$PROJECT_DIR"/{docs,wal,.lock,.opencode/{agents,skills,commands,context},infra,icon,templates,output}
```

To add skills subdirectories:

```bash
    mkdir -p "$PROJECT_DIR"/{docs,wal,.lock,.opencode/{agents,skills/{code-review-checklist,deployment-checklist,testing-strategy},commands,context},infra,icon,templates,output}
```

- [ ] **Step 2: Add skill file generation after AGENTS.md block**

After the AGENTS.md creation block (line 239), add:

```bash
  # Custom project skills
  if [ ! -f "$PROJECT_DIR/.opencode/skills/code-review-checklist/SKILL.md" ]; then
    cat > "$PROJECT_DIR/.opencode/skills/code-review-checklist/SKILL.md" << 'SKILLEOF'
---
name: code-review-checklist
description: Standard code review checklist — covers security, performance, maintainability, and correctness
---
# Code Review Checklist

## Security
- [ ] No secrets or API keys in code
- [ ] Input validation on all user-facing endpoints
- [ ] SQL injection prevention (parameterized queries)
- [ ] XSS prevention (output encoding)
- [ ] CSRF protection on state-changing operations
- [ ] Authentication/authorization on sensitive endpoints

## Performance
- [ ] No N+1 queries
- [ ] Database indexes for common queries
- [ ] Caching strategy for expensive operations
- [ ] Pagination on list endpoints
- [ ] No unnecessary data fetching

## Maintainability
- [ ] Clear function/variable names
- [ ] No magic numbers — use constants
- [ ] Error handling with meaningful messages
- [ ] No commented-out code
- [ ] Test coverage for new code

## Correctness
- [ ] Edge cases handled (null, empty, boundary)
- [ ] Idempotent operations where needed
- [ ] Rollback on failure for multi-step operations
- [ ] Type safety (no `any` in TypeScript)
SKILLEOF
    log "Skill: code-review-checklist"
  fi

  if [ ! -f "$PROJECT_DIR/.opencode/skills/deployment-checklist/SKILL.md" ]; then
    cat > "$PROJECT_DIR/.opencode/skills/deployment-checklist/SKILL.md" << 'SKILLEOF'
---
name: deployment-checklist
description: Pre-deployment and post-deployment verification checklist
---
# Deployment Checklist

## Pre-Deployment
- [ ] All tests pass (`pytest` / `cargo test` / `go test`)
- [ ] Linter passes with no errors
- [ ] Type checker passes
- [ ] Build succeeds
- [ ] Database migrations tested on staging
- [ ] Environment variables documented
- [ ] Breaking changes documented in CHANGELOG
- [ ] Rollback plan defined

## Post-Deployment
- [ ] Health check endpoint responds
- [ ] Smoke tests pass on production
- [ ] Logs show normal traffic
- [ ] Metrics/alerting active
- [ ] Database migration completed successfully
SKILLEOF
    log "Skill: deployment-checklist"
  fi

  if [ ! -f "$PROJECT_DIR/.opencode/skills/testing-strategy/SKILL.md" ]; then
    cat > "$PROJECT_DIR/.opencode/skills/testing-strategy/SKILL.md" << 'SKILLEOF'
---
name: testing-strategy
description: Test approach selection guide — unit, integration, e2e, property-based
---
# Testing Strategy

## Test Pyramid
1. **Unit tests** — individual functions/classes, fast, isolated
2. **Integration tests** — component interactions, database, APIs
3. **E2E tests** — full user flows, browser automation

## When to use each
- **Unit**: pure logic, parsing, validation, algorithms
- **Integration**: database queries, API handlers, message queues
- **E2E**: critical user journeys, auth flows, payment flows
- **Property-based**: complex data transformations, serialization
- **Snapshot**: UI components, API responses that rarely change

## Coverage targets
- Backend: ≥ 80% line coverage
- Frontend: ≥ 70% line coverage
- Critical paths: 100% branch coverage
SKILLEOF
    log "Skill: testing-strategy"
  fi
```

- [ ] **Step 3: Verify bash syntax**

Run: `bash -n lib/17-project.sh`
Expected: no output

- [ ] **Step 4: Commit**

```bash
git add lib/17-project.sh
git commit -m "feat: add 3 custom project skills (code-review, deployment, testing)"
```

---

### Task 8: New Agents

**Files:**
- Modify: `lib/17-project.sh:243-270`

**Interfaces:**
- Consumes: existing ROLE_MODELS array
- Produces: 16 agent files (10 existing + 6 new)

- [ ] **Step 1: Add new agents to ROLE_MODELS**

Change lines 242-249, add 6 new roles after the existing 10:

```bash
  declare -A ROLE_MODELS=(
    [pm]="opencode-go/glm-5.1" [analyst]="opencode-go/glm-5.1" [architect]="opencode-go/glm-5.1"
    [developer]="deepseek/deepseek-v4-pro" [qa]="opencode-go/minimax-m2.7"
    [security]="opencode-go/glm-5" [devops]="deepseek/deepseek-v4-pro"
    [reviewer]="opencode-go/qwen3.6-plus" [researcher]="deepseek/deepseek-v4-pro"
    [designer]="opencode-go/minimax-m2.7"
    [docs-writer]="deepseek/deepseek-v4-flash" [security-auditor]="deepseek/deepseek-v4-pro"
    [debugger]="deepseek/deepseek-v4-pro" [go-dev]="deepseek/deepseek-v4-pro"
    [rust-dev]="deepseek/deepseek-v4-pro" [ts-dev]="deepseek/deepseek-v4-flash"
  )
```

- [ ] **Step 2: Add permission mappings for new agents**

Change the permissions case block (lines 251-257), add entries for new roles:

```bash
    case $role in
      pm|analyst|architect)         perm="edit: allow\n  bash: deny\n  read: allow\n  glob: allow\n  grep: allow\n  write: allow" ;;
      developer)                    perm="edit: allow\n  bash: allow\n  read: allow\n  glob: allow\n  grep: allow\n  write: allow" ;;
      reviewer|researcher|designer) perm="edit: deny\n  bash: deny\n  read: allow\n  glob: allow\n  grep: allow\n  write: deny" ;;
      qa|devops)                    perm="edit: allow\n  bash: allow\n  read: allow\n  glob: allow\n  grep: allow\n  write: allow" ;;
      security)                     perm="edit: deny\n  bash: deny\n  read: allow\n  glob: allow\n  grep: allow\n  write: deny" ;;
      docs-writer)                  perm="edit: allow\n  bash: deny\n  read: allow\n  glob: allow\n  grep: allow\n  write: allow" ;;
      security-auditor)             perm="edit: deny\n  bash: deny\n  read: allow\n  glob: allow\n  grep: allow\n  write: deny" ;;
      debugger)                     perm="edit: allow\n  bash: allow\n  read: allow\n  glob: allow\n  grep: allow\n  write: allow" ;;
      go-dev|rust-dev|ts-dev)       perm="edit: allow\n  bash: allow\n  read: allow\n  glob: allow\n  grep: allow\n  write: allow" ;;
    esac
```

- [ ] **Step 3: Verify bash syntax**

Run: `bash -n lib/17-project.sh`
Expected: no output

- [ ] **Step 4: Convert to new permission format**

Replace the `permission:` YAML section in the agent file template (line 266) — change from old `permission:` with `$(echo -e "$perm")` to new format with `mode` field:

```bash
    cat > "$PROJECT_DIR/.opencode/agents/${role}.md" << ROLEEOF
---
description: "${role} specialist"
model: ${ROLE_MODELS[$role]}
mode: subagent
temperature: 0.2
permission:
  $(echo -e "$perm")
---
# ${role} Agent
Ты — **${role}**. Следуй протоколу: изучи документы, предложи план, дождись подтверждения, выполни задачу, обнови WAL.
ROLEEOF
```

- [ ] **Step 5: Commit**

```bash
git add lib/17-project.sh
git commit -m "feat: add 6 new agents + mode field to all agent configs"
```

---

### Task 9: Agent Permission System Overhaul

**Files:**
- Modify: `lib/18-opencode-json.sh:243-270`

**Interfaces:**
- Produces: opencode.json with new `agent` section containing permission overrides

- [ ] **Step 1: Add agent permission config to Python block**

After the `"mcp": mcps` line (line 269), add `"agent"` config before the closing `}`:

```python
    "agent": {
        "build": {
            "mode": "primary",
            "model": "deepseek/deepseek-v4-pro",
            "temperature": 0.2,
            "permission": {
                "edit": "allow",
                "bash": "allow",
                "read": "allow",
                "glob": "allow",
                "grep": "allow",
                "write": "allow"
            }
        },
        "plan": {
            "mode": "primary",
            "model": "deepseek/deepseek-v4-pro",
            "temperature": 0.1,
            "permission": {
                "edit": "ask",
                "bash": "ask",
                "read": "allow",
                "glob": "allow",
                "grep": "allow",
                "write": "ask"
            }
        },
        "general": {
            "mode": "subagent",
            "model": "deepseek/deepseek-v4-pro",
            "temperature": 0.2
        },
        "explore": {
            "mode": "subagent",
            "model": "deepseek/deepseek-v4-flash",
            "temperature": 0.1,
            "permission": {
                "edit": "deny",
                "bash": "deny",
                "write": "deny"
            }
        }
    },
```

- [ ] **Step 2: Verify Python produces valid JSON**

Run: `python3 -c "$(sed -n '/python3 << .PYGEN./,/PYGEN/p' lib/18-opencode-json.sh | grep -v 'python3\|PYGEN')" 2>&1`
Expected: no Python syntax errors

- [ ] **Step 3: Commit**

```bash
git add lib/18-opencode-json.sh
git commit -m "feat: agent permission system overhaul with modes"
```

---

### Task 10: Provider Fallback Chains

**Files:**
- Modify: `lib/18-opencode-json.sh:65-83`

**Interfaces:**
- Produces: Provider config with `fallback` chains

- [ ] **Step 1: Enhance _build_providers() with fallback**

Replace the `_build_providers()` function (lines 65-83) with:

```python
def _build_providers():
    """Build provider config based on available API keys, with fallback chains."""
    opts = {"options": {"timeout": 600000, "chunkTimeout": 60000, "setCacheKey": True}}
    providers = {}

    # DeepSeek — always primary
    providers["deepseek"] = dict(opts)
    providers["deepseek"]["fallback"] = ["opencode", "xai", "minimax"]

    # OpenCode — always available as backup
    providers["opencode"] = dict(opts)
    providers["opencode"]["fallback"] = ["deepseek", "minimax"]

    # xAI/Grok — conditional
    xai_key = os.environ.get("XAI_API_KEY") or secrets.get("XAI_API_KEY", "")
    if xai_key:
        providers["xai"] = dict(opts)
        providers["xai"]["fallback"] = ["deepseek"]

    # MiMo — conditional
    mimo_key = os.environ.get("MIMO_API_KEY") or secrets.get("MIMO_API_KEY", "")
    if mimo_key:
        providers["mimo"] = dict(opts)
        providers["mimo"]["fallback"] = ["deepseek"]

    # Moonshot — conditional
    moonshot_key = os.environ.get("MOONSHOT_API_KEY") or secrets.get("MOONSHOT_API_KEY", "")
    if moonshot_key:
        providers["moonshot"] = dict(opts)
        providers["moonshot"]["fallback"] = ["deepseek"]

    # MiniMax — conditional
    minimax_key = os.environ.get("MINIMAX_API_KEY") or secrets.get("MINIMAX_API_KEY", "")
    if minimax_key:
        providers["minimax"] = dict(opts)
        providers["minimax"]["fallback"] = ["deepseek"]

    return providers
```

- [ ] **Step 2: Verify Python syntax**

Run: `python3 -c "$(sed -n '/python3 << .PYGEN./,/PYGEN/p' lib/18-opencode-json.sh | grep -v 'python3\|PYGEN')" 2>&1`
Expected: no Python syntax errors

- [ ] **Step 3: Commit**

```bash
git add lib/18-opencode-json.sh
git commit -m "feat: provider fallback chains (deepseek→opencode→xai→minimax)"
```

---

### Task 11: Config Overhaul — Task Permissions + Hidden Agents

**Files:**
- Modify: `lib/18-opencode-json.sh:243-270`

**Interfaces:**
- Produces: opencode.json with task permissions and hidden agent configs

- [ ] **Step 1: Add task permissions to build agent**

Within the `"agent"` config added in Task 9, add `task` permission to build agent:

In the build agent block, add after the standard permissions:

```python
            "task": {
                "general": "allow",
                "explore": "allow",
                "scout": "allow",
                "reviewer": "allow",
                "security-auditor": "allow"
            }
```

- [ ] **Step 2: Add hidden compaction agent config**

```python
        "compaction": {
            "mode": "primary",
            "hidden": True,
            "model": "deepseek/deepseek-v4-flash",
            "temperature": 0.1
        },
```

- [ ] **Step 3: Update permissions key list in config validation**

Add `"agent"` to the config structure assertion — ensure `agent` is listed among the top-level keys. Modify the config dict to use `"agent":` instead of adding it as a separate key check.

- [ ] **Step 4: Commit**

```bash
git add lib/18-opencode-json.sh
git commit -m "feat: task permissions + hidden agents config"
```

---

### Task 12: Verification Updates

**Files:**
- Modify: `lib/19-finalize.sh:133-177`

**Interfaces:**
- Produces: Updated verification with all new components

- [ ] **Step 1: Add MCP verification for new servers**

After line 172 (chrome-devtools check), add:

```bash
  _check "MCP git"              "which mcp-server-git 2>/dev/null || uvx mcp-server-git --version &>/dev/null"
  _check "MCP memory"           "npm list -g @modelcontextprotocol/server-memory &>/dev/null"
  _check "MCP fetch"            "npm list -g @modelcontextprotocol/server-fetch &>/dev/null"
  _check "MCP time"             "which mcp-server-time 2>/dev/null || npm list -g @modelcontextprotocol/server-time &>/dev/null"
  _check "MCP redis"            "npm list -g @modelcontextprotocol/server-redis &>/dev/null"
  _check "MCP brave-search"     "npm list -g @anthropic/mcp-server-brave-search &>/dev/null"
```

- [ ] **Step 2: Add plugin verification**

After the new MCP checks, add:

```bash
  _check "Plugin daytona"          "npm list -g opencode-daytona &>/dev/null"
  _check "Plugin background-agents" "npm list -g opencode-background-agents &>/dev/null"
  _check "Plugin scheduler"         "npm list -g opencode-scheduler &>/dev/null"
  _check "Plugin shell-strategy"    "npm list -g opencode-shell-strategy &>/dev/null"
  _check "Plugin worktree"          "npm list -g opencode-worktree &>/dev/null"
  _check "Plugin firecrawl"         "npm list -g opencode-firecrawl &>/dev/null"
```

- [ ] **Step 3: Add skills verification**

After the Muninn skills check (line 175):

```bash
  _check "Skills code-review"      "[ -f \"$PROJECT_DIR/.opencode/skills/code-review-checklist/SKILL.md\" ]"
  _check "Skills deployment"       "[ -f \"$PROJECT_DIR/.opencode/skills/deployment-checklist/SKILL.md\" ]"
  _check "Skills testing-strategy" "[ -f \"$PROJECT_DIR/.opencode/skills/testing-strategy/SKILL.md\" ]"
```

- [ ] **Step 4: Verify bash syntax**

Run: `bash -n lib/19-finalize.sh`
Expected: no output

- [ ] **Step 5: Commit**

```bash
git add lib/19-finalize.sh
git commit -m "feat: updated verification with new MCPs, plugins, skills"
```

---

### Task 13: Health Checks Updates

**Files:**
- Modify: `modes/health.sh:43-64`

**Interfaces:**
- Produces: Health checks covering all new MCPs and plugins

- [ ] **Step 1: Add new MCP health checks**

After line 56 (chrome-devtools check), add:

```bash
_check "git-mcp"         "_mcp_ok mcp-server-git mcp-server-git"
_check "memory-mcp"      "_mcp_ok mcp-server-memory @modelcontextprotocol/server-memory"
_check "fetch-mcp"       "_mcp_ok mcp-server-fetch @modelcontextprotocol/server-fetch"
_check "time-mcp"        "_mcp_ok mcp-server-time @modelcontextprotocol/server-time"
_check "redis-mcp"       "_mcp_ok mcp-server-redis @modelcontextprotocol/server-redis"
_check "brave-search"    "_mcp_ok mcp-server-brave-search @anthropic/mcp-server-brave-search"
```

- [ ] **Step 2: Add new plugin health checks**

After line 64 (plugin-vibeguard), add:

```bash
_check "plugin-daytona" "npm list -g opencode-daytona &>/dev/null"
_check "plugin-devcontainers" "npm list -g opencode-devcontainers &>/dev/null"
_check "plugin-background-agents" "npm list -g opencode-background-agents &>/dev/null"
_check "plugin-scheduler" "npm list -g opencode-scheduler &>/dev/null"
_check "plugin-shell-strategy" "npm list -g opencode-shell-strategy &>/dev/null"
_check "plugin-supermemory" "npm list -g opencode-supermemory &>/dev/null"
_check "plugin-websearch-cited" "npm list -g opencode-websearch-cited &>/dev/null"
_check "plugin-firecrawl" "npm list -g opencode-firecrawl &>/dev/null"
```

- [ ] **Step 3: Add skills health checks**

After line 78 (Muninn skills), add:

```bash
_check "Skill: code-review"    "[ -f \"$HOME/projects/.opencode/skills/code-review-checklist/SKILL.md\" ] || [ -f \"$HOME/agi/.opencode/skills/code-review-checklist/SKILL.md\" ]"
_check "Skill: deployment"     "[ -f \"$HOME/projects/.opencode/skills/deployment-checklist/SKILL.md\" ] || [ -f \"$HOME/agi/.opencode/skills/deployment-checklist/SKILL.md\" ]"
_check "Skill: testing"        "[ -f \"$HOME/projects/.opencode/skills/testing-strategy/SKILL.md\" ] || [ -f \"$HOME/agi/.opencode/skills/testing-strategy/SKILL.md\" ]"
```

- [ ] **Step 4: Verify bash syntax**

Run: `bash -n modes/health.sh`
Expected: no output

- [ ] **Step 5: Commit**

```bash
git add modes/health.sh
git commit -m "feat: health checks for new MCPs, plugins, skills"
```

---

### Task 14: Pre-session Check Updates

**Files:**
- Modify: `lib/pre-session-check.sh:52`

**Interfaces:**
- Produces: Pre-session check with expanded MCP list

- [ ] **Step 1: Expand MCP list**

Change line 52 from:

```bash
  for mcp in c7-mcp-server mcp-server-filesystem agentic-tools-mcp codegraph playwright-mcp agent-browser-mcp-server chrome-devtools-mcp mcp-server-github mcp-server-postgres mcp-server-sequential-thinking memorylayer-mcp loopsense; do
```

To:

```bash
  for mcp in c7-mcp-server mcp-server-filesystem agentic-tools-mcp codegraph playwright-mcp agent-browser-mcp-server chrome-devtools-mcp mcp-server-github mcp-server-postgres mcp-server-gitlab mcp-server-google-maps mcp-server-sequential-thinking memorylayer-mcp loopsense mcp-server-git mcp-server-memory mcp-server-fetch mcp-server-time mcp-server-redis mcp-server-brave-search; do
```

- [ ] **Step 2: Verify bash syntax**

Run: `bash -n lib/pre-session-check.sh`
Expected: no output

- [ ] **Step 3: Commit**

```bash
git add lib/pre-session-check.sh
git commit -m "feat: pre-session check with expanded MCP list"
```

---

### Task 15: Version Check Updates

**Files:**
- Modify: `lib/version-check.sh:121`

**Interfaces:**
- Produces: Version check covering new npm packages

- [ ] **Step 1: Expand npm package version check list**

Change line 121 from:

```bash
    for pkg in opencode-codegraph opencode-token-tracker opencode-orchestrator opencode-auto-fallback opencode-swarm chrome-devtools-mcp; do
```

To:

```bash
    for pkg in opencode-codegraph opencode-token-tracker opencode-orchestrator opencode-auto-fallback opencode-swarm chrome-devtools-mcp opencode-daytona opencode-background-agents opencode-scheduler opencode-shell-strategy opencode-supermemory opencode-firecrawl opencode-goal-plugin opencode-conductor; do
```

- [ ] **Step 2: Verify bash syntax**

Run: `bash -n lib/version-check.sh`
Expected: no output

- [ ] **Step 3: Commit**

```bash
git add lib/version-check.sh
git commit -m "feat: version check for new npm packages"
```

---

### Task 16: Test — MCP Registry Updates

**Files:**
- Modify: `tests/unit/test_mcp_registry.sh:29,33-34,42,59-69`

**Interfaces:**
- Produces: Updated test assertions for expanded MCP registry

- [ ] **Step 1: Update EXPECTED_MCPS**

Change line 29:

```bash
EXPECTED_MCPS="context7 filesystem agentic-tools codegraph playwright agent-browser loopsense github postgres gitlab google-maps sequential-thinking memorylayer chrome-devtools git memory fetch time redis brave-search"
```

- [ ] **Step 2: Update count assertion**

Change line 34:

```bash
assert "MCP registry has 20+ entries" "test \$(grep -c '\]=' \"$CORE\") -ge 20"
```

- [ ] **Step 3: Update health check coverage loop**

Change line 42 to include new MCPs:

```bash
for mcp in context7 filesystem agentic-tools codegraph playwright agent-browser loopsense github postgres sequential-thinking memorylayer chrome-devtools git memory fetch time redis brave-search; do
```

- [ ] **Step 4: Update version check expected packages**

Change lines 67-69 to include new packages:

```bash
for pkg in opencode-codegraph opencode-swarm chrome-devtools-mcp opencode-daytona opencode-background-agents opencode-firecrawl; do
```

- [ ] **Step 5: Run test to verify**

Run: `bash tests/unit/test_mcp_registry.sh`
Expected: all assertions pass

- [ ] **Step 6: Commit**

```bash
git add tests/unit/test_mcp_registry.sh
git commit -m "test: update MCP registry test for 20 entries + new packages"
```

---

### Task 17: Test — opencode.json Generation Updates

**Files:**
- Modify: `tests/integration/test_opencode_json_gen.sh:32,40,46,53-54,58`

**Interfaces:**
- Produces: Updated test assertions for expanded config generation

- [ ] **Step 1: Update EXPECTED_MCPS**

Change line 32:

```bash
EXPECTED_MCPS="context7 filesystem agentic-tools codegraph playwright agent-browser loopsense github postgres gitlab google-maps sequential-thinking memorylayer chrome-devtools git memory fetch time redis brave-search"
```

- [ ] **Step 2: Update EXPECTED_PLUGINS**

Change line 46:

```bash
EXPECTED_PLUGINS="opencode-codegraph opencode-dcp opencode-auto-fallback opencode-goal-mode opencode-swarm opencode-vibeguard opencode-daytona opencode-background-agents opencode-scheduler opencode-shell-strategy opencode-supermemory opencode-firecrawl"
```

- [ ] **Step 3: Add provider fallback assertion**

After line 55, add:

```bash
assert "Provider fallback chains exist" "grep -q 'fallback' \"$JSON_GEN\""
```

- [ ] **Step 4: Add agent section assertion**

After line 60:

```bash
assert "Config includes agent section" "grep -qE '\"agent\"' \"$JSON_GEN\""
```

- [ ] **Step 5: Run test to verify**

Run: `bash tests/integration/test_opencode_json_gen.sh`
Expected: all assertions pass

- [ ] **Step 6: Commit**

```bash
git add tests/integration/test_opencode_json_gen.sh
git commit -m "test: update opencode.json generation test for new components"
```

---

### Task 18: ShellCheck Pass

**Files:**
- All modified .sh files

**Interfaces:**
- Produces: Zero ShellCheck warnings on all project .sh files

- [ ] **Step 1: Run ShellCheck on all files**

```bash
for f in lib/00-core.sh lib/12-mcp-lsp.sh lib/14-shokunin.sh lib/17-project.sh lib/18-opencode-json.sh lib/19-finalize.sh modes/health.sh lib/pre-session-check.sh lib/version-check.sh tests/unit/test_mcp_registry.sh tests/integration/test_opencode_json_gen.sh; do
  shellcheck "$f" || echo "ISSUES: $f"
done
```

Expected: no errors or fix all warnings

- [ ] **Step 2: Fix any ShellCheck warnings found**

Address each warning. Common patterns to fix:
- `SC2086`: Double-quote variable references
- `SC1091`: Source files — already handled via SCRIPT_DIR resolution
- `SC2155`: Export with assignment — use separate declare + export

- [ ] **Step 3: Re-run after fixes**

```bash
for f in lib/*.sh modes/*.sh tests/**/*.sh; do
  shellcheck "$f" &>/dev/null || echo "SHELLCHECK FAIL: $f"
done
```

Expected: no output (all pass)

- [ ] **Step 4: Commit**

```bash
git add -A
git commit -m "fix: ShellCheck pass for all modified files"
```

---

### Task 19: Dry-run + Final Test Suite

**Files:**
- None (validation only)

**Interfaces:**
- Consumes: All previous tasks
- Produces: Clean test suite pass + successful dry-run

- [ ] **Step 1: Run full syntax check**

```bash
for f in setup.sh lib/*.sh modes/*.sh dev.sh; do
  bash -n "$f" || echo "SYNTAX FAIL: $f"
done
```

Expected: no output (all pass)

- [ ] **Step 2: Run full test suite**

```bash
bash tests/run_tests.sh
```

Expected: all tests pass, 0 failures

- [ ] **Step 3: Run dry-run**

```bash
bash setup.sh --dry-run
```

Expected: shows all steps without errors, no changes made

- [ ] **Step 4: Check test assertions match new counts**

Run: `grep -n 'ge [0-9]' tests/unit/test_mcp_registry.sh`
Verify: registry count assertion says `ge 20`

```bash
grep -n 'ge [0-9]' tests/unit/test_mcp_registry.sh
```

- [ ] **Step 5: Final commit**

```bash
git add -A
git commit -m "chore: v35.4 final — all tests pass, ShellCheck clean, dry-run OK"
```
