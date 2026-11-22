# WinRust (Lemxy/WinRust)

**Repo:** https://github.com/Lemxy/WinRust
**License:** MIT OR Apache-2.0, at the recipient's option; preserve the chosen license's notices and obligations. Dependency terms remain separate.
**Reviewed:** 2026-11-22 (UTC)
**Revision:** `8db0b2f656ee41d6ae389cea78810a26cd8462f6`, tag v0.5.5, main at acquisition; root installer, common library, shell/search/settings and representative utility code, build/release workflow.
**Verification:** Static source review and unauthenticated public GitHub metadata checks only. No build, source tests, binary execution, installation, Windows interaction or security probes performed.
**Stack:** Rust 2024, Windows Win32/GDI/COM APIs, PowerShell and Windows command-line utilities; native executables.
**What it is:** A Windows 10/11 x64 replacement shell and system-utility suite, not a Rust Windows compatibility layer or operating system.

---

## Verdict

📚 **Study — ambitious native desktop engineering, not a daily-driver recommendation yet.** Small native components, explicit recovery code and signed-update verification are useful ideas. But this very young project combines shell replacement with SYSTEM tasks and system tuning, has incomplete release-update delivery, and cannot substantiate blanket reversibility or general performance superiority. Keep evaluation on a disposable Windows VM; do not treat this review as installation approval.

## What It Is

Lemxy packages a taskbar, tabbed file manager/desktop, NTFS filename search, Task Manager, settings UI, disk cleaner/map and photo viewer into one elevated installer. These are separate native programs, coordinated by installation functions and shared UI/Windows helpers. The browser experiment chrome-rs exists but is not an installable suite component. [1][2]

This is materially more invasive than adding a launcher: selected components disable Windows Search, redirect taskmgr.exe via Image File Execution Options (IFEO), replace folder-opening verbs and can terminate Explorer's shell while disabling its automatic restart. rust-explorer is initially unselected; debloat and irreversible purge are opt-in Extras in the actual v0.5.5 UI. The README's “command line only” description of these Extras is stale. [1][3]

## Stack

| Layer | Technology / boundary |
|-------|-----------------------|
| Installer | Rust plugin table; GUI and CLI call shared install/uninstall functions |
| Desktop | Win32/GDI/GDI+, COM shell integration; topbar, rust-explorer, rs-shell and reshell |
| Search | Raw NTFS MFT scan, USN journal maintenance, saved snapshots, named-pipe queries |
| Shared code | winrust-common: registry parsing, change journals, styling, translations, MFT helpers |
| Updates | System curl.exe over HTTPS; Ed25519 manifest signature; SHA-256 file hashes |
| Archives | Custom ZIP/deflate engine; sevenz-rust2 for 7z; independent zip crate in tests |
| Build | MSVC Windows toolchain, embed-resource, Cargo lockfiles; separate rust-search/chrome-rs projects |
| Authorization | Windows accounts, UAC, task principals, filesystem ACLs and pipe security; no web login/service API |

## Key Features and Claim Checks

### Native composition, with a sizeable unsafe/OS boundary

The installer embeds programs listed in payload.txt through build.rs. Most crates share one workspace/lockfile; rust-search and chrome-rs stay separate because they need unwinding rather than the workspace release panic-abort profile. This keeps distribution simple, not isolation strong: native processes use Windows privileges, registry state and command execution directly. Rust does not make the unsafe Win32/COM boundary or destructive operations automatically safe. [2]

File copying and archiving run on worker threads with progress notifications. ZIP has path checks and interoperability test code against another implementation. These are positive engineering signals, not a completed audit of malicious archives, resource exhaustion or Windows filesystem edge cases. [4]

### Performance claims are narrower than the headline

The README advertises large speed/memory improvements, but also discloses that measurements were one-off on one machine. Indexed filename search is compared with fresh directory traversal, not Windows Search; shell memory includes a still-running Explorer; copy/ZIP results used warm caches and single runs. These measure different workloads and do not demonstrate universal “64–99% faster” Windows behavior. No benchmarks were reproduced here. [1]

### Signed updates exist in code, not in the latest release delivery

The updater validates an Ed25519 signature before parsing the manifest, restricts executable names, checks SHA-256, maps names to known destinations and rejects versions older than its saved installed-version file. Staging under Program Files is a sensible defense against ordinary-user replacement when ACLs are intact. [5]

However, the public v0.5.5 release contains **only WinRust.exe**: no manifest.txt, manifest.sig or per-component executables. Its release notes explicitly acknowledge that automatic updates have nothing to fetch. The README's operational auto-update description is therefore ahead of the published release. An enabled SYSTEM task can still attempt the checks; it does not make this release auto-updatable. Manual installer replacement remains the documented route. [6]

## Architecture, Permissions and Security

### Privilege is persistent, not just an install-time prompt

The manifest requires administrator rights. The installer identifies the interactive session user's SID, including when UAC uses another administrator account, and redirects per-user registry/task/profile operations accordingly; installation stops if identification fails. Uninstall instead falls back with a warning, which may clean the elevated account rather than the intended user's state in a broken session. [7]

Search installs one SYSTEM boot task per fixed NTFS drive. The updater runs as SYSTEM at boot and daily. topbar and Task Manager register interactive tasks with Highest run level; reshell and the shell overlay use Limited. Ordinary app launching is intended to go through Explorer to shed elevation, but that routing should not be assumed correct in every shell-replaced session. A public pending fix specifically addresses Explorer-based launching. This is a mixed-privilege desktop, not a sandbox. [3][7][8]

### Search access restricts clients, not each returned filename

Search's explicit pipe descriptor grants access to SYSTEM, Administrators and the selected user SID; first-instance creation helps prevent pipe squatting. But the SYSTEM index scans raw NTFS, and query/render return paths without an observed per-result impersonation/access check. Thus the allowed user can potentially learn names/paths from otherwise inaccessible locations; this is metadata exposure, not proof of file-content access or code execution. Multi-user privacy deserves validation before adoption. The synchronous single-instance pipe also has no observed per-client read timeout, leaving a potential availability problem from an allowed client. No exploit was attempted. [8]

### Credentials and egress

No project account, API key or hosted backend is needed for core shell/search use. That does **not** mean wholly offline: update/version checks contact GitHub release URLs and follow download redirects; optional updater consolidation invokes winget; network settings intentionally configure Wi-Fi/VPN/proxy and interact with Windows services. No general telemetry uploader was identified in the reviewed core paths; this is not a full network audit of every component, and the non-installable browser is outside that conclusion. [5][9]

Wi-Fi credentials are passed through Windows WLAN profile APIs. XML text is escaped and selected UTF-16 buffers are wiped, but intermediate Rust strings are not demonstrated to be comprehensively zeroized. The PEAP profile leaves ServerNames empty, supplies no explicit trusted-root restriction and disables user prompts for server validation; the source describes relying on system trusted roots. This is not a certificate-validation-off finding, but it lacks organization-specific authentication-server binding. Prefer organization-managed WLAN profiles for enterprise credentials; Windows policy/default interactions were not tested. VPN uses previously saved Windows credentials. [9]

Local state includes ProgramData style/language settings and installation logs, per-user run/settings history, search snapshots in the SYSTEM profile and protected rollback records. Those may expose paths or operational details locally; removing the program is not proven to erase all user preferences/history. No secrets were requested or used for source acquisition.

### Supply chain and trust roots

Cargo lockfiles and explicit dependencies improve dependency visibility; they do not prove reproducibility or vulnerability freedom. The checked build workflow uses moving action tags (checkout@v4, rust-cache@v2, upload-artifact@v4), not immutable commit pins. No dependency advisory scan or binary/source reproducibility comparison was performed. [2][10]

The updater's embedded public key authenticates future signed manifests, not the initial installer. The README says the EXE lacks Authenticode signing; that binary property was not independently checked. The release API reports a SHA-256 digest, but a digest from the same release channel is not independent publisher authentication. A release script supports signing from an owner-held private key, and also an OnlyInstaller mode consistent with the current delivery gap. [1][6][10]

Manual/local payload handling has a separate trust boundary: a payload directory next to the launcher overrides embedded programs without the network manifest verifier. The code deliberately limits its development fallback path, but an elevated installer in a user-writable download directory still trusts that neighboring payload. Keep installer location and all payload inputs within the same trusted provenance; signed remote updates do not authenticate arbitrary local overrides. [7]

## Installation, Persistence, Uninstall and Recovery

This is not a self-hosted server. Building expects Windows x64/MSVC and compiles embedded payloads first. The review did not run the installer or reproduce build instructions.

| Component | Persistent/system effects |
|-----------|---------------------------|
| Search | SYSTEM boot tasks, NTFS snapshots, Windows Search disablement, SearchHost IFEO block, launcher logon task/Run fallback |
| Task Manager | taskmgr.exe IFEO redirection, elevation task, shared cleaner and debloat executable |
| topbar | Elevated logon task/Run fallback, hidden stock taskbar, reshell startup, marked blocks in PowerShell profiles |
| rust-explorer | Folder/drive verbs, Limited overlay startup, AutoRestartShell change, optional shell termination; fresh installs adjust five services and svchost grouping threshold |
| Settings/photo/tools | Installed binaries/shortcuts, photo Open-with registrations; optional night-light Run entry |
| Optional tuning | Service/policy changes; optional Defender exclusions, NTFS settings, hosts entries and updater scheduling |
| purge | App removal for all users/provisioned image and telemetry-task deletion; no undo |
| Auto-update | Persistent SYSTEM boot/daily task and installer copy while any plugin remains installed |

Journaling records original registry/service values before mutations and retains a journal when undo fails. New failed component installs attempt their uninstall routine; already-installed updates are not globally rolled back. Components can succeed independently, leaving a partial install. Restore-point creation is only a warning on failure, not an installation prerequisite. [3][7]

Recovery has two layers: reshell watches for a disappeared topbar with a hidden stock tray and retries at most three times; rs-shell has its own Explorer fallback. Neither makes a hung or partially broken desktop impossible. The README's manual escape route is Ctrl+Alt+Del, Task Manager, then explorer.exe and Remove all, but Task Manager itself may have been redirected, so recovery needs real VM testing rather than faith in instructions. [1][11]

**“Every change is reversible” is false as a blanket statement.** purge uninstall removes its executable, not the deleted apps/tasks. Moreover rust-explorer uninstall treats failed folder-verb import as a soft warning and subsequently attempts to delete its directory containing the backup; some cleanup errors elsewhere are ignored. The updater stages files before renaming, but old-to-aside then new-to-destination is two operations: a power cut between them can leave the expected path absent. Its multi-target rollback ignores restoration errors, and component updates are not a whole-release transaction. These are static recovery limitations, not reproduced failures. [3][5][7]

## Maturity and Verification

Public metadata on 2026-11-22: repository created 2026-11-17, last push 2026-11-22, approximately 1,143 stars and 65 forks; GitHub reported 47 open issues including pull requests. These are a fast-moving interest snapshot, not a quality score. v0.5.5 was published at 2026-11-22T12:55:56Z and its tag resolves to the reviewed SHA. [6][12]

The exact source SHA has a successful public Windows build workflow, [run 45024797484](https://github.com/Lemxy/WinRust/actions/runs/45024797484). The workflow builds all payloads and runs workspace and separate rust-search tests. Test source includes manifest tampering/name checks, update swaps, install selection, registry snapshot recovery, watchdog state transitions and ZIP interop/path validation. This is upstream CI evidence, not tests run by this review; it does not establish real install/uninstall, UAC, crash, multi-monitor or Windows policy compatibility. [4][5][10][11]

Open reports include [a black second screen](https://github.com/Lemxy/WinRust/issues/111), [Windows Hello PIN reset trouble](https://github.com/Lemxy/WinRust/issues/110) and [Settings opening trouble](https://github.com/Lemxy/WinRust/issues/109). These are user reports, not independently confirmed defects. [PR 114](https://github.com/Lemxy/WinRust/pull/114) concerns normal-user process launching and is not part of the reviewed release.

**Limits:** Static targeted inspection, not exhaustive security review. No Windows environment, runtime access-control validation, credential tests, archive fuzzing, power-loss tests, installation, network captures, source tests or benchmarks. Only review-artifact markup/provenance checks were performed locally. No executable release assets were downloaded. Dependencies and alternatives were not installed or newly benchmarked.

## Comparison

Prefer narrower tools if the goal is one capability rather than replacing a desktop:

| Need | Alternative | Tradeoff versus WinRust |
|------|-------------|------------------------|
| Filename search | [Everything](https://www.voidtools.com/) | Focused NTFS search; still requires attention to index/service privileges, but does not require replacing the shell |
| Process inspection | [Process Explorer](https://learn.microsoft.com/en-us/sysinternals/downloads/process-explorer) or [System Informer](https://github.com/winsiderss/systeminformer) | Dedicated diagnostics rather than a combined desktop/debloat suite |
| Disk map | [WinDirStat](https://github.com/windirstat/windirstat) | Focused storage analysis with less shell integration |
| Windows productivity | [PowerToys](https://github.com/microsoft/PowerToys) | Additive utilities while keeping Explorer; not a full substitute shell |
| Minimal operational risk | Built-in Explorer, Search and Task Manager | Fewer novel recovery/authentication boundaries; less aesthetic control |

These are scope comparisons, not fresh audits or speed rankings. WinRust's attractive differentiator is a cohesive small native suite; its cost is combining many sensitive Windows responsibilities into a five-day-old public project.

## Evidence

All source links below are pinned to the reviewed revision; API/release/issue observations are dated snapshots.

1. [README: purpose, installation, benchmarks and warnings](https://github.com/Lemxy/WinRust/blob/8db0b2f656ee41d6ae389cea78810a26cd8462f6/README.md).
2. [Workspace/dependencies](https://github.com/Lemxy/WinRust/blob/8db0b2f656ee41d6ae389cea78810a26cd8462f6/Cargo.toml), [payload build](https://github.com/Lemxy/WinRust/blob/8db0b2f656ee41d6ae389cea78810a26cd8462f6/build.rs).
3. [Installer UI](https://github.com/Lemxy/WinRust/blob/8db0b2f656ee41d6ae389cea78810a26cd8462f6/src/ui.rs), [Explorer changes and uninstall](https://github.com/Lemxy/WinRust/blob/8db0b2f656ee41d6ae389cea78810a26cd8462f6/src/install/explorer.rs), [tools/purge](https://github.com/Lemxy/WinRust/blob/8db0b2f656ee41d6ae389cea78810a26cd8462f6/src/install/tools.rs).
4. [File jobs](https://github.com/Lemxy/WinRust/blob/8db0b2f656ee41d6ae389cea78810a26cd8462f6/plugins/rust-explorer/src/jobs.rs), [ZIP engine/tests](https://github.com/Lemxy/WinRust/blob/8db0b2f656ee41d6ae389cea78810a26cd8462f6/plugins/rust-explorer/src/zipx.rs).
5. [Updater](https://github.com/Lemxy/WinRust/blob/8db0b2f656ee41d6ae389cea78810a26cd8462f6/src/update/mod.rs), [manifest](https://github.com/Lemxy/WinRust/blob/8db0b2f656ee41d6ae389cea78810a26cd8462f6/src/update/manifest.rs), [swap](https://github.com/Lemxy/WinRust/blob/8db0b2f656ee41d6ae389cea78810a26cd8462f6/src/update/swap.rs).
6. [v0.5.5 release and updater caveat](https://github.com/Lemxy/WinRust/releases/tag/v0.5.5), [public release metadata](https://api.github.com/repos/Lemxy/WinRust/releases/454448034).
7. [Shared install and payload trust](https://github.com/Lemxy/WinRust/blob/8db0b2f656ee41d6ae389cea78810a26cd8462f6/src/install/mod.rs), [session identity](https://github.com/Lemxy/WinRust/blob/8db0b2f656ee41d6ae389cea78810a26cd8462f6/src/install/session.rs), [journal](https://github.com/Lemxy/WinRust/blob/8db0b2f656ee41d6ae389cea78810a26cd8462f6/src/install/journal.rs), [topbar](https://github.com/Lemxy/WinRust/blob/8db0b2f656ee41d6ae389cea78810a26cd8462f6/src/install/topbar.rs), [Task Manager](https://github.com/Lemxy/WinRust/blob/8db0b2f656ee41d6ae389cea78810a26cd8462f6/src/install/taskmgr.rs).
8. [Search scan, query, pipe ACLs and scheduled tasks](https://github.com/Lemxy/WinRust/blob/8db0b2f656ee41d6ae389cea78810a26cd8462f6/plugins/rust-search/src/main.rs).
9. [Wi-Fi credentials and PEAP profile](https://github.com/Lemxy/WinRust/blob/8db0b2f656ee41d6ae389cea78810a26cd8462f6/plugins/rust-settings/src/wifi.rs), [VPN/proxy](https://github.com/Lemxy/WinRust/blob/8db0b2f656ee41d6ae389cea78810a26cd8462f6/plugins/rust-settings/src/ext.rs), [optional tuning](https://github.com/Lemxy/WinRust/blob/8db0b2f656ee41d6ae389cea78810a26cd8462f6/plugins/debloat/src/main.rs).
10. [Build workflow](https://github.com/Lemxy/WinRust/blob/8db0b2f656ee41d6ae389cea78810a26cd8462f6/.github/workflows/build.yml), [release script](https://github.com/Lemxy/WinRust/blob/8db0b2f656ee41d6ae389cea78810a26cd8462f6/scripts/release.ps1).
11. [ReShell watchdog](https://github.com/Lemxy/WinRust/blob/8db0b2f656ee41d6ae389cea78810a26cd8462f6/ReShell/src/watchdog.rs), [shell fallback](https://github.com/Lemxy/WinRust/blob/8db0b2f656ee41d6ae389cea78810a26cd8462f6/plugins/rs-shell/src/main.rs).
12. [Repository metadata](https://api.github.com/repos/Lemxy/WinRust), [tag resolution](https://api.github.com/repos/Lemxy/WinRust/git/ref/tags/v0.5.5).

---

**Attribution:** Lemxy and WinRust contributors; [MIT](https://github.com/Lemxy/WinRust/blob/8db0b2f656ee41d6ae389cea78810a26cd8462f6/LICENSE-MIT) OR [Apache-2.0](https://github.com/Lemxy/WinRust/blob/8db0b2f656ee41d6ae389cea78810a26cd8462f6/LICENSE-APACHE). Analysis only; no source components extracted.
