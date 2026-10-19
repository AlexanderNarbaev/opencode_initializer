#!/usr/bin/env bash
# test_pipefail_sigpipe.sh — regression guard for the SIGPIPE + pipefail hazard.
#
# Root cause (confirmed — see the header comment of
# tests/unit/test_software_factory_wiring.sh):
#   A capture assertion of the form
#       printf '%s' "$CAPTURE" | grep -q 'needle'
#   is unsafe when the capture is larger than the pipe buffer. `grep -q`
#   exits as soon as it finds a match, the still-writing `printf` producer
#   receives EPIPE and dies with status 141 (128 + SIGPIPE), and `pipefail`
#   promotes that 141 to the status of the whole pipeline. The assertion
#   therefore fails even though the needle IS present. Which assertion
#   failed depended on where the needle sat in the capture, which is why CI
#   reported a rotating set of failing tier names.
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

trap cleanup_test EXIT

# The payload must exceed any plausible pipe buffer (64 KiB on Linux, 16 KiB
# on macOS) so that the SIGPIPE death is deterministic, not size-dependent.
CHUNK_WIDTH=1024
CHUNK_COUNT=1024

make_payload() {
  local chunk
  local i
  printf -v chunk '%01024d' 0
  # The needle sits in the very first line, so an early-exit consumer stops
  # reading almost immediately and the producer is killed mid-write.
  printf 'NEEDLE_AT_FRONT\n'
  i=0
  while [ "$i" -lt "$CHUNK_COUNT" ]; do
    printf '%s\n' "$chunk"
    i=$((i + 1))
  done
}

printf 'pipefail_sigpipe: payload chunks=%s chunk_width=%s\n' "$CHUNK_COUNT" "$CHUNK_WIDTH"

# --- Case 1: the early-exit capture (grep -q) is SIGPIPE-prone --------------
EARLY_RC=0
make_payload | grep -q 'NEEDLE_AT_FRONT'
EARLY_RC=$?
printf 'pipefail_sigpipe: early-exit (grep -q) pipeline rc=%s\n' "$EARLY_RC"

# --- Case 2: the full-read capture always succeeds -------------------------
FULL_RC=0
make_payload | grep 'NEEDLE_AT_FRONT' >/dev/null
FULL_RC=$?
printf 'pipefail_sigpipe: full-read (grep >/dev/null) pipeline rc=%s\n' "$FULL_RC"

assert "early-exit capture dies with SIGPIPE status 141" "[ '$EARLY_RC' -eq 141 ]"
assert "full-read capture succeeds despite the large payload" "[ '$FULL_RC' -eq 0 ]"

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
