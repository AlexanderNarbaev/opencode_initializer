# Changelog

All notable changes to opencode_initializer will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Setup logging: `tee` to `~/.cache/opencode-setup/setup-YYYYMMDD-HHMMSS.log`
- `shopt -s inherit_errexit` for stricter error handling
- RAG System install module (`src/lib/21-rag.sh`) as optional component
- Architecture-aware LSP downloads (arm64 + amd64) for marksman, zls, lua-language-server

### Fixed
- Version consistency: all files now v1.0.0 (was v36.0 in 00-core.sh, interactive.sh)
- CI test.yml: fixed paths `lib/` → `src/lib/`, `modes/` → `src/modes/`
- Removed dangling `WALEOF` word in 17-project.sh (caused runtime error)
- `sudo apt-get` → `_sudo` in 05-java.sh for non-interactive environments
- `cmd.exe` proxy detection guarded behind WSL check
- `return 1` crash in 15-security.sh replaced with safe `return 0`
- All curl calls in version-check.sh and 08-go.sh: added `--retry 3 --retry-delay 2`
- Secrets: added GITLAB_TOKEN, GITVERSE_TOKEN, GOOGLE_MAPS_KEY to secrets.env
- topgrade systemd service: flexible path detection (cargo + system)
- 17-project.sh backup dir `~/agi` → `~/projects`
- Kotlin health check: removed falsy `|| echo` fallback
- AGENTS.md: updated module count 24→25, added 21-rag.sh documentation
- Test assertions: v36.0 → v1.0.0 (3 files)

### Changed
- Project structure: `lib/` → `src/lib/`, `modes/` → `src/modes/`, `plans/` → `docs/plans/`, `research/` → `docs/research/`
- Documentation: full open source pack (CHANGELOG, CODE_OF_CONDUCT 2.1, SECURITY, CITATION.cff, FUNDING.yml, issue/PR templates)

## [1.0.0] — 2026-06-22

### Added
- Initial public release of OpenCode Initializer
- 8 programming languages (Java 25, Node.js 24, Python 3.14, Go 1.26, Rust 1.96, .NET 10, Kotlin, Zig)
- 21 MCP servers for AI-assisted development
- 15+ OpenCode plugins (token-tracker, dcp, swarm, goal-mode, vibeguard, orchestrator, notify, pty, snip, snippets, envsitter-guard, command-inject, ignore, auto-fallback)
- 13 LSP servers (gopls, rust-analyzer, tsserver, pyright, omnisharp, yaml, marksman, taplo, lua, zls, bash, dockerfile, css/html/json)
- Infrastructure: Docker, ChromaDB + Muninn, GPU/LLM runtimes (Ollama, vLLM, SGLang, Open WebUI)
- ZSH + Oh My Zsh + Powerlevel10k with 18 plugins
- Google Chrome + ChromeDriver (WSL2-aware)
- CLI `dev` tool for post-install management
- Auto-update via systemd weekly timer + topgrade
- Cross-distro support (apt/dnf/pacman/apk/zypper/brew)
- Russian mirrors for network-constrained environments
- Progress tracking with retry logic and exponential backoff
- WSL2 optimization (DNS fix, memory limits, mirrored networking)
- Comprehensive test suite (unit, integration, E2E)
- ShellCheck CI on every push/PR
- Full open source documentation (README, CONTRIBUTING, CODE_OF_CONDUCT, SECURITY, CHANGELOG)
- GitVerse mirror

[Unreleased]: https://github.com/AlexanderNarbaev/opencode_initializer/compare/v1.0.0...main
[1.0.0]: https://github.com/AlexanderNarbaev/opencode_initializer/releases/tag/v1.0.0
