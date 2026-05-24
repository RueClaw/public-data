# Twenty (twentyhq/twenty)

**Repo:** https://github.com/twentyhq/twenty
**License:** AGPL-3.0 with Enterprise-marked files; summarize and study patterns, but do not copy code into closed-source products without legal review.
**Reviewed:** 2026-05-23
**Stack:** TypeScript, Yarn 4, Nx, NestJS, GraphQL/REST, BullMQ, PostgreSQL, Redis, React, Jotai, Vite, Docker, Kubernetes/Helm, Playwright
**What it is:** Twenty is an open-source CRM positioned as an alternative to Salesforce, with cloud hosting, Docker self-hosting, and an emerging app/SDK/agent extension platform.

---

## Verdict

✅ **Deploy candidate for serious CRM evaluation, with licensing and dependency caveats.** Twenty is a mature, active product with broad CI, Docker/Kubernetes deployment assets, a large test surface, and a real extension story through SDKs, app scaffolding, CLI tools, and Claude skills. The main cautions are AGPL plus Enterprise-marked source files, a large operational footprint, a current dependency audit with many moderate/high advisories, and a macOS case-insensitive checkout collision in website assets.

---

## What It Is

Twenty is a full CRM product rather than a narrow demo. The repository contains the main web app, server, worker, shared packages, UI system, email package, SDKs, CLI, app scaffolder, documentation site, website, e2e testing, Docker packaging, Kubernetes manifests, Helm chart, Podman support, and a small Claude skill package.

The core product model is recognizable CRM: contacts, companies, opportunities, settings, billing/enterprise gates, integrations, messaging/calendar providers, imports, exports, and workspace management. The more interesting direction is that Twenty is moving toward a programmable CRM platform: app developers can scaffold objects, fields, logic functions, front components, roles, skills, agents, views, navigation items, and page layouts with a code-first workflow.

It is best approached as a product to deploy or evaluate, not as a casual component library. The codebase is large, the frontend build is memory-heavy, and the server stack expects PostgreSQL, Redis, background workers, and a careful secret/configuration setup.

## Stack

| Layer | Tech |
|-------|------|
| Backend | NestJS 11, GraphQL Yoga, REST controllers, TypeORM, BullMQ workers |
| Frontend | React 18, Vite, Jotai, Apollo Client, Mantine, BlockNote, TipTap, Lingui |
| Data | PostgreSQL, Redis, optional ClickHouse, local/S3-compatible storage |
| AI/providers | Vercel AI SDK providers for OpenAI, Anthropic, Google, Azure, Bedrock, Mistral, xAI, OpenAI-compatible gateways |
| Packaging | Yarn 4.13, Nx 22, Docker multi-stage builds, Helm, Kubernetes manifests, Podman |
| Testing/quality | Jest, integration tests, Playwright, Storybook, custom Oxlint rules, GitHub Actions per package |

## Key Features

### CRM Product Surface

Twenty ships a broad CRM surface: records, workspaces, settings, billing, authentication, integrations, file storage, email/calendar providers, import/export, and admin configuration. It is not only a backend template; the frontend is substantial and includes data grids, document/editor tooling, charts, record views, generated metadata, and localized UI.

### Self-Hosting Assets

The self-hosting story is concrete. The Docker Compose stack runs a server, worker, Postgres 16, and Redis, with health checks and persistent volumes. The repository also includes Helm, raw Kubernetes manifests, Terraform examples for Kubernetes resources, Podman notes, and multi-stage Dockerfiles that separate frontend dependency/build stages from server dependency/build/runtime stages.

The default Compose examples still need production hardening: replace default database credentials, set strong encryption keys, decide whether local storage or S3 is appropriate, configure mail/OAuth providers carefully, and avoid treating the development env examples as production-ready.

### App and SDK Platform

The twenty-sdk, twenty-client-sdk, twenty-cli, and create-twenty-app packages show an explicit platform strategy. A developer can scaffold a Twenty app, start a local Twenty server through Docker, authenticate with a development API key, and define extension entities in code.

The generated app guidance includes entities such as objects, fields, logic functions, front components, roles, skills, agents, views, navigation menu items, and page layouts. That is the most reusable architectural idea in the repository: treat CRM customization as typed, versionable application code rather than purely manual admin UI state.

### Security Guardrails in Lint

Twenty includes custom Oxlint rules that encode product-specific security and architecture rules. Two notable rules require GraphQL root resolvers and REST controller methods to have authentication guards plus permission guards, or explicit public/no-permission exceptions. That is a good mature-codebase signal: access-control expectations are not just conventions in review comments; they are partly automated in CI.

## Architecture

The repository is a large Nx monorepo with package-level CI. The backend is an application package, the frontend is an application package, and core shared contracts live in twenty-shared, twenty-ui, twenty-client-sdk, and related packages. Docker packaging builds frontend and server separately, then copies only compiled artifacts and production dependencies into runtime images.

The server/worker split is clear in Docker Compose: the main server handles HTTP and migrations/cron registration while the worker runs queue jobs with migrations and cron registration disabled. That split matters for CRM deployments because imports, sync, mail/calendar operations, and AI/tooling jobs can become long-running background work.

The codebase also treats generated metadata and generated clients as first-class artifacts. That reduces drift between dynamic CRM schemas and frontend/server clients, but it increases build complexity and makes local development more sensitive to exact Node/Yarn/Nx versions.

## Comparison

| Aspect | Twenty | EspoCRM / SuiteCRM-style CRMs | Airtable/Retool-style internal tools |
|--------|--------|-------------------------------|--------------------------------------|
| Product focus | Modern CRM with programmable app platform | Traditional CRM workflows | General-purpose app/data tooling |
| Deployment | Cloud or self-hosted Docker/Kubernetes | Usually self-hosted LAMP/PHP stacks | Mostly SaaS, some self-hosted options |
| Extensibility | Code-first SDK/CLI/app model plus metadata | Plugin/module systems | UI/database builders and integrations |
| License posture | AGPL plus Enterprise-marked source files | Often GPL/AGPL/open-core variants | Commonly proprietary |
| Operational weight | High: Node 24, Postgres, Redis, worker, build pipeline | Medium to high | Varies, often lower for SaaS |

## Verification Notes

Local verification was intentionally limited because the repository is large and the frontend build is memory-heavy. The checkout itself produced a macOS case-insensitive filesystem collision in packages/twenty-website/public/illustrations/pricing/Price/ versus price/, which is a real local-development gotcha on default macOS volumes.

Checks performed:

- Inspected README, license, security policy, package manifests, Docker Compose, Dockerfile, CI workflows, SDK/app docs, Claude skill, and custom lint rules.
- Counted visible test surface: 591 server test files, 814 frontend test files, 8 e2e specs, and 17 custom Oxlint rule specs.
- Ran Yarn audit through the checked-in Yarn release: 54 moderate-or-higher advisories were reported, including high-severity findings in transitive packages such as Babel, Axios, fast-uri, Koa, lodash, minimatch, path-to-regexp, picomatch, serialize-javascript, and tar.
- Ran a targeted secret-string scan. Most hits were expected examples, GitHub Actions secret references, and test credentials; the scan did surface long JWT-like seeded test/API tokens in CI example workflows. They appear to be test tokens, but they are still worth keeping out of production-facing examples.

## Self-Hosting Notes

For evaluation, prefer the official Docker image and Compose path first. Treat the repo checkout as a development path that needs exact toolchain alignment: Node 24.5+, Yarn 4.13, Nx, Docker, and enough memory for the frontend build.

Before production use:

- Replace all default Postgres, encryption, app, OAuth, SMTP, AI, and storage credentials.
- Pin an image tag instead of relying on latest.
- Review AGPL and Enterprise file implications.
- Run dependency audit in the deployment branch and track remediation of high advisories.
- Validate backup/restore for Postgres and local/S3 file storage.
- Check whether Enterprise-gated features such as audit logs, AI usage analytics, and advanced permissions are required.

---

**Attribution:** twentyhq/twenty, AGPL-3.0 with Enterprise-marked files.
