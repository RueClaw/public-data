# Codebase Reasoning Topology Gist

**Source:** https://gist.github.com/acidgreenservers/001185d63e5cd65f9fbe6f7a1c70a200
**Author:** acidgreenservers
**Date:** 2026-05-01; latest observed update 2026-05-18
**Reviewed:** 2026-05-19
**Topic:** Coding-agent system prompts, codebase reconnaissance, software architecture heuristics

---

## Verdict

📚 **Good reference, not a drop-in operating policy.** This gist is a compact bundle of coding-agent guidance around topology-first engineering: map state, feedback, coupling, timing, blast radius, and security boundaries before changing code. The strongest pieces are the four invariant questions, the read-only code reconnaissance prompt, and the production-systems heuristics; the weakest piece is the absolute clarification requirement, which would make agents sluggish on low-risk work unless softened by the gist's own trivial-change rule.

---

## Summary

The gist is titled "System Prompt For Coding Agents" and contains five Markdown files: `AGENTS.md`, `CLAUDE.md`, `CODE-RECON.md`, `DOMAIN-WISDOM.md`, and `EXECUTION-MOMENTUM.md`. Together they define a style of coding-agent behavior that treats codebases as topologies rather than bags of files.

The core claim is that persistent engineering quality comes from understanding structural relationships: where state lives, where feedback lives, what breaks when something is deleted, and when timing or ordering matters. The agent is asked to become a cartographer before becoming an implementer.

`CODE-RECON.md` is the most operational artifact. It asks an agent to perform a read-only repository scan and produce a machine-readable topology report covering modules, interfaces, data flow, security boundaries, tests, dead code, and failure modes. That makes it useful as a reconnaissance prompt before security review, refactoring, or major feature work.

`DOMAIN-WISDOM.md` is a set of systems-design heuristics expressed as "seeds": one responsibility per component, avoid hot-row contention, prefer projections for public reads, use external schedulers for fan-out, add jitter, make jobs idempotent, measure before optimizing, and choose graceful degradation over hard failure. The metaphors are a little heavy, but the underlying advice is mostly sound production engineering.

## Key Claims

- **Structure matters more than raw context length.** Plausible and useful; agents often fail when they lack dependency and data-flow maps, even with many tokens.
- **Non-trivial code changes need state, feedback, blast-radius, and timing checks.** Strong. These four questions form a practical pre-implementation gate.
- **Read-only reconnaissance should precede high-risk implementation.** Strong for large or unfamiliar systems; less necessary for tiny edits.
- **Agent collaboration should include calibrated disagreement and explicit uncertainty.** Strong, especially for senior engineering workflows.
- **Always confirming every ambiguity is mandatory.** Too rigid if applied literally; good agents need a fast path for obvious, reversible tasks.

## Strengths

- The guidance targets real failure modes: unclear ownership, hidden coupling, race conditions, missing observability, and security seams.
- It distinguishes trivial changes from non-trivial work, which keeps the otherwise cautious posture from becoming completely paralyzing.
- The reconnaissance prompt is concrete enough to adapt into a repeatable review workflow.
- The systems-design heuristics are grounded in production patterns: append-only buffers, projections, edge caching, jitter, idempotency, and workload-specific resource pools.

## Gaps & Limitations

- No explicit license is provided. Treat it as public reading material unless the author adds reuse terms.
- The prompts are framework-agnostic but not tool-aware; they do not specify how to collect call graphs, dependency graphs, coverage, or ownership evidence in a reproducible way.
- The "always confirm" rule conflicts with high-momentum coding-agent workflows unless bounded by task risk.
- The code reconnaissance prompt asks for coverage artifacts and static analysis but also says not to run build/test/deployment commands; in many repos, coverage and dead-code findings cannot be complete without executing local tooling.
- The style leans metaphorical. Useful for human memory, but production agent instructions usually benefit from tighter operational language.

---

**Attribution:** acidgreenservers, public GitHub Gist, no explicit license found.
