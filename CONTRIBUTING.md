# Contributing

## How to contribute

1. Fork the repo (GitHub or GitVerse)
2. Create a feature branch
3. Make your changes
4. Run `bash -n setup.sh` to verify syntax
5. Submit a Pull Request

## Code style

- Bash 4.0+ compatible (no bashisms that break on older shells)
- 2-space indentation
- `snake_case` for variables
- Use helper functions (`_curl`, `_retry`, `_npm_install`) instead of raw commands
- No secrets in code — API keys via env vars or CLI args only

## Adding a new component

1. Add installation block in the appropriate step section
2. Add health check in `--health` mode (search for `health` section)
3. Add verification in the verification section (search for `verify`)
4. Update `AGENTS.md` if the architecture changes

## Commit messages

Follow conventional commits: `type: description`

Examples:
- `fix: mcp grep install failure`
- `feat: add zig direct download fallback`
- `docs: update setup.sh version history`
