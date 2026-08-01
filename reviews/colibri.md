# Colibri (JustVugg/colibri)

**Repo:** https://github.com/JustVugg/colibri  
**License:** Apache-2.0; permissive reuse with attribution and notice preservation  
**Reviewed:** 2026-08-01
**Stack:** C, OpenMP, Python stdlib gateway/tools, CUDA/HIP/Metal/Vulkan optional backends, safetensors/model containers, React/Vite dashboard, Docker, Tauri preview
**What it is:** Colibri is a local inference engine that runs very large MoE models by treating NVMe, RAM, and VRAM as one managed memory hierarchy, keeping dense/shared paths resident while streaming, caching, and pinning routed experts.

---

## Update Notes

Checked 2026-08-01 against the 2026-07-11 review. Prior review covered `1bdaeee` before tagged releases. Current HEAD is `b085b48` / `v1.4.0`.

Material changes:

- project scope expanded from GLM-5.2-focused runtime to four model families: GLM-5.2, Inkling, Kimi K3, and OLMoE;
- releases v1.0.0 through v1.4.0 added CUDA/HIP/Metal/Vulkan paths, Anthropic Messages API compatibility, tool-calling fixes, partial mirror planning, multi-drive layouts, grammar/response-format support, and a much larger test matrix;
- release archives now ship all engine binaries, not just GLM, and verify archive behavior in CI;
- docs now include quickstart, API, benchmark, tuning, Docker, Windows, Vulkan, Metal, CUDA/HIP, format registry, and multilingual READMEs;
- maturity jumped sharply: 21,778 stars, 2,304 forks, 49 open issues at check time.

---

## Verdict

✅ **Deploy candidate for serious local-inference experiments, still not production serving.** Colibri has moved from a clever single-model systems experiment into an active local MoE inference platform. The architecture is still attractive: model structure drives placement, memory tiers are explicit, compatibility APIs reject unsupported features, and performance claims are increasingly tied to measured hardware. Caveats remain substantial: it is young, model-specific per engine, hardware-sensitive, the web lockfile is currently out of sync, and full-model validation still requires enormous downloads and target hardware.

---

## What It Is

Colibri runs frontier-scale MoE models by refusing to treat total parameter count as a single residency requirement. Dense weights, attention, shared experts, KV state, and hot routed experts stay in fast memory. Cold routed experts live on storage and are staged only when the router selects them.

The original headline was GLM-5.2 744B on a small machine. Current Colibri is broader:

- **GLM-5.2:** 744B MoE, the original path.
- **Inkling:** 975B total / 41B active, with dense-set quantization so it can answer on a small host.
- **Kimi K3:** 2.8T total / 104B active preview path, with native QAT MXFP4 routing work and tokenizer integration.
- **OLMoE:** smaller 7B family for testing and validation.

The practical promise is not high throughput on tiny hardware. It is that large sparse models can become inspectable, measurable, and sometimes usable on hardware that could never load them monolithically.

## Stack

| Layer | Tech |
|-------|------|
| Core engines | C, OpenMP, portable scalar/SIMD kernels |
| Model families | GLM-5.2, Inkling, Kimi K3, OLMoE |
| GPU backends | CUDA, HIP/ROCm shim, Metal, Vulkan 1.2 compute |
| Weight formats | int4, grouped int4, int3-g64, E8/IQ3, FP8 passthrough, MXFP4 paths |
| Storage tiers | NVMe streaming, mirror/shard split support, `O_DIRECT`/platform probes |
| API | Python stdlib OpenAI-compatible and Anthropic Messages endpoints |
| UI | React/Vite dashboard with chat, profiling, Brain, and expert atlas views |
| Packaging | release archives, SHA256 sums, Docker docs, Tauri preview, CI/release workflows |
| Tests | C tests, Python stdlib tests, web tests/build, syntax CI for GPU paths |

## Key Features

### Unified Memory Hierarchy

The core pattern is unchanged and stronger: VRAM, RAM, and NVMe are all placement tiers for the same model. Limited fast memory should change speed, not router semantics or model precision.

Colibri now supports learned hot expert histories, RAM/VRAM pinning, partial mirror planning, multi-drive split layouts, direct-I/O probing, and GPU-specific resident tiers. That turns "disk-streamed MoE" into a general placement problem rather than a one-off cache.

### Multiple GPU Paths

Since the earlier review, Colibri added or expanded:

- CUDA multi-GPU expert tiers, dense paths, resident pipelines, compressed tiers, and staging fixes;
- HIP/ROCm through a compatibility header over the CUDA-like backend surface;
- Metal grouped-int4 and E8/IQ3 expert decode on Apple Silicon;
- Vulkan expert tier, dense projections, and MLA attention core for any Vulkan 1.2 GPU, including older AMD cards through Mesa/RADV.

The repo is careful to label hardware caveats: ReBAR matters for discrete Vulkan cards, GPU clocks can skew comparisons, and CPU kernels can beat a GPU tier when residency is low or CPU SIMD is strong.

### Compatibility APIs For Agents

The server now has more than a basic OpenAI-compatible path. It supports:

- Chat Completions and legacy completions;
- OpenAI-style tools and tool choice;
- SSE streaming;
- explicit errors for unsupported image/audio/logprob/penalty features;
- bounded queueing;
- localhost default bind, optional API key, exact CORS/host allowlists;
- Anthropic `/v1/messages`, including Claude Code-oriented system/tool block handling.

The most important fix is behavioral: overlong coding-agent prompts are now rejected instead of silently truncating away the user turn or tool instructions.

### Release And Test Maturity

The release process now builds multiple platforms and verifies packaged archives can actually locate the engines and dashboard. That was not cosmetic: v1.4.0 release notes say earlier archives could not run Kimi K3 or Inkling because only the GLM engine shipped.

Local verification on 2026-08-01:

- `make -C c check` passed on macOS: compiled C test set plus Python unittest suite, 275 Python tests reported, 15 skipped.
- `npm --prefix web ci` failed because `web/package.json` and `web/package-lock.json` are out of sync (`web@0.1.0` missing from the lockfile).
- After `npm --prefix web install`, `npm --prefix web run build` passed.
- `npm --prefix web test` passed: 3 files, 18 tests.
- `npm --prefix web audit --omit=dev` reported one high-severity `postcss` advisory.

Full inference and GPU/runtime validation were not run; they require model downloads in the hundreds of GB and matching hardware.

## Caveats

- **Still not a production serving stack.** It is a research-grade local engine with queueing and APIs, not a hardened multi-tenant service.
- **Hardware results are specific.** NVMe controller, RAM capacity, CPU SIMD, GPU residency, ReBAR, OS I/O behavior, and cache warmth all change outcomes.
- **Kimi K3 is still preview-like.** v1.3.0 notes say full-model generation was gated by hardware/storage access when introduced.
- **Frontend dependency hygiene needs attention.** `npm ci` currently fails and production audit reports a high `postcss` advisory after lock regeneration.
- **The model-file threat model is real.** The changelog now calls out parser/container hardening because model files can come from untrusted mirrors.
- **Agent use needs expectation setting.** A disk-streaming 744B model can spend an hour prefilling a large coding-agent tool catalog before the first token.

## Comparison

| Aspect | Colibri | llama.cpp-class runtimes | vLLM/SGLang | LMCache |
|--------|---------|--------------------------|-------------|---------|
| Main job | Run oversized sparse MoEs through tiered placement | Broad local model support | High-throughput server inference | KV-cache reuse layer |
| Memory strategy | NVMe/RAM/VRAM hierarchy for routed experts | Fit quantized model locally | Fit/partition model in server hardware | Cache KV across requests |
| Model breadth | Few huge MoE families | Very broad | Broad server models | Engine-adjacent |
| Strength | Huge-model feasibility and measurement discipline | Maturity and ecosystem | Throughput and batching | Serving economics |
| Caveat | Young, hardware-specific, slow when cold | Not designed around 2.8T disk-streamed MoE | Hardware-hungry | Not an inference engine |

## Self-Hosting Notes

Good first path:

1. Use a release archive or build with `make -C c check`.
2. Download the recommended group-scaled model container to a local NVMe.
3. Run `./coli doctor` and `./coli plan` before inference.
4. Keep `coli serve` bound to localhost unless `COLI_API_KEY`, exact allowed hosts, and CORS policy are set deliberately.
5. Treat benchmarks as hardware reports: include model/container, commit, command, cache state, token rate, TTFT, expert hit rate, bytes read, and quality check.

The previous review's extracted pattern still stands, but it now deserves the broader name: disk-tiered MoE inference is really heterogeneous model-placement over storage, RAM, and accelerators.

---

**Attribution:** JustVugg/colibri, Apache-2.0
