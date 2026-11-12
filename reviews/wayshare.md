# Wayshare (wesleygrimes/wayshare)

**Repo:** https://github.com/wesleygrimes/wayshare
**License:** Apache-2.0 source; native codec and dependency terms remain separate.
**Reviewed:** 2026-11-12 (UTC)
**Revision:** `257791a461fb1d30ab000a5ff6e5a64134216116`, v0.4.0; whole-repository static review, focused on server, capture/input, authentication, display lifecycle, packaging and CI.
**Verification:** Static review only. No builds, tests, installs, desktop access or live client/network probes performed. Public GitHub CI and release results checked separately.
**Stack:** Rust 2024, Tokio, Wayland, Hyprland IPC, EGL/GBM, VA-API/x265, IronRDP/rustls, OpenH264, PulseAudio-compatible capture and FDK-AAC.
**What it is:** A Linux/Hyprland remote-desktop server for Apple's native Screen Sharing application and RDP clients—not a generic file-sharing tool or compositor-independent Wayland service.

## Verdict

⚠️ **Interesting — a compelling Hyprland remote-desktop pilot, behind a VPN.** Native Mac High Performance support and a shared RDP backend solve a concrete interoperability problem. Authentication and teardown are substantive, but Apple Standard pixels and clipboard are unencrypted, remote users share full desktop authority, and the Apple listener lacks RDP's global connection cap. Use a dedicated password, explicitly scoped network access and verified RDP certificate identity; do not expose it directly to the internet.

## What It Is

Wes Grimes's Wayshare exports an existing Hyprland monitor, including remote keyboard/pointer input and optional resizing. It runs as the logged-in user's systemd service. It is not a separate remote login session, multi-user desktop isolation system, browser viewer, or portal-mediated one-off presentation tool.

The Apple listener implements RFB 3.888/3.889, not ordinary generic VNC compatibility. Standard mode supports text, rich-text and image clipboard. High Performance adds HEVC video and AAC-ELD system sound over SRTP; one High Performance viewer owns media at a time, with same-address reconnect takeover. Other viewers may use Standard. RDP adds TLS-protected H.264/AVC420, Planar and legacy graphics, but no clipboard, audio, AVC444, NLA or CredSSP. These asymmetries are documented rather than hidden. [Client matrix][clients], [RDP][rdp-doc].

## Stack

| Layer | Implementation |
|---|---|
| CLI/service | clap, TOML, interactive setup/doctor, systemd user unit |
| Apple protocol | Local RFB/SRP/record crypto, clipboard and media modules |
| Capture | ext-image-copy-capture and wlr-screencopy paths; DMA-BUF/EGL/GBM and CPU/shared-memory handling |
| Input/clipboard | Wayland virtual pointer/keyboard and ext-data-control |
| Display ownership | Hyprland IPC, shared session IDs and resize/exclusive snapshots |
| Apple media | HEVC VA-API or runtime x265; SRTP/RTCP; PulseAudio-compatible sink monitor and FDK-AAC |
| RDP | Vendored/patched IronRDP components, rustls TLS, VA-API/OpenH264 and graphics fallbacks |
| Persistence | TOML settings, salted SRP verifier, persistent PEM TLS identity; no application database |

## Key Features and Claim Checks

### Native clients, but a narrow server platform

The maintainer reports tests with Mac Screen Sharing, Windows App on iPhone/iPad/Mac, mstsc and FreeRDP. Only the iPhone's live resize/rotation is explicitly verified across that RDP list; Windows App on Windows is untested. Generic VNC clients are rejected. These are upstream reports, not reproduced results.

Main startup explicitly constructs a Hyprland backend and checks its version; supported runtime is Hyprland 0.56+ with systemd. Shared Wayland protocols alone do not establish Sway, GNOME, KDE, other compositors or X11 support. macOS CI exercises protocol/core code, not a macOS desktop-sharing backend. GPU support, compositor protocol availability, keyboard layout and monitor modes remain acceptance-test requirements. [Entry point][main], [capture][capture], [input][input], [packaging][packaging].

### Deliberate graphics fallback

Apple Standard captures/diffs frames; High Performance negotiates encrypted media and responds to feedback. Current Standard capture retains the last frame and retries a stopped compositor capture roughly every 500 ms. This improves reconnect resilience but means an apparently visible desktop can temporarily be stale. RDP capture is capped at roughly ten frames per second: H.264 support is not a promise of gaming-grade streaming. Its output path coalesces work, limits socket backlog and closes a client after five seconds without output progress. [Capture recovery][recovery], [RDP transport][transport], [RDP][rdp-doc].

### Shared display ownership, not separate seats

One session owns monitor size changes; other clients scale frames. Physical monitors are restricted to advertised modes, while headless outputs can take arbitrary sizes. Optional exclusive mode snapshots monitors/workspaces/focus before disabling other outputs and restores after the last viewer. It preserves failed restore state for another attempt and rolls back partial mutations. All clients still share desktop focus. [Exclusive lifecycle][exclusive], [configuration][config-doc].

## Architecture

The CLI loads/validates settings, builds authentication and Linux factories, then starts the Apple listener and optional RDP listener. Frame/input/display abstractions permit protocol tests without a real desktop; the production factories reach the compositor. RDP failure does not terminate Apple sessions. A missing SRP record disables RDP; Apple's handshake still rejects connections when no authentication method is available.

Apple sessions perform the handshake, construct input/cursor state, parse bounded messages and drive frame/clipboard/media updates. RAII teardown releases held input, stops High Performance and restores display ownership. RDP uses per-connection authenticated state shared by its credential validator, display and input handlers; session IDs occupy a separate range while sharing the display controller. Vendored IronRDP server/acceptor/DVC changes are important review scope, not interchangeable upstream defaults. [Apple server][rfb], [session][session], [RDP server][rdp-src], [manifest][manifest].

## Security, Authority and Privacy

### Authentication is not full transport confidentiality

The normal Apple login uses an SRP verifier rather than storing a plaintext password. RDP receives a password inside TLS and recomputes that verifier; usernames are exact/case-sensitive and domain must be empty. Constant-time comparisons and zeroizing temporary RDP password/derived-key wrappers are positive details, not proof that every copy is erased. A copied verifier still permits offline guesses; choose a strong password distinct from the OS account. A developer-only legacy DH/password-file path also exists and should not be confused with normal setup. [Authentication][auth], [security][security].

**Apple Standard screen updates and clipboard are unencrypted.** Encrypted input and High Performance SRTP do not protect those other channels, including fallback to Standard. Protect the entire connection with a VPN rather than assuming High Performance makes every byte confidential. Default listeners bind all IPv4 interfaces: TCP 5900 and, in default builds, 3389. mDNS advertises discovery; HP uses UDP 5960/5962 by default. No hosted relay/account is needed, but network peers receive the shared content and mDNS discloses service identity. [Security][security].

RDP creates a mode-0600, persistent self-signed certificate/key with localhost names. Existing invalid identity files fail instead of being silently regenerated. Verify the SHA-256 fingerprint through a trusted path before submitting credentials; blindly accepting a LAN hostname warning allows impersonation. This is TLS plus application password login, not enterprise NLA, MFA or per-user OS authorization. [RDP TLS implementation][rdp-src].

### The Apple pre-login resource boundary is weaker

RDP caps total pending/active connections at eight, gives login 30 seconds, delays failed login by at least two seconds, and gates desktop input/frame delivery on successful authentication. Its patched acceptor bounds pre-login queued input to 256 packets/1 MiB.

In contrast, Apple's accept loop creates a new task for every connection without a corresponding connection-count ceiling. Each session creates its frame source **before** the timed handshake begins. There is a 30-second handshake timeout and message-size validation, but no equivalent admission cap in that path. A reachable unauthenticated peer can therefore induce repeated capture/session allocation. This is a static resource-exhaustion concern, not a demonstrated exploit or a claim that screen bytes bypass authentication. Restrict reachability and consider matching the RDP admission gate before any wider deployment. [Apple accept loop][rfb], [session initialization][session], [RDP admission][rdp-src].

### Setup authorizes ongoing control

Input is enabled by default, and the production path uses virtual keyboard/pointer protocols directly rather than a screen-sharing portal approval dialog. There is no per-connection local accept prompt in the inspected path. A successful shared-password login authorizes control of the same desktop and its accessible applications; monitor selection is not application/process isolation. Input can be disabled globally, but clipboard and display mutations have their own boundaries. Do not treat “view only” as complete isolation without disabling/reviewing those separately.

Apple clipboard bridging can move sensitive text/images between local and remote applications; sound captures the default output sink monitor, not just one application. Avoid confidential content during sharing and separately qualify lock-screen/suspend behavior: this review did not establish a lock-aware capture suspension guarantee. No cloud analytics service was identified in the inspected serving paths; that is not an exhaustive privacy audit. [Main wiring][main], [Wayland clipboard][clipboard], [configuration][config-doc].

## Lifecycle, Recovery and Cleanup

- Graceful shutdown drains aborted Apple sessions so destructors release input and restore state; RDP handlers also implement session cleanup. Media teardown stops audio before joining video.
- Exclusive mode's snapshot is in memory. SIGKILL/process abort cannot run cleanup; configuration reload can restore configured monitor layout, not lost workspace assignments. Runtime exact-name monitor rules may shadow inherited color/VRR/mirroring settings. This limitation is documented explicitly.
- VPN interface availability matters: Apple bind failure stops startup, while RDP bind failure leaves Apple running. Restart after the intended interface appears; a healthy Apple listener is not proof that RDP is available.
- Setup preserves existing TOML while changing selected top-level values, enables/restarts the user unit, and offers scoped ufw changes. It is persistent access setup, not a read-only wizard. The unit follows the graphical session and restarts on failure.
- Uninstall first stops/disables the service and refuses to continue after a confirmed stop failure. It intentionally retains config, password verifier and TLS identity. The inspected uninstaller does not remove setup-created firewall rules. Plan credential and firewall cleanup separately; package/mise binaries need their own removal step. [Service][service], [setup][setup], [configuration][config-doc].

## Dependencies, Installation and Licensing

Cargo.lock, a declared Rust 1.89 minimum, pinned CI actions and pinned IronRDP versions are useful reproducibility signals. Default builds compile OpenH264 and require C/C++ tooling plus EGL/GBM; VA-API, x265 API build 217, FDK-AAC and libpulse are additional runtime compatibility surfaces. Native FFI and custom protocol/crypto code remain audit targets despite a Rust implementation.

The shell installer fetches the latest release and a same-release SHA-256 list, verifies the archive, then installs/runs the binary. The upgrade command downloads and executes the mutable main-branch installer before restarting. Checksums protect consistency, not an independently trusted publisher: the release pipeline generates provenance attestations, but this installer does not verify them. Prefer a reviewed, pinned release/package and verify provenance separately; no rollback guarantee was established. README says the Omarchy package is currently edge-only. Nothing was installed for this review. [Installer][installer], [service][service], [release workflow][release].

Root LICENSE and manifest agree on Apache-2.0; preserve license, modification and applicable notice obligations when redistributing. Vendored IronRDP carries MIT/Apache texts and THIRD-PARTY-LICENSES inventories Rust dependencies. Optional runtime x265 and FDK-AAC have separate licensing/patent implications; the root Apache license does not relicense codec libraries or settle codec patent rights. No source code was extracted. [License][license], [packaging][packaging], [dependency policy][deny].

## Maturity and Verification

Public metadata on review date: created 2026-10-15; last push 2026-11-12; 63 stars, 12 forks, 10 open issues/PRs combined. Latest release v0.4.0 was published 2026-11-12. This is a young, actively maintained project, not evidence of long-term deployment reliability.

CI defines Linux formatting/lint/tests, no-RDP builds, advisory/license checks, macOS core tests and an MSRV build. Tests visible in source cover authentication gating, malformed protocol data, crypto vectors, backpressure, ownership and rollback; real-monitor tests are explicitly ignored/opt-in. At the exact reviewed SHA, GitHub reports [CI success](https://github.com/wesleygrimes/wayshare/actions/runs/43153541492) and [release success](https://github.com/wesleygrimes/wayshare/actions/runs/43153999937). Other recent runs at different SHAs failed, so this is a revision-specific result, not a claim that every branch is green.

The dependency policy explicitly accepts three advisories, with reasons involving unused RSA/smart-card paths and an unmaintained transitive dependency. That is transparent risk acceptance, not an advisory-free tree. v0.4.0 also records fixes for monitor mode handling, capture recovery and a rustix advisory. No fresh dependency audit, build, benchmark, test suite or actual Mac/RDP interoperability test was run here. CI success does not validate every compositor/GPU/client combination. [CI][ci], [changelog][changelog], [dependency policy][deny].

## Comparison

| Option | Prefer it when | Tradeoff versus Wayshare |
|---|---|---|
| Wayshare | Hyprland with native Mac Screen Sharing or RDP clients | Apple HP integration; narrow server support and unequal protocol feature sets |
| [wayvnc](https://github.com/any1/wayvnc) | A supported compositor and conventional VNC clients | Different client/security ecosystem; not a drop-in implementation of Apple's HP mode |
| [Sunshine](https://github.com/LizardByte/Sunshine) + Moonlight | High-frame-rate remote streaming is primary | Dedicated client/pairing stack rather than native Apple Screen Sharing/RDP |
| [GNOME Remote Desktop](https://gitlab.gnome.org/GNOME/gnome-remote-desktop) / [KRdp](https://invent.kde.org/plasma/krdp) | The host is GNOME or KDE | Desktop-native integration; not a reason to assume Wayshare supports those compositors |

These are architectural fit comparisons, not side-by-side benchmarks or fresh security reviews of the alternatives.

## Self-Hosting Notes

Pilot on a non-critical, supported Hyprland desktop with explicit monitor selection. Bind both protocols to the intended VPN/interface, constrain VPN ACLs and firewall rules, disable unused listeners/input/audio, verify the RDP certificate out of band and use a dedicated strong password. Keep a local recovery path for monitor/cursor state. Before unattended use, qualify disconnect/reconnect, capture loss, suspend/lock, mixed viewers, clipboard exposure, GPU/software fallback and version upgrades on the actual client combination. “Doctor” checks do not replace real RDP certificate/connectivity or HP UDP acceptance tests.

**Bottom line:** Worth a controlled pilot for its unusually useful Apple/Hyprland integration. Not a public-internet remote-access endpoint or a multi-user security boundary.

**Attribution:** Wes Grimes and contributors, wesleygrimes/wayshare, Apache-2.0; third-party terms separate.

[clients]: https://github.com/wesleygrimes/wayshare/blob/257791a461fb1d30ab000a5ff6e5a64134216116/docs/clients.md
[rdp-doc]: https://github.com/wesleygrimes/wayshare/blob/257791a461fb1d30ab000a5ff6e5a64134216116/docs/rdp.md
[main]: https://github.com/wesleygrimes/wayshare/blob/257791a461fb1d30ab000a5ff6e5a64134216116/src/main.rs
[capture]: https://github.com/wesleygrimes/wayshare/blob/257791a461fb1d30ab000a5ff6e5a64134216116/src/capture/mod.rs
[input]: https://github.com/wesleygrimes/wayshare/blob/257791a461fb1d30ab000a5ff6e5a64134216116/src/input/wayland.rs
[packaging]: https://github.com/wesleygrimes/wayshare/blob/257791a461fb1d30ab000a5ff6e5a64134216116/docs/packaging.md
[recovery]: https://github.com/wesleygrimes/wayshare/blob/257791a461fb1d30ab000a5ff6e5a64134216116/src/capture/cpu_source.rs
[transport]: https://github.com/wesleygrimes/wayshare/blob/257791a461fb1d30ab000a5ff6e5a64134216116/src/rdp/transport.rs
[exclusive]: https://github.com/wesleygrimes/wayshare/blob/257791a461fb1d30ab000a5ff6e5a64134216116/src/display/exclusive.rs
[config-doc]: https://github.com/wesleygrimes/wayshare/blob/257791a461fb1d30ab000a5ff6e5a64134216116/docs/configuration.md
[rfb]: https://github.com/wesleygrimes/wayshare/blob/257791a461fb1d30ab000a5ff6e5a64134216116/src/rfb/mod.rs
[session]: https://github.com/wesleygrimes/wayshare/blob/257791a461fb1d30ab000a5ff6e5a64134216116/src/rfb/session.rs
[rdp-src]: https://github.com/wesleygrimes/wayshare/blob/257791a461fb1d30ab000a5ff6e5a64134216116/src/rdp.rs
[manifest]: https://github.com/wesleygrimes/wayshare/blob/257791a461fb1d30ab000a5ff6e5a64134216116/Cargo.toml
[auth]: https://github.com/wesleygrimes/wayshare/blob/257791a461fb1d30ab000a5ff6e5a64134216116/src/auth.rs
[security]: https://github.com/wesleygrimes/wayshare/blob/257791a461fb1d30ab000a5ff6e5a64134216116/docs/security.md
[clipboard]: https://github.com/wesleygrimes/wayshare/blob/257791a461fb1d30ab000a5ff6e5a64134216116/src/clipboard/wayland.rs
[service]: https://github.com/wesleygrimes/wayshare/blob/257791a461fb1d30ab000a5ff6e5a64134216116/src/service.rs
[setup]: https://github.com/wesleygrimes/wayshare/blob/257791a461fb1d30ab000a5ff6e5a64134216116/src/setup.rs
[installer]: https://github.com/wesleygrimes/wayshare/blob/257791a461fb1d30ab000a5ff6e5a64134216116/install.sh
[release]: https://github.com/wesleygrimes/wayshare/blob/257791a461fb1d30ab000a5ff6e5a64134216116/.github/workflows/release.yml
[license]: https://github.com/wesleygrimes/wayshare/blob/257791a461fb1d30ab000a5ff6e5a64134216116/LICENSE
[deny]: https://github.com/wesleygrimes/wayshare/blob/257791a461fb1d30ab000a5ff6e5a64134216116/deny.toml
[ci]: https://github.com/wesleygrimes/wayshare/blob/257791a461fb1d30ab000a5ff6e5a64134216116/.github/workflows/ci.yml
[changelog]: https://github.com/wesleygrimes/wayshare/blob/257791a461fb1d30ab000a5ff6e5a64134216116/CHANGELOG.md
