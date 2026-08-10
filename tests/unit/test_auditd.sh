#!/usr/bin/env bash
# ============================================================================
# Unit Test for 48-auditd.sh — Linux Kernel Audit Daemon
# Session: ses_auditd_test
# ============================================================================
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
TESTS_PASS=0; TESTS_FAIL=0
A="$PROJECT_DIR/src/lib/48-auditd.sh"

assert() {
  local d="$1" c="$2"
  if (eval "$c") &>/dev/null; then
    TESTS_PASS=$((TESTS_PASS + 1))
  else
    TESTS_FAIL=$((TESTS_FAIL + 1))
    echo "    FAIL: $d" >&2
  fi
}

# ── 1. File existence & syntax ───────────────────────────────────────────
assert "48-auditd.sh exists" "[ -f '$A' ]"
assert "48-auditd.sh syntax clean" "bash -n '$A'"

# ── 2. Core functions ────────────────────────────────────────────────────
assert "has _auditd_install()" "grep -q '_auditd_install()' '$A'"
assert "has _auditd_apply_rules()" "grep -q '_auditd_apply_rules()' '$A'"

# ── 3. Step tracking ─────────────────────────────────────────────────────
assert "has step_auditd skip check" "grep -q 'step_auditd' '$A'"
assert "has _step_done step_auditd" "grep -q '_step_done step_auditd' '$A'"
assert "has section header" "grep -q 'section.*auditd' '$A'"

# ── 4. auditd install logic ──────────────────────────────────────────────
assert "checks systemctl is-active auditd" "grep -q 'systemctl is-active auditd' '$A'"
assert "installs via apt-get" "grep -q 'apt-get install.*auditd' '$A'"
assert "enables via systemctl" "grep -q 'systemctl enable auditd' '$A'"
assert "starts via systemctl" "grep -q 'systemctl start auditd' '$A'"
assert "has audispd-plugins" "grep -q 'audispd-plugins' '$A'"

# ── 5. audit rules file ──────────────────────────────────────────────────
assert "has rules file path" "grep -q '/etc/audit/rules.d/99-opencode.rules' '$A'"
assert "has rules idempotency check" "grep -q 'already present' '$A'"
assert "has augenrules --load" "grep -q 'augenrules --load' '$A'"
assert "has service auditd restart fallback" "grep -q 'service auditd restart' '$A'"

# ── 6. Audit rule keys ───────────────────────────────────────────────────
assert "has -k identity rules" "grep -q '\-k identity' '$A'"
assert "has -k network rules" "grep -q '\-k network' '$A'"
assert "has -k cron rules" "grep -q '\-k cron' '$A'"
assert "has -k sudo_usage rule" "grep -q '\-k sudo_usage' '$A'"

# ── 7. Monitored files ───────────────────────────────────────────────────
assert "monitors /etc/passwd" "grep -q '/etc/passwd' '$A'"
assert "monitors /etc/shadow" "grep -q '/etc/shadow' '$A'"
assert "monitors /etc/sudoers" "grep -q '/etc/sudoers\b' '$A'"
assert "monitors /etc/hosts" "grep -q '/etc/hosts' '$A'"
assert "monitors /etc/resolv.conf" "grep -q '/etc/resolv.conf' '$A'"
assert "monitors /etc/crontab" "grep -q '/etc/crontab' '$A'"

# ── 8. Kernel audit rule lines count (13 rules in source) ─────────────────
RULES_COUNT=$(grep -cE '^\-w |^\-a ' "$A" 2>/dev/null || echo 0)
assert "has 13+ audit rules" "[ '$RULES_COUNT' -ge 13 ]"

# ── 9. Architecture awareness ────────────────────────────────────────────
assert "has arch=b64" "grep -q 'arch=b64' '$A'"
assert "has auid check" "grep -q 'auid>=1000' '$A'"

# ── 10. Module structure ─────────────────────────────────────────────────
assert "has set -euo pipefail" "grep -q 'set -euo pipefail' '$A'"
assert "has shebang" "head -1 '$A' | grep -q '#!/usr/bin/env bash'"

echo "test_auditd: $TESTS_PASS passed, $TESTS_FAIL failed"
[ "$TESTS_FAIL" -eq 0 ] || exit 1
