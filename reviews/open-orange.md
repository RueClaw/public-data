# OpenOrange (rivet-dev/open-orange)

**Repo:** https://github.com/rivet-dev/open-orange
**License:** Apache-2.0; vendored Cloudflare Workflows engine uses MIT, dependencies retain their own terms.
**Reviewed:** 2026-11-12 (UTC)
**Revision:** 0f3c2eac56d7f67d16398d54c4560543621f5582; package 1.0.1; repository-wide static review, sampled runtime, bindings, deployment, migration and conformance implementation.
**Verification:** Static review only. No install, source execution, tests, deployments, provider calls, migration or live security probes.
**Stack:** TypeScript, Node.js 22+, Wrangler, esbuild, RivetKit/Rivet Actors, SQLite, S3-compatible storage.
**What it is:** A Cloudflare Workers API compatibility layer on Node.js, mapping stateful bindings to Rivet Actors so existing applications can run outside Cloudflare. It is neither an AI assistant nor a workerd fork.

## Verdict

⚠️ **Interesting — qualify a specific application before moving production.** Substantial implementation, unusually candid compatibility evidence and thoughtful migration machinery make this a credible portability project. However, Node execution is a different trust boundary, WebSocket hibernation is emulated, migration rollback is not lossless, and the advertised infrastructure savings are not a total-cost benchmark. Best for teams with steady stateful workloads and the ability to operate Rivet; not a blanket drop-in replacement or a default host for hostile tenant code.

## What It Is

Rivet maintains OpenOrange independently of Cloudflare. The CLI reads existing Wrangler JSON/JSONC/TOML configuration, bundles Worker code and rewrites platform imports into its compatibility modules. Normal Worker code runs in a Node child process; Durable Objects become actors with individual SQLite state. KV, D1, queues, cron, workflows and other bindings are implemented above that actor substrate. This moves the platform dependency from Cloudflare services to Rivet plus configured external providers, not to a single self-contained Worker executable. See [README.md](https://github.com/rivet-dev/open-orange/blob/0f3c2eac56d7f67d16398d54c4560543621f5582/README.md), [src/build/rewrite-module-imports.ts](https://github.com/rivet-dev/open-orange/blob/0f3c2eac56d7f67d16398d54c4560543621f5582/src/build/rewrite-module-imports.ts) and [packages/runtime-node/src/runner.ts](https://github.com/rivet-dev/open-orange/blob/0f3c2eac56d7f67d16398d54c4560543621f5582/packages/runtime-node/src/runner.ts).

The intended audience is existing Workers users needing hardware control, colocated databases, fewer platform quotas or cloud portability. The README's “no changes” promise must be read alongside its Partial/Pluggable/Not supported matrix. Analytics Engine drops data points; several other unavailable bindings throw. API-shaped compatibility does not imply identical lifecycle, scaling, security or data migration.

## Stack

| Layer | Technology and responsibility |
|---|---|
| CLI/build | TypeScript, Wrangler config loader, esbuild, Node child-process IPC |
| HTTP/runtime | Node.js, Undici, ws, custom Workers globals and import shims |
| Stateful substrate | RivetKit 3.1.2-rc.1; Rivet Actors and SQLite; production durability delegated to Rivet/S3 |
| Binding providers | S3 SDK, OpenAI-compatible AI HTTP, SMTP/SES, browser CDP, optional sandbox SDKs |
| Dynamic code | agentOS VM backend for Worker Loader; distinct from ordinary Workers and local Sandbox provider |
| Tests/docs | Node test runner via tsx, conformance fixtures and saved results; Astro documentation site |

Source: [package.json](https://github.com/rivet-dev/open-orange/blob/0f3c2eac56d7f67d16398d54c4560543621f5582/package.json) and [docs/architecture.mdx](https://github.com/rivet-dev/open-orange/blob/0f3c2eac56d7f67d16398d54c4560543621f5582/docs/architecture.mdx).

## Key Features

### Real platform adaptation, with explicit gaps

The runner builds binding objects and actor definitions, registers configured Durable Object classes, starts queue/cron/tail infrastructure, and dispatches fetch, scheduled, email and queue events. Multi-worker sessions share configured resource IDs while service calls use a separate internal transport. Storage code implements synchronous SQL, transaction gates/savepoints and durability synchronization; it is not merely an in-memory mock. These mechanisms still rely on the pinned Rivet runtime for durable storage and scheduling. See [packages/runtime-node/src/runtime.ts](https://github.com/rivet-dev/open-orange/blob/0f3c2eac56d7f67d16398d54c4560543621f5582/packages/runtime-node/src/runtime.ts), [packages/runtime-node/src/bindings/durable-objects/storage.ts](https://github.com/rivet-dev/open-orange/blob/0f3c2eac56d7f67d16398d54c4560543621f5582/packages/runtime-node/src/bindings/durable-objects/storage.ts) and [packages/runtime-node/src/runner.ts](https://github.com/rivet-dev/open-orange/blob/0f3c2eac56d7f67d16398d54c4560543621f5582/packages/runtime-node/src/runner.ts).

### Hibernation is not scale-to-zero for connected objects

The documented implementation drops the application instance after idle time but keeps the actor, sockets and their state resident. A connected object therefore continues consuming resources; runner churn closes sockets. The documented default SQLite-session limit is 4,000 awake actors per runner connection. Upstream provides memory measurements, but none were reproduced here. Capacity-plan connected actors rather than treating Cloudflare hibernation economics as preserved. See [docs/modules/durable-objects.mdx](https://github.com/rivet-dev/open-orange/blob/0f3c2eac56d7f67d16398d54c4560543621f5582/docs/modules/durable-objects.mdx).

### Migration has meaningful safeguards, not universal reversibility

The migration path wraps a copy of the Worker, protects export/import routes with a shared bearer token, copies SQLite-backed Durable Objects in pages and handles concurrent changes. D1 migration freezes writes, exports, imports and verifies rows/schema before switching. This is substantive engineering, but the Durable Object migrator is also an external dependency, not fully audited here. See [src/commands/migrate.ts](https://github.com/rivet-dev/open-orange/blob/0f3c2eac56d7f67d16398d54c4560543621f5582/src/commands/migrate.ts), [src/commands/migrate-d1.ts](https://github.com/rivet-dev/open-orange/blob/0f3c2eac56d7f67d16398d54c4560543621f5582/src/commands/migrate-d1.ts) and [packages/runtime-node/src/bindings/durable-objects/cloudflare-import.ts](https://github.com/rivet-dev/open-orange/blob/0f3c2eac56d7f67d16398d54c4560543621f5582/packages/runtime-node/src/bindings/durable-objects/cloudflare-import.ts).

The documentation explicitly excludes KV-backed Durable Object classes, facets and various SQL cases; KV namespaces, R2, queues and workflow state do not move through this command. D1 has downtime, with upstream estimates rather than a guarantee. After a D1 switch there is no automated reverse migration. Durable Object rollback resumes the old Cloudflare state: post-cutover writes on Orange do not sync back. Preserve exports and a reconciliation plan; DNS reversal alone is not recovery. See [docs/migrate.mdx](https://github.com/rivet-dev/open-orange/blob/0f3c2eac56d7f67d16398d54c4560543621f5582/docs/migrate.mdx).

## Architecture and Trust Boundaries

1. **Build authority:** Wrangler configuration and custom build commands are executable project inputs. Installing/building an untrusted Worker is not safe merely because its deployment target resembles Workers. The generated image carries application code and the Orange runtime. Even deploy --dry-run calls the configured custom build before writing its output; no deployment API call does not mean no local execution.
2. **Normal runtime:** Node processes and module shims are compatibility machinery, not a workerd isolate security boundary. Some Node APIs are rewritten, including filesystem behavior and Worker-visible process environment; others use stock Node. Run only trusted application code within a container/OS boundary you control, and separate mutually distrustful workloads. Actor namespace identity and resource sharing are routing/storage scopes, not proof of hostile-tenant isolation.
3. **Dynamic Worker Loader:** This path deliberately uses agentOS VMs and fails instead of falling back to host execution. Default outbound allows network; null or Fetcher outbound produces a no-network VM with host-mediated operations. This is a strong design distinction, not evidence that every binding is sandboxed. VM escape resistance and required virtualization availability were not tested. See [packages/runtime-node/src/bindings/worker-loader/agentos.ts](https://github.com/rivet-dev/open-orange/blob/0f3c2eac56d7f67d16398d54c4560543621f5582/packages/runtime-node/src/bindings/worker-loader/agentos.ts) and [docs/modules/worker-loader.mdx](https://github.com/rivet-dev/open-orange/blob/0f3c2eac56d7f67d16398d54c4560543621f5582/docs/modules/worker-loader.mdx).
4. **Sandbox binding:** The default provider is local. Its implementation executes shell commands as host processes with a scoped working directory and reduced environment, not a filesystem or network jail. Absolute paths and reachable host ports remain relevant. Choose a real isolation provider before accepting untrusted commands. Remote providers have their own credentials, retention and billing. See [packages/runtime-node/src/modules/cloudflare-sandbox/providers.ts](https://github.com/rivet-dev/open-orange/blob/0f3c2eac56d7f67d16398d54c4560543621f5582/packages/runtime-node/src/modules/cloudflare-sandbox/providers.ts) and [docs/modules/sandbox.mdx](https://github.com/rivet-dev/open-orange/blob/0f3c2eac56d7f67d16398d54c4560543621f5582/docs/modules/sandbox.mdx).

### Authentication and network exposure

There are real defensive controls: internal session RPC uses timing-safe token comparison; the runtime strips internal metadata headers from incoming requests; forwarded-host overrides require an HMAC secret; migration endpoints compare bearer tokens in constant time; metrics bind loopback. These are valuable transport controls. They do not add end-user login, application authorization, tenant membership checks or a universal CORS policy to Worker endpoints. The Worker and deployment gateway must supply those controls.

Keep runtime/control-plane ports private behind the intended gateway. The front preserves an existing cf-connecting-ip header, while serve mode trusts forwarded scheme metadata: a trusted ingress must sanitize client-supplied forwarding headers before applications use them for authorization or rate limits. This is a static trust-precondition finding, not a demonstrated exploit against Rivet Cloud. No universal outbound deny policy was established for normal Workers; restrict network access at the infrastructure boundary where needed. Evidence: [src/serve/front.ts](https://github.com/rivet-dev/open-orange/blob/0f3c2eac56d7f67d16398d54c4560543621f5582/src/serve/front.ts), [packages/runtime-node/src/session/server.ts](https://github.com/rivet-dev/open-orange/blob/0f3c2eac56d7f67d16398d54c4560543621f5582/packages/runtime-node/src/session/server.ts), [packages/runtime-node/src/runner.ts](https://github.com/rivet-dev/open-orange/blob/0f3c2eac56d7f67d16398d54c4560543621f5582/packages/runtime-node/src/runner.ts) and [packages/runtime-node/src/internal/metrics-server.ts](https://github.com/rivet-dev/open-orange/blob/0f3c2eac56d7f67d16398d54c4560543621f5582/packages/runtime-node/src/internal/metrics-server.ts).

### Credentials and privacy

The CLI stores Rivet login/refresh credentials in a local credentials file using a temporary file, mode 0600 and rename; credentials are not encrypted merely by being permission-restricted. The runtime removes selected Rivet credentials before importing Worker code, and Worker-visible process.env is assembled from bindings. That reduces accidental exposure but is not a hostile-code sandbox. Deployment excludes common local secret/state files and supports cluster secret references rather than baking values into images. Audit build output, logs, arbitrary asset files and application-defined variables separately. Secret rollouts can affect other pools referencing the same cluster secret. See [src/commands/rivet-account.ts](https://github.com/rivet-dev/open-orange/blob/0f3c2eac56d7f67d16398d54c4560543621f5582/src/commands/rivet-account.ts), [src/commands/deploy.ts](https://github.com/rivet-dev/open-orange/blob/0f3c2eac56d7f67d16398d54c4560543621f5582/src/commands/deploy.ts), [packages/runtime-node/src/internal/rivet-credentials.ts](https://github.com/rivet-dev/open-orange/blob/0f3c2eac56d7f67d16398d54c4560543621f5582/packages/runtime-node/src/internal/rivet-credentials.ts) and [packages/runtime-node/src/modules/node/process-env.ts](https://github.com/rivet-dev/open-orange/blob/0f3c2eac56d7f67d16398d54c4560543621f5582/packages/runtime-node/src/modules/node/process-env.ts).

Self-hosting changes who operates infrastructure; it does not guarantee local-only processing. AI binding requests default to OpenRouter when configured, or a chosen OpenAI-compatible endpoint. Prompts, messages and embeddings inputs then cross that provider boundary. R2, browser, email and sandbox integrations similarly send their respective data to configured providers. No provider retention agreement or zero-retention claim was independently verified. Tail consumers receive event records through Rivet Durable Streams; code defaults to one-hour segments with seven-day retention after segment end, deleting consumed segments as it advances. Application logs and external-provider copies require separate deletion policies. See [packages/runtime-node/src/bindings/ai/backend.ts](https://github.com/rivet-dev/open-orange/blob/0f3c2eac56d7f67d16398d54c4560543621f5582/packages/runtime-node/src/bindings/ai/backend.ts) and [packages/runtime-node/src/internal-actors/tail.ts](https://github.com/rivet-dev/open-orange/blob/0f3c2eac56d7f67d16398d54c4560543621f5582/packages/runtime-node/src/internal-actors/tail.ts).

## Persistence, Export and Recovery

Local state lives under the project's .open-orange directory; production placement/durability is supplied by Rivet and its storage backend. SQL transaction/output gating and a sync path are encouraging source-level mechanisms, not a disaster-recovery test. Storage objects, queue/workflow progress, application logs, provider sandboxes and object-store data are separate retention domains. A sandbox ID is saved for reconnect, but provider deletion or expiry can still remove the actual environment; inactivity timeout is documented as a no-op for the Sandbox API.

Migration/import and logical SQLite snapshot code should not be confused with a complete operator backup/export product. Snapshot code preserves schema/rows and handles large integer/blob representation for actor/facet copies, but the inspected CLI's D1 surface is execute and migration operations rather than a universal export/restore command. Before adoption, define consistent backups of Rivet state and external buckets, protect encryption keys/cluster secrets, rehearse restore and test reconnection/idempotency across runner failure. The compatibility documentation marks ctx.restore unsupported. See [packages/runtime-node/src/bindings/durable-objects/sqlite-snapshot.ts](https://github.com/rivet-dev/open-orange/blob/0f3c2eac56d7f67d16398d54c4560543621f5582/packages/runtime-node/src/bindings/durable-objects/sqlite-snapshot.ts), [src/commands/d1.ts](https://github.com/rivet-dev/open-orange/blob/0f3c2eac56d7f67d16398d54c4560543621f5582/src/commands/d1.ts), [docs/modules/durable-objects.mdx](https://github.com/rivet-dev/open-orange/blob/0f3c2eac56d7f67d16398d54c4560543621f5582/docs/modules/durable-objects.mdx) and [docs/modules/sandbox.mdx](https://github.com/rivet-dev/open-orange/blob/0f3c2eac56d7f67d16398d54c4560543621f5582/docs/modules/sandbox.mdx).

## Claims, Tests and Maturity

The public repository was created on 2026-11-12; that dates this public repository, not the beginning of development. At retrieval, GitHub reported 105 stars, 3 forks, last push 2026-11-12T17:06:55Z and one open item (a documentation pull request). Releases v1.0.0 and v1.0.1 were published that day; v1.0.1 at 17:06:57Z. These are activity signals, not reliability proof. [Public metadata](https://api.github.com/repos/rivet-dev/open-orange) / [releases](https://github.com/rivet-dev/open-orange/releases).

The committed conformance snapshot reports **1,670/1,851** total passes, including **1,602/1,774** upstream and **68/77** synthetic. Its Cloudflare category is **844/1,003** and Node category **758/771**. It excludes 399 workerd-only Node cases and 19 infrastructure cases, with nine quota-only tests cut. Crucially it is dated 2026-11-10, identifies Orange ea40348 and a different RivetKit prerelease, and contains a composite-run label. It is useful historical author evidence, not a fresh pass report for the reviewed SHA. [packages/cloudflare-conformance/results/latest.json](https://github.com/rivet-dev/open-orange/blob/0f3c2eac56d7f67d16398d54c4560543621f5582/packages/cloudflare-conformance/results/latest.json) and [packages/cloudflare-conformance/README.md](https://github.com/rivet-dev/open-orange/blob/0f3c2eac56d7f67d16398d54c4560543621f5582/packages/cloudflare-conformance/README.md) explain scoring and exclusions.

CI declares typecheck, build, example-manifest validation, npm pack inspection and full tests; the full suite uses a larger Depot runner because it starts many processes/engines. Actions use version tags rather than commit pins. A release run on the reviewed SHA reported success ([run](https://github.com/rivet-dev/open-orange/actions/runs/43265786201)); that is not this review executing the suite or checking every deployed platform. Broad tests cover storage, RPC, gates, hibernation, migration and providers, but paid-provider/VM tests and upstream conformance require additional infrastructure. [.github/workflows/ci.yaml](https://github.com/rivet-dev/open-orange/blob/0f3c2eac56d7f67d16398d54c4560543621f5582/.github/workflows/ci.yaml).

**Review limits:** no dependency vulnerability scan, package artifact/source equivalence verification, cloud deployment, throughput/cost measurement, crash-recovery exercise or security exploit validation. Rivet Engine, cloud control-plane internals and provider SDK internals were not comprehensively reviewed. No source code was executed.

## Provider Flows and Costs

The 4.8× compute and 8.7× storage claims compare selected Cloudflare meters to raw AWS Graviton/S3 prices with stated headroom. They omit a demonstrated application-level total-cost comparison: include utilization, control plane, replicas, egress, S3 requests, backups, monitoring, operators and managed Rivet fees. AI/browser/sandbox/email providers add separate bills. A quiet or spiky Worker can be cheaper on Cloudflare. No local AI model is required for basic runtime use, and AI inference is optional.

There is also an actionable architecture mismatch to qualify: the cost illustration uses ARM Graviton, but the inspected generated Dockerfile and build command explicitly target linux/amd64. Do not apply that price model to the stock deployment without validating an appropriate ARM build and dependency/runtime support. Evidence: [README.md](https://github.com/rivet-dev/open-orange/blob/0f3c2eac56d7f67d16398d54c4560543621f5582/README.md) and [src/commands/deploy.ts](https://github.com/rivet-dev/open-orange/blob/0f3c2eac56d7f67d16398d54c4560543621f5582/src/commands/deploy.ts).

## Comparison

| Option | Best fit | Tradeoff |
|---|---|---|
| OpenOrange | Existing Workers apps needing portable stateful hosting | Many adapters; Node/Rivet semantics and operator responsibilities need qualification |
| Cloudflare Workers/Durable Objects | Managed platform, existing production semantics and edge integration | Platform limits, service pricing and vendor coupling |
| workerd | Original open-source Workers runtime semantics | A runtime, not all managed Cloudflare services or a full distributed control plane |
| Miniflare | Local Workers development/testing | Not a substitute for production distributed hosting |
| Rivet directly | New actor-oriented applications | Avoids compatibility translation, but requires using Rivet APIs rather than preserving Workers APIs |

These are architectural comparisons, not fresh benchmark results or audits of those alternatives. For related public context see [Cloudflare computer](cloudflare-computer.md) and [tailnet-do](tailnet-do.md); neither review establishes OpenOrange compatibility for those projects.

## Self-Hosting Notes

- Baseline requires Node.js 22+ and pnpm; deployment needs Docker plus a Rivet control plane, runners, registry and durable storage. The generated image uses Node 24 slim, linux/amd64, an unpinned base-image tag and no explicit non-root USER. Add deliberate image pinning, non-root qualification, resource limits and network policy.
- Dependencies are mostly pinned, but include RivetKit 3.1.2-rc.1 and some ranged packages. The generated production layer uses a frozen lockfile and ignore-scripts, which reduces install-script exposure; it does not make the global CLI install or application build harmless. Source prepare/prepack builds and project custom builds are execution boundaries.
- Inventory every binding and compatibility gap before migration. Exercise data types, concurrency, alarm retries, WebSocket reconnects, cron cutover, queue idempotency, provider outages and realistic capacity in a disposable staging deployment.
- Keep old images/configuration and data backups, but distinguish code rollback from state rollback. Pin matched CLI/runtime/Engine versions and rehearse upgrade/restore before replacing live runners.

## License and Reuse

The root contains the Apache-2.0 license, including its notice, modification and patent conditions. The vendored Cloudflare Workflows engine includes a separate MIT attribution/license and a pinned upstream provenance note. Preserve applicable notices when redistributing; the npm dependency graph and external service contracts remain separate obligations. No code was extracted for this review. [LICENSE](https://github.com/rivet-dev/open-orange/blob/0f3c2eac56d7f67d16398d54c4560543621f5582/LICENSE) and [packages/runtime-node/src/bindings/workflows/engine/LICENSE](https://github.com/rivet-dev/open-orange/blob/0f3c2eac56d7f67d16398d54c4560543621f5582/packages/runtime-node/src/bindings/workflows/engine/LICENSE).

---

**Attribution:** Rivet / rivet-dev/open-orange, Apache-2.0; Cloudflare-origin components retain their stated licenses. Analysis is based on public source and metadata retrieved 2026-11-12.
