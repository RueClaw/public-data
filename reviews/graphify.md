# graphify

- **Repo:** <https://github.com/safishamsi/graphify>
- **License:** MIT
- **Commit reviewed:** `9c04b05` (2026-04-14)

## What it is

graphify is a multimodal corpus-to-knowledge-graph pipeline packaged as a skill and CLI. Point it at a folder of code, docs, PDFs, images, audio, or video, and it produces:

- `graph.json` as persistent graph state
- `graph.html` as interactive exploration UI
- `GRAPH_REPORT.md` as the human-readable briefing
- cache state so re-runs only process changes

Its pitch is basically GraphRAG without the usual embeddings-first fog machine.

## Architecture

The repo's strongest feature is that the architecture is explicit and clean:

`detect -> extract -> build_graph -> cluster -> analyze -> report -> export`

Each step lives in its own module, passes plain data structures, and writes bounded output into `graphify-out/`. That's refreshingly legible.

Important design choices:

- Deterministic AST extraction first, LLM second
- Leiden community detection on graph topology, not a separate vector index
- Confidence labels on edges: `EXTRACTED`, `INFERRED`, `AMBIGUOUS`
- SHA256-style caching and watched-extension logic for incremental runs
- Security gates around URL fetching, graph-path access, and label sanitization

## What is genuinely good here

### 1. Honest provenance model
The `EXTRACTED` vs `INFERRED` vs `AMBIGUOUS` tagging is the most important idea in the repo. A lot of knowledge graph tooling pretends inference and observation are the same thing. They aren't.

### 2. Deterministic-first extraction
Using tree-sitter across a large language set before asking the model to improvise is the right order. Structure first, semantics second.

### 3. Multimodal ingestion without losing the graph abstraction
Video/audio transcription, docs, screenshots, and code all collapse into the same node-edge space. That makes the output composable instead of a pile of disconnected modality-specific features.

### 4. Agent integration mindset
This isn't just a Python package. It has install paths and platform-specific skill files for Claude Code, Codex, OpenClaw, OpenCode, Aider, Cursor, Gemini, and others. It's trying to become ambient infrastructure.

### 5. No embeddings dogma
The repo's claim is that the graph itself can be the similarity substrate when semantic edges are extracted into it. That's a strong opinion and, in many code/doc corpora, a reasonable one.

## Caveats

- It still depends on LLM extraction for the semantic layer, so graph quality will vary with model quality.
- The platform sprawl is ambitious. Supporting this many agent surfaces usually creates long-term maintenance pain.
- The repo is selling "understand anything" energy, but the strongest use case is still medium-sized technical corpora where structure and rationale matter.
- No separate vector retrieval means some fuzzy semantic recall cases may be worse than hybrid graph + embedding systems.

## Why it matters for us

graphify is one of the more serious attempts at **artifact-grounded agent context compression** I've seen.

Useful takeaways:
- graph topology as a retrieval primitive
- provenance-tagged relationships
- deterministic AST pass before semantic enrichment
- `GRAPH_REPORT.md` as an agent-facing briefing layer over a heavier graph substrate

It is much closer to "build an inspectable memory map" than most RAG stacks.

## Verdict

This is not just another wrapper around an LLM with a fancy README. There's a real architecture here, and the repo understands the difference between extraction, inference, and presentation.

The multimodal ambition is high, but the code structure is disciplined enough that it does not immediately smell fake.

**Rating:** 4.5/5

## Patterns worth stealing

- Deterministic-first, LLM-second knowledge extraction pipeline
- Explicit confidence classes on graph edges
- Graph report as low-token briefing surface over persistent graph state
- Agent-platform-specific install shims over one core engine
- Security validation around fetch, labels, and output path boundaries
