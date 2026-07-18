#!/usr/bin/env bash
set -euo pipefail
PROJECT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
TESTS_PASS=0; TESTS_FAIL=0
F="$PROJECT_DIR/src/lib/19-finalize.sh"
assert() { local d="$1" c="$2"; if (eval "$c") &>/dev/null; then TESTS_PASS=$((TESTS_PASS + 1)); else TESTS_FAIL=$((TESTS_FAIL + 1)); echo "    FAIL: $d" >&2; fi }
assert "exists" "[ -f $F ]"
assert "syntax" "bash -n $F"
assert "has Go check" "grep -q go.version $F"
assert "has Rust check" "grep -q rustc $F"
assert "has Node check" "grep -q node $F"
assert "has Python check" "grep -q python3 $F"
assert "has OpenCode check" "grep -q opencode $F"
assert "has uv check" "grep -q uv $F"
assert "has bun check" "grep -q bun $F"
assert "has git config" "grep -q git.config $F"
assert "has auth reminder" "grep -q API_KEY $F"
assert "has WAL module count 41" "grep -q 41 $F"
assert "has SCRIPT_VERSION" "grep -q SCRIPT_VERSION $F"
assert "has step_finalize" "grep -q step_finalize $F"
assert "has dev CLI mention" "grep -q dev.health $F"
assert "has opencode.json mention" "grep -q fix-config $F"
echo "test_finalize: $TESTS_PASS passed, $TESTS_FAIL failed"
