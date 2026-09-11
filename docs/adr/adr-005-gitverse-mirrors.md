# ADR-005: GitVerse Mirrors for RU/CN Regions

## Status
Accepted

## Context
Developers in Russia and China face slow or blocked access to global package registries (npm, PyPI, Docker Hub, etc.). GitVerse provides free mirror registries.

## Decision
Implement region-aware mirror configuration:
- Auto-detect region from timezone
- Configure mirrors for: npm, PyPI, Go, Crates, Docker, Maven
- Support manual override via `--mirrors [ru|cn|global]`

Mirror URLs:
| Service | Mirror |
|---------|--------|
| npm | `https://npm-mirror.gitverse.ru` |
| PyPI | `https://pypi-mirror.gitverse.ru/simple/` |
| Go | `https://go-mirror.gitverse.ru` |
| Crates | `https://crates-mirror.gitverse.ru` |
| Docker | `https://dh-mirror.gitverse.ru` |
| Maven | `https://mvn-mirror.gitverse.ru` |

## Consequences
- **Positive:** 10-50x faster downloads for RU/CN users
- **Positive:** Works behind firewalls
- **Positive:** Automatic region detection
- **Negative:** Must keep mirror list updated
- **Negative:** Some mirrors may lag behind upstream

## Related
- Module: `src/lib/00i-mirrors.sh`
- Tests: `tests/unit/test_mirrors_sync.sh`
- CLI: `--mirrors [ru|cn|global]`
