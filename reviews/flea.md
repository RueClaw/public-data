# Flea (thisisgm/flea)

**Repo:** https://github.com/thisisgm/flea
**Author:** GM / thisisgm and contributors
**License:** MIT for Flea; bundled dependencies and assets retain separate terms.
**Reviewed:** 2026-11-10 (UTC)
**Revision:** e6044184bb7606a854bfefbd73cdbecf9970613a (main; package version 0.4.1). Scope: launcher, Rust backend, GPUI frontend, selected preview/provider/plugin/IPC/recovery paths, packaging, tests and documentation.
**Verification:** Static source review; no build, tests, installation, desktop/device access, provider login or live application probes. Public GitHub release/CI metadata checked separately.
**Stack:** Rust, GPUI fork, Linux desktop services, subprocess helpers; retained QML/Qt components.
**What it is:** A keyboard-first graphical file manager for Omarchy, with terminal mode, previews, file operations, sharing, desktop file-chooser integration and disk-image writing—not an AI agent or model service.

---

## Verdict

⚠️ **Interesting — a credible Omarchy pilot, not yet an unconditional default-file-manager recommendation.** Flea has unusually substantive file-identity checks, recovery records, preview isolation and performance methodology for a young desktop project. The 0.4 GPUI transition, extensive helper surface, unrestricted ordinary plugins and irreversible device operations still warrant a controlled trial with backed-up files before replacing an established manager.

## What It Is

Flea combines list, grid, columns and dual-pane views with tabs, ranked search, tags, Quick Look, bulk rename, trash/undo, archives, a shelf, network shares and device browsing. It targets users who want fast keyboard navigation without giving up a graphical preview-oriented desktop. Its file-chooser and FileManager1 integrations can affect other applications, not just its own windows.

Do not identify the current app from the repository's QML topic tags or older install text alone. The default launcher explicitly executes **flea-gui**, a Rust/GPUI application, while refusing the legacy frontend; the repository still contains a large QML tree and Qt-based HTML helper. Some installation text still calls the Quickshell UI the installed frontend. The executable entry point and current package manifest are stronger evidence than those stale descriptions. See [src/main.rs](https://github.com/thisisgm/flea/blob/e6044184bb7606a854bfefbd73cdbecf9970613a/src/main.rs), [crates/flea-gui/Cargo.toml](https://github.com/thisisgm/flea/blob/e6044184bb7606a854bfefbd73cdbecf9970613a/crates/flea-gui/Cargo.toml), [docs/install.md](https://github.com/thisisgm/flea/blob/e6044184bb7606a854bfefbd73cdbecf9970613a/docs/install.md) and [PKGBUILD](https://github.com/thisisgm/flea/blob/e6044184bb7606a854bfefbd73cdbecf9970613a/PKGBUILD).

## Stack

| Layer | Implementation |
|---|---|
| Launcher and terminal | Rust flea executable; explicit --tui mode; display/argument checks |
| GUI | flea-gui; revision-pinned thisisgm/gpui-omarchy fork; Vulkan/software-Vulkan/GL fallback |
| File engine | Rust backend with request/event loop, listing/search workers, operation jobs and thumbnail pool |
| OS integration | GIO/GVFS, D-Bus file chooser/FileManager1, UDisks2/polkit, XDG defaults, Omarchy shell |
| Preview tools | bubblewrap + prlimit; image/PDF/media libraries and external decoders; Qt WebEngine HTML helper |
| Persistence | XDG JSON settings, runtime undo journal, persistent recovery records, freedesktop trash/thumbnails, file xattrs |
| Extensions | Supervised executable plugins over bounded JSON lines; separately jailed previewers |

The small root Cargo dependency list is **not** the dependency footprint of the desktop product. The workspace GUI, pinned GPUI fork, system libraries and numerous optional/required helper programs materially enlarge maintenance and patching responsibilities. [Cargo.toml](https://github.com/thisisgm/flea/blob/e6044184bb7606a854bfefbd73cdbecf9970613a/Cargo.toml), [Cargo.lock](https://github.com/thisisgm/flea/blob/e6044184bb7606a854bfefbd73cdbecf9970613a/Cargo.lock), [PKGBUILD](https://github.com/thisisgm/flea/blob/e6044184bb7606a854bfefbd73cdbecf9970613a/PKGBUILD).

## Key Features and Claim Checks

### Fast navigation, with useful benchmark caveats

The README reports a 319 ms first window and 0.75 s settled time for 100,000 empty files, and 166 ms first search result across a million files. These are upstream measurements of the 0.4.0 candidate **8a7fd82f**, not measurements of this reviewed 0.4.1 revision. The source candidly defines first window as compositor registration and settled as 500 ms CPU quiet: neither establishes painted, input-ready UI. Competitors use different view modes; unchanged rival samples are reused. Search excludes process creation and initial listing, and Flea acknowledges quality losses against nd/fff. Media memory data are incomplete and not uniformly superior. The “fastest” headline therefore applies to selected measured workloads, not a general theorem. No benchmark was independently reproduced. [README.md](https://github.com/thisisgm/flea/blob/e6044184bb7606a854bfefbd73cdbecf9970613a/README.md), [docs/bench/0.4.0-20261102.md](https://github.com/thisisgm/flea/blob/e6044184bb7606a854bfefbd73cdbecf9970613a/docs/bench/0.4.0-20261102.md).

### Operations designed around identity, not just filenames

Undo records device/inode/type plus metadata and, where available, birth time. Cross-device move checks ensure the source still matches the copied bytes before removal; directory/file undo checks distinguish untouched created entries from later user edits. Shared undo has an owner-only runtime directory, locking, a 32 MiB document bound and 50-entry undo depth. This is meaningful defensive implementation, not merely an “undo” menu label. It remains bounded history, not a backup or universal transaction rollback. [src/backend/undo.rs](https://github.com/thisisgm/flea/blob/e6044184bb7606a854bfefbd73cdbecf9970613a/src/backend/undo.rs), [src/backend/undoshare.rs](https://github.com/thisisgm/flea/blob/e6044184bb7606a854bfefbd73cdbecf9970613a/src/backend/undoshare.rs).

### Rich previews, intentionally separated from ordinary app authority

The general decoder wrapper unshares namespaces, clears the environment, provides read-only system/input mounts and a caller-selected writable output, with CPU/address-space limits. It still exposes readable **/etc** and **/usr**; “sandboxed” does not mean a minimal empty machine. Office/archive/HTML paths have different limits: archive jobs omit the generic CPU cap; Chromium HTML has a CPU limit but no address-space cap. The HTML jail exposes the page's parent folder read-only at /page, not only the selected document, and uses a separate network namespace. Treat sibling content and generated previews as sensitive. [src/backend/sandbox.rs](https://github.com/thisisgm/flea/blob/e6044184bb7606a854bfefbd73cdbecf9970613a/src/backend/sandbox.rs), [src/backend/htmlsandbox.rs](https://github.com/thisisgm/flea/blob/e6044184bb7606a854bfefbd73cdbecf9970613a/src/backend/htmlsandbox.rs).

## Architecture

The CLI routes GUI, TUI, backend, IPC, preview, plugin, shelf, update and desktop-integration modes. The backend uses a request/event loop with deferred workers, six thumbnail workers, filesystem watching, generation-aware search and bounded shutdown draining. File operations and rendering are separated so expensive decoding does not have to block directory navigation. [src/main.rs](https://github.com/thisisgm/flea/blob/e6044184bb7606a854bfefbd73cdbecf9970613a/src/main.rs), [src/backend/run.rs](https://github.com/thisisgm/flea/blob/e6044184bb7606a854bfefbd73cdbecf9970613a/src/backend/run.rs).

The GUI uses a specific GPUI fork revision rather than whatever upstream GPUI happens to release. Adapter selection tests actual surface/device creation; fallback goes from hardware Vulkan to software Vulkan to GL. Old GPUs can require Lavapipe, and GL fallback still needs storage-buffer support. Direct flea-gui invocation bypasses launcher environment cleanup. This is Linux/Omarchy software, not a demonstrated cross-platform GPUI application. [docs/gui-renderer.md](https://github.com/thisisgm/flea/blob/e6044184bb7606a854bfefbd73cdbecf9970613a/docs/gui-renderer.md).

## Security, Permissions and Execution Boundaries

- **Desktop user is the authority boundary.** Flea reads and changes files with the user's normal permissions. Opening files invokes handlers; terminal, run-file, custom script and plugin features intentionally execute programs. This is not a safe viewer for arbitrarily trusted extensions or an agent execution sandbox.
- **Local IPC has meaningful filesystem controls.** The runtime must be an absolute owner-only directory; its child directory is created 0700, and endpoints must be owner-only Unix sockets. Stale endpoint cleanup checks identity. This is local-user isolation, not per-agent authorization: another process under the same account can use window actions. No web-server/CORS security model is needed for this Unix-socket surface. [src/ipc/endpoint.rs](https://github.com/thisisgm/flea/blob/e6044184bb7606a854bfefbd73cdbecf9970613a/src/ipc/endpoint.rs), [src/ipc/action.rs](https://github.com/thisisgm/flea/blob/e6044184bb7606a854bfefbd73cdbecf9970613a/src/ipc/action.rs).
- **Ordinary plugin access labels are declarations, not permissions.** The host directly spawns the executable in its folder, sets LC_ALL but does not clear the inherited environment or apply an OS filesystem/network jail. It imposes memory/open-file limits and process-group lifecycle management. A plugin with an empty access list still has user authority and potentially inherited credentials. Only the specialized previewer path uses the stronger thumbnail sandbox. Treat installing/enabling a plugin as running third-party software. [PLUGINS.md](https://github.com/thisisgm/flea/blob/e6044184bb7606a854bfefbd73cdbecf9970613a/PLUGINS.md), [src/plugin_runtime/process.rs](https://github.com/thisisgm/flea/blob/e6044184bb7606a854bfefbd73cdbecf9970613a/src/plugin_runtime/process.rs), [src/backend/pluginpreview_sandbox.rs](https://github.com/thisisgm/flea/blob/e6044184bb7606a854bfefbd73cdbecf9970613a/src/backend/pluginpreview_sandbox.rs).
- **Plugin supervision is not side-effect rollback.** JSON-line size/time/progress bounds and cancellation reduce hangs and malformed output. They cannot undo a partial upload or filesystem change if the process dies; a failed result does not prove nothing happened. Reconcile external state before retrying non-idempotent actions.
- **Disk-image flashing is destructive authority.** The helper obtains an exclusive descriptor through UDisks/polkit, checks drive identity and has a separate fail-closed confirmation at flash time. Discovery fallback can retain candidates if the helper fails; it must not be mistaken for successful final authorization. Verification checks written bytes, not whether the user chose the right disk. Never rely on file-operation undo to recover an overwritten drive. [src/backend/flashhelper.rs](https://github.com/thisisgm/flea/blob/e6044184bb7606a854bfefbd73cdbecf9970613a/src/backend/flashhelper.rs), [src/backend/flashop.rs](https://github.com/thisisgm/flea/blob/e6044184bb7606a854bfefbd73cdbecf9970613a/src/backend/flashop.rs), [tools/flea-udisks](https://github.com/thisisgm/flea/blob/e6044184bb7606a854bfefbd73cdbecf9970613a/tools/flea-udisks).

These are source-level boundary observations, not proof of a remotely exploitable flaw or an exhaustive audit of every helper, decoder, race or archive traversal path.

## Authentication, Providers, Privacy and Costs

Flea has no required AI provider, model download, token billing or Flea cloud account. Local file browsing is distinct from explicitly using sharing/network features.

Provider discovery checks executable availability and bounded Dropbox account metadata; provider status is requested on explicit UI entry. Adapters include Dropbox, Taildrop/Tailscale, LocalSend CLI, rclone and owly. Their daemons, accounts, configured remotes, transport security and destination access policies remain separate trust dependencies. A detected executable is not evidence of an authenticated or usable provider. Sharing sends selected content to the chosen destination; a public/share link changes who can retrieve it. Account/storage/bandwidth charges can apply according to those providers; this review did not verify current pricing or execute any provider flow. [src/backend/providers.rs](https://github.com/thisisgm/flea/blob/e6044184bb7606a854bfefbd73cdbecf9970613a/src/backend/providers.rs), [src/backend/localsend.rs](https://github.com/thisisgm/flea/blob/e6044184bb7606a854bfefbd73cdbecf9970613a/src/backend/localsend.rs).

The GIO authentication helper reads one password from stdin, suppresses output, chooses “never” when prompted to store it, refuses insecure continuation prompts and rejects a second password challenge. The GPUI Secret buffer masks Debug output and wipes its owned bytes on growth/clear/drop. Those are good practices, not a proof that every toolkit/OS/remote-service copy is erased or that existing provider credential stores disappear. Prefer encrypted share protocols and understand that NFS/plain protocols have different authentication/confidentiality assumptions. [tools/flea-gio-auth](https://github.com/thisisgm/flea/blob/e6044184bb7606a854bfefbd73cdbecf9970613a/tools/flea-gio-auth), [crates/flea-gui/src/g2/pl1/secret.rs](https://github.com/thisisgm/flea/blob/e6044184bb7606a854bfefbd73cdbecf9970613a/crates/flea-gui/src/g2/pl1/secret.rs).

Local privacy is not zero retention: last folders/tabs, favourites, plugin settings, shelf paths, recovery manifests, thumbnails and converted document previews may remain on disk. Tags are file xattrs and may travel with files depending on copy/backup behavior. There is no verified universal retention deadline or one-button secure erasure here. Do not put secrets in plugin settings; the extension contract specifically warns against it.

## Persistence, Retention and Recovery

Settings and shelf state have compatibility guards that preserve unsupported future/foreign documents rather than silently rewriting them. Malformed non-object ui.json can be retained as ui.json.broken before replacement. The state inventory documents cache families, desktop-default changes and leftover atomic-write scratch. It is useful operational documentation, but parts are a 0.3.12 compatibility baseline and not a complete current-feature inventory. [docs/state-compat.md](https://github.com/thisisgm/flea/blob/e6044184bb7606a854bfefbd73cdbecf9970613a/docs/state-compat.md).

The shared undo journal resides under XDG_RUNTIME_DIR, so it should not be treated as durable across logout/reboot. Durable interrupted-trash recovery is separate under XDG state: records are synced before claiming data, and recovery rechecks identities and preserves unresolved leftovers. Freedesktop Trash payloads, shelf archives and recovery data are not disposable thumbnails. A cache purge is not a backup restore, nor does uninstall imply all user data/default changes were removed. [src/backend/undoshare.rs](https://github.com/thisisgm/flea/blob/e6044184bb7606a854bfefbd73cdbecf9970613a/src/backend/undoshare.rs), [src/backend/trashdelete/recovery.rs](https://github.com/thisisgm/flea/blob/e6044184bb7606a854bfefbd73cdbecf9970613a/src/backend/trashdelete/recovery.rs).

## Installation and Update Notes

The recommended distribution is Omarchy's package repository for x86_64/aarch64. Default-manager/chooser registration is a separate user-level action affecting MIME associations, D-Bus and portal routing, plus desktop bindings. Try the app without claiming defaults first; keep a known-good file manager and backups, and release its integration before removing the package.

Updates are handed to Omarchy's updater rather than replacing the binary with an arbitrary downloaded executable. The source updater distinguishes signed repository ownership from local/unowned builds. The root PKGBUILD intentionally contains an all-zero checksum placeholder: directly using it against a release download should fail verification. The documented development-build path skips checksums for a locally generated git archive; that transfers trust to the inspected checkout, it does not authenticate arbitrary downloaded tarballs. Builds fetch locked Cargo inputs including the GPUI fork, and require substantial native dependencies. [src/update.rs](https://github.com/thisisgm/flea/blob/e6044184bb7606a854bfefbd73cdbecf9970613a/src/update.rs), [PKGBUILD](https://github.com/thisisgm/flea/blob/e6044184bb7606a854bfefbd73cdbecf9970613a/PKGBUILD), [docs/install.md](https://github.com/thisisgm/flea/blob/e6044184bb7606a854bfefbd73cdbecf9970613a/docs/install.md).

## License, Tests and Maturity

The actual root LICENSE is MIT, copyright 2026 GM: preserve the copyright and permission notice when redistributing substantial source. THIRD-PARTY-LICENSES inventories the runtime closure, including MPL-2.0 and other terms; root MIT does not relabel all bundled code/assets or external helper programs. No source extraction was performed. [LICENSE](https://github.com/thisisgm/flea/blob/e6044184bb7606a854bfefbd73cdbecf9970613a/LICENSE), [THIRD-PARTY-LICENSES.txt](https://github.com/thisisgm/flea/blob/e6044184bb7606a854bfefbd73cdbecf9970613a/THIRD-PARTY-LICENSES.txt), [deny.toml](https://github.com/thisisgm/flea/blob/e6044184bb7606a854bfefbd73cdbecf9970613a/deny.toml).

Public metadata on 2026-11-10 showed repository creation on 2026-09-02, last push 2026-11-08, **1,144 stars**, **122 forks** and **84 open issues/PRs combined**. Latest release v0.4.1 was published 2026-11-08. These are freshness/adoption signals, not reliability metrics. The open issue sample includes a paste-destination UX request ([#449](https://github.com/thisisgm/flea/issues/449)); requests are not automatically defects.

The [release run for this exact SHA](https://github.com/thisisgm/flea/actions/runs/42511418356) was reported successful by GitHub. The checked workflows pin action revisions, test/build both architectures, and run cargo test --locked --workspace --no-fail-fast through the release helper. Candidate branches replay the release build path. This does not establish continuous PR coverage or that every committed shell/UI/real-device suite runs in that hosted lane. PKGBUILD explicitly skips selected sandbox integration tests when namespaces are unavailable. Test files cover IPC bounds, filesystem identities, state upgrades, plugin protocols, rendering and recovery, but **none were run in this review**. [.github/workflows/candidate.yml](https://github.com/thisisgm/flea/blob/e6044184bb7606a854bfefbd73cdbecf9970613a/.github/workflows/candidate.yml), [.github/workflows/release.yml](https://github.com/thisisgm/flea/blob/e6044184bb7606a854bfefbd73cdbecf9970613a/.github/workflows/release.yml), [packaging/flea-release-build](https://github.com/thisisgm/flea/blob/e6044184bb7606a854bfefbd73cdbecf9970613a/packaging/flea-release-build), [PKGBUILD](https://github.com/thisisgm/flea/blob/e6044184bb7606a854bfefbd73cdbecf9970613a/PKGBUILD).

Security policy supports only the latest release. The recent renderer migration and two-month public history make compatibility/upgrade regression testing particularly important. A lockfile, license inventory and passing upstream CI are welcome; no fresh dependency vulnerability scan or reproducible binary/signature audit was performed. [SECURITY.md](https://github.com/thisisgm/flea/blob/e6044184bb7606a854bfefbd73cdbecf9970613a/SECURITY.md).

## Comparison

| Option | Choose it when | Tradeoff relative to Flea |
|---|---|---|
| [Dolphin](https://apps.kde.org/dolphin/) | Mature general-purpose GUI, rich desktop/network integration | More established ecosystem; benchmark results depend on matching views/workloads |
| [Thunar](https://docs.xfce.org/xfce/thunar/start) | Conventional lightweight file management | Less of Flea's integrated preview/shelf/search workflow; stable alternative to retain during a pilot |
| [Strata](https://github.com/lgse/strata) | Keyboard-first GTK4 alternative | Similar audience; compare current security/license and renderer behavior, not only startup claims |
| [Yazi](https://github.com/sxyazi/yazi) | Terminal-first keyboard navigation | No equivalent promise of a native graphical desktop file-chooser replacement |

See the existing [Strata review](strata.md) for a separate static assessment. These alternatives were not installed or re-benchmarked for this review.

## Practical Adoption Gate

Pilot on a supported Omarchy session with backed-up, noncritical files. Before making it the default, validate real renderer/input behavior, Unicode and non-UTF-8 filename limitations, cross-device copies, collision/undo behavior, restart/logout recovery, representative remote shares and portal dialogs. Start without third-party plugins or device flashing. Treat extension installation and provider sharing as explicit trust decisions, and keep irreversible disk operations outside an automated trial.

**Bottom line:** strong desktop-engineering ideas and a plausible daily-driver candidate for willing Omarchy testers; static evidence alone is insufficient to entrust it with the only copy of important data or unattended high-authority actions.

---

**Attribution:** [thisisgm/flea](https://github.com/thisisgm/flea), GM and contributors; MIT source, separate third-party terms. Analysis is based on the exact revision above and public metadata retrieved 2026-11-10.
