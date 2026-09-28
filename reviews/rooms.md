# Rooms (saragordic/rooms)

**Repo:** https://github.com/saragordic/rooms  
**License:** MIT (© saragordic). Free reuse with attribution. It has no third-party dependencies: the Swift package uses only Apple frameworks.  
**Reviewed:** 2026-09-28 (commit `c659cc2`)  
**Stack:** Swift 6 (SwiftPM, macOS 14+), AppKit, Accessibility API (AXUIElement), Carbon `RegisterEventHotKey`, CoreGraphics; universal (arm64 + x86_64) ad hoc signed build, Homebrew cask  
**What it is:** A menu-bar app for switching between projects on macOS. Each "room" is a saved set of windows plus a layout. ⌥Space, then the room name, brings those windows to the current screen and lays them out. Everything else is hidden or parked off-screen, and nothing is ever closed.

---

## Verdict

⚠️ **Interesting. It's a small, carefully built project switcher with a strong "never lose a window" invariant. Treat it as a personal tool, not a hardened window manager.**

What's good: ~4,500 lines of Swift with no dependencies and no network code at all (grep finds no URLSession, sockets, or URLs in `Sources`). There's a clean split between a pure `RoomsCore` (layouts, arrangement recognition, window matching, storage), covered by 89 tests on macOS CI, and the AppKit/AX app. The parking design is the part worth studying. Before any window moves off-screen, its original frame goes to `resting.json` (atomic write). If that write fails, the window doesn't move. The entry is only cleared once the window is confirmed back within 16 px. Quit, Show Everything, and relaunch after a crash all replay the ledger.

Limits: it's four days old and single-author, tested hands-on only on Apple Silicon with macOS 26. It isn't notarized, handles windows rather than browser tabs, doesn't manage Spaces or full-screen windows, and uses one private symbol (`_AXUIElementGetWindow`, resolved with `dlsym`) to get stable window IDs. That's common among macOS window tools, but it could break with an OS update. If you live in a handful of recurring window sets per project, it's worth trying. If you want tiling or Spaces automation, use AeroSpace or yabai.

---

## What It Is

- **Rooms:** a named set of windows (bundle ID, saved title, live window ID, display UUID, fractional frame, optional grid cell) stored in `~/Library/Application Support/Rooms/rooms.json`, which is human-editable.
- **Switcher:** ⌥Space palette with fuzzy room search, ⌃⌥1–9 direct keys, right-click to edit, rename, or delete (⌘Z restores a deleted room).
- **Layouts:** Focus, Columns, Grid, "My Layout" (your arrangement snapped to an even-gap grid), and Stack (overlapping cards, used only when app minimum sizes leave nothing tidier). Tab cycles layouts with a live preview. Each display remembers its own layout.
- **Snapping keys:** halves, thirds, quarters, two-thirds, maximize, center, restore, and move-to-display, with the same gaps as rooms.
- **Hiding:** apps with no room windows are hidden natively. Windows of room apps that aren't in the room are parked just off-screen.

## Stack

| Layer | Tech |
|-------|------|
| Core logic | `RoomsCore` (Foundation + CoreGraphics only): `Layout`, `GridLayout`, `Arrangement`, `WindowSlot`/`SlotMatcher`, `Matcher`, `RoomStore`, `Snap` |
| App | AppKit menu-bar app: `WindowEngine` (AX find/move/park/measure), palette, picker, overlays (Liquid Glass looked up at run time on macOS 26) |
| Input | Carbon `RegisterEventHotKey`, so no Input Monitoring permission is needed |
| Permissions | Accessibility only |
| Build | SwiftPM + Makefile, ad hoc or "Rooms Dev" self-signed cert, universal release ZIP, Homebrew cask in `saragordic/homebrew-tap` |
| CI | GitHub Actions `macos-15`: `make test` + release build |

## Key Features

### Write-Ahead Parking Ledger
`WindowEngine.park` records `{windowID, bundleID, title, savedFrame}` and only moves the window if `saveLedger()` succeeds. `unpark` restores the saved frame onto a display that's still connected, and clears the entry only if the window actually landed there. Unresponsive apps keep their entry for the next attempt. `recoverFromLastSession` runs on launch. This is the right way to build anything that moves user state out of sight.

### Tiered Window Matching
`SlotMatcher.assign` fills slots strongest evidence first: live window ID, then saved title, then any window of the same app. It prefers windows not claimed by another room, and each window is used at most once. This lets rooms survive app restarts, where window IDs change, without grabbing windows another room owns.

### Min-Size-Aware Auto Layout
When you save a room, Rooms measures how small each app will let its windows go. Auto then tries Focus → Columns → Grid and falls back to Stack only when minimum sizes make a tidy layout impossible. Stored layouts are re-checked when applied and fall back to Auto instead of pushing windows off-screen or on top of each other.

### Arrangement Recognition
Press ⌘S after arranging windows by hand, and `Arrangement` either recognizes a standard layout and tidies it, or snaps your arrangement to a grid with even gaps ("My Layout").

### Serialized Window Work
Switching, saving, re-layout on display change, and Show Everything run strictly one at a time (`inTurn` in `AppDelegate`), which avoids the racing-AX-calls bugs common in window tools.

## Architecture

```
⌥Space (Carbon hotkey) ─▶ PaletteController ─▶ AppDelegate.inTurn { … }
                                                   └─ WindowEngine
                                                        ├─ inventory()   AX windows + _AXUIElementGetWindow IDs
                                                        ├─ SlotMatcher   (RoomsCore) slot ← live window
                                                        ├─ Layout/Grid   (RoomsCore) frames for this screen
                                                        ├─ move / hide apps / park(ledger first)
                                                        └─ resting.json  (atomic) · rooms.log
RoomStore ─▶ rooms.json (atomic write, user-editable)
```

`WindowEngine.swift` (754 lines) and `AppDelegate.swift` (708 lines) are the largest files. The code is commented with intent ("Do not move a window unless its way back is safely on disk"), not narration.

## Security

- **No network access.** There's no networking code in `Sources`. This matches the README and a stated contributor invariant.
- **Accessibility permission** gives the app control over every window's position and visibility. That's inherent to the category. It doesn't request Input Monitoring or Screen Recording.
- **Private API:** `_AXUIElementGetWindow` via `dlopen(nil)`/`dlsym`. It fails soft (returns nil), but it's undocumented.
- **Local data** (`rooms.json`, `resting.json`, `~/Library/Logs/Rooms/rooms.log`) contains window titles, which can include document names, email subjects, and so on. The README warns against posting them unedited.
- **Release hygiene:** `make release` strips local paths from the binary and refuses to ship if `$HOME` or `/Users/` remains, clears xattrs so the ZIP doesn't break the signature, and verifies the unzipped signature. Builds are ad hoc signed and not notarized. The README's install path via the Homebrew cask (`brew trust saragordic/tap`) skips the Gatekeeper prompt, so you're trusting the tap.
- **CI:** `permissions: contents: read`, and `actions/checkout@v4` is pinned by tag, not SHA.
- The README suggests "send this repo to your coding agent and ask it to install Rooms". That's fine for this repo, but it's a habit worth being careful with.

## Maturity

- Created 2026-09-23, last push 2026-09-26. 329 stars, 14 forks, and 6 open issues at review time. Single author. GitHub releases plus a Homebrew cask.
- Tests: 89 test functions across 7 files covering layout, arrangement, matching, snapping, "safety" (no off-screen or overlap), engine core, and review regressions. CI runs them on macOS 15.
- Docs: a clear README (install, first room, uninstall with `--zap`, privacy, known limits) and a CONTRIBUTING file with explicit invariants and a `desksnap` tool to save and restore your desk before risky testing.

### Validation on 2026-09-28

- `git clone --depth=1` at `c659cc2`; read README, CONTRIBUTING, LICENSE, Package.swift, Makefile, CI workflow, `WindowEngine` (parking/unparking), `WindowSlot`/`SlotMatcher`, `RoomStore`, `Hotkey`, `AX.swift`.
- Grepped `Sources` for networking, process spawning, and private symbols. Found only the `_AXUIElementGetWindow` lookup.
- **Tests not run.** The review host is Linux with 1 GB RAM and no Swift toolchain, and `RoomsCore` imports CoreGraphics. The 89-test count comes from reading the source. The CI workflow runs them on `macos-15`. The app wasn't launched.

## Comparison

| Aspect | Rooms | Stage Manager | AeroSpace / yabai | Rectangle / Raycast WM | Workspaces-style launchers |
|--------|-------|---------------|-------------------|------------------------|-----------------------------|
| Model | Named window sets + layout per project | Automatic app groups | Tiling + virtual workspaces | Snap one window at a time | Open apps/files/URLs per project |
| Switch | ⌥Space + name, ⌃⌥1–9 | Click strip | Keybinding per workspace | n/a | Launcher |
| Hides others | Hide app / park off-screen, never close | Yes | Workspaces | No | Optional quit |
| Recovery | Write-ahead ledger for parked windows | OS | Emulated workspaces restore on quit | n/a | n/a |
| Private APIs | One (`_AXUIElementGetWindow`) | n/a | AeroSpace: same one; yabai: SIP-off scripting additions | Minimal | Usually none |
| License | MIT | Apple | MIT / MIT | MIT / proprietary | Mostly proprietary |

## Self-Hosting Notes

- Install with Homebrew or build with `make run` (Xcode 16+ or CLT). Create a "Rooms Dev" code-signing cert so the Accessibility grant survives rebuilds.
- Turn off Stage Manager, since it fights any window manager. Rebind ⌥Space if you type non-breaking spaces.
- Keep one browser window per project (Chrome's "Name Window" helps), because rooms track windows, not tabs.
- To remove it cleanly: Quit Rooms first so parked windows come back, then `brew uninstall --zap --cask rooms`, then remove the Accessibility entry.

## Reusable Patterns

- **Write-ahead ledger before hiding user state.** Persist the way back atomically, refuse to act if the write fails, and clear the entry only after verifying the restore. Replay on quit, on an explicit "show everything", and on next launch.
- **Evidence-tiered matching with ownership.** Match on stable ID, then title, then type, while avoiding items claimed elsewhere, and use each candidate once.
- **Pure core + thin OS shell.** Keep all geometry and matching logic free of AppKit so it's unit-testable, and leave AX calls in one engine file.
- **Release guard against leaking build paths.** Strip, grep the binary for `$HOME`//Users/, and fail the build if found.

---

**Attribution:** saragordic/rooms, MIT
