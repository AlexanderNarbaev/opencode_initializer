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
#   calculate_maintainability_score /path/to/project
#   render_maintainability_dashboard
#
# Exit codes:
#   0 - Score >= 85 (Excellent)
#   1 - Score 70-84 (Good)
#   2 - Score 50-69 (Needs Improvement)
#   3 - Score < 50 (Critical)

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

maint_log_info() {
    echo -e "${COLOR_BLUE}[INFO]${COLOR_NC} $*"
}

maint_log_success() {
    echo -e "${COLOR_GREEN}[OK]${COLOR_NC} $*"
}

maint_log_warning() {
    echo -e "${COLOR_YELLOW}[WARN]${COLOR_NC} $*"
}

maint_log_error() {
    echo -e "${COLOR_RED}[ERROR]${COLOR_NC} $*" >&2
}

ensure_cache_dir() {
    mkdir -p "$MAINTAINABILITY_CACHE"
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
    
    # Shell scripts
    if command -v find &>/dev/null; then
        source_files=$(find "$project_root" -name "*.sh" -type f 2>/dev/null | wc -l)
        test_files=$(find "$project_root/tests" -name "test_*.sh" -type f 2>/dev/null | wc -l || echo 0)
    fi
    
    # Python files
    local py_source=$(find "$project_root" -name "*.py" -not -path "*/tests/*" -not -path "*/venv/*" -type f 2>/dev/null | wc -l || echo 0)
    local py_tests=$(find "$project_root/tests" -name "test_*.py" -type f 2>/dev/null | wc -l || echo 0)
    
    source_files=$((source_files + py_source))
    test_files=$((test_files + py_tests))
    
    if [ "$source_files" -gt 0 ]; then
        # Ratio of test to source files (target: 1:1)
        local ratio=$(echo "scale=2; $test_files / $source_files" | bc 2>/dev/null || echo "0")
        
        # Convert to 0-100 score (cap at 100)
        if (( $(echo "$ratio >= 1.0" | bc -l 2>/dev/null || echo 0) )); then
            coverage_score=100
        else
            coverage_score=$(echo "scale=0; $ratio * 100" | bc 2>/dev/null || echo 0)
        fi
    fi
    
    # Bonus for integration and e2e tests
    local integration_tests=$(find "$project_root/tests/integration" -name "*.sh" -type f 2>/dev/null | wc -l || echo 0)
    local e2e_tests=$(find "$project_root/tests/e2e" -name "*.sh" -type f 2>/dev/null | wc -l || echo 0)
    
    if [ "$integration_tests" -gt 5 ]; then
        coverage_score=$((coverage_score + 5))
    fi
    
    if [ "$e2e_tests" -gt 3 ]; then
        coverage_score=$((coverage_score + 5))
    fi
    
    # Cap at 100
    [ "$coverage_score" -gt 100 ] && coverage_score=100
    
    echo "$coverage_score"
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
    for doc in "${essential_docs[@]}"; do
        if [ -f "$project_root/$doc" ]; then
            found_docs=$((found_docs + 1))
            
            # Bonus for non-empty files (>100 bytes)
            local size=$(stat -f%z "$project_root/$doc" 2>/dev/null || stat -c%s "$project_root/$doc" 2>/dev/null || echo 0)
            if [ "$size" -gt 1000 ]; then
                found_docs=$((found_docs + 1))
            fi
        fi
    done
    
    local total_possible=$((${#essential_docs[@]} * 2))
    doc_score=$(echo "scale=0; ($found_docs / $total_possible) * 100" | bc 2>/dev/null || echo 0)
    
    # Bonus for API docs, ADRs, runbooks
    local adr_count=$(find "$project_root/docs/adr" -name "*.md" -type f 2>/dev/null | wc -l || echo 0)
    if [ "$adr_count" -gt 5 ]; then
        doc_score=$((doc_score + 10))
    fi
    
    [ "$doc_score" -gt 100 ] && doc_score=100
    
    echo "$doc_score"
}

calculate_complexity_score() {
    local project_root="$1"
    local complexity_score=100  # Start perfect, deduct points
    
    maint_log_info "Calculating code complexity..."
    
    # Average lines per function (target: <50)
    local total_lines=0
    local total_functions=0
    
    for script in $(find "$project_root/src" -name "*.sh" -type f 2>/dev/null); do
        local lines=$(wc -l < "$script")
        local functions=$(grep -c "^[a-z_]*() {" "$script" 2>/dev/null || echo 0)
        
        total_lines=$((total_lines + lines))
        total_functions=$((total_functions + functions))
    done
    
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
    
    # Deduct for deeply nested code (>4 levels)
    local deep_nesting=$(grep -r "    " "$project_root/src" --include="*.sh" 2>/dev/null | wc -l || echo 0)
    if [ "$deep_nesting" -gt 100 ]; then
        complexity_score=$((complexity_score - 15))
    fi
    
    # Deduct for long lines (>120 chars)
    local long_lines=$(grep -r '.\{120,\}' "$project_root/src" --include="*.sh" 2>/dev/null | wc -l || echo 0)
    if [ "$long_lines" -gt 50 ]; then
        complexity_score=$((complexity_score - 10))
    fi
    
    [ "$complexity_score" -lt 0 ] && complexity_score=0
    
    echo "$complexity_score"
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
        open_debt=$(grep -c '"status": "open"' "$debt_file" 2>/dev/null || echo 0)
        total_debt=$(wc -l < "$debt_file" 2>/dev/null || echo 0)
    fi
    
    # Check for TODO/FIXME/HACK comments
    local todo_count=$(grep -r "TODO\|FIXME\|HACK" "$project_root/src" --include="*.sh" 2>/dev/null | wc -l || echo 0)
    
    # Calculate ratio
    if [ "$total_debt" -gt 0 ]; then
        local debt_ratio=$(echo "scale=2; $open_debt / $total_debt" | bc 2>/dev/null || echo 0)
        
        if (( $(echo "$debt_ratio > 0.5" | bc -l 2>/dev/null || echo 0) )); then
            debt_score=40
        elif (( $(echo "$debt_ratio > 0.3" | bc -l 2>/dev/null || echo 0) )); then
            debt_score=60
        elif (( $(echo "$debt_ratio > 0.1" | bc -l 2>/dev/null || echo 0) )); then
            debt_score=80
        fi
    fi
    
    # Deduct for high TODO count
    if [ "$todo_count" -gt 100 ]; then
        debt_score=$((debt_score - 20))
    elif [ "$todo_count" -gt 50 ]; then
        debt_score=$((debt_score - 10))
    fi
    
    [ "$debt_score" -lt 0 ] && debt_score=0
    
    echo "$debt_score"
}

calculate_spec_citation_score() {
    local project_root="$1"
    local spec_score=0
    
    maint_log_info "Calculating spec citation compliance..."
    
    # Count spec:// URIs in code
    local spec_refs=$(grep -r "spec://" "$project_root/src" --include="*.sh" 2>/dev/null | wc -l || echo 0)
    
    # Count specs in catalog
    local spec_catalog="$project_root/specs/catalog"
    local spec_count=0
    
    if [ -d "$spec_catalog" ]; then
        spec_count=$(find "$spec_catalog" -name "*.md" -type f 2>/dev/null | wc -l || echo 0)
    fi
    
    # Score based on citations per module
    local module_count=$(find "$project_root/src/lib" -name "*.sh" -type f 2>/dev/null | wc -l || echo 0)
    
    if [ "$module_count" -gt 0 ] && [ "$spec_count" -gt 0 ]; then
        local citations_per_module=$(echo "scale=2; $spec_refs / $module_count" | bc 2>/dev/null || echo 0)
        
        if (( $(echo "$citations_per_module >= 3" | bc -l 2>/dev/null || echo 0) )); then
            spec_score=100
        elif (( $(echo "$citations_per_module >= 2" | bc -l 2>/dev/null || echo 0) )); then
            spec_score=80
        elif (( $(echo "$citations_per_module >= 1" | bc -l 2>/dev/null || echo 0) )); then
            spec_score=60
        elif (( $(echo "$citations_per_module >= 0.5" | bc -l 2>/dev/null || echo 0) )); then
            spec_score=40
        fi
    fi
    
    echo "$spec_score"
}

#------------------------------------------------------------------------------
# Main Scoring Function
#------------------------------------------------------------------------------

calculate_maintainability_score() {
    local project_root="${1:-.}"
    local output_format="${2:-text}"
    
    ensure_cache_dir
    
    maint_log_info "Calculating maintainability score for: $project_root"
    maint_log_info "Using weights: Test=$WEIGHT_TEST_COVERAGE%, Doc=$WEIGHT_DOCUMENTATION%, Complexity=$WEIGHT_COMPLEXITY%, Debt=$WEIGHT_DEBT_RATIO%, Spec=$WEIGHT_SPEC_CITATION%"
    
    # Calculate individual metrics
    local test_coverage=$(calculate_test_coverage "$project_root")
    local doc_score=$(calculate_documentation_score "$project_root")
    local complexity_score=$(calculate_complexity_score "$project_root")
    local debt_score=$(calculate_debt_ratio_score "$project_root")
    local spec_score=$(calculate_spec_citation_score "$project_root")
    
    maint_log_info "Metrics:"
    maint_log_info "  Test Coverage:    $test_coverage/100"
    maint_log_info "  Documentation:    $doc_score/100"
    maint_log_info "  Complexity:       $complexity_score/100"
    maint_log_info "  Debt Ratio:       $debt_score/100"
    maint_log_info "  Spec Citations:   $spec_score/100"
    
    # Calculate weighted score
    local weighted_score=$(echo "scale=0; \
        ($test_coverage * $WEIGHT_TEST_COVERAGE + \
         $doc_score * $WEIGHT_DOCUMENTATION + \
         $complexity_score * $WEIGHT_COMPLEXITY + \
         $debt_score * $WEIGHT_DEBT_RATIO + \
         $spec_score * $WEIGHT_SPEC_CITATION) / 100" | bc 2>/dev/null || echo 0)
    
    # Determine status
    local status=""
    local exit_code=0
    local color=""
    
    if [ "$weighted_score" -ge "$MAINTAINABILITY_THRESHOLD_EXCELLENT" ]; then
        status="EXCELLENT"
        exit_code=0
        color="$COLOR_GREEN"
    elif [ "$weighted_score" -ge "$MAINTAINABILITY_THRESHOLD_GOOD" ]; then
        status="GOOD"
        exit_code=1
        color="$COLOR_GREEN"
    elif [ "$weighted_score" -ge "$MAINTAINABILITY_THRESHOLD_WARNING" ]; then
        status="NEEDS IMPROVEMENT"
        exit_code=2
        color="$COLOR_YELLOW"
    else
        status="CRITICAL"
        exit_code=3
        color="$COLOR_RED"
    fi
    
    # Cache result
    local cache_file="$MAINTAINABILITY_CACHE/score_$(date +%Y%m%d).json"
    cat > "$cache_file" <<EOF
{
  "timestamp": "$(date -Iseconds)",
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
    "test_coverage": $WEIGHT_TEST_COVERAGE,
    "documentation": $WEIGHT_DOCUMENTATION,
    "complexity": $WEIGHT_COMPLEXITY,
    "debt_ratio": $WEIGHT_DEBT_RATIO,
    "spec_citations": $WEIGHT_SPEC_CITATION
  }
}
EOF
    
    # Output
    echo ""
    echo -e "${color}═══════════════════════════════════════════${COLOR_NC}"
    echo -e "${color}  MAINTAINABILITY SCORE: $weighted_score/100${COLOR_NC}"
    echo -e "${color}  STATUS: $status${COLOR_NC}"
    echo -e "${color}═══════════════════════════════════════════${COLOR_NC}"
    echo ""
    
    if [ "$output_format" = "json" ]; then
        cat "$cache_file"
    fi
    
    return $exit_code
}

#------------------------------------------------------------------------------
# Dashboard Renderer
#------------------------------------------------------------------------------

render_maintainability_dashboard() {
    local project_root="${1:-.}"
    local history_days="${2:-30}"
    
    maint_log_info "Rendering maintainability dashboard..."
    
    # Get current score
    local current_score_json=$(calculate_maintainability_score "$project_root" "json" 2>/dev/null)
    
    if [ -z "$current_score_json" ]; then
        maint_log_error "Failed to calculate current score"
        return 1
    fi
    
    # Extract metrics
    local overall=$(echo "$current_score_json" | grep '"overall_score"' | sed 's/.*: //' | tr -d ',')
    local status=$(echo "$current_score_json" | grep '"status"' | sed 's/.*: "//' | tr -d '",')
    local test_cov=$(echo "$current_score_json" | grep '"test_coverage"' | head -1 | sed 's/.*: //' | tr -d ',')
    local doc=$(echo "$current_score_json" | grep '"documentation"' | sed 's/.*: //' | tr -d ',')
    local complex=$(echo "$current_score_json" | grep '"complexity"' | sed 's/.*: //' | tr -d ',')
    local debt=$(echo "$current_score_json" | grep '"debt_ratio"' | sed 's/.*: //' | tr -d ',')
    local spec=$(echo "$current_score_json" | grep '"spec_citations"' | sed 's/.*: //' | tr -d ',')
    
    echo ""
    echo "╔════════════════════════════════════════════════════════╗"
    echo "║         MAINTAINABILITY DASHBOARD                      ║"
    echo "╠════════════════════════════════════════════════════════╣"
    printf "║  Overall Score: %-35s ║\n" "$overall/100 ($status)"
    echo "╟────────────────────────────────────────────────────────╢"
    printf "║  Test Coverage:   [%3d%%] %s\n" "$test_cov" "$(generate_bar $test_cov)"
    printf "║  Documentation:   [%3d%%] %s\n" "$doc" "$(generate_bar $doc)"
    printf "║  Complexity:      [%3d%%] %s\n" "$complex" "$(generate_bar $complex)"
    printf "║  Debt Ratio:      [%3d%%] %s\n" "$debt" "$(generate_bar $debt)"
    printf "║  Spec Citations:  [%3d%%] %s\n" "$spec" "$(generate_bar $spec)"
    echo "╟────────────────────────────────────────────────────────╢"
    echo "║  Thresholds: Excellent≥85, Good≥70, Warning≥50        ║"
    echo "╚════════════════════════════════════════════════════════╝"
    echo ""
}

generate_bar() {
    local value=$1
    local bar=""
    local filled=$((value / 5))
    local empty=$((20 - filled))
    
    for ((i=0; i<filled; i++)); do bar+="█"; done
    for ((i=0; i<empty; i++)); do bar+="░"; done
    
    echo "$bar"
}

#------------------------------------------------------------------------------
# CI Gate Function
#------------------------------------------------------------------------------

maintainability_ci_gate() {
    local project_root="${1:-.}"
    local threshold="${2:-$MAINTAINABILITY_THRESHOLD_GOOD}"
    
    maint_log_info "Running maintainability CI gate (threshold: $threshold)..."
    
    # Capture score without printing
    local score_output=$(calculate_maintainability_score "$project_root" "json" 2>&1)
    local score=$(echo "$score_output" | grep '"overall_score"' | sed 's/.*: //' | tr -d ',')
    
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
    case "${1:-help}" in
        calculate)
            calculate_maintainability_score "${2:-.}" "${3:-text}"
            ;;
        dashboard)
            render_maintainability_dashboard "${2:-.}" "${3:-30}"
            ;;
        ci-gate)
            maintainability_ci_gate "${2:-.}" "${3:-70}"
            ;;
        help|*)
            echo "Usage: $0 {calculate|dashboard|ci-gate} [project_root] [options]"
            echo ""
            echo "Commands:"
            echo "  calculate [root] [format]  - Calculate maintainability score"
            echo "  dashboard [root] [days]    - Render visual dashboard"
            echo "  ci-gate [root] [threshold] - Run CI gate check"
            echo ""
            echo "Environment variables:"
            echo "  MAINTAINABILITY_CONFIG     - Config file path"
            echo "  WEIGHT_TEST_COVERAGE       - Test coverage weight (default: 30)"
            echo "  WEIGHT_DOCUMENTATION       - Documentation weight (default: 25)"
            echo "  WEIGHT_COMPLEXITY          - Complexity weight (default: 20)"
            echo "  WEIGHT_DEBT_RATIO          - Debt ratio weight (default: 15)"
            echo "  WEIGHT_SPEC_CITATION       - Spec citation weight (default: 10)"
            ;;
    esac
fi
