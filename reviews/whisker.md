# Whisker (whiskerrs/whisker)

**Repo:** https://github.com/whiskerrs/whisker
**License:** MIT OR Apache-2.0; component and asset notices remain applicable.
**Reviewed:** 2026-11-14 (UTC)
**Revision:** 3295be306e37fef7bb6d523310976ee41e8e5324; repository-wide architecture with targeted runtime, developer transport, generation, credentials, storage and WebView inspection.
**Verification:** Static review only; no builds, installs, tests, device access, service probes or provider calls. Public GitHub CI status checked separately.
**Stack:** Rust 2024 / MSRV 1.88; Taffy; Swift/UIKit/AppKit, Kotlin/Android, GTK4, WinUI 3, browser WASM/DOM; Axum/Tokio development tooling.
**What it is:** A pre-alpha cross-platform Rust UI framework with fine-grained reactivity, shared layout and platform-native Hosts—not an AI assistant or transcription application.

## Verdict

⚠️ **Interesting — pilot a bounded app, not a portability-critical production migration.** Whisker has a real retained runtime, native integrations and substantive cross-platform conformance machinery. Its developer-code transport, incomplete secure-storage coverage and simple desktop persistence deserve explicit acceptance tests; the project itself labels the API pre-alpha. The strongest reusable idea is the revisioned Runtime–Host boundary, not an assumption that every module works everywhere.

## What It Is

Whisker targets Rust developers who want one reactive application and layout model across mobile, desktop and browser. Components produce retained elements; signals invalidate dependent work rather than rebuilding and diffing a virtual DOM. Taffy computes boxes while each Host supplies text measurement, window/input lifecycle and presentation. Web uses DOM objects but still receives Rust-computed layout. Native does not mean every control is an unmodified platform stock widget or that font rendering is identical.

The CLI generates native projects from executable Rust configuration in whisker.rs, compiles them, installs/launches development apps and drives hot reload. Modules add input, media, routing, storage, browser views and optional Firebase services. Chat and news examples are demonstrations, not a hosted product promise. [README][readme] [Architecture][arch]

## Stack and Architecture

| Layer | Implementation and boundary |
|---|---|
| Authoring | render!, component/main macros, typed styles, signals, effects and computed values |
| Runtime | Single-threaded owner scopes, lifecycle, tasks and event routing; runtime contexts isolate reactive instances on one UI thread |
| Engine/layout | Retained scene, Taffy geometry, batched intrinsic measurement, semantic frame packets |
| Host contract | Surface/epoch/revision-aware snapshots and deltas; Host acceptance commits presentation revision |
| Native bridge | Mobile FFI Driver for Android/iOS/macOS; Rust Hosts for Linux/Web; Windows WinUI Host |
| Development | Cargo/native builds, CNG generation, watching, Axum WebSocket service and forked Subsecond hot patching |
| Persistence | Optional platform key/value stores; separate encrypted developer signing credentials; no universal app database |

Copied signal/element handles do not keep their owner alive. Pause/resume supports navigation entries without conflating suspension and disposal. Host callbacks drive runtime frames: these components cooperate inside an application, not across a security isolation boundary. [Reactive implementation][reactive]

FrameSink exposes capabilities and accepts complete frame transactions. Its recording renderer retains accepted and rejected packets against a reference projection. Snapshot recovery prevents a missed delta from silently desynchronizing the trees. This is render-state recovery, **not durable user-data recovery**. [Frame implementation][frames]

## Key Features and Claims

- **Fine-grained updates:** actual owner/signal/effect/scheduler modules and retained scenes substantiate the model.
- **Fast hot reload:** real patch compilation/dynamic loading, with unchanged components intended to retain state. The “under a second” headline is an upstream demo claim, not a measurement here; first builds, native changes and component remounts differ.
- **Generated projects:** one app configuration feeds six targets and module discovery. Generation includes plugin builds; the source explicitly says there is no configuration-only execution mode. Foreign project configuration is executable build code. [Runner][cng]
- **Native services:** routing, input, SVG/images, audio/video and Firebase wrappers exist. Package presence is not proof of target parity. Secure store explicitly declines Web/Desktop rather than silently writing secrets to JSON. [Contract][secure]

## Platform Compatibility

The tree contains iOS, Android, macOS, Linux, Windows and Web pathways. Apple requires its toolchain and matching Rust targets; Android adds SDK/NDK/JDK/Gradle; Web needs WASM tooling. Linux is a **GTK4 Host**, requesting GTK 4.14 APIs and Pango/Cairo—not an Omarchy-specific app or a universally static Linux binary. Windows uses WinUI 3/Windows App SDK and native prerequisites. [Linux manifest][linux] [CI][ci]

The November 13 release adds CLI Linux and Windows hot-reload runs, so these paths are particularly recent. Test mobile IME, accessibility, text shaping, gestures, backgrounding, resize/high-DPI and native modules on every required target. No device/UI verification was performed here. [Release][release]

## Security, Execution and Privacy

### Development transport is code execution

The native CLI generates a per-session token; the server checks the client's hello token before forwarding patches. Default server configuration binds loopback and invalid-token tests exist. However, the receiver constructs a plain ws:// URL, sends its token and dynamically loads native patches. The inspected flow provides neither TLS server authentication nor signed-patch verification. Client authentication must not be mistaken for protection against a hostile network/server. Keep the channel loopback or separately secured; it is not a public app backend. [CLI][run] [Server][server] [Receiver][receiver]

**Concrete portability weakness:** token generation reads /dev/urandom, then falls back to timestamp XOR process ID. That is not a cryptographic RNG and is normally the Windows path. Use a cross-platform OS RNG that fails closed before relying on non-loopback token secrecy. This is a static finding, not a demonstrated exploit. Web development intentionally omits the native token; native receiver frame/message size limits are disabled for large patches. Both reinforce the trusted-development boundary.

Hot-reload log capture forwards stdout/stderr to the developer host; tokens and personal content in logs do not remain only on the device. Hot-reload features are intended for development; verify the final release feature graph instead of relying on that intent.

### Application and WebView authority

Rust apps, modules, build scripts and generated projects run with process/user authority. Whisker is not a sandbox. UI capabilities are not end-user authorization; backend auth and data access rules remain app responsibilities. Optional Firebase Auth does not itself enforce Firestore/Storage rules.

WebView enables JavaScript by default, exposes a string message bridge and JavaScript-evaluation method, and defaults to broad HTTP/HTTPS navigation patterns. Android now disables file access and rejects mixed content, but generated Android application configuration still sets cleartext traffic true unless overridden. Narrow origins, require TLS, validate bridge messages, and never translate arbitrary page strings into privileged commands. Navigation callbacks can carry OAuth redirect codes: redact logs. [API][webview] [Android view][androidweb] [Generation][androidgen]

Optional Firebase Analytics/Crashlytics and remotely loaded media/browser content introduce their own egress and retention. The framework requires no model provider, model download or per-token AI bill. Firebase, app stores, signing accounts and build infrastructure can impose usage/account costs and separate terms. Adding analytics is not a privacy-neutral UI choice.

### Two distinct secret stores

Developer signing/submission credentials are age-encrypted, with public recipients intended for Git and a separately held private identity. Plaintext build inputs are staged in a temporary directory with Unix 0700/0600 permissions and normal drop cleanup. This protects data at rest, not from the current user, child build tools, process compromise or abrupt termination before cleanup. Back up the identity independently; Git-history ciphertext persists after deleting current files, and compromise requires rotation. Windows ACL equivalence and crash cleanup were not verified. [Store][credentials] [Materialization][materialize]

Application secure storage instead uses iOS generic-password Keychain items with AfterFirstUnlockThisDeviceOnly, or Android Tink AES-GCM with a Keystore-wrapped keyset. Android binds ciphertext to its key as associated data and rejects the reserved keyset key. Hardware backing depends on the device; using iOS Keychain does not establish a per-operation biometric gate or a Secure-Enclave private-key API. Web/Desktop support is explicitly absent. Re-authentication is the recovery path for lost/invalidated keys; device-only storage is intentionally nonportable. [iOS][iossecure] [Android][androidsecure]

## Persistence, Retention, Export and Recovery

Ordinary local store is preferences storage: UserDefaults on Apple, SharedPreferences on Android, localStorage on Web, and a JSON map on desktop. Save/load/remove is not transactions, migrations, sync, retention management or a general export/restore workflow. Apps must supply those policies.

Desktop storage rewrites the complete JSON file directly, without temp-file-and-rename or fsync; its mutex only coordinates one process. Memory rolls back on write failure, but a partial disk write can still corrupt JSON. Opening malformed data returns an error cached by the process-wide OnceLock. Paths are keyed by executable stem: similarly named apps can collide, while renaming an executable can appear to lose its data. Do not make this the sole store for irreplaceable records. [Desktop implementation][desktopstore]

Browser values share origin-local storage and a fixed prefix; same-origin apps are not separate tenants. Clearing/eviction and private mode matter. No automatic secret-safe fallback exists for unsupported secure-store targets. Retained UI state/hot reload does not substitute for persistence. [Web implementation][webstore]

## Build, Install, Update and Licensing

The README's unversioned cargo install follows the current registry release. Pin the CLI and compatible runtime/native SDK versions and preserve lockfiles for reproducibility. Cargo.lock and exact core 0.18.1 interdependencies help, but the toolchain file tracks stable Rust and native/package streams have independent versions. A lockfile does not audit build scripts, procedural macros, Gradle, SwiftPM, NuGet or plugins.

The latest release includes Gradle distribution SHA-256 pinning, rustc environment credential exclusion, constrained submission token exchanges, mixed-content denial and reserved secure-store key rejection. Those are positive maintenance signals and reasons not to equate older releases with this one. They do not establish independent provenance verification for every downloaded native artifact. No installation, update or submission was attempted.

MIT and Apache-2.0 texts are present with itome attribution: choose the applicable license and preserve notices. The tree also contains Lucide/Feather icon notices and WPT fixture licensing; native dependencies/Firebase SDKs retain their terms. Cargo-deny runs advisory/bans/source checks but intentionally omits its license gate, with documented advisory exceptions. This is not an audited MIT-only dependency/asset bundle. No source/assets were extracted. [Manifest][manifest] [Dependency policy][deny]

## Tests, CI and Maturity

Public metadata retrieved November 14 reports creation May 13, 2026, 681 stars, 23 forks, 41 open issues/PRs combined, and last push November 13. These measure activity, not quality. Latest release is whisker-release-20261113.1 (core 0.18.1), published November 13.

The [CI run for the reviewed SHA](https://github.com/whiskerrs/whisker/actions/runs/43414531755) reports success. The workflow specifies workspace/doc tests, formatting, MSRV/clippy/rustdoc, mobile ABI C/C++ checks, packaged-consumer linking and Host conformance across Linux, Windows, Web, Android, iOS and macOS. Four renderer-foundation crates have configured 100% line/function/region coverage gates. This is meaningful discipline, not proof of runtime safety or independent test reproduction. Actions generally use mutable tags rather than full SHA pins.

The project calls itself **pre-alpha**. API churn, recent desktop run support and a broad native surface prevent a blanket production recommendation. Open input-related upstream work also illustrates ongoing platform fixes. Performance, memory use, accessibility, store distribution, vulnerability exploitation and restore behavior were not independently verified.

## Comparison

| Option | Prefer it when | Tradeoff versus Whisker |
|---|---|---|
| [Dioxus](https://github.com/DioxusLabs/dioxus) | Rust full-stack UI and its broader tooling fit | Compare actual target renderers; Whisker emphasizes shared Taffy/native Hosts and maintains a Subsecond fork |
| [Slint](https://github.com/slint-ui/slint) | Declarative desktop/embedded UI is central | Different UI language, renderer and licensing choices; evaluate distribution terms |
| [Flutter](https://github.com/flutter/flutter) | Mature mobile plugins/tooling matter more than Rust-only UI | Dart-first and a different renderer; usually less framework ownership for a conventional mobile app |
| [Tauri](https://github.com/tauri-apps/tauri) | An existing web UI plus Rust/native integration fits | WebView app architecture rather than shared retained native Hosts |

These are architectural alternatives, not benchmark rankings. Whisker best fits a Rust-native team willing to debug adapters. Prototype input/IME, navigation/back gestures, large lists/text, accessibility, offline state, secure login and recovery on every required OS. Isolate development transport, add real durability and budget for API changes.

## Verification Scope and Limits

Inspected public README/manifests/licenses/releases, runtime/engine contracts, CNG runner, dev CLI/server/receiver, credential materialization, stores, WebView controls and CI. Anonymous repository/release/CI/issue metadata was consulted. No private data/accounts were used. This is selective analysis, not an exhaustive security audit; source/tests were not executed. Publication markup validation is not proof of a running app.

**Attribution:** whiskerrs/whisker and itome/contributors; MIT OR Apache-2.0, with third-party notices as described.

[readme]: https://github.com/whiskerrs/whisker/blob/3295be306e37fef7bb6d523310976ee41e8e5324/README.md
[arch]: https://github.com/whiskerrs/whisker/blob/3295be306e37fef7bb6d523310976ee41e8e5324/docs/architecture.md
[reactive]: https://github.com/whiskerrs/whisker/blob/3295be306e37fef7bb6d523310976ee41e8e5324/crates/whisker-runtime/src/reactive/mod.rs
[frames]: https://github.com/whiskerrs/whisker/blob/3295be306e37fef7bb6d523310976ee41e8e5324/crates/whisker-engine/src/recording.rs
[cng]: https://github.com/whiskerrs/whisker/blob/3295be306e37fef7bb6d523310976ee41e8e5324/crates/whisker-cng/src/runner.rs
[secure]: https://github.com/whiskerrs/whisker/blob/3295be306e37fef7bb6d523310976ee41e8e5324/packages/whisker-secure-store/src/lib.rs
[linux]: https://github.com/whiskerrs/whisker/blob/3295be306e37fef7bb6d523310976ee41e8e5324/platforms/linux/Cargo.toml
[ci]: https://github.com/whiskerrs/whisker/blob/3295be306e37fef7bb6d523310976ee41e8e5324/.github/workflows/ci.yml
[release]: https://github.com/whiskerrs/whisker/blob/3295be306e37fef7bb6d523310976ee41e8e5324/releases/20261113.1.md
[run]: https://github.com/whiskerrs/whisker/blob/3295be306e37fef7bb6d523310976ee41e8e5324/crates/whisker-cli/src/run.rs
[server]: https://github.com/whiskerrs/whisker/blob/3295be306e37fef7bb6d523310976ee41e8e5324/crates/whisker-dev-server/src/server.rs
[receiver]: https://github.com/whiskerrs/whisker/blob/3295be306e37fef7bb6d523310976ee41e8e5324/crates/whisker-dev-runtime/src/hot_reload.rs
[webview]: https://github.com/whiskerrs/whisker/blob/3295be306e37fef7bb6d523310976ee41e8e5324/packages/whisker-webview/src/lib.rs
[androidweb]: https://github.com/whiskerrs/whisker/blob/3295be306e37fef7bb6d523310976ee41e8e5324/packages/whisker-webview/android/src/main/kotlin/rs/whisker/elements/webview/WhiskerWebView.kt
[androidgen]: https://github.com/whiskerrs/whisker/blob/3295be306e37fef7bb6d523310976ee41e8e5324/crates/whisker-cng/src/android/application.rs
[credentials]: https://github.com/whiskerrs/whisker/blob/3295be306e37fef7bb6d523310976ee41e8e5324/crates/whisker-credentials/src/store.rs
[materialize]: https://github.com/whiskerrs/whisker/blob/3295be306e37fef7bb6d523310976ee41e8e5324/crates/whisker-credentials/src/materialize.rs
[iossecure]: https://github.com/whiskerrs/whisker/blob/3295be306e37fef7bb6d523310976ee41e8e5324/packages/whisker-secure-store/ios/Sources/WhiskerSecureStore/SecureStore.swift
[androidsecure]: https://github.com/whiskerrs/whisker/blob/3295be306e37fef7bb6d523310976ee41e8e5324/packages/whisker-secure-store/android/src/main/kotlin/rs/whisker/modules/securestore/SecureStore.kt
[desktopstore]: https://github.com/whiskerrs/whisker/blob/3295be306e37fef7bb6d523310976ee41e8e5324/packages/whisker-local-store/desktop/src/lib.rs
[webstore]: https://github.com/whiskerrs/whisker/blob/3295be306e37fef7bb6d523310976ee41e8e5324/packages/whisker-local-store/web/src/lib.rs
[manifest]: https://github.com/whiskerrs/whisker/blob/3295be306e37fef7bb6d523310976ee41e8e5324/Cargo.toml
[deny]: https://github.com/whiskerrs/whisker/blob/3295be306e37fef7bb6d523310976ee41e8e5324/deny.toml
