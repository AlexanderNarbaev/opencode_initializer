# ADR-003: Parallel Installation Architecture

## Status
Accepted

## Context
Sequential module installation takes 30+ minutes. Users need faster setup, especially for CI/CD pipelines.

## Decision
Implement **layer-based parallel execution** with dependency awareness:
1. Modules declare dependencies via `_deps()` function
2. Dependency graph is built at startup
3. Modules are grouped into layers (no intra-layer dependencies)
4. Layers execute sequentially, modules within a layer execute in parallel
5. WAL (Write-Ahead Log) ensures crash recovery

WAL race condition fix: Use `flock` for atomic writes with `mkdir` fallback for systems without `flock`.

## Consequences
- **Positive:** 3-8x speedup on multi-core systems
- **Positive:** Crash recovery via WAL
- **Positive:** Dependency ordering prevents race conditions
- **Negative:** More complex error handling
- **Negative:** Some modules can't be parallelized (Docker socket, etc.)

## Related
- Engine: `src/lib/00d-parallel.sh`
- Tests: `tests/unit/test_parallel_engine.sh`
- CLI: `--parallel N`, `--no-parallel`
