# Leviathan (elstongun/leviathan)

**Repo:** https://github.com/elstongun/leviathan
**License:** Apache-2.0 (free extraction and reuse)
**Reviewed:** 2026-10-05
**Stack:** Rust 2024 (1.88+), SQLite FTS5, rusqlite (bundled), clap, serde; no runtime deps, single static binary
**What it is:** A single binary that turns records (JSONL, JSON, CSV/TSV, SQLite, or any database CLI's stdout) into a ranked full-text index, so agents answer questions about large datasets with ~450 tokens of cited result cards instead of grepping raw history.

---

## Verdict

✅ **Deploy candidate.** Leviathan solves a real, measurable problem — agents burning 100K+ tokens grepping large record sets — with a boring, correct stack: one SQLite file, FTS5, BM25, read-only queries. The benchmark methodology is reproducible and the engineering discipline (forbidden `unsafe`, atomic builds, ambiguity refusal, meaningful exit codes) is exactly what you want in a tool an agent calls unsupervised. Caveat: it is one day old (created 2026-10-05, v0.1.0), so treat the API as unstable.

---

## What It Is

Agents asked "has this happened before?" or "what fixed this last time?" over a large dataset typically grep and read raw records, which costs tokens proportional to the data. Leviathan inverts this: you index the dataset once into a single SQLite file, and the agent issues one search call that returns a handful of ranked, cited "cards" (~450 tokens median at 1M records, per the included benchmark).

The data model is generic. A field mapping (`leviathan.toml`, CLI flags, or `leviathan init` inference) declares which field is the `id`, `title`, `text`, `group` (customer/host/machine), `date`, facet `filters`, and `display` fields. Any tabular or exportable source works — Postgres via `psql | leviathan index -`, DuckDB over parquet, plain CSVs.

Integration is CLI-first: the repo ships a `skills/leviathan/SKILL.md` you drop into `~/.claude/skills/` or `AGENTS.md`, costing zero tokens until used. An optional `leviathan mcp` stdio server exposes four read-only tools (`search`, `resolve_group`, `get`, `describe`) for agents that prefer MCP.

## Stack

| Layer | Tech |
|-------|------|
| Language | Rust 2024 edition, rust 1.88+, `unsafe_code = "forbid"` |
| Index | Single SQLite file, FTS5, bundled via rusqlite |
| Ranking | BM25 × configurable boosts, title weighted 2×, recency tiebreak |
| Input | JSONL/NDJSON, JSON arrays, CSV/TSV (gzip ok), SQLite, stdin with format sniffing |
| CLI | clap derive; exit codes 0/1/2/3 with distinct semantics |
| Agent glue | Bundled SKILL.md (CLI) + optional MCP stdio server |
| Code size | ~4,500 lines of Rust across 13 modules + 410 lines of integration tests |

Dependency list is minimal (anyhow, clap, csv, flate2, regex, rusqlite, serde, strsim, toml) — no async runtime, no network stack.

## Key Features

### Group-scoped retrieval with ambiguity refusal

Search is scoped to a "group" (a customer, host, machine — the entity the question is about). The resolver tries exact key → case-insensitive key → normalized name → substring → fuzzy (strsim, cutoff 0.6). **More than one candidate in the winning tier exits with code 3 and lists candidates — it never guesses.** That is the right behavior for an autonomous agent, and it is rare.

If the group has no match, results from other groups are returned clearly labeled `OTHER <GROUP>`, so the model can't silently attribute a record to the wrong entity.

### Filters and groups as FTS tokens, not post-filters

Group scope and `--where field=value` filters are indexed as synthetic tokens in the FTS5 corpus, so scoping is a posting-list intersection that gets *cheaper* as it narrows, rather than a scan-and-filter over BM25 results. A record's own group name is excluded from scoped matching to avoid self-match noise.

### Token-budgeted cards

Only the top N records are decoded into display cards, each capped in size. Every answer reports `shown N of M` so the agent can distinguish "no match" from "no data" — a small detail that prevents a whole class of agent hallucination.

### Reproducible benchmark

`bench/` contains a deterministic synthetic dataset generator (Rust workspace member), a benchmark runner, and a report script. The headline claim — 436 median tokens vs 107K for the best grep strategy at 1M records, 99.0% top-5 answer rate, 33 ms median latency — is reproducible with two commands (~30 min, ~4 GB). The docs are honest that it's one synthetic workload with deliberately hostile properties (placeholder resolutions, distractor records, Zipf-skewed history).

### Agent-facing ergonomics

- `leviathan describe` returns a summary of the dataset (field names, facet values, date range, example calls) sized to ~640 tokens — designed to be embedded in MCP tool descriptions so the agent learns the schema once per session.
- Atomic index builds: rebuilds replace the file atomically, and open read handles reload when the file is replaced (`reload_if_replaced`).
- Incremental `upsert`/`delete` keep the index fresh without rebuilds; builds are skipped entirely when sources and mapping are unchanged.

## Architecture

Thirteen small modules, clean separation: `source.rs` (input sniffing/streaming) → `fields.rs`/`infer.rs` (mapping + inference) → `index.rs` (atomic SQLite/FTS5 build) → `query.rs` (read-only retrieval contract, documented at the top of the file) → `card.rs`/`render.rs` (token-capped output) → `mcp.rs`/`wrap.rs` (agent integration). The retrieval contract is written as a four-point comment at the top of `query.rs` and the code follows it. No `unsafe` anywhere — enforced by lint, not convention.

## Comparison

| Aspect | Leviathan | agentmemory | Plain sqlite-vec / vector store |
|--------|-----------|-------------|--------------------------------|
| Problem | Ad-hoc structured datasets too big to grep | Persistent agent session memory | Semantic similarity search |
| Retrieval | BM25 + group scope + facets | Hybrid (graph/vector/BM25) | Embedding similarity |
| Setup | Point at a file, `init` infers mapping | Hooks into agent runtime | You build the pipeline |
| Output contract | Ranked cited cards, `shown N of M` | Compact IDs, expand on demand | Raw chunks |
| Write path | Index once, upsert/delete | Continuous capture | Varies |
| Maturity | v0.1.0, one day old, 427★ | v0.9.21, months of iteration | N/A |

Leviathan is complementary to memory systems like agentmemory, not competitive: agentmemory captures what the agent *did*; Leviathan answers questions about data the agent *didn't generate*. Versus vector stores, the bet is that BM25 + a well-scoped group + facets beats embeddings for "find the record about this specific entity" questions — the benchmark supports that for entity-centric lookup, and it requires no embedding model.

## Self-Hosting Notes

`cargo install leviathan-index` or grab a prebuilt binary from Releases. No runtime dependencies; the index is one SQLite file you can commit, copy, or back up with the dataset. Read-only, offline — the query path opens the index read-only and nothing in the tool touches the network. Rust 1.88+ required to build from source.

---

**Attribution:** elstongun/leviathan, Apache-2.0
