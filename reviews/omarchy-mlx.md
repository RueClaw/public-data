# omarchy-mlx (joshuaswarren/omarchy-mlx)

**Repo:** https://github.com/joshuaswarren/omarchy-mlx
**License:** MIT project code; upstream/component notices and model terms remain separate.
**Reviewed:** 2026-11-02 (UTC)
**Revision:** 32ed79d7d834e7bdec2ac74d15d0d295c9fa1ce8 — root repository, with targeted inspection of overlay, patches, serving/chat, installer, packaging, CI and receipts. Commit dated 2026-11-02; not a review of every experimental script or external driver.
**Verification:** Static source and public evidence review only. No source execution, tests, builds, installations, model downloads or hardware benchmarks performed.
**Stack:** C++ / Vulkan / GLSL-SPIR-V, patched MLX, Python, Bash/CMake; browser HTML/CSS/JavaScript; separate ANE worker.
**What it is:** An independent MLX Vulkan backend and local inference/speech stack primarily for Apple Silicon running Linux. It is not a bridge that forwards Omarchy prompts to a Mac running macOS, and not a generic x86 Omarchy MLX installer.

## Verdict

⚠️ **Interesting — credible Linux-on-Apple accelerator engineering, but a qualified-hardware pilot, not a turnkey recommendation.** The actual GPU backend, pinned upstream patch workflow, model-memory admission and unusually explicit numerical receipts justify attention. Limited hardware qualification, experimental M4 support, an unresolved released ANE installer defect and uneven documentation/release parity prevent a broad deployment recommendation. Prefer the GPU-only path on an already-working supported Linux Mac; treat ANE and new chips as separate engineering projects.

## What It Is

Joshua Warren and contributors keep upstream MLX source outside this tree, fetch a fixed archive, then apply additive overlay files and a substantial patch series. The Python distribution is **mlx-omarchy** but applications still import **mlx.core**. Linux Vulkan compute replaces Metal for the Apple GPU through Mesa Honeykrisp. The repository includes much more than bindings: operator kernels, allocator/stream machinery, custom-kernel translation, a local chat coordinator, typed Laya decisions, specialized Bonsai serving, speech tooling and evidence collectors. [S1–S4]

Omarchy integration is concrete but optional at the application layer: package-helper use, a self-describing command-center launcher, desktop entry, login user service and a read-only color/font theme adapter. A functioning Asahi-family Linux kernel, GPU driver, firmware and Vulkan stack are prerequisites, not things magically supplied by the name. The ordinary installer also works through pacman on an appropriate non-Omarchy Arch installation. [S5–S6]

## Stack

| Layer | Implementation / boundary |
|---|---|
| Upstream | MLX 0.32.3 pin at 9c3d35571ac450a8ecf5c17b4d0e3fac52c08bc8 with archive SHA-256; applied overlay and patches |
| GPU runtime | C++ device selection, memory allocation, streams/events, command encoding and GLSL compute shaders embedded as SPIR-V |
| Compatibility | MLX primitive implementations, fused model paths and an MSL-to-GLSL custom-kernel translation surface; not blanket Metal compatibility |
| Serving | Python catalog, disk/RAM admission, locked reservations, mlx-lm context-cap shim, Laya/Bonsai module backends |
| Chat | Python loopback coordinator plus local browser/terminal clients; optional local history and voice |
| ANE | Separate native worker, Core ML package tooling, pinned Parakeet assets; external kernel/userspace/compiler dependencies |
| Packaging | Bash/CMake, release wheels, hash-locked offline system-package lane; ordinary installer has looser dependency resolution |

## Key Features

### Real GPU execution, not an inference proxy

The backend has actual device discovery, allocators, dispatch/stream synchronization, compiled-tape and primitive implementations. Release default-device selection refuses failed GPU initialization instead of silently selecting CPU; unsupported GPU operators raise shape/dtype-specific errors. **“No CPU fallback” is not “no CPU work”:** explicit CPU streams remain possible, Python/control/tokenization run on CPU, wake-word detection uses CPU ONNX, and ANE experiments can include NumPy/OpenBLAS work. [S2–S4]

Driver selection is process-scoped: use a packaged Honeykrisp ICD when available unless overridden, otherwise search installed ICDs. A packaged driver SHA mismatch is refused when its identity pin applies. This does not require replacing the desktop's Mesa merely to choose an inference ICD. That separation is valuable, but custom-driver availability and kernel compatibility still matter. [S3]

### Model admission is more than a “fits in RAM” label

The serving planner accounts for full checkpoint size (including all MoE experts), KV context, scratch/workspace and an OS reserve. An exclusive file-lock transaction couples admission to reservation; owner tokens and process lifetime prevent cooperating servers from accidentally releasing one another's budgets. The mlx-lm shim checks tokenized prompt plus requested output against admitted context, rather than trusting a CLI default. These are conservative estimates, not an OS-enforced memory sandbox or protection against unrelated workloads. [S7]

Catalog entries pin Hugging Face revisions; arbitrary remote repository selections resolve a revision before approval. Downloads require approval unless explicitly bypassed with the CLI's yes option. The inspected serving path does not enable trust_remote_code; the Laya loader uses safetensors/JSON, not pickle. Some catalog module entries still require explicit conversion before they can serve. **oMLX being listed as working does not mean this CLI will launch it:** the CLI currently refuses that backend because it lacks a verified server-side context cap. [S7–S8]

### ANE is a separate, narrower capability

Parakeet speech uses a qualified model pipeline and native worker; this is not arbitrary Core ML compatibility or a universal ANE LLM accelerator. Shipped-path assets have hash validation and sealed-memory consumption. The low-level worker also retains an unpinned load branch when seal expectations are absent: the documentation's “only hash-pinned programs” statement should be scoped to the supported pinned product path, not treated as an unconditional security property of every worker invocation. Sealing fixes byte identity, not trust in the kernel, compiler or model. [S9]

The published M2 Max ANE encoder evidence is one 10.44-second fixture, one boot and a particular module, with a roughly 253.5 ms median and bit-exact encoder output. It does not establish universal speech accuracy, an end-to-end production service, sustained soak stability or a beneficial GPU/ANE split. Documented ANE language-model experiments also diverge from reference prompts; GPU support does not qualify ANE support. [S10]

## Architecture

1. **Build:** verify pinned upstream archive → stage additive overlay → apply explicit patches → compile runtime/shaders → package the Python module and tools. The project calls this a small patch-set rather than a fork; operationally, the extensive backend and compatibility patches still create a meaningful upstream-maintenance burden.
2. **Infer:** MLX graph → backend primitives/compiled dispatch → Vulkan command encoder → Honeykrisp/Apple GPU. Custom kernel translation extends compatibility, but supported syntax/device capabilities must be checked per workload.
3. **Serve/chat:** catalog and approval → cache/conversion → memory admission/reservation → managed local server → loopback chat coordinator → browser or terminal. Typed decisions and generation are separate model roles.
4. **Speech:** verified model components → GPU/CPU frontend/control and qualified ANE encoder path → native worker/device. The external ANE driver is not installed by the ordinary mlx installer.

The clearest reusable ideas are the explicit no-silent-fallback error contract, atomic model-budget reservations, per-route numerical acceptance gates and source/wheel/driver provenance receipts. No source extraction accompanies this review. [S2–S10]

## Hardware and Performance Evidence

- **Supported installer scope:** aarch64 Python 3.14 on appropriate Arch/Asahi installations, targeting the M1 family and M2 Max. The README's measured machines are M1, M1 Max and M2 Max; other family members are not automatically qualified. The SoC check warns rather than proving compatibility.
- **M3/M4:** experimental. M4 receipts require an out-of-tree G16G kernel driver and Honeykrisp Apple9 compute port, not ordinary stock installation. The integration battery records **34 failures out of 800 cases**, including driver-rejected pipelines and two other failures; an expected-failure test also makes an exit-zero suite weaker than an all-green pass. Reported 64-token decode improvements are workload- and commit-specific. [S11]
- **Other GPUs:** an explicit development override admits qualifying Vulkan devices. A contributor reports Intel UHD 770 at 55/55 runtime tests and NVIDIA RTX 5060 Ti at 54/55 with a timing-floor miss and a recovery event. AMD lacks a qualifying run. This is development reach, not supported universal deployment. [S12]
- **macOS comparison:** the current benchmark document reports M1 Max Qwen3.5-9B at 37.1 versus 59.4 decode tokens/s (62%), and 299.4 versus 339.0 prefill tokens/s (88%). These are author measurements, not reproduced here. Other models differ in output, some driver versions were not recorded, several cells use different repeat counts, and the earlier committed full table contains older, slower figures. A single repo-wide speed ratio would be misleading. [S13]
- **Numerics matter:** the fused GDN audit reports 99.51% teacher-forced top-1 agreement but divergence in all ten longer free-runs. Some faster gather-qmm routes remain off after REJECT/WIDER numerical gates. This is refreshingly explicit, but short token parity or kernel equality is not broad model-quality validation. [S14]
- **Contention matters:** the project reports about 44% lower base-M1 GPU decode while ANE is busy, with unresolved cause and limited paired measurements. The latest published v0.7.35 notes a 5.6% batch-2 slowdown on M2 Max, even though larger batches improve. Do not combine a kernel microbenchmark, a driver upgrade and an end-to-end speedup as if they were one controlled comparison. [S14–S15]

## Network, Authentication and Privacy

**Local inference is the intended normal path.** There is no required hosted LLM account or remote macOS inference server in the inspected core path. Installation/model acquisition contacts GitHub, package repositories/PyPI and Hugging Face; optional voice/wake-word assets introduce further downloads. Hub authentication, if configured by an operator for restricted models, remains a separate external-library/account boundary. “Local” does not mean an air-gapped installation. [S5, S7]

**The browser assistant has meaningful local defenses:** forced 127.0.0.1 binding, exact Host and Origin validation, cross-site request rejection, one-use launch bootstrap, random session/CSRF values, timing-safe comparisons and HttpOnly/SameSite=Strict cookies. JSON/audio upload bounds and content-type checks are present. This is a single-user local control plane, not multi-tenant identity or protection against a hostile same-user process. [S16]

**The underlying inference API is a different boundary.** Serve defaults to loopback but permits a non-loopback host after warning that it has no authentication. Do not expose it to a LAN or tunnel merely because the chat UI has session protection. Use a separately reviewed authenticated transport/reverse proxy and appropriate network restrictions if remote access is genuinely needed; HTTP alone does not supply TLS. [S7]

**Saved content remains sensitive.** History is opt-in and stored locally as JSON, not encrypted by this application. Uninstall normally retains it and converted models. Microphone and wake-word modes are opt-in local capture surfaces, not a reason to leave microphones running unexpectedly. [S5, S16]

**Diagnostics are an explicit outbound path.** Collector uploads go to a public community service when requested; an environment-selected endpoint can also trigger interactive confirmation. Payload redaction and server scanning exist, but submit code also sends derived short host aliases in a request header for redaction checking. They are not intended to be stored publicly, yet they still leave the device. Preview archives, avoid sensitive machines, and distinguish “not in the public row” from “never transmitted.” Optional submit bearer credentials come from environment configuration. No diagnostics were run or submitted for this review. [S17]

## Installation, System Changes and Recovery

The README suggests piping a moving main-branch shell script to Bash. Prefer inspecting a fixed version first. The ordinary path resolves a latest release unless pinned, checks the wheel against release SHA256SUMS, creates/clears its private venv, installs system BLAS packages, installs Python dependencies, fetches additional scripts/modules from a release tag, applies mlx-lm patches and writes launchers, desktop integration and a login service. It is **not** a zero-system-change install. Wheel checksums are useful integrity evidence, but the same release authority supplies both artifact and checksum; fetched helper code and loosely pinned transitive packages are not covered by that single wheel check. The offline system-package lane has a stronger vendored hash-lock boundary. [S5]

Optional ANE setup writes a host-global tmpfiles policy and creates shared lock/quarantine state, and requires an existing accelerator device. Separate driver/firmware/device-tree enablement may entail privileged changes and reboot outside this repository's normal installer. Do not mistake its final device/module smoke for a real model execution proof. [S5, S10]

**Concrete current blocker:** issue [#311](https://github.com/joshuaswarren/omarchy-mlx/issues/311) reports v0.7.35's aarch64 wheel lacks the tmpfiles policy required by --ane. Maintainer comments confirm the packaging defect and source fix (#312), but explicitly say the published assets were not replaced and no corrected release was delivered by that work. Latest-release metadata still selected v0.7.35 during review. We did not download the wheel or reproduce the failure; this is corroborated public release evidence, not our runtime finding. [S15, S18]

Recovery is partial, not transactional: uninstall disables/removes the chat service and most user runtime files, retains history/pair locks/converted models unless purge is requested, and leaves the Hugging Face cache. It does not reverse system packages or external driver/firmware changes. Static inspection also shows the generated Parakeet launcher is absent from the uninstall removal list, so it can remain pointing at a removed venv. Because installation clears the venv before completion and has no full rollback, retain known-good artifacts/data and review service/custom launcher changes before upgrading. [S5]

## License, Dependencies and Model Terms

The root MIT license permits reuse subject to notice retention. Apple MLX and mlx-lm notices are carried under LICENSES; the coremltools notice has BSD-style redistribution conditions. External Mesa/kernel/ANE/compiler components retain their own terms and were not exhaustively audited here. An MLX or shader license does not grant rights to firmware or third-party model weights. [S19]

The catalog records per-model license metadata and pinned revisions; inspect each actual model card/license before downloading or redistributing, especially Gemma/Llama-family or other restricted checkpoints. Parakeet's reference lock specifically labels both the referenced model and speech fixture CC-BY-4.0; that attribution boundary is distinct from MIT code. Voice-model and wake-word licenses also need asset-level confirmation rather than assuming the Python package license covers weights. No models or code were redistributed with this review. [S8, S19]

Dependency strengths include the exact MLX archive pin, an external ANE compiler commit/hash, revision-aware model acquisition and an offline vendor path. Weaknesses include unpinned development dependencies, range/unpinned normal-install dependencies, mutable release/tag trust and version-coupled mlx-lm patches/shims. No vulnerability database or complete transitive dependency audit was performed.

## Tests, CI and Maturity

At review time public metadata showed 98 stars, 15 forks, creation on 2026-08-31 and a push on 2026-11-02; these are activity/discovery signals, not reliability evidence. GitHub's open_issues_count was 14 including pull requests. Latest published release was **v0.7.35, 2026-10-30**, distinct from the newer reviewed main SHA. Open reports include the released installer defect, batch-2 performance regression, upstream drift and ongoing M4 work. [S15, S18, S20]

This is not a README-only prototype: the tree has 142 test-named paths under tests and 114 files under overlay/tests (inventory counts, not passing-test counts). Inspected CI covers collectors on Linux/macOS and Python 3.11/3.14, Linux pytest, backend syntax/shader generation, custom-kernel translation and software-Vulkan vocabulary-tail tests. A weekly upstream compatibility workflow detects drift but is not a hardware qualification run. Actions use version tags rather than immutable action SHAs in the inspected workflows. Hardware performance/numerical evidence lives in separately generated receipts; CI configuration does not prove the current revision passed every gate. [S21]

Documentation is admirably candid but drifts between historical measurements, current main and releases: older tables differ from updated benchmark pages, README engine wording is broader than sushi's “in progress” row, and the generic serve CLI intentionally refuses oMLX despite separate measured oMLX integration. Evaluate the exact **wheel + source + driver + hardware + model revision**, not just the project name.

## Comparison

| Option | Prefer it when | Tradeoff against omarchy-mlx |
|---|---|---|
| [Upstream MLX / mlx-lm](https://github.com/ml-explore/mlx) on supported macOS | Native Apple platform and minimum downstream-patch burden matter more than Linux | Does not supply this Honeykrisp Linux backend; not a reason to assume matching performance or outputs |
| [llama.cpp Vulkan](https://github.com/ggml-org/llama.cpp) | GGUF serving and broader backend portability are the main requirement | Same Apple Linux driver constraints can still apply; less MLX Python compatibility, often competitive model-dependent results |
| Upstream MLX CUDA or CPU on ordinary Linux | NVIDIA or CPU is the actual target | Avoids the Apple-specific supported path; this project's non-Apple Vulkan switch is a development option, not an automatic improvement |
| [oMLX](https://github.com/jundot/omlx) with the documented Linux adaptations | Its server/offload features justify a separate qualified setup | Separate integration evidence exists, but the unified serve CLI refuses it until context admission can be enforced |

Related public reviews: [Laya MLX](laya-mlx.md) covers a different macOS-oriented model port; [TensorFold](tensorfold.md) is an engine review, not proof of every patched Linux integration mentioned here.

## Practical Adoption Gate

For an enthusiast with an existing M1/M1 Max/M2 Max Linux machine, start with a pinned GPU-only release, a small already-qualified model and loopback-only serving. Verify device/driver identity, numerics, model-specific throughput, long-context memory behavior and restart/uninstall recovery before relying on it. Do not infer that main-only fixes are present in the latest wheel. Wait for a verified corrected public ARM asset before treating --ane as turnkey. M3/M4, unqualified chips, arbitrary Core ML packages and non-Apple GPUs belong in a development lane.

**Bottom line:** useful and substantive accelerator work with stronger-than-usual evidence discipline; not a universal MLX-on-Linux compatibility promise, production service security boundary or guaranteed macOS-performance replacement.

## Evidence and Verification Limits

All source links below are pinned to the reviewed SHA except explicitly live release/issue/API references retrieved on 2026-11-02. Source code, documentation and selected receipts were inspected; no claim here that every one of the 5,156 tracked files was audited. External drivers, release binaries, model assets, hardware stability and performance remain unverified independently. No tests were run, and no dependencies installed.

- **S1:** [README.md](https://github.com/joshuaswarren/omarchy-mlx/blob/32ed79d7d834e7bdec2ac74d15d0d295c9fa1ce8/README.md)
- **S2:** [scripts/prepare-mlx.sh](https://github.com/joshuaswarren/omarchy-mlx/blob/32ed79d7d834e7bdec2ac74d15d0d295c9fa1ce8/scripts/prepare-mlx.sh); [mlx.lock](https://github.com/joshuaswarren/omarchy-mlx/blob/32ed79d7d834e7bdec2ac74d15d0d295c9fa1ce8/mlx.lock)
- **S3:** [overlay/mlx/backend/omarchy/device.cpp](https://github.com/joshuaswarren/omarchy-mlx/blob/32ed79d7d834e7bdec2ac74d15d0d295c9fa1ce8/overlay/mlx/backend/omarchy/device.cpp); [overlay/mlx/backend/omarchy/allocator.cpp](https://github.com/joshuaswarren/omarchy-mlx/blob/32ed79d7d834e7bdec2ac74d15d0d295c9fa1ce8/overlay/mlx/backend/omarchy/allocator.cpp); [overlay/mlx/backend/omarchy/custom_kernel.cpp](https://github.com/joshuaswarren/omarchy-mlx/blob/32ed79d7d834e7bdec2ac74d15d0d295c9fa1ce8/overlay/mlx/backend/omarchy/custom_kernel.cpp)
- **S4:** [patches/mlx-no-silent-cpu-fallback.patch](https://github.com/joshuaswarren/omarchy-mlx/blob/32ed79d7d834e7bdec2ac74d15d0d295c9fa1ce8/patches/mlx-no-silent-cpu-fallback.patch); [overlay/mlx/backend/omarchy/unsupported.h](https://github.com/joshuaswarren/omarchy-mlx/blob/32ed79d7d834e7bdec2ac74d15d0d295c9fa1ce8/overlay/mlx/backend/omarchy/unsupported.h)
- **S5:** [install.sh](https://github.com/joshuaswarren/omarchy-mlx/blob/32ed79d7d834e7bdec2ac74d15d0d295c9fa1ce8/install.sh)
- **S6:** [serve/mlx_omarchy_assistant/theme.py](https://github.com/joshuaswarren/omarchy-mlx/blob/32ed79d7d834e7bdec2ac74d15d0d295c9fa1ce8/serve/mlx_omarchy_assistant/theme.py)
- **S7:** [serve/mlx_omarchy_serve/__main__.py](https://github.com/joshuaswarren/omarchy-mlx/blob/32ed79d7d834e7bdec2ac74d15d0d295c9fa1ce8/serve/mlx_omarchy_serve/__main__.py); [serve/mlx_omarchy_serve/budget.py](https://github.com/joshuaswarren/omarchy-mlx/blob/32ed79d7d834e7bdec2ac74d15d0d295c9fa1ce8/serve/mlx_omarchy_serve/budget.py); [serve/mlx_omarchy_serve/_mlxlm_server.py](https://github.com/joshuaswarren/omarchy-mlx/blob/32ed79d7d834e7bdec2ac74d15d0d295c9fa1ce8/serve/mlx_omarchy_serve/_mlxlm_server.py)
- **S8:** [serve/mlx_omarchy_serve/catalog.json](https://github.com/joshuaswarren/omarchy-mlx/blob/32ed79d7d834e7bdec2ac74d15d0d295c9fa1ce8/serve/mlx_omarchy_serve/catalog.json); [docs/ENGINES.md](https://github.com/joshuaswarren/omarchy-mlx/blob/32ed79d7d834e7bdec2ac74d15d0d295c9fa1ce8/docs/ENGINES.md)
- **S9:** [overlay/tools/mlx-omarchy-ane-worker/main.cpp](https://github.com/joshuaswarren/omarchy-mlx/blob/32ed79d7d834e7bdec2ac74d15d0d295c9fa1ce8/overlay/tools/mlx-omarchy-ane-worker/main.cpp); [overlay/tools/mlx-omarchy-parakeet/mlx_omarchy_parakeet.py](https://github.com/joshuaswarren/omarchy-mlx/blob/32ed79d7d834e7bdec2ac74d15d0d295c9fa1ce8/overlay/tools/mlx-omarchy-parakeet/mlx_omarchy_parakeet.py)
- **S10:** [docs/ANE-LINUX.md](https://github.com/joshuaswarren/omarchy-mlx/blob/32ed79d7d834e7bdec2ac74d15d0d295c9fa1ce8/docs/ANE-LINUX.md)
- **S11:** [receipts/2026-11-01-m4-g16g-part1/README.md](https://github.com/joshuaswarren/omarchy-mlx/blob/32ed79d7d834e7bdec2ac74d15d0d295c9fa1ce8/receipts/2026-11-01-m4-g16g-part1/README.md)
- **S12:** [docs/compatibility.md](https://github.com/joshuaswarren/omarchy-mlx/blob/32ed79d7d834e7bdec2ac74d15d0d295c9fa1ce8/docs/compatibility.md)
- **S13:** [docs/BENCHMARKS.md](https://github.com/joshuaswarren/omarchy-mlx/blob/32ed79d7d834e7bdec2ac74d15d0d295c9fa1ce8/docs/BENCHMARKS.md); [receipts/2026-10-09-linux-vs-macos/table-full.md](https://github.com/joshuaswarren/omarchy-mlx/blob/32ed79d7d834e7bdec2ac74d15d0d295c9fa1ce8/receipts/2026-10-09-linux-vs-macos/table-full.md)
- **S14:** [docs/KNOWN-ISSUES.md](https://github.com/joshuaswarren/omarchy-mlx/blob/32ed79d7d834e7bdec2ac74d15d0d295c9fa1ce8/docs/KNOWN-ISSUES.md); [docs/DRIVER-AND-KERNEL.md](https://github.com/joshuaswarren/omarchy-mlx/blob/32ed79d7d834e7bdec2ac74d15d0d295c9fa1ce8/docs/DRIVER-AND-KERNEL.md)
- **S15:** [Public metadata / discussion](https://github.com/joshuaswarren/omarchy-mlx/releases/tag/v0.7.35)
- **S16:** [serve/mlx_omarchy_assistant/server.py](https://github.com/joshuaswarren/omarchy-mlx/blob/32ed79d7d834e7bdec2ac74d15d0d295c9fa1ce8/serve/mlx_omarchy_assistant/server.py); [serve/mlx_omarchy_assistant/history.py](https://github.com/joshuaswarren/omarchy-mlx/blob/32ed79d7d834e7bdec2ac74d15d0d295c9fa1ce8/serve/mlx_omarchy_assistant/history.py)
- **S17:** [scripts/collect_submit.py](https://github.com/joshuaswarren/omarchy-mlx/blob/32ed79d7d834e7bdec2ac74d15d0d295c9fa1ce8/scripts/collect_submit.py); [scripts/collect_quick.py](https://github.com/joshuaswarren/omarchy-mlx/blob/32ed79d7d834e7bdec2ac74d15d0d295c9fa1ce8/scripts/collect_quick.py); [docs/contribute-data.md](https://github.com/joshuaswarren/omarchy-mlx/blob/32ed79d7d834e7bdec2ac74d15d0d295c9fa1ce8/docs/contribute-data.md)
- **S18:** [Public metadata / discussion](https://github.com/joshuaswarren/omarchy-mlx/issues/311)
- **S19:** [LICENSE](https://github.com/joshuaswarren/omarchy-mlx/blob/32ed79d7d834e7bdec2ac74d15d0d295c9fa1ce8/LICENSE); [LICENSES/coremltools.txt](https://github.com/joshuaswarren/omarchy-mlx/blob/32ed79d7d834e7bdec2ac74d15d0d295c9fa1ce8/LICENSES/coremltools.txt); [LICENSES/MLX.txt](https://github.com/joshuaswarren/omarchy-mlx/blob/32ed79d7d834e7bdec2ac74d15d0d295c9fa1ce8/LICENSES/MLX.txt); [LICENSES/mlx-lm.txt](https://github.com/joshuaswarren/omarchy-mlx/blob/32ed79d7d834e7bdec2ac74d15d0d295c9fa1ce8/LICENSES/mlx-lm.txt); [overlay/tools/coreml/parakeet-reference.lock](https://github.com/joshuaswarren/omarchy-mlx/blob/32ed79d7d834e7bdec2ac74d15d0d295c9fa1ce8/overlay/tools/coreml/parakeet-reference.lock); [ane-compiler.lock](https://github.com/joshuaswarren/omarchy-mlx/blob/32ed79d7d834e7bdec2ac74d15d0d295c9fa1ce8/ane-compiler.lock)
- **S20:** [Public metadata / discussion](https://api.github.com/repos/joshuaswarren/omarchy-mlx)
- **S21:** [.github/workflows/collectors.yml](https://github.com/joshuaswarren/omarchy-mlx/blob/32ed79d7d834e7bdec2ac74d15d0d295c9fa1ce8/.github/workflows/collectors.yml); [.github/workflows/omarchy-syntax.yml](https://github.com/joshuaswarren/omarchy-mlx/blob/32ed79d7d834e7bdec2ac74d15d0d295c9fa1ce8/.github/workflows/omarchy-syntax.yml); [.github/workflows/upstream-compat.yml](https://github.com/joshuaswarren/omarchy-mlx/blob/32ed79d7d834e7bdec2ac74d15d0d295c9fa1ce8/.github/workflows/upstream-compat.yml)

---

**Attribution:** Joshua Warren and contributors, joshuaswarren/omarchy-mlx. MIT project code; third-party notices and model terms as described above.
