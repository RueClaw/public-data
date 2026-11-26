# PERF-GS (electronicarts/perf-gs)

**Repo:** https://github.com/electronicarts/perf-gs
**License:** BSD-3-Clause core; separate component, benchmark, mask and dataset terms.
**Reviewed:** 2026-11-26 UTC
**Revision:** 26a4ca2d81ab8495848cd9f11e2f537049f2946a (master, committed 2026-11-26). Repository-wide static inspection focused on trainer, shaders, reconstruction, evaluation, tests and benchmark records.
**Release:** v1.0.0, published 2026-11-25, commit 8107668d764da0263b2481bdae74787848d7feaf; reviewed master is newer. Package metadata still says 0.0.1.
**Verification:** Anonymous API/HTTPS acquisition; static inspection and independent CSV arithmetic. No source execution/imports, installations, GPU tests, model or dataset downloads.
**Stack:** Python 3.10+, Slang/Slang.D, SlangPy 0.42.0, Vulkan / Windows D3D12, NumPy, SciPy, OpenCV, Pillow, plyfile.
**What it is:** Electronic Arts / SEED's desktop and headless 3D Gaussian Splatting trainer, created by Stefano Scolari; calibrated photos become renderable Gaussian models.

## Verdict

⚠️ **Interesting — substantive fast-training engineering, not yet a turnkey production baseline.** The actual Slang implementation, numerical tests and candid benchmark disclosure are compelling. Optimization-only timing, single-seed variability, native tool trust and restrictive optional masks qualify the headline. Evaluate Balanced or Quality on licensed data and your own hardware before adoption.

## What It Is

The hub orchestrates COLMAP/GLOMAP reconstruction from photos, loads existing COLMAP scenes, trains with a live viewer and exports PLY. A headless CLI shares the application. This is not merely a renderer benchmark. “Dependency-free” means no CUDA/PyTorch dependency in the training core, not no dependencies or native GPU runtime. [1][2]

Anonymous metadata showed 117 stars, four forks, zero open issues and last push 2026-11-26. These are discovery signals, not quality evidence. No GitHub Actions workflow directory or dependency lockfile was present in the inspected tree. [14]

## Stack

| Layer | Technology / responsibility |
|---|---|
| Application | Python hub/CLI and run/session controls |
| Compute | SlangPy 0.42.0, Slang kernels, Vulkan / D3D12 |
| Data | COLMAP cameras/clouds; OpenCV/Pillow; NumPy/SciPy stereo initialization |
| Reconstruction | Optional COLMAP/GLOMAP executables and local SQLite database |
| Outputs | PLY, render images, JSON reports, CSV benchmark summaries |
| Evaluation | Optional PyTorch/LPIPS; Graphdeco scorer for published comparisons |

## Key Features

### Real training, modular implementation

Python owns camera sampling, schedules and lifecycle. The pipeline composes projection, tile sorting, blending, loss, backward passes, Adam and densification. Stereo matches augment sparse COLMAP points. Morton reordering/cluster culling reduce work; depth sorting followed by stable tile-ID sorting builds lists. Differentiable Slang handles projection/coverage while explicit outer backward passes reduce atomic contention. Their 32-splat forward checkpoints are GPU intermediates, not durable training checkpoints. [1][3]

### Four speed/quality budgets

Ultrafast uses quarter-pixel backward supervision with STBN masks and degree-2 spherical harmonics. Balanced streams photos from RAM and supervises every pixel. Quality increases color degree/capacity, prunes using RGB-removal costs and refines. Quality+ continues with live model/optimizer state until PSNR on up to eight fixed training views plateaus; held-out cameras are reporting data, not its stopping signal. [1][4]

### Memory savings with limits

Parameters remain float32 while bf16 Adam moments use stochastic rounding. Streaming and capacity accounting matter, but sort-pair overflow drops pairs and counts them: inspect counters rather than accepting a plausible image. Published zero-overflow measurements cover particular runs. Balanced's roughly 2.8 GiB NVIDIA average is loop-end memory, not peak usage or minimum VRAM. Viewer, setup, dimensions, sorting and host image storage add pressure. [3][5]

## Architecture

The frontend application manages TrainingApplication/TrainingLoop; the hub owns interaction, data modules prepare scenes, backend.render.pipeline composes resources, and shaders implement compute. Architecture-boundary tests are a maintenance signal. SlangPy is pinned to 0.42.0 because 0.43 removed the NDBuffer API used here; the reviewed commit fixes that mismatch. Most other dependencies float. [2][3][9]

This is a local desktop process, not an authenticated multi-tenant service. It inherits user file/process authority; image parsers, shader compilation, drivers and subprocesses belong to its trust boundary. It is not a sandbox for arbitrary datasets/executables. [6]

## Benchmark Methodology and Correctness

### What “10 seconds” measures

The RTX 4090 protocol uses nine Mip-NeRF 360 scenes, seed 42, one fresh process per scene/preset, every eighth camera held out, quarter-resolution outdoors and half-resolution indoors. There are 246 held-out views per preset. Views average within scenes, then nine scene means receive equal weight. Graphdeco scores saved RGB8 images with PSNR, SSIM and VGG LPIPS. Timing covers the headless Vulkan optimization loop through synchronization, excluding COLMAP, loading, stereo initialization, evaluation and export. Quality+ includes convergence checks. [4][5]

Independent standard-library CSV parsing reproduced these summaries; this checks arithmetic, **not performance**:

| RTX 4090 preset | Loop seconds | PSNR dB | SSIM | VGG LPIPS |
|---|---:|---:|---:|---:|
| Ultrafast | 10.51223 | 27.13068 | 0.79353 | 0.25642 |
| Balanced | 15.90804 | 27.40375 | 0.81409 | 0.22278 |
| Quality | 22.68185 | 27.90035 | 0.82853 | 0.19964 |
| Quality+ | 122.66164 | 28.22683 | 0.83173 | 0.19090 |

Each group has nine rows/246 views. AMD fixed-budget CSVs reproduce 16.44038 / 27.01759 / 39.46835 seconds and 27.12451 / 27.39085 / 27.89840 dB for Ultrafast / Balanced / Quality. These remain author measurements. [7]

### Useful provenance, but cached is not fresh

The driver checks the expected GPU, fingerprints trainer/shader source including local changes, locks its output directory, records system versions and checks completeness. Its completed-CSV early return requires a system record but does not compare it with the current environment before returning. A reused CSV is not a new measurement. The hash does not encompass every dependency, dataset or benchmark script. [8]

The published current 4090 record identifies d69f4f2f355f96d9a69472b8d62b59299f33a37b and fingerprint 1e76c2ccbdf53b2afcd6f28224a8e871a41c2ef8d58161574cd947e9d07cc41a, not this review's SHA. Preserve historical benchmark provenance separately. [7]

### Meaningful tests, limited statistical confidence

There are 74 test modules named test_*.py covering finite-difference gradients, backward/reference parity, bf16 Adam, sorting/scans, SSIM, STBN, PLY, configuration, hub state and reconstruction. GPU fixtures target Vulkan/D3D12 and skip unavailable devices. Gradient tests allow quantization/discontinuity tolerance; synthetic scenes cannot establish all real-scene correctness. None were run here. Authors report 1,202 collected cases passing across fresh AMD processes, alongside a native device-creation failure in one long-lived pytest process. No checked-in CI establishes automated cross-platform coverage. [9][5]

Fixed-model cross-vendor replay is stronger evidence than independently trained models: the same PLYs/cameras reportedly gave approximately 83.86/82.53 dB agreement for Stump/Kitchen. An independently trained AMD Room view nevertheless lost 4.26 dB and showed haze; a same-seed rerun largely cleared it. The original timed model was not saved, preventing exact replay. These are author observations, not independently reproduced visuals. Single seeds, absent confidence intervals, scene-informed recipe development and variable Quality+ stopping limit determinism/generalization claims. [5]

## Comparison

| Alternative | Why consider it | Tradeoff |
|---|---|---|
| gsplat | PyTorch/CUDA library integration | Different goal from standalone Slang/AMD training |
| Graphdeco 3DGS | Reference algorithm/evaluation ecosystem | Separate restrictive license; CUDA-oriented setup |
| LiteGS / FastGS / SAD-GS | Fast training/densification | Published peer runs differ in OS/backend and budgets |

The RTX 4080 comparisons use the same GPU, resolutions and reference pixels. However, competitors run WSL2/CUDA versus PERF-GS Windows/Vulkan; renderers, budgets and memory behavior differ. Cross-paper comparisons mix hardware and sometimes seven versus nine scenes. “Fastest publicly available” is an author claim, not established here. [5][13]

## Security, Privacy and Supply Chain

Reconstruction uses subprocess argument lists, not shell interpolation. Its installer restricts initial URLs to GitHub HTTPS, caps compressed downloads at 768 MiB and rejects absolute/traversal ZIP paths. Nevertheless it fetches mutable latest Windows binaries without pinned checksums/signature verification, then extracts and executes them. Redirect destinations and expanded ZIP size are not comprehensively bounded. Executable overrides, environment paths and PATH are trusted. [6]

STBN comes from mutable upstream main. STBN/dataset transfers use partial-file renames but no content-hash pins; dataset extraction lacks expanded-size quotas, and force replacement removes prior destination content. Most dependencies float. Optional LPIPS initialization can fetch weights; benchmarking clones and executes a pinned Graphdeco evaluator. CUDA/PyTorch-free training is not download-free benchmarking. [2][6][8][10]

No telemetry upload was identified in inspected training/reconstruction paths; this is not an exhaustive network audit. Photos, reconstruction databases, renders, PLYs and reports persist locally. Logs/reports can include paths/errors; download services observe requests. No app-level encryption, tenant isolation, automatic retention or secure deletion is provided. [6][11]

## Persistence and Recovery

Hub PLY export writes in a temporary destination-side directory then replaces the target, reducing partial-file exposure. Do not infer universal atomicity/power-loss durability for every CLI output/report. PLY stores Gaussian/render metadata, not complete Adam/sampler/schedule state. No documented full crash-resume facility was found. Pause, stop and Quality+ continuation retain state while the process survives. [11]

Benchmark locking/completeness checks support sweep-level recovery of completed scenes, not mid-optimization recovery. Partial download renames avoid treating interrupted transfers as complete but do not implement HTTP range resumption. Preserve original photos, exact software/data fingerprints, models and held-out renders; absence of an original model already limited upstream discrepancy investigation. [8][10][5]

## Self-Hosting Notes

This is a local application. Upstream tested Windows 11 on RTX 4080 16 GB, RTX 4090 24 GB and RX 7900 XT 20 GB. Linux/macOS are explicitly unverified. 32/64-lane waves and 64-bit integer buffer atomics matter; AMD evidence does not establish Apple/Intel compatibility. Published hosts use 32-core Threadripper PRO CPUs and substantial RAM; reconstruction/stereo setup is outside headline timing. [1][4][5]

Pin source/dependencies, verify optional binaries/assets, begin with Balanced/Quality on licensed non-sensitive data, measure peak memory and photo-to-model time, repeat seeds, inspect overflows and save models/renders. No installation procedure was executed here.

## Licensing and Reuse

EA's core LICENSE is BSD-3-Clause: retain copyright/terms in source and binary redistribution, and do not imply endorsement. NOTICE includes MIT GPUSorting terms and identifies optional benchmark portions carrying Graphdeco research/evaluation-only restrictions. Do not assume the whole evaluation stack is commercially permissive because the core is BSD. [12]

Default Ultrafast NVIDIA STBN masks are non-commercial research/evaluation assets. Balanced/Quality avoid that mask dependency. Separately licensed masks or full-pixel supervision change licensing and the measured configuration. COLMAP/GLOMAP, Python libraries, optional neural weights and Mip-NeRF 360 / Tanks & Temples / Deep Blending data retain separate terms; attribution is not redistribution permission. No components/data are extracted here; no full transitive license audit was performed. [10][12]

## Verification and Limits

- Anonymous access, exact master/release identity, implementation paths and test inventory checked.
- Independently recalculated seven CSV groups: six NVIDIA/AMD fixed-budget groups plus RTX 4090 Quality+, including row/view totals.
- No tests/imports, GPU work, installation, evaluator execution or model/dataset downloads.
- Review artifacts checked for trusted-template CSS/JS, markup/links, placeholders, provenance, redaction and task-only diff.
- Not visual-quality reproduction, an exploit audit, complete license audit or performance proof on another revision/machine.

## Evidence

1. [README.md](https://github.com/electronicarts/perf-gs/blob/26a4ca2d81ab8495848cd9f11e2f537049f2946a/README.md)
2. [pyproject.toml](https://github.com/electronicarts/perf-gs/blob/26a4ca2d81ab8495848cd9f11e2f537049f2946a/pyproject.toml) · [setup.py](https://github.com/electronicarts/perf-gs/blob/26a4ca2d81ab8495848cd9f11e2f537049f2946a/setup.py)
3. [src/trainer/frontend/app.py](https://github.com/electronicarts/perf-gs/blob/26a4ca2d81ab8495848cd9f11e2f537049f2946a/src/trainer/frontend/app.py) · [src/trainer/backend/render/pipeline.py](https://github.com/electronicarts/perf-gs/blob/26a4ca2d81ab8495848cd9f11e2f537049f2946a/src/trainer/backend/render/pipeline.py) · [shaders/rasterize/tile_binned/backward_persplat.slang](https://github.com/electronicarts/perf-gs/blob/26a4ca2d81ab8495848cd9f11e2f537049f2946a/shaders/rasterize/tile_binned/backward_persplat.slang)
4. [docs/benchmark-rtx4090.md](https://github.com/electronicarts/perf-gs/blob/26a4ca2d81ab8495848cd9f11e2f537049f2946a/docs/benchmark-rtx4090.md) · [docs/usage.md](https://github.com/electronicarts/perf-gs/blob/26a4ca2d81ab8495848cd9f11e2f537049f2946a/docs/usage.md)
5. [docs/benchmarks.md](https://github.com/electronicarts/perf-gs/blob/26a4ca2d81ab8495848cd9f11e2f537049f2946a/docs/benchmarks.md)
6. [src/trainer/frontend/reconstruction/tools.py](https://github.com/electronicarts/perf-gs/blob/26a4ca2d81ab8495848cd9f11e2f537049f2946a/src/trainer/frontend/reconstruction/tools.py) · [src/trainer/frontend/reconstruction/pipeline.py](https://github.com/electronicarts/perf-gs/blob/26a4ca2d81ab8495848cd9f11e2f537049f2946a/src/trainer/frontend/reconstruction/pipeline.py)
7. [docs/NVIDIA_GeForce_RTX_4090_presets_current.csv](https://github.com/electronicarts/perf-gs/blob/26a4ca2d81ab8495848cd9f11e2f537049f2946a/docs/NVIDIA_GeForce_RTX_4090_presets_current.csv) · [docs/NVIDIA_GeForce_RTX_4090_qualityplus.csv](https://github.com/electronicarts/perf-gs/blob/26a4ca2d81ab8495848cd9f11e2f537049f2946a/docs/NVIDIA_GeForce_RTX_4090_qualityplus.csv) · [docs/AMD_Radeon_RX_7900_XT_presets.csv](https://github.com/electronicarts/perf-gs/blob/26a4ca2d81ab8495848cd9f11e2f537049f2946a/docs/AMD_Radeon_RX_7900_XT_presets.csv) · [docs/NVIDIA_GeForce_RTX_4090_system_current.txt](https://github.com/electronicarts/perf-gs/blob/26a4ca2d81ab8495848cd9f11e2f537049f2946a/docs/NVIDIA_GeForce_RTX_4090_system_current.txt)
8. [scripts/running/benchmark_presets.ps1](https://github.com/electronicarts/perf-gs/blob/26a4ca2d81ab8495848cd9f11e2f537049f2946a/scripts/running/benchmark_presets.ps1)
9. [tests/conftest.py](https://github.com/electronicarts/perf-gs/blob/26a4ca2d81ab8495848cd9f11e2f537049f2946a/tests/conftest.py) · [tests/test_gradients.py](https://github.com/electronicarts/perf-gs/blob/26a4ca2d81ab8495848cd9f11e2f537049f2946a/tests/test_gradients.py) · [tests/test_adam_bf16.py](https://github.com/electronicarts/perf-gs/blob/26a4ca2d81ab8495848cd9f11e2f537049f2946a/tests/test_adam_bf16.py) · [tests/test_architecture_boundaries.py](https://github.com/electronicarts/perf-gs/blob/26a4ca2d81ab8495848cd9f11e2f537049f2946a/tests/test_architecture_boundaries.py)
10. [src/trainer/frontend/stbn_download.py](https://github.com/electronicarts/perf-gs/blob/26a4ca2d81ab8495848cd9f11e2f537049f2946a/src/trainer/frontend/stbn_download.py) · [scripts/data/_dataset_fetch.py](https://github.com/electronicarts/perf-gs/blob/26a4ca2d81ab8495848cd9f11e2f537049f2946a/scripts/data/_dataset_fetch.py) · [src/trainer/common/perceptual.py](https://github.com/electronicarts/perf-gs/blob/26a4ca2d81ab8495848cd9f11e2f537049f2946a/src/trainer/common/perceptual.py) · [docs/stbn_pixel_sampling.md](https://github.com/electronicarts/perf-gs/blob/26a4ca2d81ab8495848cd9f11e2f537049f2946a/docs/stbn_pixel_sampling.md)
11. [src/trainer/frontend/hub.py](https://github.com/electronicarts/perf-gs/blob/26a4ca2d81ab8495848cd9f11e2f537049f2946a/src/trainer/frontend/hub.py) · [src/trainer/frontend/run_control.py](https://github.com/electronicarts/perf-gs/blob/26a4ca2d81ab8495848cd9f11e2f537049f2946a/src/trainer/frontend/run_control.py) · [src/trainer/backend/export.py](https://github.com/electronicarts/perf-gs/blob/26a4ca2d81ab8495848cd9f11e2f537049f2946a/src/trainer/backend/export.py) · [src/trainer/frontend/reporting/outputs.py](https://github.com/electronicarts/perf-gs/blob/26a4ca2d81ab8495848cd9f11e2f537049f2946a/src/trainer/frontend/reporting/outputs.py)
12. [LICENSE](https://github.com/electronicarts/perf-gs/blob/26a4ca2d81ab8495848cd9f11e2f537049f2946a/LICENSE) · [NOTICE.md](https://github.com/electronicarts/perf-gs/blob/26a4ca2d81ab8495848cd9f11e2f537049f2946a/NOTICE.md)
13. Alternatives: [gsplat](https://github.com/nerfstudio-project/gsplat), [Graphdeco](https://github.com/graphdeco-inria/gaussian-splatting), [LiteGS](https://github.com/MooreThreads/LiteGS), [FastGS](https://github.com/fastgs/FastGS), [SAD-GS](https://github.com/LinjieLyu/SADGS). Architectural comparison, not independently rerun benchmarks.
14. [Public metadata](https://api.github.com/repos/electronicarts/perf-gs), [v1.0.0 release](https://github.com/electronicarts/perf-gs/releases/tag/v1.0.0); observed 2026-11-26 UTC.

---

**Attribution:** Stefano Scolari, Electronic Arts / SEED, electronicarts/perf-gs; BSD-3-Clause core and separately applicable component/asset terms.
