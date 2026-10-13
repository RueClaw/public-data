# Strata (lgse/strata)

**Repo:** https://github.com/lgse/strata
**License:** Root MIT declaration conflicts with GPL-3.0-or-later file headers; third-party terms also apply. Resolve scope before redistribution or code extraction.
**Reviewed:** 2026-10-13 UTC
**Revision:** e7e43f2a1fc5d70522601e60d852e1451ded9e8a, main commit dated 2026-10-13 01:10:21 UTC. Scope: README/LICENSE/notices, manifest/lock/build/config, entry point, browsing/search, operations/archive safety, sandbox workers, updater/installer, custom actions/providers, portal, representative tests and CI.
**Verification:** Anonymous public-source acquisition and static code review only. No installation, build, test, binary, hooks or repository scripts executed. No release artifact signatures independently verified.
**Stack:** Rust 2024, GTK4/GLib/GIO, GtkSourceView, GStreamer, Poppler, zbus/ashpd, bubblewrap, Landlock/seccomp.
**What it is:** A keyboard-first native Linux file manager with Miller columns, Icons/List views, previews, search and optional desktop integration.

---

## Verdict

⚠️ **Interesting — promising trial candidate with licensing and installer-verification caveats.** The architecture goes well beyond a cosmetic file browser, and the preview/update defenses deserve credit. Do not treat the root MIT badge as a complete reuse answer or assume the shell installer always authenticates build provenance.

## What It Is

Strata targets Arch Linux and Omarchy while supporting compatible GTK4 Linux desktops. It combines columns, grid and list presentation with shared navigation/selection, recursive fuzzy filename search, local and GIO/GVfs locations, previews, file operations and device integration. Optional portal/file-manager integration can make it a system-wide chooser or folder handler.

The published binaries require glibc 2.39 or newer and GTK 4.12 or newer, with additional media/desktop libraries. This is a native desktop application, not a dependency-free static binary or a server to self-host. [README](https://github.com/lgse/strata/blob/e7e43f2a1fc5d70522601e60d852e1451ded9e8a/README.md), [manifest](https://github.com/lgse/strata/blob/e7e43f2a1fc5d70522601e60d852e1451ded9e8a/Cargo.toml).

## Stack

| Layer | Technology |
|---|---|
| UI/files | GTK4, GLib/GIO, Rust |
| Search | ignore, frizbee, Unicode normalization |
| Preview/media | GtkSourceView, GStreamer, Poppler and format-specific parsers |
| Desktop | D-Bus, ashpd/zbus, GIO/GVfs |
| Isolation | Worker processes, bubblewrap, Landlock and seccomp |
| Update verification | ring signatures, SHA-256, structured signed manifests |

## Key Features and Architecture

### Multiple views over shared filesystem behavior

The implementation separates UI, browser/model work and services rather than rebuilding operations for each presentation. Cancellable enumeration, bounded streaming and incremental monitoring are particularly relevant to large or changing directories. Search indexes names/paths; it should not be sold as universal full-document content search. Remote shares are not included in global filename indexing at this revision. [Source tree](https://github.com/lgse/strata/tree/e7e43f2a1fc5d70522601e60d852e1451ded9e8a/src), [main](https://github.com/lgse/strata/blob/e7e43f2a1fc5d70522601e60d852e1451ded9e8a/src/main.rs), [README](https://github.com/lgse/strata/blob/e7e43f2a1fc5d70522601e60d852e1451ded9e8a/README.md).

### Preview safety is an explicit design concern

Parser-backed previews run across process boundaries instead of treating every untrusted file as safe GTK input. The inspected browser worker requires fully enforced Landlock write restrictions, including truncate protection, and no-new-privileges; seccomp closes additional mutation paths. This is real defensive code, not merely a README claim. It does not establish that every parser, helper or desktop capability is fully sandboxed. [Worker](https://github.com/lgse/strata/blob/e7e43f2a1fc5d70522601e60d852e1451ded9e8a/src/sandbox/browser/worker.rs), [process boundary](https://github.com/lgse/strata/blob/e7e43f2a1fc5d70522601e60d852e1451ded9e8a/src/sandbox/browser/process.rs).

Test hostile/truncated media and sandbox failure behavior in an isolated environment before making it the default file manager. A file browser necessarily holds broad access to the user's files; parser containment is not a replacement for backups and explicit destructive-action confirmation.

### In-app updates are stronger than installer fallback

The in-app update path parses bounded manifest/signature documents, uses bundled trusted keys, checks artifact size/hash and binds a package to its source commit. Archive and command-handling code has corresponding tests. These are positive static design signals; this review did not verify a downloaded release. [Manifest verification](https://github.com/lgse/strata/blob/e7e43f2a1fc5d70522601e60d852e1451ded9e8a/src/services/update_install/manifest.rs), [archive handling](https://github.com/lgse/strata/blob/e7e43f2a1fc5d70522601e60d852e1451ded9e8a/src/services/update_install/archive.rs), [tests](https://github.com/lgse/strata/blob/e7e43f2a1fc5d70522601e60d852e1451ded9e8a/src/services/update_install/review_tests.rs).

In contrast, the shell installer's verify_provenance function warns and returns successfully when GitHub CLI is absent or unauthenticated. Installation then proceeds after HTTPS plus a checksum downloaded alongside the archive. Checksums catch corruption but are not independent publisher authentication if both files are replaced. The README's stronger provenance language therefore needs qualification. This is a confirmed control-flow discrepancy, not evidence of an actual compromised release. [Installer](https://github.com/lgse/strata/blob/e7e43f2a1fc5d70522601e60d852e1451ded9e8a/install.sh).

## Security and Operational Boundaries

- Custom actions and external providers are executable extensions: install only scripts whose authority you understand. Their existence is intentional functionality, not by itself a vulnerability. [Custom-action documentation](https://github.com/lgse/strata/blob/e7e43f2a1fc5d70522601e60d852e1451ded9e8a/docs/custom-actions.md).
- SMB/SFTP use desktop authentication integrations; the README describes explicit host-key decisions. Do not silently accept new host identities or assume remote operations have local-filesystem semantics.
- Optional portal, folder-handler, keybinding and encrypted-volume integrations change desktop behavior. Evaluate them separately from opening the app, and preserve a rollback path.
- Automatic update checks are on by default and can be disabled. This creates routine network activity even when local browsing is the main workload.
- No reviewed HTTP server/auth/CORS surface is presented here. The relevant IPC and permissions are local desktop/D-Bus and subprocess boundaries. [Portal interface](https://github.com/lgse/strata/blob/e7e43f2a1fc5d70522601e60d852e1451ded9e8a/src/portal/dbus.rs).

## License: Unresolved Internal Conflict

The actual [root LICENSE](https://github.com/lgse/strata/blob/e7e43f2a1fc5d70522601e60d852e1451ded9e8a/LICENSE) is MIT, copyright 2026 LGSE Ltd., and Cargo.toml declares MIT. However, a tracked-file scan finds **18 files with GPL SPDX identifiers**. Representative compiled source files include [update manifest](https://github.com/lgse/strata/blob/e7e43f2a1fc5d70522601e60d852e1451ded9e8a/src/services/update_install/manifest.rs), [archive handling](https://github.com/lgse/strata/blob/e7e43f2a1fc5d70522601e60d852e1451ded9e8a/src/services/update_install/archive.rs) and [browser animation](https://github.com/lgse/strata/blob/e7e43f2a1fc5d70522601e60d852e1451ded9e8a/src/ui/browser/dissolve_delete.rs), each carrying GPL-3.0-or-later headers.

This is an unresolved scope conflict, not proof of infringement and not sufficient evidence to assign one simple license to the entire binary. Ask the maintainers to reconcile the declarations before proprietary reuse or redistribution. Do not erase restrictive headers based on the root badge.

RAR support is enabled by default in the manifest and uses UnRAR components. [Bundled UnRAR terms](https://github.com/lgse/strata/blob/e7e43f2a1fc5d70522601e60d852e1451ded9e8a/data/licenses/UnRAR.txt) permit handling RAR archives but prohibit using that code to develop a compatible RAR archiver/recreate the proprietary compression algorithm, and impose notice requirements for modified source. The dependency stack therefore cannot be summarized as MIT-only. No exhaustive transitive-license audit was performed.

## Maturity and Verification

Public metadata observed on review date: **791 stars, 75 forks**, created **2026-08-28**, pushed **2026-10-13 01:49:57 UTC**. The 71 open API issue objects split into **54 issues and 17 PRs**. Latest observed stable release: [v1.0.0](https://github.com/lgse/strata/releases/tag/v1.0.0), published 2026-10-12 20:15:04 UTC. The reviewed main SHA is not asserted to be the exact release build source. [Metadata](https://api.github.com/repos/lgse/strata), [releases](https://api.github.com/repos/lgse/strata/releases?per_page=3).

CI defines containerized formatting/lint/build checks and test infrastructure; important actions are commit-pinned. Unit and end-to-end test sources exist. These are useful maturity signals, not verified pass results: no tests were run and no CI success claim is made. Six weeks of public repository history and a 1.0 version do not independently prove production reliability. [CI](https://github.com/lgse/strata/blob/e7e43f2a1fc5d70522601e60d852e1451ded9e8a/.github/workflows/ci.yml), [tests](https://github.com/lgse/strata/tree/e7e43f2a1fc5d70522601e60d852e1451ded9e8a/tests).

## Comparison

| Alternative | Operational tradeoff |
|---|---|
| [GNOME Files/Nautilus](https://apps.gnome.org/Nautilus/) | Established GNOME integration and ordinary local/network file management; choose Strata for its column navigation and keyboard/Omarchy focus. |
| [Dolphin](https://apps.kde.org/dolphin/) | Established KDE-oriented feature set; less natural if the desired experience is a compact GTK/Omarchy-specific workflow. |
| [Yazi](https://github.com/sxyazi/yazi) | Terminal-first keyboard file management; avoids requiring a full GTK interface but is not a system GUI chooser substitute. |

No comparative performance benchmark was run.

## Self-Hosting Notes

There is no service to deploy. Trial a pinned binary/build with a disposable dataset and retain the existing file manager. Test copy/move conflicts, cancellation, trash/recovery, network disconnects, encrypted volumes and hostile previews before changing defaults. Require authenticated release verification rather than quietly relying on installer checksum fallback. Keep custom actions and system integrations opt-in during evaluation.

**Attribution:** LGSE Ltd. and strata contributors. Root MIT declaration; GPL-tagged files and third-party terms require scope clarification.
