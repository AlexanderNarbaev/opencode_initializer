# ADR-002: TOML Configuration Format

## Status
Accepted

## Context
The project needs a declarative configuration format. Options considered:
- YAML — popular but whitespace-sensitive, requires PyYAML
- JSON — no comments, verbose
- INI — limited nesting
- TOML — human-readable, native Python 3.11+ support via `tomllib`

## Decision
Use **TOML** as the primary configuration format with precedence:
```
CLI flags > Environment variables > setup.toml > Defaults
```

Implementation in `src/lib/00-core.sh` (functions: `_toml_get`, `_toml_load`, `_toml_print_resolved`).

## Consequences
- **Positive:** Human-readable, supports comments
- **Positive:** Native Python support (no dependencies)
- **Positive:** Good nesting support for complex configs
- **Negative:** Less common than YAML in DevOps ecosystem
- **Negative:** Requires Python 3.11+ for parsing

## Related
- Template: `src/data/setup.toml.template`
- Tests: `tests/unit/test_toml_config.sh`
- Docs: `docs/guides/toml-config.en.md`, `docs/guides/toml-config.ru.md`
