# Persistent Codebase Knowledge Graph

**Source:** https://github.com/Lum1104/Understand-Anything  
**Author:** Lum1104 / Yuxiang Lin  
**License:** MIT  
**Reviewed:** 2026-05-23

## Pattern

Analyze a codebase once into a durable graph artifact, then reuse that graph for dashboard exploration, onboarding, chat, file explanation, and diff impact analysis.

The important move is making the graph a real intermediate representation instead of a hidden prompt cache. Understand Anything writes .understand-anything/knowledge-graph.json with project metadata, nodes, edges, layers, and tour steps. Later commands query that graph rather than re-scanning or asking a model to infer architecture from scratch.

## Why It Works

Large-codebase assistance fails when every question starts from raw files. A persistent graph gives agents and humans a shared map:

- file/function/class/config/doc nodes
- imports, contains, calls, configures, documents, deploys, and domain/knowledge edges
- architectural layers
- guided tour steps
- diff overlays for changed and affected nodes

That map is imperfect, but it is inspectable, versionable, and reusable.

## Core Components

- **Deterministic scan:** enumerate files, languages, frameworks, categories, line counts, and import maps.
- **Structural extraction:** use tree-sitter and parsers before LLM summarization.
- **LLM enrichment:** summarize nodes, explain roles, infer relationships, build tours.
- **Validation:** check schema, referential integrity, layer coverage, duplicates, and graph completeness.
- **Durable artifact:** write .understand-anything/knowledge-graph.json.
- **Query commands:** use the graph for chat, explain, diff, onboard, and dashboard views.
- **Local dashboard:** visualize graph structure and inspect graph-backed file content.

## Implementation Notes

- Keep the graph schema typed and versioned.
- Separate structural facts from LLM-authored summaries.
- Track the git commit hash used to generate the graph.
- Exclude intermediate files and local diff overlays from committed graph artifacts.
- Gate file-content preview through graph membership and path normalization.
- Use Git LFS when graph JSON grows past normal repository-friendly sizes.
- Build incremental update around file fingerprints and changed-file lists.

## Good Fit

- New-developer onboarding.
- Agentic code review and change planning.
- Large monorepos where architecture is hard to recover from file trees alone.
- Documentation sites that should stay tied to source structure.
- Pre-commit or PR impact analysis.

## Watch Outs

- Graph quality depends on both extractor coverage and LLM summary quality.
- Stale graphs are worse than no graph if users trust them blindly.
- Large graphs need storage and review policy.
- Serving source previews from a local dashboard needs strict localhost/token/path controls.
- Dependency hygiene matters because dashboard tooling commonly includes dev-server file-serving code.

## Minimal Checklist

1. Scan files deterministically.
2. Extract structure before invoking LLMs.
3. Write typed nodes and edges to a versioned graph.
4. Validate referential integrity and layer coverage.
5. Store commit metadata with the graph.
6. Reuse the graph for explain, diff, onboard, and dashboard commands.
7. Keep generated graph artifacts intentionally included or excluded by policy.

---

**Attribution:** Lum1104/Understand-Anything, MIT
