# Lossless Off-Wire Context Governor

**Source:** gbgh1/context-governor  
**Repo:** https://github.com/gbgh1/context-governor  
**License:** MIT  
**Reviewed:** 2026-08-15  

## Pattern

Keep the model-facing prompt as a bounded projection over a fuller local context store. Large, stable, or old content is persisted off-wire and replaced with compact handles; exact content remains recoverable by handle or search.

```text
agent CLI request
  -> normalize volatile prompt bytes
  -> detect bulky messages / pressure
  -> persist full content locally
  -> replace content with stable handle stubs
  -> optionally inject bounded recall slices
  -> forward compact OpenAI-compatible request upstream
  -> observe real prompt tokens / cache reuse / failures
```

## Why It Matters

Long agent sessions often fail because the host transcript grows faster than the model window. Normal compaction is lossy and can fire repeatedly when protected tails contain large tool outputs. A lossless governor moves stable mass out of the wire format while preserving the original bytes for later retrieval.

This works best when the projection is prefix-stable. Stable stubs, deterministic handles, hysteresis, and sticky recall avoid turning the governor itself into a prompt-cache breaker.

## Core Pieces

- **Durable store:** notes/state/search index as source of truth; indexes are rebuildable projections.
- **Stable handles:** deterministic, filesystem-safe IDs rendered in parseable stubs.
- **Lossless paging:** full content is stored before the prompt is shortened.
- **Bounded rehydration:** recalled content comes back under a token budget.
- **Window sensing:** thresholds scale against real or operator-declared context size.
- **Hysteresis:** cut deeper only when pressure crosses watermarks, then hold the frontier stable.
- **Cooperative tools:** MCP or similar tools let capable agents save, search, checkpoint, and rehydrate intentionally.
- **Observability:** metrics should report chars/tokens saved, recall hits, windowing triggers, and prompt-cache reuse.

## Safety Notes

The off-wire store is sensitive. It may contain prompt text, file contents, tool outputs, API responses, and private project paths. Default to loopback services, private local storage, explicit raw/capture gates, and redacted diagnostics.

Do not treat handle stubs as security boundaries. They are a context-management mechanism; the underlying store still needs normal filesystem and process isolation.

## Good Fit

- Local agent CLIs in front of llama.cpp, Ollama, vLLM, SGLang, or OpenAI-compatible providers.
- Long coding sessions with repeated file reads, build logs, tool output, or generated artifacts.
- Personal/offline assistant workflows where local storage is acceptable and context loss is worse than local persistence.

## Poor Fit

- Multi-user hosted gateways without a separate auth, tenant, and retention model.
- Workloads where storing full tool output locally is not allowed.
- Short sessions where proxy complexity costs more than it saves.

---

**Attribution:** Pattern extracted from gbgh1/context-governor, MIT, https://github.com/gbgh1/context-governor
