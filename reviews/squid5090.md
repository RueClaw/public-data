# squid5090 (tensorfish/squid5090)

**Repo:** https://github.com/tensorfish/squid5090
**License:** No repository-wide license grant found; NOTICE attributes upstream Apache-2.0/MIT work. Model terms are separate.
**Reviewed:** 2026-11-24 (UTC)
**Revision:** `3140b6507740081827e189cda65a345bcb076885`, main; source commit 2026-11-24T04:46:02Z. Scope: README, engineering documents/ledger, build, src/, cuda/, tools/, deployment unit and NOTICE.
**Verification:** Static review only. No compilation, installation, model downloads, GPU execution, inference, performance or numerical tests run.
**Stack:** Zig, C++20/CUDA, NVIDIA Blackwell sm_120a; optional Python/PyTorch tooling.
**What it is:** A highly specialized, single-slot text inference engine for Thinking Machines’ Inkling-2-Mini, with a native OpenAI-style HTTP/SSE interface.

---

## Verdict

📚 **Study — substantial kernel engineering, not a deployment recommendation yet.** The code supports a coherent story about specialized memory layouts, speculative verification and GPU launch reduction. But the headline performance is author-reported, the million-token result is partly a synthetic capacity/latency experiment, sampling is approximate, public-serving defaults need hardening, and a project-wide reuse license is missing. Read the kernels and experimental tradeoffs; do not treat the README as an independently reproduced benchmark or a production-security claim.

## What It Is

This is not a generic model server or a Python wrapper. Compile-time geometry fixes the implementation to a 24-physical-layer, 48-visit looped model with 128 experts, top-8 routing, short convolutions, depth attention and a three-layer DSpark drafter. The original model is multimodal, but this review concerns the engine’s text/token pipeline, not demonstrated image parity. [1][2][11]

Anonymous GitHub API access confirmed the repository public. At retrieval it showed 84 stars, 12 forks, zero open issues, no releases and an empty all-state issues response; these are a time-sensitive snapshot, not quality evidence. No existing review matched the canonical owner/repository identity. The exact source SHA above, rather than an untagged latest build, is the reviewed unit. [12]

## Stack

| Layer | Technology and constraint |
|---|---|
| Host runtime | Zig CLI, tokenizer, POSIX mmap safetensors loader, fixed-capacity buffers |
| Compute | Five CUDA translation units, custom C ABI, CUDA Graphs, cuBLAS |
| Model | Inkling-2-Mini fixed geometry; NVFP4/FP8/exact weight modes; BF16/FP8/Q4 KV |
| Serving | Sequential raw TCP HTTP/SSE, OpenAI-style chat/completions/models endpoints |
| Optional research | Python 3.11–3.13, PyTorch, Transformers, Optuna, safetensors |
| Persistence | Weight files and optional ablation tensors; volatile request/KV state, systemd restart |

## Key Features

### Specialized speculation rather than generic batching

DSpark drafts and target verification run through captured graphs with adaptive widths 2/4/8. A bounded hash-indexed prompt-lookup path supplies verbatim continuation candidates and can skip drafting. Verification emits target predictions until the first mismatch, then updates the anchor/position. This is real implementation substance, especially for repetitive code-copy workloads, but does not make copy-task speed representative of arbitrary chat. [3][4]

### Capacity from architecture and compression

Only eight of 48 attention visits retain global context; the others use bounded local rings. Q4 global KV, preallocated weight/runtime arenas and zero-copy host embeddings explain why a million-token allocation could fit. The “0 GiB RAM spill” headline needs qualification: above 524,288 tokens in non-exact mode, main automatically enables host embeddings, and weights explicitly allocates mapped pinned host memory. Prefix caching also holds four roughly 193 MiB local-state checkpoints plus a side-request shield in host RAM. This avoids bulk expert-weight spilling; it is not a zero-host-memory design. [2][3][5]

### Useful negative-results documentation

PLAN and ledger record rejected changes as well as improvements: reduced draft vocabularies, occupancy changes, fusion and tensor-core paths. That is more informative than a single marketing chart. Still, the historical log mixes stages, precision configurations and prompt lengths, and does not provide a complete versioned benchmark bundle tying every result to exact source, model, prompt and machine state. [6]

## Architecture

main selects mode/context and loads local tensors; weights converts supported weights and plans memory; engine owns KV, graph state, prompt lookup, prefill, decode and prefix restoration. CUDA modules separate GEMV/LM-head, model kernels, DSpark, prefill and ABI operations. Constants and release-active assertions catch numerous geometry/bounds violations. They are invariants, not a substitute for differential tests or fuzzing. The build uses --use_fast_math and links CUDA/runtime libraries; “single binary” means one application executable, not a hermetic statically self-contained artifact. [2][3][5][7]

The safetensors reader uses mmap and explicit bounds/assertions instead of loading executable model code. That reduces one common model-loading risk, but malformed inputs can abort the process, and this static review does not prove native parser or kernel memory safety. Only trusted, pinned model/tensor artifacts should enter this process. [8]

## Performance Claims and Reproducibility

| Claim | Evidence and interpretation |
|---|---|
| 589.5 tok/s code; 771.6 tok/s code-copy/RAG; 332.5 tok/s chat | README/LEARNINGS report different prompts and acceptance rates. These are decode figures, not cold-load or end-to-end request throughput. No independent rerun here. |
| 9,181 tok/s prefill | Engineering notes identify this as a chunk peak; reported longer-prompt values are 8,755 at 20K and 7,742 at 64K. Do not substitute the peak for every input. |
| 1,048,576-token context | Allocation and simulated-position latency support feasibility. bench_step_at_pos zeroes global caches and seeds a token at a simulated position; it does not ingest a million-token document. |
| ~108 tok/s at 1M | The longctx B=4 column uses 2500/ms-per-step, an assumed 2.5 tokens per step, rather than measured acceptance on a real 1M prompt. |
| Full long-context quality | Authors report real 64K needle retrieval and 131K prefill, but explicitly list a full 1M three-needle prefill soak and bootstrap-confidence harness as unfinished. |
| Better than other engines | README comparison mixes published references and author measurements without a fully pinned cross-engine harness. No verified universal ranking follows. |

These distinctions are visible in executable benchmark logic as well as the documentation. The CLI bench does warmup, repeated runs and a median, which is a useful starting point. For reproduction, freeze source/model/tokenizer revisions, toolchain and driver; record prompt bytes/token IDs, precision, temperature, MTP, cache state, generation length, GPU clocks/power and all samples; compare TTFT, end-to-end latency, decode and quality separately. [1][3][6]

## Numerical Correctness

**Speculation parity is narrower than model fidelity.** Equal tokens across speculative widths can show consistency within a quantized engine, not equality to original BF16/reference logits or preserved downstream quality. LEARNINGS itself notes B=1 uses a different accumulation path and can differ by a one-ULP tie break from B≥2. NVFP4 conversion, Q4 KV and CUDA fast math deserve separate error/quality measurements. No automated reference-logit, perplexity, broad task-quality or tokenizer-parity suite was found in the tracked tree. Author claims of exact tokenizer/greedy parity remain unverified here. [3][6][7]

**OpenAI-style sampling is approximate.** The LM-head sampler builds a 256-bin histogram over a 20-nat window and includes entire cutoff bins for top-p/top-k. Therefore top-k can retain more than k tokens and top-p is not an exact sorted nucleus. Even the unfiltered branch truncates that window. Position/token-seeded Gumbel scoring makes target-sample comparison during speculation intelligible; it does not establish exact equivalence to another engine’s sampling distribution or RNG. This is a concrete semantic difference, not a demonstrated claim that speculation itself is invalid. [4]

**Ablation changes behavior by design.** Optional runtime detector-gated projections modify attention/MLP writes without rewriting base weight files. A small refusal-string evaluator and claimed harmless-output parity are not general evidence of retained capability or safe behavior. Disable it for a baseline; validate any intervention separately and review applicable model terms. [9][11]

## Permissions, Privacy and Supply Chain

- **Exposure is unsafe by default for an untrusted network.** ServerConfig binds 0.0.0.0 and has an empty optional API key; the sample service likewise exposes port 8000, with auth only commented. HTTP has no native TLS, CORS is wildcard, and /health bypasses auth. Use loopback or a restricted interface behind authenticated TLS and explicit rate/body/time limits. [10]
- **One slow client can monopolize service.** The accept loop handles one connection synchronously. The request reader blocks in recv before authentication; bounded loop counts do not create a wall-clock deadline. No receive timeout was found in that path. Treat slow-client/resource exhaustion as an evident design risk, not a penetration-tested exploit. [10]
- **Oversized API-key fail-open edge.** Expected Bearer authorization is formatted into a 256-byte buffer; formatting failure falls back to an empty string. A key longer than 249 bytes therefore makes an absent Authorization header compare equal. Validate key length and fail closed instead of relying on unusual configuration never occurring. This is a static code-path finding, not an executed exploit. [10]
- **Local inference is not automatic data isolation.** No hosted inference upload was found in the core path; request metrics are logged, and prompt tokens/KV persist in volatile prefix buffers across requests. There is no per-tenant cache ownership boundary. Restrict callers and manage proxy/journal retention; do not infer secure memory erasure. Optional refusal tooling sends prompts to its configured endpoint and writes completion reports. [3][9][10]
- **Avoid the sample service verbatim.** It has no User= or sandbox hardening, so a normal system-level installation runs as root. It also enables optional ablation by default and depends on an external ablation file. Use a dedicated unprivileged service identity, explicit filesystem/GPU access and a reviewed configuration. [10]
- **Supply-chain reproducibility is incomplete.** Core build invokes local nvcc and system libraries, with no package lock or reproducible binary release. Optional Python dependencies are mostly unpinned; Transformers is pinned to a commit, but no uv lock is present. The README model download does not pin a revision. No dependency installation or download command was executed in this review. [1][7][9]

## License and Model Terms

No LICENSE/COPYING or other clear repository-wide grant was found at the reviewed SHA; GitHub reports license null. NOTICE names upstream Apache-2.0 and MIT projects and the author’s copyright, but attribution is not a license for the complete repository. Do not assume fork/redistribution permission from public visibility or upstream licenses. Request clarification and preserve applicable upstream notices before reuse. No source code is extracted here. [12][13]

The anonymously accessible model card at revision **7a67ae2314b44ef05c87fd1d4d311c58aaeb18f6** labels Inkling-2-Mini Apache-2.0, dated November 20, 2026, and links a separate Model Acceptable Use Policy. That policy, retrieved November 24 and last updated July 15, 2026, states conditions for access/use and modified materials, downstream responsibility and prohibited uses, including circumvention in connection with prohibited conduct. Do not summarize the model as unrestricted solely from its license tag; assess the relationship between that policy and Apache terms for the intended use. The optional refusal-reduction workflow makes this especially relevant, without establishing that every such experiment violates the policy. This is not legal advice. [11]

## Persistence, Recovery, Tests and Maturity

Weights and ablation files survive restarts; KV, prefix checkpoints, request progress and RNG/session state are in memory. The sample systemd unit restarts failures after three seconds, but does not resume an interrupted generation or persist conversations. Clients must resend history and handle incomplete SSE output; restarting reloads weights/rebuilds runtime state. Back up pinned source, model/config provenance and any generated research reports, not an assumed durable server session. [3][10]

No tracked CI workflow, dedicated test directory, Zig test blocks or build test target was found. Bench/longctx and Python refusal/ablation verification tools exist, but are not a passing automated CI suite. No public releases were returned. The shallow checkout cannot establish a long maintenance history. Native HTTP/parsers, kernel correctness, long-context quality, concurrency behavior, clean build compatibility and actual GPU memory consumption all remain untested here. [7][9][12]

## Comparison

| Option | Better fit / tradeoff |
|---|---|
| squid5090 | Study or carefully benchmark a single-user Inkling text path on RTX 5090; narrow hardware/model target and licensing uncertainty. |
| llama.cpp / Ollama | Evaluate for wider hardware/model portability and GGUF workflows; do not assume identical Inkling quantization, DSpark support or speed. |
| vLLM / SGLang | Evaluate for multi-request scheduling and broader serving infrastructure; single-slot latency is a different objective from aggregate throughput. |
| Hugging Face Transformers | Useful model reference for logit/tokenizer/quality comparisons and multimodal coverage, accepting a heavier runtime. |
| ingine / related native engines | Relevant implementation comparison because NOTICE identifies inherited designs; independently check each project’s license, revision and benchmarks. |

The upstream model card links supported inference options, but none of these alternatives was benchmarked in this review. Prefer a maintained, appropriately licensed serving stack for production until squid5090’s license, correctness evidence and operating boundary are clarified. [1][11][13]

## Self-Hosting Notes

The author specifies Linux x86_64, an sm_120a Blackwell GPU such as RTX 5090, CUDA 13+, driver 580+ and Zig 0.17.1+ (tested versions differ in detail). CUDA Graph conditional-switch usage and explicit sm_120a PTX make this more than a generic “CUDA-capable GPU” requirement. The build defaults to sm_120a; changing an architecture flag is not proof of portability. Confirm an exact working compiler/toolkit combination before adopting. Budget about 20 GB model storage, claimed ≥16 GiB free VRAM for smaller contexts or ≥23.5 GiB for 1M, plus pinned embeddings, prefix buffers and OS/tooling memory. These are author requirements/estimates, not measurements from this review. [1][5][7]

A sensible evaluation gate is: resolve licensing; use unprivileged loopback-only serving without ablation; pin artifacts/toolchains; run parser/auth regression tests and differential logits/tokenizer tests; compare BF16/FP8/Q4 quality; perform genuine long-prompt retrieval and restart/disconnect tests; only then compare latency on representative workloads. No such deployment was performed here.

## Evidence

All repository citations below are pinned to the reviewed source revision.

[1]: https://github.com/tensorfish/squid5090/blob/3140b6507740081827e189cda65a345bcb076885/README.md
[2]: https://github.com/tensorfish/squid5090/blob/3140b6507740081827e189cda65a345bcb076885/src/constants.zig
[3]: https://github.com/tensorfish/squid5090/blob/3140b6507740081827e189cda65a345bcb076885/src/engine.zig
[4]: https://github.com/tensorfish/squid5090/blob/3140b6507740081827e189cda65a345bcb076885/cuda/kernels_gemv.cu#L1234-L1306
[5]: https://github.com/tensorfish/squid5090/blob/3140b6507740081827e189cda65a345bcb076885/src/weights.zig#L190-L207
[6]: https://github.com/tensorfish/squid5090/blob/3140b6507740081827e189cda65a345bcb076885/LEARNINGS.md
[7]: https://github.com/tensorfish/squid5090/blob/3140b6507740081827e189cda65a345bcb076885/build.zig
[8]: https://github.com/tensorfish/squid5090/blob/3140b6507740081827e189cda65a345bcb076885/src/safetensors.zig
[9]: https://github.com/tensorfish/squid5090/tree/3140b6507740081827e189cda65a345bcb076885/tools
[10]: https://github.com/tensorfish/squid5090/blob/3140b6507740081827e189cda65a345bcb076885/src/server.zig#L360-L510
[11]: https://huggingface.co/thinkingmachines/Inkling-2-Mini/blob/7a67ae2314b44ef05c87fd1d4d311c58aaeb18f6/README.md
[12]: https://api.github.com/repos/tensorfish/squid5090
[13]: https://github.com/tensorfish/squid5090/blob/3140b6507740081827e189cda65a345bcb076885/NOTICE

Additional direct evidence: [CLI benchmark and host-embedding selection](https://github.com/tensorfish/squid5090/blob/3140b6507740081827e189cda65a345bcb076885/src/main.zig), [speculative verifier](https://github.com/tensorfish/squid5090/blob/3140b6507740081827e189cda65a345bcb076885/cuda/kernels_dspark.cu#L810-L835), [service unit](https://github.com/tensorfish/squid5090/blob/3140b6507740081827e189cda65a345bcb076885/deploy/squid5090.service), [experiment ledger](https://github.com/tensorfish/squid5090/blob/3140b6507740081827e189cda65a345bcb076885/ledger.jsonl), [optimization plan](https://github.com/tensorfish/squid5090/blob/3140b6507740081827e189cda65a345bcb076885/PLAN.md), [Model AUP](https://thinkingmachines.ai/model-acceptable-use-policy/), [release API](https://api.github.com/repos/tensorfish/squid5090/releases), [issue API](https://api.github.com/repos/tensorfish/squid5090/issues?state=all).

---

**Attribution:** tensorfish/squid5090 and its credited upstream projects; model by Thinking Machines Lab. Original analysis, no source-code redistribution. Repository-wide license unspecified; component/model terms separate.
