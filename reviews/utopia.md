# Utopia (deeplethe/utopia)

**Repo:** https://github.com/deeplethe/utopia
**License:** Apache-2.0; permissive reuse with attribution
**Reviewed:** 2026-09-02
**Stack:** Rust, Axum, Postgres, pgvector, Tantivy, React, TypeScript, Vite, Docker, MCP
**What it is:** Self-hosted enterprise knowledge system that combines document ingestion, hybrid search, ontology-governed extraction, a bitemporal knowledge graph, conflict review, and read-only agent/MCP access.

---

## Verdict

✅ **Deploy candidate for serious knowledge-graph/RAG evaluation, not casual internet exposure.** Utopia is young, but the architecture is unusually coherent: ontology packs drive extraction, facts preserve valid time and record time, contradictions go to review instead of being flattened away, and the agent surface is read-only by default. The caveat is explicit in upstream's own SECURITY.md: LLM keys and datasource connection strings are plaintext in Postgres today, so treat v0.1 as trusted-network software until encryption-at-rest and operational hardening land.

---

## What It Is

Utopia is a product-shaped knowledge base rather than a library. It ingests documents and external sources, chunks and embeds text, extracts entities and facts against an ontology, records temporal provenance, and exposes search, chat, graph browsing, ontology editing, review queues, and datasource querying through a web UI.

The project is aimed at enterprise knowledge engineering: keeping a governed internal model of what documents, databases, and human review currently say, including how those beliefs changed over time. That makes it different from a plain vector store. Its core bet is that a useful AI knowledge substrate needs ontology, provenance, conflict handling, and audit records in the base layer.

The repo is already a complete Rust/React application. It ships Docker Compose, prebuilt GHCR image tags, embedded ontology packs, migrations, CI, release smoke tests, English and Chinese docs, and a security note that names current limits directly.

## Stack

| Layer | Tech |
|-------|------|
| Backend | Rust, Axum, Tokio, SQLx |
| Storage | Postgres, pgvector, filesystem data directory |
| Search | Tantivy, tantivy-jieba, pgvector hybrid retrieval, RRF |
| Ingestion | Rust parsers for PDF, Office, spreadsheets, Markdown, HTML, CSV/TSV, text |
| Ontology | OWL/RDF projection, bundled schema.org, W3C Org, PROV-O, FOAF, IOF Core packs |
| Reasoning | Custom Rust axiom checker and materialized derivation engine |
| Agent surface | Tool-calling chat, Streamable HTTP MCP endpoint, read-only exposed tools |
| Data querying | Postgres, Trino, Databricks, Snowflake connectors behind one query-engine trait |
| Frontend | React 18, TypeScript, Vite, TanStack Router/Query, Sigma graph UI |
| Deployment | Docker Compose, GHCR image, GitHub Actions release smoke test |

## Key Features

### Ontology-Governed Extraction

Documents are not only embedded for retrieval. They are parsed into entities and facts against an ontology that can start from bundled packs or imported OWL/RDFS vocabulary. Unknown entity types and predicates are deliberately allowed to remain undecided instead of being forced into a vague default relation.

This is the right failure mode. A graph that says "related_to" everywhere looks populated while losing the original claim. Utopia keeps the original wording as evidence and lets review/adoption grow the ontology later.

### Bitemporal Fact Ledger

Facts carry both world validity and system record time. Corrections close or supersede earlier facts rather than overwriting them. That gives the system enough memory to answer not only "what is true?" but "what did the system believe then, and why did that belief change?"

### Conflict and Review Workflow

Ontology axioms are treated as contracts. The reasoning crate checks self-loops, asymmetry, cycles, functional violations, signatures, inverse properties, and derived contradictions. Violations go to review instead of silently mutating source facts.

### Read-Only Agent/MCP Surface

The built-in chat can search chunks, search Utopia's own manual, find entities, inspect entity facts, query changes, query mounted databases, and record proposed memories. The MCP endpoint currently exposes only read-only tools: `search_chunks`, `search_docs`, `find_entities`, `entity_facts`, and `changes`.

That restraint matters. Personal tokens are authenticated on every MCP POST, scoped to allowed knowledge bases, checked against the user's current role, and audited when tools are called.

### Source-Native Ask-the-Data

Mounted databases are not flattened into text only. Utopia can register Postgres, Trino, Databricks, and Snowflake sources, ingest schema descriptions into the knowledge base, and let the agent run guarded SQL through a common query-engine interface. The SQL gate allows a single SELECT/WITH statement, wraps row limits, applies timeouts, and for Postgres sets a read-only session.

## Architecture

The repo is split into focused Rust crates:

- `utopia-ingest` parses files, normalizes text, chunks documents, and projects OWL/RDF.
- `utopia-extract` shapes LLM extraction prompts and parses model output.
- `utopia-reason` implements pure axiom checks and derivation logic.
- `utopia-search` wraps Tantivy and Chinese tokenization.
- `utopia-store` owns database access for accounts, graph, facts, review, tokens, sources, and audit.
- `utopia-server` ties the application API, chat tools, datasource query engines, alerting, MCP, and frontend serving together.

The docs are also part of the architecture. `docs/pipeline.md` maps how documents become graph facts, while `docs/decisions/` records the design history behind ontology import, reasoning, type resolution, source history, MCP identity, pending facts, and lakehouse querying.

## Comparison

| Aspect | Utopia | Logseq | Supermemory | OmniRetrieval |
|--------|--------|--------|-------------|---------------|
| Primary job | Governed enterprise knowledge graph/RAG app | Personal/local knowledge graph outliner | Agent memory/context platform | Research retrieval framework |
| Ontology | First-class, editable, pack/import driven | User graph/schema semantics | Memory graph/tags | Routes across source types |
| Time/provenance | Bitemporal facts, audit ledger, review queues | Notes/history/plugins | Memory history and graph context | Benchmark/query traces |
| Agent surface | Chat tools and read-only MCP | CLI/MCP/agent bridge | MCP/SDK/API | Research routing code |
| Maturity | v0.1, strong architecture and tests | Mature but AGPL/beta DB paths | Broad platform, hosted-first | Research code |

## Self-Hosting Notes

The documented quick start is:

```bash
git clone https://github.com/deeplethe/utopia.git
cd utopia
docker compose --profile app up -d
```

The app listens on `http://localhost:1516`, with Postgres bound to loopback by default on `127.0.0.1:1517`. Local development needs Rust 1.85+, Node 20+, pnpm, and Docker for Postgres/pgvector.

Important deployment caveats:

- Change the default database password before exposing anything beyond localhost.
- Keep the app and database on a trusted network for now because LLM API keys and datasource connection strings are plaintext in Postgres.
- Back up both Postgres and the `data/` directory, since raw files and full-text indexes live outside the database.
- Schema migrations are roll-forward only at v0.1.
- Use read-only datasource roles; Utopia's SQL gate is defense in depth, not a substitute for least privilege at the source.

Local validation on 2026-09-02:

- `cargo test --workspace`: passed.
- `cargo fmt --all --check`: passed.
- `cargo clippy --workspace --all-targets -- -D warnings`: passed.
- `pnpm install --frozen-lockfile && pnpm build` in `web/`: passed; Vite warned that the main JS chunk is larger than 500 kB after minification.

---

**Attribution:** deeplethe/utopia, Apache-2.0
