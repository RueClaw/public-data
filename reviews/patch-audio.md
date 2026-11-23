# Patch Audio (novuon/patch-audio)

**Repo:** https://github.com/novuon/patch-audio
**License:** MIT for Patch source; normal linked binaries, public kits, optional engines and models have separate terms.
**Reviewed:** 2026-11-23 (UTC)
**Revision:** `1d4913ae9d55b740366a260619e051115dfdf569`, default branch, whole-repository static survey with targeted implementation inspection.
**Release:** Manifest version 0.8.7; public source release v0.8.7 published 2026-11-23T15:04:48Z; its tag resolves to e67dbe42e6a127b9d6c50e5bb19dca1dd7009345, not the reviewed HEAD. Binary release v0.8.7 was published 2026-11-23T15:03:33Z in novuon/patch-releases. Binary/source equivalence was not tested.
**Verification:** Static review only. No installation, build, tests, audio capture/playback, model download, inference, device access or paid calls. Anonymous Git HTTPS and GitHub API access confirmed the source is public.
**Stack:** Rust 2024, Slint 1.18, PipeWire C integration, x86-64 DSP assembly, SQLite, FFmpeg/mpv; optional Python/PyTorch/Demucs.
**What it is:** A native Omarchy desktop audio environment combining system mixing/routing, DJ decks, metering, recording, broadcasting and live-coding surfaces—not a text-to-audio foundation model or a general DAW.

---

## Verdict

⚠️ **Interesting: substantial audio engineering, but pilot it before making it the system's sound.** The detached engine, bounded recording pipeline and supervised plugin host are meaningful designs. The reviewed public build explicitly disables the AI DJ planner, performance evidence is author-reported rather than independently reproduced, and installing this is a desktop/audio-system change with meaningful trust and licensing obligations.

## What It Is

Patch targets x86-64 Omarchy on Arch Linux with Hyprland 0.56 or newer. One engine serves multiple Slint windows, a CLI and controller integrations. Its scope includes app channel strips, AUX/FX buses, EQ, DSP routing, DJ decks, library analysis, metering, recording, podcast/broadcast features and optional LAN/phone control. The README is supported by real PipeWire/recording implementations; the application manifest's description still says “UI prototype, all audio simulated,” which is stale rather than a reliable description of the inspected code. [1][2][3]

This breadth should not be confused with feature parity across every delivery channel. The public AI crate declares AVAILABLE = false and suggest() returns an empty vector. Documentation mentioning Auto Mix and AI-driven stem preparation therefore does not establish that the public checkout contains a functioning planner. Optional stem separation is a distinct, implemented subprocess integration. [4][5]

## Stack

| Layer | Tech |
|-------|------|
| UI and host | Slint, Rust, Wayland/Hyprland integration |
| Real-time engine | PipeWire filter, Rust/C boundary, reference/SSE2/AVX2 DSP tiers |
| Control | Canonical commands, local Unix sockets, JSON messages; optional HTTP remote |
| Storage | SQLite library in WAL mode, JSON session/config/job state, filesystem audio/cache |
| Media | FFmpeg/ffprobe; detached mpv player; Broadcast WAV/RF64 writer |
| Optional extensions | Out-of-process VST3 host, Python separators, separately installed Node adapters |

## Key Features

### A real engine with separated control and analysis

The engine represents named stereo channels and a program output. It uses preallocated rings for meters/audio, with loudness/true-peak/spectrum analysis off the real-time callback. Window lifecycle is separated from engine lifecycle, so closing the UI is not a stop command. This is good architectural evidence, not a proof that every callback path is allocation-free or every update is seamless. [3]

### Recording and plugin failure containment

The WAV writer uses exclusive creation, periodically updates headers and syncs data, and supports RF64 for large takes. Recorder documentation specifies a bounded 128-buffer/8 MiB capture pool that fails instead of growing indefinitely on slow storage. These mechanisms reduce damage; they do not promise zero lost frames or power-loss immunity. [6]

Plugin inserts use shared-memory blocks and a separate host, with one-block processing latency, dry fallback when late, and supervision/restart when the host fails. That is crash containment—not an OS sandbox. Native plugins still need to be trusted with the user's process authority. [7]

### Optional stems, not generative audio

The default setup provisions a Python 3.11 environment, pinned top-level torch/torchaudio/demucs/numpy/soundfile packages and a hash-checked htdemucs checkpoint. The separator receives source/output paths and emits four stem files. Worker locking, parent-death handling, cancellation, persisted batches and cache pinning are useful operational features. [5][8]

The benchmark script measures elapsed time, RSS/VRAM, output finiteness/alignment and reconstruction RMS; it explicitly disclaims ground-truth SDR and blind listening scores. A sum that reconstructs the mix does not establish perceptual isolation quality. No model or audio was downloaded or auditioned for this review. [8]

## Architecture

The Cargo workspace separates core command/data types, host/windows, surfaces, PipeWire integration, engine, DSP, library/analysis, recording, broadcast, networking, controllers, plugins and remote access. Native library build scripts and vendored patches remain part of the build trust boundary. Cargo.lock is present and the toolchain is pinned to Rust 1.99.0. [2]

The engine keeps the audio session outside the windows; Unix-socket commands mutate the control plane. Socket permissions are the authority boundary: peer PID/UID/GID are logged, but the control code explicitly says a different UID is accepted if it can reach the socket. Do not loosen runtime-directory/socket permissions or treat this as a multi-user authorization service. [9]

### Auth, privacy and egress

- **Phone/browser control:** patch-remote binds loopback on port 8124, defaults to read-only, and requires an owner-only 64-hex-character pairing secret for API access. Control additionally requires --control, a session token and matching Origin. The Tailscale path constrains HTTPS host and account through local whois and still requires pairing; Funnel is denied. The code correctly acknowledges that forwarded headers alone cannot authenticate a loopback TCP peer. These are reviewed safeguards, not penetration-test results. [10]
- **Local privacy:** music paths/titles, analysis, play history, queues, recordings, stem caches and adapter logs are durable user data. The library documentation makes the music directory a default source. “Local” does not mean “ephemeral” or “no scanning.” [11]
- **Network egress:** optional installation/modules contact project release hosts/GitHub; stem setup contacts PyTorch package hosting, package indexes and Meta's public checkpoint host. Player accepts HTTP(S) streams. Broadcast sends selected audio and potentially rendered visuals to Icecast/RTMP; LAN networking delegates RTP/SAP/VBAN to PipeWire. These are intended data paths, not evidence of hidden telemetry. No runtime traffic audit was performed. [8][12][13]
- **Credentials:** broadcast UI/status redaction is useful, but the documentation and FFmpeg construction show that destination credentials/stream keys remain in FFmpeg's URL arguments while running. HTTP/RTMP are supported alongside HTTPS/RTMPS: choose encrypted endpoints and consider same-user process inspection. Never assume UI masking makes the credential inaccessible. [12]

### Execution authority and supply chain

The suggested curl-to-shell installer was not run. The inspected installer can install Arch packages with sudo, alter realtime-group membership, install controller udev rules and configure/start optional remote services/Tailscale Serve. This is not an inert desktop download. Review those changes and maintain a route back to ordinary system audio before installation. [14]

There are positive integrity controls: module manifests have Ed25519 verification, payload size/SHA-256 checks and staged extraction; the kit installer compares a separately downloaded checksum. A checksum downloaded beside an archive does not independently authenticate a compromised distributor, and signatures do not establish safe behavior. No downloaded release, signature, reproducible build or vulnerability scan was verified here. [13][14]

The separator subprocess is not privilege-isolated: configurable Python/adapter paths run as the user, with no environment clearing or OS sandbox evident in the inspected launcher. Particularly important, the optional MSST adapter imports code from a configured repository and calls torch.load(..., weights_only=False). Treat such checkpoint files as executable-trust inputs; a matching user-configured hash establishes identity, not safety. The Python setup pins direct versions but does not provide a complete hash-locked transitive environment. [5][8]

### Persistence, recovery and export

The DJ session persists as JSON independently of UI windows. The library uses SQLite WAL, schema migration backups and package-relative media handling. Stem jobs/batches and cache metadata use staged/atomic writes and include restart tests; this is stronger than a purely in-memory queue. A proper backup must include metadata, state and the original audio, not only the main SQLite file while writes are active. [11][15]

Recordings are ordinary Broadcast WAV/RF64 files; stems are WAV outputs; library packages and JSON state reduce opaque lock-in. This is not evidence of complete interchange with another DJ application's cues/playlists, nor a tested full-system restore. No crash/restart, migration, cache eviction, database backup restoration or export round-trip was exercised. [6][15]

## Audio Claims and Evidence

| Claim/evidence | Assessment |
|---------------|------------|
| Real-time mixing, ramps, SIMD and off-thread analysis | Substantial implementation exists. Unsafe/FFI/assembly paths need runtime stress and correctness testing, not language-level trust alone. [3] |
| Very low callback costs / large SIMD speedups | docs/bench.md reports hardware, tiers and method; its introductory baseline is Patch 0.4.0, not this HEAD. It explicitly uses a non-real-time benchmark thread and discusses scheduler noise and a baseline fmaf cost. Do not interpret its microseconds or 31.3× mix kernel result as end-to-end audio latency or whole-app speedup. [16] |
| 93.5% exact tempo on 956 tracks | Author-reported ±0.5% comparison against weak BPM tags with genre skew, not a released ground-truth cross-genre benchmark. [16] |
| Four-stem quality | Integration exists; local benchmark explicitly measures reconstruction rather than SDR/listening quality. Not independently evaluated. [8] |
| AI DJ / Auto Mix planner | Public crate disables the planner and returns no suggestions; do not purchase or deploy on an assumption of source-level availability. [4] |

## License and Reuse

Patch's own MIT source permits reuse with its copyright/license notice retained. That headline is not a blanket MIT license for a distributed application. NOTICE.md explains that normal builds link GPL-2.0-or-later Rubber Band/FFTW and can use Slint's GPL-3.0 option, with the described combined binary distribution under GPL-3.0. Public tester kits instead use MIT Signalsmith and Slint's royalty-free application terms with attribution. Verify the actual artifact and chosen license route before redistributing. [17]

Optional Strudel/Hydra engines have AGPL obligations; process separation is not an automatic exemption for modified/distributed components. The repository documents separate installation and scope. Model code, checkpoint licenses, training-data permissions and rights to the source music remain separate: the htdemucs download/digest identifies an artifact, but this review did not establish a complete checkpoint/model-card/training-data rights chain. MSST profiles can select other repositories/checkpoints with their own terms. Do not infer permission to redistribute music, stems, weights or training material from Patch's MIT license. No source code, models or samples were extracted into this review. [8][17][18]

## Maturity and Verification

Anonymous GitHub metadata on 2026-11-23 reported 5 stars, 0 forks, 0 open source-repository issues and last push 2026-11-23T16:08:41Z. The binary repository's open-issue query returned no items. These are point-in-time counts, not reliability evidence. Release history is delegated to novuon/patch-releases; the observed latest release is v0.8.7. Canonical-source deduplication found no earlier matching public review. [19]

There are Rust unit/integration tests for DSP/engine behavior, recording and remote auth, a stem restart test and separate Python/browser integration scripts. No .github/workflows directory is present in the reviewed tree, despite notices referring to release/public-kit workflows; their effective gates and latest passing results were not verified. Tests were inspected but **none were run**, and neither a green CI claim nor a clean compile is asserted. [20]

The central limitation is operational: no target-machine audio latency/xrun test, hearing/listening evaluation, controller compatibility check, release execution, model quality test or security sandbox validation was performed. A sensible next evaluation would use non-sensitive, licensed test audio on a disposable compatible desktop and measure device round-trip latency, xruns under UI/plugin load, unplug/replug behavior, recorder failures and explicit stop/recovery paths.

## Comparison

| Aspect | Patch | Alternative |
|--------|-------|-------------|
| Whole-desktop processing | Integrated mixer/routing plus DJ/podcast surfaces, tightly Omarchy-specific | [EasyEffects](https://github.com/wwmm/easyeffects) for PipeWire input/output processing with less DJ scope |
| Dedicated DJ workflow | Integrated decks/library/controller work, but public AI planner absent and documented controller scripting gaps | [Mixxx](https://github.com/mixxxdj/mixxx) for a dedicated DJ application and established controller ecosystem |
| Multitrack production/editing | Recording/player facilities; documentation calls waveform editing and multitrack recording future work | [Ardour](https://ardour.org/) for a DAW-oriented workflow |

These are category/fit comparisons, not a measured head-to-head or fresh security audit of the alternatives. Patch's own controller investigation explicitly explains why importing Mixxx mappings does not yield working scripted platter controls today. [18]

## Self-Hosting Notes

This is a native desktop deployment, not a server/container service. Source prerequisites include the pinned Rust toolchain, compiler/pkg-config and native PipeWire/Rubber Band/SQLite libraries. Keep the normal-build and kit license paths distinct. Enable only needed modules; leave phone control and broadcasting off until deliberately configured. Back up library/session state and retain a tested ordinary PipeWire output path. Closing windows does not necessarily stop audio, recording or broadcast; use explicit stop controls. No installation or configuration change was performed for this review. [1][6][12][14]

## Sources

All repository file citations below are pinned to the reviewed SHA; release/API metadata is a dated observation.

[1]: https://github.com/novuon/patch-audio/blob/1d4913ae9d55b740366a260619e051115dfdf569/README.md
[2]: https://github.com/novuon/patch-audio/blob/1d4913ae9d55b740366a260619e051115dfdf569/Cargo.toml
[3]: https://github.com/novuon/patch-audio/blob/1d4913ae9d55b740366a260619e051115dfdf569/crates/patch-engine/src/lib.rs
[4]: https://github.com/novuon/patch-audio/blob/1d4913ae9d55b740366a260619e051115dfdf569/crates/patch-ai/src/lib.rs
[5]: https://github.com/novuon/patch-audio/blob/1d4913ae9d55b740366a260619e051115dfdf569/crates/patch-stems/src/separator.rs
[6]: https://github.com/novuon/patch-audio/blob/1d4913ae9d55b740366a260619e051115dfdf569/crates/patch-record/src/wav.rs
[7]: https://github.com/novuon/patch-audio/blob/1d4913ae9d55b740366a260619e051115dfdf569/crates/patch-plugin/src/chain.rs
[8]: https://github.com/novuon/patch-audio/tree/1d4913ae9d55b740366a260619e051115dfdf569/tools/stems
[9]: https://github.com/novuon/patch-audio/blob/1d4913ae9d55b740366a260619e051115dfdf569/crates/patch-engine/src/daemon/control.rs
[10]: https://github.com/novuon/patch-audio/tree/1d4913ae9d55b740366a260619e051115dfdf569/crates/patch-remote/src
[11]: https://github.com/novuon/patch-audio/blob/1d4913ae9d55b740366a260619e051115dfdf569/docs/library.md
[12]: https://github.com/novuon/patch-audio/blob/1d4913ae9d55b740366a260619e051115dfdf569/docs/broadcast.md
[13]: https://github.com/novuon/patch-audio/blob/1d4913ae9d55b740366a260619e051115dfdf569/app/src/modules_cli.rs
[14]: https://github.com/novuon/patch-audio/blob/1d4913ae9d55b740366a260619e051115dfdf569/install.sh
[15]: https://github.com/novuon/patch-audio/blob/1d4913ae9d55b740366a260619e051115dfdf569/crates/patch-library/src/package.rs
[16]: https://github.com/novuon/patch-audio/blob/1d4913ae9d55b740366a260619e051115dfdf569/docs/bench.md
[17]: https://github.com/novuon/patch-audio/blob/1d4913ae9d55b740366a260619e051115dfdf569/NOTICE.md
[18]: https://github.com/novuon/patch-audio/blob/1d4913ae9d55b740366a260619e051115dfdf569/docs/controllers-scripting.md
[19]: https://github.com/novuon/patch-audio/releases/tag/v0.8.7
[20]: https://github.com/novuon/patch-audio/tree/1d4913ae9d55b740366a260619e051115dfdf569/integration

Additional inspected evidence: [application manifest](https://github.com/novuon/patch-audio/blob/1d4913ae9d55b740366a260619e051115dfdf569/app/Cargo.toml), [toolchain](https://github.com/novuon/patch-audio/blob/1d4913ae9d55b740366a260619e051115dfdf569/rust-toolchain.toml), [IPC permissions](https://github.com/novuon/patch-audio/blob/1d4913ae9d55b740366a260619e051115dfdf569/crates/patch-core/src/ipc.rs), [recording/player documentation](https://github.com/novuon/patch-audio/blob/1d4913ae9d55b740366a260619e051115dfdf569/docs/recording-playback.md), [stem restart test](https://github.com/novuon/patch-audio/blob/1d4913ae9d55b740366a260619e051115dfdf569/crates/patch-stems/tests/restart.rs), [stem cache](https://github.com/novuon/patch-audio/blob/1d4913ae9d55b740366a260619e051115dfdf569/crates/patch-stems/src/cache.rs), [session](https://github.com/novuon/patch-audio/blob/1d4913ae9d55b740366a260619e051115dfdf569/crates/patch-engine/src/session.rs), [network implementation](https://github.com/novuon/patch-audio/blob/1d4913ae9d55b740366a260619e051115dfdf569/crates/patch-network/src/lib.rs), [broadcast implementation](https://github.com/novuon/patch-audio/blob/1d4913ae9d55b740366a260619e051115dfdf569/crates/patch-broadcast/src/daemon.rs), [third-party engines](https://github.com/novuon/patch-audio/blob/1d4913ae9d55b740366a260619e051115dfdf569/docs/third-party-engines.md), [MIT license](https://github.com/novuon/patch-audio/blob/1d4913ae9d55b740366a260619e051115dfdf569/LICENSE), [binary release](https://github.com/novuon/patch-releases/releases/tag/v0.8.7), [public metadata](https://api.github.com/repos/novuon/patch-audio).

---

**Attribution:** novuon/patch-audio, MIT source; third-party and model/data terms as discussed above. Independent static analysis, not an endorsement or reproduction of upstream benchmark results.
