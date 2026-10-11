# TensorFold (ashhart/TensorFold)

**Repo:** https://github.com/ashhart/TensorFold  
**License:** Apache-2.0 (earlier code retains an MIT notice; model weights have separate licenses)
**Reviewed:** 2026-10-10 (current commit `a6aa478`, v1.0.5)
**Stack:** Zig 0.17 native runtime, Metal and CUDA kernels, OpenAI- and Anthropic-compatible HTTP APIs
**What it is:** A hardware-specific local inference server for recent sparse and hybrid language models, with prompt caching, deterministic concurrent decode, multi-Mac serving, context compaction, and experimental persistent learning that writes facts into model weights.

---

## Update Notes

**Prior review:** 2026-09-27, v0.3.4.1 (`bb4b4a3`)
**Current review:** 2026-10-10, v1.0.5 (`a6aa478`)

This is a material rewrite, not a routine version bump:

- TensorFold moved from a Python/MLX + PyTorch/Triton runtime to a **132K-line native Zig engine and HTTP server**; Python is no longer required at runtime.
- The license changed from MIT to Apache-2.0 for the current native line (earlier code retains its MIT notice).
- API-key authentication, reloadable protected key files, Anthropic Messages, prompt caching, cancellation, metrics, dashboard, and native packaging were added.
- The supported matrix changed to explicitly qualified model × hardware combinations, including Nemotron 3.5 Lightning on Apple M1–M5 and NVIDIA GB10.
- **Living Weights** now teaches facts into Nemotron output-projection weights and persists them across restart and Metal/CUDA moves.
- The prior “single author, no CI, no auth” assessment is stale: PR CI and robust API-key handling now exist, and the release credits 145 public contributors.

---

## Verdict

⚠️ **Interesting — pilot it on a qualified machine; do not treat it as a general-purpose inference engine yet.** TensorFold is unusually serious about reproducible inference evidence: exact model/hardware qualification, explicit cache-state receipts, deterministic concurrency checks, conservative claims, and a native Zig server with no Python runtime. Its most novel feature, Living Weights, teaches facts into model weights and persists them across restarts and Metal/CUDA — but the project's own result is only **5/11 recall questions**, with **1/16 neighboring questions contaminated**, and there is no per-fact undo. The stable native line is days old and supports a narrow hardware/model matrix. Verified locally: the 17 model-free benchmark-evidence tests pass under Python 3.12; the full Zig suite could not run because this host lacks Xcode's optional Metal toolchain, not because of a source failure. Strong engineering and evidence discipline; narrow, new, and hardware-bound.

---

## What It Is

TensorFold is a local LLM inference runtime optimized around specific combinations rather than broad compatibility. The 1.x line loads checkpoints, tokenizes, applies chat templates, executes Metal or CUDA kernels, and serves OpenAI chat/completions plus Anthropic Messages from one native process.

The qualified 1.0 matrix centers on Nemotron 3.5 Lightning on Apple M1–M5 and NVIDIA GB10, with narrower support for Qwen3.8 Flash Next, GLM-5.3-Flash paired across two M5 Ultra Macs, and Qwen3.5-2B. Unsupported combinations are not presented as generic compatibility.

## Stack

| Layer | Technology |
|-------|------------|
| Runtime | Zig 0.17.0; native checkpoint loading, tokenization and chat templates |
| Apple backend | Metal kernels on Apple Silicon |
| NVIDIA backend | CUDA, currently qualified on GB10 |
| APIs | OpenAI chat/completions, Anthropic Messages/token counting, SSE streaming |
| Operations | Health, metrics, dashboard, cancellation, API keys, prompt cache |
| Packaging | Homebrew and release archives for macOS arm64/Linux aarch64 |
| Verification | Zig no-GPU CI, benchmark receipt tooling, model-specific qualification gates |

## Key Features

### Evidence-first performance claims

Benchmark clients retain server-reported prompt/cached/output token counts, completion state, token and output fingerprints, and distinguish `cold`, `reused`, and `unverified`. Missing usage is never coerced to zero; missing fingerprints never become an exactness pass; incomplete replies do not enter decode rates. This is better benchmark hygiene than most inference repos.

### Native, hardware-specific kernels

TensorFold does not promise every model on every accelerator. It publishes qualified model/hardware pairs and leaves slower or unequal ports outside the release. The narrow scope is a limitation, but it makes claims auditable.

### Concurrency and prefix reuse

Nemotron requests share decode rounds. The release notes report eight concurrent requests at 436.7 aggregate tok/s versus 262.8 for one request on an M5 Max, with each concurrent stream checked against its solo result. Treat these as maintainer measurements, not independently reproduced results.

### Living Weights

`--slide` extracts facts, trains small output-projection changes, validates on held-out and neighboring questions, rolls failed lessons back before writing, then persists accepted changes into safetensors. The model can be moved between qualified Metal and CUDA systems. The feature is experimental: one documented five-fact evaluation recalled 5/11 questions and contaminated 1/16 neighboring questions; accepted facts have no individual undo.

### Operational security

The server supports multiple API keys from CLI, environment, or a reloadable file. Keys are stored as SHA-256 digests and compared timing-safely. Key files are opened with `NOFOLLOW`, must be regular files unreadable by group/others, are size-limited, and fail closed after an unsafe reload. Authentication is optional, so deployments bound beyond loopback still need explicit key configuration and a TLS-aware reverse proxy.

## Architecture

The codebase separates native server concerns (`zig/src/server`), model families, Metal/CUDA backends, shared lane scheduling, checkpoint/tokenizer handling, and generated kernel assets. The build compiles Metal kernels and embeds the resulting libraries. CI runs host/no-GPU Zig tests on pull requests; performance and exactness are handled through model-specific receipts rather than pretending CPU unit tests validate accelerator behavior.

## Maturity and Risks

- **Very new native line:** v1.0.0 and current v1.0.5 arrived in October 2026.
- **Narrow matrix:** model and hardware support is explicit and limited; CUDA learning is qualified only on GB10.
- **Heavy build prerequisites:** pinned Zig 0.17 plus Xcode's separately downloaded Metal toolchain on macOS.
- **Large low-level surface:** roughly 132K Zig lines and 695 Zig files, much of it hardware/kernel-specific.
- **Living Weights is not a knowledge system:** no per-fact removal, modest recall, measurable bleed, and destructive checkpoint mutation requiring a copy.
- **Model licenses remain separate:** Apache-2.0 covers TensorFold, not downloaded weights.

## Local Verification

- Downloaded the repository-pinned Zig 0.17.0 archive and verified its documented SHA-256.
- **17/17** model-free benchmark-evidence tests passed with Python 3.12.
- `zig build test` reached Metal kernel compilation, then stopped because the host lacks Xcode's optional Metal Toolchain (`xcodebuild -downloadComponent MetalToolchain`). The Zig suite is therefore **not verified here**.
- No large checkpoint was downloaded and no throughput claim was independently benchmarked.

## Who Should Use It

Use TensorFold if you own one of the qualified Apple Silicon or GB10 configurations, run one of its supported models, and value native deployment, measurable cache/concurrency behavior, and auditable receipts. Use llama.cpp, MLX-LM, or vLLM when breadth, ecosystem integrations, commodity GPU support, or operational maturity matters more than TensorFold's specialized kernels.

---

**Attribution:** TensorFold by ash hart and contributors, Apache-2.0; performance and learning measurements are repository-reported unless explicitly marked locally verified.