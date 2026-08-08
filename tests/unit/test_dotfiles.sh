#!/usr/bin/env bash
# Unit test for src/lib/27-dotfiles.sh — existence, syntax, key patterns
set -euo pipefail

P="$(cd "$(dirname "$0")/../.." && pwd)"
W="$P/src/lib/27-dotfiles.sh"
TP=0; TF=0

a() { local d="$1" c="$2"; if (eval "$c") &>/dev/null; then TP=$((TP+1)); else TF=$((TF+1)); echo "    FAIL: $d" >&2; fi }

a "exists" "[ -f $W ]"
a "syntax" "bash -n $W"
a "has chezmoi" "grep -q chezmoi $W"
a "has dotfiles" "grep -qi dotfiles $W"
a "has chezmoi init" "grep -q 'chezmoi init' $W"
a "has brew" "grep -q brew $W"
a "has get.chezmoi.io" "grep -q 'get.chezmoi.io' $W"
a "has local share" "grep -q 'local/share/chezmoi' $W"

echo "test_dotfiles: $TP passed, $TF failed"
[ "$TF" -eq 0 ] || exit 1
