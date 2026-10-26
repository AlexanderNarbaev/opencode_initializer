---
description: Stage and commit with a conventional message
agent: build
---
Prepare a commit for: $ARGUMENTS

1. `git status` and `git diff` first; never stage secrets, build artefacts or
   unrelated files.
2. Group changes logically; propose ONE conventional-commit message
   (feat/fix/docs/chore/test/refactor) with a short body explaining why.
3. Show the message and the staged file list, then wait for confirmation before
   running `git commit`.
