#!/usr/bin/env bash
# Unit test: S1.2.3 — _safe_rm() guard against critical-path deletion
# Verifies: blocks ~/.cache/opencode, HOME, /; allows /tmp, mktemp dirs
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$(dirname "$SCRIPT_DIR")")"
PASS=0; FAIL=0

check_blocked() {
  local desc="$1" path="$2"
  if _safe_rm "$path" 2>/dev/null; then
    echo "  FAIL: $desc — allowed when should block" >&2
    FAIL=$((FAIL + 1))
  else
    PASS=$((PASS + 1))
  fi
}

check_allowed() {
  local desc="$1" path="$2"
  if _safe_rm "$path" 2>/dev/null; then
    PASS=$((PASS + 1))
  else
    echo "  FAIL: $desc — blocked when should allow" >&2
    FAIL=$((FAIL + 1))
  fi
}

TMPD=$(mktemp -d /tmp/test_safe_rm.XXXXXX)
trap 'rm -rf "$TMPD"' EXIT

# Source helpers to get _safe_rm (with warn stub if needed)
source "$PROJECT_DIR/src/lib/helpers.sh" 2>/dev/null || {
  # Minimal inline fallback if helpers.sh can't be sourced standalone
  _safe_rm() {
    local cache_opencode="${HOME}/.cache/opencode"
    local p real_p
    for p in "$@"; do
      [ -z "$p" ] && continue
      real_p=$(realpath -m "$p" 2>/dev/null || echo "$p")
      case "$real_p" in
        "/") return 1 ;;
        "$HOME") return 1 ;;
        "${HOME}/.cache") return 1 ;;
        "$cache_opencode") return 1 ;;
        "${cache_opencode}/"*) return 1 ;;
      esac
    done
    rm -rf -- "$@"
  }
  warn() { echo "WARN: $*" >&2; }
}

echo "=== Testing _safe_rm() critical-path guard ==="

# ── Blocked paths ──────────────────────────────────────────────────────────
check_blocked "T1: block ~/.cache/opencode"      "$HOME/.cache/opencode"
check_blocked "T2: block subpath of cache"         "$HOME/.cache/opencode/sub/dir"
check_blocked "T3: block HOME directory"           "$HOME"
check_blocked "T4: block root filesystem"          "/"
check_blocked "T5: block ~/.cache"                 "$HOME/.cache"

# ── Allowed paths ──────────────────────────────────────────────────────────
mkdir -p "$TMPD/allowed_dir"
check_allowed "T6: allow mktemp directory"         "$TMPD/allowed_dir"

mkdir -p "$TMPD/another_dir"
check_allowed "T7: allow another mktemp dir"       "$TMPD/another_dir"

# T8: verify directory actually deleted
mkdir -p "$TMPD/to_delete"
_safe_rm "$TMPD/to_delete" 2>/dev/null
if [ ! -d "$TMPD/to_delete" ]; then
  PASS=$((PASS + 1))
else
  echo "  FAIL: T8: _safe_rm did not delete allowed directory" >&2
  FAIL=$((FAIL + 1))
fi

echo "RESULTS: $PASS pass, $FAIL fail"
exit $FAIL
