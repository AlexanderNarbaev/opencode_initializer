---
description: Run the project's test suite and summarise failures
agent: build
---
Run the tests for this project: $ARGUMENTS

1. Detect the runner (package.json scripts, Makefile, justfile, pytest, go test,
   tests/run_tests.sh). Prefer the repository's documented command.
2. Run it; capture the tail of the output.
3. If something fails: report the failing test, the first useful error line, and a
   minimal root-cause hypothesis. Do not weaken or delete tests.
4. If everything passes: report the exact command and the pass/fail counts.
