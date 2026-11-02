# Linux Subsystem for Windows (acceleration3/linux-subsystem-windows)

**Repo:** https://github.com/acceleration3/linux-subsystem-windows
**License:** Apache-2.0 for the root project; mixed bundled licenses and unresolved standalone submodule licensing (see below).
**Reviewed:** 2026-11-02 UTC
**Revision:** b8242f960cf5b9ec7ee4b7a1e8fb7af1a01113c0 (master); root application, provisioning, packaging, protocols, tests/CI and selected pinned component implementation.
**Component revisions:** accel-virt a9c01985cee76fa684d1666b39e9433128426c86; remotewin dce05c0234ea67a7c8239f71e1b584907dd71f18.
**Verification:** Static source review only. No source execution, build, application tests, VM installation, GPU benchmarks, binary inspection or OS/media downloads.
**Stack:** C++20/Qt 6, libvirt/QEMU/KVM, Wayland/KWin, Windows service, WDDM driver, Vulkan/DXVK/vkd3d-proton, virtio-fs/WinFsp.
**What it is:** Windows 11 applications in a Linux desktop, backed by a Windows VM and a custom paravirtual GPU. This is not Microsoft's Windows Subsystem for Linux.

---

## Verdict

⚠️ **Interesting — a serious experimental Windows-on-Linux integration, not a hardened daily-driver recommendation.** The split between VM management, per-application window mirroring and GPU command transport is substantive and unusually ambitious. Try only on a disposable, backed-up test setup: unauthenticated local control, plaintext guest credentials, weakened guest security defaults, stale CI and destructive reset behavior outweigh the convenience for sensitive work.

## What It Is

LSW installs a real Windows 11 guest, then presents its applications as separate Wayland windows. It does not translate the whole Windows OS like Wine and does not dedicate a physical GPU through VFIO passthrough. Windows APIs remain inside Windows; graphics work crosses a custom device to Linux graphics libraries. Applications still need their own installation, activation and licenses.

Canonical identity is acceleration3/linux-subsystem-windows, confirmed by public GitHub metadata, clone and README. A stale CMake HOMEPAGE_URL points elsewhere; that string does not establish another owner or affiliation. Both first-level submodules were publicly retrievable at their exact recorded commits. The open issue about inaccessible submodules is therefore not a current acquisition blocker.

## Stack

| Layer | Technology and role |
|---|---|
| Manager | C++20, Qt Widgets/Network/DBus/Concurrent/XML; user-session libvirt |
| VM | Patched QEMU, KVM, q35/OVMF, qcow2 NVMe disk, e1000e user-mode networking |
| Guest control | Windows service and per-session helpers; framed JSON RPC over TCP |
| Window integration | remotewin, Windows.Graphics.Capture, native Wayland surfaces and KWin placement |
| Graphics | accel-virt WDDM 3.2 driver and user-mode drivers; host Vulkan/EGL/OpenCL, DXVK and vkd3d-proton |
| Files/devices | virtio-fs plus virtio-win/WinFsp, SMB guest access, USB host-device attachment |
| Build | CMake/Ninja, mingw-w64, clang/LLVM, Python, meson; hash-pinned tarballs and some tag-pinned fetches |

## Key Features

### Separate application windows, not just a remote desktop

One host remotewin process owns an application's windows and popups. Keeping related surfaces in one process suits Wayland popup ownership. The managed launcher waits for LISTENING before starting the guest half and READY after the first frame: process creation is not confused with working display output. Application launch, file associations, shared folders, USB attachment and a full-desktop fallback are implemented rather than merely proposed. [1][2]

### Host-GPU execution without whole-device passthrough

Guest API drivers submit through shared-memory rings and device doorbells to a host executor. D3D11 and D3D12 use Linux-native DXVK/vkd3d-proton; Vulkan, OpenGL and OpenCL reach host drivers. The GPU name shown in Windows identifies the selected host GPU, not proof that Windows is running its vendor driver. In fact, vendor-driver replacement is a documented failure mode. [2][3]

### GPU-backed frame sharing with a fallback

Frames can be exported as dma-bufs and attached to Wayland buffers, with explicit synchronization and compositor-release ownership. The fallback sends pixel/tile updates over TCP. Avoid calling this universally zero-copy: capture, cross-adapter copies, compositing and fallback paths still matter. [2][4]

## Architecture

The manager provisions media, creates the libvirt domain, launches applications and updates the guest payload. The guest service dispatches framed JSON requests to handler classes; session helpers handle interactive Windows tasks. A header-only linkproto defines the shared wire contract. Window transport is separate from control RPC, and GPU commands use the paravirtual device rather than the agent TCP stream. [1][5]

The domain uses user-session libvirt, host CPU passthrough, shared memfd RAM, an NVMe system disk and QEMU user networking. It exposes host loopback forwards to guest agent ports and SMB. This avoids a system libvirt service requirement, but it is not a network-isolated or hostile-guest sandbox. [6]

**Important integration distinction:** accel-virt documents an optional av-renderer process for crash isolation. LSW's actual domain builder explicitly omits renderer= and runs the executor inside QEMU, because the libvirt seccomp sandbox denies spawning it. Do not credit LSW with that optional isolation. A driver/executor fault can therefore affect the VM process; seccomp does not itself prove malicious GPU commands safe. [7]

## Compatibility and Performance: Claims Versus Evidence

- README offers D3D11 through feature level 12_1, Vulkan 1.3, OpenGL up to 4.6, OpenCL 3.0 and D3D12 capabilities supplied by vkd3d-proton, including 32-bit processes. These are implementation/support claims, not certification or universal application compatibility. Host API availability remains decisive. No CUDA support is established here. [1][3]
- Native D3D9 is a useful documentation-drift example: the root README says it exists, while accel-virt's README still says to use a DXVK DLL. The pinned avumd export table and OpenAdapter implementation do contain the native D3D9 entry point. That corroborates the implementation direction, not complete D3D9 correctness. [3]
- The hardware testing guide describes five GPUs across AMD, Intel and NVIDIA, API probes, host/guest image comparisons, device-reset detection, capture tests and application/trace suites. This is stronger than a screenshot demo, but the large trace store and run outputs live outside Git; no complete independently replayed result set was obtained. Release v0.1.8 claims a successful matrix. [8][9]
- Performance notes report roughly 30 ms present-to-capture arrival in one path and about 8 full 2560×1440 frames/s for network pixels. These are author measurements, not an end-to-end latency guarantee or a native-Windows comparison. The November 1 buffer-flow document explicitly describes some uncommitted work and unresolved costs, so its figures cannot all be assigned to this SHA. [4]
- Open issue #4 reports Lightroom redraw failures and GPU acceleration being disabled on a specific v0.1.9 setup. It is a user report, not a reproduced defect here, but directly rebuts an assumption that broad graphics API coverage guarantees professional-app readiness. [10]
- KDE Plasma/KWin is the tested placement environment. Generic Wayland, Hyprland, GNOME, X11, ARM hosts, anti-cheat software and Windows 10 compatibility are not established by this review.

## Security and Trust Boundaries

### Local control is powerful and unauthenticated

The guest listener binds all guest interfaces; the host's QEMU forwards bind loopback. The inspected accept-to-dispatch path performs no authentication handshake before privileged RPC. That limits default LAN exposure but does not distinguish Linux users sharing loopback or guest-local callers. Launch/upload/console operations are high authority. The framing implementation buffers a 32-bit advertised length without a maximum-frame cap, and the listener creates a thread per accepted connection without an evident quota; resource exhaustion is a static concern, not an executed exploit. [5][6][11]

The manager also starts a loopback HTTP MCP server with launch, console, raw RPC and agent-redeployment tools. Its inspected HTTP path contains no bearer authentication, Origin/Host validation or explicit body-size budget. Loopback is a useful default, not an authorization mechanism. Browser-origin abuse was not tested. Standalone remotewin differs again: its documentation says an unmanaged listener binds all IPv4 interfaces and has no authentication; LSW managed mode uses loopback. [2][12]

### Guest credentials and security settings are convenience-first

Provisioning saves the guest password in QSettings INI storage; the unattended template embeds it as plaintext and enables automatic logon. This is not a keychain-backed secret store. Treat configuration, payload ISOs, guest disks and their backups as sensitive. The unattended renderer substitutes strings directly into XML, without escaping at that layer; special-character handling deserves end-to-end testing. [13]

The guest uses a test-signed kernel driver with Secure Boot keys unenrolled. Setup creates an administrator account and configures silent administrator elevation while leaving UAC structurally enabled, enables an SMB firewall rule and remote administrative token behavior, and changes many Windows policies. This is not equivalent to an ordinary stock Windows security baseline. [13]

### Shared files, USB and graphics expand the VM boundary

Read/write host shares expose real host data to guest applications; use narrowly selected, preferably read-only folders, never a broad home-directory share for an untrusted guest. The UI supports read-only flags, but malformed/legacy share records without that flag decode as writable. SMB integration defaults to the guest administrative C$ share. [6][13]

USB authorization is not only a transient attachment: the polkit helper writes a persistent udev uaccess rule per vendor/product type. Good points: exact four-hex-digit validation, atomic file replacement, and an active-session admin authorization policy. Scope is every matching device type, not a serial-number-specific device; package removal does not automatically undo generated rules. [14]

GPU command decoding, QEMU, host graphics drivers and shared-surface import all sit on a security-sensitive boundary. This review did not comprehensively audit those decoders or establish escape resistance. Do not use LSW as a malware-analysis containment system.

## Installation, Requirements and Recovery

**Requirements:** x86-64 Linux with working KVM permissions, suitable Vulkan graphics drivers and a KWin/Wayland desktop; Windows 11 24H2/build 26100 or newer for WDDM 3.2. The package targets rolling Arch libraries (currently Qt >=6.12); the domain's NVMe support requires recent libvirt (the source notes 11.5+). An Arch-built tarball is not a portable distribution-independent binary. Shared folders need virtiofsd, OpenCL needs a host ICD, and USB authorization uses polkit. [1][6][15]

Defaults allocate 8 GiB guest RAM, a 60 GiB disk and all host hardware threads, plus an 8 GiB GPU host-visible address window. The latter is an address-window setting, not a promise of fixed additional physical RAM use. Leave host headroom and room for Windows media, updates and snapshots; no tested universal minimum is asserted. Builds additionally require a Windows kit subset, patched QEMU, DXVK and vkd3d-proton; README estimates about 550 MB of first-build fetches. Nothing was installed or downloaded beyond public source and metadata for this review. [1][13]

**Changes:** package files under the normal system prefix include executables, private graphics runtime, desktop entry, guest payload and polkit helper. Running setup creates a user-session libvirt domain, per-user disks/ISOs/NVRAM/configuration and extensive guest services/registry changes. Desktop launchers, file associations and file-manager bookmarks integrate the guest; USB opt-in additionally creates system udev rules. These effects are broader than installing one GUI binary.

**Uninstall/recovery plan:** shut Windows down, back up its qcow2 disk, NVRAM, domain XML and relevant settings before upgrades or removal; preserve a matching host/guest runtime version. Remove the package through its package manager, then deliberately inventory the user-session domain, per-user state, desktop integration and generated USB rules. Package removal alone is not a documented complete rollback. No reversible one-click uninstall was established.

**Do not mistake reset for recovery:** scripts/reset-vm.sh says in its header that the downloaded Windows ISO is preserved, but its actual command deletes the entire LSW data directory and manager.ini after destroying/undefining the VM. That includes the disk and ISOs under that directory. This is a concrete source/comment mismatch and a data-loss hazard. Restore a known-good backup instead of running reset on valuable data. The component docs describe booting without the custom GPU to repair a broken driver; that is an expert recovery technique, not a tested procedure here. [3][16]

## Licensing and Redistribution

The root LICENSE is Apache-2.0, with its notice and patent terms. Release packaging carries separate QEMU, firmware, DXVK, vkd3d-proton, Vulkan-loader, virtio-win and WinFsp notices; an assembled binary distribution is not Apache-only. [15][17]

Neither acquired first-level standalone submodule had a tracked LICENSE/COPYING file at the pinned revision. The root project's Apache declaration should not silently be treated as an independently verified grant for every separately hosted component; clarify licensing before extracting or redistributing those trees. No source components were extracted in this review.

WinFsp's bundled text is GPLv3 with a FLOSS exception, including notice requirements and a restriction against distributing/linking the exception-covered software with proprietary software. LSW's packaging explains its rationale for shipping the unmodified installer. A proprietary repack or preloaded commercial Windows appliance needs its own legal assessment. [17]

Windows is separately licensed: downloading an ISO or accepting setup terms does not supply an activation entitlement, commercial-app license or blanket redistribution right. Build-time Windows SDK/WDK materials have their own terms; the packaging notes explicitly say the kit subset is not redistributable. Game/application traces, screenshots and media also have independent rights. No Windows image, application media or test corpus was downloaded or redistributed.

## Tests, CI and Maturity

At retrieval GitHub reported 93 stars, 2 forks, 4 open issues, creation on 2026-05-09 and last push on 2026-11-01. Latest listed release was v0.1.9 (2026-10-23), while this review covers newer master. Popularity is not assurance. [9][10]

There are 30 C++ test translation units under the root src test directories, covering protocol/agent/host logic, plus Python GPU-harness tests and component-specific suites. These were inspected as source inventory, not run. Root builds explicitly disable remotewin's own tests. [18]

CI is materially stale: workflows trigger pushes to main while the actual default branch is master; Linux build setup installs only a small subset of the current required dependencies; codegen/lint jobs reference a root codegen directory absent from this checkout. The public Actions API returned one dependency-graph run, not a successful current build/test matrix. Do not infer green integration from the existence of workflow YAML. [18]

The code has useful separation of concerns, a shared wire schema, scoped USB argument validation and careful XML/QEMU escaping in the domain builder. Those strengths coexist with inconsistent docs, weak local authentication and broad installer policy changes. This is early engineering with real implementation, not mature support coverage.

## Comparison

| Option | When it fits | Main tradeoff against LSW |
|---|---|---|
| [Wine](https://www.winehq.org/) / [Proton](https://github.com/ValveSoftware/Proton) | Supported Windows apps/games without a Windows guest | Avoids guest OS/license/maintenance overhead; compatibility depends on API reimplementation. LSW retains real Windows but still has a novel graphics driver. |
| [WinApps](https://github.com/winapps-org/winapps) | Windows VM applications integrated through RDP/RemoteApp | More conventional remoting stack; not the same custom shared-GPU path. Windows edition/RemoteApp requirements matter. |
| [virt-manager](https://virt-manager.org/) with ordinary QEMU/KVM | A conventional, separately managed Windows VM | Less seamless window integration, but simpler to reason about and recover; acceleration depends on configuration. |
| VFIO GPU passthrough / [Looking Glass](https://looking-glass.io/) | Near-native vendor GPU-driver workloads on suitable hardware | Requires appropriate GPU/IOMMU topology and more setup; LSW shares host rendering without dedicating the card. |
| Native Windows or dual boot | Critical creative tools, vendor support or incompatible anti-cheat | Least transparent Linux integration, but strongest baseline for testing application compatibility. |

## Practical Recommendation and Limits

A technically capable KDE/Arch user can reasonably evaluate LSW with a disposable licensed guest and synthetic documents. Check the exact required app, GPU, file round trip, resize/popups, suspend/resume and upgrade/restore path before trusting it. Keep guest credentials unique, shares minimal, USB access deliberate and control endpoints off the network.

For sensitive work, multi-user machines or production dependence, wait for authenticated local control, bounded parsers, clearer component licenses, repaired CI, explicit rollback/uninstall and a reproducible compatibility/performance matrix. This review is static evidence, not a safety certification, an application compatibility test or a full transitive dependency/security audit.

## Evidence

All root source links below are pinned to the reviewed SHA; issue/release metadata is a retrieval-time snapshot.

1. [README](https://github.com/acceleration3/linux-subsystem-windows/blob/b8242f960cf5b9ec7ee4b7a1e8fb7af1a01113c0/README.md), [CMake identity/options](https://github.com/acceleration3/linux-subsystem-windows/blob/b8242f960cf5b9ec7ee4b7a1e8fb7af1a01113c0/CMakeLists.txt).
2. [Pinned remotewin README](https://github.com/acceleration3/remotewin/blob/dce05c0234ea67a7c8239f71e1b584907dd71f18/README.md).
3. [Pinned accel-virt README](https://github.com/acceleration3/accel-virt/blob/a9c01985cee76fa684d1666b39e9433128426c86/README.md), [native D3D exports](https://github.com/acceleration3/accel-virt/blob/a9c01985cee76fa684d1666b39e9433128426c86/src/um/d3d/avumd_exports.cpp).
4. [Window buffer flow and measurement caveats](https://github.com/acceleration3/linux-subsystem-windows/blob/b8242f960cf5b9ec7ee4b7a1e8fb7af1a01113c0/docs/window-buffer-flow.md).
5. [Link protocol](https://github.com/acceleration3/linux-subsystem-windows/blob/b8242f960cf5b9ec7ee4b7a1e8fb7af1a01113c0/docs/link-protocol.md), [frame reader](https://github.com/acceleration3/linux-subsystem-windows/blob/b8242f960cf5b9ec7ee4b7a1e8fb7af1a01113c0/src/linkproto/include/lsw/linkproto/frame_reader.hpp).
6. [Domain template](https://github.com/acceleration3/linux-subsystem-windows/blob/b8242f960cf5b9ec7ee4b7a1e8fb7af1a01113c0/src/host/embedded/domain.xml).
7. [Actual domain builder](https://github.com/acceleration3/linux-subsystem-windows/blob/b8242f960cf5b9ec7ee4b7a1e8fb7af1a01113c0/src/host/src/vm/domain_xml_builder.cpp).
8. [GPU testing methodology](https://github.com/acceleration3/linux-subsystem-windows/blob/b8242f960cf5b9ec7ee4b7a1e8fb7af1a01113c0/docs/gpu-testing.md).
9. [Releases](https://github.com/acceleration3/linux-subsystem-windows/releases), [public repository metadata](https://api.github.com/repos/acceleration3/linux-subsystem-windows).
10. [Lightroom report #4](https://github.com/acceleration3/linux-subsystem-windows/issues/4), [open issues](https://github.com/acceleration3/linux-subsystem-windows/issues).
11. [Guest endpoint implementation](https://github.com/acceleration3/linux-subsystem-windows/blob/b8242f960cf5b9ec7ee4b7a1e8fb7af1a01113c0/src/agent/src/transport/host_endpoint.cpp).
12. [MCP HTTP implementation](https://github.com/acceleration3/linux-subsystem-windows/blob/b8242f960cf5b9ec7ee4b7a1e8fb7af1a01113c0/src/host/src/mcp/http_server.cpp), [tools](https://github.com/acceleration3/linux-subsystem-windows/blob/b8242f960cf5b9ec7ee4b7a1e8fb7af1a01113c0/src/host/src/mcp/mcp_server.cpp), [startup](https://github.com/acceleration3/linux-subsystem-windows/blob/b8242f960cf5b9ec7ee4b7a1e8fb7af1a01113c0/src/host/src/app/app.cpp).
13. [Settings storage/defaults](https://github.com/acceleration3/linux-subsystem-windows/blob/b8242f960cf5b9ec7ee4b7a1e8fb7af1a01113c0/src/host/src/config/manager_settings.cpp), [provisioning persistence](https://github.com/acceleration3/linux-subsystem-windows/blob/b8242f960cf5b9ec7ee4b7a1e8fb7af1a01113c0/src/host/src/provision/pipeline.cpp), [unattended template](https://github.com/acceleration3/linux-subsystem-windows/blob/b8242f960cf5b9ec7ee4b7a1e8fb7af1a01113c0/src/host/embedded/autounattend.xml), [unattended renderer](https://github.com/acceleration3/linux-subsystem-windows/blob/b8242f960cf5b9ec7ee4b7a1e8fb7af1a01113c0/src/host/src/provision/install/autounattend.cpp).
14. [USB helper](https://github.com/acceleration3/linux-subsystem-windows/blob/b8242f960cf5b9ec7ee4b7a1e8fb7af1a01113c0/packaging/lsw-usb-access), [polkit policy](https://github.com/acceleration3/linux-subsystem-windows/blob/b8242f960cf5b9ec7ee4b7a1e8fb7af1a01113c0/packaging/org.lsw.usb-access.policy).
15. [Package requirements](https://github.com/acceleration3/linux-subsystem-windows/blob/b8242f960cf5b9ec7ee4b7a1e8fb7af1a01113c0/aur/PKGBUILD), [dependency fetches](https://github.com/acceleration3/linux-subsystem-windows/blob/b8242f960cf5b9ec7ee4b7a1e8fb7af1a01113c0/cmake/LSWDependencies.cmake).
16. [Destructive reset script](https://github.com/acceleration3/linux-subsystem-windows/blob/b8242f960cf5b9ec7ee4b7a1e8fb7af1a01113c0/scripts/reset-vm.sh), [state locations](https://github.com/acceleration3/linux-subsystem-windows/blob/b8242f960cf5b9ec7ee4b7a1e8fb7af1a01113c0/src/host/src/config/settings.cpp).
17. [Root license](https://github.com/acceleration3/linux-subsystem-windows/blob/b8242f960cf5b9ec7ee4b7a1e8fb7af1a01113c0/LICENSE), [release license collection](https://github.com/acceleration3/linux-subsystem-windows/blob/b8242f960cf5b9ec7ee4b7a1e8fb7af1a01113c0/scripts/package-release.sh), [WinFsp terms](https://github.com/acceleration3/linux-subsystem-windows/blob/b8242f960cf5b9ec7ee4b7a1e8fb7af1a01113c0/packaging/licenses/winfsp-LICENSE).
18. [CI workflows](https://github.com/acceleration3/linux-subsystem-windows/blob/b8242f960cf5b9ec7ee4b7a1e8fb7af1a01113c0/.github/workflows/build.yml), [codegen workflow](https://github.com/acceleration3/linux-subsystem-windows/blob/b8242f960cf5b9ec7ee4b7a1e8fb7af1a01113c0/.github/workflows/codegen.yml), [Actions history](https://github.com/acceleration3/linux-subsystem-windows/actions), [test wiring](https://github.com/acceleration3/linux-subsystem-windows/blob/b8242f960cf5b9ec7ee4b7a1e8fb7af1a01113c0/CMakeLists.txt).

---

**Attribution:** acceleration3 and the LSW, accel-virt and remotewin contributors; root LSW Apache-2.0, third-party and component terms as discussed above.
