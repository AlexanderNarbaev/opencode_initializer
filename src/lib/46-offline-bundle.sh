#!/usr/bin/env bash
# src/lib/46-offline-bundle.sh — Air-gap offline bootstrap bundle (STEP 46)
# Enables: dev bundle create | setup.sh --airgap
# See: audit finding G19, corporate-airgap-profile.md §3.2
# v3.0.0
set -euo pipefail

# When sourced from dev.sh (not setup.sh module chain), skip the step gate
if declare -f _step_skip &>/dev/null; then
  _step_skip step_offline_bundle && return 0
fi

section "Offline Bundle — Air-Gap Bootstrap"

# ── Bundle directory ─────────────────────────────────────────────────────────
BUNDLE_DIR="${BUNDLE_DIR:-${HOME}/.cache/opencode-setup/offline-bundle}"
BUNDLE_MANIFEST="$BUNDLE_DIR/manifest.sha256"
BUNDLE_TARBALL="${BUNDLE_DIR}/opencode-offline-${SCRIPT_VERSION:-v3.0.0}.tar.gz"

# ── Create offline bundle: collects all dependencies for air-gap install ────
_offline_bundle_create() {
  local output="${1:-$BUNDLE_TARBALL}"
  local tmpdir
  tmpdir=$(mktemp -d /tmp/opencode-bundle.XXXXXX)
  mkdir -p "$tmpdir/bundle"

  info "Creating offline bundle: $output"
  _spin_start "Collecting dependencies"

  # ── Core scripts ──────────────────────────────────────────────────────────
  cp "$SCRIPT_DIR/setup.sh" "$tmpdir/bundle/"
  cp "$SCRIPT_DIR/dev.sh" "$tmpdir/bundle/"
  cp -r "$SCRIPT_DIR/src" "$tmpdir/bundle/"
  cp -r "$SCRIPT_DIR/scripts" "$tmpdir/bundle/"
  cp -r "$SCRIPT_DIR/tests" "$tmpdir/bundle/" 2>/dev/null || true
  cp -r "$SCRIPT_DIR/migrations" "$tmpdir/bundle/" 2>/dev/null || true
  cp "$SCRIPT_DIR/.env.example" "$tmpdir/bundle/" 2>/dev/null || true

  # ── Documentation ─────────────────────────────────────────────────────────
  cp -r "$SCRIPT_DIR/docs" "$tmpdir/bundle/" 2>/dev/null || true
  cp "$SCRIPT_DIR/README.md" "$tmpdir/bundle/" 2>/dev/null || true
  cp "$SCRIPT_DIR/AGENTS.md" "$tmpdir/bundle/" 2>/dev/null || true
  cp "$SCRIPT_DIR/CHANGELOG.md" "$tmpdir/bundle/" 2>/dev/null || true

  # ── MCP npm packages (offline cache) ──────────────────────────────────────
  if [ -d "$DL_CACHE/mcp-offline" ]; then
    cp -r "$DL_CACHE/mcp-offline" "$tmpdir/bundle/cache/" 2>/dev/null || true
  fi

  # ── Generate SHA256 manifest ──────────────────────────────────────────────
  cd "$tmpdir/bundle"
  find . -type f -exec sha256sum {} \; | sort -k2 > "$tmpdir/bundle/manifest.sha256"
  echo "# Offline Bundle Manifest — $(date -u +%Y-%m-%dT%H:%M:%SZ)" >> "$tmpdir/bundle/manifest.sha256"
  echo "# Version: ${SCRIPT_VERSION:-v3.0.0}" >> "$tmpdir/bundle/manifest.sha256"
  echo "# Files: $(find . -type f | wc -l)" >> "$tmpdir/bundle/manifest.sha256"

  # ── Create tarball ────────────────────────────────────────────────────────
  mkdir -p "$(dirname "$output")"
  tar -czf "$output" -C "$tmpdir" bundle/
  _spin_stop "✓"

  # ── Verify the tarball ────────────────────────────────────────────────────
  local size
  size=$(du -sh "$output" | awk '{print $1}')
  log "Offline bundle created: $output ($size)"
  log "Bundle manifest: $(grep -c '^[a-f0-9]' "$tmpdir/bundle/manifest.sha256") files verified"

  # ── Keep manifest accessible ──────────────────────────────────────────────
  mkdir -p "$BUNDLE_DIR"
  cp "$tmpdir/bundle/manifest.sha256" "$BUNDLE_MANIFEST"
  rm -rf "$tmpdir"
  _step_done step_offline_bundle
  return 0
}

# ── Run from offline bundle (called by setup.sh --airgap) ───────────────────
_offline_bundle_run() {
  local bundle_path="${1:-$BUNDLE_DIR}"

  if [ ! -d "$bundle_path/bundle" ]; then
    # Try extracting from tarball
    local tarball
    tarball=$(ls -t "$BUNDLE_DIR"/opencode-offline-*.tar.gz 2>/dev/null | head -1)
    if [ -n "$tarball" ] && [ -f "$tarball" ]; then
      info "Extracting offline bundle: $tarball"
      tar -xzf "$tarball" -C "$(dirname "$bundle_path")" 2>/dev/null || {
        warn "Offline bundle extraction failed"
        return 1
      }
    else
      warn "Offline bundle not found at $bundle_path — run 'dev bundle create' first on an online machine"
      return 1
    fi
  fi

  # ── Verify SHA256 integrity ───────────────────────────────────────────────
  local manifest="$bundle_path/bundle/manifest.sha256"
  if [ -f "$manifest" ]; then
    _spin_start "Verifying bundle integrity"
    if (cd "$bundle_path/bundle" && sha256sum -c "$manifest" --quiet 2>/dev/null); then
      _spin_stop "✓"
      log "Bundle integrity: VERIFIED"
    else
      _spin_stop "✗"
      warn "Bundle integrity check FAILED — some files may be corrupted"
    fi
  fi

  # ── Source modules from the bundle ────────────────────────────────────────
  export SCRIPT_DIR="$bundle_path/bundle"
  info "ISOLATED CIRCUIT: running from offline bundle at $bundle_path"
  return 0
}

# ── Verify bundle integrity ─────────────────────────────────────────────────
_offline_bundle_verify() {
  local bundle_path="${1:-$BUNDLE_DIR}"
  local manifest="$bundle_path/bundle/manifest.sha256"

  if [ ! -f "$manifest" ]; then
    warn "No manifest found at $manifest"
    return 1
  fi

  echo "=== Bundle Integrity Report ==="
  echo "Manifest: $manifest"
  echo "Generated: $(grep '^# Version' "$manifest" | sed 's/^# //')"
  echo "Files in manifest: $(grep -c '^[a-f0-9]' "$manifest")"

  cd "$bundle_path/bundle"
  if sha256sum -c "$manifest" --quiet 2>/dev/null; then
    echo "Status: ALL FILES VERIFIED ✅"
    return 0
  else
    echo "Status: CORRUPTION DETECTED ❌"
    sha256sum -c "$manifest" 2>/dev/null | grep -v ': OK$' || true
    return 1
  fi
}

# ── List bundle contents ─────────────────────────────────────────────────────
_offline_bundle_list() {
  local bundle_path="${1:-$BUNDLE_DIR}"
  local tarball
  tarball=$(ls -t "$BUNDLE_DIR"/opencode-offline-*.tar.gz 2>/dev/null | head -1)

  if [ ! -f "$tarball" ] && [ ! -d "$bundle_path/bundle" ]; then
    echo "No offline bundle found at $BUNDLE_DIR"
    echo "Create one with: dev bundle create"
    return 0
  fi

  echo ""
  echo "  Bundle directory: $bundle_path"

  if [ -f "$tarball" ]; then
    local size files
    size=$(du -sh "$tarball" 2>/dev/null | awk '{print $1}')
    files=$(tar -tzf "$tarball" 2>/dev/null | wc -l)
    echo "  Tarball: $(basename "$tarball")"
    echo "  Size:    $size"
    echo "  Files:   $files"
  fi

  if [ -d "$bundle_path/bundle" ]; then
    echo "  Extracted: YES"
    echo "  Contents:"
    ls -1 "$bundle_path/bundle/" 2>/dev/null | sed 's/^/    /'
  fi

  if [ -f "$BUNDLE_MANIFEST" ]; then
    echo ""
    echo "  Manifest: $(head -1 "$BUNDLE_MANIFEST" 2>/dev/null || echo 'present')"
    echo "  Files in manifest: $(grep -c '^[a-f0-9]' "$BUNDLE_MANIFEST" 2>/dev/null || echo 0)"
  fi
  echo ""
  return 0
}

# ── Exports ──────────────────────────────────────────────────────────────────
export BUNDLE_DIR BUNDLE_MANIFEST BUNDLE_TARBALL
export -f _offline_bundle_create _offline_bundle_run _offline_bundle_verify _offline_bundle_list

if declare -f _step_done &>/dev/null; then
  _step_done step_offline_bundle
fi
log "Offline bundle support initialized — use 'dev bundle create' to build"
