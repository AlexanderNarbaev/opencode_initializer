// governance.js — hash-chained audit trail + secret redaction + dangerous-command guard.
//
// Restores, for OpenCode v2, what the v1 `~/.config/opencode/hooks/` stubs only
// pretended to do (10-pii-check.sh / 50-audit-log.sh):
//
//   * every tool call is appended to ~/.cache/opencode/audit/audit.jsonl as a
//     SHA-256 hash-chained record (prev_hash -> hash), so tampering is visible;
//   * secrets/PII are redacted before anything is written;
//   * catastrophic shell commands are blocked before they run.
//
// Environment:
//   OPENCODE_GOVERNANCE=off        disable the plugin entirely
//   OPENCODE_AUDIT_DIR=<path>      override the audit directory
//   OPENCODE_GOVERNANCE_BLOCK=off  keep auditing but stop blocking commands
//
// Load: copy to ~/.config/opencode/plugins/governance.js (the installer does this).

import { createHash } from "node:crypto";
import { appendFileSync, mkdirSync, readFileSync, existsSync } from "node:fs";
import { homedir } from "node:os";
import { join } from "node:path";

const SECRET_PATTERNS = [
  { re: /\bsk-[A-Za-z0-9_-]{16,}\b/g, replace: "***" },
  { re: /\bghp_[A-Za-z0-9]{20,}\b/g, replace: "***" },
  { re: /\bgithub_pat_[A-Za-z0-9_]{20,}\b/g, replace: "***" },
  { re: /\bAKIA[0-9A-Z]{16}\b/g, replace: "***" },
  { re: /\bxox[baprs]-[A-Za-z0-9-]{10,}\b/g, replace: "***" },
  { re: /\bBearer\s+[A-Za-z0-9._-]{20,}\b/g, replace: "Bearer ***" },
  // key=value / KEY: value — keep the name, drop the value
  { re: /\b([A-Za-z0-9_]*(?:API|SECRET|TOKEN|PASSWORD)[A-Za-z0-9_]*\s*[:=]\s*["']?)([^\s"',]{8,})/gi, replace: "$1***" },
];

const EMAIL = /\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}\b/g;
const CARD = /\b(?:\d[ -]*?){13,19}\b/g;
const IPV4 = /\b(?:\d{1,3}\.){3}\d{1,3}\b/g;

export function redact(value, { pii = true } = {}) {
  let s = typeof value === "string" ? value : JSON.stringify(value ?? "");
  if (s == null) return "";
  for (const { re, replace } of SECRET_PATTERNS) s = s.replace(re, replace);
  if (pii) {
    s = s.replace(EMAIL, "***@***");
    s = s.replace(IPV4, "***.***.***.***");
    s = s.replace(CARD, (m) => (/[0-9]{13,}/.test(m.replace(/[ -]/g, "")) ? "***CARD***" : m));
  }
  return s;
}

const DANGEROUS = [
  { re: /\brm\s+(-[a-zA-Z]*\s+)*-?[a-zA-Z]*r[a-zA-Z]*f?\s+\/(\s|$)/, why: "recursive delete of /" },
  { re: /\brm\s+-rf\s+(~|\$HOME)(\/\s*)?($|\s)/, why: "recursive delete of home" },
  { re: /\bmkfs(\.[a-z0-9]+)?\b/, why: "filesystem format" },
  { re: /\bdd\s+[^|]*of=\/dev\/(sd|nvme|vd)/, why: "raw disk write" },
  { re: /\b(chmod|chown)\s+-R\s+(777|000)\s+\/(\s|$)/, why: "recursive permission wipe of /" },
  { re: /:\s*\(\s*\)\s*\{\s*:\s*\|\s*:\s*&\s*\}\s*;\s*:/, why: "fork bomb" },
  { re: /\bgit\s+push\s+[^|]*--force(-with-lease)?\b[^|]*\b(main|master)\b/, why: "force-push to main" },
];

export function checkCommand(command, { block = true } = {}) {
  if (typeof command !== "string" || command.length === 0) return { blocked: false };
  for (const { re, why } of DANGEROUS) {
    if (re.test(command)) {
      return { blocked: block, why, command: redact(command) };
    }
  }
  return { blocked: false };
}

function auditFile() {
  const dir = process.env.OPENCODE_AUDIT_DIR || join(homedir(), ".cache", "opencode", "audit");
  mkdirSync(dir, { recursive: true });
  return join(dir, "audit.jsonl");
}

function lastHash(file) {
  if (!existsSync(file)) return "0".repeat(64);
  try {
    const lines = readFileSync(file, "utf8").trimEnd().split("\n");
    const last = JSON.parse(lines[lines.length - 1] || "{}");
    return typeof last.hash === "string" ? last.hash : "0".repeat(64);
  } catch {
    return "0".repeat(64);
  }
}

export function audit(event, details = {}) {
  const file = auditFile();
  const prev = lastHash(file);
  const body = {
    ts: new Date().toISOString(),
    event,
    details,
    prev_hash: prev,
  };
  const hash = createHash("sha256").update(JSON.stringify(body)).digest("hex");
  appendFileSync(file, JSON.stringify({ ...body, hash }) + "\n");
  return hash;
}

async function setup(ctx = {}) {
  if ((process.env.OPENCODE_GOVERNANCE || "on").toLowerCase() === "off") return;
  const block = (process.env.OPENCODE_GOVERNANCE_BLOCK || "on").toLowerCase() !== "off";
  const location = ctx.location?.directory || ctx.directory || process.cwd();

  audit("plugin.load", { directory: location, block, api: ctx.tool?.hook ? "v2" : "unknown" });

  const disposers = [];

  if (ctx.tool && typeof ctx.tool.hook === "function") {
    disposers.push(
      await ctx.tool.hook("execute.before", (payload) => {
        const tool = payload?.tool || "unknown";
        const args = payload?.input ?? {};
        const command = typeof args === "object" && args ? args.command ?? args.cmd : undefined;
        if (tool === "bash" && typeof command === "string") {
          const verdict = checkCommand(command, { block });
          if (verdict.blocked) {
            audit("tool.blocked", { tool, why: verdict.why, command: verdict.command });
            throw new Error(
              `governance: blocked ${verdict.why}: ${verdict.command}. ` +
                `Set OPENCODE_GOVERNANCE_BLOCK=off to override.`
            );
          }
        }
        audit("tool.execute.before", {
          tool,
          sessionID: payload?.sessionID,
          id: payload?.id,
          args: redact(args),
        });
      })
    );

    disposers.push(
      await ctx.tool.hook("execute.after", (payload) => {
        const status = payload?.status || "unknown";
        const detail = status === "completed" ? payload?.result : payload?.error;
        audit("tool.execute.after", {
          tool: payload?.tool,
          sessionID: payload?.sessionID,
          id: payload?.id,
          status,
          detail: redact(typeof detail === "string" ? detail.slice(0, 400) : detail),
        });
      })
    );
  }

  let controller;
  if (ctx.event && typeof ctx.event.subscribe === "function") {
    controller = new AbortController();
    const interesting = new Set([
      "session.created",
      "session.idle",
      "session.error",
      "permission.asked",
      "permission.replied",
      "file.edited",
    ]);
    (async () => {
      try {
        for await (const ev of ctx.event.subscribe({ signal: controller.signal })) {
          if (ev && interesting.has(ev.type)) {
            audit(ev.type, { id: ev.id });
          }
        }
      } catch (error) {
        if (!controller.signal.aborted) {
          audit("plugin.error", { where: "event.subscribe", message: String(error?.message || error) });
        }
      }
    })();
    disposers.push(() => controller.abort());
  }

  return async () => {
    for (const dispose of disposers) {
      try {
        await dispose?.();
      } catch {
        /* best effort */
      }
    }
  };
}

// OpenCode v2 loads local plugins as a default definition with an id plus a
// setup() function returning a cleanup handler.
export default {
  id: "governance",
  setup,
};
