# Agentic Inbox (cloudflare/agentic-inbox)

**Repo:** https://github.com/cloudflare/agentic-inbox  
**License:** Apache-2.0  
**Reviewed:** 2026-05-31  
**Commit reviewed:** `48039bb6785af34e592c2966f87cde2b255c4c80`  
**Stack:** Cloudflare Workers, Hono, React 19, React Router 7, Tailwind CSS, Zustand, TipTap, Durable Objects SQLite, R2, Email Routing, Email Service, Cloudflare Access, Workers AI, Agents SDK, MCP  
**What it is:** A self-hosted email client and AI email assistant that runs on Cloudflare Workers with per-mailbox Durable Objects, R2-backed attachments, Cloudflare Access authentication, and both UI and MCP tool surfaces.

---

## Verdict

⚠️ **Interesting, with a real security and operations review before production email use.** Agentic Inbox is one of the cleanest examples of an edge-native AI email product: inbound email, mailbox storage, UI, agent runtime, and MCP all live inside Cloudflare primitives. The limiting factor is not the architecture. It is the blast radius: any user admitted by the shared Cloudflare Access policy can access every mailbox and the MCP endpoint can operate across mailboxes by ID.

## What It Is

Agentic Inbox is a full email client built around Cloudflare's email and compute stack. It receives mail through Cloudflare Email Routing, stores mailbox state in Durable Objects backed by SQLite, stores attachments in R2, sends through Cloudflare Email Service, and adds an AI side panel using the Cloudflare Agents SDK and Workers AI.

The agent can list emails, read messages, read threads, search mail, draft new messages, draft replies, mark messages read, move messages, and discard drafts. The default agent prompt is deliberately draft-first: the agent can save drafts, but normal UI review is expected before sending. The MCP endpoint exposes a broader tool surface, including send tools, with tool descriptions telling clients to send only after confirmation.

## Architecture

### Worker-Owned App Shell

`workers/app.ts` is the outer Worker entry point. It validates Cloudflare Access JWTs outside local development, routes API calls to a Hono app, routes agent traffic through `routeAgentRequest`, exposes an MCP server at `/mcp`, and handles inbound email events.

This keeps the trust boundary simple: Cloudflare Access first, then app logic.

### Per-Mailbox Durable Objects

Each mailbox maps to a named Durable Object instance. The DO stores folders, email metadata, message bodies, attachments metadata, read/starred state, threads, and send-rate counters in SQLite. That is a good fit for email because each mailbox is naturally stateful, mostly isolated, and benefits from serialized mutation.

### R2 for Attachments and Settings

Attachments are stored under R2 keys derived from the email ID plus a generated attachment ID. The filename is sanitized before being included in the key. Mailbox settings are also stored in R2 under `mailboxes/<mailbox>.json`.

### Agent and MCP Share Tool Logic

`workers/lib/tools.ts` is the key design choice. The UI agent and MCP server call the same underlying list, read, search, draft, update, move, delete, and send helpers. That avoids drifting behavior between the in-app assistant and external MCP clients.

### Draft Verification and Prompt-Injection Checks

The code includes two AI safety helpers:

- `isPromptInjection` scans incoming email and thread context before auto-drafting;
- `verifyDraft` attempts to remove tool/system artifacts from outgoing drafts and refuses some unverified send paths.

This is not a complete security boundary, but it is better than letting untrusted email content flow directly into an auto-reply path.

## Security and Operational Notes

Good signs:

- production requests fail closed if Cloudflare Access configuration is missing;
- sender validation prevents arbitrary `from` addresses from the app API;
- email HTML is rendered through DOMPurify inside a sandboxed iframe without `allow-same-origin`;
- quoted original messages are converted to escaped plain text before being inserted into compose or outgoing reply blocks;
- attachment filenames are sanitized before storage;
- SQL paths use Drizzle or parameterized raw SQL, and sort columns are allowlisted;
- auto-drafting fails closed when the prompt-injection scanner cannot run;
- the README clearly documents the shared-trust limitation instead of hiding it.

Caveats:

- there is no per-mailbox authorization layer; every user who passes the shared Cloudflare Access policy can access every mailbox;
- the MCP endpoint can list and operate on all mailboxes by `mailboxId`;
- MCP exposes direct `send_email` and `send_reply` tools, so external clients need their own confirmation discipline;
- mailbox settings accept arbitrary JSON, including custom system prompts, and those prompts become the agent's system prompt;
- deleting a mailbox currently deletes only settings, with TODOs for Durable Object data and attachment cleanup;
- the app stores sent messages before deferred send completion, so delivery failure can leave optimistic sent state;
- `npm audit --omit=dev` reported 11 production dependency advisories, including high-severity advisories in `drizzle-orm`, `fast-uri`, `lodash`, `path-to-regexp`, and `picomatch`;
- no test suite or CI configuration was found in the repository.

## Verification

Local verification on macOS:

- cloned `cloudflare/agentic-inbox` at `48039bb6785af34e592c2966f87cde2b255c4c80`;
- `npm ci` succeeded;
- `npm run build` passed;
- `npm run typecheck` passed after generating Wrangler runtime types;
- `npm audit --omit=dev` reported 11 production vulnerabilities;
- no `test` script or CI workflow was present.

## Best Reusable Pattern

The best reusable pattern is the edge-native agentic email runtime: receive email through platform routing, store each mailbox in its own stateful edge object, store attachments in object storage, put an AI draft agent beside the mailbox state, and expose the same tool logic through both UI chat and MCP.

Extracted as `public-data/patterns/edge-native-agentic-email-runtime.md`.

## Bottom Line

Agentic Inbox is worth studying and adapting if you want an AI email client that lives entirely on Cloudflare. It is not something to drop in front of sensitive mailboxes without adding per-mailbox authorization, tightening MCP send controls, fixing dependency advisories, and adding tests around email parsing, auth, mailbox isolation, and send/draft behavior.

---

**Attribution:** cloudflare/agentic-inbox, Apache-2.0, https://github.com/cloudflare/agentic-inbox
