# State Detection and Port-Conflict Resolution

`dev state` and the pre-flight port-conflict check in `setup.sh --with-all-infra` are
two halves of one idea: **detect the existing machine state before changing it**.

## Why this exists

The setup script was originally written to *install* an AI dev machine from a clean
state. On a clean host, that is the right thing to do. On a host that already has
services (Postgres, Redis, Qdrant, etc.) — perhaps from a sibling project's
`docker compose`, perhaps from a previous OpenCode install — the script silently
collides on the first host port it tries to bind. The collision is swallowed by
`2>/dev/null` in the bring-up step, and the container is left in `Created` state
forever. `docker ps` shows it; `docker logs` is empty; nothing points to the cause.

`dev state` is the read side: print everything the script cares about, and exit
non-zero on drift. The pre-flight in `30-infra.sh` is the write side: refuse to
start a container whose host port is already bound, and propose a shifted port.

## What `dev state` reports

Four sections, exit code 0 informational / 1 with `--strict` on drift.

```
── Tools ────────────────────────────────────
  PRESENT  docker       /usr/bin/docker
  PRESENT  bash         /usr/bin/bash
  PRESENT  git          /usr/bin/git
  ...

── Config files ─────────────────────────────
  PRESENT  /home/.../.config/opencode/opencode.json
  PRESENT  /home/.../.config/opencode/infra.yml
  PRESENT  /home/.../.config/opencode/secrets.env
  PRESENT  /home/.../.config/opencode-setup/setup.conf
  PRESENT  /home/.../.config/opencode/.goal-mode-manifest.json

── OpenCode docker services ────────────────
  RUNNING  opencode-postgres
  STOPPED  opencode-qdrant (created)
  STOPPED  opencode-redis (created)
  RUNNING  opencode-prometheus
  RUNNING  opencode-grafana
  ABSENT   opencode-node_exporter (no container)
  RUNNING  opencode-memorylayer

── Listening ports (canonical defaults) ─────
  BOUND    postgres        :5432  by opencode-postgres
  BOUND    qdrant          :6333  by rag-qdrant
  BOUND    redis           :6379  by rag-redis
  BOUND    prometheus      :9090  by opencode-prometheus
  ...

total=35  fails=3  strict=0
```

Each `BOUND` entry names the owning docker container (or `pid/NNN` for non-docker
listeners, or `<unknown>` if neither lookup succeeded). Use this to tell which
sibling project is squatting a canonical opencode port.

## How port-collision resolution works

When `setup.sh --with-all-infra` (or any mode that triggers `30-infra.sh`) is run,
the pre-flight block walks the list of enabled services and checks each host bind
port against the live `ss`/`lsof`/`/proc/net/tcp` table.

For each collision:

1. The owning container / process is identified (the same lookup `dev state` uses).
2. A shifted port is computed by `_find_free_port` — it bumps by 10 000 above the
   default and walks forward up to 50 candidates until it finds an unoccupied
   one. (`REDIS_PORT=16380`, `QDRANT_PORT=16333`, etc. on a host with rag-redis /
   rag-qdrant.)
3. The shifted port is persisted to `~/.config/opencode-setup/setup.conf` via
   `_set_config`. On the next run, the env-var precedence picks it up automatically.
4. The next `docker compose up` uses the shifted port.

The collision is logged as a warning, not an error. The shift is automatic but
auditable: `cat ~/.config/opencode-setup/setup.conf` shows what changed.

## What is and is not detected

| Detected | Not detected |
|---|---|
| Ports already bound by any docker container | Ports held by a process not visible to `ss`/`lsof` (rare — typically kernel listeners) |
| Ports held by `network_mode: host` services (no docker-proxy) via `docker ps -a` | Container name when the container is removed but the port is still in TIME_WAIT |
| Created/Exited containers (with `(Created/Exited)` annotation) | Container-to-port relationships when the docker daemon is unreachable |
| `pid/NNN` for non-docker listeners via `lsof -iTCP:PORT` fallback | The PID of the listener when invoked without root (no `pid=` column from `ss`) |

## Idempotency contract

Running `setup.sh --with-all-infra` twice in a row must not change anything on the
second run. Concretely:

- A container already in `RUNNING` state is skipped — no `docker compose up` for it.
- A port already shifted (recorded in `setup.conf`) is reused; the bump math does
  not re-run.
- A missing config file in `~/.config/opencode/` triggers an install; a present one
  with identical content is skipped (`bash -n` is the cheapest sanity check).

`dev state --strict` is the scriptable check for "is anything drifted from the
last known good state?". CI / crontab can run it periodically.

## When to use it

- **Before `setup.sh --with-all-infra`** — see what is already there, decide
  whether to add opencode services alongside or replace the existing ones.
- **After editing `~/.config/opencode/opencode.json` by hand** — verify nothing
  drifted (e.g., the `opencode-context` regression discussed in `audit/2026-08-08/`).
- **In incident response** — when an opencode service fails to start, the first
  step is `dev state --strict` to see which canonical port is held by whom.

## Diff-before-write for `opencode.json`

`src/lib/18-opencode-json.sh` now follows the same idempotency contract as the
port pre-flight:

1. **SHA-256 the proposed output** (with header + canonical `json.dumps`).
2. **Compare against the on-disk file**. If equal → emit `UNCHANGED:<hash>`
   to stderr and skip the write.
3. **If different** → emit a unified diff (with secret-masking) to stderr.
4. **If `DRY_RUN=1`** → also print the proposed JSON to stdout, skip the write.

This means a second `setup.sh --fix-config` after a successful run is now a
no-op (zero byte writes, zero mtime changes) — the same guarantee the port
pre-flight gives for `infra.yml`.

The diff also masks secrets. Three patterns are redacted with `<REDACTED:ENV>`:

- `apiKey: "sk-..."` / `apiKey: "xai-..."` / `apiKey: "tp-..."` / `apiKey: "dtn_..."`
  / `apiKey: "github_pat_..."` (and the JSON-style `"apiKey": "..."`)
- `password: "..."` / `token: "..."` / `secret: "..."` with the same prefixes
- The pre-existing bug at line 318 (the literal `GITHUB_PERSONAL_ACCESS_TOKEN`
  was being written to disk in the `gh_entry["env"]` map) is now also masked,
  so leaking the PAT via `--diff-only` is impossible.

To inspect the proposed `opencode.json` without writing:

```bash
DRY_RUN=1 bash ./setup.sh --fix-config
```

To see what the generator wants to change without applying:

```bash
DRY_RUN=1 bash ./dev.sh state --strict # broader view
# For the JSON specifically, the easiest path is to modify ~/.config/opencode/opencode.json
# and run setup.sh --fix-config; the diff is emitted to stderr.
```

The determinism fix at line 845 (sorting `task_profiles[].mcp` and `disabled`)
ensures two consecutive runs produce byte-identical output — required for the
hash comparison to ever report `UNCHANGED`.

## Config-file input (TOML)

Instead of passing dozens of CLI flags, you can declare your configuration in a
TOML file and pass it with `--config`:

```bash
bash setup.sh --config setup.toml --dry-run
```

### Precedence

Configuration values are resolved in this order (highest wins):

1. **CLI flags** — `--deepseek-key`, `--with-postgres`, etc.
2. **Environment variables** — `DEEPSEEK_KEY`, `INFRA_SERVICES`, etc.
3. **TOML file** — values from `--config setup.toml`
4. **Defaults** — hardcoded in `00-core.sh`

### Creating a config file

Copy the template and uncomment the values you want:

```bash
cp setup.toml.template setup.toml
# Edit setup.toml with your values
```

The template documents every available option with its default value.

### TOML structure

```toml
[meta]
profile = "corporate"           # personal | corporate | airgapped | hybrid

[user]
git_name = "Your Name"
git_email = "you@example.com"
project_dir = "~/projects"

[features]
isolated_circuit = true          # Local LLM only

[features.skip]
devbox = true                    # Skip Devbox (Nix-based)

[services]
postgres = true                  # Enable PostgreSQL
redis = true                     # Enable Redis

[ports]
postgres = 5433                  # Override default port

[providers]
deepseek_key = "sk-..."         # API key (prefer env vars for secrets)

[tools]
node_ver = "22"                  # Override pinned version
```

### Inspecting resolved values

Use `--print-config` to see what the script would use:

```bash
bash setup.sh --config setup.toml --print-config
```

Or from the dev CLI:

```bash
dev config-from setup.toml
```
