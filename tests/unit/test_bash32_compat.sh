#!/usr/bin/env bash
# Unit test: S3.4 — bash 3.2 compatibility (all modules clean)
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$(dirname "$SCRIPT_DIR")")"
PASS=0; FAIL=0

echo "=== Testing bash 3.2 compatibility (S3.4) ==="

# ── S3.4.1: All modules pass bash -n ───────────────────────────────────────
echo "  S3.4.1: bash -n on all modules..."
for f in "$PROJECT_DIR"/src/lib/*.sh "$PROJECT_DIR"/setup.sh; do
  [ -f "$f" ] || continue
  if bash -n "$f" 2>/dev/null; then PASS=$((PASS + 1))
  else echo "    FAIL: bash -n $(basename "$f")" >&2; FAIL=$((FAIL + 1)); fi
done

# ── S3.4.2: Zero declare -A (non-comment) in all modules ──────────────────
echo "  S3.4.2: declare -A audit..."
declare_ok=true
for f in "$PROJECT_DIR"/src/lib/*.sh; do
  [ -f "$f" ] || continue
  if grep -v '^[[:space:]]*#' "$f" | grep -q 'declare -A' 2>/dev/null; then
    echo "    FAIL: $(basename "$f") has non-comment declare -A" >&2
    FAIL=$((FAIL + 1))
    declare_ok=false
  fi
done
if $declare_ok; then
  echo "    PASS: zero declare -A in all modules"
  PASS=$((PASS + 1))
fi

# ── S3.4.2b: Key lookup functions exist ───────────────────────────────────
echo "  S3.4.2b: functional lookups..."
for check in \
  "_get_service_port()" \
  "_mcp_lookup()" \
  "_check_bash_version()" \
  "_provider_reg_get()"; do
  if grep -q "$check" "$PROJECT_DIR/src/lib/00-core.sh" "$PROJECT_DIR/src/lib/26-providers.sh" 2>/dev/null; then
    PASS=$((PASS + 1))
  else
    echo "    FAIL: $check not found" >&2
    FAIL=$((FAIL + 1))
  fi
done

echo "RESULTS: $PASS pass, $FAIL fail"
exit $FAIL
