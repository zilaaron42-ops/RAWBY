// ============================================================
// RAWBY — Claude bridge.
// Lets Aurora answer using the OWNER's Claude subscription (Pro/Max) through
// the Claude Agent SDK + OAuth, rather than the pay-per-token Anthropic API.
//
// Auth: this process must have CLAUDE_CODE_OAUTH_TOKEN set — generate it once
// with `claude setup-token` (requires a Claude subscription) and put it in the
// environment. The Agent SDK picks it up automatically.
//
// The RAWBY Dart server calls POST /chat with a shared secret; this runs the
// SDK with tools disabled (plain chat) and returns the reply text.
// ============================================================
import express from "express";
import { query } from "@anthropic-ai/claude-agent-sdk";

const app = express();
app.use(express.json({ limit: "2mb" }));

const SECRET = process.env.BRIDGE_SECRET || "";
const MODEL = process.env.CLAUDE_MODEL || undefined; // e.g. "claude-sonnet-4-6"

app.get("/health", (_req, res) =>
  res.json({ ok: true, hasToken: !!process.env.CLAUDE_CODE_OAUTH_TOKEN })
);

app.post("/chat", async (req, res) => {
  if (SECRET && req.headers["x-bridge-secret"] !== SECRET) {
    return res.status(403).json({ error: "forbidden" });
  }
  const { system, prompt } = req.body || {};
  if (!prompt || typeof prompt !== "string") {
    return res.status(400).json({ error: "prompt required" });
  }
  try {
    let reply = "";
    for await (const message of query({
      prompt,
      options: {
        systemPrompt: system || undefined,
        model: MODEL,
        allowedTools: [], // plain chat — no file/tool access
        maxTurns: 1,
        permissionMode: "bypassPermissions",
      },
    })) {
      if (message.type === "result" && message.subtype === "success") {
        reply = message.result;
        break;
      }
    }
    if (!reply) return res.status(502).json({ error: "no reply from Claude" });
    res.json({ reply });
  } catch (e) {
    console.error("[bridge] error:", e);
    res.status(500).json({ error: String(e?.message || e) });
  }
});

const port = process.env.PORT || 8787;
app.listen(port, () => {
  const tok = process.env.CLAUDE_CODE_OAUTH_TOKEN ? "set" : "MISSING";
  console.log(`Claude bridge listening on :${port} (OAuth token ${tok})`);
});
