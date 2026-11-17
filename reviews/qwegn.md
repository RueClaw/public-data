# Qwegn (qwegnai/qwegn)

**Repo:** https://github.com/qwegnai/qwegn
**License:** Apache-2.0 source; dependencies, models and datasets retain separate terms.
**Reviewed:** 2026-11-17 (UTC)
**Revision:** bc0f826027f5560cb6412329efa4328799963210 (main; repository-wide static review focused on engine, HTTP, memory, downloader and packaging).
**Verification:** Static inspection only. No installation, compilation, source tests, inference, weights downloads, device access or live security probes. Public CI checked separately.
**Stack:** Swift 6.2, Metal 4, SwiftPM, macOS 26+ on Apple Silicon; Python conversion/oracle tooling.
**What it is:** Native local LLM/VLM inference engine, CLI, multi-protocol server and menu-bar controller with quantized packs and precomputed repository-context caches—not a sandboxed coding agent.

## Verdict

⚠️ **Interesting — substantial specialized engineering for a single-owner pilot, not a shared-service default.** This is native kernel and memory machinery, not an MLX or llama.cpp wrapper. Reusable repository prefill plus on-demand source recall is distinctive. Performance remains author-reported, some fast decoding changes exactness, and shared workspace authority and mutable artifact acquisition require containment.

## What It Is

QwegnAI publishes Qwegn; the executable is qwg, while the Swift package retains the name qwegine. The public description and implementation agree: a Swift/Metal inference engine for recent Apple Silicon Macs. It targets developers wanting long contexts, custom quantization and coding-client compatibility without a Python inference process. Python remains relevant to conversion and golden-generation workflows. [README][readme], [manifest][package].

The core loads quantized packs, tokenizer and model configuration, chooses geometry/family-specific operators, allocates unified-memory arenas and KV state, then directly encodes Metal computation. Commands include pull, quantize, inspect, plan, run, repl, index and serve. HTTP adapters implement OpenAI, Anthropic and Ollama request/stream shapes; this is not proof of complete upstream API parity.

## Stack

| Layer | Implementation |
|---|---|
| Compute | Custom Metal kernels; Swift tensors, HAL, arenas and quantized operators |
| Runtime | Descriptor/family adapters, prefill/decode, session state, speculation and vision |
| Serving | Network.framework HTTP/1.1 parser, lifecycle actor, SSE/NDJSON, JSON/tool constraints |
| Interfaces | ArgumentParser CLI, menu-bar UI, bundled browser dashboard/chat |
| Persistence | Packs, JSON settings/profiles/manifests, RAM/SSD caches, browser localStorage |
| Toolchain | SwiftPM resolution; Python torch/transformers/numpy/safetensors/MLX tooling |

## Key Features and Architecture

### Native execution with explicit state ownership

The package separates Foundation, Operators, Subsystems, Runtime and Apps. QWEngineDriver holds the HAL, arena, weights, attention/GDN operators and pipeline states. QWEngineSession owns position, token history, KV handles, recurrent/ring state and speculation, with snapshot/rollback and an idempotent-finish witness. This is meaningful structure. Numerous unchecked Sendable classes and manual synchronization mean compiler concurrency checks alone cannot prove correctness. [Driver][driver], [session][session].

### Repository memory is cached computation plus retrieval

Indexing discovers bounded UTF-8 files, orders them by structural depth and temporal stability, prefills a resident envelope and writes a .qwcache plus manifest. Default Cortex budget: 32,768 tokens. Default additional Vault recall budget: 8,192 tokens per turn. Recall and live deltas still depend on source files. This is not weight training or portable learned memory independent of model and repository.

The “semantic” index is narrower than the name suggests: 128-dimensional signed FNV-hashed term projections, splitting/stemming, hand-authored concept expansions, weighting and clustered retrieval—not an embedding-provider call. Git and .qwgignore rules, regular-file checks, binary checks and a 256 KiB per-file cap reduce unwanted ingestion, but are not secret detection. Tests are excluded by default. “Whole-codebase visibility” does not mean every byte is resident or every relevant file recalled. [Builder][memory], [Vault][vault], [index][semantic], [ignore matcher][ignore].

### One control plane is not tenant isolation

Inference, model loading, settings, logs, telemetry and memory inspection/indexing/mounting share one service. Structured tool output is a protocol capability; callers still own execution policy, approvals and sandboxing. A coding agent does not become safe merely because inference is local.

## Security and Authority Boundaries

**Useful defaults:** loopback binding; refusal of unauthenticated non-loopback binding unless explicitly overridden; bearer/x-api-key authentication with constant-time-style byte comparison; bounded HTTP framing and malformed-request rejection. Server images default to bounded data URLs, with local paths and remote URLs disabled. Optional remote fetching blocks private address classes, redirects and excess source bytes. [Server][http], [helpers][security], [parser][parser], [image policy][images].

**Limits:** loopback may be keyless and is not user authentication. CORS controls emitted response headers; inspected dispatch does not reject all unapproved Origins as an authorization gate. The listener uses plain TCP, not built-in TLS. One key grants broad authority rather than separate inference/admin/workspace roles. Use authenticated encrypted transport and route restrictions beyond one trusted local client; avoid the unsafe public-bind override.

Memory APIs accept filesystem paths. Root resolution normalizes a path and checks directory existence, but does not enforce an authorized-repository allowlist. Indexing writes within that repository and updates Git exclude state. Workspace metadata, a model-name @repo suffix or system/developer-message paths can trigger auto-mounting. If no new root is found, an existing active pack can remain available. This is daemon-wide state, not per-user isolation. Use separate processes/accounts for separate trust domains. These are static authority findings, not demonstrated exploits. [Index/root resolution][indexing], [mounting][mount].

The optional image policy checks DNS before URLSession connects; address pinning was not established. DNS-rebinding resistance is unproven, not a confirmed exploit. Keeping remote images disabled avoids this extra egress surface.

Settings use private directories and 0600 files, but serialize the configured API key in JSON rather than a dedicated credential vault; settings responses mask it. Hugging Face uses HF_TOKEN, and HF_ENDPOINT changes its destination. Only configure trusted endpoints. No paid model API is necessary for native inference, but model acquisition, package setup and optional images still use the network. Local inference is not a zero-network guarantee. [Settings][settings], [pull/bootstrap][pull].

Repository text becomes model context, including memory envelopes rendered as system content. Filtering and delimiters are not a prompt-injection boundary. Review sensitive inclusion and enforce effect policy in the consuming agent. Optional fan-control UI documents root or an SMC helper socket for direct writes—a separate privilege boundary unnecessary for basic inference. [Envelope][indexing], [fan settings][fans].

## Persistence, Retention, Export and Recovery

- **Settings/profiles:** local JSON with atomic settings writes and restrictive permissions. One atomic file is not a transaction across application state.
- **Prefix caches:** default 4 GiB warm RAM, 10 GiB SSD, 32 entries and eight session slots. Stored token IDs and model state/logits are sensitive recoverable context, not anonymous telemetry. LRU and startup stale-cache cleanup are not secure erasure or a complete retention policy. The inspected store writes through direct I/O to its destination, not a universal atomic multi-file transaction. [Config][cacheconfig], [store][cachestore].
- **Repository packs:** manifests record source digests and model/cache identities and save atomically. Cache and manifest are separate writes. Unmounting is not deletion. Preserve source and matching model/config assets; rebuild derived caches after incompatible or interrupted writes. [Manifest][manifest].
- **Browser chats:** conversations, presets and UI state use localStorage. JSON/Markdown export, turn/session deletion and double-action Clear All exist. Browser deletion does not purge caches, packs, exports or backups. [Chat][chat].
- **Logs/uninstall:** disk logs can append persistently; the memory ring holds 2,000 lines. Uninstall deliberately preserves models/settings/profiles/caches. No end-to-end encrypted backup/restore or verified total-erasure workflow was established. Plan retention and restore testing yourself. [Logger][logger], [uninstaller][uninstall].

## Performance Claims Versus Evidence

The README advertises large MoE packs on a 128 GB M5 Max, million-token contexts, zero steady-state heap/Metal-buffer allocations and major cache TTFT gains. Relevant code and harnesses exist, but none of those measurements was reproduced here.

| Claim or evidence | Interpretation |
|---|---|
| Repository-cache TTFT 0.12–0.24 seconds, 54.4–74.3× gains | Author-reported precomputed/warm results, not first indexing or cold loading |
| Flash-Next novel speculative 94.1 tok/s versus 82.6 on mlx-serve; predictable 137.3 versus 159.2 | Documentation itself shows workload-dependent wins and losses |
| Variational MTP probability/margin relaxation | Changes exact verification; docs acknowledge timing-adaptive non-bit-reproducible greedy output and score variation |
| Three needles and small Code-10/core suites | Smoke checks, not general long-context reasoning or agent validation |
| 81/100 code and 99.74% fidelity | Author results for particular packs/protocols, not independent certification |
| Million-token planning/residency rows | Memory fit is not automatically a completed million-token generation run |

The guide supplies hardware/settings, exact-versus-relaxed distinctions and alternating cooled A/B methodology. That candor is valuable. Tables span earlier versions and mix peak/median, CLI/server, predictable/novel and resident/streamed modes. The baseline dates to October 5 and cannot substantiate all current headlines. A complete raw run bundle binding each headline to the reviewed SHA was not established. Compare identical weights, prompts, context, cache warmth, quality, speculation and thermals; measure indexing amortization and recall failures too. [Benchmarks][bench], [baseline][baseline], [whitepaper][whitepaper].

## Build, Install, Update and Licensing

Documented platform: macOS 26+, Apple Silicon, Xcode 26+, Swift 6.2/Metal; M5 recommended for cooperative tensors. This is not a Linux/Windows runtime, and M5 Max results should not be generalized to every M-series Mac.

SwiftPM commits exact resolutions for ArgumentParser, swift-jinja and swift-collections, while manifest ranges permit updates. Python direct versions are pinned, not a hash-locked full graph. Lazy bootstrap upgrades pip and falls back to unpinned numpy/safetensors/torch if requirements installation fails, then stamps success. Initialization success is not proof of a reproduced environment. [Resolution][resolved], [requirements][requirements], [bootstrap][pull].

The downloader uses mutable Hugging Face main, skips existing files by size and does not establish revision-consistent content addressing in the inspected flow. Ranged downloads accept any 2xx response and validate lengths rather than an explicit 206/Content-Range contract. Downloadable hash sidecars are not enforcement. Independently pin and verify artifacts; resumed acquisition should not mix revisions. These are static provenance/correctness concerns, not tested corruption incidents. [Downloader][pull].

The installer places CLI/app/support files in system locations and can terminate an existing menu app. Packaging supports Developer ID/notarization but defaults to ad-hoc app signing and permits unsigned installers without identities. Release metadata lists package/archive/checksum assets; their contents/signatures were not downloaded or verified. Preserve a known-good version/config; no transactional app rollback was demonstrated. [Packaging][packaging].

Root Apache-2.0 permits modification/commercial redistribution subject to conditions, notices and patent terms. It does not grant rights to third-party models, evaluation data or brands. No code or visual assets were extracted. Retain component/model notices when redistributing packs. [License][license].

## Maturity and Verification

Public metadata checked November 17 reports creation November 9, last push November 16, one star, zero forks and zero open issues. Latest listed release: v0.23.0, November 16. These are activity signals, not quality scores. Public CI at the exact reviewed SHA reported success.

The macOS workflow builds and runs host/CLI/server/quant/token/UI suites. GitHub Actions deliberately skips bare-metal GPU/golden suites, paired-performance tests and kernel-benchmark execution. Tests cover framing, auth/CORS, settings permissions, cancellation and memory mounting/indexing. GPU parity suites and golden generators exist, but existence is not a local pass result. Checkout uses a version tag rather than a full action SHA. [Workflow][workflow], [CI script][ci], [tests][tests], [security policy][policy].

**Limits:** selective static review, not a complete audit or numerical-correctness proof. No tests were run; model catalogs/weights, pack recovery, installer signatures, isolation and throughput were not experimentally verified. Only public sources/metadata were used. Review-page markup validation is separate from executing Qwegn or visually testing its UI.

## Comparison

| Option | Prefer it when | Tradeoff |
|---|---|---|
| llama.cpp / Ollama | Broad platform/model packaging and familiar serving matter | Less reason to accept bespoke macOS-only packs; compare exact workloads |
| MLX / mlx-lm | Apple Silicon experimentation and its model ecosystem matter | Qwegn specializes native execution and repository prefill; its guide shows mixed relative speed |
| [Splash](splash.md) / [TensorFold](tensorfold.md) | Comparing specialized engines on qualified hardware/model pairs | Evaluate exactness, API parity, provenance and retention, not just throughput |
| [Memorilla](memorilla.md) | Studying learned/query-conditioned compression | Different mechanism: Qwegn uses cached state and hashed lexical/concept retrieval |

## Self-Hosting Notes and Practical Decision

Start pinned, local-only and single-owner on supported hardware with non-sensitive source. Select workspaces explicitly; disable automatic memory use where inappropriate. Authenticate even loopback if local clients are not trusted. Do not share a daemon across mutually untrusted users or run it as root merely for fan control.

Budget for unified memory, model storage, conversion/indexing, SSD traffic, electricity and maintenance, not cloud per-token fees. Repeated stable repositories best amortize prefill. Prefer an existing engine for portability or ordinary small-context chat.

**Adoption gate:** verify hashes/install signatures; reproduce exact and relaxed quality/performance separately; test stale-file recall, workspace switching, API compatibility, interrupted indexing, disk-full recovery and complete deletion. Until then: interesting single-owner pilot, not a production multi-tenant service.

---

**Attribution:** QwegnAI / qwegnai/qwegn, Apache License 2.0. Implementation findings are separate from upstream performance claims.

[readme]: https://github.com/qwegnai/qwegn/blob/bc0f826027f5560cb6412329efa4328799963210/README.md
[package]: https://github.com/qwegnai/qwegn/blob/bc0f826027f5560cb6412329efa4328799963210/Package.swift
[driver]: https://github.com/qwegnai/qwegn/blob/bc0f826027f5560cb6412329efa4328799963210/Sources/Runtime/QWEngine/Driver/QWEngineDriver.swift
[session]: https://github.com/qwegnai/qwegn/blob/bc0f826027f5560cb6412329efa4328799963210/Sources/Runtime/QWEngine/Session/EngineSession.swift
[memory]: https://github.com/qwegnai/qwegn/blob/bc0f826027f5560cb6412329efa4328799963210/Sources/Runtime/QWEngine/Memory/QWMemoryPack.swift
[vault]: https://github.com/qwegnai/qwegn/blob/bc0f826027f5560cb6412329efa4328799963210/Sources/Runtime/QWEngine/Memory/QWMemoryVault.swift
[semantic]: https://github.com/qwegnai/qwegn/blob/bc0f826027f5560cb6412329efa4328799963210/Sources/Runtime/QWEngine/Memory/QWMemorySemanticIndex.swift
[ignore]: https://github.com/qwegnai/qwegn/blob/bc0f826027f5560cb6412329efa4328799963210/Sources/Runtime/QWEngine/Memory/QWMemoryIgnoreMatcher.swift
[http]: https://github.com/qwegnai/qwegn/blob/bc0f826027f5560cb6412329efa4328799963210/Sources/Apps/QWServer/Core/QWHttpServer.swift
[security]: https://github.com/qwegnai/qwegn/blob/bc0f826027f5560cb6412329efa4328799963210/Sources/Apps/QWServer/Core/QWHttpSecuritySupport.swift
[parser]: https://github.com/qwegnai/qwegn/blob/bc0f826027f5560cb6412329efa4328799963210/Sources/Apps/QWServer/Core/QWHttpIncrementalParser.swift
[images]: https://github.com/qwegnai/qwegn/blob/bc0f826027f5560cb6412329efa4328799963210/Sources/Apps/QWServer/Handlers/QWImageDecodePolicy.swift
[indexing]: https://github.com/qwegnai/qwegn/blob/bc0f826027f5560cb6412329efa4328799963210/Sources/Apps/QWServer/Core/QWEngineLifecycleActor+MemoryIndex.swift
[mount]: https://github.com/qwegnai/qwegn/blob/bc0f826027f5560cb6412329efa4328799963210/Sources/Apps/QWServer/Core/QWEngineLifecycleActor+MemoryPack.swift
[settings]: https://github.com/qwegnai/qwegn/blob/bc0f826027f5560cb6412329efa4328799963210/Sources/Apps/QWServer/Core/QWSettingsManager.swift
[pull]: https://github.com/qwegnai/qwegn/blob/bc0f826027f5560cb6412329efa4328799963210/Sources/Apps/QWCli/QWCli+PullAndQuantize.swift
[fans]: https://github.com/qwegnai/qwegn/blob/bc0f826027f5560cb6412329efa4328799963210/Sources/Apps/QWMenuBar/SettingsView+Performance.swift
[cacheconfig]: https://github.com/qwegnai/qwegn/blob/bc0f826027f5560cb6412329efa4328799963210/Sources/Runtime/QWEngine/Cache/QWCacheConfig.swift
[cachestore]: https://github.com/qwegnai/qwegn/blob/bc0f826027f5560cb6412329efa4328799963210/Sources/Runtime/QWEngine/Cache/QWCacheDiskManager+Store.swift
[manifest]: https://github.com/qwegnai/qwegn/blob/bc0f826027f5560cb6412329efa4328799963210/Sources/Runtime/QWEngine/Memory/QWMemoryManifest.swift
[chat]: https://github.com/qwegnai/qwegn/blob/bc0f826027f5560cb6412329efa4328799963210/Sources/Apps/QWServer/Resources/js/chat.js
[logger]: https://github.com/qwegnai/qwegn/blob/bc0f826027f5560cb6412329efa4328799963210/Sources/Apps/QWServer/Core/QWServerLogger.swift
[uninstall]: https://github.com/qwegnai/qwegn/blob/bc0f826027f5560cb6412329efa4328799963210/Scripts/uninstall.sh
[bench]: https://github.com/qwegnai/qwegn/blob/bc0f826027f5560cb6412329efa4328799963210/docs/benchmarks.md
[baseline]: https://github.com/qwegnai/qwegn/blob/bc0f826027f5560cb6412329efa4328799963210/Scripts/bench/baselines.json
[whitepaper]: https://github.com/qwegnai/qwegn/blob/bc0f826027f5560cb6412329efa4328799963210/docs/lsa-codebase-memory-whitepaper.md
[resolved]: https://github.com/qwegnai/qwegn/blob/bc0f826027f5560cb6412329efa4328799963210/Package.resolved
[requirements]: https://github.com/qwegnai/qwegn/blob/bc0f826027f5560cb6412329efa4328799963210/requirements.txt
[packaging]: https://github.com/qwegnai/qwegn/blob/bc0f826027f5560cb6412329efa4328799963210/Scripts/build_pkg.sh
[license]: https://github.com/qwegnai/qwegn/blob/bc0f826027f5560cb6412329efa4328799963210/LICENSE
[workflow]: https://github.com/qwegnai/qwegn/blob/bc0f826027f5560cb6412329efa4328799963210/.github/workflows/ci.yml
[ci]: https://github.com/qwegnai/qwegn/blob/bc0f826027f5560cb6412329efa4328799963210/Scripts/ci.sh
[tests]: https://github.com/qwegnai/qwegn/blob/bc0f826027f5560cb6412329efa4328799963210/Tests/QWServerTests
[policy]: https://github.com/qwegnai/qwegn/blob/bc0f826027f5560cb6412329efa4328799963210/SECURITY.md
