# Current Wave Status

> Last updated: 2026-10-26T17:20:00Z

## Status: ✅ COMPLETE

## Active Wave
- **Wave:** v16.1.0 — OpenCode v2.1.4 migration + machine recovery + reproducible agentic stack
- **Source:** user directive (recover a half-purged machine, unify project configs, make the repo the installer)

## Completed in v16.1.0
- [x] Diagnosed the real breakage: OpenCode 2.1.4 was installed but the global config was an empty V1 stub,
  `~/.npm-global` was empty, Bun/uv were purged, and 15 of 21 MCP servers pointed at binaries that no longer existed.
- [x] Restored prerequisites: npm prefix, Bun 1.4.4, uv 0.13.5, six Bun MCP servers, three uv MCP servers.
- [x] Rebuilt the global config in the **V2 shape** (flat `mcp`, flat `plugin`, `enabled_providers`);
  7 MCP servers and 7 plugins verified by actual load (not by config parsing).
- [x] Classified plugins empirically: 7 load on V2, 9 V1-only plugins fail with
  `Plugin must export a default definition with an id and an effect or setup function` and were removed.
- [x] Skills: 43 repo skills flattened into `~/.config/opencode/skills`; global `AGENTS.md` added.
- [x] Projects: all `~/Projects/*` configs reduced to a minimal V2 file that inherits the global stack;
  130 `*.bak` files removed.
- [x] Cleanup: 115 GB `_trash/`, `.legacy-backup/`, 15 repo artifacts, stray agent workspace — removed
  (secrets/auth preserved first in `~/.cache/opencode-recovery/`).
- [x] Repo: `scripts/install-agentic-stack.sh` + `src/data/opencode.global.template.json` +
  `scripts/check-version-consistency.sh` + `tests/unit/test_agentic_stack_installer.sh`;
  version unified to 16.1.0; docs parity gate repaired; new gates wired into `lint.yml` and pre-commit.


## Round 2 (same wave) — installation surface
- [x] `setup.sh --agentic` / `--agentic-check`: orchestrator mode that installs/verifies the v2 stack.
- [x] `--dry-run` is now a modifier, not a mode (`--agentic --dry-run` plans correctly).
- [x] `dev stack check|install|plan|template`, `dev marketplace list|json|check|search`.
- [x] `src/data/marketplaces.json` — curated plugin/MCP/skill registries (live-checked 2026-10-26).
- [x] `scripts/audit-module-reachability.sh` + `src/data/dead-modules.baseline` — dead-code ratchet in CI.
- [x] Two new subagents in the global config: `reviewer`, `docs`.
- [x] `tests/unit/test_module_reachability.sh` (13) and `tests/unit/test_marketplace.sh` (16).


## Round 3 (same wave) — governance + quarantine
- [x] `src/plugins/governance.js` — real v2 plugin: hash-chained audit, secret/PII redaction,
      dangerous-command guard. Verified live (`plugin.load → tool.execute.before → tool.execute.after`,
      chain valid).
- [x] Installer step 8 installs and syntax-checks the plugin; `--check` verifies it.
- [x] 64 unreachable modules quarantined in `src/lib/experimental/` (README documents status and revival
      path); `src/lib` is 97 modules, 97 reachable, 0 dead; baseline intentionally empty.
- [x] Syntax checks extended to `src/lib/experimental/*.sh` in the runner and AGENTS command.
- [x] `tests/unit/test_governance_plugin.sh` (32 assertions).

## Verification Evidence
- `bash scripts/install-agentic-stack.sh --check` → all checks passed (7 MCP, 7 plugins, 43 skills)
- `opencode run -m opencode-go/deepseek-v4.1-flash "Say OK"` → OK
- `opencode mcp` log: `mcp connected` for context7, sequential-thinking, memory, git, time, grep, chrome-devtools
- `bash scripts/check-doc-counts.sh` → OK (unit=122 intg=13 e2e=6 providers=22 lsp=12)
- `bash scripts/check-docs-parity.sh` → OK (32 locale pairs)
- `bash scripts/check-setup-lines.sh` → OK (1296)
- `bash scripts/check-version-consistency.sh` → OK (16.1.0)
- `bash tests/run_tests.sh` → see CHANGELOG entry for this wave

## Open issues carried forward
- 64 of 161 `src/lib` modules remain unreachable from any entrypoint (`62–119`, `41–51` second family).
- `sqlite` MCP disabled: upstream `mcp-server-sqlite` is incompatible with the current MCP SDK.
- `github`/`brave-search`/`notion`/`sentry` MCP servers disabled pending credentials.
- `setup.sh` still installs the V1 stack; the V2 path is `scripts/install-agentic-stack.sh`.
