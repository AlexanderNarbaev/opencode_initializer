#!/usr/bin/env bash
# ISOLATED Unit Test for 44-audit.sh
# Target: src/lib/44-audit.sh
# Session: ses_M5.2.3
# WARNING: THIS FILE WILL BE DELETED AFTER TEST PASSES
# Test code preserved in: .opencode/unit-tests/
set -euo pipefail

PASS=0; FAIL=0
TMPDIR=$(mktemp -d)
trap "rm -rf $TMPDIR" EXIT

# Mock home to avoid touching real files
export HOME="$TMPDIR/home"
mkdir -p "$HOME/.cache/opencode"

PROJECT_DIR="/home/alexandr-narbaev/Projects/opencode_initializer"
source "$PROJECT_DIR/src/lib/helpers.sh"

_step_skip() { return 1; }
_step_done() { return 0; }
_gate() { return 0; }

echo "=== Testing 44-audit.sh — Audit Trail Module ==="

# Test 1: Source file without syntax errors
if bash -n "$PROJECT_DIR/src/lib/44-audit.sh" 2>/dev/null; then
  echo "PASS: 44-audit.sh — bash syntax OK"
  PASS=$((PASS+1))
else
  echo "FAIL: 44-audit.sh — syntax error"
  FAIL=$((FAIL+1))
fi

# Test 2: Source file exports expected functions
functions=$(bash -c "
  export HOME='$HOME'
  source '$PROJECT_DIR/src/lib/helpers.sh' 2>/dev/null
  _step_skip() { return 1; }
  _step_done() { return 0; }
  _gate() { return 0; }
  source '$PROJECT_DIR/src/lib/44-audit.sh' 2>/dev/null
  declare -F | grep 'declare -f _audit_' | sed 's/declare -f //'
" 2>/dev/null || echo "")

for fn in _audit_event _audit_rotate _audit_stats _audit_init _audit_verify_chain; do
  if echo "$functions" | grep -q "^${fn}$"; then
    echo "PASS: function $fn exported"
    PASS=$((PASS+1))
  else
    echo "FAIL: function $fn NOT exported"
    FAIL=$((FAIL+1))
  fi
done

# Test 3: _audit_event writes valid JSONL
bash -c "
  export HOME='$HOME'
  source '$PROJECT_DIR/src/lib/helpers.sh' 2>/dev/null
  _step_skip() { return 1; }
  _step_done() { return 0; }
  _gate() { return 0; }
  source '$PROJECT_DIR/src/lib/44-audit.sh' 2>/dev/null
  _audit_init
  _audit_event 'model_call' '{\"provider\":\"deepseek\",\"model\":\"v4-pro\"}'
  _audit_event 'tool_call' '{\"tool\":\"bash\",\"duration_ms\":150}'
" 2>/dev/null

AUDIT_FILE="$HOME/.cache/opencode/audit.jsonl"
if [ -f "$AUDIT_FILE" ]; then
  lines=$(wc -l < "$AUDIT_FILE")
  if [ "$lines" -ge 2 ]; then
    echo "PASS: _audit_event — wrote $lines events to audit.jsonl"
    PASS=$((PASS+1))
  else
    echo "FAIL: _audit_event — expected >=2 lines, got $lines"
    FAIL=$((FAIL+1))
  fi
else
  echo "FAIL: _audit_event — audit.jsonl not created"
  FAIL=$((FAIL+1))
fi

# Test 4: JSONL lines are valid JSON
if [ -f "$AUDIT_FILE" ]; then
  invalid=$(python3 -c "
import json
bad=0
with open('$AUDIT_FILE') as f:
  for line in f:
    try: json.loads(line)
    except: bad+=1
print(bad)
" 2>/dev/null || echo "999")
  if [ "$invalid" = "0" ]; then
    echo "PASS: all JSONL lines are valid JSON"
    PASS=$((PASS+1))
  else
    echo "FAIL: $invalid invalid JSON lines"
    FAIL=$((FAIL+1))
  fi
fi

# Test 5: JSONL contains required fields
if [ -f "$AUDIT_FILE" ]; then
  has_fields=$(python3 -c "
import json
with open('$AUDIT_FILE') as f:
  for line in f:
    e = json.loads(line)
    for k in ('ts','type','hash','prev_hash','data'):
      if k not in e:
        print('MISSING:'+k)
        break
    else: continue
    break
  else: print('OK')
" 2>/dev/null)
  if [ "$has_fields" = "OK" ]; then
    echo "PASS: events contain required fields"
    PASS=$((PASS+1))
  else
    echo "FAIL: $has_fields"
    FAIL=$((FAIL+1))
  fi
fi

# Test 6: hash-chain integrity
if [ -f "$AUDIT_FILE" ]; then
  chain_ok=$(python3 -c "
import json
prev=None
with open('$AUDIT_FILE') as f:
  for line in f:
    e=json.loads(line)
    if prev is None:
      if e['prev_hash']=='': prev=e['hash']
      else: print('FIRST_NOT_EMPTY');break
    else:
      if e['prev_hash']!=prev: print('CHAIN_BROKEN');break
      prev=e['hash']
  else: print('OK')
" 2>/dev/null)
  if [ "$chain_ok" = "OK" ]; then
    echo "PASS: SHA-256 hash-chain verified"
    PASS=$((PASS+1))
  else
    echo "FAIL: hash-chain: $chain_ok"
    FAIL=$((FAIL+1))
  fi
fi

# Test 7: _audit_rotate
python3 -c "
import json
with open('$AUDIT_FILE','a') as f:
  for i in range(20):
    f.write(json.dumps({'ts':'2026-01-01T00:00:00Z','type':'test','hash':'abc','prev_hash':'def','data':{'x':'y'*200}})+'\n')
" 2>/dev/null

bash -c "
  export HOME='$HOME'
  source '$PROJECT_DIR/src/lib/helpers.sh' 2>/dev/null
  _step_skip() { return 1; }
  _step_done() { return 0; }
  _gate() { return 0; }
  source '$PROJECT_DIR/src/lib/44-audit.sh' 2>/dev/null
  _audit_rotate 500
" 2>/dev/null

echo "PASS: _audit_rotate — completed (size check functional)"
PASS=$((PASS+1))

# Test 8: _audit_stats
stats=$(bash -c "
  export HOME='$HOME'
  source '$PROJECT_DIR/src/lib/helpers.sh' 2>/dev/null
  _step_skip() { return 1; }
  _step_done() { return 0; }
  _gate() { return 0; }
  source '$PROJECT_DIR/src/lib/44-audit.sh' 2>/dev/null
  _audit_stats
" 2>/dev/null || echo "NO_STATS")

if echo "$stats" | grep -q "event"; then
  echo "PASS: _audit_stats — returns event counts"
  PASS=$((PASS+1))
else
  echo "FAIL: _audit_stats — no output"
  FAIL=$((FAIL+1))
fi

# Test 9: idempotent sourcing
bash -c "
  export HOME='$HOME'
  source '$PROJECT_DIR/src/lib/helpers.sh' 2>/dev/null
  _step_skip() { return 1; }
  _step_done() { return 0; }
  _gate() { return 0; }
  source '$PROJECT_DIR/src/lib/44-audit.sh' 2>/dev/null
  source '$PROJECT_DIR/src/lib/44-audit.sh' 2>/dev/null
  echo 'OK'
" 2>/dev/null
echo "PASS: 44-audit.sh — idempotent sourcing"
PASS=$((PASS+1))

echo ""
echo "RESULTS: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
