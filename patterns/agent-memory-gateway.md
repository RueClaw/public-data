# Agent Memory Gateway

**Source:** [supermemoryai/supermemory](https://github.com/supermemoryai/supermemory)  
**License:** MIT  
**Extracted:** 2026-05-30  

## Pattern

Expose durable agent memory as a gateway rather than as a raw database. The gateway provides authenticated tools, scoped project tags, profile composition, search, context injection, SDK adapters, and inspection surfaces around the same memory substrate.

## Why It Matters

Long-running agents need memory, but direct memory access creates privacy, prompt-injection, and governance problems. A gateway gives the agent narrow verbs and lets the platform enforce identity, scope, schemas, limits, logging, deletion, and retrieval policy.

## Core Primitives

Use a small vocabulary that maps cleanly across MCP, SDK tools, and direct APIs:

- `memory`: save or forget user/project facts.
- `recall`: search memories and related profile context.
- `context`: inject selected profile/memory context into a model turn.
- `profile`: summarize durable user or project facts.
- `documents`: list, add, delete, or inspect imported source material when the memory layer also handles RAG-like inputs.

## Architectural Shape

1. **Auth at the gateway.** Validate API keys, OAuth sessions, or service identities before exposing any memory tool.
2. **Scope every request.** Use project IDs, container tags, tenant IDs, or workspace IDs so unrelated memory domains never share an implicit pool.
3. **Register tools with schemas.** Keep save/search/delete operations behind typed tool definitions with length limits and narrow action enums.
4. **Compose profile plus search.** Return both explicit profile facts and search results when useful, but keep responses bounded.
5. **Wrap retrieval as untrusted data.** Retrieved memories may contain instructions, stale facts, or malicious text. Prompt wrappers should say they are data only and must not override the active instruction hierarchy.
6. **Offer inspection.** Provide memory lists, graph views, provenance, or audit logs so users can understand and correct what the system remembers.
7. **Build adapters, not forks.** Put framework-specific packages around the same gateway instead of creating separate memory implementations for each agent runtime.

## Useful Interfaces

### MCP

Expose memory through:

- Tools for save, forget, recall, document operations, and graph fetches.
- Resources for user/project profile views.
- Prompts for context injection.

### SDK Tools

Wrap the same gateway in AI SDK, OpenAI function-calling, or framework-specific tool definitions. Keep the underlying action model consistent so policies and logs remain comparable across clients.

### UI

Provide a human inspection surface:

- search results
- memory details
- profile facts
- graph visualization
- delete/forget controls
- source provenance where possible

## Controls to Add

- Short-lived tokens or scoped API keys.
- Per-tool and per-project allowlists.
- Size caps for saved memories and retrieved context.
- Redaction or masking for telemetry and session replay.
- Deletion/export flows.
- Connector-specific consent and revocation.
- Audit logs for create, search, inject, and delete operations.
- Tests for prompt-injection boundaries in memory injection templates.

## Failure Modes

- **Prompt injection through memory:** A stored memory says "ignore previous instructions." Treat memory as data only.
- **Cross-project leakage:** An agent searches a global memory pool and retrieves another workspace's fact. Scope every request.
- **Overbroad imports:** Connectors pull too much private data into memory. Require explicit connector consent and source filters.
- **Opaque recall:** Users cannot tell why an agent knows something. Keep provenance and graph/list inspection.
- **Tool blast radius:** A model can delete or write too broadly. Use action gates, confirmation for destructive operations, and project-local permissions.
- **Telemetry leakage:** Memory content appears in logs, traces, replay, or debug output. Mask aggressively.

## When To Use

Use this pattern when:

- multiple agents or clients need the same memory layer
- memory must be scoped by user, project, tenant, or task
- agents need both search and profile-style context
- users must inspect or correct memory
- direct vector-store access would be too broad or hard to govern

Avoid it when a project only needs a short-lived local cache or when there is no clear deletion/export story for sensitive data.

---

**Attribution:** Pattern extracted from the public `supermemoryai/supermemory` repository.
