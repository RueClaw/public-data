# Root-Mediated Model Routing Policy

**Source:** Cjbuilds/Codex-Orchestration  
**Repo:** https://github.com/Cjbuilds/Codex-Orchestration  
**License:** MIT  
**Reviewed:** 2026-07-17  

## Pattern

Keep one root agent responsible for intent, planning quality, delegation decisions, integration, verification, permissions, and the final answer. Add model routes as optional seats that report to the root:

- **Planner** drafts or revises plans.
- **Advisor** reviews the root-visible plan and returns approve/revise signals.
- **Executor** implements bounded packets only after the root decides delegation helps.

The routing policy should tell the root which route to request, not pretend to be a second scheduler. If the platform cannot mechanically prove a child route or caller identity, say that directly and fail closed when a required route is unavailable.

## Why It Matters

Multi-agent systems often blur two separate questions:

1. Should this task be delegated?
2. If delegated, which model or role should handle it?

This pattern keeps those separate. The root decides whether delegation is useful; the policy supplies the allowed route and packet contract. That avoids child agents self-coordinating, silently changing authority, or treating plan critique as implementation approval.

## Implementation Checklist

- Preserve a single root orchestrator.
- Make Planner and Advisor optional.
- Reject identical Planner and Advisor routes when independent critique matters.
- Bound Advisor review with explicit approve/revise signals and a maximum loop count.
- Give Executors self-contained packets with objective, files, constraints, acceptance criteria, and verification.
- Tell children not to spawn descendants or broaden scope.
- Treat child reports as claims until the root verifies evidence.
- Use reversible setup/status/disable for persistent policy.
- Distinguish "route accepted/requested" from "runtime identity confirmed."
- Fail closed when required routes, auth, state, or runtime metadata are unavailable.

## Good Fit

- Coding agents with different models for planning, critique, and implementation.
- Cost-sensitive workflows where high-judgment calls should be separated from token-heavy implementation.
- Agent platforms with evolving routing controls, where truthful boundaries matter more than optimistic automation.
- Human-in-the-loop systems that need plan review before execution.

## Caveats

This pattern is not a full sandbox or authorization system. It does not make child output trustworthy, and it does not solve platform-level caller authentication when the transport lacks caller identity. Pair it with tool permissions, workspace isolation, audit logs, and root-side verification.

---

**Attribution:** Based on patterns from Cjbuilds/Codex-Orchestration, MIT License.
