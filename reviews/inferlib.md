# inferlib (SkAndMl/inferlib)

*Review #278 | Source: https://github.com/SkAndMl/inferlib | License: MIT | Author: SkAndMl | Reviewed: 2026-03-27 | Stars: 5*

## Rating: 🔥🔥🔥🔥

---

## What It Is

A from-scratch LLM inference engine built CPU-first, with paged KV cache, prefix caching, and continuous batching — the same techniques vLLM uses, implemented cleanly in ~1K lines of Python as a learning/reference project.

Benchmarks on Apple Silicon: Qwen3-0.6B at 12 tok/s, Qwen3-1.7B at 5.85 tok/s. Currently supports Qwen3 only.

5 stars, but the architecture is worth studying.

---

## Architecture

```
Python API (LLM)  ←→  FastAPI Server
                           │
                    InferlibEngine (async worker loop)
                           │
              ┌────────────┴────────────┐
         Scheduler                  Runner
    (prefill/decode batching)   (prefill · decode)
              │                        │
              └────────────┬───────────┘
                       PageManager
               (paged KV pool + prefix cache)
                           │
                     Qwen3 Model
               (GQA · RoPE · RMSNorm · SwiGLU)
```

**FastAPI server** — OpenAI-compatible `/v1/chat/completions` with SSE streaming, plus `/v1/chats/` endpoints for chat history. SQLite persistence via `aiosqlite`. Built-in React UI served alongside the API.

**Engine** — single async worker loop with per-request asyncio.Queue. Requests are queued, scheduler picks what to run next, runner executes on the model, results stream back.

---

## The Interesting Parts

### Paged KV Cache (`page.py`)

KV cache stored in a pre-allocated `_PagePool`: two tensors of shape `(num_pages, num_layers, num_heads, page_size, head_dim)`. Pages are fixed-size blocks; sequences get pages allocated as they grow.

**Prefix caching** is content-addressed: each page is hashed by its token content using a parent-chain hash (so `page_hash = hash((parent_hash, page_tokens))`). On prefill, the `PageManager` walks the sequence's tokens page-by-page, looks up each page hash in a dict, and returns a list of already-cached page IDs. Those pages are shared (refcounted) — not copied. A new prompt that shares a prefix with a prior request reuses the KV state for free.

The `_PrefillPlan` dataclass captures the split: `cached_page_ids` (reuse), `fresh_pages_needed` (compute), `prefix_cached_tokens` (skip forward).

**Eviction** is simple: when a sequence hits `max_pages_per_sequence`, the oldest page is evicted and `tokens_evicted` is incremented. The sequence "slides forward" in the KV pool.

### Scheduler (`scheduler.py`)

Two queues: `_prefill_bucket` (new sequences) and `_decode_bucket` (active sequences waiting for their next token).

`_Bucket` is a frequency-sorted structure: sequences are bucketed by `ceil(num_tokens / page_size)`. `max_freq_bucket` returns the bucket with the most waiting sequences (with round-robin skip counting to avoid starvation). This ensures prefill batches are homogeneous in length — critical for efficient attention masking when prefix lengths must match.

**Interleaved scheduling:** The scheduler does at most `_max_prefill_before_decode=2` prefill batches before forcing a decode batch. This prevents new requests from starving active sequences.

**Prefill batch constraint:** All sequences in a prefill batch must have the same `prefix_cached_tokens`. Different prefix lengths = different attention masks = can't batch together. The scheduler enforces this by breaking the batch if a sequence doesn't match the target prefix length.

### Continuous Decode

After prefill, sequences move to `_decode_bucket` (a simple deque, FIFO). Each decode step produces one token per sequence in the batch. Pages are appended on-demand as sequences grow. This is continuous batching — decode for multiple sequences proceeds in parallel without waiting for any one to finish.

---

## Stack

- Python 3.13+, PyTorch (CPU build via pytorch.org/whl/cpu index)
- FastAPI + uvicorn + aiosqlite
- Transformers 5.2.0+ (for tokenizer/model loading)
- uv for dependency management
- React + Vite + KaTeX frontend
- Docker image: `ghcr.io/skandml/inferlib:latest`

---

## What's Not Here

- **Only Qwen3.** `supported_models.py` and `qwen3.py` are the only model files. No Llama, Mistral, Phi, etc.
- **CPU-only PyTorch.** No CUDA, no MLX. The `torch = [{ index = "pytorch-cpu" }]` in pyproject.toml forces it.
- **No speculative decoding, no tensor parallelism, no quantization.**
- **12 tok/s on Apple Silicon** for a 0.6B model. Usable for experiments; not production throughput.
- **Requires Python 3.13** — newer than most environments.

---

## Relevance

🔥🔥🔥🔥 — Not a production inference engine, but one of the cleaner reference implementations of the paged KV + prefix caching + continuous batching stack. vLLM does all of this (with CUDA, tensor parallelism, 50+ model types), but inferlib is readable in an afternoon.

**Where this is useful:**
- Understanding how prefix caching works before trying to implement it in something else
- The `_Bucket` frequency-sorted scheduler is a clean pattern for batching heterogeneous-length sequences
- The content-addressed page hashing approach (parent-chain hash for prefix trees) is extractable
- The interleaved prefill/decode scheduling logic is clear and well-commented

**For the MLX / Apple Silicon inference work:** vmlx (#234) is the right production choice. inferlib's value is architectural clarity — read the scheduler and page manager if you want to understand what vmlx (or vLLM) is actually doing under the hood.

MIT. Use freely.
