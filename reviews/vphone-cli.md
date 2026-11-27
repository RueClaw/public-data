# vphone-cli (Lakr233/vphone-cli)

**Repo:** https://github.com/Lakr233/vphone-cli
**License:** MIT for project code; Apple firmware/runtime and bundled dependency terms are separate.
**Reviewed:** 2026-11-27 (UTC)
**Revision:** `5dfd335a3a39ad7e5d1a24da80fbaa1a6c251aaa`, release 2.19.0; repository-wide static review with focused host, restore, automation, storage and CI inspection.
**Verification:** Anonymous HTTPS source and GitHub metadata inspected; source/tag resolution and artifact markup checked. No installation, build, upstream tests, firmware downloads, virtualization, device access or live API probes.
**Stack:** Swift, Objective-C/C, AppKit/SwiftUI, Virtualization.framework, SwiftNIO, Xcode, native firmware/restore tooling.
**What it is:** A native Apple Silicon research workstation for preparing patched Apple guests, running them as VMs, and controlling their UI and operating system.

---

## Verdict

📚 **Study; operate only on a dedicated research Mac.** The current native pipeline, separated VM executable, root-helper admission checks and coherent snapshots are substantial engineering. But relaxed host security, guest-root automation and deliberately broad local artifact permissions make this a poor default for a shared workstation or sensitive-account testing. This is not a general-purpose production iPhone substitute or a proven hostile-code containment boundary.

## What It Is

The project runs real, modified Apple guest firmware through private Virtualization.framework research-guest facilities, rather than compiling an app for the Xcode Simulator. Launchpad installs a versioned core bundle and orchestrates firmware preparation, patching, restore, custom-firmware installation and first boot. Its CLI also supports headless operation and machine libraries.[1][2]

This review covers the upstream 2.x implementation, not the older convenience distribution covered in [vphone-aio](vphone-aio.md). That earlier wrapper review is a different canonical repository and historical scope; its Makefile/Python workflow, blanket AMFI-disable requirements and SSH/VNC assumptions should not be applied to this revision. The current documentation explicitly says the standard control workflow installs no SSH or VNC endpoint.[3]

### Provenance and release state

The canonical repository was anonymously accessible. At retrieval, GitHub reported 17,017 stars, 1,994 forks, 11 open issues (the aggregate may include pull requests), and last push 2026-11-26T10:21:11Z. These are activity metadata, not safety evidence. The latest-release endpoint returned **2.19.0**, published 2026-11-26T10:21:13Z. Its annotated tag object `f2b8f76369d873523ef8801d17e9c3391346da24` peeled to the reviewed SHA. Main and workflow activity can move independently of this pinned release.[16]

The release advertises visionOS 27.2 support, watchOS 27.2 work, guest signer fixes and stale control-socket cleanup. Its assets include a notarized Launchpad ZIP, an ordinary Launchpad ZIP, VPhone bundle and skills ZIP; all four have GitHub SHA-256 digest metadata. The downloads page still ends its series table at 2.18: use release-specific version information, not that table alone. No release binary was downloaded or its notarization independently evaluated.[4][16]

## Stack

| Layer | Technology and boundary |
|---|---|
| Host launcher | SwiftUI/AppKit Launchpad; privileged XPC helper for controlled administrative work |
| CLI and patching | Swift ArgumentParser, native firmware patcher/restore modules; unentitled orchestration binary |
| VM | Separately signed, private-entitled vphone-vm using Virtualization.framework; OpenAVB/OpenSEP boot ROMs |
| Guest service | Root-running vphoned; Swift and Objective-C/C; UI, files, keychain and shell control |
| Networking | SwiftNIO TCP-to-VSOCK proxy; NAT, bridged, tunnel or no guest NIC |
| Persistence | Machine directory with plist configuration, disk image, SEP state, NVRAM, receipts; APFS clones |
| Dependencies | Revision-pinned SwiftPM lockfile including AppleMobileDeviceLibrary, icli, SwiftNIO, ArgumentParser, MachOKit and binary-library wrappers |

The lockfile improves repeatability but is not a dependency audit or reproducible-build proof. Bundled archive, disassembly, crypto and terminal libraries increase the supply-chain surface.[5]

## Key Features

### 1. Real guest orchestration with explicit compatibility limits

The documented minimum is a **physical Apple Silicon Mac with macOS 15+**; nested macOS VMs are unsupported. A default guest disk is 64 GB virtual capacity, not a promise that 64 GB free space suffices: cached IPSWs, temporary restore trees, kernelcache mixes and snapshots add overhead. Distributed bundles need no Xcode, Python or Homebrew at runtime; source builds require Xcode and the iPhoneOS SDK.[1][2]

The compatibility matrix records specific iPhone/iPad, watchOS, tvOS and HomePod combinations, with different validation depths. iOS 18 uses different firmware/kernelcache pairings; some later cloudOS versions need research-board recipes and some have not booted. Particular OTA formats require macOS 27. Release 2.19's visionOS support is a release claim, not an independently reproduced compatibility result. A device identifier in a catalog is not proof of full app, sensor, radio, Apple-service or physical-device fidelity.[6][16]

### 2. Better host privilege separation, not stock host security

The unentitled CLI delegates VM execution to vphone-vm. The less-permissive documented setup keeps SIP generally enabled but relaxes debugging restrictions, enables research guests in Recovery, and uses vphone-escalator to allow the VM's cdhash. The tool changes an AMFI preference and one byte in amfid memory; an amfid restart or changed VM signature may require admission again. The alternative fully disables SIP/AMFI and is substantially broader. Neither is an ordinary sandboxed-app install.[2]

Launchpad's helper checks a code-signing requirement for XPC callers and an administrator authorization right for privileged verbs. The right can be reused for the login session; it is not necessarily a fresh prompt for every operation. Bundle installation copies and hashes the received archive into root-owned staging, checks nested signatures and versions, records executable cdhashes, restricts writable store paths and rejects unsafe entries. These are meaningful defensive checks, not proof that the entire privileged parser/extraction surface is safe.[7]

### 3. Automation is guest-root authority

The optional HTTP/WebSocket API is absent unless explicitly enabled. A generated per-launch token is 32 random bytes; a caller can instead supply a constrained fixed token. Admission validates the first HTTP request head on a connection, with a 16 KiB head limit, before relaying the connection to the guest. This is connection admission, not per-method authorization or tenant isolation.[8]

Guest-side handlers reject Origin-bearing requests and non-local Host names; the host proxy rewrites Host to localhost after token admission. That is useful browser protection, **not** a guarantee that a non-loopback listener is unreachable. Plain HTTP carries the bearer token unencrypted, and any authorized client has powerful guest access. Tokens are printed to process logs; query-token URLs can also leak through client history/logging. Prefer loopback, protected logs and independently secured transport if remote access is necessary.[8][9]

The local vphone.sock path also accepts RPC and interactive shell commands without the HTTP token. Its inspected accept loop has no peer-credential authorization check; filesystem reachability and local OS permissions matter. Do not describe the optional HTTP token as protecting every control path.[3][10]

## Architecture

The division is practical: **Launchpad → unentitled CLI → entitled VM process → VSOCK → root guest daemon**. Shared VPhoneCoreKit owns machine/configuration and process plumbing; VPhoneArchiveKit handles archives and transfers; VPhoneExternalAccessKit exposes client functionality. Native patching/restore modules and guest components carry the hardware/OS-specific complexity. Patch receipts and explicit refusal of unsupported firmware recipes are preferable to assuming future firmware will boot.[5][6]

### Downloads, signatures and license boundaries

Launchpad discovers GitHub release assets and compares the archive to GitHub's SHA-256 digest; the helper repeats hashing while copying. The core bundle is **ad hoc signed**: signature validity demonstrates internal integrity, not a Developer ID publisher identity. The digest is delivered through the same release trust chain, not an independent maintainer signature or build-reproducibility attestation. Notarized Launchpad and the ad hoc core bundle are different trust objects.[4][7]

Provisioning obtains Apple firmware and signing tickets online; some kernelcache recipes fetch macOS recovery content to obtain matching kmutil components. Offline operation is conditional on retained firmware/tickets and the chosen workflow, not a guaranteed permanent entitlement to recreate any guest. Firmware availability, signing and private APIs remain external dependencies.[1][6]

MIT grants rights to the project code with notice preservation. It does **not** license Apple's IPSWs, frameworks, SDKs, extracted drivers, signing services or guest applications. Bundled third-party code and boot ROMs have their own notices (the build stages package notices and OpenAVB's APSL material). Check the applicable Apple agreements and component licenses before redistribution, hosted access or commercial use; public download availability and research tooling do not settle those permissions. This is a licensing boundary, not a legal determination.[11]

### Physical devices and destructive provisioning

The normal restore command derives an ECID from the selected VM and refuses an unresolved identity, which reduces accidental target selection. However, lower-level identity parsing permits an unset/empty ECID meaning an attached device, and recovery probing can select the only attached device. The code uses Apple mobile-device interfaces, not an inherently VM-only transport. Keep unrelated physical devices disconnected and verify the VM identity before destructive restore work; this review did not exercise device selection.[12]

Restore explicitly rejects its no-erase option because the guest restore ramdisk recreates the partition map. A backup, not an optimistic flag, is the recovery plan.[12]

### Privacy and local-user isolation: the largest concrete caveat

VPhoneHostFilePermissions deliberately makes eligible VM regular files and directories **0777**. Restore, import/export and launch-related paths call this helper. Its descriptor-relative traversal avoids following symlinks and widening hard-linked outside files, and root skips unrelated owners; these protections do not make the resulting guest artifacts confidential.[13]

Where parent directories permit traversal, another local account may read or alter these VM files. The Unix control socket's exposure additionally depends on OS socket permissions and the surrounding path; no cross-user exploit was attempted. Use a dedicated account/host and a restrictive parent boundary, then audit permissions after lifecycle operations rather than assuming chmod on individual guest files will persist. Do not store production Apple IDs, personal keychains or sensitive guest data here. Disabling the HTTP listener does not fix on-disk exposure.[10][13]

Guest NAT is the default; bridged mode intentionally exposes a guest on the LAN, tunnel mode uses host connections, and none removes the NIC. No blanket air-gap or VPN-isolation claim follows from these options. Screenshots, recordings, memory dumps, guest files, tokens, signing artifacts and exported disks all warrant access and retention controls. Guest-root APIs and a weakened host configuration are especially unsuitable as a default malware-analysis containment promise.[9]

## Persistence and Recovery

Snapshots capture stopped-machine disk, SEPStorage and nvram.bin together, plus available patch/restore receipts. Keeping those three state files aligned matters because SEP anti-replay state must match the disk. Create/revert refuse active use; snapshots require APFS, and revert has rollback logic. These are static implementation/documentation findings, not a successful recovery drill.[14]

Snapshots do **not** restore config.plist, firmware input trees, patch choices or ROMs. They are disk/boot-state snapshots, not live RAM checkpoints or full host rollback. Pause retains RAM only while the VM process lives. APFS clones consume additional space as blocks diverge; snapshots can retain blocks that otherwise appear reclaimable.[3][14]

Clones and exports omit snapshots. A same-identity clone is a backup and cannot run beside its original; a new-identity clone changes identity/network collision settings but still copies apps and data. Schema-1 machines are not in-place upgradable to schema 2. Preserve original images and matching bundle versions, test an export/import recovery separately, and expect firmware/signing-dependent rebuilds rather than universal backward compatibility.[4][14]

The latest release repairs stale root-owned control sockets and waits for machine resources to release before reporting stopped. Those fixes show active lifecycle maintenance, while also illustrating why successful process exit is not enough evidence that a VM can safely restart.[16]

## Maturity, CI and Verification

There are substantial tests for core/archive behavior, API admission, file permissions, firmware transforms, guest components and helper path handling. The build workflow runs focused regression scripts, a bundle build/validation, selected firmware Xcode tests, RPC schema checks and multiple guest-component tests. Presence of broader test directories does not establish that every suite runs on each PR.[15]

Anonymous GitHub Actions metadata for the **reviewed SHA** reported build and release success; tap-sync was skipped. This is upstream-reported CI, not locally reproduced execution, full firmware boot coverage, or independent security certification. The release workflow uses mutable major-version action tags and a specialized xcode-27 runner; reproducible released binaries were not established.[15][16]

**Checks performed:** canonical-source deduplication against README, reviews and repository index; anonymous source/API access; exact source/tag matching; targeted implementation/document inspection; Markdown citations checked against the pinned tree; HTML placeholders, links, structure and trusted-template CSS/JS checked; public-only task diff inspected.

**Not performed:** dependency installation, project builds/tests, asset signature verification, firmware downloads, VM boot/restore, physical-device operations, network/auth exploitation, performance benchmarks or Apple-service compatibility checks. No runtime safety claim is implied.

## Comparison

| Option | Best fit | Tradeoff against vphone-cli |
|---|---|---|
| Xcode Simulator | Ordinary app development and UI testing | Supported development path without this research-guest host weakening; not a real firmware/kernel research target |
| Dedicated physical iPhone/iPad with Xcode/XCTest | Hardware and service fidelity | Real peripherals and device behavior; less convenient snapshot/cloning and root-level introspection |
| Apple's Virtual Research Environment / security-pcc | PCC-specific research | Closer to the documented PCC research purpose; not a drop-in patched interactive iPhone workstation |
| vphone-aio wrapper | Historical convenience packaging | Separate distribution trust and versioning; inspect current upstream instead of assuming old wrapper instructions match 2.x |

For ordinary app automation, start with Simulator/XCTest or a dedicated physical test device. For research that specifically needs this modified guest environment, vphone-cli is a serious candidate **only after** accepting the host-security and data-isolation costs. No alternative was installed or benchmarked for this review.

## Self-Hosting Notes

This is a local Apple workstation stack, not a Docker service or generic Linux host workload. Budget for firmware storage and memory, choose an explicitly documented host/guest pairing, match Launchpad and core-bundle series, and keep source and downloaded-runtime provenance separate. Perform host-setting changes manually under a deliberate security plan; do not hand an installer or agent blanket permission to weaken Recovery settings, expose APIs or restore attached devices.

Before using valuable data: validate binary provenance, audit library-parent and artifact permissions, keep APIs loopback-only, disconnect unrelated devices, create an offline backup of coherent machine state, and test recovery. An isolated disposable research environment is the appropriate deployment posture.

## Evidence

All repository file references below are pinned to the reviewed commit.

[1]: https://github.com/Lakr233/vphone-cli/blob/5dfd335a3a39ad7e5d1a24da80fbaa1a6c251aaa/Documents/en/get-started/overview.md
[2]: https://github.com/Lakr233/vphone-cli/blob/5dfd335a3a39ad7e5d1a24da80fbaa1a6c251aaa/Documents/en/get-started/host-setup.md
[3]: https://github.com/Lakr233/vphone-cli/blob/5dfd335a3a39ad7e5d1a24da80fbaa1a6c251aaa/Documents/en/machines/create-and-run.md
[4]: https://github.com/Lakr233/vphone-cli/blob/5dfd335a3a39ad7e5d1a24da80fbaa1a6c251aaa/Documents/en/get-started/downloads.md
[5]: https://github.com/Lakr233/vphone-cli/blob/5dfd335a3a39ad7e5d1a24da80fbaa1a6c251aaa/VPhone.xcworkspace/xcshareddata/swiftpm/Package.resolved
[6]: https://github.com/Lakr233/vphone-cli/blob/5dfd335a3a39ad7e5d1a24da80fbaa1a6c251aaa/Documents/en/firmware/compatibility.md
[7]: https://github.com/Lakr233/vphone-cli/tree/5dfd335a3a39ad7e5d1a24da80fbaa1a6c251aaa/VPhoneLaunchpad/VPhoneLaunchpadHelper
[8]: https://github.com/Lakr233/vphone-cli/blob/5dfd335a3a39ad7e5d1a24da80fbaa1a6c251aaa/VPhoneKit/VPhoneCoreKit/Support/VPhoneAPIRequestGate.swift
[9]: https://github.com/Lakr233/vphone-cli/blob/5dfd335a3a39ad7e5d1a24da80fbaa1a6c251aaa/Documents/en/machines/automation-api.md
[10]: https://github.com/Lakr233/vphone-cli/blob/5dfd335a3a39ad7e5d1a24da80fbaa1a6c251aaa/VPhoneExecutable/VPhoneVirtualization/UI/VPhoneHostAutomationServer.swift
[11]: https://github.com/Lakr233/vphone-cli/blob/5dfd335a3a39ad7e5d1a24da80fbaa1a6c251aaa/LICENSE
[12]: https://github.com/Lakr233/vphone-cli/blob/5dfd335a3a39ad7e5d1a24da80fbaa1a6c251aaa/VPhoneExecutable/VPhoneCommand/VPhoneCommand/Restore/VPhoneRestoreCommand.swift
[13]: https://github.com/Lakr233/vphone-cli/blob/5dfd335a3a39ad7e5d1a24da80fbaa1a6c251aaa/VPhoneKit/VPhoneCoreKit/Process/VPhoneHostFilePermissions.swift
[14]: https://github.com/Lakr233/vphone-cli/blob/5dfd335a3a39ad7e5d1a24da80fbaa1a6c251aaa/Documents/en/storage/snapshots.md
[15]: https://github.com/Lakr233/vphone-cli/blob/5dfd335a3a39ad7e5d1a24da80fbaa1a6c251aaa/.github/workflows/build.yml
[16]: https://github.com/Lakr233/vphone-cli/releases/tag/2.19.0

Additional implementation: [proxy](https://github.com/Lakr233/vphone-cli/blob/5dfd335a3a39ad7e5d1a24da80fbaa1a6c251aaa/VPhoneExecutable/VPhoneVirtualization/UI/GuestCommunication/VPhoneAPIProxy.swift), [guest HTTP gate](https://github.com/Lakr233/vphone-cli/blob/5dfd335a3a39ad7e5d1a24da80fbaa1a6c251aaa/VPhoneDaemon/Daemon/GuestHyperTextHandler.swift), [transfer commands](https://github.com/Lakr233/vphone-cli/blob/5dfd335a3a39ad7e5d1a24da80fbaa1a6c251aaa/VPhoneExecutable/VPhoneCommand/VPhoneCommand/VirtualMachine/VPhoneVirtualMachineTransferCommand.swift), [restore identity](https://github.com/Lakr233/vphone-cli/blob/5dfd335a3a39ad7e5d1a24da80fbaa1a6c251aaa/VPhoneExecutable/VPhoneCommand/VPhoneRestore/VPhoneRestore/Restore/VPhoneRestoreIdentity.swift), [backup semantics](https://github.com/Lakr233/vphone-cli/blob/5dfd335a3a39ad7e5d1a24da80fbaa1a6c251aaa/Documents/en/storage/library-and-backups.md), [network modes](https://github.com/Lakr233/vphone-cli/blob/5dfd335a3a39ad7e5d1a24da80fbaa1a6c251aaa/Documents/en/networking/overview.md), [release CI](https://github.com/Lakr233/vphone-cli/blob/5dfd335a3a39ad7e5d1a24da80fbaa1a6c251aaa/.github/workflows/release.yml), [package notices](https://github.com/Lakr233/vphone-cli/blob/5dfd335a3a39ad7e5d1a24da80fbaa1a6c251aaa/scripts/stage-package-notices.zsh).

---

**Attribution:** Lakr233 and vphone-cli contributors, MIT project code. Apple and third-party materials remain subject to their respective terms. Independent static analysis; no upstream code extracted.
