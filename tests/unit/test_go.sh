#!/usr/bin/env bash
set -euo pipefail
PROJECT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
TESTS_PASS=0; TESTS_FAIL=0
G="$PROJECT_DIR/src/lib/08-go.sh"
assert() { local d="$1" c="$2"; if (eval "$c") &>/dev/null; then TESTS_PASS=$((TESTS_PASS+1)); else TESTS_FAIL=$((TESTS_FAIL+1)); echo "    FAIL: $d" >&2; fi }
assert "exists" "[ -f $G ]"
assert "syntax" "bash -n $G"
assert "has GO_LATEST fallback" "grep -q 1.26.5 $G"
assert "has GO_ARCH" "grep -q GO_ARCH $G"
assert "has golang-go apt fallback" "grep -q golang-go $G"
assert "has GOPATH setup" "grep -q go/bin $G"
assert "has _curl usage" "grep -q _curl $G"
assert "has version check" "grep -q GO_MINOR $G"
assert "has go.dev API call" "grep -q go.dev $G"
assert "exports PATH" "grep -q PATH.*go $G"
assert "has direct download" "grep -q go.dev/dl $G"
echo "test_go: $TESTS_PASS passed, $TESTS_FAIL failed"
