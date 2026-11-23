# Fugue (bmaltais/fugue)

**Repo:** https://github.com/bmaltais/fugue
**License:** MIT application code; dependencies, model weights and input/output rights are separate.
**Reviewed:** 2026-11-23 (UTC)
**Revision:** 6fdbb95f42b5f34b278e1b251c60b86b25014fc6 — main and tag v0.1.0-test3; application, engine, helper, packaging, CI and selected tests/docs. Submodules were not initialized.
**Verification:** Static source inspection and unauthenticated public GitHub metadata only. No application builds/tests, installation, model downloads, inference, playback, hardware access or live service probes.
**Stack:** C++17, Qt6/Qt Quick/QML, CMake, libvips, libarchive, FFmpeg, Vulkan/CUDA and a patched stable-diffusion.cpp helper.
**What it is:** A native Omarchy/Arch desktop node-graph editor and headless CLI for composing local or paired-host AI media workflows—not the similarly named distributed-data Python project.

---

## Verdict

⚠️ **Interesting — a substantive native workflow engine, not yet a deployment recommendation.** Its shared GUI/CLI engine, typed graph compilation, content-addressed results and process-separated generation are worthwhile. The exact reviewed release has failing Test CI on both architectures, unsigned packages, and intentionally unsandboxed extension execution. Evaluate only with trusted packs and non-sensitive material until those boundaries and release reliability meet your needs.

## What It Is

Bernard Maltais's Fugue connects prompts, models, images, masks and media-processing nodes into workflows. A Qt Quick canvas provides editing, groups, templates, progress and results; the same binary offers JSON-oriented commands for agents and scripts. Omarchy local-AI integration discovers providers on the local machine and paired hosts. Third-party node programs speak JSON over stdin/stdout; providers use HTTP or stdio manifests. [S1–S4]

This is a v0.1 test release, not a hosted AI service or a model itself. Image generation/editing, text generation, masking, crop/stitch, upscaling and audio/video-oriented modules exist in the tree. Their existence is evidence of implementation, not independent proof of output quality, supported-model completeness, latency or VRAM efficiency. The README explicitly describes layered-image canvases as CLI functionality with the window still to come; do not confuse that with the implemented node-graph canvas. [S1, S4]

## Stack

| Layer | Implementation |
|---|---|
| Interface | Qt Quick/QML desktop; headless CLI selected before QGuiApplication |
| Engine | C++17 document/compiler/scheduler, typed ports, registry and providers |
| Media | libvips, FFmpeg/ffprobe, Qt multimedia; libarchive share packages |
| Inference | Separate patched stable-diffusion.cpp helper; Omarchy and module providers |
| State | JSON files, JSONL events, content-addressed file caches and advisory locks; no database service required |
| Build/distribution | CMake, Arch PKGBUILD, x86_64/aarch64 test packages; optional CUDA helper |

## Key Features and Evidence

- **One execution model for desktop and agents:** CMake separates headless engine/CLI libraries from GUI code; compiler validation includes port compatibility, cycles, recursive groups, versions and pack trust when supplied by the caller. [S2, S3]
- **Resource-aware scheduling:** scheduler code and interface describe CPU parallelism, serialized GPU/provider lanes, resident-model preference, out-of-memory eviction/retry, branch-local failure and cancellation. Cache hits avoid kernel execution. This is implementation evidence, not a performance benchmark. [S3]
- **Reusable and shareable workflows:** nested groups, templates and ZIP-based .fuguepack exports package workflow inputs while referring to model hashes rather than embedding weights. Import rejects unsafe paths, links and non-regular files, caps entries at 10,000 and expanded data at 4 GiB. Those are useful defenses, not a complete archive-parser audit. [S5]
- **Model integrity and resumability:** downloads use partial files, retries/range requests, SHA-256 verification and rename-on-success. HTTPS is accepted generally; HTTP is allowed for loopback. A matching hash proves identity relative to the supplied manifest, not model safety, licensing or publisher authenticity. [S6]

## Architecture

A workflow document becomes a flattened compiled graph; groups resolve into node paths and typed links. The scheduler resolves inputs/providers/models, computes cache keys and runs built-in kernels or external command nodes in dependency order. Outputs become cached objects and run metadata. The GUI uses the same engine as CLI workers rather than maintaining a separate execution implementation. [S2–S4]

The inference helper is a separate executable. Its CMake project pins stable-diffusion.cpp to 532d2c15c430a785a712b2d94281f04e733008a4, ggml and CUTLASS to specific commits and SHA-256 archive hashes. This separation limits build coupling and lets the UI survive some helper failures; it is not a privilege sandbox. Provider modules can start programs on demand or contact an HTTP address. [S7, S8]

## Permissions, Authentication and Execution Boundaries

**Packs run as the desktop user.** The documentation explicitly says network/files/GPU declarations are advisory, not enforced permissions. Command nodes inherit the process environment, adding Fugue protocol/work-directory variables; malicious extensions can therefore access user-readable files and inherited credentials. A process group, cancellation and timeouts are lifecycle controls, not containment. The built-in and local packs are always trusted. Other trust decisions are stored by pack ID/version, not an immutable publisher signature. A loaded node seal detects changes between load and execution, but does not turn the extension system into a sandbox. [S9]

**“Agents cannot install packs” needs qualification.** The CLI refuses pack changes without terminal confirmation, using isatty on stdin/stderr and a yes/no prompt. This prevents ordinary noninteractive invocation; it does not authenticate a human against automation controlling a PTY or a process running as the same OS user. Treat it as an interaction safeguard, not an authorization boundary. Provider manifests with start commands are also executable trust inputs. [S8, S9]

**Remote helper auth is a shared bearer key.** The HTTP helper checks Authorization before routing and refuses group/world-accessible key files. The client blocks redirects that could carry the key elsewhere. The server is plain httplib HTTP, not TLS; its service example recommends binding to a tailnet address rather than all interfaces. Use a trusted encrypted network path, protect keys and avoid public exposure. This is not a multi-user/RBAC service; no browser-facing CORS security guarantee was established. [S10]

## Credentials, Privacy and Egress

Provider configuration persists addresses and keys in JSON, atomically written with mode 0600. That is file access control, not encryption or a credential vault. Keys also necessarily enter process memory and request headers. Prompt/media inputs leave the machine when remote providers are used; model downloads contact source hosts, and pack installation/update can contact Git repositories and run approved setup commands. “Local AI” does not mean all configurations are offline. No comprehensive telemetry-absence claim is made. [S6, S8–S11]

FUGUE_HOME redirects XDG state/data/cache/runtime, temporary files and selected GPU caches; projects can inherit models/packs/preferences but exclude provider keys and several result/history categories. This is organization and cooperative write redirection, not encrypted private mode or filesystem isolation. It deliberately preserves desktop sockets, and command nodes retain the ordinary environment. Private-mode research documents are proposals/audits with explicit uncertainties, not evidence that sandboxing or encrypted vaults ship. [S12]

Prompts, workflow paths, generated media, recovery copies, run metadata and cached results can remain on disk. A shared workflow package includes input media: inspect it before distribution. Same-user extensions, desktop integrations and remote providers remain outside any claimed confidentiality boundary. [S3, S5, S12, S13]

## Persistence and Recovery

Run directories contain run.json, compiled.json and events.jsonl; completed outputs enter the result cache. The queue uses small atomically replaced JSON files and advisory locks, with PID/start-time/boot-time checks for stale entries and cross-root GPU coordination. RecoveryStore keeps owner-only workflow autosaves and lock-associated metadata. Content-addressed canvas tiles/revisions provide a separate layered-image history. [S3, S13]

These are meaningful recovery primitives, not proof of exactly-once execution or arbitrary in-flight inference resumption after a crash. External nodes may have irreversible side effects; reruns and cache behavior do not roll those back. Back up workflow documents, required inputs and valuable outputs independently; caches and autosaves are not a backup strategy.

## Supply Chain and Licensing

The actual LICENSE is MIT, including notices for Bernard Maltais and Omarchy starter files attributed to David Heinemeier Hansson. GitHub's API classified it as “Other/NOASSERTION”; the text, not that classifier, supports the MIT assessment. Preserve the notices when reusing substantial code. [S14]

Pinned helper archives and the recorded template submodule commit are positives. Templates are pinned to 049a201ba588ec301df11faa6aa12396f8d7bc53; devkit to 750a50c3711730422a6324a562ac42ea557bcd43. Neither submodule's contents were audited here. CI actions use version tags rather than immutable SHAs, Arch dependencies/base images move, and the aarch64 Test workflow obtains an Arch Linux ARM rootfs plus MD5 over HTTP. That bootstrap is a concrete weaker supply-chain boundary than authenticated, independently verified artifacts. [S2, S7, S15]

The advertised installer downloads release packages, checks SHA256SUMS and uses sudo pacman; the README explicitly says packages are unsigned. A checksum from the same release helps detect corruption, not compromise of the release publisher. Do not treat curl-to-shell on main as a reproducible or authenticated adoption plan. [S1, S15]

MIT application licensing does **not** license model weights, training data, templates, all linked dependencies or uploaded media. The model catalog itself lists differing terms, including CC-BY-NC-SA-4.0 for an upscale model: commercial reuse cannot be assumed. Validate each model card, dependency distribution obligation and input/output right separately. No training corpus or weights were downloaded/audited. [S16]

## Maturity and Verification

At retrieval on 2026-11-23 UTC, the public API reported 0 stars, 0 forks and 52 open issues/PRs combined; these are volatile metadata, not quality scores. Latest release v0.1.0-test3 is explicitly a prerelease and resolves to the reviewed SHA; it was published at 2026-11-23T03:03:00Z. The reviewed commit is dated 2026-11-23T02:34:53Z. [S17]

The tree has **173 test_*.cpp files**, plus fixtures and other test support (209 test-directory files total). CMake registers Qt/CLI/engine/UI tests, fake providers/helpers, qmllint, isolated HOME/XDG folders and 300-second timeouts. This is substantial test infrastructure, not a count of passing test cases. [S2]

Critically, public [Test run 45102853059](https://github.com/bmaltais/fugue/actions/runs/45102853059) at the exact SHA concluded **failure**, with the Test step failing on both x86_64 and aarch64. [Package run 45102853068](https://github.com/bmaltais/fugue/actions/runs/45102853068) succeeded. Packaging success is not test-suite success. Failure causes were not established from logs, and no claim is made about a specific defect. The workflow also does not run on every main push. [S15, S17]

**Review checks:** canonical URL deduplicated against the public library; public accessibility verified without GitHub credentials; source/tag pins, license text, manifests, selected code paths and CI job metadata inspected. No source commands, tests, builds, installer, helper or media were executed. No benchmark, hardware compatibility, security exploit, remote pairing or recovery behavior was live-verified. This is a bounded static review, not a full security audit.

## Comparison

| Alternative | Prefer it when | Fugue distinction / caution |
|---|---|---|
| [ComfyUI](https://github.com/Comfy-Org/ComfyUI) | You need the established Python graph/model-node ecosystem | Native Qt/C++ and Omarchy integration are Fugue's differentiators; extension compatibility is not interchangeable |
| [InvokeAI](https://github.com/invoke-ai/InvokeAI) | You want an image-focused creative application rather than primarily wiring general nodes | Fugue emphasizes a common headless graph engine and extensible protocols; its layered-image UI is still developing |
| [stable-diffusion.cpp](https://github.com/leejet/stable-diffusion.cpp) | You need lightweight inference tooling rather than a workflow desktop | Fugue adds graphs, caching, editing and provider orchestration on top of a patched helper |

These are positioning comparisons, not fresh audits or performance comparisons of the alternatives. Existing engines are more appropriate starting points than building another inference runtime; Fugue is worth following if its native/agent-friendly workflow is the missing layer.

## Self-Hosting Notes and Costs

This is a local desktop/CLI application, not a web deployment stack. Its packaged target is Arch/Omarchy on x86_64 or aarch64, with Vulkan and optional NVIDIA CUDA inference. No mandatory SaaS fee or subscription was found in the inspected application path. Real costs are suitable hardware/VRAM/RAM, electricity, model storage/download bandwidth and maintenance; remote/custom providers may add charges and privacy obligations. No dollar estimate or throughput claim is supported by this review.

Before adoption: require green tests for the chosen revision, inspect installation artifacts and extension code, use a non-sensitive separate OS environment, verify model terms, and constrain helper reachability to a trusted network. No installation or deployment was performed for this review.

## Evidence Map

All source links below are pinned to the reviewed commit; GitHub metadata/CI links are time-sensitive observations.

[S1]: https://github.com/bmaltais/fugue/blob/6fdbb95f42b5f34b278e1b251c60b86b25014fc6/README.md
[S2]: https://github.com/bmaltais/fugue/blob/6fdbb95f42b5f34b278e1b251c60b86b25014fc6/CMakeLists.txt
[S3]: https://github.com/bmaltais/fugue/tree/6fdbb95f42b5f34b278e1b251c60b86b25014fc6/src/engine
[S4]: https://github.com/bmaltais/fugue/tree/6fdbb95f42b5f34b278e1b251c60b86b25014fc6/src/nodes
[S5]: https://github.com/bmaltais/fugue/blob/6fdbb95f42b5f34b278e1b251c60b86b25014fc6/src/engine/share_package.cpp
[S6]: https://github.com/bmaltais/fugue/blob/6fdbb95f42b5f34b278e1b251c60b86b25014fc6/src/engine/model_download.cpp
[S7]: https://github.com/bmaltais/fugue/blob/6fdbb95f42b5f34b278e1b251c60b86b25014fc6/helper/CMakeLists.txt
[S8]: https://github.com/bmaltais/fugue/blob/6fdbb95f42b5f34b278e1b251c60b86b25014fc6/src/engine/provider_module.h
[S9]: https://github.com/bmaltais/fugue/tree/6fdbb95f42b5f34b278e1b251c60b86b25014fc6/docs/nodes
[S10]: https://github.com/bmaltais/fugue/blob/6fdbb95f42b5f34b278e1b251c60b86b25014fc6/helper/src/main.cpp
[S11]: https://github.com/bmaltais/fugue/blob/6fdbb95f42b5f34b278e1b251c60b86b25014fc6/src/engine/providers_file.h
[S12]: https://github.com/bmaltais/fugue/blob/6fdbb95f42b5f34b278e1b251c60b86b25014fc6/src/engine/fugue_home.cpp
[S13]: https://github.com/bmaltais/fugue/blob/6fdbb95f42b5f34b278e1b251c60b86b25014fc6/src/workflow/recovery_store.cpp
[S14]: https://github.com/bmaltais/fugue/blob/6fdbb95f42b5f34b278e1b251c60b86b25014fc6/LICENSE
[S15]: https://github.com/bmaltais/fugue/blob/6fdbb95f42b5f34b278e1b251c60b86b25014fc6/.github/workflows/test.yml
[S16]: https://github.com/bmaltais/fugue/blob/6fdbb95f42b5f34b278e1b251c60b86b25014fc6/src/catalog/upscale-models.json
[S17]: https://github.com/bmaltais/fugue/releases/tag/v0.1.0-test3

- [S1 README][S1]; [S2 build/tests][S2]; [S3 engine sources][S3]; [S4 built-in kernels][S4].
- [S5 sharing][S5]; [S6 downloads][S6]; [S7 helper pins][S7]; [S8 provider modules][S8].
- [S9 node trust documentation][S9]; [S10 HTTP helper][S10]; [S11 credential persistence][S11]; [S12 root redirection][S12].
- [S13 recovery][S13]; [S14 license][S14]; [S15 CI][S15]; [S16 model terms][S16]; [S17 release][S17].
- Additional implementation anchors: [terminal confirmation](https://github.com/bmaltais/fugue/blob/6fdbb95f42b5f34b278e1b251c60b86b25014fc6/src/cli/packs.cpp), [inherited execution environment](https://github.com/bmaltais/fugue/blob/6fdbb95f42b5f34b278e1b251c60b86b25014fc6/src/engine/command_node.cpp), [trust store](https://github.com/bmaltais/fugue/blob/6fdbb95f42b5f34b278e1b251c60b86b25014fc6/src/engine/trust_store.cpp), [remote helper transport](https://github.com/bmaltais/fugue/blob/6fdbb95f42b5f34b278e1b251c60b86b25014fc6/src/engine/remote_helper_provider.cpp), [project inheritance](https://github.com/bmaltais/fugue/blob/6fdbb95f42b5f34b278e1b251c60b86b25014fc6/src/engine/project.h), [private-mode research, not a guarantee](https://github.com/bmaltais/fugue/blob/6fdbb95f42b5f34b278e1b251c60b86b25014fc6/docs/private-mode-research.md).

---

**Attribution:** bmaltais/fugue, Bernard Maltais; MIT application code, including credited Omarchy starter files. Independent review; no source code or media extracted.
