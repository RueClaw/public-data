# Forkable Event-Sourced Agent Runs

**Source:** https://github.com/yoheinakajima/activegraph  
**Author:** Yohei Nakajima / Active Graph contributors  
**License:** Apache-2.0  
**Reviewed:** 2026-05-20

## Pattern

Model an agent run as an append-only event log over a shared graph. Behaviors react to events and graph patterns, propose mutations, and emit new events. Because the graph is a projection of the log, the system can replay a run, resume it, fork it at any prior event, and structurally diff the resulting graph against another run.

The key shift is treating agent coordination as state physics instead of chat choreography.

## Core Components

- **Event log:** every graph mutation, behavior lifecycle event, LLM call, tool call, approval, rejection, and failure is recorded.
- **Graph projection:** objects and typed relations are rebuilt from the log.
- **Reactive behaviors:** functions or LLM-backed handlers subscribe to event types, predicates, relation events, or graph patterns.
- **Patch lifecycle:** behaviors propose mutations; the runtime applies, rejects, or routes them through approvals.
- **Replay mode:** rehydrate or re-execute from the event log to detect divergence.
- **Fork mode:** copy the prefix through event N into a new run and continue independently.
- **Diff mode:** compare parent and fork graphs by divergent events, objects, relations, and states.
- **LLM/tool cache:** replay prior LLM and tool responses for shared prefixes to avoid repeated external calls.

## Why It Matters

Most agent frameworks optimize the live loop. This pattern optimizes the audit trail. That matters when outputs need provenance, when failures should be inspectable, or when alternative hypotheses should be tested without losing the original run.

Forking is especially valuable for research and diligence workflows:

- What changes if a constraint is different?
- What changes if one claim is contradicted?
- What changes if a behavior or model is swapped?
- Which outputs are stable under rerun?

## Design Rules

- Make failures events, not only exceptions.
- Record behavior start/completion/failure separately from graph mutations.
- Keep provider responses, token counts, costs, latency, and cache-hit status in trace events.
- Use optimistic patches or approvals for controlled mutation.
- Keep pattern matching deliberately small and testable.
- Make replay divergence a first-class error, not a log warning.
- Treat forked runs as independent histories with shared prefixes.

## Good Fit

- Research agents and diligence workflows.
- Multi-step planning where traceability matters.
- Agent evaluation and A/B testing.
- Hypothesis branches over a common evidence graph.
- Long-running systems that need resume and audit.

## Watch Outs

- Event logs grow; storage, compaction, and retention need policy.
- Replay is only as deterministic as behaviors, tools, clocks, and providers.
- A small pattern language is easier to audit but may frustrate graph-query power users.
- Fork/diff semantics can clarify behavior but do not prove the behavior is correct.

## Minimal Checklist

1. Persist every mutation and side-effect boundary as an event.
2. Rebuild current state from the log.
3. Make behavior subscriptions explicit and testable.
4. Add replay with divergence detection.
5. Add fork-at-event and graph diff.
6. Cache external responses for shared-prefix replay.
7. Document event types and failure reasons as public contract.
