# FlashLib (FlashML-org/flashlib)

**Repo:** https://github.com/FlashML-org/flashlib
**License:** Apache-2.0, permissive for use, modification, and extraction with attribution
**Reviewed:** 2026-05-27
**Stack:** Python, PyTorch, Triton, NVIDIA CUTLASS/CuteDSL, CUDA, NumPy, Numba, pytest
**What it is:** A GPU library for fast classical machine-learning operators, exposing flash-style kernels for clustering, nearest-neighbor search, decomposition, manifold learning, regression, classification, and multi-precision GEMM.

---

## Verdict

⚠️ **Interesting, but alpha.** FlashLib is a serious systems-research implementation with unusually useful ideas: fused GPU formulations for classical ML, tolerance-driven precision routing, and a cost API that higher-level schedulers can query before running GPU work. It is too new to treat as infrastructure without local validation, and the advertised torch-free info boundary has a real packaging/import caveat.

---

## What It Is

FlashLib targets the classical ML operators that increasingly sit in online paths around LLM and agentic systems: KMeans, KNN, PCA, SVD, DBSCAN, HDBSCAN, UMAP, t-SNE, regression, RandomForest, MultinomialNB, StandardScaler, eigensolvers, and GEMM variants. The project frames these as millisecond-budget building blocks for retrieval, semantic caching, clustering, verification, dimensionality reduction, and scientific feedback loops.

The implementation applies the same spirit as FlashAttention to non-transformer operators: avoid materializing huge intermediates, keep reductions and running top-k/minima close to registers or shared memory, and route between kernels based on workload and hardware. The first release is Python-facing but CUDA/NVIDIA-centered, with Triton as the broad backend and CuteDSL/CUTLASS paths for Hopper-era kernels.

The repo is very fresh: created 2026-05-26, version `0.1.0`, 142 stars and 4 forks at review time, no open issues, and a latest commit of `bd2896f` on 2026-05-26. Treat the benchmark claims as promising but still requiring reproduction on target hardware.

## Stack

| Layer | Tech |
|-------|------|
| Package/runtime | Python 3.9+, setuptools |
| Tensor/runtime dependency | PyTorch 2.0+ |
| GPU kernels | Triton 3.6+, NVIDIA CUTLASS DSL / CuteDSL |
| Numeric/support deps | NumPy, Numba, tqdm |
| API style | Top-level `flash_*` functions plus sklearn-style classes |
| Tests | pytest, CUDA-gated primitive and backend parity tests |
| Benchmarks | Local scripts comparing FlashLib, cuML, sklearn, Torch |
| Target platform | Linux, NVIDIA CUDA GPUs |

## Key Features

### Broad Classical ML Primitive Surface

The package exports 15 high-level primitives plus lower-level linear algebra and kernel building blocks. The top-level API includes `flash_kmeans`, `flash_knn`, `flash_pca`, `flash_dbscan`, `flash_hdbscan`, `flash_umap`, `flash_tsne`, regression primitives, classification primitives, and sklearn-style wrappers such as `KMeans`, `PCA`, `DBSCAN`, and `NearestNeighbors`.

### Flash-Style Reformulations

The main design win is not just "GPU implementation"; it is reformulating the operator so the expensive intermediate is never materialized. KNN and KMeans both avoid full pairwise/cross matrices in HBM. PCA routes through covariance/eigensolver/GEMM subops, and density/manifold algorithms compose KNN, graph, MST, and optimization kernels.

### Tolerance-Driven Dispatch

FlashLib exposes a `tol` argument for workloads where exact fp32 is unnecessary. GEMM routing chooses among fp32, tf32, bf16, fp16, multi-pass precision emulation, and Ozaki-style variants based on residual tolerance. Higher-level operators cascade the tolerance into sub-operations.

### Informative Cost API

`flashlib.info` provides `estimate`, `compare`, `summary`, `pareto`, and `variants` APIs. The idea is valuable: a planner can ask for predicted runtime, FLOPs, HBM bytes, memory peak, kernel count, confidence, and sub-op breakdown before launching GPU work.

Important caveat: `import flashlib.info` itself is lazy, but `info.estimate("kmeans", ...)` currently resolves through primitive package initialization that imports torch-backed runtime dispatchers. In a local Python 3.14 environment without torch, `info.list_ops()` worked but `info.summary("kmeans", ...)` failed with `ModuleNotFoundError: No module named 'torch'`. That weakens the README claim that the informative API is useful in a GPU-less environment without importing torch/triton/cutlass.

## Architecture

The source is organized by algorithm family:

- `flashlib/primitives/*` holds high-level ML operators with `impl.py`, `cost.py`, and backend folders.
- `flashlib/linalg/*` holds GEMM, covariance/Gram products, eigensolvers, polar decomposition, QR/cholesky/orthonormalization helpers.
- `flashlib/kernels/*` holds shared distance, connected-components, and MST kernels.
- `flashlib/info/*` holds the registry, dispatch layer, roofline model, and estimate dataclasses.
- `benchmarks/` contains broad cuML comparisons, microbenchmarks, and tuner scripts.
- `tests/` covers imports, info API, CUDA primitive correctness, multi-backend parity, and advantage boundaries.

The strongest pattern is the parallel runtime/cost-model structure: each primitive has both execution code and a cost model, and the registry lets planning code query the same family of decisions without executing kernels. That is the part most worth borrowing.

## Comparison

| Aspect | FlashLib | cuML | sklearn / Torch baselines |
|--------|----------|------|---------------------------|
| Goal | Flash-style GPU kernels for classical ML | Production GPU classical ML suite | General CPU/GPU primitives and references |
| Operator breadth | Broad but alpha | Broad and mature | Very broad, not always GPU-optimized |
| Kernel strategy | Hand-routed Triton/CuteDSL variants | RAPIDS production kernels | General implementations |
| Planning API | Explicit cost/roofline/variant estimates | Limited upfront budgeting | Usually benchmark after the fact |
| Maturity | 0.1.0, created 2026-05-26 | Established | Established |

## Self-Hosting Notes

Installation is standard Python packaging:

```bash
pip install flashlib
```

For source work:

```bash
git clone https://github.com/FlashML-org/flashlib.git
cd flashlib
pip install -e .
```

The practical runtime expectation is Linux with NVIDIA CUDA, PyTorch, Triton, and optionally CUTLASS DSL for Hopper-focused paths. Many correctness tests are CUDA-gated and skip on CPU-only systems. Local verification in this review could not run pytest because the system Python lacked `pytest`, and a direct `PYTHONPATH` info smoke test exposed the torch import dependency described above.

---

**Attribution:** FlashML-org/flashlib, Apache-2.0. Review includes source observations from the repository README, package metadata, source tree, tests, and project blog at https://flashml-org.github.io/.
