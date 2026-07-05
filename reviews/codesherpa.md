# codesherpa (farhankhwaja/codesherpa)

**Repo:** https://github.com/farhankhwaja/codesherpa
**License:** Apache-2.0. Permissive reuse with NOTICE attribution.
**Reviewed:** 2026-07-05
**Stack:** Python 3.11+, pygit2, SQLite/FTS5/sqlite-vec, tree-sitter, sentence-transformers, MCP stdio server
**What it is:** A local, git-native structural memory for codebases that indexes code by git blob hash and exposes compact retrieval tools to coding agents over MCP.

---

## Verdict

✅ **Deploy candidate for local pilot use.** codesherpa has a strong architecture, unusually candid eval reporting, and a serious test posture for a very young repo. It is not yet boring infrastructure: PyPI is not published, the default embedder uses `trust_remote_code`, cold init downloads large models, and the repo commits benchmark transcripts that deserve release-hygiene review. Still, the blob-keyed incremental index plus compact MCP retrieval surface is good enough to try on non-sensitive repos.

---

## What It Is

codesherpa gives coding agents a local codebase memory instead of making them grep, open whole files, and re-read large context. It creates `.sherpa/index.db`, indexes the current git `HEAD`, installs git hooks that run `sherpa sync --quiet`, and serves seven MCP tools for search, definitions, callers, references, recent changes, expansion, and index status.

The core design is content-addressed. Index entries are keyed by git blob hash, so branch switches and rebases only pay for genuinely new file content. Chunks and embeddings stay incremental while symbol and edge tables are recomputed from the active path-to-blob mapping so incremental sync can match a clean rebuild.

The project is also unusually honest about metrics. The README and `EVAL_LOG.md` report strong retrieval quality and lower file reads/tool calls, while explicitly preserving the missed target around raw token reduction. That candor matters for this category, where "saves tokens" claims are often hand-wavy.

## Stack

| Layer | Tech |
|-------|------|
| CLI | Python argparse console script `sherpa` |
| Git indexing | pygit2, git hooks, content-addressed blob cache |
| Parsing | tree-sitter and tree-sitter-language-pack |
| Storage | SQLite, FTS5, sqlite-vec |
| Retrieval | BM25, vector search, symbol search, reciprocal rank fusion, cross-encoder rerank, budget-aware packing |
| Embeddings | sentence-transformers, default `nomic-ai/nomic-embed-text-v1.5` |
| MCP | `mcp>=1.2`, stdio server |
| Tests/CI | pytest, Hypothesis golden test, MCP integration tests, GitHub Actions on Python 3.12 |

## Key Features

### Git Blob-Keyed Incremental Index

The key architectural move is indexing by blob hash rather than by path or timestamp. If a file's content already exists in the index, a branch switch can remap paths without re-parsing and re-embedding that content. This is exactly the right primitive for agent memory tied to a git repo.

### Structural Chunks and Symbol Graph

Chunks are structure-aware via cAST/tree-sitter for Python, TypeScript, JavaScript, TSX, Go, and proto. The graph layer extracts definitions, call/reference/import edges, and recent symbol-level changes. That lets the MCP server answer "where is this defined?", "who calls it?", and "what changed recently?" without dumping files.

### Compact MCP Surface

The MCP tools are compact-first. `search_code` returns breadcrumb rows with `expand_id` handles by default, and full code bodies only when the caller asks. This is a better contract than most code search MCPs, because the tool itself pushes the agent toward selective expansion.

### Measured Local Analytics

`sherpa gain` records local usage analytics without storing raw query text, code, or file paths. It separates counted facts from an explicitly labeled "estimated context avoided" metric, which is the right level of honesty for retrieval savings.

## Architecture

The repo is small and cleanly split:

- `codesherpa/gitlayer/` owns repository discovery, hooks, locking, and sync.
- `codesherpa/chunker/` owns cAST/fallback chunking.
- `codesherpa/graph/` owns symbol extraction, graph recomputation, and recent-change views.
- `codesherpa/store/` owns the SQLite schema and concrete index store.
- `codesherpa/retrieve/` owns routing, fusion, rerank, packing, and warm embedding passes.
- `codesherpa/mcp_server/` exposes the retrieval contract as MCP tools.
- `tests/` contains unit, integration, golden, MCP, and eval-gate tests.
- `verification/` records phase reports and A/B benchmark artifacts.

The strongest choice is separating sync-time work from server-time work. The MCP server does not compute embeddings or download models at startup; `init` and `sync` own warming, and `index_status` reports missing embeddings.

## Comparison

| Aspect | codesherpa | codegraph | agentmemory | context-firewall |
|--------|------------|-----------|-------------|------------------|
| Primary job | Local code retrieval memory | Local code graph/MCP | Persistent agent memory | Command-output compaction/evidence |
| Freshness model | Git hooks, blob-keyed sync | Pre-indexed graph | Hook/API memory capture | Per-command artifacts |
| Retrieval shape | Hybrid lexical/vector/symbol + MCP | SQLite/FTS/tree-sitter graph + MCP | Hybrid memory retrieval | Stored exact output spans |
| Best use | Coding-agent repo navigation | Codebase graph exploration | Cross-session memory | Safer terminal output handling |
| Main caveat | Young, model-heavy, default remote model code | Node/version caveats | Broader privacy surface | Not a code index |

## Self-Hosting Notes

There is no hosted service. Install from GitHub until PyPI is published:

```bash
pip install git+https://github.com/farhankhwaja/codesherpa
sherpa init
claude mcp add sherpa -- python -m codesherpa.mcp_server "$PWD"
```

Operational caveats:

- First run downloads the embedding model to `~/.cache/sherpa/`.
- The default `nomic-ai/nomic-embed-text-v1.5` configuration uses `trust_remote_code=True`.
- `.sherpa/` is local state and should stay gitignored.
- The repository currently includes benchmark transcripts under `verification/ab/`; audit those before using this repo as an example of clean public release hygiene.

---

**Attribution:** farhankhwaja/codesherpa, Apache-2.0, https://github.com/farhankhwaja/codesherpa
