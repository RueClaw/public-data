# vork (voyager-so/vork)

**Repo:** https://github.com/voyager-so/vork
**License:** Custom vork Preview License; source-available, not open source. Commercial internal use is allowed; modified redistribution and third-party rendering services require permission.
**Reviewed:** 2026-11-07 (UTC)
**Revision:** 44188baab29ad1c174c9e949c982d9edb45308fc (main; repository-wide static sampling, with emphasis on CLI, scene schema, renderer, compiler, SDKs, installers and benchmarks). Commit dated 2026-11-07 UTC.
**Verification:** Static review only. No builds, source tests, installers, GPU rendering, asset downloads or benchmark runs performed.
**Stack:** Rust 2024 / Rust 1.96, Slang 2026.20, wgpu 29 with native Vulkan/Metal paths, Python and TypeScript authoring SDKs, OIDN, FFmpeg/native video encoding.
**What it is:** Voyager's headless 3D and VFX rendering kernel for code-writing agents: declarative scenes and programmable GPU stages become stills, control passes and movies. It is not an agent harness, model, desktop editor or general-purpose execution sandbox.

---

## Verdict

⚠️ **Interesting — a substantive agent-friendly renderer, suitable for a bounded creative pilot rather than an assumed Blender replacement.** The retained scene architecture, generated schema/help and programmable camera/material/compute hooks are real implementation features. Narrow GPU support, research-preview rendering limits, unreproduced unequal-quality benchmarks and a restrictive service/distribution license are material adoption gates.

Try it for owned scenes and iterative previews on explicitly supported hardware. Keep Blender/Cycles or another established pipeline available for demanding transport, volumes, interchange and recovery; do not build a public render service around the preview license without permission.

## What It Is

An external agent writes scene JSON, optionally using Python or TypeScript helpers, invokes the native CLI, inspects the rendered image and revises the scene. There is no embedded LLM or required model-provider key in the inspected render path. Agent intelligence and any image-model assets belong to the surrounding workflow, not to the rendering kernel.

Scene API v2 separates content from render profiles. The standard previs/draft/final/path profiles trade fidelity and cost; the default hybrid renderer combines raster visibility and ray-traced lighting, while path tracing is a separate choice. Assets can be imported from glTF, and libraries/examples cover simulation, compositing, camera effects and VFX on real footage. These are executable graphics workflows, not generative-video inference. The README explicitly identifies image-model-painted backgrounds in one showcase and qualifications on other demos. [E1–E4]

## Stack

| Layer | Technology / role |
|---|---|
| Entry point | Clap CLI: render, setup, std and topic/field help |
| Scene contract | Serde/schemars scene v2, validation, generated SDK types and JSON Schema |
| Renderer | Rust, wgpu 29, Vulkan/Metal, native ray queries, retained GPU scene and per-frame values |
| Programs | Pinned Slang compiler; generated shader modules, reflection and program ABI |
| Standard library | Native geometry/text/environment helpers and embedded QuickJS for shared functions |
| Output | PNG, EXR/control outputs; NVENC/VideoToolbox or FFmpeg fallback |
| Persistence | Files, immutable SDK buffer sidecars, content-keyed BLAKE3-checked disk cache; no database |

## Key Features

### An interface designed for iterative code generation

The CLI exposes short progressive help, exact field help, named render profiles and structured scene validation. Scene structs reject unknown fields in inspected definitions, and reference/name/resource validation runs before rendering. Python/TypeScript types derive from the scene contract rather than being unrelated hand-written APIs. This reduces spelling and schema drift; it does not ensure that an agent's composition is artistically correct or that a supported scene fits VRAM. [E2, E3]

### Retained scene resources and programmable rendering

The install step creates an immutable GPU scene and effect plan; frame processing supplies animation and changing values instead of rebuilding every resource. Slang hooks cover camera, materials, propagation, display/compositing and compute-based geometry/simulation. This is the most useful architectural distinction from driving an editor through clicks. CPU parsing, planning, animation evaluation and I/O remain necessary; “GPU” is not “CPU-free.” [E4, E5]

### Actual preview limits, not just a roadmap disclaimer

The current install code deliberately strips participating-media bindings and volume geometry, warning that they are ignored. Extra environment lights are also reduced to the first one in that path. Thus the presence of volume-related source modules is not proof of usable volume rendering in this release. The README documents allocation failures on dense scenes, quality losses at four/eight samples, long compilation stalls, and limited water simulation. More samples cannot restore omitted indirect transport. [E1, E4]

## Architecture

The main flow is:

1. CLI/SDK authors or loads scene JSON and selects a profile and output paths.
2. Scene/standard-library expansion normalizes geometry and resource references; validation checks structure and relationships.
3. Renderer installation imports assets, compiles programs, builds acceleration/resources and derives the effect plan.
4. Retained resources are reused across ordered frame work; native encoders can keep video on GPU, with readback fallbacks.
5. Output workers encode/write frames, and cache entries preserve expensive intermediate work.

Seven Rust workspace crates divide CLI, scene, standard library, mesh processing, Slang, rendering and encoding. The renderer remains a large, tightly coupled subsystem with many inline regression modules. Vendored wgpu family patches, EXR bounds changes and Basis compression changes have provenance files; this improves inspectability but makes upstream updates a maintenance responsibility. GPU/FFI code and dynamic native libraries mean Rust alone is not an isolation guarantee. [E2, E4–E6]

## Execution, Permissions, Network and Privacy

**The trust boundary is the operating-system process, not the scene document.** Asset and shader paths are resolved for use, not confined to a dedicated scene root. SDK path rewriting intentionally permits relative paths outside the scene directory. Slang runs as a subprocess and uses authored module origins for imports. Python/TypeScript authoring programs are ordinary host code; their helpers are not an execution sandbox. Only the embedded standard-library QuickJS context has the narrower no-host-binding boundary. [E3, E5, E7]

The inspected SDK render calls use argument arrays rather than concatenating a shell command, which avoids that common injection class. However, executable selection through VORK_BIN, Slang selection through VORK_SLANGC and native tools on PATH remain trusted configuration. Unix compiler subprocesses use a process-group guard to prevent orphaned compilers after the parent dies; that is lifecycle cleanup, not CPU/VRAM quotas or a filesystem jail. The non-Unix compiler path simply spawns the process. [E5, E7]

There is no HTTP service/auth/CORS layer in the inspected CLI architecture. That is appropriate for a local renderer, not evidence that arbitrary remote jobs are safe. No account, telemetry uploader or provider-credential flow was identified in the sampled core path; this is not a network trace or a whole-dependency privacy certification. Installers and example preparation recipes do download software/assets. Video input invokes FFmpeg/ffprobe without an explicit protocol allowlist in the inspected calls, so local-looking media inputs should not be treated as a guaranteed no-network boundary. External authoring agents can separately transmit scene content to their providers. [E1, E7, E8]

For untrusted scenes/assets, use a secret-free worker, read-only approved inputs, a separate output/cache directory, denied outbound networking and external time/memory/process limits. GPU exposure and native image/video/compiler parsers still enlarge the attack surface. This review did not demonstrate an exploit or certify these components against hostile media.

## Data Preservation and Recovery

SDK scene writes are thoughtfully ordered: immutable UUID buffer sidecars are written first, then a temporary JSON file atomically replaces the destination. Existing destination symlinks are rejected, new files are private, and old sidecars are retained for concurrent readers. This avoids replacing a reader's backing buffers midway through a save. It also accumulates old/orphan sidecars; these are not automatic scene-history snapshots, and the inspected writes do not establish power-loss durability through explicit fsync. Back up the scene plus all referenced assets/sidecars. [E7]

The renderer cache has integrity hashes, version/content keys, a store lock, temporary-file publication and budget-based eviction. It is regenerable acceleration state, not a backup. In particular, eviction considers .entry files in the configured cache directory, so dedicate VORK_CACHE_DIR to this tool rather than pointing it at a general data folder. [E9]

Rendered PNG/EXR files use direct writes in the output worker, unlike the SDK's atomic scene publication. Do not assume an interrupted render leaves an old destination intact or produces a transactionally complete image sequence. Use a new run directory, verify expected frames, then promote accepted outputs. The inspected interface supports frame ranges, but that is not a proven general checkpoint/resume system for stateful simulation. [E10]

The Unix installer verifies a release checksum and stages a complete install tree, testing --version before replacing the old tree. The old install is retired and deleted by cleanup, and GPU setup occurs after replacement. A setup failure explicitly leaves the new version installed; there is no automatic rollback to the prior working GPU setup. Retain the old archive/version if rollback matters. Default installation also appends PATH entries to shell startup files; custom PREFIX or VORK_NO_MODIFY_PATH opts out. Nothing was installed during this review. [E8]

## Claims and Evidence

| Claim / impression | Evidence and qualification |
|---|---|
| Agent-friendly rendering | CLI, schema, SDKs and program hooks substantiate the interface; no independent agent-success study was performed. |
| Faster than Blender | Vendor final-profile warm timings include selected 1.14–2.32× movie ratios, but quality/sample/denoising and startup boundaries differ. Not equal-quality speedups. |
| Million simulated birds | Example compute programs and recorded workflow exist; Blender figures are sparse-frame projections, not complete measured movies. |
| Fast path tracing | Carried-forward path measurements are actually 5.81× and 1.99× slower than Cycles for two reported scenes. |
| Reproducible benchmark | Public runner omits the historical draft profile/seed and forces denoise=false; Blender helper is documented broken on 5.2.1. Historical tables are not currently reproducible by those commands. |
| Physical correctness | Analytic-oracle and numerical/regression test source exists; no independent executed result or broad correctness guarantee follows. |

The tables primarily describe frozen build 81ae2b075 or earlier freezes, not the reviewed HEAD. The reported sweep delivered 583/585 images, with a million-stars allocation failure in both profiles; 19 earlier comparisons failed their no-worse FLIP condition. These unusually candid qualifications are valuable, but do not rescue the missing independent rerun. Setup/warmup can cost minutes, and new shaders can compile long after initial setup. [E1, E11]

## Tests, CI and Maturity

Public GitHub metadata retrieved 2026-11-07: repository created 2026-11-05; last push 2026-11-07; 787 stars, 49 forks and one open issue/PR in the repository aggregate. Release v0.1.0 was published 2026-11-06. These are a fresh public launch's popularity/activity signals, not production validation. The shallow clone does not establish the full development history. [E12]

The tree includes CLI invalid-scene/help/range/output tests, standard-library property tests, SDK serialization/render-option tests, installer/package tests, and renderer analytic/GPU/regression tests. Examples include independent trilinear-field and brute-force geometry oracles. No GitHub Actions workflow files were present under .github/workflows at the reviewed SHA; build documentation's references to CI are not independently verifiable public workflow evidence. Cargo.lock, dependency policy and pinned Slang/OIDN distribution metadata are positive reproducibility inputs. No dependency vulnerability audit or binary/notarization validation was performed. [E2, E6, E13]

**Tests run: none.** Static acquisition, source inspection and review-artifact checks must not be confused with upstream test results. Rendering quality, runtime safety, performance and platform compatibility remain unverified here.

## License and Reuse

Copyright is attributed to Nullframe, Inc.; the public project is voyager-so/vork. The custom Preview License allows free use including commercial work, private modification, and unmodified redistribution with notices. It prohibits distributing modified versions, selling/licensing the software, and offering a hosted/managed service where others submit scenes/code/jobs without permission. Rendering internally and delivering finished media to clients is explicitly allowed. Rights for this version survive a later version's change to paid terms. Contributions grant broad perpetual relicensing rights to the company. [E14]

The Blender bridge is separately GPL-3.0-or-later; third-party libraries and example assets retain their own terms. NOTICE is substantial, and showcase assets include CC BY, CC BY-SA, CC0 and footage-specific licenses. A renderer license does not grant unrestricted rights to demo assets or all generated derivatives. No upstream code/assets were extracted into this review. This is not an OSI-open-source fork/service foundation.

## Comparison

| Option | Best fit | Tradeoff against vork |
|---|---|---|
| [Blender](https://www.blender.org/) / EEVEE / Cycles | Broad production authoring, mature simulation/compositing and established interchange | Larger UI/Python API surface, but supports headless scripting too; stronger default choice when completeness and ecosystem outweigh compact agent help. |
| [Mitsuba 3](https://github.com/mitsuba-renderer/mitsuba3) | Research-grade programmable/differentiable light transport | Different focus from quick hybrid VFX/movie authoring; useful when transport experimentation matters most. |
| [Three.js](https://github.com/mrdoob/three.js) | Browser-delivered interactive graphics | Much easier web distribution; not a direct replacement for this offline ray-traced VFX/encoding pipeline. |

Within this library, [ManimGX](manimgx.md) is a closer comparison for code-authored educational animation, not a general VFX substitute. The choice should follow output type and fidelity, not the shared “agent-native” label.

## Self-Hosting / Local Operation Notes

This is a local executable distribution, not a ready-made web deployment. Published requirements are Linux x64 with glibc 2.35+ and suitable libstdc++, or Windows x64, with a supported NVIDIA hardware-ray-tracing Vulkan GPU; Apple Silicon uses Metal with macOS 26 required by the bundled Slang toolchain. Intel Mac, Linux ARM and software Vulkan are not qualified paths. NVIDIA data-center accelerators without the required ray tracing are not made suitable merely by being newer. [E1, E15]

Keep Slang, OIDN, libraries, notices and SDK companions together. Linux video output needs FFmpeg even when NVENC supplies encoding; input videos need ffprobe too. Mac H.264 can use VideoToolbox. Source builds require Rust 1.96, a native C/C++ toolchain/libclang and separately provisioned pinned Slang. SDKs require Python 3.11+ or Node 22.18+; the npm package named vork is unrelated, and the shipped TypeScript import is @usevoyager/vork. Avoid an accidental namesake package install.

Acceptance gates for a pilot: verify actual GPU/driver/compiler compatibility, render a representative interior/transparency/simulation shot, measure cold and warm wall time including setup, inspect outputs at equal quality, interrupt and recover a run, and check the license against the intended internal/client/service use. Do not promise performance or production readiness before those checks.

## Evidence / Source Map

All source links below are pinned to the reviewed revision unless marked live metadata.

- **E1:** [README: demos, limits, measurements and installation](https://github.com/voyager-so/vork/blob/44188baab29ad1c174c9e949c982d9edb45308fc/README.md).
- **E2:** [Workspace manifest](https://github.com/voyager-so/vork/blob/44188baab29ad1c174c9e949c982d9edb45308fc/Cargo.toml), [CLI entry point](https://github.com/voyager-so/vork/blob/44188baab29ad1c174c9e949c982d9edb45308fc/crates/vork-cli/src/main.rs).
- **E3:** [Scene v2 validation](https://github.com/voyager-so/vork/blob/44188baab29ad1c174c9e949c982d9edb45308fc/crates/vork-scene/src/v2/mod.rs), [standard-library boundary](https://github.com/voyager-so/vork/blob/44188baab29ad1c174c9e949c982d9edb45308fc/crates/vork-std/src/lib.rs).
- **E4:** [Installation and ignored media](https://github.com/voyager-so/vork/blob/44188baab29ad1c174c9e949c982d9edb45308fc/crates/vork-render/src/install.rs), [effect plan](https://github.com/voyager-so/vork/blob/44188baab29ad1c174c9e949c982d9edb45308fc/crates/vork-render/src/plan.rs).
- **E5:** [Slang compiler and subprocess lifecycle](https://github.com/voyager-so/vork/blob/44188baab29ad1c174c9e949c982d9edb45308fc/crates/vork-slang/src/lib.rs).
- **E6:** [Vendored dependencies](https://github.com/voyager-so/vork/tree/44188baab29ad1c174c9e949c982d9edb45308fc/vendor), [dependency policy](https://github.com/voyager-so/vork/blob/44188baab29ad1c174c9e949c982d9edb45308fc/deny.toml).
- **E7:** [TypeScript scene writer](https://github.com/voyager-so/vork/blob/44188baab29ad1c174c9e949c982d9edb45308fc/packages/ts/src/index.ts), [Python SDK](https://github.com/voyager-so/vork/blob/44188baab29ad1c174c9e949c982d9edb45308fc/packages/python/vork/__init__.py), [video decoder](https://github.com/voyager-so/vork/blob/44188baab29ad1c174c9e949c982d9edb45308fc/crates/vork-render/src/footage.rs).
- **E8:** [Unix installer](https://github.com/voyager-so/vork/blob/44188baab29ad1c174c9e949c982d9edb45308fc/install.sh).
- **E9:** [Disk-cache integrity, publication and eviction](https://github.com/voyager-so/vork/blob/44188baab29ad1c174c9e949c982d9edb45308fc/crates/vork-render/src/disk_cache.rs).
- **E10:** [Output writing](https://github.com/voyager-so/vork/blob/44188baab29ad1c174c9e949c982d9edb45308fc/crates/vork-render/src/png_output.rs), [shot lifecycle](https://github.com/voyager-so/vork/blob/44188baab29ad1c174c9e949c982d9edb45308fc/crates/vork-render/src/shot.rs).
- **E11:** [Benchmark method and known reproduction failure](https://github.com/voyager-so/vork/blob/44188baab29ad1c174c9e949c982d9edb45308fc/benchmarks/README.md), [recorded results](https://github.com/voyager-so/vork/blob/44188baab29ad1c174c9e949c982d9edb45308fc/benchmarks/RESULTS.md).
- **E12:** [Public repository metadata](https://api.github.com/repos/voyager-so/vork), [releases](https://github.com/voyager-so/vork/releases) (live, retrieved 2026-11-07).
- **E13:** [CLI tests](https://github.com/voyager-so/vork/tree/44188baab29ad1c174c9e949c982d9edb45308fc/crates/vork-cli/tests), [renderer source/test modules](https://github.com/voyager-so/vork/tree/44188baab29ad1c174c9e949c982d9edb45308fc/crates/vork-render/src), [SDKs](https://github.com/voyager-so/vork/tree/44188baab29ad1c174c9e949c982d9edb45308fc/packages), [.github tree](https://github.com/voyager-so/vork/tree/44188baab29ad1c174c9e949c982d9edb45308fc/.github).
- **E14:** [License](https://github.com/voyager-so/vork/blob/44188baab29ad1c174c9e949c982d9edb45308fc/LICENSE), [third-party notices](https://github.com/voyager-so/vork/blob/44188baab29ad1c174c9e949c982d9edb45308fc/NOTICE).
- **E15:** [Build requirements](https://github.com/voyager-so/vork/blob/44188baab29ad1c174c9e949c982d9edb45308fc/docs/help/build.md).

---

**Attribution:** voyager-so/vork / Nullframe, Inc.; vork Preview License, with separately licensed dependencies, Blender bridge and assets. Independent analysis; not an endorsement or legal opinion.
