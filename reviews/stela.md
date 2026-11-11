# Stela (tylertms/Stela)

**Repo:** https://github.com/tylertms/Stela
**License:** GPL-2.0-or-later for Stela's own code; distributed EFI GPL-2.0-only and CLI GPL-3.0-or-later; component terms apply.
**Reviewed:** 2026-11-11 (UTC)
**Revision:** `9c190f250930e54dd74d2396c17400e6e212160b`, main; root workspace, selected boot/compiler/engine/SoC/runtime/driver modules, installer, guest GPU/app, build and CI. Commit dated 2026-11-11T20:06:48Z.
**Verification:** Static source review and public GitHub metadata only. No builds, source tests, firmware downloads, installation, device access, boot, Apple service calls, or performance measurements.
**Stack:** Rust 2024, UEFI, native C/C++ and Objective-C GPU components, SwiftUI companion, Linux driver code, Mesa/NVK/NIR, LLVM, smoltcp, rustls/Mbed TLS.
**What it is:** An experimental Apple-silicon hardware/translation layer that boots ARM macOS on x86-64 PCs—not an AI assistant, inference server, or ordinary desktop application.

## Verdict

📚 **Study — substantial systems work, not a dependable Mac replacement.** Stela combines ARM64-to-x86 translation, an M2 device model, and a Metal-to-NVIDIA graphics path behind a bare-metal UEFI bootloader. Its explicit failure contracts, installer recovery, and source/licensing records are worth studying. The project's own low-boot-success warning, extremely young releases, broad hardware authority, and non-Apple secure-enclave trust model make production or sensitive-data use premature.

## What It Is

The [README](https://github.com/tylertms/Stela/blob/9c190f250930e54dd74d2396c17400e6e212160b/README.md) describes a general-purpose Apple-silicon layer for Intel/AMD PCs, currently modeling a Mac mini M2 and running macOS 27. It claims macOS and most apps start but are slow, and explicitly warns that the chance of booting is low. Those are upstream claims, not reproduced results.

Unlike an Intel Hackintosh bootloader, this executes ARM software by translation and models Apple hardware. Unlike a conventional hosted VM, the shipping boot target owns hardware after UEFI boot services end. The host-side CLI prepares an installer USB; the guest includes a GPU kext/Metal bundle and a small SwiftUI system-information application. A label such as “unmodified macOS” does not mean an unmodified trust platform: Stela provides replacement hardware services and its own SEP implementation.

## Stack and Architecture

| Layer | Implementation and evidence |
|---|---|
| Installer/control | [stela-cli](https://github.com/tylertms/Stela/blob/9c190f250930e54dd74d2396c17400e6e212160b/crates/stela-cli/src/setup.rs): setup records, raw-disk formatting, IPSW preparation, diagnostics, repair, updates, state backup |
| Boot | [stela-boot](https://github.com/tylertms/Stela/blob/9c190f250930e54dd74d2396c17400e6e212160b/crates/stela-boot/src/main.rs): UEFI entry, memory/PCI/interrupt setup, native host drivers, installed-system or restore boot |
| Translation | [stela-compiler](https://github.com/tylertms/Stela/blob/9c190f250930e54dd74d2396c17400e6e212160b/crates/stela-compiler/src/lib.rs): AArch64 lifting/native x86 emission, source fingerprint, target-dependent behavior; unsupported instructions are errors, not an interpreter fallback |
| Execution | [stela-engine](https://github.com/tylertms/Stela/blob/9c190f250930e54dd74d2396c17400e6e212160b/crates/stela-engine/src/lib.rs): translated-block dispatch/cache, guest memory/system state, pointer authentication and execution services |
| Hardware model | [stela-soc](https://github.com/tylertms/Stela/blob/9c190f250930e54dd74d2396c17400e6e212160b/crates/stela-soc/src/lib.rs): M2 register/device models, interrupt wiring, USB, storage, display, SEP; unknown registers explicitly refuse |
| Composition/network | [stela-runtime](https://github.com/tylertms/Stela/blob/9c190f250930e54dd74d2396c17400e6e212160b/crates/stela-runtime/src/lib.rs): board mounting, restore, host storage and raw-Ethernet protocols |
| Graphics | [Metal host service](https://github.com/tylertms/Stela/blob/9c190f250930e54dd74d2396c17400e6e212160b/crates/stela-driver-gpu/src/metal/service.rs), [guest driver](https://github.com/tylertms/Stela/blob/9c190f250930e54dd74d2396c17400e6e212160b/guest/stela-gpu/kext/StelaGPUUserClient.cpp), Mesa/NVK/NIR and LLVM build integration |
| Guest UI | [UpdatesView.swift](https://github.com/tylertms/Stela/blob/9c190f250930e54dd74d2396c17400e6e212160b/guest/stela-app/Sources/Stela/UpdatesView.swift): version/setup-record inspection and opening System Settings, not a demonstrated independent automatic updater |

The separation between immutable formats/contracts, CPU execution, device models, and platform adapters is a genuine strength. Native and hosted builds share substantial Rust code. Nevertheless, Rust does not eliminate unsafe MMIO/DMA, generated machine code, FFI, kernel-driver, and guest-kernel trust boundaries.

## Key Features and Claim Assessment

### ARM translation with retained work

The README claims more than 3,000 AArch64 instruction encodings and x86-64-v2 compatibility. The compiler and engine are substantive implementations rather than just command wrappers; this review did not enumerate encoding coverage or establish instruction-level equivalence. Translation packs are keyed to translator identity, bounded, and recoverable on corruption; the installer provisions a spare so firmware need not grow files at boot. [Translation-store management](https://github.com/tylertms/Stela/blob/9c190f250930e54dd74d2396c17400e6e212160b/crates/stela-cli/src/setup/translations.rs) keeps one translator pack and a 64 MiB pipeline store, and prunes stale packs during repair/update. Checksums and identity binding provide corruption/staleness checks, not a reason to trust writable boot media against a malicious local actor.

### Metal on supported NVIDIA hardware

The project advertises GTX 16/RTX 20 and newer, Metal3 and Apple7, with AIR shader IR translated toward NIR. Source includes a Metal service, resource/queue/lifecycle handling, a guest IOKit user client and Objective-C Metal bundle, plus Mesa/LLVM integration. [GPU discovery](https://github.com/tylertms/Stela/blob/9c190f250930e54dd74d2396c17400e6e212160b/crates/stela-driver-gpu/src/lib.rs) carefully distinguishes an enumerated adapter from an initialized accelerator. Finding AMD/Intel vendor enums is not proof those GPUs work. No GPU, Metal conformance, application compatibility, or speed claim was independently tested.

### Installer repair is more developed than the short README suggests

[Creation](https://github.com/tylertms/Stela/blob/9c190f250930e54dd74d2396c17400e6e212160b/crates/stela-cli/src/setup/create.rs) rejects internal disks for the USB-erasure path, requires confirmation for destructive formatting, checks input placement, and rechecks selected-media identity before erase. [Updates](https://github.com/tylertms/Stela/blob/9c190f250930e54dd74d2396c17400e6e212160b/crates/stela-cli/src/setup/update.rs) prepare new content first, activate recorded state, then prune old content; interrupted operations can be repeated. These are useful safeguards, not transactional protection against every power failure or wrong operator choice. The update implementation explicitly says **there is no rollback**.

## Security, Privacy, and Authority

### Bare-metal trust, not a sandbox

Setup needs administrator/root disk authority and intentionally erases the selected USB. Installation also requires an empty target GPT partition and destructive restore choices. Boot requires **Secure Boot off** per upstream requirements. The boot program then manages physical memory, PCI/MMIO, interrupts, DMA, networking and storage. There is no SaaS login/RBAC/CORS boundary to evaluate; possession of the boot medium, local administrative access, guest driver interfaces, and firmware/device isolation are the relevant boundaries. Do not treat this layer as an isolation boundary for hostile guests.

### The SEP is Stela's software, not Apple's hardware security

[SEP firmware](https://github.com/tylertms/Stela/blob/9c190f250930e54dd74d2396c17400e6e212160b/crates/stela-soc/src/sep/firmware.rs) states that Apple's encrypted sepOS cannot run here: Stela implements its own SEP under an explicit TSS-free trust policy. Container measurements/signature evidence are not asserted to be Apple-verified boot. [Key derivation](https://github.com/tylertms/Stela/blob/9c190f250930e54dd74d2396c17400e6e212160b/crates/stela-soc/src/sep/keys.rs) likewise distinguishes its UID/GID substrate from Apple's secret hardware KDF. A familiar macOS login or encryption UI therefore must not be read as equivalent Secure Enclave, physical extraction resistance, or verified-boot assurance. This is an architectural distinction, not a claimed exploit.

### Credentials and exports need physical protection

[Wi-Fi setup](https://github.com/tylertms/Stela/blob/9c190f250930e54dd74d2396c17400e6e212160b/crates/stela-cli/src/setup/wifi.rs) masks interactive input but writes the passphrase in **plaintext** to `EFI/stela/wifi.key` on the ESP; the plan discloses this. The setup record keeps the SSID/country, not the password. Prefer a disposable isolated network or wired install rather than putting a valuable network password on a portable USB.

[State backup](https://github.com/tylertms/Stela/blob/9c190f250930e54dd74d2396c17400e6e212160b/crates/stela-cli/src/setup/state.rs) exports NVRAM and the SEP area, including machine keys, with identity metadata and SHA-256. It creates a new file with mode 0600 on Unix; Windows inherits directory ACLs. It does **not encrypt that export**. Restore checks the original machine identity; this is not a general migration facility. Protect backup media separately and do not attach state backups to public issue reports.

### Egress is real and not uniformly HTTPS

Install preparation obtains macOS images/catalogues, public archive keys, signing responses, and sometimes hardware firmware. [Historical image metadata](https://github.com/tylertms/Stela/blob/9c190f250930e54dd74d2396c17400e6e212160b/crates/stela-cli/src/restore/history.rs) uses ipsw.me; public AEA keys use an [HTTPS host/path allowlist and redirect restrictions](https://github.com/tylertms/Stela/blob/9c190f250930e54dd74d2396c17400e6e212160b/crates/stela-cli/src/restore/aea.rs). [Boot-time ranged downloads](https://github.com/tylertms/Stela/blob/9c190f250930e54dd74d2396c17400e6e212160b/crates/stela-boot/src/engine/remote.rs) use source length/entity-tag identity and manifest checks; HTTPS depends on admitted clock and entropy capabilities. Firmware recipes name [linux-firmware and wireless-regdb sources](https://github.com/tylertms/Stela/blob/9c190f250930e54dd74d2396c17400e6e212160b/crates/stela-loader/src/host_firmware/recipes.rs).

However, [setup TSS transport](https://github.com/tylertms/Stela/blob/9c190f250930e54dd74d2396c17400e6e212160b/crates/stela-cli/src/boot/ticket.rs) explicitly POSTs to `http://{host}{path}`, with the [TSS host](https://github.com/tylertms/Stela/blob/9c190f250930e54dd74d2396c17400e6e212160b/crates/stela-runtime/src/restore/tss.rs) set to gs.apple.com. This exposes request metadata/identifiers to the network and lacks TLS server authentication on that leg. Recognizing a STATUS-prefixed response is not transport authentication; downstream ticket validation must be considered separately. This review did not prove ticket forgery or bypass.

No model provider, API-token billing, paid AI call, or model download is part of the inspected purpose. Costs are compatible hardware, storage, substantial downloads/build time and power; Apple software/service terms remain separate. No application telemetry sink was identified in sampled paths, but this is not a whole-program no-egress certification. macOS and applications have their own networking and account behavior, untested here.

## Persistence, Retention, and Recovery

- Installer USB: bootloader/configuration, setup record, restore bundles/media, firmware, translation/pipeline caches, and boot log. Some install flows stream images; larger media can hold the full image. The release history shows this policy evolving rapidly—do not assume every install is offline.
- Installed system: macOS data plus NVRAM/SEP machine state on a recorded state partition or designated partition tail. Preserve both system data and machine keys; a state-only backup is not a full disk/user-data backup.
- Boot logs persist on the USB and, when space permits, the machine-state area; [log code](https://github.com/tylertms/Stela/blob/9c190f250930e54dd74d2396c17400e6e212160b/crates/stela-boot/src/log_file.rs) spans firmware and native-driver phases. Logs can contain hardware identifiers, paths, addresses and download metadata. Inspect/redact before sharing; no comprehensive retention/privacy policy was established.
- [Uninstall](https://github.com/tylertms/Stela/blob/9c190f250930e54dd74d2396c17400e6e212160b/crates/stela-cli/src/setup/uninstall.rs) removes recorded Stela USB artifacts and Wi-Fi key but **keeps installed macOS, NVRAM and SEP state**. Deleting the bootloader is not erasing the installation or its secrets; deletion is not secure sanitization.
- [Update handling](https://github.com/tylertms/Stela/blob/9c190f250930e54dd74d2396c17400e6e212160b/crates/stela-cli/src/setup/update.rs) distinguishes replacing Stela from replacing installer media; installed macOS has its own Software Update boot path. That code path is not proof arbitrary future macOS updates will work. Keep independent offline backups and a separate known-good boot environment.

## Platform and Supply-Chain Notes

Upstream minimums are x86-64-v2, UEFI with Secure Boot disabled, 8 GB RAM, supported NVIDIA GPU, USB at least 8 GB, and an empty GPT partition at least 60 GB. These are stated requirements, not a qualified-machine matrix. The Linux release targets glibc 2.35+, Windows is x86-64, and macOS CLI archives are universal. A Mac installer binary does not make this an Apple-silicon Mac virtualization product.

Source builds require Rust 1.99.1 per [toolchain file](https://github.com/tylertms/Stela/blob/9c190f250930e54dd74d2396c17400e6e212160b/rust-toolchain.toml), Clang/LLVM 21+ per README, and fetch/build substantial Linux, Mesa, LLVM and related sources. [Git submodules](https://github.com/tylertms/Stela/blob/9c190f250930e54dd74d2396c17400e6e212160b/.gitmodules) are commit-pinned by the repository; Cargo.lock and firmware recipes improve reproducibility. A plain GitHub source ZIP omits submodule contents; the release workflow separately assembles corresponding source.

[Release CI](https://github.com/tylertms/Stela/blob/9c190f250930e54dd74d2396c17400e6e212160b/.github/workflows/release.yml) checks version/tag alignment, constructs guest app → EFI → CLI artifacts, checks embedded EFI bytes, packages license texts, and publishes SHA256SUMS. Those checks are positive evidence of packaging discipline, not a boot test or an independent signature. Actions use version tags rather than immutable action SHAs; macOS signing shown is ad hoc. No independent release-signing/attestation guarantee was established. Do not run build or installer commands merely to inspect this project on a daily-use machine.

## License and Reuse

The [LICENSE](https://github.com/tylertms/Stela/blob/9c190f250930e54dd74d2396c17400e6e212160b/LICENSE) supplies GPL v2 text; [NOTICE](https://github.com/tylertms/Stela/blob/9c190f250930e54dd74d2396c17400e6e212160b/NOTICE) and workspace manifest explicitly choose GPL-2.0-or-later for own code. NOTICE distinguishes the Linux-containing **stela.efi (GPL-2.0-only)** from the CLI linking Apache-licensed crates **(GPL-3.0-or-later)**; the EFI is aggregated inside, not linked into, the CLI. Other guest/maintenance components and third-party files retain their stated terms. Binary redistribution requires corresponding source, pinned dependencies/patches, scripts and notices—not just a link to a moving main branch. No code was extracted for this review.

macOS, Apple firmware/services and third-party firmware do not become GPL merely because Stela is. Evaluate Apple's applicable software-license and hardware restrictions before use; the README's legal disclaimer is not permission or legal clearance.

## Maturity and Verification

Public GitHub metadata observed on 2026-11-11: repository created 2026-10-12; 389 stars, 11 forks, two open issues; last push 2026-11-11T20:06:48Z. Both v0.1.0 and v0.2.0 were published on November 11, with v0.2.0 at 15:51:23Z. The reviewed main commit is later than that release; README prose still says “as of v0.1.0.” Do not conflate main with the downloadable binary.

[CI](https://github.com/tylertms/Stela/blob/9c190f250930e54dd74d2396c17400e6e212160b/.github/workflows/ci.yml) formats the workspace and runs CLI-only Clippy/library tests on Linux, Windows and macOS. It does **not** run the full translator/SoC/GPU/boot acceptance suite. The inspected revision's public CI was pending during observation, not a passing result. [xtask check](https://github.com/tylertms/Stela/blob/9c190f250930e54dd74d2396c17400e6e212160b/xtask/src/check.rs) defines broader cross-target checks, and the tree contains substantial synthetic tests for installer recovery, TLS, device models and translation. Their presence is not proof they pass or cover real machines.

The [v0.2.0 release notes](https://github.com/tylertms/Stela/releases/tag/v0.2.0) include reverts of native transition optimizations after early watchdog resets and a hold on firmware MMIO admission pending proof. [Issue #10](https://github.com/tylertms/Stela/issues/10) reports a boot page fault on Ryzen 5 1600/RTX 3060 Ti. This is a user report, not a reproduced diagnosis, but consistent with upstream's explicit hardware warning.

**Checks performed:** anonymous public acquisition, exact source SHA, metadata/releases/workflow inspection, canonical-URL duplicate search, targeted source tracing, and publication-artifact validation. **Not performed:** compiling/running upstream code or tests, submodule acquisition, vulnerability scanning, binaries-to-source reproducibility, hardware/performance/conformance tests, account activation or future-update compatibility. No live exploit/security testing was attempted.

## Comparison

| Option | Practical difference |
|---|---|
| Stela | ARM macOS on x86 PCs through translation and modeled Apple hardware; unusually ambitious, but immature and broad-trust |
| [OpenCore](https://github.com/acidanthera/OpenCorePkg) | Boot environment for compatible platforms; not an ARM-to-x86 translator or replacement Apple GPU/SEP implementation |
| [QEMU](https://www.qemu.org/) | Mature general emulation infrastructure; generic ARM emulation alone does not provide compatible Apple-silicon macOS hardware/security/Metal support |
| [UTM](https://mac.getutm.app/) / macOS virtualization on a supported Mac | More practical route for ordinary Mac-hosted guest use; different hardware requirement and not a way to turn arbitrary x86 hardware into an Apple-silicon Mac |
| [darwin-vm review](darwin-vm.md) | Narrow Darwin/XNU research harness; appropriate comparison for kernel experiments, not equivalent to a usable accelerated desktop |

**Practical call:** read/follow it if CPU translation, OS bring-up or GPU driver engineering is your goal. Only consider disposable, explicitly authorized lab hardware after checking current known-good reports and making full backups. For dependable macOS applications or sensitive credentials, use supported Apple hardware rather than assuming boot success, Secure Enclave equivalence, or reliable upgrades here.

---

**Attribution:** tylertms/Stela and its contributors; own code GPL-2.0-or-later, component/distribution distinctions above. This is independent analysis of public source, not an endorsement or legal clearance.
