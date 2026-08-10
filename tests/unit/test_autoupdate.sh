#!/usr/bin/env bash
# Test 20-autoupdate.sh — Auto-update system (topgrade + systemd timer)
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
TESTS_PASS=0; TESTS_FAIL=0
TMP_DIR=$(mktemp -d)
trap 'rm -rf "$TMP_DIR"' EXIT

assert() {
  local desc="$1" condition="$2"
  if (eval "$condition") &>/dev/null; then TESTS_PASS=$((TESTS_PASS + 1)); else TESTS_FAIL=$((TESTS_FAIL + 1)); echo "    FAIL: $desc" >&2; fi
}

S="$PROJECT_DIR/src/lib/20-autoupdate.sh"

echo "=== Testing 20-autoupdate.sh ==="

# ── File structure checks ──────────────────────────────────────────────────
assert "20-autoupdate.sh exists" "[ -f '$S' ]"
assert "20-autoupdate.sh syntax valid" "bash -n '$S'"
assert "has shebang" "head -1 '$S' | grep -q '#!/usr/bin/env bash'"
assert "has set -euo pipefail" "grep -q 'set -euo pipefail' '$S'"

# ── Air-gap gate ───────────────────────────────────────────────────────────
assert "has ISOLATED_CIRCUIT gate" "grep -q 'ISOLATED_CIRCUIT' '$S'"
assert "ISOLATED skips autoupdate" "grep -q 'ISOLATED: skipped' '$S'"
assert "air-gap returns early" "grep -q 'return 0' '$S'"
assert "has step_autoupdate" "grep -q 'step_autoupdate' '$S'"

# ── topgrade installation ──────────────────────────────────────────────────
assert "has topgrade" "grep -q 'topgrade' '$S'"
assert "topgrade cargo install" "grep -q 'cargo install topgrade' '$S'"
assert "topgrade apt fallback" "grep -q 'apt-get.*topgrade' '$S'"

# ── abtop installation ─────────────────────────────────────────────────────
assert "has abtop" "grep -q 'abtop' '$S'"
assert "abtop cargo install" "grep -q 'cargo install abtop' '$S'"

# ── systemd timer ──────────────────────────────────────────────────────────
assert "has systemctl" "grep -q 'systemctl' '$S'"
assert "has systemd user dir" "grep -q 'systemd/user' '$S'"
assert "has opencode-update.service" "grep -q 'opencode-update.service' '$S'"
assert "has opencode-update.timer" "grep -q 'opencode-update.timer' '$S'"
assert "timer OnCalendar Sun 04:00" "grep -q 'Sun 04:00' '$S'"
assert "timer Persistent=true" "grep -q 'Persistent=true' '$S'"
assert "timer RandomizedDelaySec" "grep -q 'RandomizedDelaySec' '$S'"
assert "timer daemon-reload" "grep -q 'daemon-reload' '$S'"
assert "timer enable" "grep -q 'systemctl.*enable' '$S'"
assert "timer start" "grep -q 'systemctl.*start' '$S'"

# ── unattended-upgrades ────────────────────────────────────────────────────
assert "has unattended-upgrades" "grep -q 'unattended-upgrades' '$S'"
assert "has dpkg-reconfigure" "grep -q 'dpkg-reconfigure' '$S'"
assert "has 50unattended-upgrades config" "grep -q '50unattended-upgrades' '$S'"

# ── Mode gating ────────────────────────────────────────────────────────────
assert "has MODE=full guard" "grep -q 'MODE.*full' '$S'"
assert "has MODE=reinit guard" "grep -q 'MODE.*reinit' '$S'"
assert "has MODE=update guard" "grep -q 'MODE.*update' '$S'"
assert "has INTERACTIVE_DO_SYSTEM gate" "grep -q 'INTERACTIVE_DO_SYSTEM' '$S'"

# ── Section header ─────────────────────────────────────────────────────────
assert "has Auto-update section" "grep -q 'Auto-update' '$S'"

echo "test_autoupdate: $TESTS_PASS passed, $TESTS_FAIL failed"
[ "$TESTS_FAIL" -eq 0 ] || exit 1
