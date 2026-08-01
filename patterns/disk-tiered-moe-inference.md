# Disk-Tiered MoE Inference

**Source:** JustVugg/colibri  
**Repo:** https://github.com/JustVugg/colibri  
**License:** Apache-2.0  
**Reviewed:** 2026-08-01

## Pattern

Run oversized Mixture-of-Experts models by mapping model structure onto a heterogeneous memory hierarchy: storage, RAM, and VRAM all become placement tiers for weights.

The design rule is that placement changes speed, not semantics. Dense/shared components and active state stay resident; routed experts move between cold storage, warm RAM, and hot accelerator memory according to measured use.

## Why It Works

MoE models have many total parameters but activate only a subset per token. Routed experts are a sparse working set, not a monolithic tensor that must all be resident. That makes them tierable.

Cold tokens can still be painfully disk-bound, but repeated workloads, routing locality, batching, speculative decode, and accelerator residency can turn the hot subset into a much faster path.

## Shape

```text
resident RAM:
  embeddings
  attention and shared/dense layers
  compressed KV cache
  warm expert cache
  route history / placement metadata

local NVMe:
  cold routed experts
  model backing store
  optional mirrored or split shard copies

optional VRAM:
  pinned hottest experts
  dense projections / attention kernels
  backend-specific resident tensors
```

## Mechanics

1. Convert or select a model container whose expert layout is explicit.
2. Validate tensor shapes, quant layouts, and byte counts before trusting model files.
3. Keep dense/shared weights resident.
4. Route each layer to the selected experts.
5. Load missing experts from storage into bounded RAM or VRAM slots.
6. Track expert usage per engine/model family.
7. Promote hot experts into RAM or VRAM when space allows.
8. Use prefetch or router lookahead when it wins on the target hardware.
9. Persist compact KV state so restarts do not require full re-prefill.
10. Expose planner output as both human-readable text and machine-readable JSON.

## Placement Extensions

Use multi-drive layouts when storage bandwidth or capacity is the bottleneck:

- full mirrors can split read traffic across drives;
- partial mirrors can stage the hottest shards into a smaller second drive;
- N-drive shard directories can aggregate capacity when no single drive holds the container.

Use accelerator tiers only when they beat the CPU on the real workload. GPU residency helps most when expert hit rate is high enough and transfer/synchronization overhead does not erase the win. CPU SIMD plus warm RAM can outperform a lightly used GPU tier.

## Resource Planning

Before runtime load, read only model metadata and safetensors/container headers. Estimate:

- total model bytes;
- dense resident bytes;
- expert bytes and expert count;
- runtime/KV reserve;
- safe RAM cache slots per layer;
- optional VRAM hot-tier capacity;
- storage bandwidth and direct-I/O behavior;
- warnings for swap, missing shards, unsupported layouts, and unsafe exposure.

The planner should explain the bottleneck class and emit environment settings that preserve model semantics unless the operator explicitly opts into experimental-fast policies.

## Caveats

- This does not make a giant model automatically fast. Cold decode can still require many GB of reads per token.
- Quality depends on quantization and container correctness. Feasibility is not accuracy.
- Network storage is usually the wrong backing store; use local NVMe.
- Avoid swap. Swapping turns read-heavy inference into write-heavy system pain.
- Thermal behavior matters for sustained reads.
- GPU comparisons are easy to confound: clocks, ReBAR, speculation settings, cache warmth, and CPU SIMD all matter.
- A general serving system still needs scheduling, isolation, metrics, auth, and backpressure.

## When To Use

Use this pattern for:

- experimental local inference with very large MoE models;
- hardware benchmarking across NVMe/RAM/CPU/GPU combinations;
- privacy-preserving local model experiments where speed is secondary;
- research into expert hotness, route locality, cache/pinning policies, and model-container formats.

Do not use it when low latency, high concurrency, or broad model support is the main requirement.

---

**Attribution:** Derived from Colibri's disk-streamed MoE architecture, JustVugg/colibri, Apache-2.0.
