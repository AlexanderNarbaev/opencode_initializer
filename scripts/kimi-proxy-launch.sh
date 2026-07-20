#!/usr/bin/env bash
# Wrapper to launch kimi proxy cleanly
cd /home/alexandr-narbaev/Projects/opencode_initializer || exit 1
exec python3 scripts/kimi-anthropic-proxy.py