# ADR-004: Multi-Agent Target Generation

## Status
Accepted

## Context
Different AI coding assistants (GitHub Copilot, Claude, Cursor, VS Code) use different configuration formats. Developers using multiple tools need consistent settings across all of them.

## Decision
Generate configuration files for all major AI assistants from a single source of truth:
1. `.github/copilot-instructions.md` — GitHub Copilot
2. `.claude/settings.json` — Claude
3. `.cursor/settings.json` — Cursor
4. `.vscode/settings.json` — VS Code

All generated from `setup.toml` configuration.

## Consequences
- **Positive:** Single config, multiple outputs
- **Positive:** Consistent behavior across AI tools
- **Positive:** Easy to add new AI assistants
- **Negative:** Must track format changes for each tool
- **Negative:** Some settings don't map 1:1 between tools

## Related
- Generator: `src/lib/00h-multi-agent.sh`
- Tests: `tests/unit/test_v4_features.sh`
- CLI: `--multi-agent`, `--copilot`, `--claude`, `--cursor`, `--vscode`
