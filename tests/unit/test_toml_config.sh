#!/usr/bin/env bash
# tests/unit/test_toml_config.sh — TOML config parsing tests
set -euo pipefail

PASS=0; FAIL=0; TOTAL=0
_script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
# shellcheck source=/dev/null
source "$_script_dir/src/lib/helpers.sh"
# shellcheck source=/dev/null
source "$_script_dir/src/lib/00-core.sh"

assert_eq() {
  TOTAL=$((TOTAL + 1))
  local desc="$1" expected="$2" actual="$3"
  if [ "$expected" = "$actual" ]; then
    PASS=$((PASS + 1))
    printf "  ${GREEN}✓${NC} %s\n" "$desc"
  else
    FAIL=$((FAIL + 1))
    printf "  ${RED}✗${NC} %s\n  expected: %s\n  actual:   %s\n" "$desc" "$expected" "$actual"
  fi
}

assert_exit() {
  TOTAL=$((TOTAL + 1))
  local desc="$1" expected="$2" cmd="$3"
  local actual
  actual=0
  eval "$cmd" >/dev/null 2>&1 || actual=$?
  if [ "$expected" = "$actual" ]; then
    PASS=$((PASS + 1))
    printf "  ${GREEN}✓${NC} %s\n" "$desc"
  else
    FAIL=$((FAIL + 1))
    printf "  ${RED}✗${NC} %s\n  expected exit: %s\n  actual exit:   %s\n" "$desc" "$expected" "$actual"
  fi
}

# ── Setup temp TOML file ─────────────────────────────────────────────────────
TMP_DIR=$(mktemp -d)
trap 'rm -rf "$TMP_DIR"' EXIT

cat > "$TMP_DIR/test.toml" <<'TOML'
[meta]
version = "2.0.0"
profile = "corporate"

[user]
git_name = "Test User"
git_email = "test@example.com"
project_dir = "~/my-projects"

[features]
isolated_circuit = true
dry_run = false
parallel_install = true

[features.skip]
devbox = true
caching = false

[services]
postgres = true
redis = true
qdrant = false

[ports]
postgres = 5433
redis = 6380

[providers]
deepseek_key = "sk-test123"
github_token = "ghp_test456"

[tools]
node_ver = "22"
python_ver = "3.13"
TOML

echo "─── TOML Config Tests ───"
echo

# ── Test 1: _toml_get reads scalar values ─────────────────────────────────────
echo "1. _toml_get — scalar value retrieval"
val="$(_toml_get "$TMP_DIR/test.toml" "meta" "version")"
assert_eq "read string value" "2.0.0" "$val"

val="$(_toml_get "$TMP_DIR/test.toml" "user" "git_name")"
assert_eq "read user name" "Test User" "$val"

val="$(_toml_get "$TMP_DIR/test.toml" "ports" "postgres")"
assert_eq "read integer value" "5433" "$val"

# ── Test 2: _toml_get boolean handling ────────────────────────────────────────
echo
echo "2. _toml_get — boolean values"
val="$(_toml_get "$TMP_DIR/test.toml" "features" "isolated_circuit")"
assert_eq "read true boolean" "true" "$val"

val="$(_toml_get "$TMP_DIR/test.toml" "features" "dry_run")"
assert_eq "read false boolean" "false" "$val"

# ── Test 3: _toml_get missing key ─────────────────────────────────────────────
echo
echo "3. _toml_get — missing key"
assert_exit "missing key returns exit 1" "1" '_toml_get "$TMP_DIR/test.toml" "meta" "nonexistent"'
assert_exit "missing section returns exit 1" "1" '_toml_get "$TMP_DIR/test.toml" "nosuch" "key"'
assert_exit "missing file returns exit 1" "1" '_toml_get "/nonexistent.toml" "meta" "version"'

# ── Test 4: _toml_load exports env vars ───────────────────────────────────────
echo
echo "4. _toml_load — export as env vars"
# Reset vars to test TOML loading
unset META_VERSION USER_GIT_NAME FEATURES_ISOLATED_CIRCUIT SERVICES_POSTGRES PORTS_POSTGRES PROVIDERS_DEEPSEEK_KEY TOOLS_NODE_VER 2>/dev/null || true
_toml_load "$TMP_DIR/test.toml"
assert_eq "META_VERSION exported" "2.0.0" "${META_VERSION:-}"
assert_eq "USER_GIT_NAME exported" "Test User" "${USER_GIT_NAME:-}"
assert_eq "FEATURES_ISOLATED_CIRCUIT exported" "true" "${FEATURES_ISOLATED_CIRCUIT:-}"
assert_eq "SERVICES_POSTGRES exported" "true" "${SERVICES_POSTGRES:-}"
assert_eq "PORTS_POSTGRES exported" "5433" "${PORTS_POSTGRES:-}"
assert_eq "PROVIDERS_DEEPSEEK_KEY exported" "sk-test123" "${PROVIDERS_DEEPSEEK_KEY:-}"
assert_eq "TOOLS_NODE_VER exported" "22" "${TOOLS_NODE_VER:-}"

# ── Test 5: _toml_load preserves existing env vars ────────────────────────────
echo
echo "5. _toml_load — precedence (env > toml)"
export META_VERSION="override-value"
_toml_load "$TMP_DIR/test.toml"
assert_eq "existing env var preserved" "override-value" "${META_VERSION:-}"
unset META_VERSION

# ── Test 6: _toml_print_resolved ──────────────────────────────────────────────
echo
echo "6. _toml_print_resolved — output format"
output="$(_toml_print_resolved "$TMP_DIR/test.toml")"
assert_exit "print_resolved succeeds" "0" '_toml_print_resolved "$TMP_DIR/test.toml"'
# Check it contains expected keys
if echo "$output" | grep -q "meta.version = 2.0.0"; then
  PASS=$((PASS + 1)); TOTAL=$((TOTAL + 1))
  printf "  ${GREEN}✓${NC} print_resolved contains meta.version\n"
else
  FAIL=$((FAIL + 1)); TOTAL=$((TOTAL + 1))
  printf "  ${RED}✗${NC} print_resolved missing meta.version\n"
fi

# ── Test 7: nested table (features.skip) ──────────────────────────────────────
echo
echo "7. _toml_get — nested table access"
val="$(_toml_get "$TMP_DIR/test.toml" "features.skip" "devbox")"
assert_eq "nested boolean (features.skip.devbox)" "true" "$val"

val="$(_toml_get "$TMP_DIR/test.toml" "features.skip" "caching")"
assert_eq "nested boolean (features.skip.caching)" "false" "$val"

# ── Summary ───────────────────────────────────────────────────────────────────
echo
echo "─── Results: $PASS/$TOTAL passed, $FAIL failed ───"
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
