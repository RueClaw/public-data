# Linger (simplexai-labs/linger)

**Repo:** https://github.com/simplexai-labs/linger
**License:** Custom Linger Open Source License: Apache-2.0-derived with hosted-service and frontend-branding restrictions; source-available, not ordinary Apache-2.0 or unrestricted OSI open source. Component/model/asset terms separate.
**Reviewed:** 2026-11-19 (UTC)
**Revision:** cd0e23af6cacbca311bfe1964e11ea6c73cc7562 (main; commit dated 2026-11-19T16:55:34Z). Scope: architecture, server authorization/consent, local execution/update paths, memory, persistence, manifests, documentation and CI.
**Verification:** Static review only. No installation, builds, tests, model/dataset downloads, provider calls, desktop access or live security probes.
**Stack:** Go, TypeScript, React 19, Electron, PostgreSQL 17, River, Hono, Yjs/Hocuspocus, SQLite, LiveKit; Codex/Claude Code/Pi runtimes.
**What it is:** A personal-agent workspace combining chat, collaborative documents, shared knowledge, proactive follow-ups and agents operating a connected computer. Local inference is an option, not a guarantee that every feature stays offline.

## Verdict

⚠️ **Interesting — substantial personal-agent engineering, but pilot on a dedicated account before granting daily-life authority.** Linger has concrete consent, source-validation and recovery machinery, not just a chat UI. Host-access authority, runtime-dependent guardrails, cloud integrations, unproven complete disaster recovery and restricted licensing keep it out of the uncomplicated deploy category.

## What It Is

“Another Me” coordinates agents, reads connected sources, maintains a personal wiki and follows up proactively. Rooms, Tasks and Documents provide contexts. The server owns business records and permissions; a Go Computer Daemon connects outward and launches the chosen runtime. This is neither a memory-only library nor an isolated agent sandbox.

The desktop app can install a local server; Compose serves the workspace across computers. Agents and model endpoints operate from connected computers even when the server is elsewhere. There are several trust/storage locations, not one local database. See [docs/architecture.md](https://github.com/simplexai-labs/linger/blob/cd0e23af6cacbca311bfe1964e11ea6c73cc7562/docs/architecture.md) and [docs/self-hosting.md](https://github.com/simplexai-labs/linger/blob/cd0e23af6cacbca311bfe1964e11ea6c73cc7562/docs/self-hosting.md).

## Stack and Architecture

| Layer | Implementation |
|---|---|
| Interface | React/Vite, BlockNote; Electron desktop shell |
| Business authority | Go/Gin TeamHub, PostgreSQL, River jobs, goose migrations, OpenAPI contracts |
| Agent/document services | Node 26, Hono, Yjs/Hocuspocus; memory/wiki pipelines |
| Local execution | Go daemon, SQLite operation ledger, per-context workspaces, native runtime adapters |
| Tools | teamhub CLI; Playwright/Cua, or Linux AT-SPI/xdotool |
| Voice | LiveKit, FFmpeg, Soniox transcription, xAI live voice |

Per-agent credentials authorize business operations independently of active model runs. The daemon carries queued work and events; runtimes call model endpoints directly. This helps reconnects and background work but is not an all-traffic egress firewall. [apps/teamhub/internal/agentauth/agentauth.go](https://github.com/simplexai-labs/linger/blob/cd0e23af6cacbca311bfe1964e11ea6c73cc7562/apps/teamhub/internal/agentauth/agentauth.go) resolves current tenant/actor/resource facts rather than treating a client-supplied target as authority.

## Key Features

### Checked knowledge structure, not guaranteed truth

The owner-scoped wiki and per-agent memory are separate. Documentation describes typed entity/session pages, citations and app-written change logs. [apps/node-services/src/llm-wiki/wiki-candidate-validation.ts](https://github.com/simplexai-labs/linger/blob/cd0e23af6cacbca311bfe1964e11ea6c73cc7562/apps/node-services/src/llm-wiki/wiki-candidate-validation.ts) checks routed targets, incoming citations and source coverage. These are useful provenance/anti-loss checks, not factual entailment proofs or prompt-injection immunity.

Search combines PostgreSQL keyword and temporal ranks with reciprocal-rank fusion; it needs no embedding/reranker model. Alternate phrasings help lexical and cross-language recall. Summarized sections and short change logs are not complete audit archives. [docs/wiki-and-memory.md](https://github.com/simplexai-labs/linger/blob/cd0e23af6cacbca311bfe1964e11ea6c73cc7562/docs/wiki-and-memory.md) describes extraction after five successful Room runs and idle consolidation; delegated Tasks and document work do not feed that agent-memory path.

### Content-bound connector consent

[apps/teamhub/internal/agentconnectedapps/confirmation.go](https://github.com/simplexai-labs/linger/blob/cd0e23af6cacbca311bfe1964e11ea6c73cc7562/apps/teamhub/internal/agentconnectedapps/confirmation.go) binds confirmation to a connection and stored action, pins draft content, rechecks current grants/connection state and refuses changed drafts/canvases. Unknown provider outcomes are distinguished from definitive failure. This is good duplicate-send defense, not distributed transactional exactly-once execution.

This guarantee belongs to the connector path. Desktop clicks and shell commands have different policy surfaces. “External apps write only after confirmation” must not be read as universal human confirmation across every runtime/tool.

### Host execution, not a sandbox

[apps/computer/local-daemon/internal/workspace/codex_projection.go](https://github.com/simplexai-labs/linger/blob/cd0e23af6cacbca311bfe1964e11ea6c73cc7562/apps/computer/local-daemon/internal/workspace/codex_projection.go) supplies Codex with sandbox_mode="danger-full-access". [apps/computer/local-daemon/internal/permission/reviewer.go](https://github.com/simplexai-labs/linger/blob/cd0e23af6cacbca311bfe1964e11ea6c73cc7562/apps/computer/local-daemon/internal/permission/reviewer.go) fast-allows selected reads, recognized shell operations and navigation shapes; other intercepted calls go to review. Failures return unavailable; navigation reuse is run-scoped. That is defense in depth, not OS isolation. [docs/architecture.md](https://github.com/simplexai-labs/linger/blob/cd0e23af6cacbca311bfe1964e11ea6c73cc7562/docs/architecture.md) explicitly says **Pi runs without review**.

Per-context folders, read-only memory projections and separate browser profiles organize work; they do not separate same-account processes from files, credentials or signed-in apps. Hostile pages, email and documents reach an agent with real authority. Use a dedicated OS account or disposable machine, narrow integration accounts and no unrelated secrets. No exploit or bypass resistance was tested here.

## Authentication, Network and Credential Boundaries

- **Real API authorization:** action allowlists, tenant-qualified queries, current room/document access and task-context restrictions exist in [apps/teamhub/internal/agentauth/agentauth.go](https://github.com/simplexai-labs/linger/blob/cd0e23af6cacbca311bfe1964e11ea6c73cc7562/apps/teamhub/internal/agentauth/agentauth.go). This is positive API isolation, not proof of safe unrelated-tenant cohosting.
- **Session lifecycle:** [apps/teamhub/internal/account/session.go](https://github.com/simplexai-labs/linger/blob/cd0e23af6cacbca311bfe1964e11ea6c73cc7562/apps/teamhub/internal/account/session.go) stores token digests, locks against stale password verification and rechecks renewed sessions. Complete route-level auth/CSRF coverage was not audited.
- **Broad local-origin trust:** [apps/teamhub/internal/app/cors.go](https://github.com/simplexai-labs/linger/blob/cd0e23af6cacbca311bfe1964e11ea6c73cc7562/apps/teamhub/internal/app/cors.go) accepts configured origins plus localhost, loopback and private-IP origins, reflecting them with credentials enabled. This expands trust beyond an explicit allowlist; CORS alone does not bypass authentication and exploitability was not tested.
- **Shared service trust:** [SECURITY.md](https://github.com/simplexai-labs/linger/blob/cd0e23af6cacbca311bfe1964e11ea6c73cc7562/SECURITY.md) documents seed-derived service credentials and a deployment encryption key. [apps/teamhub/internal/secretbox/secretbox.go](https://github.com/simplexai-labs/linger/blob/cd0e23af6cacbca311bfe1964e11ea6c73cc7562/apps/teamhub/internal/secretbox/secretbox.go) uses AES-256-GCM for saved secrets, not end-to-end document encryption against the server operator. [apps/node-services/src/service-bearer-auth.ts](https://github.com/simplexai-labs/linger/blob/cd0e23af6cacbca311bfe1964e11ea6c73cc7562/apps/node-services/src/service-bearer-auth.ts) compares token digests timing-safely.
- **Local credential files:** [apps/desktop/src/main/computer-credential.ts](https://github.com/simplexai-labs/linger/blob/cd0e23af6cacbca311bfe1964e11ea6c73cc7562/apps/desktop/src/main/computer-credential.ts) atomically writes owner-only files, explicitly not OS keychain storage, and accepts ws or wss. Same-account compromise remains relevant.
- **Remote setup:** Compose defaults database/media ports to loopback. SECURITY requires private secrets and HTTPS before exposure. The shorter self-hosting example shows HTTP/ws and only one replacement secret; follow the stronger security guidance, not that example verbatim. Replace database defaults and the example owner password too.

## Privacy, Provider Flows and Costs

Local inference is not an offline feature matrix. Codex, Claude Code and Pi can use remote subscriptions/API endpoints; background memory/wiki work follows runtime routing. The selected provider receives required context. Composio mediates connected apps and holds upstream credentials; mail/calendar/chat cross that integration boundary. Browser control can use existing signed-in Chrome sessions.

[docs/voice.md](https://github.com/simplexai-labs/linger/blob/cd0e23af6cacbca311bfe1964e11ea6c73cc7562/docs/voice.md) explicitly sends transcription/archive-recovery audio to Soniox and uses xAI for live voice. Saved voice keys are deployment-wide, and the documentation allows any signed-in person to replace them unless environment keys lock them. [apps/teamhub/internal/voicekey/voicekey.go](https://github.com/simplexai-labs/linger/blob/cd0e23af6cacbca311bfe1964e11ea6c73cc7562/apps/teamhub/internal/voicekey/voicekey.go) implements environment precedence and encrypted stored keys. This is shared operational authority, not tenant-isolated billing.

Local inference avoids vendor token charges, not hardware/RAM/storage/power costs. Remote inference, Composio and voice carry their own quotas/pricing; no current price quote or universal spending cap was verified. Background consolidation and proactive/parallel agents consume inference too. Diagnostics upload is optional and user-confirmed, with file/receiver preview and redaction ([docs/diagnostics-upload.md](https://github.com/simplexai-labs/linger/blob/cd0e23af6cacbca311bfe1964e11ea6c73cc7562/docs/diagnostics-upload.md)); receiver retention is a recommendation, not independently verified hosted behavior. Obtain participant consent before meeting recording.

## Persistence, Retention, Export, Delete and Recovery

PostgreSQL holds business records, permissions and jobs; local workspaces and daemon SQLite retain execution state; artifacts/media add file storage. [apps/computer/local-daemon/internal/daemon/operation_ledger.go](https://github.com/simplexai-labs/linger/blob/cd0e23af6cacbca311bfe1964e11ea6c73cc7562/apps/computer/local-daemon/internal/daemon/operation_ledger.go) provides persisted operation handling. Reconnect replay and uncertain-action handling improve resilience but cannot undo external effects.

[apps/teamhub/internal/retention/retention.go](https://github.com/simplexai-labs/linger/blob/cd0e23af6cacbca311bfe1964e11ea6c73cc7562/apps/teamhub/internal/retention/retention.go) explicitly excludes business content—messages, room events, documents, wiki and recordings—from age deletion. [apps/teamhub/internal/store/queries/retention.sql](https://github.com/simplexai-labs/linger/blob/cd0e23af6cacbca311bfe1964e11ea6c73cc7562/apps/teamhub/internal/store/queries/retention.sql) cleans working data in bounded batches, including eligible 30-day document events and seven-day non-recording voice state. Disconnecting an app or deleting a chat must not be assumed to erase derived memory, logs, backups or provider copies.

[apps/teamhub/internal/document/export.go](https://github.com/simplexai-labs/linger/blob/cd0e23af6cacbca311bfe1964e11ea6c73cc7562/apps/teamhub/internal/document/export.go) validates media type, byte length, SHA-256 and asset/thread correspondence for Markdown, text, HTML or blocks exports. [apps/teamhub/internal/roomcreation/deletion.go](https://github.com/simplexai-labs/linger/blob/cd0e23af6cacbca311bfe1964e11ea6c73cc7562/apps/teamhub/internal/roomcreation/deletion.go) waits for membership revocation before finalizing a room deletion event. These are narrower lifecycle capabilities, not a demonstrated full-account export or secure-erasure contract.

No comprehensive, tested deployment backup/restore runbook was established in the reviewed documentation. Inventory the database, artifact/media files, daemon state, workspaces and encryption keys; take consistent backups and rehearse isolated restore. DB-only backup may omit files and cannot recover lost encryption keys. Update rollback is not data rollback.

## Claims Versus Evidence

| Claim | Evidence and limitation |
|---|---|
| “Claude-class” / 125B on 12 GB | README gives model/quantization-dependent measurements and admits simulated tiers and short/long-prompt differences. PolyStrata is a separate inference project. No speed/quality was reproduced; fitting offloaded weights does not establish equivalent agent performance. |
| 95% LoCoMo | A real benchmark harness exists, but the headline was not independently reproduced or tied here to a verified full result bundle. |
| Local/private | Local models are supported; remote runtimes, Composio, Soniox, xAI and optional diagnostics are explicit egress paths. |
| Safe actions | Connector approval and intercepted-tool review exist; Pi's missing review and full host execution preclude treating this as an isolation boundary. |

[apps/node-services/scripts/memory-benchmark/README.md](https://github.com/simplexai-labs/linger/blob/cd0e23af6cacbca311bfe1964e11ea6c73cc7562/apps/node-services/scripts/memory-benchmark/README.md) candidly states that benchmark tools bypass production TeamHub auth/CLI projection, model calls use a gateway, wiki timing differs and LoCoMo excludes adversarial category 5 under AMB. Extraction, answering and judging need configured models. Such results do not validate local-model quality, security or full desktop workflows. Run-to-run variance is explicitly acknowledged; comparison charts are not controlled end-to-end product evaluations.

## Dependencies, Install, Updates and Maturity

The workspace pins pnpm, requires Node 26, and includes lockfiles, Go sums, generated contracts and dependency build-script allowlists. Native dependencies include SQLite, image/media libraries, browser tooling and Electron. Patches to Hocuspocus, LiveKit, Deep Agents and an alpha Playwright build add compatibility maintenance. No advisory scan was run; locked versions do not establish safety. See [package.json](https://github.com/simplexai-labs/linger/blob/cd0e23af6cacbca311bfe1964e11ea6c73cc7562/package.json) and [pnpm-workspace.yaml](https://github.com/simplexai-labs/linger/blob/cd0e23af6cacbca311bfe1964e11ea6c73cc7562/pnpm-workspace.yaml).

Mac documentation describes unsigned packages and quarantine removal. SHA256SUMS establishes consistency only relative to a trusted manifest. [apps/computer/local-daemon/internal/selfupdate/stager.go](https://github.com/simplexai-labs/linger/blob/cd0e23af6cacbca311bfe1964e11ea6c73cc7562/apps/computer/local-daemon/internal/selfupdate/stager.go) downloads a server-advertised archive, bounds size, verifies hash and executes its installer. [apps/computer/local-daemon/internal/selfupdate/selfupdate.go](https://github.com/simplexai-labs/linger/blob/cd0e23af6cacbca311bfe1964e11ea6c73cc7562/apps/computer/local-daemon/internal/selfupdate/selfupdate.go) handles staged activation, confirmation and rollback. The server origin and manifest are code-distribution authorities; matching hashes are not independent publisher signatures.

[.github/workflows/ci.yml](https://github.com/simplexai-labs/linger/blob/cd0e23af6cacbca311bfe1964e11ea6c73cc7562/.github/workflows/ci.yml) provides path-aware gates, frontend shards and daemon Go checks. It explicitly leaves heavier node-services, voice, integration, container and E2E suites local. Many targeted tests address grants, confirmations, sessions and updates, but none ran here and no passing CI status is asserted.

Public GitHub metadata retrieved November 19 showed creation November 10, last push November 19, 1,382 stars, 98 forks and 38 open issues/PRs combined. The latest-release API identified desktop-v0.1.5; the source desktop manifest says 0.16.20, and release packaging can override it. Neither substitutes for the exact reviewed SHA. Recent PR listings include operation-ID handling after unreadable write responses. This is active, very young public software; popularity is not validation.

## License and Assets

Read [LICENSE](https://github.com/simplexai-labs/linger/blob/cd0e23af6cacbca311bfe1964e11ea6c73cc7562/LICENSE), not just the open-source headline. Outside-organization hosted/managed services need producer authorization/commercial licensing, and frontend logo/copyright removal is restricted. Internal commercial use is permitted subject to terms. These restrictions materially affect white-label and SaaS reuse.

[NOTICE](https://github.com/simplexai-labs/linger/blob/cd0e23af6cacbca311bfe1964e11ea6c73cc7562/NOTICE) separately identifies integration trademarks, Hindsight/Codex adaptations, MPL components, LGPL/possibly distribution-specific GPL media components, fonts and proprietary LiveKit model terms. Inference-model licenses remain independent. No upstream code or assets were extracted.

## Comparison

| Need | Alternative | Tradeoff |
|---|---|---|
| Desktop coworker | [OpenWorker](https://github.com/andrewyng/openworker), [review](openworker.md) | Compare permissions/recovery on identical tasks; Linger emphasizes integrated wiki, proactive work and documents. |
| Local coding workflow | [Magnitude](https://github.com/magnitudedev/magnitude), [review](magnitude.md), or a runtime plus local inference | Less personal-workspace breadth, fewer integrations to operate. |
| Memory component | [Hindsight](https://github.com/vectorize-io/hindsight) | Composable without adopting a full desktop/server product; not a computer-control replacement. |
| Collaborative knowledge | [Outline](https://github.com/outline/outline), [review](outline.md) | Different license/features, without adding general computer authority merely to maintain knowledge. |

These are fit comparisons, not fresh audits or benchmarks of alternatives.

## Self-Hosting / Adoption Gate

Start with synthetic data on a dedicated account, local-only inference and connectors/voice disabled. Test human confirmation, revocation, reconnect, ambiguous effects, provider spending and complete restore before real accounts. Verify the chosen runtime's actual policy behavior, especially Pi. Do not expose it as an untrusted multi-tenant service or assume the license permits managed hosting.

**Bottom line:** worth studying and carefully piloting for its server/host split, checked wiki and content-bound approvals. This static review does not justify a “fully private, safely autonomous, free Claude-class assistant” conclusion.

---
**Attribution:** simplexai-labs/linger; SIMPLEX AI TECHNOLOGIES PTE. LTD. Custom Linger license and component notices. Public-source independent analysis; no code redistribution.
