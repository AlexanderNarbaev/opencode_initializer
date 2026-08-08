#!/usr/bin/env bash
# Unit test: S1.1.4 — WAL race-condition test with hash-chain verification
# Verifies _wal_locked_append() atomicity under concurrent writes.
# Hash-chain tested with SEQUENTIAL _wal_agent_log writes (not racy).
set -euo pipefail

PASS=0; FAIL=0
PROJECT_DIR="/home/alexandr-narbaev/Projects/opencode_initializer"
TMPD=$(mktemp -d)
trap 'rm -rf "$TMPD"' EXIT

# 37-wal.sh has top-level `if [ "$MODE" = "full" ]` guard — set MODE to avoid triggering
export MODE=test
source "$PROJECT_DIR/src/lib/helpers.sh"
source "$PROJECT_DIR/src/lib/37-wal.sh"

echo "=== Testing WAL race conditions (S1.1.4) ==="

# ── Setup: temp WAL file (isolated from real WAL) ──
export WAL_AGENT_FILE="$TMPD/race.wal"

# ── T1: 10 parallel _wal_agent_log writers × 10 entries = 100 total ─────────
# NOTE: _wal_agent_log hash-chain is NOT designed for concurrent writes.
# This test only verifies count + line validity under _wal_locked_append.
run_agent_log() {
  local wid="$1" total="$2"
  local i=1
  while [ $i -le "$total" ]; do
    _wal_agent_log "test" "d-${wid}-${i}" "r-${wid}-${i}" "0.$((50 + wid * 5))" "S1"
    i=$((i+1))
  done
}

for w in $(seq 1 10); do
  run_agent_log "$w" 10 &
done
wait

# Count lines robustly (strip all whitespace from wc -l output)
lines=$(wc -l < "$WAL_AGENT_FILE" 2>/dev/null)
lines=$(echo "$lines" | tr -d '[:space:]')
lines=${lines:-0}
if [ "$lines" -eq 100 ]; then
  echo "PASS: T1 — all 100 entries written (10 writers × 10)"
  PASS=$((PASS+1))
else
  echo "FAIL: T1 — expected 100 entries, got '$lines'"
  FAIL=$((FAIL+1))
fi

# ── T2: all lines are valid JSON objects ─────────────────────────────────────
# Count lines NOT starting with '{' (empty/corrupt)
bad=$(grep -cv '^{' "$WAL_AGENT_FILE" 2>/dev/null) || bad=0
bad=${bad:-0}
if [ "$bad" -eq 0 ]; then
  echo "PASS: T2 — all $lines lines are valid JSON (none empty/corrupt)"
  PASS=$((PASS+1))
else
  echo "FAIL: T2 — $bad invalid line(s) (not starting with '{')"
  FAIL=$((FAIL+1))
fi

# ── T3: hash-chain integrity (SEQUENTIAL writes) ────────────────────────────
# Wipe WAL and write 20 entries sequentially to verify hash-chain continuity
export WAL_AGENT_FILE="$TMPD/hash.wal"
: > "$WAL_AGENT_FILE"  # truncate

for i in $(seq 1 20); do
  _wal_agent_log "test" "decision-$i" "rationale-$i" "0.85" "S1"
done

# Verify: each entry.prev_hash == previous entry.hash
prev="genesis"
chain_ok=true
while IFS= read -r entry; do
  [ -z "$entry" ] && continue
  entry_prev=$(echo "$entry" | jq -r '.prev_hash // "genesis"' 2>/dev/null || echo "genesis")
  entry_hash=$(echo "$entry" | jq -r '.hash // ""' 2>/dev/null || echo "")
  if [ "$entry_prev" != "$prev" ]; then
    chain_ok=false
    break
  fi
  prev="$entry_hash"
done < "$WAL_AGENT_FILE"

# Count sequential entries
seq_lines=$(wc -l < "$WAL_AGENT_FILE" | tr -d '[:space:]')
seq_lines=${seq_lines:-0}

if $chain_ok && [ "$seq_lines" -eq 20 ]; then
  echo "PASS: T3 — hash-chain continuous across $seq_lines sequential entries"
  PASS=$((PASS+1))
elif [ "$seq_lines" -ne 20 ]; then
  echo "FAIL: T3 — expected 20 sequential entries, got '$seq_lines'"
  FAIL=$((FAIL+1))
else
  echo "FAIL: T3 — hash-chain broken in sequential writes"
  FAIL=$((FAIL+1))
fi

# ── T4: missing file argument handled ────────────────────────────────────────
if _wal_locked_append "" '{}' 2>/dev/null; then
  echo "FAIL: T4 — empty file argument should be rejected"
  FAIL=$((FAIL+1))
else
  echo "PASS: T4 — empty file argument rejected"
  PASS=$((PASS+1))
fi

# ── T5: no mixed/corrupted data between entries ──────────────────────────────
# Verify no line contains garbage between JSON objects (each line is standalone)
export WAL_AGENT_FILE="$TMPD/race.wal"  # switch back to race file
race_ok=$(grep -cvE '^\{.*\}$' "$WAL_AGENT_FILE" 2>/dev/null) || race_ok=0
race_ok=${race_ok:-0}
if [ "$race_ok" -eq 0 ]; then
  echo "PASS: T5 — no mixed/garbage data in race entries"
  PASS=$((PASS+1))
else
  echo "FAIL: T5 — $race_ok race entries have malformed data"
  FAIL=$((FAIL+1))
fi

echo "RESULTS: $PASS pass, $FAIL fail"
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
