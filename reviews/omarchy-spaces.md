# Omarchy Spaces (t4t5/omarchy-spaces)

**Repo:** https://github.com/t4t5/omarchy-spaces
**License:** MIT code; Apache-2.0 Herdr sounds embedded in the binary. Preserve applicable notices for both on redistribution.
**Reviewed:** 2026-11-26 (UTC)
**Revision:** f0e148075cd816e5047f237b7a705772deb606c3, main and v0.1.0; repository-wide static review focused on state/restore/adapters/IPC, QML service/watch, Lua integration, lifecycle scripts, tests and CI.
**Verification:** Anonymous HTTPS acquisition and public metadata; static inspection only. No installs, builds, source/test execution, desktop access or runtime probes.
**Stack:** Rust 2024, Clap, Serde/JSON, TOML; Qt Quick/QML, Quickshell, Hyprland Lua, Bash.
**What it is:** An Omarchy 4.5+ plugin grouping ordinary Hyprland workspaces into project spaces, with sidebar/tab navigation and supported terminal/browser session reconstruction.

---

## Verdict

⚠️ **Interesting — a coherent project-oriented desktop, not yet a low-risk default.** The single-snapshot UI and recovery machinery are thoughtful for v0.1.0. Trial with backed-up configuration/state: it has desktop-user authority, saves sensitive metadata and depends on evolving compositor/application internals. Invalid restore configuration also falls back to enabled restoration rather than preserving privacy opt-outs.

## What It Is

A space is a project context, not a container, VM, browser profile or security boundary. Tabs remain Hyprland workspaces named like s1:2; numbered workspaces remain in “home.” Every monitor follows the selected space, with its own block of ten slots. Names follow terminal directories unless overridden. Spaces do not isolate agent credentials or permissions. [S1, S2]

Implemented features include creation, naming/icons, reordering, closing spaces/tabs, moving windows/tabs, shared sidebar/bar state, Claude indicators, optional sounds and selective restoration. Closing a space closes its windows: more than changing a label. [S2–S5]

## Stack

| Layer | Tech |
|---|---|
| CLI/state | Rust space binary; Clap, anyhow, Serde, serde_json, toml |
| UI | Qt Quick/QML, Quickshell processes/file watching, local JavaScript |
| Compositor | Direct Hyprland Unix IPC and Lua hooks/key helpers |
| Persistence | Versioned JSON, locks, bounded backups |
| Inspection | Linux /proc, Claude notes, Chromium session parser |
| Installation | Omarchy plugin lifecycle, Bash downloader, user-local binary |

No database server, hosted backend, HTTP API or separate application login appears in this design. Its trust boundary is the logged-in desktop user, not web authentication or CORS. [S2–S7]

## Key Features

### Project tabs without another window manager

Lua supplies slot-based focus/move helpers, cross-monitor following, monitor reconciliation and empty-tab handling. Home navigation delegates to Omarchy defaults. It wraps workspace reconciliation and conditionally adds a blur layer rule: meaningful compositor integration, not a passive widget. [S2]

### One authoritative UI snapshot

One space watch emits complete newline-delimited JSON snapshots for sidebar and tabs. Hyprland events drive immediate refresh; active terminal processes are sampled five times per second and other shells/layouts roughly every two seconds. QML restarts failed watchers with capped backoff and attempts matching managed binary updates once per version. This avoids independently drifting views; performance/reconnect behavior were not measured. [S3]

### Claude status, not universal agent integration

Only Claude Code has a status/resume adapter here. It reads process notes, checks PID/start identity where available, accepts UUID-shaped resume IDs and ignores noninteractive sessions. Other programs appear by name without equivalent status semantics. Open PRs for other adapters/direct-exec recognition are proposals, not shipped support. [S4, M3]

### Selective restoration

Restore recreates terminal folders, supported layouts, Claude conversations and Chromium/Chrome/Brave/Edge windows. It excludes arbitrary terminal jobs, scrollback, arbitrary apps, Firefox/Zen, incognito and custom browser data directories. Tabs reload without history, groups or pins; dwindle has the strongest split restoration. App autostart can duplicate windows; browser-native continuation is detected to reduce duplication. [S5, S6]

## Architecture

Rust queries/dispatches to Hyprland; QML views snapshots; Lua owns hotkeys/hooks. Adapters isolate application parsing from common live/session models. Terminal inspection reads process trees, foreground groups, directories and selected environment information. Shared-process windows are matched heuristically by creation order. Browser session files are located via open file descriptors and matched by title/order, not a stable extension API. These integrations carry compatibility limits. [S2–S7]

### Desktop authority and input boundaries

The enabled plugin executes programs/scripts, reads same-user process/application state, focuses/moves/closes windows, launches apps and reloads Hyprland. Scripts provide neither a root step nor a sandbox. Bar replacement is prompted; enabling also admits service startup and future managed binary updates. [S2, S8]

Positive controls include shell quoting, browser-family allowlisting, URL filtering against option-like input, UUID-only resume IDs and local Unix IPC rather than a network command listener. Browser restore still accepts http, https, file, chrome and about URLs. It is not a safe untrusted-session importer or destination filter. Treat imported sessions as operational input despite not being arbitrary shell scripts. [S4, S6, S7]

### Privacy and egress

No dedicated telemetry uploader/network client was found in reviewed application paths. This does not mean no egress: install/update downloads GitHub archives/checksums; restore launches browsers loading saved URLs and Claude processes that may contact configured services. Private/authenticated sites can reopen in existing profiles. [S4, S6, S8]

Snapshots contain terminal paths, conversation IDs and URLs, potentially including query-string secrets. Session files are created with mode 0600, flushed and atomically renamed; a 48-entry history remains. This is local persistence, not encryption or protection against same-user processes. Generic space metadata uses a separate atomic writer without an explicit private mode, so names/folders also depend on directory permissions and umask. [S5, S9]

**Concrete opt-out caveat:** restore calls Config::load_or_default(). Unreadable/malformed TOML warns and defaults auto, agents and browsers to true. A broken config intended to disable restoration can reopen saved pages/agents. The watcher handles unavailable browser configuration more cautiously; this is not a claim every config error immediately collects URLs. Fail-closed opt-outs would be safer. Also, auto = false is not a recording opt-out, and browsers = false does not erase old snapshots. [S10, S3, S5]

### Persistence and recovery

Sessions have locks, fsync plus rename, previous-session state, periodic backups (at most one per 15 minutes), and a ten-second deletion grace period intended to avoid saving a shutting-down desktop as empty. Invalid/newer state is moved aside rather than overwritten. Restore locks/progress tracking reduce duplicates; missing folders fall back to existing ancestors. Strong design signals, not proof across every crash/power-loss point. [S5, S9]

## Installation, Uninstallation and Rollback

This is desktop integration, not a self-hosted service. Documentation requires Omarchy 4.5+, shell/plugin tools and compatible Lua-era Hyprland. Installer dependencies include Bash, curl, jq, tar, sha256sum and standard utilities. Releases support x86_64/aarch64 Linux. No install was performed. [S1, S8]

Setup links the Hyprland helper into user config, reloads Hyprland, saves an uninstall script in state and installs a missing space binary in the user-local bin directory. Hotkeys require a separate manual bindings.lua addition guarded by module availability. Confirmed bar replacement disables menu/workspaces widgets. Updates replace only a binary matching its installation hash; binary replacement uses rename. [S8]

Removal is **not byte-for-byte rollback**. Its hook attempts to return named-space windows to numbered workspaces, restore replaced widgets, remove its owned symlink/hash-matching binary and delete the whole Spaces state directory, including session history. User config/binding text remain. Bar restoration recreates default placement, not an exact saved layout. Disabling differs from removal and primarily restores bar widgets; it does not undo all key/config integration. [S8]

Before trial, independently back up bar config, bindings, preexisting helpers and Spaces state. Preserve snapshots before removal; record matched plugin/binary versions. Scripts provide no automatic binary-version rollback, config transaction or verified rollback receipt. Test restore, hotplug, shell restart and removal on a disposable compatible desktop before daily reliance. [S8, S9]

## Maturity, Tests and Supply Chain

On 2026-11-26 metadata showed 3 stars, 1 fork and 5 open items, all returned as PRs. Last push was 2026-11-25; the sole returned release was v0.1.0, published that day, with tag resolving to the reviewed SHA. These indicate an early project, not safety. An open PR addresses missing workspace IDs on Hyprland 0.57+; reviewed structs still require IDs. This is a compatibility warning, not a reproduced failure. [M1–M3, S7]

CI defines formatting, Clippy with warnings denied, locked Rust tests, Node helper tests, Lua syntax/key tests and a no-symlinks check. The substantial CLI suite uses fake Hyprland Unix sockets/stub apps, covering restore, monitors, concurrency and install/removal. A live stress script exists but was not run. GitHub reported successful CI and Release runs for this SHA; tests were not independently executed here. [S11, M4]

Cargo.lock and locked builds constrain Rust resolution. Release builds both architectures after CI and packages code/sound licenses. Installer SHA-256 is downloaded beside the archive: corruption detection, not independent publisher authentication. No signature/attestation verification appears in the installer. Actions use mutable version tags; Rust tracks stable rather than a fixed toolchain. No vulnerability audit or binary reproducibility verification was performed. [S8, S11]

MIT covers code; Herdr sounds are Apache-2.0 and embedded, reflected in Cargo’s MIT AND Apache-2.0 declaration. Packaging includes both licenses. Preserve applicable attribution/notices. No code/media components were extracted. [S12]

## Comparison

| Option | Best fit | Tradeoff relative to Spaces |
|---|---|---|
| Native Omarchy/Hyprland workspaces | Lower-integration baseline | No extra hierarchy/cross-app restore; fewer plugin state/privacy obligations |
| tmux project sessions | Terminal persistence | Preserves terminal sessions independently, not browser/desktop layouts |
| Browser-native restore | Browser continuity | Browser owns semantics, without unified project workspaces |
| Herdr | Agent-attention workflow to evaluate | Upstream inspiration/sound source, not assumed a drop-in workspace replacement |

Scope comparisons, not hands-on benchmarks. Prefer native workspaces or tmux if grouping suffices; Spaces is compelling when project switching, terminal folders and GUI restoration must be coordinated. [S1, A1–A3]

## Verification and Limits

- Verified anonymous accessibility, canonical identity, no same-source review/index match, exact SHA and tag.
- Inspected implementation, lifecycle scripts, licenses, test fixtures and workflow definitions/results.
- No source execution, installs, builds, desktop/config modification, profile/account access or live runtime probes. Metadata retrieval is not a deployment test.
- Rendering, performance, real multi-monitor recovery, Chromium compatibility, deployment-specific permissions and removal recovery remain unproven.
- Revision-pinned findings; PRs are not implemented features. Targeted static review, not exhaustive audit.

## Evidence

All S-links below are pinned to the reviewed commit.

- S1: [README.md](https://github.com/t4t5/omarchy-spaces/blob/f0e148075cd816e5047f237b7a705772deb606c3/README.md), [Cargo.toml](https://github.com/t4t5/omarchy-spaces/blob/f0e148075cd816e5047f237b7a705772deb606c3/Cargo.toml), [manifest.json](https://github.com/t4t5/omarchy-spaces/blob/f0e148075cd816e5047f237b7a705772deb606c3/manifest.json).
- S2: [hypr/omarchy-spaces.lua](https://github.com/t4t5/omarchy-spaces/blob/f0e148075cd816e5047f237b7a705772deb606c3/hypr/omarchy-spaces.lua), [src/main.rs](https://github.com/t4t5/omarchy-spaces/blob/f0e148075cd816e5047f237b7a705772deb606c3/src/main.rs), [src/commands/space.rs](https://github.com/t4t5/omarchy-spaces/blob/f0e148075cd816e5047f237b7a705772deb606c3/src/commands/space.rs).
- S3: [src/watch.rs](https://github.com/t4t5/omarchy-spaces/blob/f0e148075cd816e5047f237b7a705772deb606c3/src/watch.rs), [omarchy/Watch.qml](https://github.com/t4t5/omarchy-spaces/blob/f0e148075cd816e5047f237b7a705772deb606c3/omarchy/Watch.qml), [omarchy/Service.qml](https://github.com/t4t5/omarchy-spaces/blob/f0e148075cd816e5047f237b7a705772deb606c3/omarchy/Service.qml), [docs/internals/architecture.md](https://github.com/t4t5/omarchy-spaces/blob/f0e148075cd816e5047f237b7a705772deb606c3/docs/internals/architecture.md).
- S4: [src/agent/claude.rs](https://github.com/t4t5/omarchy-spaces/blob/f0e148075cd816e5047f237b7a705772deb606c3/src/agent/claude.rs), [src/agent/mod.rs](https://github.com/t4t5/omarchy-spaces/blob/f0e148075cd816e5047f237b7a705772deb606c3/src/agent/mod.rs).
- S5: [docs/guide/restore.md](https://github.com/t4t5/omarchy-spaces/blob/f0e148075cd816e5047f237b7a705772deb606c3/docs/guide/restore.md), [src/restore.rs](https://github.com/t4t5/omarchy-spaces/blob/f0e148075cd816e5047f237b7a705772deb606c3/src/restore.rs).
- S6: [src/browser/chromium.rs](https://github.com/t4t5/omarchy-spaces/blob/f0e148075cd816e5047f237b7a705772deb606c3/src/browser/chromium.rs), [src/browser/mod.rs](https://github.com/t4t5/omarchy-spaces/blob/f0e148075cd816e5047f237b7a705772deb606c3/src/browser/mod.rs).
- S7: [src/hypr.rs](https://github.com/t4t5/omarchy-spaces/blob/f0e148075cd816e5047f237b7a705772deb606c3/src/hypr.rs), [src/terminal.rs](https://github.com/t4t5/omarchy-spaces/blob/f0e148075cd816e5047f237b7a705772deb606c3/src/terminal.rs), [src/launch.rs](https://github.com/t4t5/omarchy-spaces/blob/f0e148075cd816e5047f237b7a705772deb606c3/src/launch.rs), [src/shell.rs](https://github.com/t4t5/omarchy-spaces/blob/f0e148075cd816e5047f237b7a705772deb606c3/src/shell.rs).
- S8: [install.sh](https://github.com/t4t5/omarchy-spaces/blob/f0e148075cd816e5047f237b7a705772deb606c3/install.sh), [uninstall.sh](https://github.com/t4t5/omarchy-spaces/blob/f0e148075cd816e5047f237b7a705772deb606c3/uninstall.sh), [omarchy/Service.qml](https://github.com/t4t5/omarchy-spaces/blob/f0e148075cd816e5047f237b7a705772deb606c3/omarchy/Service.qml).
- S9: [src/session.rs](https://github.com/t4t5/omarchy-spaces/blob/f0e148075cd816e5047f237b7a705772deb606c3/src/session.rs), [src/state.rs](https://github.com/t4t5/omarchy-spaces/blob/f0e148075cd816e5047f237b7a705772deb606c3/src/state.rs), [src/spaces.rs](https://github.com/t4t5/omarchy-spaces/blob/f0e148075cd816e5047f237b7a705772deb606c3/src/spaces.rs).
- S10: [src/config.rs](https://github.com/t4t5/omarchy-spaces/blob/f0e148075cd816e5047f237b7a705772deb606c3/src/config.rs), [src/restore.rs](https://github.com/t4t5/omarchy-spaces/blob/f0e148075cd816e5047f237b7a705772deb606c3/src/restore.rs).
- S11: [.github/workflows/ci.yml](https://github.com/t4t5/omarchy-spaces/blob/f0e148075cd816e5047f237b7a705772deb606c3/.github/workflows/ci.yml), [.github/workflows/release.yml](https://github.com/t4t5/omarchy-spaces/blob/f0e148075cd816e5047f237b7a705772deb606c3/.github/workflows/release.yml), [tests/cli.rs](https://github.com/t4t5/omarchy-spaces/blob/f0e148075cd816e5047f237b7a705772deb606c3/tests/cli.rs), [scripts/package.sh](https://github.com/t4t5/omarchy-spaces/blob/f0e148075cd816e5047f237b7a705772deb606c3/scripts/package.sh), [Cargo.lock](https://github.com/t4t5/omarchy-spaces/blob/f0e148075cd816e5047f237b7a705772deb606c3/Cargo.lock).
- S12: [LICENSE](https://github.com/t4t5/omarchy-spaces/blob/f0e148075cd816e5047f237b7a705772deb606c3/LICENSE), [assets/sounds/LICENSE](https://github.com/t4t5/omarchy-spaces/blob/f0e148075cd816e5047f237b7a705772deb606c3/assets/sounds/LICENSE), [assets/sounds/README.md](https://github.com/t4t5/omarchy-spaces/blob/f0e148075cd816e5047f237b7a705772deb606c3/assets/sounds/README.md), [Cargo.toml](https://github.com/t4t5/omarchy-spaces/blob/f0e148075cd816e5047f237b7a705772deb606c3/Cargo.toml).
- M1: [Public metadata](https://api.github.com/repos/t4t5/omarchy-spaces), retrieved 2026-11-26.
- M2: [v0.1.0 release](https://github.com/t4t5/omarchy-spaces/releases/tag/v0.1.0); tag resolves to reviewed SHA.
- M3: [Open PRs](https://github.com/t4t5/omarchy-spaces/pulls), including [workspace-ID proposal](https://github.com/t4t5/omarchy-spaces/pull/3), observed 2026-11-26.
- M4: [CI success](https://github.com/t4t5/omarchy-spaces/actions/runs/45711714920), [Release success](https://github.com/t4t5/omarchy-spaces/actions/runs/45711911130), both at reviewed SHA.
- A1: [Omarchy](https://omarchy.org).
- A2: [tmux](https://github.com/tmux/tmux).
- A3: [Herdr](https://herdr.dev), credited by upstream README and sound attribution.

---

**Attribution:** T4T5 / t4t5/omarchy-spaces; MIT code and Apache-2.0 Herdr sounds. Independent static analysis; no endorsement implied.
