# FreeToken Review

Source: https://github.com/FlashML-org/FreeToken  
Author: FlashML-org  
License: Apache-2.0  
Reviewed: 2026-08-23  
Commit reviewed: `184a4f1` (`build(kernel-cache): add sm_80 (A100/A800) to default arches (#75)`)

## Verdict: ✅ Deploy candidate, for the right machine

FreeToken is an edge-native MoE inference runtime for serving frontier-scale open-weight models on local NVIDIA hardware. It is not a casual laptop install: the documented path targets Linux x86_64, NVIDIA driver r580+, CUDA 13, Python 3.10+, and very large model checkpoints. Inside that envelope, it is one of the more substantial local-MoE serving projects in the current open ecosystem.

The repository is fresh and beta-labeled, but it has serious signals: Apache-2.0 licensing, active development, extensive Python/CUDA test coverage, PyPI-oriented wheel workflows, OpenAI- and Anthropic-compatible HTTP APIs, and a focused runtime architecture around CPU/GPU MoE offload rather than a thin wrapper around an existing server.

## What It Is

FreeToken is a Python/PyTorch/CUDA serving engine for mixture-of-experts models. Its stated goal is to run very large sparse models locally by keeping dense/shared work on the GPU while placing expert weights across GPU cache, host RAM, and CPU execution paths.

The public API surface is familiar:

- `ft serve` starts the API server, defaulting to `127.0.0.1:1919`.
- `/v1/chat/completions`, `/v1/responses`, and `/v1/models` provide OpenAI-compatible endpoints.
- `/v1/messages` and `/v1/messages/count_tokens` provide Anthropic-compatible endpoints.
- `ft shell` gives a terminal chat interface.
- `ft launch` can configure agent CLIs against a local FreeToken server and includes a `--dry-run` mode.
- `ft checkpoint` converts Hugging Face safetensors checkpoints into FreeToken's FTW format.
- `ft bench bw` measures CPU memory bandwidth, PCIe copy bandwidth, and real MoE kernels to choose hybrid/offload behavior for the machine.

## Stack

- Python package under `python/freetoken`
- PyTorch `>=2.11,<2.12`, CUDA 13 wheel indexes, Triton `3.6.0`
- FastAPI/Uvicorn server
- C++/CUDA extensions for pinned tensors and CPU MoE
- FlashInfer and SGLang kernels as optional acceleration dependencies
- TVM FFI-based prebuilt kernel-cache package
- GGUF, Hugging Face Hub, ModelScope, safetensors, and Transformers 5.x integrations

The source tree is broad: attention backends, checkpoint conversion, daemon/supervisor code, distributed helpers, engine/cache budget logic, KV cache implementations, model loaders, MoE backends, scheduler, tokenizer workers, OpenAI/Anthropic protocol models, and server control APIs.

## Notable Design Choices

### Hardware-aware MoE backend selection

The `ft bench bw` path is more than a synthetic benchmark. It measures host memory bandwidth, PCIe transfer bandwidth, CPU MoE kernels, offload gather behavior, and overlapped contention. The runtime can then pick between `hybrid` and `offload` behavior based on measured local hardware rather than only model metadata.

### Explicit MoE/KV cache budgeting

`engine/cache_budget.py` keeps the GPU memory split as testable integer arithmetic: model weights, fixed cache, MoE expert slots, KV pages, memory ratio, and prefill overlap are planned before allocation. That is the right shape for a runtime that needs to avoid CUDA OOM surprises while dynamically moving budget between expert cache and KV memory.

### Multiple expert storage and compute paths

The MoE code supports BF16, NVFP4, MXFP4, FP8 block formats, DeepSeek FP4, Q4_0 GGUF paths, CPU execution, GPU fused kernels, host pinned banks, and offload caches. Adding a new expert format is intentionally described as touching the bank schema, provider, and expert GEMM dispatch.

### Agent-compatible serving surface

The OpenAI/Anthropic endpoints make FreeToken usable as a drop-in local model endpoint for existing clients. `ft launch` is unusually direct about agent tooling: it can write client configuration for several command-line agents, uses local placeholder API keys, normalizes `0.0.0.0` to a loopback connection target, and can show changes with `--dry-run`.

### Release workflow hygiene

The GitHub workflows build runtime and kernel-cache wheels on self-hosted GPU builders, but publishing is separated onto hosted runners with gated environments and tokens. The release workflow comments explicitly avoid PR triggers for self-hosted runners. Recent workflow runs were green at review time.

## Model Coverage

The docs list support for families including:

- DeepSeek-V4 Flash
- GLM-5.2 / GLM-4.7
- Qwen3.6 MoE and dense variants
- Qwen3-MoE
- gpt-oss 120B / 20B
- Gemma-4
- MiniMax-M2.5
- Muse-Glimmer

Supported formats include MXFP4, NVFP4, FP8, BF16, and GGUF-related paths, depending on model family and backend.

## Strengths

- Real runtime implementation, not just a launch recipe.
- Apache-2.0 license.
- Local-first serving with standard OpenAI/Anthropic API compatibility.
- Strong fit for sparse MoE models that are too large for full GPU residency.
- Hardware calibration path for backend selection.
- Good decomposition across model loading, cache budget, KV cache, scheduler, server, and kernels.
- Tests are not an afterthought: the repo has 328 Python source files and 98 Python test files across daemon, engine, kernels, KV cache, models, MoE, scheduler, server, and tokenizer areas.
- CI/release workflows show active wheel publication and self-hosted runner risk awareness.

## Caveats

- Very new project: the GitHub repository was created in July 2026 and is still beta software.
- Local validation was not run in this review because the review machine is not the target Linux/CUDA 13/NVIDIA environment.
- The dependency stack is extremely fast-moving: PyTorch 2.11 CUDA 13, Triton 3.6, Transformers 5.x, FlashInfer, SGLang kernels, and TVM FFI.
- First install/build can require `nvcc` and CUDA toolkit parity with the installed PyTorch CUDA version.
- The README advertises a desktop app download, but the reviewed repository is the runtime source; treat the desktop app as a separate artifact unless its source and release chain are reviewed separately.
- `ft launch` intentionally writes agent/client configuration and can install third-party CLIs. Use `--dry-run` first.
- Keep the API server bound to loopback or place it behind real auth. The default examples use `127.0.0.1`, which is the right default posture.

## How I Would Use It

For a local inference lab with a modern NVIDIA GPU and enough host RAM, FreeToken is worth piloting as a local MoE endpoint. Start with the documented quickstart, run `ft bench bw`, serve one supported model on loopback, and compare it against vLLM/SGLang/llama.cpp for the same workload.

For production or internet-exposed serving, I would wait for more release maturity, pin exact wheels, isolate model weights and config state, front it with authentication, and run a workload-specific soak test before relying on it.

## Related Projects

- vLLM and SGLang: more mature general-purpose serving stacks.
- llama.cpp: broader CPU/consumer-device ecosystem, especially dense GGUF models.
- LMCache: cache-management layer for multi-runtime serving.
- MoonEP: expert-parallel communication reference for larger distributed MoE systems.
- Colibri: another local MoE serving effort with a broader accelerator story.

FreeToken's distinct niche is local sparse-MoE serving with explicit CPU/GPU offload, cache budgeting, and agent-friendly OpenAI/Anthropic endpoints.

## Attribution

This review is based on the public `FlashML-org/FreeToken` repository and its documentation. FreeToken is Apache-2.0 licensed. The repository acknowledges ideas and code from mini-sglang, SGLang, vLLM, FlashInfer, flash-linear-attention, LightLLM, and llama.cpp; downstream use should preserve those upstream attributions where applicable.
