#!/usr/bin/env bash
# tests/unit/test_sdd_commands.sh — SDD lifecycle command tests (M4/T4.2)
# S4.2.1: Create commands in mktemp project, verify bash -n clean
# S4.2.2: /tasks with sample spec (3 FRs) → shows 3 requirements
# S4.2.3: /analyze with divergence → exit non-zero + report
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$(dirname "$SCRIPT_DIR")")"
PASS=0; FAIL=0

export MODE=test
source "$PROJECT_DIR/src/lib/helpers.sh"
source "$PROJECT_DIR/src/lib/41-constitution.sh"

echo "=== S4.2.1: Generate SDD commands ==="

TMP_PROJECT=$(mktemp -d)
trap 'rm -rf "$TMP_PROJECT"' EXIT

# Generate commands in temp project
_sdd_generate_commands "$TMP_PROJECT"

# Verify files created
for cmd in tasks analyze implement; do
  f="$TMP_PROJECT/.opencode/commands/${cmd}.sh"
  if [ -f "$f" ] && [ -x "$f" ]; then
    echo "PASS: ${cmd}.sh exists + executable"
    PASS=$((PASS + 1))
  else
    echo "FAIL: ${cmd}.sh missing or not executable"
    FAIL=$((FAIL + 1))
  fi
done

# Verify bash -n clean
for cmd in tasks analyze implement; do
  f="$TMP_PROJECT/.opencode/commands/${cmd}.sh"
  if bash -n "$f" 2>&1; then
    echo "PASS: bash -n ${cmd}.sh"
    PASS=$((PASS + 1))
  else
    echo "FAIL: bash -n ${cmd}.sh"
    FAIL=$((FAIL + 1))
  fi
done

echo ""
echo "=== S4.2.2: /tasks with sample spec ==="

# Create sample spec with 3 FRs
mkdir -p "$TMP_PROJECT/.opencode"
cat > "$TMP_PROJECT/.opencode/spec.md" << 'EOF'
# Sample Spec
## FR-001: User login
## FR-002: Dashboard view
## FR-003: Export reports
## SC-001: Login success
## SC-002: Dashboard loads
EOF

# Create minimal todo.md
cat > "$TMP_PROJECT/.opencode/todo.md" << 'EOF'
# Mission: Test
- [x] S1: Done task
- [ ] S2: Pending task
EOF

output=$(bash "$TMP_PROJECT/.opencode/commands/tasks.sh" 2>&1 || true)
if echo "$output" | grep -q "FR requirements: 3"; then
  echo "PASS: /tasks reports 3 FRs"
  PASS=$((PASS + 1))
else
  echo "FAIL: /tasks FR count wrong: $output"
  FAIL=$((FAIL + 1))
fi
if echo "$output" | grep -q "SC scenarios: 2"; then
  echo "PASS: /tasks reports 2 SCs"
  PASS=$((PASS + 1))
else
  echo "FAIL: /tasks SC count wrong"
  FAIL=$((FAIL + 1))
fi
if echo "$output" | grep -q "Done: 1"; then
  echo "PASS: /tasks reports 1 done"
  PASS=$((PASS + 1))
else
  echo "FAIL: /tasks done count wrong"
  FAIL=$((FAIL + 1))
fi
if echo "$output" | grep -q "Pending: 1"; then
  echo "PASS: /tasks reports 1 pending"
  PASS=$((PASS + 1))
else
  echo "FAIL: /tasks pending count wrong"
  FAIL=$((FAIL + 1))
fi

echo ""
echo "=== S4.2.3: /analyze with intentional divergence ==="

# Create constitution
mkdir -p "$TMP_PROJECT/memory"
echo "# Constitution" > "$TMP_PROJECT/memory/constitution.md"

# Create spec with FR that's NOT in todo
cat > "$TMP_PROJECT/.opencode/spec.md" << 'EOF'
# Spec with divergence
## FR-001: User login
## FR-099: Unimplemented feature
EOF

# Todo without FR-099
cat > "$TMP_PROJECT/.opencode/todo.md" << 'EOF'
# Mission: Test
- [x] FR-001: User login done
- [ ] S2: Other task
EOF

set +e
analyze_output=$(bash "$TMP_PROJECT/.opencode/commands/analyze.sh" 2>&1)
analyze_exit=$?
set -e

if [ "$analyze_exit" -ne 0 ]; then
  echo "PASS: /analyze exits non-zero ($analyze_exit) on divergence"
  PASS=$((PASS + 1))
else
  echo "FAIL: /analyze exits 0 despite divergence"
  FAIL=$((FAIL + 1))
fi
if echo "$analyze_output" | grep -q "FR-099"; then
  echo "PASS: /analyze reports unsatisfied FR-099"
  PASS=$((PASS + 1))
else
  echo "FAIL: /analyze missing FR-099 in output"
  FAIL=$((FAIL + 1))
fi

echo ""
echo "=== S4.2.4: /implement — next task selector ==="

# Todo with pending item
cat > "$TMP_PROJECT/.opencode/todo.md" << 'EOF'
# Mission: Test
- [x] S1: Done
- [ ] IMPL-01: Build login page — acceptance: must render in <2s
- [ ] IMPL-02: Build dashboard
EOF

impl_output=$(bash "$TMP_PROJECT/.opencode/commands/implement.sh" 2>&1 || true)
if echo "$impl_output" | grep -q "IMPL-01"; then
  echo "PASS: /implement shows first pending task"
  PASS=$((PASS + 1))
else
  echo "FAIL: /implement missing IMPL-01: $impl_output"
  FAIL=$((FAIL + 1))
fi
if echo "$impl_output" | grep -q "Build login page"; then
  echo "PASS: /implement shows task description"
  PASS=$((PASS + 1))
else
  echo "FAIL: /implement missing description"
  FAIL=$((FAIL + 1))
fi

# Todo with all done
cat > "$TMP_PROJECT/.opencode/todo.md" << 'EOF'
# Mission: Test
- [x] S1: Done
- [x] S2: Also done
EOF

impl_output2=$(bash "$TMP_PROJECT/.opencode/commands/implement.sh" 2>&1 || true)
if echo "$impl_output2" | grep -q "All tasks complete"; then
  echo "PASS: /implement reports all complete"
  PASS=$((PASS + 1))
else
  echo "FAIL: /implement should report complete: $impl_output2"
  FAIL=$((FAIL + 1))
fi

echo ""
echo "=== S4.2.5: Idempotency — regenerate does not overwrite ==="

# Modify a command file, then regenerate
MODDED="$TMP_PROJECT/.opencode/commands/tasks.sh"
echo "# MODIFIED" >> "$MODDED"
original_md5=$(md5sum "$MODDED" 2>/dev/null || echo "skip")
_sdd_generate_commands "$TMP_PROJECT"

# Verify the modified file was NOT overwritten (idempotent guard: [ ! -f ])
if grep -q "# MODIFIED" "$MODDED"; then
  echo "PASS: idempotent — modified tasks.sh preserved"
  PASS=$((PASS + 1))
else
  echo "FAIL: idempotent — tasks.sh was overwritten"
  FAIL=$((FAIL + 1))
fi

# Delete one command, regenerate — should recreate
rm -f "$TMP_PROJECT/.opencode/commands/analyze.sh"
_sdd_generate_commands "$TMP_PROJECT"
if [ -f "$TMP_PROJECT/.opencode/commands/analyze.sh" ]; then
  echo "PASS: regenerate restores missing analyze.sh"
  PASS=$((PASS + 1))
else
  echo "FAIL: regenerate did not restore analyze.sh"
  FAIL=$((FAIL + 1))
fi

echo ""
echo "RESULTS: $PASS pass, $FAIL fail"
[ "$FAIL" -eq 0 ] || exit 1
