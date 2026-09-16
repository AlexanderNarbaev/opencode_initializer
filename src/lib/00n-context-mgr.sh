#!/usr/bin/env bash
# src/lib/00n-context-mgr.sh — Context Manager (v4.4.0)
# Manages AI context windows, token budgets, and conversation history.
set -euo pipefail

# ── Context configuration ────────────────────────────────────────────────────
_CONTEXT_DIR="${DL_CACHE}/context"
_CONTEXT_HISTORY="${_CONTEXT_DIR}/history.jsonl"
_CONTEXT_BUDGET="${_CONTEXT_DIR}/budget.json"

# ── Model context limits ────────────────────────────────────────────────────
# Using function-based lookup for bash 3.2 compatibility
_get_context_limit() {
  local model="$1"
  case "$model" in
    gpt-4o) echo 128000 ;;
    gpt-4-turbo) echo 128000 ;;
    claude-3.5-sonnet) echo 200000 ;;
    claude-3-opus) echo 200000 ;;
    gemini-1.5-pro) echo 1000000 ;;
    gemini-1.5-flash) echo 1000000 ;;
    deepseek-chat) echo 64000 ;;
    deepseek-coder) echo 64000 ;;
    qwen-2.5) echo 128000 ;;
    mistral-large) echo 128000 ;;
    llama-3.1) echo 128000 ;;
    codellama) echo 16000 ;;
    *) echo 128000 ;;
  esac
}

# ── Initialize context manager ──────────────────────────────────────────────
_context_init() {
  mkdir -p "$_CONTEXT_DIR"
  
  if [ ! -f "$_CONTEXT_BUDGET" ]; then
    cat > "$_CONTEXT_BUDGET" <<EOF
{
  "version": "1.0.0",
  "models": {},
  "default_budget": 80000,
  "reserve_for_response": 4000
}
EOF
  fi
}

# ── Count tokens (approximate) ──────────────────────────────────────────────
# Usage: tokens=$(_count_tokens "text here")
# Uses simple word-based approximation (1 token ≈ 4 chars or 0.75 words)
_count_tokens() {
  local text="$1"
  local chars words tokens

  chars=${#text}
  words=$(echo "$text" | wc -w)
  
  # Use character-based estimate (more accurate for code)
  tokens=$(( chars / 4 ))
  
  echo "$tokens"
}

# ── Add to context history ──────────────────────────────────────────────────
# Usage: _context_add "user" "message text"
_context_add() {
  local role="$1" content="$2"
  local now
  now=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
  local tokens
  tokens=$(_count_tokens "$content")

  _context_init

  # Append to JSONL
  cat >> "$_CONTEXT_HISTORY" <<EOF
{"role":"$role","content":$(echo "$content" | python3 -c 'import json,sys; print(json.dumps(sys.stdin.read()))' 2>/dev/null || echo '"..."'),"timestamp":"$now","tokens":$tokens}
EOF

  log "Context added: $role ($tokens tokens)"
}

# ── Trim context to fit budget ──────────────────────────────────────────────
# Usage: trimmed=$(_context_trim [max_tokens])
# Returns trimmed context that fits within budget.
_context_trim() {
  local max_tokens="${1:-80000}"
  local reserve="${2:-4000}"
  local available=$((max_tokens - reserve))

  _context_init

  if [ ! -f "$_CONTEXT_HISTORY" ]; then
    echo ""
    return 0
  fi

  # Read history from newest to oldest
  local total_tokens=0
  local lines=()

  while IFS= read -r line; do
    local line_tokens
    line_tokens=$(echo "$line" | python3 -c "import json,sys; print(json.loads(sys.stdin.read()).get('tokens',0))" 2>/dev/null || echo "0")
    
    total_tokens=$((total_tokens + line_tokens))
    
    if [ "$total_tokens" -le "$available" ]; then
      lines+=("$line")
    else
      break
    fi
  done < <(tac "$_CONTEXT_HISTORY" 2>/dev/null || true)

  # Output trimmed context (oldest to newest)
  printf '%s\n' "${lines[@]}" | tac
}

# ── Get context statistics ──────────────────────────────────────────────────
# Usage: _context_stats
_context_stats() {
  _context_init

  section "Context Statistics"

  if [ ! -f "$_CONTEXT_HISTORY" ]; then
    log "No context history"
    return 0
  fi

  local total_entries total_tokens user_tokens assistant_tokens
  total_entries=$(wc -l < "$_CONTEXT_HISTORY")
  total_tokens=$(python3 -c "
import json, sys
total = 0
for line in open('$_CONTEXT_HISTORY'):
    try:
        data = json.loads(line)
        total += data.get('tokens', 0)
    except:
        pass
print(total)
" 2>/dev/null || echo "0")

  user_tokens=$(python3 -c "
import json, sys
total = 0
for line in open('$_CONTEXT_HISTORY'):
    try:
        data = json.loads(line)
        if data.get('role') == 'user':
            total += data.get('tokens', 0)
    except:
        pass
print(total)
" 2>/dev/null || echo "0")

  assistant_tokens=$(python3 -c "
import json, sys
total = 0
for line in open('$_CONTEXT_HISTORY'):
    try:
        data = json.loads(line)
        if data.get('role') == 'assistant':
            total += data.get('tokens', 0)
    except:
        pass
print(total)
" 2>/dev/null || echo "0")

  log "Total entries: $total_entries"
  log "Total tokens: $total_tokens"
  log "User tokens: $user_tokens"
  log "Assistant tokens: $assistant_tokens"
}

# ── Clear context history ───────────────────────────────────────────────────
# Usage: _context_clear
_context_clear() {
  _context_init
  
  if [ -f "$_CONTEXT_HISTORY" ]; then
    rm -f "$_CONTEXT_HISTORY"
    log "Context history cleared"
  fi
}

# ── Export functions ─────────────────────────────────────────────────────────
export -f _context_init _get_context_limit _count_tokens _context_add \
  _context_trim _context_stats _context_clear 2>/dev/null || true
