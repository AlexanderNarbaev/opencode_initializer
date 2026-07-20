#!/usr/bin/env python3
"""Daemon launcher for litellm proxy."""
import os
import sys
import time

PROXY = "/home/alexandr-narbaev/.local/share/pipx/venvs/litellm/bin/litellm"
CONFIG = "/home/alexandr-narbaev/Projects/opencode_initializer/litellm-config.yaml"
LOG = "/home/alexandr-narbaev/Projects/opencode_initializer/.litellm.log"

pid = os.fork()
if pid > 0:
    print(f"Started daemon PID={pid}")
    sys.exit(0)

os.setsid()
pid = os.fork()
if pid > 0:
    sys.exit(0)

sys.stdin = open("/dev/null", "r")
log = open(LOG, "a")
os.dup2(log.fileno(), 1)
os.dup2(log.fileno(), 2)
os.execv(PROXY, [PROXY, "--config", CONFIG, "--port", "9876"])
