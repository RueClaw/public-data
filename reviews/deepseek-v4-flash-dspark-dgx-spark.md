# DeepSeek V4 Flash 0731 DSpark 2x DGX Spark (MiaAI-Lab/DeepSeek-v4-Flash-DSpark-2x-DGX-Spark)

**Repo:** https://github.com/MiaAI-Lab/DeepSeek-v4-Flash-DSpark-2x-DGX-Spark  
**License:** MIT for repo-local scripts/docs; vLLM-derived overlays retain Apache-2.0 lineage; model weights, base images, CUDA/NCCL, FlashInfer, TileLang, and Triton have separate upstream terms  
**Reviewed:** 2026-08-01  
**Stack:** Docker Compose, Bash, vLLM, DeepSeek V4 Flash 0731, NVIDIA DGX Spark/GB10, NVFP4 KV cache, DSpark speculative decoding, FlashInfer, NCCL/RoCE  
**What it is:** A self-contained two-node DGX Spark recipe for serving DeepSeek V4 Flash 0731 through vLLM TP=2 with a documented 1M-token NVFP4 KV-cache profile, benchmark artifacts, and DSpark/encoding compatibility notes.

---

## Update Notes

Checked 2026-08-01 against the prior 2026-07-26 review. Current HEAD is `914c35b` (`Report prompt caching details (#15)`), with material changes since the prior review:

- default checkpoint moved to `deepseek-ai/DeepSeek-V4-Flash-0731` and served model name `deepseek-v4-flash-0731`;
- repo now documents the 0731 encoding/parser/tool-call compatibility layer and text-only boundary;
- default `MTP_NUM_TOKENS` is 5, `GPU_MEMORY_UTILIZATION` is 0.80, and regular CUDA graphs are explicitly retained with `VLLM_USE_BREAKABLE_CUDAGRAPH=0`;
- new 0731 benchmark docs, screenshot, Python sweep script, and raw JSON results were added;
- Anemll-vs-Stage-C environment-variable docs and a Stage-C override compose file were added;
- start scripts gained vLLM host/port overrides, worker-specific NCCL overrides, and RoCEv2 GID auto-resolution.

---

## Verdict

⚠️ **Interesting, better documented after the 0731 update, still not turnkey.** The repo has become a more complete operator runbook: it now pins the DeepSeek V4 Flash 0731 lane, records live KV/concurrency evidence, publishes sweep results, and separates Anemll-safe env knobs from Stage-C overlay knobs. It remains a privileged two-node GPU deployment with host networking, InfiniBand mounts, `--trust-remote-code`, SSH/SCP worker control, no CI, and hardware-specific performance claims that need reproduction on the target cluster.

---

## What It Is

This repository packages a very specific serving lane: DeepSeek V4 Flash 0731 on two DGX Spark nodes, one GPU per node, tensor parallel size 2, served through an OpenAI-compatible vLLM endpoint. The current default uses Anemll's prebuilt `ghcr.io/anemll/dspark-vllm-gx10:0.1.1` image with `deepseek-ai/DeepSeek-V4-Flash-0731`, `kv_cache_dtype=nvfp4_ds_mla`, `max_model_len=1048576`, `max_num_seqs=6`, `MTP_NUM_TOKENS=5`, FlashInfer B12X MoE, prefix caching, chunked prefill, async scheduling, and DSpark speculative decoding.

The repo is partly a deployment kit and partly an evidence ledger. It keeps env templates, compose files, worker-first launch scripts, cache-prep/status/log/smoke scripts, benchmark tooling, raw result JSON, current 0731 docs, historical preview numbers, and failure-mode triage in one place.

It is most useful for operators already working with DGX Spark/GB10, vLLM, RoCE/NCCL, local Hugging Face caches, and DeepSeek V4 Flash. It is not a general local-LLM starter kit.

## Stack

| Layer | Tech |
|-------|------|
| Runtime | Anemll `ghcr.io/anemll/dspark-vllm-gx10:0.1.1` DSpark/GX10 image |
| Model | `deepseek-ai/DeepSeek-V4-Flash-0731`, tested revision `9e165c30e2704aec5d9d593cce3eebd58bbef1cb` |
| Hardware target | 2x NVIDIA DGX Spark / GB10 |
| Distributed serving | vLLM TP=2, host networking, NCCL/RoCE, explicit per-node `VLLM_HOST_IP` |
| Container orchestration | Docker Compose, optional Stage-C override |
| Launch/control | Bash scripts over SSH/SCP/rsync |
| Benchmarks | `scripts/benchmark-0731.py`, `results/deepseek-v4-flash-0731-2x-dgx-spark.json`, README tables |
| Optional patch | GB10 hybrid NVFP4 vLLM plugin |

## Key Features

### Updated 0731 1M Agent-Serving Profile

The default profile now targets the 0731 GA checkpoint:

- `DSPARK_MODEL=deepseek-ai/DeepSeek-V4-Flash-0731`
- `SERVED_MODEL_NAME=deepseek-v4-flash-0731`
- `MAX_MODEL_LEN=1048576`
- `MAX_NUM_SEQS=6`
- `MAX_NUM_BATCHED_TOKENS=8192`
- `GPU_MEMORY_UTILIZATION=0.80`
- `MTP_NUM_TOKENS=5`
- `VLLM_USE_BREAKABLE_CUDAGRAPH=0`
- `kv_cache_dtype=nvfp4_ds_mla`

The MTP change is material: the checkpoint `dspark_block_size` is 5, so `k < 5` can truncate draft blocks or be rejected depending on the vLLM/runtime version.

### 0731 Encoding and Tool-Call Compatibility

The 0731 checkpoint includes an `encoding/encoding_dsv4.py` package rather than a normal Jinja chat template. The compose command installs that encoder into vLLM when needed and patches older tokenizer wrappers so `low` reasoning effort stays low instead of being promoted to high.

The docs explicitly call out validation for role boundaries, reasoning separation, and OpenAI function arguments. That is the right level of caution: successful weight loading does not prove chat/tool compatibility.

### Published Benchmark Evidence

The update adds a benchmark script and raw JSON result file. The headline 0731 evidence includes:

- 900K request: 899,994 prompt tokens, 1,028.85 s TTFT, roughly 874.8 prefill tok/s, requested sentinel returned;
- official decode capture: x1 82.4 tok/s, x2 98.0 aggregate tok/s, x3 134.6 aggregate tok/s, x4 120.4 aggregate tok/s with a 5.36 s TTFT jump;
- sweep table over 256, 2K, 8K, 32K, and 128K prompt lengths at concurrency 1/2/4/6;
- regular CUDA graph opt-out numbers showing decode improvement versus Anemll's automatic breakable-graph path.

Those are still operator-supplied results, not independently reproduced benchmarks, but the raw artifact is a meaningful improvement over prose-only claims.

### Environment-Lane Split

`docs/ENVS.md` and `docker-compose.stage-c.override.yml` separate Anemll `0.1.1` safe knobs from Stage-C-only overlay kill switches. This matters because vLLM warns on unknown `VLLM_*` keys, and older recipe variants carried many Stage-C-specific DSpark knobs.

The repo now says clearly: unknown env registration on Anemll does not mean the DSpark/Keys code path is absent, and setting Stage-C-only keys on Anemll does not enable those switches.

### Worker and Fabric Improvements

The start script now supports temporary `--host` / `--port` overrides, worker-specific NCCL interface/HCA/GID settings, and RoCEv2 GID auto-resolution from sysfs. That is practical DGX Spark work: one shared GID literal across both ranks can wedge NCCL after reboot or link changes.

## Architecture

The main operator path is:

1. Copy `.env.dspark.example` to `.env.dspark`.
2. Configure worker host, node ranks, RoCE/NCCL interfaces, cache paths, model, image, bind host/port, and per-node `VLLM_HOST_IP`.
3. Pull the Anemll DSpark image on both nodes.
4. Prepare or sync the 0731 Hugging Face cache on both nodes.
5. Run `start-deepseek-v4-flash-dspark.sh`.
6. Validate `/v1/models`, direct chat smoke, concurrent direct prompts, and only then the agent/client harness.

The historical Stage-C path remains under `recipe/` and can be enabled with a separate compose override. That separation is cleaner than the prior mixed env surface.

## Comparison

| Aspect | This Repo | Colibri | Flash-MoE |
|--------|-----------|---------|-----------|
| Target | DeepSeek V4 Flash 0731 on 2x DGX Spark | GLM MoE on consumer hardware | Large MoE on Apple Silicon |
| Primary value | Exact deployment recipe, env lane split, 0731 benchmark evidence | Inference engine design | Minimal C/Metal inference experiment |
| Operational model | Privileged Docker/vLLM cluster service | Local server/client | Local runtime experiment |
| Reuse level | Deploy only on matching hardware | More general architecture lessons | Study/experiment |

This repo is closer to an operator's field notebook than a product. The August update makes the notebook more reproducible and better labeled.

## Self-Hosting Notes

Use only where the operator controls both nodes and the network boundary. The compose file uses `network_mode: host`, `ipc: host`, all GPUs, `/dev/infiniband`, host-mounted caches, and `--trust-remote-code`. The example binds `VLLM_HOST=0.0.0.0` for multi-host clients.

Minimum hardening before real exposure:

- bind to localhost/private interfaces or put an authenticated reverse proxy in front;
- treat Hugging Face caches, prompt/KV caches, vLLM logs, and benchmark artifacts as sensitive;
- pin and inspect the prebuilt image, model revision, encoder file, and Stage-C override inputs;
- keep SSH worker access narrow and avoid running scripts from untrusted paths or env files;
- validate direct vLLM behavior before debugging agent-client replay or fallback settings.

Verification performed for this check-in:

- `bash -n` passed for all top-level helper scripts;
- `scripts/verify-overlay-sources.sh` passed;
- `python3 -m compileall` passed for benchmark script, GB10 plugin, and overlay Python sources;
- `docker compose config` could not be run because Docker is not installed in this environment;
- hardware/runtime validation was not run.

---

**Attribution:** MiaAI-Lab/DeepSeek-v4-Flash-DSpark-2x-DGX-Spark, MIT plus upstream component licenses/terms
