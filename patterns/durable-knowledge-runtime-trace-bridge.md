# Durable Knowledge / Runtime Trace Bridge

**Source:** apprentice-labs/activegraph-gbrain-bridge
**Repo:** https://github.com/apprentice-labs/activegraph-gbrain-bridge
**License:** MIT
**Reviewed:** 2026-05-27

## Pattern

Keep durable knowledge storage separate from runtime causality. Let a knowledge system own facts, schemas, retrieval, source documents, timelines, and long-lived records. Let a runtime graph own how an agent used that knowledge: lookup requests, cited evidence, context assembly, policy gates, proposed mutations, approvals, forks, replay, and diffs.

The bridge between them should be typed, redaction-aware, fixture-testable, and mutation-conservative.

## Why It Matters

Agent systems often blur "what the world knows" with "what happened in this run." That makes audits and memory mutation dangerous. This pattern keeps the durable knowledge layer as the source of truth while the runtime layer records causal use, uncertainty, approval state, and replayable execution.

This is useful whenever an agent can read from trusted knowledge but should not casually mutate it.

## Implementation Shape

1. Define a typed client protocol for durable knowledge operations.
2. Support fixture/mock clients with the same method surface as the live client.
3. Turn each external operation into requested/completed/failed runtime events.
4. Redact secrets, raw bodies, private payloads, and schema taxonomy by default.
5. Project retrieved evidence into runtime graph objects with stable source references.
6. Assemble model context from linked evidence and record the assembly decision.
7. Model writes as proposals, not direct mutations.
8. Require approval before applying a proposed write, and keep dry-run as the default.
9. Fork the runtime graph before applying mutation traces.
10. Maintain a compatibility matrix for upstream versions and operation families.

## Design Notes

- Fixture mode should be the default, not a special testing hack.
- Live client and fixture client signatures should stay identical.
- Writeback helpers should be usable without exposing privileged live mutation operations.
- Replay fixtures should fail on missing operation/argument matches instead of falling back silently.
- Compatibility claims should distinguish smoke-tested, source-inspected, fixture-only, and unverified.
- Any private upstream API use should be isolated behind one compatibility shim.

## Representative Source Paths

- `activegraph_gbrain/client.py` — typed client protocol, fixture client, MCP/HTTP client.
- `activegraph_gbrain/events.py` — operation event records.
- `activegraph_gbrain/redaction.py` — redaction policy.
- `activegraph_gbrain/replay.py` — recorded fixtures.
- `activegraph_gbrain/writeback.py` — proposal/approval/apply trace helpers.
- `activegraph_gbrain/forking.py` — fork-before-writeback and diff metadata.
- `docs/gbrain_compatibility_matrix.md` — version/operation compatibility ledger.

## Caveats

This pattern is strongest when the bridge stays small. If it starts becoming a fork of the durable knowledge system or the runtime graph system, the boundary value erodes. Production mutation needs a separate live-compatibility and approval story; fixture-backed proof is not enough.

## Attribution

Pattern extracted from apprentice-labs/activegraph-gbrain-bridge, MIT.
