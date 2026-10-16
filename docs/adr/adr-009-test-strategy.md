# ADR-009: Test Strategy

## Status
Accepted

## Context
Need comprehensive test coverage for reliability and quality assurance. Current tests are shallow (structure checks only).

## Decision
Implement layered testing:
1. **Unit tests** — bash syntax, function existence, configuration validation
2. **Integration tests** — Testcontainers for PostgreSQL/Redis, mode-specific tests
3. **E2E tests** — smoke tests for CI, dry-run validation
4. **Performance tests** — load time, memory usage, token efficiency

Tests must never change the machine they run on. Because unit tests `source` real
modules from `src/lib/` and a module body installs packages through `sudo`, the
runner installs a **privilege sandbox** (`tests/test_sandbox.sh`): shims for
`sudo`, `doas`, `apt`, `apt-get`, `apt-key`, `add-apt-repository`, `dpkg`,
`dpkg-reconfigure` and `gpg` are prepended to `PATH`. Shims log the invocation and
exit 0, so a mis-mocked test degrades into a no-op instead of an interactive
password prompt or a mutated host. `tee`, `systemctl --user` and `curl` are
deliberately *not* shimmed — tests depend on them.

Two opt-in escape hatches, both defaulting to off:
- `RUN_E2E=1` (`--e2e`) runs the heavy end-to-end suite.
- `RUN_PRIVILEGED=1` (`--privileged`) disables the sandbox entirely.

Every test also runs under a timeout (`TEST_TIMEOUT`, default 300s) so a child that
captures the TTY cannot wedge the suite; a timeout counts as a failure.

## Consequences
- **Positive:** Faster feedback on regressions
- **Positive:** Easier debugging with specific test layers
- **Positive:** Confidence in production deployments
- **Positive:** The suite is safe on a laptop or a CI runner with no throwaway container
- **Positive:** The interception log is a leak detector — it names exactly which test tried to escalate
- **Negative:** Higher CI execution time
- **Negative:** Testcontainers dependency for integration tests
- **Negative:** A test that sources a privileged module still needs its own mock; the shim is defence in depth, not a substitute
- **Negative:** E2E coverage no longer runs by default in `run_tests.sh` (CI keeps its own explicit smoke-test job)

## Related
- Test files: `tests/unit/`, `tests/integration/`, `tests/e2e/`
- CI pipeline: `.github/workflows/test.yml`
- Test infrastructure: `tests/test_lib.sh`
- Privilege sandbox: `tests/test_sandbox.sh`, covered by `tests/unit/test_sandbox.sh`