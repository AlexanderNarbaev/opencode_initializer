#!/usr/bin/env bash
# test_software_factory_wiring.sh — Software Factory modules are reachable
#
# Context: setup.sh used to only `source` the 13 Software Factory modules and
# never call `_run_step` on them, so the whole wave was dead code at install
# time (registries never created, model policy / audit chain never
# initialised, the maintainability score never ran). `33-spec-registry.sh list`
# additionally died with "log_warn: command not found" because the modules call
# log_info/log_warn from 00y-logging.sh, which setup.sh and dev.sh never
# sourced.
#
# This test asserts that the modules are wired into the real step flow, that
# the logging shim is installed before them, and that the new `dev` subcommands
# actually work against a throwaway project root.
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../test_lib.sh"

SETUP="$PROJECT_DIR/setup.sh"
DEV="$PROJECT_DIR/dev.sh"
LIB="$PROJECT_DIR/src/lib"
FIXTURE="$(mktemp -d)"
# Hermetic HOME for the setup.sh dry-runs below: a polluted shared
# ~/.cache/opencode-setup/progress must never hide scheduled steps. All
# runtime state paths are $HOME-derived (helpers.sh:89 DL_CACHE,
# 00-core.sh:190 PROGRESS="$DL_CACHE/progress", setup.sh:42 setup-log dir),
# so a temp HOME fully isolates the dry-run from the host.
# Single combined EXIT trap: a second trap on EXIT replaces the first.
SFW_TMP="$(mktemp -d)"
trap 'rm -rf "$FIXTURE" "$SFW_TMP"' EXIT

SF_MODULES="33-spec-registry 34-token-cache 35-debt-intent-registry 41-model-policy 42-pii-guard 43-audit-chain 44-offline-bundle 45-maintainability-score 50-product-review 51-architecture-doc 52-program-design 53-vertical-slices 54-agent-handoff"

# ── Files exist and parse ────────────────────────────────────────────────────
assert "setup.sh syntax OK" "bash -n '$SETUP'"
assert "dev.sh syntax OK"    "bash -n '$DEV'"

for m in $SF_MODULES; do
  assert "$m module file present" "[ -f '$LIB/$m.sh' ]"
done

# ── setup.sh: every Software Factory module has a real _run_step ─────────────
for m in $SF_MODULES; do
  assert "$m wired into _run_step" "grep -q '_run_step step_[a-z_]* .*lib/$m\.sh' '$SETUP'"
done

sf_steps="$(grep -c '_run_step step_sf_' "$SETUP")"
assert "13 Software Factory steps registered" "[ '$sf_steps' -eq 13 ]"

# ── _run_step supports an entry function (4th arg) ──────────────────────────
# Modules that only *define* functions produce no observable effect as steps
# unless the step invokes one after sourcing.
assert "_run_step accepts a 4th entry-function argument" \
  "grep -q 'local step_entry=\"\${4:-}\"' '$SETUP'"
assert "_run_step invokes the entry function after sourcing" \
  "grep -q 'declare -f \"\$step_entry\"' '$SETUP'"
assert "each SF step passes an entry function" \
  "! grep '_run_step step_sf_' '$SETUP' | grep -qvE '_sf_step_[a-z_]+[[:space:]]*$'"

# ── setup.sh: the logging shim precedes the modules (fixes log_warn) ────────
assert "setup.sh sources 00y-logging.sh for the SF modules" \
  "grep -q 'src/lib/00y-logging.sh' '$SETUP'"
assert "setup.sh defines a log_success shim" "grep -q 'log_success()' '$SETUP'"
log_line="$(grep -n '00y-logging.sh' "$SETUP" | head -1 | cut -d: -f1)"
first_sf_step="$(grep -n '_run_step step_sf_' "$SETUP" | head -1 | cut -d: -f1)"
assert "logging shim is loaded before the first SF step" \
  "[ -n \"$log_line\" ] && [ -n \"$first_sf_step\" ] && [ \"$log_line\" -lt \"$first_sf_step\" ]"

# ── setup.sh: gating (default install stays cheap) ─────────────────────────
assert "SOFTWARE_FACTORY_ENABLED gate present"  "grep -q 'SOFTWARE_FACTORY_ENABLED' '$SETUP'"
assert "registry tier gate present"             "grep -q 'SOFTWARE_FACTORY_REGISTRY' '$SETUP'"
assert "governance tier gate present"           "grep -q 'SOFTWARE_FACTORY_GOVERNANCE' '$SETUP'"
assert "design tier gate present"               "grep -q 'SOFTWARE_FACTORY_DESIGN' '$SETUP'"
assert "scoring tier is opt-in (default false)" "grep -q 'SOFTWARE_FACTORY_SCORE:-false' '$SETUP'"
assert "tier predicates are not inverted" \
  "! grep -q 'SOFTWARE_FACTORY_REGISTRY:-true\"   = \"false\"' '$SETUP'"

# ── setup.sh: CLI flags ─────────────────────────────────────────────────────
for flag in --software-factory --no-software-factory --software-factory-registry \
            --software-factory-governance --software-factory-design --software-factory-score; do
  assert "setup.sh parses $flag" "grep -q '^  $flag)' '$SETUP'"
  assert "setup.sh --help documents $flag" "bash '$SETUP' --help 2>&1 | grep -q -- '$flag'"
done

# ── setup.sh: the default install must stay cheap ──────────────────────────
# --software-factory-score is the only tier that walks the whole source tree,
# so it must be opt-in. Assert it on a real dry-run.
DRY_DEFAULT="$(SUDO_PASS="" SKIP_MIRROR_RESOLVE=true HOME="$SFW_TMP" timeout 300 bash "$SETUP" --dry-run 2>&1 | sed -e 's/\x1b\[[0-9;]*m//g')"
# History: these asserts originally used `grep -q`; CI runs rotated failing
# tier names run-to-run while the debug dump below PROVED the same capture
# contained every line. SIGPIPE/pipefail could NOT be reproduced locally
# (grep -q returned 0 at every size/offset on the dev machine), so the true
# root cause is under active verification via the debug dump. The asserts now
# consume the whole capture (`grep '...' >/dev/null`) — a safe superset fix —
# while the debug block fingerprints the capture (len, sha256, per-tier
# match counts, toolchain versions) so the next red run is triage-complete.
printf 'DRY_DEBUG_SF_LINES:\n%s\n' "$(printf '%s' "$DRY_DEFAULT" | grep 'Software Factory' | head -16)"
printf 'DRY_DEBUG_LEN=%s SHA=%s\n' "${#DRY_DEFAULT}" "$(printf '%s' "$DRY_DEFAULT" | sha256sum | cut -d' ' -f1)"
printf 'DRY_DEBUG_BASH=%s GREP=%s PIPEFAIL=%s\n' "$BASH_VERSION" "$(grep --version | head -1)" \
  "$(set -o | grep pipefail | tr -s ' ' | tail -c 30)"
for step in "Spec Registry" "Token Cache" "Model Policy" "Audit Chain"; do
  printf 'DRY_DEBUG_MATCH[%s]=%s\n' "$step" \
    "$(printf '%s' "$DRY_DEFAULT" | grep -c "Software Factory: $step")"
done
assert "default dry-run does not run the maintainability scoring step" \
  "! printf '%s' \"\$DRY_DEFAULT\" | grep 'Software Factory: Maintainability Score' >/dev/null"
# The cheap tiers (mkdir / tiny config files) ARE on by default — that is the
# point of the wiring; only the tree-walking scoring step stays opt-in.
for step in "Spec Registry" "Token Cache" "Model Policy" "Audit Chain"; do
  assert "default dry-run runs the cheap tier '$step'" \
    "printf '%s' \"\$DRY_DEFAULT\" | grep 'Software Factory: $step' >/dev/null"
done

DRY_FULL="$(SUDO_PASS="" SKIP_MIRROR_RESOLVE=true HOME="$SFW_TMP" timeout 300 bash "$SETUP" --dry-run --software-factory 2>&1 | sed -e 's/\x1b\[[0-9;]*m//g')"
for step in "Spec Registry" "Token Cache" "Debt/Intent Registry" "Model Policy" \
            "PII Guard" "Audit Chain" "Offline Bundle" "Product Review" \
            "Architecture Doc" "Program Design" "Vertical Slices" "Agent Handoff" \
            "Maintainability Score"; do
  assert "--software-factory schedules '$step'" \
    "printf '%s' \"\$DRY_FULL\" | grep 'Software Factory: $step' >/dev/null"
done

DRY_OFF="$(SUDO_PASS="" SKIP_MIRROR_RESOLVE=true HOME="$SFW_TMP" timeout 300 bash "$SETUP" --dry-run --no-software-factory 2>&1 | sed -e 's/\x1b\[[0-9;]*m//g')"
assert "--no-software-factory schedules nothing" \
  "! printf '%s' \"\$DRY_OFF\" | grep 'Software Factory:' >/dev/null"

# ── dev.sh: new subcommands exist and are dispatched exactly once ──────────
for fn in cmd_maintainability cmd_spec cmd_debt cmd_intent; do
  assert "dev.sh defines $fn()" "grep -q \"^$fn()\" '$DEV'"
done
for verb in maintainability spec debt intent; do
  n="$(grep -c "^  $verb)$" "$DEV")"
  assert "dev.sh dispatches '$verb' exactly once" "[ '$n' -eq 1 ]"
done
assert "dev.sh documents the new commands" \
  "bash '$DEV' --help 2>&1 | grep -q 'dev maintainability'"
assert "dev.sh unknown-command hint lists the new commands" \
  "grep -q 'maintainability|spec|debt|intent' '$DEV'"

# ── dev.sh: modules are sourced at dispatcher scope ────────────────────────
# `source` inside a function makes the module's top-level `declare -a`
# (VALID_PACKAGE_KINDS in 33-spec-registry.sh) local to that function, which
# made `register_spec` reject every kind with "Invalid package kind: feat".
assert "spec module sourced outside a command function" \
  "awk '/^  spec\\)/{found=1} found && /source .*33-spec-registry.sh/{print; exit}' '$DEV' | grep -q '33-spec-registry.sh'"
assert "validate VALID_PACKAGE_KINDS survives sourcing" \
  "bash -c 'source \"$LIB/33-spec-registry.sh\"; printf \"%s\n\" \"\${VALID_PACKAGE_KINDS[@]}\"' 2>/dev/null | grep -q '^feat$'"

# ── Functional: the step entry functions produce their artifacts ───────────
# Reproduces what _run_step does (source module + call the entry point) in an
# isolated HOME/root so the repo is never touched.
SF_ROOT="$FIXTURE/root"
SF_HOME="$FIXTURE/home"
mkdir -p "$SF_HOME"

run_entry() {
  # run_entry <module-basename> <entry-function>
  (
    export HOME="$SF_HOME"
    export OPENCODE_ROOT="$SF_ROOT"
    export MAINTAINABILITY_CACHE="$SF_HOME/.cache/maintainability"
    # shellcheck source=/dev/null
    source "$PROJECT_DIR/src/lib/helpers.sh" >/dev/null 2>&1
    # shellcheck source=/dev/null
    source "$PROJECT_DIR/src/lib/00y-logging.sh" >/dev/null 2>&1
    declare -f log_success >/dev/null 2>&1 || log_success() { log_info "$*"; }
    # shellcheck source=/dev/null
    source "$LIB/$1.sh" >/dev/null 2>&1
    # shellcheck disable=SC2086
    eval "$2"
  ) >/dev/null 2>&1
}

# Same, but forwards arguments to the entry point.
run_entry_arg() {
  (
    export HOME="$SF_HOME"
    export OPENCODE_ROOT="$SF_ROOT"
    export MAINTAINABILITY_CACHE="$SF_HOME/.cache/maintainability"
    # shellcheck source=/dev/null
    source "$PROJECT_DIR/src/lib/helpers.sh" >/dev/null 2>&1
    # shellcheck source=/dev/null
    source "$PROJECT_DIR/src/lib/00y-logging.sh" >/dev/null 2>&1
    declare -f log_success >/dev/null 2>&1 || log_success() { log_info "$*"; }
    # shellcheck source=/dev/null
    source "$LIB/$1.sh" >/dev/null 2>&1
    shift
    "$@"
  ) >/dev/null 2>&1
}

assert "entry: init_spec_registry creates the catalog" \
  "run_entry 33-spec-registry init_spec_registry && [ -f '$SF_ROOT/specs/catalog.json' ]"
assert "entry: init_token_cache creates the cache dir" \
  "run_entry 34-token-cache init_token_cache && [ -d '$SF_ROOT/.cache/tokens' ]"
assert "entry: init_registry creates debt + intent ledgers" \
  "run_entry 35-debt-intent-registry init_registry && [ -f '$SF_ROOT/discipline/registry/debt.jsonl' ] && [ -f '$SF_ROOT/discipline/registry/intent.jsonl' ]"
assert "entry: model_policy_init writes model-policy.json" \
  "run_entry 41-model-policy model_policy_init && [ -f '$SF_HOME/.config/opencode/model-policy.json' ]"
assert "entry: pii guard redacts an email" \
  "run_entry 42-pii-guard true && bash -c 'source \"$LIB/42-pii-guard.sh\"; pii_sanitize \"a b@x.io\"' 2>/dev/null | grep -q REDACTED"
assert "entry: audit_init creates the audit chain dir" \
  "run_entry 43-audit-chain audit_init && [ -d '$SF_HOME/.cache/opencode/audit' ]"
assert "entry: offline bundle dir is created" \
  "run_entry 44-offline-bundle 'mkdir -p \"\${_BUNDLE_DIR:-/nonexistent/sf}\"' && [ -d '$SF_HOME/.cache/opencode/bundles' ]"
assert "entry: product-review dirs are created" \
  "run_entry 50-product-review 'mkdir -p \"\$MODULE_50_DIR\" \"\$MODULE_50_TEMPLATE_DIR\"' && [ -d '$SF_ROOT/.opencode/product-reviews' ] && [ -d '$SF_ROOT/src/templates/product-review' ]"
assert "entry: architecture-doc dir is created" \
  "run_entry 51-architecture-doc 'mkdir -p \"\$MODULE_51_DIR\"' && [ -d '$SF_ROOT/.opencode/architecture-docs' ]"
assert "entry: program-design dir is created" \
  "run_entry 52-program-design 'mkdir -p \"\$MODULE_52_DIR\"' && [ -d '$SF_ROOT/.opencode/program-designs' ]"
assert "entry: vertical-slices dir is created" \
  "run_entry 53-vertical-slices 'mkdir -p \"\$MODULE_53_DIR\"' && [ -d '$SF_ROOT/.opencode/vertical-slices' ]"
assert "entry: agent-handoff dir is created" \
  "run_entry 54-agent-handoff 'mkdir -p \"\$MODULE_54_DIR\"' && [ -d '$SF_ROOT/.opencode/agent-handoffs' ]"

assert "entry: maintainability score returns a number" \
  "run_entry_arg 45-maintainability-score calculate_maintainability_score '$SF_ROOT' text 0 && [ -d '$SF_HOME/.cache/maintainability' ]"
assert "entry: maintainability score writes a JSON cache" \
  "[ \"\$(ls '$SF_HOME/.cache/maintainability'/score_*.json 2>/dev/null | wc -l)\" -ge 1 ]"

# ── Functional: dev subcommands against the throwaway root ─────────────────
dev_run() { HOME="$SF_HOME" OPENCODE_ROOT="$SF_ROOT" SKIP_MIRROR_RESOLVE=true \
                      NONINTERACTIVE=true timeout 120 bash "$DEV" "$@" 2>/dev/null; }

out="$(dev_run maintainability)"
assert "dev maintainability prints a numeric score" \
  "printf '%s' \"\$out\" | sed -e 's/\\x1b\\[[0-9;]*m//g' | grep -E 'MAINTAINABILITY SCORE: [0-9]+/100' >/dev/null"
assert "dev maintainability exits 0" \
  "HOME='$SF_HOME' OPENCODE_ROOT='$SF_ROOT' SKIP_MIRROR_RESOLVE=true bash '$DEV' maintainability >/dev/null 2>&1"

if command -v jq >/dev/null 2>&1; then
  assert "dev maintainability json emits valid JSON" \
    "dev_run maintainability json | jq -e '.overall_score | type == \"number\"' >/dev/null 2>&1"
fi

# dev spec list must not fail with the missing log helper any more.
spec_out="$(dev_run spec list)"
assert "dev spec list runs without 'command not found'" \
  "! printf '%s' \"\$spec_out\" | grep 'command not found' >/dev/null"
spec_err="$(HOME="$SF_HOME" OPENCODE_ROOT="$SF_ROOT" SKIP_MIRROR_RESOLVE=true bash "$DEV" spec list 2>&1 >/dev/null)"
assert "dev spec list has no missing-helper error on stderr" \
  "! printf '%s' \"\$spec_err\" | grep 'log_warn: command not found' >/dev/null"
assert "dev spec register + list round-trips" \
  "dev_run spec register feat demo 'Demo' 'demo spec' 1.0.0 approved >/dev/null && dev_run spec list | grep -q 'spec://feat/demo'"

assert "dev debt add + list round-trips" \
  "dev_run debt add D-1 perf high slow 'walks tree' >/dev/null && dev_run debt list | grep -q 'D-1'"
assert "dev intent add + list round-trips" \
  "dev_run intent add I-1 'use jq' 'no jq dep' '[]' 'jq removed' >/dev/null && dev_run intent list | grep -q 'I-1'"

cleanup_test