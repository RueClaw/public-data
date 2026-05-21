# calcom/cal.diy Review

**Source:** https://github.com/calcom/cal.diy  
**Author:** Cal.com / community fork maintainers  
**License:** MIT  
**Reviewed:** 2026-05-20  
**Snapshot:** `180ede28f0bddf2738933a6e60a8e80f6116d7da`

## Verdict: ⚠️ Interesting

Cal.diy is the MIT-only, community-oriented self-host fork of Cal.com. It is useful if you want a full scheduling platform under a permissive license and are comfortable operating a large modern TypeScript/Postgres stack yourself. I would not treat it as a casual production deployment: the README explicitly frames it as personal, non-production, use-at-your-own-risk software that expects advanced server, database, and security knowledge.

The practical value is clear: it keeps a broad Cal.com-style scheduling surface without requiring a license key, hosted account, or open-core enterprise split. The cost is that you inherit the operational weight of a large monorepo, lots of third-party integrations, many environment variables, and a sizeable dependency surface.

## What It Is

- Next.js/React web scheduling app.
- tRPC and Prisma/Postgres backend surface.
- NestJS-style API v2 under `apps/api/v2`.
- Tailwind-based UI packages and shared app-store packages.
- Docker and docker-compose path for local/self-host deployment.
- Community fork with commercial/enterprise code removed.

## Repository Signals

- Stars: 43,839
- Forks: 13,533
- Open issues: 1,044
- License: MIT
- Created: 2021-03-22
- Last pushed at review time: 2026-05-14
- TypeScript/TSX files: 5,018
- Test-like files: 421
- `package.json` files: 119

## Strengths

- **Permissive scheduling stack:** MIT license, no license key requirement, and no hosted-service dependency for the core self-host story.
- **Mature product surface:** booking pages, calendars, credentials, webhooks, users, teams, embeds, API routes, and app integrations are represented in the codebase.
- **Operationally explicit:** README and compose files are direct about prerequisites: Node, Yarn, Postgres, secrets, Docker, and security responsibility.
- **Good local developer path:** the repo includes Yarn 4, Turborepo scripts, seed users, Docker compose, and Prisma tooling.
- **API surface worth studying:** `apps/api/v2` has modular controllers/services/DTOs that are useful reference material for scheduling APIs.

## Risks

- **Not positioned as production-ready:** the README says personal/non-production use and pushes commercial/enterprise needs toward Cal.com.
- **Large attack and failure surface:** thousands of TypeScript files, 119 package manifests, many integrations, and hundreds of environment knobs.
- **Default/example secret footguns:** examples include seed credentials, a default `CRON_API_KEY`, and empty secrets that are fine for docs but risky when copied into a real deploy.
- **Prisma Studio exposure:** docker-compose includes an optional Studio service on port 5555 and warns to remove it for production.
- **Dependency complexity:** immutable install completed, but Yarn reported many peer dependency warnings.
- **Maintenance load:** 1,044 open issues and a very large inherited monorepo mean self-hosters should expect active maintenance work.

## Verification

Commands run against a shallow clone at `180ede28f0bddf2738933a6e60a8e80f6116d7da`:

- `node .yarn/releases/yarn-4.12.0.cjs install --immutable` — completed successfully with warnings.
- `node .yarn/releases/yarn-4.12.0.cjs workspace @calcom/api-v2 test --runInBand` — passed.

Test result:

- Test suites: 17 passed, 17 total
- Tests: 275 passed, 275 total
- Time: 8.603s

The API v2 test run emitted expected-looking service-account error logs inside Google Calendar tests and a localstorage warning, but all tests passed.

## Best Use

Use Cal.diy as a personal or homelab scheduling system, or as a source reference for scheduling product architecture. Before exposing it publicly, harden secrets, remove development-only services, review auth/session settings, put it behind a real reverse proxy/TLS setup, and plan for dependency updates.

## Relevance

Worth tracking as a self-host scheduling option and as a reference implementation for booking, availability, calendar integration, and webhook design. It is not the lightweight default answer for production scheduling unless the operator is ready to own the whole stack.
