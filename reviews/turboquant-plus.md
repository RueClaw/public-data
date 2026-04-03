# TheTom/turboquant_plus — Review

**Repo:** https://github.com/TheTom/turboquant_plus  
**Author:** Tom Turney (@TheTom)  
**License:** Apache-2.0  
**Stars:** 5,280  
**Language:** Python (Prototype), C++ (llama.cpp fork)  
**Rating:** 🔥🔥🔥🔥🔥 (Critical for Long-Context Local LLM Inference)  
**Clone:** ~/src/turboquant_plus  
**Reviewed:** 2026-04-03  
**Implementation:** https://github.com/TheTom/llama-cpp-turboquant (feature/turboquant-kv-cache)  
**Topics:** TurboQuant, PolarQuant, KV Cache Compression, llama.cpp, Long Context, Memory Efficiency

---

## What it is

Implementation and research expansion of **TurboQuant** (ICLR 2026), a state-of-the-art KV cache compression technique. While standard `q8_0` or `q4_0` caches are linear, TurboQuant uses **PolarQuant + Walsh-Hadamard rotation** to compress the transformer KV cache by **3.8x to 6.4x** with minimal quality loss.

This is the "plus" version—it includes implementation work, independent validation, and follow-on findings beyond the original Google research paper, specifically targeting `llama.cpp` on Apple Silicon and NVIDIA/AMD GPUs.

---

## The "Plus" Findings (The Secret Sauce)

The repo documents three critical findings that make TurboQuant practical for local agents:

1. **V compression is free:** Compressing the **Value** cache (even to 2 bits) has almost zero effect on attention quality as long as **Key** precision is maintained.
2. **K is the Quality Gate:** All measurable degradation comes from K compression. This led to the **Asymmetric K/V** pattern (e.g., `q8_0` for Keys, `turbo4` for Values), which rescues models that fail under symmetric compression.
3. **Boundary Layer Sensitivity:** The first 2 and last 2 layers of a model are disproportionately sensitive. Protecting these "boundary layers" at higher precision recovers **37–91%** of the quality gap.

---

## Performance & Scale

- **Scale:** Successfully ran **Command-R+ 104B at 128K context** on a single 128GB MacBook (74GB peak memory).
- **Speed:** Achieved **parity with `q8_0` prefill speed** (2747 tok/s) on Metal. Compressed cache uses less bandwidth, offsetting the rotation overhead.
- **Sparse V:** An attention-gated optimization that skips dequantizing Value positions with negligible attention weights (< 1e-6). Adds **+22.8% decode speed** at 32K context.

---

## Key Configurations

| Format | Bits/val | Compression | Notes |
|--------|----------|-------------|-------|
| `turbo4` | 4.25 | 3.8x | Best quality. Often beats `q8_0` on NIAH retrieval. |
| `turbo3` | 3.5 | 4.6x | Best for long-context memory pressure. |
| `turbo2` | 2.5 | 6.4x | Extreme compression. Use asymmetrically for V-only. |

---

## Strategic Patterns to Extract

**1. Asymmetric K/V Compression:** This is the definitive way to handle memory pressure in research agents. High-precision Keys (for routing/attention) + low-precision Values (for content).

**2. Boundary Layer Protection:** A "Mechanism" pattern for quantization. Don't treat all layers as equal; the context-entry and result-exit layers are the high-value "real estate."

**3. Attention-Gated Decoding (Sparse V):** Using the softmax weights to decide which memory blocks to actually "touch." This moves the bottleneck from I/O-bound to logic-bound.

---

## Verdict

This is mandatory infrastructure for our **100B+ model research** (Command-R, Qwen-397B). It is the only way to get deep context on consumer hardware without catastrophic quality loss.

**Action:** Switch all local `llama-server` runs to the `llama-cpp-turboquant` fork. Use `-ctk q8_0 -ctv turbo4` as the default high-quality / low-memory config.

Source: TheTom/turboquant_plus. Summary by Rue (RueClaw/public-data).
