#!/usr/bin/env bash
set -euo pipefail
# OpenCode Initializer - Module 45: Maintainability Score
# Part of Wave 5: Maintainability Scoring
# 
# Implements maintainability scoring algorithm based on:
# - Test coverage
# - Documentation completeness
# - Code complexity (cyclomatic)
# - Technical debt ratio
# - Spec citation compliance
#
# Usage:
#   source 45-maintainability-score.sh
#   calculate_maintainability_score /path/to/project [text|json] [strict]
#   render_maintainability_dashboard
#   maintainability_ci_gate /path/to/project [threshold]
#
# Exit codes:
#   calculate_maintainability_score  0 = score computed (any band)
#                                  non-zero = genuine failure (bad args, unwritable cache)
#                                  With "strict" as $3 the legacy band codes are returned
#                                  instead: 0 Excellent, 1 Good, 2 Needs Improvement,
#                                  3 Critical.
#   maintainability_ci_gate         0 = score >= threshold, 1 = below threshold
#
# Output contract: progress/summary logs go to STDERR, machine-readable results
# go to STDOUT. With format=json, STDOUT carries the JSON document and nothing
# else (`calculate_maintainability_score . json | jq`); with format=text it
# carries the score banner.
#
# All scoring arithmetic is pure bash integer math (no `bc`, no floats), so the
# result is identical on GNU/Linux and macOS bash 3.2.

# NOTE: sourced by setup.sh — set -euo pipefail is idempotent there (setup.sh already strict).

# Module metadata
MODULE_45_VERSION="1.0.0"
MODULE_45_NAME="Maintainability Score"
MODULE_45_DESCRIPTION="Calculate and track codebase maintainability metrics"

# Configuration
MAINTAINABILITY_CONFIG="${MAINTAINABILITY_CONFIG:-${OPENDCODE_CONFIG_DIR:-$HOME/.config/opencode}/maintainability.toml}"
MAINTAINABILITY_CACHE="${MAINTAINABILITY_CACHE:-${XDG_CACHE_HOME:-$HOME/.cache}/opencode/maintainability}"
MAINTAINABILITY_THRESHOLD_EXCELLENT=${MAINTAINABILITY_THRESHOLD_EXCELLENT:-85}
MAINTAINABILITY_THRESHOLD_GOOD=${MAINTAINABILITY_THRESHOLD_GOOD:-70}
MAINTAINABILITY_THRESHOLD_WARNING=${MAINTAINABILITY_THRESHOLD_WARNING:-50}

# Weights for scoring components
WEIGHT_TEST_COVERAGE=${WEIGHT_TEST_COVERAGE:-30}
WEIGHT_DOCUMENTATION=${WEIGHT_DOCUMENTATION:-25}
WEIGHT_COMPLEXITY=${WEIGHT_COMPLEXITY:-20}
WEIGHT_DEBT_RATIO=${WEIGHT_DEBT_RATIO:-15}
WEIGHT_SPEC_CITATION=${WEIGHT_SPEC_CITATION:-10}

# Colors for output
[[ -z "${COLOR_RED:-}" ]] && COLOR_RED='\033[0;31m' || true
[[ -z "${COLOR_YELLOW:-}" ]] && COLOR_YELLOW='\033[0;33m' || true
[[ -z "${COLOR_GREEN:-}" ]] && COLOR_GREEN='\033[0;32m' || true
[[ -z "${COLOR_BLUE:-}" ]] && COLOR_BLUE='\033[0;34m' || true
[[ -z "${COLOR_NC:-}" ]] && COLOR_NC='\033[0m' || true

#------------------------------------------------------------------------------
# Utility Functions
#------------------------------------------------------------------------------

# NOTE: all logs go to stderr so that `$(metric_fn ...)` captures only the value.
maint_log_info() {
    echo -e "${COLOR_BLUE}[INFO]${COLOR_NC} $*" >&2
}

maint_log_success() {
    echo -e "${COLOR_GREEN}[OK]${COLOR_NC} $*" >&2
}

maint_log_warning() {
    echo -e "${COLOR_YELLOW}[WARN]${COLOR_NC} $*" >&2
}

maint_log_error() {
    echo -e "${COLOR_RED}[ERROR]${COLOR_NC} $*" >&2
}

ensure_cache_dir() {
    mkdir -p "$MAINTAINABILITY_CACHE" 2>/dev/null || {
        maint_log_error "Cannot create cache dir: $MAINTAINABILITY_CACHE"
        return 1
    }
}

#------------------------------------------------------------------------------
# Numeric sanitizers
#
# Every metric is coerced through these before it reaches $(( )) or [ -gt ].
# Historically unsanitized values came from `bc` (which emits "3.00", ".25")
# and from `grep -c ... || echo 0` (which emits "0\n0" when grep finds nothing
# and still exits 1), producing:
#     line 120: 3.00: arithmetic syntax error
#     line 190: 0\n0 : arithmetic syntax error in expression
#     SCORE: /100  (empty variable reaching the banner)
#------------------------------------------------------------------------------

# Coerce any value to a non-negative integer. First line only (kills "0\n0"),
# truncate at the first non-digit (kills "3.00", ".25", "26.00", "abc"), empty → 0.
_maint_int() {
    local v="${1:-}"
    v="${v%%$'\n'*}"
    case "$v" in
        '' ) v=0 ;;
        *[!0-9]* ) v="${v%%[!0-9]*}" ;;
    esac
    printf '%s' "${v:-0}"
}

# Integer clamp: _maint_clamp <value> <lo> <hi>
_maint_clamp() {
    local v="$(_maint_int "$1")" lo="$(_maint_int "$2")" hi="$(_maint_int "$3")"
    [ "$v" -lt "$lo" ] && v="$lo"
    [ "$v" -gt "$hi" ] && v="$hi"
    printf '%s' "$v"
}

# File size in bytes, portable across GNU stat / BSD stat. Empty → 0.
_maint_filesize() {
    local f="$1" sz=""
    [ -f "$f" ] || { printf '0'; return 0; }
    sz="$(stat -c%s "$f" 2>/dev/null)" || sz="$(stat -f%z "$f" 2>/dev/null)" || sz=""
    printf '%s' "$(_maint_int "$sz")"
}

# Count non-zero lines in a stream/file, tolerating a missing path.
# Never emits the "0\n0" produced by `grep -c ... || echo 0`.
_maint_count_matches() {
    local n
    n="$(grep -c "$1" "$2" 2>/dev/null)" || n=0
    printf '%s' "$(_maint_int "$n")"
}

# Ratio → integer percent (0..100), truncation toward zero. No floats.
# _maint_ratio_pct <numerator> <denominator>; denominator 0 → 0
_maint_ratio_pct() {
    local num="$(_maint_int "$1")" den="$(_maint_int "$2")"
    [ "$den" -eq 0 ] && { printf '0'; return 0; }
    printf '%s' "$(( num * 100 / den ))"
}

#------------------------------------------------------------------------------
# Metric Calculators
#------------------------------------------------------------------------------

calculate_test_coverage() {
    local project_root="$1"
    local coverage_score=0
    
    maint_log_info "Calculating test coverage..."
    
    # Count test files vs source files
    local test_files=0
    local source_files=0
    
    if command -v find >/dev/null 2>&1; then
        source_files=$(_maint_int "$(find "$project_root" -name "*.sh" -type f 2>/dev/null | wc -l)")
        test_files=$(_maint_int "$(find "$project_root/tests" -name "test_*.sh" -type f 2>/dev/null | wc -l)")
        
        # Python files
        local py_source
        py_source=$(_maint_int "$(find "$project_root" -name "*.py" -not -path "*/tests/*" -not -path "*/venv/*" -type f 2>/dev/null | wc -l)")
        local py_tests
        py_tests=$(_maint_int "$(find "$project_root/tests" -name "test_*.py" -type f 2>/dev/null | wc -l)")
        
        source_files=$((source_files + py_source))
        test_files=$((test_files + py_tests))
    fi
    
    if [ "$source_files" -gt 0 ]; then
        # Ratio of test to source files (target: 1:1), integer percent.
        if [ "$test_files" -ge "$source_files" ]; then
            coverage_score=100
        else
            coverage_score=$((test_files * 100 / source_files))
        fi
    fi
    
    # Bonus for integration and e2e tests
    local integration_tests
    integration_tests=$(_maint_int "$(find "$project_root/tests/integration" -name "*.sh" -type f 2>/dev/null | wc -l)")
    local e2e_tests
    e2e_tests=$(_maint_int "$(find "$project_root/tests/e2e" -name "*.sh" -type f 2>/dev/null | wc -l)")
    
    if [ "$integration_tests" -gt 5 ]; then
        coverage_score=$((coverage_score + 5))
    fi
    
    if [ "$e2e_tests" -gt 3 ]; then
        coverage_score=$((coverage_score + 5))
    fi
    
    # Cap at 100
    coverage_score=$(_maint_clamp "$coverage_score" 0 100)
    
    printf '%s' "$coverage_score"
}

calculate_documentation_score() {
    local project_root="$1"
    local doc_score=0
    
    maint_log_info "Calculating documentation completeness..."
    
    # Check for essential documentation files
    local essential_docs=(
        "README.md"
        "CHANGELOG.md"
        "CONTRIBUTING.md"
        "docs/architecture/overview.md"
        "docs/getting-started.md"
    )
    
    local found_docs=0
    local doc
    for doc in "${essential_docs[@]}"; do
        if [ -f "$project_root/$doc" ]; then
            found_docs=$((found_docs + 1))
            
            # Bonus for non-empty files (>1000 bytes)
            if [ "$(_maint_filesize "$project_root/$doc")" -gt 1000 ]; then
                found_docs=$((found_docs + 1))
            fi
        fi
    done
    
    # Integer percent of (found / possible). Previously `bc scale=0` truncated
    # 5/10 to 0, so any project below 50% completeness scored a flat 0.
    local total_possible=$((${#essential_docs[@]} * 2))
    doc_score=$(_maint_ratio_pct "$found_docs" "$total_possible")
    
    # Bonus for API docs, ADRs, runbooks
    local adr_count
    adr_count=$(_maint_int "$(find "$project_root/docs/adr" -name "*.md" -type f 2>/dev/null | wc -l)")
    if [ "$adr_count" -gt 5 ]; then
        doc_score=$((doc_score + 10))
    fi
    
    doc_score=$(_maint_clamp "$doc_score" 0 100)
    
    printf '%s' "$doc_score"
}

calculate_complexity_score() {
    local project_root="$1"
    local complexity_score=100  # Start perfect, deduct points
    
    maint_log_info "Calculating code complexity..."
    
    # Average lines per function (target: <50)
    local total_lines=0
    local total_functions=0
    local script lines functions
    
    # while-read instead of `for $(find ...)` so filenames with spaces survive.
    while IFS= read -r script; do
        [ -f "$script" ] || continue
        lines=$(_maint_int "$(wc -l < "$script" 2>/dev/null)")
        functions=$(_maint_count_matches '^[a-z_]*() {' "$script")
        total_lines=$((total_lines + lines))
        total_functions=$((total_functions + functions))
    done <<EOF
$(find "$project_root/src" -name "*.sh" -type f 2>/dev/null)
EOF
    
    if [ "$total_functions" -gt 0 ]; then
        local avg_lines=$((total_lines / total_functions))
        
        if [ "$avg_lines" -gt 100 ]; then
            complexity_score=$((complexity_score - 40))
        elif [ "$avg_lines" -gt 75 ]; then
            complexity_score=$((complexity_score - 25))
        elif [ "$avg_lines" -gt 50 ]; then
            complexity_score=$((complexity_score - 10))
        fi
    fi
    
    # Deduct for deeply nested code (>4 levels of indentation)
    local deep_nesting
    deep_nesting=$(_maint_int "$(grep -r "    " "$project_root/src" --include="*.sh" 2>/dev/null | wc -l)")
    if [ "$deep_nesting" -gt 100 ]; then
        complexity_score=$((complexity_score - 15))
    fi
    
    # Deduct for long lines (>120 chars)
    local long_lines
    long_lines=$(_maint_int "$(grep -r '.\{120,\}' "$project_root/src" --include="*.sh" 2>/dev/null | wc -l)")
    if [ "$long_lines" -gt 50 ]; then
        complexity_score=$((complexity_score - 10))
    fi
    
    complexity_score=$(_maint_clamp "$complexity_score" 0 100)
    
    printf '%s' "$complexity_score"
}

calculate_debt_ratio_score() {
    local project_root="$1"
    local debt_score=100
    
    maint_log_info "Calculating technical debt ratio..."
    
    # Check debt registry
    local debt_file="$project_root/discipline/registry/debt.jsonl"
    local open_debt=0
    local total_debt=0
    
    if [ -f "$debt_file" ]; then
        open_debt=$(_maint_count_matches '"status": *"open"' "$debt_file")
        total_debt=$(_maint_int "$(wc -l < "$debt_file" 2>/dev/null)")
    fi
    
    # Check for TODO/FIXME/HACK comments
    local todo_count
    todo_count=$(_maint_int "$(grep -r "TODO\|FIXME\|HACK" "$project_root/src" --include="*.sh" 2>/dev/null | wc -l)")
    
    # Calculate open-debt share as an integer percent (thresholds: >50/>30/>10).
    # Previously this went through `bc -l` inside $(( )); a registry with no
    # open entries produced the literal "0\n0" and killed the whole score.
    if [ "$total_debt" -gt 0 ]; then
        local debt_pct=$((open_debt * 100 / total_debt))
        
        if [ "$debt_pct" -gt 50 ]; then
            debt_score=40
        elif [ "$debt_pct" -gt 30 ]; then
            debt_score=60
        elif [ "$debt_pct" -gt 10 ]; then
            debt_score=80
        fi
    fi
    
    # Deduct for high TODO count
    if [ "$todo_count" -gt 100 ]; then
        debt_score=$((debt_score - 20))
    elif [ "$todo_count" -gt 50 ]; then
        debt_score=$((debt_score - 10))
    fi
    
    debt_score=$(_maint_clamp "$debt_score" 0 100)
    
    printf '%s' "$debt_score"
}

calculate_spec_citation_score() {
    local project_root="$1"
    local spec_score=0
    
    maint_log_info "Calculating spec citation compliance..."
    
    # Count spec:// URIs in code
    local spec_refs
    spec_refs=$(_maint_int "$(grep -r "spec://" "$project_root/src" --include="*.sh" 2>/dev/null | wc -l)")
    
    # Count specs in catalog
    local spec_catalog="$project_root/specs/catalog"
    local spec_count=0
    
    if [ -d "$spec_catalog" ]; then
        spec_count=$(_maint_int "$(find "$spec_catalog" -name "*.md" -type f 2>/dev/null | wc -l)")
    fi
    
    # Score based on citations per module
    local module_count
    module_count=$(_maint_int "$(find "$project_root/src/lib" -name "*.sh" -type f 2>/dev/null | wc -l)")
    
    if [ "$module_count" -gt 0 ] && [ "$spec_count" -gt 0 ]; then
        # citations/module × 100, compared as an integer percent (>=300/200/100/50)
        local cit_pct=$((spec_refs * 100 / module_count))
        
        if [ "$cit_pct" -ge 300 ]; then
            spec_score=100
        elif [ "$cit_pct" -ge 200 ]; then
            spec_score=80
        elif [ "$cit_pct" -ge 100 ]; then
            spec_score=60
        elif [ "$cit_pct" -ge 50 ]; then
            spec_score=40
        fi
    fi
    
    printf '%s' "$spec_score"
}

#------------------------------------------------------------------------------
# Main Scoring Function
#------------------------------------------------------------------------------

calculate_maintainability_score() {
    local project_root="${1:-.}"
    local output_format="${2:-text}"
    # strict=1 restores the legacy band exit codes (0/1/2/3). Default is 0 for any
    # successfully computed score — callers under `set -e` (setup.sh _run_step,
    # dev CLI) must not treat "score 78 / GOOD" as a failure.
    local strict="${3:-0}"
    
    if [ ! -d "$project_root" ]; then
        maint_log_error "Project root not found: $project_root"
        return 1
    fi
    
    ensure_cache_dir || return 1
    
    maint_log_info "Calculating maintainability score for: $project_root"
    maint_log_info "Using weights: Test=$WEIGHT_TEST_COVERAGE%, Doc=$WEIGHT_DOCUMENTATION%, Complexity=$WEIGHT_COMPLEXITY%, Debt=$WEIGHT_DEBT_RATIO%, Spec=$WEIGHT_SPEC_CITATION%"
    
    # Calculate individual metrics (each echoes a bare integer)
    local test_coverage doc_score complexity_score debt_score spec_score
    test_coverage=$(calculate_test_coverage "$project_root") || return 1
    doc_score=$(calculate_documentation_score "$project_root") || return 1
    complexity_score=$(calculate_complexity_score "$project_root") || return 1
    debt_score=$(calculate_debt_ratio_score "$project_root") || return 1
    spec_score=$(calculate_spec_citation_score "$project_root") || return 1
    
    test_coverage=$(_maint_clamp "$test_coverage" 0 100)
    doc_score=$(_maint_clamp "$doc_score" 0 100)
    complexity_score=$(_maint_clamp "$complexity_score" 0 100)
    debt_score=$(_maint_clamp "$debt_score" 0 100)
    spec_score=$(_maint_clamp "$spec_score" 0 100)
    
    maint_log_info "Metrics:"
    maint_log_info "  Test Coverage:    $test_coverage/100"
    maint_log_info "  Documentation:    $doc_score/100"
    maint_log_info "  Complexity:       $complexity_score/100"
    maint_log_info "  Debt Ratio:       $debt_score/100"
    maint_log_info "  Spec Citations:   $spec_score/100"
    
    # Weighted score — pure integer math, clamped to 0..100.
    local w_test w_doc w_cx w_debt w_spec
    w_test=$(_maint_int "$WEIGHT_TEST_COVERAGE")
    w_doc=$(_maint_int "$WEIGHT_DOCUMENTATION")
    w_cx=$(_maint_int "$WEIGHT_COMPLEXITY")
    w_debt=$(_maint_int "$WEIGHT_DEBT_RATIO")
    w_spec=$(_maint_int "$WEIGHT_SPEC_CITATION")
    
    local weighted_score
    weighted_score=$(( (test_coverage * w_test + \
                        doc_score * w_doc + \
                        complexity_score * w_cx + \
                        debt_score * w_debt + \
                        spec_score * w_spec) / 100 ))
    weighted_score=$(_maint_clamp "$weighted_score" 0 100)
    
    # Determine status
    local status=""
    local band_code=0
    local color=""
    
    if [ "$weighted_score" -ge "$MAINTAINABILITY_THRESHOLD_EXCELLENT" ]; then
        status="EXCELLENT"
        band_code=0
        color="$COLOR_GREEN"
    elif [ "$weighted_score" -ge "$MAINTAINABILITY_THRESHOLD_GOOD" ]; then
        status="GOOD"
        band_code=1
        color="$COLOR_GREEN"
    elif [ "$weighted_score" -ge "$MAINTAINABILITY_THRESHOLD_WARNING" ]; then
        status="NEEDS IMPROVEMENT"
        band_code=2
        color="$COLOR_YELLOW"
    else
        status="CRITICAL"
        band_code=3
        color="$COLOR_RED"
    fi
    
    # Cache result
    local cache_file="$MAINTAINABILITY_CACHE/score_$(date +%Y%m%d).json"
    if ! cat > "$cache_file" <<EOF
{
  "timestamp": "$(date +%Y-%m-%dT%H:%M:%S%z)",
  "project": "$project_root",
  "overall_score": $weighted_score,
  "status": "$status",
  "metrics": {
    "test_coverage": $test_coverage,
    "documentation": $doc_score,
    "complexity": $complexity_score,
    "debt_ratio": $debt_score,
    "spec_citations": $spec_score
  },
  "weights": {
    "test_coverage": $w_test,
    "documentation": $w_doc,
    "complexity": $w_cx,
    "debt_ratio": $w_debt,
    "spec_citations": $w_spec
  }
}
EOF
    then
        maint_log_error "Cannot write score cache: $cache_file"
        return 1
    fi
    
    # Output. Logs already went to stderr. With format=json we emit ONLY the
    # JSON document, so `calculate_maintainability_score . json | jq` works.
    if [ "$output_format" = "json" ]; then
        cat "$cache_file"
    else
        echo ""
        echo -e "${color}═══════════════════════════════════════════${COLOR_NC}"
        echo -e "${color}  MAINTAINABILITY SCORE: ${weighted_score}/100${COLOR_NC}"
        echo -e "${color}  STATUS: ${status}${COLOR_NC}"
        echo -e "${color}═══════════════════════════════════════════${COLOR_NC}"
        echo ""
    fi
    
    if [ "$strict" = "1" ]; then
        return "$band_code"
    fi
    return 0
}

#------------------------------------------------------------------------------
# Dashboard Renderer
#------------------------------------------------------------------------------

render_maintainability_dashboard() {
    local project_root="${1:-.}"
    local history_days="${2:-30}"
    
    maint_log_info "Rendering maintainability dashboard..."
    
    # Get current score (logs are on stderr; stdout carries banner + JSON)
    local current_score_json
    current_score_json=$(calculate_maintainability_score "$project_root" "json" 2>/dev/null) || true
    
    if [ -z "$current_score_json" ]; then
        maint_log_error "Failed to calculate current score"
        return 1
    fi
    
    # Extract metrics (coerced — a malformed field must not abort printf)
    local overall status test_cov doc complex debt spec
    overall=$(_maint_int "$(echo "$current_score_json" | grep '"overall_score"' | head -1 | sed 's/.*: //' | tr -d ',')")
    status=$(echo "$current_score_json" | grep '"status"' | head -1 | sed 's/.*: "//' | tr -d '",')
    [ -n "$status" ] || status="UNKNOWN"
    test_cov=$(_maint_int "$(echo "$current_score_json" | grep '"test_coverage"' | head -1 | sed 's/.*: //' | tr -d ',')")
    doc=$(_maint_int "$(echo "$current_score_json" | grep '"documentation"' | head -1 | sed 's/.*: //' | tr -d ',')")
    complex=$(_maint_int "$(echo "$current_score_json" | grep '"complexity"' | head -1 | sed 's/.*: //' | tr -d ',')")
    debt=$(_maint_int "$(echo "$current_score_json" | grep '"debt_ratio"' | head -1 | sed 's/.*: //' | tr -d ',')")
    spec=$(_maint_int "$(echo "$current_score_json" | grep '"spec_citations"' | head -1 | sed 's/.*: //' | tr -d ',')")
    
    echo ""
    echo "╔════════════════════════════════════════════════════════╗"
    echo "║         MAINTAINABILITY DASHBOARD                      ║"
    echo "╠════════════════════════════════════════════════════════╣"
    printf "║  Overall Score: %-35s ║\n" "$overall/100 ($status)"
    echo "╟────────────────────────────────────────────────────────╢"
    printf "║  Test Coverage:   [%3d%%] %s\n" "$test_cov" "$(generate_bar "$test_cov")"
    printf "║  Documentation:   [%3d%%] %s\n" "$doc" "$(generate_bar "$doc")"
    printf "║  Complexity:      [%3d%%] %s\n" "$complex" "$(generate_bar "$complex")"
    printf "║  Debt Ratio:      [%3d%%] %s\n" "$debt" "$(generate_bar "$debt")"
    printf "║  Spec Citations:  [%3d%%] %s\n" "$spec" "$(generate_bar "$spec")"
    echo "╟────────────────────────────────────────────────────────╢"
    echo "║  Thresholds: Excellent≥85, Good≥70, Warning≥50        ║"
    echo "╚════════════════════════════════════════════════════════╝"
    echo ""
}

generate_bar() {
    local value
    value=$(_maint_int "$1")
    local bar=""
    local filled=$((value / 5))
    local empty=$((20 - filled))
    [ "$empty" -lt 0 ] && empty=0
    local i
    
    for ((i=0; i<filled; i++)); do bar+="█"; done
    for ((i=0; i<empty; i++)); do bar+="░"; done
    
    printf '%s' "$bar"
}

#------------------------------------------------------------------------------
# CI Gate Function
#------------------------------------------------------------------------------

maintainability_ci_gate() {
    local project_root="${1:-.}"
    local threshold
    threshold=$(_maint_int "${2:-$MAINTAINABILITY_THRESHOLD_GOOD}")
    
    maint_log_info "Running maintainability CI gate (threshold: $threshold)..."
    
    # Capture score without printing the banner
    local score_output score
    score_output=$(calculate_maintainability_score "$project_root" "json" 2>&1) || {
        maint_log_error "Score calculation failed — CI gate FAILED"
        return 1
    }
    score=$(_maint_int "$(echo "$score_output" | grep '"overall_score"' | head -1 | sed 's/.*: //' | tr -d ',')")
    
    if [ "$score" -eq 0 ] && ! echo "$score_output" | grep -q '"overall_score"'; then
        maint_log_error "Could not read overall_score from score output — CI gate FAILED"
        return 1
    fi
    
    if [ "$score" -lt "$threshold" ]; then
        maint_log_error "Maintainability score ($score) below threshold ($threshold)"
        maint_log_error "CI gate FAILED"
        return 1
    fi
    
    maint_log_success "Maintainability score ($score) meets threshold ($threshold)"
    maint_log_success "CI gate PASSED"
    return 0
}

#------------------------------------------------------------------------------
# Main Entry Point
#------------------------------------------------------------------------------

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    set +e
    case "${1:-help}" in
        calculate)
            calculate_maintainability_score "${2:-.}" "${3:-text}" "${4:-0}"
            exit $?
            ;;
        dashboard)
            render_maintainability_dashboard "${2:-.}" "${3:-30}"
            exit $?
            ;;
        ci-gate)
            maintainability_ci_gate "${2:-.}" "${3:-70}"
            exit $?
            ;;
        help|*)
            echo "Usage: $0 {calculate|dashboard|ci-gate} [project_root] [options]"
            echo ""
            echo "Commands:"
            echo "  calculate [root] [format] [strict]  - Calculate maintainability score"
            echo "      format: text (default) | json"
            echo "      strict: 1 = exit 0/1/2/3 by score band (default 0 = always 0 on success)"
            echo "  dashboard [root] [days]    - Render visual dashboard"
            echo "  ci-gate [root] [threshold] - Run CI gate check (exit 1 below threshold)"
            echo ""
            echo "Environment variables:"
            echo "  MAINTAINABILITY_CONFIG     - Config file path"
            echo "  WEIGHT_TEST_COVERAGE       - Test coverage weight (default: 30)"
            echo "  WEIGHT_DOCUMENTATION       - Documentation weight (default: 25)"
            echo "  WEIGHT_COMPLEXITY          - Complexity weight (default: 20)"
            echo "  WEIGHT_DEBT_RATIO          - Debt ratio weight (default: 15)"
            echo "  WEIGHT_SPEC_CITATION       - Spec citation weight (default: 10)"
            echo ""
            echo "Logs go to stderr; the score banner and JSON go to stdout."
            exit 0
            ;;
    esac
fi
