# Project Context — opencode_initializer v2.0.3

## Environment
- Language: Bash (shell scripts), Python (config generation), Go (cockpit)
- Runtime: bash 5.x (Linux), requires bash>=4
- Build: bash -n (syntax check), shellcheck (lint)
- Test: bash tests/run_tests.sh (38 unit + 5 integration + 4 e2e = 47 total)
- Package Manager: apt, npm, pipx, cargo, go

## Current Status — Wave v2.0.3 (deep-research findings)
- M1 DONE: T1.1 plugins.json, T1.2 migration, T1.3 sudo, T1.4 macOS grep
- M2 DONE: T2.1 trivy, T2.2 env unification, T2.3 test coverage, T2.4 shellcheck
- M3 DONE: T3.1 dev doctor, T3.2 health checks
- M4 IN PROGRESS: T4.1 DONE, T4.2 pending, T4.3 pending

## Verification Gates
- `bash -n` ALL .sh: 0 errors
- `shellcheck -S error`: 0 errors
- `grep -P` remaining: 0
- `test_core.sh`: 63/0
- `test_helpers.sh`: 61/0
- `test_sync_providers.py`: 3/3
- `test_sync_agents.py`: 3/3
- Full suite: syntax+unit+integration pass, e2e timeout (expected)
