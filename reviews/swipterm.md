# Swipterm (swipt-automation/Swipterm)

**Repo:** https://github.com/swipt-automation/Swipterm
**License:** GPL-3.0-or-later notice plus an additional name/association restriction; inspect the actual terms before redistribution.
**Reviewed:** 2026-11-25 (UTC)
**Revision:** c70bb3b33538377fe2cae97b5f837eaa26ae8a39, default branch main; application, provisioning, host bridges, dependency lockfile, build/release workflow and screenshot tooling.
**Verification:** Static review only. Anonymous GitHub API and credential-free HTTPS Git access confirmed public accessibility. No application builds, tests, installs, guest execution, accounts, device access or service probes were performed.
**Stack:** Swift 6, SwiftUI/UIKit, SwiptermKit, libghostty, GRDB/SQLite; Go release and screenshot tooling.
**What it is:** An on-device ARM64 Linux environment and Ghostty-based terminal for iOS, not a browser terminal service or an AI-agent orchestration platform.

---

## Verdict

⚠️ **Interesting — credible mobile Linux integration, not yet a trusted execution sandbox.** The app implements real distro provisioning, terminal tabs and native host bridges. Its guest has broad authority, optional network services and access to sensitive host capabilities; recovery, supply-chain verification and emulator isolation need further validation before important workloads or credentials belong here.

## What It Is

Swipterm targets developers who want a Linux shell and tooling locally on an iPhone or iPad. A SwiftUI app provisions a root filesystem, boots a Linux runtime supplied by SwiptermKit, and connects guest terminal sessions to libghostty surfaces. There is one installed root/runtime in the inspected application; tabs are multiple shells in that same environment, not separate containers or security principals. [1][2][3]

The catalog enumerates fourteen distributions, including Alpine, Debian, Ubuntu, Arch and Void. Setup also accepts a local archive or remote archive URL. The app can install development tools and Claude Code, Codex or Antigravity CLI; these are optional guest programs, not built-in models or an app-level agent permission system. [4][5]

## Stack

| Layer | Tech |
|---|---|
| UI / platform | Swift 6, SwiftUI/UIKit; project deployment target iOS 17.0 |
| Guest runtime | SwiptermKit 0.2.2026112502, locked to 6adc43a7b690d163957db90fb48c04eb83539c48 |
| Terminal | libghostty-spm 2.2.2026112303; DisplayLink 3.0.1 |
| Preferences | GRDB 7.12.0, SQLite with JSON-encoded values |
| Installation | Rootfs archive importer, distribution-specific kernel bootstrap, guest shell provisioner |
| Release tooling | Xcode/macOS, Make, Go 1.26.8, GitHub Actions, Apple signing for distribution |

The lockfile records exact Swift package revisions; the emulator, networking implementation, archive extraction and terminal engine are upstream dependencies, not implemented entirely in this repository. They were not independently audited here. [6]

## Key Features

### Linux distribution and software provisioning

Catalog and custom-rootfs paths are implemented, with staged extraction, kernel selection and managed/system init modes. Setup supports shells, development packages, optional SSH, and coding-agent installation. This is substantially more than terminal rendering, but the README's “any distribution, any Linux kernel” is too broad: the app explicitly reports a requirement for a bootable 4K-page ARM64 kernel, and excludes some catalog releases. [2][4][5][7]

### Terminal tabs and native integration

The reviewed commit adds terminal tabs. Session manager code creates, selects, reorders and closes sessions; closing the last creates a replacement. Themes, fonts and Ghostty configuration have dedicated settings views. Host integration includes clipboard exchange, pasted-file staging, URL-opening prompts, and a guest command for device location and background keepalive. These are useful capabilities and meaningful trust boundaries. [3][8][9]

### Optional JIT and background execution

JIT code is gated to DEBUG or SIDELOAD builds. It discovers Swipt using Bonjour, accepts a resolved address only if it belongs to the device, then contacts a loopback HTTP endpoint. It optionally sends a bearer token and asks Swipt to enable JIT for the app's bundle ID and PID. This is not a demonstrated arbitrary remote-LAN bearer-token transmission; it is still a local privileged-service trust dependency. [10]

Background operation uses CoreLocation authorization and a keepalive preference. Without keepalive, the runtime suspends after its iOS background task expires and resumes in the foreground. That is not durable execution after OS termination. The README's “does not ... drain your battery” language is not established by code: coarse accuracy and a maximal distance filter reduce location work, but neither proves zero battery cost, especially while guest processes run. [1][2][11]

## Architecture

SwiptermApp routes setup, provisioning, boot, running, halted and failed states. LinuxSystem owns the singleton runtime, installed metadata, lifecycle notifications, boot retries and provisioning transitions. TerminalSessionManager owns in-memory sessions; each obtains a PTY and logs in as the configured guest user. Generation counters invalidate stale asynchronous work; teardown is serialized before subsequent boots. [2][3]

Installation downloads or copies an archive into staging, builds a root, installs a kernel for catalog distributions, and records metadata. Provisioning runs a shell script inside the guest. Completion clears the setup payload from metadata; failures preserve enough state for retry. Native callbacks bridge guest commands to selected iOS features. This is an application boundary around an emulator, not evidence that hostile kernels or programs are safely contained. [2][5][7]

## Execution Authority, Authentication and Privacy

- **Tabs are not isolation.** Every tab logs into the same runtime/root with the configured default user. There is no app-level approval gate for each shell command. The provisioner grants the selected non-root user passwordless sudo when available, passwordless doas when available, and permissive polkit rules when applicable. Selecting a non-root account therefore does not create a least-privilege workload boundary. Guest root is not automatically iOS root, but emulator and bridge vulnerabilities remain outside this review. [2][3][5]
- **SSH is opt-in, not absent.** Setup defaults SSH off, port 10022, with password authentication selected when enabled. Public-key and mixed modes are available. Root plus password mode explicitly permits root login; no app-generated ListenAddress restriction is present in the inspected SSH configuration. Actual host binding/reachability depends on SwiptermKit and was not tested. Prefer public-key-only authentication and verify exposure before enabling it. CORS/web-session controls are not the relevant boundary: this is a native app with an optional guest sshd. [5][12]
- **Host capabilities cross the guest boundary.** The app registers /dev/clipboard and host clipboard services; the device handler reads the general pasteboard and writes back on close without its own per-process confirmation. iOS permission behavior still applies. Pasted files are staged and mounted read-only where supported, rather than mounting the whole host filesystem. Location commands can request precise data or stream updates under iOS authorization. A location grant is not a separate grant per guest program. URL opening shows an action sheet, including non-web schemes, rather than blindly launching all guest-supplied URLs. [8][9][11]
- **Credentials are not uniformly in a keychain.** The Swipt token is JSON-encoded in the SQLite preference store; no Keychain use appears in that path. A setup password is temporarily serialized in machine metadata with iOS file protection until first authentication and passed to the guest provisioner via an environment variable. It is removed from metadata on successful setup, but can remain during failed/interrupted provisioning. These are app-container protections, not independent secret-vault encryption. [2][10][13]
- **Local does not mean offline or free of egress.** Distribution images, kernel repositories, package registries and optional language/agent installers use network downloads. LinuxSystem also makes a request to Apple's captive portal endpoint in its network-authorization path. Optional coding agents may send code/prompts and use their own credentials/accounts and billable services; this app provides no model-spend cap. No mandatory app backend subscription or embedded metered-model call was identified in the reviewed application, but distribution/signing and third-party service costs remain separate. The privacy manifest declares no tracking and no collected data types; it is a declaration, not a traffic audit of guests or dependencies. [2][5][7][14]

## Persistence, Recovery and Export

The guest root persists in application-support storage, with atomic machine-metadata writes and installation staging. Restart and provisioning retry exist; boot handling caps repeated reboots. Reset moves the root to temporary trash and schedules deletion, so this is not a user-restorable recycle bin. [2]

Preferences live in SQLite. Corruption/not-a-database errors trigger deletion and recreation, and the migrator enables database erasure on schema change. That favors recovery of app startup over preservation of settings and the stored JIT token. [13]

Sessions and terminal state are held in memory; no app-level persistent shell/process snapshot, terminal history export or rootfs backup/export UI was found in the inspected Swift sources. Guest files surviving an app restart does not imply running processes survive it. Guest-native archive/SSH transfer may be useful, but was not tested as a recovery workflow. Keep independent backups before reset or upgrades and do not assume iOS background keepalive is a reliability guarantee. [2][3]

## Supply Chain, Licensing and Maturity

**Integrity gap at the application layer.** RootImageDownloader checks HTTP success but accepts no expected digest. The rootfs install path passes the archive into the builder without an app-level digest/signature comparison. Void's checksum listing is parsed to discover filenames; the digest is not carried in LinuxReleaseImage or compared by this path. Kernel bootstrap and optional tool installers add more upstream trust. This is a concrete missing app-level verification step, not a proven malicious artifact or a complete audit of dependency internals. Prefer verified artifacts and add digest/signature validation before extracting or executing downloaded software. [2][4][7][15]

**Build evidence is narrower than test evidence.** The observed GitHub Build run for this exact SHA completed successfully. The workflow builds/publishes artifacts; it does not establish a security or runtime regression test suite. Screenshot XCTest coverage and two Go screenshot-tool test files exist, but no app emulator/SSH/permission/recovery test suite was found in the reviewed tree. No tests were run for this review. Some Actions are pinned to commit hashes (checkout), while setup-go/cache/artifact actions use movable major tags. Make invokes Xcode with macro validation skipped, increasing reliance on trusted build inputs. [16][17]

**Release and activity snapshot.** On 2026-11-25, anonymous metadata reported 136 stars, 8 forks and zero open issues/PRs in GitHub's combined open_issues_count field; last push was 2026-11-25T21:41:06Z. The releases endpoint returned one release, the mutable nightly published at 2026-11-25T21:41:11Z. Its annotated tag object was c13042af3e5de7fe095631ea4fd2ce084dffc9ab and peeled to the reviewed SHA. No stable release appeared in that response. The workflow deliberately moves nightly; pin the commit, not that label. Popularity and a green build are not safety evidence. [18]

**License caution.** LICENSE contains a GPL v3-or-later grant and a further clause prohibiting derivative use of the name or implied association without prior consent. It is not simply an MIT-style permissive grant; GitHub reports Other/NOASSERTION. Preserve notices, evaluate GPL source/distribution obligations, rename forks as needed and seek clarification on the additional clause if redistributing. Component and distro licenses also apply. This review redistributes no implementation code. [19]

## Claims Versus Evidence

| Claim | Assessment |
|---|---|
| “Any distribution, any Linux kernel” | Custom imports and broad catalog are real; kernel architecture/page-size and distribution constraints remain. |
| Fast even without JIT | README publishes Lua/Git/Go timing comparisons against iSH variants; no independent benchmark was performed. Device conditions, repeatability and workload coverage need validation. |
| Automatic JIT | Supported by conditional client integration; not proven on a device, and external Swipt is required. |
| Background without battery drain | Coarse location keepalive exists; zero battery cost and uninterrupted OS background execution are not established. |

## Comparison

These are architectural alternatives, not a fresh performance or security audit of the alternatives.

| Option | Best fit | Tradeoff versus Swipterm |
|---|---|---|
| [iSH](https://github.com/ish-app/ish) | Established iOS Linux-shell approach using x86 emulation/syscall translation | Different compatibility model from Swipterm's ARM64 Linux-kernel runtime; benchmark superiority is unverified here. |
| [UTM](https://github.com/utmapp/UTM) | Broader VM/emulation workflows and machine configuration | More general machine-oriented approach; Swipterm focuses on terminal-first distro provisioning and native host bridges. |
| SSH to a separately managed Linux host | Durable compute sessions and server-side backups | Requires a host/network and its administration/cost; avoids depending on an iOS app staying alive, but moves trust and data to that host. |

## Self-Hosting Notes

This is locally installed iOS software, not a server to deploy behind a reverse proxy. The README offers TestFlight and nightly sideloading. Source builds require Apple's toolchain; CI uses xcode-27 runners and signing material for Apple distribution. Do not confuse a successful IPA build with verified TestFlight availability or App Store approval. [1][16]

For an evaluation, use disposable guest data, leave SSH and JIT disabled initially, minimize clipboard/location permissions, install only trusted images, and separately verify emulator boundaries, network listeners, export/restore and background behavior. Audit SwiptermKit and the binary terminal distribution before treating this as an environment for untrusted code. These are recommended next checks, not checks performed here.

## Evidence and Verification Limits

All source citations below are pinned to the reviewed commit. Public metadata/release/workflow links are time-sensitive. Static inspection cannot prove emulator isolation, archive traversal resistance, network binding, actual battery/performance behavior, distribution compatibility, binary reproducibility or absence of telemetry in dependencies. No source instructions were executed, dependencies installed, external accounts created, paid services called or private data used. Canonical-source deduplication found no prior matching review, so this is a new review rather than a refresh.

[1]: https://github.com/swipt-automation/Swipterm/blob/c70bb3b33538377fe2cae97b5f837eaa26ae8a39/README.md
[2]: https://github.com/swipt-automation/Swipterm/blob/c70bb3b33538377fe2cae97b5f837eaa26ae8a39/Swipterm/Shared/LinuxSystem.swift
[3]: https://github.com/swipt-automation/Swipterm/blob/c70bb3b33538377fe2cae97b5f837eaa26ae8a39/Swipterm/Terminal/TerminalSessionManager.swift
[4]: https://github.com/swipt-automation/Swipterm/blob/c70bb3b33538377fe2cae97b5f837eaa26ae8a39/Swipterm/Setup/LinuxDistributionCatalog.swift
[5]: https://github.com/swipt-automation/Swipterm/blob/c70bb3b33538377fe2cae97b5f837eaa26ae8a39/Swipterm/Provisioning/ContainerProvisioner.swift
[6]: https://github.com/swipt-automation/Swipterm/blob/c70bb3b33538377fe2cae97b5f837eaa26ae8a39/Swipterm.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved
[7]: https://github.com/swipt-automation/Swipterm/blob/c70bb3b33538377fe2cae97b5f837eaa26ae8a39/Swipterm/Provisioning/KernelBootstrap.swift
[8]: https://github.com/swipt-automation/Swipterm/blob/c70bb3b33538377fe2cae97b5f837eaa26ae8a39/Swipterm/Shared/ClipboardDevice.swift
[9]: https://github.com/swipt-automation/Swipterm/blob/c70bb3b33538377fe2cae97b5f837eaa26ae8a39/Swipterm/Shared/OpenURLPrompt.swift
[10]: https://github.com/swipt-automation/Swipterm/blob/c70bb3b33538377fe2cae97b5f837eaa26ae8a39/Swipterm/JIT/SwiptJIT.swift
[11]: https://github.com/swipt-automation/Swipterm/blob/c70bb3b33538377fe2cae97b5f837eaa26ae8a39/Swipterm/Shared/HostLocation.swift
[12]: https://github.com/swipt-automation/Swipterm/blob/c70bb3b33538377fe2cae97b5f837eaa26ae8a39/Swipterm/Setup/SetupSoftwareViews.swift
[13]: https://github.com/swipt-automation/Swipterm/tree/c70bb3b33538377fe2cae97b5f837eaa26ae8a39/Swipterm/Model
[14]: https://github.com/swipt-automation/Swipterm/blob/c70bb3b33538377fe2cae97b5f837eaa26ae8a39/Swipterm/PrivacyInfo.xcprivacy
[15]: https://github.com/swipt-automation/Swipterm/blob/c70bb3b33538377fe2cae97b5f837eaa26ae8a39/Swipterm/Setup/RootImageDownloader.swift
[16]: https://github.com/swipt-automation/Swipterm/blob/c70bb3b33538377fe2cae97b5f837eaa26ae8a39/.github/workflows/build.yml
[17]: https://github.com/swipt-automation/Swipterm/actions/runs/45706083693
[18]: https://github.com/swipt-automation/Swipterm/releases/tag/nightly
[19]: https://github.com/swipt-automation/Swipterm/blob/c70bb3b33538377fe2cae97b5f837eaa26ae8a39/LICENSE

---

**Attribution:** swipt-automation/Swipterm, copyright 2026 nekohasekai; GPL-3.0-or-later notice with additional name/association restriction. Independent static analysis; no endorsement implied.
