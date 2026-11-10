# LibrePaper (LibrePaper/librepaper)

**Repo:** https://github.com/LibrePaper/librepaper
**License:** MIT, copyright 2026 Vincent Arel-Bundock; retain copyright and permission notices. Renderer, font and other dependency terms remain separate.
**Reviewed:** 2026-11-10 (UTC)
**Revision:** `2c58e8aff047dad024b8ec18aa26156f28cda87e` (main snapshot; application, web, desktop, deployment and test definitions). Commit dated 2026-11-09. Latest public release observed: v0.0.71, published 2026-11-09, targeting a different revision.
**Verification:** Static source review; no application builds, tests, installs, accounts, native tools, model calls or live deployment probes. Public GitHub metadata and upstream CI status checked separately.
**Stack:** Rust, Axum/Tokio, PostgreSQL, Loro CRDT, Svelte 5/CodeMirror 6, browser WebAssembly, Tauri 2.
**What it is:** A collaborative source-writing, annotation and publishing platform for HTML, Markdown, Typst, LaTeX and Quarto projects—not a PDF library or a general office-suite replacement.

---

## Verdict

⚠️ **Interesting: pilot for technical writing, not a default destination for sensitive work.** LibrePaper has substantial collaboration, authorization and recovery engineering, plus useful source portability. Its desktop integration deliberately gives a trusted server access to native tools running as the user; hosted documents are not end-to-end encrypted, and project ZIP copies are not full-fidelity backups. Start browser-only with non-sensitive material and test your exact rendering and restore workflows before expanding trust.

## What It Is

Authors edit multi-file projects, render previews, invite readers or collaborators, attach source-linked comments and propose tracked edits. The browser and desktop app use the same server and account. Desktop adds native renderers, executable Quarto/R/Python workflows, Zotero integration, Git transfer, scheduled source copies and installed coding agents. AI is optional rather than the server's core writing engine. [S1, S3, S6]

The README's “one static binary” describes application packaging, not a complete production deployment. The documented kit includes Caddy, LibrePaper, PostgreSQL and a backup sidecar, plus DNS, TLS, identity-provider registration and separately configured backup storage. [S1, S8]

## Stack

| Layer | Implementation |
|---|---|
| HTTP and realtime | Rust Axum/Tokio routes and WebSockets; room-level document operations |
| Collaborative source | Loro document maps for text, paths, assets and metadata; shared native/browser substrate |
| Durable data | PostgreSQL catalog, logs, comments and history; immutable object blobs on disk or S3-compatible storage |
| Web | Svelte 5, CodeMirror 6, Vite, Loro JS, PDF.js; pinned WASM rendering assets |
| Desktop/local | Tauri shell and authenticated loopback companion; native renderer and ACP agent subprocesses |
| Identity/automation | OAuth/OIDC sessions; share capabilities; scoped agent tokens; stdio MCP and HTTPS document tools |

## Key Features

### Source-first collaboration with stable file identities

The document separates opaque file IDs from paths. Renames therefore do not inherently orphan comments; assets are addressed by digest, and source is authoritative rather than rendered HTML. PostgreSQL holds update logs with compressed base snapshots and compaction. Browser IndexedDB persistence appends deltas and compacts them, providing local recovery for opened editor projects. This is meaningful implementation, not just a realtime-editing claim. It does not prove every disconnected merge or annotation survives correctly. [S2]

### Several formats, not universal interchange

Browser rendering chooses PDF for LaTeX/Typst and flow HTML for Markdown/Quarto/HTML. Quarto's browser path explicitly implements a subset: it does not execute code, filters, shortcodes or JavaScript. Full Quarto work needs the native toolchain. Browser LaTeX availability depends on a configured asset mirror. Native command records expose selected PDF/HTML/DOCX outputs, with configurable commands; DOCX output is not evidence of Word track-change/comment round-tripping or DOCX authoring support. [S3]

CLI export captures text and digest-verified assets into a new directory, stages before publishing the result, and refuses an existing destination. Historical export requests a named-version archive. These are independent source snapshots, not a live sync folder and not a portable copy of all review state. Git transfer is separate: the sync crate tracks base state, pending pushes, conflict refusals and source-change operations. The README's narrow CLI summary does not capture all of the newer Git workflow documented elsewhere. [S4]

### Agent integration with actual tool-side authority

External tokens are scoped to one project and Read/Comment/Edit permissions; Edit includes direct edits and file creation/deletion, not only suggestions. The server rechecks authorization at mutation time rather than relying solely on a previously admitted request. Built-in desktop delegation uses a five-minute document/link grant and rejects bearer-based or cross-origin attempts to mint it. Runtime permission logic refuses stale/cancelled turns, auto-allows permitted LibrePaper tools during a live task and asks for other requests. These controls constrain LibrePaper authority, not everything an independently installed agent can do. [S5]

## Architecture

The workspace separates base utilities/protocols, document representation, persistence engine, live rooms, HTTP server, CLI, companion and Git sync. The web shell is embedded in the application build, while browser rendering engines are consumed from sibling LibrePaper WASM repositories via asset pins. A production request flows through origin resolution and identity/access checks to room/storage operations; the desktop shell separately mediates local-feature requests into its loopback service. [S2, S3, S5, S6]

Particularly useful patterns are typed authorization rungs with mutation-time revalidation, immutable object references in backups, source-based comment identity, staged exports, and distinct render-success versus fresh-output checks. Bound process lifetime/output and rejecting stale outputs are good reliability measures, but not sandboxing. [S4–S7]

## Security, Permissions and Privacy

### The decisive desktop trust boundary

The local service uses a private per-instance bearer credential, validates the configured server origin, rejects ordinary browser-origin requests, checks Host, and proves possession of its control token during discovery. The shell only forwards trusted-origin requests. This is substantially better than an unauthenticated browser-accessible localhost API. [S6]

**However, the trusted server is an execution authority.** Native rendering constructs a subprocess in the project workspace and passes it to a bounded supervisor. The supervisor explicitly states that it is process hygiene, not a security boundary, and runs with the caller's permissions. The Run code switch lives in the served page: the architecture documentation explicitly acknowledges that a compromised server or injected application script can start builds without that switch, and that collaborative documents can execute collaborators' code locally. A “confined runner” phrase in a render-module comment must not be read as an OS sandbox guarantee. Local working-directory/path validation does not prevent a Quarto program from accessing other files or the network. [S6]

Use the browser when native execution is unnecessary. For untrusted executable projects, use a separately isolated account or disposable environment with no valuable credentials; do not equate a server-origin allowlist with trustworthy project contents. This review did not attempt an exploit.

### Authentication and capability handling

Self-hosting supports GitHub, Google, Entra, ORCID and configured OIDC providers. Provider policy controls publishing/commenting; the sample enables any GitHub account as a publisher, so restrict it for a private deployment. Identity-provider disablement does not immediately invalidate existing application sessions. Sessions default to 30 days; logout clears the browser cookie but does not revoke a copied session. These are documented lifecycle limits, not claims of a bypass discovered here. [S5, S8, S9]

Read links expose source files as well as the rendered document. Comment/edit links require sign-in in the documented hosted policy. Share links and agent tokens are bearer capabilities: pasting agent connection instructions into model chat exposes the token to that provider and retained chat history. Environment/MCP configuration avoids the chat copy but remains sensitive local state. The CLI has an origin-keyed JSON token cache; that is not an OS-keychain guarantee. [S5, S9]

### Network and provider flows

The application and published-document origins must use different hosts, not merely different ports. The server rejects an identical-host configuration. This protects application cookies/DOM from active document content, but published HTML can still load external resources and contact third parties; it is not a network-isolation or anti-tracking promise. [S5, S9]

Hosted operators can read documents: no end-to-end encryption. The hosted privacy policy says data/backups are in Canada, no access logs/IP retention, and aggregate operational metrics are retained for 400 days. These are operator statements, not audited deployment facts. Browser asset/LaTeX mirror requests reveal IP and requested packages; embedded remote resources reveal reader traffic. Agents run locally but their selected AI service sees the content they read. Git uses the user's existing helper or SSH identity; the application does not need a new central GitHub credential to sync. [S4, S9]

No model service is required for ordinary editing. Optional agents bring their own credentials, subscriptions/API costs and provider retention policies. Adapter installation/fallback acquisition adds npm supply-chain trust. Self-hosting still incurs server, database, storage, egress and backup costs; there is no validated operating-cost benchmark here. [S8, S9]

## Persistence, Retention and Recovery

- **Live state:** PostgreSQL plus referenced objects must be backed up together. The session-signing key and deployment credentials also need protected recovery copies. Source history and named versions persist until deletion/trim; chat has its own retention behavior. [S2, S7, S8]
- **Browser state:** opened editor projects and caches remain on the device; clearing site storage removes local copies. Revoking server access is not remote erasure of downloaded data. [S2, S9]
- **Desktop ZIP copies:** only the latest ZIP per project is retained; source/assets only, no comments/history, and only server-saved changes. Restore imports a new project. Turning backups off or deleting the project leaves existing ZIPs on disk; shared projects can be included. [S7]
- **Server backups:** the implementation captures a consistent PostgreSQL snapshot and immutable referenced objects, records lengths/digests and verifies them. Importantly, it can report a “verified backup” while recording and warning about missing objects already absent from the source. Check the manifest's missing list; verified copied bytes are not proof of a complete original dataset. The standalone admin backup command does not itself encrypt or schedule copies. [S7]
- **Hosted retention policy:** inactive accounts are erased after 365 days without warning email; their owned shared documents go too. Deleted projects ordinarily spend seven days in trash. Offsite retained backups may preserve deleted data for about eleven weeks, longer if backup jobs stop. Other people's comments/chat attributed to an erased user may remain as “Deleted user.” These hosted settings are not universal self-hosting defaults. [S9]

Test full restore and source-only import separately. Restoring an older server backup can resurrect state predating deletion; the documented restore does not independently replay account-erasure requests. [S2, S7]

## Self-Hosting and Update Notes

A maintained PostgreSQL deployment, object data, two public hosts, HTTPS and at least one OAuth/OIDC provider are operational requirements. The bundled deployment helper validates candidate configuration, checks readiness and preserves settings during upgrades. Schema migrations run at startup; the helper refuses downgrade, so rollback is a restore/migration compatibility problem rather than simply selecting an older image. [S8]

Release kits pin LibrePaper images by digest; PostgreSQL/Caddy use version tags. Upgrade attestation verification uses a pinned cosign image, but the simple first-install download/extract recipe does not itself verify the first kit. Verify initial provenance before executing it, and avoid the explicit unverified/skip-backup escape hatches. Tauri updater configuration contains a verification public key and GitHub release endpoint; release workflows describe signed Windows and signed/notarized macOS packaging. No downloaded binary signature was independently checked. [S8, S10]

CLI targets include Linux x86-64/aarch64, macOS Intel/Apple Silicon and Windows x86-64; native desktop builds need platform webview/tooling. Optional desktop rendering requires installed LaTeX/Typst/Quarto and relevant R/Python dependencies; Claude/Codex adapters require Node.js 22+. Browser WASM packaging does not imply complete offline operation or renderer parity. [S1, S3, S10]

## License, Dependencies, Tests and Maturity

The actual root MIT license permits reuse with its notice. The vendored CodeMirror visual-markup notice is retained; fonts, photo assets, WASM engines and transitive packages need their own license inventory. Cargo/Bun and browser asset lockfiles support reproducibility; digest-pinned WASM assets are a useful supply-chain control, not a review of the sibling renderer implementations. No dependency vulnerability scan or full license audit was performed. [S1, S10]

Public metadata observed on 2026-11-10: created 2026-09-02, 111 stars, 5 forks, 15 open issues/PRs combined, last push 2026-11-10. Latest release v0.0.71 was published November 9. These indicate a young, actively changing project, not production reliability. The reviewed main SHA is distinct from the release target. [M1, M2]

CI defines Rust formatting/lint/tests, browser tests, PostgreSQL integration, SQLx cache checking, backup-sidecar restore drills, deploy-kit exercises and platform companion checks. PostgreSQL-dependent tests can skip when not configured; the dedicated job matters. The workflow explicitly omits a Quarto PDF-preview integration case after unexplained runner termination, retaining a separate native rendering test. Some Actions use moving version tags rather than commit pins. [S10]

GitHub reports the `ci` run for the exact reviewed SHA as completed/successful: [run 42692194050](https://github.com/LibrePaper/librepaper/actions/runs/42692194050). This is upstream execution evidence, not tests run by this review, nor proof that every optional path executed. No performance, accessibility, concurrency, security or round-trip claim was independently reproduced.

## Comparison

| Need | LibrePaper | Alternative to evaluate |
|---|---|---|
| Collaborative LaTeX-first writing | Multiple source formats and agent/comment workflow | [Overleaf](https://github.com/overleaf/overleaf) for a LaTeX-focused collaboration ecosystem |
| Lightweight shared Markdown | More rendering formats, history and desktop integration; more operational scope | [HedgeDoc](https://github.com/hedgedoc/hedgedoc) for Markdown-centered collaboration |
| Reproducible computational publishing | Browser subset plus native Quarto execution; collaboration built in | [Quarto](https://github.com/quarto-dev/quarto-cli) plus Git for source-native publishing with an explicitly owned execution environment |

These are fit comparisons, not comparative security tests. Prefer LibrePaper when source-linked review across several scientific-writing formats is the differentiator. Prefer established format-specific tooling when exact compatibility or simpler trust boundaries matter more. Do not treat any of these as proof of Office-format fidelity.

## Verification Scope and Adoption Gates

Inspected manifests, core origin/access and agent-delegation paths, desktop forwarding/control authentication, native rendering/process supervision, source export/sync, offline persistence, backup implementation, deployment documentation and CI definitions. No source code was executed. Renderer sibling repositories, production configuration, full dependency graph, binary attestations and end-to-end behavior were not audited.

Before adopting: (1) test representative projects and export fidelity, (2) exercise disconnect/reconnect and comment anchoring, (3) prove complete server restore including missing-object handling, (4) shorten/restrict identity and sharing authority, and (5) decide explicitly whether the server and every coauthor may influence native code run on your computer.

## Evidence

All S-links refer to the exact reviewed commit; paths within each group identify supporting implementation and documentation.

- **S1 — Identity/packaging:** [README](https://github.com/LibrePaper/librepaper/blob/2c58e8aff047dad024b8ec18aa26156f28cda87e/README.md), [Cargo manifest](https://github.com/LibrePaper/librepaper/blob/2c58e8aff047dad024b8ec18aa26156f28cda87e/Cargo.toml), [LICENSE](https://github.com/LibrePaper/librepaper/blob/2c58e8aff047dad024b8ec18aa26156f28cda87e/LICENSE).
- **S2 — State model:** [document/storage](https://github.com/LibrePaper/librepaper/blob/2c58e8aff047dad024b8ec18aa26156f28cda87e/docs/architecture/document.md), [offline persistence](https://github.com/LibrePaper/librepaper/blob/2c58e8aff047dad024b8ec18aa26156f28cda87e/web/src/lib/offline-persistence.js).
- **S3 — Render paths:** [renderers.js](https://github.com/LibrePaper/librepaper/blob/2c58e8aff047dad024b8ec18aa26156f28cda87e/web/src/lib/renderers.js), [Quarto subset](https://github.com/LibrePaper/librepaper/blob/2c58e8aff047dad024b8ec18aa26156f28cda87e/web/src/lib/engines/quarto.js), [native command records](https://github.com/LibrePaper/librepaper/blob/2c58e8aff047dad024b8ec18aa26156f28cda87e/crates/librepaper-companion/src/local/render/tool.rs).
- **S4 — Portability:** [export](https://github.com/LibrePaper/librepaper/blob/2c58e8aff047dad024b8ec18aa26156f28cda87e/crates/librepaper/src/cli/export.rs), [sync push](https://github.com/LibrePaper/librepaper/blob/2c58e8aff047dad024b8ec18aa26156f28cda87e/crates/librepaper-sync/src/push.rs), [Git guide](https://github.com/LibrePaper/librepaper/blob/2c58e8aff047dad024b8ec18aa26156f28cda87e/docs/git.md).
- **S5 — Authority:** [access guard](https://github.com/LibrePaper/librepaper/blob/2c58e8aff047dad024b8ec18aa26156f28cda87e/crates/librepaper-server/src/server/access.rs), [origin checks](https://github.com/LibrePaper/librepaper/blob/2c58e8aff047dad024b8ec18aa26156f28cda87e/crates/librepaper-server/src/server/origins.rs), [desktop grants](https://github.com/LibrePaper/librepaper/blob/2c58e8aff047dad024b8ec18aa26156f28cda87e/crates/librepaper-server/src/server/agent_auth.rs), [runtime permissions](https://github.com/LibrePaper/librepaper/blob/2c58e8aff047dad024b8ec18aa26156f28cda87e/crates/librepaper-companion/src/assistant/runtime.rs), [sign-in/logout](https://github.com/LibrePaper/librepaper/blob/2c58e8aff047dad024b8ec18aa26156f28cda87e/crates/librepaper-server/src/server/signin.rs).
- **S6 — Native trust:** [local-service architecture](https://github.com/LibrePaper/librepaper/blob/2c58e8aff047dad024b8ec18aa26156f28cda87e/docs/architecture/local-service.md), [render execution](https://github.com/LibrePaper/librepaper/blob/2c58e8aff047dad024b8ec18aa26156f28cda87e/crates/librepaper-companion/src/local/render/mod.rs), [process supervisor](https://github.com/LibrePaper/librepaper/blob/2c58e8aff047dad024b8ec18aa26156f28cda87e/crates/librepaper-base/src/process.rs), [control auth](https://github.com/LibrePaper/librepaper/blob/2c58e8aff047dad024b8ec18aa26156f28cda87e/crates/librepaper-companion/src/local/service/control.rs), [desktop forwarding](https://github.com/LibrePaper/librepaper/blob/2c58e8aff047dad024b8ec18aa26156f28cda87e/desktop/src/main.rs).
- **S7 — Recovery:** [server backup](https://github.com/LibrePaper/librepaper/blob/2c58e8aff047dad024b8ec18aa26156f28cda87e/crates/librepaper-engine/src/storage/backup.rs), [desktop backups](https://github.com/LibrePaper/librepaper/blob/2c58e8aff047dad024b8ec18aa26156f28cda87e/docs/backups.md).
- **S8 — Operations:** [simple deployment](https://github.com/LibrePaper/librepaper/blob/2c58e8aff047dad024b8ec18aa26156f28cda87e/docs/host/simple.md), [security/upgrade guide](https://github.com/LibrePaper/librepaper/blob/2c58e8aff047dad024b8ec18aa26156f28cda87e/docs/host/security.md).
- **S9 — Privacy/providers:** [privacy](https://github.com/LibrePaper/librepaper/blob/2c58e8aff047dad024b8ec18aa26156f28cda87e/docs/privacy.md), [agents](https://github.com/LibrePaper/librepaper/blob/2c58e8aff047dad024b8ec18aa26156f28cda87e/docs/agents.md), [token cache](https://github.com/LibrePaper/librepaper/blob/2c58e8aff047dad024b8ec18aa26156f28cda87e/crates/librepaper-companion/src/local/credentials.rs).
- **S10 — Supply chain/CI:** [CI](https://github.com/LibrePaper/librepaper/blob/2c58e8aff047dad024b8ec18aa26156f28cda87e/.github/workflows/ci.yml), [asset pins](https://github.com/LibrePaper/librepaper/blob/2c58e8aff047dad024b8ec18aa26156f28cda87e/assets.lock), [desktop updater](https://github.com/LibrePaper/librepaper/blob/2c58e8aff047dad024b8ec18aa26156f28cda87e/desktop/tauri.conf.json), [web manifest](https://github.com/LibrePaper/librepaper/blob/2c58e8aff047dad024b8ec18aa26156f28cda87e/web/package.json).
- **M1:** [Public repository metadata](https://api.github.com/repos/LibrePaper/librepaper), retrieved 2026-11-10.
- **M2:** [v0.0.71 release](https://github.com/LibrePaper/librepaper/releases/tag/v0.0.71), metadata retrieved 2026-11-10.

---

**Attribution:** LibrePaper/librepaper and Vincent Arel-Bundock, MIT. Independent review; no source code extracted.
