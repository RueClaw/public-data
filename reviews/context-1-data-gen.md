# context-1-data-gen (chroma-core/context-1-data-gen)

*Review #266 | Source: https://github.com/chroma-core/context-1-data-gen | License: Apache 2.0 | Author: Chroma | Reviewed: 2026-03-26*

## Rating: 🔥🔥🔥🔥

---

## What It Is

The synthetic data generation pipeline Chroma used to train [Context-1](https://huggingface.co/chromadb/context-1), their retrieval model. Generates multi-hop search tasks across structured domains: web, SEC filings, patents, and email (Epstein corpus).

The architecture is worth studying regardless of whether you run it — it's a clean, domain-pluggable agentic pipeline for generating high-quality retrieval training data.

## The Pipeline

Each domain runs the same 5-6 stage pipeline:

```
seeds → explore → verify → distract → verify distractors → (extend) → index
```

1. **Explore** — Agent browses/searches, finds N supporting documents, formulates a question with a verifiable truth answer. Outputs clues, question, truth, supporting items + full page contents.
2. **Verify** — Quote-level verification: clue quotes must appear in clue text, item quotes in page content, truth must be present in at least one supporting item. Uses Claude Opus (smarter, more reliable).
3. **Distract** — A separate agent actively mines *plausible but wrong* documents — topically relevant pages that don't contain the truth. Hard negatives for retrieval training.
4. **Verify distractors** — Filters out distractors that accidentally contain the truth.
5. **Extend** (optional) — Chains a second hop: finds a new question whose answer bridges to a supporting URL from the previous hop. Enables multi-level reasoning chains.
6. **Index** — Chunks documents, embeds with BM25 + OpenAI dense embeddings, loads into ChromaDB.

## Architecture

Three-layer design:

**Core (`/core`)** — Abstract base classes with concrete logic. `BaseExplorerAgent`, `BaseDistractorAgent`, `BaseVerifier`, `Reranker`. Each has an `execute_tool()` + `format_initial_prompt()` + `get_force_output_message()` interface domains implement. Max-iterations failsafe throughout — agents forced to output structured XML when hitting iteration cap.

**Domains (`/domains`)** — Plug in a domain by implementing the base classes + prompts + utils. Web wraps Serper (search) + Jina (fallback scraper). SEC wraps edgartools + EDGAR filings. Patents wraps USPTO + datalab PDF extraction. Epstein wraps the public Epstein email corpus (downloaded via gdown).

**Output format** — Clean JSON per seed:
```json
{
  "tasks": [{
    "level": 0,
    "clues": "...", "question": "...", "truth": "...",
    "supporting_items": [{"id": "url", "clue_quotes": [...], "item_quotes": [...], "contains_truth": true}],
    "items_and_contents": {"url": "page text"},
    "distractors": [...]
  }]
}
```

## Key Technical Details

**Quote-based grounding.** Every supporting item cites exact quotes that must match the source. `text_contains_quote()` uses fuzzy matching (not just substring). `min_required_matches()` allows a few quote failures — realistic since web content changes. This is what makes the data trustworthy rather than hallucinated.

**Long-page handling.** When a fetched page exceeds the token budget, the agent does a semantic search over the page content to extract the relevant section, saves only the truncated portion, and logs the original token count. Trajectory entries distinguish `long_page_search` from normal `get_page` calls.

**Distractor mining is first-class.** Not bolted on — it's a dedicated agent with its own agentic loop, tool access, and XML parsing. Distractors are verified in a second pass. This is the right way to build hard negatives: actively hunt for them rather than sample randomly.

**17 truth types** for web domain: person, date, number, location, organization, etc. Forces diversity in what kinds of facts the tasks test for.

**Parallelism.** `ThreadPoolExecutor` with configurable workers throughout — all stages parallelized per-seed.

## What's Missing / Watch

- No deduplication across seeds — could generate overlapping tasks if seeds are similar
- Web domain is expensive (Serper + Jina + Claude + OpenAI embeddings per seed)
- Email domain requires downloading the Epstein corpus (~10GB via gdown) — probably not what you want for most applications
- No built-in eval harness against the generated data; Context-1 eval is presumably internal

## Relevance

**Retrieval fine-tuning.** If we ever want to fine-tune an embedding model or build eval benchmarks for Marcos's medical knowledge base or the Obsidian vault, this is the right approach. The explore→verify→distract pattern produces *verified*, *grounded* training pairs — not LLM-hallucinated Q&A.

**Pattern steal — the distractor agent.** Most RAG pipelines treat hard negatives as an afterthought. The `BaseDistractorAgent` pattern (dedicated agentic search for plausible-wrong documents, second verification pass) is worth adapting for any retrieval eval setup.

**Vault search eval.** Our Vault search (FastAPI, port 8888, 2340 docs) has no eval harness. We could run this pipeline against the vault contents to generate a small eval set — replace web search with vault search, same pipeline shape.

Context-1 weights: <https://huggingface.co/chromadb/context-1>
Technical report: <https://www.trychroma.com/research/context-1>
