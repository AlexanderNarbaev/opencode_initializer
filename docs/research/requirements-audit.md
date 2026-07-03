# Requirements Audit — Current Status vs Specification

**Date:** 2026-07-03
**Spec:** docs/research/requirements-specification.md
**Status:** CRITICAL GAPS IDENTIFIED

## Audit Summary

| Req | Title | Status | Score | Critical Gaps |
|-----|-------|--------|-------|---------------|
| R1 | Universal Completeness | PARTIAL | 70% | MCP: 27 declared, only 4 installed. LSP: 16 declared, 11 installed. |
| R2 | Easy Lifecycle | GOOD | 85% | No CI on Fedora/Arch. Update not tested end-to-end. |
| R3 | Verified Interoperability | PARTIAL | 60% | CI only Ubuntu. No component interaction tests. |
| R4 | OpenCode Super-Setup | GOOD | 80% | opencode.json valid. But 13 plugins not installed. |
| R5 | Beyond Installation | PARTIAL | 65% | MemoryLayer runs. Cockpit built. But RAG is stub. No token analytics. |
| R6 | Visual Management | PARTIAL | 55% | Cockpit TUI built (1210 lines). GUI is stub (54 lines). Grafana config? |
| R7 | Max Agent Performance | WEAK | 30% | **NO model routing. NO cost analytics. NO effectiveness evaluation.** |
| R8 | Dual Environment | GOOD | 75% | Isolated Circuit works. But no corporate proxy/auth. |
| R9 | Proactive Auth | PARTIAL | 50% | Pre-session check exists but doesn't RECOMMEND models. No z.ai/OpenRouter. |
| R10 | Closed Environment | GOOD | 75% | Isolated Circuit + local backends. But no model download guidance. |
| R11 | Documentation | GOOD | 85% | All pages updated. But some reference pages may be incomplete. |
| R12 | Security | GOOD | 85% | Secrets in secrets.env. ShellCheck CI. But no Trivy in CI. |
| R13 | Reproducibility | GOOD | 80% | Progress file, idempotent. But no version pinning. |
| R14 | Observability | PARTIAL | 60% | Prometheus + Grafana declared. But dashboards not provisioned. |
| R15 | Team Collaboration | GOOD | 75% | chezmoi, env-var substitution. But no team model preferences. |
| R16 | Disaster Recovery | WEAK | 40% | .zshrc backup. But no config backup/restore system. |
| R17 | Performance | GOOD | 80% | Bun paths, npm cache, _curl cache. |
| R18 | Accessibility | GOOD | 80% | Bilingual docs, 6 package managers, WSL2. |

**Overall: 66% — SIGNIFICANT GAPS in R7, R16, R6, R5**

## Critical Gaps (Priority Order)

### GAP 1: R7 — No Model Routing Intelligence (CRITICAL)

**Current state:** opencode.json has a fixed `model` and `small_model`. No automatic selection.
**What's needed:**
- Task-based model selection (coding → Claude Opus 4.8, fast → DeepSeek Flash, reasoning → GLM-5.2)
- Cost tracking dashboard (tokens used, cost per task, model efficiency)
- Model performance evaluation (success rate, iteration count, user satisfaction)
- Automatic fallback when primary model is unavailable or rate-limited

**Impact:** Users always use the same model regardless of task. No cost optimization.
No quality optimization. This is the biggest gap vs the stated goal.

### GAP 2: R1 — MCP/LSP Installation Gap (HIGH)

**Current state:** 27 MCP servers declared in config, only 4 actually installed in ~/.bun/bin/.
16 LSP servers declared, 11 actually installed (lua, zls missing).

**What's needed:**
- Verify ALL declared MCP servers are installed by 12-mcp-lsp.sh
- Install missing LSP servers (lua-language-server, zls)
- Add installation verification step after 12-mcp-lsp.sh
- MCP cold-start test should verify ALL declared MCPs, not just check binary exists

### GAP 3: R6 — GUI is a Stub (HIGH)

**Current state:** `src/gui/server.js` (243 lines) + `index.html` (94 lines) exist but:
- 35-gui.sh is only 54 lines — just creates a systemd service
- No actual management UI — just a basic web server
- No settings panel, no visualization, no real-time monitoring

**What's needed:**
- Functional web UI with: provider status, model selection, MCP/LSP management, log viewer
- Or: declare GUI as "foundation" and document it as future work

### GAP 4: R5 — RAG System is a Clone Stub (MEDIUM)

**Current state:** 21-rag.sh (30 lines) just clones a git repo and pip installs requirements.
No verification, no integration with opencode, no configuration.

**What's needed:**
- RAG system should be verified after installation
- Should be integrated with Qdrant (already in infra)
- Should be accessible from opencode as a tool or MCP

### GAP 5: R9 — Pre-session Check Outdated (MEDIUM)

**Current state:** pre-session-check.sh checks 5 providers (DeepSeek, OpenCodeGo, Grok, MiniMax,
Moonshot). Missing: z.ai, OpenRouter, Alibaba, DeepInfra, Google, Anthropic, OpenAI, etc.
Cost table is hardcoded and outdated.

**What's needed:**
- Check ALL 24 providers (or at least all with keys)
- Dynamic cost table from models.dev
- Model recommendation based on task type
- Suggest using z.ai GLM-5.2 for RU/CN users

### GAP 6: R14 — Grafana Dashboards Not Provisioned (MEDIUM)

**Current state:** 34-observability.sh adds Prometheus + Grafana to docker-compose.
But no dashboard JSON files, no datasource auto-provisioning.

**What's needed:**
- Grafana datasource auto-provisioning (Prometheus)
- Pre-built dashboards: system overview, agent performance, token usage
- Alert rules for service health

### GAP 7: R16 — No Config Backup/Restore (LOW)

**Current state:** .zshrc backup exists. But no systematic config backup.

**What's needed:**
- `dev backup` — backup all configs to tar.gz
- `dev restore` — restore from backup
- Include: opencode.json, secrets.env, setup.conf, .zshrc, infra.yml

### GAP 8: R3 — CI Only Ubuntu (LOW)

**Current state:** CI runs only on ubuntu-latest.

**What's needed:**
- Add Fedora to CI matrix
- Add Arch Linux (or at least syntax check for pacman paths)

## Improvement Plan

### Phase 1: Critical Fixes (R7, R1, R9)
1. **Model routing**: Create `src/lib/36-model-router.sh` — task-based model selection
2. **Cost tracking**: Enhance pre-session-check.sh with token/cost analytics
3. **MCP verification**: Add post-install MCP verification to 12-mcp-lsp.sh
4. **LSP gaps**: Install lua-language-server and zls in 12-mcp-lsp.sh
5. **Pre-session update**: Add all 24 providers, dynamic costs, model recommendations

### Phase 2: Visual & Integration (R6, R5, R14)
6. **GUI enhancement**: Expand src/gui/ with real management controls
7. **RAG integration**: Connect RAG system to Qdrant + opencode
8. **Grafana dashboards**: Create dashboard JSON files, datasource provisioning
9. **Cockpit enhancement**: Add model routing tab, cost analytics tab

### Phase 3: Resilience (R16, R3, R8)
10. **Backup/restore**: `dev backup` / `dev restore` commands
11. **CI matrix**: Add Fedora to CI
12. **Corporate proxy**: HTTP_PROXY support in _curl(), certificate handling
13. **Model download guidance**: `dev models` command for local model recommendations

### Phase 4: Documentation (R11)
14. **Reference docs**: Update MCP/LSP/plugin catalog with actual installed state
15. **Corporate guide**: Document closed-environment setup
16. **Model routing guide**: Document task-based model selection
