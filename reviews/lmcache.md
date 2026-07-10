# LMCache (LMCache/LMCache)

**Repo:** https://github.com/LMCache/LMCache  
**License:** Apache-2.0. Permissive reuse with attribution and license preservation.  
**Reviewed:** 2026-07-10  
**Stack:** Python, C++/CUDA/SYCL/Rust extensions, PyTorch, vLLM, SGLang, TensorRT-LLM, FastAPI, ZeroMQ, Prometheus/OpenTelemetry, Kubernetes operator  
**What it is:** A KV-cache management layer for LLM inference that offloads, persists, transfers, observes, and reuses attention KV blocks across requests, sessions, and serving engines.

---

## Verdict

✅ **Deploy candidate for serious LLM serving stacks.** LMCache is not a toy cache wrapper: it has engine integrations, CUDA/SYCL/native storage code, multiprocess serving, controller APIs, production deployment docs, a Kubernetes operator, broad tests, CodeQL, and active releases. The caveat is operational: it belongs inside a hardened inference cluster, not exposed as a casual HTTP service.

---

## What It Is

LMCache turns LLM KV cache from short-lived process state into an explicit serving layer. Instead of letting each inference engine instance compute and discard KV blocks, LMCache can move them through GPU, CPU, local disk, remote storage, and peer-to-peer transfer paths so repeated long-context, RAG, and multi-turn workloads avoid redundant prefill work.

The project supports in-process and recommended multiprocess modes. In multiprocess mode, LMCache runs as a standalone service and engines such as vLLM attach through a KV connector. That gives the cache its own lifecycle, management endpoints, observability, and the ability to share cache across engine instances.

This is most useful when prompts have reusable context: long documents, agent conversations, repeated RAG corpora, or prefill/decode-disaggregated serving. For simple low-context chat serving, the operational cost may outweigh the gain.

## Stack

| Layer | Tech |
|-------|------|
| Core runtime | Python package with C++/CUDA/SYCL extensions |
| ML/runtime deps | PyTorch, transformers, safetensors, xformers, cupy/CUDA wheels |
| Serving integrations | vLLM, SGLang, TensorRT-LLM |
| Cache service | Multiprocess server, ZeroMQ, FastAPI HTTP frontend |
| Storage/transport | CPU RAM, local disk, Redis/Valkey, S3-compatible object storage, Mooncake, InfiniStore, NIXL, GDS |
| Observability | Prometheus, OpenTelemetry, request/KV metrics |
| Deployment | Docker, vLLM production stack, Kubernetes operator |
| Quality/security | pytest, Buildkite GPU pipelines, GitHub Actions, CodeQL, pinned GitHub Actions, harden-runner |

## Key Features

### Engine-Independent KV Cache

LMCache can run outside the serving engine process. The README calls this "engine-independent deployment": cache state survives engine crashes and can be shared by multiple instances rather than fate-sharing with a single vLLM process.

### Tiered Offload and Reuse

The architecture spans GPU memory, pinned CPU memory, local disk/NVMe/GDS, and remote backends. The useful design move is separating active GPU KV from reusable cached KV, then choosing whether to retrieve, prefetch, evict, pin, move, compress, or recompute based on cost.

### Multiprocess Server and Controller APIs

The MP mode exposes cache/server lifecycle outside the engine. Controller and HTTP APIs support lookup, clear, move, pin/unpin, compression/decompression, health checks, worker info, quotas, and metrics. That makes the cache observable and operable rather than an invisible performance trick.

### Non-Prefix Reuse and CacheBlend

LMCache goes beyond ordinary prefix caching. CacheBlend supports reuse of cached KV blocks away from the prompt prefix and selectively recomputes tokens to recover quality. That matters for RAG and multi-document workloads where reused context is not always a clean prefix.

### Production Signals

The repo is very active, has a current v0.5.1 release, and reports more than 10k stars. The codebase includes extensive unit tests, GPU/Buildkite pipelines, CodeQL, scorecard workflow, Docker images, docs, and a Kubernetes operator with controller/webhook/e2e tests.

## Architecture

The core shape is:

```text
serving engine
  -> KV connector
  -> LMCache engine/server
       -> token database / cache index
       -> memory objects and allocators
       -> storage manager
            -> local CPU backend
            -> local disk / GDS backend
            -> remote L2 backends
            -> P2P / NIXL / PD transfer paths
       -> observability and controller APIs
```

The central implementation lives under `lmcache/v1/`: cache engine, storage manager, memory allocators, GPU connectors, multiprocess runtime, controller, distributed storage, lookup clients, and observability. Engine adapters live under `lmcache/integration/`, with version-specific vLLM connectors and separate SGLang/TensorRT-LLM paths.

Two architecture choices stand out:

- Configuration is centralized in typed config definitions with YAML/env/CLI overrides and backward-compatible aliases.
- Storage backends are constructed behind a common interface, including dynamic storage plugins when operators explicitly configure module/class paths.

## Comparison

| Aspect | LMCache | vLLM Prefix Caching | Redis/S3 Prompt Cache | NVIDIA Dynamo-style Serving |
|--------|---------|---------------------|-----------------------|-----------------------------|
| Cache unit | KV tensors/chunks | Prefix KV blocks inside engine | Usually text/output/application objects | Distributed inference/runtime layer |
| Engine lifecycle | Can be external to engine | Tied to engine | External but not KV-native | External runtime/control plane |
| Best fit | Long-context, RAG, multi-turn, shared serving | Single-engine repeated prefixes | App-level response reuse | Large distributed serving systems |
| Main caveat | Operational and security hardening | Narrower reuse surface | Recompute still needed on misses | Heavier platform dependency |

LMCache is closer to an inference infrastructure component than an application cache. It is for avoiding prefill and transfer waste, not for deduplicating user-visible completions.

## Self-Hosting Notes

For local trials, `pip install lmcache` is the simple path. The recommended production shape is multiprocess mode: start `lmcache server`, then attach vLLM through `LMCacheMPConnector`.

Operational caveats:

- GPU deployments often require `--network host`, `--ipc host`, CUDA IPC, `/dev/shm`, and node-local placement. Treat that as privileged infrastructure.
- The controller and HTTP APIs can mutate cache state. Keep them private, authenticated through surrounding infrastructure, or network-isolated.
- Runtime plugins execute Python or shell scripts from configured locations. Only use trusted plugin paths.
- Usage telemetry exists and can be disabled with `LMCACHE_TRACK_USAGE=false` or `DO_NOT_TRACK=true`.
- Benchmark on the real workload. For small prompts or low hit ratios, cache transfer can be slower than recomputation.

---

**Attribution:** LMCache/LMCache, Apache-2.0, https://github.com/LMCache/LMCache
