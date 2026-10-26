#!/usr/bin/env bash
# audit-module-reachability.sh — find src/lib modules that no entrypoint can reach.
#
# The orchestrator grew to 161 modules by accretion; some families were never
# wired into setup.sh or dev.sh and are exercised only by their own unit tests.
# This audit walks the real reference graph:
#
#   roots  : setup.sh, dev.sh, src/modes/*.sh, scripts/*.sh
#   edges  : every literal `src/lib/<name>.sh` occurrence in a root or module
#   output : reachable modules, dead modules, dead-but-tested modules
#
# Usage:
#   bash scripts/audit-module-reachability.sh                 # report (exit 0)
#   bash scripts/audit-module-reachability.sh --json          # machine-readable
#   bash scripts/audit-module-reachability.sh --strict        # exit 1 if any dead
#   bash scripts/audit-module-reachability.sh --baseline FILE # exit 1 only on NEW dead
#
# Baseline format: one module basename per line, `#` comments allowed.
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$SCRIPT_DIR"

JSON=false
STRICT=false
BASELINE=""
while [ "$#" -gt 0 ]; do
  case "$1" in
    --json) JSON=true ;;
    --strict) STRICT=true ;;
    --baseline) shift; BASELINE="${1:-}" ;;
    --baseline=*) BASELINE="${1#*=}" ;;
    -h|--help) sed -n '2,20p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "Unknown option: $1" >&2; exit 2 ;;
  esac
  shift
done

refs_of() { # <file> -> basenames of src/lib modules it references
  grep -hoE 'src/lib/[A-Za-z0-9_.-]+\.sh' "$1" 2>/dev/null | sed 's#src/lib/##' | sort -u
}

ROOTS=()
[ -f setup.sh ] && ROOTS+=(setup.sh)
[ -f dev.sh ] && ROOTS+=(dev.sh)
for f in src/modes/*.sh scripts/*.sh; do [ -f "$f" ] && ROOTS+=("$f"); done

# BFS over the reference graph
SEEN=" "
QUEUE=" "
for f in "${ROOTS[@]}"; do
  for m in $(refs_of "$f"); do QUEUE="$QUEUE $m"; done
done
while [ -n "${QUEUE// /}" ]; do
  NEXT=" "
  for m in $QUEUE; do
    case "$SEEN" in *" $m "*) continue ;; esac
    SEEN="$SEEN$m "
    [ -f "src/lib/$m" ] || continue
    for dep in $(refs_of "src/lib/$m"); do NEXT="$NEXT $dep"; done
  done
  QUEUE="$NEXT"
done

ALL=()
for f in src/lib/*.sh; do ALL+=("$(basename "$f")"); done

REACHABLE=()
DEAD=()
for m in "${ALL[@]}"; do
  case "$SEEN" in *" $m "*) REACHABLE+=("$m") ;; *) DEAD+=("$m") ;; esac
done

TESTED=()
for m in "${DEAD[@]}"; do
  if grep -rql -- "$m" tests/ 2>/dev/null; then TESTED+=("$m"); fi
done

# baseline handling
NEW_DEAD=()
if [ -n "$BASELINE" ] && [ -f "$BASELINE" ]; then
  for m in "${DEAD[@]}"; do
    grep -qxF "$m" "$BASELINE" || grep -qE "^[[:space:]]*$m[[:space:]]*(#.*)?$" "$BASELINE" || NEW_DEAD+=("$m")
  done
fi

if $JSON; then
  printf '{"total":%d,"reachable":%d,"dead":%d,"dead_tested":%d,"dead_modules":[' \
    "${#ALL[@]}" "${#REACHABLE[@]}" "${#DEAD[@]}" "${#TESTED[@]}"
  first=1
  for m in "${DEAD[@]}"; do
    [ $first -eq 0 ] && printf ','
    printf '"%s"' "$m"; first=0
  done
  printf ']}\n'
else
  echo "modules: ${#ALL[@]}  reachable: ${#REACHABLE[@]}  dead: ${#DEAD[@]}  (dead but tested: ${#TESTED[@]})"
  if [ "${#DEAD[@]}" -gt 0 ]; then
    echo
    echo "unreachable modules:"
    for m in "${DEAD[@]}"; do
      case " ${TESTED[*]} " in *" $m "*) echo "  $m  [tested]" ;; *) echo "  $m" ;; esac
    done
  fi
  if [ -n "$BASELINE" ] && [ -f "$BASELINE" ]; then
    echo
    if [ "${#NEW_DEAD[@]}" -eq 0 ]; then
      echo "baseline: no new dead modules"
    else
      echo "baseline: NEW dead modules (wire or remove them):" >&2
      printf '  %s\n' "${NEW_DEAD[@]}" >&2
    fi
  fi
fi

if [ "${#NEW_DEAD[@]}" -gt 0 ]; then
  exit 1
fi
if $STRICT && [ "${#DEAD[@]}" -gt 0 ]; then
  exit 1
fi
exit 0
