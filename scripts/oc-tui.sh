#!/usr/bin/env bash
# oc-tui — Terminal UI wrapper for OpenCode
# Uses dialog/whiptail for interactive prompt construction
# Falls back to plain prompt if neither is available
set -euo pipefail

OPENCODE="${OPENCODE_BIN:-opencode}"

# ── Cost / Cache view ────────────────────────────────────────────────────
cost_view() {
  local COST_TABLE="${XDG_CONFIG_HOME:-$HOME/.config}/opencode/model-router/cost-table.json"
  local SCRIPT_DIR ROUTING CFG
  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  ROUTING="$SCRIPT_DIR/../src/data/routing.json"
  CFG=""
  if [ -f "$COST_TABLE" ]; then
    CFG="$COST_TABLE"
  elif [ -f "$ROUTING" ]; then
    CFG="$ROUTING"
  fi

  echo "Cost / Cache (per 1M tokens, USD)"
  echo "────────────────────────────────"
  if [ -z "$CFG" ]; then
    echo "(no cost data yet — run setup.sh)"
    return 0
  fi

  python3 - "$CFG" << 'PY'
import json, sys, glob, os
path = sys.argv[1]
try:
    data = json.load(open(path))
except Exception:
    print("(no cost data yet — run setup.sh)")
    sys.exit(0)
table = data.get("cost_table", data) if isinstance(data, dict) else {}
if not isinstance(table, dict) or not table:
    print("(no cost data yet — run setup.sh)")
    sys.exit(0)
for model, e in sorted(table.items()):
    if not isinstance(e, dict):
        continue
    inp = e.get("input", 0.0)
    out = e.get("output", 0.0)
    print("  %-32s in $%-8s out $%s" % (model, inp, out))
cache_dir = os.path.expanduser("~/.cache/opencode")
hits = total = 0
for f in glob.glob(os.path.join(cache_dir, "*.jsonl")):
    try:
        for line in open(f):
            try:
                rec = json.loads(line)
            except Exception:
                continue
            if isinstance(rec, dict) and ("cache_hit" in rec or "hit" in rec):
                total += 1
                if rec.get("cache_hit", rec.get("hit", False)):
                    hits += 1
    except Exception:
        continue
if total:
    print("  cache hit rate: %.1f%% (%d/%d)" % (100.0 * hits / total, hits, total))
else:
    print("  cache hit rate: (no cache logs yet)")
PY
}

# Direct invocation: `oc-tui.sh cost` or `oc-tui.sh --cost`
if [ "${1:-}" = "cost" ] || [ "${1:-}" = "--cost" ]; then
  cost_view
  exit 0
fi

if command -v dialog &>/dev/null; then
  DIALOG="dialog"
  DIALOG_ARGS=""
elif command -v whiptail &>/dev/null; then
  DIALOG="whiptail"
  DIALOG_ARGS=""
else
  echo "⚠ dialog/whiptail not found — using plain prompt mode"
  read -r -p "Enter your prompt: " PROMPT
  if [ -z "${PROMPT:-}" ]; then
    echo "No prompt provided. Exiting."
    exit 0
  fi
  exec $OPENCODE "$PROMPT"
fi

MODEL=$($DIALOG $DIALOG_ARGS --title "OpenCode TUI" --menu "Select model:" 15 60 6 \
  "deepseek/deepseek-v4-pro"   "DeepSeek V4 Pro (recommended)" \
  "deepseek/deepseek-v4-flash" "DeepSeek V4 Flash (fast)" \
  "openai/gpt-5"               "OpenAI GPT-5" \
  "anthropic/claude-sonnet-4"  "Anthropic Claude Sonnet 4" \
  3>&1 1>&2 2>&3) || exit 0

PROMPT=$($DIALOG $DIALOG_ARGS --title "OpenCode TUI" --inputbox "Enter your prompt:" 10 60 \
  3>&1 1>&2 2>&3) || exit 0

if [ -z "${PROMPT:-}" ]; then
  echo "No prompt provided. Exiting."
  exit 0
fi

exec $OPENCODE --model "$MODEL" "$PROMPT"
