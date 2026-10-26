#!/usr/bin/env bash
# src/lib/00v-age-encryption.sh — age encryption for secrets
# https://github.com/FiloSottile/age
set -euo pipefail

# ── Configuration ────────────────────────────────────────────────────────────
_AGE_KEY_FILE="${AGE_KEY_FILE:-$HOME/.config/opencode-init/keys.txt}"
_AGE_RECIPIENTS="${AGE_RECIPIENTS:-}"

# ── Check age availability ───────────────────────────────────────────────────
_age_check() {
  if ! command -v age &>/dev/null; then
    warn "age not installed — encryption disabled"
    info "Install: brew install age"
    return 1
  fi
  return 0
}

# ── Generate key pair ────────────────────────────────────────────────────────
# Usage: _age_keygen
_age_keygen() {
  if ! _age_check; then return 1; fi

  local key_dir
  key_dir=$(dirname "$_AGE_KEY_FILE")
  mkdir -p "$key_dir"

  if [ -f "$_AGE_KEY_FILE" ]; then
    warn "Key file already exists: $_AGE_KEY_FILE"
    info "To regenerate, remove the file first"
    return 1
  fi

  age-keygen -o "$_AGE_KEY_FILE" 2>&1
  chmod 600 "$_AGE_KEY_FILE"

  log "Key generated: $_AGE_KEY_FILE"
  info "Public key: $(grep 'public key' "$_AGE_KEY_FILE" | cut -d: -f2 | tr -d ' ')"
}

# ── Encrypt file ─────────────────────────────────────────────────────────────
# Usage: _age_encrypt FILE [RECIPIENT]
_age_encrypt() {
  local file="$1"
  local recipient="${2:-$_AGE_RECIPIENTS}"

  if ! _age_check; then return 1; fi

  if [ ! -f "$file" ]; then
    warn "File not found: $file"
    return 1
  fi

  if [ -z "$recipient" ]; then
    # Use key file
    if [ ! -f "$_AGE_KEY_FILE" ]; then
      warn "No key file found. Run: opencode-init --age-keygen"
      return 1
    fi
    recipient=$(grep 'public key' "$_AGE_KEY_FILE" | cut -d: -f2 | tr -d ' ')
  fi

  local output="${file}.age"
  age -r "$recipient" -o "$output" "$file"

  log "Encrypted: $file → $output"
  echo "$output"
}

# ── Decrypt file ─────────────────────────────────────────────────────────────
# Usage: _age_decrypt FILE
_age_decrypt() {
  local file="$1"

  if ! _age_check; then return 1; fi

  if [ ! -f "$file" ]; then
    warn "File not found: $file"
    return 1
  fi

  if [ ! -f "$_AGE_KEY_FILE" ]; then
    warn "No key file found. Run: opencode-init --age-keygen"
    return 1
  fi

  local output="${file%.age}"
  age -d -i "$_AGE_KEY_FILE" -o "$output" "$file"

  log "Decrypted: $file → $output"
  echo "$output"
}

# ── Encrypt directory ────────────────────────────────────────────────────────
# Usage: _age_encrypt_dir DIR
_age_encrypt_dir() {
  local dir="$1"

  if ! _age_check; then return 1; fi

  local count=0
  while IFS= read -r -d '' file; do
    _age_encrypt "$file" >/dev/null
    ((count++))
  done < <(find "$dir" -type f -name "*.secret" -print0)

  log "Encrypted $count files in $dir"
}

# ── Decrypt directory ────────────────────────────────────────────────────────
# Usage: _age_decrypt_dir DIR
_age_decrypt_dir() {
  local dir="$1"

  if ! _age_check; then return 1; fi

  local count=0
  while IFS= read -r -d '' file; do
    _age_decrypt "$file" >/dev/null
    ((count++))
  done < <(find "$dir" -type f -name "*.age" -print0)

  log "Decrypted $count files in $dir"
}

# ── Export functions ─────────────────────────────────────────────────────────
export -f _age_check _age_keygen _age_encrypt _age_decrypt _age_encrypt_dir _age_decrypt_dir 2>/dev/null || true
