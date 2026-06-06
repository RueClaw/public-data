# MAMMA (cuevhv/mamma)

**Repo:** https://github.com/cuevhv/mamma  
**License:** Custom non-commercial scientific research license. Use is limited to non-commercial scientific research, non-commercial education, or non-commercial artistic projects; redistribution, commercial use, surveillance, military use, and most third-party sharing are prohibited without permission.  
**Reviewed:** 2026-06-06  
**Stack:** Python 3.11, CUDA 12.4, PyTorch 2.5.1, SAM 2/3, YOLOv12, CLIP/OpenCLIP, SMPL-X, Detectron2, PyTorch Lightning, Hydra, WebDataset, Flask, React/Vite, SQLite, Rerun  
**What it is:** MAMMA is a CVPR 2026 markerless multi-person motion-acquisition pipeline. It turns calibrated multi-view video into segmentation masks, dense 2D landmarks, optimized SMPL-X bodies, overlays, and interactive 3D visualizations.

---

## Verdict

⚠️ **Interesting for non-commercial motion-capture research, not a general deploy candidate.** The release is substantial: code, docs, GUI, dataset download scripts, example configs, a smoke-test harness, and a full five-stage pipeline. The hard limits are the custom research-only license, gated model/data assets, CUDA-heavy setup, no visible GitHub Actions, and a local-only GUI with no authentication.

---

## What It Is

MAMMA stands for Markerless Accurate Multi-person Motion Acquisition. The project targets labs and researchers that need multi-person body capture without markers, using calibrated multi-camera footage. The top-level pipeline is:

```text
ma_cap -> ma_masks -> ma_2d -> ma_3d -> ma_vis
```

`ma_cap` loads capture data and calibration. `ma_masks` uses YOLO plus SAM 2 or SAM 3 to segment and track people across cameras. `ma_2d` runs MammaNet dense landmark detection. `ma_3d` optimizes SMPL-X bodies from multi-view landmarks, calibration, contact signals, and temporal losses. `ma_vis` renders per-camera overlays and Rerun-style interactive scenes.

The repo also ships a browser GUI for local runs. The GUI wraps the same Python runner used by the CLI, stores job metadata in SQLite, lets users manage capture descriptors and presets, downloads gated assets, launches pipeline tasks, and browses outputs.

## Stack

| Layer | Tech |
|-------|------|
| Pipeline runtime | Python 3.11, conda/micromamba, CUDA 12.4 |
| ML stack | PyTorch 2.5.1, torchvision, Detectron2, pytorch_sdf |
| Segmentation | YOLOv12, SAM 2, SAM 3, OpenCLIP, Hungarian matching, epipolar geometry |
| 2D landmarks | MammaNet, ViTPose/HRNet/CameraHMR-style backbones, PyTorch Lightning, Hydra, WebDataset |
| 3D fitting | SMPL-X, multi-stage optimization, contact/intersection/temporal losses |
| Visualization | OpenCV/video outputs, Rerun SDK, HTML/MP4/NPZ viewers |
| GUI | Flask, Flask-CORS, SQLite, React 18, Vite, Tailwind, Radix UI |
| Execution | Local conda engine, optional Docker and Apptainer step engines |

## Key Features

### End-To-End Multi-View Body Pipeline

The strongest feature is the integrated five-step path from footage and calibration to SMPL-X body outputs. Many research repos release isolated models; MAMMA ships the orchestration layer, configs, docs, and GUI needed to run a complete capture workflow.

### Segmentation With Cross-Camera Identity Matching

The segmentation module supports SAM 2, SAM 3, and SAM 3 prompt mode. It combines CLIP appearance features with epipolar geometry and Hungarian matching to keep person IDs aligned across cameras. The docs are honest about temporal identity failures: the matching is cross-camera, not a full temporal correction system.

### Runner DAG And Step Builders

The inference runner topologically sorts enabled steps, supports step-major or sequence-major dispatch, skips downstream work after failed dependencies, and runs each stage through a `StepBuilder`. Each builder translates config fields into the exact subprocess invocation for that stage.

### Local GUI Over The Same Pipeline

The GUI is useful because it does not invent a separate execution model. It uses the same `inference.runner.run_dag` path, then adds task queues, SQLite bookkeeping, status polling, output browsing, dataset/asset readiness panels, and a Vite/React interface.

### Asset Registry And Doctor Flow

The install docs and `inference doctor` flow are strong for a research release. The repo declares default locations for YOLO, SAM, MammaNet, SMPL-X locked-head models, downsampled vertices, and optional BUN/part meshes; `.env.local` can override those paths; the runner turns `MAMMA_*` paths into argv flags and strips them from child environments.

## Architecture

The repo is organized by pipeline step:

```text
inference/       runner, CLI, step builders, doctor, asset registry
capture/         ma_cap
segmentation/    ma_masks
landmarks/       ma_2d and training code
optimization/    ma_3d
visualization/   ma_vis
configs/         presets, capture descriptors, calibration examples
data/            gitignored weights/datasets
gui/             Flask + React local UI
scripts/         smoke tests and migration utilities
```

The best engineering choice is the separation between capture-independent presets and capture descriptors. Presets define which steps run and with what flags; capture descriptors define footage roots, camera names, calibration, and sequences. That makes one pipeline preset reusable across multiple datasets.

The runner is also pragmatic. It launches each step as a subprocess in its own process group, handles cooperative cancellation, escalates from SIGTERM to SIGKILL for wedged CUDA children, writes logs, and uses DONE sentinels for resume/skip behavior.

The GUI needs careful framing. It explicitly has no login, treats anyone reaching the backend as the local OS user, enables CORS, and exposes file browsing/serving APIs that accept absolute paths. That is acceptable for a single-user localhost lab tool. It is not safe to expose as a shared web service without an auth and path-sandbox pass.

## Comparison

| Aspect | MAMMA | Surya | ComfyUI-LTXVideo |
|--------|-------|-------|------------------|
| Domain | Markerless multi-person motion capture | Document OCR/layout/table understanding | Video generation workflows |
| Output | SMPL-X parameters, masks, landmarks, overlays, 3D scenes | Text/layout/table JSON/HTML | Generated video assets |
| Deployment posture | Research/local GPU pipeline | More package-like document toolkit | ComfyUI custom-node workflow pack |
| License posture | Custom non-commercial research license | Code Apache-2.0, model license caveats | Community/model license caveats |
| Main caveat | Gated assets, CUDA setup, local-only GUI | Model/runtime tradeoffs | Heavy model/runtime and license limits |

MAMMA is closer to a complete academic release than a library. It is useful if the exact domain matters, but the license and runtime requirements make it unsuitable as a reusable component in commercial or hosted products.

## Self-Hosting Notes

Install path:

```sh
micromamba create -f requirements/mamma_conda.yaml -y
micromamba activate mamma
export CUDA_HOME=/path/to/cuda-12.4
pip install -r requirements/requirements.txt
pip install --no-build-isolation -r requirements/requirements_no_build_isolation.txt
python -m inference doctor
```

Important setup constraints:

- CUDA 12.4 is the documented target.
- Some pip layers compile CUDA kernels.
- MAMMA weights require a MAMMA account.
- SMPL-X locked-head models require an SMPL-X account.
- SAM 3 requires gated Hugging Face access if used.
- Dataset downloads can be very large: the docs list video/data variants from gigabytes to terabytes.
- The GUI is localhost-only by design and should stay that way.

Local verification on 2026-06-06:

- Reviewed commit: `0183e5b86b5bce786891037a2ef24c399c1dca00`.
- GitHub metadata: 180 stars, 15 forks, 3 open issues, pushed 2026-06-02.
- GitHub Actions: no public workflow runs returned.
- `python3 scripts/smoke_test.py --list`: passed and listed 36 registered checks.
- `python3 -m compileall -q inference capture configs`: passed.
- `python3 -m inference doctor`: failed in this shell because the project conda env is not installed (`ModuleNotFoundError: No module named 'dotenv'`).
- Full pipeline tests were not run because they require CUDA 12.4, the project conda env, downloaded model weights, body models, and example data.
- Secret-pattern scan found expected credential env names and download-script prompts, not obvious committed live credentials.

---

**Attribution:** cuevhv/mamma, custom non-commercial scientific research license.
