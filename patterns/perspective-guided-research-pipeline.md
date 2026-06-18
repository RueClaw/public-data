# Perspective-Guided Research Pipeline

**Source:** [stanford-oval/storm](https://github.com/stanford-oval/storm)
**License:** MIT
**Reviewed:** 2026-06-18

## Pattern

Split long-form research generation into inspectable stages:

1. Generate multiple topic perspectives or expert personas.
2. Simulate focused information-seeking conversations for each perspective.
3. Convert each question into bounded retrieval queries.
4. Store retrieved source snippets as structured evidence.
5. Build an outline from the collected evidence.
6. Generate section drafts against the outline and citation table.
7. Polish the article as a final stage, preserving references and intermediate artifacts.

## Why It Works

The key move is separating "what should I ask?" from "what did I retrieve?" and "what should I write?" A single summarization prompt tends to flatten the topic around whatever the first search results emphasize. Perspective-guided questioning creates deliberate coverage pressure before drafting begins.

The staged artifact model is just as important as the prompts. STORM writes conversation logs, raw search results, generated outlines, article drafts, citation mappings, run configs, and LLM call history. Those files make the system debuggable and let later stages be rerun without repeating all upstream work.

## Implementation Notes

Useful source files:

- `knowledge_storm/storm_wiki/engine.py` — staged runner and artifact writes.
- `knowledge_storm/storm_wiki/modules/knowledge_curation.py` — simulated writer/expert conversation and question-to-query flow.
- `knowledge_storm/storm_wiki/modules/outline_generation.py` — outline generation from collected information.
- `knowledge_storm/storm_wiki/modules/article_generation.py` — section drafting against retrieved evidence.
- `knowledge_storm/rm.py` — common retrieval adapters.

Generalize the pattern by keeping these contracts narrow:

- A retriever returns structured evidence, not prose conclusions.
- Question generation gets conversation context, not the full raw web.
- Drafting consumes an outline plus evidence table.
- Final polishing can improve readability, but should not erase citations or provenance.

## Caveats

Generated research reports remain drafts. The pipeline improves coverage and traceability, but it does not prove source quality or factual correctness. Add independent verification for high-stakes use, and keep untrusted web/private-corpus content visibly separate from system instructions.

---

**Attribution:** stanford-oval/storm, MIT License.
