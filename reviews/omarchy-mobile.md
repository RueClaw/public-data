# Omarchy Mobile (derekross/omarchy-mobile)

**Repo:** https://github.com/derekross/omarchy-mobile
**Author:** Derek Ross and Omarchy Mobile contributors
**License:** MIT at repository root; GPL-2.0 kernel/DT material, Apache-2.0 boot-control code, GPL-3.0-or-later keyboard material and separately licensed dependencies also apply. Not an all-MIT OS image.
**Reviewed:** 2026-10-20 (UTC)
**Revision:** f1885a79a1709c8387ad32798c00cfc8f16afabd (main; committed 2026-10-20T02:06:22Z).
**Scope:** Repository documentation, descriptors, installer/rootfs/initramfs, selected shell/service/package implementations and test definitions. External kernel and application repositories were not audited.
**Verification:** Static review only. No source scripts, tests, builds, installers or hardware experiments run. Hardware results below are project-reported, not independently reproduced.
**Stack:** Arch Linux ARM, patched mainline Linux, Hyprland, Omarchy/Quickshell QML, JavaScript, Bash, Python, C, systemd, D-Bus, PipeWire and libcamera; external Rust/GTK camera app.
**What it is:** A native Linux phone bring-up and distribution-integration project, primarily for Pixel 7 Pro—not a desktop touch theme, Android launcher or finished smartphone OS.

---

## Verdict

⚠️ **Interesting — a substantial pocket-computer prototype, not a daily-driver phone.** Real integration goes well beyond a mockup: constrained flashing, a touch shell, rotation services, hardware bridges and package tooling. Untested cellular service, high standby draw, partial audio/cameras and developer-oriented security rule out a primary-phone recommendation. Worth studying or experimenting with on a backed-up spare Pixel 7 Pro, with recovery expertise.

## What It Is

Arch Linux ARM boots directly on a Pixel using a patched mainline kernel, with Omarchy packages and a phone-oriented shell profile. Android stays in the other boot slot as a recovery route, but shares the userdata partition that installation erases. Waydroid is a later goal, not demonstrated Android-app compatibility.

The [device matrix](https://github.com/derekross/omarchy-mobile/blob/f1885a79a1709c8387ad32798c00cfc8f16afabd/docs/DEVICES.md) separates works, testing, built and WIP. That is unusually useful documentation, but still maintainer evidence rather than certification. A descriptor or successful build does not imply usable hardware support.

## Stack

| Layer | Technology and responsibility |
|---|---|
| Boot/hardware | Device descriptors, Android-format boot images for Tensor phones, initramfs/storage guard, external patched kernel |
| Distribution | Arch Linux ARM root image; pacman precedence: omamobile, Omarchy, Arch Linux ARM |
| Session/UI | Hyprland, Omarchy plugins, Quickshell/QML, squeekboard, user setup and systemd |
| Hardware services | AoC sensor proxy, GeoClue, PipeWire/libcamera, vendor chroots, fprintd bridge, SIT modem client and ModemManager-compatible API |
| Build/install | Bash, Docker/aarch64 builder, PKGBUILDs, firstboot configuration, firmware extraction |

## Actual Device Compatibility

These are **upstream reports at the reviewed revision**, not our hardware tests.

| Device | Implemented/reported state | Not established |
|---|---|---|
| Pixel 7 Pro / cheetah | Main target: 120 Hz display, GPU, touch/buttons, USB networking, Wi-Fi, Bluetooth audio, charging, sensors/rotation, GNSS, NFC, opt-in fingerprint | Cellular registration/SMS/data/calls; production standby; polished audio/cameras |
| Pixel Fold / felix | Community bring-up: cover-screen simplefb console, USB networking, guarded storage | Usable touch desktop, GPU, inner display/folding and most hardware |
| Pixel 6 / oriole | Descriptor and boot images built | Matrix says not yet booted |
| Pixel 4 / flame | Temporary read-only RAM probe and separate software-desktop payload; touch/PIN and scan-level Wi-Fi tests reported | Installer parity, normal accelerated desktop, Wi-Fi association and mature phone support |
| Other Pixels | Wishlist/starting points | Brand or Tensor family does not imply compatibility |

The cheetah modem boots firmware and answers IPC, but the matrix explicitly says no SIM test has happened. A ModemManager-shaped API and Calls/Chatty integration do not prove calls, SMS, data or emergency calling. Four cameras have image paths, but telephoto focus is unresolved and quality is basic. Audio is quiet/thin with occasional static. Sources: [README](https://github.com/derekross/omarchy-mobile/blob/f1885a79a1709c8387ad32798c00cfc8f16afabd/README.md), [matrix](https://github.com/derekross/omarchy-mobile/blob/f1885a79a1709c8387ad32798c00cfc8f16afabd/docs/DEVICES.md).

## Key Features

### A genuine mobile session

The [shell package](https://github.com/derekross/omarchy-mobile/blob/f1885a79a1709c8387ad32798c00cfc8f16afabd/packages/omamobile-shell/README.md) provides status bar, quick settings, home pages/widgets, drawer, recent-app switcher, permission sheet, keyboard controls and fingerprint UI. [phone.lua](https://github.com/derekross/omarchy-mobile/blob/f1885a79a1709c8387ad32798c00cfc8f16afabd/packages/omamobile-shell/hypr/phone.lua) maximizes ordinary windows, handles power/volume/screenshot gestures and arranges keyboard/fingerprint surfaces above the session lock. The session auto-logs in then requests a lock when configured: not boot-time encryption, and lock startup/failure behavior needs adversarial testing.

[Sensor integration](https://github.com/derekross/omarchy-mobile/blob/f1885a79a1709c8387ad32798c00cfc8f16afabd/packages/omamobile-sensors/README.md) adapts AoC sensors to the iio-sensor-proxy D-Bus API and transforms both display and touchscreen during rotation. That avoids the obvious input-coordinate mismatch. Full-screen placement does not make every desktop application touch-friendly.

### Power remains a practical blocker

The matrix reports 31/31 Wi-Fi-connected s2idle cycles, but screen-off suspend is not on by default. Reported screen-off consumption is **434 mA awake, 312 mA in s2idle, versus 32–50 mA in stock deep sleep**. Deep sleep is not started. These are project measurements, not independently controlled benchmarks or a universal battery-life estimate. Charging has a temperature guard; USB Type-C/role switching remains unfinished. Screen-off is not phone-grade standby.

### Widget approvals are not OS isolation

OWL exposes command, HTTP, file and Linux-adapted device sources. [OwlPhoneHost.qml](https://github.com/derekross/omarchy-mobile/blob/f1885a79a1709c8387ad32798c00cfc8f16afabd/packages/omamobile-shell/plugins/omamobile.home/OwlPhoneHost.qml) checks approvals/network settings and executes commands through timeout and bash -c in the user's session. Network classification uses command capability analysis, not a separate network namespace. Approval sheets and risk heuristics therefore should not be sold as strong isolation for hostile code. Approved widgets exercise user authority; AI-created or arbitrary QML widgets require code-review-level trust.

Limits and conformance fixtures are good engineering, but output truncation is not a full process/memory sandbox. Widget web requests and optional location-based weather disclose data to selected services. The README describes an AI-agent chooser with no agent preinstalled; provider credentials, terms and costs remain separate choices.

## Architecture

This is an integration layer around moving upstreams, not one self-contained app. Descriptors feed build/flash tooling; rootfs construction installs regular and patched packages; firstboot creates the owner and enables services; shell packages seed per-user profiles. Hardware bridges expose standard desktop interfaces where possible.

The design is coherent but maintenance-heavy: patched Mesa/Hyprland/libcamera, Omarchy patch reapplication, external kernel, vendor firmware and separate omacam versions must remain compatible. [pacman.conf](https://github.com/derekross/omarchy-mobile/blob/f1885a79a1709c8387ad32798c00cfc8f16afabd/rootfs/pacman.conf) gives mobile packages precedence and requires package signatures (database signatures optional; local-file signatures optional). [omacam's PKGBUILD](https://github.com/derekross/omarchy-mobile/blob/f1885a79a1709c8387ad32798c00cfc8f16afabd/packages/omacam/PKGBUILD) pins an archive checksum and locked Cargo fetch/offline build. Good hygiene does not prove whole-OS reproducibility or security.

## Installation, Recovery and Operational Fit

This is an unlocked-phone firmware/root-image workflow, not a casual desktop add-on. The documented host needs Arch/Omarchy, Docker, android-tools and e2fsprogs, plus the owner's factory image. Nothing was installed for this review.

[install-phone](https://github.com/derekross/omarchy-mobile/blob/f1885a79a1709c8387ad32798c00cfc8f16afabd/tools/install-phone) parses descriptors as restricted data instead of sourcing shell, checks one fastboot device, codename, unlocked status, matching bootloader-slot versions, checksums and some kernel/module consistency. Bundle mode checks a signed checksum manifest against a pinned fingerprint unless explicitly allowed unsigned. A narrow flash function accepts descriptor-approved slot-B boot images and userdata, gated by typed codename. These are meaningful safeguards, not authentication of an untrusted installer itself; repository mode and signed-bundle verification differ.

**Installation erases userdata, including Android data.** Slot A boot images survive, but Android needs a factory reset on return. The [reinstall runbook](https://github.com/derekross/omarchy-mobile/blob/f1885a79a1709c8387ad32798c00cfc8f16afabd/device/cheetah/REINSTALL-RUNBOOK.md) documents recovery and one clean reinstall on 2026-10-13, including subsequently fixed missing firmware/services. This is not transactional installation or nondestructive uninstall. Old userdata survives only in backups. The generic installer refuses non-android-v4 boot methods: do not apply cheetah instructions indiscriminately to Pixel 4 probes.

The installer's narrow write scope is not a blanket no-sensitive-writes guarantee. The [matrix](https://github.com/derekross/omarchy-mobile/blob/f1885a79a1709c8387ad32798c00cfc8f16afabd/docs/DEVICES.md) says boot-success marking writes slot flags in devinfo; fingerprint startup writes Trusty secure storage/RPMB. Fingerprint is appropriately opt-in and the runbook calls that step irreversible. These lifecycle exceptions qualify the README's broad partition-safety language.

## Security, Privacy and Permissions

- **Boot/data protection:** unlocked bootloader; inspected [initramfs](https://github.com/derekross/omarchy-mobile/blob/f1885a79a1709c8387ad32798c00cfc8f16afabd/initramfs/init) directly mounts an ext4 root, with no encrypted-root unlock flow found in that path. A PIN/session lock is not Android-equivalent at-rest protection or verified boot. Full hardening was not audited.
- **Credentials:** installer uses SHA-512 crypt, restrictive firstboot-file permissions and normal-exit cleanup of temporary config/image copies. Wi-Fi secrets temporarily reside in provisioning data. This is not secure-erasure proof after crashes. Any nonempty PIN/password is accepted; choose a strong one.
- **SSH/firewall:** [firstboot](https://github.com/derekross/omarchy-mobile/blob/f1885a79a1709c8387ad32798c00cfc8f16afabd/packages/omamobile-firstboot/bin/omamobile-firstboot) installs the supplied public key for root and owner; its SSH drop-in disables password authentication. It allows SSH on USB but also **TCP/UDP 53317 without interface restriction**, and permits outbound traffic. USB-only SSH does not mean every inbound service is USB-only. Verify actual listeners/rules.
- **Mirroring:** [wayvnc integration](https://github.com/derekross/omarchy-mobile/blob/f1885a79a1709c8387ad32798c00cfc8f16afabd/packages/omamobile-mirror/README.md) is on-demand, USB-bound, session-scoped and has no password by default; optional password/RSA-AES is available. An active mirror grants screen/input access to the connected host. Do not assume authenticated encryption by default; runtime binding/firewall behavior was not tested.
- **Permissions:** portal consent improves portal-aware apps, not isolation of every native app or direct hardware access. Sensor docs permit any local user to claim gyro data. Vendor chroots, firmware and fingerprint bridge add privileged attack surface despite the mainline-kernel label.
- **Network/privacy:** GNSS assistance options, widget endpoints, NFC-opened links and ordinary native applications create network boundaries to assess. No traffic instrumentation or exhaustive daemon/parser/polkit/dependency audit was performed.

## Tests, CI and Maturity

[tests/all](https://github.com/derekross/omarchy-mobile/blob/f1885a79a1709c8387ad32798c00cfc8f16afabd/tests/all) defines syntax checks, fake-fastboot installer tests, provisioning tests, initramfs/storage-guard/image-layout tests, firstboot checks and optional rootfs smoke tests. Package suites cover shell models, permissions, launch and widgets; OWL includes conformance/rendering fixtures. **None ran here**: test existence does not establish current pass status or hardware safety. No tracked GitHub Actions workflow was found at this SHA.

GitHub metadata retrieved 2026-10-20: created 2026-10-12, last push 2026-10-20T02:06:23Z, **140 stars, 20 forks, 9 open issues/PRs combined**. The releases endpoint returned an empty list. Bundle tooling does not establish a published stable release. An open PR addresses Omarchy-version/pacman migration compatibility ([#19](https://github.com/derekross/omarchy-mobile/pull/19)); unmerged proposals are not implemented support. Popularity is not a support lifetime or safety guarantee.

Documentation is candid but snapshots lag: the historical OWL review document retains pre-phone/staging language while current README describes shipped built-ins; camera narratives also advance at different rates. Prefer exact revisions, package versions and linked hardware gates. External kernel implementation, emergency calling, long-term reliability, accessibility, lock robustness and restore success were not independently verified.

## Comparison

| Option | Best fit | Tradeoff |
|---|---|---|
| Omarchy Mobile | Omarchy/Arch enthusiasts developing Pixel 7 Pro hardware/UI | Cohesive desktop reuse; very young, narrow support, cellular unverified |
| postmarketOS / Phosh-based Linux | Wider mobile-Linux port research and mobile-first UI | Exact device/subsystem tables still govern; not a promise for this Pixel |
| [Plasma Mobile](https://plasma-mobile.org/) | KDE mobile shell/apps on supported distributions/devices | Shell ecosystem, not automatic hardware enablement |
| Stock Android or a supported Android distribution | Reliable daily phone and Android apps | Different openness/control tradeoffs; verify device/security support |

Architectural comparison only, not a tested head-to-head benchmark. Do not buy hardware assuming equal support across these options.

## Adoption Gate

Before primary-phone use: reproduce cellular registration/SMS/data/call audio and state emergency-call limitations; establish safe suspend/charging and standby life; validate backups and full Android restoration; test session-lock/permission failures; audit privileged bridges/network defaults; demonstrate repeatable upgrades across patched packages. Until then: spare-device experimentation or study.

---

**Attribution:** [derekross/omarchy-mobile](https://github.com/derekross/omarchy-mobile), Derek Ross and contributors. Root MIT with file-specific/dependency exceptions above. Analysis only; no firmware or implementation extraction.
