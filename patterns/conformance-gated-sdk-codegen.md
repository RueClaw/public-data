# Conformance-Gated SDK Code Generation

**Source:** stainlu/stainful
**Repo:** https://github.com/stainlu/stainful
**License:** MIT
**Reviewed:** 2026-05-19

## Pattern

Treat generated SDK output as a tested artifact, not a best-effort side effect. Build a semantic IR from source inputs, generate the SDK from that IR, commit a representative generated SDK, and make CI fail when regeneration changes it unexpectedly.

## Why It Matters

SDK generators are vulnerable to quiet regressions: a naming change, method signature drift, pagination mismatch, or runtime behavior change can break downstream users even when the generator still runs. stainful's useful move is to combine three checks:

- A real-world fixture generated from an actual OpenAPI spec plus SDK config.
- A byte-stability test that regenerates output and compares it to the committed SDK.
- Surface comparison against an upstream/oracle SDK, scoring resource-method recall, signature match, model-name recall, export recall, and exception recall.

## Implementation Shape

```text
source spec + generator config
        |
        v
semantic IR
        |
        v
generated SDK
        |
        +--> committed golden output
        +--> regeneration stability test
        +--> oracle public-surface comparison
```

The key is that tests assert user-visible SDK compatibility, not just internal generator behavior.

## When To Use

Use this pattern for:

- API SDK generators.
- Code generators whose output is imported by external projects.
- Agent or tool scaffolding systems where generated files become user-maintained code.
- Migration tools that claim compatibility with another framework or hosted generator.

Avoid relying on this alone when the output behavior depends heavily on live services. In that case, pair surface and golden tests with behavioral contract tests against mocks or a sandbox API.

## Source Files

- `tests/test_dogfood.py` — regeneration stability guard.
- `tests/quality/surface.py` — AST-based public API surface extraction.
- `tests/quality/compare.py` — oracle comparison metrics.
- `examples/onebusaway/` — committed real-world generated SDK fixture.

---

**Attribution:** stainlu/stainful, MIT License
