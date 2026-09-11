#!/usr/bin/env bash
# src/lib/00d-parallel.sh — Parallel Installation Engine (v3.5.0)
# Provides dependency-aware parallel module execution with flock-based WAL.
# Modules are grouped by dependency layers; independent modules run concurrently.
# Sources: src/lib/helpers.sh, src/lib/00-core.sh must be sourced before this file
set -euo pipefail

# ── Parallel execution state ─────────────────────────────────────────────────
_PARALLEL_PIDS=()        # Array of background PIDs
_PARALLEL_NAMES=()       # Corresponding module names
_PARALLEL_RESULTS=()     # Exit codes (filled on wait)
_PARALLEL_MAX_JOBS="${PARALLEL_MAX_JOBS:-$(nproc 2>/dev/null || echo 4)}"
_PARALLEL_WAL_LOCK="${DL_CACHE}/parallel.lock"
_PARALLEL_PROGRESS_FILE="${DL_CACHE}/parallel-progress"

# ── Layer-based parallel execution ───────────────────────────────────────────
# Usage: _parallel_run_layer "layer_name" "step1:module1" "step2:module2" ...
# Each arg is "step_key:module_path:display_name"
# All modules in a layer run concurrently; layer completes before next starts.
_parallel_run_layer() {
  local layer_name="$1"
  shift
  local modules=("$@")
  local pids=() names=() results=()
  local active_jobs=0

  section "Parallel Layer: $layer_name (${#modules[@]} modules)"

  for entry in "${modules[@]}"; do
    IFS=':' read -r step_key module_path display_name <<< "$entry"

    # Skip if already completed
    if _step_skip "$step_key" 2>/dev/null; then
      log "Skip: $display_name (completed earlier)"
      continue
    fi

    # Wait if we've hit max parallel jobs
    while [ $active_jobs -ge $_PARALLEL_MAX_JOBS ]; do
      _parallel_wait_one
      active_jobs=$((active_jobs - 1))
    done

    # Launch module in background subshell
    (
      set +e
      local start_time end_time duration
      start_time=$(date +%s)

      # Source required infrastructure in subshell
      source "$SCRIPT_DIR/src/lib/helpers.sh" 2>/dev/null || true
      source "$SCRIPT_DIR/src/lib/00-core.sh" 2>/dev/null || true

      # Run the module
      if source "$module_path" 2>&1; then
        end_time=$(date +%s)
        duration=$((end_time - start_time))
        # Atomic WAL write for completion
        _wal_locked_append "$_PARALLEL_PROGRESS_FILE" "${step_key}:DONE:${duration}" 2>/dev/null || true
        exit 0
      else
        local exit_code=$?
        end_time=$(date +%s)
        duration=$((end_time - start_time))
        _wal_locked_append "$_PARALLEL_PROGRESS_FILE" "${step_key}:FAILED:${duration}" 2>/dev/null || true
        exit $exit_code
      fi
    ) &

    local pid=$!
    pids+=("$pid")
    names+=("$display_name")
    _PARALLEL_PIDS+=("$pid")
    _PARALLEL_NAMES+=("$display_name")
    active_jobs=$((active_jobs + 1))

    info "  ↳ Started: $display_name (PID: $pid)"
  done

  # Wait for all modules in this layer
  local all_ok=true
  for i in "${!pids[@]}"; do
    local pid="${pids[$i]}"
    local name="${names[$i]}"
    if wait "$pid" 2>/dev/null; then
      log "  ✓ $name — done"
    else
      local exit_code=$?
      warn "  ✗ $name — failed (exit: $exit_code)"
      all_ok=false
    fi
  done

  if $all_ok; then
    log "Layer $layer_name: all modules completed"
  else
    warn "Layer $layer_name: some modules failed"
  fi

  return $($all_ok && echo 0 || echo 1)
}

# ── Wait for one background job ──────────────────────────────────────────────
_parallel_wait_one() {
  if [ ${#_PARALLEL_PIDS[@]} -gt 0 ]; then
    local pid="${_PARALLEL_PIDS[0]}"
    wait "$pid" 2>/dev/null || true
    _PARALLEL_PIDS=("${_PARALLEL_PIDS[@]:1}")
    _PARALLEL_NAMES=("${_PARALLEL_NAMES[@]:1}")
  fi
}

# ── Wait for all parallel jobs ───────────────────────────────────────────────
_parallel_wait_all() {
  local all_ok=true
  for i in "${!_PARALLEL_PIDS[@]}"; do
    local pid="${_PARALLEL_PIDS[$i]}"
    local name="${_PARALLEL_NAMES[$i]}"
    if wait "$pid" 2>/dev/null; then
      log "  ✓ $name — done"
    else
      warn "  ✗ $name — failed"
      all_ok=false
    fi
  done
  _PARALLEL_PIDS=()
  _PARALLEL_NAMES=()
  $all_ok
}

# ── Dependency graph for installation order ──────────────────────────────────
# Defines which modules can run in parallel (no dependencies between them).
# Format: _PARALLEL_LAYERS[layer_num]="step1:module1:display1 step2:module2:display2"
#
# Layer 0: System foundation (sequential — each depends on previous)
# Layer 1: Language runtimes (independent of each other)
# Layer 2: Core tools (depend on runtimes)
# Layer 3: AI/ML stack (depends on core)
# Layer 4: Optional enhancements (fully independent)

_parallel_build_layers() {
  local layers=()

  # Layer 0: System foundation (MUST be sequential)
  layers+=("system:docker:infra")

  # Layer 1: Language runtimes (independent — can run in parallel)
  layers+=("java:node:python:go:rust:dotnet")

  # Layer 2: Core tools (depend on runtimes)
  layers+=("opencode:mcp:chromadb:shokunin")

  # Layer 3: AI/ML stack
  layers+=("security:llm:project:json")

  # Layer 4: Optional enhancements (fully independent)
  layers+=("rag:webui:mise:just:websearch")

  # Layer 5: Configuration and finalization
  layers+=("providers:isolated:dotfiles:devbox:gui:cockpit")
  layers+=("observability:model_router:context_selector:auto_skills")
  layers+=("task_distributor:context_bundle:grace_semantics:caching")
  layers+=("context_guard:provider_discovery:local_memory:daytona")
  layers+=("best_practices:upstream_sync")

  echo "${layers[@]}"
}

# ── Execute installation with optimal parallelism ────────────────────────────
# Usage: _parallel_install [--dry-run]
# Reads module list from setup.sh's _run_step calls and groups them.
_parallel_install() {
  local dry_run="${1:-false}"
  local start_time
  start_time=$(date +%s)

  info "Parallel installation engine v3.5.0"
  info "Max concurrent jobs: $_PARALLEL_MAX_JOBS"
  info "WAL lock: $_PARALLEL_WAL_LOCK"

  # Initialize progress tracking
  : > "$_PARALLEL_PROGRESS_FILE" 2>/dev/null || true

  # Layer 1: System + Docker + Infra (sequential — critical path)
  _parallel_run_layer "Foundation" \
    "step_system:$SCRIPT_DIR/src/lib/01-system.sh:System packages" \
    "step_docker:$SCRIPT_DIR/src/lib/02-docker.sh:Docker Engine"

  # Layer 2: Language runtimes (parallel)
  _parallel_run_layer "Runtimes" \
    "step_java:$SCRIPT_DIR/src/lib/05-java.sh:Java 25" \
    "step_node:$SCRIPT_DIR/src/lib/06-node.sh:Node.js 24" \
    "step_python:$SCRIPT_DIR/src/lib/07-python.sh:Python 3.14" \
    "step_go:$SCRIPT_DIR/src/lib/08-go.sh:Go 1.26" \
    "step_rust:$SCRIPT_DIR/src/lib/09-rust.sh:Rust 1.97" \
    "step_dotnet:$SCRIPT_DIR/src/lib/10-dotnet.sh:.NET 10"

  # Layer 3: Core tools (parallel)
  _parallel_run_layer "Core Tools" \
    "step_opencode:$SCRIPT_DIR/src/lib/11-opencode.sh:OpenCode CLI" \
    "step_mcp:$SCRIPT_DIR/src/lib/12-mcp-lsp.sh:MCP + LSP" \
    "step_chromadb:$SCRIPT_DIR/src/lib/13-chromadb.sh:ChromaDB" \
    "step_shokunin:$SCRIPT_DIR/src/lib/14-shokunin.sh:Shokunin"

  # Layer 4: AI/ML stack (parallel)
  _parallel_run_layer "AI/ML" \
    "step_security:$SCRIPT_DIR/src/lib/15-security.sh:Security" \
    "step_llm:$SCRIPT_DIR/src/lib/16-llm.sh:LLM Stack" \
    "step_project:$SCRIPT_DIR/src/lib/17-project.sh:Project" \
    "step_json:$SCRIPT_DIR/src/lib/18-opencode-json.sh:Config"

  # Layer 5: Optional enhancements (parallel)
  _parallel_run_layer "Enhancements" \
    "step_rag:$SCRIPT_DIR/src/lib/21-rag.sh:RAG" \
    "step_webui:$SCRIPT_DIR/src/lib/22-webui-service.sh:WebUI" \
    "step_mise:$SCRIPT_DIR/src/lib/29-mise.sh:mise" \
    "step_just:$SCRIPT_DIR/src/lib/23-just.sh:just" \
    "step_websearch:$SCRIPT_DIR/src/lib/24-websearch.sh:WebSearch"

  # Layer 6: Configuration (parallel)
  _parallel_run_layer "Configuration" \
    "step_providers:$SCRIPT_DIR/src/lib/26-providers.sh:Providers" \
    "step_isolated:$SCRIPT_DIR/src/lib/32-isolated.sh:Isolated" \
    "step_model_router:$SCRIPT_DIR/src/lib/36-model-router.sh:Router" \
    "step_context_selector:$SCRIPT_DIR/src/lib/52-context-selector.sh:Context" \
    "step_auto_skills:$SCRIPT_DIR/src/lib/53-auto-skills.sh:Skills"

  # Layer 7: Advanced features (parallel)
  _parallel_run_layer "Advanced" \
    "step_task_distributor:$SCRIPT_DIR/src/lib/54-task-distributor.sh:Tasks" \
    "step_context_bundle:$SCRIPT_DIR/src/lib/55-context-bundle.sh:Bundle" \
    "step_grace_semantics:$SCRIPT_DIR/src/lib/56-grace-semantics.sh:GRACE" \
    "step_caching:$SCRIPT_DIR/src/lib/60-caching.sh:Caching" \
    "step_context_guard:$SCRIPT_DIR/src/lib/57-context-guard.sh:Guard"

  # Layer 8: Final (parallel)
  _parallel_run_layer "Finalization" \
    "step_provider_discovery:$SCRIPT_DIR/src/lib/58-provider-discovery.sh:Discovery" \
    "step_local_memory:$SCRIPT_DIR/src/lib/59-local-memory.sh:Memory" \
    "step_daytona:$SCRIPT_DIR/src/lib/61-daytona.sh:Daytona" \
    "step_best_practices:$SCRIPT_DIR/src/lib/40-best-practices.sh:BestPractices" \
    "step_upstream_sync:$SCRIPT_DIR/src/lib/99-upstream-sync.sh:Sync"

  # Calculate total time
  local end_time total_time
  end_time=$(date +%s)
  total_time=$((end_time - start_time))

  # Summary
  section "Parallel Installation Summary"
  local total_modules done_count failed_count
  total_modules=$(wc -l < "$_PARALLEL_PROGRESS_FILE" 2>/dev/null || echo 0)
  done_count=$(grep -c ":DONE:" "$_PARALLEL_PROGRESS_FILE" 2>/dev/null || echo 0)
  failed_count=$(grep -c ":FAILED:" "$_PARALLEL_PROGRESS_FILE" 2>/dev/null || echo 0)

  log "Total modules: $total_modules"
  log "Completed: $done_count"
  [ "$failed_count" -gt 0 ] && warn "Failed: $failed_count"
  log "Total time: ${total_time}s"
  log "Avg per module: $((total_time / (total_modules > 0 ? total_modules : 1)))s"
}

# ── Skip-flag processor ─────────────────────────────────────────────────────
# Usage: _process_skip_flags "flag1,flag2,flag3"
# Sets SKIP_* environment variables for each flag.
_process_skip_flags() {
  local flags="$1"
  IFS=',' read -ra flag_array <<< "$flags"
  for flag in "${flag_array[@]}"; do
    flag=$(echo "$flag" | xargs)  # trim whitespace
    case "$flag" in
      devbox)     export SKIP_DEVBOX=true ;;
      dotfiles)   export SKIP_DOTFILES=true ;;
      gui)        export SKIP_GUI=true ;;
      cockpit)    export SKIP_COCKPIT=true ;;
      caching)    export SKIP_CACHING=true ;;
      rag)        export SKIP_RAG=true ;;
      webui)      export SKIP_WEBUI=true ;;
      mise)       export SKIP_MISE=true ;;
      just)       export SKIP_JUST=true ;;
      websearch)  export SKIP_WEBSEARCH=true ;;
      security)   export SKIP_SECURITY=true ;;
      llm)        export SKIP_LLM=true ;;
      chrome)     export SKIP_CHROME=true ;;
      *)          warn "Unknown skip flag: $flag" ;;
    esac
    info "Skip flag: $flag"
  done
}

# ── Incremental install check ────────────────────────────────────────────────
# Returns 0 if module should be installed, 1 if already installed.
_should_install() {
  local module_name="$1"
  local marker_file="${DL_CACHE}/installed/${module_name}"

  # Force reinstall if --force flag is set
  if [ "${FORCE_REINSTALL:-false}" = "true" ]; then
    return 0
  fi

  # Check if marker exists and is recent (< 24h)
  if [ -f "$marker_file" ]; then
    local marker_age
    marker_age=$(( $(date +%s) - $(stat -c %Y "$marker_file" 2>/dev/null || echo 0) ))
    if [ "$marker_age" -lt 86400 ]; then
      log "Skip: $module_name (installed ${marker_age}s ago)"
      return 1
    fi
  fi

  return 0
}

# Mark module as installed
_mark_installed() {
  local module_name="$1"
  local marker_dir="${DL_CACHE}/installed"
  mkdir -p "$marker_dir"
  date -u +"%Y-%m-%dT%H:%M:%SZ" > "${marker_dir}/${module_name}"
}

# ── Export functions ─────────────────────────────────────────────────────────
export -f _parallel_run_layer _parallel_wait_all _parallel_install \
  _process_skip_flags _should_install _mark_installed 2>/dev/null || true
