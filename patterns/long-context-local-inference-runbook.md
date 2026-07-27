# Long-Context Local Inference Runbook

> **Source:** [MiaAI-Lab/DeepSeek-v4-Flash-DSpark-2x-DGX-Spark](https://github.com/MiaAI-Lab/DeepSeek-v4-Flash-DSpark-2x-DGX-Spark)
> **License:** MIT for repo-local scripts/docs; upstream model/runtime components have separate terms
> **Extracted:** 2026-07-26

## Pattern

Package a local inference deployment as an executable runbook: env template, compose file, start/stop/status/log scripts, cache-prep script, direct smoke test, benchmark evidence, and known failure modes in one repo.

This is especially useful for long-context multi-node LLM serving, where the real knowledge is not just "run vLLM" but the exact relationship among context ceiling, concurrency ceiling, KV pool size, fabric settings, model cache placement, and client validation.

## What To Include

- `.env.example` with explicit hardware, fabric, cache, model, and serving knobs.
- `docker-compose.yml` or equivalent runtime manifest.
- `start`, `stop`, `status`, and `logs` scripts that operate on every node involved.
- A cache-prep script that downloads/verifies model artifacts before serving.
- A direct API smoke test that avoids the agent/client layer.
- Benchmarks that separate prefill, first-token, per-stream decode, and aggregate decode.
- A troubleshooting section that distinguishes runtime failures from client/harness failures.

## Why It Works

Long-context inference failures are often configuration failures: wrong NIC, stale model cache, silent fallback model, inherited sampling defaults, insufficient KV pool, or a worker using a different image. A runbook repo keeps the operator decisions visible and gives future maintainers a concrete validation ladder.

The key debugging order is:

1. Direct model API prompt is clean.
2. Concurrent direct model API prompts are clean.
3. Client or agent harness prompt is clean with fallback disabled.

Only after those pass should higher-level agent behavior be blamed on prompts, tools, or orchestration.

## Adaptation Guide

1. Record the exact model id, image digest/tag, hardware, and fabric assumptions.
2. Make local and worker config explicit rather than relying on host defaults.
3. Keep node-specific overrides out of shared env values when they can differ after reboot.
4. Validate the rendered runtime config before starting containers.
5. Start distributed workers before the head process when the runtime expects them.
6. Run direct smoke tests before any application or agent harness tests.
7. Publish benchmark numbers with enough context to reproduce or reject them.

## Caveats

- Do not expose a host-networked inference server without authentication and network controls.
- Treat model caches, prompt/KV caches, and logs as sensitive.
- Hardware-specific throughput numbers rarely transfer cleanly to a different image, model revision, driver, or fabric.
- `--trust-remote-code` and prebuilt images require the same supply-chain scrutiny as application code.
