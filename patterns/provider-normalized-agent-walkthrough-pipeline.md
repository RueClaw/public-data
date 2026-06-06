# Provider-Normalized Agent Walkthrough Pipeline

**Source:** https://github.com/austeane/walkthrough  
**License:** no license specified — educational/personal use only; do not reuse implementation code without permission  
**Extracted:** 2026-06-06  
**Pattern:** Convert heterogeneous agent session histories into one normalized evidence model, reduce noise deterministically, then generate a source-backed walkthrough artifact.

## Problem

Agent session histories are too verbose for review. They mix user intent, assistant narration, tool calls, tool output, file edits, screenshots, context dumps, errors, and hidden implementation details. Raw transcript replay is technically complete but usually useless for someone trying to understand what changed.

Different agent tools also serialize their sessions differently. A review system that directly depends on every provider format becomes brittle and hard to test.

## Pattern

Split the walkthrough generator into deterministic stages around a provider-neutral event model:

1. Discover session files and metadata.
2. Strip or preserve binary media according to the review mode.
3. Normalize each provider into one JSONL event schema.
4. Project normalized events into a smaller review-oriented stream.
5. Extract deterministic session cards for high-level context.
6. Chunk projected events for LLM summarization.
7. Summarize chunks into claims, decisions, files, commands, errors, and evidence refs.
8. Merge summaries into a final walkthrough document.
9. Render an offline HTML artifact.
10. Validate both data contracts and narrative quality.

The useful separation is deterministic compression before LLM compression. The parser and projection stages decide what evidence exists and what noise can be removed. The LLM stage decides how to explain the evidence.

## Why It Works

- **Stable downstream contract:** rendering and summarization consume one event schema instead of provider-specific transcript formats.
- **Better context economics:** projection removes low-signal bulk before chunking.
- **Auditability:** claims can point back to source lines or evidence artifacts.
- **Testability:** parser, projector, chunker, renderer, and validators can be tested without invoking an LLM.
- **Reader control:** the final artifact can separate skim-level narrative from collapsed proof.

## Applicability

Use this pattern for:

- AI coding-agent review artifacts.
- Multi-session implementation walkthroughs.
- PR explanations grounded in actual agent actions.
- Local trace-to-documentation pipelines.
- Tooling that needs to support more than one agent session format.

Avoid it when:

- The session source is not trusted enough to cite as evidence.
- The desired output is a raw audit log rather than a narrative.
- The implementation cannot preserve source references through normalization and summarization.

## Implementation Notes

- Keep the normalized event schema small and explicit.
- Preserve `source_path` and `source_line` through every stage.
- Treat screenshots and binary media as optional evidence, not as mandatory pipeline state.
- Compress non-error tool output aggressively, but keep errors and command statuses visible.
- Validate final narrative quality, not just JSON validity.
- Keep the rendered artifact offline and self-contained when it is meant for long-term review.

## Caveats

The source repo has no license, so this extraction is a pattern summary only. Reimplement the idea from the concept, not from copied code.

---

**Attribution:** austeane/walkthrough, no license specified
