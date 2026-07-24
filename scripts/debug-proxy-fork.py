#!/usr/bin/env python3
"""Daemon launcher for debug-proxy."""
import os
import sys

PROXY = "/home/alexandr-narbaev/Projects/opencode_initializer/scripts/debug-proxy.py"
LOG = "/home/alexandr-narbaev/Projects/opencode_initializer/.debug-proxy.log"

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
os.execv(sys.executable, [sys.executable, PROXY])
