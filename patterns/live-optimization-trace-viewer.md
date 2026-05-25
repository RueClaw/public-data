# Live Optimization Trace Viewer

**Source:** https://github.com/modaic-ai/gepa-viz
**License:** MIT declared in README/package metadata; no root LICENSE file detected
**Extracted:** 2026-05-24

## Pattern

Turn a long-running optimizer into an inspectable live UI by emitting complete trace snapshots that can be streamed, saved, and replayed.

The reusable structure:

1. Define a compact JSON trace schema for examples, candidates, parent links, scores, predictions, minibatch details, and feedback.
2. Capture optimizer lifecycle events through a callback rather than coupling the visualizer to the optimizer loop.
3. Normalize domain objects into JSON-safe values at the boundary.
4. Publish full snapshots over a simple live channel such as SSE.
5. Always write the same data to disk as a durable artifact.
6. Let the viewer support three modes: live stream, static file, and development polling.
7. Keep the graph and detail views separate: overview for topology, detail page for prompts, diffs, examples, outputs, and feedback.

## Why It Matters

Prompt optimization, agent search, policy tuning, and evaluation loops can produce useful work while still being hard to debug. A scalar final score hides the path: which parent generated the best child, which examples flipped, what feedback produced a proposal, and which rejected candidates were close.

A live trace viewer makes the process inspectable while it runs, but the durable JSON artifact is the more important piece. It gives users a replayable record for postmortems, comparison, sharing, and regression investigation.

## Implementation Notes

- Prefer a domain-specific trace schema over raw logs.
- Treat rejected candidates as first-class nodes; they often explain search behavior.
- Store parent ids explicitly so the graph can be reconstructed without inference.
- Use full snapshot publication for small/medium runs; move to patch events only when scale requires it.
- Include prompt diffs and evaluation feedback beside scores.
- Keep local-only defaults for live servers.
- If remote ingestion is supported, add auth, payload size limits, and schema validation before public exposure.
- Document that trace files may contain private prompts, examples, and model outputs.

## Non-Goals

This pattern is not a general observability stack. It is a lightweight, domain-specific trace surface for optimization/debug loops where the full state is small enough to render in a browser.

---

**Attribution:** modaic-ai/gepa-viz, MIT declared in README/package metadata; no root LICENSE file detected.
