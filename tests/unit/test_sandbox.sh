#!/usr/bin/env bash
# ============================================================================
# Unit Test — tests/test_sandbox.sh + tests/run_tests.sh safety gates
#
# The sandbox is the guard that keeps the suite from installing packages or
# hanging on a password prompt, so it gets its own test.
# ============================================================================
set -uo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
TESTS_DIR="$PROJECT_DIR/tests"
SANDBOX="$TESTS_DIR/test_sandbox.sh"
RUNNER="$TESTS_DIR/run_tests.sh"

PASS=0; FAIL=0
ok()  { PASS=$((PASS + 1)); }
bad() { FAIL=$((FAIL + 1)); echo "    FAIL: $1" >&2; }
check() { local d="$1" c="$2"; if eval "$c" >/dev/null 2>&1; then ok; else bad "$d"; fi; }

echo "=== Testing tests/test_sandbox.sh ==="

# ── 1. Files & syntax ──────────────────────────────────────────────────────
check "test_sandbox.sh exists"        "[ -f '$SANDBOX' ]"
check "test_sandbox.sh bash -n clean" "bash -n '$SANDBOX'"
check "run_tests.sh exists"           "[ -f '$RUNNER' ]"
check "run_tests.sh bash -n clean"    "bash -n '$RUNNER'"

# ── 2. API surface ─────────────────────────────────────────────────────────
for fn in sandbox_init sandbox_activate sandbox_report sandbox_cleanup \
          sandbox_log_lines sandbox_log_since; do
  check "defines $fn()" "grep -qE '^${fn}\(\)' '$SANDBOX'"
done
check "declares shim list"       "grep -q 'TEST_SANDBOX_SHIMS=' '$SANDBOX'"
check "shim list covers sudo"    "grep -qE 'TEST_SANDBOX_SHIMS=.*sudo' '$SANDBOX'"
check "shim list covers apt-get" "grep -qE 'TEST_SANDBOX_SHIMS=.*apt-get' '$SANDBOX'"
check "shim list covers gpg"     "grep -qE 'TEST_SANDBOX_SHIMS=.*gpg' '$SANDBOX'"
check "leaves tee alone"         "! grep -qE 'TEST_SANDBOX_SHIMS=.*[^a-z-]tee' '$SANDBOX'"
check "leaves systemctl alone"   "! grep -q 'TEST_SANDBOX_SHIMS=.*systemctl' '$SANDBOX'"
check "honours RUN_PRIVILEGED"   "grep -q 'RUN_PRIVILEGED' '$SANDBOX'"
check "forces non-interactive apt" "grep -q 'DEBIAN_FRONTEND=noninteractive' '$SANDBOX'"
check "disables git credential prompts" "grep -q 'GIT_TERMINAL_PROMPT=0' '$SANDBOX'"

# ── 3. RUN_E2E / RUN_PRIVILEGED gates in the runner ────────────────────────
check "runner reads RUN_E2E"          "grep -q 'RUN_E2E=' '$RUNNER'"
check "runner reads RUN_PRIVILEGED"   "grep -q 'RUN_PRIVILEGED=' '$RUNNER'"
check "runner reads TEST_TIMEOUT"     "grep -q 'TEST_TIMEOUT=' '$RUNNER'"
check "runner has --e2e flag"         "grep -q -- '--e2e' '$RUNNER'"
check "runner has --privileged flag"  "grep -q -- '--privileged' '$RUNNER'"
check "runner has --timeout flag"     "grep -q -- '--timeout' '$RUNNER'"
check "runner has --help flag"        "grep -q -e '--help' '$RUNNER'"
check "runner sources sandbox"        "grep -q 'test_sandbox.sh' '$RUNNER'"
check "runner calls sandbox_init"     "grep -q 'sandbox_init' '$RUNNER'"
check "runner calls sandbox_activate" "grep -q 'sandbox_activate' '$RUNNER'"
check "runner wraps tests in timeout" "grep -q 'run_with_timeout' '$RUNNER'"
check "runner tracks SKIP"            "grep -q 'SKIP=' '$RUNNER'"
check "runner gates e2e on RUN_E2E"   "grep -qE 'if \[ \"\\\$RUN_E2E\" = \"1\" \]' '$RUNNER'"
check "runner defaults RUN_E2E to 0"      "grep -qF 'RUN_E2E:-0' '$RUNNER'"
check "runner defaults privileged to 0"   "grep -qF 'RUN_PRIVILEGED:-0' '$RUNNER'"
check "runner sets cleanup trap"      "grep -q 'trap sandbox_cleanup EXIT' '$RUNNER'"

# ── 4. --help exits 0 and documents the gates ──────────────────────────────
out=$(bash "$RUNNER" --help 2>&1); rc=$?
check "--help exits 0"                "[ $rc -eq 0 ]"
check "--help mentions --e2e"         "printf '%s' \"\$out\" | grep -q -e '--e2e'"
check "--help mentions --privileged"  "printf '%s' \"\$out\" | grep -q -e '--privileged'"
check "--help mentions RUN_PRIVILEGED" "printf '%s' \"\$out\" | grep -q 'RUN_PRIVILEGED'"
check "--unknown flag exits 2"        "bash '$RUNNER' --nope >/dev/null 2>&1; [ \$? -eq 2 ]"

# ── 5. Behavioural: shims intercept sudo and mutate nothing ────────────────
beh=$(RUN_PRIVILEGED=0 bash -c "
  . '$SANDBOX'
  sandbox_init
  sandbox_activate
  echo \"active=\$TEST_SANDBOX_ACTIVE\"
  echo \"dir=\$TEST_SANDBOX_DIR\"
  echo \"which_sudo=\$(command -v sudo)\"
  sudo apt-get install -y somepkg >/dev/null 2>&1; echo \"rc=\$?\"
  sandbox_log_since 0
  sandbox_cleanup
  echo \"dir_after=[\$TEST_SANDBOX_DIR]\"
" 2>&1)
_beh_dir=$(printf '%s\n' "$beh" | sed -n 's/^dir=//p' | head -1)

check "sandbox activates when RUN_PRIVILEGED=0" "printf '%s' \"\$beh\" | grep -q '^active=1\$'"
check "sandbox dir is created"                "[ -n '$_beh_dir' ]"
check "sudo resolves inside the sandbox dir"  "printf '%s' \"\$beh\" | grep -qE '^which_sudo=.*test-sandbox\..*/sudo\$'"
check "shimmed sudo returns success"           "printf '%s' \"\$beh\" | grep -q '^rc=0\$'"
check "shimmed sudo never ran apt-get"        "printf '%s' \"\$beh\" | grep -q '^sudo apt-get install -y somepkg\$'"
check "apt-get was not reached directly"      "! printf '%s' \"\$beh\" | grep -q '^apt-get install'"
check "cleanup clears TEST_SANDBOX_DIR"       "printf '%s' \"\$beh\" | grep -q '^dir_after=\[\]\$'"
check "cleanup removes the sandbox dir"       "[ ! -d '$_beh_dir' ]"

# A real privileged command must NOT be reachable inside the sandbox.
REAL=$(RUN_PRIVILEGED=0 bash -c "
  . '$SANDBOX'
  sandbox_init
  sandbox_activate
  p=\$(command -v sudo)
  case \"\$p\" in *test-sandbox*|*_sandbox_shim) echo SHIMMED ;; *) echo \"REAL:\$p\" ;; esac
  sandbox_cleanup
" 2>&1)
check "sudo is shimmed, never the real binary" "printf '%s' \"\$REAL\" | grep -q '^SHIMMED\$'"

# ── 6. Behavioural: RUN_PRIVILEGED=1 disables the sandbox ─────────────────
PRIV=$(RUN_PRIVILEGED=1 bash -c "
  . '$SANDBOX'
  sandbox_init
  echo \"active=\$TEST_SANDBOX_ACTIVE\"
  echo \"log=\${TEST_SANDBOX_LOG:-empty}\"
" 2>/dev/null)
check "RUN_PRIVILEGED=1 leaves sandbox off" "printf '%s' \"\$PRIV\" | grep -q '^active=0\$'"
check "RUN_PRIVILEGED=1 creates no log"     "printf '%s' \"\$PRIV\" | grep -q '^log=empty\$'"
check "RUN_PRIVILEGED=1 warns loudly"       "RUN_PRIVILEGED=1 bash -c \". '$SANDBOX'; sandbox_init\" 2>&1 | grep -q 'RUN_PRIVILEGED=1'"

# ── 7. Behavioural: e2e gate skips by default ──────────────────────────────
SEC=$(bash "$RUNNER" --section e2e 2>&1)
check "--section e2e skips without --e2e"  "printf '%s' \"\$SEC\" | grep -q 'SKIP'"
check "--section e2e counts skipped files" "printf '%s' \"\$SEC\" | grep -qE '[1-9][0-9]* skipped'"

# ── 8. 47-lynis.sh stubs out every privileged binary it can reach ─────────
LYNIS="$PROJECT_DIR/tests/unit/test_lynis.sh"
check "test_lynis.sh exists" "[ -f '$LYNIS' ]"
for mock in sudo apt-get gpg; do
  check "test_lynis.sh stubs $mock" "grep -qF '$mock() { echo \"mock-$mock' '$LYNIS'"
done
check "test_lynis.sh isolates HOME in STUBS" "grep -q 'export HOME=' '$LYNIS'"

echo ""
echo "  PASS: $PASS  FAIL: $FAIL"
if [ "$FAIL" -gt 0 ]; then
  echo "  RESULT: FAIL"
  exit 1
fi
echo "  RESULT: PASS"
exit 0