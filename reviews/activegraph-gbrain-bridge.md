# ActiveGraph GBrain Bridge (apprentice-labs/activegraph-gbrain-bridge)

**Repo:** https://github.com/apprentice-labs/activegraph-gbrain-bridge
**License:** MIT, permissive for use, modification, and extraction with attribution
**Reviewed:** 2026-05-27
**Stack:** Python 3.11+, ActiveGraph, Pydantic v2, pytest, MCP/HTTP client boundary
**What it is:** A proof-of-concept bridge that treats GBrain as durable knowledge and schema storage while using ActiveGraph as the runtime event, provenance, replay, branching, and policy layer.

---

## Verdict

⚠️ **Interesting boundary pattern, not a deployable integration yet.** The repo is unusually honest about what works: fixture-backed demos, read-only client surfaces, replay fixtures, redaction, compatibility ledgers, and dry-run writeback proposals. It is intentionally not a production bridge today: no pack-local ActiveGraph tools, no default live lookup, no production writeback, and one ActiveGraph replay path depends on an isolated private-method shim.

---

## What It Is

This project connects two roles that often get blurred in agent systems. GBrain is positioned as the durable knowledge and ontology layer: Markdown/Git source of truth, retrieval indexes, typed links, facts, timelines, jobs, schema packs, and MCP operations. ActiveGraph is positioned as the runtime-causality layer: event log, graph projection, replay, branching, policy gates, and provenance around how an agent used or proposed changes to that knowledge.

The bridge is deliberately small. It exposes typed clients and models for GBrain operations, turns GBrain responses into ActiveGraph objects/events, records redaction-aware replay fixtures, and models writeback as proposals that can be approved, rejected, applied in dry-run form, or represented on a forked graph. The README and `STATUS.md` make clear that live production mutation is not supported.

At review time the repo was very new: created 2026-05-25, version `0.1.0`, latest commit `26d4252` on 2026-05-26, with 19 stars and 1 fork. The local test suite passed: `146 passed in 1.99s`.

## Stack

| Layer | Tech |
|-------|------|
| Language/package | Python 3.11+, setuptools |
| Runtime dependency | `activegraph>=1.0` |
| Data models | Pydantic v2 |
| Knowledge boundary | GBrain-shaped MCP/HTTP operations and fixtures |
| Tests | pytest |
| CI | GitHub Actions: install/import smoke, pytest, fixture demos |
| Safety posture | fixture-first demos, redaction, dry-run writeback, compatibility matrix |

## Key Features

### Typed GBrain Client Boundary

`activegraph_gbrain.client` defines a `GBrainClient` protocol and concrete fixture, mock, recording, local fallback, and MCP/HTTP clients. The operation surface includes search, query, page read/write, graph query, recall, trajectory lookup, job submission, and schema read operations.

Tests verify that mock and HTTP clients keep the same method signatures, and that read-only clients do not expose `schema_apply_mutations`.

### Redaction-Aware Events and Replay Fixtures

The bridge summarizes operation arguments, redacts sensitive keys and raw bodies by default, records stable operation IDs, and builds requested/completed/failed event records. Replay fixtures can be served without fallback and can optionally redact schema taxonomy.

### Policy-Gated Writeback

Writeback is modeled as a proposal object. Policies can restrict source scopes, slug prefixes, schema packs, and dry-run requirements. Approval and rejection generate trace events without mutation. Applying content writeback goes through a supplied client and remains dry-run by default.

### Fork-Before-Mutation

`activegraph_gbrain.forking` can replay a parent event prefix into a new graph, apply a writeback trace only to the fork, and produce structural diff metadata. This is a clean pattern for making proposed knowledge changes inspectable before durable mutation.

### Compatibility Ledger

The repo keeps both human and machine-readable GBrain compatibility matrices. It explicitly distinguishes `smoke-tested`, `source-inspected`, `fixture-only`, and `unverified`, including an unverified row for GBrain `0.41.11.1`.

## Architecture

The codebase is compact and readable:

- `activegraph_gbrain/client.py` defines the typed operation boundary and MCP/HTTP transport.
- `activegraph_gbrain/models.py` defines immutable wire models.
- `activegraph_gbrain/events.py` turns GBrain operations into ActiveGraph-safe event records.
- `activegraph_gbrain/redaction.py` centralizes redaction policy.
- `activegraph_gbrain/writeback.py` models proposal/approval/application traces.
- `activegraph_gbrain/forking.py` implements fork-before-writeback and diff summaries.
- `activegraph_gbrain/activegraph_compat.py` isolates the private ActiveGraph replay shim.
- `docs/gbrain_compatibility_matrix.md` and the JSON catalog hold version claims.
- `examples/` contains fixture-only demos for Q&A, memory boundaries, writeback forks, contradiction detection, trajectories, jobs, schema evolution, and public pitch.

## Comparison

| Aspect | This Bridge | ActiveGraph | GBrain |
|--------|-------------|-------------|--------|
| Primary role | Compatibility/provenance bridge | Runtime graph, events, replay, branching | Durable knowledge, schema, retrieval, MCP operations |
| Maturity | Proof of concept | External runtime dependency | External knowledge system |
| Mutation stance | Proposal/dry-run by default | Records and forks runtime state | Owns durable writes |
| Main reusable idea | Keep knowledge storage and runtime causality separate | Event-sourced graph runtime | Knowledge/schema layer |

## Self-Hosting Notes

Development install:

```bash
python -m pip install -e '.[dev]'
```

Core validation:

```bash
python -m pytest -q
python examples/import_smoke.py
python examples/brain_first_qa_demo.py
python examples/live_readonly_trace_demo.py
```

The committed examples are designed to avoid private data, live LLM calls, Slack/GitHub actions, deployments, and production writeback. Live MCP/HTTP use requires explicit endpoint/token/logging review.

---

**Attribution:** apprentice-labs/activegraph-gbrain-bridge, MIT.
