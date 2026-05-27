# Tolerance-Routed GPU Operator Dispatch

**Source:** FlashML-org/flashlib
**Repo:** https://github.com/FlashML-org/flashlib
**License:** Apache-2.0
**Reviewed:** 2026-05-27

## Pattern

Expose a numeric tolerance budget at the public API boundary, then route to the fastest kernel or algorithm variant whose expected residual stays inside that budget. Pair the runtime dispatcher with a lightweight cost API that returns predicted runtime, FLOPs, memory traffic, peak memory, launch count, confidence, and sub-operation breakdowns.

## Why It Matters

Many production ML and data workflows do not require exact fp32 everywhere. Retrieval, clustering, dimensionality reduction, semantic caching, and noisy feature pipelines often tolerate approximate residuals if the speed or memory savings are large enough. Making tolerance explicit turns precision from a hidden implementation choice into a scheduling parameter.

This is especially useful for agentic or workflow orchestration systems. A planner can ask "what will this cost on H100/H200 at tolerance X?" before launching work, then choose between exact, mixed-precision, approximate, or fallback paths.

## Implementation Shape

1. Public operator accepts `tol=None | float`.
2. Runtime dispatcher maps `(shape, dtype, hardware, tol, optional backend)` to a concrete variant.
3. Each variant declares or estimates expected residual, runtime, memory traffic, and launch behavior.
4. Compound operators cascade the same tolerance to sub-operations.
5. A pure planning API mirrors the runtime dispatcher and returns structured estimates without running kernels.
6. Tests verify both reference correctness and cross-backend parity for the same input.

Representative source locations:

- `flashlib/linalg/gemm/route.py` — tolerance-dominant GEMM variant selection.
- `flashlib/info/registry.py` — op and variant registry.
- `flashlib/info/dispatch.py` — estimate/recommend/pareto/compare entry points.
- `flashlib/info/estimate.py` — structured estimate dataclass.
- `flashlib/primitives/*/cost.py` — per-operator cost models.
- `tests/test_backend_parity.py` — parity tests across enhanced kernels.

## Design Notes

- Keep runtime dispatch and estimate dispatch in sync. If they drift, planners will make wrong choices.
- Treat the cost model as a contract, not only documentation.
- Report confidence tiers such as calibrated, measured, roofline, or heuristic.
- Make exact mode the default. Approximation should require an explicit tolerance or backend.
- Make backend overrides available for benchmarking and debugging.
- Include CPU or reference fallbacks where practical, but make platform limitations explicit.

## Cautions

The planning API must truly avoid importing heavyweight runtime stacks if it is advertised as GPU-less or agent-friendly. In FlashLib 0.1.0, `import flashlib.info` is lazy, but some `info.estimate(...)` calls still resolve through primitive package initializers that import torch-backed modules. That is fixable by moving cost models under import-light namespaces or avoiding eager runtime imports in primitive `__init__.py` files.

## Attribution

Pattern extracted from FlashML-org/flashlib, Apache-2.0.
