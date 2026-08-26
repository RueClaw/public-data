# CRM (trycompai/crm)

**Repo:** https://github.com/trycompai/crm  
**License:** MIT  
**Reviewed:** 2026-08-01  
**Commit:** `856ae2fc855757e45c31d31cebee03fbfbe46029`  
**Stack:** TypeScript, Bun, Turborepo, Next.js 16, React 19, NestJS, tRPC, Prisma 7, Postgres, Better Auth, Google OAuth/Gmail/Calendar, eve durable agents, Vercel Sandbox/Blob/AI Gateway  
**What it is:** An open-source, single-tenant, agent-first CRM where a durable research agent reads mailbox/calendar context, maintains contact/company/deal records, and writes sourced facts into a Postgres-backed CRM.

---

## Verdict

⚠️ **Interesting and unusually well-reasoned, but too young and sensitive for casual deployment.** The core design is strong: the API reports events, the agent owns intelligence, claims are priced by observed evidence rather than model confidence, and the sandbox is denied network and database credentials. The blockers are real too: this handles mailbox/customer data, has no visible CI, is only a day old, and `bun audit` reports 18 advisories including a critical Better Auth advisory path that should be triaged before any real deployment.

---

## What It Is

Most CRMs treat AI as a chat box attached to a database. This repo flips that around: the CRM is the record store and operator surface for a durable research agent. Gmail and Calendar sync create threads, meetings, contacts, companies, activities, and work items; the agent leases queued work, reads CRM history first, optionally calls external research/enrichment providers, and records only claims backed by explicit evidence.

It is intentionally single-tenant. Google sign-in is the only auth path, `ALLOWED_SIGN_IN` is the allow-list, and every signed-in user can see every record. The README and `SECURITY.md` are honest about that boundary: this is for one internal organization, not a public multi-tenant CRM.

## Stack

| Layer | Tech |
|-------|------|
| Monorepo/runtime | Bun, Turborepo, TypeScript |
| Frontend | Next.js App Router, React 19, shadcn-style shared UI package, TanStack Query, tRPC client, nuqs URL state |
| API | NestJS, nestjs-trpc, Better Auth, Helmet, cache-manager/optional Redis |
| Data | Postgres, Prisma 7, committed migrations, generated Prisma client |
| Agent | eve durable agent framework, file-based tools/skills/schedule, Vercel Sandbox/Docker/microsandbox backend selection |
| Sync | Google OAuth, Gmail API, Calendar API, cron-guarded sync route |
| Optional research | Perplexity, RapidAPI LinkedIn, context.dev |
| Deployment | Vercel-oriented app/API/agent deployments plus Postgres, optional Redis and Blob |

## Key Features

### Agent-First CRM Boundary

The strongest architectural rule is "intelligence never lives in the API." NestJS owns HTTP, auth, tRPC, Google sync, and CRUD. When something may need research, the API writes an `AgentTask` row. The agent leases that row and decides what it means.

That boundary avoids two common failure modes:

- request handlers that block on slow enrichment providers;
- duplicated identity/enrichment logic that drifts between the API and agent.

The repo documents this rule in `docs/api.md`, `docs/agent.md`, and comments near the queueing code, which makes it easier to maintain than a vague "agentic" architecture diagram.

### Durable Event-Row Work Queue

`apps/agent/agent/lib/tasks.ts` claims due work with `FOR UPDATE SKIP LOCKED`, leases rows for ten minutes, caps attempts at three, and keeps the reason/budget on the row. The schedule runs every minute but "decides nothing"; all priority, due time, subject, and budget are carried by durable database state.

That is a good small-system alternative to a full message broker. It gives the agent crash recovery, deduplication by subject/kind, visible task reasons, and resumable dispatch without putting agent work on a web request path.

### Evidence, Not Confidence

The fact-writing path is the best product idea in the repo. Tools do not submit model confidence. They submit observations: signature block, thread reply, LinkedIn employer-and-name, GitHub account identity, cited web claim, contradiction. `lib/evidence.ts` scores those observations, and `lib/facts.ts` decides whether a claim is applied, proposed for a human, held, or ignored.

Important guardrails are enforced in code:

- a primary source is required before an automatic write;
- contradictions are not averaged away;
- human-entered record values outrank the agent;
- dismissed suggestions are not re-offered;
- weak evidence can become a proposal rather than a fake certainty.

That is exactly the right instinct for a CRM: a confidently wrong customer fact is worse than a blank field.

### Egress Boundary For Mailbox Data

The agent may read full internal CRM history, including email bodies and calendar context, because that is where the strongest evidence lives. The boundary is what may leave:

- no customer text in third-party queries;
- no mailbox bodies copied into `/workspace`;
- no sensitive logging;
- the sandbox has `deny-all` network policy;
- the sandbox is never given `DATABASE_URL`.

This does not make the system low-risk, but it is a coherent threat model: read broadly inside the trusted single-tenant app, constrain writes and external egress.

### Same-Origin Agent Bridge

The web app proxies `/eve/v1/*` to the agent. The proxy checks the Better Auth session, strips cookies and hop-by-hop headers, validates record IDs, and mints a short-lived HMAC token for the agent. The record focus travels as token attributes instead of being pasted into the user's message.

That is a clean pattern for embedding a durable agent panel inside a business record without handing the agent browser session cookies.

## Architecture

The repo is arranged as:

- `apps/app` — Next.js CRM UI;
- `apps/api` — NestJS API, auth, tRPC routers, Google sync;
- `apps/agent` — eve agent, tools, skills, schedule, sandbox;
- `packages/db` — Prisma schema, migrations, seed data, shared client;
- `packages/auth` — Better Auth configuration and Google allow-list handling;
- `packages/ui` — shared UI components;
- `packages/env` — root `.env` loading and parsing.

The database model covers users/sessions/accounts, companies, contacts, deals, activities, synced email/calendar objects, agent tasks, agent conversations/events, contact facts, and enrichment state. The schema comments are unusually useful: they explain why the project intentionally avoids organizations, why `lastActivityAt` is denormalized, why profile images are mirrored, and why certain uniqueness tradeoffs exist.

## Comparison

Compared with conventional open-source CRMs, this is narrower but more opinionated. It does not try to be a multi-tenant sales platform. It tries to be a single-tenant internal CRM where the agent does the background research work.

Compared with "AI email assistant" projects, it is more structured: email/calendar data becomes CRM evidence, task rows, contact facts, and deal context rather than only draft replies or inbox triage.

Compared with generic agent frameworks, the interesting part is not the use of a durable agent runtime. It is the product contract around evidence, human proposals, explicit task reasons, and the hard split between API events and agent decisions.

## Self-Hosting Notes

The happy path needs Bun, Docker/Postgres, a root `.env`, Google OAuth credentials, and three deployments if following the Vercel-oriented architecture: app, API, and agent. Required local values are `DATABASE_URL`, `BETTER_AUTH_SECRET`, `ALLOWED_SIGN_IN`, `GOOGLE_CLIENT_ID`, and `GOOGLE_CLIENT_SECRET`. Optional keys add Perplexity, LinkedIn, context.dev, Redis, Blob, and the agent bridge.

Deployment cautions:

- set `ALLOWED_SIGN_IN` to a domain you control or exact addresses, never a public mail domain;
- set `CRON_SECRET` before exposing the sync route;
- keep Postgres private;
- start with no optional vendor keys and add them deliberately;
- understand that all signed-in users can see all records.

## Caveats

- **Very fresh.** Created 2026-07-31, no releases yet, no visible GitHub Actions in the clone.
- **Single-tenant authorization only.** That is a deliberate scope choice, not a missing feature, but it makes the tool wrong for teams needing roles, territories, customer partitions, or external users.
- **Mailbox data is sensitive.** The design is candid and thoughtful, but the app still reads real email and calendar data.
- **Dependency advisories need triage.** `bun audit` reported 18 advisories: 1 critical, 12 high, 4 moderate, 1 low, including Better Auth, Drizzle ORM, PostCSS, lodash, and sharp paths.
- **DB-backed tests were not runnable here.** Static checks passed, but full test verification needs a working Postgres; Docker was not installed in this environment.
- **Build has a deploy hygiene warning.** Next/Turbopack warned that an app route import trace may be pulling broader project files into NFT tracing through env/db/session imports.
- **External-provider behavior is optional and volatile.** LinkedIn via RapidAPI, Perplexity, context.dev, Vercel AI Gateway, and eve/Vercel Sandbox all add operational dependencies.

## Verification

Local checks performed on 2026-08-01:

- `DATABASE_URL=... bun install --frozen-lockfile` passed.
- `DATABASE_URL=... bun run check-types` passed.
- `DATABASE_URL=... bun run lint` passed.
- `DATABASE_URL=... BETTER_AUTH_SECRET=... API_URL=... APP_URL=... ALLOWED_SIGN_IN=... bun run build` passed, with the Next/Turbopack tracing warning noted above.
- `DATABASE_URL=... bun run test` partially ran: app tests passed 53/53, env tests passed 17/17, and agent tests showed 56 passing before 27 DB-backed failures caused by denied access to the dummy Postgres URL. Docker was unavailable, so I could not bring up the repo's compose database.
- `bun audit` reported 18 advisories: 1 critical, 12 high, 4 moderate, 1 low.

## Reuse Notes

The public pattern worth extracting is the event-row agent work queue: use durable database rows to report facts/events from ordinary app code to an autonomous worker, with row-carried subject, due time, reason, budget, priority, lease, and attempt state. That pattern is small enough to reuse without adopting the whole CRM.

The evidence ledger is also worth studying, especially for systems where a wrong personal or business fact has real cost.

---

**Attribution:** trycompai/crm, MIT License.
