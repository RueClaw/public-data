# Hex (anomalyco/hex)

**Repo:** https://github.com/anomalyco/hex
**License:** MIT; copyright 2026 Christopher Langton. Preserve copyright and permission notices. Models and dependencies have separate terms.
**Reviewed:** 2026-11-27 (UTC)
**Revision:** 27366ae5d3d9b7deaaea02f4bf5887b5a31d2681, default dev branch. Scope: desktop Rust app, local API, output processing, persistence, model/update paths and CI. Mobile, site and capture subcrates received structural inspection only.
**Verification:** Static source inspection and anonymous public metadata only. No installation, source execution, tests, model downloads, accounts or live application probes.
**Stack:** Rust 2024, Rune/wgpu native UI, cpal, transcribe.cpp/ggml, QuickJS, TypeScript SDK.
**What it is:** Desktop push-to-talk dictation with local speech inference and insertion into the focused application, plus optional transformations and recording features.

---

## Verdict

⚠️ **Interesting — credible local dictation, but local is a configuration boundary, not a blanket privacy guarantee.** Loopback authentication, model integrity checks, signed updates and careful persistence are substantive strengths. Pilot core dictation on the actual OS/compositor first; optional OpenCode processing and scripts widen the data and execution boundaries.

## What It Is

This is Anomaly's voice-dictation Hex, not Hex.tech analytics, the Erlang/Elixir Hex package manager, a hex editor or a coding-agent orchestrator. The canonical repository is anomalyco/hex; the requested .git suffix normalizes to that identity. No existing matching review or public index entry was found.

The normal journey is shortcut → microphone → local inference → optional output steps → clipboard/paste or platform text insertion. The README describes multilingual models, vocabulary, seven-day searchable history, per-app/site transformations, screen annotation and an authenticated local API. Meetings remain a macOS lab: desktop feature parity is not universal. [E1]

Anonymous metadata reported 8,920 stars, 617 forks, 375 open issues (GitHub aggregate), and a last push of 2026-11-27T19:49:28Z. These are activity signals, not safety evidence. Latest stable release returned: v3.5.2, published 2026-11-27T05:01:54Z, tag SHA 7ae9c033e251cd197f07d8503b7cc647912ef13a. The reviewed dev SHA is newer, not the released binary. iOS prereleases coexist with desktop releases. [E2]

## Stack

| Layer | Tech |
|-------|------|
| Desktop/CLI | Rust, clap, Rune/rune-kit/wgpu, native platform APIs |
| Capture/inference | cpal; transcribe.cpp/ggml; platform GPU backends; Symphonia decoding |
| Output | Rust cleanup, QuickJS custom transforms, optional running OpenCode 2 |
| Persistence | JSON settings/history, optional recordings, atomic writes; no database server |
| Integration | Loopback HTTP bearer API, CLI, TypeScript SDK, stdio MCP |
| Network | ureq, native TLS/system roots and proxies |

Cargo.lock and pinned Rune/transcribe.cpp Git revisions improve source repeatability but couple maintenance to modified upstream forks and native toolchains. This is not an Electron/Tauri web shell. [E3]

## Key Features

### Local inference with checked artifacts

Model installation validates size/checksum and verifies partial downloads before promotion. This is stronger than blindly loading weights, but trusts the application's catalog rather than independently proving model quality. Custom models are another trust decision. README accuracy rankings such as “fewest wrong words” were not independently benchmarked. [E4]

### Programmable output and explicit trust costs

Vocabulary, replacements and per-app profiles go beyond a transcription CLI. Optional OpenCode rewrites discover an already-running service through a registration naming a loopback address/password; Hex does not launch its executable in that path. The local service can still call a remote provider, so text egress depends on configuration. [E5]

Custom-config approval is pinned to a hash of loaded files. The prompt lists literal hosts/programs and marks incomplete lists, but this is explanatory scanning, not a destination allowlist. Scripts can use HTTP(S) fetch and subprocess APIs. Subprocesses receive a minimal environment rather than every inherited variable, yet execute with the user's permissions: **not a sandbox**. Approved code can still access user files or send text away. [E6]

### A local automation API, not a multi-user server

The listener binds 127.0.0.1 on an ephemeral port, generates a 32-random-byte bearer token and authenticates before dispatch. Discovery is atomically written with Unix mode 0600; Windows relies on inherited per-user directory ACLs. Header/path/body bounds, deadlines and per-dictation owner tokens are useful controls. Inspected responses do not grant browser CORS access; CORS is not a replacement for authorization. Same-user processes able to read the discovery file remain inside the trust boundary. Do not expose this API publicly. [E7]

## Architecture

The main entry point selects CLI/app behavior; platform modules own shortcuts, audio and paste; dictation, parakeet and transcription modules handle capture/inference and ordered output. Rune renders the interface; local_api serves integrations; capture/router crates extend into screen annotation. The product is substantially larger than a minimal dictation utility. [E3, E7]

### Permissions, network and privacy

Microphone capture, global shortcuts and text insertion need sensitive platform integration. macOS capture additionally checks screen-recording/accessibility permissions. Linux paste differs between X11, wlroots protocols and desktop portals. Validate focus, secure fields and clipboard restoration with disposable text. [E8]

The README's “after that nothing leaves your machine” should not be applied to every feature: model/update downloads use the network; custom fetch calls and optional provider-backed rewrites can send content outside it. No packet capture or whole-tree telemetry audit was performed. No account is described as necessary for core local dictation; API tokens/service passwords are capabilities, not cloud identity. Keep discovery, recordings, histories and diagnostics private. SECURITY.md explicitly warns against posting transcripts/logs in public issues. [E1, E4–E7, E10]

macOS managed preferences can disable meetings, annotation, OpenCode, transforms and labs. A loopback-only transform policy checks destinations after DNS and on redirects, and disallows subprocesses. The implementation explicitly says other OSes have no managed locks. Do not assume enterprise policy parity. [E9]

### Persistence and recovery

History uses bounded JSON: 10,000 entries and 16 MiB aggregate text, with seven-day default retention. Optional recordings follow entry retention and separate caps; text-free usage counts can outlive that retention. **Turning retention Off preserves existing entries**, so explicit clearing is required. JSON storage is not an application-encrypted vault; owner permissions do not protect against same-user code, administrators or backups. [E11]

The durable writer stages uniquely, syncs the file, renames, then syncs the directory on Unix. Settings reread/merge changed fields under a process-wide lock, preserve unknown keys, refuse destructive saves from failed reads and retain invalid-field backups. That is careful recovery engineering, not a guarantee against arbitrary external writers, storage failures or forensic recovery after deletion. Recovery documentation explicitly separates synthetic checks from native end-to-end proof. [E12]

### Updates and supply chain

Platform update validation includes macOS bundle identity/signature, Windows Authenticode signer and Linux Ed25519 signature binding the executable hash to a pinned release key. Package-managed Linux installations do not self-replace. Model integrity is checked separately. These are static positive findings; released binaries, signing chains and rollback behavior were not exercised. [E4, E10]

## Maturity and Verification

Tests live alongside implementation, with UI/accessibility fixtures and native integration scripts. Linux CI defines locked nextest runs, fmt/clippy, X11 grabs, Wayland paste, virtual-microphone inference/paste, signed-installer tamper rejection and service lifecycle checks. Inspected actions are commit-pinned and checkout disables persisted credentials. Definitions are not proof of passing runs. [E13]

At the reviewed SHA, anonymous checks showed macOS arm64 success, several Linux/Windows desktop/build jobs in progress and check-linux/check-macos/check-windows skipped. This was **not an all-platform green result**. No tests ran for this review. Linux docs explicitly mark live-typing behavior as not verified on a real compositor. Accuracy, latency, sustained memory, assistive technology and device recovery remain unverified. [E2, E8]

The README says pull requests are not accepted and issues are generally handled by the project's agents: a governance constraint, not proof of quality or failure. Root lints allow categories including undocumented unsafe blocks and unwrap usage; Rust plus native FFI does not imply end-to-end memory safety. No dependency vulnerability scan or full transitive license audit was performed. [E1, E3]

## Comparison

Fit comparisons, not measured benchmarks or recommendations to buy services:

| Aspect | Hex | Alternative |
|--------|-----|-------------|
| Local desktop dictation | Integrated history, output profiles and API | [Handy](https://github.com/cjpais/Handy): relevant open-source local-dictation peer |
| Embedded inference | Broad desktop lifecycle/permissions | [whisper.cpp](https://github.com/ggml-org/whisper.cpp): lower-level engine when building your own UX |
| Managed polished output | Optional provider configuration | [Wispr Flow](https://wisprflow.ai/): commercial workflow alternative, different privacy/cost boundary |
| Minimal deployment | App, models and native integrations | Built-in OS dictation: less setup, but offline/language behavior depends on OS |

Prefer Hex when local inference and programmable output matter, after validating the actual shortcut/paste path. Prefer an inference engine for embedding without desktop control, or a simpler dictation tool when extension governance is unwanted.

## Self-Hosting Notes

This is a per-user desktop installation, not an internet-facing web service. Initial models need network/storage; latency depends on model/hardware. Linux docs require AVX2 for official x86_64 builds and a Vulkan driver for the UI even with CPU inference. Linux remains described as beta; meetings are macOS-only. [E1, E8]

For a privacy-focused pilot, choose stable, keep optional rewrites/scripts/capture labs off initially, explicitly clear existing history if required, and test the complete microphone-to-correct-target path. Verify supported release/model integrity rather than copying unreviewed installation pipelines. No installation commands were executed.

## License and Reuse

MIT applies to Hex source, not all weights/dependencies. Notices include CC BY 4.0 models, CC BY-SA 4.0 Orukeet weights, an Apache-2.0-derived cleanup model and ISC/MIT icon assets. Verify exact selected-model terms and preserve applicable attribution/ShareAlike obligations. No implementation or model weights were extracted. [E14]

## Evidence

- **E1:** [README.md](https://github.com/anomalyco/hex/blob/27366ae5d3d9b7deaaea02f4bf5887b5a31d2681/README.md).
- **E3:** [Cargo.toml](https://github.com/anomalyco/hex/blob/27366ae5d3d9b7deaaea02f4bf5887b5a31d2681/Cargo.toml), [Cargo.lock](https://github.com/anomalyco/hex/blob/27366ae5d3d9b7deaaea02f4bf5887b5a31d2681/Cargo.lock), [src/main.rs](https://github.com/anomalyco/hex/blob/27366ae5d3d9b7deaaea02f4bf5887b5a31d2681/src/main.rs).
- **E4:** [src/transcription/models.rs](https://github.com/anomalyco/hex/blob/27366ae5d3d9b7deaaea02f4bf5887b5a31d2681/src/transcription/models.rs), [src/transcription/definitions.rs](https://github.com/anomalyco/hex/blob/27366ae5d3d9b7deaaea02f4bf5887b5a31d2681/src/transcription/definitions.rs).
- **E5:** [src/dictation/processor.rs](https://github.com/anomalyco/hex/blob/27366ae5d3d9b7deaaea02f4bf5887b5a31d2681/src/dictation/processor.rs), [src/desktop/opencode_service.rs](https://github.com/anomalyco/hex/blob/27366ae5d3d9b7deaaea02f4bf5887b5a31d2681/src/desktop/opencode_service.rs).
- **E6:** [SECURITY.md](https://github.com/anomalyco/hex/blob/27366ae5d3d9b7deaaea02f4bf5887b5a31d2681/SECURITY.md), [src/personal_commands/trust.rs](https://github.com/anomalyco/hex/blob/27366ae5d3d9b7deaaea02f4bf5887b5a31d2681/src/personal_commands/trust.rs), [src/personal_commands/process.rs](https://github.com/anomalyco/hex/blob/27366ae5d3d9b7deaaea02f4bf5887b5a31d2681/src/personal_commands/process.rs), [src/personal_commands/fetch.rs](https://github.com/anomalyco/hex/blob/27366ae5d3d9b7deaaea02f4bf5887b5a31d2681/src/personal_commands/fetch.rs).
- **E7:** [src/local_api.rs](https://github.com/anomalyco/hex/blob/27366ae5d3d9b7deaaea02f4bf5887b5a31d2681/src/local_api.rs), [src/local_api/discovery.rs](https://github.com/anomalyco/hex/blob/27366ae5d3d9b7deaaea02f4bf5887b5a31d2681/src/local_api/discovery.rs), [src/local_api/http.rs](https://github.com/anomalyco/hex/blob/27366ae5d3d9b7deaaea02f4bf5887b5a31d2681/src/local_api/http.rs).
- **E8:** [docs/linux.md](https://github.com/anomalyco/hex/blob/27366ae5d3d9b7deaaea02f4bf5887b5a31d2681/docs/linux.md), [docs/features/capture.md](https://github.com/anomalyco/hex/blob/27366ae5d3d9b7deaaea02f4bf5887b5a31d2681/docs/features/capture.md), [docs/features/dictation.md](https://github.com/anomalyco/hex/blob/27366ae5d3d9b7deaaea02f4bf5887b5a31d2681/docs/features/dictation.md).
- **E9:** [src/policy.rs](https://github.com/anomalyco/hex/blob/27366ae5d3d9b7deaaea02f4bf5887b5a31d2681/src/policy.rs), [src/net.rs](https://github.com/anomalyco/hex/blob/27366ae5d3d9b7deaaea02f4bf5887b5a31d2681/src/net.rs).
- **E10:** [src/updater/linux.rs](https://github.com/anomalyco/hex/blob/27366ae5d3d9b7deaaea02f4bf5887b5a31d2681/src/updater/linux.rs), [src/updater/macos.rs](https://github.com/anomalyco/hex/blob/27366ae5d3d9b7deaaea02f4bf5887b5a31d2681/src/updater/macos.rs), [src/updater/windows.rs](https://github.com/anomalyco/hex/blob/27366ae5d3d9b7deaaea02f4bf5887b5a31d2681/src/updater/windows.rs).
- **E11:** [src/history.rs](https://github.com/anomalyco/hex/blob/27366ae5d3d9b7deaaea02f4bf5887b5a31d2681/src/history.rs), [src/history/recordings.rs](https://github.com/anomalyco/hex/blob/27366ae5d3d9b7deaaea02f4bf5887b5a31d2681/src/history/recordings.rs).
- **E12:** [src/durable.rs](https://github.com/anomalyco/hex/blob/27366ae5d3d9b7deaaea02f4bf5887b5a31d2681/src/durable.rs), [src/app_settings/persistence.rs](https://github.com/anomalyco/hex/blob/27366ae5d3d9b7deaaea02f4bf5887b5a31d2681/src/app_settings/persistence.rs), [src/app_settings/persistence/tests.rs](https://github.com/anomalyco/hex/blob/27366ae5d3d9b7deaaea02f4bf5887b5a31d2681/src/app_settings/persistence/tests.rs), [docs/features/recovery.md](https://github.com/anomalyco/hex/blob/27366ae5d3d9b7deaaea02f4bf5887b5a31d2681/docs/features/recovery.md).
- **E13:** [.github/workflows/check-linux.yml](https://github.com/anomalyco/hex/blob/27366ae5d3d9b7deaaea02f4bf5887b5a31d2681/.github/workflows/check-linux.yml), [.github/workflows/check-macos.yml](https://github.com/anomalyco/hex/blob/27366ae5d3d9b7deaaea02f4bf5887b5a31d2681/.github/workflows/check-macos.yml), [.github/workflows/check-windows.yml](https://github.com/anomalyco/hex/blob/27366ae5d3d9b7deaaea02f4bf5887b5a31d2681/.github/workflows/check-windows.yml).
- **E14:** [LICENSE](https://github.com/anomalyco/hex/blob/27366ae5d3d9b7deaaea02f4bf5887b5a31d2681/LICENSE), [THIRD_PARTY_NOTICES.md](https://github.com/anomalyco/hex/blob/27366ae5d3d9b7deaaea02f4bf5887b5a31d2681/THIRD_PARTY_NOTICES.md).
- **E2:** Anonymous [metadata](https://api.github.com/repos/anomalyco/hex), [releases](https://api.github.com/repos/anomalyco/hex/releases?per_page=5), [v3.5.2](https://github.com/anomalyco/hex/releases/tag/v3.5.2) and [commit checks](https://api.github.com/repos/anomalyco/hex/commits/27366ae5d3d9b7deaaea02f4bf5887b5a31d2681/check-runs). Mutable endpoints; values above are dated observations.

---

**Attribution:** anomalyco/hex; MIT copyright Christopher Langton (2026). Analysis uses the pinned public revision.
