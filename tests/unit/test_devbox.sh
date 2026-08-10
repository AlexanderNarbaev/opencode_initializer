#!/usr/bin/env bash
# Unit test: 28-devbox.sh — Devbox Nix-based isolated dev environments
set -euo pipefail

P="$(cd "$(dirname "$0")/../.." && pwd)"
M="$P/src/lib/28-devbox.sh"
TP=0; TF=0
a() { local d="$1" c="$2"; if (eval "$c") &>/dev/null; then TP=$((TP+1)); else TF=$((TF+1)); echo "    FAIL: $d" >&2; fi }

echo "=== Testing 28-devbox.sh ==="

# ── Module file + syntax ────────────────────────────────────────────────
a "28-devbox.sh exists" "[ -f '$M' ]"
a "28-devbox.sh bash -n clean" "bash -n '$M'"

# ── Key content checks ───────────────────────────────────────────────────
a "has _step_skip gate" "grep -q '_step_skip step_devbox' '$M'"
a "has section output" "grep -q 'section.*Devbox' '$M'"
a "has command -v devbox check" "grep -q 'command -v devbox' '$M'"
a "has _download_verify call" "grep -q '_download_verify.*devbox' '$M'"
a "has devbox install URL" "grep -q 'get.jetify.com/devbox' '$M'"
a "has devbox.json generation" "grep -q 'devbox.json' '$M'"
a "has devbox.json schema URL" "grep -q 'devbox.schema.json' '$M'"
a "has nodejs@latest" "grep -q 'nodejs' '$M'"
a "has python@latest" "grep -q 'python' '$M'"
a "has go@latest" "grep -q 'go@latest' '$M'"
a "has rustup@latest" "grep -q 'rustup' '$M'"
a "has bun@latest" "grep -q 'bun' '$M'"
a "has init_hook" "grep -q 'init_hook' '$M'"
a "has _step_done step_devbox" "grep -q '_step_done step_devbox' '$M'"

# ── setup.sh references ──────────────────────────────────────────────────
S="$P/setup.sh"
a "setup.sh references 28-devbox.sh" "grep -q '28-devbox' '$S'"

echo "test_devbox: $TP passed, $TF failed"
[ "$TF" -eq 0 ] || exit 1
