# Source Roll (TechHutTV/sourceroll)

**Repo:** https://github.com/TechHutTV/sourceroll
**License:** MIT at the reviewed revision; retain both copyright notices and permission notice when reusing substantial code. Dependencies retain their own terms.
**Reviewed:** 2026-11-25 (UTC)
**Revision:** 1392f794e11585e605e5fa96b76ff9ded1f4fc91 — master and v0.6.0; whole-repository static review focused on src/, plugin/, tests/, packaging, workflows and documentation.
**Verification:** Anonymous public acquisition; implementation and test-source inspection, release/tag and CI metadata checked. No source execution, installation, recording, hardware tests or binary verification.
**Stack:** C++17, Qt 6 / QML, FFmpeg/ffprobe, GPU Screen Recorder, PipeWire/PulseAudio, V4L2; Python installation/testing scripts.
**What it is:** A native Omarchy recording application that saves independently editable screen, camera, microphone and desktop-audio sources, plus timing metadata and an OpenTimelineIO timeline. It is not a source-code management service or an OBS-style live compositor.

---

## Verdict

⚠️ **Interesting — a focused post-production recorder worth a disposable pilot, not yet an unqualified production recommendation.** Separate outputs, shared previews and explicit interruption handling are strong design choices. The very young project has substantive tests and a successful release workflow, but timing is not physical synchronization, several real-device paths remain unverified, and static inspection exposes configuration and timeline-finalization edge cases.

## What It Is

Source Roll is for creators who want to decide framing, camera placement and audio mixing in an editor rather than bake them into one composited video. Up to eight video sources can be configured, plus one microphone and one desktop-audio source. Screens/windows use GPU Screen Recorder; cameras use FFmpeg's V4L2 input; audio uses FFmpeg's PulseAudio input. Native-resolution video is saved separately from small monitoring previews. [E1–E4]

It is intentionally Omarchy/Arch-oriented: a Qt Quick window, resident per-user recorder, command-line controls and optional Omarchy bar widget share the same backend. Streaming, transitions, live compositing, headphone monitoring and multiple microphones are outside the documented scope. Closing the window hides it; it does **not** stop an active take. [E1, E2, E5]

## Stack

| Layer | Technology / role |
|---|---|
| UI | Qt Quick/QML; English/Danish catalogs and live Omarchy theme integration |
| Coordination | C++17 Qt event loop; Backend, SessionRecorder and per-source feed objects |
| Capture | GPU Screen Recorder for screens; FFmpeg V4L2 for cameras; PulseAudio inputs for audio |
| Health | PipeWire graph observation via pw-dump; worker exits, file/output progress and preview deadlines |
| Local integration | QLocalServer/QLocalSocket, QLockFile, desktop notifications, Hyprland monitor/layer queries |
| Storage | MKV video, PCM WAV/RF64 audio, JSON settings/session manifest, OTIO JSON timeline |
| Distribution | Arch package recipes, release workflow and optional user-scoped Omarchy widget |

Sources: [E2–E7]. There is no database or hosted backend in the reviewed implementation.

## Key Features and Claims Versus Evidence

### Independent sources without a second recording capture

Camera recording and its 640-pixel preview share one FFmpeg input. Supported MJPEG/H.264 camera streams can be copied; other supported modes encode H.264. Screen recording uses a tee muxer: the MKV file is primary, while the MPEG-TS preview branch has FIFO packet dropping and on-failure ignore behavior. This is a meaningful separation of durable capture from a slow viewer, not a claim that eight high-resolution sources will fit any GPU/USB/disk budget. [E3, E4]

### Alignment metadata, not genlock

The implementation maps device/first-frame timestamps into a common monotonic frame of reference and writes per-source offsets and OTIO track gaps. It warns on clock changes and missing timing. Camera DSP, microphone processing and USB latency are not calibrated away; use a clap or other synchronization cue for critical work. OTIO support depends on the editor. The timeline writes **absolute local file URLs**, so moving a take to another machine requires relinking; the manifest also embeds settings, device identifiers and output paths. [E2, E3]

### Recovery preserves evidence, not missing footage

Screens recover independently into numbered segments, with three retries per screen, a replacement first-frame deadline, interruption timecodes and timeline gaps. Other sources can continue during a screen retry; exhausted retries or camera/audio failure stop the take. The recorder requires 512 MiB free to begin and stops below 256 MiB. These are fixed thresholds, not capacity planning for high-rate MJPEG. [E3, E6]

Progress and PipeWire health cannot detect a producer that continues writing duplicate frames while reporting a healthy graph. ffprobe validation checks expected stream type and positive duration; it is not a full decode test or a visual-freshness guarantee. The documentation explicitly acknowledges these limitations. [E2, E3, E6]

## Architecture

1. The GUI process owns the backend, a user-only local socket and a single-instance lock. CLI invocations send JSON commands; commands other than idle status/stop can start the resident when needed. [E5]
2. Backend discovers cameras with V4L2 ioctls, audio with pactl and displays with hyprctl. It normalizes source lists and coordinates previews, selection and settings. Sources sanitizes IDs/names and reserves output stems to prevent collisions with audio, manifests and reconnection segments. [E7, E8]
3. SessionRecorder starts screen sources, serializes portal selection, then starts remaining sources after screen readiness. Workers are QProcess children with argument lists rather than shell interpolation; parent-death signals ask capture workers to finalize. [E3, E4]
4. Stop transitions through coordinated shutdown and sequential ffprobe validation. Valid partial files are renamed; manifests are atomically replaced with QSaveFile. Recovery scans the latest eligible incomplete take, rejects non-basename media paths and avoids a manifest whose owner PID is still alive. [E3]
5. The widget subscribes to bounded JPEG/meter events. Slow preview clients are skipped instead of building an unbounded outgoing queue; Model.js caps and validates data and escapes dynamic rich-text boundaries. [E5, E9]

The small codebase has clear capture/feed/session boundaries and useful fault-injection tests. Some functions are dense, and synchronous discovery/stop waits inside the UI backend deserve responsiveness testing on slow or failing devices. [E4, E7]

## Auth, Permissions, Privacy and Egress

- **Local-user trust boundary, not per-client authorization.** QLocalServer uses UserAccessOption and the runtime directory socket; no web service, CORS or account system is involved. Another process running as that user can issue recording/configuration commands or subscribe to previews. Do not treat the socket as an isolation boundary between mutually untrusted desktop apps. [E5]
- **Capture permissions vary.** Portal-based screen/window selection requests approval and can restore a prior selection using temporary per-session tokens. Direct-monitor capture can run without a portal prompt. Camera/audio access follows the desktop user's OS/device/session permissions; there is no separate app-level consent dialog for every local command. [E2, E4, E7, E10]
- **Preview is real access.** Opening a visible app or preview subscriber may activate enabled camera/audio feeds before Record is pressed. Closing the last idle viewer releases them; closing a window during recording leaves recording active. Defaults include microphone capture unless disabled, while desktop audio is opt-in. [E3, E7]
- **No telemetry/upload path found in the inspected runtime.** This supports the README's local-only claim, but is not a packet-capture proof. Runtime Qt network linkage also serves local IPC, not evidence of internet transmission. Install/release tooling contacts package repositories, GitHub and potentially the AUR; those are separate from normal recording. [E1, E5, E11]
- **Storage is sensitive.** No application encryption, secure erasure or explicit restrictive permissions on all take outputs were found. File access depends on the output directory and process umask. Recordings may include passwords, other people's voices and desktop notifications; session metadata and absolute timeline URLs can reveal filesystem/device information. Use a private output directory and review metadata before sharing. Runtime stderr is appended to an app log; no rotation was found in that startup path. [E3, E5]
- Portal token diagnostics containing lowercase “token” are filtered from retained screen logs, and tokens live in a QTemporaryDir rather than session metadata. This is good minimization, not a comprehensive secret-redaction engine or protection against same-user compromise. [E3, E7, E10]

## Persistence, Recovery, Export and Deletion

Settings live in the documented user configuration directory; recordings default to the user's Videos/Sourceroll folder. Earlier Source Record/Multitake settings are imported only when the new file is absent; source-list migration is persisted on subsequent changes. Back up finalized take directories, settings and any wanted plugin backups. There is no remote backup or transactional snapshot of an active recording. [E1, E2, E7]

Outputs are ordinary MKV/WAV files, JSON and OTIO; they do not require an account or proprietary export service. Recovery validates existing files and rebuilds metadata when possible, but cannot reconstruct missing media or unknown timing. It handles one eligible take per call rather than acting as a general archive repair utility. Keep the output directory trusted: basename checks are useful, but are not a hardened importer for attacker-controlled manifests/symlinks. [E3]

Removal of the package/widget deliberately leaves recordings, settings and migration backups. Source removal changes the source configuration, not historical media. Deletion and retention are the operator's responsibility; no integrated retention schedule or secure-delete mechanism was found. [E2, E12]

### Specific implementation concerns

1. **Multi-option updates can partially commit (static finding).** Backend::handle iterates source-set and configure options, saving each individually. A valid name/fps option can persist even if another option fails and the response reports ok=false. The transactional helper is called with one option at a time on this path; source-add correctly batches its options. Read settings back after failures, and batch-validation/one-commit semantics would be a useful upstream fix. The existing regression test covers rejected additions and individual save failures, not this multi-option rollback case. [E7: lines 705–726; E13]
2. **“Complete” does not guarantee an OTIO file (static finding).** SessionRecorder::complete does not set an error when opening/writing/committing timeline.otio fails; the session can still become complete if media validation succeeded. Missing timing can also yield no timeline. Check the manifest's timeline field and actual file before handing off a take; surface timeline-write failures explicitly. [E3: lines 661–680]
3. **Atomic files are not universally transactional settings.** commitSettings uses QSaveFile, but legacy/global setSetting mutates in-memory settings before saveSettings reports failure. Source-list update paths are better: they prepare and persist a proposed copy before activating it. Do not generalize the documented atomic-write behavior into “every failed operation leaves all runtime state unchanged.” [E7: lines 437–477]

These are code-path findings, not executed reproductions or demonstrated remote vulnerabilities.

## Maturity, Licensing, Supply Chain and Tests

At retrieval the public repository had 3 stars, 1 fork and 0 open issues/PRs, was created 2026-11-24 and last pushed 2026-11-25. The all-issues response contained five closed PRs. This is a roughly one-day public history, not evidence of long field reliability. v0.6.0 resolves exactly to the reviewed SHA and was published 2026-11-25T19:58:07Z with an x86_64 Arch package asset; the package was not downloaded or inspected. [E14–E16]

The actual LICENSE, plugin license and package manifests say **MIT** and credit Brandon plus David Heinemeier Hansson for adapted Omarchy theme/translation adapters. PR #5 proposed GPL-3.0-or-later but was closed **unmerged**; that proposal does not change this revision's license. Preserve notices when reusing code and separately assess Qt, FFmpeg, GPU Screen Recorder and other distribution obligations. No code was extracted in this review. [E17, E18]

The Release workflow builds/tests/packages in an Arch container on pull requests and published releases. GitHub reports the release run for the exact reviewed SHA successful. This is independently observed **CI metadata**, not an independently repeated test run; AUR publishing can be skipped when its secret is absent, so overall success alone does not prove AUR availability. [E11, E19]

Tests include multi-source orchestration, fake capture workers, interrupted-take recovery, permission failures, retry limits, naming/migration, late timestamps, real QML interactions, widget parsing and installer behavior. Upstream verification notes report 45 local Qt cases with one hardware skip and a clean-container run with 44 passed/two skipped. Those are upstream reports, not this review's measurements. The notes also leave two-real-camera recording/USB limits, dual-picker ordering/restoration and live display-change recovery unverified in the relevant checks. [E13, E20]

Supply-chain caveats: rolling Arch dependencies/container and major-tag actions are not fully immutable; Release Drafter is SHA-pinned. The checked-in AUR recipe has sha256sums=SKIP as a **template**; bin/aur-package generates a tarball checksum and bin/aur-publish compares it before publishing. Do not mistake the template for a pinned final recipe. No artifact signature/attestation verification was performed, and no dependency vulnerability scan was run. [E11]

## Comparison

| Aspect | Source Roll | OBS Studio | Direct FFmpeg / GPU Screen Recorder tooling |
|---|---|---|---|
| Best fit | Separate sources for editing on Omarchy | Scenes, compositing and streaming | A tightly controlled custom capture pipeline |
| Audio | One microphone plus desktop, separate WAV files | Documented advanced recording supports up to six audio tracks | Depends on explicitly constructed inputs/outputs |
| Independent video files | Built-in per-source model and timing manifest | Do not equate multiple audio tracks with separate per-source video outputs | Must coordinate processes/files/timestamps yourself |
| Recovery / handoff | Segment recovery and OTIO, with caveats above | Different workflow; not benchmarked here | Own the supervision, recovery and editor handoff |
| Operational cost | Young, integrated, platform-specific | Broader workflow; more setup than this narrow task needs | Maximum control, maximum integration responsibility |

OBS's own [multi-track recording guide](https://obsproject.com/kb/advanced-recording-guide-and-multi-track-audio) confirms the audio-track distinction. The direct-tool comparison is based on the actual command construction in Source Roll, not a separate audit of those dependencies. A standalone GPU Screen Recorder documentation fetch was unavailable during review; no feature or performance parity is claimed. Prefer existing OBS workflows for live production; trial Source Roll when independently editable files are the main requirement.

## Self-Hosting Notes

This is a desktop installation, not a server to expose. It needs a working Arch/Omarchy desktop session, Qt 6, FFmpeg/ffprobe, pactl, GPU Screen Recorder, PipeWire and the relevant screen-sharing portal. The optional widget installer writes user Omarchy configuration, preserves backups/placement and restarts the shell. Package installation requires system-level authority; normal capture runs as the user. The plugin's local.sourceroll ID is explicitly a local plugin, not proof of marketplace publication. [E1, E2, E12]

Before using irreplaceable footage, test the intended source combination on disposable material: permission prompts/restoration, multi-camera USB load, long-take storage, interruptions, stop/quit/recovery, and OTIO import after moving the folder. Inspect both video freshness and audible synchronization; a successful ffprobe check alone is insufficient. These are recommendations, not tests performed here.

## Evidence and Verification Ledger

All source links below pin the reviewed commit unless identified as live public metadata. Retrieved 2026-11-25 UTC.

- **E1:** [README](https://github.com/TechHutTV/sourceroll/blob/1392f794e11585e605e5fa96b76ff9ded1f4fc91/README.md).
- **E2:** [Recording guide](https://github.com/TechHutTV/sourceroll/blob/1392f794e11585e605e5fa96b76ff9ded1f4fc91/docs/recording.md).
- **E3:** [Session lifecycle, arguments, validation, timeline and recovery](https://github.com/TechHutTV/sourceroll/blob/1392f794e11585e605e5fa96b76ff9ded1f4fc91/src/session.cpp).
- **E4:** [Camera input/preview implementation](https://github.com/TechHutTV/sourceroll/blob/1392f794e11585e605e5fa96b76ff9ded1f4fc91/src/camerafeed.cpp).
- **E5:** [CLI, resident startup and socket](https://github.com/TechHutTV/sourceroll/blob/1392f794e11585e605e5fa96b76ff9ded1f4fc91/src/main.cpp).
- **E6:** [PipeWire health tracking](https://github.com/TechHutTV/sourceroll/blob/1392f794e11585e605e5fa96b76ff9ded1f4fc91/src/capturehealth.cpp).
- **E7:** [Backend, settings and command handlers](https://github.com/TechHutTV/sourceroll/blob/1392f794e11585e605e5fa96b76ff9ded1f4fc91/src/backend.cpp).
- **E8:** [Source normalization and filenames](https://github.com/TechHutTV/sourceroll/blob/1392f794e11585e605e5fa96b76ff9ded1f4fc91/src/sources.cpp).
- **E9:** [Widget model validation](https://github.com/TechHutTV/sourceroll/blob/1392f794e11585e605e5fa96b76ff9ded1f4fc91/plugin/Model.js).
- **E10:** [Screen preview/portal tokens](https://github.com/TechHutTV/sourceroll/blob/1392f794e11585e605e5fa96b76ff9ded1f4fc91/src/screenfeed.cpp).
- **E11:** [Release workflow](https://github.com/TechHutTV/sourceroll/blob/1392f794e11585e605e5fa96b76ff9ded1f4fc91/.github/workflows/release.yml), [draft workflow](https://github.com/TechHutTV/sourceroll/blob/1392f794e11585e605e5fa96b76ff9ded1f4fc91/.github/workflows/draft-release.yml), [AUR template](https://github.com/TechHutTV/sourceroll/blob/1392f794e11585e605e5fa96b76ff9ded1f4fc91/aur/PKGBUILD), [checksum generation](https://github.com/TechHutTV/sourceroll/blob/1392f794e11585e605e5fa96b76ff9ded1f4fc91/bin/aur-package), [publishing checks](https://github.com/TechHutTV/sourceroll/blob/1392f794e11585e605e5fa96b76ff9ded1f4fc91/bin/aur-publish).
- **E12:** [Widget installer](https://github.com/TechHutTV/sourceroll/blob/1392f794e11585e605e5fa96b76ff9ded1f4fc91/bin/install-plugin).
- **E13:** [Qt test suite](https://github.com/TechHutTV/sourceroll/blob/1392f794e11585e605e5fa96b76ff9ded1f4fc91/tests/sourceroll_tests.cpp), [test entry point](https://github.com/TechHutTV/sourceroll/blob/1392f794e11585e605e5fa96b76ff9ded1f4fc91/bin/test).
- **E14:** [Public repository metadata](https://api.github.com/repos/TechHutTV/sourceroll).
- **E15:** [Release v0.6.0](https://github.com/TechHutTV/sourceroll/releases/tag/v0.6.0), [tag target](https://api.github.com/repos/TechHutTV/sourceroll/git/ref/tags/v0.6.0).
- **E16:** [Public issue/PR inventory](https://api.github.com/repos/TechHutTV/sourceroll/issues?state=all&per_page=20).
- **E17:** [LICENSE](https://github.com/TechHutTV/sourceroll/blob/1392f794e11585e605e5fa96b76ff9ded1f4fc91/LICENSE), [plugin license](https://github.com/TechHutTV/sourceroll/blob/1392f794e11585e605e5fa96b76ff9ded1f4fc91/plugin/LICENSE).
- **E18:** [Closed, unmerged license proposal #5](https://github.com/TechHutTV/sourceroll/pull/5).
- **E19:** [Successful release CI at reviewed SHA](https://github.com/TechHutTV/sourceroll/actions/runs/45690358880).
- **E20:** [Upstream verification notes and remaining gaps](https://github.com/TechHutTV/sourceroll/blob/1392f794e11585e605e5fa96b76ff9ded1f4fc91/docs/verification.md).

**Review checks performed:** canonical URL/.git normalization and existing-review/index search (no prior matching review); anonymous source and metadata retrieval; exact tag/SHA match; static implementation/test/workflow inspection; generated-artifact markup, trusted-template CSS/JS, link/provenance and task-only diff checks. **Not performed:** compilation, tests, source scripts, device access, recording, install/uninstall, account creation, package downloads, live exploit probes, network-traffic measurement, full dependency audit or hardware/editor compatibility validation.

---

**Attribution:** TechHutTV/sourceroll, Brandon; MIT. Theme and translation adapters credit David Heinemeier Hansson. Independent public-source analysis; no upstream code extracted.
