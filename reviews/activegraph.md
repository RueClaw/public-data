# yoheinakajima/activegraph Review

**Source:** https://github.com/yoheinakajima/activegraph  
**Author:** Yohei Nakajima / Active Graph contributors  
**License:** Apache-2.0  
**Reviewed:** 2026-05-20  
**Snapshot:** `f3ed033d36f554fe591dd4fa513e0668dbecbcb4`  
**Version:** `1.0.5.post2`

## Verdict: ⚠️ Interesting

ActiveGraph is a compact, serious Python runtime for long-running agentic systems built around an event-sourced graph. Behaviors react to graph changes, every mutation becomes an append-only event, and runs can be resumed, replayed, forked, and structurally diffed.

The core idea is strong enough to study closely and prototype with. I would still treat it as young infrastructure rather than a default production runtime: the package is new, its PyPI classifier says Alpha, and the project itself says it is not a production graph database. The architecture, tests, docs, and contracts are much stronger than its age would suggest.

## What It Is

- Event-sourced graph runtime for agent systems.
- Objects and typed relations form the shared world state.
- Behaviors react to event types, predicates, relation events, or a constrained Cypher-like pattern subset.
- LLM-backed behaviors share a provider protocol for Anthropic/OpenAI.
- SQLite is the default persistent store, with optional Postgres support.
- Runs can be replayed, resumed, forked at a prior event, and diffed.
- Packs bundle object types, behaviors, tools, prompts, and policies.

## Repository Signals

- Stars: 76
- Forks: 6
- Open issues: 1
- License: Apache-2.0
- Created: 2026-05-16
- Last pushed at review time: 2026-05-20
- Python files: 159
- Markdown files: 84
- Tests: 66 top-level test modules
- Package version: `1.0.5.post2`

## Stack

- Python 3.11+
- Hard dependencies: `click`, `pydantic>=2`
- Optional extras: Anthropic, OpenAI, tiktoken, psycopg, Prometheus client
- Stores: in-memory, SQLite, Postgres via an `EventStore` protocol
- Docs: MkDocs Material, mkdocstrings, generated `llms.txt` / `llms-full.txt`

## Strong Ideas

- **Trace as proof:** behavior starts, completions, failures, LLM calls, tool calls, patches, approvals, and graph mutations all become inspectable events.
- **Graph as shared workspace:** agents coordinate through state changes instead of direct message passing.
- **Relation behaviors:** logic can live on typed edges, which is a useful primitive for dependencies, constraints, blockers, and coordination.
- **Fork-and-diff runs:** branch a run at a prior event, rerun with different configuration or injected facts, and compare the resulting graph.
- **Replay cache:** LLM responses can be harvested from prior event logs so forks do not necessarily re-spend shared-prefix LLM calls.
- **Per-error docs:** errors point to reference pages explaining when they fire, why, and how to fix them.
- **Contracts and gates:** the repo uses `CONTRACT.md`, changelog discipline, type allowlists, docstring audits, wheel completeness, docs links, and snapshots to lock behavior.

## Risks

- **Very new project:** created days before this review; community and production history are thin.
- **Alpha classifier:** package metadata still marks it as `Development Status :: 3 - Alpha`.
- **Not a graph database:** the README explicitly says SQLite/Postgres are stores for event persistence, not high-throughput graph backends.
- **Constrained pattern language:** the Cypher subset is intentionally small; useful, but not a general graph query language.
- **Provider asymmetry:** README notes OpenAI tool use is a v1.1 candidate, while Anthropic support is further along.
- **Docs/code drift exists:** the changelog notes an `object.patched` event-name drift in docs as a v1.1 backlog item.

## Verification

Commands run against a shallow clone at `f3ed033d36f554fe591dd4fa513e0668dbecbcb4`:

- `python3.12 -m venv .venv`
- `.venv/bin/pip install -e '.[dev]'`
- Initial `.venv/bin/python -m pytest -q`: 603 passed, 15 skipped, 3 failed due missing optional Anthropic/OpenAI SDKs and missing `build` package for the wheel test.
- `.venv/bin/pip install -e '.[all]' build`
- Targeted rerun of the 3 failing tests: passed.
- Final `.venv/bin/python -m pytest -q`: 606 passed, 15 skipped in 7.55s.

Secret scan found no checked-in API keys or private keys; hits were env-var names, docs, examples, and token accounting code.

## Best Use

Use ActiveGraph when an agent system needs an auditable shared state model, resumable traces, deterministic replay checks, and forkable experiments. It is especially interesting for diligence, research, evaluation, planning, and systems where the audit log matters as much as the final answer.

For production use, expect to prototype first, harden storage/operations, and validate the runtime model against your real workload.

## Extracted Pattern

- [forkable-event-sourced-agent-runs.md](../patterns/forkable-event-sourced-agent-runs.md) — reusable architecture pattern for agent systems that need replay, audit, branch, and diff semantics.
