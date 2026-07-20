#!/usr/bin/env bash
# Start kimi-anthropic-proxy in background, redirecting output to workspace dir.
# Caller sets MOONSHOT_API_KEY in env before invoking.
cd /home/alexandr-narbaev/Projects/opencode_initializer || exit 1
exec python3 scripts/kimi-anthropic-proxy.py