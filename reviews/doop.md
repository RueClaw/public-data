# Doop (kgoedecke/doop)

**Repo:** https://github.com/kgoedecke/doop
**Author:** Kevin Goedecke / kgoedecke and contributors
**License:** AGPL-3.0; preserve notices and satisfy corresponding-source obligations, including modified network-service versions. Dependencies retain their own terms.
**Reviewed:** 2026-11-20 (UTC)
**Revision:** b2b4536e066118829344bd1ae8264fa370093ea4 (main snapshot; package version 0.15.0). Scope: web/client, shared model, server/auth/MCP/providers/storage/rendering, deployment, tests/CI; selected desktop/extension boundaries, not exhaustive native-client audits.
**Verification:** Static source review only. No dependencies installed, application or tests run, accounts connected, live service probed, or paid calls made.
**Stack:** TypeScript, React/Vite/Zustand, Express/ws/MCP, Drizzle with PGlite/PostgreSQL, Puppeteer/Chromium; optional Tauri desktop and mobile clients.
**What it is:** A collaborative HTML design canvas for people and AI agents—not a duplicate-file tool. Agents edit the same frames that humans manipulate, through MCP or a built-in model-driven worker.

---

## Verdict

⚠️ **Interesting: a credible agent-native design workbench, not a confidential-design drop-in.** The shared human/agent mutation model, live rendering and inspect/screenshot feedback loop are unusually concrete. Pilot with non-sensitive designs first: unauthenticated asset/image URLs, optional plaintext credential storage, conditional session replay, asynchronous durability and a weak default Docker rendering boundary need explicit operational decisions.

## What It Is

Doop stores canvases containing pages and HTML frames, rather than converting a proprietary vector-document format into application code. The browser editor changes layout, typography, shapes and elements; MCP clients create and patch HTML, inspect computed geometry and take screenshots. WebSocket rooms carry presence, cursors, changes and task progress. Prototypes connect frames with declarative interactions; comments can queue agent work.

Its built-in agent is separate from an externally connected MCP client. External clients bring their own inference/account environment. Built-in runs use connected model accounts or an explicitly enabled server allowance. Design references, decisions, guidelines, reusable components and tokens persist alongside the work. The first-canvas welcome animation is scripted; it is not evidence of model output quality.

The README explicitly excludes Figma, Canva and PSD import/export from the open-source edition. Do not equate the public checkout with complete hosted-service parity. Sources: [README.md](https://github.com/kgoedecke/doop/blob/b2b4536e066118829344bd1ae8264fa370093ea4/README.md), [server/mcp.ts](https://github.com/kgoedecke/doop/blob/b2b4536e066118829344bd1ae8264fa370093ea4/server/mcp.ts), [server/resident.ts](https://github.com/kgoedecke/doop/blob/b2b4536e066118829344bd1ae8264fa370093ea4/server/resident.ts).

## Stack

| Layer | Implementation |
|---|---|
| Editor | React 18, Vite, Zustand, HTML iframe runtime, Tailwind/Radix |
| Application | Node via tsx, Express, ws, shared TypeScript actions |
| Agent interface | MCP SDK, stateless HTTP POST; built-in provider-specific agent loops |
| Persistence | Drizzle PostgreSQL dialect; PGlite without DATABASE_URL; PostgreSQL otherwise |
| Rendering/assets | Puppeteer-core + installed or remote Chromium, sharp, PDF tooling; local disk or S3-compatible objects |
| Identity | Better Auth email/password, optional social/OIDC, MCP OAuth and account agent keys |
| Packaging | Bun lockfile; Docker; separate Tauri/Rust and native mobile trees |

## Key Features

### One mutable design model for humans and agents

REST, MCP and resident workers converge on shared actions, rather than maintaining separate design documents. MCP exposes HTML editing, page management, component/token operations, prototype wiring, imports, inspect and screenshot tools. Browser rooms show progress live. This is useful for iterative UI composition; it does not prove fidelity to an arbitrary production app. Evidence: [server/actions.ts](https://github.com/kgoedecke/doop/blob/b2b4536e066118829344bd1ae8264fa370093ea4/server/actions.ts), [server/mcp.ts](https://github.com/kgoedecke/doop/blob/b2b4536e066118829344bd1ae8264fa370093ea4/server/mcp.ts), [shared/types.ts](https://github.com/kgoedecke/doop/blob/b2b4536e066118829344bd1ae8264fa370093ea4/shared/types.ts).

### Visual verification and design memory

Agents can render their frame and inspect computed layout for overflow, clipping and overlap. Those are candidate problems, not an automated aesthetic oracle. Guidelines, pinned references and recorded decisions provide persistent design context. Imported website content, comments and memory remain untrusted model inputs: tool schemas and budgets constrain actions, but do not solve prompt injection. Evidence: [server/screenshot.ts](https://github.com/kgoedecke/doop/blob/b2b4536e066118829344bd1ae8264fa370093ea4/server/screenshot.ts), [server/guide.ts](https://github.com/kgoedecke/doop/blob/b2b4536e066118829344bd1ae8264fa370093ea4/server/guide.ts), [server/workBudget.ts](https://github.com/kgoedecke/doop/blob/b2b4536e066118829344bd1ae8264fa370093ea4/server/workBudget.ts).

### Actual collaboration, with a centralized authority

Canvas access distinguishes view/comment/edit and durable membership. Owners, invited members and workspace members edit; share-link permissions are weaker and separately checked. Signed-out visitors can view link-shared canvases, with team conversations omitted. Ownerless legacy canvases intentionally permit editing. The server—not a peer-to-peer CRDT—is authoritative. Evidence: [server/access.ts](https://github.com/kgoedecke/doop/blob/b2b4536e066118829344bd1ae8264fa370093ea4/server/access.ts), [server/index.ts](https://github.com/kgoedecke/doop/blob/b2b4536e066118829344bd1ae8264fa370093ea4/server/index.ts).

## Architecture and durability

The Express process owns in-memory maps and WebSocket rooms. Metadata hydrates from the database; frame HTML loads per canvas. Shared actions update memory, schedule persistence and broadcast. A journal queues external effects until an operation commits and can undo changes on failure; its own documentation explicitly disclaims isolation across awaited work. This is an application transaction mechanism, not proof of serializable database transactions. Multiple independent application replicas would need coordination not established by this review. Evidence: [server/store.ts](https://github.com/kgoedecke/doop/blob/b2b4536e066118829344bd1ae8264fa370093ea4/server/store.ts), [server/frameHtml.ts](https://github.com/kgoedecke/doop/blob/b2b4536e066118829344bd1ae8264fa370093ea4/server/frameHtml.ts), [server/journal.ts](https://github.com/kgoedecke/doop/blob/b2b4536e066118829344bd1ae8264fa370093ea4/server/journal.ts).

Persistence deserves particular care. Ordinary mutations mirror asynchronously; general write failures are logged. Frames debounce for 400 ms, track dirty generations, remain loaded while unsaved, and retry failed writes during idle sweeping. A flush path and queued version writes exist; canvas duplication explicitly awaits a database transaction. These are real mitigations, but a UI-visible update is not automatically a durable commit, and process death can lose pending state. Do not describe this as a crash-proof collaborative database. Evidence: [server/db/persist.ts](https://github.com/kgoedecke/doop/blob/b2b4536e066118829344bd1ae8264fa370093ea4/server/db/persist.ts).

Frame and guideline versions cap at 50 each. The hydrated log window is 100 entries per canvas for relevant histories; this is not a comprehensive retention/deletion policy. Export includes HTML-oriented workflows and PNG/JPG/vector PDF, not an independently verified full-instance backup/restore interchange. Account deletion removes private owned canvases but deliberately preserves shared/workspace canvases. No restore drill was performed. Back up the database, object bytes and encryption key material as one recoverable system. Evidence: [server/db/persist.ts](https://github.com/kgoedecke/doop/blob/b2b4536e066118829344bd1ae8264fa370093ea4/server/db/persist.ts), [server/accountDeletion.ts](https://github.com/kgoedecke/doop/blob/b2b4536e066118829344bd1ae8264fa370093ea4/server/accountDeletion.ts), [server/storage.ts](https://github.com/kgoedecke/doop/blob/b2b4536e066118829344bd1ae8264fa370093ea4/server/storage.ts), [README.md](https://github.com/kgoedecke/doop/blob/b2b4536e066118829344bd1ae8264fa370093ea4/README.md).

## Security and privacy boundaries

### Authentication is not the same as asset confidentiality

MCP tools require OAuth or a revocable account-scoped bearer key; agent keys are stored as SHA-256 hashes of high-entropy secrets. They resolve to the human's access, not a separate per-canvas least-privilege identity. Anonymous MCP discovery is limited to static resource discovery/ping. Bans are checked beyond token validity. REST/room/tool permissions share canvas-role helpers, and admin access is deliberately separated from ordinary MCP authorization. These are positive controls, not a complete endpoint audit. Evidence: [server/agentKeys.ts](https://github.com/kgoedecke/doop/blob/b2b4536e066118829344bd1ae8264fa370093ea4/server/agentKeys.ts), [server/mcp.ts](https://github.com/kgoedecke/doop/blob/b2b4536e066118829344bd1ae8264fa370093ea4/server/mcp.ts), [server/auth.ts](https://github.com/kgoedecke/doop/blob/b2b4536e066118829344bd1ae8264fa370093ea4/server/auth.ts), [server/access.ts](https://github.com/kgoedecke/doop/blob/b2b4536e066118829344bd1ae8264fa370093ea4/server/access.ts).

**Frame images and uploaded assets are deliberately public by unguessable ID.** The /i/:id image handler checks frame existence, not canvas membership, and renders the current design. The /a/:id asset handler similarly omits membership checks, permits cross-origin loads and advertises one-year immutable caching. Thus a private canvas does not make a leaked asset/image URL private; turning off its share link is not equivalent to revoking those URLs or cached copies. This is observable route design, not a claimed live exploit. Evidence: [server/index.ts](https://github.com/kgoedecke/doop/blob/b2b4536e066118829344bd1ae8264fa370093ea4/server/index.ts) (public images/assets routes).

### Credential encryption must be configured

Model/integration credentials can be AES-256-GCM sealed with per-write random IVs and a versioned key ID. Rotation/backfill is implemented. **Production without SECRETS_ENCRYPTION_KEYS stores these credentials as plaintext and only warns at boot.** Development uses a fixed test key. Better Auth social OAuth tokens have a separate encryption setting backed by the auth secret. Server compromise still exposes usable credentials; this is at-rest protection, not end-to-end encryption. The supplied Compose environment does not forward the secret-encryption setting, so merely defining it outside the container is insufficient unless deployment wiring is changed. Evidence: [server/secretBox.ts](https://github.com/kgoedecke/doop/blob/b2b4536e066118829344bd1ae8264fa370093ea4/server/secretBox.ts), [server/secretBackfill.ts](https://github.com/kgoedecke/doop/blob/b2b4536e066118829344bd1ae8264fa370093ea4/server/secretBackfill.ts), [server/env.ts](https://github.com/kgoedecke/doop/blob/b2b4536e066118829344bd1ae8264fa370093ea4/server/env.ts), [server/auth.ts](https://github.com/kgoedecke/doop/blob/b2b4536e066118829344bd1ae8264fa370093ea4/server/auth.ts), [docker-compose.yml](https://github.com/kgoedecke/doop/blob/b2b4536e066118829344bd1ae8264fa370093ea4/docker-compose.yml).

### Replay is conditional, but potentially content-rich

Without a build-time PostHog key, client analytics is disabled. When enabled, the code initializes session recording with cross-origin iframe recording, maskAllInputs false, and password/email masking; its comments explicitly include prompt/comment visibility. A same-origin relay is designed to avoid ordinary analytics-host blocking. Internal-domain and impersonation exclusions exist. Self-hosting alone therefore does not establish zero analytics egress; inspect the built bundle configuration and obtain appropriate consent. This review does not establish whether the hosted service currently enables recording. Evidence: [src/lib/posthog.ts](https://github.com/kgoedecke/doop/blob/b2b4536e066118829344bd1ae8264fa370093ea4/src/lib/posthog.ts), [src/lib/frameReplay.ts](https://github.com/kgoedecke/doop/blob/b2b4536e066118829344bd1ae8264fa370093ea4/src/lib/frameReplay.ts), [Dockerfile](https://github.com/kgoedecke/doop/blob/b2b4536e066118829344bd1ae8264fa370093ea4/Dockerfile).

### HTML sandboxing and server-side rendering are different boundaries

Editor/prototype frames use sandbox=allow-scripts without allow-same-origin, preventing normal same-origin access to the parent. That is not a blanket network-denial policy or proof that arbitrary HTML is harmless. Server rendering and website import execute web content in Chromium. Public-URL helpers reject private/literal/resolved network ranges, pin DNS for Node fetches, validate browser resources, impose byte budgets and block unsupported transports. Custom model endpoints require public HTTPS and reject redirects unless an operator explicitly enables private hosts. Declaring a remote renderer isolated changes enforcement and must reflect real network separation. Evidence: [src/components/FrameView.tsx](https://github.com/kgoedecke/doop/blob/b2b4536e066118829344bd1ae8264fa370093ea4/src/components/FrameView.tsx), [src/components/PrototypePlayer.tsx](https://github.com/kgoedecke/doop/blob/b2b4536e066118829344bd1ae8264fa370093ea4/src/components/PrototypePlayer.tsx), [server/publicUrl.ts](https://github.com/kgoedecke/doop/blob/b2b4536e066118829344bd1ae8264fa370093ea4/server/publicUrl.ts), [server/customProviderFetch.ts](https://github.com/kgoedecke/doop/blob/b2b4536e066118829344bd1ae8264fa370093ea4/server/customProviderFetch.ts).

The Dockerfile enables CHROME_NO_SANDBOX and specifies no non-root USER. A container with Chromium's own sandbox disabled should not be treated as a strong hostile-document execution boundary. Use a deliberately isolated renderer/network and resource policy before accepting untrusted public workloads. No browser escape or SSRF exploit was tested. Evidence: [Dockerfile](https://github.com/kgoedecke/doop/blob/b2b4536e066118829344bd1ae8264fa370093ea4/Dockerfile), [server/screenshot.ts](https://github.com/kgoedecke/doop/blob/b2b4536e066118829344bd1ae8264fa370093ea4/server/screenshot.ts).

### Optional native integrations widen trust

The desktop app wraps a chosen server and grants its origin native IPC capabilities. Its local Claude worker asks consent, runs an installed CLI in a temporary directory, disables built-in tools/settings/hooks/slash commands, and permits only the run's Doop MCP tools. This is materially narrower than an unrestricted shell agent, but depends on CLI behavior and trusts server-supplied work plus the native bridge. A separate Gemini worker also spawns a CLI with core tools/extensions/hooks disabled. Desktop updates use the Tauri updater and configured signing key; release builds check/download in the background. The Chrome capture extension requests activeTab, scripting and clipboardWrite—not unrestricted persistent all-site access in its manifest. None was installed or exercised. Evidence: [desktop/src-tauri/src/server.rs](https://github.com/kgoedecke/doop/blob/b2b4536e066118829344bd1ae8264fa370093ea4/desktop/src-tauri/src/server.rs), [desktop/src-tauri/src/claude.rs](https://github.com/kgoedecke/doop/blob/b2b4536e066118829344bd1ae8264fa370093ea4/desktop/src-tauri/src/claude.rs), [desktop/src-tauri/src/updates.rs](https://github.com/kgoedecke/doop/blob/b2b4536e066118829344bd1ae8264fa370093ea4/desktop/src-tauri/src/updates.rs), [server/geminiCloudWorker.ts](https://github.com/kgoedecke/doop/blob/b2b4536e066118829344bd1ae8264fa370093ea4/server/geminiCloudWorker.ts), [chrome-extension/manifest.json](https://github.com/kgoedecke/doop/blob/b2b4536e066118829344bd1ae8264fa370093ea4/chrome-extension/manifest.json).

## Providers, data flows and costs

Built-in model adapters cover Anthropic, OpenAI, Gemini and Chat Completions-compatible providers, with custom endpoints behind explicit controls. Prompts, relevant design context, tool results and screenshots/images may leave the instance for the selected provider. Optional rendering, object storage, email, image search/generation, GitHub, Slack and Linear integrations add their own destinations and retention policies. External MCP clients also decide what they send to their models. A local canvas database is not local inference.

The server free-task allowance defaults to zero; connected user accounts or explicitly funded server keys enable real agent runs. Agent turns, image generation/description, remote rendering and storage can incur separate costs. Tool rate limits and work budgets are useful controls, not a universal money-denominated spending cap. Provider rates and hosted subscription prices were not independently verified.

The ChatGPT connection reuses Codex OAuth registration, with loopback, device and pasted-callback variants. The source itself warns that third-party-server subscription use is not sanctioned and may cause rate limits/suspension. Treat that as the maintainer's compatibility/terms warning, not an independent legal determination; prefer documented API-key arrangements for predictable operations. Evidence: [server/modelAccounts.ts](https://github.com/kgoedecke/doop/blob/b2b4536e066118829344bd1ae8264fa370093ea4/server/modelAccounts.ts), [server/agentModel.ts](https://github.com/kgoedecke/doop/blob/b2b4536e066118829344bd1ae8264fa370093ea4/server/agentModel.ts), [server/env.ts](https://github.com/kgoedecke/doop/blob/b2b4536e066118829344bd1ae8264fa370093ea4/server/env.ts), [server/imageGen.ts](https://github.com/kgoedecke/doop/blob/b2b4536e066118829344bd1ae8264fa370093ea4/server/imageGen.ts), [server/mcp.ts](https://github.com/kgoedecke/doop/blob/b2b4536e066118829344bd1ae8264fa370093ea4/server/mcp.ts).

## Self-Hosting Notes

1. Start with non-sensitive sample designs on a restricted instance; configure production auth origin/secret, TLS, signup policy and real SMTP/SSO as appropriate. Development origin trust is deliberately permissive.
2. Configure and verify credential encryption inside the actual process/container. Preserve old rotation keys until data and backups remain recoverable.
3. Persist both database and assets. The supplied Compose file persists PostgreSQL, but gives the app no volume for its default disk assets: container recreation can discard uploaded files while database references survive. Add durable object storage or an appropriate app-data volume; do not mistake the database volume for a complete backup.
4. Isolate Chromium and egress; decide whether public-by-ID media is acceptable. For confidential material, redesign/access-gate delivery rather than relying on obscure IDs.
5. Keep PostHog disabled unless deliberately approved; audit every provider/integration destination. Use external provider-side spending controls.
6. Pin reviewed builds and lockfile, back up before boot migrations, and test restoration before upgrades. No deployment was attempted here.

Sources: [docker-compose.yml](https://github.com/kgoedecke/doop/blob/b2b4536e066118829344bd1ae8264fa370093ea4/docker-compose.yml), [Dockerfile](https://github.com/kgoedecke/doop/blob/b2b4536e066118829344bd1ae8264fa370093ea4/Dockerfile), [server/storage.ts](https://github.com/kgoedecke/doop/blob/b2b4536e066118829344bd1ae8264fa370093ea4/server/storage.ts), [server/db/index.ts](https://github.com/kgoedecke/doop/blob/b2b4536e066118829344bd1ae8264fa370093ea4/server/db/index.ts), [server/auth.ts](https://github.com/kgoedecke/doop/blob/b2b4536e066118829344bd1ae8264fa370093ea4/server/auth.ts).

## Dependencies, licensing and maturity

The repository is substantial rather than a tiny demo: 389 top-level test files matching *.test.* were counted, including access, SSRF/public URL, secret-box, custom-provider, journal, persistence and version-burst tests. CI config runs typecheck, lint/format/doc checks, build and four Vitest shards with pinned Chrome. This establishes test coverage intent, not passing results for this SHA: no suite or CI-run outcome was independently verified. Package install includes a prepare hook; build packages a Claude extension. Bun's frozen lockfile improves repeatability, while semver-ranged dependencies, tag-referenced Actions, floating Docker base tags and distro Chromium still require supply-chain review. No vulnerability database audit was performed. Evidence: [package.json](https://github.com/kgoedecke/doop/blob/b2b4536e066118829344bd1ae8264fa370093ea4/package.json), [bun.lock](https://github.com/kgoedecke/doop/blob/b2b4536e066118829344bd1ae8264fa370093ea4/bun.lock), [.github/workflows/ci.yml](https://github.com/kgoedecke/doop/blob/b2b4536e066118829344bd1ae8264fa370093ea4/.github/workflows/ci.yml), [tests/publicUrl.test.ts](https://github.com/kgoedecke/doop/blob/b2b4536e066118829344bd1ae8264fa370093ea4/tests/publicUrl.test.ts), [tests/secretBox.test.ts](https://github.com/kgoedecke/doop/blob/b2b4536e066118829344bd1ae8264fa370093ea4/tests/secretBox.test.ts).

Public GitHub metadata checked 2026-11-20 reported creation 2026-08-22, last push 2026-11-19, 2,208 stars, 280 forks and 107 open issues/PRs combined. Latest release returned was v0.15.0, published 2026-11-16; the reviewed main SHA is not claimed to be that release commit. Rapid activity and wide surface area suggest a young, fast-changing product, not demonstrated long-term operational stability. Metadata: [repository API](https://api.github.com/repos/kgoedecke/doop), [release](https://github.com/kgoedecke/doop/releases/tag/v0.15.0).

The actual LICENSE is AGPL v3. The contributor agreement grants broad relicensing rights to the maintainer, including proprietary terms; that does not remove recipients' obligations for existing AGPL code. Hosted-only features are a separate product boundary. This review extracts no implementation code and does not provide legal advice. Evidence: [LICENSE](https://github.com/kgoedecke/doop/blob/b2b4536e066118829344bd1ae8264fa370093ea4/LICENSE), [CLA.md](https://github.com/kgoedecke/doop/blob/b2b4536e066118829344bd1ae8264fa370093ea4/CLA.md), [README.md](https://github.com/kgoedecke/doop/blob/b2b4536e066118829344bd1ae8264fa370093ea4/README.md).

## Comparison

| Option | Practical distinction |
|---|---|
| Doop | Best fit when agents and humans should co-edit real HTML frames with MCP and visual feedback, and operators accept a young self-hosted application. |
| Paper.design | Closest stated product comparator for HTML-oriented design; compare current integration/pricing terms separately. Doop offers an inspectable AGPL server rather than assumed hosted parity. |
| Penpot | Consider for a conventional open-source collaborative design/document workflow; evaluate format and handoff needs rather than expecting Doop's exact HTML/MCP interaction model. |
| Figma | Consider when established design-file and team-tool compatibility is primary. Doop's README explicitly places Figma conversion in its hosted-only offering. |
| Plain HTML + browser preview + coding agent | Simpler for a solo developer who does not need multiplayer canvas, design memory or collaboration administration; fewer credentials and storage systems to operate. |

These are workflow alternatives, not newly benchmarked product comparisons. **Practical call:** pilot Doop for disposable or low-sensitivity design work; study its shared mutation and agent feedback patterns. Hold a confidential multi-user rollout until media access, encryption, replay, renderer containment, durable asset storage and restore behavior are verified in the intended deployment.

---

**Attribution:** Kevin Goedecke / kgoedecke/doop and contributors, AGPL-3.0. Independent public-source analysis at the exact revision above; no private user or infrastructure data used.
