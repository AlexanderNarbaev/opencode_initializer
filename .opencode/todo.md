# Mission Tasks

## Task List

- [x] Remove `opencode-context` + `opencode-router` from plugin array in `~/.config/opencode/opencode.json` (breaking `opencode agent list`)
- [x] Uninstall both plugins via npm (durable fix — CLI was auto-re-registering them)
- [x] Verify `opencode agent list 2>&1 | grep -cE "^[a-z_-]+ \("` returns 57 (stable: 57/57/57)
- [x] Verify `opencode stats` does not hang (`--pure --days 1` → exit 0, full cost/cache output)
- [x] Verify `~/.config/opencode/opencode.json` remains valid JSON (`jq empty` → clean, 31 plugins)
