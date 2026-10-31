#!/usr/bin/env bash
# dsh-setup.sh — provision the DeepSeek Harness web profile from repo templates
#
# Renders src/data/dsh/cordis.patch.web.yml and src/data/dsh/AGENTS.md into
# $DSH_HOME (default ~/.dsh), links the shared skill library, and validates the
# composed profile with `dsh --dump-config`. Idempotent: unchanged files are left
# alone, changed files are backed up first.
#
# Usage:
#   scripts/dsh-setup.sh --check      # read-only verification (default)
#   scripts/dsh-setup.sh --apply      # write templates + symlink + validate
#   scripts/dsh-setup.sh --dry-run    # print planned actions, change nothing
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DSH_HOME="${DSH_HOME:-$HOME/.dsh}"
PROFILE="${DSH_PROFILE:-web}"
TEMPLATE_DIR="$REPO_ROOT/src/data/dsh"
PATCH_TEMPLATE="$TEMPLATE_DIR/cordis.patch.web.yml"
AGENTS_TEMPLATE="$TEMPLATE_DIR/AGENTS.md"
PATCH_TARGET="$DSH_HOME/profiles/$PROFILE/cordis.patch.yml"
AGENTS_TARGET="$DSH_HOME/AGENTS.md"
SKILLS_SOURCE="$HOME/.config/opencode/skills"
[ -d "$SKILLS_SOURCE" ] || SKILLS_SOURCE="$REPO_ROOT/.opencode/skills"

MODE="check"
case "${1:-}" in
  --check)   MODE="check" ;;
  --apply)   MODE="apply" ;;
  --dry-run) MODE="dry-run" ;;
  -h|--help)
    sed -n '2,14p' "$0" | sed 's/^# \{0,1\}//'
    exit 0
    ;;
  "")
    ;;
  *)
    echo "unknown option: $1 (use --check, --apply or --dry-run)" >&2
    exit 2
    ;;
esac

# Resolve the binary once: non-login shells often miss ~/.npm-global/bin.
DSH_BIN="${DSH_BIN:-}"
if [ -z "$DSH_BIN" ]; then
  if command -v dsh >/dev/null 2>&1; then
    DSH_BIN="$(command -v dsh)"
  elif [ -x "$HOME/.npm-global/bin/dsh" ]; then
    DSH_BIN="$HOME/.npm-global/bin/dsh"
  fi
fi

PASS=0
FAIL=0
CHANGED=0

pass() { PASS=$((PASS + 1)); printf '  OK   %s\n' "$1"; }
fail() { FAIL=$((FAIL + 1)); printf '  FAIL %s\n' "$1" >&2; }
plan() { CHANGED=$((CHANGED + 1)); printf '  PLAN %s\n' "$1"; }

render() { sed "s|__HOME__|$HOME|g" "$1"; }

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT
render "$PATCH_TEMPLATE" > "$tmpdir/patch.yml"
render "$AGENTS_TEMPLATE" > "$tmpdir/AGENTS.md"

echo "DeepSeek Harness profile: $PROFILE (DSH_HOME=$DSH_HOME)"

# ── Prerequisites ─────────────────────────────────────────────────────────
if [ -n "$DSH_BIN" ]; then
  pass "dsh binary present ($("$DSH_BIN" --version 2>/dev/null | head -1))"
else
  fail "dsh binary not found (PATH or ~/.npm-global/bin)"
fi

[ -f "$PATCH_TEMPLATE" ] && [ -f "$AGENTS_TEMPLATE" ] \
  && pass "templates present (src/data/dsh/)" \
  || fail "templates missing under $TEMPLATE_DIR"

[ -d "$SKILLS_SOURCE" ] \
  && pass "skill library present ($SKILLS_SOURCE)" \
  || fail "skill library not found (expected ~/.config/opencode/skills or repo .opencode/skills)"

# ── Desired state ─────────────────────────────────────────────────────────
patch_state="missing"
if [ -f "$PATCH_TARGET" ]; then
  if cmp -s "$tmpdir/patch.yml" "$PATCH_TARGET"; then patch_state="current"; else patch_state="drift"; fi
fi
agents_state="missing"
if [ -f "$AGENTS_TARGET" ]; then
  if cmp -s "$tmpdir/AGENTS.md" "$AGENTS_TARGET"; then agents_state="current"; else agents_state="drift"; fi
fi
skills_state="missing"
if [ -L "$DSH_HOME/skills" ]; then
  if [ "$(readlink -f "$DSH_HOME/skills")" = "$(readlink -f "$SKILLS_SOURCE")" ]; then skills_state="current"; else skills_state="drift"; fi
elif [ -e "$DSH_HOME/skills" ]; then
  skills_state="drift"
fi
mcp_state="missing"
[ -d "$DSH_HOME/mcp" ] && mcp_state="current"

if [ "$MODE" = "check" ]; then
  [ "$patch_state" = "current" ] && pass "profile patch current" || fail "profile patch $patch_state ($PATCH_TARGET)"
  [ "$agents_state" = "current" ] && pass "user AGENTS.md current" || fail "user AGENTS.md $agents_state ($AGENTS_TARGET)"
  [ "$skills_state" = "current" ] && pass "skills symlink current" || fail "skills symlink $skills_state ($DSH_HOME/skills)"
  [ "$mcp_state" = "current" ] && pass "memory dir present" || fail "memory dir missing ($DSH_HOME/mcp)"
  if [ -n "$DSH_BIN" ] && [ "$patch_state" = "current" ]; then
    if "$DSH_BIN" --profile "$PROFILE" --dump-config >/dev/null 2>"$tmpdir/dump.err"; then
      pass "profile composes (dsh --dump-config)"
    else
      fail "profile does not compose: $(head -1 "$tmpdir/dump.err")"
    fi
  fi
else
  # ── Apply / dry-run ─────────────────────────────────────────────────────
  if [ "$MODE" = "dry-run" ]; then
    for state in patch agents skills mcp; do
      case "$state" in
        patch)  [ "$patch_state" = "current" ] || plan "write $PATCH_TARGET ($patch_state)" ;;
        agents) [ "$agents_state" = "current" ] || plan "write $AGENTS_TARGET ($agents_state)" ;;
        skills) [ "$skills_state" = "current" ] || plan "link $DSH_HOME/skills -> $SKILLS_SOURCE ($skills_state)" ;;
        mcp)    [ "$mcp_state" = "current" ] || plan "create $DSH_HOME/mcp" ;;
      esac
    done
    [ "$CHANGED" -eq 0 ] && echo "  nothing to change"
    echo "dsh: dry-run — no files written"
    exit 0
  fi

  mkdir -p "$DSH_HOME/mcp" "$(dirname "$PATCH_TARGET")"
  if [ "$mcp_state" != "current" ]; then pass "created $DSH_HOME/mcp"; fi

  install_file() { # <rendered> <target> <label>
    local src="$1" dst="$2" label="$3"
    if [ -f "$dst" ] && cmp -s "$src" "$dst"; then
      pass "$label already current"
      return 0
    fi
    if [ -f "$dst" ]; then
      local backup="$dst.bak.$(date +%Y%m%d-%H%M%S)"
      cp -p "$dst" "$backup"
      echo "  INFO backup $backup"
    fi
    cp "$src" "$dst"
    pass "$label written"
  }
  install_file "$tmpdir/patch.yml" "$PATCH_TARGET" "profile patch"
  install_file "$tmpdir/AGENTS.md" "$AGENTS_TARGET" "user AGENTS.md"

  if [ "$skills_state" != "current" ]; then
    if [ -e "$DSH_HOME/skills" ] && [ ! -L "$DSH_HOME/skills" ]; then
      mv "$DSH_HOME/skills" "$DSH_HOME/skills.bak.$(date +%Y%m%d-%H%M%S)"
    fi
    ln -sfn "$SKILLS_SOURCE" "$DSH_HOME/skills"
    pass "skills symlink -> $SKILLS_SOURCE"
  else
    pass "skills symlink already current"
  fi

  if [ -n "$DSH_BIN" ]; then
    if "$DSH_BIN" --profile "$PROFILE" --dump-config >/dev/null 2>"$tmpdir/dump.err"; then
      pass "profile composes (dsh --dump-config)"
    else
      fail "profile does not compose: $(head -1 "$tmpdir/dump.err")"
    fi
  fi
fi

echo "dsh-setup: $PASS ok, $FAIL failed ($MODE)"
[ "$FAIL" -eq 0 ]
