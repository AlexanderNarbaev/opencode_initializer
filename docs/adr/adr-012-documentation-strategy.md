# ADR-012: Documentation Strategy

## Status
Accepted

## Context
International user base needs documentation in multiple languages. Technical depth requires comprehensive architecture docs.

## Decision
Implement bilingual documentation:
1. **English/Russian pairs** — `.en.md` and `.ru.md` for all docs
2. **Architecture docs** — comprehensive technical documentation
3. **ADRs** — decision records for architectural choices
4. **Runbooks** — operational procedures
5. **Changelog** — version history

## Consequences
- **Positive:** Accessible to international users
- **Positive:** Comprehensive technical reference
- **Positive:** Decision traceability through ADRs
- **Negative:** Translation maintenance burden
- **Negative:** Risk of documentation drift

## Related
- Docs site: `docs/`
- Architecture docs: `docs/architecture/`
- ADRs: `docs/adr/`
- Runbook: `docs/runbook/`
