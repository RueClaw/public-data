# Conformance-First Service Emulator

**Source:** https://github.com/nubo-db/dynoxide
**License:** MIT OR Apache-2.0
**Reviewed:** 2026-06-20

## Pattern

Build a local emulator for a cloud service around an executable conformance suite, not around ad hoc examples. The emulator should be fast and embeddable, but its compatibility story should come from repeatable tests against the real service.

Dynoxide applies this to DynamoDB: a native Rust/SQLite engine implements the DynamoDB API, while an external conformance suite compares behavior against real AWS DynamoDB and other emulators.

## Why It Works

Local emulators are useful only when developers trust their edge cases. A conformance-first approach turns compatibility into a maintained artifact:

- real-service behavior becomes the reference
- emulator claims can be measured as the suite grows
- regressions become normal test failures
- documentation can point to live coverage instead of static marketing
- unsupported cloud-only features can be named explicitly

This is especially important for databases and APIs where small validation, pagination, and error-shape differences break real client code.

## Core Components

- **Reference target:** run the same cases against the real cloud service.
- **Competitor targets:** compare against existing local emulators to reveal practical gaps.
- **Tiered coverage:** separate core CRUD, complete feature coverage, and strict error-fidelity tests.
- **Embedded mode:** expose a no-server library API for fast isolated tests.
- **Server mode:** expose the wire-compatible local endpoint for SDK tests.
- **Compatibility summary:** publish operation, expression, index, and limitation coverage.
- **Benchmark harness:** measure startup, memory, throughput, and CI impact against incumbents.
- **Release gates:** run feature combinations, lints, dependency policy, and smoke tests in CI.

## Implementation Notes

- Make the storage backend swappable before adding non-native targets.
- Keep cloud-infrastructure features explicitly out of scope when they have no local meaning.
- Match error envelopes and validation ordering, not just happy-path responses.
- Use the same operation names and request/response shapes as the real service.
- Model pagination cursors carefully; emulator bugs often hide there.
- Give tests a direct embedded API so they avoid ports, containers, and startup delays.
- Publish limitations beside compatibility claims.

## Good Fit

- Local database emulators.
- Local versions of managed queues, event buses, object stores, or key-value stores.
- CI fixtures that need realistic API behavior with low startup cost.
- Agent sandboxes where tools should manipulate disposable service-shaped state.

## Watch Outs

- A partial emulator can create false confidence if limitations are hidden.
- The conformance suite must evolve with the real service.
- Matching error messages can become a maintenance burden.
- Local semantics may not reproduce distributed behaviors like eventual consistency, throttling, capacity, or contention.
- Exposing an emulator endpoint on a network needs a separate threat model from local test use.

## Minimal Checklist

1. Define the supported subset and the intentionally unsupported cloud-only APIs.
2. Build a conformance suite that runs against the real service.
3. Run the same suite against the emulator and incumbents.
4. Gate releases on conformance, lint, dependency policy, and smoke tests.
5. Provide an embedded test API and a wire-compatible local server.
6. Document current coverage and limitations.
7. Treat security separately for any network or agent-facing transport.

---

**Attribution:** nubo-db/dynoxide, MIT OR Apache-2.0
