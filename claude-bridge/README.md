# RAWBY Claude bridge

Lets Aurora answer with **your Claude subscription** (Pro/Max) via the Claude
Agent SDK + OAuth — no pay-per-token API key. Usage draws from your normal
Claude plan limits.

It's a tiny Node service the RAWBY server calls. You host it once and point the
RAWBY server at it.

## 1. Get a subscription OAuth token

On a machine where you're logged into Claude with your subscription:

```bash
npm i -g @anthropic-ai/claude-code   # if you don't have the `claude` CLI
claude setup-token                   # prints a long-lived OAuth token
```

Copy the token it prints.

## 2. Run the bridge

```bash
cd claude-bridge
npm install
CLAUDE_CODE_OAUTH_TOKEN="<token from step 1>" \
BRIDGE_SECRET="<make up a long random string>" \
npm start
```

It listens on `:8787`. Check `GET /health` → `{ "ok": true, "hasToken": true }`.

To deploy: put it on any Node host (Render Web Service, Fly, a VPS). Set the two
env vars above (and optionally `CLAUDE_MODEL`, e.g. `claude-sonnet-4-6`).

## 3. Point the RAWBY server at it

On the RAWBY Dart server (Render `rawby-1`), set:

```
CLAUDE_BRIDGE_URL = https://<your-bridge-host>
BRIDGE_SECRET     = <same secret as above>
```

Then in the app: **Settings → "Use my Claude (Pro)"**. Aurora now routes through
your subscription. If the bridge is down or unset, Aurora automatically falls
back to Groq, so it never breaks.

## Notes
- Tools are disabled — this is plain chat, no file/system access.
- Keep `BRIDGE_SECRET` private; it's the only thing gating who can spend your
  Claude usage.
