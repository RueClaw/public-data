# Fairy Cursor (Rrrima/fairy-cursor)

**Repo:** https://github.com/Rrrima/fairy-cursor
**License:** MIT (Rima Cao, 2026); bundled Barlow fonts use SIL OFL 1.1. Preserve component notices when redistributing.
**Reviewed:** 2026-11-26 (UTC)
**Revision:** ac165ff6223a7ee20f0d9558e977327e603fe103 (main); repository-wide targeted scope detailed below.
**Verification:** Static source, public GitHub metadata and release comparison only. No installation, build, source execution, macOS permissions, desktop access or tests run.
**Stack:** Swift, Swift Package Manager, AppKit/SwiftUI, Accessibility, ScreenCaptureKit, AVFoundation/Core Image; ausm screenshot/cursor kits.
**What it is:** A macOS 26 menu-bar companion that carries screenshots beside the pointer, pastes them on double-click, creates contextual Markdown notes and records the screen with zoom and ink.

---

## Verdict

⚠️ **Interesting — thoughtful interaction engineering, but not a dependable capture archive by default.** The small capability architecture and explicit paste/gesture policies are worth studying; this is a plausible personal-use pilot for someone comfortable granting desktop-wide permissions. Screenshot redirection and deletion, heuristic delivery confirmation, mutable dependency resolution and unverified release binaries prevent an unconditional deployment recommendation.

## What It Is

Fairy Cursor replaces the usual screenshot thumbnail/file workflow with a floating stack. Double-clicking a recognized destination pastes the stack, saves it in Finder or inserts it into a note; shaking discards a card. It is a native desktop helper, not an AI agent or hosted service. Notes and recording are separately switchable capabilities, enabled by default alongside screenshots.

The README says it “doesn't take screenshots itself,” but also explains that ausm detects the system screenshot and **recaptures** it. The integration receives an image from ScreenshotMonitorKit rather than simply importing the system PNG. Without auditing or exercising that dependency, pixel identity, timing and exclusions cannot be assumed. [README][readme] [screenshot integration][screenshots]

## Stack

| Layer | Tech |
|---|---|
| Host and UI | Swift AppKit/SwiftUI; menu-bar-only app |
| Decision logic | FairyCore: gestures, drop/paste policies, held pile, viewport and ink |
| Capability boundary | FairyKit protocols; three compiled-in modules, not sandboxed plugins |
| OS integrations | Accessibility, CG events, Apple Events, ScreenCaptureKit |
| Recording | Core Image transforms; AVAssetWriter H.264 MOV |
| Storage | Markdown notes, attachments, JSON window state, UserDefaults, PNG/MOV files |
| Dependency | foundation-interface/ausm, SwiftPM requirement from 0.1.2; no checked-in lockfile |

## Key Features

### Cursor-based delivery with unusually explicit failure handling

The router excludes secure text fields on its direct editable path, distinguishes Finder, terminals and canvas/document surfaces, and waits for mouse-up/focus settlement. Terminal pastes write an image under the user's Pictures/Fairy Cursor directory and paste a shell-quoted path. Finder removes only successfully saved cards from the pile. These are useful, concrete ergonomics rather than a generic clipboard wrapper. [DropRouter][router] [PasteTarget][paste]

Paste jobs snapshot and later restore the clipboard, account for terminal copy-on-select, and mark generated clipboard items transient. Restoration can wait eight seconds for a late reader. Those markers are advisory: other clipboard clients can still read the content. A pasteboard read is treated as acceptance when no single-line probe is available, and later cards skip the probe. This is **not proof that the intended app retained the attachment or that a message was sent**; clipboard-manager reads and focus changes remain integration risks. [PastePolicy][policy]

### Plain-file notes, with context worth protecting

Notes use atomic Markdown writes, a 400 ms debounce, collision-avoiding filenames, Trash on deletion and separate window-state JSON. They record application identity, window title and full page/document URL in front matter. This is helpful provenance but can also preserve sensitive document names, URL query values and browsing context. A synced notes folder deliberately carries that metadata off-device; inspect it before sharing. External edits to open notes are ignored in favor of the in-memory version, so this is not a multi-writer merge system. Legacy migration suppresses individual write/copy errors yet writes its completion marker, a recovery weakness if storage fails. [NoteStore][notes] [NoteContext][context]

### Focused recording, not a complete production recorder

The recorder captures the display under the pointer, uses a 60 Hz output clock, crops/scales a movable viewport and writes H.264 MOV with the longest dimension capped near 3840 pixels. Audio capture is explicitly off. The blue frame is excluded; pen/highlighter overlay is intended to appear in the recording. Enlarging the cursor uses private SkyLight functions loaded at runtime, a compatibility risk across macOS updates. No frame-rate, latency, battery or image-quality measurements were run. [ScreenRecorder][recorder] [CursorScale][cursor]

## Architecture

The host owns cursor following, the held pile, delivery and capability coordination. FairyKit exposes host services; screenshot, notes and recording modules do not import each other. FairyCore isolates decisions from live OS effects and is the sole target of the test suite. Owner-tagged visibility/exclusivity/drop-zone state supports cleanup when modules deactivate. This is a good reusable design pattern, but all modules run with the same process authority; a capability toggle is not a security boundary. Runtime installation of third-party capabilities is described as future work, not a shipped feature. [Package.swift][package] [CapabilityRegistry][registry]

## Security, Privacy and Permissions

- **Broad local authority:** Accessibility enables inspecting UI/text and synthesizing paste input; Screen Recording exposes display content. Apple Events automation is declared for Finder/browser queries, beyond the README's two primary setup permissions. The entitlement file does not enable App Sandbox. These are meaningful grants even without networking. [Info.plist][info] [entitlements][entitlements]
- **Scope the local-only claim:** No direct network client was found in the reviewed app source; that is not a runtime traffic audit or an audit of ausm. Pasting into cloud apps and syncing files can transmit captures through other software. The separate marketing website loads Umami analytics and submits feedback (message, optional email and page URL) to the author's site. “Nothing leaves your Mac” should not be extended to website interactions. [site][site]
- **Persistence exceeds the floating card:** terminal delivery writes durable files, notes retain origins, recordings remain on disk, and some unconditional NSLog calls include saved paths. No application-level encryption or retention controls were found for these files. macOS account/file protections and the chosen folders matter.
- **Supply chain:** SwiftPM permits compatible ausm upgrades and explicitly ignores Package.resolved. The dependency's complete source, transitive terms and resolved revision were not audited. Source builds are therefore not reproducibly pinned by this repository alone.

## Persistence and Recovery

**The most important caveat is screenshot takeover.** Activation changes the system screencapture location to an app-managed folder and disables thumbnails, retaining originals in UserDefaults. It purges that folder on activation/restoration and after capture sessions. “Keep every screenshot” defaults off, so an unsaved card is not an archive. The released-card memory defaults to three batches/eight cards with a 15-minute TTL and is not serialized. A process crash can lose those cards. [SystemScreenshotTakeover][takeover] [HeldPile][pile]

Normal deactivation/quit restores screenshot preferences. A crash does not execute that cleanup: system screenshots may continue accumulating in the redirected folder while the app is absent, and the next activation purges its contents. The stored original preferences make later restoration possible, but this is **not crash-safe recovery of intervening screenshots**. The screenshot capability takes over before starting its monitor; the host waits for Accessibility, not successful Screen Recording capture, so validate capture permission and actual output before relying on it. Keep-every-screenshot writes asynchronously, with failures logged rather than a durable success acknowledgment. [AppDelegate][app] [ScreenshotSaver][saver]

Recording deactivation waits up to three seconds for finalization; failed/empty finalization removes the output. Cursor scale has a saved original restored on recording-capability activation, but this is next-launch cleanup, not a watchdog while the process is dead. There is no demonstrated recovery of a crash-interrupted MOV. Notes flush on orderly shutdown; atomic writes reduce partial-file risk but do not eliminate debounce-window loss or external-edit conflicts. [RecordingCapability][recordcap] [ScreenRecorder][recorder]

For an evaluation: use non-sensitive captures, enable retention, confirm a file actually appears, test unsupported destinations and clipboard-manager coexistence, then verify screenshot location/thumbnail behavior after disabling or quitting. Do not assume deleting the app restores global settings after a crash.

## Maturity, Releases and Verification

Public anonymous GitHub metadata on 2026-11-26 reported **44 stars, 5 forks, zero open issues**, and a last push of 2026-11-26T04:41:21Z. These are snapshots, not quality signals; the recent issues API entries inspected were closed pull requests, not evidence of a bug-free application.

Latest published release: **v0.3.1**, 2026-11-25T18:41:23Z, tag commit **55b3abc98e56b7e2d9d435f5f04b5adb626040ad**, with a 2,919,943-byte fairy-cursor.zip asset. Info.plist also says 0.3.1, build 4. The reviewed main revision differs from that tag only in README.md and site/index.html, so the app implementation inspected matches the tagged source. Neither the GitHub ZIP nor the website download was installed or signature-verified. [release][release]

The release script supports universal arm64/x86_64 builds, Developer ID signing, notarization and stapling. That supports the documented release process, **not independent proof of the distributed artifact's signature or source correspondence**. Its build pipelines end in `|| true`, followed by an executable-exists check; a failed build can potentially package an old existing binary. Use a clean build and propagate failures before trusting a release. [bundle.sh][bundle]

Static inventory found **11 XCTest files and 165 functions named test** covering shake detection/gating, held piles, editable resolution, drop/paste policies, simulated paste timelines, recording viewport, ink and capture watchdog. No .github workflows were tracked, and the public check-runs endpoint returned zero checks for the reviewed SHA. Tests were **not run**. Pure-policy coverage cannot establish OS permissions, real application compatibility, recovery under process death, signing or recording quality. The README's “fully unit-tested” description should not be mistaken for complete app coverage. [tests][tests]

## Comparison

| Option | Best fit | Tradeoff |
|---|---|---|
| Fairy Cursor | Immediate screenshot-to-destination gestures, contextual notes, lightweight zoom/ink recording | Global permission/settings footprint; heuristic paste acceptance; macOS 26 only |
| Built-in macOS Screenshot and Preview | Conventional captures with explicit file destinations and basic markup | No equivalent carried pile or contextual note workflow; avoids adding this third-party helper |
| OBS Studio | Deliberate capture/compositing/encoding/recording/streaming workflows | More setup and interface complexity; not a screenshot-carrying or sticky-note substitute |

[OBS's public README](https://github.com/obsproject/obs-studio#readme) confirms its capture/compositing/encoding/recording/streaming scope. The Apple support-page retrieval was rate-limited (HTTP 429); the built-in comparison is a general workflow comparison, not a current documentation verification or a hands-on benchmark. No paid service is required for these alternatives.

## Self-Hosting Notes

There is no server to self-host. The documented source build needs macOS 26 and Xcode 26 or its command-line tools; source dependency fetching requires public GitHub access. Release tooling and signing are distinct from runtime. Moving the app to Applications and preserving its signing identity help permissions remain stable; the README warns rebuilds can require regranting them. No installation or privileged permission change was performed for this review.

## Evidence and Limitations

Canonical-source deduplication found no existing review/index entry. Inspected scope: README, license/font notice, package/ignore files, app host and paste router, capability registry, screenshot takeover/saver, notes context/store, recorder/lifecycle/cursor scale, core policies/tests, release script, entitlements and website network code. This was targeted static inspection, not an exhaustive audit of every line or dependency. Public accessibility and metadata were checked without account authentication. No evidence here proves zero telemetry, crash safety, release reproducibility or universal application compatibility.

**Attribution:** Rrrima/fairy-cursor, Rima Cao, MIT; Barlow Project Authors, SIL OFL 1.1. Freehand.swift credits Steve Ruiz's MIT perfect-freehand; verify/preserve upstream notices when redistributing that port. No source code was extracted.

[readme]: https://github.com/Rrrima/fairy-cursor/blob/ac165ff6223a7ee20f0d9558e977327e603fe103/README.md
[screenshots]: https://github.com/Rrrima/fairy-cursor/blob/ac165ff6223a7ee20f0d9558e977327e603fe103/sources/capabilities/screenshots/ScreenshotsCapability.swift
[router]: https://github.com/Rrrima/fairy-cursor/blob/ac165ff6223a7ee20f0d9558e977327e603fe103/sources/app/DropRouter.swift
[paste]: https://github.com/Rrrima/fairy-cursor/blob/ac165ff6223a7ee20f0d9558e977327e603fe103/sources/app/PasteTarget.swift
[policy]: https://github.com/Rrrima/fairy-cursor/blob/ac165ff6223a7ee20f0d9558e977327e603fe103/sources/core/PastePolicy.swift
[notes]: https://github.com/Rrrima/fairy-cursor/blob/ac165ff6223a7ee20f0d9558e977327e603fe103/sources/capabilities/notes/NoteStore.swift
[context]: https://github.com/Rrrima/fairy-cursor/blob/ac165ff6223a7ee20f0d9558e977327e603fe103/sources/capabilities/notes/NoteContext.swift
[recorder]: https://github.com/Rrrima/fairy-cursor/blob/ac165ff6223a7ee20f0d9558e977327e603fe103/sources/capabilities/recording/ScreenRecorder.swift
[cursor]: https://github.com/Rrrima/fairy-cursor/blob/ac165ff6223a7ee20f0d9558e977327e603fe103/sources/capabilities/recording/CursorScale.swift
[package]: https://github.com/Rrrima/fairy-cursor/blob/ac165ff6223a7ee20f0d9558e977327e603fe103/Package.swift
[registry]: https://github.com/Rrrima/fairy-cursor/blob/ac165ff6223a7ee20f0d9558e977327e603fe103/sources/app/CapabilityRegistry.swift
[info]: https://github.com/Rrrima/fairy-cursor/blob/ac165ff6223a7ee20f0d9558e977327e603fe103/resources/Info.plist
[entitlements]: https://github.com/Rrrima/fairy-cursor/blob/ac165ff6223a7ee20f0d9558e977327e603fe103/resources/entitlements.plist
[site]: https://github.com/Rrrima/fairy-cursor/blob/ac165ff6223a7ee20f0d9558e977327e603fe103/site/index.html
[takeover]: https://github.com/Rrrima/fairy-cursor/blob/ac165ff6223a7ee20f0d9558e977327e603fe103/sources/capabilities/screenshots/SystemScreenshotTakeover.swift
[pile]: https://github.com/Rrrima/fairy-cursor/blob/ac165ff6223a7ee20f0d9558e977327e603fe103/sources/core/HeldPile.swift
[app]: https://github.com/Rrrima/fairy-cursor/blob/ac165ff6223a7ee20f0d9558e977327e603fe103/sources/app/AppDelegate.swift
[saver]: https://github.com/Rrrima/fairy-cursor/blob/ac165ff6223a7ee20f0d9558e977327e603fe103/sources/capabilities/screenshots/ScreenshotSaver.swift
[recordcap]: https://github.com/Rrrima/fairy-cursor/blob/ac165ff6223a7ee20f0d9558e977327e603fe103/sources/capabilities/recording/RecordingCapability.swift
[bundle]: https://github.com/Rrrima/fairy-cursor/blob/ac165ff6223a7ee20f0d9558e977327e603fe103/scripts/bundle.sh
[tests]: https://github.com/Rrrima/fairy-cursor/tree/ac165ff6223a7ee20f0d9558e977327e603fe103/tests/core
[release]: https://github.com/Rrrima/fairy-cursor/releases/tag/v0.3.1
