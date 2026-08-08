#!/usr/bin/env bash
# Test 33-services.sh — Unified Service Configuration Layer
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
TESTS_PASS=0; TESTS_FAIL=0
TMP_DIR=$(mktemp -d)
trap 'rm -rf "$TMP_DIR"' EXIT

assert() {
  local desc="$1" condition="$2"
  if (eval "$condition") &>/dev/null; then TESTS_PASS=$((TESTS_PASS + 1)); else TESTS_FAIL=$((TESTS_FAIL + 1)); echo "    FAIL: $desc" >&2; fi
}

# ── Static analysis ──────────────────────────────────────────────────────
S="$PROJECT_DIR/src/lib/33-services.sh"
assert "33-services.sh exists" "[ -f '$S' ]"
assert "33-services.sh syntax" "bash -n '$S'"
assert "has Service Configuration" "grep -q 'Service Configuration' '$S'"
assert "has deployment profile" "grep -q 'DEPLOYMENT_PROFILE' '$S'"
assert "has service mode" "grep -q '_service_mode' '$S'"
assert "has port resolution" "grep -q '_resolve_service_port' '$S'"
assert "has disabled mode" "grep -q 'disabled' '$S'"
assert "has external mode" "grep -q 'external' '$S'"
assert "has local mode" "grep -q 'local' '$S'"
assert "has _set_config" "grep -q '_set_config' '$S'"
assert "has step_services" "grep -q 'step_services' '$S'"
assert "no local in loop" "! grep -E '^[[:space:]]+local ' '$S'"

# ── Integration with 00-core.sh ──────────────────────────────────────────
CORE="$PROJECT_DIR/src/lib/00-core.sh"
assert "00-core has _port_is_free" "grep -q '_port_is_free' '$CORE'"
assert "00-core has _find_free_port" "grep -q '_find_free_port' '$CORE'"
assert "00-core has _resolve_service_port" "grep -q '_resolve_service_port' '$CORE'"
assert "00-core has _service_mode" "grep -q '_service_mode' '$CORE'"
assert "00-core has _set_config" "grep -q '_set_config' '$CORE'"
assert "00-core has _get_service_port" "grep -q '_get_service_port' '$CORE'"
assert "00-core has DEPLOYMENT_PROFILE" "grep -q 'DEPLOYMENT_PROFILE' '$CORE'"

# ── Verify _get_service_port covers key services ─────────────────────────
for svc in postgres qdrant redis prometheus grafana node_exporter metrics_exporter gui ollama; do
  assert "_get_service_port has $svc" "grep -q '${svc})' '$CORE'"
done
assert "_get_service_port qdrant=6333" "grep -A1 'qdrant)' '$CORE' | grep -q 6333"
assert "_get_service_port postgres=5432" "grep -A1 'postgres)' '$CORE' | grep -q 5432"

# ── 33-services is a standalone module used by dev.sh CLI ──────────────────
DEV="$PROJECT_DIR/dev.sh"
assert "dev.sh has service management" "grep -q 'cmd_metrics\|cmd_observability\|_service_mode' '$DEV' || grep -q 'services' '$DEV'"

echo "test_services: $TESTS_PASS passed, $TESTS_FAIL failed"
[ "$TESTS_FAIL" -eq 0 ] || exit 1
