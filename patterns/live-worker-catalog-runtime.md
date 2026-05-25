# Live Worker Catalog Runtime

**Source:** iii-hq/iii
**Repo:** https://github.com/iii-hq/iii
**License:** Engine implementation under Elastic License 2.0; SDKs and skills under Apache-2.0
**Reviewed:** 2026-05-25

## Pattern

Model a backend as a live catalog of workers, functions, and triggers instead of a fixed mesh of point-to-point integrations.

- **Worker:** a process that connects to the runtime and registers capabilities.
- **Function:** a stable callable unit, addressed by a function ID such as `orders::validate` or `agents::critic`.
- **Trigger:** a declarative cause for invoking a function, such as HTTP, cron, queue, state change, stream event, or direct invocation.

The important design move is making discovery, invocation, and observability part of the same runtime surface. A worker can register a function, other workers can discover it immediately, and operators or agents can inspect what happened through traces and logs.

## Why It Matters

Agentic systems often fail at the integration boundary. Each new capability gets its own SDK, queue, webhook, retry behavior, logs, permissions, and discovery mechanism. A live catalog runtime reduces that sprawl by making new capabilities join one shared execution surface.

This is useful for:

- Agent backends that need to discover and invoke tools dynamically.
- Internal platforms where teams publish capabilities as callable functions.
- Long-running systems with mixed HTTP, queues, cron, streams, and state reactions.
- Operations consoles that need to show live workers, functions, triggers, queues, traces, and logs in one place.

## Implementation Shape

1. Run a central engine with built-in modules for common trigger and state surfaces.
2. Let workers connect over a durable protocol such as WebSocket.
3. Require workers to register function IDs, request/response schema metadata, and trigger declarations.
4. Route all invocations through the engine so execution, retries, auth, and telemetry stay consistent.
5. Expose a discovery API that can be filtered by RBAC policy.
6. Treat worker installation and spawning as privileged operations.
7. Ship agent-readable skills or docs beside the runtime so coding agents learn the framework from source.

## Security Boundaries

- Separate private worker ports from public/browser-facing listener ports.
- Put untrusted callers behind RBAC-enabled listeners with filtered discovery.
- Support auth at both connection and outbound HTTP-invocation layers.
- Redact telemetry payloads by key name before export.
- Harden local process metadata and temp files because worker configs can carry secrets.
- Keep URL allowlists and private-network blocking available for outbound HTTP invocations.

## Borrowable Pieces

- Function IDs as stable public contracts.
- Discovery that respects the same permissions as invocation.
- Agent skills checked into the framework repo.
- Queue/state/stream primitives exposed through the same function-trigger mental model.
- Runtime console built around live registry state rather than static config.

## Caveats

This pattern is powerful because it centralizes capability discovery and execution. That also makes the runtime a high-trust control plane. Do not let arbitrary agents install workers or register functions without policy gates, audit logs, and namespace controls.

The iii engine itself is Elastic License 2.0, so this file describes the pattern rather than extracting implementation code.

---

**Attribution:** iii-hq/iii, Elastic License 2.0 / Apache-2.0 mixed licensing.
