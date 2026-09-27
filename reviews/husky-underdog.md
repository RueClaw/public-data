# Husky: Model-Specific Inference on Apple Silicon (Underdog)

**Source:** https://husky.underdog.ai/  
**Author:** Sigil Wen, Underdog  
**Date:** 20 September 2026  
**Reviewed:** 2026-09-27  
**License:** Article is proprietary vendor content. The Husky engine is **closed source** and ships only inside the Underdog Mac app; no public repo was found. The model it runs (Woof, `ConwayResearch/Underdog-Woof-4B-1.1` on Hugging Face) is Apache-2.0.  
**Topic:** Single-model inference engines, Metal kernel specialization, speculative decoding (prompt lookup + trained draft), prefix caching on Apple silicon

---

## Verdict

📚 **Good reference, but read the benchmark as a vendor comparison against a weak baseline.** The write-up clearly explains why decode on a Mac is memory-bandwidth-bound and what a single-model engine can do about it: kernels compiled for exact shapes, weights stored in kernel tile order, norm folded into projections, pipelined command submission, a resident grid for the linear-attention recurrence, and an 8-row verify step at ~1.5× the cost of one row. The honest parts are genuinely useful. It shows that prose decode is within ~5% of MLX without speculation, and it reports a megakernel experiment that came out "identical output, and no faster."

The headline "4.5× faster than MLX" is mostly **prompt-lookup speculative decoding on edit tasks** where the answer repeats the prompt. It's measured against plain `mlx-lm` decode with no speculation, even though the model ships with a native MTP head. Prompt lookup and draft models are available in general engines too (llama.cpp lookup decoding, vLLM n-gram, mlx-lm draft models), so the real gap to a well-configured general engine is unmeasured. The engine can't be inspected or run outside the app, so nothing here is reproducible. Study the techniques. Don't cite the multipliers.

---

## Summary

Underdog is an on-device assistant app (mail, calendar, notes) that runs its own small model, Woof, locally on Macs and iPhones. Husky is its new inference engine. It supports exactly one model, and every kernel is written for that model's matrix shapes. On an M5 Max (40-core GPU, 128 GB, macOS 26.5.1) with the same 4-bit weights and greedy decoding, the vendor reports:

| Metric | MLX (mlx-lm 0.31.3) | Husky | Husky + Flash draft |
|--------|---------------------|-------|---------------------|
| Decode, function edit | 163 tok/s | 614 | 730 (4.48×) |
| Decode, prose tasks (email, summary, notes) | 151–163 | 164–193 (1.02–1.27×) | 210–273 (1.3–1.8×) |
| Decode, code from scratch | 155 | 170 | 545 (3.5×) |
| First token, continued chat | 137–177 ms (with prompt cache) | 29–39 ms | — |
| Cold prefill, ~860-token prompt (at caller) | 3,094 tok/s | 5,151 tok/s | — |

These are medians of three runs on 16 prompt types taken from the app's workload, with order alternated and repeats agreeing within 12%.

## Key Claims

1. **Decode is bandwidth-bound.** Every token streams the full ~2.4 GB of weights. That takes ~4.5 ms at best on this machine, and both engines sit near ~6 ms/token. The only way past the limit is more tokens per weight read.
2. **8-token verify for ~1.5× the cost of one.** Splitting the long (12,800-wide in their figure) input across eight simdgroups brought the 8-row step from 2.3× to 1.5× of a single row.
3. **Prompt lookup does the edits.** When recent output matches the prompt, the engine proposes the next seven prompt tokens, and five or six are typically accepted.
4. **Flash draft for everything else.** A single-layer draft reads hidden states from five Woof layers and proposes 7 tokens. It was self-distilled on Woof's replies to 139k conversations in ~2 h on one B200, weighs 273 MB, and lands ~2 tokens/step on prose and ~5 on code.
5. **Host off the critical path.** The next step is encoded and submitted while the current one runs, which accounts for the last ~5% on prose.
6. **Prefix cache.** A continued chat answers in ~35 ms vs ~140 ms for mlx-lm's prompt cache, which the article attributes to fixed per-call overhead on that path.
7. **Next:** a whole-step persistent megakernel, a better draft, and a CUDA version "for upcoming launches with NVIDIA and Microsoft".

## Strengths

- **Clear explanation of the bandwidth limit.** The article says plainly that Husky ties MLX on plain prose and explains why, instead of implying a general 4.5×.
- **Negative results included.** The MLP-as-one-persistent-dispatch experiment is reported as no faster, with a sound reason: back-to-back dispatches in one encoder already have almost no gap on this GPU.
- **Methodology is better than most vendor posts.** Hardware, OS, library versions, load conditions, repeat tolerance, and a canary run are all stated, and greedy output is checked token by token against MLX after every change.
- **Practical recipe for small-model speedups.** Kernel-order weight packing, fused norm+projection, gate/up walked together, 8-bit KV in attention-kernel layout, and adaptive switching between lookup and draft. These carry over to anyone writing Metal kernels for a fixed model.
- **Cheap draft training.** Two B200-hours for a draft that roughly doubles prose throughput is a useful data point.

## Gaps & Limitations

- **Baseline choice inflates the headline.** MLX runs plain autoregressive decode. Husky's edit numbers come from prompt-lookup speculation, a general technique any engine can enable. A fair comparison would include mlx-lm with a draft model, llama.cpp's lookup/n-gram decoding, or the model's own MTP head (the published config has `mtp_num_hidden_layers: 1`). None of these are benchmarked.
- **Closed engine, nothing reproducible.** The engine is only in the Underdog app. "The receipts are kept" isn't the same as publishing them.
- **Model shapes don't match the published weights.** The published `Underdog-Woof-4B-1.1` config is a Qwen3.5-style hybrid: 32 layers, one full-attention layer every 4 (so 24 linear-attention layers, which matches the article), hidden size 2560, and 2.39 GB on disk (matches). But it has **`intermediate_size` 9216** and **4 KV heads × 256 dims** (1024), while the article's figure shows gate/up at 2560 × 12800 and k/v at 2560 × 512. Either the benchmarked Woof isn't the published 1.1 checkpoint, or the figure is illustrative. The article says it is "Underdog's published 4B model".
- **Single machine, top-end chip.** Everything was measured on an M5 Max with 128 GB. Base M-series chips with lower bandwidth and fewer GPU cores will shift the balance, and there's no iPhone data despite the iPhone claim.
- **Workload is the vendor's own.** The 16 prompt types are drawn from the app's traffic, which is edit-heavy by design. That's appropriate for the product, but it flatters lookup decoding.
- **First-token comparison mixes engines' cache overheads.** The 35 ms vs 140 ms continued-chat number largely measures mlx-lm's per-call path, not prefill compute.
- **"Pareto-frontier model"** is asserted with no quality evaluation in the article.

## Comparison

| Aspect | Husky (Underdog) | mlx-lm | llama.cpp (Metal) | Model-specific open engines (e.g. single-family Apple-silicon servers) |
|--------|------------------|--------|-------------------|-------------------------|
| Model scope | One model (Woof 4B) | Broad | Very broad | 1–2 families |
| Source | Closed, in-app only | Open | Open | Open |
| Speculation | Prompt lookup + trained 1-layer draft, adaptive | Draft models | Draft, lookup/n-gram, MTP | Trained drafts per model |
| Kernel specialization | Per-matrix, fused norms, kernel-order weights | General | General with per-arch paths | Per-model |
| Use it if | You use the Underdog app | You want MLX flexibility | Portability | You run a supported model and want speed |

## Takeaways

- For fixed-model on-device products, **specializing kernels plus speculation is where the wins are**. Speculation (lookup for edit workloads, a small self-distilled draft for prose) is the bigger lever, and kernel work mostly makes the 8-row verify step cheap.
- **Benchmark against a speculative baseline**, not plain decode, before claiming multiples.
- If you run edit-heavy agents locally, **turn on prompt-lookup / n-gram speculation in your existing engine first**. It's the cheapest way to capture most of the edit-task gains described here.

---

**Attribution:** Sigil Wen, "Husky: a model-specific inference engine up to 4.5× faster than Apple's MLX," Underdog, 20 September 2026, https://husky.underdog.ai
