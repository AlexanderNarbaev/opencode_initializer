#!/usr/bin/env bash
set -euo pipefail
P="$(cd "$(dirname "$0")/../.." && pwd)"
TP=0; TF=0
a() { local d="$1" c="$2"; if (eval "$c") &>/dev/null; then TP=$((TP+1)); else TF=$((TF+1)); echo "    FAIL: $d" >&2; fi }

CH="$P/src/lib/03-chrome.sh"
a "chrome exists" "[ -f $CH ]"
a "chrome syntax" "bash -n $CH"
a "has chromedriver" "grep -q chromedriver $CH"
a "has WSL2 aware" "grep -qi wsl $CH"

PR="$P/src/lib/17-project.sh"
a "project exists" "[ -f $PR ]"
a "project syntax" "bash -n $PR"
a "has AGENTS.md" "grep -q AGENTS.md $PR"
a "has docker-compose" "grep -q compose $PR"

ZS="$P/src/lib/04-zsh.sh"
a "zsh exists" "[ -f $ZS ]"
a "zsh syntax" "bash -n $ZS"
a "has oh-my-zsh" "grep -q oh-my-zsh $ZS"
a "has p10k" "grep -q p10k $ZS"

echo "test_chrome_project_zsh: $TP passed, $TF failed"
