#!/usr/bin/env bash
# check-version-consistency.sh — one canonical version, enforced everywhere.
#
# Source of truth: package.json "version" (semantic-release writes it).
# Every other declared version must match it exactly:
#   .version, SCRIPT_VERSION (src/lib/00-core.sh), pyproject.toml, apm.yml,
#   CLI_VERSION (src/cli.sh), setup.sh header, README/docs H1.
#
# Exit 0 when aligned, 1 on any drift (prints a per-file table).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$SCRIPT_DIR"

V="$(jq -r '.version' package.json)"
FAIL=0

check() { # <label> <actual>
  local label="$1" actual="$2"
  if [ "$actual" = "$V" ]; then
    printf '  ok    %-22s %s\n' "$label" "$actual"
  else
    printf '  DRIFT %-22s %s (expected %s)\n' "$label" "${actual:-<missing>}" "$V" >&2
    FAIL=$((FAIL + 1))
  fi
}

parse() { # <file> <sed-expr>
  sed -nE "$2" "$1" 2>/dev/null | head -1 | sed -E 's/^v//'
}

check ".version"            "$(parse .version 's/^v([0-9.]+)$/\1/p')"
check "SCRIPT_VERSION"      "$(parse src/lib/00-core.sh 's/.*SCRIPT_VERSION:-(v[0-9.]+).*/\1/p')"
check "pyproject.toml"      "$(parse pyproject.toml 's/^version = "([0-9.]+)"$/\1/p')"
check "apm.yml"             "$(parse apm.yml 's/^version: ([0-9.]+)$/\1/p')"
check "CLI_VERSION"         "$(parse src/cli.sh 's/.*CLI_VERSION="([0-9.]+)".*/\1/p')"
check "setup.sh header"     "$(parse setup.sh 's/.*Bootstrap v([0-9.]+).*/\1/p')"
check "README.md H1"        "$(parse README.md 's/^# OpenCode Initializer v([0-9.]+)$/\1/p')"
check "docs/index.en.md H1" "$(parse docs/index.en.md 's/^# OpenCode Initializer v([0-9.]+)$/\1/p')"
check "docs/index.ru.md H1" "$(parse docs/index.ru.md 's/^# OpenCode Initializer v([0-9.]+)$/\1/p')"

if [ "$FAIL" -ne 0 ]; then
  echo "version-consistency: FAIL ($FAIL drift(s), canonical $V)" >&2
  exit 1
fi
echo "version-consistency: OK ($V)"
