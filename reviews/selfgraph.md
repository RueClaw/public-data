# SelfGraph (hydra-db/selfgraph)

**Repo:** https://github.com/hydra-db/selfgraph
**Owner:** HydraDB
**License:** Apache-2.0; retain license/notices and mark modifications when redistributing. Backend and optional dependency terms remain separate.
**Reviewed:** 2026-11-15 (UTC)
**Revision:** 8124bee74334e9a5555afa52ce2d05ffc93b89d4 (v0.2.1); repository-wide architecture, with detailed Python core/store/MCP review and sampled TypeScript parity/provider code.
**Source updated:** Commit 2026-11-14 18:13:37 UTC; v0.2.1 published 18:18:08 UTC.
**Verification:** Static source, documentation, test and CI inspection only. No packages installed, source executed, database started, models downloaded, provider calls made, or runtime/security benchmarks performed.
**Stack:** Python 3.10+, Pydantic, Neo4j driver; TypeScript/Node 20+, Zod, Commander; optional graph engines, LLM adapters and MCP.
**What it is:** A developer SDK, CLI and stdio MCP server that extracts or accepts structured facts and maintains a queryable, partially temporal knowledge graph across several graph databases. It is not a graph database, autonomous assistant, or managed multi-tenant memory service.

---

## Verdict

⚠️ **Interesting — a well-documented graph layer for controlled pilots, not yet a production memory guarantee.** Deterministic operation without a model, source evidence, schema-aware retrieval and explicit backend semantics are useful. Full-scan retrieval, incomplete historical reconstruction, backend-dependent atomicity and caller-owned authorization make workload qualification essential before sensitive or concurrent deployment.

## What It Is

SelfGraph puts application semantics above a small store interface: entities, versioned relations and preferences, decision traces, sources, chunks, evidence and merge records. Applications supply a graph backend and optionally an extractor, LLM, schema or embedder. Structured facts avoid model calls entirely; free text can use regex/spaCy or structured model extraction. The repository contains genuine implementations, not just an architecture proposal. [README](https://github.com/hydra-db/selfgraph/blob/8124bee74334e9a5555afa52ce2d05ffc93b89d4/README.md), [client](https://github.com/hydra-db/selfgraph/blob/8124bee74334e9a5555afa52ce2d05ffc93b89d4/src/selfgraph/client.py), [operations](https://github.com/hydra-db/selfgraph/blob/8124bee74334e9a5555afa52ce2d05ffc93b89d4/src/selfgraph/_ops.py).

The strongest use case is a bounded graph whose facts change over time and whose answers need traceable source passages. There is no requirement to buy HydraDB: Neo4j/Memgraph, FalkorDB and embedded Kuzu adapters are present. “Any graph database” means supported adapters or a custom implementation, not interchangeable arbitrary Cypher or identical consistency guarantees.

## Stack

| Layer | Technology / responsibility |
|---|---|
| Python SDK | Pydantic models, async SelfGraph, synchronous facade, resource classes |
| TypeScript SDK | Separate implementation; Zod validation, ESM/CJS packaging, CLI |
| Storage | Neo4j/Memgraph via Bolt; FalkorDB; Kuzu; HydraDB adapter |
| Extraction | Regex/spaCy or Python Instructor + LiteLLM; TypeScript AI SDK provider adapters |
| Retrieval | BM25-style lexical scans, schema synonyms, BFS/DFS or bounded personalized PageRank; optional caller embedder |
| Agent interface | CLI and stdio MCP; host/database supply the security boundary |

## Key Features

### Deterministic-first capability tiers

The default balanced level uses the strongest free deterministic tiers: name/alias resolution, schema-based contradiction checks, lexical/synonym seeds and BFS. Passing an LLM enables extraction; other LLM tiers require opt-in. A max-tier cap can prevent LLM tiers, but is not a universal monetary or network budget: custom embedders and application code have their own effects. Inspect effective result tiers rather than assuming the requested tier ran. [Tiers](https://github.com/hydra-db/selfgraph/blob/8124bee74334e9a5555afa52ce2d05ffc93b89d4/src/selfgraph/tiers.py), [extraction](https://github.com/hydra-db/selfgraph/blob/8124bee74334e9a5555afa52ce2d05ffc93b89d4/src/selfgraph/extraction/extractor.py).

Derived IDs improve idempotence but can merge distinct names: documentation explicitly gives Acme Group and Acme Holdings becoming company:acme. Use stable explicit IDs where identity matters. LLM-assisted resolution/contradictions introduce judgment errors, not proof of identity or truth. [ID semantics](https://github.com/hydra-db/selfgraph/blob/8124bee74334e9a5555afa52ce2d05ffc93b89d4/docs/resources.md), [resolution](https://github.com/hydra-db/selfgraph/blob/8124bee74334e9a5555afa52ce2d05ffc93b89d4/src/selfgraph/resolution.py).

### Useful temporal reads, not a complete event log

Relations and preferences retain revisions. as_of uses effective/event time; known_at additionally restricts what had been recorded by a knowledge time, including retirement and certification history. Backdated corrections can change an as_of answer, while known_at can recover the earlier recorded fact. The exact reviewed release adds known_at, with targeted tests. [Temporal rules](https://github.com/hydra-db/selfgraph/blob/8124bee74334e9a5555afa52ce2d05ffc93b89d4/docs/retrieval.md), [temporal tests](https://github.com/hydra-db/selfgraph/blob/8124bee74334e9a5555afa52ce2d05ffc93b89d4/tests/test_as_of.py).

Crucially, entity property edits, decision updates, deletes, merges/unmerges and decay changes are not all reversible through these reads. An update without a new event_time keeps the old effective time. Do not describe this as universal point-in-time recovery or an immutable audit ledger.

### Evidence and answerability are useful guardrails, not guarantees

Text inserted with a source_id can yield stored source versions/chunks and quoted passages. Structured facts alone do not produce source passages. Certification marks a relation version, affects retrieval and protects against some automatic retirement/pruning; the supplied certifier name is not authenticated identity. [Provenance](https://github.com/hydra-db/selfgraph/blob/8124bee74334e9a5555afa52ce2d05ffc93b89d4/src/selfgraph/provenance.py), [trust documentation](https://github.com/hydra-db/selfgraph/blob/8124bee74334e9a5555afa52ce2d05ffc93b89d4/docs/trust.md).

check_answerable matches lexical terms/schema synonyms and tests connectivity, with a hub warning. It does not prove that the graph logically answers a question, that evidence is correct, or that a downstream model will abstain. Source passages remain untrusted text when passed to an agent. A connected false fact is still false.

## Architecture

SelfGraph orchestrates validation, extraction, identity resolution, writes and retrieval; resource classes expose typed operations. _ops implements semantic behavior; stores translate graph primitives and physical layouts. Python and TypeScript are separate implementations backed by cross-language conformance CI, rather than generated bindings. [Python layout](https://github.com/hydra-db/selfgraph/blob/8124bee74334e9a5555afa52ce2d05ffc93b89d4/src/selfgraph/client.py), [TypeScript client](https://github.com/hydra-db/selfgraph/blob/8124bee74334e9a5555afa52ce2d05ffc93b89d4/typescript/src/client.ts), [CI](https://github.com/hydra-db/selfgraph/blob/8124bee74334e9a5555afa52ce2d05ffc93b89d4/.github/workflows/ci.yml).

### Storage, consistency and query costs

- Neo4j/Memgraph use real transaction begin/commit/rollback and subject locking; failed batches can roll back. AutoCommitStore serializes writes per store object but does not provide equivalent rollback. HydraDB, Kuzu and FalkorDB can retain partial batches; cross-process writes on auto-commit backends are not serialized by this SDK. Replaying idempotent inserts helps reconciliation but is not exactly-once processing. [Transactional store](https://github.com/hydra-db/selfgraph/blob/8124bee74334e9a5555afa52ce2d05ffc93b89d4/src/selfgraph/stores/cypher.py), [auto-commit implementation](https://github.com/hydra-db/selfgraph/blob/8124bee74334e9a5555afa52ce2d05ffc93b89d4/src/selfgraph/stores/_cypher.py), [concurrency contract](https://github.com/hydra-db/selfgraph/blob/8124bee74334e9a5555afa52ce2d05ffc93b89d4/docs/backends.md).
- Raw Cypher is backend-native. Kuzu uses N/R tables with JSON records; HydraDB uses sid and RELATES/etype with a narrower dialect; Bolt/FalkorDB use more conventional labels. Raw writes can bypass SDK invariants and HydraDB resolution indexes.
- _scan_seeds performs up to two paginated passes over every entity per query for corpus statistics and ranking. It bounds memory, not total work. max_nodes, depth and context token caps constrain later output/traversal, not initial corpus scanning. check_answerable loads the namespace's entities and relations. [Retrieval implementation](https://github.com/hydra-db/selfgraph/blob/8124bee74334e9a5555afa52ce2d05ffc93b89d4/src/selfgraph/retrieval.py).
- Optional embeddings are an in-process cache, not a durable ANN index. Cold use embeds the namespace and scores every entity; restarts/cache churn can repeat provider work. No throughput/latency/answer-quality benchmark suite or raw comparative measurements were found in the reviewed tree. Claims about usefulness are supported by implementation/tests, not independent scale evidence.

### Auth, tenancy, network and credentials

Typed operations carry namespace filters, but namespaces are not authorization boundaries. SDK/CLI raw Cypher is not namespace-scoped and can write. MCP raw Cypher has a lexical read-only guard, but still reads any namespace accessible to the backend credential. The MCP server also registers explicit mutation and deletion tools; read-only raw queries do not make the whole server read-only. [MCP guard/tools](https://github.com/hydra-db/selfgraph/blob/8124bee74334e9a5555afa52ce2d05ffc93b89d4/src/selfgraph/mcp/server.py), [runtime validation](https://github.com/hydra-db/selfgraph/blob/8124bee74334e9a5555afa52ce2d05ffc93b89d4/src/selfgraph/runtime.py).

The documented MCP entry point is stdio. There is no reviewed end-user login/RBAC/tenant service to place on the public internet, and browser CORS is not the relevant default boundary. A trusted host process possesses the database and provider authority. Restrict tools in the host, separate databases/credentials for hostile tenants, and use database-enforced permissions rather than relying on a query keyword filter. Initialization may need schema-creation authority; plan provisioning separately from least-privilege runtime access.

Database auth and provider keys can come from settings/environment; CLI secret flags risk shell history/process exposure. Secure transport is operator-owned: plain Bolt/Redis examples do not establish TLS. Configure encrypted connections and validate endpoint policy before handling sensitive data. Custom model base URLs and embedders are egress choices, not safe destinations merely because they were configured.

Python sends model prompts through LiteLLM/Instructor; TypeScript uses AI SDK provider packages. Extraction sends document chunks, instructions and potentially schema material; higher resolution/contradiction tiers send candidate facts. Embedding calls expose query/entity text to the chosen implementation. Logs/error strings may contain provider/backend details; disabling verbose logging is not comprehensive redaction. No application-level encryption, provider retention guarantee or hard spend ceiling was established. Costs include storage, multiple extraction passes per chunk, retries, optional judgment calls and cold embeddings. [Python provider adapter](https://github.com/hydra-db/selfgraph/blob/8124bee74334e9a5555afa52ce2d05ffc93b89d4/src/selfgraph/llm/base.py), [TypeScript adapter](https://github.com/hydra-db/selfgraph/blob/8124bee74334e9a5555afa52ce2d05ffc93b89d4/typescript/src/llm/index.ts).

### Retention, export, deletion and recovery

History and source evidence intentionally persist. Maintenance decay/prune/dedupe is explicit and dry-run by default, not an automatic TTL. Pruning retired facts is not equivalent to expiring every historical/source record, and certified relations are protected unless explicitly included. [Maintenance](https://github.com/hydra-db/selfgraph/blob/8124bee74334e9a5555afa52ce2d05ffc93b89d4/docs/maintenance.md).

Entity deletion cascades through relations/preferences/evidence/merge records and affected decisions, with documented exceptions for alternatives and about references. Source/chunk records are distinct: do not infer complete subject-data erasure from deleting an entity. A privacy deletion plan must inspect source text, prior versions, other graph references, exports, provider retention and backups as well. [Deletion code](https://github.com/hydra-db/selfgraph/blob/8124bee74334e9a5555afa52ce2d05ffc93b89d4/src/selfgraph/_ops.py), [deletion tests](https://github.com/hydra-db/selfgraph/blob/8124bee74334e9a5555afa52ce2d05ffc93b89d4/tests/test_delete.py).

Obsidian export produces readable current-state notes, not a round-trip full-history backup. Ossie export is an ontology conversion with explicit omissions, not a database recovery format. No complete cross-backend backup/restore protocol was established. Use backend-supported consistent backups, retain external schema/settings securely, and test restores including histories/provenance. Partial writes on auto-commit adapters and deletes cannot be repaired by known_at alone. [Export implementation](https://github.com/hydra-db/selfgraph/blob/8124bee74334e9a5555afa52ce2d05ffc93b89d4/src/selfgraph/_export.py), [export API](https://github.com/hydra-db/selfgraph/blob/8124bee74334e9a5555afa52ce2d05ffc93b89d4/src/selfgraph/client.py).

## Maturity, Installation and Evidence

Public GitHub metadata retrieved 2026-11-15 reports creation on 2026-11-04, 47 stars, 4 forks and zero open issues (the API aggregate is not a security assessment). v0.2.1 is published and matches the reviewed SHA. This is a very young public project despite substantial code and documentation. [Metadata](https://api.github.com/repos/hydra-db/selfgraph), [release](https://github.com/hydra-db/selfgraph/releases/tag/v0.2.1).

CI defines Python 3.10–3.13 builds/tests, Node 20/22/24 tests, Kuzu runs, Neo4j/Memgraph/FalkorDB integration jobs and cross-language conformance. Tests cover temporal reads, namespaces, deletion, extraction, schema, MCP and backend behavior. This is stronger evidence than screenshots; it does not mean those jobs passed at this SHA or that production recovery/performance has been validated here. HydraDB is not included in the displayed CI backend matrix. Tests and CI were inspected, not executed or independently reproduced.

Python core depends on pydantic and neo4j, with broad minimum versions and optional extras adding Instructor/LiteLLM, spaCy, Kuzu, FalkorDB, tokenizer and MCP. TypeScript has a lockfile but broad optional provider peers. CI actions use version tags and some database images use latest; release publishing is a separate workflow, not visibly dependent on successful full CI. npm declares provenance; that is not a verification of an installed artifact. Pin versions, minimize extras and validate upgrades on representative data. No dependency vulnerability audit or registry artifact verification was performed. [Python manifest](https://github.com/hydra-db/selfgraph/blob/8124bee74334e9a5555afa52ce2d05ffc93b89d4/pyproject.toml), [TypeScript manifest](https://github.com/hydra-db/selfgraph/blob/8124bee74334e9a5555afa52ce2d05ffc93b89d4/typescript/package.json), [publish workflow](https://github.com/hydra-db/selfgraph/blob/8124bee74334e9a5555afa52ce2d05ffc93b89d4/.github/workflows/publish.yml).

## Comparison

| Option | Prefer it when | Tradeoff relative to SelfGraph |
|---|---|---|
| [Graphiti](https://github.com/getzep/graphiti) | Evaluating a dedicated temporal agent-knowledge graph stack | Closest conceptual comparison; assess current provider/storage requirements independently rather than assume equivalence |
| Direct Neo4j/Memgraph driver | Database-native indexing, permissions and transactional queries dominate | More application work for extraction/provenance/version semantics, fewer abstraction surprises |
| SQLite FTS + explicit relational history | Small local corpus needs indexed text and straightforward recovery | Less native graph traversal; often simpler operationally than several graph adapters |
| [Utopia review](utopia.md) | Seeking a larger knowledge application rather than an embeddable SDK | Broader ingestion/service scope; not a drop-in library comparison |

These are architectural alternatives, not measured head-to-head winners. SelfGraph's differentiator is the combination of deterministic-first tiers, evidence, schema/ontology support and backend choice—not proven superiority in recall or throughput.

## Self-Hosting Notes

Treat it as a library integration, not a turnkey hosted product. For a pilot, choose one backend, pin SDK and dependencies, start with structured synthetic facts and no LLM, use explicit IDs, and test namespace/raw-query boundaries. Use a single writer for auto-commit adapters; prefer a transactional backend for contention and rollback requirements. Kuzu allows one owning process per database file and has documented virtual-address-space sizing constraints.

Before production, demonstrate failure/retry reconciliation, historical query expectations, deletion of source-bearing data, consistent backup/restore, provider egress/cost limits and representative retrieval latency. Only promote after those tests match the intended workload. No deployment was performed for this review.

---

**Attribution:** HydraDB / hydra-db/selfgraph, Apache-2.0. Analysis only; no source code extracted. All technical source links are pinned to the reviewed commit unless explicitly marked public metadata/release/alternative.
