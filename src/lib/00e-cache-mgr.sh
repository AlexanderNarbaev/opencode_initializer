#!/usr/bin/env bash
# src/lib/00e-cache-mgr.sh — Download Cache Manager (v3.5.0)
# Centralized download caching with dedup, integrity checks, and cleanup.
# Prevents re-downloading of already-fetched packages across runs.
# Sources: src/lib/helpers.sh must be sourced before this file
set -euo pipefail

# ── Cache configuration ──────────────────────────────────────────────────────
_CACHE_ROOT="${DL_CACHE}/packages"
_CACHE_INDEX="${_CACHE_ROOT}/.cache-index.json"
_CACHE_MAX_AGE_DAYS="${CACHE_MAX_AGE_DAYS:-30}"
_CACHE_MAX_SIZE_MB="${CACHE_MAX_SIZE_MB:-5120}"  # 5GB default

# ── Cache initialization ─────────────────────────────────────────────────────
_cache_init() {
  mkdir -p "$_CACHE_ROOT"
  if [ ! -f "$_CACHE_INDEX" ]; then
    echo '{"version":1,"entries":{}}' > "$_CACHE_INDEX"
  fi
}

# ── Generate cache key from URL ──────────────────────────────────────────────
# Usage: key=$(_cache_key "https://example.com/file.tar.gz")
_cache_key() {
  local url="$1"
  # Use SHA256 of URL as key (first 16 chars for readability)
  if command -v sha256sum &>/dev/null; then
    echo "$url" | sha256sum | cut -c1-16
  elif command -v shasum &>/dev/null; then
    echo "$url" | shasum -a 256 | cut -c1-16
  else
    # Fallback: use sanitized URL as filename
    echo "$url" | tr '/:?' '---' | tail -c 16
  fi
}

# ── Check if URL is cached ──────────────────────────────────────────────────
# Usage: if _cache_hit "https://..."; then use cached; else download; fi
# Returns 0 if cached file exists and is valid, 1 otherwise.
_cache_hit() {
  local url="$1"
  local key
  key=$(_cache_key "$url")
  local cached_file="${_CACHE_ROOT}/${key}"

  # Check if file exists
  if [ ! -f "$cached_file" ]; then
    return 1
  fi

  # Check if file is not empty
  if [ ! -s "$cached_file" ]; then
    rm -f "$cached_file"
    return 1
  fi

  # Check age (optional, controlled by CACHE_MAX_AGE_DAYS)
  if [ "${_CACHE_MAX_AGE_DAYS}" -gt 0 ]; then
    local file_age_days
    file_age_days=$(( ($(date +%s) - $(stat -c %Y "$cached_file" 2>/dev/null || echo 0)) / 86400 ))
    if [ "$file_age_days" -gt "$_CACHE_MAX_AGE_DAYS" ]; then
      info "Cache expired: $url (${file_age_days} days old)"
      rm -f "$cached_file"
      return 1
    fi
  fi

  log "Cache hit: $url → $cached_file"
  return 0
}

# ── Get cached file path ────────────────────────────────────────────────────
# Usage: path=$(_cache_get "https://...")
# Returns path to cached file, or empty string if not cached.
_cache_get() {
  local url="$1"
  local key
  key=$(_cache_key "$url")
  local cached_file="${_CACHE_ROOT}/${key}"

  if [ -f "$cached_file" ] && [ -s "$cached_file" ]; then
    echo "$cached_file"
    return 0
  fi
  return 1
}

# ── Store file in cache ─────────────────────────────────────────────────────
# Usage: _cache_store "https://..." "/path/to/downloaded/file"
# Moves (not copies) the file into cache, then symlinks/copies to original path.
_cache_store() {
  local url="$1" source_file="$2"
  local key
  key=$(_cache_key "$url")
  local cached_file="${_CACHE_ROOT}/${key}"

  _cache_init

  # Move file to cache
  if mv "$source_file" "$cached_file" 2>/dev/null; then
    # Create symlink at original location
    ln -sf "$cached_file" "$source_file" 2>/dev/null || \
      cp "$cached_file" "$source_file" 2>/dev/null || true

    # Update index
    _cache_index_update "$url" "$key"

    log "Cached: $url → $cached_file"
    return 0
  fi

  warn "Failed to cache: $url"
  return 1
}

# ── Download with cache ─────────────────────────────────────────────────────
# Usage: _cache_download "https://..." "/dest/path" [sha256]
# Downloads to cache first, then copies to destination. Verifies SHA256 if given.
_cache_download() {
  local url="$1" dest="$2" sha256="${3:-}"

  # Check cache first
  if _cache_hit "$url"; then
    local cached
    cached=$(_cache_get "$url")
    if [ -n "$cached" ]; then
      # Verify SHA256 if provided
      if [ -n "$sha256" ]; then
        local actual_sha
        actual_sha=$(_sha256 "$cached" | awk '{print $1}')
        if [ "$actual_sha" != "$sha256" ]; then
          warn "Cache SHA256 mismatch for $url — re-downloading"
          rm -f "$cached"
        else
          # Cache is valid — copy to destination
          cp "$cached" "$dest"
          log "Used cached: $url"
          return 0
        fi
      else
        # No SHA256 check — use cache as-is
        cp "$cached" "$dest"
        log "Used cached: $url"
        return 0
      fi
    fi
  fi

  # Cache miss — download
  local tmp_dest="${dest}.tmp"
  if _curl "$url" "$tmp_dest"; then
    # Verify SHA256 if provided
    if [ -n "$sha256" ]; then
      local actual_sha
      actual_sha=$(_sha256 "$tmp_dest" | awk '{print $1}')
      if [ "$actual_sha" != "$sha256" ]; then
        warn "SHA256 mismatch: expected $sha256, got $actual_sha"
        rm -f "$tmp_dest"
        return 1
      fi
    fi

    # Move to destination
    mv "$tmp_dest" "$dest"

    # Store in cache (creates a copy)
    cp "$dest" "${dest}.cache_tmp" 2>/dev/null && \
      _cache_store "$url" "${dest}.cache_tmp" || true

    log "Downloaded: $url"
    return 0
  fi

  rm -f "$tmp_dest"
  warn "Download failed: $url"
  return 1
}

# ── Update cache index ──────────────────────────────────────────────────────
_cache_index_update() {
  local url="$1" key="$2"
  local now
  now=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

  # Use python3 for atomic JSON update (if available)
  if command -v python3 &>/dev/null; then
    python3 -c "
import json, sys
try:
    with open('$_CACHE_INDEX', 'r') as f:
        data = json.load(f)
except:
    data = {'version': 1, 'entries': {}}
data['entries']['$key'] = {'url': '$url', 'cached_at': '$now'}
with open('$_CACHE_INDEX', 'w') as f:
    json.dump(data, f, indent=2)
" 2>/dev/null || true
  fi
}

# ── Cache cleanup ───────────────────────────────────────────────────────────
# Removes old entries based on CACHE_MAX_AGE_DAYS and CACHE_MAX_SIZE_MB.
_cache_cleanup() {
  _cache_init

  local removed=0
  local total_size=0

  # Remove expired entries
  if [ "${_CACHE_MAX_AGE_DAYS}" -gt 0 ]; then
    for cached_file in "$_CACHE_ROOT"/*; do
      [ -f "$cached_file" ] || continue
      [[ "$(basename "$cached_file")" == .* ]] && continue  # skip hidden files

      local file_age_days
      file_age_days=$(( ($(date +%s) - $(stat -c %Y "$cached_file" 2>/dev/null || echo 0)) / 86400 ))
      if [ "$file_age_days" -gt "$_CACHE_MAX_AGE_DAYS" ]; then
        rm -f "$cached_file"
        removed=$((removed + 1))
      fi
    done
  fi

  # Check total size
  total_size=$(du -sm "$_CACHE_ROOT" 2>/dev/null | awk '{print $1}')
  if [ "${total_size:-0}" -gt "${_CACHE_MAX_SIZE_MB}" ]; then
    info "Cache size ${total_size}MB exceeds limit ${_CACHE_MAX_SIZE_MB}MB — cleaning oldest"
    # Remove oldest files until under limit
    ls -t "$_CACHE_ROOT"/* 2>/dev/null | tail -n +100 | while read -r f; do
      [ -f "$f" ] && rm -f "$f"
    done
  fi

  log "Cache cleanup: removed $removed entries"
}

# ── Cache statistics ────────────────────────────────────────────────────────
_cache_stats() {
  _cache_init

  local file_count total_size hit_count miss_count
  file_count=$(find "$_CACHE_ROOT" -type f -not -name '.*' 2>/dev/null | wc -l)
  total_size=$(du -sh "$_CACHE_ROOT" 2>/dev/null | awk '{print $1}')
  hit_count=$(grep -c "cache_hit" "$_CACHE_ROOT/.cache-log" 2>/dev/null || echo 0)
  miss_count=$(grep -c "cache_miss" "$_CACHE_ROOT/.cache-log" 2>/dev/null || echo 0)

  echo "Cache Statistics:"
  echo "  Files: $file_count"
  echo "  Size: $total_size"
  echo "  Hits: $hit_count"
  echo "  Misses: $miss_count"
}

# ── Export functions ─────────────────────────────────────────────────────────
export -f _cache_init _cache_key _cache_hit _cache_get _cache_store \
  _cache_download _cache_cleanup _cache_stats 2>/dev/null || true
