# OpenCode Initializer — Master Requirements Specification

**Version:** 1.0 | **Date:** 2026-07-03 | **Status:** Authoritative

## Purpose

This document defines the complete, binding requirements for the opencode_initializer project.
Every feature, module, and configuration must be traceable to these requirements.
All changes must be validated against this specification.

---

## R1: Universal Completeness

The system must be a **universal, complete, interconnected ecosystem** containing all available
and relevant components for AI-enhanced development:

- **MCP servers**: All community-available MCP servers that provide value for development workflows
- **LSP servers**: All language servers for supported programming languages
- **Modes**: All operational modes (full, reinit, new, health, update, upgrade, interactive, ci,
  fix-config, fix-zshrc, dry-run, isolated)
- **Skills**: AI agent skills (Shokunin, Superpowers, Caveman, custom skills)
- **Plugins**: All opencode plugins that enhance agent capabilities
- **Providers**: All LLM providers accessible to the target user (cloud + local)
- **Infrastructure**: All supporting services (PostgreSQL, Qdrant, Redis, Prometheus, Grafana,
  MemoryLayer, ChromaDB, SearXNG, LiteLLM, Ollama, vLLM, SGLang, Open WebUI)
- **Interconnections**: Every component must be configured to work with every other component
  it can interact with (e.g., MCP→LSP, LLM→LiteLLM→Ollama, Memory→Qdrant→embeddings)

**Acceptance criteria**: No known relevant MCP/LSP/plugin/provider is missing from the registry.
All declared components have installation + configuration + verification steps.

## R2: Easy Lifecycle Management

The system must support **frictionless install, update, and rebuild**:

- **Install**: Single command (`curl | bash`) from any state (fresh OS, partial, reinit)
- **Update**: `dev update` updates all tools + runs pending migrations
- **Rebuild**: `dev self-update` pulls latest + reinstalls CLI + setup.sh
- **Idempotency**: Re-running setup.sh skips completed steps (progress file)
- **Rollback**: Failed steps can be retried without full restart
- **Dry-run**: Preview all changes without executing

**Acceptance criteria**: `setup.sh --full` completes without manual intervention on a fresh
Ubuntu 22.04/24.04, Debian 12, Fedora 40+, Arch, or WSL2. `dev update` updates all tools.

## R3: Verified Interoperability

All components must be **strictly verified, configured, and tested** to work:

- **Cross-distro**: Every module works on apt/dnf/pacman/apk/zypper/brew
- **Cross-arch**: amd64 and arm64 supported where applicable
- **WSL2**: DNS fix, memory limits, mirrored networking, .wslconfig
- **Component-to-component**: MCP servers don't conflict, LSP servers don't conflict,
  infrastructure services don't conflict (port assignments verified)
- **Model IDs**: All model IDs verified against models.dev (opencode's authoritative source)
- **Config validity**: opencode.json is valid JSON, passes schema validation

**Acceptance criteria**: CI runs on at least Ubuntu + Fedora. All port assignments are unique.
opencode.json validates against schema. All model IDs match models.dev.

## R4: OpenCode Super-Setup

The system is a **super-configuration for opencode** as the base platform:

- **opencode.json**: Generated with all providers, MCPs, LSPs, plugins, agents, permissions
- **Provider fallback chains**: Automatic failover between providers
- **Agent configuration**: build, plan, general, explore, code-reviewer, compaction agents
- **Permission model**: File edit, bash, read, write, task permissions per agent
- **Compaction**: Auto-compaction with pruning and tail-turns preservation
- **Plugin ecosystem**: All relevant plugins installed and configured

**Acceptance criteria**: `opencode` starts without errors using the generated config.
All declared providers are reachable (when API keys are set). All plugins load.

## R5: Beyond Installation — Configuration, Monitoring, Memory, Knowledge

The system must include **not just installation, but ongoing operation**:

- **Configuration**: Persistent config (`~/.config/opencode-setup/setup.conf`)
- **Monitoring**: Cockpit TUI (7-tab), Prometheus metrics, Grafana dashboards
- **Memory**: MemoryLayer (AI memory with Ollama embeddings), Muninn (ChromaDB)
- **Knowledge base**: RAG system (corporate knowledge assistant)
- **Session persistence**: WAL (Write-Ahead Log) for session state
- **Pre-session validation**: Provider/model/MCP status check before each session
- **Auto-update**: systemd weekly timer + topgrade + unattended-upgrades

**Acceptance criteria**: MemoryLayer container runs. Cockpit TUI launches and shows real data.
Pre-session check reports accurate provider/MCP status. RAG system is installable.

## R6: Visual Management

The system must provide **visual tools for management, visualization, and configuration**:

- **Cockpit TUI**: 7-tab terminal UI (System, Plugins, GPU/Models, Sessions, Tasks, Logs, Infra)
- **Web GUI**: Browser-based management interface (port 4200)
- **Grafana dashboards**: Pre-provisioned observability dashboards (port 3001)
- **Open WebUI**: LLM chat interface (systemd service)
- **Health visualization**: Color-coded diagnostic output (65+ checks, 11 sections)

**Acceptance criteria**: `cockpit` command launches TUI with all 7 tabs showing live data.
Web GUI serves on port 4200 with management controls. Grafana shows Prometheus metrics.

## R7: Maximum Agent Performance — Quality, Cost, Caching, Evaluation

The agent system must **always operate at maximum available capability**:

- **Model selection**: Best model per task type (coding, reasoning, fast, cheap)
- **Cost optimization**: Track token usage, cost per task, model efficiency
- **Caching**: LLM response caching where applicable, tool output caching
- **Token tracking**: opencode-token-tracker plugin for usage analytics
- **Effectiveness evaluation**: Periodic assessment of model performance per task type
- **Fallback chains**: Automatic failover to alternative models/providers
- **Small model**: Dedicated small_model for lightweight tasks (compaction, exploration)
- **Context optimization**: DCP plugin for context pruning, vibeguard for PII filtering

**Acceptance criteria**: Token usage is tracked and visible. Model selection can be
configured per task type. Fallback chains work when primary provider is unreachable.

## R8: Dual Environment — Individual and Corporate

The system must work **both for individual developers and in corporate/closed environments**:

- **Individual mode**: Full install with all cloud providers, public services
- **Corporate mode**: Isolated Circuit (air-gapped LLM), corporate proxy support
- **Tool enable/disable**: `dev install <component>` / `dev remove <component>`
- **Granular control**: Interactive mode for component-by-component selection
- **Config isolation**: Project-level config overrides global config
- **Proxy support**: HTTP_PROXY, HTTPS_PROXY, corporate certificate handling
- **No forced cloud**: All cloud features are opt-in, not default in closed mode

**Acceptance criteria**: `--isolated` flag disables all cloud providers. `dev isolated on/off/status`
toggles mode. Interactive mode allows selecting/deselecting any component.

## R9: Proactive Authorization and Model Recommendation

The system must **proactively authenticate and recommend optimal models**:

- **Pre-session check**: Validates provider keys, reports available models, shows costs
- **Model recommendation**: Suggests best model based on task type (coding, reasoning, fast)
- **Cost display**: Shows per-1M-token costs for available models
- **Key detection**: Reads keys from secrets.env, auth.json, environment variables
- **Guided setup**: `--deepseek-key`, `--zai-key`, etc. for initial configuration
- **Auth persistence**: Keys stored in `~/.config/opencode/secrets.env` (chmod 600)

**Acceptance criteria**: Pre-session check shows accurate provider status, model count, costs.
Model recommendations are based on current models.dev data. Keys are never logged or exposed.

## R10: Closed Environment — External and Local Models

In closed environments, the system must support **both external (user-provided) and local models**:

- **External models**: User provides API keys for cloud providers (z.ai, OpenRouter, etc.)
- **Local models**: Ollama, vLLM, SGLang, LiteLLM for air-gapped operation
- **Model installation**: Guidance for downloading local models (ollama pull)
- **OpenRouter bridge**: Single key for 100+ models, works through corporate proxy
- **LiteLLM gateway**: OpenAI-compatible endpoint unifying all local backends
- **Auto-detection**: Discovers running local backends at /v1/models
- **Config persistence**: Isolated Circuit state saved in setup.conf

**Acceptance criteria**: `--isolated` mode uses only local backends. User can provide external
keys even in isolated mode (hybrid). `ollama pull` guidance is shown. LiteLLM unifies backends.

## R11: Comprehensive Documentation and Landing

All features must be **reflected in beautiful, detailed, understandable documentation**:

- **Landing page**: MkDocs Material site with feature grid, quick start, architecture
- **Getting started**: Beginner-friendly installation guide
- **User guide**: Day-to-day usage patterns
- **Architecture**: C4 diagrams, module reference, dependency map
- **Reference**: CLI, opencode.json schema, MCP/LSP/plugin catalog
- **Advanced**: Customization, WSL2, GPU, corporate setup
- **FAQ**: Common questions and troubleshooting
- **Team setup**: Onboarding guide for teams
- **Contributing**: How to contribute, code style, testing
- **Changelog**: Versioned release notes with migration guides
- **Bilingual**: English and Russian documentation
- **Social card**: OG image with current stats

**Acceptance criteria**: All docs pages reflect current v2.0.0 state. No outdated version
references. Landing page is visually appealing with accurate stats. Docs deploy via CI.

---

## Additional Requirements (Strengthened)

## R12: Security Hardening

- No hardcoded credentials in any source file
- All API keys via CLI arguments or secrets.env (chmod 600)
- .env files protected from agent reads (permission model)
- ShellCheck CI on every push/PR
- Trivy + Qodana security scanning
- opencode-vibeguard plugin for PII/secret filtering

## R13: Reproducibility

- Same input → same output (deterministic config generation)
- Idempotent operations (re-runs skip completed steps)
- Progress tracking (`~/.cache/opencode-setup/progress`)
- Version pinning for all installable tools
- Mirror fallback for network-constrained environments

## R14: Observability

- Prometheus metrics for infrastructure services
- Grafana dashboards for visualization
- Cockpit TUI for real-time system status
- OpenTelemetry plugin for agent tracing
- Health check mode (65+ checks, 11 sections)

## R15: Team Collaboration

- chezmoi dotfiles manager for shared team config
- ${ENV_VAR} substitution in opencode.json (shareable without secrets)
- Project-level config overrides (`.opencode/` directory)
- Team setup guide documentation
- Git-based config sharing

## R16: Disaster Recovery

- .zshrc backup before modification
- Progress file for resume-after-crash
- Migration scripts for version upgrades
- Config backup/restore (setup.conf)
- Git-based recovery (self-update pulls latest)

## R17: Performance Optimization

- Bun binary paths for MCP cold-start (0.5s vs 5-15s with npx)
- npm pack cache for MCP (.tgz files survive cache clears)
- _curl() with 24h cache and 5 retries
- Parallel installation where dependencies allow
- Small model for lightweight tasks (compaction, exploration)

## R18: Accessibility and Internationalization

- Bilingual documentation (English + Russian)
- Cross-distro support (6 package managers)
- Cross-architecture support (amd64 + arm64)
- CLI usability (color output, progress indicators, help text)
- WSL2 optimization for Windows users
