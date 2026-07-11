# Disk-Tiered MoE Inference

**Source:** JustVugg/colibri  
**Repo:** https://github.com/JustVugg/colibri  
**License:** Apache-2.0  
**Reviewed:** 2026-07-11  

## Pattern

Run an oversized Mixture-of-Experts model by mapping model structure onto the hardware memory hierarchy:

- keep dense/shared components resident in RAM;
- keep cold routed experts on local NVMe;
- stream only the experts selected for the current token;
- cache or pin hot experts in RAM/VRAM;
- use a resource planner to choose safe cache sizes before loading.

## Why It Works

MoE models have many total parameters but activate only a subset per token. That makes routed experts more like a sparse working set than a monolithic tensor that must all be resident.

The tradeoff is brutal but useful: cold tokens become disk-bound, while warm or repetitive routes can hit RAM/VRAM caches.

## Shape

```text
resident RAM:
  embeddings
  attention and shared/dense layers
  compressed KV cache
  hot expert cache

local NVMe:
  cold routed experts
  model backing store

optional VRAM:
  pinned hottest experts
  resident experimental tensors
```

## Mechanics

1. Convert the source checkpoint into a disk-friendly quantized container.
2. Keep dense weights resident.
3. For each layer, route to top experts.
4. Load missing experts from disk into a per-layer LRU or pinned slot.
5. Track expert usage over time.
6. Promote frequently used experts into RAM or VRAM when space allows.
7. Persist compact KV state so restarts do not require full re-prefill.

## Resource Planning

Before runtime load, read only model metadata and safetensors headers. Estimate:

- total model bytes;
- dense resident bytes;
- expert bytes and expert count;
- runtime/KV reserve;
- safe RAM cache slots per layer;
- optional VRAM hot-tier capacity;
- disk free space and warning conditions.

The planner should output both human-readable text and machine-readable JSON so CLI, API server, and UI all apply the same placement decision.

## Caveats

- This does not make a giant model fast. Cold decode can be dominated by many GB of random reads per token.
- Quality still depends on quantization. Feasibility is not accuracy.
- Network storage is the wrong backing store; use local NVMe.
- Avoid swap. Swapping turns read-heavy inference into write-heavy system pain.
- Thermal behavior matters for sustained NVMe reads.
- A general serving system still needs scheduling, isolation, metrics, and backpressure.

## When To Use

Use this pattern for:

- experimental local inference with very large MoE models;
- hardware benchmarking across NVMe/RAM/CPU/GPU combinations;
- privacy-preserving local model experiments where speed is secondary;
- research into expert hotness, route locality, and cache/pinning policies.

Do not use it when low latency or high concurrency is the main requirement.

---

**Attribution:** Derived from Colibri's GLM-5.2 disk-streamed expert architecture, JustVugg/colibri, Apache-2.0.
