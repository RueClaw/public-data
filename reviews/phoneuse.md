# phoneuse (lxe/phoneuse)

**Repo:** https://github.com/lxe/phoneuse

**Author:** Aleksey Smolenchuk (lxe)

**License:** MIT; preserve copyright and permission notices when reusing code. Dependencies and model weights have separate terms.

**Reviewed:** 2026-11-08 (UTC)

**Revision:** 3902b415c763ff9ebd63e3627e23c87237b3076c, default branch master; whole-repository static review, focused on Python control/services, ESP32 control protocol, installation and agent interfaces. Commit dated 2026-11-08T16:29:08Z.

**Verification:** Static source and public metadata inspection only. No source execution, tests, installation, model downloads, pairing, phone access or paid calls.

**Stack:** Python 3.11+, BlueZ/D-Bus, UxPlay, GStreamer/GTK4, Hyprland, aiohttp/WebCodecs, optional local OCR/grounding, C/ESP-IDF bridge.

## Verdict

⚠️ **Interesting — ingenious iPhone control demo, not a hardened personal-phone agent.** AirPlay in and Bluetooth HID out avoids jailbreaks and a mandatory iOS app. The frame hub, visual feedback and owner-unlock workflow are thoughtful, but missing WebSocket origin validation, always-open Bluetooth pairing, plaintext bridge reports and cooperative-only agent controls make this a supervised spare-device experiment, not unattended access to a primary phone.

## What It Is

phoneuse lets a Linux desktop view and manipulate an unmodified iPhone using ordinary Screen Mirroring and AssistiveTouch. It is not Android ADB automation, an iOS accessibility-tree reader, an iMessage database client, or a standalone reasoning agent. CLI and stdio MCP tools provide screen capture, OCR, coordinate/label taps, swipes, typing and app navigation to an external agent. Human operators can use GTK and browser mirrors directly. [README](https://github.com/lxe/phoneuse/blob/3902b415c763ff9ebd63e3627e23c87237b3076c/README.md), [MCP](https://github.com/lxe/phoneuse/blob/3902b415c763ff9ebd63e3627e23c87237b3076c/phoneuse/mcp_server.py)

The optional LilyGO ESP32 bridge moves the Bluetooth transmitter next to the phone while the computer sends commands over Wi-Fi. A newly added companion **server and protocol** support phone-side takeover/unlock approval and APNs Live Activities; this checkout contains no iOS application source or verified app distribution. Do not confuse the optional companion design with a requirement for the core app-free path. [Companion implementation](https://github.com/lxe/phoneuse/blob/3902b415c763ff9ebd63e3627e23c87237b3076c/phoneuse/companion.py), [protocol](https://github.com/lxe/phoneuse/blob/3902b415c763ff9ebd63e3627e23c87237b3076c/docs/COMPANION.md)

## Stack and Requirements

| Layer | Implementation / requirement |
|---|---|
| Screen ingress | iPhone AirPlay → UxPlay → loopback H.264 RTP |
| Display and frames | GStreamer decode/re-encode hub; GTK4 mirror; WebCodecs browser; frames service |
| Input | Root Python HID daemon with BlueZ classic Bluetooth mouse/keyboard/absolute-pointer reports |
| Desktop coupling | Hyprland IPC, readable Linux input devices, GTK4/GStreamer plugins; not a generic Windows/macOS host |
| Local vision | RapidOCR/ONNX Runtime; GoClick-Large via PyTorch and Transformers 4.45.0 |
| Agent integration | CLI plus optional MCP SDK in a separate system-site-packages virtual environment |
| Optional hardware | Original ESP32 LilyGO T-Display, ESP-IDF v6.1, 2.4 GHz Wi-Fi; BLE setup and classic Bluetooth HID |

Upstream explicitly calls this **heavy-construction technology-demo software**, tested on one setup: iPhone 17 Pro/iOS 26, Arch Linux, BlueZ 5.87, Hyprland 0.56, UxPlay 1.73.7, GStreamer 1.28, GTK 4.24 and NVIDIA GPU. Python 3.11+ is required by the core; vision setup selects Python 3.12. Software video decode/encode and CPU model fallbacks exist, but their practical latency and other iPhone/desktop compatibility were not verified. Other screen sizes require configuration and pointer calibration; these are not evidence of broad iOS support. [Requirements](https://github.com/lxe/phoneuse/blob/3902b415c763ff9ebd63e3627e23c87237b3076c/README.md), [config](https://github.com/lxe/phoneuse/blob/3902b415c763ff9ebd63e3627e23c87237b3076c/phoneuse/config.py)

The phone and computer need LAN reachability, Bluetooth connectivity (direct or bridge), user-initiated mirroring, and AssistiveTouch; Dwell Control must be off to avoid unintended taps. The cursor helper can ask Siri aloud via the computer's speakers, which requires an appropriate unlocked, nearby phone and is not a silent system API. No jailbreak/developer account/cable is required for the core path; USB flashing and additional tooling are needed for the optional bridge. APNs configuration is a separate Apple credential/account dependency.

## Architecture and Key Features

1. **Two independent channels.** Screen video arrives through AirPlay; input goes back as keyboard/mouse reports, not through AirPlay. The root daemon exposes a group-writable Unix command socket, used by CLI, browser and desktop input adapters. The bridge can replace direct Bluetooth without presenting two keyboards at once. [Daemon](https://github.com/lxe/phoneuse/blob/3902b415c763ff9ebd63e3627e23c87237b3076c/phoneuse/hid_daemon.py), [bridge client](https://github.com/lxe/phoneuse/blob/3902b415c763ff9ebd63e3627e23c87237b3076c/phoneuse/bridge.py)
2. **A restartable frame fan-out.** UxPlay feeds a dedicated hub that decodes once and re-encodes with NVENC or x264, retaining the last frame and producing keyframes for new viewers. Viewer restarts need not interrupt AirPlay; hub or receiver restarts still require the owner to restart Screen Mirroring. Bounded browser frame queues drop stale work rather than accumulate latency. [Hub](https://github.com/lxe/phoneuse/blob/3902b415c763ff9ebd63e3627e23c87237b3076c/phoneuse/hub.py), [browser](https://github.com/lxe/phoneuse/blob/3902b415c763ff9ebd63e3627e23c87237b3076c/phoneuse/web.py)
3. **Feedback rather than blind sleeps.** The frame service detects meaningful visual change and settling while discounting persistent animation. MCP actions default to a three-frame strip at approximately 0.1/0.4/0.8 seconds, plus OCR of the last frame—not the README's blanket claim that every action waits for settling. A settled single image/text view is another mode. Neither proves the intended app transaction succeeded. [Frames](https://github.com/lxe/phoneuse/blob/3902b415c763ff9ebd63e3627e23c87237b3076c/phoneuse/frames.py), [MCP](https://github.com/lxe/phoneuse/blob/3902b415c763ff9ebd63e3627e23c87237b3076c/phoneuse/mcp_server.py)
4. **Text-first targeting and stale-view detection.** Label matching can refuse absent text; visual descriptions fall back to a grounding model that can still return a coordinate when the target is absent. Positional tap guards compare nearby image content, but permit force overrides and fail open on absent/old evidence or read errors. This is an ergonomic safeguard, not an authorization boundary. [CLI](https://github.com/lxe/phoneuse/blob/3902b415c763ff9ebd63e3627e23c87237b3076c/phoneuse/cli.py)

## Security, Consent and Privacy

### Browser mirror: loopback is not enough

The browser server binds to loopback port 8777. Several sensitive HTTP mutations validate an exact localhost Origin, which is worthwhile. However, the **WebSocket handler prepares /ws without any Origin or token check**, then streams phone frames and accepts input messages. The client-provided “playing” flag and a live mirror are the input gates; there is no browser identity check. A foreign website able to reach that loopback WebSocket could therefore access the screen/control path. Browser local-network protections may constrain reachability, so this is a static missing-control finding, not a reproduced browser exploit. Validate Origin/Host and add a per-session secret before using a real personal phone. [web.py, ws / Tab.handle / same_origin](https://github.com/lxe/phoneuse/blob/3902b415c763ff9ebd63e3627e23c87237b3076c/phoneuse/web.py)

### Pairing and privileged host access

The BlueZ agent accepts Just Works pairing. Despite an earlier comment describing a limited pairing window, setup actually calls **open_pairing(0)**, leaving the adapter discoverable/pairable indefinitely. The profile sets RequireAuthentication and RequireAuthorization false, and the architecture permits a new paired device to replace the current connection. This is not evidence that an arbitrary nearby device can directly read the iPhone; it is an unnecessarily broad pairing/device-selection boundary. Use a bounded owner-approved window and explicit device binding. [hid_daemon.py, Agent / setup_dbus](https://github.com/lxe/phoneuse/blob/3902b415c763ff9ebd63e3627e23c87237b3076c/phoneuse/hid_daemon.py)

The HID command socket is mode 0660, root-owned with the wheel group selected by the installer. Members can send low-level commands outside the CLI's mirror, unlock and takeover checks. The service runs Python as root from the installed repository directory, without sandbox hardening in the supplied unit; a user-writable checkout consequently becomes trusted root-executed code on service restart. Desktop input capture reads Linux input devices; read-only does not mean privacy-free. Restrict both source-tree ownership and device/socket access. [Installer](https://github.com/lxe/phoneuse/blob/3902b415c763ff9ebd63e3627e23c87237b3076c/scripts/install.sh), [input adapter](https://github.com/lxe/phoneuse/blob/3902b415c763ff9ebd63e3627e23c87237b3076c/phoneuse/mirror_input.py)

### Unlock approval is useful, but not isolation

The normal unlock route creates a request ID, waits up to two minutes for the browser/desktop/companion answer, and does not disclose the saved code in normal tool output. Storage is **plaintext**, protected by mode 0600 and a 0700 directory, not a vault. The unlock helper refuses permissive file modes, detects lock screens through OCR, types once and checks afterward; the three-attempts/hour counter is in process memory and resets on restart. OCR/English lock-screen heuristics can be wrong. [unlock.py](https://github.com/lxe/phoneuse/blob/3902b415c763ff9ebd63e3627e23c87237b3076c/phoneuse/unlock.py), [UnlockRequests](https://github.com/lxe/phoneuse/blob/3902b415c763ff9ebd63e3627e23c87237b3076c/phoneuse/web.py)

The helper function itself is not a separate authorization service; approval lives in its caller. A same-user shell agent can read the stored code, spoof Origin headers, or use the underlying daemon if granted access. Thus “the agent never sees the passcode” describes the intended tool flow, not a guarantee against a compromised same-user agent. Prefer manual unlock and do not grant a phone agent unrestricted shell access.

### Bridge: integrity is not confidentiality

BLE provisioning uses X25519, a displayed comparison code and AES-GCM for Wi-Fi credentials. UDP control on port 47700 uses HMAC-SHA256 truncated to eight bytes, sessions and increasing sequence numbers. Cached replies suppress duplicate report execution after a lost reply; four sessions support concurrent clients. These are substantive reliability/authentication mechanisms. [Bridge protocol](https://github.com/lxe/phoneuse/blob/3902b415c763ff9ebd63e3627e23c87237b3076c/docs/BRIDGE.md), [firmware link](https://github.com/lxe/phoneuse/blob/3902b415c763ff9ebd63e3627e23c87237b3076c/bridge/main/link.c)

**Ordinary HID REPORT/KEYS payloads are authenticated but not encrypted.** A party able to observe LAN packets can infer typed characters—including a saved passcode when entered through the bridge—from keyboard reports. Wi-Fi credential sealing does not protect those keystrokes. Discovery is unsigned, and firmware persists the control key/network settings in NVS without flash-encryption or secure-boot settings evident in the supplied defaults. Treat the network and physical bridge as trusted; encrypt all control traffic before credential-bearing use. [link.c](https://github.com/lxe/phoneuse/blob/3902b415c763ff9ebd63e3627e23c87237b3076c/bridge/main/link.c), [settings.c](https://github.com/lxe/phoneuse/blob/3902b415c763ff9ebd63e3627e23c87237b3076c/bridge/main/settings.c), [defaults](https://github.com/lxe/phoneuse/blob/3902b415c763ff9ebd63e3627e23c87237b3076c/bridge/sdkconfig.defaults)

### Companion listener and outbound data

The browser process attempts to start the companion API on **all IPv4 interfaces, TCP 8778**, even though the companion app is optional. It advertises through Avahi. Authentication uses a one-use, ten-minute pairing link with a 32-byte key; signed requests include method/path/body hash, timestamp and nonce, with replay tracking. Passcode/Wi-Fi fields are AES-GCM sealed. This is stronger than an unauthenticated LAN API, but ordinary requests/responses use HTTP, not TLS, and state/action labels are not confidential. Nonce history is in memory; restart loses it. Pairing URLs are bearer secrets and need private handling. No app implementation was available to verify Keychain storage or phone-side approval behavior. [companion.py](https://github.com/lxe/phoneuse/blob/3902b415c763ff9ebd63e3627e23c87237b3076c/phoneuse/companion.py)

Core mirroring and local OCR need no cloud model API. Nevertheless, MCP returns images and OCR text to the external agent, so that harness may transmit private messages, notifications, photos and account information to its model provider and retain them in transcripts. There is no task-specific screen redaction or iOS accessibility-tree permission scope: this is pixel access to whatever is visible. Screenshots and diagnostic input/video/Bluetooth captures are sensitive artifacts; some temporary screenshots are removed, but explicit captures and traces persist and error paths are not a complete retention policy. Runtime paths fall back to a shared temporary directory when XDG_RUNTIME_DIR is absent. [MCP](https://github.com/lxe/phoneuse/blob/3902b415c763ff9ebd63e3627e23c87237b3076c/phoneuse/mcp_server.py), [CLI](https://github.com/lxe/phoneuse/blob/3902b415c763ff9ebd63e3627e23c87237b3076c/phoneuse/cli.py), [telemetry](https://github.com/lxe/phoneuse/blob/3902b415c763ff9ebd63e3627e23c87237b3076c/tools/telemetry.py)

If APNs is configured, action text, session state/counts and unlock notifications leave for Apple's push service using an operator-supplied signing key. Local vision still consumes RAM/GPU, disk and model-download bandwidth. External agent inference has its own image/token charges or subscription limits; no end-to-end spend cap is implemented here. Upstream image-token/latency figures are observations or estimates, not verified pricing or performance guarantees. [APNs](https://github.com/lxe/phoneuse/blob/3902b415c763ff9ebd63e3627e23c87237b3076c/phoneuse/apns.py), [companion activity loop](https://github.com/lxe/phoneuse/blob/3902b415c763ff9ebd63e3627e23c87237b3076c/phoneuse/companion.py)

### Prompt injection and consequential actions

MCP instructions and the shipped skill tell the agent to ask before sending, posting, buying, deleting, modifying accounts/security or approving permissions. These are good instructions, **not enforced transaction gates**. Generic tap/type/Enter tools can perform all those operations; there is no recipient/amount binding, purchase confirmation receipt, app allowlist or screen-content trust classifier. Malicious text in a web page, message or screenshot can enter the same model context as legitimate observations. Keep that content untrusted, require a human approval immediately before the final consequential action, and verify the actual destination and outcome. [MCP instructions](https://github.com/lxe/phoneuse/blob/3902b415c763ff9ebd63e3627e23c87237b3076c/phoneuse/mcp_server.py), [skill rules](https://github.com/lxe/phoneuse/blob/3902b415c763ff9ebd63e3627e23c87237b3076c/skill/SKILL.md)

## Reliability, Recovery and Concurrency

The implementation has real engineering beyond a gesture demo: Bluetooth reconnection and calibration, skippable hover backpressure, bridge acknowledgement/deduplication, key release on browser disconnect, fresh keyframes, frame settling and automatic child-process restart. The author reports roughly 100 ms visual response and slower bridge report delivery; this review did not reproduce those measurements. [Architecture](https://github.com/lxe/phoneuse/blob/3902b415c763ff9ebd63e3627e23c87237b3076c/ARCHITECTURE.md), [bridge measurements](https://github.com/lxe/phoneuse/blob/3902b415c763ff9ebd63e3627e23c87237b3076c/docs/BRIDGE.md)

Takeover pauses normal CLI/MCP actions through a browser-service check, but that check **continues on connection errors and non-409 HTTP failures**. Browser restart also loses its in-memory pause state. Low-level HID clients bypass it entirely. A 20-second activity timeout is a UI indicator, not an exclusive per-agent lease. Shared last-view/action files, multiple socket clients and simultaneous physical-phone use can interleave; report-level locks do not make a multi-step gesture or purchase atomic. Run one controller at a time. [cli.agent_turn](https://github.com/lxe/phoneuse/blob/3902b415c763ff9ebd63e3627e23c87237b3076c/phoneuse/cli.py), [web agent state](https://github.com/lxe/phoneuse/blob/3902b415c763ff9ebd63e3627e23c87237b3076c/phoneuse/web.py), [daemon command threads](https://github.com/lxe/phoneuse/blob/3902b415c763ff9ebd63e3627e23c87237b3076c/phoneuse/hid_daemon.py)

Automatic reconnect cannot establish whether an app already sent a message before a failure. Do not retry a consequential action merely because its screenshot/acknowledgement failed. Re-observe and reconcile first. Auto-correct, US keyboard layout, notification overlays, iOS updates, stale coordinates and OCR/grounder errors all remain operational hazards.

## Installation, Updates, Dependencies and Maturity

Installation is manual clone/symlink plus a sudo script, not a self-contained package manager transaction. The script writes a Bluetooth systemd override, disables bluetoothd input/hostname plugins, adds a device class, installs/enables the root HID service and restarts Bluetooth. It can disrupt the computer's own Bluetooth keyboard/mouse. An uninstall path removes owned files/markers, but it is not a snapshot-based rollback and does not restore arbitrary previous overwritten contents. Inspect and back up the exact affected configuration before any pilot. [install.sh](https://github.com/lxe/phoneuse/blob/3902b415c763ff9ebd63e3627e23c87237b3076c/scripts/install.sh)

Vision setup installs mostly unpinned dependencies and downloads GoClick files without a model revision pin; runtime uses **trust_remote_code=True** for model and processor loading. That executes remote model-repository Python, not merely inert weights. MCP setup uses mcp>=2.3 and system-site-packages. No lockfile, root Python packaging manifest, test suite or CI workflow was found in the reviewed tree; diagnostic tools and touchlab are not automated regression coverage. The root MIT license does not establish the licenses or security of UxPlay, GStreamer plugins, model weights and their transitive dependencies. No dependency vulnerability audit was performed. [vision setup](https://github.com/lxe/phoneuse/blob/3902b415c763ff9ebd63e3627e23c87237b3076c/scripts/setup-vision.sh), [vision loader](https://github.com/lxe/phoneuse/blob/3902b415c763ff9ebd63e3627e23c87237b3076c/phoneuse/vision.py), [MCP setup](https://github.com/lxe/phoneuse/blob/3902b415c763ff9ebd63e3627e23c87237b3076c/scripts/setup-mcp.sh)

Updates are especially sensitive because the user-side supervisor watches source files and restarts components, while MCP hot-reloads modules between calls. Stop control before changing the checkout, pin a reviewed revision and explicitly restart/test; do not treat an in-place pull as an atomic upgrade. No signed release/update verification path was identified.

Public GitHub metadata retrieved 2026-11-08 reported creation on 2026-11-07, last push 2026-11-08T16:29:10Z, 362 stars, 36 forks and 7 open items (GitHub's issue count includes pull requests). The releases API returned an empty list. An open issue proposes remote modes; it is not evidence of implemented supported remote operation. The issue listing was not used as a complete issue census. Popularity after roughly one day does not establish reliability. [Metadata](https://api.github.com/repos/lxe/phoneuse), [releases](https://github.com/lxe/phoneuse/releases), [remote-mode issue](https://github.com/lxe/phoneuse/issues/8)

## Comparison

| Option | Better fit | Tradeoff against phoneuse |
|---|---|---|
| [UxPlay](https://github.com/FDH2/UxPlay) alone | Linux AirPlay viewing without agent input | Smaller authority surface; does not supply phoneuse's HID/agent loop |
| [Apple iPhone Mirroring](https://support.apple.com/en-us/120421) | Supported human desktop control on compatible Macs/iPhones | Apple platform/availability restrictions; not this Linux CLI/MCP workflow |
| [Appium XCUITest](https://github.com/appium/appium-xcuitest-driver) | Structured iOS application testing | More provisioning/macOS toolchain setup; different testing and element-access model |
| [scrcpy](https://github.com/Genymobile/scrcpy) | Android display/control | Mature alternative for a different platform; not a replacement for an iPhone |
| Native app APIs / Shortcuts | Narrow repeatable tasks when supported | Less general UI reach, often a more constrainable and reliable action surface |

These are capability-level comparisons, not fresh audits or benchmark results. Prefer a narrow authorized API over full-screen control where possible; use phoneuse when the specific Linux-to-stock-iPhone interaction is the experiment itself.

## Self-Hosting Notes / Acceptance Bar

Use a spare phone with test accounts on an isolated trusted network, a dedicated Linux user/host, manual unlock, and one controller. Do not port-forward the web/companion services or expose bridge UDP to the Internet. Keep real notifications, payment apps and credentials out of early tests. Do not mistake “local OCR” for “no provider data egress.”

Before broader use: fix WebSocket origin/session authorization; restrict pairing and device identity; encrypt bridge input; make takeover fail closed and persistent; isolate secrets from agents; add serialized session ownership and app/action approvals; pin and audit dependencies/model code; test lock-state failures, disconnects, stale frames, concurrent control and rollback on every qualified platform.

## Verification and Limits

Public HTTPS acquisition and canonical lxe/phoneuse identity were verified; the exact source commit above was checked out. Review evidence includes README/license, service and firmware configuration, CLI/MCP, frame/display pipeline, browser and companion authentication, bridge protocol, credential handling and installers. Findings about missing guards are static code observations, not penetration-test results. No real phone, Bluetooth adapter, local input device, user content, credential or cloud model was accessed; source tests/builds were not run. Firmware crypto, Bluetooth behavior, browser restrictions, app availability and all performance/compatibility claims require independent controlled validation.

**Attribution:** [lxe/phoneuse](https://github.com/lxe/phoneuse), copyright 2026 Aleksey Smolenchuk, MIT. Analysis only; no source-code extraction.
