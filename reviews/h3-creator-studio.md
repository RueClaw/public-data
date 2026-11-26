# YUZU Creator Studio (animede/h3-creator-studio)

**Repo:** https://github.com/animede/h3-creator-studio
**Author:** YUZUKI (ゆずき), GitHub: animede
**License:** Apache-2.0 for studio code; separate engine, model and voice terms apply. Bundled sample manifests declare CC0.
**Reviewed:** 2026-11-26 (UTC)
**Revision:** `4d76328ca7a4618add48317247d2ffafcb4c5130`, main and peeled `v1.0.0`; repository-wide static review with emphasis on supervisor, API, persistence, installers and tests.
**Verification:** Anonymous GitHub API and public HTTPS clone succeeded. Source inspection only; no installation, imports, tests, GPU inference, accounts, uploads or running-service probes.
**Stack:** Python 3.11+, FastAPI/Uvicorn, vanilla JavaScript, SQLite, HTTP engine adapters, NVIDIA/CUDA, ffmpeg, llama.cpp.
**What it is:** A local, single-user multimedia production supervisor, now branded YUZU, that brings image, video, music, music-video, short-video and editing workflows into one browser UI. It is not a social-media publishing service or a new foundation model.

---

## Verdict

⚠️ **Interesting — a coherent local creation workflow, not a deploy-anywhere service.** Engine lifecycle management, staged video recovery and reusable media are substantive engineering. Keep it on a trusted workstation: unauthenticated administrative APIs and a static mount encompassing the SQLite database make network exposure inappropriate. The first release, heavyweight moving dependencies and unverified hardware claims warrant a measured trial rather than production adoption.

## What It Is

YUZU supplies task-oriented tabs instead of a node graph. Images and songs can become inputs to a music video; a character reference and song feed scene planning, optional vocal separation, H3 scene generation and final ffmpeg assembly. Short videos reuse the director machinery with story, speech and subtitle handling. The editor provides non-destructive cuts, inserts, transitions, color and audio changes, preview, undo/redo and local export.

The underlying generators live in separate repositories and processes: MiniMax-H3, MiniMax-H3-Image, ACE-Step and AivisSpeech. A local llama.cpp server supplies the configured Gemma 4 E4B helper for prompt enhancement, lyrics and multimodal descriptions. These are source-described integrations, not independently tested model capabilities. See [README.en.md][readme], [component configuration][config] and [handlers][handlers].

## Stack

| Layer | Technology and responsibility |
|---|---|
| UI/API | Same-origin static JavaScript and FastAPI JSON endpoints |
| Scheduling | Async per-engine lanes, two CPU slots, GPU ownership/budget decisions |
| Generators | Separate H3, H3-Image, ACE-Step and AivisSpeech processes |
| Assistant | Locally managed llama.cpp; GGUF and vision/audio projection downloads |
| Storage | SQLite ledger plus uploaded/generated media and working files under outputs |
| Assembly | ffmpeg/ffprobe; Demucs/librosa in a separate environment |
| Authentication | No application login, tenant isolation or role model found |

## Key Features

### Resource-aware orchestration

The default GPU policy chooses exclusive engine swapping below 40 GiB and budgeted sharing at or above it; idle engines can be evicted to make room. CPU work has its own lane. The helper LLM relinquishes GPU resources before generation and can answer on CPU while GPU work is pending. External engines are treated differently from owned child processes; the documentation explains that external ACE-Step cannot simply be killed to free memory. This is practical coordination, not a strict OS-enforced quota system or proof every GPU combination fits. [Scheduler][scheduler], [jobs][jobs], [LLM][llm].

### Stateful productions, not just one-shot calls

The MV director advances through analysis, planning/direction, scenes and assembly. Scene status and parameters survive in SQLite. Restart restoration pauses interrupted projects and resets running scenes to pending; users resume from surviving artifacts. ShortDirector extends the workflow rather than duplicating an entirely separate orchestrator. This is checkpointed recovery, not continuation of an interrupted tensor computation. [Director][mv], [short workflow][short].

### Reusable media and local editing

Uploads and generated artifacts enter a gallery with metadata and thumbnails. The ledger confines resolved paths to its output root; upload names are randomized rather than directly used as destination paths. Editing retains a bounded undo history (100 states), renders previews and exports through jobs. Export means a local output file and browser download, not authorization to publish to YouTube, TikTok or another account. [Ledger][ledger], [API][api], [editor][edit].

## Architecture

`browser → FastAPI → JobRunner → Scheduler → engine HTTP adapter → local process` is the generation path. The ledger records outputs and terminal job history; directors persist longer-lived project state. Configuration merges the repository defaults with an ignored local TOML override. A separate environment for each engine helps accommodate incompatible GPU stacks, but expands installation and maintenance scope.

### Security, permissions and authority

- **Loopback is the principal boundary.** Default host is `127.0.0.1`; inspected API routes have no authentication dependencies. Component start/stop, generation, deletion, export and the MV-tools installer are available to callers that can reach the service. No explicit CORS middleware, CSRF token or Host/Origin validation was found in the main app; lack of permissive CORS is not authorization. This is a static finding, not a demonstrated browser exploit.
- **The output directory includes the database and is served wholesale.** `Ledger` creates `outputs/studio.db`; `main.py` mounts the whole output directory with `StaticFiles` at `/outputs`. Consequently the routing design exposes the database file path alongside media to a reachable client, absent an external filter. That database holds prompts, job parameters, project state and filenames. No live download was attempted. Move internal state outside the served media tree before any remote deployment.
- **Uploads are not a hardened hostile-input boundary.** The upload handler accepts media categories from client MIME or filename inference and copies the stream without an application-level byte quota in that function. It then invokes image/media processing. Path containment and random names are worthwhile, but do not substitute for size, parser-resource and decompression limits.
- **Local process privilege is broad.** Installers download software; engine processes, ffmpeg and model tools run with the invoking user’s OS permissions. There is no reviewed sandbox or per-user capability boundary. Do not run this under an account holding unrelated sensitive credentials.
- **No publication approval workflow.** No social-account connector or remote publishing endpoint was identified. Local exports and destructive gallery/project deletion have no role-based authorization. Obtain rights and human approval outside this tool before distributing music, voices, likenesses or generated video.

Evidence: [API and mounts][api], [ledger path checks/schema][ledger], [installer][setup].

### Privacy, provider egress and costs

Inference is designed to use local engine endpoints, including the helper LLM on loopback; no paid hosted inference provider or API-key setup was found in the inspected supervisor path. This supports the local-first claim, not an audited guarantee of zero network activity. Setup and first use fetch repositories/releases from GitHub, models through Hugging Face, and Python/GPU packages from package indexes including PyPI and download.pytorch.org. Those hosts learn download/network metadata; downloaded engines and their transitive behavior were not audited.

Prompts, filenames, generation settings, project histories and source media remain on disk; there is no reviewed encryption, retention policy or secure-erasure mechanism. Deletion unlinks files rather than providing forensic erasure. The helper receives image/audio content locally for description, so restricting the supervisor alone is not a complete engine isolation policy.

README estimates roughly 175 GB installed (about 145 GB without reference support), with image preparation transferring substantially more than retained model size. NVIDIA hardware, compatible drivers, electricity, bandwidth and long render times are the main costs; no measured cost or latency benchmark was reproduced. First-use downloads mean an air-gapped workflow requires advance provisioning and separate verification. [README][readme], [setup][setup], [LLM downloads][llm].

### Persistence and recovery limits

Back up the **whole output tree plus a consistent SQLite snapshot**, local configuration and pinned engine/model inventory, not just final videos. Projects depend on intermediate clips and source assets. SQLite transactions protect individual ledger updates, but media deletion and database changes are not a single atomic filesystem/database transaction. Startup removes `*.part` files. In-memory pending jobs do not become a durable general-purpose queue simply because completed history is stored; MV/short projects receive special restart handling.

Engine death detection includes a bounded one-time restart/retry for selected generators. That is useful failure handling but not exactly-once inference: after an uncertain failure, duplicate work and extra GPU time remain possible. No backup/restore exercise, forced-crash test or migration rollback was performed. [Jobs][jobs], [ledger][ledger], [director restore][mv], [engine-death tests][death-tests].

## Correctness, Maturity and Evidence

The public API snapshot on 2026-11-26 reported 19 stars, 5 forks and 0 open issues/PRs; the repository was created 2026-11-22 and last pushed 2026-11-26T14:25:48Z. These are freshness/popularity observations, not reliability evidence. The first public release, [v1.0.0](https://github.com/animede/h3-creator-studio/releases/tag/v1.0.0), was published 2026-11-26T14:27:14Z with no attached binary assets. Its annotated tag peels to the reviewed SHA.

There are **51 `test*.py` modules**, including scheduling, engine death, ledger, editor, API, cache, multi-GPU and director tests. Inspected tests use unittest, fake schedulers and mocked HTTP; some media tests conditionally invoke installed ffmpeg/ffprobe. This is appreciably better evidence than screenshots alone, but the tests were **not run** and mocked scheduling cannot establish GPU compatibility, generation quality or memory bounds. No tracked `.github` CI workflows or dependency lockfiles were found. Main Python requirements are unversioned; engine setup clones repository heads, while llama.cpp uses a named release tag (`b12475`). The binary downloader inspected does not verify a pinned content hash. Repeating the same studio install later need not reproduce the same dependency stack.

The README records author-reported Windows/Linux hardware results and bundled examples. It also explicitly qualifies 6 GB studio reference-workflow support: the cited low-memory simulation does not reproduce Windows attention behavior and real 6 GB testing is absent for that path. Do not flatten this into “all workflows verified on 6 GB.” Independent quality, lip-sync accuracy, hardware performance, dependency advisories and model-card compliance remain unverified. [Tests][tests], [manifests][manifest], [README][readme].

## Licensing and Reuse

Studio code is Apache-2.0: preserve the license, attribution, NOTICE and required modification notices when redistributing. NOTICE explicitly documents ported MV components and separates third-party licenses. The two bundled sample manifests declare CC0 for their generated example media; that declaration is not a blanket clearance of all possible likeness, music or upstream-model restrictions. No media was copied into this review.

NOTICE lists MiniMax Community License for H3/H3-Image weights, Qwen model-specific terms, Gemma Terms of Use and prohibited-use policy, distinct voice-model authors’ terms, LGPL-3.0 AivisSpeech, and build-dependent LGPL/GPL ffmpeg. These are **repository-stated classifications**, not a fresh legal audit of each downloaded artifact. Apache-2.0 on the supervisor does not override model restrictions, voice rights or output-distribution obligations. Check exact model cards, voice licenses and binary builds before commercial use or bundling. [LICENSE][license], [NOTICE][notice], [sample manifests][samples].

## Comparison

| Alternative | Prefer it when | Tradeoff versus YUZU |
|---|---|---|
| [ComfyUI](https://github.com/Comfy-Org/ComfyUI) | You need composable graphs and many model integrations | More workflow assembly and extension management; YUZU offers opinionated end-to-end tabs |
| [Kdenlive](https://kdenlive.org/) / [Shotcut](https://shotcut.org/) | Your main need is established timeline editing rather than generation | Separate tools are needed for AI generation; stronger focus on conventional editing |
| Direct engine interfaces | You want one modality and control over a specific engine version | Fewer orchestration layers, but no unified gallery, resource scheduling or resumable cross-engine production |

These are architectural fit comparisons, not side-by-side benchmarks.

## Self-Hosting Notes

Treat this as a workstation application, not a public web service. The documented target is NVIDIA Windows/Linux with Python 3.11+ (setup instructions favor 3.12), ffmpeg and compatible drivers; README recommends at least 12 GB VRAM and assumes 32 GB RAM while describing constrained lower-memory paths. GPU-free editing does not make generation CPU-friendly.

Before a controlled trial: pin studio and all engine revisions, capture package/model versions and hashes, review upstream licenses, budget disk and temporary download space, retain loopback binding, separate sensitive OS data and test project recovery with disposable assets. Before any LAN/team hosting: add authentication and authorization, isolate database/internal files from static media, enforce upload/resource limits, protect mutating routes and audit child-engine listeners. A reverse-proxy login alone does not repair all underlying trust assumptions.

---

**Attribution:** YUZUKI (ゆずき) / animede, YUZU Creator Studio (`h3-creator-studio`), Apache-2.0 studio code; upstream components and model terms remain separate.

[readme]: https://github.com/animede/h3-creator-studio/blob/4d76328ca7a4618add48317247d2ffafcb4c5130/README.en.md
[config]: https://github.com/animede/h3-creator-studio/blob/4d76328ca7a4618add48317247d2ffafcb4c5130/studio.toml
[handlers]: https://github.com/animede/h3-creator-studio/tree/4d76328ca7a4618add48317247d2ffafcb4c5130/studio/handlers
[scheduler]: https://github.com/animede/h3-creator-studio/blob/4d76328ca7a4618add48317247d2ffafcb4c5130/studio/scheduler.py
[jobs]: https://github.com/animede/h3-creator-studio/blob/4d76328ca7a4618add48317247d2ffafcb4c5130/studio/jobs.py
[llm]: https://github.com/animede/h3-creator-studio/blob/4d76328ca7a4618add48317247d2ffafcb4c5130/studio/llm.py
[mv]: https://github.com/animede/h3-creator-studio/blob/4d76328ca7a4618add48317247d2ffafcb4c5130/studio/mv.py
[short]: https://github.com/animede/h3-creator-studio/blob/4d76328ca7a4618add48317247d2ffafcb4c5130/studio/short.py
[ledger]: https://github.com/animede/h3-creator-studio/blob/4d76328ca7a4618add48317247d2ffafcb4c5130/studio/ledger.py
[api]: https://github.com/animede/h3-creator-studio/blob/4d76328ca7a4618add48317247d2ffafcb4c5130/studio/main.py
[edit]: https://github.com/animede/h3-creator-studio/blob/4d76328ca7a4618add48317247d2ffafcb4c5130/studio/edit.py
[setup]: https://github.com/animede/h3-creator-studio/blob/4d76328ca7a4618add48317247d2ffafcb4c5130/scripts/setup.py
[death-tests]: https://github.com/animede/h3-creator-studio/blob/4d76328ca7a4618add48317247d2ffafcb4c5130/tests/test_engine_death.py
[tests]: https://github.com/animede/h3-creator-studio/tree/4d76328ca7a4618add48317247d2ffafcb4c5130/tests
[manifest]: https://github.com/animede/h3-creator-studio/blob/4d76328ca7a4618add48317247d2ffafcb4c5130/pyproject.toml
[license]: https://github.com/animede/h3-creator-studio/blob/4d76328ca7a4618add48317247d2ffafcb4c5130/LICENSE
[notice]: https://github.com/animede/h3-creator-studio/blob/4d76328ca7a4618add48317247d2ffafcb4c5130/NOTICE
[samples]: https://github.com/animede/h3-creator-studio/tree/4d76328ca7a4618add48317247d2ffafcb4c5130/samples
