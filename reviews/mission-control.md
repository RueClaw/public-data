# Mission Control (builderz-labs/mission-control)

**Repo:** https://github.com/builderz-labs/mission-control
**License:** MIT. Permissive reuse with attribution.
**Reviewed:** 2026-07-05
**Stack:** Next.js 16, React 19, TypeScript, SQLite/better-sqlite3, Tailwind CSS 4, WebSocket/SSE, Playwright, Vitest
**What it is:** A self-hosted operations dashboard for AI agent fleets: tasks, agents, sessions, memory, costs, schedules, security checks, skills, CLI dispatch, and gateway/local runtime observability from one web UI.

---

## Verdict

✅ **Deploy candidate for an alpha self-hosted agent control plane.** Mission Control is much more complete than a dashboard skin: it has RBAC/session auth, SQLite migrations, OpenAPI parity checks, Playwright/Vitest coverage, hardened Docker notes, local CLI dispatch, gateway adapters, and a security-audit surface. The main caveat is operational blast radius: it controls agent runtimes, secrets, local workspaces, and shell-adjacent workflows, so it should be deployed behind strong network/auth boundaries and treated as alpha infrastructure.

---

## What It Is

Mission Control is a local-first control plane for agent operations. It tracks tasks, agents, sessions, logs, channels, skills, memory, cron jobs, tokens, costs, alerts, webhooks, GitHub sync, gateway health, and local CLI sessions. The project can run with or without an OpenClaw gateway: standalone mode covers task/project/agent/session operations, while gateway mode adds live agent communication and dispatch.

The product shape is useful because agent teams quickly outgrow raw terminal tabs and ad hoc JSON logs. Mission Control gives operators a persistent board, status panels, audit logs, quality review gates, scheduling, and a single place to see which agents are active, blocked, expensive, or unsafe.

It is clearly still moving fast. The README labels it alpha, and the changelog shows large feature/security sprints landing through the 2.1.0 release. That said, the repo is unusually serious for an alpha agent dashboard: 5,557 stars, 951 forks, recent commits, 253 documented OpenAPI operations, 97 source-level test files, 69 Playwright specs, CI quality gates, and explicit hardening docs.

## Stack

| Layer | Tech |
|-------|------|
| Web app | Next.js 16 App Router, React 19, TypeScript |
| UI | Tailwind CSS 4, Recharts, Reagraph, xterm |
| State/API | Zustand client store, REST route handlers, OpenAPI 3.1 |
| Database | SQLite via better-sqlite3, WAL mode, migrations |
| Realtime | WebSocket and server-side event bus/SSE patterns |
| Auth/security | Session auth, API keys, RBAC, Google/proxy auth support, CSRF/origin checks, rate limits |
| Agent/runtime integrations | OpenClaw gateway, Claude Code, Codex CLI, Hermes, OpenCode, MCP helper scripts |
| Testing/CI | Vitest, Playwright, API contract parity, lint, typecheck, build, Docker publish workflows |
| Deployment | Local pnpm, standalone Next server, Docker/GHCR, hardened compose overlay |

## Key Features

### Agent Operations Dashboard

The UI is organized as an operations console rather than a demo app: overview, agents, tasks, chat, activity, logs, costs, memory, skills, cron, webhooks, alerts, GitHub, security, audit, gateways, integrations, and settings. Navigation supports a smaller "essential" mode, and the dashboard uses smart polling plus live event feeds to avoid stale state.

### Task Lifecycle and Quality Gates

Tasks move through inbox, assigned, in-progress, review, quality-review, done, and failed states. The orchestration docs describe queue claiming, auto-dispatch, model routing, recurring tasks, and Aegis-style quality review. That quality-review gate is the right instinct: agent work should not become "done" just because an agent stopped talking.

### Local-First Persistence

SQLite is the only required database. The database layer enables WAL mode, foreign keys, busy timeout, migrations, and runtime schema initialization. This keeps deployment friction low and makes the project plausible for a single operator, small team, or private lab where Postgres/Redis would be overkill.

### Security and Hardening Surface

The repo has a visible security posture: session-token hashing, API-key rotation/hashing, timing-safe auth comparisons, rate limiters, proxy-auth guardrails, SSRF/path-traversal checks around skill installs, MCP call auditing, secret detection, security scan panels, and a hardened Docker compose overlay.

The 2.1.0 changelog is especially relevant: it records plaintext global API key removal, a production dependency vulnerability refresh, gateway-token leakage fixes, and prompt-injection guard improvements.

### Runtime and CLI Dispatch

Mission Control can dispatch through gateway agents and host CLIs. The host CLI sandbox options are opt-in and validated: allowed Claude tools are filtered through an allowlist, max budget is clamped, and configured working directories are resolved under `MC_WORKSPACE_ROOT` with realpath checks to reject traversal and symlink escapes.

## Architecture

The architecture is pragmatic: a monolithic Next.js application with route handlers, a SQLite database, typed lib modules, a client store, and many focused panels. It favors one deployable control plane over a distributed microservice stack.

The database migration model is straightforward and extensible. `src/lib/migrations.ts` holds ordered migrations plus a registration hook for extensions. `src/lib/db.ts` owns the singleton database connection, WAL/busy-timeout setup, schema initialization, admin seeding, webhook listener initialization, and scheduler startup.

Realtime state is intentionally simple. A singleton `EventEmitter` broadcasts typed server events such as `task.created`, `task.updated`, `agent.synced`, `audit.security`, `run.completed`, and `session.updated`. That is not a multi-node event backbone, but it is appropriate for the single-node SQLite deployment story.

The project also keeps API shape honest with an OpenAPI spec and a contract parity script. That matters in a dashboard with many route handlers: without an explicit parity gate, UI/API drift becomes inevitable.

## Comparison

| Aspect | Mission Control | Arcane | Hermes Agent Control Room | Fabro |
|--------|-----------------|--------|---------------------------|-------|
| Primary job | Agent operations dashboard/control plane | Docker/Compose control plane | Sidecar runbooks/control room | Deterministic workflow graph runner |
| Persistence | SQLite | Backend DB plus Docker state | Mostly docs/templates/scripts | Workflow/event storage |
| Agent focus | First-class agents, tasks, sessions, skills, CLI/gateway dispatch | Infrastructure containers | Agent ops conventions | Agent workflow execution |
| Deployment style | Local/self-hosted app | Self-hosted infra control plane | Pattern/source material | Runtime platform |
| Main caveat | Alpha, high-authority surface | Docker socket authority | Needs hardening to become product | Larger runtime commitment |

Mission Control sits closest to an agent SRE console. It is more productized than a runbook repo and less workflow-formal than Fabro. The interesting niche is day-to-day agent fleet operations: visibility, dispatch, task state, credentials, audit, and local runtime health.

## Self-Hosting Notes

The lowest-friction path is `bash install.sh --local` or `docker compose up`, then `/setup` for the first admin. Production deployments should use the hardened compose overlay or equivalent reverse-proxy/TLS/network isolation.

Important hardening points:

- Set strong `AUTH_PASS`, `API_KEY`, and `AUTH_SECRET`, or use generated credentials.
- Configure `MC_ALLOWED_HOSTS`; do not expose with broad host access.
- Use HTTPS with `MC_COOKIE_SECURE=1` and `MC_ENABLE_HSTS=1`.
- Treat gateway tokens, CLI access, and workspace roots as high-authority secrets.
- Keep `MC_WORKSPACE_ROOT` narrow if host CLI dispatch is enabled.
- Review Docker/runtime comments and example values for organization-specific leakage before publishing derivatives.

---

**Attribution:** builderz-labs/mission-control, MIT License
