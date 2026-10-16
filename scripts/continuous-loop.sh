#!/usr/bin/env bash
# continuous-loop.sh — non-stop self-driving work loop (2026-10-16)
# Cycles forever: verify → self-heal → improve → log. Run in background.
REPO=/home/alexandr-narbaev/Projects/opencode_initializer
LOG=$REPO/.opencode/docs/continuous-loop.log
while true; do
  TS=$(date -Iseconds)
  echo "[$TS] cycle start" >> "$LOG"
  # 1. plugin self-heal: if banned plugins reappeared, prune both configs
  if grep -q "opencode-router\|opencode-cache-ttl" "$HOME/.config/opencode/opencode.json" 2>/dev/null; then
    echo "[$TS] banned plugins detected -> fixing" >> "$LOG"
    bash "$REPO/scripts/fix-plugin-configs.sh" >> "$LOG" 2>&1
  fi
  # 2. health
  cd "$REPO" && timeout 120 bash setup.sh --health 2>&1 | tail -2 >> "$LOG"
  # 3. services self-heal (restart dead docker deps)
  for c in opencode-postgres rag-redis rag-qdrant; do
    docker inspect -f '{{.State.Running}}' "$c" 2>/dev/null | grep -q true || docker start "$c" >> "$LOG" 2>&1
  done
  # 4. hourly full test run marker
  if [ "$(date +%M)" = "00" ]; then
    echo "[$TS] hourly test run" >> "$LOG"
    timeout 1500 bash tests/run_tests.sh 2>&1 | tail -2 >> "$LOG"
  fi
  # 5. keep reports fresh: regenerate history snapshot
  git log --oneline -20 > "$REPO/.opencode/docs/live-git-snapshot.txt"
  echo "[$TS] cycle done" >> "$LOG"
  sleep 300
done
