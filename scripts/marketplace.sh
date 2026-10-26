#!/usr/bin/env bash
# marketplace.sh — curated plugin/MCP/skill marketplaces for the OpenCode stack.
#
# Commands:
#   list                 table of known marketplaces (id, kind, url)
#   json [kind]          raw registry (optionally filtered by kind: plugins|mcp|skills)
#   check                HTTP reachability of every marketplace URL
#   search <query>       npm registry search (default query: opencode-plugin)
#
# Data source: src/data/marketplaces.json
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DATA="$SCRIPT_DIR/src/data/marketplaces.json"

[ -f "$DATA" ] || { echo "marketplaces.json not found: $DATA" >&2; exit 1; }
command -v jq >/dev/null 2>&1 || { echo "jq is required" >&2; exit 1; }

cmd="${1:-list}"; shift || true

case "$cmd" in
  list)
    printf '%-20s %-8s %s\n' "ID" "KIND" "URL"
    jq -r '.marketplaces[] | [.id, .kind, .url] | @tsv' "$DATA" |
      while IFS=$'\t' read -r id kind url; do
        printf '%-20s %-8s %s\n' "$id" "$kind" "$url"
      done
    echo
    echo "install hints:"
    jq -r '.marketplaces[] | "  \(.id): \(.install)"' "$DATA"
    ;;
  json)
    kind="${1:-}"
    if [ -n "$kind" ]; then
      jq --arg k "$kind" '{version, marketplaces: [.marketplaces[] | select(.kind == $k)]}' "$DATA"
    else
      cat "$DATA"
    fi
    ;;
  check)
    fail=0
    jq -r '.marketplaces[].url' "$DATA" | while IFS= read -r url; do
      code=$(curl -s -o /dev/null -w '%{http_code}' --max-time 10 -L "$url" 2>/dev/null || echo 000)
      case "$code" in
        2*|3*) printf '  ok    %s  %s\n' "$code" "$url" ;;
        *)     printf '  FAIL  %s  %s\n' "$code" "$url" ;;
      esac
    done
    # Recompute failures in the parent shell (the loop above runs in a pipeline).
    fail=$(jq -r '.marketplaces[].url' "$DATA" | while IFS= read -r url; do
      code=$(curl -s -o /dev/null -w '%{http_code}' --max-time 10 -L "$url" 2>/dev/null || echo 000)
      case "$code" in 2*|3*) ;; *) echo x ;; esac
    done | wc -l)
    [ "$fail" -eq 0 ] || exit 1
    ;;
  search)
    q="${1:-opencode-plugin}"
    curl -s --max-time 15 "https://registry.npmjs.org/-/v1/search?text=$(printf '%s' "$q" | sed 's/ /%20/g')&size=20" \
      | jq -r '.objects[]?.package | "\(.name)\t\(.version)\t\(.date[0:10])\t\(.description[0:80] // "")"' \
      | column -t -s $'\t' 2>/dev/null || true
    ;;
  -h|--help|help)
    sed -n '2,12p' "$0" | sed 's/^# \{0,1\}//'
    ;;
  *)
    echo "Unknown: $cmd (use: list|json|check|search)" >&2
    exit 2
    ;;
esac
