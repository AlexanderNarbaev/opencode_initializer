#!/usr/bin/env bash
# ============================================================================
# tests/test_sandbox.sh — privileged-command sandbox for the test suite.
#
# Why this exists
# ---------------
# Many unit tests `source` real modules from src/lib/. Module bodies install
# packages (apt-get, dpkg, gpg, snap) through `sudo`. Before this sandbox the
# suite therefore asked apt for a password on interactive machines (the
# terminal hung on "File '/usr/share/keyrings/cisofy-archive-keyring.gpg'
# exists. Overwrite?"), and on passwordless CI runners it silently installed
# lynis on the runner. Ctrl-C could not even kill it because the child sudo
# owned the TTY.
#
# Contract
# --------
#   RUN_PRIVILEGED=0 (default)  privilege-escalating binaries are replaced by
#                               shims placed first on PATH; every intercepted
#                               call is appended to $TEST_SANDBOX_LOG and the
#                               host is left untouched.
#   RUN_PRIVILEGED=1            no shims — tests may really change the machine.
#                               Use only on a throwaway box/container.
#
# Usage
# -----
#   source tests/test_sandbox.sh
#   sandbox_init          # build the shims (honours RUN_PRIVILEGED)
#   sandbox_activate      # prepend shims to PATH + force non-interactive env
#   ...
#   sandbox_report        # dump everything that was intercepted
#   sandbox_cleanup
#
# Design notes
# ------------
# * Only binaries that (a) escalate privilege or (b) mutate the host are
#   shimmed. `tee`, `systemctl --user`, `curl`, `git` are deliberately left
#   alone — tests rely on their real behaviour.
# * A shim is created only for names that already exist on the host, so
#   `command -v apt` keeps reporting the truth on non-Debian machines.
# * Shims never read stdin: `sudo -S` callers pipe a password in, and a shim
#   that swallowed it would break the caller's heredoc.
# ============================================================================

# Binaries that can escalate privilege or mutate the host.
TEST_SANDBOX_SHIMS="sudo doas apt apt-get apt-key add-apt-repository dpkg dpkg-reconfigure gpg"

TEST_SANDBOX_ACTIVE=0
TEST_SANDBOX_DIR=""
TEST_SANDBOX_LOG=""

# Build the shim directory. Honours RUN_PRIVILEGED=1 (no-op, loud warning).
sandbox_init() {
  if [ "${RUN_PRIVILEGED:-0}" = "1" ]; then
    TEST_SANDBOX_ACTIVE=0
    echo "  ⚠ RUN_PRIVILEGED=1 — tests may modify this host!" >&2
    return 0
  fi

  TEST_SANDBOX_DIR="$(mktemp -d "${TMPDIR:-/tmp}/oc-test-sandbox.XXXXXX")"
  TEST_SANDBOX_LOG="$TEST_SANDBOX_DIR/intercepted.log"
  : >"$TEST_SANDBOX_LOG"
  export TEST_SANDBOX_LOG

  local shim="$TEST_SANDBOX_DIR/_sandbox_shim"
  cat >"$shim" <<'SHIM'
#!/usr/bin/env bash
# Injected by tests/test_sandbox.sh — records the call, mutates nothing.
_cmd="${0##*/}"
printf '%s %s\n' "$_cmd" "$*" >>"${TEST_SANDBOX_LOG:-/dev/null}"
exit "${TEST_SANDBOX_EXIT:-0}"
SHIM
  chmod +x "$shim"

  local bin created=0
  for bin in $TEST_SANDBOX_SHIMS; do
    command -v "$bin" >/dev/null 2>&1 || continue
    ln -sf "$shim" "$TEST_SANDBOX_DIR/$bin"
    created=$((created + 1))
  done

  if [ "$created" -eq 0 ]; then
    # Nothing to intercept (no sudo, no package manager) — stay inert rather
    # than inventing binaries that `command -v` would then wrongly report.
    sandbox_cleanup
    return 0
  fi

  TEST_SANDBOX_ACTIVE=1
}

# Put the shims first on PATH and force non-interactive tool behaviour.
# Call once, before spawning any test.
sandbox_activate() {
  export DEBIAN_FRONTEND=noninteractive
  export APT_LISTCHANGES_FRONTEND=none
  export NEEDRESTART_MODE=a
  export GIT_TERMINAL_PROMPT=0
  [ "$TEST_SANDBOX_ACTIVE" = "1" ] || return 0
  PATH="$TEST_SANDBOX_DIR:$PATH"
  export PATH
}

# Line count of the interception log (0 when the sandbox is inert).
sandbox_log_lines() {
  if [ "$TEST_SANDBOX_ACTIVE" != "1" ] || [ ! -f "$TEST_SANDBOX_LOG" ]; then
    echo 0
    return 0
  fi
  wc -l <"$TEST_SANDBOX_LOG" | tr -d ' '
}

# Print everything appended to the log after line $1 (exclusive).
sandbox_log_since() {
  local since="${1:-0}"
  if [ "$TEST_SANDBOX_ACTIVE" != "1" ] || [ ! -f "$TEST_SANDBOX_LOG" ]; then
    return 0
  fi
  tail -n "+$((since + 1))" "$TEST_SANDBOX_LOG"
}

# Print the whole log, if anything was intercepted.
sandbox_report() {
  if [ "$TEST_SANDBOX_ACTIVE" != "1" ] || [ ! -s "$TEST_SANDBOX_LOG" ]; then
    return 0
  fi
  echo "  ── intercepted privileged commands (host NOT modified) ──" >&2
  sandbox_log_since 0 | sed 's/^/    /' >&2
}

sandbox_cleanup() {
  if [ -n "$TEST_SANDBOX_DIR" ] && [ -d "$TEST_SANDBOX_DIR" ]; then
    rm -rf "$TEST_SANDBOX_DIR"
  fi
  TEST_SANDBOX_DIR=""
  TEST_SANDBOX_ACTIVE=0
}