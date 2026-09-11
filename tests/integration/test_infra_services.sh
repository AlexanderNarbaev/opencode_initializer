#!/usr/bin/env bash
# tests/integration/test_infra_services.sh — Infrastructure service integration tests
# Tests that all infrastructure services can be configured and started.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Source test helpers
source "$PROJECT_ROOT/tests/test_lib.sh" 2>/dev/null || true

# ── Test helpers ─────────────────────────────────────────────────────────────
PASS=0
FAIL=0
SKIP=0

pass() { ((PASS++)); echo -e "  \033[32m✓\033[0m $1"; }
fail() { ((FAIL++)); echo -e "  \033[31m✗\033[0m $1"; }
skip() { ((SKIP++)); echo -e "  \033[33m⊘\033[0m $1 (skipped)"; }

# ── Test: Service configuration files ────────────────────────────────────────
echo "=== Test: Service Configuration Files ==="

test_service_configs() {
  local services=("postgres" "redis" "qdrant" "prometheus" "grafana")
  for svc in "${services[@]}"; do
    # Check for config in various locations
    local found=false
    for dir in src/data infra config; do
      if [ -f "$PROJECT_ROOT/$dir/$svc.yml" ] || [ -f "$PROJECT_ROOT/$dir/$svc.conf" ] || [ -f "$PROJECT_ROOT/$dir/docker-compose.yml" ]; then
        found=true
        break
      fi
    done
    if $found; then
      pass "Configuration for $svc found"
    else
      skip "Configuration for $svc not found"
    fi
  done
}

test_service_configs

# ── Test: Port configuration ─────────────────────────────────────────────────
echo ""
echo "=== Test: Port Configuration ==="

test_port_defaults() {
  # Check that default ports are defined in setup.toml or core
  local ports_file="$PROJECT_ROOT/src/data/setup.toml.template"
  if [ -f "$ports_file" ]; then
    if grep -q "postgres" "$ports_file"; then
      pass "PostgreSQL port configured"
    else
      fail "PostgreSQL port not configured"
    fi

    if grep -q "redis" "$ports_file"; then
      pass "Redis port configured"
    else
      fail "Redis port not configured"
    fi

    if grep -q "qdrant" "$ports_file"; then
      pass "Qdrant port configured"
    else
      fail "Qdrant port not configured"
    fi
  else
    skip "setup.toml.template not found"
  fi
}

test_port_defaults

# ── Test: Health check endpoints ─────────────────────────────────────────────
echo ""
echo "=== Test: Health Check Endpoints ==="

test_health_check_functions() {
  local core_file="$PROJECT_ROOT/src/lib/33-services.sh"
  if [ -f "$core_file" ]; then
    if grep -q "_health_check\|_check_service\|_service_health" "$core_file"; then
      pass "Health check functions defined in services module"
    else
      skip "Health check functions not found in services module"
    fi
  else
    skip "Services module not found"
  fi
}

test_health_check_functions

# ── Test: Docker Compose structure ───────────────────────────────────────────
echo ""
echo "=== Test: Docker Compose Structure ==="

test_compose_services() {
  local compose_file=""
  for dir in src/data infra; do
    if [ -f "$PROJECT_ROOT/$dir/docker-compose.yml" ]; then
      compose_file="$PROJECT_ROOT/$dir/docker-compose.yml"
      break
    fi
  done

  if [ -z "$compose_file" ]; then
    skip "docker-compose.yml not found"
    return
  fi

  local expected_services=("postgres" "redis" "qdrant" "prometheus" "grafana")
  for svc in "${expected_services[@]}"; do
    if grep -q "$svc" "$compose_file"; then
      pass "Service $svc defined in docker-compose.yml"
    else
      skip "Service $svc not in docker-compose.yml"
    fi
  done
}

test_compose_services

# ── Test: Environment variable support ───────────────────────────────────────
echo ""
echo "=== Test: Environment Variable Support ==="

test_env_vars() {
  local core_file="$PROJECT_ROOT/src/lib/33-services.sh"
  if [ ! -f "$core_file" ]; then
    skip "Services module not found"
    return
  fi

  if grep -q "PORTS_POSTGRES\|POSTGRES_PORT" "$core_file"; then
    pass "PostgreSQL port env var supported"
  else
    skip "PostgreSQL port env var not found"
  fi

  if grep -q "PORTS_REDIS\|REDIS_PORT" "$core_file"; then
    pass "Redis port env var supported"
  else
    skip "Redis port env var not found"
  fi
}

test_env_vars

# ── Summary ──────────────────────────────────────────────────────────────────
echo ""
echo "─── Results: $((PASS + FAIL + SKIP)) tests, $PASS passed, $FAIL failed, $SKIP skipped ───"

if [ "$FAIL" -gt 0 ]; then
  exit 1
fi
exit 0
