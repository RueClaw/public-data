# User-Controlled RAG Research Workspace

**Source:** https://github.com/lfnovo/open-notebook
**License:** MIT
**Extracted:** 2026-05-24

## Pattern

Build research-assistant software around explicit user-controlled context boundaries instead of treating retrieval as an opaque background feature.

The reusable structure:

1. Store raw sources, user notes, generated insights, and notebooks as separate domain objects.
2. Let users decide whether each source is excluded, summarized, retrieved through RAG, or included as full context.
3. Keep transformations as durable outputs attached to sources rather than transient chat text.
4. Use a context builder that can deduplicate, prioritize, and enforce token budgets before model calls.
5. Separate exploratory chat from retrieval-based ask flows.
6. Keep provider credentials and model registrations separate from the research objects.
7. Support local models and cloud models behind the same workspace contract.

## Why It Matters

Opaque RAG systems make privacy, cost, and answer quality hard to reason about. A user-controlled workspace makes the context boundary visible: the user can see which material exists, which material is eligible for model context, and which model/provider will receive it.

This pattern is useful for:

- private research notebooks;
- legal and compliance review;
- academic literature workflows;
- internal knowledge bases;
- agent memory systems;
- any workflow where not every stored document should automatically become model context.

## Implementation Notes

- Model notebooks, sources, notes, and insights independently instead of storing everything as one document blob.
- Preserve both full source text and derived insight artifacts.
- Attach inclusion levels to context selection, not just to whole notebooks.
- Treat max-token handling as product logic, not a hidden prompt-template detail.
- Keep API key storage, model discovery, and model defaults separate from source ingestion.
- Make local providers first-class so sensitive content can stay on local infrastructure.

## Deployment Caveats

This pattern works best when paired with explicit auth, origin controls, encrypted credentials, and clear operator defaults. Local-first research tools often carry sensitive documents and provider keys, so install guides should make production hardening part of the normal path.

---

**Attribution:** lfnovo/open-notebook, MIT License.
