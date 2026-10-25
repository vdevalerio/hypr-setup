#!/usr/bin/env node
// Friction logger for /retro. Appends one short JSON line per friction event to
// ~/.claude/forge/friction/<repo-slug>.jsonl. No output, no model calls: zero token cost.
// Events: PostToolUseFailure (a tool call failed), UserPromptSubmit (the user corrected Claude).
import { appendFileSync, mkdirSync } from "node:fs";
import { homedir } from "node:os";
import { basename, join } from "node:path";
import { execFileSync } from "node:child_process";

const CORRECTION = /\b(n[aã]o era isso|n[aã]o foi isso|errado|de novo|ainda n[aã]o|continua (errado|quebrado)|t[aá] errado|desfaz|reverte|voc[eê] esqueceu|wrong|not what i|that's not|undo that|still (broken|wrong|not)|you forgot)\b/i;

let raw = "";
for await (const chunk of process.stdin) raw += chunk;
let ev;
try { ev = JSON.parse(raw); } catch { process.exit(0); }

const cwd = ev.cwd || process.cwd();
let root = cwd;
try { root = execFileSync("git", ["-C", cwd, "rev-parse", "--show-toplevel"], { encoding: "utf8", stdio: ["ignore", "pipe", "ignore"] }).trim(); } catch {}
const slug = root.replace(/^\/+/, "").replace(/[^A-Za-z0-9._-]+/g, "-");

const cut = (s, n) => String(s ?? "").replace(/\s+/g, " ").slice(0, n);
let rec = null;
if (ev.hook_event_name === "PostToolUseFailure") {
  const input = ev.tool_input ?? {};
  rec = { kind: "tool_failure", tool: ev.tool_name, target: cut(input.command ?? input.file_path ?? input.pattern ?? "", 160), error: cut(ev.error, 240) };
} else if (ev.hook_event_name === "UserPromptSubmit" && CORRECTION.test(ev.prompt ?? "")) {
  rec = { kind: "correction", prompt: cut(ev.prompt, 240) };
}
if (!rec) process.exit(0);

rec.ts = new Date().toISOString();
rec.session = String(ev.session_id ?? "").slice(0, 8);
const dir = join(homedir(), ".claude", "forge", "friction");
mkdirSync(dir, { recursive: true });
appendFileSync(join(dir, `${slug}.jsonl`), JSON.stringify(rec) + "\n");
