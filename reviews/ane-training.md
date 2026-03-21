# ANE Training (maderix/ANE)

**Rating:** 🔥🔥🔥🔥  
**License:** MIT  
**Source:** https://github.com/maderix/ANE  
**Reviewed:** 2026-03-21

## What It Is

Proof-of-concept for training neural networks directly on Apple's Neural Engine (ANE) via reverse-engineered private APIs (`_ANEClient`, `_ANECompiler`, `_ANEInMemoryModelDescriptor`). Not a framework — explicit research code documenting what's possible on ANE silicon that Apple restricts to inference-only through CoreML.

**Author's own framing:** "Training works, but utilization is low (~5-9% of peak) with significant engineering challenges remaining. This does not replace GPU training for anything beyond small research models today."

## How It Differs From vmlx and PMetal

| Project | API Layer | Compute Target | Status |
|---------|-----------|----------------|--------|
| **vmlx** | MLX (Apple public) | GPU + CPU | Production serving |
| **PMetal** (Epistates) | Private ANE (Rust/objc2) | ANE + CPU | Training framework |
| **ANE** (this) | Private ANE (Obj-C) | ANE + CPU | Research/PoC |

The ANE is a separate chip from the GPU — 15.8 TFLOPS FP16 on M4, Apple only officially exposes for inference via CoreML. Both PMetal and this bypass that using reverse-engineered private APIs.

## Results

**Training throughput (M4):**

| Model | Params | ms/step | Notes |
|-------|--------|---------|-------|
| Stories110M (12L, MHA) | 109M | 91ms | Dynamic, no recompile |
| Qwen3-0.6B (28L, GQA) | 596M | 412ms | Dynamic, no recompile |

Forward + backward dx on ANE; dW gradients on CPU (cblas_sgemm); Adam optimizer on CPU.

**INT8 W8A8 quantization (M4, H16G):**

| Config | FP16 | INT8 W8A8 | Speedup |
|--------|------|-----------|---------|
| 128x conv 512ch 64x64 | 18.6 TOPS, 14.8ms | 35.1 TOPS, 7.8ms | **1.88x** |

Mechanism: `quantize`/`dequantize` ops between layers halve L2 SRAM bandwidth between tiles. Weights use `constexpr_affine_dequantize` (int8 stored, fp16 at compute time).

**GPU prefill → ANE decode (zero-copy IOSurface, M4):**

| Model | GPU Prefill | ANE Decode | Total |
|-------|------------|------------|-------|
| Stories110M | 6.7ms | 1.9ms | 8.8ms |
| Qwen3-0.6B | 9.7ms | 2.3ms | 12.0ms |

## How It Works

1. **MIL generation** — Obj-C constructs MIL (Model Intermediate Language) program text at runtime
2. **In-memory compilation** — `_ANEInMemoryModelDescriptor` compiles MIL + weight blobs directly to ANE programs (no disk mlmodelc)
3. **IOSurface I/O** — tensors via IOSurface shared memory in `[1, channels, 1, spatial]` format (fp16 direct I/O ~37% faster than fp32)
4. **Dynamic weights** — weights + activations packed into single spatial dimension, sliced inside the MIL kernel. Weights change without recompilation.
5. **Gradient flow** — forward taps expose intermediates; backward kernels compute dx on ANE; dW on CPU via cblas
6. **GCD overlap** — dW sgemms run parallel with ANE evals on serial dispatch queue; deferred wait pushed into next step's forward pass

## Key Limitations

- **~5-9% ANE utilization** — significant engineering challenges remain
- **~119 compile limit per process** — ANE compiler leaks resources; workaround: `exec()` restart with checkpoint
- **SDPA causal masking ignored by ANE** — decomposed to Q@K^T (ANE) → mask+softmax (CPU) → scores@V (ANE)
- **FP16 gradient underflow** — fixed via global loss scaling (256 × NLAYERS)
- **Single-input constraint** — multi-input ANE requests fail (0x1d); inputs packed into spatial dimension
- **Element-wise ops fall back to CPU** — not everything runs on ANE

## Kernel Structure (Dynamic Pipeline)

MHA models (6 kernels/layer): `sdpaFwd`, `ffnFused`, `ffnBwdW2t`, `ffnBwdW13t`, `sdpaBwd1`, `sdpaBwd2`  
GQA models (10 kernels/layer): adds `woFwd`, `qBwd`, `kvBwd` for grouped-query attention

## Key Optimizations

- Channel-first CPU layout matching ANE IOSurface `[1,C,1,S]` format — eliminates all transpose overhead
- vDSP vectorized RMSNorm — 10x faster (6.7ms → 0.7ms)
- ANE RMSNorm fusion — folded into forward kernels as MIL ops (reduce_sum + pow + mul)
- Wo^T fusion — output projection backward merged into SDPA backward kernel
- Forward taps — Q, K, V, attention scores, hidden states exposed via concat outputs, avoiding CPU recompute

## Disclaimer

Uses Apple private undocumented APIs. Not affiliated with or endorsed by Apple. Research/educational use only. APIs may break with any macOS update. Author cites DMCA §1201(f) interoperability provisions.

## Closest Prior Work

PMetal (Epistates/pmetal) — same concept, Rust implementation, more complete training framework (SFT/LoRA/DPO/GRPO/PPO/distillation), less explicit benchmark documentation. ANE repo is more honest about limitations and has better INT8 and GPU↔ANE pipeline data.

## Relevance

- Reference architecture for GPU prefill → ANE decode zero-copy pipeline — most practical result here
- INT8 W8A8 on ANE pattern is directly applicable to inference serving if ANE access becomes stable
- Not usable for production today — use vmlx (MLX/GPU) instead
- Educational: deepest public documentation of how ANE private APIs actually work
