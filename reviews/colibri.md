# Colibri (JustVugg/colibri)

**Repo:** https://github.com/JustVugg/colibri  
**License:** Apache-2.0; permissive reuse with attribution and notice preservation  
**Reviewed:** 2026-07-11  
**Stack:** C, OpenMP, AVX2 integer kernels, safetensors reader, Python stdlib tools/server, optional CUDA, React/Vite web UI  
**What it is:** Colibri is a tiny dependency-light inference engine for running GLM-5.2 744B MoE on consumer hardware by keeping dense weights resident and streaming routed experts from disk.

---

## Verdict

✅ **Deploy candidate for local-inference experiments, not production serving.** Colibri is a serious systems experiment: pure C runtime, disk-streamed MoE experts, compressed MLA KV cache, int4/int8 quantization paths, OpenAI-compatible serving, a web client, and local tests that pass. It is still slow, hardware-sensitive, and missing full published quality benchmarks, but the core idea is real enough to run and measure.

---

## What It Is

Colibri targets a very specific question: can a 744B-parameter mixture-of-experts model answer on a machine with roughly laptop-class RAM if the inactive experts stay on disk? The answer is yes, slowly. The README reports a dense resident set around 9.9 GB, a 370 GB int4 model on disk, and cold decode dominated by roughly 11 GB of expert reads per token.

The engine exploits GLM-5.2's MoE structure: dense components, embeddings, attention, shared experts, and caches stay resident; routed experts are loaded on demand with per-layer caching, page-cache help, optional pinned hot experts, and experimental prefetch. The runtime is intentionally plain C. Python is used for conversion, resource planning, benchmarking helpers, and a stdlib OpenAI-compatible gateway.

This is not a general-purpose LLM serving stack. It is a readable, hardware-aware engine for making a huge MoE model run on constrained machines and for collecting honest bottleneck data.

## Stack

| Layer | Tech |
|-------|------|
| Core runtime | C, OpenMP, AVX2/scalar fallback, safetensors reader |
| Model format | GLM-5.2 FP8 converted shard-by-shard to int4/int8 Colibri container |
| Attention/cache | MLA attention, compressed KV cache, optional KV persistence |
| Expert tiering | Disk-backed routed experts, per-layer LRU, learned hot expert pinning, optional CUDA resident tier |
| API | Python stdlib OpenAI-compatible HTTP server |
| UI | React 19, Vite, TypeScript, Tailwind-style CSS, SSE Chat Completions client |
| Tests | C unit tests, Python stdlib unit tests, web TypeScript/Vite build |

## Key Features

### Disk-Streamed MoE Execution

The core trick is not trying to load the whole model. GLM-5.2 activates only a subset of experts per token, so Colibri stores routed experts on NVMe and reads the needed expert weights as routing selects them. A per-layer LRU cache, learned `.coli_usage` hot-store, and optional pinned RAM/VRAM tiers turn repeated routes into cache hits.

### Compressed MLA KV Cache

The README claims GLM-5.2's MLA cache is 576 floats/token rather than 32,768, a 57x reduction. Colibri also persists KV state to `.coli_kv` files so conversations can reopen warm without prefill, with a slot mechanism for isolated contexts in the HTTP server.

### OpenAI-Compatible Local API

`coli serve` exposes `GET /v1/models`, `POST /v1/chat/completions`, legacy completions, SSE streaming, basic usage counts, queue admission, optional API key, and CORS controls. It is deliberately one-generation-at-a-time because the engine owns a mutable KV context.

The defaults are sane for local use: bind to localhost by default, warn if listening beyond localhost without `COLI_API_KEY`, and explicitly reject unsupported OpenAI parameters instead of silently ignoring them.

### Resource Planner

`coli plan` reads safetensors headers without allocating model tensors and estimates disk, dense bytes, expert bytes, runtime reserve, RAM cache slots, and VRAM hot-tier capacity. That is a useful pattern for large local model runners: plan before loading.

### Honest Performance Notes

The README does not pretend this is fast. It publishes cold and community benchmarks, calls out disk/RAM/matmul bottlenecks, warns about thermals and swap, and asks for quality benchmarks because full int4 accuracy evaluation is still missing.

## Architecture

The runtime is intentionally flat:

- `c/glm.c` is the GLM engine.
- `c/st.h`, `tok.h`, `json.h`, and `compat.h` keep runtime support small.
- `c/coli` is the user-facing CLI wrapper.
- `c/openai_server.py` is the dependency-free HTTP gateway.
- `c/tools/` contains conversion, fixture, benchmark, and validation helpers.
- `web/` is a pure OpenAI-compatible browser client and does not touch the engine directly.

This is good for auditability. The project is young, but it is not opaque.

## Comparison

| Aspect | Colibri | Flash-MoE-style local runners | LMCache | llama.cpp-class runtimes |
|--------|---------|-------------------------------|---------|--------------------------|
| Focus | Run one huge MoE on constrained RAM | High-end local MoE feasibility | KV-cache serving layer | General local LLM runtime |
| Main trick | Stream routed experts from disk | Usually memory/GPU-heavy local inference | Cache reuse across requests | Broad quantized model support |
| Runtime | Tiny C engine | Varies | Python/C++ service layer | Mature C/C++ ecosystem |
| Strength | Radical hardware accessibility and readable code | Throughput when hardware fits | Serving/caching infrastructure | Model breadth and maturity |
| Caveat | Slow, model-specific, quality benchmarks incomplete | Hardware demands | Not an inference engine | Not designed around 744B disk-streamed MoE |

## Self-Hosting Notes

For a local experiment:

1. Build in `c/` with `./setup.sh` or `make test`.
2. Use the pre-converted GLM-5.2 Colibri int4 model on Hugging Face, or run the FP8-to-int4 converter.
3. Put the ~370 GB model on real local NVMe, not a network mount.
4. Start with `COLI_MODEL=/path/to/model ./coli plan`, then `./coli chat`.
5. Only expose `coli serve` beyond localhost with `COLI_API_KEY` and explicit CORS origins.

Do not expect production throughput. Expect a hardware experiment that becomes more useful as RAM, NVMe bandwidth, cache warmth, and pinned expert tiers improve.

## Verification Notes

Local checks on 2026-07-11:

- Cloned current `main` at `1bdaeee82ed143c6b7480186e5b9a4614909aa55`.
- GitHub metadata: 3,245 stars, 249 forks, 12 open issues, Apache-2.0.
- `make test` in `c/` passed: C unit tests plus 27 Python stdlib tests.
- `npm ci && npm run build` in `web/` passed; `npm audit` reported 0 vulnerabilities.
- Secret-pattern scan found only documented local API key examples and server auth/CORS code paths.
- Full GLM-5.2 inference and quality benchmarks were not run; they require the ~370 GB converted model and suitable hardware.

---

**Attribution:** JustVugg/colibri, Apache-2.0
