# Tiered KV Cache Inference Layer

**Source:** LMCache/LMCache  
**Repo:** https://github.com/LMCache/LMCache  
**License:** Apache-2.0  
**Reviewed:** 2026-07-10

## Pattern

Treat LLM KV cache as an explicit serving layer rather than as private, temporary state inside one inference process. Move reusable KV blocks through GPU, CPU, local disk, remote storage, and peer-to-peer transport tiers under a common management and observability surface.

## Shape

```text
LLM serving engine
  -> KV connector
  -> external cache service
       -> token/chunk index
       -> GPU/CPU transfer adapters
       -> L1 memory manager
       -> L2 storage adapters
       -> cache-control API
       -> metrics/tracing/events
```

## Why It Works

Long-context serving spends a lot of time recomputing KV state that may already exist from prior requests, documents, conversations, or prefill workers. A tiered cache layer lets the serving system decide when it is cheaper to retrieve than recompute.

The useful design properties are:

- cache lifecycle is independent from any one model server process;
- GPU memory only holds the active working set;
- CPU pinned memory serves as hot cache and transfer buffer;
- disk or remote storage stores larger or persistent reuse sets;
- peer-to-peer transfer supports prefill/decode disaggregation;
- cache control APIs support lookup, clear, pin, move, compression, and health checks;
- request and token-level metrics expose actual hit ratios and transfer costs.

## Implementation Notes

- Keep engine-specific connector code thin. The cache service should own storage, eviction, metrics, and lifecycle.
- Use chunked token keys rather than whole prompts so partial reuse is possible.
- Make transfer cost explicit. Add a minimum retrieve threshold so small hits can be recomputed instead of loaded.
- Separate prefix reuse from non-prefix reuse; non-prefix reuse needs extra quality recovery checks.
- Keep cache mutation APIs private or authenticated. Clear, move, pin, and compression endpoints are operational controls, not public user APIs.
- Treat runtime storage plugins as trusted code, not as data configuration.
- Add observability before optimizing. Cache hit tokens, requested tokens, transfer bytes, eviction, and backend latency determine whether the cache is helping.

## Caveats

This pattern is infrastructure, not a free speedup. It adds privileged GPU/runtime deployment concerns, shared-memory and IPC requirements, cache consistency questions, backend credentials, and new control-plane APIs. It pays off when prompts have meaningful repeated context and when operators can measure hit ratios and transfer overhead.

---

**Attribution:** Pattern extracted from LMCache/LMCache, Apache-2.0.
