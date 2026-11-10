# omacast (nchudleigh/oma-cast)

**Repo:** https://github.com/nchudleigh/oma-cast
**License:** MIT; preserve copyright and permission notices. Vendored Flea matcher has its own MIT notice; external applications retain their own terms.
**Reviewed:** 2026-11-10 (UTC)
**Revision:** 18f35f49ebf78b644934c0498d64ff8b481bd2a4 (main); README, license, manifest, CLI, QML/JavaScript runtime, Rust search adapter, tests, CI and selected provenance documents.
**Verification:** Static review and Git tree comparison only. No source/tests executed, dependencies installed, desktop capture, device connections, config changes or runtime probes.
**Stack:** QML/Qt Quick, Quickshell, JavaScript, Bash; optional Rust search and Python/PyGObject overlay helper.
**What it is:** An Omarchy-native application/command launcher, not a screen-casting product.

## Verdict

⚠️ **Interesting — substantial launcher evolution, with privacy and recovery gates before daily use.** Native menu/theme integration, clipboard tools and optional typo-tolerant search are useful. However, default-on clipboard collection, permissive local IPC authority, incomplete persistence recovery and unverified shell compatibility make this an evaluation candidate rather than a dependable drop-in recommendation.

## Identity and Update Notes

Checked 2026-11-10. GitHub identifies this as the public **nchudleigh fork** of typecraft-dev/oma-cast, not a redirect or rename of upstream. README installation examples still target typecraft-dev, and both use plugin ID typecraft.omacast. Do not assume those examples install the fork reviewed here. [1,2]

The existing [upstream review](oma-cast.md) is dated 2026-10-19 at 107484e4836195e89d50975568c6ee75c6c51853. No prior public review of this fork was found in the review collection, README or repository index. This distinct canonical identity receives an owner-qualified artifact; the upstream review remains a historical, pinned review rather than being silently overwritten.

The old commit was fetched and an actual tree diff against this fork was inspected: 112 files changed, 11,710 insertions and 2,421 deletions. This is a **cross-revision, cross-repository comparison**, not a claim that every change originated in this fork. Material differences include MIT licensing, root-level marketplace packaging, IpcHandler/PanelWindow replacing ShellIpc/OverlayWindow, clipboard/calculator/emoji/theme/Script Commands/Superwhisper features, owner-only storage setup, preserving hotkey setup, optional Rust search and CI. The old missing-type blocker and absence-of-license finding must not be mechanically carried over to this snapshot. [2–8]

## What It Is and Architecture

The keep-loaded menu plugin receives global shortcuts or local shell IPC in Launcher.qml. LauncherWindow presents results and Backend dispatches registered methods. Apps, Omarchy JSONC menus, built-ins and executable Script Commands become candidates; JavaScript ranks titles, aliases, learned terms and frecency. Settings and histories use five versioned JSON documents, not the reference corpus's SQLite schema. [2,3,5]

The optional Rust helper uses bounded NDJSON over stdin/stdout, not a TCP service. It matches titles/alternate names/subtitles/keywords while JavaScript retains ranking policy. Separate helper instances serve root and emoji search. Request IDs reject stale replies; a one-second timeout or helper failure disables native matching until reload and falls back to JavaScript. Cargo.lock and --locked builds improve reproducibility; serde/serde_json remain build dependencies that Cargo may download. The vendored matcher has explicit provenance hashes and retained MIT attribution. [6]

| Layer | Implementation and boundary |
|---|---|
| Desktop | Omarchy 4, Hyprland 0.56+ per README; exact shell API compatibility still needs runtime testing |
| UI | Qt Quick, Quickshell PanelWindow, host qs.Commons/qs.Ui integration |
| Actions | Host app/menu utilities; trusted Bash guards/providers and scripts |
| Storage | settings, frecency, calculator, emoji and clipboard JSON; atomic FileView writes |
| Search | JavaScript fallback; optional local Rust child processes |
| Dictation integration | External Superwhisper CLI; optional session-bus geometry helper |

No receiver, discovery/mDNS, AirPlay, Chromecast, Miracast, WebRTC, video encoder or streaming transport is implemented. No casting-compatible TV, special Wi-Fi adapter, LAN topology or GPU encoder requirement applies. Normal launcher operation needs a working Omarchy/Wayland desktop; clipboard capture/paste additionally calls wl-paste, wl-copy, wtype and common Linux utilities (including timeout, jq and setpriv). Rust is optional; Python/PyGObject is optional for the recording-overlay integration. No minimum RAM/GPU performance budget is established by this review. [2–7]

## Features and Capture Boundaries

- **Search and actions:** aliases, favorites, learned searches, calculator conversions/history, emoji and theme selection; apps can be focused instead of relaunched. Script Commands support up to three arguments and optional confirmation. FullOutput/inline modes are downgraded to compact output, not full Raycast parity. Extensions, snippets, quicklinks and broader window management remain roadmap. [2,3]
- **Clipboard is real capture:** enabled by default while the plugin remains loaded, independently of the launcher being visible. It stores text, links, file URIs, images and source-app metadata. Default retention is one week with at most 1,000 unpinned entries; pins bypass age/count pruning. Disabling recording does not erase existing history. Large blobs have time-limited reads but no explicit byte quota; entry count is not a disk-space bound. [3,5]
- **Sensitive-copy filtering has limits:** CLIPBOARD_STATE and the password-manager MIME hint are checked before capture. App denylisting happens later in Backend using the currently active toplevel, after the watcher may have written an image/long-text blob. Focus changes or missing metadata can defeat source attribution; blocked blobs are deleted when no retained entry uses them. “Password managers are never recorded” is stronger than this best-effort mechanism proves. [3,5]
- **Dictation is delegated:** Superwhisper commands start/stop recording, select microphone/language/mode and read recent transcription history (up to 500 entries). This repository does not itself implement a microphone/audio pipeline. Superwhisper permissions, processing destination, models, accounts and costs are separate and were not audited. The optional Python helper publishes card geometry on the session bus, not screen pixels or audio. [7]

## Security, Privacy and Network

Local search requires no account or API key. No direct telemetry client or Raycast-server integration was found in the reviewed runtime. Nevertheless, default-enabled currency conversion fetches public rates from api.frankfurter.dev on stale-cache refresh, with a 12-hour cache, 30-minute failure retry and 15-second request timeout. The request has no search query payload. Currency networking can be disabled through config. Browser-search actions intentionally disclose queries; menus/scripts can use arbitrary network services; Superwhisper may have independent egress. Thus the README's “only network request” describes direct built-in rate fetching, not an enforced offline boundary. [2,3,7,9]

The plugin exposes general backend calls and run through local Quickshell IPC without plugin-level authentication or method-specific capabilities. No HTTP listener/CORS policy is relevant here; host IPC permissions were not audited, so this is not evidence of remote unauthenticated access. Treat same-session callers, menu JSONC, shell environment and script directories as trusted code. Guards may execute during menu refresh before selecting an action. Script argument arrays avoid query-to-shell interpolation, but password arguments still appear in the script process argv. CLI run explicitly skips script confirmation; callers can supply confirmed through the backend. Confirmation is a user-interface safeguard, not authorization. User “Disable Command” hides search entries rather than forming a comprehensive execution denylist. [3,4,10]

Owner-only roots and recursive permission tightening are a meaningful improvement: setup uses umask 077, removes group/other access and precreates store files. Clipboard copies pass text through stdin instead of process arguments. But stores are **plaintext**, not encryption against the account, root or backups. Permission-repair failure is logged and directoriesReady is still set true, so this guarantee is not fail-closed. Malformed/unreadable config falls back to defaults, including clipboardHistory=true and currencyRates=true; privacy opt-outs can therefore revert on a broken config file. These are static code-path findings, not reproduced incidents. [3,5]

## Installation, Preservation and Rollback

This is desktop integration, not server self-hosting. The CLI installs no system packages itself, but if Cargo is available install builds the optional helper and can fetch crates. A marketplace installation and a development checkout share one plugin ID; both cannot independently occupy the same slot. Development install links the source tree and CLI, refuses an existing non-symlink plugin directory, but can replace symlinks. Updates therefore change executable desktop code; pin and review the intended repository. [2,4,6]

Hotkey setup now displays a plan and confirms (or accepts --yes), preserves an existing omacast.lua, appends/replaces a require statement and reloads Hyprland. Legacy setup can rename/mutate old binding files; legacy config/data/cache/state directories are moved when the new destination does not exist. It is not transactional: install can move directories before a build fails, and there is no automatic snapshot/rollback. Uninstall offers hotkey removal, removes owned links or delegates marketplace removal, but deliberately retains histories/config/cache/state. It can remove a customized hotkey file after confirmation; back it up first. [4,5]

While open, the UI enters a Hyprland submap so Super navigation reaches the launcher. Closing and normal QML destruction reset it, but that does not prove recovery after abrupt shell death. Keep an independent recovery path and the stock menu available; exercise reload, crash, hotkey restoration and data restoration in a disposable desktop profile before everyday use. No such operations were performed here. [8]

## Reliability and Recovery Findings

1. **Save-retry bug persists:** JsonStore records _lastWritten before setText; onSaveFailed logs without clearing it. An identical next write can be skipped after a failure. Atomic replacement prevents partial-file writes but is not a retry or durability guarantee. [5]
2. **Mutation success can overstate persistence:** several action handlers ignore JsonStore.update's false result when read-only. Clipboard blob deletion also occurs before the debounced JSON save succeeds; a save failure/crash can leave persisted entries pointing at deleted blobs. New blob capture followed by unavailable/read-only storage can leave unindexed files. [3,5]
3. **Recovery is partial:** invalid JSON/newer schema is preserved read-only, but general document-shape validation is incomplete. Config fallback has the privacy-default issue described above. No automatic restore procedure is established. [3,5]
4. **Process bounds are uneven:** native search, currency requests and clipboard reads have timeouts, and a dead clipboard watcher restarts after two seconds. Menu guards/providers and ScriptRunner lack comparable execution deadlines; ScriptRunner collects all stdout/stderr. Hung or noisy trusted scripts can stall refresh or consume memory. [6,9,10]
5. **Compatibility remains coupled:** runtime dynamically uses Omarchy's menu guard compiler with a fallback and validates complete guard output, but the user-menu path still hardcodes HOME/.config instead of XDG_CONFIG_HOME. Host-internal API changes and Lua-only hotkey setup remain real portability limits. [4,10]

## Tests, Maturity and Claims

The tree contains 23 Node test files, Rust unit/protocol tests, synthetic menu fixtures, privacy/marketplace/native-transport checks and a live shell smoke script. CI specifies Node 24 tests, locked Cargo tests/build, search integration, shell syntax and manifest parsing on a WarpBuild runner. Presence of that workflow is not passing evidence: the fork's public Actions endpoint returned zero workflow runs. None of its tests were executed for this review. [11]

Public metadata checked 2026-11-10: fork created November 3, last pushed November 7 at 18:31:10 UTC, 8 stars, 0 forks, issue tracker disabled, no releases and no pull requests returned. Source HEAD's commit time is November 7 at 18:31:02 UTC. These describe activity, not quality. The 40 ms opening claim, approximately 400 menu actions, clean-room provenance and exact compatibility were not independently demonstrated. Root/backend versions both say 0.1.0; pin SHA rather than inferring release assurance. [1,2,11]

## Comparison

| Option | Best fit | Tradeoff |
|---|---|---|
| Stock Omarchy menu | Minimum added maintenance and capture surface | Fewer launcher conveniences, no extra fork integration |
| [Vicinae](https://github.com/vicinaehq/vicinae) | Broader native command palette, snippets/files and Raycast-compatible extensions | Separate application rather than a host-shell plugin; evaluate its own privacy and dependencies |
| [Walker](https://github.com/abenz1267/walker) | Rust/GTK4 launcher with Elephant providers | Broader provider ecosystem and additional service instead of shared QML shell |
| [Earlier upstream review](oma-cast.md) | Historical baseline at its pinned October revision | Not a current certification of either upstream or this fork |

Alternative feature descriptions were checked against public READMEs, not benchmarked. For screen casting, none of these launchers is a media transport; choose a dedicated solution based on the actual receiver/protocol instead.

## Evidence and Limits

1. [Public fork metadata](https://api.github.com/repos/nchudleigh/oma-cast).
2. [README and license](https://github.com/nchudleigh/oma-cast/blob/18f35f49ebf78b644934c0498d64ff8b481bd2a4/README.md).
3. [Backend dispatch and lifecycle](https://github.com/nchudleigh/oma-cast/blob/18f35f49ebf78b644934c0498d64ff8b481bd2a4/Backend.qml).
4. [CLI install/setup/uninstall](https://github.com/nchudleigh/oma-cast/blob/18f35f49ebf78b644934c0498d64ff8b481bd2a4/bin/omacast).
5. [Storage, clipboard and privacy](https://github.com/nchudleigh/oma-cast/blob/18f35f49ebf78b644934c0498d64ff8b481bd2a4/core/Paths.js).
6. [Rust helper and provenance](https://github.com/nchudleigh/oma-cast/blob/18f35f49ebf78b644934c0498d64ff8b481bd2a4/search/PROVENANCE.md).
7. [Superwhisper integration](https://github.com/nchudleigh/oma-cast/blob/18f35f49ebf78b644934c0498d64ff8b481bd2a4/services/SuperwhisperSource.qml).
8. [Launcher window/submap](https://github.com/nchudleigh/oma-cast/blob/18f35f49ebf78b644934c0498d64ff8b481bd2a4/ui/LauncherWindow.qml).
9. [Currency network/cache](https://github.com/nchudleigh/oma-cast/blob/18f35f49ebf78b644934c0498d64ff8b481bd2a4/services/CalculatorData.qml).
10. [Menu guards/providers](https://github.com/nchudleigh/oma-cast/blob/18f35f49ebf78b644934c0498d64ff8b481bd2a4/services/OmarchyMenuSource.qml).
11. [CI workflow](https://github.com/nchudleigh/oma-cast/blob/18f35f49ebf78b644934c0498d64ff8b481bd2a4/.github/workflows/ci.yml).

Additional pinned evidence: [LICENSE](https://github.com/nchudleigh/oma-cast/blob/18f35f49ebf78b644934c0498d64ff8b481bd2a4/LICENSE); [manifest.json](https://github.com/nchudleigh/oma-cast/blob/18f35f49ebf78b644934c0498d64ff8b481bd2a4/manifest.json); [Launcher.qml](https://github.com/nchudleigh/oma-cast/blob/18f35f49ebf78b644934c0498d64ff8b481bd2a4/Launcher.qml); [services/JsonStore.qml](https://github.com/nchudleigh/oma-cast/blob/18f35f49ebf78b644934c0498d64ff8b481bd2a4/services/JsonStore.qml); [services/ClipboardWatcher.qml](https://github.com/nchudleigh/oma-cast/blob/18f35f49ebf78b644934c0498d64ff8b481bd2a4/services/ClipboardWatcher.qml); [services/ClipboardWriter.qml](https://github.com/nchudleigh/oma-cast/blob/18f35f49ebf78b644934c0498d64ff8b481bd2a4/services/ClipboardWriter.qml); [core/ClipboardHistory.js](https://github.com/nchudleigh/oma-cast/blob/18f35f49ebf78b644934c0498d64ff8b481bd2a4/core/ClipboardHistory.js); [core/Schema.js](https://github.com/nchudleigh/oma-cast/blob/18f35f49ebf78b644934c0498d64ff8b481bd2a4/core/Schema.js); [core/Migrate.js](https://github.com/nchudleigh/oma-cast/blob/18f35f49ebf78b644934c0498d64ff8b481bd2a4/core/Migrate.js); [services/ScriptRunner.qml](https://github.com/nchudleigh/oma-cast/blob/18f35f49ebf78b644934c0498d64ff8b481bd2a4/services/ScriptRunner.qml); [services/NativeSearch.qml](https://github.com/nchudleigh/oma-cast/blob/18f35f49ebf78b644934c0498d64ff8b481bd2a4/services/NativeSearch.qml); [search/Cargo.toml](https://github.com/nchudleigh/oma-cast/blob/18f35f49ebf78b644934c0498d64ff8b481bd2a4/search/Cargo.toml); [search/Cargo.lock](https://github.com/nchudleigh/oma-cast/blob/18f35f49ebf78b644934c0498d64ff8b481bd2a4/search/Cargo.lock); [services/superwhisper-frame.py](https://github.com/nchudleigh/oma-cast/blob/18f35f49ebf78b644934c0498d64ff8b481bd2a4/services/superwhisper-frame.py).

Public metadata checks: [releases](https://api.github.com/repos/nchudleigh/oma-cast/releases), [Actions](https://api.github.com/repos/nchudleigh/oma-cast/actions/runs?per_page=3), [pull requests](https://api.github.com/repos/nchudleigh/oma-cast/pulls?state=all).

Limits: shallow source acquisition plus fetched historical comparison commit; targeted static analysis, not an exhaustive audit of every reference document. No runtime compatibility/privacy/performance tests, host permission audit, dependency vulnerability scan, device/account access or independent legal/provenance verification. No source extracted.

---

**Attribution:** nchudleigh/oma-cast, typecraft and contributors; MIT. Flea matcher attribution: GM, MIT. Raycast and Superwhisper are separate projects.
