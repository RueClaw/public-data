# MoonEP (MoonshotAI/MoonEP)

**Repo:** https://github.com/MoonshotAI/MoonEP  
**License:** MIT, permissive for use, modification, and extraction with attribution  
**Reviewed:** 2026-07-27  
**Stack:** Python, PyTorch distributed/NCCL, CUDA, pybind11, NVIDIA VMM/NVLink/NVSwitch multicast, CUTLASS/CuTe DSL  
**What it is:** MoonEP is a specialized expert-parallel communication library for Mixture-of-Experts workloads. It keeps per-rank token load exactly balanced by dynamically duplicating a small number of experts, prefetching their weights, and reducing duplicate gradients back to home ranks.

---

## Verdict

📚 **Study this if you work on large MoE training or serving; do not treat it as a general deployment component.** The core idea is sharp: move a bounded set of remote experts to balance skewed routing, keep static `S x K` token shapes, and fuse permutation with communication. The caveat is equally sharp: this is a tiny, hardware-specific CUDA/NVLink systems repo with heavyweight assumptions and no CPU/macOS path.

---

## What It Is

MoonEP targets the hot communication path in expert-parallel MoE models. Standard EP dispatch sends routed tokens to the rank that owns each expert, so a skewed router can overload a few ranks and leave others idle. MoonEP instead plans a balanced assignment online: every rank receives exactly `S x K` token slots, and overloaded experts may be duplicated into local prefetch slots on other ranks.

The implementation contract is intentionally narrow. A framework provides one contiguous symmetric-memory `[E+B, H, H']` weight tensor per expert projection plus router outputs. MoonEP returns expert-grouped buffer views and `cu_seqlens` for a VM-group GEMM. In training, duplicate expert gradients are accumulated from temporary reduce buffers back into the owning expert rows.

The repo is closer to a research systems artifact than a polished package. It has a strong README, benchmark scripts against DeepEP v2, and a serious multi-GPU test suite, but the package metadata is minimal, version is `0.0.1`, and local validation requires CUDA, PyTorch, multiple NVIDIA GPUs, NCCL, NVLink/VMM support, and `nvidia-cutlass-dsl==4.4.2`.

## Stack

| Layer | Tech |
|-------|------|
| Public API | Python package `moonep`, `Buffer`, `MoonEPCommPlan` |
| Distributed runtime | PyTorch distributed, NCCL process groups |
| GPU kernels | CUDA, CUTLASS/CuTe DSL, inline PTX helpers |
| Native extension | `torch.utils.cpp_extension.CUDAExtension`, pybind11 |
| Memory model | NVIDIA VMM, POSIX fd IPC, NVLink distributed tensors, NVSwitch multicast |
| Tests | pytest tests launched with `torchrun --nproc_per_node=8` |
| Benchmarks | MoonEP versus DeepEP v2 communication and end-to-end scripts |
| Target hardware | NVIDIA GPUs with NVLink/NVSwitch-style peer memory support; Zhenwu PPU noted as planned |

## Key Features

### Perfect Per-Rank Token Balance

The planner computes a destination assignment where each rank receives a fixed `S x K` real-token workload regardless of router skew. Remote expert duplication is bounded by prefetch slots `B`, with training defaulting to `B = E/R`.

### Static Shapes and Zero-Copy Views

MoonEP uses fixed-size communication buffers and returns expert-grouped views into those buffers. With `zero_copy=True`, dispatch and combine avoid extra boundary copies; the expert FFN reads and writes directly in the communication buffer.

### Dynamic Redundant Experts

Rather than moving all weights or changing the model topology permanently, MoonEP selects redundant experts from the current router outputs. `prefetch_weight` copies the selected remote expert weights into local `[E, E+B)` rows, and `reduce_grad` later sends duplicate gradients back to owner ranks.

### Hardware-Aware Symmetric Memory

The low-level buffer code exchanges POSIX file descriptors between ranks, maps each rank's VMM allocation into a shared virtual address range, and overlays multicast memory where supported. That is the real systems work behind the simple Python API.

## Architecture

The source tree is compact:

- `moonep/api.py` owns the public `Buffer` API, allocation context, stream handling, dispatch/combine/prefetch/reduce orchestration, and resource cleanup.
- `moonep/planning.py` implements the online planner in CuTe DSL, including plan outputs, destination slots, zero-fill ranges, duplicate metadata, and cross-rank synchronization.
- `moonep/dispatch.py`, `dispatch_epilogue.py`, `combine.py`, and `combine_prologue.py` handle scatter/gather and fused permute/unpermute behavior.
- `moonep/prefetch.py` and `grad_reduce.py` move selected expert weights and accumulate duplicate gradients.
- `moonep/buffer.py` and `csrc/nvl_shared_buffer.cuh` provide the VMM/NVLink shared-memory primitives.
- `tests/` contains correctness coverage for planning, dispatch, combine, prefetch, grad reduce, and end-to-end public API paths.

The strongest design pattern is treating the communication plan as a reusable first-class artifact. A fresh dispatch builds a `MoonEPCommPlan`; later backward or saved-plan paths can reuse the same destination and duplicate maps without replanning.

## Comparison

| Aspect | MoonEP | DeepEP v2 | Colibri | FlashLib |
|--------|--------|-----------|---------|----------|
| Goal | Balance expert-parallel MoE token traffic | High-performance EP communication | Run huge MoE inference with disk-tiered experts | Fast CUDA classical ML primitives |
| Main mechanism | Dynamic redundant experts plus static communication buffers | Elastic dispatch/combine around hot ranks | Dense weights resident, routed experts streamed/cached | Tolerance-routed GPU kernels |
| Hardware target | Multi-GPU NVIDIA NVLink/NVSwitch class systems | Multi-GPU NVIDIA systems | Consumer-ish CPU/RAM/NVMe, optional GPU | NVIDIA CUDA GPUs |
| Reuse value | EP planning, symmetric-memory buffer design | Production comparison target | Model memory hierarchy idea | GPU scheduling/cost-model idea |
| Maturity signal | Fresh `0.0.1`, tests and benchmarks but niche hardware required | Established adjacent baseline | Practical local inference experiment | Alpha systems library |

## Self-Hosting Notes

Installation is source-based:

```bash
git clone https://github.com/MoonshotAI/MoonEP.git
cd MoonEP
pip install -e .
```

Representative tests require a multi-GPU CUDA environment:

```bash
torchrun --nproc_per_node=8 -m pytest tests/test_planning.py
torchrun --nproc_per_node=8 -m pytest tests/test_dispatch.py
torchrun --nproc_per_node=8 -m pytest tests/test_combine.py
torchrun --nproc_per_node=8 -m pytest tests/test_e2e.py
torchrun --nproc_per_node=8 -m pytest tests/test_grad_reduce.py
torchrun --nproc_per_node=8 -m pytest tests/test_prefetch.py
```

Do not expect this to run meaningfully on a laptop or CPU-only server. It depends on CUDA extension compilation, PyTorch distributed, NCCL, compatible NVIDIA memory APIs, and the exact CUTLASS DSL dependency pinned in `setup.py`.

Local verification for this review was limited: Python `compileall` passed over the package, tests, and benchmarks, but runtime tests were not run because the local Python environment does not have PyTorch installed and the machine context is not the required 8-GPU NVLink setup.

---

**Attribution:** MoonshotAI/MoonEP, MIT License. Review based on repository README, source tree, package metadata, CUDA extension boundary, test suite, benchmarks, and GitHub metadata at commit `0f385f038fc33bec22e3bcf5a07a8a22693e754c`.
