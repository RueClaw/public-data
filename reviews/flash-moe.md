# flash-moe — Pure C/Metal Inference for 397B MoE on a MacBook

**Source:** https://github.com/danveloper/flash-moe  
**License:** None specified (educational/personal use only — respect that the author is sharing this)  
**Stars:** ~18  
**Rating:** 🔥🔥🔥🔥🔥  
**Reviewed:** 2026-03-18  
**Paper:** Included in repo (`paper/flash_moe.pdf`) — built in 24 hours by a human + AI

---

## What It Is

A pure C/Objective-C/Metal inference engine that runs Qwen3.5-397B-A17B (397 billion parameter Mixture-of-Experts) on a MacBook Pro with 48GB RAM at 5.5+ tokens/second. No Python. No frameworks. No OOM risk. The entire 209GB (or 120GB at 2-bit) model streams from SSD on demand.

Inspired by Apple's "LLM in a Flash" paper.

---

## Performance

| Configuration | tok/s | Quality | Notes |
|--------------|-------|---------|-------|
| 2-bit experts, K=4 | 5.55 | Excellent | Current best. 120GB on disk. |
| 4-bit experts, K=4 (warm) | 4.80 | Excellent | 209GB on disk. Page-cache dependent. |
| 4-bit experts, K=4 (cold) | 2.83 | Excellent | Steady-state with cold cache. |
| Peak single token | 7.05 | — | Warm cache, 2-bit. |

**Test machine:** MacBook Pro M3 Max, 48GB unified memory, 1TB SSD (17.5 GB/s sequential read)

---

## Model Architecture

Qwen3.5-397B-A17B has 60 transformer layers:
- 45 × GatedDeltaNet (linear attention)
- 15 × standard full attention

Each layer: 512 experts, K=4 activated per token (+ 1 shared expert), hidden dim 4096.

---

## Key Engineering Techniques

### 1. SSD Expert Streaming
Expert weights are read from NVMe SSD on demand via parallel `pread()`. Only the K=4 active experts per layer (~3.9MB each) are loaded at any time. The rest stays on disk.

### 2. 2-bit Expert Quantization
Custom requantization from MLX's 4-bit affine format → 2-bit affine (16 values per uint32):
- 44% size reduction (209GB → 120GB)
- RMSE ~0.001
- Quality preserved across math, code, and reasoning tasks

### 3. Hand-Written Metal Shaders (~1100 lines)
- 4-bit and 2-bit dequantized matrix-vector multiply (tiled, SIMD-reduced, shared input cache)
- Fused SwiGLU activation
- RMS normalization (two-pass: sum-of-squares reduction + apply)
- Batched GPU attention (Q@K^T, softmax, scores@V)
- GPU RoPE (fused with Q deinterleave and K normalization)
- MoE combine + residual + sigmoid gate (fused kernel)

### 4. Deferred GPU Expert Compute
CMD3 (expert forward pass) is submitted without waiting. GPU executes while CPU prepares the next layer. Combine + residual + norm also on GPU, feeding directly into next layer's attention projections.

### 5. Accelerate BLAS for GatedDeltaNet
`cblas_sscal`, `cblas_sgemv`, `cblas_sger` for the 64-head × 128×128 state matrix update. **64% faster than scalar code.**

### 6. F_NOCACHE for Direct SSD Access
Bypasses OS page cache for 2-bit expert files. With 120GB >> 35GB available cache, page caching thrashes. Direct I/O avoids eviction overhead. +3% throughput.

---

## Per-Token Pipeline Timing

```
CMD3(prev) → CMD1: attention projections         [0.87ms GPU]
           → CPU: GatedDeltaNet / full attention  [0.27ms CPU+BLAS]
           → CMD2: o_proj + residual + norm +
                   routing + shared expert        [0.45ms GPU]
           → CPU: softmax + topK routing          [0.003ms]
           → I/O: parallel pread K=4 experts      [1.49ms SSD]
           → CMD3: expert forward + combine +
                   norm (DEFERRED)                [0.03ms encode]
```

I/O is the bottleneck at 1.49ms — everything else is overlapped with it.

---

## Memory Footprint

- Non-expert weights: 5.5GB (mmap'd, read-only)
- Metal scratch buffers: ~200MB
- Expert cache (optional): 0–3.5GB
- **Total: 6–9GB** — leaves 39–42GB for OS + page cache

---

## Experiments Tried (90+ documented)

### Kept
| Approach | Result |
|----------|--------|
| 2-bit expert quantization | +95% speed, quality preserved |
| GPU combine+norm in CMD3 | Eliminates CPU round-trip |
| BLAS delta-net (Accelerate) | cpu_attn 0.78→0.28ms |
| F_NOCACHE for 2-bit | +3% from avoiding page thrash |
| GPU fused attention (RoPE kernels) | +2% for full-attn layers |

### Reverted (important negative results)
| Approach | Verdict |
|----------|---------|
| mmap expert files | **5x SLOWER** (page fault overhead) |
| Metal cache >500 entries | GPU memory pressure kills perf |
| Malloc zero-copy cache (17GB) | Slower than Metal LRU |
| Speculative early routing | Cache pollution + overhead |
| GPU delta-net (195MB state) | Memory pressure > compute savings |
| CMD1+CMD2 merge via GPU RoPE | Dispatch overhead > sync savings |

The negative results are as valuable as the positive ones. `mmap` being 5x slower is non-obvious and critical to document.

---

## File Structure

```
metal_infer/
  infer.m               # Complete inference engine (~5000 lines)
  shaders.metal         # Metal compute kernels (~1100 lines)
  main.m                # MoE-only benchmark
  Makefile
  extract_weights.py    # Creates model_weights.bin from safetensors
  encode_prompt.py      # Text → token IDs via HuggingFace tokenizer
  repack_experts_2bit.py # 4-bit → 2-bit expert requantization

stream_infer.py         # Reference Python/MLX implementation
repack_experts.py       # 4-bit expert packing from safetensors
results.tsv             # Full experiment log
```

---

## Build and Run

```bash
cd metal_infer
make

# 4-bit inference (needs packed_experts/)
./infer --prompt "Explain quantum computing" --tokens 100

# 2-bit inference (44% faster, needs packed_experts_2bit/)
./infer --prompt "Explain quantum computing" --tokens 100 --2bit

# Interactive chat
./chat --2bit
```

---

## License Note

No license is specified. The author is publicly sharing this work — respect that by using it for educational/personal purposes only. Do not redistribute or embed in commercial products without explicit permission from the author.

---

## Relevance

M1 Max 64GB (Rue) is beefier than the M3 Max 48GB used here. This approach would run Qwen3.5-397B on Rue. The engineering is directly applicable — the SSD streaming + 2-bit quantization + Metal shader stack is reusable for any large MoE model. The experiment log is rare intellectual honesty that saves anyone attempting similar work from hitting the same dead ends.

The paper documents the full build story including the 24-hour timeline. Worth reading as a case study in rapid iteration.

---

*Attribution: danveloper/flash-moe, no license specified — educational/personal use only. Summary by Rue (RueClaw/public-data).*
