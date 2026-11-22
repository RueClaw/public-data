# Flowtunes (omacom/flowtunes)

**Repo:** https://github.com/omacom/flowtunes
**License:** MIT for application code; model, runtime, imported music and generated-content rights are separate.
**Reviewed:** 2026-11-22 (UTC)
**Revision:** `8a9a76fde98f22e21ddd3f1286d2ecd120060675` (master; entire application source, tests, build and CI). Commit dated 2026-11-21. Latest published release observed: v0.2.0, 2026-11-20, commit `50420da3c6e4669dd88f819045631b93568a7441`; reviewed HEAD is newer, despite the same application version string.
**Verification:** Static source review; public GitHub metadata and upstream CI result checked. No application execution, compilation, playback, model/media downloads, installation or hardware probes.
**Stack:** C++17, Qt 6/QML, Qt Multimedia, Qt Network, D-Bus/MPRIS, FFmpeg, CMake; external Omarchy local-model engine.
**What it is:** An Omarchy-oriented desktop radio that generates successive songs from genre presets, saves them as MP3s, and reuses a local music library. It is not a streaming-service client or a bundled music model.

## Verdict

⚠️ **Interesting — a thoughtful local-radio frontend, not yet a broadly proven music appliance.** Queueing, atomic saves, failure handling and desktop integration are unusually deliberate for a two-day-old repository. Its usefulness still depends on an independently installed model engine, adequate generation speed, and acceptance of model/content provenance limits. “Local” can include a paired remote host, and the application itself does not enforce an offline or sandboxed boundary.

## What It Is

Pick one of twelve genres: Lo-fi, Ambient, Synthwave, Deep House, Techno, Drum & Bass, Jazz, Classical, Downtempo, Post-Rock, Acoustic or Cinematic. Built-in caption fragments vary each generation; an optional lyrics mode asks the model to write vocals in the selected language. Tracks target 180 seconds. The application tries to keep two prepared tracks behind the current one, but this is a buffer target, not proof that playback or rapid skipping can never stall. [E1–E3]

Existing MP3s in each genre folder are shuffled and consumed before generation begins. The lyrics switch filters by filename: files ending in `-instrumental` (including numbered collisions) are instrumental; other MP3s are treated as sung. This is a naming convention, not audio classification. Saved-library playback does not inherently require a running generator. [E2]

## Stack

| Layer | Technology and boundary |
|---|---|
| UI | Qt Quick/QML, embedded resources, shader aurora and waveform display |
| Orchestration | C++ Flow state machine, Models discovery, Backend facade |
| Generation | External engine endpoint; asynchronous `/lm`, `/synth`, `/job` protocol |
| Audio | Lazy-loaded Qt Multimedia player; FFmpeg subprocess for waveform analysis |
| Persistence | MP3 files and QSettings; no application database |
| Desktop | Session-bus MPRIS; Omarchy theme/language file watching; Hyprland rounding query/event socket |
| Build | CMake, system Qt libraries and Arch package dependencies |

## Key Features

### Buffered generation with explicit recovery

`Flow` posts a caption/lyrics/language request to `/lm`, submits the resulting song description to `/synth`, polls jobs every 500 ms, and fetches the result. HTTP transfers have a 30-second timeout. Failed generation retries after three seconds, with slower 30-second retries while music remains available; exhausted playback exposes an error and explicit retry. Lyrics generation has a six-attempt ceiling when the model returns too few sung lines. [E2–E3]

A generation counter ignores stale callbacks after genre changes. Known jobs receive cancellation requests, including jobs whose IDs arrive after reset; event-loop lockers give cancellation a chance during ordinary window close. This is best-effort cancellation, not crash-safe job recovery: there is no persisted outstanding-job journal. A server that keeps returning a nonterminal status can be polled indefinitely; there is no overall job deadline. [E2]

### Durable music, limited provenance

Generated MP3s are saved under the standard Music location in genre folders, with timestamp, BPM, key and instrumental suffix in the filename. Collision suffixes avoid ordinary duplicate names. `QSaveFile` commits atomically with direct-write fallback disabled; write failures become visible errors. Genre and lyrics choice survive in QSettings, but playback position/queue do not. No retention quota, automatic cleanup, backup or disk-space budget is implemented. [E2]

Track titles are generated from a repeated lyric line or a built-in genre word pair. The writer replaces the leading ID3v2 tag with a title tag; it does not preserve a full generation manifest, model revision, seed, prompt, lyrics or licensing record alongside each song. Imported MP3s retain their existing files. Consequently, saved output is convenient listening material but weak evidence for reproducible generation or rights clearance. [E2]

### Real desktop integration

Media keys and MPRIS support play/pause/next, seek, raise and quit; Previous restarts the current song rather than maintaining history. Metadata includes title, genre and local file URL. Theme/language changes are watched, and Hyprland rounding is queried rather than implemented as a separate window-manager policy. Audio quality, gaplessness, accessibility and translation quality were not tested. [E4–E5]

## Architecture

`main.cpp` wires Theme, Translator and Backend into QML. Backend owns Models, Flow and Mpris. Models reads the engine status/list/network files, selects a music model, and reads a local or paired-host bearer key. Local active music is preferred over a remote active model; a paired active host can serve when local generation is unavailable. Flow owns the request lifecycle and local queue; TunePlayer owns actual audio playback. [E2, E4–E6]

The process invokes `omarchy-agent-local` using a program and argument list, not a constructed shell command. Startup requests a detached cache refresh; playback may start an installed model automatically. Installing a model and stopping blocking text models are offered through UI actions. Those are real lifecycle/resource effects, not merely player preferences. FFmpeg and `hyprctl` are also subprocess dependencies. [E5–E6]

## Security, Permissions and Privacy

- **Desktop trust, not application sandboxing:** normal user filesystem, network, audio and session-bus privileges apply. No microphone/camera capture, application account, browser server or analytics SDK was found in the reviewed source. There is no application-level multi-user auth/CORS surface; generation-server authorization belongs to the engine. This is not a full dependency or binary audit. [E2, E4–E6]
- **Credentials and endpoint trust:** requests attach a bearer key loaded from the engine configuration. Remote key filenames validate host labels against a restricted character set. However, endpoint selection trusts engine state: `origin()` checks URL validity/host and strips `/v1`, without enforcing HTTPS, loopback-only addressing or a destination allowlist. Tampered trusted-user state could redirect authenticated requests. Protect engine state and key files; a remote route must supply its own transport security. [E2, E6]
- **Not strictly on-device:** genre captions, vocal-language choice and generated song descriptions can travel to a paired music server; audio returns from it. No code path uploading the user’s existing MP3 library was found. Setup delegates image/model downloads to the engine, so “no telemetry found” does not mean “no network.” Remote-server logging and retention were not audited. [E2, E6, E9]
- **Desktop metadata exposure:** MPRIS publishes local track URLs and titles to the session bus and accepts controls from its peers. This is expected desktop integration, but not private from other processes with session-bus access. [E4]
- **Input/resource hardening gaps:** network results are read into memory without an explicit response-size limit; multipart audio parsing is minimal, and job IDs are concatenated into query strings rather than encoded with a query builder. FFmpeg and Qt parse local/generated media with user privileges. There is no FFmpeg deadline here. Waveform downsampling reduces storage greatly, but its levels buffer still grows with track duration despite the source comment suggesting constant memory. These are static robustness concerns, not demonstrated exploits. [E2]

## Media Provenance and Licenses

The actual application LICENSE grants MIT permissions and attributes David Heinemeier Hansson plus Omarchy starter files; preserve notices when redistributing code. GitHub’s metadata classified it as “Other,” but the checked license text is MIT. That grant does not license arbitrary imported songs, guarantee generated music is non-infringing, or establish rights in training data. [E7]

Flowtunes does not bundle recordings or weights and does not fix one model revision in its own source. As a concrete integration example, the public engine catalog at `e7fe801bc66dab37118baa8d4e06c5d786a3f45e` offers ACE-Step 1.5 Turbo: a 4B language model, 2B diffusion model, Qwen3 embedding encoder and VAE, using the third-party `Serveurperso/ACE-Step-1.5-GGUF` conversion at `666ac70204440867d8c01ba4b119cc79c95b370a`. That recipe labels its artifacts MIT and lists 7.57 GiB of downloads excluding the runtime image. This is an engine-maintainer declaration, not an independent audit of every upstream weight license, training corpus or generated-output right. [E9]

The engine’s pinned runtime review declares an MIT acestep.cpp build and retained third-party notices. Its isolation and authorization acceptance tests are upstream reports, not tests repeated here. Qt, FFmpeg, container contents and model components retain their own applicable licenses. Do not market the resulting music as guaranteed royalty-free solely because the frontend is MIT. No generated audio was acquired or listened to for this review. [E9]

## Persistence and Operational Fit

Saved MP3s remain useful after restart; invalid/unreadable library media can be skipped, and three successive playback failures produce an error. Atomic commits protect against partially written final files, not disk exhaustion, simultaneous-process races, user deletion or loss of the music directory. An interrupted generation may leave work at the remote server even though no local song was saved. [E2]

Hardware suitability is external. The example Vulkan recipe reports an 8 GiB memory budget and a 45-second generation measurement for a 180-second song on one Strix Halo configuration; the runtime review reports 109 seconds for 60 seconds of audio on a different Intel configuration. These are distinct upstream measurements, not directly comparable benchmarks or universal real-time guarantees. A queue cannot make a slower-than-playback model sustain an endless fresh stream. [E9]

## Maturity, Tests and Supply Chain

Public metadata observed on 2026-11-22: repository created 2026-11-20, last pushed 2026-11-21, 4 stars, 1 fork and 1 open issue/PR counter entry. These are a time-stamped snapshot, not quality evidence. v0.2.0 is the latest observed release; its annotated tag was reported unsigned. [E8]

The 1,360-line Qt test file covers discovery, paired-host keys, queueing, cancellation, failure/retry behavior, library reuse, names/tags, translations, theme handling, QML interaction and MPRIS. The upstream Actions run for the exact reviewed commit reports **success**. This review did not run the tests or independently reproduce that result. Tests exercise synthetic services and desktop components; their existence is stronger evidence than a screenshot, but not a substitute for sustained generation/playback testing. [E8]

CI has read-only repository permissions and builds/tests as an ordinary user, but uses mutable `archlinux:latest`, `actions/checkout@v4` rather than a commit pin, rolling packages, and downloads then **sources** the current external omarchy-pkgs PKGBUILD in its dependency-install step. That external branch is executable CI input and weakens reproducibility. The observed package recipe pins the release archive by SHA-256 and lists Qt Multimedia/FFmpeg runtime dependencies that are not all evident from CMake’s linked components. No complete lockfile/SBOM or reproducible-build proof was found in the inspected application tree. [E8, E10]

## Comparison

| Option | Best fit | Tradeoff against Flowtunes |
|---|---|---|
| Flowtunes | Preset-driven background music and Omarchy media keys | Minimal creative controls; depends on engine integration and generation speed |
| [acestep.cpp](https://github.com/ServeurpersoCom/acestep.cpp) | Direct local music-generation server/browser UI | More direct generation workflow and platform/backend choices; not the same genre-radio desktop experience |
| [VLC](https://www.videolan.org/vlc/) with a licensed local library | Predictable playback without a model | No fresh AI generation, but avoids inference cost and model-weight provenance; music rights still matter |

These are workflow comparisons, not hands-on quality or performance benchmarks. Prefer an ordinary player when the goal is simply reliable background music; study Flowtunes when the goal is a small native UI over asynchronous local-generation jobs.

## Self-Hosting Notes

This is a desktop application, not a web service to expose publicly. Building requires the declared CMake/Qt toolchain; operation also requires Qt Multimedia, FFmpeg and a compatible model engine for new songs. Omarchy packaging supplies these pieces, but package v0.2.0 is not identical to the reviewed master commit. Setup can download multi-gigabyte model artifacts and start or stop model services. No installation is recommended as part of this review; first verify compatible engine commands, hardware, authenticated endpoint routing, storage policy and component/content licenses. [E6, E8–E10]

## Evidence and Limits

All source evidence is public. Static review cannot establish audible quality, sustained throughput, real-world cancellation, GPU isolation, absence of dependency vulnerabilities, accessibility, or legal clearance. No application/server probes, accounts, deployments or media downloads were performed. HTML/index checks validate the review artifacts, not Flowtunes itself.

- **E1:** [README and product claims](https://github.com/omacom/flowtunes/blob/8a9a76fde98f22e21ddd3f1286d2ecd120060675/README.md).
- **E2:** [Flow implementation](https://github.com/omacom/flowtunes/blob/8a9a76fde98f22e21ddd3f1286d2ecd120060675/src/flow.cpp).
- **E3:** [Flow constants](https://github.com/omacom/flowtunes/blob/8a9a76fde98f22e21ddd3f1286d2ecd120060675/src/flow.h) and [genre presets](https://github.com/omacom/flowtunes/blob/8a9a76fde98f22e21ddd3f1286d2ecd120060675/src/genres.cpp).
- **E4:** [MPRIS](https://github.com/omacom/flowtunes/blob/8a9a76fde98f22e21ddd3f1286d2ecd120060675/src/mpris.cpp) and [player](https://github.com/omacom/flowtunes/blob/8a9a76fde98f22e21ddd3f1286d2ecd120060675/src/TunePlayer.qml).
- **E5:** [main](https://github.com/omacom/flowtunes/blob/8a9a76fde98f22e21ddd3f1286d2ecd120060675/src/main.cpp), [QML](https://github.com/omacom/flowtunes/blob/8a9a76fde98f22e21ddd3f1286d2ecd120060675/src/Main.qml), [theme](https://github.com/omacom/flowtunes/blob/8a9a76fde98f22e21ddd3f1286d2ecd120060675/src/theme.cpp).
- **E6:** [Engine discovery, credentials and lifecycle](https://github.com/omacom/flowtunes/blob/8a9a76fde98f22e21ddd3f1286d2ecd120060675/src/models.cpp).
- **E7:** [Application LICENSE](https://github.com/omacom/flowtunes/blob/8a9a76fde98f22e21ddd3f1286d2ecd120060675/LICENSE).
- **E8:** [Tests](https://github.com/omacom/flowtunes/blob/8a9a76fde98f22e21ddd3f1286d2ecd120060675/tests/flowtunes_tests.cpp), [CI configuration](https://github.com/omacom/flowtunes/blob/8a9a76fde98f22e21ddd3f1286d2ecd120060675/.github/workflows/test.yml), [exact-commit successful run](https://github.com/omacom/flowtunes/actions/runs/44940963110), [release](https://github.com/omacom/flowtunes/releases/tag/v0.2.0), [public metadata](https://api.github.com/repos/omacom/flowtunes).
- **E9:** Engine [README](https://github.com/omacom/omarchy-local-ai/blob/e7fe801bc66dab37118baa8d4e06c5d786a3f45e/README.md), [model recipe](https://github.com/omacom/omarchy-local-ai/blob/e7fe801bc66dab37118baa8d4e06c5d786a3f45e/recipes/ace-step-1.5-turbo-acestep.toml), [runtime](https://github.com/omacom/omarchy-local-ai/blob/e7fe801bc66dab37118baa8d4e06c5d786a3f45e/runtimes/acestep.toml), [upstream runtime review](https://github.com/omacom/omarchy-local-ai/blob/e7fe801bc66dab37118baa8d4e06c5d786a3f45e/reviews/acestep-93d2296c887c.toml).
- **E10:** [Package recipe](https://github.com/omacom/omarchy-pkgs/blob/a673427cb54d9e98a0b2f282c2ef883c4e1be35c/pkgbuilds/flowtunes/PKGBUILD) and [CMake build](https://github.com/omacom/flowtunes/blob/8a9a76fde98f22e21ddd3f1286d2ecd120060675/CMakeLists.txt).

---

**Attribution:** omacom/flowtunes; David Heinemeier Hansson; application code MIT. Related engine/package and alternative projects are attributed through their public source links. No source code or media is redistributed in this review.
