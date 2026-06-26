#!/usr/bin/env bash
# oc-rpc — Simple HTTP RPC server for OpenCode
# Exposes opencode as an HTTP endpoint on localhost:9999
# Requires socat; falls back to nc if socat is unavailable
set -euo pipefail

PORT="${OC_RPC_PORT:-9999}"
OPENCODE="${OPENCODE_BIN:-opencode}"

rpc_response() {
  local code="$1" body="$2"
  printf 'HTTP/1.1 %s\r\nContent-Type: application/json\r\nContent-Length: %d\r\nConnection: close\r\n\r\n%s' \
    "$code" "${#body}" "$body"
}

handle_request() {
  local method path content_length body prompt output json_response

  read -r method path _ || { exit 0; }
  method="${method%%$'\r'}"

  content_length=0
  while IFS= read -r line; do
    line="${line%%$'\r'}"
    [ -z "$line" ] && break
    if [[ "${line,,}" =~ ^content-length:[[:space:]]*([0-9]+) ]]; then
      content_length="${BASH_REMATCH[1]}"
    fi
  done

  if [[ "$path" == /health* ]]; then
    json_response='{"status":"ok","service":"oc-rpc","port":'"$PORT"'}'
    rpc_response "200 OK" "$json_response"
    return
  fi

  if [[ "$path" == /list-models* ]]; then
    json_response=$(curl -sf http://localhost:4000/v1/models 2>/dev/null || echo '{"data":[{"id":"deepseek/deepseek-v4-pro"}]}')
    rpc_response "200 OK" "$json_response"
    return
  fi

  prompt=""
  if [ "$content_length" -gt 0 ] 2>/dev/null; then
    if [ "$content_length" -gt 65536 ]; then
      json_response='{"error":"Request body too large"}'
      rpc_response "413 Payload Too Large" "$json_response"
      return
    fi
    body=$(dd bs=1 count="$content_length" 2>/dev/null 2>&1 || true)
    prompt=$(echo "$body" | python3 -c "import json,sys; print(json.load(sys.stdin).get('prompt',''))" 2>/dev/null || true)
  else
    prompt="${path#/}"
    prompt="${prompt//+/ }"
    prompt=$(python3 -c "import urllib.parse,sys; print(urllib.parse.unquote(sys.argv[1]))" "$prompt" 2>/dev/null || echo "$prompt")
  fi

  if [ -z "${prompt:-}" ]; then
    json_response='{"error":"No prompt provided. Send GET /<prompt> or POST {\"prompt\":\"...\"}"}'
    rpc_response "400 Bad Request" "$json_response"
    return
  fi

  output=$($OPENCODE --non-interactive "$prompt" 2>&1) || true
  json_response=$(python3 -c "
import json, sys
json.dump({'result': sys.argv[1], 'prompt': sys.argv[2]}, sys.stdout)
" "$output" "$prompt" 2>/dev/null || echo '{"result":"","error":"response encoding failed"}')

  rpc_response "200 OK" "$json_response"
}

if [ "${1:-}" = "--handle" ]; then
  handle_request
  exit 0
fi

if command -v socat &>/dev/null; then
  echo "oc-rpc starting on http://localhost:$PORT (socat mode)"
  socat TCP-LISTEN:"$PORT",reuseaddr,fork EXEC:"$0 --handle",nofork
elif command -v nc &>/dev/null; then
  echo "oc-rpc starting on http://localhost:$PORT (nc mode)"
  while true; do
    nc -l -p "$PORT" -c "$0 --handle" 2>/dev/null || true
    sleep 0.1
  done
else
  echo "ERROR: socat or nc required for RPC mode. Install socat: sudo apt install socat"
  exit 1
fi
