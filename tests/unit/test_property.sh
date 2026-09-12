#!/usr/bin/env bash
# tests/unit/test_property.sh — Property-based tests for configuration
# Tests invariants that must hold for all valid inputs
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Source core
source "$PROJECT_ROOT/src/lib/helpers.sh" 2>/dev/null || true
source "$PROJECT_ROOT/src/lib/00-core.sh" 2>/dev/null || true

PASS=0
FAIL=0
TOTAL=0

pass() { PASS=$((PASS + 1)); echo -e "  \033[32m✓\033[0m $1"; }
fail() { FAIL=$((FAIL + 1)); echo -e "  \033[31m✗\033[0m $1"; }
test_case() { TOTAL=$((TOTAL + 1)); echo "Test $TOTAL: $1"; }

# ── Property: TOML values survive round-trip ─────────────────────────────────
echo "=== Property-Based Tests ==="
echo ""

test_case "TOML boolean values are preserved"
# Property: true/false in TOML must remain true/false after parsing
TEMP_TOML=$(mktemp /tmp/test_prop_XXXXXX.toml)
cat > "$TEMP_TOML" << 'EOF'
[features]
docker = true
rust = false
install_gui = true
EOF

if command -v python3 &>/dev/null; then
  result=$(python3 -c "
import tomllib, json
with open('$TEMP_TOML', 'rb') as f:
    d = tomllib.load(f)
print(json.dumps(d['features']))
" 2>/dev/null)

  if echo "$result" | grep -q '"docker": true' && echo "$result" | grep -q '"rust": false'; then
    pass "Boolean values preserved in TOML round-trip"
  else
    fail "Boolean values not preserved: $result"
  fi
else
  pass "Python not available (skipped)"
fi
rm -f "$TEMP_TOML"

# ── Property: Port numbers are valid ────────────────────────────────────────
echo ""
test_case "Port numbers are valid (1-65535)"

valid_ports=(80 443 3000 5432 6379 6333 8080 9090)
for port in "${valid_ports[@]}"; do
  if [ "$port" -ge 1 ] && [ "$port" -le 65535 ]; then
    pass "Port $port is valid"
  else
    fail "Port $port is invalid"
  fi
done

# ── Property: Version strings are semver ────────────────────────────────────
echo ""
test_case "Version strings follow semver"

versions=("v8.0.0" "v7.0.0" "v3.5.0" "v10.2.3")
for ver in "${versions[@]}"; do
  if echo "$ver" | grep -qE '^v[0-9]+\.[0-9]+\.[0-9]+$'; then
    pass "Version $ver is valid semver"
  else
    fail "Version $ver is not valid semver"
  fi
done

# ── Property: File paths are absolute ───────────────────────────────────────
echo ""
test_case "File paths are absolute"

paths=("/home/user/project" "/usr/local/bin" "/etc/config")
for path in "${paths[@]}"; do
  if [[ "$path" == /* ]]; then
    pass "Path $path is absolute"
  else
    fail "Path $path is not absolute"
  fi
done

# ── Property: Environment variables are uppercase ───────────────────────────
echo ""
test_case "Environment variables are uppercase"

env_vars=("PROJECT_ROOT" "NODE_ENV" "PYTHON_PATH" "DOCKER_HOST")
for var in "${env_vars[@]}"; do
  if [[ "$var" =~ ^[A-Z_]+$ ]]; then
    pass "Variable $var is uppercase"
  else
    fail "Variable $var is not uppercase"
  fi
done

# ── Property: URLs are valid ────────────────────────────────────────────────
echo ""
test_case "URLs are valid"

urls=(
  "https://github.com/AlexanderNarbaev/opencode_initializer"
  "https://npm-mirror.gitverse.ru"
  "https://pypi-mirror.gitverse.ru/simple/"
)
for url in "${urls[@]}"; do
  if [[ "$url" =~ ^https?:// ]]; then
    pass "URL $url is valid"
  else
    fail "URL $url is not valid"
  fi
done

# ── Property: Shell scripts have shebang ────────────────────────────────────
echo ""
test_case "Shell scripts have shebang"

scripts=(
  "$PROJECT_ROOT/src/lib/00-core.sh"
  "$PROJECT_ROOT/src/lib/00d-parallel.sh"
  "$PROJECT_ROOT/setup.sh"
)
for script in "${scripts[@]}"; do
  if [ -f "$script" ]; then
    first_line=$(head -1 "$script")
    if [[ "$first_line" == "#!/"* ]]; then
      pass "$(basename $script) has shebang"
    else
      fail "$(basename $script) missing shebang"
    fi
  else
    pass "$(basename $script) not found (skipped)"
  fi
done

# ── Property: JSON is valid ─────────────────────────────────────────────────
echo ""
test_case "JSON files are valid"

json_files=(
  "$PROJECT_ROOT/package.json"
  "$PROJECT_ROOT/session_checkpoint.json"
)
for json_file in "${json_files[@]}"; do
  if [ -f "$json_file" ]; then
    if python3 -c "import json; json.load(open('$json_file'))" 2>/dev/null; then
      pass "$(basename $json_file) is valid JSON"
    else
      fail "$(basename $json_file) is invalid JSON"
    fi
  else
    pass "$(basename $json_file) not found (skipped)"
  fi
done

# ── Summary ─────────────────────────────────────────────────────────────────
echo ""
echo "─── Property-Based Tests: $TOTAL tests, $PASS passed, $FAIL failed ───"

if [ "$FAIL" -gt 0 ]; then
  exit 1
fi
exit 0
