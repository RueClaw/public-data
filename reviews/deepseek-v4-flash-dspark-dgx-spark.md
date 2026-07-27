# DeepSeek V4 Flash DSpark 2x DGX Spark (MiaAI-Lab/DeepSeek-v4-Flash-DSpark-2x-DGX-Spark)

**Repo:** https://github.com/MiaAI-Lab/DeepSeek-v4-Flash-DSpark-2x-DGX-Spark
**License:** MIT for repo-local scripts/docs; vLLM-derived overlays retain Apache-2.0 lineage; model weights, base images, CUDA/NCCL, FlashInfer, TileLang, and Triton have separate upstream terms
**Reviewed:** 2026-07-26
**Stack:** Docker Compose, Bash, vLLM, DeepSeek V4 Flash DSpark, NVIDIA DGX Spark/GB10, NVFP4 KV cache, FlashInfer, NCCL/RoCE
**What it is:** A self-contained two-node DGX Spark recipe for serving DeepSeek V4 Flash DSpark through vLLM TP=2 with a documented 1M-token NVFP4 KV-cache profile and concurrency validation notes.

---

## Verdict

⚠️ **Interesting, high-signal hardware recipe; not a turnkey install.** The repo is valuable because it records exact runtime knobs, launch order, cache/fabric gotchas, benchmark numbers, and the DSpark concurrency patch lineage. It is also a privileged GPU cluster deployment with host networking, InfiniBand device mounts, `--trust-remote-code`, SSH-based worker control, no CI, and hardware-specific claims that need reproduction on the target DGX Spark pair.

---

## What It Is

This repository packages a very specific serving lane: DeepSeek V4 Flash DSpark on two DGX Spark nodes, one GPU per node, tensor parallel size 2, served through an OpenAI-compatible vLLM endpoint. The current default uses Anemll's prebuilt `ghcr.io/anemll/dspark-vllm-gx10:0.1.1` image with `kv_cache_dtype=nvfp4_ds_mla`, `max_model_len=1048576`, `max_num_seqs=6`, and DSpark speculative decoding.

The README is mostly a deployment notebook turned runbook. It explains the current Anemll image path, preserves historical Stage-C build recipes, lists measured decode throughput, documents why `max_model_len` and `max_num_seqs` are ceilings rather than per-slot KV reservations, and names the common failure mode of clean direct prompts but broken agent-harness output.

The repo is most useful for operators already working with DGX Spark/GB10, vLLM, RoCE/NCCL, local Hugging Face caches, and DeepSeek V4 Flash DSpark. It is not useful as a general local-LLM starter kit.

## Stack

| Layer | Tech |
|-------|------|
| Runtime | vLLM 0.25-derived DSpark image |
| Model | `deepseek-ai/DeepSeek-V4-Flash-DSpark` |
| Hardware target | 2x NVIDIA DGX Spark / GB10 |
| Distributed serving | vLLM TP=2, host networking, NCCL/RoCE |
| Container orchestration | Docker Compose |
| Launch/control | Bash scripts over SSH/SCP |
| Optional patch | GB10 hybrid NVFP4 vLLM plugin |

## Key Features

### Validated 1M Context Profile

The repo documents a default profile for agent-serving workloads:

- `MAX_MODEL_LEN=1048576`
- `MAX_NUM_SEQS=6`
- `MAX_NUM_BATCHED_TOKENS=8192`
- `GPU_MEMORY_UTILIZATION≈0.85`
- `MTP_NUM_TOKENS=3`
- `kv_cache_dtype=nvfp4_ds_mla`

The important operational point is that KV cache is pooled. Six sessions do not reserve six million tokens up front; live tokens consume the shared pool as requests run.

### Worker-First Launch Scripts

`start-deepseek-v4-flash-dspark.sh` validates local and worker images, checks passwordless SSH, syncs compose/env/proposer files to the worker, validates both compose configs, starts the worker first, then starts the head and runs a minimal chat smoke request.

### DSpark Concurrency Patch Documentation

`docs/PATCHES.md` explains the request-stable KV slot and ragged-context fixes needed for `max_num_seqs > 1` under vLLM continuous batching. This is one of the most reusable parts of the repo because it gives a clear root-cause explanation, not just a patch blob.

### Operational Failure Notes

The README calls out model-garbling symptoms such as loops, CJK drift, and prompt/tool XML leakage, then separates direct vLLM validation from higher-level harness validation. That distinction is useful: do not blame weights until direct API prompts and concurrent direct prompts are clean.

## Architecture

The main path is:

1. Copy `.env.dspark.example` to `.env.dspark`.
2. Configure worker host, fabric IPs, NCCL/RoCE interfaces, cache paths, image, model, and vLLM bind address.
3. Pull the prebuilt DSpark vLLM image on both nodes.
4. Prepare or sync the model cache on both nodes.
5. Run `start-deepseek-v4-flash-dspark.sh`.
6. Validate with `/v1/models`, a minimal chat request, and `smoke-deepseek-v4-flash-dspark.sh`.

The historical build path remains under `recipe/` for local Stage-C image rebuilds. `scripts/verify-overlay-sources.sh` guards that Dockerfile COPY references point at files that actually exist.

## Comparison

| Aspect | This Repo | Colibri | Flash-MoE |
|--------|-----------|---------|-----------|
| Target | DeepSeek V4 Flash DSpark on 2x DGX Spark | GLM MoE on consumer hardware | Large MoE on Apple Silicon |
| Primary value | Exact deployment recipe and benchmark runbook | Inference engine design | Minimal C/Metal inference experiment |
| Operational model | Privileged Docker/vLLM cluster service | Local server/client | Local runtime experiment |
| Reuse level | Deploy only on matching hardware | More general architecture lessons | Study/experiment |

This repo is closer to an operator's field note than a product. That is a compliment, as long as readers treat its numbers as target-specific.

## Self-Hosting Notes

Use only on a lab or production cluster where the operator controls both nodes and the network boundary. The compose file uses `network_mode: host`, `ipc: host`, GPU access, and `/dev/infiniband`; the vLLM command uses `--trust-remote-code`; the default example binds the API to `0.0.0.0:8888` for multi-host clients.

Minimum hardening before real exposure:

- Bind to localhost or a private interface unless an authenticated reverse proxy is in front.
- Treat the Hugging Face model cache and vLLM KV/cache directories as sensitive.
- Pin and inspect the prebuilt image, model revision, and patch inputs.
- Reproduce direct and concurrent smoke tests on the exact hardware.
- Keep SSH worker access narrow and avoid running the scripts from untrusted paths or env files.

Verification performed for this review: `bash -n` passed for shell scripts, overlay-source verification passed, and Python compile passed for the GB10 plugin plus overlay sources. Hardware/runtime validation was not run.

---

**Attribution:** MiaAI-Lab/DeepSeek-v4-Flash-DSpark-2x-DGX-Spark, MIT plus upstream component licenses/terms
