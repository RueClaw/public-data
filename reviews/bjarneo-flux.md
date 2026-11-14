# Flux (bjarneo/flux)

**Repo:** https://github.com/bjarneo/flux

**Author:** Bjarne Oeverli (bjarneo)

**License:** MIT; retain copyright and permission notices when redistributing substantial code. Dependencies and platform services have separate terms.

**Reviewed:** 2026-11-14 (UTC)

**Revision:** f6ed4ac00d84aa06dc948df9efc69ca4beda589c, master; repository-wide static review with emphasis on Linux daemon, trust, transfers, policies, packaging and native-client manifests. Commit dated 2026-11-09; GitHub last-push metadata 2026-11-11.

**Verification:** Static source and public metadata inspection only. No builds, tests, installs, pairing, device access, live protocol probes or dependency audit were run.

**Stack:** Go 1.27.1, Qt 6/QML/C++, Kotlin/Compose, Swift/SwiftUI/SwiftNIO, C#/.NET/WPF.

**What it is:** An Omarchy-centered phone/desktop integration suite for sharing files and clipboard, notifications, media, camera/audio streams and optional remote control—not FluxCD, an image model, or a display-color utility.

---

## Verdict

⚠️ **Interesting: strong Omarchy integration, but pair it as a high-trust desktop companion.** The implementation is substantially more than a file-sharing demo: certificate-bound pairing, private local IPC, rooted read-only file browsing and persistent transfer snapshots are thoughtful. However, default home/clipboard/agent visibility, optional shell/PAM authority, an empty release-signing trust key and uneven platform maturity make a deliberately restricted pilot more appropriate than blanket deployment.

## What It Is

Flux centers on a Linux user daemon, `fluxd`, with a CLI, native Qt application and Omarchy shell host. Android is the primary supported phone client; iOS and macOS share FluxKit, and Windows is a newer companion port. Those companions connect to the Linux daemon rather than replacing it with a general cross-platform desktop server. Its own protocol is version 8; do not assume KDE Connect interoperability.

The standout is the breadth of a single integration: files, clipboard text/images, SMS via Android, notification forwarding, media control, phone webcam/microphone/speaker, screen mirroring, desktop streaming and input, agent terminal visibility, optional phone-backed SSH signing and biometric approval. Availability is not identical across clients. The architecture supports outbound desktop connections and reverse tunnels, so the documented default Omarchy firewall can remain unchanged; this does not mean the daemon binds only to loopback.

## Stack

| Layer | Tech |
|---|---|
| Desktop authority | Go daemon; TOML config; private JSON/file state |
| Local clients | Go CLI, C++ Qt host, shared Qt Quick QML, Omarchy shell plugin |
| Network | mDNS/Avahi discovery, UDP identity, TLS peer links, payload/reverse tunnels, SSH/SFTP browsing |
| Android | Kotlin Compose, coroutines/serialization, SSHJ/Bouncy Castle, CameraX, ML Kit, Android Keystore |
| Apple | SwiftUI, shared FluxKit; SwiftNIO/TLS, Swift Certificates/Crypto, Citadel 0.12.0; Package.resolved present |
| Windows | .NET 10/WPF companion; Windows 10 2004+ |
| Desktop integrations | wl-clipboard, D-Bus, PipeWire, optional ffmpeg/v4l2loopback, mpv, wtype and screen recorders |

## Key Features

### Integrated sharing with real persistence

The offline outbox snapshots selected files into private data files, hashes them and records jobs before sending. Later edits to the source do not silently change queued content. It caps the queue at 100 files, archives folders, and reconstructs waiting transfers on startup. Resumable transfer messages carry a transfer ID, SHA-256, size and offset; chunks are 1 MiB and acknowledgments are checked. This is much stronger than retrying an ephemeral open file handle, but it costs additional disk space and is not a disk quota or an independently proven exactly-once delivery guarantee. [E5]

Pinned clipboard snippets persist separately, with a 100-entry limit and optional expiration. Plain files and folders remain useful outside Flux; no proprietary cloud account is required. Saved snippets, queued payloads, received photos and identity material are nevertheless sensitive retained data, not merely ephemeral traffic. [E5, E6]

### Pairing is a real trust ceremony

Users compare all 16 hexadecimal characters derived from both public keys and a pairing timestamp. Outgoing pairing requires local confirmation after peer acceptance. TLS uses self-signed peer certificates and explicit application pin checks, not public CA hostname validation: the presence of InsecureSkipVerify in the TLS helper is therefore not by itself evidence of an authentication bypass. The provider compares pinned certificate bytes, and handlers reject noncurrent or unpaired feature traffic. Limits constrain unpaired links, line sizes, discovery and pairing requests. These are inspected controls, not a penetration-test result. [E1, E2]

### Fine-grained restrictions exist, despite stale documentation

Global switches combine with per-device restrictions; omitted device restrictions allow the feature, and a restriction cannot turn on a globally disabled feature. Policy changes cancel browse sessions and affected streams. The configuration guide still says there is no setting for one device, but its workflow link, security guide and actual policies.go implementation establish otherwise. Use the implementation and workflow guide rather than that stale sentence. [E3]

## Architecture

CLI / Qt / shell host → private Unix socket → fluxd core → paired TLS links and tunnels → native companions. Core modules own device state, pairing, command dispatch, feature policy and integration lifecycles; desktop modules invoke OS services. The same QML views use separate host adapters. Native clients share protocol semantics, but not one universal implementation: Android, Apple and Windows have different permission/lifecycle constraints and separate maintenance burdens. [E1]

The local socket is mode 0600 inside a validated private runtime directory; peer credentials are checked. This protects against other Unix users, not a malicious process already running as the desktop user. Such a process is inside the local control boundary. Network listeners bind all interfaces, on TCP 12100–12108 and UDP 12100; payloads use 12070–12099. Firewall policy still matters on non-Omarchy systems and tailnets. Discovery is not authentication. [E2]

## Security, Privacy and Execution Boundaries

- **Broad visibility by default:** auto clipboard, home browsing and herdr agent visibility default on. Hiding dotfiles and Flux internals is useful but does not make visible documents, exported secrets or terminal output nonsensitive. Clipboard sync can copy credentials. Pair only devices trusted with those materials and disable unnecessary global/device features. [E3]
- **Browse PC is constrained, not arbitrary SFTP:** rooted filesystem access, actual opened-file path checks, hidden-component filtering and read-only handlers protect the exported roots. This is meaningful defensive work; it does not make exporting the home directory least-privilege. [E4]
- **Execution is explicit but powerful:** remote input, remote desktop, herdr control and ordinary terminal control default off. Enabling agent control can still execute arbitrary user commands even when ordinary-terminal control stays off. Desktop commands are locally configured; automation runs a configured command through sh -c with inherited environment, event values in environment variables, cooldown and timeout. It is not a sandbox. Treat event values as untrusted in any configured shell script. [E3, E7]
- **Biometric UI is not daemon-enforced authorization:** the documentation correctly distinguishes a client unlock prompt from a server feature gate. A modified paired client need not honor its own UI. Optional PAM approval is a separate boundary: the root helper verifies a signed nonce-bound request against root-owned enrollment material, with requester/service checks and a bounded wait; daemon approval alone is insufficient. Keep password recovery available and test this separately before enabling it. [E7]
- **Phone permissions are substantial:** Android declares camera, microphone, notification access/service paths, SMS, contacts/call-log, media, package visibility and update-install capabilities. Declarations are not proof every permission is granted. Feature permission and sharing controls matter; Android backup is disabled. Phone SSH keys use Android Keystore and require an interactive signature authorization path. [E8]
- **Local-first is not zero egress:** the daemon checks GitHub releases daily by default; GitHub receives IP and version User-Agent. Tailscale is optional external infrastructure, not built-in Flux identity. Android bundles text-recognition/barcode components but also depends on the Play-services document scanner; dictation can use the phone speech-recognition service. Do not assume every optional feature is offline. No hosted LLM provider, API-key billing flow or required model subscription was found in the inspected core; herdr integration exposes an external agent's output/control, not an inference service. SMS/carrier, optional network service and Apple distribution costs remain separate. [E6, E8]

## Persistence, Export and Recovery

Configuration and device trust are ordinary TOML/JSON; the desktop identity includes a filesystem private key. Private file modes reduce cross-user exposure but are not encryption at rest. Trust writes use an atomic-write helper; malformed trust JSON is moved aside with a broken-file suffix instead of overwritten, after which devices must be paired again. The outbox snapshots and snippets are separate from configuration, so backing up config alone is insufficient. [E5, E6]

The shared state writer flushes the temporary file and renames it; it does not fsync the containing directory. That distinction matters for claims of power-loss durability. Invalid outbox records return an error rather than being silently skipped. No single comprehensive backup/export/restore contract was established in this review: preserve config, identity, trust, queued data and wanted received content deliberately, and test recovery. Restoring identity/trust also restores authority. Unpairing is revocation, not deletion of files already delivered to another device. [E5]

## Platform Compatibility and Accessibility

Linux packaging targets Arch/Omarchy and Wayland-specific tools, not an arbitrary Linux desktop with identical capabilities. Android requires 10+, iOS 17+, macOS 14+. iOS background execution, clipboard and other-app access are OS-limited; Apple builds and sideloading require their signing/toolchain path. The iOS guide documents seven-day renewal with a free Apple ID versus longer paid-team provisioning—not a required Flux subscription. Windows is explicitly described upstream as new, with CI-rendered views not yet checked on a physical Windows computer. [E9]

QML controls include accessible roles/names for toggles, buttons and the composer, and Android declares RTL support. Those are positive source signals, not proof of screen-reader navigation, focus order, magnification, touch-target quality or reduced-motion coverage. None was device-tested here. Platform feature parity and accessibility remain acceptance-test items. [E9]

## Build, Install, Update and Uninstall Risks

The Go module is small but the full distribution is not: Qt, Android/Gradle, Apple/Xcode/Swift packages, Windows/.NET, OS multimedia utilities and optional kernel modules widen the build and runtime trust surface. Manifest pins, go.sum, Package.resolved and SHA-pinned CI actions help reproducibility; they do not replace a vulnerability audit. The Arch recipe requires Go 1.27.1 and runs Go tests during package checking. [E10]

System installation can reload udev, configure/load v4l2loopback when not already configured and restart older running user daemons. User setup enables persistent background service. Optional approval setup modifies PAM; this is a login-security change, not a cosmetic integration. Uninstall paths disable approval and remove owned system integration, but preserve user config/identity and root enrollment key files. Removal is not data erasure; user-only and system-prefix removal differ. [E10]

**Important supply-chain limitation:** release download code verifies hashes and supports Ed25519-signed SHA256SUMS, but internal/release/sign.go sets PublicKey to the empty string at this revision. Signature verification is therefore inactive for this source build; HTTPS plus an adjacent checksum file is not an independent publisher-signature guarantee. The release workflow explicitly permits the unsigned case while the key is empty. Do not repeat the docs' signed-checksum capability as an enabled assurance. Android APK signing, ad hoc macOS signing and Windows Authenticode are different boundaries; Windows docs explicitly report no Authenticode signature. [E11]

## Maturity and Verification

Public GitHub metadata on 2026-11-14 reported 652 stars, 60 forks and 42 open issues/PRs combined, with repository creation on 2026-09-25. Latest stable release metadata reported v0.19.1 on 2026-10-29; this review covers the later exact master SHA, not a binary equivalence claim. Sampled open issues request additional approval UX and Bluetooth/ADB transports; requests are not implemented-feature evidence. Popularity is not security assurance. [E12]

The tree has substantial Go regression tests for pairing, trust, policies, file browsing, outbox, IPC, approval and release handling, plus protocol fuzz targets and native-client tests. CI defines Go vet/race tests and multi-platform builds, with pinned actions and a digest-pinned Arch build image. Pull requests intentionally run no build to save minutes. We inspected definitions, not current green-run results, measured coverage or released-binary provenance. No upstream test or benchmark result is claimed as independently reproduced. [E10]

## Comparison

| Option | Prefer it when | Tradeoff against Flux |
|---|---|---|
| [KDE Connect](https://kdeconnect.kde.org/) / [GSConnect](https://github.com/GSConnect/gnome-shell-extension-gsconnect) | You want the established general desktop/phone integration ecosystem | Less specific to Omarchy's shell and herdr/PAM workflow; compare actual platform features |
| [LocalSend](https://localsend.org/) | You mainly need cross-platform local file sharing | Much narrower purpose; avoids adopting a whole remote desktop/agent integration stack |
| [scrcpy](https://github.com/Genymobile/scrcpy) | You need Android screen mirroring/control through ADB | Different transport and trust model; not notification, home-browse and cross-platform companion parity |
| Flux | You value one Omarchy-native workflow across sharing, streams and optional phone-backed control | Broad paired-device authority and young multi-client maintenance surface |

Related public reviews: [wayshare](wayshare.md) covers a different remote-desktop design; [phoneuse](phoneuse.md) covers an iPhone control bridge. Neither substitutes for Flux's full companion model.

## Self-Hosting Notes

There is no separate hosted SaaS server to deploy for basic LAN use. Start with one trusted Android device and narrowly selected sharing features, keep remote input/desktop/agent control and PAM approval off, and review home/clipboard visibility before pairing. Keep all clients current for the 16-character ceremony. Preserve firewall restrictions rather than exposing the daemon directly to the Internet. Validate reconnects, sleep/wake, interrupted transfers, revocation, permissions and uninstall recovery on a disposable or noncritical setup before expanding scope.

Adoption gates: qualify the exact client/desktop pair; verify a trusted release provenance path; test offline queue recovery and disk growth; audit visible documents/clipboard/agent output; exercise permission denial and revocation; and separately validate accessibility and any PAM fallback. For file transfer alone, choose the smaller tool.

## Evidence and Attribution

All code/doc links below are pinned to the reviewed revision. Claims above distinguish inspected implementation from upstream documentation and untested behavior.

- **E1:** [README.md](https://github.com/bjarneo/flux/blob/f6ed4ac00d84aa06dc948df9efc69ca4beda589c/README.md), [docs/architecture.md](https://github.com/bjarneo/flux/blob/f6ed4ac00d84aa06dc948df9efc69ca4beda589c/docs/architecture.md), [internal/core/pairing.go](https://github.com/bjarneo/flux/blob/f6ed4ac00d84aa06dc948df9efc69ca4beda589c/internal/core/pairing.go).
- **E2:** [internal/lan/tls.go](https://github.com/bjarneo/flux/blob/f6ed4ac00d84aa06dc948df9efc69ca4beda589c/internal/lan/tls.go), [internal/lan/provider.go](https://github.com/bjarneo/flux/blob/f6ed4ac00d84aa06dc948df9efc69ca4beda589c/internal/lan/provider.go), [internal/core/handlers.go](https://github.com/bjarneo/flux/blob/f6ed4ac00d84aa06dc948df9efc69ca4beda589c/internal/core/handlers.go), [internal/ipc/ipc.go](https://github.com/bjarneo/flux/blob/f6ed4ac00d84aa06dc948df9efc69ca4beda589c/internal/ipc/ipc.go), [internal/ipc/peer.go](https://github.com/bjarneo/flux/blob/f6ed4ac00d84aa06dc948df9efc69ca4beda589c/internal/ipc/peer.go).
- **E3:** [internal/core/policies.go](https://github.com/bjarneo/flux/blob/f6ed4ac00d84aa06dc948df9efc69ca4beda589c/internal/core/policies.go), [internal/config/config.go](https://github.com/bjarneo/flux/blob/f6ed4ac00d84aa06dc948df9efc69ca4beda589c/internal/config/config.go), [docs/security.md](https://github.com/bjarneo/flux/blob/f6ed4ac00d84aa06dc948df9efc69ca4beda589c/docs/security.md), [docs/configuration.md](https://github.com/bjarneo/flux/blob/f6ed4ac00d84aa06dc948df9efc69ca4beda589c/docs/configuration.md), [docs/workflows.md](https://github.com/bjarneo/flux/blob/f6ed4ac00d84aa06dc948df9efc69ca4beda589c/docs/workflows.md).
- **E4:** [internal/core/sftp.go](https://github.com/bjarneo/flux/blob/f6ed4ac00d84aa06dc948df9efc69ca4beda589c/internal/core/sftp.go), [internal/core/sftp_test.go](https://github.com/bjarneo/flux/blob/f6ed4ac00d84aa06dc948df9efc69ca4beda589c/internal/core/sftp_test.go).
- **E5:** [internal/core/outbox.go](https://github.com/bjarneo/flux/blob/f6ed4ac00d84aa06dc948df9efc69ca4beda589c/internal/core/outbox.go), [internal/core/resume.go](https://github.com/bjarneo/flux/blob/f6ed4ac00d84aa06dc948df9efc69ca4beda589c/internal/core/resume.go), [internal/core/storage.go](https://github.com/bjarneo/flux/blob/f6ed4ac00d84aa06dc948df9efc69ca4beda589c/internal/core/storage.go), [internal/core/snippets.go](https://github.com/bjarneo/flux/blob/f6ed4ac00d84aa06dc948df9efc69ca4beda589c/internal/core/snippets.go), [internal/config/trust.go](https://github.com/bjarneo/flux/blob/f6ed4ac00d84aa06dc948df9efc69ca4beda589c/internal/config/trust.go).
- **E6:** [docs/configuration.md](https://github.com/bjarneo/flux/blob/f6ed4ac00d84aa06dc948df9efc69ca4beda589c/docs/configuration.md), [internal/proto/cert.go](https://github.com/bjarneo/flux/blob/f6ed4ac00d84aa06dc948df9efc69ca4beda589c/internal/proto/cert.go).
- **E7:** [internal/core/automation.go](https://github.com/bjarneo/flux/blob/f6ed4ac00d84aa06dc948df9efc69ca4beda589c/internal/core/automation.go), [internal/core/herdr_control.go](https://github.com/bjarneo/flux/blob/f6ed4ac00d84aa06dc948df9efc69ca4beda589c/internal/core/herdr_control.go), [internal/approve/helper.go](https://github.com/bjarneo/flux/blob/f6ed4ac00d84aa06dc948df9efc69ca4beda589c/internal/approve/helper.go), [internal/approve/message.go](https://github.com/bjarneo/flux/blob/f6ed4ac00d84aa06dc948df9efc69ca4beda589c/internal/approve/message.go), [docs/approve.md](https://github.com/bjarneo/flux/blob/f6ed4ac00d84aa06dc948df9efc69ca4beda589c/docs/approve.md).
- **E8:** [android/app/src/main/AndroidManifest.xml](https://github.com/bjarneo/flux/blob/f6ed4ac00d84aa06dc948df9efc69ca4beda589c/android/app/src/main/AndroidManifest.xml), [android/app/build.gradle.kts](https://github.com/bjarneo/flux/blob/f6ed4ac00d84aa06dc948df9efc69ca4beda589c/android/app/build.gradle.kts), [android/app/src/main/java/org/omarchy/flux/core/SshKeys.kt](https://github.com/bjarneo/flux/blob/f6ed4ac00d84aa06dc948df9efc69ca4beda589c/android/app/src/main/java/org/omarchy/flux/core/SshKeys.kt).
- **E9:** [docs/ios.md](https://github.com/bjarneo/flux/blob/f6ed4ac00d84aa06dc948df9efc69ca4beda589c/docs/ios.md), [docs/macos.md](https://github.com/bjarneo/flux/blob/f6ed4ac00d84aa06dc948df9efc69ca4beda589c/docs/macos.md), [docs/windows.md](https://github.com/bjarneo/flux/blob/f6ed4ac00d84aa06dc948df9efc69ca4beda589c/docs/windows.md), [gui/qml/components/Toggle.qml](https://github.com/bjarneo/flux/blob/f6ed4ac00d84aa06dc948df9efc69ca4beda589c/gui/qml/components/Toggle.qml), [gui/qml/components/Composer.qml](https://github.com/bjarneo/flux/blob/f6ed4ac00d84aa06dc948df9efc69ca4beda589c/gui/qml/components/Composer.qml).
- **E10:** [go.mod](https://github.com/bjarneo/flux/blob/f6ed4ac00d84aa06dc948df9efc69ca4beda589c/go.mod), [macos/Package.swift](https://github.com/bjarneo/flux/blob/f6ed4ac00d84aa06dc948df9efc69ca4beda589c/macos/Package.swift), [dist/arch/PKGBUILD](https://github.com/bjarneo/flux/blob/f6ed4ac00d84aa06dc948df9efc69ca4beda589c/dist/arch/PKGBUILD), [dist/post-install.sh](https://github.com/bjarneo/flux/blob/f6ed4ac00d84aa06dc948df9efc69ca4beda589c/dist/post-install.sh), [dist/pre-remove.sh](https://github.com/bjarneo/flux/blob/f6ed4ac00d84aa06dc948df9efc69ca4beda589c/dist/pre-remove.sh), [docs/install.md](https://github.com/bjarneo/flux/blob/f6ed4ac00d84aa06dc948df9efc69ca4beda589c/docs/install.md), [.github/workflows/build.yml](https://github.com/bjarneo/flux/blob/f6ed4ac00d84aa06dc948df9efc69ca4beda589c/.github/workflows/build.yml).
- **E11:** [internal/release/sign.go](https://github.com/bjarneo/flux/blob/f6ed4ac00d84aa06dc948df9efc69ca4beda589c/internal/release/sign.go), [internal/release/download.go](https://github.com/bjarneo/flux/blob/f6ed4ac00d84aa06dc948df9efc69ca4beda589c/internal/release/download.go), [.github/workflows/release.yml](https://github.com/bjarneo/flux/blob/f6ed4ac00d84aa06dc948df9efc69ca4beda589c/.github/workflows/release.yml).
- **E12:** [repository metadata](https://api.github.com/repos/bjarneo/flux), [latest release](https://github.com/bjarneo/flux/releases/latest), [open issues](https://github.com/bjarneo/flux/issues); retrieved 2026-11-14 UTC.

**Attribution:** bjarneo/flux, Bjarne Oeverli; [MIT license](https://github.com/bjarneo/flux/blob/f6ed4ac00d84aa06dc948df9efc69ca4beda589c/LICENSE). Independent public-source analysis; no upstream code extracted.
