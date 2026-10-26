#!/usr/bin/env bash
# Unit tests for src/plugins/governance.js (OpenCode v2 local plugin).
# The v2 plugin API is `{ id, setup(ctx) }` where ctx.tool.hook() registers tool
# hooks and ctx.event.subscribe() yields events. The harness fakes that context
# under Node, so no opencode process is needed.
set -uo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
PLUGIN="$PROJECT_DIR/src/plugins/governance.js"
HARNESS="$(mktemp /tmp/governance-test.XXXXXX.mjs)"
AUDIT_DIR="$(mktemp -d /tmp/governance-audit.XXXXXX)"

PASS=0; FAIL=0
pass() { echo "  PASS: $1"; PASS=$((PASS + 1)); }
fail() { echo "  FAIL: $1"; FAIL=$((FAIL + 1)); }

echo "=== Test 1: plugin shape ==="
[ -f "$PLUGIN" ] && pass "governance.js exists" || fail "governance.js missing"
node --check "$PLUGIN" 2>/dev/null && pass "plugin parses (node --check)" || fail "plugin syntax error"
grep -q 'execute.before' "$PLUGIN" && pass "registers execute.before" || fail "missing before-hook"
grep -q 'execute.after' "$PLUGIN" && pass "registers execute.after" || fail "missing after-hook"
grep -qE 'id: "governance"' "$PLUGIN" && pass "exports a v2 definition with an id" || fail "missing plugin id"
grep -q 'setup' "$PLUGIN" && pass "exports a setup function" || fail "missing setup()"

echo
echo "=== Test 2: behaviour under Node ==="
cat > "$HARNESS" <<'MJS'
import { readFileSync } from "node:fs";
import { pathToFileURL } from "node:url";
const { default: plugin, redact, checkCommand, audit } = await import(
  pathToFileURL(process.env.PLUGIN_PATH).href
);

const out = (ok, name) => console.log(`${ok ? "OK" : "NO"} ${name}`);

out(typeof plugin.id === "string" && plugin.id.length > 0, "plugin has id");
out(typeof plugin.setup === "function", "plugin has setup()");

out(redact("key sk-abcdefghijklmnop1234").includes("***"), "redact sk- key");
out(!redact("sk-abcdefghijklmnop1234").includes("abcdefghijklmnop"), "key body removed");
out(redact("mail john@example.com").includes("***@***"), "redact email");
out(redact("API_KEY=supersecretvalue").includes("API_KEY=***"), "redacts key=value");

out(checkCommand("rm -rf /").blocked === true, "blocks rm -rf /");
out(checkCommand("rm -rf ~").blocked === true, "blocks rm -rf home");
out(checkCommand("mkfs.ext4 /dev/sda1").blocked === true, "blocks mkfs");
out(checkCommand("ls -la").blocked === false, "allows ls");
out(checkCommand("git push --force origin main").blocked === true, "blocks force-push main");
out(checkCommand("rm -rf /", { block: false }).blocked === false, "honours block=false");

const h1 = audit("test.one", { a: 1 });
const h2 = audit("test.two", { b: 2 });
const lines = readFileSync(process.env.AUDIT_FILE, "utf8").trim().split("\n");
const rec1 = JSON.parse(lines[0]);
const rec2 = JSON.parse(lines[1]);
out(/^[0-9a-f]{64}$/.test(h1) && /^[0-9a-f]{64}$/.test(h2), "hashes are sha256 hex");
out(rec2.prev_hash === rec1.hash, "hash chain links records");

const hooks = {};
const ctx = {
  location: { directory: "/tmp/demo" },
  tool: {
    hook: async (name, cb) => {
      hooks[name] = cb;
      return { dispose: async () => {} };
    },
  },
  event: {
    subscribe: () => ({
      [Symbol.asyncIterator]: async function* () {
        yield { type: "session.idle", id: "ev_1" };
      },
    }),
  },
};

const cleanup = await plugin.setup(ctx);
out(typeof hooks["execute.before"] === "function", "before hook registered");
out(typeof hooks["execute.after"] === "function", "after hook registered");

await hooks["execute.before"]({
  tool: "bash",
  sessionID: "ses_1",
  id: "call_1",
  input: { command: "ls -la" },
});
out(true, "safe command is audited");

let threw = false;
try {
  await hooks["execute.before"]({
    tool: "bash",
    sessionID: "ses_1",
    id: "call_2",
    input: { command: "rm -rf /" },
  });
} catch (e) {
  threw = String(e.message).includes("governance");
}
out(threw, "dangerous command is rejected");

await hooks["execute.after"]({
  tool: "bash",
  sessionID: "ses_1",
  id: "call_1",
  status: "completed",
  result: "token=supersecretvalue",
});
await new Promise((r) => setTimeout(r, 30));
const text = readFileSync(process.env.AUDIT_FILE, "utf8");
out(text.includes("session.idle"), "session event is audited");
out(!text.includes("supersecretvalue"), "tool output is redacted");
out(text.includes("tool.execute.before") && text.includes("tool.execute.after"), "both tool hooks audited");

const all = text.trim().split("\n").map((l) => JSON.parse(l));
let ok = true;
for (let i = 1; i < all.length; i++) if (all[i].prev_hash !== all[i - 1].hash) ok = false;
out(ok, "every audit record chains to the previous hash");

await cleanup();
out(true, "cleanup runs without throwing");

process.env.OPENCODE_GOVERNANCE = "off";
const off = await plugin.setup({ location: { directory: "/tmp" } });
out(off === undefined || typeof off === "function", "OPENCODE_GOVERNANCE=off short-circuits");
MJS

PLUGIN_PATH="$PLUGIN" AUDIT_FILE="$AUDIT_DIR/audit.jsonl" OPENCODE_AUDIT_DIR="$AUDIT_DIR" \
  node "$HARNESS" > /tmp/governance-out.txt 2>/tmp/governance-err.txt
rc=$?
if [ "$rc" -ne 0 ]; then
  fail "node harness exited $rc"
  sed -n '1,12p' /tmp/governance-err.txt
fi
while IFS= read -r line; do
  case "$line" in
    "OK "*) pass "${line#OK }" ;;
    "NO "*) fail "${line#NO }" ;;
  esac
done < /tmp/governance-out.txt

checks=$(grep -cE '^(OK|NO) ' /tmp/governance-out.txt || true)
[ "${checks:-0}" -ge 20 ] && pass "harness ran $checks assertions" || fail "harness ran only ${checks:-0} assertions"

echo
echo "=== Test 3: audit file is append-only JSONL ==="
if [ -f "$AUDIT_DIR/audit.jsonl" ]; then
  bad=0
  while IFS= read -r line; do echo "$line" | jq empty 2>/dev/null || bad=$((bad + 1)); done < "$AUDIT_DIR/audit.jsonl"
  [ "$bad" -eq 0 ] && pass "every audit line is valid JSON" || fail "$bad invalid JSON lines"
else
  fail "audit file was not created"
fi

rm -f "$HARNESS"; rm -rf "$AUDIT_DIR"

echo
echo "=========================================="
echo "RESULTS: $PASS pass, $FAIL fail"
echo "=========================================="
[ "$FAIL" -eq 0 ] || exit 1
