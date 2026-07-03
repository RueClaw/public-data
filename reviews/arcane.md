# Arcane (getarcaneapp/arcane)

**Repo:** https://github.com/getarcaneapp/arcane  
**License:** BSD-3-Clause, permissive reuse with attribution and non-endorsement requirements  
**Reviewed:** 2026-07-03  
**Commit reviewed:** `6987b5e046c3a00c54c88ee54219dc8f79d87c1e`  
**Stack:** Go 1.26, Echo, Huma v2, GORM, SQLite/Postgres, Docker/Moby, Docker Compose v5, SvelteKit 3, Svelte 5, TypeScript, Tailwind CSS, TanStack Query/Table, Playwright, Goreleaser, GHCR  
**What it is:** A self-hosted Docker management UI with local and remote environment management, Compose project workflows, image updates, vulnerability scanning, RBAC, API keys, OIDC, GitOps syncs, webhooks, and optional edge agents.

---

## Verdict

✅ **Deploy candidate for serious self-hosted Docker management, with the usual Docker-socket caution.** Arcane is much more than a prettier container list: it has typed APIs, granular RBAC, multi-environment support, edge agents, vulnerability scanning, GitOps syncs, signed multi-arch releases, and a real test suite. The main risk is inherent to the product category: a management UI with Docker socket access is a high-trust control plane, so internet exposure, weak secrets, broad roles, or direct socket mounting are the mistakes to avoid.

---

## What It Is

Arcane is a modern web control plane for Docker and Docker Compose. It gives operators a browser UI and CLI surface for containers, projects, images, volumes, networks, ports, events, updates, users, roles, API keys, notifications, templates, registries, Git repositories, GitOps syncs, and system actions.

The project is aimed at self-hosters and small operators who want something more approachable than raw Docker CLI commands but more operationally complete than a simple dashboard. It can run against the local Docker socket, through a socket proxy, or through Arcane agents that connect back to a manager.

The repository is unusually active and polished for this space. At review time it had 6,153 stars, 226 forks, 140 open issues, a July 3 2026 push, v2.3.1 release notes, a BSD-3-Clause license, CI for Go/Svelte/E2E/image checks, signed release images, SBOM/provenance settings, and explicit AI contribution policy.

## Stack

| Layer | Tech |
|-------|------|
| Backend | Go 1.26, Echo, Huma v2, GORM |
| API | Typed Huma handlers, OpenAPI/Scalar docs, JWT bearer auth, API key auth |
| Database | SQLite by default, Postgres support through GORM/migrations |
| Docker Runtime | Docker/Moby SDK, Docker CLI, Docker Compose v5, BuildKit |
| Frontend | SvelteKit 3, Svelte 5 runes, TypeScript, Tailwind CSS |
| UI Data | TanStack Query, TanStack Table, virtualized tables |
| Auth | Local users, OIDC, sessions, API keys, scoped environment tokens |
| Remote Environments | Direct agent mode, edge agent WebSocket/gRPC tunnel, optional mTLS |
| Automation | GitOps syncs, webhooks, scheduler jobs, auto-update, auto-heal, notifications |
| Supply Chain | GitHub Actions, Goreleaser, GHCR multi-arch images, cosign, provenance, SBOM |

## Key Features

### Docker and Compose Operations

Arcane covers the expected Docker surfaces: container start/stop/restart/redeploy/delete, logs, terminal exec, stats, image pull/build/tag/commit/prune/delete/upload, volume browse/upload/backup/restore, network views, ports, prune, update checks, and dashboard action items.

Compose projects are first-class. The backend includes project discovery, compose parsing, runtime state, project file tree access, Git-backed sync, pre-deploy hooks, project archive/unarchive, and image reference extraction.

### Multi-Environment and Edge Agents

Environment ID `"0"` is the local Docker socket. Additional environments can be paired through API keys or agent tokens. Edge agents can dial out to the manager over WebSocket or gRPC tunnel, which is the right shape for remote hosts behind NAT or firewalls.

The edge tunnel does not just proxy arbitrary URLs. `backend/pkg/libarcane/edge/commands.go` maps method/path patterns to named commands, including stream routes for logs, stats, terminal, and system stats. That command registry is a useful boundary for remote Docker control planes.

### RBAC and API Authorization

The permission catalog is broad and explicit: users, roles, API keys, federated credentials, settings, environments, registries, templates, Git repositories, diagnostics, containers, projects, images, volumes, networks, swarm, GitOps, webhooks, jobs, notifications, system, vulnerabilities, build workspaces, and activities.

Permissions distinguish global and environment-scoped capabilities. Built-in roles include Admin, Editor, No Shell Editor, Deployer, Monitor, and Viewer. The UI reachability registry is backend-owned metadata, while middleware and handlers remain authoritative.

### Security-Conscious Defaults and Documentation

Good signs:

- CSRF middleware checks cookie-backed cross-origin state changes and bypasses only header-authenticated or explicitly public endpoints.
- Agent token checks use constant-time comparison.
- API key and JWT auth are distinct security schemes.
- GitOps lifecycle hooks are separated behind a special `gitops:lifecycle` permission because hooks can become host code execution.
- Docker secret-style `_FILE` env handling exists for sensitive configuration.
- Compose examples include a Docker socket proxy option rather than only direct socket mounting.
- Release workflows publish multi-arch images with SBOM, provenance, and cosign signing.
- The project has a public AI contribution policy that rejects unverified AI-generated changes and public AI-generated vulnerability reports.

### Operational Polish

The repo has 60+ SQLite/Postgres migrations, extensive backend unit tests, Playwright E2E structure, docs links, release automation, localization via Crowdin/Paraglide, Snyk badge/config, issue templates that explicitly warn users to scrub secrets, and Dependabot-managed dependency churn.

## Architecture

The backend is split into thin Huma handlers, injected services, GORM models, Docker helpers, edge tunnel libraries, scheduler jobs, and shared `types/` packages consumed by the CLI. Echo owns the router; Huma owns typed REST/OpenAPI; raw Echo routes are reserved for WebSockets, streaming, diagnostics, webhooks, Playwright routes, and embedded frontend.

The frontend is a SvelteKit app organized by product surfaces. It uses Svelte 5 runes, generated message functions for i18n, shared service clients, and route-level data loading. The repo's `AGENTS.md` is blunt about local conventions: no duplicate service wrappers, no new API standard, no hardcoded UI strings, and no Svelte 4 syntax.

The most interesting architectural choice is the remote-environment model. Arcane combines environment-scoped permissions, command allowlisting, edge tunnel registration, optional generated mTLS enrollment, and remote event sync. That is the right direction for a Docker manager that wants to control more than localhost without exposing every remote daemon directly.

## Comparison

| Aspect | Arcane | Portainer-style managers | Simple Docker dashboards |
|--------|--------|--------------------------|--------------------------|
| Primary fit | Self-hosted Docker/Compose control plane | Broad Docker/Kubernetes management | Read-only or light single-host visibility |
| License | BSD-3-Clause | Often mixed/community/commercial | Varies |
| Remote hosts | Edge/direct agents with command routing | Agent models vary by edition | Often absent |
| RBAC | Granular global and env-scoped catalog | Mature in established products | Usually minimal |
| GitOps | Git repos, syncs, hooks, webhooks | Product-dependent | Usually absent |
| Security posture | Strong signals, but high-trust Docker socket surface | Mature but edition-dependent | Often simpler and less guarded |
| Maturity | Very active, fast-moving v2.x | More established | Depends heavily on project |

## Self-Hosting Notes

Arcane can run from GHCR with a basic Compose file:

- mount `/var/run/docker.sock` directly for simplest local management;
- set strong `ENCRYPTION_KEY` and `JWT_SECRET`;
- persist `/app/data`;
- set `PROJECTS_DIRECTORY` if managing Compose projects from host paths;
- prefer the provided socket-proxy compose example when exposing the app beyond a trusted LAN;
- use OIDC and scoped roles/API keys for multi-user operation;
- treat GitOps lifecycle hooks and terminal exec as high-risk capabilities.

The direct socket mount is the critical deployment choice. Anyone who can exercise enough Arcane permissions against that socket can effectively control the host. Arcane has better internal permission machinery than many tools in this category, but Docker socket exposure is still Docker socket exposure.

## Verification

Local verification on macOS:

- cloned `getarcaneapp/arcane` at `6987b5e046c3a00c54c88ee54219dc8f79d87c1e`;
- checked GitHub metadata: 6,153 stars, 226 forks, 140 open issues, BSD-3-Clause license, last pushed 2026-07-03;
- reviewed README, LICENSE, CHANGELOG, AGENTS.md, AI_POLICY.md, SECURITY.md, manifests, Compose examples, config, auth/RBAC, edge tunnel routing, migrations, frontend routes, and CI workflows;
- `go test ./...` failed first because the embedded frontend package expects a built `dist`;
- `go test -tags exclude_frontend ./...` still failed in `backend/internal/services` on two project-service tests in this local environment: one expected Docker unavailable rename recovery but hit missing `/var/run/docker.sock`, and one derived-status pagination test returned 0 instead of 25;
- most backend packages passed, including API, middleware, WebSocket, authz, Docker helpers, edge tunnel, scheduler, projects, and utility packages.

## Best Reusable Pattern

The best reusable pattern is the remote edge-agent command allowlist: define a typed command registry for method/path/stream routes, resolve requests through that registry, and combine it with environment-scoped permissions before proxying to agents that run with high local authority.

Extracted as `public-data/patterns/edge-agent-command-allowlist.md`.

## Bottom Line

Arcane is a credible deploy candidate if you need a self-hosted Docker/Compose control plane and you are willing to treat it like privileged infrastructure. Use it behind real authentication, prefer a socket proxy or agent topology where practical, keep roles tight, and test upgrades carefully because the project is moving quickly.

---

**Attribution:** getarcaneapp/arcane, BSD-3-Clause, https://github.com/getarcaneapp/arcane
