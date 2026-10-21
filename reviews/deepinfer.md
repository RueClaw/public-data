# DeepInfer (deepseek-ai/DeepInfer)

**Repo:** https://github.com/deepseek-ai/DeepInfer
**License:** Apache-2.0 for the framework; default checkpoint separately MIT. Dependencies retain their own terms.
**Reviewed:** 2026-10-21 (UTC)
**Revision:** 9bd9cf243fc53ef9afbf8f04d391d989117d6ab9; root framework, build manifests, engine/C++ scheduling, selected model and TileLang modules, distributed transport, examples, evaluation and tests. Vendor submodules were not recursively acquired or audited.
**Verification:** Static source inspection only. No builds, imports, tests, inference, model downloads, deployments or benchmark runs.
**Stack:** Python 3.12, PyTorch, C++/pybind11, CUDA/TileLang or Ascend/CANN, specialist DeepSeek kernel libraries.
**What it is:** DeepSeek's model-specific distributed inference engine, released as an offline framework for DeepSeek-V4.1-Flash—not a complete public inference service.

---

## Verdict

📚 **Study: serious systems engineering, not a turnkey serving stack.** The scheduler, expert-parallel execution, confidence-budgeted speculation and cache replay are valuable references for teams operating supported accelerator clusters. The public release omits critical online-service components, and its synthetic steady-state throughput is not interchangeable with accepted-token production throughput or tail latency. Consider an isolated engineering evaluation only if the model and hardware match; do not replace a general-purpose serving stack on these charts alone.

## What It Is

The public repository is genuinely owned by **deepseek-ai**, is not a fork, and describes itself as the engine behind DeepSeek production services. Its documented supported model is DeepSeek-V4.1-Flash and its default checkpoint is DeepSeek-V4.1-Flash-1017. The production provenance is an author claim, not something this review independently establishes. [README](https://github.com/deepseek-ai/DeepInfer/blob/9bd9cf243fc53ef9afbf8f04d391d989117d6ab9/README.md)

The important boundary is explicit: the release supplies offline inference, not the full KV cache service, vision/prefill/decode disaggregation deployment, or cross-replica load balancers. In-memory KV allocation and engine hooks exist; that does **not** mean the external persistent cache and orchestration system have been released. The engine class explicitly says there is no online-serving wrapper. [Engine](https://github.com/deepseek-ai/DeepInfer/blob/9bd9cf243fc53ef9afbf8f04d391d989117d6ab9/deepinfer/engine/llm_engine.py)

## Stack

| Layer | Technology / constraint |
|---|---|
| Public API | Python LLM.generate batch interface and SamplingParams |
| Runtime | PyTorch; C++ extension for scheduling, sequences, blocks and output processing |
| NVIDIA | SM100; Linux, GCC ≥13, Python 3.12, CUDA 13; NVIDIA requirements pin torch 2.13.0+cu132 |
| Ascend | Ascend 950; CANN 9.2; torch 2.13.0+cpu and torch-npu 2.13.0rc1 |
| Kernels | FlashMLA, DeepGEMM, DeepEP, DeepSelect, TileKernels, in-tree TileLang operations |
| Constraints | XGrammar structured output; Hugging Face checkpoint/tokenizer; safetensors loading |

Evidence: [requirements](https://github.com/deepseek-ai/DeepInfer/blob/9bd9cf243fc53ef9afbf8f04d391d989117d6ab9/requirements.txt), [NVIDIA](https://github.com/deepseek-ai/DeepInfer/blob/9bd9cf243fc53ef9afbf8f04d391d989117d6ab9/requirements-nvidia.txt), [Ascend](https://github.com/deepseek-ai/DeepInfer/blob/9bd9cf243fc53ef9afbf8f04d391d989117d6ab9/requirements-ascend.txt), [manifest](https://github.com/deepseek-ai/DeepInfer/blob/9bd9cf243fc53ef9afbf8f04d391d989117d6ab9/pyproject.toml). Package availability and compatibility were not tested. This is not documented as a CPU, Apple Silicon, consumer CUDA or older NVIDIA drop-in.

## Key Features

### CPU/device overlap is a real implementation, not just a slogan

The Python entry point constructs LLMEngine, queues inputs, repeatedly steps the engine, then drains in-flight results. The C++ ZOS preparation path distinguishes fresh rows from rows remapped to previous device outputs, validates tensor metadata and uses pinned CPU tensors. Workers and graph runners connect this metadata to accelerator execution. “Zero-overhead scheduler” is the project's terminology: the intended optimization is overlapping scheduling/postprocessing with device work, not literally eliminating CPU work. [API](https://github.com/deepseek-ai/DeepInfer/blob/9bd9cf243fc53ef9afbf8f04d391d989117d6ab9/deepinfer/entrypoints/llm.py), [ZOS](https://github.com/deepseek-ai/DeepInfer/blob/9bd9cf243fc53ef9afbf8f04d391d989117d6ab9/csrc/engine/zos.cpp), [worker](https://github.com/deepseek-ai/DeepInfer/blob/9bd9cf243fc53ef9afbf8f04d391d989117d6ab9/deepinfer/worker/model_runner.py)

### Model-specific distributed execution

Attention DP / balanced CP and MoE expert parallelism are coupled to expert load balancing. FusedExperts distinguishes logical, redundant and physical experts; physical expert count must divide EP size, and local weights are partitioned accordingly. V4 attention calls DeepGEMM and FlashMLA; these are optimized specialist dependencies rather than generic Transformers dispatch. Redundant experts and topology affect both memory needs and benchmark comparability. [MoE](https://github.com/deepseek-ai/DeepInfer/blob/9bd9cf243fc53ef9afbf8f04d391d989117d6ab9/deepinfer/model_executor/models/v4_modules/moe.py), [attention](https://github.com/deepseek-ai/DeepInfer/blob/9bd9cf243fc53ef9afbf8f04d391d989117d6ab9/deepinfer/model_executor/models/v4_modules/attn.py), [EPLB](https://github.com/deepseek-ai/DeepInfer/blob/9bd9cf243fc53ef9afbf8f04d391d989117d6ab9/deepinfer/model_executor/eplb/)

### Speculation, replay and reproducibility have conditions

DSpark confidence scheduling distributes a query-token budget using cumulative draft confidence and global rank selection; the in-tree module includes a Torch reference and accelerator operation. That is a useful executable-specification pattern, but was not run here. [Confidence scheduler](https://github.com/deepseek-ai/DeepInfer/blob/9bd9cf243fc53ef9afbf8f04d391d989117d6ab9/deepinfer/model_executor/layers/tilelang_ops/schedule_mtp_varlen.py)

Decoder SWA bounded replay retains only a suffix; the deployment Q&A describes reconstruction as **approximate**, not full-context equivalence. Mask-versus-compact regression is a narrower property than proving unchanged model quality against full replay. Batch-invariant inference is documented as NVIDIA-only; deterministic sampling additionally requires a fixed sequence seed and variable-length MTP disabled. Structured-output constraints are grammar enforcement, not semantic validation or safe tool execution. [README](https://github.com/deepseek-ai/DeepInfer/blob/9bd9cf243fc53ef9afbf8f04d391d989117d6ab9/README.md), [replay checks](https://github.com/deepseek-ai/DeepInfer/blob/9bd9cf243fc53ef9afbf8f04d391d989117d6ab9/examples/yoco/README.md), [deployment Q&A](https://github.com/deepseek-ai/DeepInfer/blob/9bd9cf243fc53ef9afbf8f04d391d989117d6ab9/doc/inference_deployment_qa.md)

## Architecture

The operational path is: batch API → engine/sequence scheduler → native metadata and block management → workers/model runner → V4 attention, MoE and speculative model → sampler/structured-output masks → output processing. Python handles orchestration and configuration; C++ moves scheduling and metadata hot paths out of Python; accelerator libraries and TileLang cover numerical work. Vision preprocessing and model modules are present, but the production E/P/D routing and persistent-cache services are a separate integration burden.

The public Q&A is valuable architecture documentation, but its 155-trillion-token/day, $38/GPU-hour revenue, ~80% online/offline efficiency, large cache-retention infrastructure and internal-versus-public performance statements are **operator-reported claims**, not reproducible outcomes of this checkout. It even describes internal kernel/draft differences. Do not price a deployment by extrapolating those numbers.

## Performance Claims and Benchmark Fairness

The README charts use **4 SM100 GPUs for prefill and 64 for decode**, each within a scale-up domain. These are distinct experimental configurations, not a single four-GPU service result. The supplied sweep runner, JSONL output, configuration checks and profiler separation are good reproducibility aids. [Benchmark documentation](https://github.com/deepseek-ai/DeepInfer/blob/9bd9cf243fc53ef9afbf8f04d391d989117d6ab9/examples/README.md), [runner](https://github.com/deepseek-ai/DeepInfer/blob/9bd9cf243fc53ef9afbf8f04d391d989117d6ab9/examples/benchmark.py), [sweep](https://github.com/deepseek-ai/DeepInfer/blob/9bd9cf243fc53ef9afbf8f04d391d989117d6ab9/examples/sweep/run_sweep.sh)

Important measurement limits are directly visible in the code and documentation:

- The default fixed-length decode metric counts **1 + nextn tokens per request per step regardless of actual acceptance**. With default nextn=5, six credited tokens are not proof of six emitted accepted tokens.
- The plotter scales step rate with **τ = 1 + nextn × supplied draft_acceptance** (example 0.75), and refuses variable-length records under that plotting convention. This is an acceptance assumption, not a measured workload acceptance distribution. [Plotter](https://github.com/deepseek-ai/DeepInfer/blob/9bd9cf243fc53ef9afbf8f04d391d989117d6ab9/examples/sweep/plot_pareto.py)
- Measurement discards intervals overlapping expert-load-balancing statistics flushes and excludes warmup, regular logging and profiler overhead. This is a clean steady-state kernel/engine comparison, not inclusive production accounting. The benchmark contains explicit filtering of these intervals.
- Requests reuse a shared cached prefix; prefill and decode batch sizes are decoupled. Encoder sweeps exclude CPU preprocessing and host-to-device transport. Results therefore do not establish cold-request TTFT, network overhead, request-arrival behavior, p95/p99 latency or multitenant fairness.
- No checked-in sweep JSONL was found in the reviewed tree. Charts and scripts alone do not supply independent reruns, uncertainty estimates or version-matched competitor baselines.

A fair adoption experiment should pin framework, all kernel revisions and checkpoint revision; report GPU SKU, memory, topology, precision, context/cache-hit distribution, redundant experts and speculation settings; measure actual accepted tokens with request latency percentiles; retain LB/communication costs; and compare a version-pinned alternative under the same quality and resource budget. No such experiment was performed for this review.

The evaluation suite reports reference Pass@1 of AIME 99.9%, GPQA Diamond 93.4%, HLE-Full 42.6%. Its separation of generation and scoring, run metadata and coverage_complete check are useful. These remain author reference scores: judging uses a configurable LLM service by default, and HLE judging includes fallback text heuristics. Judge protocol/model differences and sample counts matter; this is not independent validation of model capability. [Evaluation](https://github.com/deepseek-ai/DeepInfer/blob/9bd9cf243fc53ef9afbf8f04d391d989117d6ab9/eval/README.md), [judge](https://github.com/deepseek-ai/DeepInfer/blob/9bd9cf243fc53ef9afbf8f04d391d989117d6ab9/eval/common/judge.py)

## Self-Hosting Notes

The build is not a lightweight pip-only install: it installs backend-specific dependencies, reinstalls NCCL 2.32.3 on NVIDIA, initializes pinned submodules and builds vendor wheels plus the native extension. Most runtime requirements are version pinned, but no complete hash-locked transitive environment is established. Use a disposable build environment and preserve the exact source/kernel manifest. [Build](https://github.com/deepseek-ai/DeepInfer/blob/9bd9cf243fc53ef9afbf8f04d391d989117d6ab9/build.sh), [vendor build](https://github.com/deepseek-ai/DeepInfer/blob/9bd9cf243fc53ef9afbf8f04d391d989117d6ab9/scripts/build_vendor.sh), [submodules](https://github.com/deepseek-ai/DeepInfer/blob/9bd9cf243fc53ef9afbf8f04d391d989117d6ab9/.gitmodules)

Published performance assumes expensive scale-up hardware. The Q&A recommends wide EP64–128 decode and calls 64 prefill + 64 decode GPUs its smallest **efficient production unit**; this is a production recommendation, not proof that offline inference needs 128 GPUs. Smaller examples exist. Memory fit and interconnect requirements still need measurement; no general minimum VRAM guarantee is established here.

### Security and privacy boundaries

1. **Do not expose the optional profiler.** It is disabled by default, but enabling it binds HTTP to all interfaces. GET/POST /profile has no authentication in the inspected implementation, accepts output_dir and writes trace files under process permissions. Step counts are bounded (1–50), but callers can cause profiling overhead and choose writable trace directories. Keep it disabled or on an authenticated, restricted management network. This is a static exposure finding, not a demonstrated exploit. [Profiler](https://github.com/deepseek-ai/DeepInfer/blob/9bd9cf243fc53ef9afbf8f04d391d989117d6ab9/deepinfer/engine/profile_server.py)
2. **Distributed peers are trusted.** The shared-memory/ZeroMQ broadcast path deserializes pickle, and remote publishing binds a wildcard TCP address. No transport authentication/encryption is visible in that module. Do not place these ports or writable IPC resources in an untrusted tenant network; untrusted pickle input is unsafe. [Transport](https://github.com/deepseek-ai/DeepInfer/blob/9bd9cf243fc53ef9afbf8f04d391d989117d6ab9/deepinfer/distributed/shm_broadcast.py)
3. **Checkpoint code is code.** The main LLM API defaults trust_remote_code to false and weight loading uses safetensors with shape/coverage checks, which are positives. Nevertheless, evaluation explicitly executes checkpoint encoding/encoding.py via importlib; that path is not made safe by safetensors or the API default. Default example resolution calls snapshot_download without a revision pin. Review and pin artifacts before use. [Loader](https://github.com/deepseek-ai/DeepInfer/blob/9bd9cf243fc53ef9afbf8f04d391d989117d6ab9/deepinfer/hugging_face/loading.py), [encoder import](https://github.com/deepseek-ai/DeepInfer/blob/9bd9cf243fc53ef9afbf8f04d391d989117d6ab9/eval/common/encoder.py), [example resolver](https://github.com/deepseek-ai/DeepInfer/blob/9bd9cf243fc53ef9afbf8f04d391d989117d6ab9/examples/_config.py)
4. **Offline inference is not a blanket no-egress promise.** Examples download the default model unless a local copy is selected. LLM judging sends question, reference answer and model response to the configured service; evaluation writes raw outputs to disk. Configure storage retention and egress deliberately. No judge service was called here.
5. **Bring a service security layer.** API authentication, tenant authorization, quotas, TLS termination, input bounds, cancellation policy and cache isolation belong in the missing service wrapper. Long-lived KV retention described for the production system creates privacy obligations; those retention settings are not automatically provided by this offline release.

## License, Dependencies and Model Terms

The root [LICENSE](https://github.com/deepseek-ai/DeepInfer/blob/9bd9cf243fc53ef9afbf8f04d391d989117d6ab9/LICENSE) is Apache-2.0: preserve license/notices, identify changes when redistributing, and respect patent/trademark limitations. Source attribution explicitly acknowledges vLLM derivation and SGLang/TensorRT-LLM inspiration; preserve inherited notices. The default checkpoint's public [LICENSE](https://huggingface.co/deepseek-ai/DeepSeek-V4.1-Flash-1017/blob/main/LICENSE) was separately checked on 2026-10-21 and is MIT, requiring preservation of its copyright/permission notice. This model-license check was against the live public file, not a pinned checkpoint download.

Vendor submodules are pinned gitlinks, but their complete license trees and transitive dependencies were not audited here. The framework's Apache license does not relicense CUDA/CANN tooling, other packages, model artifacts or evaluation datasets. HLE and GPQA sources may require gated access/terms; obtain those permissions independently. No source component was extracted for redistribution.

## Tests, CI and Maturity

The package labels itself **0.1.0 / Beta**. Tests cover sequence behavior, distributed broadcast/expert shuffling, samplers, EPLB, batch invariance, multimodal metadata, state cache and offline PPL/structured outputs; TileLang modules also include reference tests. Exact per-sample PPL baselines and long-context regression are useful quality signals, not a substitute for cross-platform execution.

No checked-in GitHub Actions workflow or other obvious public CI definition was found; pytest ci/ci_npu markers do not prove a publicly running pipeline. The releases endpoint returned no releases. Public API metadata at retrieval reported creation on 2026-10-16, last push 2026-10-21T04:55:44Z, 15,486 stars and 1,521 forks. Issues were disabled; the API open_issues_count includes PR-related counts and should not be presented as 165 ordinary issue reports. A very new public release and rapid popularity do not establish support quality or long-term API stability.

## Comparison

| Option | Practical distinction |
|---|---|
| DeepInfer | Closest reference for this DeepSeek engine's specialized model, kernels and scale-up design; service orchestration remains yours |
| [vLLM](https://github.com/vllm-project/vllm) | First evaluate for a general multi-model serving/API workflow; confirm exact V4.1 revision and feature support rather than assuming parity |
| [SGLang](https://github.com/sgl-project/sglang) | Compare when serving orchestration and scheduling ecosystem matter; use identical workload, hardware and accepted-token accounting |
| [TensorRT-LLM](https://github.com/NVIDIA/TensorRT-LLM) | NVIDIA-focused optimization alternative; platform portability and engine/build integration differ |

These are architectural alternatives, not benchmark rankings; their current source revisions were not independently audited in this review. DeepInfer is most compelling for inference specialists studying the released execution path or building a deliberately model-specific service. For ordinary API hosting or limited hardware, start by validating an existing serving framework's model support instead.

## Verification and Limits

Confirmed public identity and exact source SHA through unauthenticated HTTPS acquisition; inspected the source paths cited above and live public metadata/model license. No source scripts executed, dependencies installed, models fetched, tests run or accelerators used. Kernel internals in vendor submodules, numerical correctness, latency, security exploitability and full production behavior remain unverified. This is a static technical review, not a deployment certification.

---

**Attribution:** DeepSeek-AI / deepseek-ai/DeepInfer, Apache-2.0; upstream derivation acknowledged by the project. Public source and metadata retrieved 2026-10-21 UTC.
