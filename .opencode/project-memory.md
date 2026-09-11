# Project Memory — OpenCode Initializer
# Saved: 2026-09-11
# Purpose: Preserve context for next sessions

## Project Identity
- **Name:** opencode_initializer
- **Type:** AI-Native SDD Harness
- **Version:** v3.3.0
- **Author:** Alexander Narbaev (solo developer)
- **Repo:** github.com/AlexanderNarbaev/opencode_initializer

## Vision
OpenSource product for international community. Framework-platform combining
best practices of AI-assisted development. Not just an installer — a governed
agent harness with SDD workflow, multi-agent architecture, and governance.

## Unique Position
Only tool combining:
1. OS bootstrapping (packages, toolchains)
2. Agent context (MCP, LSP, plugins, skills)
3. Infrastructure (PostgreSQL, Redis, Qdrant, Prometheus)
4. Governance (model policies, PII, audit trails)

Competitors do one or the other:
- Microsoft APM = agent config distribution
- VibeVM = spec-driven prompts
- Omakub = machine setup
- opencode_initializer = ALL of the above

## Current State (2026-09-11)
- 76 shell modules (src/lib/)
- 104 tests (91 unit, 6 integration, 5 e2e)
- 22 providers, 24 MCP servers, 12 LSP servers, 21 plugins
- 43 skills in .opencode/skills/
- MkDocs Material documentation site (EN/RU)

## Accepted Decisions (from interview 2026-09-11)
1. APM integration: NOT NOW — focus on current architecture first
2. Docker testing: Testcontainers (Go/Python)
3. Multi-agent targets: NOT NOW — AGENTS.md as standard
4. Documentation: Bilingual (.en.md + .ru.md pairs)
5. Priorities v3.4.0: TOML config [P0] + 80%+ tests [P0] + F1/F2 [P1] + docs [P1]

## Current Pains
1. opencode.json drift — SOLVED (diff-before-write, 2026-08-28)
2. Slow installation (30+ min) — NOT STARTED
3. No TOML config — IN PROGRESS (TODO M3)
4. Docker services don't start — SOLVED (pre-flight, 2026-08-28)

## Key Files
- setup.sh — entry point (727 lines, 48 steps)
- dev.sh — dev CLI (1014 lines, 22+ subcommands)
- src/lib/00-core.sh — core bootstrap
- src/lib/18-opencode-json.sh — config generation (1023 lines)
- src/data/routing.json — model routing SSOT
- src/data/providers.json — provider registry SSOT
- src/data/mcp-profiles.json — MCP profiles SSOT

## Development Machine
- MECHREVO JIAOLONG Series
- AMD Ryzen 9 9955HX (16C/32T), 64GB RAM
- NVIDIA RTX 5070 Ti Laptop (12GB VRAM)
- 2TB NVMe (Kingston 1TB + YMTC 1TB)
- Ubuntu 26.04.1 LTS, GNOME 50, Wayland