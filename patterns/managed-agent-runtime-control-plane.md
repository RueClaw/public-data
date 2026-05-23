# Managed Agent Runtime Control Plane

**Source:** <https://github.com/multica-ai/multica>
**License context:** Multica uses a source-available Apache-2.0-derived license with hosted/embedded commercial restrictions. This pattern is a high-level architectural summary, not copied source.
**Reviewed:** 2026-05-23

## Problem

Coding agents become harder to operate when they move from one-off local prompts into team workflows. A team needs to know:

- which agents exist
- which runtimes can execute them
- which workspace owns the work
- what task was claimed
- whether execution is still alive
- what files, comments, logs, and usage were produced
- who is allowed to see or mutate the result

Treating an agent as just a model dropdown does not solve that.

## Pattern

Split the system into a management plane and an execution plane.

The management plane owns:

- workspaces and membership
- issues/tasks
- comments and activity
- agent profiles
- skills/configuration
- runtime registry
- task queue and task lifecycle
- realtime authorization
- audit and usage records

The execution plane owns:

- local daemons or cloud runtime nodes
- installed CLI/provider detection
- workspace checkout/cache
- task claiming
- provider-specific execution
- cancellation/timeouts
- streaming progress and usage
- heartbeat and health

Provider adapters normalize each agent CLI/runtime into the platform's internal session, message, tool-event, and usage model.

## Why It Works

This separates product concerns from process concerns. The web app should not need to know how a specific CLI streams output. The runtime should not decide who can see another user's private chat. The backend should own authorization and durable state; the runtime should own execution mechanics.

That separation also makes multi-provider support realistic. New agent tools can be integrated behind adapters without rewriting assignment, comments, auth, or runtime health.

## Implementation Checklist

- Register runtimes with workspace, machine, provider, version, and capability metadata.
- Store tasks in a durable queue with explicit states: queued, claimed, running, completed, failed, cancelled.
- Require runtime heartbeats and reclaim stale claims.
- Keep provider adapters behind one execution/session interface.
- Stream progress through a normalized event model.
- Put tenant identifiers, such as workspace ID, into destructive database queries as a second guard after handler authorization.
- Authorize realtime subscriptions by workspace and resource ownership.
- Separate server state from local UI state so clients can reconnect and recover cleanly.
- Treat local and cloud runtimes as the same conceptual interface with different trust and deployment profiles.

## Failure Modes To Watch

- Runtime identity is too weak, so stale or spoofed runtimes can claim work.
- Task claiming is not atomic, causing duplicate execution.
- Realtime channels leak private task/chat activity across workspace members.
- Provider adapters expose raw CLI events without normalization.
- Agent credentials or environment variables leak into logs, comments, or persisted task messages.
- UI shows an agent as available when the runtime is degraded or missing required tools.
- Skills become unversioned blobs that cannot be audited or reproduced.

## Good Fit

Use this pattern for:

- managed coding-agent teams
- self-hosted agent workspaces
- local/cloud hybrid execution
- enterprise agent operations
- multi-provider agent platforms
- human-in-the-loop task boards for agents

Avoid it for small single-user tools where a direct local CLI wrapper is enough.

---

**Attribution:** multica-ai/multica, source-available Apache-2.0-derived license with commercial restrictions.
