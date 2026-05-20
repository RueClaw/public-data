# Topology-First Codebase Reasoning

**Source:** acidgreenservers gist
**Gist:** https://gist.github.com/acidgreenservers/001185d63e5cd65f9fbe6f7a1c70a200
**License:** No explicit license found; summarized as a pattern with attribution, not a verbatim prompt republication.
**Reviewed:** 2026-05-19

## Pattern

Before making non-trivial code changes, have the agent map the local topology of the system: state ownership, feedback/observability, coupling and deletion blast radius, timing/order constraints, security boundaries, and existing implementation patterns. Use that topology to decide whether to proceed, ask a targeted question, or ship a bounded partial change.

## Core Questions

- Where does state live?
- Where does feedback live?
- What breaks if this is deleted or changed?
- When does timing or ordering matter?
- Which trust boundaries does data cross?
- What existing pattern should this follow?

## Why It Matters

Many agent coding failures are not syntax failures. They are topology failures: changing one side of an interface without finding the other side, adding state in the wrong layer, missing a race condition, or broadening scope without understanding blast radius. A topology-first gate forces the agent to reason about relationships before edits.

## Practical Workflow

1. Classify ambiguity and risk.
2. For trivial low-risk changes, proceed with light verification.
3. For non-trivial changes, inspect entry points, high-centrality modules, data flow, state ownership, and tests.
4. State the relevant topology briefly before editing.
5. Make the smallest coherent change.
6. Verify with the narrowest meaningful test, typecheck, lint, or direct inspection.
7. Flag deferred risks explicitly.

## Good Uses

- Refactors across module boundaries.
- Security-sensitive code paths.
- Async, queue, scheduler, or database changes.
- Agent review before implementation.
- Read-only reconnaissance reports for unfamiliar repositories.

## Risks

- If applied literally to every task, it slows down small changes.
- If the agent cannot use static-analysis or test tooling, the topology map may be incomplete.
- "Ask before proceeding" rules need a risk threshold; otherwise the agent can become over-cautious.

---

**Attribution:** acidgreenservers gist, no explicit license found.
