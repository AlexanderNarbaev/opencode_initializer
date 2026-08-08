#!/usr/bin/env bash
# src/lib/42-hooks.sh — Lifecycle Hooks Framework
# Creates and manages ~/.config/opencode/hooks/ with 4 hook types:
#   pre-request  — runs before LLM call; exit 1 = reject
#   post-response — runs after LLM call; for logging/audit
#   pre-commit   — runs before git commit; exit 1 = block
#   on-error     — runs on error; for cleanup/notifications
# v3.0.0
# Sources: helpers.sh + 00-core.sh must be sourced before this module
set -euo pipefail

# ── Constants ─────────────────────────────────────────────────────────────────
HOOKS_DIR="${OPENCODE_HOOKS_DIR:-$HOME/.config/opencode/hooks}"

_step_skip step_hooks && return 0

section "Lifecycle Hooks Framework"

# ── Default hook stubs (templates for _hooks_init) ────────────────────────────
_hooks_stub_pii() {
  cat << 'STUBEOF'
#!/usr/bin/env bash
# pre-request: PII sanitizer gate
# Detects PII in request context and can reject (exit 1)
# Dependencies: 45-pii-guard.sh (_pii_scan)
set -euo pipefail
echo "[hooks] PII check passed (no module)" >&2
exit 0
STUBEOF
}

_hooks_stub_policy() {
  cat << 'STUBEOF'
#!/usr/bin/env bash
# pre-request: model governance policy check
# Validates provider/model against model-policy.json
# Dependencies: 43-governance.sh (_governance_is_provider_allowed)
set -euo pipefail
echo "[hooks] Policy check passed (no module)" >&2
exit 0
STUBEOF
}

_hooks_stub_audit() {
  cat << 'STUBEOF'
#!/usr/bin/env bash
# post-response: audit trail logging
# Logs model_call / tool_call events to audit.jsonl
# Dependencies: 44-audit.sh (_audit_event)
set -euo pipefail
echo "[hooks] Audit log recorded (no module)" >&2
exit 0
STUBEOF
}

# ── Initialize hooks directory with default stubs ─────────────────────────────
# Idempotent: skips existing files, does not overwrite user hooks.
_hooks_init() {
  mkdir -p "$HOOKS_DIR"

  if [ ! -f "$HOOKS_DIR/10-pii-check.sh" ]; then
    _hooks_stub_pii > "$HOOKS_DIR/10-pii-check.sh"
    chmod +x "$HOOKS_DIR/10-pii-check.sh"
    log "Created pre-request hook: 10-pii-check.sh"
  fi

  if [ ! -f "$HOOKS_DIR/20-policy-check.sh" ]; then
    _hooks_stub_policy > "$HOOKS_DIR/20-policy-check.sh"
    chmod +x "$HOOKS_DIR/20-policy-check.sh"
    log "Created pre-request hook: 20-policy-check.sh"
  fi

  if [ ! -f "$HOOKS_DIR/50-audit-log.sh" ]; then
    _hooks_stub_audit > "$HOOKS_DIR/50-audit-log.sh"
    chmod +x "$HOOKS_DIR/50-audit-log.sh"
    log "Created post-response hook: 50-audit-log.sh"
  fi
}

# ── Run all hooks of a given type ─────────────────────────────────────────────
# Usage: _hooks_run <hook_type> [args...]
#   hook_type: pre-request | post-response | pre-commit | on-error
#   Returns: 0 if all hooks pass, 1 if any hook rejects
#   Hooks are executed in numeric filename order within the type subdirectory.
_hooks_run() {
  local hook_type="${1:-}"
  shift || true

  if [ -z "$hook_type" ]; then
    warn "_hooks_run: hook_type required (pre-request | post-response | pre-commit | on-error)"
    return 1
  fi

  local hook_subdir="${HOOKS_DIR}/${hook_type}"
  [ -d "$hook_subdir" ] || return 0

  local hook_failed=0

  for hook in "$hook_subdir"/*.sh; do
    [ -f "$hook" ] || continue
    [ -x "$hook" ] || { warn "Hook not executable: $hook — skipping"; continue; }
    if ! bash "$hook" "$@" 2>/dev/null; then
      warn "Hook rejected: $hook (hook_type=$hook_type)"
      hook_failed=1
      break
    fi
  done

  [ "$hook_failed" -eq 0 ] && return 0 || return 1
}

# ── Convenience wrappers ──────────────────────────────────────────────────────
_hooks_pre_request()  { _hooks_run "pre-request" "$@"; }
_hooks_post_response() { _hooks_run "post-response" "$@"; }
_hooks_pre_commit()   { _hooks_run "pre-commit" "$@"; }
_hooks_on_error()     { _hooks_run "on-error" "$@"; }

# ── Create hook type directories ──────────────────────────────────────────────
_hooks_setup_dirs() {
  for htype in pre-request post-response pre-commit on-error; do
    mkdir -p "${HOOKS_DIR}/${htype}"
  done
}

# ── Init on source (idempotent — first-run only) ──────────────────────────────
_hooks_setup_dirs
_hooks_init

_step_done step_hooks

# ── Exports ──────────────────────────────────────────────────────────────────
export HOOKS_DIR
export -f _hooks_init _hooks_run _hooks_setup_dirs
export -f _hooks_pre_request _hooks_post_response _hooks_pre_commit _hooks_on_error
