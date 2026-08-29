# Typed Composable Agent Capabilities

**Source:** pydantic/pydantic-ai
**URL:** https://github.com/pydantic/pydantic-ai
**Reviewed:** 2026-08-28
**License:** MIT

---

## Pattern

Make agent extensions composable units with typed lifecycle hooks instead of one-off patches to the agent loop.

A capability can contribute:

- Instructions.
- Function tools and toolsets.
- Provider-native tools.
- Model settings or model selection.
- Request, tool-call, output, and stream hooks.
- History processors.
- Deferred loading metadata.
- Run-scoped state or derived behavior.

The agent composes capabilities, resolves ordering, and lets each capability participate in the same typed run context. This keeps memory, guardrails, tool search, web fetch, approvals, cost tracking, model routing, and UI adapters from all inventing their own extension paths.

## Why It Matters

Agent frameworks often start with one central loop and then grow side features: memory, search, approval, retries, model routing, telemetry, tool filtering, compaction, and durable execution. If each feature modifies the loop directly, the system becomes hard to test and harder to reason about.

A capability layer gives those features a shared contract. Each extension declares what it provides and which lifecycle stages it wraps. The core loop stays small enough to inspect, while advanced behavior composes through explicit hooks.

## Design Rules

- Give each capability a stable ID when it owns tools, persistent state, or durable execution behavior.
- Treat instructions, tools, model settings, and hooks as one bundle when they describe one behavior.
- Support always-on and on-demand capabilities.
- Preserve ordering semantics so guardrails, instrumentation, tool filters, and output validators run in predictable places.
- Keep tool definitions typed and validator-backed.
- Let capabilities expose local fallbacks and provider-native versions under the same public API when their behavior is equivalent enough.
- Ensure capability loading does not accidentally bust prompt caches or flood the model with unused tool schemas.
- Make sensitive capabilities explicit: approval, external execution, file access, browser access, network fetches, and MCP connections are authority boundaries.

## Useful Compositions

- **Tool search**: mark many tools as deferred and reveal only relevant definitions.
- **Approval**: wrap selected tools so the model can request the action but the host resolves approval.
- **Model routing**: select a model per step using history, usage, task type, or user tier.
- **Observability**: attach spans and cost data without changing business tools.
- **Context control**: process history, trim tool results, or warn on cache busts.
- **Durable execution**: identify toolsets and steps so a workflow engine can replay or resume safely.

## Adoption Checklist

- Define a base capability interface with typed run context.
- Split extension points by lifecycle stage: before request, tool validation, tool execution, output validation, stream processing, and after run.
- Add a deterministic ordering mechanism.
- Add stable capability/toolset IDs.
- Make deferred/on-demand loading a first-class flag.
- Test composition order, duplicate IDs, deferred loading, and cache-preserving discovery.
- Document which capabilities are safety boundaries and which are only model guidance.

---

**Attribution:** Pattern summarized from pydantic/pydantic-ai, MIT, https://github.com/pydantic/pydantic-ai
