# Multica (multica-ai/multica)

**Repo:** <https://github.com/multica-ai/multica>
**License:** Source-available Apache-2.0-derived license with hosted/embedded commercial restrictions. Treat as inspectable and self-hostable, not clean Apache-2.0.
**Reviewed:** 2026-05-23
**Stack:** Go, Chi, PostgreSQL 17 + pgvector, Redis, Next.js 16, React 19, TypeScript, pnpm/Turbo, Electron, Expo/React Native
**What it is:** Multica is a managed-agent workspace that turns coding agents into assignable teammates: issues, comments, runtimes, skills, squads, autopilots, and local/cloud execution.

---

## Update Notes

Checked on 2026-05-23 against fd0fe1d (2026-05-22), after the prior April review at 287a9eb.

Material changes since the prior review:

- 883 commits landed after the April review.
- The product expanded from web/backend/daemon/desktop into an iOS mobile client under apps/mobile/.
- The agent surface grew from individual agents into squads, autopilots, richer issue metadata, parent/child issue protocols, and per-agent runtime controls such as thinking-level settings.
- Cloud runtime fleet APIs, self-healing runtime deletion, runtime health, and usage/pricing surfaces are more developed.
- CI is materially stronger: frontend build/typecheck/lint/test, backend build/migration/test, installer tests, release workflows, and desktop smoke packaging.
- Security posture improved in code through workspace-scoped deletes/updates, private chat realtime authorization, attachment MIME/disposition hardening, and workspace-level environment redaction.
- Dependency hygiene regressed or remains unresolved: pnpm audit --audit-level moderate reports 34 moderate and 16 high advisories in the current workspace dependency graph.

---

## Verdict

✅ **Deploy candidate for evaluation, with dependency hygiene caveats.** Multica is now a much more complete managed-agent operating surface than it was in April: web, desktop, mobile, daemon, backend, self-hosting, cloud runtime plumbing, squads, and automation are all represented in active code. The license and audit findings keep it from being a frictionless fork, but the architecture is serious enough to study and pilot.

---

## What It Is

Multica is an AI-native task management platform where coding agents are modeled as coworkers. Users create workspaces, issues, agents, runtimes, skills, squads, and autopilots; agents can pick up work, comment on issues, update state, and execute through local or cloud runtimes.

The most important design choice is that Multica does not treat an agent as just a model name. It separates the management plane from execution: a Go backend owns state and authorization, a local daemon or cloud runtime executes work, and UI clients show the collaboration surface.

That makes it closer to a team operations layer for coding agents than to a simple chat wrapper. The hard parts are runtime registration, task claiming, workspace isolation, realtime updates, agent compatibility, and long-running execution loops. The repo now has code for all of those.

## Stack

| Layer | Tech |
|-------|------|
| Backend | Go 1.26, Chi, sqlc, gorilla/websocket |
| Database | PostgreSQL 17, pgvector, migrations, Redis for selected realtime/test paths |
| Frontend | Next.js 16, React 19, TypeScript, Tailwind, React Query, Zustand |
| Desktop | Electron + Vite, packaged installers, bundled CLI integration |
| Mobile | Expo 55, React Native 0.83, Expo Router, NativeWind, React Query, Zustand |
| Agent runtime | Local daemon and cloud runtime nodes |
| Agent providers | Multiple CLI/runtime adapters including Claude Code, Codex, GitHub Copilot CLI, OpenCode, Gemini, Pi, Cursor Agent, Kimi, Kiro, and others |
| Tooling | pnpm 10, Turbo, Vitest, Playwright, GoReleaser, Docker Compose |

## Key Features

### Agents as Assignable Teammates

Issues can be assigned to agents and tracked like ordinary team work. Agents have profiles, comments, task runs, activity state, and runtime bindings. This is a better abstraction than treating agent execution as a hidden background job.

### Runtime Control Plane

The runtime model is the product's center of gravity. Local daemons and cloud runtime nodes report capabilities, claim work, stream progress, and keep execution separate from the web management layer. That split is what makes a multi-agent team product operational rather than just decorative.

### Squads and Autopilots

Recent commits add a more explicit routing layer. Squads group agents and humans under a leader, while autopilots support scheduled or triggered automation. This moves Multica from assign-a-bot-to-a-card toward programmable team workflows.

### Mobile Client

The new apps/mobile/ client is not a token demo folder. It includes auth, workspace selection, issues, inbox, chat, projects, realtime updates, markdown rendering, attachment handling, and local state stores. The mobile app is still young, but it is a meaningful product-surface expansion.

### Security and Tenant-Scoping Work

The codebase has visible hardening work:

- SQL queries use workspace_id predicates as tenant guards for destructive issue/skill/attachment operations.
- Realtime chat/task scope authorization checks workspace membership and private chat creator ownership.
- Attachment handling includes MIME normalization and forced attachment disposition for SVG uploads.
- Workspace-level environment redaction is now represented in the system.

Those are the right kinds of concerns for an agent platform, where file access, task execution, and workspace boundaries can easily become confused.

## Architecture

The architecture is a management plane plus runtime plane:

- Next.js/web, Electron/desktop, and Expo/mobile provide user surfaces.
- Go backend owns workspace state, users, agents, issues, comments, tasks, runtimes, auth, and realtime.
- PostgreSQL stores durable product state; Redis appears in selected realtime/test paths.
- Local daemon and cloud runtime nodes execute agent work.
- Agent adapters normalize different CLI providers behind one internal execution model.

The repo is also unusually explicit about frontend boundaries. Shared packages are separated into core, UI, and views; the docs warn against coupling shared views to platform-specific APIs. That discipline matters now that web, desktop, and mobile all exist.

## Verification

Local verification on 2026-05-23:

- cd server && go test ./... passed across backend packages.
- Core frontend tests passed through Turbo cache replay: 43 files / 387 tests.
- JS lint reported warnings, not errors, in @multica/core and @multica/views.
- A broad Turbo typecheck/lint/test run was started but became too heavy locally after spawning web/desktop/views TypeScript and Vitest workers; it was stopped rather than leaving runaway processes.
- pnpm audit --audit-level moderate reported 34 moderate and 16 high advisories. Notable affected modules include Vite, protobufjs, fast-uri, glob, path-to-regexp, picomatch, xmldom, Hono, and Turbo.

## Caveats

### License Is Source-Available, Not Plain Apache

The license is Apache-2.0-derived, but it adds commercial restrictions around hosted or embedded services and frontend branding. That is fine for evaluation and many self-hosted/internal uses, but it is not the same as a standard permissive license.

### Dependency Audit Needs Attention

The current lockfile has meaningful moderate/high advisories. Many appear transitive through frontend, desktop, mobile, dev-server, or docs dependencies, but this is still not something to ignore for an agent platform that handles code execution and workspace data.

### Operational Complexity Is High

Multica now spans Go, PostgreSQL, Redis, Docker, Next.js, Electron, Expo, desktop packaging, mobile builds, local daemons, cloud runtimes, and many agent CLIs. That scope is appropriate for the ambition, but it raises the cost of running and maintaining it.

### Skills Still Need Empirical Validation

The skills-compound-over-time story remains plausible but not proven by inspection alone. The codebase has stronger surrounding machinery now, but the long-term transfer value of reusable skills still needs real usage data.

## Comparison

| Aspect | Multica | Lightweight agent wrappers | Governance-first frameworks |
|--------|---------|----------------------------|-----------------------------|
| Primary layer | Team workspace and runtime control plane | Single-user execution or chat UX | Policy, approvals, audit |
| Execution model | Local/cloud runtime nodes with task claiming | Usually direct process launch | Often abstract or enforcement-focused |
| Product surface | Web, desktop, mobile, CLI, daemon | Usually one app or CLI | Often SDK/tooling-first |
| Strength | Operationalizing agents as teammates | Fast experimentation | Safety and control |
| Risk | Complexity, license, dependency hygiene | Shallow orchestration | Integration burden |

## Self-Hosting Notes

The self-hosting path is coherent and actively maintained. The repo includes Docker Compose files, self-hosting docs, GHCR image references, migration flow, CLI setup, and a local daemon pairing story. Pinning image tags is recommended for stable deployments.

For serious use, do a dependency update/audit pass first and test the exact agent CLIs and runtime modes intended for production.

---

**Attribution:** multica-ai/multica, source-available Apache-2.0-derived license with commercial restrictions.
