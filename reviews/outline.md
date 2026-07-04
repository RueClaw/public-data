# Outline (outline/outline)

**Repo:** https://github.com/outline/outline  
**License:** Business Source License 1.1; not open source, converts to Apache-2.0 on 2030-06-06 for the inspected licensed work  
**Reviewed:** 2026-07-03  
**Stack:** TypeScript, React, Vite, MobX, Koa, Sequelize, PostgreSQL, Redis, Bull, Hocuspocus/Y.js, ProseMirror  
**What it is:** A mature collaborative team knowledge base with realtime editing, Markdown-compatible documents, integrations, self-hosting support, and a hosted commercial service.

---

## Verdict

✅ **Deploy candidate if the BSL terms fit your use case.** Outline is a polished, mature, actively maintained knowledge-base product with strong architecture, real self-hosting support, and serious CI/test coverage. The catch is license shape: BSL 1.1 is not open source, production use is limited by the Additional Use Grant, and you cannot use it to offer a competing commercial third-party document service without a commercial license.

---

## What It Is

Outline is a team wiki/knowledge-base application: documents, collections, sharing, comments, realtime collaboration, attachments, templates, search, imports, notifications, and a large integration surface. The public hosted product lives at getoutline.com, while this repository is the source for the app and services.

The codebase is a TypeScript monorepo. The frontend is a React/Vite application using MobX and styled-components. The backend is Koa with Sequelize/PostgreSQL, Redis, Bull queues, background workers, websockets, and a separate realtime collaboration service built around Hocuspocus/Y.js. Shared editor logic and utilities live under `shared/`.

It is not a small "wiki starter." It is a full product codebase: 39k+ stars, 3k+ forks, roughly 240 collocated test files, active commits, Docker image publishing, CodeQL, production dependency audit, and CI split across lint, typecheck, frontend/shared/server tests, and bundle-size checks.

## Stack

| Layer | Tech |
|-------|------|
| Frontend | React 17, Vite, MobX, styled-components, React Router |
| Editor | ProseMirror, Markdown serialization, Hocuspocus/Y.js collaboration |
| Backend | Node.js, TypeScript, Koa, koa-router |
| Database | PostgreSQL via Sequelize migrations/models |
| Queue/cache | Redis, Bull |
| Auth | JWT sessions, OAuth/API tokens, many provider plugins, passkeys |
| Integrations | Slack, Google, Azure/OIDC, Discord, GitHub, GitLab, Linear, Notion, Figma, webhooks, Zapier, analytics plugins |
| Deployment | Docker images, Heroku-style Procfile, service selection via `SERVICES` |
| CI | Oxlint, TypeScript, Vitest, production dependency audit, CodeQL, Docker multi-arch builds |

## Key Features

### Collaborative Knowledge Base

Outline has the expected product surface for a modern team wiki: nested collections/documents, templates, attachments, comments, sharing, backlinks-ish relationships, search, notifications, revisions, imports, exports, and a responsive web app.

The editor stack is serious. The repository has dedicated editor packages under `shared/editor` and UI integration under `app/editor`, rather than treating rich text as a black-box dependency.

### Service-Split Backend

The backend is one repository but multiple runtime services:

- `web` for app/API delivery;
- `websockets` for client push;
- `worker` for queues;
- `collaboration` for realtime document editing;
- `cron` for scheduled work;
- `admin` for development queue inspection.

The service modules are lazily imported, so a worker-only process does not load the whole web/collaboration dependency tree. That is a good middle ground between a monolith and operationally expensive microservices.

### Plugin Architecture

Plugins can register API routes, auth providers, email templates, issue providers, processors, search providers, tasks, unfurl providers, uninstall hooks, and group sync providers. The repo ships a broad plugin set for common SaaS and auth integrations.

This makes Outline extensible without forcing every integration into the core route tree.

### Application-Native MCP Endpoint

The current repository includes an MCP endpoint at `server/routes/mcp/`. It is not just bolted on:

- it requires auth;
- rejects JWT session auth for MCP in tests;
- supports OAuth/API auth paths;
- is gated behind a team preference;
- registers tools according to granted scopes;
- uses MCP tool annotations such as read-only/idempotent hints;
- includes tests for protocol, auth, preference gating, and scope enforcement.

That is one of the more interesting current architecture points. It shows a production app exposing its own document, collection, comment, template, user, attachment, and fetch actions as agent tools with the same permission model as the app.

### Security And Operational Posture

The security posture is more mature than many self-hostable apps:

- `koa-helmet` and custom CSP middleware;
- double-submit CSRF for mutating cookie-auth requests;
- global and route-specific rate limiting;
- environment validation with `class-validator`;
- OAuth/API token scope checks;
- cancan-style policies under `server/policies`;
- file-based secret loading via `_FILE` env vars;
- non-root Docker runtime user;
- local-only Postgres/Redis ports in development compose;
- CodeQL workflow and production dependency audit on dependency changes.

There are still deployment-sensitive choices to watch. CSP currently has very broad `connect-src`, `img-src`, `media-src`, and `frame-src` directives, likely for embeds and integrations. That may be acceptable for the product, but self-hosters with strict compliance needs should review it.

## Architecture

The code organization is conventional and clean for a product of this size:

```text
app/      React application, routes, scenes, stores, editor UI
server/   Koa API, services, routes, commands, models, policies, queues
shared/   shared editor, i18n, utilities, types
plugins/  auth, integration, analytics, storage, and search plugins
```

API routes are thin and schema-backed; larger multi-model operations live under `server/commands`. Authorization is centralized in policy files. Presenters shape backend objects before sending them to the frontend. Tests are collocated beside routes, commands, models, policies, tools, and utilities.

The repo also includes an `AGENTS.md` that is unusually specific: it tells coding agents not to create new Markdown files, requires focused tests, warns about ProseMirror `toDOM` sanitization, and documents local style rules. That is a useful maintainer response to low-quality AI PRs.

## Comparison

| Aspect | Outline | BookStack | Wiki.js | Notion |
|--------|---------|-----------|---------|--------|
| Primary model | Team knowledge base with polished editor/collaboration | Structured book/chapter/page wiki | General wiki/knowledge platform | Hosted workspace/docs/database product |
| Self-hosting | Yes, production docs and Docker images | Yes | Yes | No official self-host |
| License | BSL 1.1 with commercial document-service restriction | Open source | Open source | Proprietary SaaS |
| Realtime collaboration | First-class | Limited | Product-dependent | First-class |
| Integration surface | Large plugin set plus MCP endpoint | Smaller | Plugin/module ecosystem | Large SaaS ecosystem |
| Best fit | Teams wanting a Notion-like knowledge base they can self-host within license terms | Simpler internal docs | Wiki-style knowledge portals | SaaS-first teams |

## Self-Hosting Notes

Self-hosting is a first-class path, but not trivial. Plan for:

- PostgreSQL and Redis;
- object storage or local attachment storage;
- at least one web process and one worker;
- separate collaboration/websocket services for larger deployments;
- OAuth/OIDC or another configured sign-in provider;
- stable `SECRET_KEY`, `UTILS_SECRET`, URL, mail, and storage settings;
- license review if offering document-service functionality to third parties.

Local validation note: I did not run the full suite. The repo expects Yarn 4.11 via Corepack and Node ranges `>=20.12 <21 || 22 || 24 <24.17.0 || 26 <26.3.1`; this machine had Node 25.9 and no `corepack` command available. Static inspection covered docs, license, package scripts, service layout, Dockerfiles, CI, auth/CSRF/CSP/rate-limit middleware, MCP routes/tools, and secret-pattern search.

---

**Attribution:** outline/outline, Business Source License 1.1
