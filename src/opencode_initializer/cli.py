#!/usr/bin/env python3
"""
OpenCode Initializer CLI — Command line interface.
"""

import sys
import argparse

from . import __version__, run_setup


def parse_args(args: list[str] | None = None) -> argparse.Namespace:
    """Parse command line arguments."""
    parser = argparse.ArgumentParser(
        prog="opencode-init",
        description="AI-Native SDD Harness — one-command AI-enhanced development environment",
    )

    parser.add_argument(
        "--version",
        action="version",
        version=f"%(prog)s {__version__}",
    )

    parser.add_argument(
        "--full",
        action="store_true",
        help="Run full installation",
    )

    parser.add_argument(
        "--health",
        action="store_true",
        help="Run health check",
    )

    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Check without installing",
    )

    parser.add_argument(
        "--config",
        type=str,
        help="Path to configuration file",
    )

    parser.add_argument(
        "--skip",
        type=str,
        help="Comma-separated list of modules to skip",
    )

    parser.add_argument(
        "--parallel",
        type=int,
        help="Number of parallel jobs",
    )

    parser.add_argument(
        "--force",
        action="store_true",
        help="Force reinstall",
    )

    parser.add_argument(
        "--sync",
        action="store_true",
        help="Sync updates",
    )

    parser.add_argument(
        "--security-scan",
        action="store_true",
        help="Run security scan",
    )

    parser.add_argument(
        "--benchmark",
        action="store_true",
        help="Run performance benchmark",
    )

    return parser.parse_args(args)


def main(args: list[str] | None = None) -> int:
    """Main CLI entry point."""
    parsed = parse_args(args)

    # Build arguments for setup.sh
    setup_args = []

    if parsed.full:
        setup_args.append("--full")
    if parsed.health:
        setup_args.append("--health")
    if parsed.dry_run:
        setup_args.append("--dry-run")
    if parsed.config:
        setup_args.extend(["--config", parsed.config])
    if parsed.skip:
        setup_args.extend(["--skip", parsed.skip])
    if parsed.parallel:
        setup_args.extend(["--parallel", str(parsed.parallel)])
    if parsed.force:
        setup_args.append("--force")
    if parsed.sync:
        setup_args.append("--sync")
    if parsed.security_scan:
        setup_args.append("--security-scan")
    if parsed.benchmark:
        setup_args.append("--benchmark")

    return run_setup(setup_args)


if __name__ == "__main__":
    sys.exit(main())
