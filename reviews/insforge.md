# InsForge (InsForge/InsForge)

**Repo:** https://github.com/InsForge/InsForge
**License:** Apache-2.0. Permissive license; code and patterns can be reused with attribution.
**Reviewed:** 2026-05-18
**Stack:** TypeScript, Node.js/Express, React/Vite, PostgreSQL, PostgREST, Deno workers, Docker Compose, OpenAPI, MCP
**What it is:** InsForge is an open-source backend platform aimed at AI coding agents. It packages database, auth, storage, edge functions, realtime, schedules, payments, deployment hooks, and an AI gateway behind APIs, a dashboard, and agent-facing control surfaces.

---

## Verdict

⚠️ **Interesting and unusually relevant for agent-built apps, but still a young platform.** The project has real product surface, a broad TypeScript codebase, active releases, CI, and a permissive license. The risk is scope: it is trying to be a self-hostable agent-native Supabase-style platform, cloud backend, MCP surface, function runtime, payments layer, and deployment orchestrator all at once.

---

## What It Is

InsForge positions itself as a backend-as-a-service for coding agents rather than only for human developers. The idea is that an agent can inspect backend state, deploy database migrations, configure auth, manage storage, deploy functions, read logs, and use an AI gateway without requiring the user to manually wire up every cloud primitive.

The self-hosted path runs a Docker Compose stack with PostgreSQL, PostGREST, the InsForge backend/dashboard service, and a Deno function runtime. The hosted path adds cloud-only CLI/skill flows and managed provider integrations. The repository is a monorepo with a Node/Express backend, React dashboard package, shared Zod/OpenAPI schemas, and a Deno runtime for edge-style functions.

This is closest to a lighter, agent-oriented Supabase alternative. It does not match Supabase's maturity or depth, but it is explicitly designed around AI agents as backend operators, which is the interesting part.

## Stack

| Layer | Tech |
|-------|------|
| Backend | Node.js, Express, TypeScript |
| Frontend | React 19, Vite, Tailwind, Radix UI, shared dashboard package |
| Database | PostgreSQL, PostGREST, node-pg-migrate, libpg-query |
| Auth | JWT, email/password, OAuth providers, API keys, RLS-aware request context |
| Storage | Local storage plus S3-compatible provider/gateway paths |
| Functions | Deno worker runtime, optional Deno Subhosting provider |
| Realtime | Socket.IO plus Postgres-backed realtime services |
| AI | OpenRouter/OpenAI-compatible model gateway and embeddings/image APIs |
| Deployment | Docker Compose, GHCR image builds, Vercel/Fly/provider hooks |
| Interfaces | REST/OpenAPI, dashboard, MCP/agent-facing instructions |

## Key Features

### Agent-Operated Backend Control Plane

The strongest design idea is not any single primitive; it is the decision to expose backend operations as things an agent can inspect and change. The README describes two agent interfaces: an MCP server and a CLI plus skills. The codebase backs that up with route families for database, auth, storage, logs, docs, functions, secrets, AI, realtime, schedules, deployments, payments, compute, and analytics integrations.

That gives coding agents a high-level backend control plane rather than asking them to SSH into a box, edit env vars, guess SQL state, or call cloud consoles manually.

### Postgres-Centered BaaS

InsForge follows the proven Postgres-as-core-platform pattern. PostgreSQL is the source of data, migrations, auth-adjacent tables, storage metadata, realtime tables, schedules, payments, and function deployment metadata. PostGREST provides generated REST access, while the custom backend handles management APIs and platform-specific workflows.

### Deno Function Runtime With Secret Containment

The local function runtime runs user function code inside a Deno worker template. The worker shadows Deno.env and process.env, injects only selected function secrets, removes secret enumeration, and blocks subprocess APIs as a secondary defense. This is a useful reference pattern for lightweight self-hosted function execution, though it should still be treated as a security-sensitive subsystem.

### SQL Parsing for Safer Database Operations

The backend uses libpg-query instead of ad hoc string checks to analyze SQL statements. It can classify DDL/DML changes and block dangerous operations on managed schemas such as destructive auth schema operations. This is a good signal: agent-facing SQL tools need parser-backed policy checks, not regex-only guardrails.

## Architecture

The repository is organized as a TypeScript monorepo:

- backend/ holds the Express API, providers, services, migrations, auth middleware, storage gateway, realtime, deployments, payments, schedules, AI gateway, and tests.
- frontend/ is the self-hosting dashboard host app.
- packages/dashboard/ is the reusable dashboard package with unit, component, and Playwright UI tests.
- packages/shared-schemas/ contains Zod schemas shared by backend, frontend, and generated OpenAPI surfaces.
- functions/ contains the local Deno runtime and function worker template.
- openapi/ contains API specs for auth, records, storage, functions, logs, AI, realtime, payments, and related surfaces.

Operationally, the production Compose file starts PostgreSQL, PostGREST, InsForge, and Deno. It includes health checks, persistent volumes, no-new-privileges security options, and many environment-based provider knobs. The defaults are developer-friendly, but production deployments must replace default secrets and admin credentials.

## Comparison

| Aspect | InsForge | Supabase | Firebase |
|--------|----------|----------|----------|
| Core database | PostgreSQL | PostgreSQL | Firestore/Realtime Database |
| Self-hosting | First-class Docker Compose | Supported but heavier | Not equivalent |
| Agent focus | First-class MCP/CLI/skills pitch | Increasing AI tooling, but human-dev platform first | Human/cloud platform first |
| Maturity | Young, fast-moving | Very mature | Very mature |
| Function runtime | Deno worker/local runtime plus subhosting path | Deno Edge Runtime | Cloud Functions |
| Best fit | Agent-built prototypes and self-hosted app backends | Production Postgres app platform | Google Cloud-native app backends |

## Self-Hosting Notes

The documented self-hosted path is straightforward: clone, copy .env.example, and run docker compose -f docker-compose.prod.yml up. The default exposed ports include the app on 7130, auth on 7131, Postgres on 5432, PostGREST on 5430, and Deno on 7133.

The main caution is configuration hygiene. The Compose files intentionally include development defaults such as dev-secret-please-change-in-production, admin@example.com, and change-this-password. Those are clear placeholders, not hidden leaks, but any internet-exposed deployment needs explicit secret rotation, tighter CORS/origin policy, and likely a reverse proxy/TLS layer.

---

**Attribution:** InsForge/InsForge, Apache-2.0
