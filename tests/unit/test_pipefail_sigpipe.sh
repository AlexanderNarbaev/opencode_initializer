#!/usr/bin/env bash
# test_pipefail_sigpipe.sh — regression guard for the SIGPIPE + pipefail hazard.
#
# Root cause (confirmed — see the header comment of
# tests/unit/test_software_factory_wiring.sh):
#   A capture assertion of the form
#       printf '%s' "$CAPTURE" | grep -q 'needle'
#   is unsafe when the capture is larger than the pipe buffer. `grep -q`
#   exits as soon as it finds a match; the still-writing `printf` producer
#   then hits a closed pipe. Depending on the shell build the producer is
#   either killed by SIGPIPE (status 141 = 128 + SIGPIPE) or its builtin
#   reports "write error: Broken pipe" and returns non-zero. `pipefail`
#   promotes that producer status to the whole pipeline, so the assertion
#   fails (or becomes untrustworthy) even though the needle IS present.
#   Which assertion failed depended on where the needle sat in the capture,
#   which is why CI reported a rotating set of failing tier names.
#
# The safe form reads the whole stream and discards it:
#       printf '%s' "$CAPTURE" | grep 'needle' >/dev/null
#
# This test pins the mechanism down deterministically and guards the
# Software Factory wiring test against a regression to the early-exit form.
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../test_lib.sh"

finish() {
  local rc=$?
  if [ "$rc" -ne 0 ]; then
    echo "pipefail_sigpipe: aborted with status $rc before completing all asserts"
    exit "$rc"
  fi
  cleanup_test
}

trap finish EXIT

# The payload must exceed any plausible pipe buffer (64 KiB on Linux, 16 KiB
# on macOS) so that the hazard is deterministic, not size-dependent.
CHUNK_WIDTH=1024
CHUNK_COUNT=1024

make_payload() {
  local chunk
  local i
  printf -v chunk '%01024d' 0
  # The needle sits in the very first line, so an early-exit consumer stops
  # reading almost immediately and the producer is cut off mid-write.
  printf 'NEEDLE_AT_FRONT\n' || return 1
  i=0
  while [ "$i" -lt "$CHUNK_COUNT" ]; do
    printf '%s\n' "$chunk" || return 1
    i=$((i + 1))
  done
}

printf 'pipefail_sigpipe: payload chunks=%s chunk_width=%s\n' "$CHUNK_COUNT" "$CHUNK_WIDTH"

BIG_CAPTURE="$(make_payload)"

# --- Case 1: the early-exit capture (grep -q) cuts the producer off ---------
# PIPESTATUS must be copied as the very next statement after the pipeline:
# any later simple command (even an assignment) resets it. The producer's
# fate is poisoned in both manifestations of the hazard — SIGPIPE death (141)
# or a reported write error (non-zero) — while grep itself still reports the
# match (rc=0).
printf '%s' "$BIG_CAPTURE" 2>/dev/null | grep -q 'NEEDLE_AT_FRONT'
EARLY_PS=("${PIPESTATUS[@]}")
EARLY_PRODUCER_RC="${EARLY_PS[0]}"
EARLY_GREP_RC="${EARLY_PS[1]}"
printf 'pipefail_sigpipe: early-exit (grep -q) producer rc=%s grep rc=%s (pipeline status is poisoned although the match is present)\n' \
  "$EARLY_PRODUCER_RC" "$EARLY_GREP_RC"

# --- Case 2: the full-read capture always succeeds -------------------------
printf '%s' "$BIG_CAPTURE" | grep 'NEEDLE_AT_FRONT' >/dev/null
FULL_PS=("${PIPESTATUS[@]}")
FULL_PRODUCER_RC="${FULL_PS[0]}"
FULL_GREP_RC="${FULL_PS[1]}"
printf 'pipefail_sigpipe: full-read (grep >/dev/null) producer rc=%s grep rc=%s\n' \
  "$FULL_PRODUCER_RC" "$FULL_GREP_RC"

assert "early-exit consumer cuts the producer off although the match is present" \
  "[ '$EARLY_PRODUCER_RC' -ne 0 ] && [ '$EARLY_GREP_RC' -eq 0 ]"
assert "full-read consumer lets the producer finish the capture cleanly" \
  "[ '$FULL_PRODUCER_RC' -eq 0 ] && [ '$FULL_GREP_RC' -eq 0 ]"

# --- Case 3: the Software Factory wiring test must keep full-read captures -
# Every large capture in that test is a $DRY_* variable. The hazard is an
# early-exit consumer (`| grep -q`) fed by such a capture; a file-sized
# `grep -q` and the small `bash ... --help | grep -q` pipelines are safe and
# are deliberately NOT flagged here. Comment lines are skipped, so the
# documented example of the hazardous form does not trip the guard.
SF_TEST="${SCRIPT_DIR}/test_software_factory_wiring.sh"
SF_HAZARD_RE='\$DRY_[A-Z_]+[^|]*\|([^|]*\|)?[^|]*grep[[:space:]]+(-{1,2}[A-Za-z]+[[:space:]]+)*-{1,2}[A-Za-z]*q'
SF_EARLY_COUNT="$(grep -v '^[[:space:]]*#' "$SF_TEST" | grep -cE "$SF_HAZARD_RE" || true)"
printf 'pipefail_sigpipe: test_software_factory_wiring.sh early-exit captures of large captures=%s\n' \
  "$SF_EARLY_COUNT"
assert "Software Factory wiring test never early-exits on a large capture" \
  "[ '$SF_EARLY_COUNT' -eq 0 ]"

# --- Case 4: the temporary DRY_DEBUG fingerprint block must be gone --------
SF_DRY_DEBUG_COUNT="$(grep -c 'DRY_DEBUG' "$SF_TEST" || true)"
printf 'pipefail_sigpipe: test_software_factory_wiring.sh DRY_DEBUG occurrences=%s\n' \
  "$SF_DRY_DEBUG_COUNT"
assert "Software Factory wiring test contains no DRY_DEBUG fingerprint block" \
  "[ '$SF_DRY_DEBUG_COUNT' -eq 0 ]"

# --- Case 5: the confirmed root cause must stay documented -----------------
SF_ROOT_CAUSE_COUNT="$(grep -c 'Root cause (confirmed)' "$SF_TEST" || true)"
printf 'pipefail_sigpipe: test_software_factory_wiring.sh root-cause comment occurrences=%s\n' \
  "$SF_ROOT_CAUSE_COUNT"
assert "Software Factory wiring test documents the confirmed root cause" \
  "[ '$SF_ROOT_CAUSE_COUNT' -ge 1 ]"

# --- Case 6: no test may use the early-exit pipeline on a captured variable --
# `echo "$capture" | grep -q ...` kills the producer with SIGPIPE under
# `set -o pipefail`, making the assertion fail even when the match is present.
# Captured variables must be fed with a here-string: `grep -q ... <<< "$capture"`.
TEST_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
HAZARD_TOTAL=0
for f in "$TEST_ROOT"/unit/*.sh "$TEST_ROOT"/integration/*.sh "$TEST_ROOT"/e2e/*.sh; do
  n="$(grep -v '^[[:space:]]*#' "$f" | grep -cE 'echo "\$[A-Za-z_][A-Za-z0-9_]*"[[:space:]]*\|[[:space:]]*grep[[:space:]]+-[A-Za-z]*q' || true)"
  HAZARD_TOTAL=$((HAZARD_TOTAL + n))
done
printf 'pipefail_sigpipe: early-exit pipelines over captured variables=%s\n' "$HAZARD_TOTAL"
assert "no test pipes a captured variable into grep -q" "[ '$HAZARD_TOTAL' -eq 0 ]"
