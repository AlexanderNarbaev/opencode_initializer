#!/usr/bin/env bash
# tests/integration/test_containers.sh — Docker container integration tests
# Tests that infrastructure services start and respond correctly.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# ── Test helpers ─────────────────────────────────────────────────────────────
PASS=0
FAIL=0
SKIP=0

pass() { PASS=$((PASS + 1)); echo -e "  \033[32m✓\033[0m $1"; }
fail() { FAIL=$((FAIL + 1)); echo -e "  \033[31m✗\033[0m $1"; }
skip() { SKIP=$((SKIP + 1)); echo -e "  \033[33m⊘\033[0m $1 (skipped)"; }

# ── Check Docker availability ────────────────────────────────────────────────
if ! command -v docker &>/dev/null; then
  echo "Docker not available — skipping container tests"
  exit 0
fi

if ! docker info &>/dev/null; then
  echo "Docker daemon not running — skipping container tests"
  exit 0
fi

# Skip container tests in CI (Docker-in-Docker not available)
if [ "${CI:-false}" = "true" ] || [ "${GITHUB_ACTIONS:-false}" = "true" ]; then
  echo "Running in CI — skipping container tests"
  exit 0
fi

# ── Test: PostgreSQL container ───────────────────────────────────────────────
echo "=== Test: PostgreSQL Container ==="

test_postgres_start() {
  local container_name="test-postgres-$$"
  docker run -d --name "$container_name" \
    -e POSTGRES_PASSWORD=testpass \
    -p 15432:5432 \
    postgres:17-alpine &>/dev/null

  # Wait for PostgreSQL to be ready
  local attempts=0
  while [ $attempts -lt 30 ]; do
    if docker exec "$container_name" pg_isready -U postgres &>/dev/null; then
      break
    fi
    sleep 1
    ((attempts++))
  done

  if docker exec "$container_name" pg_isready -U postgres &>/dev/null; then
    pass "PostgreSQL container starts and accepts connections"
  else
    fail "PostgreSQL container failed to start"
  fi

  docker rm -f "$container_name" &>/dev/null || true
}

test_postgres_connection() {
  local container_name="test-postgres-conn-$$"
  docker run -d --name "$container_name" \
    -e POSTGRES_PASSWORD=testpass \
    -p 15433:5432 \
    postgres:17-alpine &>/dev/null

  sleep 5

  # Test connection via psql
  if docker exec "$container_name" psql -U postgres -c "SELECT 1;" &>/dev/null; then
    pass "PostgreSQL accepts SQL queries"
  else
    fail "PostgreSQL rejected SQL queries"
  fi

  docker rm -f "$container_name" &>/dev/null || true
}

test_postgres_start
test_postgres_connection

# ── Test: Redis container ────────────────────────────────────────────────────
echo ""
echo "=== Test: Redis Container ==="

test_redis_start() {
  local container_name="test-redis-$$"
  docker run -d --name "$container_name" \
    -p 16379:6379 \
    redis:7-alpine &>/dev/null

  sleep 2

  if docker exec "$container_name" redis-cli ping | grep -q "PONG"; then
    pass "Redis container starts and responds to PING"
  else
    fail "Redis container failed to respond"
  fi

  docker rm -f "$container_name" &>/dev/null || true
}

test_redis_set_get() {
  local container_name="test-redis-setget-$$"
  docker run -d --name "$container_name" \
    -p 16380:6379 \
    redis:7-alpine &>/dev/null

  sleep 2

  docker exec "$container_name" redis-cli SET testkey testvalue &>/dev/null
  local result
  result=$(docker exec "$container_name" redis-cli GET testkey 2>/dev/null)

  if [ "$result" = "testvalue" ]; then
    pass "Redis SET/GET works correctly"
  else
    fail "Redis SET/GET returned unexpected value: $result"
  fi

  docker rm -f "$container_name" &>/dev/null || true
}

test_redis_start
test_redis_set_get

# ── Test: Qdrant container ───────────────────────────────────────────────────
echo ""
echo "=== Test: Qdrant Container ==="

test_qdrant_start() {
  local container_name="test-qdrant-$$"
  docker run -d --name "$container_name" \
    -p 16333:6333 \
    qdrant/qdrant:latest &>/dev/null

  sleep 5

  if curl -sf http://localhost:16333/healthz &>/dev/null; then
    pass "Qdrant container starts and responds to health check"
  else
    fail "Qdrant container failed to respond"
  fi

  docker rm -f "$container_name" &>/dev/null || true
}

test_qdrant_start

# ── Test: Docker Compose infrastructure ──────────────────────────────────────
echo ""
echo "=== Test: Docker Compose Infrastructure ==="

test_compose_file() {
  local compose_file="$PROJECT_ROOT/src/data/docker-compose.yml"
  if [ -f "$compose_file" ]; then
    pass "docker-compose.yml exists"
  else
    # Check alternative locations
    compose_file="$PROJECT_ROOT/infra/docker-compose.yml"
    if [ -f "$compose_file" ]; then
      pass "docker-compose.yml exists (infra/)"
    else
      skip "docker-compose.yml not found"
    fi
  fi
}

test_compose_validation() {
  local compose_file="$PROJECT_ROOT/src/data/docker-compose.yml"
  if [ ! -f "$compose_file" ]; then
    compose_file="$PROJECT_ROOT/infra/docker-compose.yml"
  fi

  if [ -f "$compose_file" ]; then
    if docker compose -f "$compose_file" config &>/dev/null; then
      pass "docker-compose.yml is valid"
    else
      fail "docker-compose.yml has syntax errors"
    fi
  else
    skip "docker-compose.yml not found"
  fi
}

test_compose_file
test_compose_validation

# ── Summary ──────────────────────────────────────────────────────────────────
echo ""
echo "─── Results: $((PASS + FAIL + SKIP)) tests, $PASS passed, $FAIL failed, $SKIP skipped ───"

if [ "$FAIL" -gt 0 ]; then
  exit 1
fi
exit 0
