#!/usr/bin/env bash
# oc-json — JSON mode wrapper for OpenCode
# Takes a prompt as argument, runs opencode non-interactively, outputs JSON
set -euo pipefail

if [ $# -lt 1 ]; then
  echo '{"error": "Usage: oc-json <prompt> [--model MODEL] [--workdir DIR]"}' >&2
  exit 1
fi

PROMPT="$1"
shift

MODEL="${OPENCODE_MODEL:-deepseek/deepseek-v4-pro}"
WORKDIR="${PWD}"
JSON_FILE=$(mktemp /tmp/oc-json-output.XXXXXX.json)
trap 'rm -f "$JSON_FILE"' EXIT

while [ $# -gt 0 ]; do
  case "$1" in
    --model) MODEL="$2"; shift 2 ;;
    --workdir) WORKDIR="$2"; shift 2 ;;
    *) shift ;;
  esac
done

json_result() {
  local status="$1" output="$2" error="$3"
  printf '{"status": "%s", "output": %s, "stderr": %s, "model": "%s"}\n' \
    "$status" \
    "$(python3 -c "import json,sys; json.dump(sys.argv[1], sys.stdout)" "$output" 2>/dev/null || echo '""')" \
    "$(python3 -c "import json,sys; json.dump(sys.argv[1], sys.stdout)" "$error" 2>/dev/null || echo '""')" \
    "$MODEL"
}

if opencode --model "$MODEL" "$PROMPT" --non-interactive 2>"$JSON_FILE.error" 1>"$JSON_FILE.output"; then
  OUTPUT=$(cat "$JSON_FILE.output")
  ERROR=$(cat "$JSON_FILE.error" 2>/dev/null || true)
  json_result "success" "$OUTPUT" "$ERROR"
else
  EXIT_CODE=$?
  OUTPUT=$(cat "$JSON_FILE.output" 2>/dev/null || true)
  ERROR=$(cat "$JSON_FILE.error" 2>/dev/null || true)
  json_result "error" "$OUTPUT" "$ERROR"
  exit $EXIT_CODE
fi
