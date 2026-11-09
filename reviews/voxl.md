# voxl (tembo/voxl)

**Repo:** https://github.com/tembo/voxl
**License:** MIT source; upstream explicitly says x264-linked binaries and bundles are GPL-distributed. Dependency and font terms remain separate.
**Reviewed:** 2026-11-09 (UTC)
**Revision:** 3eda62874b2b3f160bc0b2e1ea20c434e0de5325 (main snapshot; root application, native backends, web client, build/release/CI and benchmark tooling).
**Verification:** Static source review only; no build, application tests, desktop capture, microphone access, installs or paid services run. Public GitHub CI reports success for this exact SHA; that is upstream evidence, not a local test result.
**Stack:** Rust 2021, Tokio, Axum, x264, Opus, native desktop APIs; TypeScript, WebCodecs and OffscreenCanvas.
**What it is:** A self-hosted desktop streaming and control server for browser viewers, especially headless X11 VMs and computer-use agents. It is not a speech model or voice assistant. The Cargo package is **voxl-server**; the executable and library are **voxl** (the registry package named voxl is unrelated).

## Verdict

⚠️ **Interesting — a strong isolated-desktop streaming candidate, not a turnkey public remote-access service.** The damage-driven pipeline, browser worker and screenshot/record/wait APIs are well matched to GPU-less agent desktops. Default authentication and server-side read-only checks are real, but shared-password authority, home-directory sharing, plaintext transport and resource/retention limits require an operator-owned security boundary. Pilot in a disposable VM behind TLS and access controls before considering wider deployment.

## What It Is

Tembo's server captures an existing display and sends H.264 over a WebSocket to its embedded browser client. Input, cursor, clipboard, system audio and optional browser microphone use the same application connection; file transfers use separate HTTP requests. It does not provision a VM, isolate tenants, run an LLM or decide which computer actions are safe.

Linux targets X11/Xvfb, not native Wayland. macOS and Windows have native capture/input/audio implementations. Browser-only viewing and ordinary HTTP proxy traversal are the differentiators: no mandatory relay, TURN service or viewer installation. The price is TCP head-of-line blocking on lossy networks and CPU x264 encoding rather than GPU acceleration at this revision. [README](https://github.com/tembo/voxl/blob/3eda62874b2b3f160bc0b2e1ea20c434e0de5325/README.md), [manifest](https://github.com/tembo/voxl/blob/3eda62874b2b3f160bc0b2e1ea20c434e0de5325/Cargo.toml).

## Stack

| Layer | Implementation |
|---|---|
| Server | Tokio runtime, Axum HTTP/WebSocket, shared in-memory Hub |
| Linux capture/control | X11 SHM/XDamage/XFixes/XTest/RandR, libyuv, PulseAudio |
| macOS | ScreenCaptureKit, CGEvent, NSPasteboard; optional loopback audio device |
| Windows | DXGI Desktop Duplication, SendInput, clipboard, WASAPI |
| Media | CPU x264 H.264, Opus, PNG screenshots, in-process MP4 muxer |
| Browser | TypeScript bundled by esbuild; worker-owned WebSocket/decode; native browser APIs |
| Persistence/auth | No application database; shared password and transient runtime state |

## Key Features and Architecture

1. **Damage-driven video rather than constant screenshot polling.** Platform capture feeds conversion and x264; the shared Hub distributes frames, cursor and audio. Client acknowledgements drive queue tracking and adaptive bitrate. Paint-over frames sharpen still content. A stalled client is resynchronized after roughly four seconds; before that, a slow viewer can gate the shared capture flow. This is not independently isolated per-viewer video quality. [video.rs](https://github.com/tembo/voxl/blob/3eda62874b2b3f160bc0b2e1ea20c434e0de5325/src/video.rs), [hub.rs](https://github.com/tembo/voxl/blob/3eda62874b2b3f160bc0b2e1ea20c434e0de5325/src/hub.rs), [encoder.rs](https://github.com/tembo/voxl/blob/3eda62874b2b3f160bc0b2e1ea20c434e0de5325/src/encoder.rs).
2. **Useful agent APIs without an agent dependency.** Screenshot responses carry a sequence number; /wait supports change/idle, region, timeout and since-sequence semantics, avoiding blind sleeps and missed-change races. This detects visual changes, not semantic application readiness. Recordings reuse encoded frames rather than re-encoding, but muxing, buffering and transfer still consume resources; the README's “no extra CPU” wording is stronger than the implementation warrants. Resize ends a recording and multi-stripe recording is refused. [wait.rs](https://github.com/tembo/voxl/blob/3eda62874b2b3f160bc0b2e1ea20c434e0de5325/src/wait.rs), [record.rs](https://github.com/tembo/voxl/blob/3eda62874b2b3f160bc0b2e1ea20c434e0de5325/src/record.rs).
3. **Browser work is separated sensibly.** The worker owns transport and video decode, with OffscreenCanvas or a presentation handoff; the main thread owns layout, input, clipboard, audio and microphone controls. It checks secure-context/WebCodecs availability and reconnects a closed socket after one second. This is transport recovery, not durable session replay. [main.ts](https://github.com/tembo/voxl/blob/3eda62874b2b3f160bc0b2e1ea20c434e0de5325/web/src/client/main.ts), [worker.ts](https://github.com/tembo/voxl/blob/3eda62874b2b3f160bc0b2e1ea20c434e0de5325/web/src/worker.ts).
4. **A compact embeddable process, not a static dependency-free binary.** main.rs delegates to library run(); compile-time platform modules share interfaces. build.rs generates x264 FFI and invokes esbuild, then embeds client assets. Native codec/display dependencies remain operational and supply-chain inputs. [lib.rs](https://github.com/tembo/voxl/blob/3eda62874b2b3f160bc0b2e1ea20c434e0de5325/src/lib.rs), [build.rs](https://github.com/tembo/voxl/blob/3eda62874b2b3f160bc0b2e1ea20c434e0de5325/build.rs).

## Security, Permissions and Privacy

### Authentication and network boundary

Authentication middleware protects the desktop, WebSocket, file and agent endpoints; a small explicit asset list and /healthz are public. Credentials may come from a CLI flag, VOXL_PASSWORD, a Selkies-compatible environment variable, or a generated 128-bit random password. Basic, Bearer and URL-token authentication all grant the same authority; the optional Basic username does not constrain Bearer/token access. There is no per-user RBAC, MFA, expiring viewer token or per-session permission system in the reviewed paths. No application login rate limiter was found. [login.rs](https://github.com/tembo/voxl/blob/3eda62874b2b3f160bc0b2e1ea20c434e0de5325/src/login.rs), [lib.rs](https://github.com/tembo/voxl/blob/3eda62874b2b3f160bc0b2e1ea20c434e0de5325/src/lib.rs).

Generated passwords are intentionally printed in startup logs. Token links remain in the page URL and are propagated to worker/WebSocket/file URLs, so browser history, copied links and proxy access logs must be treated as credential stores. Use protected secret injection rather than command-line secrets, restrict logs, and prefer an authenticated front proxy for multi-user access. Changing a configured password requires restarting/reconfiguring the process; a generated one changes on restart.

Linux defaults to all interfaces on port 6901; macOS/Windows default to loopback. The server itself is plain HTTP. Host validation and browser Origin checks are real middleware, run before login, but are not network authentication: non-browser callers can omit Origin, IP hosts are permitted, and wildcard exceptions weaken browser protections. Remote browser WebCodecs also requires HTTPS. Terminate TLS at a trusted proxy and restrict direct backend reachability; disabling built-in auth is safe only when that proxy cannot be bypassed. [access.rs](https://github.com/tembo/voxl/blob/3eda62874b2b3f160bc0b2e1ea20c434e0de5325/src/access.rs), [SECURITY.md](https://github.com/tembo/voxl/blob/3eda62874b2b3f160bc0b2e1ea20c434e0de5325/SECURITY.md).

### Desktop authority is execution authority

An authenticated writable viewer can type into a terminal or privileged application already present in the desktop. There is no command allowlist, action approval or application sandbox. All viewers share the same desktop and privilege level. macOS needs Screen Recording and Accessibility permissions; Windows runs in the user's interactive session and has lock-screen/UAC restrictions. Do not elevate it to bypass those boundaries. Linux capture relies on authority to access the X display.

Read-only mode is enforced on the server: a command allowlist rejects input/clipboard writes/resize and all binary client messages; upload is disabled separately. **Read-only does not mean confidential:** screen, screenshot/recording, outbound clipboard and enabled downloads remain available. Turn off clipboard, audio and file transfers independently when those data channels are unwanted. Browser microphone is off by default server-side and requires a browser permission flow when enabled. [server.rs](https://github.com/tembo/voxl/blob/3eda62874b2b3f160bc0b2e1ea20c434e0de5325/src/server.rs), [lib.rs](https://github.com/tembo/voxl/blob/3eda62874b2b3f160bc0b2e1ea20c434e0de5325/src/lib.rs), [mic.ts](https://github.com/tembo/voxl/blob/3eda62874b2b3f160bc0b2e1ea20c434e0de5325/web/src/client/mic.ts).

### Files are a broad grant, not a vault

Uploads and downloads default on, with the user's home as files-root (falling back to filesystem root if neither home environment variable exists). The list UI hides dotfiles, but direct downloads resolve a requested relative path and directory ZIP traversal does not filter hidden files. **Hiding dotfiles is not secret protection:** a home-root share can expose configuration and credentials to an authorized downloader. Use a dedicated minimal exchange directory instead of a real user's home.

Path components reject absolute paths and parent traversal; canonicalized existing targets must remain under the configured root. Folder ZIPs omit symlinks, upload subdirectories are checked stepwise, uploads require a custom header and use create-new temporary files followed by rename. These are meaningful safeguards, but path validation and later filesystem operations are not a race-proof filesystem sandbox. Concurrent local mutation and crash/race behavior were not dynamically tested. Avoid attacker-writable shared roots and use OS isolation. [files.rs](https://github.com/tembo/voxl/blob/3eda62874b2b3f160bc0b2e1ea20c434e0de5325/src/files.rs).

### Data and cost flows

The reviewed runtime has no model provider, account service, telemetry uploader or obligatory third-party media relay. Screen/audio/clipboard/files go between the host and authenticated viewer through whatever reverse proxy or tunnel the operator chooses; a TLS-terminating intermediary can observe them. Browser-origin media permissions are separate from server authentication. Apps on the controlled desktop can make their own network calls; voxl does not restrict their egress.

Costs are CPU encoding, bandwidth, hosting and optional tunnel/proxy services—not model tokens. The 30,000-kbps default video ceiling is about 13.5 GB/hour per viewer if continuously saturated, excluding overhead/audio; actual damage-driven/adaptive traffic can be much lower. Multiple viewers still multiply delivered traffic. The optional Daytona benchmark script uses an external account/API key and may incur cloud charges; it is not a runtime requirement and was not run. [lib.rs](https://github.com/tembo/voxl/blob/3eda62874b2b3f160bc0b2e1ea20c434e0de5325/src/lib.rs), [bench README](https://github.com/tembo/voxl/blob/3eda62874b2b3f160bc0b2e1ea20c434e0de5325/bench/README.md).

## Persistence, Retention and Recovery

- **Uploaded files persist** in the selected root; there is no expiry/cleanup scheduler or resumable upload protocol. The default per-upload size limit is unlimited. Error paths attempt to remove temporary .part files, but crashes can leave them behind; no startup scavenger was identified. Unique-name selection plus rename is not a transactional multi-client conflict protocol.
- **Recordings are RAM-backed**, with a default 300-second maximum. Started/unclaimed recordings are discarded after the maximum duration plus a 60-second grace period. No global recording-count/byte budget was found. A time limit alone is not a safe aggregate memory bound. Saved downloads/recordings then have viewer-owned retention, not server-enforced deletion.
- **Session state is ephemeral.** There is no database, durable task journal, audit identity or restore system. WebSocket reconnect resets decoding; disconnect releases input state and stops that client's microphone stream. It does not undo desktop actions or recover an interrupted upload/recording after process loss.
- **Operational recovery is external.** Release builds abort on panic; the library also installs an aborting panic hook in unwind builds. A supervisor, isolated desktop lifecycle, resource quotas and backup/restore policy belong to the deployment. /healthz is a simple “ok” response, not proof that capture/input/audio are healthy. [files.rs](https://github.com/tembo/voxl/blob/3eda62874b2b3f160bc0b2e1ea20c434e0de5325/src/files.rs), [record.rs](https://github.com/tembo/voxl/blob/3eda62874b2b3f160bc0b2e1ea20c434e0de5325/src/record.rs), [server.rs](https://github.com/tembo/voxl/blob/3eda62874b2b3f160bc0b2e1ea20c434e0de5325/src/server.rs), [lib.rs](https://github.com/tembo/voxl/blob/3eda62874b2b3f160bc0b2e1ea20c434e0de5325/src/lib.rs).

## Claims, Benchmarks and Maturity

The README reports approximately 60 FPS and 12–99 ms median latency on a 16-vCPU GPU-less VM. It discloses that voxl's column uses its best run, that native clients measure draw-to-decode rather than complete browser/input-to-photon latency, that Sunshine is outside its GPU-oriented sweet spot, and that shaped links do not drop packets. These results are useful author evidence, not a universal product ranking or a reproduction by this review.

Importantly, the **reviewed HEAD itself updates the Selkies benchmark setup**. Its merged commit message reports much closer voxl/Selkies results, including faster Selkies LAN scroll in that separate run, and calls for standardized quality/legibility tests. Hardware and setup differ, so do not combine those numbers with the README table; they do show why its headline should not decide a purchase or migration. Compare text/chroma fidelity, real browser latency, loss, concurrent viewers and matched resource limits. [README](https://github.com/tembo/voxl/blob/3eda62874b2b3f160bc0b2e1ea20c434e0de5325/README.md), [benchmark methodology](https://github.com/tembo/voxl/blob/3eda62874b2b3f160bc0b2e1ea20c434e0de5325/bench/README.md), [reviewed commit discussion](https://github.com/tembo/voxl/commit/3eda62874b2b3f160bc0b2e1ea20c434e0de5325).

Public metadata checked 2026-11-09: repository created 2026-06-18, last push 2026-11-09T04:16:38Z, 1,383 stars, 76 forks, 23 open issue/PR items in GitHub's combined counter; not archived. Latest public release is [v0.3.4](https://github.com/tembo/voxl/releases/tag/v0.3.4), published 2026-11-07. These are time-sensitive activity signals, not safety evidence.

CI defines web formatting/lint/type checks, Linux formatting/clippy/tests/package verification, macOS tests, and Windows tests plus a real-desktop smoke exercise. The public [CI run for the reviewed SHA](https://github.com/tembo/voxl/actions/runs/42560916056) reports success. Unit tests cover areas including auth, origins, read-only commands, recording-length bounds and encoder logic; bench/tests contains richer Playwright transfer/resize/microphone scenarios. Most of those integration scripts are not invoked by the main CI workflow. Native OS/FFI code and manual feature tests still need platform qualification. [CI](https://github.com/tembo/voxl/blob/3eda62874b2b3f160bc0b2e1ea20c434e0de5325/.github/workflows/ci.yml), [bench](https://github.com/tembo/voxl/blob/3eda62874b2b3f160bc0b2e1ea20c434e0de5325/bench/README.md).

Cargo and npm lockfiles are committed, but CI actions mostly use movable version tags and Nix shells resolve external nixpkgs; this is not fully hermetic supply-chain pinning. No vulnerability scan or exhaustive dependency audit was performed. SECURITY.md says fixes target the latest release, so operators own upgrade cadence.

## Installation, Updates and Licensing

The documented installation builds voxl-server with Rust and native dependencies; it is not a one-file script installer. Linux needs x264/libyuv/Opus/PulseAudio, pkg-config/clang and esbuild. macOS uses Homebrew-provided libraries and OS permissions; Windows uses vcpkg/LLVM/esbuild and an interactive desktop. Nix files support a Linux build, with default.nix advertising x86_64-linux. Patched Xvfb is recommended for smooth scrolling and shared-memory capture. A capable browser needs a secure context, WebCodecs and OffscreenCanvas; the README's exact browser/version matrix was not device-tested.

build.rs executes esbuild from PATH or ESBUILD and generates FFI bindings; normal Cargo/native package build trust applies. No runtime self-updater, automatic model download or account bootstrap was found. The release workflow publishes a crate and attaches it to a GitHub release; it is not evidence of signed ready-to-run installers. Pin a reviewed version/lockfile and separately manage native libraries, rebuilds and rollback. Unknown CLI flags are silently accepted for Selkies compatibility, so validate effective behavior rather than assuming a misspelled security flag failed closed. [build](https://github.com/tembo/voxl/blob/3eda62874b2b3f160bc0b2e1ea20c434e0de5325/build.rs), [release workflow](https://github.com/tembo/voxl/blob/3eda62874b2b3f160bc0b2e1ea20c434e0de5325/.github/workflows/release.yml), [argument parsing](https://github.com/tembo/voxl/blob/3eda62874b2b3f160bc0b2e1ea20c434e0de5325/src/lib.rs).

The root LICENSE is MIT, copyright Tembo 2026, but README explicitly calls out GPL obligations for x264-linked binaries/bundles. Cargo and Nix MIT metadata alone do not describe the complete distributed artifact. The bundled Inter font has its own OFL license. Review native-library and codec-distribution obligations before redistributing; this review extracts no source code. [LICENSE](https://github.com/tembo/voxl/blob/3eda62874b2b3f160bc0b2e1ea20c434e0de5325/LICENSE), [font license](https://github.com/tembo/voxl/blob/3eda62874b2b3f160bc0b2e1ea20c434e0de5325/web/inter-LICENSE.txt).

## Comparison

| Option | Prefer it when | Tradeoff against voxl |
|---|---|---|
| [Selkies](https://github.com/selkies-project/selkies) | Building a Linux browser-desktop stack with its ecosystem | Compare current matched setups; updated source evidence narrows the headline performance gap |
| [KasmVNC](https://github.com/kasmtech/KasmVNC) / [noVNC](https://github.com/novnc/noVNC) | Existing VNC infrastructure and desktop/productivity compatibility matter | Workload, server and encoding configuration dominate; noVNC is a client, not synonymous with one slow x11vnc setup |
| [Sunshine](https://github.com/LizardByte/Sunshine) + Moonlight | GPU-backed gaming and native-client streaming | Not a fair GPU-less browser benchmark substitute; different transport/client strengths |
| [RustDesk](https://github.com/rustdesk/rustdesk) | General remote support and device rendezvous | More complete remote-access ecosystem; voxl is simpler as an embedded URL for a pre-existing sandbox |

These are fit comparisons, not fresh independent audits of the alternatives.

## Self-Hosting Notes

Start with a disposable Xvfb VM/container and dedicated low-privilege account, not a logged-in personal workstation. Explicitly bind loopback or a protected interface; use TLS and authenticated proxy access with an exact host/origin allowlist. Keep built-in authentication unless the backend is unreachable except through the authenticating proxy. Disable files/clipboard/audio/microphone unless needed; otherwise use a minimal exchange root and nonzero upload limits. Read-only is useful for observers but does not remove download or capture authority.

Add connection/request/concurrency limits and memory/disk quotas outside the process, bound recordings, protect access/startup logs, and test reconnect, shutdown, upload interruption, restore and loss-heavy networking with synthetic data. Validate permissions and input on each OS before use. For computer-use agents, put policy and approval gates in the agent harness and isolate the actual desktop: the streaming layer is not that boundary.

## Verification Limits

Anonymous public acquisition and exact Git SHA identification succeeded; existing public reviews, README and repository-tracking index had no matching canonical source. Findings come from static reading of the identified files plus unauthenticated public metadata. No benchmark, app test, native build, vulnerability exploit or real device interaction was run. Resource-exhaustion and filesystem-race concerns are design observations, not demonstrated exploits. No private data was used.

**Attribution:** Tembo and public contributors, [tembo/voxl](https://github.com/tembo/voxl); MIT source with the distribution caveats above.
