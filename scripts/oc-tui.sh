#!/usr/bin/env bash
# oc-tui — Terminal UI wrapper for OpenCode
# Uses dialog/whiptail for interactive prompt construction
# Falls back to basic prompt if neither is available
set -euo pipefail

OPENCODE="${OPENCODE_BIN:-opencode}"

if command -v dialog &>/dev/null; then
  DIALOG="dialog"
  DIALOG_ARGS=""
elif command -v whiptail &>/dev/null; then
  DIALOG="whiptail"
  DIALOG_ARGS=""
else
  echo "⚠ dialog/whiptail not found — using basic prompt mode"
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
