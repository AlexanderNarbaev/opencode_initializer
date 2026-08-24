# Context Budget

`dev context` reports how full each OpenCode session's context window is, measured
against the **model's own maximum** — not a generic cap.

## Why this exists

Two layers already watch the context window at runtime:

- `opencode-context-watch` warns when the window crosses a usage threshold.
- `opencode-context-compress` (and `@skybluejacket/opencode-context-compress`)
  prune/compress when the window gets crowded.

Those plugins work from provider-reported usage and a fixed threshold. What they
cannot do is answer "how full is this session relative to *this model's* ceiling?"
A 350k-token session is nothing for a 1M-token model, but it is an emergency for a
131k-token local model. The initializer owns the model-limits registry
(`src/data/routing.json` → `cost_table[].context`), so it also owns the report:

- **Model limits SSOT** — one place lists every model's context window.
- **Offline report** — review usage without a running session, from stored state.
- **Consistent thresholds** — the same WARN/ACT numbers the plugins use.

## How it reads the registry

The tool never copies model numbers into code. It reads `cost_table` from
`routing.json` at runtime. Each entry maps a model key (e.g.
`deepseek/deepseek-v4-pro`) to `{ input, output, context, free }`. `context` is the
window size in tokens.

Session records are matched to a registry key by containment, case-insensitive:
a session id `deepseek-v4-pro` matches the key `deepseek/deepseek-v4-pro`, and vice
versa. A session whose model cannot be matched is shown with `limit=?` and status
`UNKNOWN` — it is reported, not dropped.

## Usage

```bash
dev context models           # table of known models + context windows
dev context status           # scan sessions, report usage vs model limit
dev context check --strict   # status, exit 1 if any session is at ACT level
dev context status --json    # machine-readable output
```

### `models`

```text
model                                         context  note
deepseek/deepseek-v4-pro                      1000000  free
deepseek/deepseek-v4-flash                    1000000  free
zai/glm-5-turbo                                200000  paid
ollama/qwen3:32b                               131072  free · local
```

### `status`

```text
session                          model                      used     limit     pct  status
ses_ab12cd                        deepseek/deepseek-v4-pro  950000  1000000   95.0  ACT
ses_ef34gh                        zai/glm-5.2                610000  1000000   61.0  OK
ses_ij56kl                        mystery-model-1            50000        ?      ?  UNKNOWN
warn=0.77 act=0.9  act_sessions=1 warn_sessions=0
```

`status` is advisory: it always exits `0`. `check --strict` is the CI/script form —
it exits `1` when any session is at `ACT` level, `0` otherwise.

## Threshold semantics

| Level | Default | Meaning |
|-------|---------|---------|
| `OK` | below 77% | room to spare |
| `WARN` | 77% | compression should already have fired |
| `ACT` | 90% | practical ceiling — beyond this the model degrades or drops context |

The numbers are industry convergence, not invention: warn thresholds cluster around
75–77%, the act ceiling around 90%, and an absolute token cap around 350k is a
separate plugin concern (a 1M-token model can hold 350k; a 131k-token model cannot).
WARN and ACT are deliberately spread apart (77 → 90) to give a hysteresis band:
compression triggers at WARN and only escalates to a hard alarm at ACT, so a session
does not flap between states at the boundary.

## Tuning

Thresholds live in `~/.config/opencode/context-guard.json` under the `budget` block,
written by module `57-context-guard`:

```json
{
  "version": 1,
  "managed_by": "opencode_initializer@57-context-guard",
  "compress": { "enabled": true, "auto": true },
  "watch": { "threshold": 0.85 },
  "budget": { "warn_percent": 0.77, "act_percent": 0.90 }
}
```

Edit `budget.warn_percent` / `budget.act_percent` and rerun `dev context status`.
The tool reads this file; it never writes it. If the block is absent, it falls back
to `watch.warn_percent`, then `watch.threshold`, then the built-in defaults.

## Integration

- Session state is read from `$HOME/.local/share/opencode/storage/session` (with a
  `storage/` fallback), newest files first, capped at 20. Malformed files are
  skipped silently.
- `ROUTING_JSON` overrides the registry path; `--json` emits
  `{ sessions, warn_percent, act_percent, act_count, warn_count }` for scripts.
- `dev context` is registered alongside `dev skills` and the other post-install
  commands; `health` verifies the tool compiles via `py_compile`.
