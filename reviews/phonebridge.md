# PhoneBridge (CodeFu72/phonebridge)

**Repo:** https://github.com/CodeFu72/phonebridge
**Author:** Kirk Fuson / EchoLine and PhoneBridge contributors
**License:** MIT original code; bundled Monoton and Orbitron fonts carry SIL OFL notices. Preserve applicable notices when redistributing.
**Reviewed:** 2026-11-24 (UTC)
**Revision:** `52d80947ed0e6265f5fb8505fc45fb63c564d8fb`, main; repository-wide static review focused on desktop, Bluetooth transport, setup, storage, preview networking, installer, packaging and tests.
**Verification:** Anonymous HTTPS clone and public GitHub metadata verified. Source and tests inspected; no source execution, installs, device access, live Bluetooth/desktop probes or message sending. Artifact checks are not application tests.
**Stack:** Python, GTK 4/PyGObject, dbus-python, BlueZ/bluez-obex, GLib; standard-library HTTP preview client.
**What it is:** A small Linux desktop text client for a nearby paired iPhone over Bluetooth MAP, not a remote-control bridge or a complete Apple Messages replacement.

---

## Verdict

⚠️ **Interesting — carefully gated messaging, but still an experimental alpha.** The single-worker transport, exact-send review and conservative uncertain-send handling are good foundations for a deliberately narrow, no-Mac client. Broad interoperability remains unproven; link previews expand its network/privacy boundary, and the source-archive packaging allowlist is already stale. Evaluate BlueFerry first for broader direct-Bluetooth functionality; consider PhoneBridge for a small, session-only GTK workflow, not as the sole channel for important messages.

## What It Is

PhoneBridge exposes iPhone messages through BlueZ's existing MAP/OBEX interfaces. The Linux computer does not log into Apple or relay through a Mac. The phone remains the service endpoint and decides SMS versus iMessage; a Bluetooth transfer completion is not recipient delivery. The README reports one working ThinkPad/iPhone setup and explicitly calls the project experimental. That report is not independent compatibility validation. [S1] [S2]

This is an interactive personal desktop application. It has neither an HTTP messaging server nor an agent/MCP API, general phone control, screen mirroring, or a cloud account integration in the reviewed runtime. ANCS appears as a temporary permission-discovery advertisement, not a general notification reader. It is a standalone GTK app with a standard tray item, not an Omarchy shell plugin. [S3] [S4] [S5]

## Stack

| Layer | Tech |
|-------|------|
| Desktop | GTK 4, PyGObject, GLib; custom CSS and bundled fonts |
| Transport | dbus-python; BlueZ system bus for devices/setup, user-session OBEX bus for MAP |
| Concurrency | One command-queue Bluetooth worker; GTK completion events; separate preview threads |
| State | In-memory message/session state; small private JSON settings files |
| Integration | StatusNotifierItem/DBusMenu, desktop notifications, optional audio binaries and targeted hyprctl dispatches |
| Networking | urllib HTTP(S), on explicit Preview action only |

The README says Python 3, but theme.py imports standard-library tomllib: this source needs Python 3.11+ absent a compatibility change. Dependencies come from distribution packages; no Python dependency lockfile or pinned runtime environment is tracked. [S1] [S5] [S6]

## Key Features

### Deliberately bounded read and send paths

The bridge polls the inbox approximately every four seconds, requesting up to 100 previews with 255-character subjects. Selecting a conversation queues full-body downloads with attachments disabled; failed downloads remain visibly marked previews. The parser has a 2 MiB input limit. Size checking occurs on advertised transfer size and the resulting file, so this is not a demonstrated streaming disk quota against a peer that misreports size. [S2] [S7]

The composer supports one validated telephone number or email recipient and a 2,000 UTF-8-byte text limit. It rejects control characters and structural bMessage delimiter lines. A modal review captures the exact address and draft; a state gate permits one outstanding submission. Push options disable retries, terminal transfer receipts are preserved, and disappearance of a transfer object alone never establishes success. Uncertain results require acknowledgement rather than automatic resend. These protections are implemented application logic, not an OS-enforced permission boundary. [S2] [S8] [S9]

### Desktop convenience without full message synchronization

Implemented features include favorites, local aliases, emoji insertion, recency ordering, generic optional notifications, an unread tray badge, and confirmed local thread clearing. Read/unread counts do not modify the phone's Read flag. Outgoing history consists of sends during this app session; there is no persistent chat database, complete phone-sent history, group reply, media transfer, reaction or calling implementation in the desktop client. Group-origin messages target the visible sender only. The attachment probe is a separate experimental diagnostic, not media support. [S1] [S5] [S9]

### On-demand previews are a real egress boundary

Message text is escaped for Pango links. Preview explicitly fetches a page and potentially its declared thumbnail; the initial tooltip names the first host. Downloads have timeouts and byte limits, with no preview disk cache in this implementation. This avoids automatic link fetching on receipt, but does not mean the whole application is offline. [S5] [S9] [S10]

## Architecture

app.py is the large GTK coordinator (1,247 lines at this revision); bridge.py owns Bluetooth session lifecycle and serializes discover/connect/poll/body/send commands. send_test.py is both a terminal diagnostic and a runtime transport/validation dependency, which makes packaging correctness particularly important. model.py handles message presentation, settings and SendGate; history.py parses plain/MIME text. Setup and access advertisement are separate entry points. tray.py, presentation.py, alerts.py and theme.py isolate desktop integration. [S2] [S5] [S8] [S9]

This is a useful separation of slow transport from UI work, but not a sandbox. The regular desktop user grants the process access to session/system D-Bus as allowed by host policy, local files, the network, desktop notifications and the compositor. There is no separate scoped application credential or per-recipient OS consent. A compromised app has normal user-process authority; send confirmation protects against ordinary UI mistakes, not malicious code running as that user.

## Security, Privacy and Authority

### Pairing and permission setup

The wizard temporarily registers a KeyboardDisplay default BlueZ agent, asks the user to compare the six-digit code, rejects unrelated authorization/service requests once a device is selected, and asks before allowing a service. New pairing makes the adapter discoverable/pairable, with a 180-second discoverability timer. The permission helper advertises ANCS solicitation for at most 90 seconds. The phone must grant Show Message Notifications; a successful capability probe only opens/introspects MAP and lists folders, not messages or a test send. [S3] [S4]

Ordinary exit uses cleanup to unregister agents/advertisements and restore saved adapter settings. Forced termination cannot guarantee cleanup; Pairable may need manual restoration. Explicitly enabling adapter power persists. The prior default agent cannot be recovered through this implementation, so unregistering is not restoration of the former selection. The bond and iPhone permission also outlive the app. Installation itself does not pair devices or enable services. [S3] [S4] [S11]

### Finding: Preview can reach local-network destinations

**Moderate, click-dependent concern:** linkpreview.py restricts schemes to HTTP(S), including redirects, but does not reject private, loopback, link-local or metadata addresses, resolve/filter DNS results, or enforce a same-origin thumbnail policy. A sender-controlled page can therefore redirect the preview or declare an image at a host reachable by the desktop, after the user clicks Preview. The dot-in-host link heuristic is not an address-range security check. Remote sites also learn the client IP and requested URL; thumbnail hosts receive additional requests. This is a local-network request/privacy exposure, not proof of credential theft or arbitrary code execution. [S10]

Recommendation: disable/avoid previews for untrusted messages until all request hops and thumbnails have public-address checks, credentials-in-URL rejection, DNS/rebinding-aware enforcement and explicit cross-origin disclosure. The HTTP size caps limit downloaded bytes, not necessarily decoded image dimensions or aggregate in-memory cache size. No exploit was run.

### Storage and retention

Message bodies and send receipts remain in process memory except temporary bMessage files. Sends use a 0700 temporary directory and 0600 file; downloads use a private temporary directory and chmod the received file. Normal context-manager cleanup removes files, but a crash/forced kill can leave them; this is not encrypted storage, secure erasure or proof against swap/core dumps. The phone, carrier/service and recipients retain their normal copies. [S2] [S8]

Favorites retain recipient addresses/names; aliases and preferences are JSON. Atomic replacement and owner-only directory/temp-file modes are positive controls. cleared.json stores unsalted hashes of contact/message identities: these are persistent metadata, not anonymization or encryption, and low-entropy addresses can be guessed. There is no retention TTL. Removing deletion markers allows old phone inbox entries to reappear; deletion is local suppression, not phone deletion. [S9]

Notifications are disabled by default and generic when enabled; audio receives a bundled sound path, not message text. Diagnostic terminal tools can print private messages and should not have logs shared indiscriminately. No analytics or network listener was found in the reviewed runtime, but preview networking is the important exception to the no-cloud-relay story. [S1] [S8] [S12]

## Persistence, Recovery and Self-Hosting Notes

There is no server to self-host. The per-user installer copies modules/assets/docs, writes two launchers and a desktop entry/icon, and optionally merges an existing parseable Omarchy menu after backing it up. It leaves comment-bearing JSONC unchanged. It does not register login startup or a background service, but a tray-enabled running app continues receiving when its window is hidden. Quit is distinct from closing X and waits for the worker; pending sends block quitting until a result. No automatic reconnect is implemented. [S5] [S11]

The installer is not transactional, does not remove obsolete modules during upgrades and provides no rollback/uninstaller command. Manual uninstall must cover launchers, the application folder, desktop entry, icon and whichever menu group was actually used: the README's kirk.phonebridge example does not cover the installer's apps.phonebridge/default or custom-group choices. Local JSON settings and menu backups are separate retained data. Uninstalling app files does not revoke Bluetooth pairing or phone permissions; revoke those separately if retiring access. [S1] [S11]

Before adopting: test a clean pairing and recovery on the intended phone/adapter, compare long received texts privately, check both accepted and uncertain send outcomes against the phone, verify tray shutdown, and test clean install/upgrade/uninstall. These are recommendations, not tests performed for this review.

## Supply Chain, Licensing and Maturity

- Public metadata at retrieval: **2 stars, 0 forks, 0 open issues**, last push **2026-11-24T02:32:50Z**. The reviewed commit timestamp is **2026-11-24T02:32:43Z**. Popularity and issue count do not establish quality. [M1]
- Commit subject and package constant call this **0.1.0-alpha.1**, but the public release API returned an empty list and anonymous tag enumeration found no tags. It is an untagged source snapshot, not a verified published release artifact. [S13] [M2]
- No tracked GitHub Actions workflows were present; the public runs API returned zero runs. Thirteen unittest files cover send safety, mocked Bluetooth/setup, local state, links, history and tray/placement behavior. They were inspected, **not executed**. Mocked tests cannot establish iOS compatibility or actual delivery. [S14] [M3]
- **Concrete packaging defect:** scripts/package.py's explicit top-level allowlist omits composer.py, synthwave.py, linkpreview.py and theme.py, which the desktop/installer now require. Its nonrecursive assets scan also excludes assets/fonts and their notices. The source archive generated by that recipe would be incomplete; this follows from literal file lists, without executing the packager. Use of an allowlist is a good privacy pattern, but it needs an import/manifest completeness test. [S5] [S11] [S13]
- README/release/testing documents lag one another: the README still says no public repository exists, and the acceptance plan says exact device/iOS is unconfirmed although README names a tested version. Many full-body, tray, first-pairing and keyboard checks remain explicitly pending. Treat the single-setup working claim as author report. [S1] [S14] [S15]
- MIT permits reuse of original code with copyright/license notice preservation; font OFL terms and dependency licenses remain separate. No source was extracted into this review. No signed release, provenance attestation, dependency audit or reproducible-build evidence was established. [S16]

## Comparison

Alternative descriptions below are their public documentation claims checked on the review date, not independent tests or a security endorsement.

| Aspect | PhoneBridge | BlueFerry | iphonebridge |
|--------|-------------|-----------|--------------|
| Main shape | Small GTK app, one Bluetooth worker | Direct-Bluetooth backend with GTK/KDE/Quickshell/terminal clients | Historical direct-Bluetooth bridge |
| State/scope | Session texts, private JSON metadata; one recipient | Claims encrypted local history, contact sync and cautious group support | README says archived and directs users to BlueFerry |
| Operational fit | Narrow experimental personal workflow | First candidate to investigate for broader Linux integration | Reference, not a new deployment recommendation |

[BlueFerry](https://github.com/erikwb/blueferry) documents no Mac/cloud relay and explicitly warns that iOS behavior can change; its broader feature set comes with a larger integration/state surface. [iphonebridge](https://github.com/gabrielmeir53/iphonebridge) identifies BlueFerry as the continuing project. PhoneBridge's useful distinction is its smaller scope and MIT-original-code licensing, not that direct Bluetooth messaging is unique. [A1] [A2]

## Verification Results and Limits

Anonymous acquisition and canonical-source search found no prior review for this repository/scope, so this is a new review. Static inspection covered the principal runtime modules, setup/permission helpers, installer/package recipe, license/font notices, test sources and acceptance documentation. No application unit tests, compilation/imports, package builds, installs, live network-preview probes, phone access or desktop acceptance tests were performed. No private source or user data was used. Hardware behavior, delivery, forced-kill cleanup and third-party safety remain unverified.

Review artifacts were checked for matching provenance/verdict/index links, complete trusted-template substitution, unchanged template JavaScript/CSS except its verdict token, safe markup/link structure, and task-only public content. These publication checks do not raise the application's maturity rating.

## Evidence

All S citations are pinned to the reviewed commit; M/A endpoints are mutable metadata/documentation observed 2026-11-24 UTC.

[S1]: https://github.com/CodeFu72/phonebridge/blob/52d80947ed0e6265f5fb8505fc45fb63c564d8fb/README.md
[S2]: https://github.com/CodeFu72/phonebridge/blob/52d80947ed0e6265f5fb8505fc45fb63c564d8fb/bridge.py
[S3]: https://github.com/CodeFu72/phonebridge/blob/52d80947ed0e6265f5fb8505fc45fb63c564d8fb/connect_phone.py
[S4]: https://github.com/CodeFu72/phonebridge/blob/52d80947ed0e6265f5fb8505fc45fb63c564d8fb/request_access.py
[S5]: https://github.com/CodeFu72/phonebridge/blob/52d80947ed0e6265f5fb8505fc45fb63c564d8fb/app.py
[S6]: https://github.com/CodeFu72/phonebridge/blob/52d80947ed0e6265f5fb8505fc45fb63c564d8fb/theme.py
[S7]: https://github.com/CodeFu72/phonebridge/blob/52d80947ed0e6265f5fb8505fc45fb63c564d8fb/history.py
[S8]: https://github.com/CodeFu72/phonebridge/blob/52d80947ed0e6265f5fb8505fc45fb63c564d8fb/send_test.py
[S9]: https://github.com/CodeFu72/phonebridge/blob/52d80947ed0e6265f5fb8505fc45fb63c564d8fb/model.py
[S10]: https://github.com/CodeFu72/phonebridge/blob/52d80947ed0e6265f5fb8505fc45fb63c564d8fb/linkpreview.py#L16-L99
[S11]: https://github.com/CodeFu72/phonebridge/blob/52d80947ed0e6265f5fb8505fc45fb63c564d8fb/scripts/install.py
[S12]: https://github.com/CodeFu72/phonebridge/blob/52d80947ed0e6265f5fb8505fc45fb63c564d8fb/alerts.py
[S13]: https://github.com/CodeFu72/phonebridge/blob/52d80947ed0e6265f5fb8505fc45fb63c564d8fb/scripts/package.py#L7-L22
[S14]: https://github.com/CodeFu72/phonebridge/tree/52d80947ed0e6265f5fb8505fc45fb63c564d8fb/tests
[S15]: https://github.com/CodeFu72/phonebridge/blob/52d80947ed0e6265f5fb8505fc45fb63c564d8fb/docs/TESTING.md
[S16]: https://github.com/CodeFu72/phonebridge/blob/52d80947ed0e6265f5fb8505fc45fb63c564d8fb/LICENSE
[M1]: https://api.github.com/repos/CodeFu72/phonebridge
[M2]: https://api.github.com/repos/CodeFu72/phonebridge/releases
[M3]: https://api.github.com/repos/CodeFu72/phonebridge/actions/runs
[A1]: https://github.com/erikwb/blueferry/blob/main/README.md
[A2]: https://github.com/gabrielmeir53/iphonebridge/blob/main/README.md

---

**Attribution:** CodeFu72/phonebridge, Kirk Fuson / EchoLine and contributors. MIT original code; bundled fonts under SIL OFL. This review is independent analysis, not an endorsement or an official Apple/Omarchy publication.
