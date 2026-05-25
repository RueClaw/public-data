# iii (iii-hq/iii)

**Repo:** https://github.com/iii-hq/iii
**License:** Engine under Elastic License 2.0; SDKs, console, docs, website, and skills under Apache-2.0. The engine is source-available, not plain permissive open source; avoid building a competing managed service on top of the ELv2 engine without legal review.
**Reviewed:** 2026-05-25
**Stack:** Rust engine/CLI, TypeScript/Node SDK, Python SDK, Rust SDK, React/Vite console, OpenTelemetry, Redis/RabbitMQ adapters, Docker, GitHub Actions
**What it is:** iii is a backend runtime that turns services into live-discoverable workers, functions, and triggers. It aims to give developers and agents one shared surface for HTTP, queues, cron, state, streams, observability, and worker installation.

---

## Verdict

✅ **Deploy candidate for local/internal agent backends, with license caution.** iii is unusually complete for an agent-era backend runtime: the Rust engine has broad primitive coverage, real RBAC work, a console, multi-language SDKs, deploy artifacts, skills, and a serious test suite. The main caveat is the Elastic License 2.0 engine and the young platform surface; treat it as an internal runtime candidate, not a casual fork base for a hosted product.

---

## What It Is

iii collapses common backend integration surfaces into three primitives: workers, functions, and triggers. A worker is a process that registers capabilities; a function is a callable unit of work; a trigger is anything that invokes a function, including HTTP, cron, queues, streams, state changes, or direct calls.

The interesting part is that this model is meant for both humans and agents. A developer can add a worker with the CLI, while an agent can discover the same live catalog, add missing capabilities, invoke functions, and inspect traces. That is a cleaner primitive than asking every service, automation, and agent harness to integrate with every other one separately.

The repo is a full product monorepo, not a small framework demo. It includes the Rust engine and CLI, SDKs for Node/Python/Rust, a React developer console, public docs, install scripts, Docker packaging, worker skills, and a release pipeline for npm, PyPI, crates.io, Docker, GitHub releases, and Homebrew.

## Stack

| Layer | Tech |
|-------|------|
| Engine / CLI | Rust 2024, Axum, Tokio, WebSockets, inventory macros |
| Runtime primitives | Workers, functions, triggers, queues, cron, state, pubsub, streams, HTTP routes |
| SDKs | TypeScript/Node, Python, Rust |
| Console | React 19, Vite, TanStack Router/Query, Radix UI, lucide-react |
| Observability | OpenTelemetry traces, metrics, logs, Prometheus endpoint |
| Queue / state adapters | Built-in KV, Redis, RabbitMQ/lapin |
| Deployment | Docker, Docker Compose, Caddy, distroless runtime image, Homebrew, npm, PyPI, crates.io |
| CI / release | GitHub Actions, multi-platform Rust builds, package publishing, Trivy scan, license agreement gate |

## Key Features

### Live Worker Catalog

Workers register functions and triggers at runtime. Other workers can discover and call them immediately, which makes the system useful for long-running service meshes and for agents that need to inspect available capabilities before acting.

### Multi-Primitive Runtime

The engine includes modules for HTTP functions, queues, cron, pubsub, state, streams, shell workers, worker lifecycle, and observability. This matters because the pitch only works if the catalog covers common backend primitives instead of becoming another thin RPC layer.

### Cross-Language SDKs

The Node, Python, and Rust SDKs expose the same concepts: register workers, register functions, trigger functions, stream data, use state, and emit telemetry. The package manifests show first-party packages at version `0.13.0` for npm, PyPI, and crates.io.

### Agent-Readable Skills

The `skills/` directory ships Agent Skills for iii concepts such as HTTP endpoints, queue processing, state reactions, realtime streams, worker RBAC, and agentic backends. This is a smart distribution pattern: the framework teaches coding agents how to use it in the repo, with examples and boundaries close to the source.

### Security and Isolation Work

Security is not an afterthought. The engine has RBAC for worker-manager listeners, filtered discovery, HMAC/bearer/API-key auth support for HTTP invocations, URL validation, redaction helpers in SDK telemetry payloads, CORS restrictions in the console server, hardened pidfile reads, and 0600 temp config writes for spawned worker secrets.

## Architecture

The core design is a runtime registry around function IDs and trigger declarations. Workers connect over WebSocket, register functions/triggers, receive invocations, and send results back. Built-in modules implement common trigger types and services; external workers can be spawned through `iii-worker`.

The Rust engine uses an inventory-style plugin registration pattern for built-in workers and adapters. That keeps module registration declarative while preserving a single binary distribution.

The design also treats discovery as a first-class API, not a documentation afterthought. RBAC can filter discovery results so untrusted clients only see the allowed function surface.

One visible internal caveat: the engine source calls out a process-wide active registration scope as a correctness risk during concurrent registration. The comment says the practical risk is low, but a per-worker registrar token would be cleaner for high-concurrency systems.

## Comparison

| Aspect | iii | LangGraph / agent workflow libs | Temporal / durable workflow engines | API gateways / queues alone |
|--------|-----|----------------------------------|-------------------------------------|-----------------------------|
| Main abstraction | Worker / Function / Trigger runtime | Graph nodes and agent state | Durable workflows and activities | Routing or async jobs |
| Agent fit | High: live discovery and skills are central | High for agent control flow | Medium: reliable orchestration, less agent-native | Low to medium |
| Backend breadth | HTTP, queues, cron, state, streams, observability | Usually app-level orchestration | Strong durability, weaker service catalog | Narrow |
| Language story | Rust engine plus Node/Python/Rust SDKs | Mostly Python/JS | Multi-language SDKs | Depends on component |
| License posture | Mixed ELv2/Apache-2.0 | Varies | Usually permissive/core + commercial | Varies |

## Self-Hosting Notes

The default local quickstart is:

```bash
iii project init myapp
cd myapp
iii
```

Docker deployment is documented, including a production example with read-only filesystem, tmpfs, dropped capabilities, `no-new-privileges`, and Caddy reverse proxy support.

Operational cautions:

- Do not expose the private worker WebSocket port directly to untrusted clients.
- Put public/browser access behind RBAC-enabled worker-manager listeners.
- Review ELv2 restrictions before offering iii as part of a managed hosted service.
- Treat worker installation as a privileged operation; agent-added workers are powerful.

## Verification Notes

Local review on 2026-05-25 checked the current `main` branch at commit `3583e95fb0b5d398744d78f86b92f51ec9d03046`, release `iii/v0.13.0`.

Command result:

```text
cargo test -p iii --lib --all-features
1603 passed; 0 failed; 6 ignored
```

Node SDK tests were not run because the fresh clone had no `node_modules` and `vitest` was missing. Python SDK tests were attempted with `uv --directory sdk/packages/python/iii run pytest -q`, but pytest failed to import `iii` from the generated venv in this local checkout.

---

**Attribution:** iii-hq/iii, engine under Elastic License 2.0; SDKs/console/docs/website/skills under Apache-2.0.
