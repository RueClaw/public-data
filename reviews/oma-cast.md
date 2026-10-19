# oma-cast (typecraft-dev/oma-cast)

**Repo:** https://github.com/typecraft-dev/oma-cast
**License:** No license specified. Public visibility is not a general grant to reuse, modify or redistribute the code; obtain permission before reuse.
**Reviewed:** 2026-10-19 (UTC)
**Revision:** 107484e4836195e89d50975568c6ee75c6c51853 (main); implementation under bin/, plugin/, tests/, README, manifest, SPEC and selected reference documentation.
**Verification:** Static review only. No source execution, unit tests, live smoke tests, installation, desktop configuration changes or performance measurements were performed.
**Stack:** QML/Qt Quick, Quickshell, JavaScript, Bash, Omarchy shell and Hyprland; versioned JSON storage.
**What it is:** A Raycast-style application and command launcher embedded in Omarchy's desktop shell—not a screen recorder, casting service or streaming application.

---

## Verdict

⚠️ **Interesting — promising Omarchy-native launcher, not yet a dependable replacement.** The implemented search, ranking, favorites and themed action UI are substantial, and the pure-JavaScript core is sensibly separated from QML integration. But the reviewed main branch still uses shell types reported missing on Omarchy 4.0.5, licensing is unspecified, and command execution and persistence have important boundaries and failure cases. Evaluate only against a known-compatible shell version; wait for compatibility, licensing and integration-test evidence before depending on it.

## What It Is

oma-cast searches installed desktop applications and the host's Omarchy menu, presents nested actions with breadcrumbs and live state, and learns which commands a user selects. It is a keep-loaded menu plugin, not an independent desktop service. Its own IPC methods are exposed through the surrounding shell; its hotkey uses a Hyprland global shortcut rather than starting the CLI for every press. [1–4]

The implemented scope is much smaller than the reconstruction specification. Clipboard history, snippets, quicklinks, calculator, Script Commands, Raycast extension execution, window management and importing macOS configuration are roadmap items. The reference SQL schema and large lists of Raycast methods do not describe an implemented SQLite database or extension runtime. Current persistence is two JSON documents. [1,4,6]

The README claims approximately 40 ms opening time, approximately 400 Omarchy actions, no telemetry and no Raycast-server traffic. The source supports local search and explicit browser fallbacks, but this review did not measure latency, enumerate a running host's menu or independently establish clean-room provenance. [1]

## Stack

| Layer | Implementation |
|---|---|
| Shell integration | Omarchy menu plugin, keepLoaded, GlobalShortcut, ShellIpc |
| UI | Qt Quick/QML, Quickshell Wayland layer surface, host qs.Commons/qs.Ui theme and layout types |
| Search | JavaScript candidate assembly, fuzzy ranking, aliases, frecency and learned terms |
| Execution | Host app library, Omarchy command helpers, Bash guards/providers, browser launcher, wl-copy |
| Persistence | XDG paths; settings.json and frecency.json; FileView atomic writes and numbered migrations |
| Tooling | Bash CLI; Node built-in test runner for core modules; live shell smoke script |

There is no package manifest or dependency lockfile in the reviewed tree. Node is a development/test dependency, not a runtime launcher dependency. The README requires Omarchy 4, Hyprland 0.56+ and socat; runtime additionally relies on the installed shell's QML API and relevant Omarchy utilities. Optional development watching needs inotify-tools; the smoke script also calls Python 3. Version compatibility is therefore more important than the absence of npm dependencies. [1–4,7]

## Key Features

### Search that remembers intent

RootSearch combines app entries, visible Omarchy actions, submenu links, runtime font/power-profile choices and a built-in entry back to the original menu. Ranker prioritizes exact aliases and learned terms alongside title/subtitle matching, pins and frecency rather than applying one generic fuzzy score. Frecency uses a ten-day decay half-life; learned terms affect ranking within a 17-day window. Per-item terms and global search history are each capped at 20 entries, but expiry for ranking is not deletion from disk. [5]

### Native presentation without a separate application runtime

The action panel, keyboard selection, favorites, aliases and theme bindings are implemented. LauncherWindow consumes the host's menu color, font, border and spacing APIs. This produces tight visual integration, but also couples loading to internal shell types. [2,8]

### Good separation, incomplete operational hardening

The backend owns a method registry, candidates, execution and stores; pure JS modules expose a CommonJS export path for tests and QML imports for production. Migration history, newer-schema read-only behavior and atomic writes are useful safeguards. They do not establish successful disk persistence, schema validity or safe command policy by themselves. [4–6]

## Architecture and Reliability

The main flow is: shell/global shortcut → Launcher → LauncherWindow → Backend RPC registry → RootSearch/Ranker → app or menu action. Menu JSONC files are watched; guard/provider processes refresh on open, with cached results used while refresh runs. Settings and visit changes trigger reranking and debounced writes. [2–6,8]

**Compatibility is the immediate blocker.** The reviewed Launcher uses ShellIpc and LauncherWindow derives from OverlayWindow. Open PR [#1](https://github.com/typecraft-dev/oma-cast/pull/1) reports that both types are missing on Omarchy 4.0.5 with Quickshell 0.3.2, preventing the plugin from loading. Its proposed replacement uses IpcHandler and PanelWindow; the contributor reports passing doctor/smoke checks and a worst toggle of 75 ms. This is third-party evidence, not a reproduced result, and the change is not present in this reviewed SHA. “Omarchy 4” alone is not a sufficient compatibility guarantee. [2,8,9]

Other concrete static findings:

- **Save failure can suppress an identical retry.** JsonStore.write updates _lastWritten before file.setText; onSaveFailed only logs. A later write of the same serialized document returns early, even if the earlier write failed. A subsequent different edit may retry, but the failing value has no explicit retry path. [6]
- **Some mutations can claim success while read-only.** JsonStore.update returns false when unavailable/read-only. Several favorite/alias/disable paths ignore that result and return success or emit a change notification. updateGeneralSettings does check read-only status, so protection is inconsistent rather than absent everywhere. [4,6]
- **Schema versions are checked, document shape is not comprehensively validated.** A syntactically valid current-version object missing general/commands/items can pass migration and later break consumer assumptions. Corrupt JSON is preserved rather than overwritten, which is good, but read-only recovery and user-visible diagnostics need integration testing. [4,6]
- **Refresh work has no explicit timeout.** Bash guard batches run eight groups in parallel; providers run sequentially. A stuck command can keep a process running, preserve stale state and skip subsequent refreshes. Unknown when guards default visible, so these guards must not be treated as authorization controls. [3]
- **XDG support is inconsistent.** Data/config resolution and CLI plugin paths use XDG settings, but the user-menu source hardcodes HOME/.config/omarchy/extensions/omarchy-menu.jsonc. Nondefault XDG_CONFIG_HOME users can get a different menu than expected. [3,6]
- **Version labels disagree.** The manifest says 0.0.1 while Backend.version says 0.1.0. Pin the source commit rather than relying on either version string. [4]

These are code-path assessments, not reproduced runtime failures.

## Security, Privacy and Network Boundaries

**Treat the plugin and menu files as trusted executable configuration.** Menu actions reach the host's Util.execDetached. Guard expressions are intentionally embedded in bash -lc scripts and can execute on menu rebuild/open without selecting an action. Guard IDs are restricted before insertion into quoted output, and provider values use shell quoting; these are useful protections against accidental command construction errors, not a sandbox for untrusted menus. Bash login-shell behavior also inherits the local shell environment. [3,4]

The generic IPC call surface dispatches registered backend methods, including actions and settings mutations, without plugin-level authentication or per-method capabilities. No HTTP listener or CORS surface is implemented here; access control depends on the host shell's local IPC transport, which was not audited. There is no basis to claim remote unauthenticated execution. However, same-session IPC callers should be regarded as trusted. “Disable Command” filters search visibility, but direct run/performAction looks up the candidate without checking the enabled setting; it is a UI preference, not an execution denylist. [2,4,5]

There is no general confirmation barrier around menu action execution; downstream tools determine prompts, privilege escalation and destructive-action behavior. Install does not invoke sudo or a package manager, but enabled menu commands may delegate to tools that do. App launch and clipboard-copy paths use argument arrays; browser fallbacks use fixed HTTPS search templates, encodeURIComponent and an argument-array launcher rather than interpolating the search query into a shell command. [4,5]

**Network:** ordinary ranking is local. Choosing Google or DuckDuckGo explicitly sends the query to that search engine through the browser, with the browser's normal history/cookies/network exposure. Arbitrary selected menu actions and guard expressions can themselves use the network. “No telemetry” does not mean an enforced offline sandbox. No direct telemetry client, Raycast endpoint, account login or embedded secret store was found in the implementation reviewed. [3–5]

**Local privacy:** visit times, learned query strings and search history live in plaintext frecency.json under the XDG data directory; command aliases/preferences are in settings.json. No encryption or explicit restrictive chmod/umask policy is implemented. The scope of local access therefore depends on filesystem permissions and backup practices. Resetting one item's ranking deletes that item but does not clear the separate global history. [4–6]

**Recording/casting/audio:** there is no capture pipeline, encoder, audio mixing, microphone permission flow, stream destination or casting protocol in this repository's runtime. Such actions could appear from the host Omarchy menu and be launched externally, but their privacy/consent behavior belongs to those external commands. Clipboard copy via wl-copy is implemented; built-in clipboard-history collection is not. [1,3–5]

## Installation and Desktop Integration Notes

This is desktop integration, not a self-hosted web deployment. The CLI links the live source directory into the user's Omarchy plugins directory, links itself into the user's local bin directory, rescans plugins and enables the plugin. A source update changes the linked code; there is no independent packaged artifact or pinned dependency resolution. Existing non-symlink plugin paths are refused, but existing symlinks can be replaced. [7]

The separate setup hyprland command requires Lua-based Hyprland configuration, scans for a limited set of Alt+Space conflicts, overwrites its own oma-cast.lua, appends a require statement if absent, and reloads Hyprland. Rerunning setup can erase edits to that generated file. Uninstall disables/unlinks the plugin and owned CLI link, but does not remove the generated hotkey file/require line or persisted user data. Review those remaining files before manual cleanup; uninstall is not a complete rollback. [7]

No install or setup command was run for this review. Recommended evaluation gates: obtain license clarification; verify the compatibility fix on the exact shell version; retain a working original menu/hotkey; use a disposable desktop profile; exercise disk-full/corrupt-store recovery and hung guard/provider behavior before trusting daily use.

## Tests and Maturity

Eight Node test files cover frecency, logging, migrations, paths, RPC, ranking, root-search composition and Omarchy-menu parsing. Tests include fuzzy-score expectations, aliases, learned-term expiry, history handling, provider quoting and guard script execution. The menu test optionally reads an installed system menu, so it is not wholly environment-independent. The smoke script invokes a live shell, toggles windows, watches the Hyprland socket, checks candidates and measures latency. None were run here. No .github CI workflow was present in the reviewed tree. [10]

Public GitHub metadata retrieved 2026-10-19 showed creation that same day, last push at 20:04:02 UTC, 61 stars, 3 forks and one open item (the compatibility pull request). The releases endpoint returned an empty list. These are a time-sensitive activity snapshot, not evidence of quality or longevity. The reviewed commit timestamp is 20:03:55 UTC. [11]

The README calls this a clean-room project with no Raycast code/assets. SPEC explicitly describes static reverse engineering, and the ranking modules describe themselves as ports of the documented algorithm. This review cannot verify provenance or resolve legal questions from those statements. No LICENSE/COPYING file or package-license grant was found. Do not assume Raycast extensions' MIT license licenses this repository; no source extraction is included in this review. [1,5,12]

## Comparison

| Option | Best fit | Tradeoff against oma-cast |
|---|---|---|
| Existing Omarchy menu | Retaining the desktop's own actions and integration | Lowest additional maintenance; oma-cast adds learned ranking, aliases and a Raycast-style action workflow |
| [Vicinae](https://github.com/vicinaehq/vicinae) | Broader Linux command palette and Raycast-ecosystem extensions | Its current README advertises clipboard, snippets, calculator, file search and extensions that remain roadmap here; separate application rather than this shell-native plugin |
| [Walker](https://github.com/abenz1267/walker) | Customizable launcher with a provider ecosystem | Rust/GTK4 frontend with Elephant service/providers; broader advertised tools, but additional components rather than sharing Omarchy's QML shell |

Alternative feature descriptions were checked against their public READMEs, not benchmarked or security-audited. Neither comparison proves exact behavioral parity. oma-cast's strongest differentiator is native Omarchy menu/theme integration, precisely the boundary currently most exposed to shell API churn.

## Evidence and Limits

1. [README: purpose, requirements, roadmap and claims](https://github.com/typecraft-dev/oma-cast/blob/107484e4836195e89d50975568c6ee75c6c51853/README.md).
2. [Launcher: global shortcut, shell lifecycle and IPC](https://github.com/typecraft-dev/oma-cast/blob/107484e4836195e89d50975568c6ee75c6c51853/plugin/Launcher.qml).
3. [Menu source: file watches and Bash processes](https://github.com/typecraft-dev/oma-cast/blob/107484e4836195e89d50975568c6ee75c6c51853/plugin/services/OmarchyMenuSource.qml); [menu parsing, guards and providers](https://github.com/typecraft-dev/oma-cast/blob/107484e4836195e89d50975568c6ee75c6c51853/plugin/core/OmarchyMenu.js).
4. [Backend: dispatch, actions, stores and versions](https://github.com/typecraft-dev/oma-cast/blob/107484e4836195e89d50975568c6ee75c6c51853/plugin/Backend.qml); [manifest](https://github.com/typecraft-dev/oma-cast/blob/107484e4836195e89d50975568c6ee75c6c51853/plugin/manifest.json).
5. [RootSearch](https://github.com/typecraft-dev/oma-cast/blob/107484e4836195e89d50975568c6ee75c6c51853/plugin/core/RootSearch.js), [Ranker](https://github.com/typecraft-dev/oma-cast/blob/107484e4836195e89d50975568c6ee75c6c51853/plugin/core/Ranker.js), [Frecency](https://github.com/typecraft-dev/oma-cast/blob/107484e4836195e89d50975568c6ee75c6c51853/plugin/core/Frecency.js).
6. [JsonStore](https://github.com/typecraft-dev/oma-cast/blob/107484e4836195e89d50975568c6ee75c6c51853/plugin/services/JsonStore.qml), [Migrate](https://github.com/typecraft-dev/oma-cast/blob/107484e4836195e89d50975568c6ee75c6c51853/plugin/core/Migrate.js), [Schema](https://github.com/typecraft-dev/oma-cast/blob/107484e4836195e89d50975568c6ee75c6c51853/plugin/core/Schema.js), [Paths](https://github.com/typecraft-dev/oma-cast/blob/107484e4836195e89d50975568c6ee75c6c51853/plugin/core/Paths.js).
7. [CLI: install, uninstall, reload, setup and doctor](https://github.com/typecraft-dev/oma-cast/blob/107484e4836195e89d50975568c6ee75c6c51853/bin/oma-cast).
8. [LauncherWindow](https://github.com/typecraft-dev/oma-cast/blob/107484e4836195e89d50975568c6ee75c6c51853/plugin/ui/LauncherWindow.qml).
9. [Open compatibility PR #1](https://github.com/typecraft-dev/oma-cast/pull/1), checked 2026-10-19; third-party report only, outside reviewed main revision.
10. [Tests tree](https://github.com/typecraft-dev/oma-cast/tree/107484e4836195e89d50975568c6ee75c6c51853/tests); [live smoke script](https://github.com/typecraft-dev/oma-cast/blob/107484e4836195e89d50975568c6ee75c6c51853/tests/smoke.sh).
11. [Public metadata](https://api.github.com/repos/typecraft-dev/oma-cast), [releases](https://api.github.com/repos/typecraft-dev/oma-cast/releases), [issues including PRs](https://api.github.com/repos/typecraft-dev/oma-cast/issues?state=all).
12. [SPEC: reconstruction provenance and planned architecture](https://github.com/typecraft-dev/oma-cast/blob/107484e4836195e89d50975568c6ee75c6c51853/SPEC.md).

Limitations: shallow source checkout; static implementation review, not a complete line-by-line audit of the extensive reference corpus. No runtime host IPC-permission audit, compositor test, latency benchmark, dependency vulnerability scan or legal provenance verification. No source or tests were executed. Findings apply to the pinned commit, not a future merge of PR #1.

---

**Attribution:** typecraft-dev/oma-cast and its contributors. No license specified; this is independent analysis, not redistributed source code. Raycast is a separate project; no affiliation is implied.
