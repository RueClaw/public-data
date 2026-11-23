# Tuff (usetuff/tuff)

**Repo:** https://github.com/usetuff/tuff
**License:** AGPL-3.0-only; network copyleft, with name/logo excluded from the project's licensing grant.
**Reviewed:** 2026-11-23 (UTC)
**Revision:** 018e6ecf32e6f9c31c936b80b20f1579b54675cc (main); scope: manifests, documentation, deployment, auth/API/MCP, permissions, storage/recovery, client cache, test samples and CI.
**Verification:** Static source review; no installation, source execution, tests, accounts, or external integrations exercised. Public GitHub CI reports success for this exact commit; this is upstream evidence, not an independent test run.
**Stack:** TypeScript, Node.js 22+, Hono, React 19, Vite, Tailwind 4, Tiptap/Yjs, Zod, PostgreSQL 17, MCP.
**What it is:** A self-hostable team workspace combining tasks, documents, chat and announcements, with external AI agents participating through permissioned MCP tools.

---

## Verdict

⚠️ **Interesting — a credible pilot candidate, not yet an unqualified production recommendation.** Tuff implements substantial agent permissions, database isolation and operational recovery rather than merely decorating a kanban board with an AI chat box. Its very recent public releases, single-maintainer model, incomplete public browser-test coverage and several deployment/documentation caveats warrant a disposable-data pilot and restore drill before it becomes a team's system of record.

## What It Is

Tuff overlaps Linear/ClickUp/Asana for task tracking and Basecamp for integrated project communication. Projects contain tasks, files/documents, announcements and chat; cross-project personal tasks, search, version history and notifications make this a collaboration suite rather than an agent runtime. GitHub issue synchronization, importers and external agents widen its useful scope, but also its security and maintenance surface. [1][2]

An agent connects through remote MCP or a local stdio adapter. It can act under its own identity or a person's token, read and change authorized project content, ask questions and record reported spend. Tuff does not supply the coding agent, model subscription or a general-purpose shell execution sandbox. The external client's filesystem, shell and model permissions remain outside Tuff's control. [3][4]

The public repository was accessible anonymously over HTTPS, confirmed by unauthenticated GitHub metadata and source acquisition. At review time metadata showed 56 stars, 2 forks, 0 open issues and a last push of 2026-11-23T10:54:06Z. These are activity observations, not safety evidence. Latest published release was **v1.1.0**, published 2026-11-22T15:14:15Z, at commit **415311078f23fb8f5256f79097981fa539cc247c** (annotated tag object 736d279dd6a9c8f82f05b18c593d87b81f250c84). This review examines newer development main, not that release image; package version is 0.0.0. v1.0.0 was published November 20. [16]

## Stack

| Layer | Tech |
|-------|------|
| API / worker | Node.js, TypeScript, Hono; separate worker process using the same image |
| Client | React 19, Vite, Tailwind 4, Tiptap/Yjs; installable web app |
| Contract | Shared Zod schemas and permission matrix; generated client schemas/types |
| Persistence | PostgreSQL 17, SQL migrations, row-level security; local upload volume or S3-compatible storage |
| Live updates | WebSockets plus PostgreSQL LISTEN/NOTIFY |
| Agent interface | MCP SDK, streamable HTTP and stdio; API tokens or OAuth/PKCE |
| Packaging | pnpm workspace; Docker Compose with Caddy TLS; amd64/arm64 release workflow |

Sources: package manifests, architecture and deployment files. [2][5][6]

## Key Features

### One permission model for people and agents

The remote MCP handler authenticates a token and dispatches tool operations back through the in-process REST application. It does not implement a second direct database access path. The shared matrix has a hard `NEVER_VIA_MCP` denylist covering invitations, role changes, workspace transfer/deletion, task/file/channel deletion, file sharing and more. Project-scoped tokens flow through AsyncLocalStorage into database transaction settings. This is stronger than relying solely on a prompt asking an agent to behave. [3][4][7]

Tools still perform real writes: creating/updating tasks and documents, posting and sending messages. Permission is not per-operation human approval. Project text is wrapped as untrusted JSON and angle brackets escaped; that helps delimit content but is not proof against prompt injection in an external model. A malicious document can still influence an agent within its granted rights, or exploit unrelated tools available in its client. Keep agent identities narrow and separate from owner accounts. [4][7]

### Integrated collaboration, not another model host

Tasks, board/list views, chat, documents and activity are first-class data. MCP includes questions/answers and agent status, and the release adds agent-owned lists and recurring work. AI spend is supplied by clients, not independently metered provider billing. No model API key is required for the core project manager; the connected agent's model/service costs are separate. Self-hosted users get the browser/PWA experience: the upstream native mobile apps connect only to usetuff.com. [1][4][16]

### Recoverable content and usable exit paths — with limits

The worker permanently purges soft-deleted content after the configured window (default 30 days). Document history and restoration are helpful but not backups. The personal JSON export enumerates authored content and account/device metadata; it explicitly lists attachments without including their bytes. This is not a complete workspace export or a tested migration round trip. Preserve the database, upload volume or bucket, and encryption/configuration secrets together. [8][9]

## Architecture

The pnpm workspace contains `shared-schema/`, `server/` and `web/`. Request validation and permission checks precede transactions carrying actor/workspace context. Runtime database roles split application, authentication and worker duties from the migration owner; a production startup guard rejects roles that bypass RLS. This is meaningful defense in depth, although it is not protection from full container compromise: the shipped Compose environment passes owner database credentials and the shared secret environment to both app and worker. SQL privilege separation does not equal process-level secret isolation. [2][6][7][10]

Realtime notifications use a dedicated PostgreSQL listener, with a heartbeat/reconnect path; clients refetch authoritative data through REST. That avoids adding Redis merely for fan-out. However, the self-hosting guide's Railway section still instructs one replica on the premise that realtime requires one container, while the implementation and architecture document describe cross-process LISTEN/NOTIFY. Treat horizontal-scaling support as unproven until deployment-specific tests reconcile this documentation mismatch. [2][9][11]

The worker is operationally essential for email, push, imports, webhooks and final deletion. Compose disables the worker's HTTP healthcheck, so a healthy app does not prove background work is progressing. Monitor actual job delivery and failures, not just the app health endpoint. [6]

## Security, Credentials and Privacy

- **Authentication:** email/password and optional second factor, plus optional Google/Apple/GitHub sign-in. Passwords use scrypt; random API tokens are stored as SHA-256 hashes. MCP OAuth uses the app's consent flow and PKCE. Setup creates a one-time owner capability: whoever has the setup link can claim the instance. It is printed in startup logs until claimed, so log access is sensitive. Manually omitting both owner email and setup token leaves the documented first-confirmed-account ownership behavior. [1][3][9][10]
- **Recoverable secrets:** AES-256-GCM sealing uses a separate ENCRYPTION_KEY when supplied, with a previous-key/reseal migration path. Legacy fallback derives keys from JWT_SECRET, so changing that secret without the correct reseal procedure can strand integration credentials and second-factor secrets. This is server-side encryption at rest, not end-to-end encryption; the application can decrypt them. [10]
- **Origin policy:** the architecture prose says “one origin, no CORS,” but routes actually reflect requesting origins with `credentials: false`. This is broad non-credentialed CORS, not a discovered auth bypass; bearer tokens still authorize API calls. Browser-binding cookies use HttpOnly, Secure outside local-try mode, and SameSite=Lax. Review the real proxy/header setup rather than relying on the prose. [2][12]
- **Network egress:** optional SMTP/Resend, OAuth providers, GitHub/Slack integrations, import APIs, S3 storage, browser-push services, GIF service and Cloudflare Turnstile can move data off-host. Link previews also fetch external URLs. Connected agents receive authorized task/chat/file content and may forward it to their model providers. Self-hosting does not mean offline or no third parties. [9][13]
- **Default update check:** released builds' worker queries GitHub daily with a Tuff/version user agent; IP and version are visible to GitHub. `UPDATE_CHECK=off` disables it. The code skips unreleased 0.0.0 builds. This checks for updates; it does not automatically install them. [14]
- **Outbound hardening:** user-supplied webhook endpoints require public HTTPS; DNS results are checked at socket connection, redirects are not followed, and calls time out. Push endpoints are allowlisted. Mail settings have public-address checks, with an explicit private-relay override. These are good SSRF mitigations, not a complete penetration test. [13]
- **Client and file exposure:** recent content is persisted in IndexedDB for offline display, with clearing logic; shared devices need care. MCP can receive short-lived signed file URLs usable without ordinary sign-in (up to an hour). Treat those URLs as capabilities, not public harmless references. [15]

## Data Durability, Recovery and Export

The standard Compose stack persists database and uploads on separate named volumes. Pre-migration database dumps go to a third, same-host volume and have 30-day default retention. A dump write failure aborts migration, but **the protection is conditional**: `backupBeforeMigrating()` explicitly continues without a backup when skipping is enabled, no backup directory exists, the directory is not a mount, or the server PostgreSQL major exceeds the bundled pg_dump version. Thus the README's broad “no migration runs if the backup fails” is not a universal “no backup, no migration” guarantee. Railway requires separately enabled database backups. [6][9][17]

Migration rollback is not implemented; recovery means restoring an earlier database and matching application version. The restore script validates the dump, stops app/worker, renames the existing database rather than immediately discarding it, and attempts recovery on failure. Those are encouraging safeguards, but no restore drill was performed here. Copy backups off-machine; include uploaded bytes and the keys needed to decrypt stored secrets. Switching storage to S3 does not migrate existing files. [9][17]

## Installation and Update Risks

Use a numbered release and its matching checkout/Compose scripts, not the reviewed development main, for a pilot. Setup generates secrets with restrictive umask; local-try mode binds localhost and has explicit destructive fresh-start handling. Docker access remains host-level administrative authority. Read setup/update/restore scripts before running them; do not treat “one command” as a sandbox. [6][18]

The image runs as the non-root node user, and release automation declares cosign signing, SBOM and build provenance with SHA-pinned Actions. This review inspected the workflow, not a downloaded image, verified signature or complete dependency vulnerability audit. App version tags are pinned by configuration, but are not content digests; PostgreSQL/Caddy image tags also float. Pin verified digests where reproducibility matters. [5][6][19]

Updates pull images and restart services; they can trigger forward-only migrations and downtime. The Docker host, registry, dependency lockfile, package install/build chain and release maintainer are all trust dependencies. Keep explicit off-host backups, validate mail/reset access, and rehearse a restore before enabling real team use. [9][17][18]

## Maturity and Verification

The reviewed tree contains 156 server `*.test.ts` files and 53 Playwright `*.spec.ts` files; these are file counts, not passing-test counts. Inspected examples exercise password-reset invalidation and agent webhook-loop ceilings. Public CI runs types, generated-schema consistency, permission tests, server tests against PostgreSQL, web tests, builds, multi-platform image builds and the localhost trial setup. It **does not run the Playwright suite**, and its check job does not invoke the linter; the documented local `pnpm check` path is broader. [19][20]

GitHub reports [CI run 45160254847](https://github.com/usetuff/tuff/actions/runs/45160254847) completed successfully on the exact reviewed SHA. That is an upstream reported result, not independent reproduction. No runtime security testing, performance benchmark, UI check, image attestation verification, backup/restore execution or end-to-end integration test was performed. Performance claims in the README remain project claims. [1][19]

The contribution policy says one person builds the product and pull requests are not merged; issues are accepted. This concentrates maintenance and release authority. Two very recent public releases and a large test tree are encouraging, but do not establish a long operating history, independent audit or self-hosted SLA. [21]

## License and Reuse

The actual LICENSE is GNU AGPL v3 and manifests/README specify AGPL-3.0-only. Forking and modification are permitted subject to its terms; distributing covered work and offering modified versions for network interaction can require corresponding source availability and preservation of notices. Do not treat it as permissive proprietary embedding material. Name/logo use is separately excluded by project documentation; a fork should use its own branding. This review extracts no code. [1][5][21][22]

## Comparison

| Need | Tuff | Alternatives and tradeoff |
|------|------|--------------------------|
| Integrated project discussion and docs | Tasks/chat/docs in one self-hosted workspace | Basecamp is a hosted integrated-workspace comparison; evaluate vendor operation versus local control |
| Issue-centric planning | Built-in boards plus broader communication and MCP | Plane or OpenProject are worth comparing for planning-first self-hosting; evaluate their current feature/licensing splits separately |
| Source-native coordination | GitHub synchronization and separate agent identities | GitHub Issues/Projects avoids operating another collaboration database when work already lives in GitHub |
| Fully managed polished task tooling | Self-hosted flexibility, operational responsibility | Linear/Asana/ClickUp trade infrastructure ownership for managed services and their pricing/data policies |

These are category-level alternatives, not hands-on benchmarks or claims of feature parity. No paid service is necessary to evaluate the public source. Self-hosted software has no advertised seat/project fee, but compute, storage, backups, mail delivery, domains and administration cost money/time. External AI usage is additional. The README describes a paid hosted flat-workspace option; exact current prices were not independently verified. [1]

## Self-Hosting Notes

**Recommended pilot gate:** deploy a verified release on a noncritical server; retain Caddy or correctly configure a trusted reverse proxy; protect setup logs and claim ownership; use distinct agent/project scopes; configure mail and test recovery; monitor worker jobs; take coordinated database/files/secrets backups off-host and complete a restore drill. Keep the instance single-replica initially. Restrict unnecessary integrations/egress and review offline-device retention before storing sensitive team content.

Move toward production only after browser acceptance tests, permission-boundary checks, backup recovery and upgrade rollback have been exercised on the actual release and environment. The strongest reusable idea here is shared REST authorization plus database-scoped agent identities—not the assumption that a model reading wrapped text is safe.

## Evidence

All code links below are pinned to the reviewed revision. Documentation statements are distinguished from inspected implementation above.

1. [README.md](https://github.com/usetuff/tuff/blob/018e6ecf32e6f9c31c936b80b20f1579b54675cc/README.md).
2. [docs/architecture.md](https://github.com/usetuff/tuff/blob/018e6ecf32e6f9c31c936b80b20f1579b54675cc/docs/architecture.md).
3. [server/src/mcp/remote.ts](https://github.com/usetuff/tuff/blob/018e6ecf32e6f9c31c936b80b20f1579b54675cc/server/src/mcp/remote.ts); [server/src/http/oauth.ts](https://github.com/usetuff/tuff/blob/018e6ecf32e6f9c31c936b80b20f1579b54675cc/server/src/http/oauth.ts).
4. [server/src/mcp/tools.ts](https://github.com/usetuff/tuff/blob/018e6ecf32e6f9c31c936b80b20f1579b54675cc/server/src/mcp/tools.ts).
5. [package.json](https://github.com/usetuff/tuff/blob/018e6ecf32e6f9c31c936b80b20f1579b54675cc/package.json); [server/package.json](https://github.com/usetuff/tuff/blob/018e6ecf32e6f9c31c936b80b20f1579b54675cc/server/package.json); [web/package.json](https://github.com/usetuff/tuff/blob/018e6ecf32e6f9c31c936b80b20f1579b54675cc/web/package.json); [Dockerfile](https://github.com/usetuff/tuff/blob/018e6ecf32e6f9c31c936b80b20f1579b54675cc/Dockerfile).
6. [docker-compose.prod.yml](https://github.com/usetuff/tuff/blob/018e6ecf32e6f9c31c936b80b20f1579b54675cc/docker-compose.prod.yml).
7. [shared-schema/src/permissions.ts](https://github.com/usetuff/tuff/blob/018e6ecf32e6f9c31c936b80b20f1579b54675cc/shared-schema/src/permissions.ts); [server/src/db.ts](https://github.com/usetuff/tuff/blob/018e6ecf32e6f9c31c936b80b20f1579b54675cc/server/src/db.ts); [server/src/auth/context.ts](https://github.com/usetuff/tuff/blob/018e6ecf32e6f9c31c936b80b20f1579b54675cc/server/src/auth/context.ts).
8. [server/src/http/yourdata.ts](https://github.com/usetuff/tuff/blob/018e6ecf32e6f9c31c936b80b20f1579b54675cc/server/src/http/yourdata.ts).
9. [docs/self-hosting.md](https://github.com/usetuff/tuff/blob/018e6ecf32e6f9c31c936b80b20f1579b54675cc/docs/self-hosting.md).
10. [server/src/auth/crypto.ts](https://github.com/usetuff/tuff/blob/018e6ecf32e6f9c31c936b80b20f1579b54675cc/server/src/auth/crypto.ts); [server/src/auth/seal.ts](https://github.com/usetuff/tuff/blob/018e6ecf32e6f9c31c936b80b20f1579b54675cc/server/src/auth/seal.ts); [server/src/rlsGuard.ts](https://github.com/usetuff/tuff/blob/018e6ecf32e6f9c31c936b80b20f1579b54675cc/server/src/rlsGuard.ts).
11. [server/src/realtime.ts](https://github.com/usetuff/tuff/blob/018e6ecf32e6f9c31c936b80b20f1579b54675cc/server/src/realtime.ts).
12. [server/src/http/routes.ts](https://github.com/usetuff/tuff/blob/018e6ecf32e6f9c31c936b80b20f1579b54675cc/server/src/http/routes.ts); [server/src/http/access.ts](https://github.com/usetuff/tuff/blob/018e6ecf32e6f9c31c936b80b20f1579b54675cc/server/src/http/access.ts).
13. [server/src/outbound.ts](https://github.com/usetuff/tuff/blob/018e6ecf32e6f9c31c936b80b20f1579b54675cc/server/src/outbound.ts); [server/src/http/preview.ts](https://github.com/usetuff/tuff/blob/018e6ecf32e6f9c31c936b80b20f1579b54675cc/server/src/http/preview.ts).
14. [server/src/updates.ts](https://github.com/usetuff/tuff/blob/018e6ecf32e6f9c31c936b80b20f1579b54675cc/server/src/updates.ts).
15. [web/src/data/memory.ts](https://github.com/usetuff/tuff/blob/018e6ecf32e6f9c31c936b80b20f1579b54675cc/web/src/data/memory.ts); [server/src/http/files.ts](https://github.com/usetuff/tuff/blob/018e6ecf32e6f9c31c936b80b20f1579b54675cc/server/src/http/files.ts).
16. [CHANGELOG.md](https://github.com/usetuff/tuff/blob/018e6ecf32e6f9c31c936b80b20f1579b54675cc/CHANGELOG.md). [Release](https://github.com/usetuff/tuff/releases/tag/v1.1.0); [metadata](https://api.github.com/repos/usetuff/tuff).
17. [server/src/backup.ts](https://github.com/usetuff/tuff/blob/018e6ecf32e6f9c31c936b80b20f1579b54675cc/server/src/backup.ts); [scripts/restore.sh](https://github.com/usetuff/tuff/blob/018e6ecf32e6f9c31c936b80b20f1579b54675cc/scripts/restore.sh).
18. [scripts/setup.sh](https://github.com/usetuff/tuff/blob/018e6ecf32e6f9c31c936b80b20f1579b54675cc/scripts/setup.sh); [scripts/update.sh](https://github.com/usetuff/tuff/blob/018e6ecf32e6f9c31c936b80b20f1579b54675cc/scripts/update.sh); [scripts/try.sh](https://github.com/usetuff/tuff/blob/018e6ecf32e6f9c31c936b80b20f1579b54675cc/scripts/try.sh).
19. [.github/workflows/ci.yml](https://github.com/usetuff/tuff/blob/018e6ecf32e6f9c31c936b80b20f1579b54675cc/.github/workflows/ci.yml); [.github/workflows/release.yml](https://github.com/usetuff/tuff/blob/018e6ecf32e6f9c31c936b80b20f1579b54675cc/.github/workflows/release.yml).
20. [server/test/access.test.ts](https://github.com/usetuff/tuff/blob/018e6ecf32e6f9c31c936b80b20f1579b54675cc/server/test/access.test.ts); [server/test/agent-chain-attacks.test.ts](https://github.com/usetuff/tuff/blob/018e6ecf32e6f9c31c936b80b20f1579b54675cc/server/test/agent-chain-attacks.test.ts); [scripts/check.sh](https://github.com/usetuff/tuff/blob/018e6ecf32e6f9c31c936b80b20f1579b54675cc/scripts/check.sh).
21. [CONTRIBUTING.md](https://github.com/usetuff/tuff/blob/018e6ecf32e6f9c31c936b80b20f1579b54675cc/CONTRIBUTING.md).
22. [LICENSE](https://github.com/usetuff/tuff/blob/018e6ecf32e6f9c31c936b80b20f1579b54675cc/LICENSE).

---

**Attribution:** usetuff/tuff contributors, AGPL-3.0-only. Independent static analysis of public source; no private-source or submission material included.
