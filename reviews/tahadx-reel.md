# Reel (tahadx/reel)

**Repo:** https://github.com/tahadx/reel

**Author:** Taha Sadough (tahadx)

**License:** MIT; preserve copyright and permission notices when reusing substantial code. External programs have their own licenses.

**Reviewed:** 2026-11-10 (UTC)

**Revision:** da2174b6a4a53133d82fa04b03d8ef4a1e9bd961; main checkout, manifest/crate version 0.4.0. Scope: repository documentation, QML/JS, Rust engine, installer, workflows and test sources.

**Verification:** Static review only. No source or shipped binary executed; no builds, tests, recording, installation, desktop changes or device access. Upstream CI success is separately reported below.

**Stack:** Rust, Qt Quick/QML, Quickshell, Hyprland/Omarchy, gpu-screen-recorder, FFmpeg.

**What it is:** A native Omarchy bar-plugin screen recorder with local take history and click-driven post-processing—not a social-media generator or hosted video service.

---

## Verdict

⚠️ **Interesting: a strong Omarchy-specific recording workflow with retention and recovery caveats.** The capture/save state machine, editable camera projects and focused tests are substantive. Do not rely on its “trash” action for either complete privacy cleanup or guaranteed recovery: this revision leaves telemetry/project sidecars behind and permanently deletes the video if desktop trash fails. Evaluate on non-sensitive footage before adopting it for routine screen capture.

## What It Is

Reel wraps gpu-screen-recorder in an Omarchy Quattro shell widget, with a Rust CLI usable independently. It selects a monitor, region or a window's visible rectangle; supports pause/resume, audio, webcam overlay, manual zoom and local history. Window capture is explicitly not isolated application capture: overlap and movement can expose other windows. Desktop audio and cursor capture default on; microphone, webcam and auto zoom default off. [README](https://github.com/tahadx/reel/blob/da2174b6a4a53133d82fa04b03d8ef4a1e9bd961/README.md), [manifest](https://github.com/tahadx/reel/blob/da2174b6a4a53133d82fa04b03d8ef4a1e9bd961/manifest.json).

Automatic zoom is local deterministic processing, not AI: pointer clicks become camera blocks; low-resolution frame differences help retarget quiet clicks toward changing content. No LLM provider, account, API key, model download or paid inference is involved. Compute, disk capacity and encoding time are the operating costs; performance was not measured. [activity.rs](https://github.com/tahadx/reel/blob/da2174b6a4a53133d82fa04b03d8ef4a1e9bd961/crates/reel/src/activity.rs), [project.rs](https://github.com/tahadx/reel/blob/da2174b6a4a53133d82fa04b03d8ef4a1e9bd961/crates/reel/src/project.rs).

## Stack

| Layer | Implementation |
|---|---|
| Desktop UI | Panel.qml, Countdown.qml, Model.js; Qt Quick and Quickshell |
| Background integration | Service.qml watches state and polls recovery/update status |
| Engine | One Rust crate; anyhow, clap, libc, serde, serde_json; Cargo.lock committed |
| Capture/control | gpu-screen-recorder process and local Unix control socket; Hyprland selection/zoom |
| Processing | FFmpeg/ffprobe; camera render uses libx264 and AAC |
| Storage | Ordinary MP4/MKV videos, JSON state/projects, JSONL pointer telemetry; no database |
| Integrations | mpv playback/webcam; optional Omacut trimming, wl-clipboard, LocalSend via Omarchy |

## Key Features and Architecture

1. **Separated UI and engine.** QML launches argument-array CLI commands. The service watches state, refreshes history and polls every three seconds while busy to notice dead workers. Rust separates recording, targeting, telemetry, camera planning, rendering, finalization and quarantine recovery. This is real implementation, not a UI-only demo. [Service.qml](https://github.com/tahadx/reel/blob/da2174b6a4a53133d82fa04b03d8ef4a1e9bd961/Service.qml), [main.rs](https://github.com/tahadx/reel/blob/da2174b6a4a53133d82fa04b03d8ef4a1e9bd961/crates/reel/src/main.rs).
2. **Two recording stages.** A raw capture is hidden from ordinary history until the save pass trims/normalizes/processes it. New recordings are gated while saving. State reconciliation detects exited recorder/finalizer PIDs; a durable quarantine ledger preserves problematic captures rather than presenting unfinished footage as completed. This is useful recovery design, not a guarantee against power loss or corrupted media. [recorder.rs](https://github.com/tahadx/reel/blob/da2174b6a4a53133d82fa04b03d8ef4a1e9bd961/crates/reel/src/recorder.rs), [finalize.rs](https://github.com/tahadx/reel/blob/da2174b6a4a53133d82fa04b03d8ef4a1e9bd961/crates/reel/src/finalize.rs), [state.rs](https://github.com/tahadx/reel/blob/da2174b6a4a53133d82fa04b03d8ef4a1e9bd961/crates/reel/src/state.rs), [quarantine.rs](https://github.com/tahadx/reel/blob/da2174b6a4a53133d82fa04b03d8ef4a1e9bd961/crates/reel/src/quarantine.rs).
3. **Editable camera projects.** Takes with telemetry get a hidden project JSON and raw JSONL, even when auto zoom is disabled. Keyframes are normalized/clamped and rendered through FFmpeg; dense paths use generated sendcmd scripts. Re-rendering normally writes a separate rendered video. The original recorded cursor remains baked into the pixels; this is not a fully separated cursor/video editing system. [project.rs](https://github.com/tahadx/reel/blob/da2174b6a4a53133d82fa04b03d8ef4a1e9bd961/crates/reel/src/project.rs), [render.rs](https://github.com/tahadx/reel/blob/da2174b6a4a53133d82fa04b03d8ef4a1e9bd961/crates/reel/src/render.rs).
4. **Practical history.** Thumbnails can be rebuilt; files can open in mpv or Omacut, be renamed with companion data, copied by path, dragged out or shared. Rename validates names and recording-folder containment; companion moves are best-effort, not a transactional archive operation. [commands.rs](https://github.com/tahadx/reel/blob/da2174b6a4a53133d82fa04b03d8ef4a1e9bd961/crates/reel/src/commands.rs#L475-L733), [Panel.qml](https://github.com/tahadx/reel/blob/da2174b6a4a53133d82fa04b03d8ef4a1e9bd961/Panel.qml).

## Security, Permissions and Privacy

### Desktop authority, not a sandbox

This runs as the logged-in desktop user, launching tools from PATH and controlling the compositor, capture, audio and camera. There is no web server, multi-user authentication layer or CORS surface in the inspected design. Local state and a Unix recorder socket replace HTTP APIs. Treat the plugin, native binary and all helper executables as trusted desktop code—not as an untrusted-document viewer.

Pointer telemetry opens Linux input devices and filters for pointer capabilities; persisted events contain timed coordinates/buttons and capture metadata, not a general typed-text log. The recommended membership in the input group nonetheless grants broader raw-input access to processes running as that user, not a narrow Reel-only permission. Avoid granting that capability casually. A denied input device degrades telemetry/auto zoom rather than blocking ordinary recording. [telemetry.rs](https://github.com/tahadx/reel/blob/da2174b6a4a53133d82fa04b03d8ef4a1e9bd961/crates/reel/src/telemetry.rs#L600-L737), [event schema](https://github.com/tahadx/reel/blob/da2174b6a4a53133d82fa04b03d8ef4a1e9bd961/crates/reel/src/telemetry.rs#L1145-L1210).

Capture rectangles, previews, window labels, audio and screen pixels can reveal sensitive material. Runtime, thumbnail and sidecar directories are set owner-only, and persisted telemetry is chmod 0600, but several permission-setting errors are ignored. These are best-effort local protections, not encryption; normal videos are not shown to have the same enforced mode. [paths.rs](https://github.com/tahadx/reel/blob/da2174b6a4a53133d82fa04b03d8ef4a1e9bd961/crates/reel/src/paths.rs#L61-L132), [sidecar directory](https://github.com/tahadx/reel/blob/da2174b6a4a53133d82fa04b03d8ef4a1e9bd961/crates/reel/src/paths.rs#L221-L232), [telemetry persistence](https://github.com/tahadx/reel/blob/da2174b6a4a53133d82fa04b03d8ef4a1e9bd961/crates/reel/src/telemetry.rs#L557-L570).

### Confirmed static retention mismatch

Documentation says project and telemetry files are removed when a take is trashed. However, main dispatches Trash directly to commands::trash, which removes/trashes the video and removes three preview locations only. Neither the successful-video nor missing-video branch deletes the hidden project or telemetry. The panel delegates to that CLI and adds no sidecar cleanup. **At this revision, deleting a take through Reel can leave interaction traces and project metadata on disk.** This is established by source-path inspection, not a runtime reproduction. [docs claim](https://github.com/tahadx/reel/blob/da2174b6a4a53133d82fa04b03d8ef4a1e9bd961/docs/reference.md), [dispatch](https://github.com/tahadx/reel/blob/da2174b6a4a53133d82fa04b03d8ef4a1e9bd961/crates/reel/src/main.rs#L42-L49), [complete trash function](https://github.com/tahadx/reel/blob/da2174b6a4a53133d82fa04b03d8ef4a1e9bd961/crates/reel/src/commands.rs#L414-L471).

The same function falls back from gio trash to fs::remove_file whenever gio is absent or unsuccessful. Therefore the UI promise to move a file to trash is not a recovery guarantee. There is no fallback confirmation distinguishing permanent deletion. Recommend failing closed or explicitly asking before permanent removal, and deleting/retaining companion artifacts under one clear policy.

### Network, credentials and updates

The shell checks at startup and hourly; the engine fetches the installed git origin's HEAD with a timeout and caches results for an hour. It reads the fetched manifest without executing it during the check. This reveals routine Git connection metadata to the configured origin; it is not a video upload. Git can inherit local credential helpers/SSH context even though terminal prompting is disabled. No application credential store was found. “Only network access” should be read narrowly: user-triggered sharing delegates to LocalSend through omarchy share, and actual updating also contacts the remote. [update code](https://github.com/tahadx/reel/blob/da2174b6a4a53133d82fa04b03d8ef4a1e9bd961/crates/reel/src/commands.rs#L55-L236), [share action](https://github.com/tahadx/reel/blob/da2174b6a4a53133d82fa04b03d8ef4a1e9bd961/Panel.qml#L733-L738).

Updating executes omarchy plugin update followed by bash on the newly fetched installer; this is an explicit upstream-code trust boundary. The installer restarts the shell, and active recording/saving is refused. Release hashes and CI byte-comparison improve integrity diagnostics but do not substitute for independent signatures or trust in the upstream account. The shipped native engine is not independently rebuilt in this review.

### Project imports are trusted local inputs

Project loading validates schema version and camera geometry, but accepts absolute take paths and normalized relative paths outside the project folder. It is not a confined importer. The render CLI's original-file protection compares paths lexically; equivalent paths using symlinked parent directories are not canonicalized before the final rename. Existing rendered outputs can be replaced. Treat third-party project JSON and explicit output paths as trusted instructions to read/write local media; review paths and back up inputs. This is a static robustness concern, not a demonstrated remote exploit. [project path resolution](https://github.com/tahadx/reel/blob/da2174b6a4a53133d82fa04b03d8ef4a1e9bd961/crates/reel/src/project.rs#L917-L960), [render guards/output publication](https://github.com/tahadx/reel/blob/da2174b6a4a53133d82fa04b03d8ef4a1e9bd961/crates/reel/src/render.rs#L31-L177).

## Data Handling, Export and Recovery

Default videos live in the user's XDG Videos/Reel folder. Companion data lives in a hidden .reel directory beside takes; durable previews live in the user's .reel/previews directory. Runtime logs/state and the persistent quarantine ledger occupy separate XDG locations. There is no inspected timed-retention policy, encrypted archive, automatic backup or cloud synchronization. Uninstall intentionally preserves recordings, settings and state. Include companions when backing up editable projects, and deliberately audit them when deleting sensitive footage. [paths.rs](https://github.com/tahadx/reel/blob/da2174b6a4a53133d82fa04b03d8ef4a1e9bd961/crates/reel/src/paths.rs), [uninstaller](https://github.com/tahadx/reel/blob/da2174b6a4a53133d82fa04b03d8ef4a1e9bd961/bin/uninstall).

Export is ordinary MP4/MKV plus editable JSON, not a proprietary hosted format. Re-rendering re-encodes video to H.264 and audio to AAC; it can retry without audio after failure, so check the resulting file rather than assuming every successful render retained sound. Recovery preserves failed raw captures, but hidden/quarantined footage may still contain the countdown/overlay content intentionally withheld from history. [render.rs](https://github.com/tahadx/reel/blob/da2174b6a4a53133d82fa04b03d8ef4a1e9bd961/crates/reel/src/render.rs#L108-L177), [state.rs](https://github.com/tahadx/reel/blob/da2174b6a4a53133d82fa04b03d8ef4a1e9bd961/crates/reel/src/state.rs#L130-L225).

## Installation and Operating Fit

This is a Linux/Omarchy Quattro/Hyprland integration, not a generic cross-platform recorder. The supplied binary is Linux x86_64; other architectures require a Rust source build. Capture needs gpu-screen-recorder and FFmpeg/ffprobe, with Omarchy's picker, slurp, grim and mpv supporting the advertised workflow. Installer checks classify some advertised workflow tools as optional, so a successful install alone does not prove every feature works. GPU/driver/compositor compatibility needs a real, separate desktop trial.

The installer links the command, enables the plugin, optionally backs up/merges a marked Hyprland bindings block, and restarts the shell. Service startup also invokes configure automatically. The wrapper can prefer a sibling development native binary over the committed dist binary. Review what executable will run; do not treat enabling the plugin as a passive manifest import. [install.sh](https://github.com/tahadx/reel/blob/da2174b6a4a53133d82fa04b03d8ef4a1e9bd961/install.sh), [configure](https://github.com/tahadx/reel/blob/da2174b6a4a53133d82fa04b03d8ef4a1e9bd961/bin/configure), [wrapper](https://github.com/tahadx/reel/blob/da2174b6a4a53133d82fa04b03d8ef4a1e9bd961/bin/reel).

## Maturity, Dependencies and Verification

Public GitHub metadata retrieved 2026-11-10: created 2026-10-20, pushed 2026-11-10T13:25:10Z, 39 stars, 1 fork, 0 open issues reported. Latest published release was v0.4.0 on 2026-11-09T17:39:41Z; the reviewed main SHA is the exact scope, not an assumption that release and main are identical. This is a young, actively changing project; popularity and an empty issue count do not establish reliability. [metadata](https://api.github.com/repos/tahadx/reel), [release](https://github.com/tahadx/reel/releases/tag/v0.4.0).

There are 156 Rust #[test] annotations in the source, four QML test files, synthetic project/telemetry fixtures and installer rerun tests. CI declares formatting, cargo check/clippy/tests, ShellCheck, installer tests, QML checks, release consistency and byte-for-byte dist rebuilding. GitHub reported the build for this exact SHA completed successfully in [run 42824341122](https://github.com/tahadx/reel/actions/runs/42824341122). That is upstream CI evidence, not tests run by this reviewer. Some plugin-contract checking falls back to a minimal manifest assertion when Omarchy is unavailable; hardware capture is not thereby validated. [build workflow](https://github.com/tahadx/reel/blob/da2174b6a4a53133d82fa04b03d8ef4a1e9bd961/.github/workflows/build.yml).

Cargo.lock is committed and the Rust toolchain is pinned, but workflow actions use moving tags/branches, including the toolchain action's master branch. Native releases include checksums but explicitly no binary signature verification. The substantial runtime behavior also depends on external packages beyond Cargo's dependency graph. No dependency vulnerability audit, license audit of every transitive component or reproducible-build verification was performed. [release workflow](https://github.com/tahadx/reel/blob/da2174b6a4a53133d82fa04b03d8ef4a1e9bd961/.github/workflows/release.yml), [Cargo manifest](https://github.com/tahadx/reel/blob/da2174b6a4a53133d82fa04b03d8ef4a1e9bd961/crates/reel/Cargo.toml).

## Comparison

| Option | Better fit | Tradeoff versus Reel |
|---|---|---|
| Omarchy stock recorder | Minimal native recording with fewer moving parts | Less integrated take-history/camera-project workflow |
| OBS Studio | Scenes, sources, mixing, streaming and broader platform coverage | Larger application and setup surface; not a drop-in Omarchy bar workflow |
| gpu-screen-recorder directly | Lean capture/control with explicit scripting | You supply selection, history and post-processing orchestration |

These are architectural fit comparisons, not fresh benchmarks or equivalent-version audits. OBS is available at https://obsproject.com and Omarchy at https://omarchy.org.

## Recommended Next Steps

Before routine use: fix sidecar cleanup and the permanent-delete fallback; canonicalize/protect render destinations; then test non-sensitive captures across pause, crash, low disk space, window overlap, audio failures and updates on supported hardware. Keep input-device permissions optional and narrow where possible. The code is worth studying, especially the two-phase capture/quarantine pattern, but the privacy cleanup gap prevents an unconditional deploy recommendation.

---

**Attribution:** Taha Sadough / tahadx/reel, MIT. Review is independent analysis; no source code extracted. All source links above are pinned to the reviewed SHA except explicitly dated public metadata, release and CI links.
