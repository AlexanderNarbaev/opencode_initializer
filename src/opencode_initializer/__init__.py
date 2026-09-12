#!/usr/bin/env python3
"""
OpenCode Initializer — AI-Native SDD Harness

A one-command setup for AI-enhanced development environments.
"""

__version__ = "12.0.0"
__author__ = "Alexander Narbaev"
__license__ = "MIT"

import subprocess
import sys
import os
from pathlib import Path


def get_project_root() -> Path:
    """Get the project root directory."""
    return Path(__file__).parent.parent.parent


def run_setup(args: list[str] | None = None) -> int:
    """Run the setup.sh script with given arguments."""
    project_root = get_project_root()
    setup_script = project_root / "setup.sh"

    if not setup_script.exists():
        print(f"Error: setup.sh not found at {setup_script}", file=sys.stderr)
        return 1

    cmd = ["bash", str(setup_script)]
    if args:
        cmd.extend(args)

    try:
        result = subprocess.run(cmd, cwd=str(project_root))
        return result.returncode
    except KeyboardInterrupt:
        print("\nInterrupted by user")
        return 130
    except Exception as e:
        print(f"Error: {e}", file=sys.stderr)
        return 1


def main():
    """Main entry point for the CLI."""
    args = sys.argv[1:]

    if not args or "--help" in args or "-h" in args:
        print("OpenCode Initializer — AI-Native SDD Harness")
        print(f"Version: {__version__}")
        print()
        print("Usage: opencode-init [OPTIONS]")
        print()
        print("Options:")
        print("  --full          Run full installation")
        print("  --health        Run health check")
        print("  --dry-run       Check without installing")
        print("  --version       Show version")
        print("  --help          Show this help")
        print()
        print("For full documentation, see:")
        print("  https://alexandernarbaev.github.io/opencode_initializer/")
        return 0

    if "--version" in args:
        print(f"opencode-init {__version__}")
        return 0

    return run_setup(args)


if __name__ == "__main__":
    sys.exit(main())
