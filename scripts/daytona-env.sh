#!/usr/bin/env bash
# scripts/daytona-env.sh — declarative Daytona environments registry → CLI
# Reads environments.json (${DAYTONA_ENVIRONMENTS} or
# ${XDG_CONFIG_HOME:-$HOME/.config}/opencode/daytona/environments.json) and
# translates registry entries into `daytona` create/status/delete commands.
# Single source of truth: installed to ~/.local/bin/daytona-env by module
# 61-daytona.sh. Bash 3.2 safe (no associative arrays); JSON via python3.
set -euo pipefail

ENV_FILE="${DAYTONA_ENVIRONMENTS:-${XDG_CONFIG_HOME:-$HOME/.config}/opencode/daytona/environments.json}"

_usage() {
  cat >&2 <<'EOF'
Usage: daytona-env <command> [args]

Commands:
  list                 Pretty-print registry entries
  create <name>        Compose and run `daytona create` for a registry entry
  status               Show sandboxes (daytona list)
  delete <id|name>     Delete a sandbox
  prune                Delete all sandboxes (confirmation required)
  help                 Show this help

Registry: $DAYTONA_ENVIRONMENTS (or default environments.json from module 61)
EOF
}

_missing_config() {
  echo "No environments registry at $ENV_FILE" >&2
  echo "Generate it with opencode_initializer module 61 (setup.sh step_daytona)," >&2
  echo "or set DAYTONA_ENVIRONMENTS to point at your own registry." >&2
}

# ── list ────────────────────────────────────────────────────────────────────
cmd_list() {
  [ -f "$ENV_FILE" ] || { _missing_config; return 1; }
  python3 - "$ENV_FILE" <<'PYEOF'
import json, sys
data = json.load(open(sys.argv[1]))
envs = data.get("environments", [])
defaults = data.get("defaults", {})
print("Daytona environments registry: %s" % sys.argv[1])
print()
if not envs:
    print("(empty — add entries to the environments array)")
    sys.exit(0)
for e in envs:
    name = e.get("name", "(unnamed)")
    cpu = e.get("cpu", defaults.get("cpu", 2))
    mem = e.get("memory_gb", defaults.get("memory_gb", 4))
    disk = e.get("disk_gb", defaults.get("disk_gb", 10))
    auto = e.get("auto_stop_minutes", defaults.get("auto_stop_minutes", 15))
    img = e.get("image", {})
    base = "snapshot=%s" % img["snapshot"] if img.get("snapshot") else ("dockerfile=%s" % img["dockerfile"] if img.get("dockerfile") else "default")
    labels = ",".join(e.get("labels", [])) or "-"
    print("- %s  cpu=%s mem=%sG disk=%sG auto-stop=%sm target=%s image=[%s] labels=[%s]"
          % (name, cpu, mem, disk, auto, e.get("target", defaults.get("target", "us")), base, labels))
PYEOF
}

# ── create <name> ───────────────────────────────────────────────────────────
cmd_create() {
  local name="${1:-}"
  [ -n "$name" ] || { echo "Usage: daytona-env create <name>" >&2; return 1; }
  [ -f "$ENV_FILE" ] || { _missing_config; return 1; }

  local cmd
  cmd="$(python3 - "$ENV_FILE" "$name" <<'PYEOF'
import json, sys
path, name = sys.argv[1], sys.argv[2]
data = json.load(open(path))
defaults = data.get("defaults", {})
entry = next((e for e in data.get("environments", []) if e.get("name") == name), None)
if entry is None:
    print("__MISSING__")
    raise SystemExit
cpu = entry.get("cpu", defaults.get("cpu", 2))
mem = entry.get("memory_gb", defaults.get("memory_gb", 4))
disk = entry.get("disk_gb", defaults.get("disk_gb", 10))
auto = entry.get("auto_stop_minutes", defaults.get("auto_stop_minutes", 15))
target = entry.get("target", defaults.get("target", "us"))
parts = ["daytona", "create", "--name", name,
         "--cpu", str(cpu), "--memory", str(mem), "--disk", str(disk),
         "--auto-stop", str(auto), "--target", target]
img = entry.get("image", {})
if img.get("snapshot"):
    parts += ["--snapshot", img["snapshot"]]
elif img.get("dockerfile"):
    parts += ["--dockerfile", img["dockerfile"]]
for k, v in sorted((entry.get("env") or {}).items()):
    parts += ["--env", "%s=%s" % (k, v)]
for lab in (entry.get("labels") or []):
    parts += ["--label", lab]
print(" ".join(parts))
PYEOF
)"

  [ "$cmd" = "__MISSING__" ] && { echo "No environment '$name' in registry" >&2; return 1; }

  echo "Composed: $cmd"
  if command -v daytona >/dev/null 2>&1; then
    echo "Executing..."
    # shellcheck disable=SC2086
    $cmd
  else
    echo "WARN: daytona CLI not found — command composed but not executed." >&2
    echo "Install it via opencode_initializer module 61 (setup.sh step_daytona)." >&2
    return 1
  fi
}

# ── status / delete / prune ────────────────────────────────────────────────
cmd_status() {
  if command -v daytona >/dev/null 2>&1; then
    daytona list
  else
    echo "WARN: daytona CLI not found." >&2
    return 1
  fi
}

cmd_delete() {
  local target="${1:-}"
  [ -n "$target" ] || { echo "Usage: daytona-env delete <id|name>" >&2; return 1; }
  if command -v daytona >/dev/null 2>&1; then
    daytona delete "$target"
  else
    echo "WARN: daytona CLI not found." >&2
    return 1
  fi
}

cmd_prune() {
  printf 'This will delete ALL daytona sandboxes. Type "yes" to confirm: '
  read -r answer
  [ "$answer" = "yes" ] || { echo "Aborted."; return 1; }
  if command -v daytona >/dev/null 2>&1; then
    daytona delete --all
  else
    echo "WARN: daytona CLI not found." >&2
    return 1
  fi
}

# ── dispatch ────────────────────────────────────────────────────────────────
case "${1:-}" in
  list)       cmd_list ;;
  create)     cmd_create "${2:-}" ;;
  status)     cmd_status ;;
  delete)     cmd_delete "${2:-}" ;;
  prune)      cmd_prune ;;
  help | -h | --help | "") _usage ;;
  *) echo "Unknown: daytona-env $1" >&2; _usage; exit 1 ;;
esac
