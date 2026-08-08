# Audit: Infrastructure & Services Layer (T1.3)

> **Scope:** 30-infra.sh, 33-services.sh, 34-observability.sh, 21-rag.sh, 24-websearch.sh
> **Date:** 2026-08-08 | **Auditor:** Planner

---

## Summary

11 findings (2 CRITICAL, 3 HIGH, 4 MEDIUM, 2 LOW). The infrastructure layer is functionally solid (port-based service resolution, multi-profile support, comprehensive observability) but has significant security gaps: 2 containers run in `host` network mode, default passwords are weak, and qdrant is wide-open on localhost.

---

## Findings

### F3.1 — MemoryLayer: network_mode=host + user=root (CRITICAL)

| Attribute | Value |
|-----------|-------|
| **Severity** | CRITICAL |
| **File** | `src/lib/30-infra.sh:201-207` |
| **Category** | Security / Container Isolation |

MemoryLayer container runs with `network_mode: host` AND `user: root`. This grants the container **full host network access** and **root-level filesystem access**. If memorylayer-server is compromised, the attacker gets unrestricted access to the host.

```yaml
# src/lib/30-infra.sh:201-207
memorylayer:
  image: scitrera/memorylayer-server:latest
  container_name: opencode-memorylayer
  network_mode: host    # ← bypasses all Docker network isolation
  user: root            # ← full root on the host
```

**Recommendation:** Bind to specific ports (`127.0.0.1:61001:61001`) instead of `network_mode: host`. Remove `user: root`. If host networking is required for performance, add a dedicated `docker0` bridge and bind to that.

---

### F3.2 — Node Exporter: network_mode=host + pid=host (CRITICAL)

| Attribute | Value |
|-----------|-------|
| **Severity** | CRITICAL |
| **File** | `src/lib/30-infra.sh:187-196` |
| **Category** | Security / Container Isolation |

Node Exporter has `network_mode: host` and `pid: host` with `/:/host:ro` bind mount. While read-only, this exposes **all host processes and filesystem** to the container. In a corporate deployment, this is a data leak vector.

```yaml
node_exporter:
  network_mode: host   # ← full host network
  pid: host            # ← sees all host processes
  volumes:
    - '/:/host:ro,rslave'  # ← entire filesystem
```

**Recommendation:** For corporate/air-gap profiles, gate node_exporter behind a deployment profile check (`if [ "$DEPLOYMENT_PROFILE" != "airgapped" ]`). Add `--collector.disable-defaults --collector.cpu --collector.meminfo` to limit metric surface.

---

### F3.3 — Hardcoded Default Passwords (HIGH)

| Attribute | Value |
|-----------|-------|
| **Severity** | HIGH |
| **Files** | `30-infra.sh`, `34-observability.sh` |
| **Category** | Security / Credentials |

| Service | Default Password | Location |
|---------|-----------------|----------|
| PostgreSQL | `opencode_dev` | `30-infra.sh:80` |
| Neo4j | `opencode_dev` | `30-infra.sh:131` |
| MinIO | `minioadmin` | `30-infra.sh:146` |
| Grafana | `admin` | `34-observability.sh:113` |

All defaults are well-known and easily guessable. The env-var override mechanism (`${PG_PASSWORD:-opencode_dev}`) exists but defaults are weak.

**Recommendation:** Replace static defaults with auto-generated passwords stored in `secrets.env`:

```bash
PG_PASSWORD="${PG_PASSWORD:-$(openssl rand -hex 16)}"
echo "PG_PASSWORD=$PG_PASSWORD" >> "$SECRETS_FILE"
```

---

### F3.4 — Prometheus Config: sed-based Injection (HIGH)

| Attribute | Value |
|-----------|-------|
| **Severity** | HIGH |
| **File** | `src/lib/34-observability.sh:91-130` |
| **Category** | Reliability / Correctness |

Uses `sed -i '/^services:/a\...'` with multi-line backslash-continued insert. If `infra.yml` has indentation differences or the `services:` line is missing, the sed command silently corrupts the file.

```bash
sed -i '/^services:/a\
\
  prometheus:\           # ← 2-space indent hardcoded
    image: prom/...
```

**Recommendation:** Regenerate the entire `infra.yml` instead of sed-patching. If patching is required, use `yq` (YAML-aware) or at minimum validate the result with `docker compose -f "$INFRA_CONFIG" config --quiet`.

---

### F3.5 — Docker Host IP Detection Fragile (HIGH)

| Attribute | Value |
|-----------|-------|
| **Severity** | HIGH |
| **File** | `src/lib/34-observability.sh:58` |
| **Category** | Reliability |

```bash
DOCKER_HOST=$(ip -4 addr show docker0 2>/dev/null | grep -oE 'inet [0-9.]+' | awk '{print $2}' || echo "host.docker.internal")
```

Silent fallback to `"host.docker.internal"` which only works on Mac/Windows Docker Desktop — **not on Linux**. On Linux, Prometheus scrape targets will fail silently.

**Recommendation:** Explicitly detect OS and use correct host resolution:
- Linux: `ip addr show docker0` or `hostname -I | awk '{print $1}'`
- macOS: `host.docker.internal`
- If detection fails, WARN and skip Prometheus generation.

---

### F3.6 — Qdrant: No Authentication (MEDIUM)

| Attribute | Value |
|-----------|-------|
| **Severity** | MEDIUM |
| **File** | `src/lib/21-rag.sh:36-38`, `30-infra.sh:88-94` |
| **Category** | Security / Access Control |

Qdrant container has no API key. curl calls to Qdrant have no authentication headers. Any process on localhost can read/create/delete all collections.

```bash
curl -s -X PUT "$QDRANT_URL/collections/rag_documents"  # no auth header
```

**Recommendation:** Enable Qdrant API key in docker-compose:

```yaml
qdrant:
  environment:
    QDRANT__SERVICE__API_KEY: ${QDRANT_API_KEY:-}
```

Pass the key in all curl calls: `-H "api-key: $QDRANT_API_KEY"`.

---

### F3.7 — RAG pip installs swallow errors (MEDIUM)

| Attribute | Value |
|-----------|-------|
| **Severity** | MEDIUM |
| **File** | `src/lib/21-rag.sh:22,27` |
| **Category** | Reliability |

```bash
pip install -r "$RAG_DIR/etl/requirements_etl.txt" 2>/dev/null && log "RAG ETL deps" || warn "RAG ETL deps failed"
```

`2>/dev/null` hides all pip errors. If a critical dependency fails to compile, the user gets "failed" but no actionable error message.

**Recommendation:** Capture stderr to a temp log and include in the warning:

```bash
pip install ... 2>/tmp/rag-pip-err.log && log "RAG ETL deps" || warn "RAG ETL deps failed — see /tmp/rag-pip-err.log"
```

---

### F3.8 — SearXNG Managed Outside Docker Compose (MEDIUM)

| Attribute | Value |
|-----------|-------|
| **Severity** | MEDIUM |
| **File** | `src/lib/24-websearch.sh:72-78` |
| **Category** | Maintainability |

SearXNG runs via `docker run -d` with `--restart unless-stopped`, while all other services use `docker compose` via `infra.yml`. This creates a split management surface.

**Recommendation:** Add SearXNG to `infra.yml` generation (30-infra.sh). Remove `docker run` from 24-websearch.sh.

---

### F3.9 — setup.conf Re-sourced Inside Loop (MEDIUM)

| Attribute | Value |
|-----------|-------|
| **Severity** | MEDIUM |
| **File** | `src/lib/33-services.sh:30` |
| **Category** | Correctness |

```bash
for svc in "${!SERVICE_PORTS[@]}"; do
  ...
  if [ -f "$SETUP_CONF" ]; then
    . "$SETUP_CONF" 2>/dev/null  # ← re-sourced on every iteration
  fi
```

Sources the same config file inside the loop, potentially re-reading hundreds of lines on each service iteration.

**Recommendation:** Source once before the loop, or cache values in local variables.

---

### F3.10 — No Docker Health Checks (LOW)

| Attribute | Value |
|-----------|-------|
| **Severity** | LOW |
| **File** | `src/lib/30-infra.sh` (all containers) |
| **Category** | Reliability |

None of the 10 Docker services define `healthcheck:` blocks. Docker Compose `--wait` relies on health checks. Currently `30-infra.sh:254` uses `docker compose up -d --wait` which will timeout on services without health checks.

**Recommendation:** Add health checks:

```yaml
postgres:
  healthcheck:
    test: ["CMD-SHELL", "pg_isready -U opencode"]
    interval: 10s
    retries: 5
```

---

### F3.11 — Sanitizer Proxy: No Log Rotation (LOW)

| Attribute | Value |
|-----------|-------|
| **Severity** | LOW |
| **File** | `src/lib/24-websearch.sh:134` |
| **Category** | Maintainability |

Sanitizer appends to `~/.cache/opencode-setup/sanitizer.log` without rotation. In an active air-gapped deployment, this could grow large.

**Recommendation:** Use Python's `RotatingFileHandler` or add a logrotate snippet.

---

## Recommendations Priority

| Priority | Finding | Effort |
|----------|---------|--------|
| P0 | F3.1 — Remove `network_mode: host` + `user: root` from MemoryLayer | S |
| P0 | F3.3 — Auto-generate passwords to secrets.env | M |
| P1 | F3.2 — Gate node_exporter behind deployment profile | S |
| P1 | F3.5 — Fix Linux docker0 IP detection | S |
| P1 | F3.6 — Enable Qdrant API key auth | S |
| P2 | F3.4 — Replace sed patch with yq or full regenerate | M |
| P2 | F3.8 — Move SearXNG to docker-compose | M |
| P2 | F3.9 — Fix setup.conf re-source in loop | S |
| P3 | F3.7 — Capture pip errors to log | S |
| P3 | F3.10 — Add Docker health checks | M |
| P3 | F3.11 — Add log rotation for sanitizer | S |
