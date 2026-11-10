# Ember (NYLLON-SOFTWARE/ember-cloudflare)

**Repo:** https://github.com/NYLLON-SOFTWARE/ember-cloudflare
**License:** MIT; retain the 37signals and NYLLON copyright/permission notices when redistributing code. Dependencies and bundled assets have their own terms.
**Reviewed:** 2026-11-10 (UTC)
**Revision:** `e1af690e19d02028b2460138e008d165b4fd17fc`, main snapshot; whole-repository architecture review with sampled implementation and tests. Worker package version 0.4.2; this main snapshot is newer than release v0.4.2.
**Verification:** Static source review only. No dependencies installed, source executed, deployments created, paid APIs called, or live security probes performed. Upstream CI status checked separately below.
**Stack:** TypeScript, React 19/Vite/Tailwind, Cloudflare Workers, Durable Objects/SQLite, optional D1, R2, WebSockets, shared rich-text/protocol packages.
**What it is:** A self-hosted team/community chat application inspired by Slack and Campfire, running in the operator's Cloudflare account. It is not an agent-hosting sandbox or general-purpose Cloudflare infrastructure framework.

## Verdict

⚠️ **Interesting — a credible small-team chat pilot, not yet a blanket Slack replacement.** The room-per-object design, explicit revocation handling, dual-backend tests and detailed operator documentation are unusually substantial for a repository created less than a month ago. Pilot with non-sensitive conversations first: permanent bearer file links, administrator impersonation, provider egress, distributed recovery and consumption billing are important product boundaries, not details hidden by “one click” or “$5/month.”

## What It Is

Ember supplies rooms, private rooms, group/direct messages, threads, reactions, file sharing, filtered full-text search, presence, web push and an installable web UI. It also implements Slack-compatible incoming webhook formatting and outgoing reply-capable bots. The optional @ember assistant and administrator-defined AI personas answer inside conversations through Cloudflare AI Gateway.

Ownership means control of code and a Cloudflare account, **not end-to-end encryption or infrastructure independence**. Application servers can read chat. Administrators are trusted with workspace policy, bot destinations, custom CSS and sign-in links for other users. Cloudflare remains the hosting/storage trust boundary; optional integrations introduce others.

The snapshot contains SFU settings and room-side huddle machinery, but its self-hosting guide explicitly says huddles are unfinished and nobody can start one yet. An open draft PR #269 proposes the usable client. Do not count voice/video as a delivered feature merely because a huddles directory exists. [README](https://github.com/NYLLON-SOFTWARE/ember-cloudflare/blob/e1af690e19d02028b2460138e008d165b4fd17fc/README.md), [huddle status](https://github.com/NYLLON-SOFTWARE/ember-cloudflare/blob/e1af690e19d02028b2460138e008d165b4fd17fc/docs/self-hosting.md#huddles).

## Stack

| Layer | Technology / responsibility |
|---|---|
| UI | React 19, Vite, Tailwind 4, Radix, Lexxy editor, highlight.js |
| Edge entry | Worker routes, cookie/CSRF checks, static assets, security headers |
| Live state | One ChatRoom Durable Object per room; hibernating WebSockets |
| Shared authority | One Workspace Durable Object per deployment; users, sessions, memberships, settings and outboxes |
| Primary persistence | Per-object SQLite by default; shared D1 alternative with common SQL driver |
| Search | Separate SearchIndex Durable Object with SQLite FTS5, on either backend |
| Files | Private R2 binding served through signed application URLs; multipart uploads |
| Optional integrations | AI Gateway, Memberful, Resend/Cloudflare Email Service, browser push services; unfinished Realtime SFU integration |

## Key Features and Architecture

### Rooms are execution and consistency units

[`apps/worker/src/index.ts`](https://github.com/NYLLON-SOFTWARE/ember-cloudflare/blob/e1af690e19d02028b2460138e008d165b4fd17fc/apps/worker/src/index.ts) is the HTTP entry; it authenticates before handing an upgrade to the appropriate ChatRoom. The Worker replaces internal identity/authorization headers rather than trusting client-supplied values. [`apps/worker/src/workspace.ts`](https://github.com/NYLLON-SOFTWARE/ember-cloudflare/blob/e1af690e19d02028b2460138e008d165b4fd17fc/apps/worker/src/workspace.ts) resolves the fixed object name `workspace`: this is **one workspace per deployment**, not a hosted multi-tenant service with arbitrary tenant IDs.

[`apps/worker/src/chat-room.ts`](https://github.com/NYLLON-SOFTWARE/ember-cloudflare/blob/e1af690e19d02028b2460138e008d165b4fd17fc/apps/worker/src/chat-room.ts) owns room messages, socket fan-out, uploads, bot/model answer queues and alarms. [`apps/worker/src/db.ts`](https://github.com/NYLLON-SOFTWARE/ember-cloudflare/blob/e1af690e19d02028b2460138e008d165b4fd17fc/apps/worker/src/db.ts) abstracts bound SQL parameters and transactional batches for both D1 and DO SQLite. This is real implementation, not only a deployment wrapper. Large central modules (roughly 3,851 lines for Workspace and 1,550 for ChatRoom) also create substantial review and maintenance surface.

### Durable logs bridge objects, but not every side effect is durable

[`apps/worker/src/room-log.ts`](https://github.com/NYLLON-SOFTWARE/ember-cloudflare/blob/e1af690e19d02028b2460138e008d165b4fd17fc/apps/worker/src/room-log.ts) and the room courier track changes for Workspace unread state and SearchIndex. Alarms retry delivery; revocation, purge and reindex jobs also persist. This avoids assuming a cross-object RPC is an atomic transaction.

Search filters are constructed from the authenticated user's accessible room IDs before querying FTS, including DMs. Results can use indexed message copies, so edits/deletes appear after indexing catches up, not atomically with room writes. The centralized Workspace and SearchIndex remain shared coordination/capacity points even though message storage is sharded. See [`apps/worker/src/searches.ts`](https://github.com/NYLLON-SOFTWARE/ember-cloudflare/blob/e1af690e19d02028b2460138e008d165b4fd17fc/apps/worker/src/searches.ts).

In contrast, outgoing webhook/model work uses bounded in-memory queues and waitUntil. The code explicitly drops work when queues fill; webhook delivery does not retry. Do not interpret durable chat history as exactly-once bot automation or guaranteed completion of AI answers across eviction/deployment.

### Compatibility is deliberately implemented

Slack payload parsing, attachments/Block Kit cards and Campfire-style bot endpoints have dedicated modules; this is useful for existing alert publishers but not Slack's app/workflow ecosystem. The rich-text package has server and browser parser paths and fixture-based compatibility tests. Uploads split the advertised 250 MB limit into 10 MiB pieces, rather than trying to pass a 250 MB request through the Worker request-size limit. [Bot modules](https://github.com/NYLLON-SOFTWARE/ember-cloudflare/blob/e1af690e19d02028b2460138e008d165b4fd17fc/apps/worker/src/bots), [rich-text](https://github.com/NYLLON-SOFTWARE/ember-cloudflare/blob/e1af690e19d02028b2460138e008d165b4fd17fc/packages/richtext), [uploads](https://github.com/NYLLON-SOFTWARE/ember-cloudflare/blob/e1af690e19d02028b2460138e008d165b4fd17fc/apps/worker/src/files/uploads.ts).

## Security and Trust Boundaries

### Authentication and authorization: thoughtful, with powerful administrators

- Session cookies are random 32-byte tokens, HttpOnly, SameSite=Lax, Secure and __Host-prefixed on HTTPS. The database retains HMAC digests under SESSION_SECRET. Sessions may last 400 days unused: convenient, but a long stolen-session exposure window. Passwords use scrypt with N=2^15, r=8, p=3 and random salts; legacy PBKDF2 hashes upgrade at login. Rate limits precede password hashing and dummy work obscures unknown accounts. [`apps/worker/src/auth.ts`](https://github.com/NYLLON-SOFTWARE/ember-cloudflare/blob/e1af690e19d02028b2460138e008d165b4fd17fc/apps/worker/src/auth.ts), [`apps/worker/src/passwords.ts`](https://github.com/NYLLON-SOFTWARE/ember-cloudflare/blob/e1af690e19d02028b2460138e008d165b4fd17fc/apps/worker/src/passwords.ts).
- API writes reject cross-site browser headers; WebSocket upgrades require the exact origin. Membership is checked before a room is opened. Short-lived authorization timestamps and persisted revocations address the race between admission and removal; tests cover eviction and delayed grants. This is stronger evidence than a generic “secure by default” slogan, but not a penetration-test result. [`apps/worker/src/revocations.ts`](https://github.com/NYLLON-SOFTWARE/ember-cloudflare/blob/e1af690e19d02028b2460138e008d165b4fd17fc/apps/worker/src/revocations.ts), [`apps/worker/test/revocation.test.ts`](https://github.com/NYLLON-SOFTWARE/ember-cloudflare/blob/e1af690e19d02028b2460138e008d165b4fd17fc/apps/worker/test/revocation.test.ts).
- Setup is gated by a deployment password/token, but the setup password accepts any length. Choose a strong one. Keep guest-name sign-in confined to development. Open registration does not prove ownership of the supplied email address; invitation/domain flows do. Memberful is a trusted identity provider, with signed webhook-triggered API rechecks. [Security notes](https://github.com/NYLLON-SOFTWARE/ember-cloudflare/blob/e1af690e19d02028b2460138e008d165b4fd17fc/docs/self-hosting.md#security-notes).
- Administrators can generate sign-in links for **any user, including administrators**, reusable for four hours while the originating admin session remains valid. A recovery token can reset any account. These are intentional impersonation/recovery powers, not private-room confidentiality from the administrator. Disable recovery credentials when not needed. [`apps/worker/src/transfers.ts`](https://github.com/NYLLON-SOFTWARE/ember-cloudflare/blob/e1af690e19d02028b2460138e008d165b4fd17fc/apps/worker/src/transfers.ts), [`apps/worker/src/recovery.ts`](https://github.com/NYLLON-SOFTWARE/ember-cloudflare/blob/e1af690e19d02028b2460138e008d165b4fd17fc/apps/worker/src/recovery.ts).
- Tenant isolation is deployment/resource isolation. Give each instance its own Worker, object namespaces, R2 bucket and D1 database. Sharing a bucket/database is not a supported tenant boundary; the deployment tooling contains collision/adoption checks. A separate Cloudflare account is stronger isolation from deploy-token compromise.

### File links do not enforce current membership

[`apps/worker/src/files/serving.ts`](https://github.com/NYLLON-SOFTWARE/ember-cloudflare/blob/e1af690e19d02028b2460138e008d165b4fd17fc/apps/worker/src/files/serving.ts) validates the file signature and object existence, **not a login or current room membership**. Addresses have no expiry and responses are publicly cacheable for one hour. Someone who retains a private-room file URL can continue retrieving it after removal; deletion at origin does not erase downloaded or cached copies. This behavior is candidly documented, but incompatible with requirements for immediate membership-based attachment revocation. Treat such URLs as durable bearer credentials.

Serving forces dangerous types such as HTML/SVG to downloads and applies nosniff/header controls; this is not malware scanning. No antivirus guarantee was established.

### Credentials, network and privacy

Resend, Turnstile, AI Gateway and SFU secrets entered in settings are AES-GCM sealed using purpose-separated HKDF keys derived from SESSION_SECRET ([`apps/worker/src/sealed.ts`](https://github.com/NYLLON-SOFTWARE/ember-cloudflare/blob/e1af690e19d02028b2460138e008d165b4fd17fc/apps/worker/src/sealed.ts)). This protects a database-only leak, not the running Worker or account administrator. Rotating/loss of SESSION_SECRET signs users out, invalidates signed links and makes sealed integration settings unreadable until reconfigured; preserve it securely with the recovery plan.

Link unfurls validate HTTP(S) hosts, reject non-public DNS results and IP literals, recheck redirect hosts, bound body/time/subrequests, and use global_fetch_strictly_public. The guard explicitly cannot pin the resolved IP to the actual fetch, so it relies partly on Cloudflare's egress semantics rather than being a portable DNS-rebinding-proof proxy. No live bypass testing was performed. [`apps/worker/src/unfurl/guard.ts`](https://github.com/NYLLON-SOFTWARE/ember-cloudflare/blob/e1af690e19d02028b2460138e008d165b4fd17fc/apps/worker/src/unfurl/guard.ts), [`apps/worker/src/unfurl/fetch.ts`](https://github.com/NYLLON-SOFTWARE/ember-cloudflare/blob/e1af690e19d02028b2460138e008d165b4fd17fc/apps/worker/src/unfurl/fetch.ts).

Outgoing bot URLs are administrator-controlled; they do not use that DNS guard. HTTPS is required except localhost HTTP, redirects are not followed, and delivery includes **the bot's reusable posting key** in room.path. A compromised destination acquires that bot capability; configure only trusted receivers and rotate exposed keys. [`apps/worker/src/bots/webhooks.ts`](https://github.com/NYLLON-SOFTWARE/ember-cloudflare/blob/e1af690e19d02028b2460138e008d165b4fd17fc/apps/worker/src/bots/webhooks.ts).

Worker observability is enabled. The guide warns invocation URLs can record bot keys and join codes, even where application logs redact them. Restrict logs, decide retention, and consider disabling invocation logging as documented. Remote preview/card images contact third-party sites and reveal reader IP addresses even without a referrer. Email goes to the configured service; encrypted Web Push still involves browser push infrastructure and notification display on devices. Server-side chat/search are not E2EE. [Security/privacy documentation](https://github.com/NYLLON-SOFTWARE/ember-cloudflare/blob/e1af690e19d02028b2460138e008d165b4fd17fc/docs/self-hosting.md#security-notes), [`apps/worker/src/push/endpoints.ts`](https://github.com/NYLLON-SOFTWARE/ember-cloudflare/blob/e1af690e19d02028b2460138e008d165b4fd17fc/apps/worker/src/push/endpoints.ts).

## AI Providers, Tools and Costs

The optional assistant sends conversation text and speaker names through the account's default AI Gateway to Workers AI or external models, with user/agent IDs as gateway metadata. Ordinary room context is the latest 20 messages; thread context includes its parent and up to 50 recent replies, with a 40,000-character conversation target. File context is filenames rather than a general attachment-document ingestion system. Administrators choose models and maximum thinking/answer levels; users pick within them. [`apps/worker/src/assistant/answers.ts`](https://github.com/NYLLON-SOFTWARE/ember-cloudflare/blob/e1af690e19d02028b2460138e008d165b4fd17fc/apps/worker/src/assistant/answers.ts), [`apps/worker/src/assistant/gateway.ts`](https://github.com/NYLLON-SOFTWARE/ember-cloudflare/blob/e1af690e19d02028b2460138e008d165b4fd17fc/apps/worker/src/assistant/gateway.ts).

Claude Messages and OpenAI Responses may receive provider-hosted web tools; Chat Completions has no such tools here. These are **not shell, filesystem, browser-control or arbitrary MCP agents**. Source messages and web results can still manipulate answers or web queries; no deterministic confidentiality firewall for provider tools was established. The implementation restricts model-produced image/unfurl destinations to conversation/source evidence, which is a useful mitigation, not a universal prompt-injection defense.

Gateway formats can fall back after compatibility refusals, and Anthropic paused turns can continue with reduced budgets. Token/time/search limits bound individual answers, not aggregate account spend. The documented upper answer budget reaches 38,000 output tokens including thinking; web search/page input may add charges. Setup/model trials themselves make provider requests. Configure Gateway spend limits before enabling this for an open community, and independently review logging/cache/retention/DLP settings and external provider terms. Disabling the assistant or deleting the question can prevent posting the result, but cannot recall content already sent upstream.

**The $5 headline is a base plan, not a total bill ceiling.** At review time Cloudflare's public pricing confirms DO SQLite Free allows 100,000 rows written/day and 5 GB total, versus 50 million included writes/month on Paid; R2 Standard includes 10 GB-month plus operation allowances, then $0.015/GB-month **and operations charges**. Free egress does not mean every download costs nothing in requests. AI Gateway credit purchases add a 5% fee; external-model tokens/search and optional services are separate. The README's roughly 100 daily users is an author estimate from about 20 row writes/message, not an independently measured capacity guarantee. Usage patterns, shared account quotas, active duration, alarms, search and notifications change the answer.

Pricing references checked 2026-11-10: [Durable Objects](https://developers.cloudflare.com/durable-objects/platform/pricing/), [R2](https://developers.cloudflare.com/r2/pricing/), [AI Gateway Unified Billing](https://developers.cloudflare.com/ai-gateway/features/unified-billing/). Recheck current rates before adoption.

## Persistence, Retention and Recovery

Default DO SQLite distributes primary data across rooms and Workspace, while a separate SearchIndex holds message text/copies. D1 centralizes primary data for SQL export and Time Travel but **does not eliminate the separate search object or R2**. The guide documents D1's 500 MB Free / 10 GB Paid per-database cap and 7/30-day Time Travel windows. Those restore mechanisms do not by themselves produce a consistent whole-workspace snapshot with attachments and search.

There is no automatic DO-SQLite-to-D1 migration: changing STORAGE_BACKEND starts an empty application view and leaves old data in its original backend. Choose early. The product advertises no age-based chat expiry, but unlimited retention is neither unlimited storage nor a backup promise. Message/room deletion has cleanup machinery; unfinished uploads are scheduled for cleanup after a day, and search removal is asynchronous. No complete portable export/import and coordinated restore drill was demonstrated in this review. The README explicitly lists full-message exports as “not yet.”

Before valuable data: establish an operator-owned backup inventory for primary objects/database, R2 objects, configuration and secrets; test restoration and reindexing; decide legal deletion/log retention and device-copy handling. A database export without the matching signing/encryption secret and files is insufficient. [Storage guide](https://github.com/NYLLON-SOFTWARE/ember-cloudflare/blob/e1af690e19d02028b2460138e008d165b4fd17fc/docs/self-hosting.md#storage-durable-object-sqlite-or-d1), [`apps/worker/src/chat-room.ts`](https://github.com/NYLLON-SOFTWARE/ember-cloudflare/blob/e1af690e19d02028b2460138e008d165b4fd17fc/apps/worker/src/chat-room.ts), [`apps/worker/src/search-index.ts`](https://github.com/NYLLON-SOFTWARE/ember-cloudflare/blob/e1af690e19d02028b2460138e008d165b4fd17fc/apps/worker/src/search-index.ts).

## Self-Hosting and Update Notes

- Requires a Cloudflare account, R2 enabled, Worker/DO bindings and GitHub/GitLab integration for the deploy-button path. Local builds require the documented recent Node versions and pnpm 10. Optional email requires provider/domain setup; AI requires account/API token and applicable credits; unfinished huddles require an SFU app. None were provisioned here.
- Keep do-sqlite unless central SQL/export outweighs D1's contention and capacity limits. DO free quotas can stop new writes until reset; do not wait for production data loss symptoms before considering Paid.
- “One click” still leaves setup, access policy, resource naming, build-token trimming, update workflow installation, backup design and monitoring. The guide warns Cloudflare-created build tokens can be very broad. Even trimmed Worker deploy authority can bind other account resources, so least privilege has an account-level limit.
- The update workflow opens release PRs; a human merge deploys. Its write-capable Actions are commit-pinned, but the ordinary read-only CI uses version tags. Copies do not automatically inherit upstream CI. Workers Builds branch previews intentionally lack bindings/address: a successful branch build is **not a runtime staging test**.
- D1 migrations apply before Worker deployment; DO migrations apply as objects open. Upstream prohibits edits/deletions to released migration files and documents additive rollback compatibility. Inspect schema/update diffs anyway: code rollback is not data rollback. Preserve deployment names, resource identity and secrets; never use “fresh setup” as recovery for a mistaken backend switch.

Evidence: [`wrangler.jsonc`](https://github.com/NYLLON-SOFTWARE/ember-cloudflare/blob/e1af690e19d02028b2460138e008d165b4fd17fc/wrangler.jsonc), [`apps/worker/scripts/deploy.ts`](https://github.com/NYLLON-SOFTWARE/ember-cloudflare/blob/e1af690e19d02028b2460138e008d165b4fd17fc/apps/worker/scripts/deploy.ts), [`.github/workflows/update-ember.yml`](https://github.com/NYLLON-SOFTWARE/ember-cloudflare/blob/e1af690e19d02028b2460138e008d165b4fd17fc/.github/workflows/update-ember.yml), [operator guide](https://github.com/NYLLON-SOFTWARE/ember-cloudflare/blob/e1af690e19d02028b2460138e008d165b4fd17fc/docs/self-hosting.md).

## Maturity, License and Verification

Public GitHub metadata retrieved 2026-11-10 showed creation on 2026-10-12, 272 stars, 17 forks and last push on 2026-11-10. These are adoption/activity signals, not quality scores. Latest published release was [v0.4.2](https://github.com/NYLLON-SOFTWARE/ember-cloudflare/releases/tag/v0.4.2), 2026-11-08; this review pins newer main. Recent v0.4.1 notes include a reindex-start fix, demonstrating why upgrade/derived-state behavior matters. Open-work inspection included draft huddle PR #269; this was not a complete issue-triage audit.

There are 158 files named *.test.ts across the snapshot (not 158 executed tests). Worker Vitest runs in workerd for both storage backends; other tests cover scripts, protocol/rich text and UI, with Playwright desktop/mobile projects. Sampled tests include sign-in/revocation, file behavior and network guards. [CI configuration](https://github.com/NYLLON-SOFTWARE/ember-cloudflare/blob/e1af690e19d02028b2460138e008d165b4fd17fc/.github/workflows/ci.yml) includes frozen lockfile install, typecheck, tests, build and browser tests, plus released-migration immutability checks. [Upstream CI run 42765304514](https://github.com/NYLLON-SOFTWARE/ember-cloudflare/actions/runs/42765304514) reported success for the exact reviewed SHA. This is hosted upstream evidence; **we did not run or independently reproduce that suite**, audit all dependencies, inspect every assertion or validate production reliability.

The committed [performance report](https://github.com/NYLLON-SOFTWARE/ember-cloudflare/blob/e1af690e19d02028b2460138e008d165b4fd17fc/perf/baseline/report.md) is from 2026-10-12 at a different commit, on local wrangler dev with state in memory-backed storage. Its 1,359 messages/s DO result and millisecond latencies are not current geographically distributed Cloudflare production guarantees. It also records join-latency degradation at 750 members. No performance test was run here.

The actual [MIT license](https://github.com/NYLLON-SOFTWARE/ember-cloudflare/blob/e1af690e19d02028b2460138e008d165b4fd17fc/LICENSE) credits 37signals, LLC and 2026 NYLLON LLC. Preserve both notices for substantial reused code. Iconoir, seed photos, bundled skill material and packages have separate notices/terms; the root license is not a blanket asset or hosted-provider license. The pnpm lockfile and relatively lean Worker runtime dependency list help reproducibility; no vulnerability-free dependency claim is made.

## Comparison

| Option | Prefer it when | Main tradeoff versus Ember |
|---|---|---|
| [Campfire](https://github.com/basecamp/once-campfire) | You want the directly related self-hosted chat design on a conventional application stack | Ember trades conventional server operations for Cloudflare coupling and object-based persistence |
| [Zulip](https://github.com/zulip/zulip) | Topic-structured discussion and a longer-established open-source collaboration ecosystem matter most | More conventional service operations; not the same minimal Cloudflare deployment model |
| [Mattermost](https://github.com/mattermost/mattermost) | Richer organization/integration requirements justify a heavier deployment | Compare edition/licensing and identity/compliance features explicitly; not a drop-in cost comparison |
| Slack | Managed operations, extensive apps, enterprise identity and collaboration workflows are mandatory | Recurring commercial plans and less infrastructure ownership |

These are architectural fit comparisons, not fresh full audits of each alternative. An existing [Zlack review](zlack.md) describes a desktop Slack wrapper, not a self-hosted substitute.

**Practical adoption gate:** test join/revoke/private search and attachment-link behavior with synthetic users; exercise quota exhaustion and bot/model failure; restore a full disposable workspace; inspect update rollback; then decide whether permanent links and administrator impersonation meet the organization's expectations. Good candidate for an informed small-community pilot; defer sensitive or compliance-critical migration until those boundaries and recovery are proven.

---

**Attribution:** NYLLON-SOFTWARE/ember-cloudflare, NYLLON LLC and Campfire/37signals lineage; MIT. Review is independent analysis of public source, not an endorsement or security certification.
