# Langfuse (langfuse/langfuse)

**Repo:** https://github.com/langfuse/langfuse
**License:** MIT for the open-source tree; `ee/`, `web/src/ee/`, and `worker/src/ee/` use a separate enterprise license
**Reviewed:** 2026-08-02
**Stack:** TypeScript, Next.js, React, tRPC, Prisma/Postgres, ClickHouse, Redis/BullMQ, S3-compatible object storage, Docker, Kubernetes/Helm
**What it is:** Open-source LLM engineering platform for tracing, monitoring, prompt management, datasets, evaluations, playground workflows, and API/SDK-based LLMOps.

---

## Verdict

✅ **Deploy candidate for LLM observability and evaluation.** Langfuse is one of the more production-shaped open-source LLMOps platforms: active maintainers, strong adoption, real self-hosting paths, broad integration coverage, and a codebase that treats ingestion, queueing, storage, security checks, and CI as first-class concerns. The main caution is operational weight: a serious deployment is not just a Next.js app, it is a Postgres + ClickHouse + Redis + object-storage + worker system.

---

## What It Is

Langfuse gives teams a central place to instrument AI applications, inspect traces, track model calls, version prompts, run evaluations, manage datasets, and debug user sessions. It sits in the same category as LangSmith, Phoenix/Arize-style observability, Helicone-style logging, and internal LLM telemetry stacks, but with a broad open-source product surface and a self-hosting story.

The repository is a TypeScript monorepo with a Next.js web/API app, a worker service, and a shared package containing domain logic, Prisma schema, ClickHouse definitions, ingestion services, auth helpers, caching, OpenTelemetry mapping, storage, webhooks, model-pricing logic, and queue definitions. The app supports SDK ingestion, OpenTelemetry ingestion, prompt management, evaluations, datasets, model-provider integrations, LLM playground workflows, dashboards, monitors, and exports.

The repo is also clearly a commercial open-core product. The default open tree is MIT, but enterprise-specific code is separated into `ee/`, `web/src/ee/`, and `worker/src/ee/` under a different license. That is manageable for deployment and study, but extraction should stay inside the MIT portions unless the enterprise license terms are reviewed.

## Stack

| Layer | Tech |
|-------|------|
| Frontend/API | Next.js 16, React 19, tRPC, TanStack Query/Table/Virtual, Radix UI, Tailwind-related utilities |
| Worker | Node 24, TypeScript, Express, BullMQ, Redis, OpenTelemetry instrumentation |
| Primary DB | Postgres via Prisma |
| Analytics DB | ClickHouse migrations for traces, observations, scores, events, dataset-run items, and aggregation tables |
| Queue/cache | Redis, BullMQ, local cache helpers |
| Object storage | S3-compatible storage, MinIO for compose, Azure Blob and OCI object-storage switches |
| Observability/security | OpenTelemetry, Sentry, Datadog/AppSignal hooks, CodeQL, Semgrep, Snyk, zizmor, license checks |
| Deployment | Docker Compose, Docker images, Kubernetes/Helm docs, cloud Terraform templates |

## Key Features

### LLM Tracing and Ingestion

Langfuse exposes public ingestion APIs and SDK integrations for tracing model calls, retrieval, embeddings, tool/agent actions, and user sessions. The ingestion handler is built around key authentication, project-scoped attribution, rate limiting, request-size limits, schema validation, async processing, and fallback sync processing. That is a good sign: ingest is treated as an unreliable high-volume boundary, not a normal CRUD endpoint.

### Evaluation Workflows

The worker has dedicated queues and processors for eval job creation, trace-based evals, dataset-based evals, LLM-as-judge execution, and code evaluator execution. The queue design is configurable by shard count, concurrency, limiter settings, and worker enablement flags, which matters once evaluation runs become expensive or model-provider-limited.

### Prompt and Dataset Management

Prompt entities, prompt dependencies, protected labels, datasets, dataset items, dataset runs, score configs, and scoring workflows are represented in the schema and feature folders rather than bolted onto trace viewing. That makes Langfuse more than a log viewer: it can become the experiment ledger for prompt/version/dataset changes.

### Self-Hosting

The top-level Compose file brings up `langfuse-web`, `langfuse-worker`, Postgres, ClickHouse, Redis, and MinIO. It marks default secrets with `CHANGEME`, binds most backing services to localhost, and notes that inbound traffic should be restricted to the web app and MinIO console endpoint where needed. For production, the docs point toward Kubernetes/Helm and cloud templates.

### Security and Operational Guardrails

The repo includes concrete guardrails around sensitive areas:

- API ingestion is authenticated and rate-limited.
- Webhook signatures use HMAC-SHA256.
- Stored secrets use AES-256-GCM when `ENCRYPTION_KEY` is configured.
- Outbound URL handling includes pre-fetch validation plus connection-time DNS/IP validation to reduce SSRF and DNS-rebinding exposure.
- Worker HTTP surface uses Helmet.
- CI includes CodeQL, Semgrep, Snyk workflows, license checks, codespell, action pinning, and zizmor.

## Architecture

The strongest architectural choice is the split between web/API, worker, and shared domain package. Public API routes authenticate and enqueue or process; the worker owns expensive or asynchronous work; shared code owns schema, queues, ClickHouse utilities, domain types, storage, auth, and ingestion behavior.

ClickHouse is used where it belongs: high-volume trace, observation, score, event, and analytics tables. Postgres remains the system-of-record store for users, organizations, projects, API keys, prompts, datasets, memberships, and configuration. Redis/BullMQ bridges the two with explicit queues for ingestion, OTEL ingestion, trace upserts, evals, code evals, exports, webhooks, monitoring, retention, deletion, and integrations.

The repository has a large test footprint, with roughly 619 test/spec files in the shallow clone. Worker tests cover ingestion, masking, retries, queue health, outbound URL validation, webhook validation/redirects, deletion flows, batch exports, monitors, eval services, and LLM connection handling. That matches the risk profile of the product.

## Comparison

| Aspect | Langfuse | LangSmith | Phoenix / Arize-style OSS observability | Helicone-style LLM logging |
|--------|----------|-----------|-----------------------------------------|-----------------------------|
| Openness | Open-source core, MIT plus enterprise tree | Primarily hosted/commercial | Open-source observability focus | Open-source/hosted logging focus |
| Scope | Traces, prompts, evals, datasets, playground, dashboards, APIs | Deep LangChain ecosystem fit | Strong observability/eval focus | Provider logging, cost, latency, request inspection |
| Self-hosting | First-class but multi-service | Not the main story | Usually viable | Usually simpler than Langfuse |
| Operational weight | Higher | Lower for managed users | Medium | Lower to medium |
| Best fit | Teams wanting an owned LLMOps platform | LangChain-heavy teams accepting hosted workflow | Teams centered on observability/eval analysis | Teams needing fast API-level LLM logging |

## Self-Hosting Notes

For a local trial, Docker Compose is enough. For durable use, treat it as a multi-service data platform: secure all defaults, back up Postgres, ClickHouse, and object storage, size ClickHouse separately from the web app, monitor Redis/BullMQ queues, and pin upgrade procedures around migrations.

The Compose defaults are friendly for onboarding but intentionally include placeholders such as `mysecret`, `mysalt`, `clickhouse`, `miniosecret`, and a zeroed encryption key. Do not expose a default Compose deployment unchanged.

---

**Attribution:** langfuse/langfuse, MIT for open-source tree with separately licensed enterprise directories
