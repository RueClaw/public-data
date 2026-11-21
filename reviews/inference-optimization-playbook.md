# Inference Optimization Playbook (alesha-pro/inference-optimization-playbook)

**Source:** https://github.com/alesha-pro/inference-optimization-playbook
**Author:** alesha-pro; README attribution: @superalesha.
**License:** MIT, copyright 2026 alesha-pro. Preserve the notice for substantial reuse; model weights and linked engines have separate terms.
**Reviewed / retrieved:** 2026-11-21 (UTC).
**Revision:** 53868e29b2a773ecd30ec6eda2ef9b675459a82b; whole repository: 16 playbook chapters, six model cases, ledger, protocols, agent instructions and both Python tools.
**Verification:** Static source inspection, public primary-reference checks and independent arithmetic only. No source programs, inference, benchmarks or GPU tests executed; no packages or weights downloaded.
**Stack:** Markdown research notebook and agent skill; two Python standard-library CLI utilities.
**What it is:** A mechanism-indexed notebook of consumer-GPU inference experiments, mainly large mixture-of-experts models with CPU/RAM offload. It is not an inference engine or a benchmark harness.

---

## Verdict

📚 **Study: unusually useful experimental discipline, not independently reproduced performance guidance.** The strongest material is the negative-result ledger, workload-specific cost reasoning and explicit numerical-quality/release gates. Read it to design experiments, but do not import its universal-sounding speculation ceilings, profiling advice or hardware rules unchanged. The underlying engine patches, datasets and measurements are not bundled into a reproducible experiment package.

## Summary and actual artifacts

The notebook organizes work by bottleneck rather than offering a universal sequence of flags: identify residency and routing skew, compare CPU computation with PCIe transfers, model misses, then consider prefill, speculation, precision and session reuse. A situation card and tagged ledger help an engineer choose a relevant case. Every negative result has scope or a reason to revisit it. [S1–S4]

The checked tree contains **115 ledger rows**, independently counted, matching the README and skill description. The GitHub repository description still says 97. There are six case files, including the newly added resident Inkling 2 Mini path; the opening map still says five models and understates its resident-model coverage. These are documentation-drift signals, not evidence that the experiments are fabricated. [S1–S3]

The executable deliverables are only tools/route_sim.py and tools/fit_cost.py. There is no package/dependency manifest, automated test suite, CI workflow, GPU implementation, benchmark launcher, raw trace corpus or model weights in this revision. The README links separate author-owned benchmark/engine repositories; their existence does not make this notebook an independently validated implementation. [S1, S11, S12]

## Key claims and assessment

### 1. Optimize the expensive term, not a fashionable mechanism

The local approximation time = constant + misses × miss_cost is a useful first hypothesis, especially when compared with actual residency, transfer volume and end-to-end time. The cases correctly show a CPU lane beating PCIe on some models and losing on another, and tensor parallel winning in one configuration but losing elsewhere. The prefill discussion also distinguishes tokens served per expert load from activation tile size. NVIDIA's primary guidance supports minimizing repeated host/device transfers, pinned-memory DMA and measured overlap; it does not validate these specific speedups. [S4–S6, P1]

Do not treat the fitted intercept as a physical, architecture-independent ceiling. Transfer/compute overlap, changing batch shapes, cache policy, heterogeneous expert sizes and resource contention can change both slope and intercept. Two or three points are weak evidence for extrapolation to zero misses. The text sometimes says 2–3 runs, while the one-regressor tool requires at least three. Its R² is in-sample, not a predictive interval. A CPU-versus-copy decision needs the entire overlapped critical path and merge cost, not just one isolated expert measurement.

### 2. Cache placement is not pruning; bits are a quality choice

Distinguishing frequency-based placement from expert importance is valuable. The notebook explicitly rejects several pruning and kernel changes despite speed gains, and separates fixed-history logits, distribution tolerances and application behavior. It recognizes that CPU/GPU summation order, quantization, KV precision and even chunk size can change routing and generated text. It also documents a first-turn match that failed on the second turn after a snapshot-boundary change. [S7–S9]

However, a change within the variation of two stock configurations is **not proof of unchanged quality**. That stock variation can itself harm a downstream task. KL on selected forced positions, a 96-question GSM8K subset, and a few language examples are useful screens, not universal equivalence or statistical non-inferiority. The reported 74/96 versus 73/96 is one extra success, not established improvement. Require prespecified margins, representative held-out task panels, paired uncertainty estimates and multi-turn behavior checks. Keep KV precision fixed when attributing error to an expert kernel.

### 3. Speculation guidance has a material overgeneralization

Measuring committed tokens per full draft-plus-verification time is right. Distinguishing copied edits from fresh prose is particularly good: the author reports 488.9 tok/s for a repetitive 509-token edit versus roughly 113–114 tok/s for fresh prose/code on that serving profile. These are author results, not measurements reproduced here. [S10]

But “the ceiling of any drafter is +20%” from the target choosing its argmax at 79% of positions is **not a general bound**. It can at most describe the specified exact-match proposal/verification method, workload and cost fit. Exact speculative sampling uses acceptance/rejection correction; if proposal distribution q equals target p, acceptance is one even for a high-entropy target. A perfect drafter is therefore not universally defined as “always the argmax.” The original speculative-decoding paper explicitly preserves the target distribution. Likewise, “under batching speculation loses everywhere” should remain a local observation, not a rule for all engines, hardware or batch sizes. [S10, P2]

### 4. Profiler and cache advice needs version and correctness qualifications

Chapter 14 says Nsight Systems cannot see kernels inside CUDA graphs and recommends disabling the graph. Current NVIDIA documentation explicitly supports node-level tracing via --cuda-graph-trace=node, with overhead and driver/mode qualifications. Graph-off profiling can help attribution but changes the workload; it must not stand in for graph-on end-to-end timing. [S8, P3]

Chapter 11 suggests matching history prefixes by text after non-canonical tokenization. Text equality alone does not establish identical token IDs, positions or recurrent/KV state. A safe implementation needs a proved mapping to a valid checkpoint and correct replay of the unmatched suffix. This review did not inspect or validate the external engine implementation. [S13]

## Benchmark methodology and evidence quality

| Dimension | What the notebook supplies | Remaining limitation |
|---|---|---|
| Hardware | 1–4 RTX 3090 24 GB; PCIe 3.0 x16, P2P, no NVLink; EPYC 7642; changing DDR4 population, later 503 GiB and eight channels; generally 300 W/card after an earlier 220 W period | One rig, not cross-platform validation; topology, NUMA, cooling and power confound comparisons |
| Models and precision | Six named cases, expert shapes, GGUF/EXL3 variants and some KV formats; Hy4 main series Q3_K experts/MTP and Q8 KV | Not every row identifies immutable weight hashes, tokenizer, template, compiler, driver and engine revision |
| Batch/concurrency | Mostly one active request; speculative verify widths and prefill block sizes discussed; isolated multi-session and batching examples | No systematic offered-load, scheduler, queueing or concurrent throughput matrix in this repository |
| Latency/throughput | Prefill, decode, TTFT, reread, whole-session time, worst answer and rolling-window rates; recommends total tokens / total time | No consistent p50/p95/p99 client latency, request-rate/SLO goodput or error-rate reporting across cases; engine times omit some user-visible overhead |
| Memory | Residency, expert slots, pinned RAM, RSS/cgroup distinctions, some peak VRAM and warm-file-cache qualifications | No uniform peak CPU/GPU/allocator/workspace accounting per row; configured maximum context is not populated context |
| Warm/cold | Separates process loading, fresh HTTP input, warmed expert/prefix cache and OS page cache; describes first-turn graph preparation | Not every result fixes all cache states; one low-RAM combined run explicitly had warm OS cache |
| Controls/statistics | ABAB/control-candidate-control; frozen profiles; thermal bandwidth checks; acknowledges bundles, one-run results and selected failures | Mostly narrative summaries without complete raw per-trial records, seed/input IDs, intervals or ablation mapping |
| Quality | Forced full logits, KL/NLL, top-token agreement, multiple turns and languages, occasional application panels | Limited samples and external metrics are not universal equivalence; “bit-exact” applies only to the reported checked inputs |

The reported Hy4 release gate is a good cautionary example: 187.67 tok/s overall, 159.35 on the worst full answer and 132.49 on the worst 32-token window did **not** satisfy a 170 tok/s target along the full context. Calling only the mean a pass would hide the failure. Another TP comparison explicitly excludes unexplained periods in which the CPU lane slowed by about 2×; that selection must remain visible when planning reliability or tail latency. [S6, S8, S9]

**Independent arithmetic, not replication:** 2,199 / 430 ≈ 5.11× for the bundled DeepSeek prefill changes; 1,510.2 / 415.6 ≈ 3.63× for the full Hy4 single-card build; 4,050 / 1,084 ≈ 3.74× for a single MiniMax replay; 660,006,416 × 96 / 2³⁰ ≈ 59.009 GiB for the Hy4 table. These ratios confirm arithmetic only, not causality, timing or quality. The first two must not be credited to one isolated optimization. [S1, S5, S14]

The linked benchmark archive README was publicly readable and describes a separate JSONL/SQLite catalog with commands and methodology. It also contains stale 638-row introductory text next to a generated 1,064-row summary. Only its README was checked here; no archive dataset was downloaded, and no row-by-row linkage to the 115 hypotheses was established. Many notebook citations lead to another chapter rather than an immutable raw experiment; several external KL/throughput claims lack a direct primary citation at the claim. [P4]

## Static tool review

### route_sim.py

A small, readable stdlib program that reads JSONL, builds a profile from the first part and scores static, oracle, LRU, heat and future-aware policies on the rest. The demo is explicitly synthetic; the “uniform” demo has local 200-token working sets and is not IID uniform traffic. [S11]

Important interpretation limits:

- Splitting is by per-layer record count after sorting token indices, not by independent session. Traces with token-index resets across requests can interleave histories; the schema has no session ID. Hold out whole requests or provide monotonic global processing indices.
- Expert count defaults to maximum observed ID plus one. Unobserved experts above that ID are omitted; sparse/remapped or invalid IDs distort the random baseline. Supply the true expert count and validate IDs.
- LRU/Belady flatten picks into a sequential access stream, whereas heat scores a whole token before movement. Real top-k dispatch, within-token eviction/admission and asynchronous copy budgets need not match those models. Belady permits bypass; its headroom is an offline bound for this abstraction, not achievable production throughput.
- Capacity is fixed per layer and ignores heterogeneous bytes per expert, shared VRAM budgets, transfer cost and contention. Hit rate alone cannot rank latency.
- No robust range/schema/resource validation: zero decay interval can divide by zero, empty picks can leave no maximum or zero denominator, non-object JSON can raise an uncaught attribute error, and negative capacities are not rejected. Layer aggregation of moves assumes aligned test durations. Files and flattened future-use arrays are retained in memory; no input-size cap.

These are static observations, not executed regression tests.

### fit_cost.py

Fits ordinary least squares through normal equations and Gaussian elimination with partial pivoting. Useful for a quick small-dimensional sketch, but normal equations square the condition number; the fixed absolute singularity threshold is scale-dependent. There is no feature scaling, finite-number validation, uncertainty estimate, held-out validation or residual diagnostic. Negative slopes are permitted; a positive intercept does not prevent a zero/negative predicted time in later percentage/throughput calculations. Units must actually be milliseconds for 1000 / a to mean events per second. Treat its “ceiling” as a conditional extrapolation, not a hardware guarantee. [S12]

## Security, permissions, privacy and cost

The two inspected scripts import only Python standard-library modules, read a caller-selected local input and print results. No network client, subprocess launch, shell execution, dynamic evaluation, credential lookup or persistent write appears in their code. They are not servers, so authentication/CORS are not applicable. This is a narrow static assessment, not a security certification. Untrusted oversized or malformed inputs can still crash or exhaust resources. [S11, S12]

Installing the repository as an agent skill is a separate authority decision: prose asks agents to inspect hardware, run experiments and modify engines. It supplies experimental discipline, not enforced permission boundaries, spend caps, secret isolation or rollback controls. Review and pin a revision before giving an agent execution authority; do not let source text authorize privileged changes. Linked patched engines and the mentioned gpu-unlock module are separate supply-chain/kernel-trust surfaces, not dependencies audited here. BIOS/NUMA, power-limit, driver/module and THP changes require explicit operator control and a restoration plan. [S5, S15]

Real-session replay can retain prompts, generated code, tool results, router traces, KV snapshots and logits. Keep those artifacts local and access-controlled, minimize retention, sanitize any published reproducer and do not assume a router trace or KV snapshot is anonymous. This repository's contribution rules prohibit private paths and secrets, but no redaction mechanism is provided. Persistent cache reuse in a shared service also needs tenant isolation beyond the A → B → A correctness test. [S13, S15]

No paid API is required by the utilities. Reproducing the reported setup is nevertheless expensive in hardware, memory, storage, energy and engineering time: four 300 W GPU limits alone total 1.2 kW before CPU/RAM/cooling, not a measured whole-system draw. An eight-channel EPYC system with roughly 512 GB RAM is not an ordinary small desktop. No installation, driver modification, live service probe, model download or paid call was performed for this review.

## Maturity, alternatives and recommended use

Public GitHub metadata observed 2026-11-21 reports creation on November 20, last push November 21 at 13:19:40 UTC, 38 stars, 9 forks and zero open issue/PR items. The releases endpoint returned an empty list. The reviewed commit is dated November 21 at 13:19:39 UTC. The notebook claims experiments from July–November; that is author provenance, not independently established public history. A shallow checkout cannot establish the full maintenance record. [P5]

Use this alongside NVIDIA's CUDA/Nsight documentation for hardware/profiler semantics, the original speculative-decoding work for algorithmic guarantees, and your chosen engine's pinned benchmark tooling for execution. The author's separate benchmark archive may supply richer launch records, but still needs per-claim mapping and independent reproduction. This notebook's comparative advantage is its conditional negative results and release discipline, not a replacement for maintained engine tooling or a serving benchmark. [P1–P4]

**Recommended adoption:** start with the situation card and experiment protocol, then choose one hypothesis whose bottleneck actually appears on your system. Freeze engine/weights/input IDs and all relevant cache states; run matched baseline/candidate experiments at target depth and concurrency with client latency, memory and energy accounting. Require quality acceptance before speed acceptance. Do not buy GPUs, reduce precision or change production scheduling based solely on the headline ratios.

## Verification limits

All six cases and the core chapters, ledger, protocols and both scripts were read statically. The ledger row count and displayed ratios were independently checked. Public accessibility was verified anonymously through GitHub's API and HTTPS source retrieval; canonical source identity was checked for duplicate reviews before creating this review.

No upstream code was executed, no synthetic tests of the source utilities were run, and no performance/quality claim was independently reproduced. External engine implementations, model cards/weight licenses, raw benchmark datasets, PR merges, driver/module safety and real service behavior were not audited. Primary references corroborate general mechanisms and identify specific overstatements; they do not certify the author's measurements.

## Evidence

Source links below pin the reviewed commit; public metadata and external documentation are retrieval-date observations.

- [S1 — README](https://github.com/alesha-pro/inference-optimization-playbook/blob/53868e29b2a773ecd30ec6eda2ef9b675459a82b/README.md)
- [S2 — Ledger](https://github.com/alesha-pro/inference-optimization-playbook/blob/53868e29b2a773ecd30ec6eda2ef9b675459a82b/ledger/hypotheses.md)
- [S3 — Rig and cases](https://github.com/alesha-pro/inference-optimization-playbook/blob/53868e29b2a773ecd30ec6eda2ef9b675459a82b/cases/README.md)
- [S4 — Cost model](https://github.com/alesha-pro/inference-optimization-playbook/blob/53868e29b2a773ecd30ec6eda2ef9b675459a82b/playbook/01-cost-model.md)
- [S5 — Prefill](https://github.com/alesha-pro/inference-optimization-playbook/blob/53868e29b2a773ecd30ec6eda2ef9b675459a82b/playbook/07-prefill.md)
- [S6 — Multi-GPU](https://github.com/alesha-pro/inference-optimization-playbook/blob/53868e29b2a773ecd30ec6eda2ef9b675459a82b/playbook/05-multi-gpu.md)
- [S7 — Quants](https://github.com/alesha-pro/inference-optimization-playbook/blob/53868e29b2a773ecd30ec6eda2ef9b675459a82b/playbook/09-quants.md)
- [S8 — Benchmarking](https://github.com/alesha-pro/inference-optimization-playbook/blob/53868e29b2a773ecd30ec6eda2ef9b675459a82b/playbook/14-benchmarking-and-traps.md)
- [S9 — Quality gates](https://github.com/alesha-pro/inference-optimization-playbook/blob/53868e29b2a773ecd30ec6eda2ef9b675459a82b/playbook/15-quality-and-release-gates.md)
- [S10 — Speculative decoding](https://github.com/alesha-pro/inference-optimization-playbook/blob/53868e29b2a773ecd30ec6eda2ef9b675459a82b/playbook/08-speculative-decoding.md)
- [S11 — Route simulator](https://github.com/alesha-pro/inference-optimization-playbook/blob/53868e29b2a773ecd30ec6eda2ef9b675459a82b/tools/route_sim.py)
- [S12 — Cost fitter](https://github.com/alesha-pro/inference-optimization-playbook/blob/53868e29b2a773ecd30ec6eda2ef9b675459a82b/tools/fit_cost.py)
- [S13 — Session cache](https://github.com/alesha-pro/inference-optimization-playbook/blob/53868e29b2a773ecd30ec6eda2ef9b675459a82b/playbook/11-sessions-and-prompt-cache.md)
- [S14 — Loading and big tables](https://github.com/alesha-pro/inference-optimization-playbook/blob/53868e29b2a773ecd30ec6eda2ef9b675459a82b/playbook/12-loading-and-big-tables.md)
- [S15 — Agent skill](https://github.com/alesha-pro/inference-optimization-playbook/blob/53868e29b2a773ecd30ec6eda2ef9b675459a82b/SKILL.md), [contribution rules](https://github.com/alesha-pro/inference-optimization-playbook/blob/53868e29b2a773ecd30ec6eda2ef9b675459a82b/AGENTS.md), [MIT license](https://github.com/alesha-pro/inference-optimization-playbook/blob/53868e29b2a773ecd30ec6eda2ef9b675459a82b/LICENSE)
- [P1 — NVIDIA CUDA Best Practices: pinned memory and transfers](https://docs.nvidia.com/cuda/cuda-c-best-practices-guide/index.html#pinned-memory)
- [P2 — Leviathan, Kalman and Matias, Fast Inference from Transformers via Speculative Decoding, ICML 2023](https://proceedings.mlr.press/v202/leviathan23a.html)
- [P3 — NVIDIA Nsight Systems: CUDA Graph Trace](https://docs.nvidia.com/nsight-systems/UserGuide/index.html#cuda-graph-trace)
- [P4 — Author's separate benchmark archive, README only checked](https://github.com/alesha-pro/4x3090-llm-benchmarks)
- [P5 — Public repository metadata](https://api.github.com/repos/alesha-pro/inference-optimization-playbook), [releases](https://api.github.com/repos/alesha-pro/inference-optimization-playbook/releases)

---

**Attribution:** alesha-pro / @superalesha, Inference Optimization Playbook, MIT. This review is independent analysis; performance and quality figures remain attributed author reports unless explicitly marked as arithmetic checks.
