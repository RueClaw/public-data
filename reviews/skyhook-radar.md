# Radar (skyhook-io/radar)

**Repo:** https://github.com/skyhook-io/radar
**License:** Apache-2.0; preserve license/notices and observe patent terms; no trademark grant. [license](https://github.com/skyhook-io/radar/blob/711f4b425a64a6871f8cf604d895a4cb590f83cb/LICENSE)
**Reviewed:** 2026-11-28 (UTC)
**Revision:** 711f4b425a64a6871f8cf604d895a4cb590f83cb, also tag v1.22.0. Scope: repository-wide static sampling, especially CLI/bootstrap, server, auth, MCP, AI, Cloud, timeline, permission code, Helm, manifests and CI.
**Verification:** Anonymous API/HTTPS acquisition and tag lookup; static inspection only. No installation, source execution, cluster/cloud connection, account login, paid/model call or security probe. Tests not run locally.
**Stack:** Go, client-go, chi, React/TypeScript/Vite, MCP Go SDK, Helm, SQLite/PostgreSQL, optional Wails desktop shell.
**What it is:** A Kubernetes operations UI and cluster-context MCP server, not a passive scanner.

---

## Verdict

⚠️ **Interesting — strong local workbench; shared deployment needs an explicit trust design.** Radar combines topology, issues, changes and agent-readable evidence. Distinct read-only MCP catalogs and explicit storage degradation are useful, but ordinary namespaced reads do not exactly reproduce per-kind Kubernetes RBAC, full MCP supports writes, and AI/Cloud expand authority and data exposure. Pilot with least privilege before adopting it as a shared control plane.

## What It Is

Skyhook’s Radar runs against local kubeconfig, as a desktop app, or in Kubernetes through Helm. Go watchers populate a shared model served through a React UI, SSE and MCP. Features cover resources, topology, issues, logs, Helm/GitOps, traffic, metrics and change history. Richer views need existing integrations: “no agents” describes the basic client, not all possible data sources. [readme](https://github.com/skyhook-io/radar/blob/711f4b425a64a6871f8cf604d895a4cb590f83cb/README.md)

Radar also drives installed AI CLIs and optionally connects to Radar Cloud via an outbound tunnel. Neither is required for local browsing. The client is reviewed here, not the remote Cloud service’s tenancy, retention or security. [cloud](https://github.com/skyhook-io/radar/blob/711f4b425a64a6871f8cf604d895a4cb590f83cb/internal/cloud/client.go)

## Stack

| Layer | Tech |
|-------|------|
| Backend | Go 1.27.4 declaration; chi; client-go 0.37.2 |
| UI | React 19, TypeScript, Vite, TanStack Query, XYFlow/ELK; shared k8s-ui |
| Operations | Kubernetes API/informers, Helm v3, integration clients |
| Agents | MCP Go SDK; HTTP/stdio; subprocess adapters |
| Persistence | Memory timeline; optional SQLite/pgx PostgreSQL; separate SQLite investigation store |
| Auth | Optional OIDC/trusted proxy; Kubernetes SAR and impersonation |
| Cloud | WebSocket plus yamux tunnel |

Versions are manifest observations, not tested compatibility or vulnerability clearance. [gomod](https://github.com/skyhook-io/radar/blob/711f4b425a64a6871f8cf604d895a4cb590f83cb/go.mod) [web](https://github.com/skyhook-io/radar/blob/711f4b425a64a6871f8cf604d895a4cb590f83cb/web/package.json)

## Key Features

### Shared contextual model

Relationships, issues and recent changes reduce repeated raw-object exploration. MCP builds distinct read-only and full catalogs rather than relying on a prompt not to mutate. Investigation/apply transports are separate; the apply catalog removes deletion and Helm-management tools. [mcp](https://github.com/skyhook-io/radar/blob/711f4b425a64a6871f8cf604d895a4cb590f83cb/internal/mcp/server.go)

### History with explicit gaps

SQLite uses WAL/cleanup and distinguishes corruption from locking/permission failures; corruption is quarantined and unavailable SQLite can degrade to explicitly marked memory. PostgreSQL startup outages leave history unavailable and reconnect rather than silently pretending memory is durable. Observation-start timestamps bound claims about periods actually watched. These are good patterns, not tested disaster-recovery guarantees. [manager](https://github.com/skyhook-io/radar/blob/711f4b425a64a6871f8cf604d895a4cb590f83cb/internal/timeline/manager.go) [sqlite](https://github.com/skyhook-io/radar/blob/711f4b425a64a6871f8cf604d895a4cb590f83cb/internal/timeline/sqlite_store.go) [postgres](https://github.com/skyhook-io/radar/blob/711f4b425a64a6871f8cf604d895a4cb590f83cb/internal/timeline/postgres_store.go)

### Not a read-only dashboard

Full MCP and UI expose mutation workflows under the effective Kubernetes identity. The read-only endpoint excludes writes; the MCP read-only flag does not disable UI writes. Opt-in MCP exec can change containers/external systems and returns unredacted output. Destructive-tool annotations are not a universal server-enforced human approval boundary for arbitrary clients. [readme](https://github.com/skyhook-io/radar/blob/711f4b425a64a6871f8cf604d895a4cb590f83cb/README.md) [mcp](https://github.com/skyhook-io/radar/blob/711f4b425a64a6871f8cf604d895a4cb590f83cb/internal/mcp/server.go) [exec](https://github.com/skyhook-io/radar/blob/711f4b425a64a6871f8cf604d895a4cb590f83cb/internal/mcp/tools_exec.go)

## Architecture

Kubeconfig/ServiceAccount → watchers and shared cache → contextual permission/read layer → REST/SSE/MCP → React or agent.

Optional Cloud hub → authenticated outbound WebSocket/yamux transport → the same HTTP router.

Startup composes services in internal/app; internal/server integrates HTTP, internal/k8s collects state, pkg/auth discovers permissions, and internal/mcp exposes tools. Domain modules handle integrations/storage. Shared Go/UI packages offer reuse seams, but the large routing module and many authorization-sensitive integrations increase maintenance complexity. The efficient shared cache is also a privileged aggregation boundary. [server](https://github.com/skyhook-io/radar/blob/711f4b425a64a6871f8cf604d895a4cb590f83cb/internal/server/server.go) [permissions](https://github.com/skyhook-io/radar/blob/711f4b425a64a6871f8cf604d895a4cb590f83cb/pkg/auth/permissions.go) [tunnel](https://github.com/skyhook-io/radar/blob/711f4b425a64a6871f8cf604d895a4cb590f83cb/internal/cloud/serve.go)

## Security, Privileges and Privacy

### Local default versus shared exposure

CLI defaults to loopback. Docker/Helm shared listeners need an explicit network/auth decision: authentication defaults to none, so reachable clients act with Radar’s Kubernetes identity. Host validation, CORS and origin/fetch-metadata checks address browser threats; headerless non-browser requests are intentionally supported. CORS is not authentication. Do not expose an unauthenticated ingress based on a read-only assumption. [listener](https://github.com/skyhook-io/radar/blob/711f4b425a64a6871f8cf604d895a4cb590f83cb/internal/server/listen_address.go) [origin](https://github.com/skyhook-io/radar/blob/711f4b425a64a6871f8cf604d895a4cb590f83cb/internal/server/cross_site.go) [authdoc](https://github.com/skyhook-io/radar/blob/711f4b425a64a6871f8cf604d895a4cb590f83cb/docs/authentication.md)

Proxy mode accepts forwarded identity headers; the proxy must strip supplied identities and be the only backend path. Normal auth deployment grants users/groups impersonation and SubjectAccessReview creation. Reserved-identity filtering is useful, but a compromised Radar process remains a high-value cluster principal. [middleware](https://github.com/skyhook-io/radar/blob/711f4b425a64a6871f8cf604d895a4cb590f83cb/internal/auth/middleware.go) [rbac](https://github.com/skyhook-io/radar/blob/711f4b425a64a6871f8cf604d895a4cb590f83cb/deploy/helm/radar/templates/clusterrole.yaml)

### Per-user RBAC is not exact read parity

Namespace discovery checks cluster-wide pod listing, then pod/deployment listing per namespace. Ordinary namespaced cached reads use that visibility: a pod reader can see ConfigMaps even where direct Kubernetes authorization would deny them. Secrets, selected sensitive kinds and cluster-scoped resources have tighter gates; writes use caller identity. This is documented behavior, not a newly demonstrated bypass. Separate namespace-scoped instances are a better fit for strict tenant boundaries. [permissions](https://github.com/skyhook-io/radar/blob/711f4b425a64a6871f8cf604d895a4cb590f83cb/pkg/auth/permissions.go) [authdoc](https://github.com/skyhook-io/radar/blob/711f4b425a64a6871f8cf604d895a4cb590f83cb/docs/authentication.md)

Raw PromQL/aggregate metrics use broad pod visibility for authorization but Radar’s credentials to query Prometheus; that backend still needs tenant isolation. Documentation also acknowledges limited matching-information disclosure through narrowed relationship results involving hidden cached objects. [authdoc](https://github.com/skyhook-io/radar/blob/711f4b425a64a6871f8cf604d895a4cb590f83cb/docs/authentication.md)

### Render privileges rather than trusting one checkbox

Default Helm values disable general Secret reads, Helm writes, pod exec, port forwarding and self-upgrade; pod logs and broad inventory remain. Traffic integration has its own certificate-secret grant. Auth or Cloud automatically enables cache Secret reads even when rbac.secrets is false. Enabling Helm writes without auth adds create/update/patch/delete across all API groups/resources. [values](https://github.com/skyhook-io/radar/blob/711f4b425a64a6871f8cf604d895a4cb590f83cb/deploy/helm/radar/values.yaml) [rbac](https://github.com/skyhook-io/radar/blob/711f4b425a64a6871f8cf604d895a4cb590f83cb/deploy/helm/radar/templates/clusterrole.yaml)

Cloud is off by default. When enabled it tunnels the router, including SSE, exec and MCP, and advertises cluster/installation metadata. Tunnel requests carry a private in-process marker; Cloud auth refuses spoofed forwarded identities on the ordinary TCP listener. That is concrete hardening, but Cloud is still a remote authority/data recipient. Avoid insecure TLS bypass. User-token mode has separate chart checks requiring verified transport and different RBAC assumptions. Reconnection uses bounded exponential backoff. [cloud](https://github.com/skyhook-io/radar/blob/711f4b425a64a6871f8cf604d895a4cb590f83cb/internal/cloud/client.go) [tunnel](https://github.com/skyhook-io/radar/blob/711f4b425a64a6871f8cf604d895a4cb590f83cb/internal/cloud/serve.go) [middleware](https://github.com/skyhook-io/radar/blob/711f4b425a64a6871f8cf604d895a4cb590f83cb/internal/auth/middleware.go) [rbac](https://github.com/skyhook-io/radar/blob/711f4b425a64a6871f8cf604d895a4cb590f83cb/deploy/helm/radar/templates/clusterrole.yaml)

### Agent context is sensitive

MCP withholds Secret value fields and AI context uses key/shape heuristics. Regex cannot guarantee removal of arbitrary credentials, business data or unusual encodings. Read-only tools prevent mutation through that catalog, not disclosure to the model provider or prompt injection from logs/resources. Opt-in exec returns raw output. [readme](https://github.com/skyhook-io/radar/blob/711f4b425a64a6871f8cf604d895a4cb590f83cb/README.md) [redact](https://github.com/skyhook-io/radar/blob/711f4b425a64a6871f8cf604d895a4cb590f83cb/pkg/ai/context/redact.go) [exec](https://github.com/skyhook-io/radar/blob/711f4b425a64a6871f8cf604d895a4cb590f83cb/internal/mcp/tools_exec.go)

Claude’s safeguarded adapter disables built-in tools and constrains MCP. Codex requests read-only sandboxing and constrained configuration. Cursor/OpenCode full-local paths retain other configured tools and auto-approve requests: Radar’s read-only catalog does not bound their authority. Approve the particular adapter, provider and tool setup, not merely the Investigate button. [claude](https://github.com/skyhook-io/radar/blob/711f4b425a64a6871f8cf604d895a4cb590f83cb/internal/ai/agent_claude.go) [codex](https://github.com/skyhook-io/radar/blob/711f4b425a64a6871f8cf604d895a4cb590f83cb/internal/ai/agent_codex.go) [cursor](https://github.com/skyhook-io/radar/blob/711f4b425a64a6871f8cf604d895a4cb590f83cb/internal/ai/agent_cursor.go) [opencode](https://github.com/skyhook-io/radar/blob/711f4b425a64a6871f8cf604d895a4cb590f83cb/internal/ai/agent_opencode.go)

### Local-first does not mean unconditional no-egress

Usage reporting is consent-controlled and off unless opted in; payloads contain counts/coarse cluster facts. Release checking has vendor/GitHub endpoints. Registries, metrics, OIDC, Cloud and agents introduce further destinations. No egress capture or airgap test was performed. [usage](https://github.com/skyhook-io/radar/blob/711f4b425a64a6871f8cf604d895a4cb590f83cb/internal/usagedata/usagedata.go) [payload](https://github.com/skyhook-io/radar/blob/711f4b425a64a6871f8cf604d895a4cb590f83cb/internal/usagedata/report.go) [version](https://github.com/skyhook-io/radar/blob/711f4b425a64a6871f8cf604d895a4cb590f83cb/internal/version/version.go)

Authenticated image inspection is documented to gate images by readable Pods, constrain credential use/connections and reject metadata/link-local destinations. Private addresses remain allowed for enterprise registries; local unauthenticated credential discovery is broader. Redirect/credential-provider behavior was not exhaustively traced; SSRF resistance was not proven. [authdoc](https://github.com/skyhook-io/radar/blob/711f4b425a64a6871f8cf604d895a4cb590f83cb/docs/authentication.md)

## Persistence and Recovery

Memory timeline is bounded and restart-volatile. The chart defaults persistent-backend retention to 168 hours; SQLite needs writable persistent storage with the hardened container filesystem. Configure retention/capacity/backups together. This is observed history, not a cluster backup or complete audit system; downtime and database failures leave evidence gaps. [values](https://github.com/skyhook-io/radar/blob/711f4b425a64a6871f8cf604d895a4cb590f83cb/deploy/helm/radar/values.yaml) [manager](https://github.com/skyhook-io/radar/blob/711f4b425a64a6871f8cf604d895a4cb590f83cb/internal/timeline/manager.go) [sqlite](https://github.com/skyhook-io/radar/blob/711f4b425a64a6871f8cf604d895a4cb590f83cb/internal/timeline/sqlite_store.go)

Investigation transcripts have separate SQLite persistence with private file creation, transactional event/summary boundaries and degraded-state reporting for disk/queue failures. These are sensitive records requiring access controls and deletion policy. No restore, crash injection, migration or multi-replica consistency test was run. [aistore](https://github.com/skyhook-io/radar/blob/711f4b425a64a6871f8cf604d895a4cb590f83cb/internal/ai/store.go)

## Maturity, Dependencies and Claim Evidence

Anonymous GitHub metadata retrieved 2026-11-28 reported 4,251 stars, 284 forks and 122 open issues/PRs combined; push time was 2026-11-28T01:58:57Z. Latest release v1.22.0 was published 2026-11-27T23:44:06Z; its public tag resolves exactly to the reviewed SHA. Previous releases observed: v1.21.5 and v1.21.4. Popularity/activity do not prove safety. [Public metadata](https://api.github.com/repos/skyhook-io/radar) · [Release](https://github.com/skyhook-io/radar/releases/tag/v1.22.0)

There are 1,048 internal Go test files, including auth/MCP/Cloud/storage regressions. CI defines Go tests/vet/build, PostgreSQL tests, frontend tests/typecheck/lint/build, browser settings journeys and Helm render/negative/unit tests. Anonymous Actions metadata reported successful [CI](https://github.com/skyhook-io/radar/actions/runs/46082464479) and [CodeQL](https://github.com/skyhook-io/radar/actions/runs/46082464482) for this SHA. These are upstream-reported results, not local execution or review of every log. [ci](https://github.com/skyhook-io/radar/blob/711f4b425a64a6871f8cf604d895a4cb590f83cb/.github/workflows/ci.yml)

Go sums and npm lockfile are present. Kubernetes, Helm, registry/cloud SDKs, OIDC, MCP, database and desktop/UI libraries form a large dependency surface. CI uses mutable major-version actions alongside some SHA pins. No dependency install, SBOM/CVE/transitive-license audit, release reproducibility or binary-signature verification was performed. Apache-2.0 permits reuse under its terms; dependencies still need separate license accounting. [gomod](https://github.com/skyhook-io/radar/blob/711f4b425a64a6871f8cf604d895a4cb590f83cb/go.mod) [web](https://github.com/skyhook-io/radar/blob/711f4b425a64a6871f8cf604d895a4cb590f83cb/web/package.json) [ci](https://github.com/skyhook-io/radar/blob/711f4b425a64a6871f8cf604d895a4cb590f83cb/.github/workflows/ci.yml) [license](https://github.com/skyhook-io/radar/blob/711f4b425a64a6871f8cf604d895a4cb590f83cb/LICENSE)

| Claim | Evidence assessment |
|-------|---------------------|
| Single binary, no account | Consistent with local core; integrations and agent CLIs remain dependencies. |
| Read-only agent access | Separate catalog exists; full MCP and other agent tools are outside that guarantee. |
| Per-user RBAC | Qualified by namespace-level ordinary reads and sensitive-kind exceptions. |
| Private by design | Local/opt-in baseline, qualified by integrations, agents, Cloud and update traffic. |
| About 3× faster diagnosis | README vendor SREGym study reports 64s versus 191s; not independently reproduced. |
| Large-cluster speed | Cache/informer rationale is plausible; no load test performed. |

## Comparison

Workflow-fit comparison, not fresh audits/benchmarks of alternatives.

| Aspect | Radar | K9s | Headlamp |
|--------|-------|-----|----------|
| Fit | Contextual UI plus MCP/investigations | Terminal operations | Web UI and plugins |
| Advantage | Shared topology/issues/history | Direct terminal workflow | Conventional extensible UI |
| Choose when | Correlated context and MCP matter | Kubectl-style work suffices | UI/plugin customization matters |

Consider [K9s](https://github.com/derailed/k9s) or [Headlamp](https://github.com/kubernetes-sigs/headlamp) before adding a broad operations surface. [HolmesGPT](https://github.com/robusta-dev/holmesgpt) is an investigation-oriented alternative if diagnosis matters more than integrated UI. Radar does not replace durable metrics, GitOps reconciliation, audit retention or backups.

## Self-Hosting Notes

1. Pilot locally with restricted kubeconfig; effective authority includes credential-plugin behavior.
2. Start agents on the read-only MCP endpoint; separately restrict UI/Kubernetes writes and exec. Prefer safeguarded adapters over full-local auto-approval.
3. For shared use, configure TLS/OIDC or an isolated trusted proxy. Scope cache/service-account namespaces and inspect rendered Secret, impersonation and Helm grants.
4. Keep Cloud/telemetry off unless approved; review registry/metrics/provider egress separately and never bypass TLS verification in production.
5. Choose durable history deliberately, protect transcripts, test restore and validate with representative user identities before rollout.
6. Pin releases and independently verify distribution integrity. No installer/deployment was executed here.

## Verification and Limitations

Verified anonymous accessibility, canonical deduplication against public reviews/index, exact SHA/tag, release metadata, selected source paths, chart defaults and upstream CI status. Targeted static analysis, not exhaustive certification. No exploit was attempted or confirmed. Runtime integration-wide authorization, performance, provider costs, Cloud security and recovery guarantees remain unverified.

## Sources

Code references are pinned to the reviewed commit. Public owner: Skyhook / skyhook-io/radar contributors.

- [license](https://github.com/skyhook-io/radar/blob/711f4b425a64a6871f8cf604d895a4cb590f83cb/LICENSE)
- [readme](https://github.com/skyhook-io/radar/blob/711f4b425a64a6871f8cf604d895a4cb590f83cb/README.md)
- [cloud](https://github.com/skyhook-io/radar/blob/711f4b425a64a6871f8cf604d895a4cb590f83cb/internal/cloud/client.go)
- [gomod](https://github.com/skyhook-io/radar/blob/711f4b425a64a6871f8cf604d895a4cb590f83cb/go.mod)
- [web](https://github.com/skyhook-io/radar/blob/711f4b425a64a6871f8cf604d895a4cb590f83cb/web/package.json)
- [mcp](https://github.com/skyhook-io/radar/blob/711f4b425a64a6871f8cf604d895a4cb590f83cb/internal/mcp/server.go)
- [manager](https://github.com/skyhook-io/radar/blob/711f4b425a64a6871f8cf604d895a4cb590f83cb/internal/timeline/manager.go)
- [sqlite](https://github.com/skyhook-io/radar/blob/711f4b425a64a6871f8cf604d895a4cb590f83cb/internal/timeline/sqlite_store.go)
- [postgres](https://github.com/skyhook-io/radar/blob/711f4b425a64a6871f8cf604d895a4cb590f83cb/internal/timeline/postgres_store.go)
- [exec](https://github.com/skyhook-io/radar/blob/711f4b425a64a6871f8cf604d895a4cb590f83cb/internal/mcp/tools_exec.go)
- [server](https://github.com/skyhook-io/radar/blob/711f4b425a64a6871f8cf604d895a4cb590f83cb/internal/server/server.go)
- [permissions](https://github.com/skyhook-io/radar/blob/711f4b425a64a6871f8cf604d895a4cb590f83cb/pkg/auth/permissions.go)
- [tunnel](https://github.com/skyhook-io/radar/blob/711f4b425a64a6871f8cf604d895a4cb590f83cb/internal/cloud/serve.go)
- [listener](https://github.com/skyhook-io/radar/blob/711f4b425a64a6871f8cf604d895a4cb590f83cb/internal/server/listen_address.go)
- [origin](https://github.com/skyhook-io/radar/blob/711f4b425a64a6871f8cf604d895a4cb590f83cb/internal/server/cross_site.go)
- [authdoc](https://github.com/skyhook-io/radar/blob/711f4b425a64a6871f8cf604d895a4cb590f83cb/docs/authentication.md)
- [middleware](https://github.com/skyhook-io/radar/blob/711f4b425a64a6871f8cf604d895a4cb590f83cb/internal/auth/middleware.go)
- [rbac](https://github.com/skyhook-io/radar/blob/711f4b425a64a6871f8cf604d895a4cb590f83cb/deploy/helm/radar/templates/clusterrole.yaml)
- [values](https://github.com/skyhook-io/radar/blob/711f4b425a64a6871f8cf604d895a4cb590f83cb/deploy/helm/radar/values.yaml)
- [redact](https://github.com/skyhook-io/radar/blob/711f4b425a64a6871f8cf604d895a4cb590f83cb/pkg/ai/context/redact.go)
- [claude](https://github.com/skyhook-io/radar/blob/711f4b425a64a6871f8cf604d895a4cb590f83cb/internal/ai/agent_claude.go)
- [codex](https://github.com/skyhook-io/radar/blob/711f4b425a64a6871f8cf604d895a4cb590f83cb/internal/ai/agent_codex.go)
- [cursor](https://github.com/skyhook-io/radar/blob/711f4b425a64a6871f8cf604d895a4cb590f83cb/internal/ai/agent_cursor.go)
- [opencode](https://github.com/skyhook-io/radar/blob/711f4b425a64a6871f8cf604d895a4cb590f83cb/internal/ai/agent_opencode.go)
- [usage](https://github.com/skyhook-io/radar/blob/711f4b425a64a6871f8cf604d895a4cb590f83cb/internal/usagedata/usagedata.go)
- [payload](https://github.com/skyhook-io/radar/blob/711f4b425a64a6871f8cf604d895a4cb590f83cb/internal/usagedata/report.go)
- [version](https://github.com/skyhook-io/radar/blob/711f4b425a64a6871f8cf604d895a4cb590f83cb/internal/version/version.go)
- [aistore](https://github.com/skyhook-io/radar/blob/711f4b425a64a6871f8cf604d895a4cb590f83cb/internal/ai/store.go)
- [ci](https://github.com/skyhook-io/radar/blob/711f4b425a64a6871f8cf604d895a4cb590f83cb/.github/workflows/ci.yml)

---

**Attribution:** skyhook-io/radar contributors, Apache-2.0. Independent analysis; no source code extracted.
