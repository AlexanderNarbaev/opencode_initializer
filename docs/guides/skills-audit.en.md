# Skills Audit

`dev skills` audits the three views of your skill estate and reports where they
have drifted apart:

1. **Installed** — every `SKILL.md` found under the global skills directory
   (`${XDG_CONFIG_HOME:-$HOME/.config}/opencode/skills`, or `$OPENCODE_SKILLS_DIR`).
2. **Registered** — every skill slug referenced by the auto-skills registry
   (`${XDG_CONFIG_HOME:-$HOME/.config}/opencode/auto-skills/config.json`), i.e. the
   `default_skills`, `priority`, and every `task_triggers[*].skills` /
   `file_triggers[*].skills` array.
3. **Used** — skill names that appear in recent OpenCode logs (best-effort).

Drift matters because the auto-skills system (module `53-auto-skills.sh`) can
only *suggest* skills it knows about, and can only *resolve* skills that are
actually installed. When the three views disagree, you either ship a suggestion
that points at nothing, or carry an installed skill that never gets suggested.

## Run it

```bash
dev skills                 # human-readable report (advisory, exits 0)
dev skills --strict        # exit 1 when broken > 0 or the config is unparseable
dev skills --json          # machine-readable summary (counts + lists)
dev skills --since 90      # look back 90 days for usage evidence (default 30)
dev skills --help          # full flag reference
```

The tool is advisory: it exits `0` no matter what it finds, unless you pass
`--strict`. It is safe to run in CI as a soft signal, or with `--strict` as a
hard gate.

## Interpreting the summary line

Every run ends with:

```
SKILLS AUDIT SUMMARY: installed=N registered=M broken=B unregistered=U oversize=O duplicates=D used_recently=R
```

| Field | Meaning | Action |
|-------|---------|--------|
| `broken` | Registered in `config.json` but no `SKILL.md` on disk | Reinstall the skill, or drop the stale registry entry |
| `unregistered` | `SKILL.md` present but name absent from `config.json` | Register it (keeper) or prune it (dead) |
| `oversize` | A `SKILL.md` longer than 400 lines | Split or trim the file — a real maintenance signal |
| `duplicates` | Same skill name found in more than one location | Remove the redundant copy (often a symlink or stale bundle) |
| `used_recently` | Unregistered skills with recent log mentions | **Keep** these — they are in active use |
| `stale-config` | `config.json` missing or unparseable | Regenerate it by rerunning setup module 53 |

## Workflow

### 1. Register keepers

For every `unregistered` skill that is also `used_recently`, register it into the
auto-skills registry. Either rerun the module to regenerate the config
(`bash setup.sh` runs module 53, or re-trigger `step_auto_skills`), or edit
`~/.config/opencode/auto-skills/config.json` directly and add the slug to the
right `task_triggers[*].skills` / `file_triggers[*].skills` array (or
`default_skills`). Keep the bash trigger tables in `53-auto-skills.sh` in sync.

### 2. Prune dead skills

For `unregistered` skills with **no** `used_recently` evidence, delete the
`SKILL.md` directory. They are carried cost with no suggestion path.

### 3. Fix broken references

For `broken` skills, either install the missing `SKILL.md` or remove the stale
slug from `config.json` so the system stops suggesting what does not exist.

### 4. Split oversize skills

For `oversize` skills, split the `SKILL.md` into focused skills or trim the
instructions. Oversized files slow the agent and dilute the trigger signal.

## Flags

| Flag | Effect |
|------|--------|
| `--json` | Emit a JSON object with counts and name lists (assembled via `python3`) |
| `--strict` | Exit `1` when `broken > 0` or `stale-config` |
| `--since N` | Look back `N` days for usage evidence (default 30) |
| `--help` | Print usage and exit |

## Environment overrides

- `OPENCODE_SKILLS_DIR` — where installed skills are scanned.
- `AUTO_SKILLS_CONFIG` — path to the auto-skills `config.json`.
- `OPENCODE_LOG_DIR` — where `*.log` files live for usage evidence
  (`$HOME/.local/share/opencode/log` by default).
