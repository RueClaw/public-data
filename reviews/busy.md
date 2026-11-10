# Busy (MatiSolina/busy)

**Repo:** https://github.com/MatiSolina/busy

**Author:** Matias Solina / MatiSolina

**License:** Apache-2.0; preserve LICENSE/NOTICE and applicable third-party terms.

**Reviewed:** 2026-11-10 (UTC)

**Revision:** 7ad291731948a949c90220952fd1dfcb6d99950a, main snapshot committed 2026-11-10 12:43:19 UTC; whole-repository architecture with targeted implementation inspection, not exhaustive audit.

**Verification:** Static review only. No installation, source execution, build, tests, deployment, accounts, model calls or live security probes. Upstream CI for this exact SHA reported success.

**Stack:** TypeScript, Next.js/React, PostgreSQL/Drizzle, Eve, Vercel Workflow/Queues/Schedules/Sandbox/Drives/Blob, Electron.

**What it is:** A single-workspace AI-coworker application: each durable bot gets a deployed Eve runtime and cloud Linux computer, with browser/macOS clients, memory, files, routines and collaboration.

## Verdict

⚠️ **Interesting — a serious Vercel-native control plane, not a local or turnkey assistant.** Durable orchestration, explicit provider billing and per-project bot identity are compelling. Pilot with disposable data and narrowly scoped integrations: broad computer authority, legacy credential paths, cloud coupling, retention uncertainty and a very young public release prevent an unqualified deployment recommendation.

## What It Is

Busy is not a productivity timer. The Hub owns the application state; Electron is a thin macOS shell around it. Each bot runs in a separate Vercel project, with a long-lived Eve conversation and a Sandbox computer backed by a persistent Drive. That computer contains Chrome, a Linux desktop, command execution and Office/PDF tools. People can view/control it, attach files, schedule routines and have bots consult peers.

“Self-hosted” means operating the stack in your own cloud accounts. Starting the local Hub and Postgres does not run the full bot system locally. One shared workspace is not multi-tenant isolation; multiple permitted logins do not create separate data or capability domains. Sources: [README.md](https://github.com/MatiSolina/busy/blob/7ad291731948a949c90220952fd1dfcb6d99950a/README.md), [docs/architecture.md](https://github.com/MatiSolina/busy/blob/7ad291731948a949c90220952fd1dfcb6d99950a/docs/architecture.md).

## Stack

| Layer | Implementation | Meaning |
|---|---|---|
| Hub/UI | Next.js 16.4.3, React 19.3, TypeScript | APIs, settings, chat projection and orchestration |
| State | PostgreSQL/Drizzle; private Vercel Blob | Relational ownership separated from object bytes |
| Agent | Eve 0.91.0, AI SDK 7 | Durable sessions and tool lifecycle |
| Background work | Workflow 5.2.3, Queues 0.8.0, Schedules 0.0.3 | Leases, outboxes and reconciliation |
| Computer | Sandbox 3.9.1 + Drive | Cloud desktop/browser/shell and persistent filesystem |
| Coding tasks | durable-harness 0.0.1, libfx 0.0.16 | Separate durable task runtime |
| Desktop | Electron 45, macOS arm64 | Same Hub, not on-device inference |

Versions are manifest declarations, not installed binaries. Evidence: [apps/hub/package.json](https://github.com/MatiSolina/busy/blob/7ad291731948a949c90220952fd1dfcb6d99950a/apps/hub/package.json), [templates/bot/package.json](https://github.com/MatiSolina/busy/blob/7ad291731948a949c90220952fd1dfcb6d99950a/templates/bot/package.json), [apps/desktop/package.json](https://github.com/MatiSolina/busy/blob/7ad291731948a949c90220952fd1dfcb6d99950a/apps/desktop/package.json).

## Key Features

### Durable work instead of a disposable chat

The UI projects persisted messages/events; delivery identities survive retries. Deployment workflows fence writes by generation, and deletion uses tokens/tombstones. Routines combine schedules with outboxes. Recovery distinguishes an uncertain earlier outcome from permission to repeat an external action. These are strong patterns, although static inspection cannot establish exactly-once behavior across providers. See [docs/agent-execution.md](https://github.com/MatiSolina/busy/blob/7ad291731948a949c90220952fd1dfcb6d99950a/docs/agent-execution.md), [apps/hub/workflows/deploy-bot.ts](https://github.com/MatiSolina/busy/blob/7ad291731948a949c90220952fd1dfcb6d99950a/apps/hub/workflows/deploy-bot.ts) and [apps/hub/workflows/delete-bot.ts](https://github.com/MatiSolina/busy/blob/7ad291731948a949c90220952fd1dfcb6d99950a/apps/hub/workflows/delete-bot.ts).

### A cloud computer and inspectable memory

[templates/bot/agent/sandbox.ts](https://github.com/MatiSolina/busy/blob/7ad291731948a949c90220952fd1dfcb6d99950a/templates/bot/agent/sandbox.ts) opens computers in iad1, mounts the bot Drive at /data and sets a 45-minute sandbox timeout. Consultations receive a snapshot and deny-all network policy; normal computer sessions do not receive that restrictive policy. Fireside discussions get a separate writable workspace plus a context snapshot. Memory uses an Eve file-memory abstraction backed by Hub APIs, with version/session/turn provenance—not model-weight learning ([templates/bot/agent/memory/memory.ts](https://github.com/MatiSolina/busy/blob/7ad291731948a949c90220952fd1dfcb6d99950a/templates/bot/agent/memory/memory.ts)).

### Explicit provider and billing choices

AI Gateway and Token Pass are distinct from ChatGPT/Grok subscription OAuth. Saved defaults apply to new bots; existing bots keep their selected connection. Subscription grants are encrypted in the Hub and refreshed server-side. Bots use OIDC-authenticated Hub inference; normalization enforces the selected model, streaming and store:false. Subscription failures do not silently switch to paid Gateway usage. This is supported by the routing design, not by live account validation. See [docs/ai-connections.md](https://github.com/MatiSolina/busy/blob/7ad291731948a949c90220952fd1dfcb6d99950a/docs/ai-connections.md), [apps/hub/lib/ai/inference.ts](https://github.com/MatiSolina/busy/blob/7ad291731948a949c90220952fd1dfcb6d99950a/apps/hub/lib/ai/inference.ts), [apps/hub/lib/ai/subscription-store.ts](https://github.com/MatiSolina/busy/blob/7ad291731948a949c90220952fd1dfcb6d99950a/apps/hub/lib/ai/subscription-store.ts).

## Architecture

Browser/Electron → authenticated Hub → Postgres/control-plane state → per-bot Eve project → model and Sandbox/Drive. Blob stores uploaded/generated bytes. Workflow owns longer lifecycles; Queues and Schedules deliver and reconcile work. A generated template bundle deploys bots without runtime access to an operator checkout.

The separation is coherent: deployments, conversations and files can fail independently, and the Hub does not need an always-running process per task. The cost is a substantial cloud product graph, wildcard bot DNS, management credentials and coupling between Hub, template, image and external Eve runtime. Installing one package is insufficient.

## Authentication, Permissions and Trust Boundaries

**Positive controls:** scrypt hashing with timing-safe comparison; signed 30-day HttpOnly/SameSite cookies; cross-site write checks; optional allowlisted Vercel login; bot OIDC matched to persisted project ID, with unlinked compatibility off by default; short-lived ES256 Hub tokens. MCP OAuth uses AES-256-GCM with connection-bound associated data. MCP App iframes use a separate origin and restrictive default CSP/permissions. Evidence: [apps/hub/lib/auth/password.ts](https://github.com/MatiSolina/busy/blob/7ad291731948a949c90220952fd1dfcb6d99950a/apps/hub/lib/auth/password.ts), [apps/hub/lib/auth/session.ts](https://github.com/MatiSolina/busy/blob/7ad291731948a949c90220952fd1dfcb6d99950a/apps/hub/lib/auth/session.ts), [apps/hub/proxy.ts](https://github.com/MatiSolina/busy/blob/7ad291731948a949c90220952fd1dfcb6d99950a/apps/hub/proxy.ts), [apps/hub/lib/bot-auth.ts](https://github.com/MatiSolina/busy/blob/7ad291731948a949c90220952fd1dfcb6d99950a/apps/hub/lib/bot-auth.ts), [apps/hub/lib/mcp/crypto.ts](https://github.com/MatiSolina/busy/blob/7ad291731948a949c90220952fd1dfcb6d99950a/apps/hub/lib/mcp/crypto.ts), [apps/hub/lib/mcp/app-sandbox.ts](https://github.com/MatiSolina/busy/blob/7ad291731948a949c90220952fd1dfcb6d99950a/apps/hub/lib/mcp/app-sandbox.ts).

**Limits that matter:**

- **Shared authority:** skills and connections are app-wide. Bot separation is not user tenancy. A compromised Hub has management authority, stored data and decryption material; RLS does not remove the privileged server from trust.
- **Approval is not a universal computer firewall.** MCP writes request approval through Eve and ACLs are re-read per call. Reads can run without asking; classification trusts remote readOnlyHint or a name heuristic. Such metadata does not guarantee confidentiality or harmlessness. Browser/shell actions have a wider surface than this MCP policy, and prompt instructions are not a comprehensive external-effect gate ([templates/bot/agent/lib/approval.ts](https://github.com/MatiSolina/busy/blob/7ad291731948a949c90220952fd1dfcb6d99950a/templates/bot/agent/lib/approval.ts), [templates/bot/agent/instructions.ts](https://github.com/MatiSolina/busy/blob/7ad291731948a949c90220952fd1dfcb6d99950a/templates/bot/agent/instructions.ts)).
- **Reviewed and legacy MCP differ.** Reviewed connections go through a Hub allowlist proxy; at this SHA the raw-token route refuses connections with a tool policy. Legacy connections can still receive provider tokens and call providers directly. Thus “all MCP credentials remain in the Hub” is too broad. The proxy checks membership; it is not a separate signed approval-receipt verifier for every action ([templates/bot/agent/connections/marketplace.ts](https://github.com/MatiSolina/busy/blob/7ad291731948a949c90220952fd1dfcb6d99950a/templates/bot/agent/connections/marketplace.ts), [apps/hub/app/api/bot/mcp/[id]/token/route.ts](https://github.com/MatiSolina/busy/blob/7ad291731948a949c90220952fd1dfcb6d99950a/apps/hub/app/api/bot/mcp/%5Bid%5D/token/route.ts), [apps/hub/lib/mcp/model-proxy.ts](https://github.com/MatiSolina/busy/blob/7ad291731948a949c90220952fd1dfcb6d99950a/apps/hub/lib/mcp/model-proxy.ts)).
- **Consultation identity is transitional.** Pair-scoped credentials exist, but sending them requires BUSY_CONSULTATION_CREDENTIALS=1; legacy peer OIDC remains accepted unless BUSY_LEGACY_PEER_OIDC=off. The helper explicitly says neither switch is set by the Hub yet. Architecture prose about pair-scoped identity is therefore not a description of every default deployment. This is a deployment caveat, not a demonstrated exploit ([templates/bot/agent/lib/consultation-auth.ts](https://github.com/MatiSolina/busy/blob/7ad291731948a949c90220952fd1dfcb6d99950a/templates/bot/agent/lib/consultation-auth.ts), [templates/bot/agent/channels/eve.ts](https://github.com/MatiSolina/busy/blob/7ad291731948a949c90220952fd1dfcb6d99950a/templates/bot/agent/channels/eve.ts)).
- **Network guards are not a proven egress perimeter.** MCP HTTPS/private-address validation, redirect checks and credential stripping are useful. DNS validation precedes ordinary fetch without a visibly address-pinned connection, so rebinding resistance remains unproven. No live probe was performed ([apps/hub/lib/mcp/network.ts](https://github.com/MatiSolina/busy/blob/7ad291731948a949c90220952fd1dfcb6d99950a/apps/hub/lib/mcp/network.ts)).
- **Revocation is coarse.** Logout removes the local cookie; verification is stateless. A copied valid session is not visibly revoked by logout itself. Shared-secret rotation also affects encrypted connection records, requiring a deliberate recovery procedure.

## Privacy, Persistence, Retention and Recovery

Busy is not local-only or end-to-end-encrypted storage. Conversations, instructions, selected files and tool context can reach models; connected services receive tool arguments; browsed sites see bot traffic. Vercel hosts application and computer workloads; Postgres, Blob and Drives persist content. Subscription store:false is a request option, not erasure of Busy history or a universal provider-retention guarantee. Optional Speed Insights is gated by NEXT_PUBLIC_RUM=1 ([apps/hub/lib/rum/client.ts](https://github.com/MatiSolina/busy/blob/7ad291731948a949c90220952fd1dfcb6d99950a/apps/hub/lib/rum/client.ts), [apps/hub/app/layout.tsx](https://github.com/MatiSolina/busy/blob/7ad291731948a949c90220952fd1dfcb6d99950a/apps/hub/app/layout.tsx)).

The agent declares default workflow retention and a one-year session timeout, neither a global content TTL ([templates/bot/agent/agent.ts](https://github.com/MatiSolina/busy/blob/7ad291731948a949c90220952fd1dfcb6d99950a/templates/bot/agent/agent.ts)). Deletion is unusually careful: stop code tasks, delete the project by immutable ID, remove schedules/Blobs, write a tombstone, cascade owned rows and sweep late uploads after 30 minutes. Repeated failures become an attention-needed state ([apps/hub/lib/bots/deletion.ts](https://github.com/MatiSolina/busy/blob/7ad291731948a949c90220952fd1dfcb6d99950a/apps/hub/lib/bots/deletion.ts)).

**Deleting a bot is not independently verified erasure everywhere.** No explicit Drive/snapshot deletion call was found in the inspected deletion path; provider-side consequences of project deletion were not independently verified. Code tasks and other bots' consultation records may survive with null references; tombstones intentionally persist. Provider logs, backups and model-service retention require separate policies.

Recovery handles interrupted work, not automatically complete disaster recovery. Before real use, define consistent database/Blob/Drive backups, preserve keys securely, test restoration into a disposable installation and verify orphan cleanup. The handbook warns that changing SESSION_SECRET can make encrypted grants unreadable; HUB_SIGNING_KEY rotation also requires bot public-key updates. No complete restore drill was performed or independently established ([docs/handbook.md](https://github.com/MatiSolina/busy/blob/7ad291731948a949c90220952fd1dfcb6d99950a/docs/handbook.md)).

## Self-Hosting, Costs and Update Risks

- Node.js ≥24.15, pinned pnpm 12.16.1 and PostgreSQL; Docker supplies the documented local database example. Native packaging targets Apple Silicon macOS; the browser is the other client. The documented model path requires no local GPU or weight download.
- Full operation needs operator-owned Vercel Hub/bot projects, database, private Blob, Registry image, Sandbox/Drives, Workflow/Queues/Schedules, DNS and a model connection. Per-bot projects consume quotas. Account availability and free-tier sufficiency were not validated.
- Models, peer/fireside turns, coding tasks, embeddings, compute, retained storage and traffic can all cost money. Subscription inference does not make infrastructure free. Set separate provider/infrastructure budgets; no unified hard end-to-end spending cap was established here. Live provider eligibility, terms, consent and quotas remain account-dependent.
- Bot deployment requires a digest-pinned image, a useful safeguard. Building it still uses a tag-based Eve base, current Chrome, apt and unpinned Python packages. A digest pins the resulting output, not the safety or reproducibility of those ingredients ([images/bot-base/Dockerfile](https://github.com/MatiSolina/busy/blob/7ad291731948a949c90220952fd1dfcb6d99950a/images/bot-base/Dockerfile)).
- Desktop defaults to the official hosted Hub unless BUSY_URL is overridden. Updates require confirmation, check SHA-256/bundle identity and use rollback-aware swapping. Hash and archive come from the same configured Hub—not independent publisher-signature verification. The manifest uses ad-hoc signing and disables hardened runtime; do not assume notarization ([apps/desktop/main.mjs](https://github.com/MatiSolina/busy/blob/7ad291731948a949c90220952fd1dfcb6d99950a/apps/desktop/main.mjs), [apps/desktop/update.mjs](https://github.com/MatiSolina/busy/blob/7ad291731948a949c90220952fd1dfcb6d99950a/apps/desktop/update.mjs), [apps/desktop/package.json](https://github.com/MatiSolina/busy/blob/7ad291731948a949c90220952fd1dfcb6d99950a/apps/desktop/package.json)).
- db:init is only for an empty database; upgrades require ordered migrations. Coordinate Hub, bot and image releases and verify a real first response/computer after deployment.

## Maturity, Tests and Claims

Public GitHub metadata retrieved on 2026-11-10 showed creation on 2026-11-09, 49 stars, 7 forks, zero open issues and last push at 12:43:20 UTC. These are a snapshot, not quality evidence. Release v0.5.0 was published 2026-11-09 with no attached binary assets; the reviewed desktop manifest is 0.5.1. The public project is very young despite substantial implementation and documentation.

There are extensive route, database, OAuth, policy, wrapper and updater tests. CI defines frozen-lockfile installs, lint/type/build checks, affected-task planning and macOS desktop tests. GitHub reported [Ultracite run 42818167590](https://github.com/MatiSolina/busy/actions/runs/42818167590) successful for the reviewed SHA. This is upstream evidence, **not tests run by this review**. Default tests use mocks/PGlite; browser tests, real-Postgres concurrency and live provider evals have separate opt-in requirements. A green default workflow does not prove production integration ([docs/testing.md](https://github.com/MatiSolina/busy/blob/7ad291731948a949c90220952fd1dfcb6d99950a/docs/testing.md), [.github/workflows/ultracite.yml](https://github.com/MatiSolina/busy/blob/7ad291731948a949c90220952fd1dfcb6d99950a/.github/workflows/ultracite.yml)).

Dependencies are locked but include early-version orchestration packages, patched frontend dependencies and a SheetJS tarball hosted on its own CDN. Actions use version tags rather than immutable commit pins. No dependency vulnerability/provenance audit, load test or macOS validation was performed. Published latency measurements are author-reported baselines, not independently reproduced gains. No deployment, subscription, deletion or real-browser success is claimed by this review.

## Comparison

| Option | Prefer it when | Difference from Busy |
|---|---|---|
| [OpenWorker](openworker.md) | You want a local desktop coworker | Local-host permission boundary rather than this per-bot cloud topology |
| [Hermes Bot Mode](hermes-bot-mode.md) | You already operate Hermes and want named bot profiles | Avoids adding a new Vercel control plane solely for a roster |
| [OpenMuse](openmuse.md) | You want a forkable single-owner assistant template | Different infrastructure and action-gate design; still needs its own review |
| [Eve](https://github.com/vercel/eve) directly | You need the durable runtime, not the whole product | You build UX, identity, file ownership and lifecycle orchestration |

These are architectural comparisons, not a fresh benchmark or feature-parity claim; linked public reviews provide context.

## Practical Adoption Gate

Start with one disposable bot, synthetic files, no valuable logged-in browser accounts and a minimal reviewed MCP allowlist. Require consent for external effects, retire legacy credentials, set budgets, check image provenance and prove interruption recovery plus cleanup. Then test backup restoration and OAuth/quotas before expanding. Worth studying and piloting for cloud-native durable coworkers; unsuitable as-is for offline operation, minimal infrastructure, strict tenant isolation or independently proven deletion guarantees.

---

**Attribution:** Matias Solina, [MatiSolina/busy](https://github.com/MatiSolina/busy), Apache-2.0. Analysis only; no source code extracted. Third-party notices and provider terms remain applicable.
