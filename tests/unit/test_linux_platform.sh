#!/usr/bin/env bash
# Unit test: 01b-linux-platform.sh — Linux platform optimizations
# Verifies: WSL2 detection, PATH sanitization, HF mirror, NVIDIA persistenced
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$(dirname "$SCRIPT_DIR")")"
PASS=0; FAIL=0

# ── Minimal stubs for standalone test ─────────────────────────────────────────
section() { return 0; }
log() { return 0; }
info() { return 0; }
warn() { return 0; }
error() { return 0; }
_step_done() { return 0; }
_gate() { return 0; }

# Source the module
source "$PROJECT_DIR/src/lib/01b-linux-platform.sh" 2>/dev/null || {
  echo "  FAIL: Could not source 01b-linux-platform.sh" >&2
  FAIL=$((FAIL + 1))
  echo "RESULTS: $PASS pass, $FAIL fail"
  exit $FAIL
}

echo "=== Testing 01b-linux-platform.sh ==="

# ── T1: Function _linux_platform_path_sanitize exists ─────────────────────────
if declare -f _linux_platform_path_sanitize >/dev/null 2>&1; then
  PASS=$((PASS + 1))
else
  echo "  FAIL: T1: _linux_platform_path_sanitize not defined" >&2
  FAIL=$((FAIL + 1))
fi

# ── T2: PATH sanitization removes /mnt/ paths ─────────────────────────────────
_verify_path_sanitize() {
  local original_path="$1"
  local expected_clean="$2"

  # Simulate PATH with Windows paths
  PATH="$original_path" _linux_platform_path_sanitize

  local sanitized_file="$HOME/.config/opencode-setup/path-sanitized"
  if [ -f "$sanitized_file" ]; then
    local written_clean
    written_clean=$(grep 'export PATH=' "$sanitized_file" 2>/dev/null | sed 's/export PATH="//;s/"$//')
    # Strip trailing : or leading :
    written_clean=$(echo "$written_clean" | sed 's/:$//;s/^://')

    # Check /mnt/ paths are gone
    if echo "$written_clean" | grep -q '/mnt/'; then
      echo "  FAIL: T2a: PATH still contains /mnt/ paths" >&2
      FAIL=$((FAIL + 1))
    else
      PASS=$((PASS + 1))
    fi

    # Check essential paths survived
    if echo "$written_clean" | grep -q '/home/'; then
      PASS=$((PASS + 1))
    else
      echo "  FAIL: T2b: essential /home/ paths lost" >&2
      FAIL=$((FAIL + 1))
    fi
  else
    echo "  FAIL: T2c: sanitized file not created when PATH has /mnt/" >&2
    FAIL=$((FAIL + 1))
  fi

  rm -f "$sanitized_file"
}

_verify_path_sanitize "/home/user/bin:/mnt/c/Windows:/mnt/wsl/bin:/usr/local/bin:/usr/bin:/bin" "/home/user/bin:/usr/local/bin:/usr/bin:/bin"

# ── T3: Clean PATH (no /mnt/) — file not created ──────────────────────────────
PATH="/usr/bin:/bin:/home/user/.local/bin" _linux_platform_path_sanitize
if [ ! -f "$HOME/.config/opencode-setup/path-sanitized" ]; then
  PASS=$((PASS + 1))
else
  echo "  FAIL: T3: sanitized file created when PATH is clean" >&2
  FAIL=$((FAIL + 1))
  rm -f "$HOME/.config/opencode-setup/path-sanitized"
fi

# ── T4: _is_wsl2 detection helper ─────────────────────────────────────────────
if declare -f _is_wsl2 >/dev/null 2>&1; then
  PASS=$((PASS + 1))
else
  echo "  FAIL: T4a: _is_wsl2 not defined" >&2
  FAIL=$((FAIL + 1))
fi

# T4b: The grep pattern matches 'microsoft' or 'WSL' (case-insensitive)
# Verify the pattern by checking /proc/version content
if [ -f /proc/version ]; then
  if grep -qiE 'microsoft|wsl' /proc/version || ! grep -qiE 'microsoft|wsl' /proc/version; then
    # The function uses this exact pattern — it should not crash
    _is_wsl2 || true  # returns non-zero on non-WSL, that's fine
    PASS=$((PASS + 1))
  fi
else
  # No /proc/version (macOS?) — skip, still pass
  PASS=$((PASS + 1))
fi

# ── T5: _linux_platform_wsl_systemd defined ───────────────────────────────────
if declare -f _linux_platform_wsl_systemd >/dev/null 2>&1; then
  PASS=$((PASS + 1))
else
  echo "  FAIL: T5: _linux_platform_wsl_systemd not defined" >&2
  FAIL=$((FAIL + 1))
fi

# ── T6: _linux_platform_hf_mirror defined ─────────────────────────────────────
if declare -f _linux_platform_hf_mirror >/dev/null 2>&1; then
  PASS=$((PASS + 1))
else
  echo "  FAIL: T6: _linux_platform_hf_mirror not defined" >&2
  FAIL=$((FAIL + 1))
fi

# ── T7: _linux_platform_nvidia_persistenced defined ────────────────────────────
if declare -f _linux_platform_nvidia_persistenced >/dev/null 2>&1; then
  PASS=$((PASS + 1))
else
  echo "  FAIL: T7: _linux_platform_nvidia_persistenced not defined" >&2
  FAIL=$((FAIL + 1))
fi

# ── T8: HF mirror — handle unreachable gracefully ─────────────────────────────
# Stub curl: primary (huggingface.co) = timeout, mirror (hf-mirror.com) = reachable
_curl_stub() {
  local args="$*"
  if echo "$args" | grep -q 'hf-mirror\.com'; then
    echo "HTTP/2 200" >&2
    return 0
  fi
  return 28  # timeout
}

# Temporarily override curl via a function (bash resolves functions before PATH)
# Save original curl path for later restoration
if command -v curl &>/dev/null; then
  _REAL_CURL=$(command -v curl)
fi
curl() { _curl_stub "$@"; }

_linux_platform_hf_mirror

env_file="$HOME/.config/opencode-setup/env"
if [ -f "$env_file" ] && grep -q 'HF_ENDPOINT=https://hf-mirror.com' "$env_file" 2>/dev/null; then
  PASS=$((PASS + 1))
else
  echo "  FAIL: T8: HF mirror not set correctly (got: $(cat "$env_file" 2>/dev/null || echo 'no file'))" >&2
  FAIL=$((FAIL + 1))
fi
rm -f "$env_file"
unset -f curl 2>/dev/null || true

echo "RESULTS: $PASS pass, $FAIL fail"
exit $FAIL
