# Omarchy on Amazon Fire HD 10 (Cesarus85/omarchy-amazon-fire-hd10)

**Repo:** https://github.com/Cesarus85/omarchy-amazon-fire-hd10
**Author:** Stefan Maier / Cesarus85; upstream contributors credited; OpenAI Codex assistance disclosed.
**License:** GPL-2.0-only for new glue/documentation; component-specific GPL, MIT and Apache-2.0 terms (see NOTICE).
**Reviewed:** 2026-11-23 (UTC)
**Revision:** a744f8eec8ddb6f85d942aa59f47dbef01d22d56 (main, committed 2026-11-22); scope: repository documentation, build/installer, boot, runtime access configuration, packaging, CI and selected tests—not every vendored driver line.
**Verification:** Static review only. Public CI reports success for this SHA; no source tests, builds, installer, device access or flashing were run for this review.
**Stack:** Linux ARM64, Arch Linux ARM, Hyprland, Omarchy, C kernel drivers, Python/Bash, QML/Lua, systemd and pacman.
**What it is:** An independent native Linux hardware port for a narrowly specified Fire tablet, not an Android theme, remote desktop client or official Omarchy/Amazon product.

---

## Verdict

📚 **Study — substantial native-port engineering, not a consumer installation recommendation.** The repository contains real kernel/device-tree adaptations, tablet UI integration and unusually explicit destructive-install safeguards. However, the clean installer has not completed physical acceptance on a second tablet, storage is unencrypted, and recovery/bootloader prerequisites exclude arbitrary Fire HD 10 devices. Suitable for experienced port developers with expendable, already-compatible hardware—not a daily-use tablet containing important data.

## What It Is

The README explicitly describes Linux running directly on the tablet. That claim is supported structurally by a Linux patch/configuration, board DTS, external drivers, Android-format boot-image builder, native ext4 initramfs and systemd runtime—not inferred from its name. Physical functionality is still author-reported rather than independently reproduced here. The project explicitly disclaims official Amazon, Arch Linux ARM and Omarchy affiliation. [1][2]

The reference device evolved from an Android-userdata loop image to native partition 18. The published boot contract targets the latter; it cannot boot the old loop-root layout. The clean installer is separate from that successful incremental bring-up. There is no universal public ready-to-flash root image. [1][3]

## Compatibility and evidence

| Boundary | Supported claim / limitation |
|---|---|
| Device | Fire HD 10 (2021), 11th generation, Trona, MediaTek MT8183; 32-GB reference unit |
| Installer | Exact stock 21-partition geometry, already unlocked compatible boot chain, TWRP 3.7.0_9-0, root ADB, one connected device, battery at least 50% |
| Exclusions | Other generations, Fire HD 8/Max 11, 64-GB layouts, modified or already-native layouts; alternate camera sensors unverified |
| Firmware | Four original radio files must match repository SHA256 values; preserve the device's own calibration/identity. No complete supported Fire OS build-number matrix is supplied |
| Qualified software | Linux 6.18.56-trona-arch14; Omarchy/settings 4.5.0-3; Hyprland 0.57.2-1; Quickshell 0.3.2.r7.g2b4501a-1; libcamera family 0.7.2-4 |
| Actual package manifest | platform/PKGBUILD says 2026.11.22-10; docs/updates.md still lists 2026.11.17-10—small but concrete documentation drift |

The linked amonet-koboreru prerequisite is a separate high-privilege boot-chain exploit, not an installer feature. Its current README warns that newer Preloaders were patched around 2022 and that damage to boot-chain partitions can hard-brick a device. This review does **not** establish that a particular Fire OS version can safely be unlocked or downgraded. Treat eligibility as unresolved until independently checked against exact hardware/firmware, not as permission to follow a generic flashing recipe. [3][4][5]

The author reports native boot, eight CPU cores, display/touch, Panfrost, rotation, Wi-Fi, a paired Bluetooth keyboard, speakers, cameras, SD mounting, s2idle and wake/lock on one reference tablet. Hardware documentation explicitly leaves deep firmware suspend, long-term battery/thermal behavior, charger coverage, Bluetooth audio, headphone jack and alternate sensors incomplete. Display scanout still depends on LK initialization; this is not a finished native DSI panel implementation. Experimental hardware video decode is disabled in normal builds and lacks long-run/standby qualification. [2][4]

## Stack and architecture

| Layer | Implementation |
|---|---|
| Boot | Preserved Amazon/LK/recovery chain; Android header-v1 Image.gz + DTB + XZ initramfs |
| Kernel | Linux 6.18.56 patch set, arch14 configuration, 28-module inventory, MediaTek/Amazon-derived connectivity and board drivers |
| Graphics/media | SimpleDRM/boot framebuffer, Mesa Panfrost, Hyprland; libcamera software ISP for cameras |
| Desktop | Omarchy/Quickshell, patched wvkbd, QML session-lock keyboard, Lua/window and Python/shell helpers |
| Packaging | Device-rendered trona-platform pacman package, ALPM hooks, boot/integration integrity checks |
| Installer | Python standard library controller, ADB recovery transport, ARM64 Docker build/chroot, pure-Python GPT planner |

Boot verifies root UUID and size, marks other partitions read-only, checks ext4 and switches to systemd; failure waits rather than opening an unauthenticated emergency shell. This is useful accident containment, not verified boot against a malicious root or physical attacker. [2][6]

The installer separates prepare/build/verify/install. Preparation captures both GPTs and the original first 200 MiB, extracts firmware read-only with journal replay disabled, and creates a unique root UUID. The planner validates CRCs, exact partition names/types/bounds/capacity and preserves entries 1–17. Installation requires a serial-specific erase confirmation, rechecks the device, freezes recovery UI, refuses mounted/held storage, writes backup GPT before primary, verifies root readback, checks/resizes ext4, checks protected partitions and writes boot last. Atomic, fsynced stage records and explicit resume checks are strong design choices. They do not make a multi-stage flash atomic or power-loss-proof. [7]

## Permissions, security and privacy

- **Local authentication:** QML uses a real Wayland session lock and PAM, not a hard-coded PIN. PAM includes failure throttling; sudo requires the trona account password. Provisioning removes default alarm credentials and locks root's password. Serial console uses normal login, not autologin. The compositor/session runs as trona, with device-access groups; this is a privileged personal desktop, not a multi-tenant isolation design. [8]
- **Remote maintenance:** Optional supplied public key is installed for **root** SSH. The SSH drop-in specifies USB link-local IPv4/IPv6 listen addresses and disables password/keyboard-interactive authentication. Clean build enables sshd only when a key is supplied. Root-password locking does not disable key-based root access. Confirm effective sshd configuration after any changes; these source settings are not a live listener/firewall audit. [8]
- **Physical boundary:** Bootloader remains unlocked, TWRP remains accessible and root storage is **not encrypted**. Recovery can read or modify files regardless of the desktop password; hash guards are not an independent trust anchor. Do not use it for sensitive data on the assumption that the screen lock protects storage. [9]
- **Proxy/egress:** Native WLAN is normal networking. Optional rescue proxy explicitly opts in environment variables and relays loopback TCP to a configured USB link-local host; there is no proxy authentication or TLS added by the relay. The host is therefore a trust boundary. No project telemetry/upload endpoint was identified in the reviewed installer/access paths; this is not an audit of browsers, upstream packages or all vendored code. [8][9]
- **Private build material:** Preparation stores device identifiers, original protected partitions and calibration; bundles contain firmware and a password hash. The wizard uses a restrictive umask/private workspace, accepts only a public-key format and strips its comment, and passes the password to Docker stdin rather than an argv flag. Neither ignored files nor containers make these artifacts safe to publish. Protect the workspace, Docker storage and backups; never attach them wholesale to issues. No tablet credentials were supplied or used in this review. [7][9]
- **Host privilege caveat:** The build uses Docker **--privileged**, root chroots and pseudo-filesystem mounts. Absence of an explicit tablet mount does not turn privileged Docker into a security sandbox, especially on a native Linux daemon. Use a dedicated build VM/host if evaluating it later. Docker/build dependencies and all executed upstream code must be trusted. [7]

## Installation changes, persistence and rollback

This section describes effects; it is not a flashing guide. The host needs Python 3.10+, Git, ADB and an ARM64-capable Docker engine, internet and at least 25 GiB free in both relevant storage locations. Builds download packages/sources, create a Docker image, named volume/container and private local artifacts; the volume persists even after successful container cleanup. Failed builds retain diagnostic state. There is no host service installation in the inspected wizard; installing prerequisites is a separate administrative action. [3][7]

The final tablet install deliberately erases Android system/vendor/cache/userdata and replaces partitions 18–21 with about 28.93 GiB native Linux storage, plus a new boot image in p16. The protected-area capture is **not** an Android/user-data backup. An adopted/encrypted SD card can become unreadable after Android keys are lost even though the SD card is not written. Preserving recovery reduces risk; an interrupted GPT or boot write can still leave an unbootable device requiring expert repair. External unlocking carries separate hard-brick risk. [3][5][7]

Persistence includes a native rootfs, platform files, system services for desktop/boot guard/radios/battery/power/USB networking, user services for rotation/keyboard/window fit/SD helper, PAM/SSH/sudoers settings and pacman hooks. Qualified package pins and patch restoration deliberately constrain rolling upgrades. The guard blocks generic kernel/bootloader payloads and ordinary removal of trona-platform. This is ongoing maintenance commitment, not a removable desktop theme. Pinned versions also require timely security qualification. [10]

No complete one-click uninstall, stock-Android restoration or automatic transaction rollback is supplied. Resume accepts only known saved old/new GPT and boot states, restarts the root write from zero, and refuses completed installs or unknown/torn boot states. Restoring the old GPT cannot recover overwritten Android data. Recovery requires the same private workspace, functioning recovery access and appropriate independently preserved originals; a factory reset is not an undo button. Host cleanup should target only the recorded container/volume and chosen private files, not global Docker pruning. [3][7][10]

## Supply chain and license

Strengths: kernel/rootfs/keyring/firmware hashes are recorded, the Omarchy key fingerprint is checked, package signature verification remains enabled, sensitive desktop packages are exact-version gated, original component notices and upstream revisions are listed. Firmware is not bundled publicly. [11]

Limits: Ubuntu container tags and apt package versions are not immutable snapshots; wvkbd is cloned by tag v0.16 rather than verified commit/hash; CI actions use major-version tags; remaining Arch packages roll. A checksum pin on an upstream “latest” rootfs stops drift but can also make a future build unavailable. Local manifests detect accidental changes, not malicious replacement of both files and manifests. These are not fully hermetic, reproducible current arch14 builds: documentation distinguishes arch12 bit-identical results from arch14's lack of independent clean-build reproduction. [11][12]

The root GPLv2 text is not the entire licensing story. NOTICE marks new glue/documentation GPL-2.0-only, retains component-specific GPL/MIT and Apache-2.0 notices, and includes Omarchy/wvkbd/TECHO5 license files. Respect corresponding-source and notice obligations when distributing modifications; stock firmware has a separate redistribution question. This review extracts no implementation code or firmware. [13]

## Maturity and verification

Public GitHub metadata retrieved 2026-11-23: created 2026-11-15; last push 2026-11-22; 0 stars, 0 forks, and no returned open/closed issues in the public issues query. These are age/activity signals, not safety evidence. Latest published release is **v0.2.0-alpha.1**, an experimental installer prerelease dated 2026-11-15; v0.1.0 is also marked prerelease. Reviewed main is newer than those releases. [14]

The exact-SHA [Source checks run](https://github.com/Cesarus85/omarchy-amazon-fire-hd10/actions/runs/45053187176) reports **success**. Workflow inspection shows source/profile/update/installer/rotation and UI policy tests, GTK dialog tests under Xvfb, a real WLAN function test and SCP proxy emulation. Installer tests use generated GPTs/mocks, not physical flashing. Author validation separately records 16 installer tests, an offline filesystem/package build, original kernel reproduction, and physical reference-device checks. These are useful evidence with different scopes—not independent clean-install acceptance. [12][15]

**Review actions:** read public documentation, installer/planner/build/provisioning code, boot/auth/network configuration, package manifest, workflow and selected tests/evidence; checked unauthenticated GitHub metadata/releases/CI. No repository code executed, no dependencies installed, no containers started, no live network/service probes, no tablet/desktop access, and no hardware compatibility or full kernel security audit. Source CI success is reported evidence, not a locally rerun test. Publication markup/diff/link checks are separate from product testing.

## Comparison and operational fit

| Option | Benefit | Tradeoff |
|---|---|---|
| This native Trona port | Real ARM Linux kernel/Wayland stack and deep tablet integration | Destructive migration, narrow prerequisites, one-device evidence and no encrypted root |
| Keep stock Fire OS | Avoid this port's repartitioning/unlock workflow | No native Arch/Hyprland stack; stock support/security lifespan still needs checking |
| Remote desktop from the existing tablet | Linux workload remains on a supported computer; no native-port flash needed | Network latency, remote credentials and client/platform compatibility; not offline native Linux |
| Android-hosted Linux userspace where supported | Explore CLI/userland without replacing the kernel | Android/Fire OS restrictions and application compatibility; not proof of Hyprland/device-driver support |
| Purpose-built Linux-capable hardware | Choose a documented boot/recovery and hardware-support path | Additional hardware cost; not an automatic endorsement of any particular model |

**Recommendation:** read the architecture and guarded-install design as a hardware-port case study. Consider hands-on evaluation only after a reproducible second-device clean install, exact firmware/unlock eligibility and a separately rehearsed recovery/data-preservation plan are established. For ordinary Linux access, keeping the tablet's existing OS and using a supported host is the lower-storage-risk approach.

## Evidence

All repository file links below are pinned to the reviewed SHA; external prerequisite and metadata links were retrieved 2026-11-23.

[1] [README.md](https://github.com/Cesarus85/omarchy-amazon-fire-hd10/blob/a744f8eec8ddb6f85d942aa59f47dbef01d22d56/README.md)

[2] [docs/architecture.md](https://github.com/Cesarus85/omarchy-amazon-fire-hd10/blob/a744f8eec8ddb6f85d942aa59f47dbef01d22d56/docs/architecture.md)

[3] [docs/installer.md](https://github.com/Cesarus85/omarchy-amazon-fire-hd10/blob/a744f8eec8ddb6f85d942aa59f47dbef01d22d56/docs/installer.md), [docs/install.md](https://github.com/Cesarus85/omarchy-amazon-fire-hd10/blob/a744f8eec8ddb6f85d942aa59f47dbef01d22d56/docs/install.md)

[4] [docs/hardware.md](https://github.com/Cesarus85/omarchy-amazon-fire-hd10/blob/a744f8eec8ddb6f85d942aa59f47dbef01d22d56/docs/hardware.md), [firmware/required.json](https://github.com/Cesarus85/omarchy-amazon-fire-hd10/blob/a744f8eec8ddb6f85d942aa59f47dbef01d22d56/firmware/required.json), [platform/PKGBUILD](https://github.com/Cesarus85/omarchy-amazon-fire-hd10/blob/a744f8eec8ddb6f85d942aa59f47dbef01d22d56/platform/PKGBUILD)

[5] [amonet-koboreru prerequisite README](https://github.com/R0rt1z2/amonet-koboreru#readme)

[6] [boot/init.template](https://github.com/Cesarus85/omarchy-amazon-fire-hd10/blob/a744f8eec8ddb6f85d942aa59f47dbef01d22d56/boot/init.template)

[7] [installer/trona-installer.py](https://github.com/Cesarus85/omarchy-amazon-fire-hd10/blob/a744f8eec8ddb6f85d942aa59f47dbef01d22d56/installer/trona-installer.py), [installer/layout.py](https://github.com/Cesarus85/omarchy-amazon-fire-hd10/blob/a744f8eec8ddb6f85d942aa59f47dbef01d22d56/installer/layout.py), [installer/build.sh](https://github.com/Cesarus85/omarchy-amazon-fire-hd10/blob/a744f8eec8ddb6f85d942aa59f47dbef01d22d56/installer/build.sh), [installer/provision.sh](https://github.com/Cesarus85/omarchy-amazon-fire-hd10/blob/a744f8eec8ddb6f85d942aa59f47dbef01d22d56/installer/provision.sh), [installer/finalize-root.py](https://github.com/Cesarus85/omarchy-amazon-fire-hd10/blob/a744f8eec8ddb6f85d942aa59f47dbef01d22d56/installer/finalize-root.py)

[8] [platform/payload/etc/pam.d/omarchy-lock-password](https://github.com/Cesarus85/omarchy-amazon-fire-hd10/blob/a744f8eec8ddb6f85d942aa59f47dbef01d22d56/platform/payload/etc/pam.d/omarchy-lock-password), [platform/payload/usr/share/trona-platform/lock/trona-login.qml](https://github.com/Cesarus85/omarchy-amazon-fire-hd10/blob/a744f8eec8ddb6f85d942aa59f47dbef01d22d56/platform/payload/usr/share/trona-platform/lock/trona-login.qml), [platform/payload/etc/ssh/sshd_config.d/trona-usb.conf](https://github.com/Cesarus85/omarchy-amazon-fire-hd10/blob/a744f8eec8ddb6f85d942aa59f47dbef01d22d56/platform/payload/etc/ssh/sshd_config.d/trona-usb.conf), [platform/payload/etc/sudoers.d/00-trona-admin](https://github.com/Cesarus85/omarchy-amazon-fire-hd10/blob/a744f8eec8ddb6f85d942aa59f47dbef01d22d56/platform/payload/etc/sudoers.d/00-trona-admin), [platform/payload/usr/local/sbin/trona-usb-proxy-relay](https://github.com/Cesarus85/omarchy-amazon-fire-hd10/blob/a744f8eec8ddb6f85d942aa59f47dbef01d22d56/platform/payload/usr/local/sbin/trona-usb-proxy-relay), [platform/payload/etc/profile.d/trona-usb-proxy.sh](https://github.com/Cesarus85/omarchy-amazon-fire-hd10/blob/a744f8eec8ddb6f85d942aa59f47dbef01d22d56/platform/payload/etc/profile.d/trona-usb-proxy.sh)

[9] [docs/security.md](https://github.com/Cesarus85/omarchy-amazon-fire-hd10/blob/a744f8eec8ddb6f85d942aa59f47dbef01d22d56/docs/security.md)

[10] [docs/updates.md](https://github.com/Cesarus85/omarchy-amazon-fire-hd10/blob/a744f8eec8ddb6f85d942aa59f47dbef01d22d56/docs/updates.md), [platform/trona-platform.install](https://github.com/Cesarus85/omarchy-amazon-fire-hd10/blob/a744f8eec8ddb6f85d942aa59f47dbef01d22d56/platform/trona-platform.install)

[11] [installer/sources.json](https://github.com/Cesarus85/omarchy-amazon-fire-hd10/blob/a744f8eec8ddb6f85d942aa59f47dbef01d22d56/installer/sources.json), [installer/Dockerfile](https://github.com/Cesarus85/omarchy-amazon-fire-hd10/blob/a744f8eec8ddb6f85d942aa59f47dbef01d22d56/installer/Dockerfile), [userspace/wvkbd/build.sh](https://github.com/Cesarus85/omarchy-amazon-fire-hd10/blob/a744f8eec8ddb6f85d942aa59f47dbef01d22d56/userspace/wvkbd/build.sh), [CREDITS.md](https://github.com/Cesarus85/omarchy-amazon-fire-hd10/blob/a744f8eec8ddb6f85d942aa59f47dbef01d22d56/CREDITS.md)

[12] [docs/validation.md](https://github.com/Cesarus85/omarchy-amazon-fire-hd10/blob/a744f8eec8ddb6f85d942aa59f47dbef01d22d56/docs/validation.md)

[13] [NOTICE](https://github.com/Cesarus85/omarchy-amazon-fire-hd10/blob/a744f8eec8ddb6f85d942aa59f47dbef01d22d56/NOTICE), [LICENSE](https://github.com/Cesarus85/omarchy-amazon-fire-hd10/blob/a744f8eec8ddb6f85d942aa59f47dbef01d22d56/LICENSE)

[14] [Public metadata](https://api.github.com/repos/Cesarus85/omarchy-amazon-fire-hd10), [releases](https://github.com/Cesarus85/omarchy-amazon-fire-hd10/releases), [issues](https://github.com/Cesarus85/omarchy-amazon-fire-hd10/issues)

[15] [.github/workflows/check.yml](https://github.com/Cesarus85/omarchy-amazon-fire-hd10/blob/a744f8eec8ddb6f85d942aa59f47dbef01d22d56/.github/workflows/check.yml), [tests/test-installer.py](https://github.com/Cesarus85/omarchy-amazon-fire-hd10/blob/a744f8eec8ddb6f85d942aa59f47dbef01d22d56/tests/test-installer.py)

---

**Attribution:** Cesarus85/omarchy-amazon-fire-hd10; Stefan Maier and credited upstream contributors. GPL-2.0-only new glue/documentation; component-specific terms in NOTICE and LICENSES. Independent static analysis; no official affiliation implied.
