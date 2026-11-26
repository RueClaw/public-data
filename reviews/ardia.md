# Ardia (ardia-browser/ardia)

**Repo:** https://github.com/ardia-browser/ardia
**License:** GPL-3.0 distributed application; Ardia-owned source Apache-2.0; component notices apply.
**Reviewed:** 2026-11-26 (UTC)
**Revision:** ceae550b7d871cac3cf78a64ead176a644708b8c; targeted desktop architecture, native boundaries, plugins/control, privacy, sync/storage, builds and CI.
**Verification:** Static source and public GitHub metadata review only. No installation, application/source execution, personal profiles, device access, provider calls or upstream tests run.
**Stack:** TypeScript/React Native macOS/Expo, Chromium C++/Objective-C++, Swift, Rust; platform-specific desktop hosts.
**What it is:** An Arc/Dia-style browser built around real Chromium, with profiles, split views, extensions, encrypted folder sync and substantial automation/plugin surfaces.

---

## Verdict

⚠️ **Interesting — credible browser engineering, not yet a blanket daily-driver or agent-safety recommendation.** Ardia is much more than an Electron skin: its native Chromium integration, explicit network inventory, plugin sandbox and recovery code deserve study. The important qualifications are equally concrete: daily telemetry has no Settings opt-out, Chromium Safe Browsing is disabled, admitted automation is owner-level, and plugin programs escape the helper sandbox by design. Pilot with a separate profile and no valuable logins before considering migration.

## What It Is

The project's public positioning is Arc's sidebar and Dia's polish on Chromium. The tree backs that up with a native macOS shell, ArdiaCore hooks into Chromium, profile-scoped browser services, bundled uBlock Origin and Chrome extension support. It is not a new rendering engine, an Electron BrowserWindow wrapper or an inherently autonomous AI browser. AI features are described as plugins, not a mandatory core model service. [README](https://github.com/ardia-browser/ardia/blob/ceae550b7d871cac3cf78a64ead176a644708b8c/README.md) and [docs/plugins.md](https://github.com/ardia-browser/ardia/blob/ceae550b7d871cac3cf78a64ead176a644708b8c/docs/plugins.md) distinguish the product and extension model.

The default public release endpoint returned **v0.2.48**, published **2026-11-22T15:58:41Z**. Its annotated tag resolves to **6b1bcbaca49e766a3be05c6e7c52d57a69c0bd0d** (tag object 886e074722ab1616f195d0d88f6e4516ef9a1c32). This review is of newer main, not a claim that every inspected feature shipped in that release. The repository metadata snapshot showed 3,122 stars, 408 forks, 1,155 open issues/PRs combined and last push 2026-11-26T20:49:18Z; none is a quality or safety score. Public anonymous HTTPS access was verified. [Release](https://github.com/ardia-browser/ardia/releases/tag/v0.2.48).

## Stack

| Layer | Tech |
|---|---|
| macOS UI | TypeScript, React Native macOS, Expo, Hermes; Swift/native shell |
| Page engine | Patched Chromium/Helium/ungoogled-chromium; ArdiaCore C++/Objective-C++ integration |
| Other desktop hosts | Dedicated Chromium/WebUI native hosts; not identical feature support |
| Shared logic | TypeScript packages plus Rust core/FFI for crypto, import and update logic |
| Persistence | Chromium profile databases plus versioned app documents; encrypted folder sync |
| Extensibility | Chrome extensions; macOS JavaScriptCore plugin helpers, sidecars and external programs |
| Build | Node >=24, pnpm 12.21.0, Turbo; macOS Xcode 26+/CocoaPods |

## Key Features

### Native browser, real compatibility work

Profiles, split panes, sidebar tabs, DevTools, sleeping background tabs and import paths are concrete modules, not just screenshots. Chromium extensions and built-in uBlock Origin offer a meaningful compatibility advantage over a WebKit-only shell. DRM streaming can switch to WebKit, so security/privacy behavior is engine-dependent. README CPU, download-size and notarization claims were not independently reproduced. [README.md](https://github.com/ardia-browser/ardia/blob/ceae550b7d871cac3cf78a64ead176a644708b8c/README.md); [packages/ardiacore/scripts/ubo.sh](https://github.com/ardia-browser/ardia/blob/ceae550b7d871cac3cf78a64ead176a644708b8c/packages/ardiacore/scripts/ubo.sh).

### Encrypted sync without an Ardia sync server

Sync writes sealed files to a user-selected folder; iCloud Drive is the default carrier, not the only one. The design uses a 24-word recovery phrase, HKDF-SHA256 derived keys, AES-256-GCM, authenticated file identity and padded records. The inspected Rust key code has distinct derivation labels, framing and zeroization. The carrier still sees file counts/timing/sizes; a stolen phrase, compromised binary or unlocked endpoint defeats this protection. Losing all devices and the recovery kit loses access; sync is not an independent backup. [docs/sync.md](https://github.com/ardia-browser/ardia/blob/ceae550b7d871cac3cf78a64ead176a644708b8c/docs/sync.md); [packages/core-rs/crates/ardia-sync-core/src/keys.rs](https://github.com/ardia-browser/ardia/blob/ceae550b7d871cac3cf78a64ead176a644708b8c/packages/core-rs/crates/ardia-sync-core/src/keys.rs).

### Stronger-than-average boundary documentation

The privacy inventory enumerates stacks, cookies, per-profile behavior, gates and off switches. Its test checks source citations and host literals, explicitly not runtime absence of traffic. Socket schemas, consent-generation checks and recovery tests make good engineering patterns; their presence must not be confused with a completed adversarial audit. [docs/privacy.md](https://github.com/ardia-browser/ardia/blob/ceae550b7d871cac3cf78a64ead176a644708b8c/docs/privacy.md); [apps/browser/src/privacyEndpoints.test.mjs](https://github.com/ardia-browser/ardia/blob/ceae550b7d871cac3cf78a64ead176a644708b8c/apps/browser/src/privacyEndpoints.test.mjs); [apps/browser/src/state/automation/controlSocket.ts](https://github.com/ardia-browser/ardia/blob/ceae550b7d871cac3cf78a64ead176a644708b8c/apps/browser/src/state/automation/controlSocket.ts).

## Architecture

### Process isolation and browser sandbox

The page engine is Chromium's multi-process architecture with custom browser/renderer hooks, rather than web pages running inside the React Native JS context. The main delegate derives from Chrome machinery and strips dangerous profile-opening switches, including remote debugging, certificate bypass, extension loading and web-security overrides. That is useful hardening, but this static review did not observe live renderer sandbox status or verify site-isolation behavior on each OS. [engine/ardiacore/src/ardia/core/ac_main_delegate.cc](https://github.com/ardia-browser/ardia/blob/ceae550b7d871cac3cf78a64ead176a644708b8c/engine/ardiacore/src/ardia/core/ac_main_delegate.cc).

The Linux launcher normally refuses to start when neither user namespaces nor a suitable setuid helper is available. It does **not** silently fall back to an unsandboxed browser; an explicitly supplied `--no-sandbox` option is honored and labeled. Flatpak has a separate launch path. The Linux smoke harness checks renderer seccomp/namespaces and forbidden sandbox switches, but was not run here. Avoid using the manual bypass or weakening system namespace policy merely to make a package start. [scripts/linux/ardia-launch](https://github.com/ardia-browser/ardia/blob/ceae550b7d871cac3cf78a64ead176a644708b8c/scripts/linux/ardia-launch); [scripts/linux/smoke.mjs](https://github.com/ardia-browser/ardia/blob/ceae550b7d871cac3cf78a64ead176a644708b8c/scripts/linux/smoke.mjs).

### Agent and extension authority

The local control socket is available while the user enables CLI control. macOS has a native program-approval doorbell, with bundled/team-signed code admitted under its rules. **Every admitted connection is currently owner-level**: the implementation literally returns owner from connectionAccess; per-plugin socket credentials are documented as not built. Linux/Windows do not have the same doorbell parity. This is powerful browser automation, not a narrowly scoped agent capability token. [docs/control-socket.md](https://github.com/ardia-browser/ardia/blob/ceae550b7d871cac3cf78a64ead176a644708b8c/docs/control-socket.md); [apps/browser/src/state/automation/controlSocket.ts](https://github.com/ardia-browser/ardia/blob/ceae550b7d871cac3cf78a64ead176a644708b8c/apps/browser/src/state/automation/controlSocket.ts).

Revocation guards check connection and consent generation across awaits, and partial apply results distinguish completed effects from unknown outcomes. However, the documented DevTools token can outlive a program's approval until control/server restart. The rollout still documents file-based token access; no claim of immediate revocation should be made. Socket password listings omit password values, but browser control can still act in authenticated pages. Silent upload/download arms, file-URL navigation and trusted-input methods materially increase the authority of an admitted automation client. Use separate accounts/profiles and explicit action approval outside the browser for consequential tasks.

Ardia plugins are separate from Chrome extensions. On macOS, main JS runs in an offline JavaScriptCore helper under a deny-default Seatbelt profile. Host-mediated net.fetch checks declared hosts, resolves/vets addresses and uses its own TLS connection. **Network-enabled sidecars are broader:** the sandbox permits outbound IP and local binding/listening, not just the broker's hostname allowlist. **Installed plugin programs are explicitly unsandboxed**, run as the user and may fully control Ardia when control is enabled. Do not extend the helper's sandbox promise to everything a plugin distributes. [packages/shell/ios/PluginCore/PluginSandbox.swift](https://github.com/ardia-browser/ardia/blob/ceae550b7d871cac3cf78a64ead176a644708b8c/packages/shell/ios/PluginCore/PluginSandbox.swift); [packages/shell/ios/PluginHostFetch.swift](https://github.com/ardia-browser/ardia/blob/ceae550b7d871cac3cf78a64ead176a644708b8c/packages/shell/ios/PluginHostFetch.swift); [docs/plugins.md](https://github.com/ardia-browser/ardia/blob/ceae550b7d871cac3cf78a64ead176a644708b8c/docs/plugins.md).

Chrome extensions remain privileged browser code under Chromium's permission model; the full uBlock Origin component is not proof that arbitrary extensions are safe. Web Store installation still involves Google infrastructure and extension-update trust. No separate AI plugin repository or provider implementation was audited, so model selection, prompt retention and prompt-injection resistance remain out of scope.

### Privacy, egress and credentials

“Google's pings are compiled out” needs qualification. The source disables many Google services and sets **safe_browsing_mode=0**, sacrificing Chromium URL-reputation protection. Google security-component downloads, Web Store/extension updates and selected search suggestions remain. Search suggestions can send typed text and, on some platforms, the selected engine's profile cookies; private-window exceptions are documented separately. WebKit fraudulent-site warnings are opt-in. [engine/patches/build/gn_defines.sh](https://github.com/ardia-browser/ardia/blob/ceae550b7d871cac3cf78a64ead176a644708b8c/engine/patches/build/gn_defines.sh); [docs/privacy.md](https://github.com/ardia-browser/ardia/blob/ceae550b7d871cac3cf78a64ead176a644708b8c/docs/privacy.md).

There is also a daily anonymous opened-today event sent by production builds regardless of the crash/usage-sharing toggle, with no Settings off switch. The code records version, platform/channel and first/daily/weekly/monthly flags, with a per-event random identifier rather than a permanent device identifier in that daily body. Optional usage/crash reporting and user-submitted reports are different paths; feedback includes install/session IDs and selected attachments. An IP address remains visible to the receiving service even when the payload lacks a persistent ID. [apps/browser/src/state/telemetry/daily.ts](https://github.com/ardia-browser/ardia/blob/ceae550b7d871cac3cf78a64ead176a644708b8c/apps/browser/src/state/telemetry/daily.ts); [apps/browser/src/state/telemetry/transport.ts](https://github.com/ardia-browser/ardia/blob/ceae550b7d871cac3cf78a64ead176a644708b8c/apps/browser/src/state/telemetry/transport.ts); [docs/privacy.md](https://github.com/ardia-browser/ardia/blob/ceae550b7d871cac3cf78a64ead176a644708b8c/docs/privacy.md).

Optional Live Folders contact GitHub, Bitbucket, Notion, Google Drive or a chosen Confluence site using granted tokens. Custom omnibox providers receive suggestion traffic after approval; plugin network requests can leave directly and bypass an HTTP proxy. Encrypted sync does not make these paths local-only. No core always-on LLM egress was established in the inspected desktop paths; installing an AI plugin adds its own provider and data-policy review.

Plugin secrets use per-plugin Keychain account namespaces and permission-gated secret methods rather than ordinary plugin settings JSON. They are still disclosed to the authorized plugin when requested. DevTools endpoint file loading checks owner/private-file properties, no-follow access, size and server identity. These are good containment mechanisms, not protection from malicious code already authorized as the user. [apps/browser/src/state/plugins/secrets.ts](https://github.com/ardia-browser/ardia/blob/ceae550b7d871cac3cf78a64ead176a644708b8c/apps/browser/src/state/plugins/secrets.ts); [apps/browser/src/state/plugins/channelData.ts](https://github.com/ardia-browser/ardia/blob/ceae550b7d871cac3cf78a64ead176a644708b8c/apps/browser/src/state/plugins/channelData.ts); [packages/shell/ios/ControlPeerCore/DevtoolsEndpoint.swift](https://github.com/ardia-browser/ardia/blob/ceae550b7d871cac3cf78a64ead176a644708b8c/packages/shell/ios/ControlPeerCore/DevtoolsEndpoint.swift).

### Persistence and recovery

Chromium retains profile browsing data; the app separately retains session/settings documents. Session parsing distinguishes absent, unreadable, malformed and newer-version data, keeps aside copies and gates writes instead of blindly treating errors as a fresh empty session. The macOS document store uses atomic replacement for saves. Tests cover migration replay, session safety and persistence timing. Atomic replacement is not a full backup or a proven power-loss recovery contract across every platform. Importing passwords and logins increases the value of that persistent state. [apps/browser/src/state/session/sessionSafety.ts](https://github.com/ardia-browser/ardia/blob/ceae550b7d871cac3cf78a64ead176a644708b8c/apps/browser/src/state/session/sessionSafety.ts); [apps/browser/src/state/session/sessionDocument.ts](https://github.com/ardia-browser/ardia/blob/ceae550b7d871cac3cf78a64ead176a644708b8c/apps/browser/src/state/session/sessionDocument.ts); [packages/shell/ios/DocumentStore.swift](https://github.com/ardia-browser/ardia/blob/ceae550b7d871cac3cf78a64ead176a644708b8c/packages/shell/ios/DocumentStore.swift).

### Update supply chain and licensing

The inspected engine build pins Chromium **158.0.8127.36** and Helium repositories to exact commits. Do not infer the built engine patch level from a newer engine release tag appearing in the repository's release feed. Prebuilt engine downloads are checked against repository-pinned SHA-256 entries; that proves agreement with the trusted manifest, not independent reproducibility. A compromised repository/manifest remains a supply-chain risk. [engine/patches/build/helium-pins.ini](https://github.com/ardia-browser/ardia/blob/ceae550b7d871cac3cf78a64ead176a644708b8c/engine/patches/build/helium-pins.ini); [packages/ardiacore/scripts/fetch-engine.sh](https://github.com/ardia-browser/ardia/blob/ceae550b7d871cac3cf78a64ead176a644708b8c/packages/ardiacore/scripts/fetch-engine.sh).

The macOS app has a Sparkle feed and public Ed25519 key, and release scripts import signing material and support notarization. Those are stronger signals than an unsigned download URL; no downloaded DMG, notarization ticket, signature chain, rollback behavior or cross-platform updater was dynamically validated. Automatic update checks also gate a remotely fetched kill-switch document. Browser engine security patch cadence is a deployment criterion, not a cosmetic feature. [apps/browser/macos/Ardia-macOS/Info.plist](https://github.com/ardia-browser/ardia/blob/ceae550b7d871cac3cf78a64ead176a644708b8c/apps/browser/macos/Ardia-macOS/Info.plist); [.github/release/signing.sh](https://github.com/ardia-browser/ardia/blob/ceae550b7d871cac3cf78a64ead176a644708b8c/.github/release/signing.sh); [docs/privacy.md](https://github.com/ardia-browser/ardia/blob/ceae550b7d871cac3cf78a64ead176a644708b8c/docs/privacy.md).

NOTICE explicitly separates GPL-3.0 distribution of the combined app/Helium engine from Apache-2.0 Ardia-owned source. Chromium, uBlock Origin, Sparkle and other assets retain their own licenses/notices; this is not an Apache-only browser distribution. NOTICE describes corresponding-source release archives, but their completeness was not audited. Retain attribution and review applicable copyleft/source obligations before redistributing a fork. [NOTICE](https://github.com/ardia-browser/ardia/blob/ceae550b7d871cac3cf78a64ead176a644708b8c/NOTICE); [LICENSE](https://github.com/ardia-browser/ardia/blob/ceae550b7d871cac3cf78a64ead176a644708b8c/LICENSE); [LICENSE.Apache-2.0](https://github.com/ardia-browser/ardia/blob/ceae550b7d871cac3cf78a64ead176a644708b8c/LICENSE.Apache-2.0).

## Tests, CI and Limitations

- Read public source, manifests, lockfile presence, native bridge/security files, sync/session code, tests and CI definitions. No source scripts or tests were executed.
- Public GitHub Actions metadata for the exact reviewed SHA reported successful **Checks**, **Conventions** and **iOS** runs at retrieval; many administrative workflows were skipped. This is workflow status, not independent reproduction or proof every platform gate ran. [Exact-SHA runs](https://github.com/ardia-browser/ardia/actions?query=head_sha%3Aceae550b7d871cac3cf78a64ead176a644708b8c).
- Checks defines typechecking, portable package/mac tests and browser tests; separate macOS, Linux, Windows, Rust and release workflows exist. Security-oriented fixtures include plugin sandbox escape cases, session recovery and Linux sandbox smoke checks. [.github/workflows/checks.yml](https://github.com/ardia-browser/ardia/blob/ceae550b7d871cac3cf78a64ead176a644708b8c/.github/workflows/checks.yml); [packages/shell/plugin-tests/PluginSandboxEscapeTests.swift](https://github.com/ardia-browser/ardia/blob/ceae550b7d871cac3cf78a64ead176a644708b8c/packages/shell/plugin-tests/PluginSandboxEscapeTests.swift).
- This is a targeted desktop review, not an exhaustive Chromium patch audit. Mobile implementations, separate plugins/CLI releases, all binaries, provider retention policies, live traffic, accessibility, resource consumption and crash recovery were not exercised. Documentation sometimes contains planned rollout stages; implementation was preferred where checked.

## Comparison

| Need | Ardia | Existing alternative |
|---|---|---|
| Arc-like open-source desktop experience | Integrated profiles/sidebar/splits on Chromium | Zen/Firefox offers a different engine and extension ecosystem; compare compatibility before migrating |
| Conservative browser maintenance baseline | Custom Chromium patch/build/release burden | Chrome/Chromium or Firefox provides a more established upstream baseline; privacy defaults differ |
| De-Googled Chromium with uBlock Origin | Adds a large native UI/automation/plugin surface | Helium is the directly relevant upstream to compare when those extra surfaces are unnecessary |
| Reproducible browser automation | Can control a real user's rich workspace | Playwright with disposable browser contexts is a better starting point for tests and isolated agent jobs, not a replacement for a personal browser UI |

These are architectural fit comparisons, not fresh audits or benchmark rankings of the alternatives. For real accounts, the ability to automate an existing session is a liability as well as a convenience.

## Self-Hosting Notes

This is a desktop browser, not a server to self-host. The documented macOS source build needs Xcode 26+, CocoaPods, Node 24 and pnpm 12, and may fetch the pinned prebuilt engine. Building Chromium itself is a substantially larger trust/resource commitment. Apple-Silicon macOS is the prominently advertised release; Linux has several packaging formats, while plugin and native-tool parity varies. Some passkey/saved-card functionality depends on the upstream signing team identity, so a fork is not automatically feature-equivalent.

Recommended pilot: use an isolated data directory, do not import valuable credentials initially, leave automation/plugins off until needed, check actual engine/sandbox state and network traffic, and exercise restore/export before migration. If zero vendor telemetry or Chromium Safe Browsing is mandatory, the inspected defaults are not a fit. No installation was performed for this review.

---

**Attribution:** ardia-browser/ardia; copyright 2026 Mantra Patel and contributors. GPL-3.0 combined distribution; Apache-2.0 Ardia source and third-party notices as described in NOTICE.
