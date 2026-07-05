# Git Blob-Keyed Code Memory

**Source:** farhankhwaja/codesherpa
**Repo:** https://github.com/farhankhwaja/codesherpa
**License:** Apache-2.0
**Reviewed:** 2026-07-05

## Pattern

Build a local codebase memory around git blob hashes instead of file paths, mtimes, or branch names. A blob hash is the stable identity for file content, so the index can survive branch switches, rebases, checkouts, and merges without redoing work for content it has already seen.

## Why It Works

Agent code-search tools need freshness, but full rebuilds make local indexing feel too expensive. Git already gives the right cache key: content-addressed blobs.

The useful split:

- Store expensive per-content work by blob hash: parsing, chunking, embeddings.
- Store active repository state as a path-to-blob mapping for the current ref.
- Reactivate known blobs when they return on another branch.
- Soft-deactivate unreachable blobs instead of deleting them.
- Recompute path-dependent projections, such as cross-file symbols and edges, from the active mapping when needed.
- Expose compact retrieval handles first, then let the agent expand only the chunks it needs.

## Minimal Schema

```sql
blobs(blob_hash primary key, language, size_bytes, active)
files(ref, path, blob_hash, primary key(ref, path))
chunks(chunk_id primary key, blob_hash, byte_start, byte_end, file_path, code, breadcrumb)
embeddings(chunk_id primary key, model, dim, vector)
symbols(node_id primary key, symbol, blob_hash, byte_start, byte_end, file_path)
edges(src, dst, kind, primary key(src, dst, kind))
```

The exact tables can vary, but the identity rule matters: durable content work belongs under blob or chunk identity; current checkout state belongs under ref/path mappings.

## Implementation Guidance

Use git hooks for freshness, but keep them quiet and bounded. Hooks should never trigger first-time model downloads or long silent work. The foreground command should own cold setup, model downloads, and progress reporting.

Add a golden test: after random git operations, compare the incremental index against a fresh rebuild at the same `HEAD`. If those projections differ, the index is not trustworthy enough for agents.

## Good Fit

- Local MCP servers for coding agents
- Codebase graph/search tools
- Branch-heavy repositories
- Agent memory that must survive rebases and checkouts
- Retrieval systems with expensive embeddings

## Bad Fit

- Non-git workspaces
- Data that depends on path semantics more than content identity
- Remote multi-tenant indexes where repo-local hooks are not available
- Security-sensitive environments that cannot allow local model downloads or `trust_remote_code`

---

**Attribution:** Extracted from farhankhwaja/codesherpa, especially `codesherpa/gitlayer/sync.py`, `codesherpa/store/schema.sql`, and `codesherpa/graph/index.py`. Apache-2.0.
