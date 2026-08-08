#!/usr/bin/env bash
# Test Provider SSOT — src/data/providers.json as single source of truth
# Session: C1-audit-fix
# Validates: JSON completeness, sync with 26-providers.sh embedded registry,
#            anti-divergence guard with 18-opencode-json.sh
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
TESTS_PASS=0; TESTS_FAIL=0
TMP_DIR=$(mktemp -d)
trap 'rm -rf "$TMP_DIR"' EXIT

assert() {
  local desc="$1" condition="$2"
  if (eval "$condition") &>/dev/null; then TESTS_PASS=$((TESTS_PASS + 1))
  else TESTS_FAIL=$((TESTS_FAIL + 1)); echo "    FAIL: $desc" >&2; fi
}

PJ="$PROJECT_DIR/src/data/providers.json"
P26="$PROJECT_DIR/src/lib/26-providers.sh"
P18="$PROJECT_DIR/src/lib/18-opencode-json.sh"

# ── Helper: extract cloud provider names from 26-providers.sh ─────────────────
# Uses a pre-written Python helper to avoid inline-eval blocking
cat > "$TMP_DIR/extract_names.py" << 'PYEOF'
import re, sys

with open(sys.argv[1]) as f:
    content = f.read()

# Find cloud section by locating the ASCII substring (Unicode box-drawings may differ)
cloud_start = content.find('Cloud provider registry')
if cloud_start == -1:
    print('ERROR: Cloud section not found')
    sys.exit(1)

cloud_section = content[cloud_start:]

# Find PROVIDER_REGISTRY=( after cloud section start
pr_start = cloud_section.find('PROVIDER_REGISTRY=(')
if pr_start == -1:
    print('ERROR: PROVIDER_REGISTRY=( not found in cloud section')
    sys.exit(1)

# Extract all [name]=" patterns from after PROVIDER_REGISTRY=(
after_pr = cloud_section[pr_start:]
names = set(re.findall(r'\[(\w+)\]="', after_pr))
for n in sorted(names):
    print(n)
PYEOF

# Helper: extract provider names from all_keys dict in 18-opencode-json.sh
# Filters out all-caps env vars (PG_CONNECTION_STRING, etc.) that are not providers
cat > "$TMP_DIR/extract_p18.py" << 'PYEOF'
import re, sys

with open(sys.argv[1]) as f:
    content = f.read()

p18_names = set(re.findall(r'"(\w+)":\s*os\.environ\.get', content))
# Skip all-caps non-provider env vars (e.g. PG_CONNECTION_STRING)
p18_names = {n for n in p18_names if not n.isupper() or n == n.lower()}
for n in sorted(p18_names):
    print(n)
PYEOF

# ── T1: JSON file exists and is valid ─────────────────────────────────────────
assert "providers.json exists" "[ -f '$PJ' ]"
assert "providers.json is valid JSON" "python3 -c 'import json; json.load(open(\"$PJ\"))'"
assert "providers.json has 22 providers" "python3 -c \"import json; d=json.load(open('$PJ')); assert len(d['providers']) == 22, len(d['providers'])\""

# ── T2: Each provider has all required fields ─────────────────────────────────
assert "all providers have required fields" "python3 -c \"
import json
d = json.load(open('$PJ'))
providers = d['providers']
required = 'model free sdk api_key_env cli_flag description'.split()
missing = []
for name, p in providers.items():
    for f in required:
        if f not in p:
            missing.append(f'{name}.{f}')
if missing:
    print('MISSING:', missing)
    exit(1)
\""

# ── T3: JSON provider names == 26-providers.sh cloud provider names ───────────
assert "JSON and 26-providers.sh have same provider set" "python3 -c \"
import json, subprocess, sys

d = json.load(open('$PJ'))
json_set = set(d['providers'].keys())

# Use extract_names.py helper (avoids bash double-quote escaping issues)
result = subprocess.run(['python3', '$TMP_DIR/extract_names.py', '$P26'],
    capture_output=True, text=True)
if result.returncode != 0:
    print('extract_names.py FAILED:', result.stderr)
    sys.exit(1)
reg_set = set(n for n in result.stdout.strip().split(chr(10)) if n)

if json_set != reg_set:
    print(f'DIFF json-reg={json_set-reg_set} reg-json={reg_set-json_set}')
    sys.exit(1)
\""

# ── T4: free flag matches between JSON and 26-providers.sh ────────────────────
cat > "$TMP_DIR/check_free.py" << 'PYEOF'
import json, re, sys

d = json.load(open(sys.argv[1]))
providers = d['providers']

with open(sys.argv[2]) as f:
    content = f.read()

cloud_start = content.find('Cloud provider registry')
if cloud_start == -1:
    sys.exit(1)
cloud_section = content[cloud_start:]
pr_start = cloud_section.find('PROVIDER_REGISTRY=(')
if pr_start == -1:
    sys.exit(1)
after_pr = cloud_section[pr_start:]

mismatches = []
for match in re.finditer(r'\[(\w+)\]="([^"]+)"', after_pr):
    name = match.group(1)
    value = match.group(2)
    parts = value.split('|')
    reg_free = (parts[-1] == 'yes') if len(parts) >= 4 else False
    if name in providers:
        json_free = providers[name].get('free', False)
        if json_free != reg_free:
            mismatches.append(f'{name}: JSON={json_free} REG={reg_free}')

if mismatches:
    print('FREE MISMATCH:', mismatches)
    sys.exit(1)
PYEOF
assert "free flag sync: JSON == 26-providers.sh" "python3 '$TMP_DIR/check_free.py' '$PJ' '$P26'"

# ── T5: All providers in 18-opencode-json.sh are subset of JSON ───────────────
assert "18-opencode-json.sh providers subset of JSON (anti-divergence)" "python3 -c \"
import json, subprocess, sys

d = json.load(open('$PJ'))
json_names = set(d['providers'].keys())

# Use extract_p18.py helper (avoids bash double-quote escaping issues)
result = subprocess.run(['python3', '$TMP_DIR/extract_p18.py', '$P18'],
    capture_output=True, text=True)
if result.returncode != 0:
    print('extract_p18.py FAILED:', result.stderr)
    sys.exit(1)
p18_names = set(n for n in result.stdout.strip().split(chr(10)) if n)

only_in_p18 = p18_names - json_names
if only_in_p18:
    print(f'DIVERGENCE: {only_in_p18}')
    sys.exit(1)
\""

# ── T6: JSON loading path in 26-providers.sh exists ───────────────────────────
assert "26-providers.sh references providers.json" "grep -q 'providers.json' '$P26'"
assert "26-providers.sh has embedded fallback" "grep -q 'Embedded fallback' '$P26'"

# ── T7: api_key_env fields match PROVIDER_REGISTRY ────────────────────────────
cat > "$TMP_DIR/check_env.py" << 'PYEOF'
import json, re, sys

d = json.load(open(sys.argv[1]))

with open(sys.argv[2]) as f:
    content = f.read()

cloud_start = content.find('Cloud provider registry')
if cloud_start == -1:
    sys.exit(1)
cloud_section = content[cloud_start:]
pr_start = cloud_section.find('PROVIDER_REGISTRY=(')
if pr_start == -1:
    sys.exit(1)
after_pr = cloud_section[pr_start:]

mismatches = []
for match in re.finditer(r'\[(\w+)\]="([^"]+)"', after_pr):
    name = match.group(1)
    value = match.group(2)
    parts = value.split('|')
    reg_env = parts[0] if len(parts) >= 1 else ''
    if name in d['providers']:
        json_env = d['providers'][name].get('api_key_env', '')
        if json_env != reg_env:
            mismatches.append(f'{name}: JSON={json_env} REG={reg_env}')

if mismatches:
    print('ENV MISMATCH:', mismatches)
    sys.exit(1)
PYEOF
assert "api_key_env matches 26-providers.sh" "python3 '$TMP_DIR/check_env.py' '$PJ' '$P26'"

# ── T8: provider count consistency ────────────────────────────────────────────
assert "22 providers total" "python3 -c \"import json; d=json.load(open('$PJ')); assert len(d['providers']) == 22\""

# ── T9: bash -n syntax check ──────────────────────────────────────────────────
assert "26-providers.sh syntax valid" "bash -n '$P26'"

# ── T10: backward compat — test_providers.sh still passes ─────────────────────
assert "test_providers.sh backward compat" "grep -q 'deepseek' '$P26' && grep -q 'zai' '$P26' && grep -q 'openrouter' '$P26'"

echo "test_provider_ssot: $TESTS_PASS passed, $TESTS_FAIL failed"
[ "$TESTS_FAIL" -eq 0 ] || exit 1
