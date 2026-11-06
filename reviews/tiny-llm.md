# tiny-llm (skyzh/tiny-llm)

**Repo:** https://github.com/skyzh/tiny-llm
**Author:** Alex Chi Z (skyzh) and contributors
**License:** Apache-2.0 code; book explicitly CC BY-NC-SA 4.0; model licenses separate.
**Reviewed:** 2026-11-06 (UTC)
**Revision:** `17a8cc660b1547bd42dfe53b01e9c76410f4cf8c`, main; repository-wide overview with focused inference, native kernels, agent workspace, tests, benchmarks and CI inspection.
**Verification:** Static source review; no installation, source execution, model downloads, inference, training or GPU benchmarks. Independently checked all 10 entries in the historical benchmark SHA-256 ledger: all matched. That establishes artifact consistency, not benchmark truth.
**Stack:** Python 3.10–3.12, MLX/MLX-LM, C++/Metal, nanobind, PDM, pytest, mdBook.
**What it is:** A four-week hands-on LLM inference and coding-agent course for systems engineers on Apple silicon—not a tiny pretrained model or a production inference service.

## Verdict

📚 **Study: unusually concrete systems education, not a deployment recommendation.** The progression from equations through packed-weight kernels, paged KV and bounded agent effects is valuable precisely because it exposes ownership and measurement boundaries. Use the reference solution as a learning oracle, implement the student exercises deliberately, and rerun matched measurements on the exact current source before believing performance numbers. The published historical evidence is candid about its limitations; it does not certify this revision.

## What It Is

The [README](https://github.com/skyzh/tiny-llm/blob/17a8cc660b1547bd42dfe53b01e9c76410f4cf8c/README.md) starts with Qwen3 attention, RoPE, grouped-query attention, RMSNorm, MLP and sampling, then moves through KV caches and Metal optimization to continuous batching, paging and a coding-agent loop. “Build a Mini vLLM” describes a teaching sequence, not vLLM API compatibility or production operational parity. Fine-tuning is explicitly outside scope; no training pipeline or pretrained weights are supplied by this repository.

The learner package, [tiny_llm](https://github.com/skyzh/tiny-llm/blob/17a8cc660b1547bd42dfe53b01e9c76410f4cf8c/src/tiny_llm/attention.py), deliberately contains empty bodies and TODOs. The separately maintained tiny_llm_ref and extensions_ref trees contain substantive reference implementations. The default main.py solution is the student package; selecting ref is necessary to exercise the completed reference rather than unfinished homework. Building a reference extension does not fill learner stubs.

The roadmap distinguishes code, tests, documentation and the author's editorial audit. Week 1 is fully checked there; Week 2's current five-day route is still marked work-in-progress for code/tests/audit, while Week 3 and Week 4 Days 1–9 have code/tests/docs but pending editorial audit. Several agent files explicitly warn that they are LLM-generated and under review. Read these as publication/maturity signals, not proof that all paths are broken or all checked paths are correct.

## Stack

| Layer | Implementation and consequence |
|---|---|
| Arrays and loading | MLX >=0.32.4 and MLX-LM >=0.31.3; MLX is both substrate and numerical/performance oracle |
| Native operators | C++/Metal extensions through nanobind 3.1.0; full Xcode/Metal toolchain and CMake >=3.27 |
| Environment | PDM with pdm.lock; Python >=3.10,<3.13 |
| Test/development dependencies | pytest, pytest-benchmark, Ruff, NumPy, Torch, torchtune, torchao; much larger install surface than the small teaching model code suggests |
| Documentation | mdBook, TOC/KaTeX preprocessors and sitemap generation |
| Service/auth/database | No production HTTP service, tenant authorization layer or database in the reviewed entry points |

[Manifest](https://github.com/skyzh/tiny-llm/blob/17a8cc660b1547bd42dfe53b01e9c76410f4cf8c/pyproject.toml), [setup](https://github.com/skyzh/tiny-llm/blob/17a8cc660b1547bd42dfe53b01e9c76410f4cf8c/book/src/setup.md). Most direct dependencies use lower bounds; the lockfile matters. PDM's pre_run hook synchronizes dependencies, so even an apparently simple pdm run can install packages/contact registries. We did not invoke it or audit dependency advisories.

## Key Features

### 1. Equations stay connected to memory traffic

[Week 1](https://github.com/skyzh/tiny-llm/blob/17a8cc660b1547bd42dfe53b01e9c76410f4cf8c/src/tiny_llm_ref/qwen3_week1.py) imports MLX-loaded weights, dequantizes linear weights to BF16, implements attention/GQA and residual blocks, and computes logits. Its teaching clarity costs memory: a 4-bit checkpoint on disk does not mean a 4-bit runtime at this stage, and the original MLX model remains referenced. Start with the documented 0.6B model rather than treating a larger download's file size as the RAM requirement.

[Week 2](https://github.com/skyzh/tiny-llm/blob/17a8cc660b1547bd42dfe53b01e9c76410f4cf8c/src/tiny_llm_ref/qwen3_week2.py) introduces selectable cumulative checkpoints: dense cache, bounded capacity, packed quantized matvec, SIMD matmul, RMSNorm, RoPE, SwiGLU, tiled prefill and selected. [Quantized dispatch](https://github.com/skyzh/tiny-llm/blob/17a8cc660b1547bd42dfe53b01e9c76410f4cf8c/src/tiny_llm_ref/quantize.py) chooses short-row matvec versus matrix-shaped work; it also exposes an explicit MLX projection path. These are shape- and dtype-sensitive teaching kernels, not a universal quantization backend.

### 2. Paging has actual ownership and validation

The [Week 3 model](https://github.com/skyzh/tiny-llm/blob/17a8cc660b1547bd42dfe53b01e9c76410f4cf8c/src/tiny_llm_ref/qwen3_week3.py) owns a page pool per layer; request caches own logical page lists. [Batching](https://github.com/skyzh/tiny-llm/blob/17a8cc660b1547bd42dfe53b01e9c76410f4cf8c/src/tiny_llm_ref/batch.py) advances one pending prefill in chunks, admits it into decode slots, performs batched decode, and releases completed request caches. The dense compatibility route reconstructs padded K/V, whereas the direct paged path passes block tables and context lengths to Metal without gathering whole histories.

The [Python attention boundary](https://github.com/skyzh/tiny-llm/blob/17a8cc660b1547bd42dfe53b01e9c76410f4cf8c/src/tiny_llm_ref/attention.py) checks shapes, dtypes, live page ranges, unused -1 sentinels and duplicate live page aliases before native dispatch. This explicitly rejects shared physical pages across live entries: do not confuse it with cross-request prefix caching. Batched append validation and state snapshots in [kv_cache.py](https://github.com/skyzh/tiny-llm/blob/17a8cc660b1547bd42dfe53b01e9c76410f4cf8c/src/tiny_llm_ref/kv_cache.py) provide rollback on append errors. [Native page writes](https://github.com/skyzh/tiny-llm/blob/17a8cc660b1547bd42dfe53b01e9c76410f4cf8c/src/extensions_ref/src/paged_attention.cpp) intentionally alias storage and update only the appended slice; this is mutable request state, not a general immutable array abstraction.

Importantly, dense Week 3 defaults to **MLX quantized projections**, keeping course-owned cache, attention, normalization, activation and scheduling. Its performance is hybrid, not evidence that every course-written kernel beats MLX. Optional MoE retains a separate projection contract.

### 3. Agent effects are explicit—but not sandboxed

The Week 4 reference adds strict JSON action parsing, bounded loop budgets, workspace inspection, operator-approved mutations, exact command allowlists, effect receipts, checkpoint/resume, compaction, steering, evaluation, isolated branch continuations and range-retrievable evidence. The [workspace implementation](https://github.com/skyzh/tiny-llm/blob/17a8cc660b1547bd42dfe53b01e9c76410f4cf8c/src/tiny_llm_ref/agent/workspace.py) blocks traversal/symlinks and selected sensitive names, requires read-before-edit plus an unchanged content hash, uses same-directory atomic replacement, and declines effects without an approval callback. Reused tool-call IDs return the recorded effect rather than blindly repeating it.

These are useful educational controls, not a security enclosure. Approved subprocesses inherit the environment, have normal host filesystem/network authority, and can run arbitrary behavior embedded in an allowed script. They run without a shell, but exact argv does not make their code safe. Output is captured before being truncated to 16,000 characters, so the displayed bound is not a process-memory bound. Filename exclusions are not a secret detector; path checks do not defeat hostile concurrent filesystem changes. Receipts are written after effects, not a crash-atomic transaction with them. The source explicitly disclaims sandbox, process-jail and hostile-filesystem protection.

## Architecture and Correctness Limits

- **Loading:** [main.py](https://github.com/skyzh/tiny-llm/blob/17a8cc660b1547bd42dfe53b01e9c76410f4cf8c/main.py) calls mlx_lm.load, formats a tokenizer chat template and dispatches a course wrapper by week. [Model dispatch](https://github.com/skyzh/tiny-llm/blob/17a8cc660b1547bd42dfe53b01e9c76410f4cf8c/src/tiny_llm_ref/models.py) uses the Qwen/Qwen3 name prefix, not a comprehensive architecture compatibility registry. A matching name alone is not a supported-model guarantee.
- **Model scope:** [shortcuts](https://github.com/skyzh/tiny-llm/blob/17a8cc660b1547bd42dfe53b01e9c76410f4cf8c/model_names.py) include dense 0.6B, 1.7B, 4B and 8B plus 30B-A3B MoE. Dense Week 1 expects a dense MLP; the optional MoE implementation belongs to later paths. Larger models require appropriately larger memory and separate validation. No arbitrary Llama/Gemma/multimodal support should be inferred.
- **Hardware:** The course requires Apple silicon. Week 1 and early readable cache paths expose CPU streams, but later packed-weight/Week 3 native kernels are GPU-only and the CLI rejects incompatible CPU selections. This is not a CUDA, Linux or Intel-Mac portability claim. Even early test collection requires both native extensions, per setup documentation.
- **Sampling discrepancy:** main.py accepts temperature/top-p/top-k and builds a sampler, but the normal Week 2/3 call does not pass it to simple_generate_with_kv_cache. That function explicitly uses argmax. These flags therefore do not provide stochastic sampling on that path at this revision. This is a static control-flow finding, not a reproduced runtime failure. See [generation](https://github.com/skyzh/tiny-llm/blob/17a8cc660b1547bd42dfe53b01e9c76410f4cf8c/src/tiny_llm_ref/generate.py).
- **Speculation:** Optional speculative generation is greedy-only; the CLI rejects stochastic options and the reference checks prompt encodings, EOS IDs and vocabulary equality before draft/target use. Cache rewind and token budgets are explicit. This is not general distribution-preserving stochastic speculative decoding.
- **Attention:** Paged attention accepts only no mask or causal mask, FP32/BF16, and validated page metadata. The optimized BF16 long-prefill schedule and scalar fallback are distinct. Tolerance-based comparisons are not bitwise equivalence or a full model-quality evaluation.
- **Context:** The performance appendix distinguishes trained, configured, memory and latency limits; its 300K synthetic attention sweep is not supported 300K end-to-end Qwen inference. Week 4 documents a 32,768-token hard budget. There is no claim here of long-context quality validation.

## Performance Evidence: Strong Method, Historical Numbers

The [performance appendix](https://github.com/skyzh/tiny-llm/blob/17a8cc660b1547bd42dfe53b01e9c76410f4cf8c/book/src/appendix-performance.md) explicitly labels its main tables historical. The retained task367 corpus records source **18aec8503929d80c986324578068ecac2463c2ac**, not the reviewed SHA, on an M4 Pro/20-core GPU/64 GB with MLX 0.32.0. The reviewed manifest now requires MLX >=0.32.4. Current runner commands produce new measurements, not automatic reproduction of old figures.

The methodology is better than an isolated tokens/sec screenshot: fresh subprocesses, balanced order, complete warmups, synchronized lazy execution, workload/configuration recording and median aggregation. It distinguishes last-row versus all-row prefill logits, excludes the first generated token from decode throughput, separates output throughput from decode phase throughput, and labels logical copy counters as **not physical DRAM traffic**.

Historical direct-paged serving reports 46.36 output tok/s versus 35.23 for dense reconstruction, with decode phase 105.01 versus 57.59 and peak KV 576 versus 1,096 MiB. Those are upstream measurements for a particular request trace, not our results, a vLLM comparison or current-source promises. The isolated attention comparison is admirably negative at short context: direct paged is slower than dense-plus-gather at 128 tokens, and MLX fused remains faster at both displayed shapes. The cumulative serving table does not isolate the Day 5 FlashAttention kernel.

We independently verified all ten files listed in [the SHA-256 ledger](https://github.com/skyzh/tiny-llm/blob/17a8cc660b1547bd42dfe53b01e9c76410f4cf8c/benchmark_results/task367-final-main/task367-final-main-sha256.txt), including its manifest, eight raw JSON files and evidence ledger. All match. Hash agreement proves checked-in files agree with the checked-in ledger; it does not authenticate the host, independently reproduce timings or prove correctness. The manifest's 74 passing focused tests and three model-availability skips are historical author-reported evidence, not tests run for this review. No present-source speedup or agent benchmark score is asserted.

## Security, Network and Licensing Boundaries

Normal entry points load named Hugging Face models through MLX-LM without an explicit immutable revision pin or local-only enforcement. Initial loading can access the network and cache downloads; an existing cache is not a guarantee of offline behavior. No explicit trust_remote_code=True was found in the inspected entry points, but dependency loading/deserialization remains part of the trust boundary. Pin source, environment and exact model artifacts; prepopulate a verified cache and enforce offline operation for private exercises. Never hand arbitrary model IDs or native tensor metadata directly to untrusted clients.

Inference is local in the reviewed implementation; no hosted inference API or telemetry client was identified in these entry points. That does not constrain approved agent subprocesses, package installation or model acquisition. Keep all agent work in a disposable, secret-free environment, and treat prompts, model output, receipts, checkpoints and evidence artifacts as potentially sensitive. Auth/CORS hardening is not meaningfully evaluated because this is not an HTTP deployment stack.

The root [LICENSE](https://github.com/skyzh/tiny-llm/blob/17a8cc660b1547bd42dfe53b01e9c76410f4cf8c/LICENSE) is Apache-2.0: preserve applicable license/notice and modification requirements when reusing code. The [book copyright statement](https://github.com/skyzh/tiny-llm/blob/17a8cc660b1547bd42dfe53b01e9c76410f4cf8c/book/src/copyright.md) separately says CC BY-NC-SA 4.0; do not advertise the entire course as Apache-only or copy book material into commercial training under the code license. The inspected [Qwen3-4B-MLX-4bit model card](https://huggingface.co/Qwen/Qwen3-4B-MLX-4bit) declares Apache-2.0 (its license_link points to the Qwen3-14B LICENSE, so check the exact downloaded artifact's terms rather than relying solely on that link). Other models and dependencies retain their own terms. This review extracts no source code or book content wholesale.

## Tests, CI and Maturity

There is substantive pytest coverage beyond happy-path generation: synthetic transformer comparison with MLX, page order/tail poisoning, cache capacity/rewind, loader guards, sampler behavior, agent approvals/stale-file rejection, receipt reopening and duplicate effects. [Paged attention tests](https://github.com/skyzh/tiny-llm/blob/17a8cc660b1547bd42dfe53b01e9c76410f4cf8c/tests_refsol/test_week_3_day_4.py) deliberately poison unused physical storage to catch accidental reads; [agent tests](https://github.com/skyzh/tiny-llm/blob/17a8cc660b1547bd42dfe53b01e9c76410f4cf8c/tests_refsol/test_week_4_day_3.py) exercise approval and receipt semantics. These are strong design signals, not a substitute for running them.

The [macOS workflow](https://github.com/skyzh/tiny-llm/blob/17a8cc660b1547bd42dfe53b01e9c76410f4cf8c/.github/workflows/macos.yml) targets ARM macos-15, downloads the 0.6B weights, builds learner/reference extensions and runs test-refsol on pushes and PRs. The README's [main workflow badge](https://github.com/skyzh/tiny-llm/blob/17a8cc660b1547bd42dfe53b01e9c76410f4cf8c/.github/workflows/main.yml) corresponds primarily to book build/deployment, not numerical tests. Actions are tag-referenced rather than immutable-SHA pinned, and some tools/models are installed without immutable artifact pins. We inspected workflow definitions, not a successful current check run.

Public GitHub metadata retrieved 2026-11-06: created 2025-04-19; 5,650 stars, 520 forks, 13 open items reported by open_issues_count (may include PRs), not archived, last push 2026-11-04. HEAD's commit date is 2026-10-31; these are different timestamps. The releases endpoint returned no releases; the package declares 0.1.0. Popularity and ongoing maintenance do not imply a stable serving API or audited agent safety.

## Comparison

| Option | Best use | Tradeoff relative to tiny-llm |
|---|---|---|
| [MLX-LM](https://github.com/ml-explore/mlx-lm) | Practical local Apple-silicon generation/fine-tuning | Existing runtime and broader integrations; less explicit homework progression. tiny-llm already relies on it for loading/oracles and some projections. |
| [llama.cpp](https://github.com/ggml-org/llama.cpp) | Cross-platform local inference and serving | Much broader hardware/model ecosystem; larger implementation, less focused teaching sequence. |
| [vLLM](https://github.com/vllm-project/vllm) | High-throughput service infrastructure | Actual serving platform with a different deployment/hardware scope; “Mini vLLM” here is conceptual education. |
| [nanoGPT](https://github.com/karpathy/nanoGPT) | Understanding a small training loop | Training-centered rather than packed-weight inference, page ownership and agent effects. |

For complementary production-oriented study, the existing [LMCache review](lmcache.md) discusses KV management as a separate serving layer; it is not a drop-in component requirement for this course.

## Self-Hosting Notes

Treat this as a local lab, not something to expose to a network. Use a supported Apple-silicon Mac, pinned PDM environment and full Metal toolchain; account for the native builds even for early exercises. Begin with the reference 0.6B checkpoint, then complete the student code and compare numerical outputs before trying larger models or performance tuning. Keep exact source/model/dependency versions with every result. Do not infer memory requirements from quantized download size or reuse an M4 Pro benchmark as an acceptance threshold on another machine.

Before real use, fix or explicitly document the cached-generation sampler mismatch, run the appropriate reference suite on the target hardware, compare a matched workload with MLX-LM, and isolate any agent subprocesses at the OS boundary. There is no reviewed production deployment recipe here, and no install or deployment was performed.

---

**Attribution:** skyzh/tiny-llm, Alex Chi Z and contributors. Code Apache-2.0; book CC BY-NC-SA 4.0; model/dependency terms separate. Independent analysis; all source citations above are pinned to the reviewed revision unless explicitly identified as external metadata/model/alternative links.
