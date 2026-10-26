# Experimental modules (quarantine)

These 64 modules came from the v15 "ecosystem" waves (skill registry, agent
orchestration, enterprise governance, harness, PLA, RAG, performance, cloud sync,
marketplace). They were **never reachable from any entrypoint**: `setup.sh`,
`dev.sh`, `src/modes/*` and `scripts/*` never sourced them, so `setup.sh --full`
and every `dev` command silently ignored them. Their unit tests passed because
they `source` the file directly.

They live here instead of being deleted so the work is not lost, and instead of
staying in `src/lib/` so nobody mistakes them for shipped functionality.

## Rules

1. Nothing in `src/lib/` or the entrypoints may reference this directory.
   `scripts/audit-module-reachability.sh` only scans `src/lib/*.sh`, so a module
   here is by definition not part of the product.
2. To revive a module: fix it, add an entrypoint (`_run_step` in `setup.sh`, a
   `dev` subcommand, or a hook), move it back to `src/lib/`, then run
   `bash scripts/audit-module-reachability.sh --baseline src/data/dead-modules.baseline`.
   The baseline is intentionally empty: any new unreachable module fails CI.
3. Tests may still reference `src/lib/experimental/<name>.sh`; when a module is
   revived, move the test path back too.

## Known state

- `62-skill-registry`, `63-skill-manager`, `64-skill-security`, `65-skill-eval`:
  half-working even standalone (`cmd_skill list` prints nothing, `cmd_skill_eval`
  dies on an unbound variable, `cmd_skill_manager` exits 1). Not wired on purpose.
- `66`–`90`: agent/orchestration/enterprise families — no runtime consumer.
- `91`–`100`: harness primitives (the `har` CLI in `scripts/har` does not use them).
- `101`–`110`: PLA + hybrid RAG — research prototypes.
- `111`–`119`: performance/security/cloud/marketplace scaffolds.
- `00u`–`00x`, `01b`: telemetry, age-encryption, shell integrations, chezmoi,
  alternate config loader, Linux platform probe.

Verified on 2026-10-26: 97 live modules, 0 unreachable, 64 quarantined.
