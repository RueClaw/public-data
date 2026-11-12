# Newmarchy (yamz8/newmarchy)

**Repo:** https://github.com/yamz8/newmarchy
**License:** MIT (copyright 2026 yamz8); retain the notice when reusing code. Upstream release prose and desktop/font assets have separate provenance.
**Reviewed:** 2026-11-12 (UTC)
**Revision:** `23dcf122483bc65c622b9e6252d300c817f82d9d` — main and tag v1.6.1; entire plugin implementation, manifest, detector, tests and documentation.
**Verification:** Static implementation review plus all 45 upstream Node tests passing in an offline, cleared-environment Bubblewrap sandbox with read-only source and no host home or desktop access. No installation, live desktop, detector, Try action, or plugin-manager execution.
**Stack:** QML/Qt Quick, Quickshell/Omarchy shell components, JavaScript, Bash, curl, jq and Omarchy/Hyprland commands.
**What it is:** A release-discovery checklist in the Omarchy bar, not an operating-system fork, installer, theme pack, or replacement desktop.

---

## Verdict

⚠️ **Interesting — a focused Omarchy companion, with honest limits on what “seen” means.** The small parser/action split, bounded plain-text rendering and persistent manual overrides are good engineering. Pilot on a compatible Omarchy shell rather than treating the progress icon as evidence that an update is correct or every security change has been reviewed: detection is heuristic, Try actions tick before success, and lifecycle recovery is limited.

## What It Is

Newmarchy reads the installed Omarchy version, fetches public upstream release notes and turns selected topics into checkboxes. A filling circle in the bar tracks progress. Opening a topic shows its details; keyboard controls support navigation, checking, expansion, trying a feature and marking everything seen. The source-notes button retains provenance when the checklist falls back from the stable release to release-candidate notes.

The canonical repository is the public, non-fork GitHub project **yamz8/newmarchy**. Its manifest identifies **yamz8.newmarchy**, version **1.6.1**, as a single-instance bar-widget with entry point **Newmarchy.qml**. Its relationship to [Omarchy](https://github.com/omacom/omarchy) is additive: it consumes Omarchy releases, imports host UI components and invokes host commands. It does not implement Omarchy's installer, package management, compositor, kernel or update machinery. Accordingly, there is no meaningful OS-fork feature comparison or upstream patch delta to claim. [1–3]

## Stack

| Layer | Implementation |
|---|---|
| Host UI | Qt Quick, Quickshell, qs.Commons and qs.Ui; host theme, fonts, panels and IPC |
| Parsing and state logic | Newmarchy.js; bounded release/HTML parsers, IDs, progress and pure state transforms |
| Feature knowledge | Features.js; hand-authored 4.5.0 title-to-command/signal mapping |
| Local detection | Bash plus Omarchy, Hyprland, jq and filesystem existence checks |
| Remote data | Unauthenticated GitHub releases API; narrowly shaped omarchy.org news URLs |
| Persistence | Quickshell FileView JSON with atomicWrites enabled |
| Tests | Node built-ins only: node:test, assert, fs and vm; no npm dependency tree |

## Key Features

### A checklist, not a second release feed

For GitHub Markdown, breaking changes and highlights are counted preferentially; absent these, all parsed items count. For the news-page fixture, 22 checklist entries result after splitting the named apps, with 29 More features, 13 Security and 215 Fixes entries below as read-only collapsed lists. Thus **100% does not mean the security/fix lists were read**. These counts are fixture/test results, not a promise about later live posts. [3,6]

### Explicit commands, not execution of release-note text

Try buttons resolve a release/title against a local static table and execute fixed argument arrays without a shell. Remote descriptions do not supply shell commands. Installed-app signals gate the individual app buttons. This is a useful separation between untrusted prose and executable behavior, although upstream text still influences which locally permitted action appears. The map currently covers stable **4.5.0**, not future releases or direct RC tags. [4]

### Local inference with a durable opt-out

The detector reads language selection, workspace layouts, Quake-console presence, Elsewhen configuration, current theme/background and app directories. It emits allowlisted signal names; there is no network operation in the detector script. Auto-ticked IDs are separately remembered under an auto-tag, so unchecking an automatically detected item survives later detection. Directory existence or a pre-existing non-English configuration is only a proxy for experience, not proof someone tried the new release feature. [3–5]

## Architecture

**Shell startup / panel open → local version and detector processes → release selection → GitHub notes → optional news-page replacement → derived checklist → JSON seen-state.** A local hourly timer rereads version/detection; network refresh is startup/open-driven rather than periodic background polling. Successful GitHub fetches are throttled for ten minutes, while explicit refresh bypasses that throttle. Failed fetches do not receive the same successful-fetch cooldown. Only the latest 30 releases are requested; if the installed version is absent or unrecognized, the newest final release is displayed instead. [2,3]

Newmarchy.js keeps network/filesystem effects outside the parser. It bounds release count, body length, section/item counts and text lengths; news parsing uses a small regex-based article/h2/p/li extraction rather than a browser DOM. It is appropriate for the current upstream page shape but needs fixture refreshes as editorial markup changes. IDs are 32-bit hashes of section/title, stable for unchanged names but not semantic identities or collision-proof identifiers. The changelog explicitly records lost RC-title ticks when the news source changed in 1.4.0; the later heading adjustment deliberately preserves the old hash namespace. [3,7]

## Security, Network and Privacy

- **Good input boundary:** downloaded content is bounded and displayed with Text.PlainText, not rendered as active HTML. URLs passed through Bash fetch wrappers are positional arguments, not interpolated source prose. curl time/connect limits and a 4 MiB transfer/collector cap constrain responses; news parsing further limits its input to 2 MiB. These are useful bounds, not a formal complexity proof. [2,3]
- **Redirect caveat:** initial news URLs match a fixed HTTPS omarchy.org path and that fetch uses --proto =https, but curl follows redirects without a final-host/private-address allowlist. The GitHub fetch also follows redirects and lacks the news fetch's explicit protocol restriction. This is a trusted-upstream/redirect boundary, not an observed exploit or a claim that arbitrary note URLs are accepted. [2,3]
- **No account or telemetry service found:** core requests are unauthenticated public reads with a newmarchy user-agent. The inspected plugin has no credential store, token setup, listening HTTP service or analytics upload path. GitHub/omarchy.org still receive connection metadata; using the notes button opens a normal browser. Launched apps have their own network/privacy behavior, outside this review. [2,4,5]
- **Desktop authority remains broad:** this is executable code inside a user's shell session, not a permission-isolated reader. No sudo, package installation, remote-code download-and-execute or privilege elevation was found in the plugin implementation. That does not sandbox host commands or establish the safety of the external plugin manager. Local IPC delegates transport/access control to the host and exposes panel controls, unseen count and forced refresh. [2]
- **Try is a real effect:** the Jade Horse action switches the current theme; other entries launch apps, open menus, dispatch a workspace or send a notification. The checkbox is saved **before** detached execution, with no exit-status check, confirmation/undo transaction or restoration of the old theme. A checked item can therefore represent a failed launch. [2,4]

## Installation, Updates and Recovery

The documented install is `omarchy plugin add https://github.com/yamz8/newmarchy.git --enable`; documented removal is `omarchy plugin remove yamz8.newmarchy`, followed by optional deletion of its state directory. These are source-documented commands, **not commands run for this review**. The README targets a standard Omarchy 4 installation, but the actual imports and commands require compatible contemporary Omarchy shell APIs. Generic Hyprland, an older Omarchy shell, macOS and Windows are not established supported targets. There is no CPU-specific binary here, but that is not proof of testing on every architecture supported by the host. [1,2]

The plugin supplies no custom installer, updater, package lock, compatibility matrix or rollback command. Installation/update trust is delegated to the host plugin manager and the Git repository; the README install URL is not revision-pinned. For a controlled pilot, record the source SHA, preserve the plugin-manager configuration and current theme selection, and back up the state file before updating. Audit the manager's actual update/remove behavior separately rather than assuming config merge, pinning, signature verification or rollback guarantees.

The plugin's own persistent file is **~/.local/state/newmarchy/seen.json**. FileView requests atomic writes and watches changes, but there is no backup/version journal or explicit write-failure UX; errors are suppressed. The directory is created asynchronously at startup, and no readiness gate around early state writes is visible. Invalid/missing state becomes an empty map. Also, this state path hardcodes HOME rather than honoring XDG_STATE_HOME, even though the detector honors XDG paths for the host data it reads. [2,3,5]

There is no bulk dotfile replacement in the plugin itself. Removing the widget does not undo the theme change or other effects of apps launched with Try. Keep state if progress matters; deleting it resets both manual progress and automatic-detection history. A file backup supports manual recovery of progress, not a transactional desktop rollback. Notes are cached only in memory: a cold offline start has no persisted release catalogue, and a failed news-page fetch is remembered for that URL until shell restart rather than retried by the ordinary refresh path. [1–3]

## Maturity, Licensing and Verification

Public metadata retrieved on 2026-11-12 reports creation on 2026-11-05, last push 2026-11-11T22:57:22Z, **0 stars, 0 forks and 0 open issues**. The queried all-state issue list and GitHub Releases list were empty; tags include v1.6.1 at the reviewed SHA. Changelog 1.6.1 is dated November 12; the commit's UTC timestamp is November 11. This is a roughly week-old project with rapid UI iteration, not a long field history. Counts are a dated snapshot, not quality evidence. [7,8]

The tree contains two test modules with **45 passing tests** covering parsing, text bounds, URL filtering, release fallback, stable IDs, progress round trips, feature mappings and automatic-override behavior. They use repository fixtures and synthetic inputs, requiring no packages, credentials or remote calls. Execution was isolated with networking disabled, a cleared environment, read-only source/system runtime mounts, an empty home and no host desktop/socket access. node:vm is used by upstream tests for compatibility, **not relied on as the security sandbox**. No CI workflow exists in the reviewed tree. No detector integration tests, QML lifecycle tests, desktop accessibility/rendering checks, plugin-manager validation, package audit or live redirect tests were run. [6]

The root MIT text and manifest agree. The repository also includes preview.png and copied upstream release-page/Markdown fixtures; the MIT license should not be taken as independent proof that all third-party prose, screenshot elements, trademarks or font glyph designs are relicensed. The UI uses the host's Nerd Font rather than shipping a font file. This review redistributes neither the preview nor the upstream fixtures. [1,2,6]

## Comparison and Practical Fit

| Option | Strength | Tradeoff |
|---|---|---|
| Newmarchy | Per-release progress in the bar, local detection and curated Try actions | Host-version coupling, heuristic completion and local executable-plugin trust |
| [Official Omarchy news](https://omarchy.org/news/) / [GitHub releases](https://github.com/omacom/omarchy/releases) | Original full context without installing this widget | No per-feature progress or local-use detection |
| A manual local checklist | Explicit personal interpretation and easy archival | Manual maintenance; no integration or automatic detection |

Use it when a small persistent reminder helps explore a compatible Omarchy release. Prefer the original notes for upgrade planning, security review and troubleshooting. Before broader recommendation, validate QML startup/persistence, failed Try behavior, host compatibility and removal/restore on a disposable desktop; add retry/disk-cache behavior and explicit action-result handling. **The design is worth considering, but its progress indicator is a convenience signal, not a compliance or update-health check.**

## Evidence

All implementation links below are pinned to the reviewed revision:

1. [README and lifecycle documentation](https://github.com/yamz8/newmarchy/blob/23dcf122483bc65c622b9e6252d300c817f82d9d/README.md), [manifest](https://github.com/yamz8/newmarchy/blob/23dcf122483bc65c622b9e6252d300c817f82d9d/manifest.json), [MIT license](https://github.com/yamz8/newmarchy/blob/23dcf122483bc65c622b9e6252d300c817f82d9d/LICENSE).
2. [Newmarchy.qml: host integration, fetching, state and actions](https://github.com/yamz8/newmarchy/blob/23dcf122483bc65c622b9e6252d300c817f82d9d/Newmarchy.qml).
3. [Newmarchy.js: parsers, selection and state transforms](https://github.com/yamz8/newmarchy/blob/23dcf122483bc65c622b9e6252d300c817f82d9d/Newmarchy.js).
4. [Features.js: fixed action/signal map](https://github.com/yamz8/newmarchy/blob/23dcf122483bc65c622b9e6252d300c817f82d9d/Features.js).
5. [Read-only local detector](https://github.com/yamz8/newmarchy/blob/23dcf122483bc65c622b9e6252d300c817f82d9d/bin/newmarchy-detect).
6. [Tests and fixtures](https://github.com/yamz8/newmarchy/tree/23dcf122483bc65c622b9e6252d300c817f82d9d/tests).
7. [Changelog](https://github.com/yamz8/newmarchy/blob/23dcf122483bc65c622b9e6252d300c817f82d9d/CHANGELOG.md).
8. [Public repository metadata](https://api.github.com/repos/yamz8/newmarchy), [tags](https://api.github.com/repos/yamz8/newmarchy/tags), [releases](https://api.github.com/repos/yamz8/newmarchy/releases), [issues](https://github.com/yamz8/newmarchy/issues); retrieved 2026-11-12.

---

**Attribution:** yamz8/newmarchy, MIT. Omarchy release material belongs to its respective upstream authors. Independent review; no affiliation implied.
