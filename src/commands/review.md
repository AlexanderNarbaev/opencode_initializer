---
description: Review the current diff for defects (no edits)
agent: build
---
Review the current working-tree diff (git diff, plus staged if any): $ARGUMENTS

Rules:
- Read the changed files and their surrounding code before judging.
- Report only findings you can anchor to file:line, grouped BLOCKER / MAJOR / MINOR,
  each with a concrete fix.
- Check for regressions, missing tests, secret leakage and unsafe shell commands.
- Do not modify files; finish with an explicit verdict: APPROVE or REQUEST CHANGES.
