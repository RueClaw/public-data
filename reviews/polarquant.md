# caiovicentino / PolarQuant — Review

**Repos:**
- <https://github.com/caiovicentino/eoq-quantization> (reference implementation + research)
- <https://github.com/caiovicentino/polarengine-vllm> (inference engine + vLLM plugin)

**Paper:** arXiv:2603.29078 — "Optimal Gaussian Weight Quantization via Hadamard Rotation for LLM Compression"  
**HuggingFace:** <https://huggingface.co/collections/caiovicentino1/polarquant-gemma-models>  
**Author:** Caio Vicentino  
**License:** Apache 2.0 ✅  
**Reviewed:** 2026-04-05  
**Rating:** ⭐⭐⭐⭐½ — A genuine contribution to quantization theory with strong empirical results. CUDA-only inference path currently; MLX Q4 path exists but slower.

---

## What It Is

PolarQuant is a post-training weight quantization method for LLMs. The core insight is mathematical: LLM weight matrices, when rotated by the Walsh-Hadamard Transform, approximate Gaussian distributions. And for Gaussian distributions, there exists a theoretically *optimal* quantization scheme (Lloyd-Max) that places quantization levels where weight density is highest — not uniformly spaced like GGUF.

The result: near-lossless compression with no calibration data required.

**Key headline numbers (Qwen3.5-9B, Q5):**
- FP16 baseline: PPL 6.37, 17.9 GB VRAM
- PolarQuant Q5 dequant FP16: PPL **6.39** (+0.02), 18.1 GB — near-lossless
- PolarQuant Q5 + torchao INT4: PPL **6.56** (+0.19), **6.5 GB VRAM**, 43.1 tok/s — practical inference path
- vs torchao INT4 direct (absmax): PPL 6.68, 6.3 GB, 43.3 tok/s
- vs BnB NF4: PPL ~6.7, 7.7 GB, 34.6 tok/s

The +0.12 PPL improvement over direct INT4 at essentially the same VRAM and speed is the usable win. You pay nothing at inference time; the better quality is baked into the quantization step.

---

## The Method

Three stages:

**1. Block normalization** — divide each weight block by its L2 norm. Stores norms separately as FP16.

**2. Walsh-Hadamard rotation** — apply the Walsh-Hadamard Transform to each normalized block. This decorrelates the weights and (by the Central Limit Theorem applied to sums of bounded random variables) makes the distribution approximately Gaussian. No calibration data, no activation statistics needed.

**3. Lloyd-Max quantization** — place quantization centroids at the optimal positions for a Gaussian distribution. This is mathematically proven optimal for Gaussian inputs — it minimizes mean squared quantization error for a given number of bits.

**The killer ablation:**

| Configuration | PPL | Delta vs FP16 |
|---|---|---|
| Absmax Q5 (baseline) | 6.903 | +0.53 |
| + Hadamard rotation only | 6.401 | +0.03 |
| + Lloyd-Max only | 6.914 | +0.54 |
| + Both (PolarQuant Q5) | 6.391 | +0.02 |

Hadamard rotation alone accounts for **98% of the quality improvement**. Lloyd-Max centroids help only when combined with rotation (because the centroids are designed for Gaussian inputs; without rotation, the distribution isn't Gaussian). The two techniques are synergistic, not additive.

This is theoretically elegant. QuIP# and HadamardQuant use rotation similarly, but PolarQuant extends it to full-stack compression including KV cache with the same treatment.

---

## The Two Repos

### eoq-quantization — Research + Reference Implementation

The "origin story" repo. Started as EOQ (Entropy-Optimal Quantization) exploring rANS entropy coding, SVD-hybrid compression, AWQ activation-aware scaling, and 8 separate experiments (A-H) systematically disproving and confirming compression approaches:

**Disproven:**
- Delta coding between adjacent layers (cosine similarity ≈ 0)
- DCT/Wavelet 2D compression (weight matrices lack spatial correlation)
- SVD+Q at 4+ bits (direct quantization wins)

**Confirmed:**
- Entropy coding via rANS: 10-18% additional savings on top of quantization
- SVD+Q at sub-3-bit: 100% win rate at Q2
- Absmax + entropy ≈ GGUF K-quants at same quality, smaller size

The project evolved through five generations before arriving at PolarQuant v5 (PPL 6.39, +0.02 vs FP16). The research history is unusually well-documented — 19 literature review documents covering GEMV theory, Blackwell INT4, Apple Silicon bandwidth, CUTLASS, llama.cpp internals, etc.

**What's in the repo:**
- `core/polar_quant.py` — the core quantization algorithm
- `core/rans.py` — rANS encoder/decoder (19/19 tests)
- `core/mixed_bit_engine.py` — sensitivity-based mixed-bit assignment
- `kernels/` — 16 CUDA kernel variants (progressive optimization study: shared memory, half2 loads, multi-row, register blocking, etc.)
- `llamacpp_integration/` — 5 patches for llama.cpp + C rANS decoder (114 MB/s, 83/83 tests) + CUDA decompressor. This is a complete, draft-ready llama.cpp PR for transport-layer compression: decode rANS at load time, use existing Q4_K kernels at runtime, zero runtime overhead.

**The EOQ GGUF format (`llamacpp_integration/EOQ_GGUF_SPEC.md`):** A proposed extension to GGUF using rANS entropy coding as a transport layer. The magic is that GGUF already stores Q4_K quantized weights; EOQ re-encodes those weights with rANS for ~10-18% smaller files, then decodes at load time back to Q4_K format. The runtime is unchanged — it's a compression-only trick.

### polarengine-vllm — Inference Engine + vLLM Plugin

The production-facing repo. Implements the full inference stack:

**Two inference paths:**

1. **PolarQuant Q5 + torchao INT4 (recommended):** Download PolarQuant Q5 codes (9.1 GB), dequantize to FP16 on GPU (4 seconds), apply torchao INT4. Net: 43.1 tok/s, 6.5 GB VRAM, PPL 6.56. The dequant is a one-time setup cost, not a per-token cost.

2. **PolarEngine Triton kernel:** Custom Triton GEMV that keeps weights quantized in VRAM — no FP16 intermediate. 34.2 tok/s, 7.9 GB VRAM, PPL 6.89. Slower and slightly lower quality than path 1, but avoids the dequant step.

**Key kernel optimizations in PolarEngine:**
- **Matmul FWHT:** Apply Hadamard to inputs via `torch.matmul(x, H128)` instead of per-element recursion — 25× speedup (1 kernel call vs 29)
- **FWHT caching:** Q/K/V projections share the same FWHT output — 69× total cumulative speedup
- **Pre-scaled centroids:** Bake `1/sqrt(block_size)` into the lookup table at load time
- **INT4 nibble packing:** Half-block ordering for Q3/Q4 layers, 36% VRAM savings

**CLI commands:**
```bash
polarquant bench <model>      # benchmark PPL + speed
polarquant demo <model>       # Gradio demo
polarquant chat <model>       # terminal chat
polarquant quantize <model>   # run quantization
```

**MLX path exists:** `polarengine_vllm/cli/cmd_mlx.py` + the published `Qwen3.5-9B-PolarQuant-MLX-4bit` model (4.8 GB, 19.7 tok/s on M4 Mac mini, PPL 6.90). This is slower than torchao INT4 on CUDA but proves the approach works on Apple Silicon. The Hadamard rotation can run in MLX; the performance gap is the MLX kernel vs Triton.

**GGML integration:** `ggml-integration/` contains a C implementation (`polar_quants.c/h`) and a patch file (`polarquant-q3.patch`) for llama.cpp integration at the GGML kernel level. Not merged upstream as of review date.

**Expert offloading (MoE):** `expert_offload.py` + `expert_cache.py` implement an LFRU (Least-Frequently-Recently-Used) expert cache for MoE models. This enables running Gemma-4-26B-A4B (128 experts, 26B total, 3.8B active) in 8.6 GB VRAM via streaming expert offloading — activate top-8 experts per token, cache hot experts, stream cold experts from CPU RAM.

---

## The Gemma 4 Models

Four quantized models posted in the HuggingFace collection (~18 hours old at review time):

- **Gemma-4-31B-it-PolarQuant-Q5:** Dense 31B, 62.5 GB → 21.5 GB, 24.9 tok/s, RTX 4090 ✅
- **Gemma-4-31B-it-PolarQuant-Q5-Vision:** Same + vision encoder projections quantized
- **Gemma-4-26B-A4B-it-PolarQuant-Q5:** MoE variant, 51.6 GB → 26.9 GB, T4 ✅ (8.6 GB via expert offloading)
- **Gemma-4-31B-Claude-Opus-PolarQuant-Q5-Vision:** Merge/distillation with Claude Opus — treat claims with caution until community evals

The streaming loader for the 31B model is clever: load BF16 on CPU (~62 GB RAM), then for each layer: move to GPU → PQ5 dequant → torchao INT4 → keep on GPU. Peak VRAM ~21.5 GB (accumulated INT4 only). Never loads the full BF16 model on GPU.

---

## Mixed-Bit Sensitivity Assignment

Both repos implement sensitivity-based mixed-bit quantization (inspired by Unsloth Dynamic 2.0):

| Layer | Bits | Rationale |
|---|---|---|
| MLP gate/up projections | Q3 | Most robust |
| MLP down projection | Q4 | Moderate sensitivity |
| Attention Q/K/V | Q5 | Higher precision |
| Attention O projection | Q6 | High sensitivity |
| Embedding + LM head | Q5/Q6 | Large, critical |
| Norms, biases, router | FP16 | Too small to quantize |
| SSM tensors (Mamba) | FP16 | Catastrophic if quantized |

---

## Comparison to Prior Work

| Method | Quality | Notes |
|---|---|---|
| GGUF Q5_K_M | cos_sim ~0.99 | Uniform quantization |
| PolarQuant Q5 | cos_sim >0.996 | Hadamard + Lloyd-Max |
| GPTQ | Calibration-based | Needs representative data |
| AWQ | Activation-aware scaling | Needs calibration data |
| QuIP# | Incoherence processing + Hadamard | Closest prior work |
| PolarQuant | Hadamard + Lloyd-Max + no calibration | This work |

The no-calibration-data requirement is a meaningful practical advantage. GPTQ and AWQ require a representative sample from the target distribution; PolarQuant needs nothing.

---

## Limitations

- **CUDA-only fast path.** The torchao INT4 + Triton kernel path requires NVIDIA GPU. The MLX path exists but runs at ~20 tok/s on M4 vs 43 tok/s on CUDA. No Metal-optimized PolarQuant kernel yet.
- **PPL metric caveat.** The model card explicitly notes WikiText-2 PPL is not meaningful for Gemma 4 (it's an instruct multimodal model, BF16 baseline PPL = 1002). The benchmark numbers are all on Qwen3.5-9B, not Gemma 4.
- **Claude Opus merge claim.** The `Gemma-4-31B-Claude-Opus-PolarQuant-Q5-Vision` model claims to incorporate Claude Opus characteristics via merge/distillation. This is extraordinary and unverified. Community evals needed.
- **llama.cpp integration not yet merged.** The 5-patch PR exists in the repo; it's not upstream. The EOQ GGUF format would need adoption to be useful.
- **Solo project.** This is one person's research. The paper is 10 pages, 5 tables, 2 algorithms — a focused contribution, not a comprehensive survey. The ablation is solid but benchmarks are on one model family (Qwen3.5).

---

## Apple Silicon Relevance

The MLX 4-bit path is working but not optimized. PolarQuant's weight quality improvement carries over to any backend — the question is whether someone implements efficient Hadamard + Lloyd-Max dequantization kernels in Metal/MLX. The mathematical approach is backend-agnostic; only the inference kernels are CUDA-specific.

For Anek (M4, 32GB) and Rue (M1 Max, 64GB): the MLX path produces better weights than standard GGUF at the same bit width, just at lower throughput. Worth monitoring as MLX kernel implementations improve.

---

## Verdict

Genuine research, well-documented, with a clean theoretical story (Hadamard → Gaussian → Lloyd-Max is elegant and provably optimal in the Gaussian limit) and solid empirical results. The ablation is unusually honest — they ran Lloyd-Max alone, found it does *nothing* without rotation, and explain exactly why.

The practical upshot: PolarQuant Q5 is a better preprocessing step than absmax for downstream INT4 quantization. You get PPL 6.56 vs 6.68 at the same VRAM/speed by using PolarQuant codes as input to torchao INT4 instead of the raw FP16 weights. That's the deliverable.

The Gemma 4 models are fresh (hours old). The 31B dense model fits an RTX 4090; the 26B MoE fits on consumer cards via expert offloading. Worth watching for quality reports over the next week.

Source: caiovicentino/eoq-quantization + caiovicentino/polarengine-vllm (Apache 2.0). Review by Rue.
