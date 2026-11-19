# Skywake (skywakehq/skywake)

**Repo:** https://github.com/skywakehq/skywake
**License:** Apache-2.0; dependency, container and third-party asset terms remain separate.
**Reviewed:** 2026-11-19 (UTC)
**Revision:** 686871971b2ccaba342a047700d76c5e15a48be0 (master); storage engine, daemon, API, console, agent package, deployment files and tests sampled across the repository.
**Verification:** Static source review and public GitHub metadata inspection only. No installation, builds, tests, mounts, cloud provisioning, provider calls or live security probes.
**Stack:** Rust, TypeScript/Node, Hono/Zod, N-API, Next.js, Better Auth, PostgreSQL/Drizzle, Zero, S3-compatible object storage, Tantivy.
**What it is:** A branchable filesystem and hybrid search index for agent workspaces, not an agent model or a complete execution sandbox.

## Verdict

⚠️ **Interesting — pilot the storage layer, not an assumed security or durability guarantee.** Skywake combines cheap copy-on-write workspace forks, mergeable files and branchable search with unusually substantial failure-handling code. Its public history is very young, some headline guarantees omit important configuration-dependent behavior, and operating it securely means owning the host sandbox, network policy, backups and provider egress.

The strongest implementation/documentation discrepancy is that **fsync can acknowledge replicated cache-tier logs before the bucket is updated**. That is a legitimate design, but not the unconditional “fsync means saved in the bucket” statement in the architecture guide. Treat cache nodes as durability infrastructure when that mode is enabled.

## What It Is

Skywake serves teams running many agents against related working data. A disk is a versioned tree; each agent can fork a branch, change files and propose a three-way merge instead of copying a whole environment. Linux FUSE or virtio-fs exposes it as a mounted filesystem; HTTP SDKs and MCP support agents that do not mount. It does not itself create an isolated VM or container for those agents.

An index holds searchable rows with vectors, text and attributes. It also branches, restores historical versions and supports filtering, hybrid retrieval and optional reranking. Disk search is a separately synchronized index: file saves and search visibility are not one atomic transaction. The console and control-plane database track organizations, environments, keys, activity and search synchronization; the bucket alone is not a complete service backup.

## Stack and Architecture

| Layer | Implementation and significance |
|---|---|
| File engine | Rust; FastCDC chunks, BLAKE3-addressed objects, zstd compression, Merkle trees and conditional branch-head updates |
| Search | Rust vector IVF/RaBitQ modules, vendored Tantivy text engine, branch/version storage and hybrid query code |
| Host mount | skywaked, FUSE/virtio-fs, local dirty-file state and cache; optional distributed cache/write-log tier |
| API | Node 22.18+, Hono/OpenAPI/Zod contract over N-API Rust bindings; PostgreSQL for identity, catalog and background work |
| Console | Next.js, Better Auth, Zero browser synchronization; separate database roles but trusted replication service |
| Agent access | Seven SDK directories, native CLI, stdio MCP, just-bash virtual filesystem adapter |

Evidence: [Cargo.toml](https://github.com/skywakehq/skywake/blob/686871971b2ccaba342a047700d76c5e15a48be0/Cargo.toml), [crates/core/src/store/io.rs](https://github.com/skywakehq/skywake/blob/686871971b2ccaba342a047700d76c5e15a48be0/crates/core/src/store/io.rs), [crates/index/src](https://github.com/skywakehq/skywake/blob/686871971b2ccaba342a047700d76c5e15a48be0/crates/index/src), [apps/api/src/app.ts](https://github.com/skywakehq/skywake/blob/686871971b2ccaba342a047700d76c5e15a48be0/apps/api/src/app.ts), [packages/skywake/src/shell.ts](https://github.com/skywakehq/skywake/blob/686871971b2ccaba342a047700d76c5e15a48be0/packages/skywake/src/shell.ts).

### Useful engineering patterns

- **Pointer forks rather than copying:** immutable content and tree sharing avoid copying all bytes, while compare-and-swap head updates detect competing writers. This is a different operation from materializing an independent S3 copy; the advertised roughly 300× comparison is useful but not like-for-like copying throughput.
- **Failure-aware persistence:** garbage collection checks filesystem/index kind markers before traversing roots, coordinates batches with writers and applies a grace window. SQL deletion combines catalog removal and a durable deletion queue in one statement; workers retry remaining object-folder cleanup with bounded backoff.
- **Explicit conflicts and ownership:** branches can be protected, mounts detect takeover and become read-only, and unsaved changes have a recovery path. Agent claims are coordination hints, not exclusive locks.
- **Shared implementation:** the API delegates engine operations to Rust rather than reimplementing filesystem semantics in each SDK. The Zod/OpenAPI contract reduces—but does not eliminate—cross-language drift.

Evidence: [crates/core/src/store/gc/mod.rs](https://github.com/skywakehq/skywake/blob/686871971b2ccaba342a047700d76c5e15a48be0/crates/core/src/store/gc/mod.rs), [apps/api/src/features/deletions/queries.ts](https://github.com/skywakehq/skywake/blob/686871971b2ccaba342a047700d76c5e15a48be0/apps/api/src/features/deletions/queries.ts), [apps/api/src/features/deletions/worker.ts](https://github.com/skywakehq/skywake/blob/686871971b2ccaba342a047700d76c5e15a48be0/apps/api/src/features/deletions/worker.ts), [crates/daemon/src/mounted/save.rs](https://github.com/skywakehq/skywake/blob/686871971b2ccaba342a047700d76c5e15a48be0/crates/daemon/src/mounted/save.rs), [docs/how-it-works.md](https://github.com/skywakehq/skywake/blob/686871971b2ccaba342a047700d76c5e15a48be0/docs/how-it-works.md).

## Security, Permissions and Consent

### API and tenant boundaries

API keys contain random secrets, are stored hashed and compared with timing-safe equality. Authorization distinguishes organization, environment, resource scope and read/write/admin role. Key cache invalidation is supported; mutations recheck key records. Console JWTs constrain algorithm, issuer, audience and expiry, with five-minute issuance configured in the console. JWT role claims should not be mistaken for immediate revocation on every API request.

Resource access resolves namespace rows within the caller's organization. Explicitly public namespaces can be read across organizations, including by unauthenticated callers through the relevant v1 access path; indexes are not public. Public visibility is therefore a deliberate disclosure feature, not a universal private-by-default guarantee for all configured resources. CORS is configured from allowed origins, and body/rate limits exist; CORS is not tenant authentication.

Evidence: [apps/api/src/auth/keys.ts](https://github.com/skywakehq/skywake/blob/686871971b2ccaba342a047700d76c5e15a48be0/apps/api/src/auth/keys.ts), [apps/api/src/auth/authenticate.ts](https://github.com/skywakehq/skywake/blob/686871971b2ccaba342a047700d76c5e15a48be0/apps/api/src/auth/authenticate.ts), [apps/api/src/auth/tokens.ts](https://github.com/skywakehq/skywake/blob/686871971b2ccaba342a047700d76c5e15a48be0/apps/api/src/auth/tokens.ts), [apps/api/src/auth/access.ts](https://github.com/skywakehq/skywake/blob/686871971b2ccaba342a047700d76c5e15a48be0/apps/api/src/auth/access.ts), [apps/console/server/auth.ts](https://github.com/skywakehq/skywake/blob/686871971b2ccaba342a047700d76c5e15a48be0/apps/console/server/auth.ts), [apps/api/src/app.ts](https://github.com/skywakehq/skywake/blob/686871971b2ccaba342a047700d76c5e15a48be0/apps/api/src/app.ts).

### A disk-scoped credential is not branch isolation

The STS policy narrows access to a disk folder, denies object deletion and denies writes to GC state, the kind marker and protected refs. But writable credentials can still overwrite other unprotected branch refs and content objects inside that disk. Hash validation detects corrupted content; it does not prevent denial of service. Previously minted credentials remain usable until expiry, normally 15 minutes. A revoked API key does not instantly revoke an already-issued S3 session.

Use separate disks or a stronger credential/execution boundary for mutually hostile tenants. Do not give an agent whole-bucket keys and expect API scopes to protect the bucket from its direct calls. Protected refs reduce one attack surface, not all attacks on their reachable data.

Evidence: [apps/api/src/features/credentials/mint.ts](https://github.com/skywakehq/skywake/blob/686871971b2ccaba342a047700d76c5e15a48be0/apps/api/src/features/credentials/mint.ts), [docker/README.md](https://github.com/skywakehq/skywake/blob/686871971b2ccaba342a047700d76c5e15a48be0/docker/README.md).

### Host authority and a fail-open configuration edge

The daemon validates access-file ownership and permissions, and supports per-user/group branch policy. **If the access file is absent—or is removed during reload—the policy becomes unrestricted for members of the configured daemon group.** Invalid contents retain the last good policy; removal is explicitly different. Existing mounts keep their original access until unmounted. Root and the daemon owner remain privileged, and direct store credentials bypass these daemon rules.

A branch is a storage boundary, not process isolation. FUSE, VM socket ownership, host filesystem permissions, network restrictions and the actual VM/container boundary remain operator responsibilities. MCP grants tools according to the configured key's role; no independent human confirmation gate was found in the inspected registration path. The bash adapter uses just-bash over SkywakeFs rather than automatically spawning a host shell, but accepts caller-provided options/custom commands. Its run helper can commit changes even when the command returned a nonzero exit status if a commit option was requested.

Evidence: [crates/daemon/src/access.rs](https://github.com/skywakehq/skywake/blob/686871971b2ccaba342a047700d76c5e15a48be0/crates/daemon/src/access.rs), [packages/skywake/src/mcp.ts](https://github.com/skywakehq/skywake/blob/686871971b2ccaba342a047700d76c5e15a48be0/packages/skywake/src/mcp.ts), [packages/skywake/src/shell.ts](https://github.com/skywakehq/skywake/blob/686871971b2ccaba342a047700d76c5e15a48be0/packages/skywake/src/shell.ts), [packages/skywake/src/run.ts](https://github.com/skywakehq/skywake/blob/686871971b2ccaba342a047700d76c5e15a48be0/packages/skywake/src/run.ts).

### Network and secret handling

Customer bucket keys are sealed with AES-256-GCM using row-bound authenticated context; assumed roles use an external ID. This protects stored key material, not a compromised API process holding the sealing key. Preserve that key securely with recoverable backups.

The bring-your-own-bucket endpoint is accepted as a URL and used by the server during verification. The inspected schema and route do not impose a public-address allowlist or private-network rejection. Treat tenant-admin-selected storage endpoints as an outbound network trust boundary; enforce egress policy before offering this to untrusted organizations. This is a static hardening concern, not a reproduced exploit. Shared cache tokens require a trusted network or TLS transport; content hashes provide integrity, not confidentiality.

Compose publishes API, console and Zero ports without loopback-only bindings. It is a convenient starter, not a hardened Internet deployment. Zero's PostgreSQL REPLICATION capability can decode broader database changes than its SELECT grants suggest; the documentation correctly says to trust it like the API and keep Postgres private.

Evidence: [apps/api/src/security/sealed.ts](https://github.com/skywakehq/skywake/blob/686871971b2ccaba342a047700d76c5e15a48be0/apps/api/src/security/sealed.ts), [packages/contract/src/environments.ts](https://github.com/skywakehq/skywake/blob/686871971b2ccaba342a047700d76c5e15a48be0/packages/contract/src/environments.ts), [apps/api/src/features/environments/routes.ts](https://github.com/skywakehq/skywake/blob/686871971b2ccaba342a047700d76c5e15a48be0/apps/api/src/features/environments/routes.ts), [apps/api/src/features/environments/buckets.ts](https://github.com/skywakehq/skywake/blob/686871971b2ccaba342a047700d76c5e15a48be0/apps/api/src/features/environments/buckets.ts), [compose.yaml](https://github.com/skywakehq/skywake/blob/686871971b2ccaba342a047700d76c5e15a48be0/compose.yaml), [docker/README.md](https://github.com/skywakehq/skywake/blob/686871971b2ccaba342a047700d76c5e15a48be0/docker/README.md).

## Durability, Retention, Export and Recovery

### Qualify both headline durability claims

The README's “lose at most 2 seconds” is not an unconditional recovery-point objective under slow uploads, errors or network partitions. The detailed guide already adds “plus the save in flight”; the saver records lag/failures and cannot make an unavailable bucket durable on a timer. Monitor save lag and test failures under the intended workload.

More importantly, the source enables a write log when cache nodes are configured and log copies are positive (default three). In that mode fsync can return after changes are recorded on cache nodes in distinct zones; the bucket gets them at the next save. When logging fails it falls back to waiting for the bucket. New mounts seal/replay those logs. Thus cache-node storage, zone placement and recovery become part of the durability guarantee. Setting zero log copies selects bucket-waiting semantics; evaluate this explicitly instead of relying on the guide's blanket wording.

Evidence: [crates/daemon/src/server/mod.rs](https://github.com/skywakehq/skywake/blob/686871971b2ccaba342a047700d76c5e15a48be0/crates/daemon/src/server/mod.rs), [crates/daemon/src/mounted/save.rs](https://github.com/skywakehq/skywake/blob/686871971b2ccaba342a047700d76c5e15a48be0/crates/daemon/src/mounted/save.rs), [crates/daemon/src/mounted/log.rs](https://github.com/skywakehq/skywake/blob/686871971b2ccaba342a047700d76c5e15a48be0/crates/daemon/src/mounted/log.rs), [crates/core/src/cache/log.rs](https://github.com/skywakehq/skywake/blob/686871971b2ccaba342a047700d76c5e15a48be0/crates/core/src/cache/log.rs), [docs/how-it-works.md](https://github.com/skywakehq/skywake/blob/686871971b2ccaba342a047700d76c5e15a48be0/docs/how-it-works.md).

### History is useful—and retains deleted data

Deleting a file from the current tree does not remove its reachable historical bytes. Disk GC preserves reachable history and observes an eight-day default grace period. Index versions are kept indefinitely by default; retentionDays can restrict replaced-version retention, with GC needed to reclaim unreferenced data. Removing a whole disk/index queues eventual folder destruction rather than instant physical erasure. Provider-side object versioning, backups, caches, audit records and browser replicas are separate retention domains.

Files can be downloaded and index rows paginated for export. Those are data exports, not complete org/identity/configuration backups. Mount-local hard-link identity, owners, access times and extended attributes do not all persist as full POSIX metadata; FIFOs, sockets and device nodes are not saved. Ignored build directories are intentionally local and disposable. Unsaved recovery state helps after daemon failures, but cannot recover a destroyed host's only local dirty bytes.

Back up PostgreSQL, object storage, configuration/sealing keys and any durability-bearing cache log state together, and test restore ordering. AWS deployment files provide database-backup options, but no end-to-end restore was exercised here. Automatic startup migrations plus a moving git-pull update recipe warrant a pinned release and a rollback/restore rehearsal.

Evidence: [apps/docs/content/docs/indexes/time-travel.mdx](https://github.com/skywakehq/skywake/blob/686871971b2ccaba342a047700d76c5e15a48be0/apps/docs/content/docs/indexes/time-travel.mdx), [apps/docs/content/docs/indexes/write.mdx](https://github.com/skywakehq/skywake/blob/686871971b2ccaba342a047700d76c5e15a48be0/apps/docs/content/docs/indexes/write.mdx), [crates/core/src/store/gc/mod.rs](https://github.com/skywakehq/skywake/blob/686871971b2ccaba342a047700d76c5e15a48be0/crates/core/src/store/gc/mod.rs), [apps/api/src/features/deletions/worker.ts](https://github.com/skywakehq/skywake/blob/686871971b2ccaba342a047700d76c5e15a48be0/apps/api/src/features/deletions/worker.ts), [deploy/terraform/aws/database.tf](https://github.com/skywakehq/skywake/blob/686871971b2ccaba342a047700d76c5e15a48be0/deploy/terraform/aws/database.tf), [docker/README.md](https://github.com/skywakehq/skywake/blob/686871971b2ccaba342a047700d76c5e15a48be0/docker/README.md), [docs/how-it-works.md](https://github.com/skywakehq/skywake/blob/686871971b2ccaba342a047700d76c5e15a48be0/docs/how-it-works.md).

## Providers, Privacy and Costs

Embedding adapters support OpenAI-compatible, Voyage, Cohere and Gemini request shapes; reranking transmits a query and selected result text to the configured service. Enabling disk search can extract and embed file content automatically. Self-hosting storage does not make those remote requests private or free. Use numeric vectors or approved local endpoints when external processing is unacceptable, and verify provider retention terms separately.

Provider calls have batching, timeout/retry handling and usage admission/accounting. That is not proof of a universal prepaid cost ceiling: embeddings, retries, indexing, pinned RAM, API/database replicas, object requests, stored history and cross-region egress all affect cost. No current hosted price quote or provider bill was independently verified. Logs/audit and Zero's browser-side replicas also enlarge the data lifecycle beyond the bucket; do not upload secrets merely because branches are easy to delete.

Evidence: [apps/api/src/features/indexes/providers.ts](https://github.com/skywakehq/skywake/blob/686871971b2ccaba342a047700d76c5e15a48be0/apps/api/src/features/indexes/providers.ts), [apps/api/src/features/indexes/models.ts](https://github.com/skywakehq/skywake/blob/686871971b2ccaba342a047700d76c5e15a48be0/apps/api/src/features/indexes/models.ts), [apps/api/src/features/indexes/embeddings.ts](https://github.com/skywakehq/skywake/blob/686871971b2ccaba342a047700d76c5e15a48be0/apps/api/src/features/indexes/embeddings.ts), [apps/api/src/features/indexes/rerank.ts](https://github.com/skywakehq/skywake/blob/686871971b2ccaba342a047700d76c5e15a48be0/apps/api/src/features/indexes/rerank.ts), [apps/api/src/features/links/sync.ts](https://github.com/skywakehq/skywake/blob/686871971b2ccaba342a047700d76c5e15a48be0/apps/api/src/features/links/sync.ts), [apps/api/src/audit/retention.ts](https://github.com/skywakehq/skywake/blob/686871971b2ccaba342a047700d76c5e15a48be0/apps/api/src/audit/retention.ts).

## Maturity, Tests, Supply Chain and License

Public metadata on the review date reported 41 stars, 5 forks, repository creation on 2026-11-12 and last push on 2026-11-16. Release v0.2.0 was published on November 16. These are a young public project's activity signals, not reliability evidence; earlier benchmark dates may reflect pre-public development.

The [CI run for this exact SHA](https://github.com/skywakehq/skywake/actions/runs/43975148213) reported success. The separate [Release PR workflow](https://github.com/skywakehq/skywake/actions/runs/43975148227) reported failure; that is not the same as failing tests. CI configuration includes Rust formatting/clippy/tests, FUSE and privileged tests, TypeScript builds/typechecking, API/SDK integration tests, a synthetic 100-agent swarm, deployment validation and cargo deny/audit. This review did not run or independently reproduce those jobs. The swarm is orchestration evidence, not proof that 100 autonomous models solve real tasks safely.

Published benchmark reports are better than unsupported marketing numbers, and explicitly admit pre-release code and uncommitted changes: **no single commit exactly reproduces them**. The 10M-vector cold/warm results depend on dataset, recall, hardware, head caching and disk cache. Rebenchmark the reviewed SHA with production-like latency, churn, recovery and cost accounting.

Cargo and pnpm lockfiles, commit-pinned GitHub Actions, security policy and release-attestation steps are positives. The workspace patches Tantivy locally; native Rust/N-API, FUSE, container images, JavaScript packages and SDK tooling widen maintenance responsibility. Docker images use version tags rather than universal digest pinning, Rust CI follows stable, and the starter can install missing tooling with consent. Do not execute it as a harmless inspection command. Native npm CLI prebuilts target glibc Linux x64/arm64; the wrapper allows an explicit binary override. Release workflow attestations were inspected, not downloaded or cryptographically verified.

The root and manifests specify Apache-2.0, permitting modification/commercial use subject to its notice, attribution and other terms; it does not grant trademark rights. Vendored Tantivy and every distributed dependency/image retain their own terms. No project code, logos, fonts or other assets were extracted into this review.

Evidence: [.github/workflows/ci.yml](https://github.com/skywakehq/skywake/blob/686871971b2ccaba342a047700d76c5e15a48be0/.github/workflows/ci.yml), [.github/workflows/release.yml](https://github.com/skywakehq/skywake/blob/686871971b2ccaba342a047700d76c5e15a48be0/.github/workflows/release.yml), [docs/benchmarks.md](https://github.com/skywakehq/skywake/blob/686871971b2ccaba342a047700d76c5e15a48be0/docs/benchmarks.md), [scripts/start.sh](https://github.com/skywakehq/skywake/blob/686871971b2ccaba342a047700d76c5e15a48be0/scripts/start.sh), [packages/skywake/bin/skywake.cjs](https://github.com/skywakehq/skywake/blob/686871971b2ccaba342a047700d76c5e15a48be0/packages/skywake/bin/skywake.cjs), [LICENSE](https://github.com/skywakehq/skywake/blob/686871971b2ccaba342a047700d76c5e15a48be0/LICENSE), [vendor/tantivy/LICENSE](https://github.com/skywakehq/skywake/blob/686871971b2ccaba342a047700d76c5e15a48be0/vendor/tantivy/LICENSE).

## Comparison

| Need | Practical alternative | Tradeoff against Skywake |
|---|---|---|
| A few coding agents on one host | Git worktrees plus local storage | Much simpler operationally; no equivalent lazy object-backed file tree or integrated branchable search |
| Versioned object datasets | lakeFS | Designed around object/data versioning; not the same mounted agent-workspace and per-file merge experience |
| Shared object-backed filesystem | JuiceFS | Established filesystem focus; evaluate its metadata/service model and snapshot semantics rather than assuming identical branch/merge behavior |
| Primarily hybrid/vector retrieval | Qdrant or PostgreSQL with pgvector | Narrower search-focused stack; workspace branching and mounted files must be supplied separately |

These are fit comparisons, not head-to-head performance or security tests. Skywake is most compelling when cheap large-workspace forks and searchable branch state are both central. For a handful of local agents, its multi-service control plane may cost more complexity than it saves.

## Self-Hosting Notes and Acceptance Gates

Start only in an isolated pilot with synthetic data. Pin a source/release revision; keep public services behind HTTPS; restrict database/cache networks; decide whether BYOB endpoints need egress filtering; use narrow API credentials and separate disks for separate trust domains. Protect main branches and require the orchestrator's own review/approval before merging consequential changes.

Before production: reproduce cross-tenant/key-expiry tests, fail-open access-file behavior, takeover and conflict recovery, provider egress, sustained save lag, cache-log zone failures, GC concurrent with writers, full backup restoration and deletion across replicas/backups. Document the exact fsync mode and accepted data-loss window. None of those deployment acceptance tests was run for this static review.

---

**Attribution:** skywakehq/skywake contributors; Apache-2.0 source. Analysis based exclusively on public source and public GitHub metadata.
