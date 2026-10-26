# Agentic stack services

Local Docker services that back the `qdrant` and `postgres` MCP servers. Everything
binds to `127.0.0.1`, drops capabilities and caps CPU/RAM.

| Service | Image | Host endpoint | Purpose |
|---|---|---|---|
| qdrant | `qdrant/qdrant:v1.20.0` | `http://127.0.0.1:6333` | vectors for memory/RAG/codegraph |
| postgres | `postgres:17-alpine` | `postgresql://opencode:opencode@127.0.0.1:5432/opencode` | relational store |
| redis | `redis:7-alpine` | `redis://127.0.0.1:6379/0` | cache/sessions |
| memorylayer | `scitrera/memorylayer-server:latest` | `http://127.0.0.1:61001` | Muninn-style memory server |
| chromadb | `chromadb/chroma:1.0.15` | `http://127.0.0.1:8000` | optional RAG backend (`--profile extras`) |

## Usage

```bash
bash scripts/stack.sh status      # health table (works with adopted containers too)
bash scripts/stack.sh check       # exit 1 if a required service is down
bash scripts/stack.sh up          # start (compose if absent, `docker start` if adopted)
bash scripts/stack.sh down
bash scripts/stack.sh env         # connection URLs used by the MCP servers
bash scripts/stack.sh logs qdrant
```

Or drive compose directly:

```bash
cd deploy/agentic-stack
docker compose up -d                 # qdrant + postgres + redis + memorylayer
docker compose --profile extras up -d  # adds chromadb
```

## How this machine is wired

The MCP servers in `~/.config/opencode/opencode.json` (rendered from
`src/data/opencode.global.template.json`) use these endpoints:

- `qdrant` → `mcp-server-qdrant`, `QDRANT_URL=http://127.0.0.1:6333`,
  collection `opencode-memory`
- `postgres` → `@modelcontextprotocol/server-postgres` against the URL above
- `codegraph` → `@colbymchenry/codegraph serve --mcp` (local CLI, no container)

## Adopted vs compose mode

This machine already runs containers created by an earlier setup run
(`opencode-qdrant`, `opencode-postgres`, `opencode-redis`, `opencode-memorylayer`,
`opencode-grafana`). `scripts/stack.sh` detects them and manages them by name, so no
data is recreated. On a clean machine the same commands fall back to `docker compose`.

If you prefer compose to own the containers, stop and remove the legacy ones first
(volumes are project-scoped named volumes, not the bind mounts used here):

```bash
docker rm -f opencode-qdrant opencode-postgres opencode-redis opencode-memorylayer
cd deploy/agentic-stack && docker compose up -d
```

## Security notes

- `security_opt: no-new-privileges`, `deploy.resources.limits`, log rotation.
- No service is published beyond loopback.
- Credentials come from `.env` (copy `.env.example`); change the default password
  before putting anything real in the database.
