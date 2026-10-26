#!/usr/bin/env bash
# src/lib/65-skill-eval.sh — Skill evaluation framework
# Part of Phase 0: Skill Management System
# shellcheck disable=SC2034
set -euo pipefail

SKILL_EVAL_SCENARIOS="${SKILL_EVAL_SCENARIOS:-$HOME/.config/opencode/eval-scenarios.json}"
SKILL_EVAL_REPORT_DIR="${SKILL_EVAL_REPORT_DIR:-/tmp/opencode-eval-reports}"
SKILL_EVAL_TIMEOUT="${SKILL_EVAL_TIMEOUT:-300}"

# ── Evaluation Framework ─────────────────────────────────────────────────────

# Run evaluation for a skill
_skill_eval_run() {
  local skill_name="${1:-}"
  local scenario="${2:-default}"
  local output_format="${3:-text}"
  
  if [ -z "$skill_name" ]; then
    err "Skill name required"
  fi
  
  section "Evaluating: $skill_name (scenario: $scenario)"
  
  local skill_dir="$SKILL_INSTALL_DIR/$skill_name"
  if [ ! -d "$skill_dir" ]; then
    err "Skill $skill_name not installed"
  fi
  
  # Create eval report directory
  local report_dir="$SKILL_EVAL_REPORT_DIR/$skill_name/$(date +%Y%m%d-%H%M%S)"
  mkdir -p "$report_dir"
  
  # Run evaluation metrics
  local metrics=()
  
  # 1. Task completion rate
  local completion_rate
  completion_rate=$(_skill_eval_completion "$skill_dir" "$scenario")
  metrics+=("completion_rate:$completion_rate")
  
  # 2. Code quality score
  local quality_score
  quality_score=$(_skill_eval_quality "$skill_dir")
  metrics+=("quality_score:$quality_score")
  
  # 3. Documentation completeness
  local docs_score
  docs_score=$(_skill_eval_docs "$skill_dir")
  metrics+=("docs_score:$docs_score")
  
  # 4. Test coverage
  local test_score
  test_score=$(_skill_eval_tests "$skill_dir")
  metrics+=("test_score:$test_score")
  
  # 5. Security score
  local security_score
  security_score=$(_skill_security_score "$skill_dir" 2>/dev/null || echo "0")
  metrics+=("security_score:$security_score")
  
  # Calculate overall score
  local overall_score
  overall_score=$(_skill_eval_overall "${metrics[@]}")
  
  # Generate report
  if [ "$output_format" = "json" ]; then
    _skill_eval_report_json "$skill_name" "$overall_score" "${metrics[@]}" > "$report_dir/report.json"
    cat "$report_dir/report.json"
  else
    _skill_eval_report_text "$skill_name" "$overall_score" "${metrics[@]}"
  fi
  
  # Save report
  echo "$overall_score" > "$report_dir/score.txt"
  
  log "Evaluation complete: $skill_name scored $overall_score/100"
}

# ── Individual Metrics ───────────────────────────────────────────────────────

# Task completion rate
_skill_eval_completion() {
  local skill_dir="${1:-.}"
  local scenario="${2:-default}"
  local score=0
  
  # Check if skill has executable commands
  if [ -f "$skill_dir/SKILL.md" ]; then
    # Check for code blocks (executable examples)
    local code_blocks
    code_blocks=$(grep -c '```' "$skill_dir/SKILL.md" 2>/dev/null | tr -d '[:space:]')
    code_blocks=${code_blocks:-0}
    if [ "$code_blocks" -gt 0 ]; then
      score=$((score + 30))
    fi
    
    # Check for step-by-step instructions
    if grep -qE "^[0-9]+\." "$skill_dir/SKILL.md" 2>/dev/null; then
      score=$((score + 20))
    fi
    
    # Check for clear inputs/outputs
    if grep -qi "input\|output\|return" "$skill_dir/SKILL.md" 2>/dev/null; then
      score=$((score + 20))
    fi
    
    # Check for error handling
    if grep -qi "error\|exception\|fail" "$skill_dir/SKILL.md" 2>/dev/null; then
      score=$((score + 15))
    fi
    
    # Check for examples
    if grep -qi "example\|sample\|demo" "$skill_dir/SKILL.md" 2>/dev/null; then
      score=$((score + 15))
    fi
  fi
  
  # Clamp to 100
  [ "$score" -gt 100 ] && score=100
  
  echo "$score"
}

# Code quality score
_skill_eval_quality() {
  local skill_dir="${1:-.}"
  local score=0
  
  # Check for shellcheck compliance
  if command -v shellcheck &>/dev/null; then
    local shellcheck_errors=0
    for script in "$skill_dir"/*.sh; do
      [ -f "$script" ] || continue
      if ! shellcheck -S warning "$script" &>/dev/null; then
        ((shellcheck_errors++))
      fi
    done
    if [ "$shellcheck_errors" -eq 0 ]; then
      score=$((score + 30))
    fi
  else
    score=$((score + 15)) # Partial credit if shellcheck not available
  fi
  
  # Check for consistent formatting
  local tabs=0 spaces=0
  tabs=$(grep -rl "	" "$skill_dir/" 2>/dev/null | wc -l | tr -d '[:space:]')
  tabs=${tabs:-0}
  spaces=$(grep -rl "  " "$skill_dir/" 2>/dev/null | wc -l | tr -d '[:space:]')
  spaces=${spaces:-0}
  if [ "$spaces" -gt "$tabs" ]; then
    score=$((score + 20))
  fi
  
  # Check for comments
  local comments
  comments=$(grep -r "^#" "$skill_dir/" 2>/dev/null | wc -l | tr -d '[:space:]')
  comments=${comments:-0}
  if [ "$comments" -gt 5 ]; then
    score=$((score + 25))
  elif [ "$comments" -gt 0 ]; then
    score=$((score + 10))
  fi
  
  # Check for set -euo pipefail
  if grep -rq "set -euo pipefail" "$skill_dir/" 2>/dev/null; then
    score=$((score + 25))
  elif grep -rq "set -e" "$skill_dir/" 2>/dev/null; then
    score=$((score + 10))
  fi
  
  # Clamp to 100
  [ "$score" -gt 100 ] && score=100
  
  echo "$score"
}

# Documentation completeness
_skill_eval_docs() {
  local skill_dir="${1:-.}"
  local score=0
  
  # Check for SKILL.md
  if [ -f "$skill_dir/SKILL.md" ]; then
    score=$((score + 20))
    
    # Check for title
    if grep -q "^# " "$skill_dir/SKILL.md"; then
      score=$((score + 10))
    fi
    
    # Check for description
    if grep -qi "description\|overview\|summary" "$skill_dir/SKILL.md"; then
      score=$((score + 15))
    fi
    
    # Check for usage examples
    if grep -qi "usage\|example\|how to" "$skill_dir/SKILL.md"; then
      score=$((score + 15))
    fi
    
    # Check for parameters/options
    if grep -qi "parameter\|option\|argument" "$skill_dir/SKILL.md"; then
      score=$((score + 10))
    fi
    
    # Check for return values
    if grep -qi "return\|output\|result" "$skill_dir/SKILL.md"; then
      score=$((score + 10))
    fi
  fi
  
  # Check for README
  if [ -f "$skill_dir/README.md" ]; then
    score=$((score + 10))
  fi
  
  # Check for CHANGELOG
  if [ -f "$skill_dir/CHANGELOG.md" ]; then
    score=$((score + 5))
  fi
  
  # Check for LICENSE
  if [ -f "$skill_dir/LICENSE" ]; then
    score=$((score + 5))
  fi
  
  # Clamp to 100
  [ "$score" -gt 100 ] && score=100
  
  echo "$score"
}

# Test coverage
_skill_eval_tests() {
  local skill_dir="${1:-.}"
  local score=0
  
  # Check for test files
  local test_files=0
  test_files=$(find "$skill_dir" -name "*test*" -o -name "*spec*" 2>/dev/null | wc -l || echo "0")
  
  if [ "$test_files" -gt 0 ]; then
    score=$((score + 40))
    
    # Check for test assertions
    local assertions=0
    assertions=$(grep -r "assert\|expect\|should" "$skill_dir"/*test* "$skill_dir"/*spec* 2>/dev/null | wc -l || echo "0")
    
    if [ "$assertions" -gt 10 ]; then
      score=$((score + 30))
    elif [ "$assertions" -gt 0 ]; then
      score=$((score + 15))
    fi
    
    # Check for test runner
    if [ -f "$skill_dir/package.json" ] && grep -q "test" "$skill_dir/package.json" 2>/dev/null; then
      score=$((score + 15))
    fi
    
    if [ -f "$skill_dir/Makefile" ] && grep -q "test" "$skill_dir/Makefile" 2>/dev/null; then
      score=$((score + 15))
    fi
  fi
  
  # Clamp to 100
  [ "$score" -gt 100 ] && score=100
  
  echo "$score"
}

# Calculate overall score
_skill_eval_overall() {
  local metrics=("$@")
  local total=0
  local count=0
  
  for metric in "${metrics[@]}"; do
    local value="${metric##*:}"
    total=$((total + value))
    ((count++))
  done
  
  if [ "$count" -eq 0 ]; then
    echo "0"
    return
  fi
  
  echo $((total / count))
}

# ── Reports ──────────────────────────────────────────────────────────────────

_skill_eval_report_text() {
  local skill_name="${1:-}"
  local overall_score="${2:-0}"
  shift 2
  local metrics=("$@")
  
  echo
  echo "━━━ Evaluation Report ━━━"
  echo "  Skill: $skill_name"
  echo "  Overall: $overall_score/100"
  echo
  echo "  Metrics:"
  for metric in "${metrics[@]}"; do
    local name="${metric%%:*}"
    local value="${metric##*:}"
    printf "    %-20s %s/100\n" "$name" "$value"
  done
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━"
}

_skill_eval_report_json() {
  local skill_name="${1:-}"
  local overall_score="${2:-0}"
  shift 2
  local metrics=("$@")
  
  cat <<EOF
{
  "skill": "$skill_name",
  "overall_score": $overall_score,
  "metrics": {
EOF
  
  local first=true
  for metric in "${metrics[@]}"; do
    local name="${metric%%:*}"
    local value="${metric##*:}"
    if [ "$first" = "true" ]; then
      first=false
    else
      echo ","
    fi
    printf '    "%s": %s' "$name" "$value"
  done
  
  cat <<EOF

  },
  "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
}
EOF
}

# ── Compare Skills ───────────────────────────────────────────────────────────

# Compare two skills
_skill_eval_compare() {
  local skill1="${1:-}"
  local skill2="${2:-}"
  
  if [ -z "$skill1" ] || [ -z "$skill2" ]; then
    err "Two skill names required"
  fi
  
  section "Comparing: $skill1 vs $skill2"
  
  local score1 score2
  score1=$(_skill_eval_run "$skill1" "default" "json" 2>/dev/null | jq -r '.overall_score // 0' 2>/dev/null || echo "0")
  score2=$(_skill_eval_run "$skill2" "default" "json" 2>/dev/null | jq -r '.overall_score // 0' 2>/dev/null || echo "0")
  
  echo "$skill1: $score1/100"
  echo "$skill2: $score2/100"
  
  if [ "$score1" -gt "$score2" ]; then
    echo "Winner: $skill1 (+$((score1 - score2)))"
  elif [ "$score2" -gt "$score1" ]; then
    echo "Winner: $skill2 (+$((score2 - score1)))"
  else
    echo "Tie"
  fi
}

# ── CLI Interface ────────────────────────────────────────────────────────────

cmd_skill_eval() {
  local subcmd="${1:-run}"
  shift || true
  
  case "$subcmd" in
    run)      _skill_eval_run "$@" ;;
    compare)  _skill_eval_compare "$@" ;;
    score)    _skill_eval_overall "$@" ;;
    help|*)
      cat <<'EOF'
Usage: opencode skill-eval <command> [args]

Commands:
  run <name> [scenario] [format]   Run evaluation (text|json)
  compare <name1> <name2>          Compare two skills
  score <metrics...>               Calculate overall score
EOF
      ;;
  esac
}
