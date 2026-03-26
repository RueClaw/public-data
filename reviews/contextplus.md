# contextplus — #262

**Repo:** https://github.com/ForLoopCodes/contextplus  
**Author:** ForLoopCodes  
**License:** MIT (Copyright 2026 ForLoop)  
**Language:** TypeScript  
**Stars:** 1,547 | **Forks:** 106  
**Created:** 2026-02-27 | **Reviewed:** 2026-03-26  
**Rating:** 🔥🔥🔥🔥🔥  
**Cloned:** ~/src/contextplus

---

## What It Is

An MCP server for semantic codebase navigation. Plugs into Claude Code, Cursor, VS Code, Windsurf, or OpenCode via `bunx contextplus`. Combines Tree-sitter AST parsing, Ollama embeddings, spectral clustering, and a temporal knowledge graph into a unified 15-tool interface.

```bash
bunx contextplus init claude   # generates .mcp.json
# or add to claude_desktop_config.json manually
```

Requires Ollama running locally with `nomic-embed-text` (embeddings) and a chat model (default `gemma2:27b`).

---

## Architecture (~4,200 lines TypeScript)

Five conceptual layers:

**1. AST Parsing** (`core/parser.ts`, `core/tree-sitter.ts`) — Tree-sitter grammar per language. Extracts functions, classes, methods, imports with line ranges. Builds file headers (path + symbol inventory) for embedding.

**2. Embeddings** (`core/embeddings.ts`, ~498 lines) — Ollama-backed vector store. Indexes file headers + symbol entries. Cosine similarity search with keyword score blending (semantic + keyword → ranked results). Disk cache to avoid re-embedding unchanged files. Abort controller for cancellation.

**3. Spectral Clustering** (`core/clustering.ts`, ~198 lines) — Groups semantically related files into labeled clusters using cosine similarity matrix → eigenvalue decomposition → k-means. `semantic_navigate` uses this to surface "what belongs together" rather than what matches a query.

**4. Memory Graph** (`core/memory-graph.ts`, ~375 lines) — Temporal knowledge graph with typed edges. Nodes: concept, file, symbol, note. Edges: relates_to, depends_on, implements, references, similar_to, contains. Edge decay via `e^(-λt)` — stale links get weak automatically. Auto-similarity linking: add a batch of nodes and edges at cosine ≥ 0.72 are created automatically. Graph traversal returns neighbors scored by decay × depth.

**5. Tools** (15 MCP tools) — Discovery, Analysis, Code Ops, Version Control, Memory & RAG.

---

## Tool Highlights

**`get_blast_radius`** — given a symbol name, trace every file and line where it's imported or used. Essential for refactoring without leaving orphaned references. This is the tool that makes large-scale refactors safe.

**`propose_commit`** — the only way to write code (per the project's philosophy). Before any write: validates against strict rules, creates a shadow restore point capturing file state. `list_restore_points` + `undo_change` let you roll back AI edits without touching git.

**`semantic_navigate`** — spectral clustering browser. Returns labeled file groups by semantic relatedness — "here are the 6 files that form the authentication system" without you having to know that's what you're looking for.

**`get_feature_hub`** — Obsidian-style `[[wikilink]]` navigation. Drop `.md` hub files with wikilinks into your repo; the tool resolves them to code files. Human-readable feature maps that agents can traverse.

**`search_memory_graph`** — semantic search + graph walk. Finds embedding matches then walks 1st/2nd-degree neighbors. Returns not just what matches, but what's related to what matches.

**`prune_stale_links`** — temporal decay on graph edges. Relationships that haven't been traversed decay via `e^(-λt)` and get cleaned up automatically. The graph stays fresh without manual maintenance.

---

## What's Genuinely Novel

**Spectral clustering for navigation** — most codebase search tools return matches. `semantic_navigate` returns *structure*: here are the semantic clusters your codebase naturally forms. That's a different kind of intelligence — understanding topology, not just retrieval.

**Temporal decay on memory graph edges** — adapts to evolving codebases. A dependency that was important 6 months ago and hasn't been touched since gets lower weight automatically. This is the right model for a living codebase.

**Shadow restore points before every AI write** — `propose_commit` always snapshots before writing. Not git — a separate shadow store. Instant rollback without polluting git history. This is the right safety model for agentic code edits.

**Feature hubs as human-AI interface** — instead of trying to infer feature boundaries from code structure, you write a `.md` hub file with wikilinks and the agent can navigate by feature. Low-tech but high-leverage: humans annotate what's hard for agents to infer.

---

## Comparison to CGC

CGC (CodeGraphContext) is the codebase graph tool we have wired to ODR. Both build structural graphs of codebases for agent navigation.

| | CGC | Context+ |
|--|--|--|
| AST parsing | ✅ | ✅ (Tree-sitter) |
| Semantic search | — | ✅ (Ollama embeddings) |
| Spectral clustering | — | ✅ |
| Memory graph + decay | — | ✅ |
| Blast radius | — | ✅ |
| Shadow restore points | — | ✅ |
| Feature hubs | — | ✅ |
| Ollama dependency | — | Required |

Context+ is strictly more capable. The Ollama requirement is the tradeoff — it needs a running local model for embeddings and analysis. CGC is lighter weight for pure structural navigation.

---

## Relevance

**ODR directly** — `semantic_navigate` + `get_blast_radius` + `propose_commit` are the three tools that would most change how Claude Code works on the ODR codebase. CGC (#229 context) gave us structural navigation; Context+ adds semantic navigation + safe writes.

**As a pattern source** — the spectral clustering implementation (`clustering.ts`) and temporal decay graph (`memory-graph.ts`) are both clean extractable patterns. ~200 and ~375 lines respectively. The decay formula (`e^(-λt)`) and auto-similarity linking at cosine ≥ 0.72 are specific decisions worth studying.

**The feature hub pattern** — `.md` files with `[[wikilinks]]` as human-maintained maps that agents traverse. This is low-cost and immediately applicable to any project where humans know the domain structure better than the code structure reveals.

---

## Verdict

🔥🔥🔥🔥🔥 — Spectral clustering for topology navigation, temporal decay on memory edges, and shadow restore points before every AI write are three genuinely novel additions to the codebase-agent space. MIT, clean TypeScript, 1.5K stars in a month. 

**Install on ODR:** `bunx contextplus init claude` in the ODR project root. Needs Ollama with `nomic-embed-text`. Complements CGC — run both.  
**Steal immediately:** `clustering.ts` (spectral grouping), `memory-graph.ts` (decay graph), feature hub pattern.
