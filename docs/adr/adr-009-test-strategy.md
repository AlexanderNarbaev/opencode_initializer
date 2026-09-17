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

## Consequences
- **Positive:** Faster feedback on regressions
- **Positive:** Easier debugging with specific test layers
- **Positive:** Confidence in production deployments
- **Negative:** Higher CI execution time
- **Negative:** Testcontainers dependency for integration tests

## Related
- Test files: `tests/unit/`, `tests/integration/`, `tests/e2e/`
- CI pipeline: `.github/workflows/test.yml`
- Test infrastructure: `tests/test_lib.sh`
