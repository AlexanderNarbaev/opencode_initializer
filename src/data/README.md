# src/data/ — Single Source of Truth (SSOT)

## providers.json
Canonical provider registry (22 providers). All other copies derive from this file.

### Update procedure
1. Edit `providers.json` — add/remove/modify provider entries
2. Update `src/lib/26-providers.sh` embedded fallback (must match JSON exactly)
3. Run `bash tests/unit/test_provider_ssot.sh` — verifies sync across all consumers

### Current consumers (technical debt)
These files still use embedded copies — migration pending:

| File | Lines | Status |
|------|-------|--------|
| `src/lib/26-providers.sh` | 57–80 | ✅ JSON loader + embedded fallback (2026-08-08) |
| `src/lib/18-opencode-json.sh` | 125–145 | ⚠️ Embedded dict — needs JSON import |
| `src/lib/36-model-router.sh` | 17–76 | ⚠️ Embedded costs table — needs JSON merge |
| `scripts/ai-router.sh` | 36–43 | ⚠️ Partial list (4 providers) |
| `scripts/provider-check.sh` | 25–31 | ⚠️ Partial list (6 providers) |
| `src/lib/pre-session-check.sh` | 42–57 | ⚠️ Partial list |

### Audit reference
- C1 finding: [.opencode/audit/2026-08-08/01-core-architecture.md](../.opencode/audit/2026-08-08/01-core-architecture.md)
