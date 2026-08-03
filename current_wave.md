# Current Wave Status

> Last updated: 2026-08-03T22:08:00Z

## Status: ✅ COMPLETE (pending commit)

## Active Task
- **Wave:** v2.0.2 — Remove Moonshot/Kimi + LiteLLM, streamline proxy dependencies
- **Task:** Complete removal from all configs, scripts, services — DONE

## Protection
- **Fragile zones:** src/lib/18-opencode-json.sh (provider config), src/lib/36-model-router.sh (routing profiles)

## Completed in this wave
- [x] Moonshot/Kimi/LiteLLM removed from all 9 opencode.json configs
- [x] litellm uninstalled from pipx
- [x] kimi-proxy + litellm systemd services stopped/disabled/removed
- [x] Project scripts cleaned (kimi-anthropic-proxy.py, litellm-force-temp.py, kimi.sh)
- [x] Module files removed (25-litellm.sh, 39-kimi-proxy.sh)
- [x] Provider registry updated (AGENTS.md, dev.sh, setup.sh)
- [x] **Audit 2026-08-03 follow-ups** ([docs/research/audit-2026-08-03.md](./docs/research/audit-2026-08-03.md)):
  - [x] Test harness gate: 23 test files gained exit-on-failure; 7 silent failures surfaced and fixed
  - [x] Dead modules wired into setup.sh: 31-cockpit.sh, 32-isolated.sh, 33-services.sh (TOTAL_STEPS=41)
  - [x] Stale kimi assertions in test_model_router.sh replaced (deepseek/glm reality)
  - [x] Root opencode.json: dangling zai fallback refs removed; fallback-consistency invariant added to test_providers.sh
  - [x] LiteLLM check removed from health.sh; dev.sh recommendation updated
  - [x] docs/VERSIONS.md (Moonshot endpoint, rag-system row), README, 12 live docs files (en+ru) cleaned
  - [x] SCRIPT_VERSION → v2.0.2; CHANGELOG [2.0.1] + [2.0.2]; session_checkpoint.json refreshed
  - [x] dist/ added to .gitignore
