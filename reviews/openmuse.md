# OpenMuse (CopilotKit/openmuse)

**Repo:** https://github.com/CopilotKit/openmuse  
**License:** MIT for the repository code, so free reuse with attribution. The API server refuses to start without a `CPK_INTELLIGENCE_API_KEY` for CopilotKit Intelligence. That's a separate CopilotKit service (CopilotKit Cloud, or their self-hosted Kubernetes offering) that the README says is *not* covered by the MIT license. Model providers and Google APIs are under their own terms.  
**Reviewed:** 2026-09-28 (commit `34b15bc`, 0.1.0-alpha)  
**Stack:** TypeScript. Hono + CopilotKit runtime 1.70 + AG-UI on the server, TanStack AI (OpenAI/Anthropic/Gemini adapters), PGlite or PostgreSQL, Playwright Chromium worker, optional Docker Linux "computer". Expo / React Native client for iOS, Android and web. pnpm monorepo.  
**What it is:** A single-owner, self-hosted personal-agent reference app. It has chat, durable delegated tasks with plans, approvals and receipts, a persistent Chromium browser you can take over, a locked-down Docker terminal and workspace, Gmail and Calendar adapters behind stored action reviews, PDF form filling, page-change watches, and CSV spending summaries. Positioned as a template to clone and customise.

---

## Verdict

⚠️ **Interesting. It's one of the more carefully engineered open "personal agent" templates, with real sandboxing and approval plumbing. But it's a vendor showcase: every mode, including the local fictional sample, hard-requires a CopilotKit Intelligence project key. It's a 13-day-old alpha with no live Google or live-model acceptance yet.**

What's good:
- **External writes are structurally gated.** Emails and calendar changes go through `prepare_email`/`prepare_event` proposals. Each one is bound to the account, a content hash and the provider version. The server needs a recorded approval before it dispatches, and the model has no approve tool at all. Uncertain network outcomes are kept for reconciliation, not retried.
- **Browser SSRF defence is layered.** URL validation allows only http/https on ports 80/443, with no userinfo and no `.local/.internal/.lan` hosts. It resolves DNS and rejects the request if *any* resolved address is non-global. Chromium also runs behind a local egress proxy that re-validates the target and connects to the pinned IP, which closes the DNS-rebinding gap.
- **The Docker computer is properly locked down.** It runs as UID 1000 with a read-only rootfs, `--cap-drop ALL`, no-new-privileges, `--network none`, 512 MB RAM, 1 CPU, 128 PIDs, no host mounts and no credentials. It's launched with `spawn("docker", args, {shell:false})`, and commands have a 30 s cap and a 128 KB output cap. Interrupted commands are recorded as uncertain and never replayed.
- **Honest docs.** `docs/VERIFICATION.md` separates what was exercised (fictional mailbox, iPhone simulator, real Chromium, real Docker smoke) from what wasn't (live Google, live models, Android on a device, live Intelligence persistence).

What gives pause:
- **Hard dependency on a hosted vendor service.** `readConfig()` throws if `CPK_INTELLIGENCE_API_KEY` is empty, even in `WORKSPACE_MODE=sample`. "Self-hosted" means your server plus CopilotKit's thread persistence, which receives your conversation events.
- **Single-owner auth only.** Live mode uses one shared access key (≥24 chars, compared with `timingSafeEqual` on SHA-256 digests) that mints 24 h bearer sessions. There are no users and no MFA. The docs say to put it behind HTTPS and restricted network access, and they mean it.
- **Chromium runs without its internal sandbox** (Playwright's default). The docs say plainly that the browser worker is not a hostile-content boundary.
- **Prompt-injection defence is mostly prompt text** ("untrusted data, never instructions"). The real protection is that there's no un-reviewed write tool, which is the right design, but read access to the whole mailbox still goes to the model provider.
- **"Compatible with any agent harness" is aspirational.** A raw AG-UI endpoint can replace conversational routing (`AGENT_BACKEND=agui`), and the OpenBot adapter is disabled and only contract-tested.
- **Young:** created 2026-09-15, ~2.7k stars, 32 open issues, and a burst of fix PRs merged on 2026-09-26.

---

## What It Is

- **Server (`apps/server`):** Hono API hosting the CopilotKit runtime (AG-UI streaming), auth, the task engine (`engine/service.ts`, ~1.1k lines), reviews, files, persistence and routes to the computer and browser.
- **Task engine:** durable delegated jobs with plans, checkpoints, SQL leases for multiple workers, pause/resume/cancel/retry, `ask_user` input requests and saved receipts. A server-side TanStack AI agent runs each task with tools like `read_web`, `prepare_email`, `prepare_event`, computer tools, `ask_user` and `finish_task`.
- **Browser worker (`apps/worker`):** a token-protected Playwright service (≥32-char token, constant-time compare) with persistent per-session Chromium profiles, screenshot "takeover" console, PDF download import and the egress proxy.
- **Computer (`apps/computer`):** a nonroot Linux image with bash/Python/Node/git. A bounded `files.py` helper keeps file ops inside `/workspace`, rejects symlink traversal and special files, and does atomic replace with 256 KB text and 10 MB PDF caps.
- **Client (`apps/mobile`):** one Expo codebase for iOS, Android and web. CopilotKit headless hooks, inline cards (email, browser, PDF, plan, finance), and a Send→Stop composer with a visible follow-up queue.
- **Packages:** `domain` (zod-validated types), `integrations` (Google OAuth/Gmail/Calendar, PDF, vault), `backends/openbot` (disabled adapter).

## Stack

| Layer | Tech |
|-------|------|
| API | Node 24, Hono 4, `@copilotkit/runtime` 1.70.1, `@ag-ui/*` 0.0.59, zod 4 |
| Agent loop | `@tanstack/ai` + OpenAI/Anthropic/Gemini adapters, optional OpenAI-compatible base URL, `MODEL_MAX_RETRIES=2` before first byte |
| Persistence | Embedded PGlite (single process) or PostgreSQL (separate task worker), `.openmuse/` data dir with a 0600 signing key |
| Threads | CopilotKit Intelligence (hosted/external, required) |
| Browser | Playwright Chromium, persistent profiles, local egress proxy |
| Computer | Docker CLI → hardened container, named `/workspace` volume |
| Docs/PDF | pdf-lib (AcroForm fill), parse5 |
| Client | Expo / React Native, markdown-it, native and web PDF readers |
| CI | GitHub Actions: lint/typecheck/test/build, Expo export ×3, real Chromium, browser container, computer container |

## Key Features

### Reviewed external actions
A proposal records the account, reviewed content, content hash and provider version (e.g. calendar ETags). Changing or disconnecting the Google account invalidates pending connection-bound work. Approval happens only in the native app UI. The system prompt tells the model approvals never go through chat tool arguments, and the tool surface backs that up. Cancelling stops later steps. An already-dispatched provider request may still finish, and the docs say so.

### Durable delegated work
Tasks survive restarts (tested with real PGlite restarts), coordinate through SQL leases (tested with two-worker races and expired-lease recovery), and resume from saved receipts rather than re-running writes. "No hidden retry after an uncertain external write" is a stated invariant.

### Agent computer
The persistent browser plus the optional terminal are exposed both to the agent (tools) and to the person (takeover console, terminal, file editor). The computer's `operationId` convention asks the model to reuse an ID for duplicates and never auto-retry timed-out commands.

### Goals, Ideas, Tracking
Rules-based suggestions with source evidence (edit, accept, dismiss). Recurring public-page watches for change, text availability or USD price thresholds, with deduped alerts, failure backoff and auto-pause. A recent fix makes every failure streak alert, not just the first.

### Documents and finance
Email attachment → PDF → requested values → filled copy → reviewed reply → receipt. AcroForms only, no OCR. CSV import produces an exact-cents spending summary artifact.

## Architecture

Client ↔ API over AG-UI plus bearer-authenticated REST. The API hosts the task worker by default. Set `TASK_WORKER_ENABLED=false` and use PostgreSQL to split it out, because PGlite can't be shared across processes. The browser worker and Docker computer are separate trust zones reached by token and by the Docker CLI respectively. File URLs and browser-console links are HMAC-signed (owner + path + expiry, 15 minutes) and verified with `timingSafeEqual`. CORS and an explicit Origin check reject unlisted origins with 403. Sample mode refuses to bind to anything but loopback. The code sets `DO_NOT_TRACK=1` and `COPILOTKIT_TELEMETRY_DISABLED=true` by default.

Code size is modest: about 14k lines of server, worker, package and test TypeScript, plus the Expo client.

## Security

- **Secrets scan:** no `sk-`, `AKIA` or `ghp_` patterns. No `eval`/`new Function`/`execSync`. The one `spawn` is `docker` with an argv array and `shell:false`.
- **Auth:** live mode needs `OPENMUSE_ACCESS_KEY` (≥24 chars) and `TOKEN_ENCRYPTION_KEY` (32-byte base64) or it won't start. Sessions are random 32-byte tokens stored hashed, 24 h expiry. Sample mode issues sessions with no key but is loopback-only.
- **Google tokens** are encrypted at rest. OAuth state races are covered by tests.
- **Browser worker:** requires a token, defaults to `127.0.0.1`, and has the SSRF controls above. Chromium's internal sandbox is off, so treat the worker host as exposed to whatever pages the agent visits.
- **CI hygiene:** `permissions: contents: read`, all actions pinned to full SHAs, `persist-credentials: false`, per-ref concurrency cancel.
- **Residual risks:** a single shared key guards the full mailbox, calendar and agent. The Docker host kernel is shared. The persistent volume has no disk quota. Conversation events go to CopilotKit Intelligence. Mailbox and page content reach the configured model provider.

## Maturity

~2.7k stars and 338 forks in 13 days. 32 open issues, last push 2026-09-26. Vendor-reported: 154 tests passing, seven CI jobs green, iPhone simulator and web exercised. Live Google, live models, Android on a device and live Intelligence replay are listed as not yet accepted. About 208 `test(`/`it(` calls across the test files.

### Validation on 2026-09-28

Host: Linux, Node v26.5.1 (native TS type stripping). `pnpm install` wasn't possible in this environment because the package-install gate blocked it, so the full suite, typecheck, Expo exports, Chromium and Docker tests were **not run**.

- `node --test apps/mobile/test/*.test.ts` gave **10 passed, 1 failed**. The one failure is `assistant-markdown.test.ts`, which can't load its `markdown-it` dependency (not installed). That's an environment failure, not a code failure. `browser-address`, `conversation-queue` and `date-time` all pass.
- `node --test tests/log.test.ts` gave **2 passed, 0 failed**.
- An ad-hoc probe of `apps/worker/src/network.ts` (`isPublicIp` / `validatePublicUrl` with a stub resolver) correctly allowed `8.8.8.8`, `2606:4700::1111` and a public hostname. It correctly **blocked** 10/8, 127/8, 169.254.169.254, 100.64/10, 172.16/12, 192.168/16, 0.0.0.0, `::1`, `fe80::`, `fc00::`, `::ffff:127.0.0.1`, NAT64 `64:ff9b::7f00:1`, 6to4 `2002:7f00:1::`, mixed public+loopback DNS answers, port 8080, `file:`, userinfo URLs, `.internal`, and the decimal/hex IPv4 forms `2130706433` and `0x7f.1`.
- No benchmarks or demo claims were reproduced.

## Comparison

| | OpenMuse | Hermes Agent / OpenClaw-style assistants | Browser-agent libraries (browser-use, dev-browser) |
|---|---|---|---|
| Shape | Full-stack app template (server + mobile/web client) | Long-running agent runtime + chat gateways | Library/tool for driving a browser |
| External-write safety | Stored, hash-bound reviews; no model-side approve tool | Varies; usually tool-level approval prompts | N/A |
| Sandbox | Hardened no-network Docker + SSRF-guarded Chromium | Varies (local shell, Docker, remote) | Usually none by default |
| Persistence | PGlite/Postgres + **required** CopilotKit Intelligence | Local files/SQLite | Caller's job |
| Multi-user | No (single owner, shared key) | Usually single operator | N/A |
| Mobile client | Yes (Expo iOS/Android/web) | Via chat apps | No |

## Self-Hosting Notes

- Minimum: Node 24, pnpm 11.19, **a CopilotKit Intelligence project key** (`npx copilotkit@latest login` / `project select`). The sample mode needs no model, Google account or Docker.
- For real use: `WORKSPACE_MODE=live`, `AGENT_BACKEND=model`, `MODEL=provider/id` and its key, access and encryption keys, a Google OAuth client with `${PUBLIC_API_URL}/api/google/callback`, HTTPS and network restriction.
- The browser worker needs `playwright install chromium` or `infra/compose.yaml`. The computer needs `docker build -t openmuse-computer:local apps/computer` and Docker access from the API, which is effectively root-equivalent, so scope it (e.g. a dedicated Colima/rootless context via `DOCKER_CONTEXT`).
- Back up `.openmuse/` (database, documents, signing key, browser profiles) and treat it as private.
- For an OpenAI-compatible gateway, set `OPENAI_BASE_URL` and prefix model IDs as `openai/vendor/model`.

## Reusable Patterns

- **Approval as data, not as a tool:** the model can only *prepare* a write. Approval is a separate UI-side record bound to a content hash and provider version, and dispatch checks for it. It's worth copying into any agent that sends email or edits calendars.
- **Validate-then-pin egress proxy:** reject if any DNS answer is non-global, then connect to the validated IP from a local proxy that the browser is forced through. `network.ts` + `proxy.ts` is a compact, reusable SSRF guard.
- **Uncertain outcomes are first-class:** interrupted commands and in-flight provider writes are stored as "uncertain" and surfaced for reconciliation, never auto-replayed.
- **Hardened throwaway computer recipe:** `--read-only --cap-drop ALL --security-opt no-new-privileges --network none --user 1000:1000`, memory/CPU/PID limits, a named workspace volume and ownership labels checked before re-attach.

---

**Attribution:** CopilotKit/openmuse, MIT
