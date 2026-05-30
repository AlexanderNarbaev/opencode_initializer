#!/usr/bin/env bash
# migration: 20260530-v30-config-changes — update opencode.json to v30 schema
# This migration is safe to run multiple times (idempotent)

OP="$(dirname "$0")/.."
if [ -f "$OP/setup.sh" ]; then
  bash "$OP/setup.sh" --fix-config
  echo "opencode.json migrated to v30 schema"
fi
