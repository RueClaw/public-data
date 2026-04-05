# supabase/supabase — Review

**Repo:** https://github.com/supabase/supabase
**Author:** Supabase, Inc.
**License:** Apache 2.0 ✅
**Stack:** TypeScript monorepo (pnpm + Turborepo) / Next.js / Elixir / Haskell / Go / Rust / Deno / Postgres
**Reviewed:** 2026-04-04
**Rating:** ⭐⭐⭐⭐⭐ — The open-source Firebase alternative. Massive, mature, actively maintained, self-hostable.

---

## What It Is

Supabase is a Postgres development platform — an open-source Firebase replacement built on enterprise-grade open-source tools. Instead of building their own database, auth, and realtime systems from scratch, they compose existing battle-tested projects (PostgREST, GoTrue, Kong) into a unified developer experience with a polished dashboard.

Core capabilities:
1. **Hosted Postgres** — the actual database, not an abstraction over one
2. **Authentication** — GoTrue (JWT-based auth with OAuth, MFA, session management)
3. **Auto-generated APIs** — REST (PostgREST), GraphQL (pg_graphql), Realtime (Elixir websockets)
4. **Edge Functions** — Deno-based serverless functions
5. **File Storage** — S3-backed with Postgres-managed permissions
6. **AI/Vector Toolkit** — pgvector integration, embeddings support
7. **Studio** — Full Next.js dashboard (SQL editor, table browser, auth management, logs, AI assistant)

---

## Architecture

Composable services behind Kong API gateway:

- **Postgres** — core database, handles permissions and RLS
- **PostgREST** (Haskell) — auto-generates REST API from Postgres schema
- **GoTrue** (Go) — JWT auth (signups, logins, sessions, MFA, OAuth)
- **Realtime** (Elixir) — websocket subscriptions on Postgres WAL changes
- **Storage API** (Go) — S3 file management with Postgres permissions
- **pg_graphql** (Rust) — Postgres extension exposing GraphQL
- **postgres-meta** — RESTful Postgres management API
- **Kong** — API gateway fronting all services
- **Studio** (Next.js) — the dashboard UI
- **Edge Runtime** (Rust/Deno) — serverless function runtime
- **Supavisor** — Postgres connection pooler
- **Logflare** — log aggregation
- **imgproxy** — image transformation

The key design decision: Postgres is the source of truth for everything including permissions. RLS policies are the authorization layer — no separate auth middleware.

---

## Repo Structure

Turborepo monorepo (~15k files, 1.4GB):

- `apps/studio` — Next.js dashboard (the main product UI)
- `apps/docs` — documentation site
- `apps/www` — marketing site
- `apps/lite-studio` — lightweight studio variant
- `apps/learn` — tutorial app
- `apps/design-system` — component library docs
- `apps/ui-library` — UI component registry
- `packages/ui` — shared React component library
- `packages/ui-patterns` — higher-level UI patterns
- `packages/ai-commands` — AI-powered SQL/function generation
- `packages/pg-meta` — Postgres metadata client
- `docker/` — full self-hosting Docker Compose (10+ services)
- `examples/` — integration examples (auth, realtime, AI, edge functions)
- `examples/prompts/` — 8 AI coding rules for Supabase patterns (Cursor-rule format)

---

## Self-Hosting

Full Docker Compose stack with health checks, dependency ordering, env-based config. Maintained version matrix in `docker/versions.md` (latest: 2026-03-16). Three reverse proxy options:

- `docker-compose.yml` — base (no proxy)
- `docker-compose.caddy.yml` — Caddy
- `docker-compose.nginx.yml` — Nginx

---

## Extractable Content

### Coding Rules (extracted to `prompts/supabase-coding-rules/`)

8 production Cursor-rule-format prompts from the Supabase team:

| File | Covers |
|------|--------|
| `database-rls-policies.md` | RLS policy writing + performance optimization (initPlan caching, index recs, join avoidance) |
| `edge-functions.md` | Deno edge function patterns (npm/jsr imports, env vars, routing, background tasks) |
| `nextjs-supabase-auth.md` | Next.js + Supabase Auth (SSR, middleware, client/server patterns) |
| `database-functions.md` | Database function best practices |
| `database-create-migration.md` | Postgres migration patterns |
| `declarative-database-schema.md` | Schema management |
| `code-format-sql.md` | SQL formatting conventions |
| `use-realtime.md` | Realtime subscription patterns |

The RLS doc is the highest value — the `(select auth.uid())` initPlan caching trick and join avoidance patterns aren't obvious and have real performance impact.

### AI Commands Package

`packages/ai-commands/` — TypeScript package for AI-powered SQL generation with schema tokenization and doc retrieval. Shows how they integrate LLMs into platform tooling.

---

## Verdict

Massive, well-maintained, actively developed. Not a contribution target — this is a product review. Primary value: the coding rules are immediately usable as agent guidelines for any Supabase/Postgres project, and the self-hosting Docker stack is a solid reference for multi-service orchestration.
