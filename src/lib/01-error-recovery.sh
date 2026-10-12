#!/usr/bin/env bash
# OpenCode Initializer - Error Recovery Framework (Wave 0.2)
# Retry logic, graceful degradation, error isolation.
# Designed to be SOURCED by setup.sh — no `set -euo pipefail` here
# (strict mode must not leak into the parent shell).

ER_MAX_RETRIES="${OPENCODE_MAX_RETRIES:-3}"
ER_RETRY_DELAY="${OPENCODE_RETRY_DELAY:-2}"
ER_ERROR_LOG="${OPENCODE_ERROR_LOG:-/tmp/opencode-errors.log}"

declare -gA ER_SEVERITY=( ["CRITICAL"]=3 ["HIGH"]=2 ["MEDIUM"]=1 ["LOW"]=0 )
declare -ga ER_FAILED_STEPS=()
declare -gA ER_STEP_STATUS=()

# Guarded: never override global log_error() from 00y-logging.sh
er_log() {
    local level="$1" message="$2" timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] [$level] $message" >> "$ER_ERROR_LOG" 2>/dev/null || true
    case "$level" in
        CRITICAL|HIGH) printf '\033[31m[%s]\033[0m %s\n' "$level" "$message" >&2 ;;
        MEDIUM)        printf '\033[33m[MEDIUM]\033[0m %s\n' "$message" ;;
        *)             printf '\033[36m[LOW]\033[0m %s\n' "$message" ;;
    esac
}

retry_with_backoff() {
    local func_name="$1"
    local max_attempts="${2:-$ER_MAX_RETRIES}"
    local delay="${3:-$ER_RETRY_DELAY}"
    local attempt=1

    while [ "$attempt" -le "$max_attempts" ]; do
        if [ "$attempt" -gt 1 ]; then
            er_log "LOW" "Retry attempt $attempt/$max_attempts for $func_name (delay: ${delay}s)"
            sleep "$delay"
        fi
        if "$func_name"; then
            return 0
        fi
        attempt=$((attempt + 1))
        delay=$((delay * 2))   # exponential backoff
    done

    er_log "HIGH" "All retry attempts failed for $func_name"
    return 1
}

safe_execute() {
    local step_name="$1"
    shift

    ER_STEP_STATUS["$step_name"]="running"
    if "$@"; then
        ER_STEP_STATUS["$step_name"]="success"
        return 0
    else
        ER_STEP_STATUS["$step_name"]="failed"
        ER_FAILED_STEPS+=("$step_name")
        er_log "MEDIUM" "Step '$step_name' failed: $*"
        return 1
    fi
}

continue_on_error() {
    local step_name="$1"
    shift
    safe_execute "$step_name" "$@" || true
}

abort_on_critical_error() {
    local step_name="$1"
    local critical_condition="$2"
    if eval "$critical_condition"; then
        er_log "CRITICAL" "Critical error in step '$step_name' - aborting"
        print_recovery_guide
        return 1
    fi
    return 0
}

print_recovery_guide() {
    echo ""
    echo "======================================================="
    echo "                   RECOVERY GUIDE                      "
    echo "======================================================="
    echo ""
    echo "Failed steps: ${#ER_FAILED_STEPS[@]}"
    local step
    for step in "${ER_FAILED_STEPS[@]}"; do
        echo "  [x] $step"
    done
    echo ""
    echo "To resume from last successful step:"
    echo "  bash setup.sh --full   (WAL progress is tracked)"
    echo ""
    echo "Health check first:"
    echo "  bash setup.sh --health"
    echo ""
    echo "Error log: $ER_ERROR_LOG"
    echo "======================================================="
}

check_step_status() {
    echo "${ER_STEP_STATUS[$1]:-unknown}"
}

get_failed_steps() {
    [ ${#ER_FAILED_STEPS[@]} -gt 0 ] && printf '%s\n' "${ER_FAILED_STEPS[@]}"
    return 0
}

reset_error_state() {
    ER_FAILED_STEPS=()
    ER_STEP_STATUS=()
    : > "$ER_ERROR_LOG" 2>/dev/null || true
    er_log "LOW" "Error state reset"
}

# Foundation module (sourced early by setup.sh bootstrap). Register load
# completion with the step framework so module coverage checks see it.
type _step_done &>/dev/null && _step_done step_error_recovery || true
