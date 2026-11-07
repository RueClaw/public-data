# Zlack (sanguneo/zlack)

**Repo:** https://github.com/sanguneo/zlack
**License:** MIT; preserve copyright and permission notices when reusing substantial code. Slack remains a separate proprietary service.
**Reviewed:** 2026-11-07 (UTC)
**Revision:** 2b5e3e25c698f9e84fb4b1393c45b4fda295b4d3 (main, version 1.6.0); repository-wide review focused on src-tauri, preload bridges, manifests, workflows and tests.
**Verification:** Static review plus 33/33 JavaScript unit tests passing in a network-isolated, environment-cleared, read-only-source sandbox using synthetic fixtures. No dependency installation, Rust build/test, app launch, Slack login, native notifications, updater installation or performance benchmark.
**Stack:** Rust, Tauri 2, JavaScript, OS WebView, platform-native notifications.
**What it is:** An independent desktop wrapper around the real Slack web client—not a Slack replacement, messaging server or self-hostable collaboration backend.

## Verdict

⚠️ **Interesting — a focused desktop experiment, not a default enterprise Slack client.** The small native shell and notification/workspace bridge are useful, with real unit-test coverage and deliberately scoped IPC. Authentication compatibility remains unresolved, and the trusted remote-page boundary has an existing-window navigation validation gap. Prefer official Slack or a supported browser for important accounts until those concerns and platform behavior are validated.

## What It Is

Zlack loads app.slack.com into a system WebView and injects a substantial JavaScript compatibility layer. Slack still supplies the UI, accounts, messages, files, permissions and backend. There is no independent message database, server API, tenant provisioning, retention service or offline archive. The project is not affiliated with or endorsed by Slack/Salesforce.

The audience is a desktop user seeking native notifications and workspace switching without packaging an entire Chromium runtime. That packaging choice is verified; lower real-world RAM/CPU use is not. Up to two workspace windows stay warm. Evicted workspaces are not continuously live, so do not assume every workspace continues receiving real-time alerts.

## Stack

| Layer | Technology |
|---|---|
| Native shell | Tauri 2 / Rust, tray, windows, single-instance plugin |
| Remote UI | Slack web client; injected JavaScript and DOM/network observation |
| Rendering | Windows WebView2, macOS WebKit, Linux WebKitGTK |
| Notifications | notify-rust 4.11.7, Windows WinRT, macOS Objective-C bridge |
| Local state | WebView session/storage, localStorage workspace metadata, window-state config, Downloads |
| Updating | Tauri updater, GitHub Releases metadata, embedded signature public key |

Evidence: [Cargo manifest](https://github.com/sanguneo/zlack/blob/2b5e3e25c698f9e84fb4b1393c45b4fda295b4d3/src-tauri/Cargo.toml), [entry point](https://github.com/sanguneo/zlack/blob/2b5e3e25c698f9e84fb4b1393c45b4fda295b4d3/src-tauri/src/main.rs), [preload](https://github.com/sanguneo/zlack/blob/2b5e3e25c698f9e84fb4b1393c45b4fda295b4d3/src-tauri/preload.js).

## Key Features

### Native notification routing

The preload replaces Notification and notification-permission behavior, disables service-worker registration, and intercepts fetch/XHR/sendBeacon telemetry to associate notifications with team/channel IDs. The native layer shows titles/bodies through the OS notification service and routes activation to the originating window, with a Slack URL fallback. Ten-minute JavaScript and Rust activation retention is **not** a promise to purge OS notification history or Slack messages. Slack-internal telemetry formats are compatibility liabilities despite thoughtful reconciliation tests. [Bridge](https://github.com/sanguneo/zlack/blob/2b5e3e25c698f9e84fb4b1393c45b4fda295b4d3/src-tauri/notification-bridge.cjs), [native registry](https://github.com/sanguneo/zlack/blob/2b5e3e25c698f9e84fb4b1393c45b4fda295b4d3/src-tauri/src/native_notifications.rs), [activation](https://github.com/sanguneo/zlack/blob/2b5e3e25c698f9e84fb4b1393c45b4fda295b4d3/src-tauri/src/notifications.rs).

### Workspace and unread integration

A mutex-protected Rust registry tracks window/team mappings, LRU order, metadata and aggregate badges. MAX_LOADED_WORKSPACES is two. Preload observes Slack state, caches workspace names/domains locally, and remembers request headers/body for counts polling in page memory. Authentication remains Slack's responsibility. [Registry](https://github.com/sanguneo/zlack/blob/2b5e3e25c698f9e84fb4b1393c45b4fda295b4d3/src-tauri/src/main.rs#L87-L146), [request replay](https://github.com/sanguneo/zlack/blob/2b5e3e25c698f9e84fb4b1393c45b4fda295b4d3/src-tauri/preload.js#L397-L433).

### Authenticated downloads

File/image requests run inside the logged-in page with credentials included, then send base64 bytes through IPC to Rust. Native saves use the OS Downloads directory, sanitized stems/extensions and 64 MiB image / 256 MiB general-file limits. Base64 and full-buffer copies can be expensive. Native save commands do not themselves require a user gesture or Save dialog: a compromised allowed page could issue repeated writes. General-file extensions may be executable, but this code does not automatically execute the saved file. [Downloads](https://github.com/sanguneo/zlack/blob/2b5e3e25c698f9e84fb4b1393c45b4fda295b4d3/src-tauri/src/downloads.rs), [fetch bridge](https://github.com/sanguneo/zlack/blob/2b5e3e25c698f9e84fb4b1393c45b4fda295b4d3/src-tauri/preload.js#L1449-L1475).

## Architecture and Security

### Authentication and tenant boundaries

Slack web sessions/cookies handle login and service authorization; Zlack has no separate password system or server-side authorization. Workspace windows are UI separation, not strong tenant compartments: they use shared application state, no explicit per-workspace WebView data directory, and commands accept team identifiers supplied by the page. workspace_status exposes aggregate workspace metadata. update_notification_context mutates a global ID-keyed registry without checking the caller's originating window. These are local cross-workspace trust concerns, not evidence of bypassing Slack's server-side access controls.

Public [issue #13](https://github.com/sanguneo/zlack/issues/13) reports Google login blocked in embedded WebViews. [PR #14](https://github.com/sanguneo/zlack/pull/14) proposes browser/deep-link login, but was open at review time and is not in this SHA. [PR #7](https://github.com/sanguneo/zlack/pull/7) separately addresses Linux slack: sign-in handoff recovery. These are upstream reports/proposals, not independently tested fixes or proof every login fails. Validate the actual identity-provider flow before adoption; do not infer huddle/screen-sharing support from a working chat page.

### Native IPC: useful restrictions, incomplete defense

Static capabilities permit only the slack-ipc command set on HTTPS app.slack.com/slack.com in main/workspace-* windows. Additional workspace-host capabilities are created for a particular window after Slack-domain URL parsing. No general shell permission is exposed. New-window URLs must be credential-free HTTPS under slack.com. External opening accepts credential-free HTTP(S), rejecting file/custom protocols, but does not exclude private-network hosts or unusual ports; this opens the user's browser, not a native HTTP proxy. [Capability](https://github.com/sanguneo/zlack/blob/2b5e3e25c698f9e84fb4b1393c45b4fda295b4d3/src-tauri/capabilities/slack.json), [permissions](https://github.com/sanguneo/zlack/blob/2b5e3e25c698f9e84fb4b1393c45b4fda295b4d3/src-tauri/permissions/slack.toml), [URL validation](https://github.com/sanguneo/zlack/blob/2b5e3e25c698f9e84fb4b1393c45b4fda295b4d3/src-tauri/src/security.rs).

**Important static finding:** switch_workspace accepts an optional URL. Creating a new window validates it, but ensure_workspace_window skips creation/validation when that team already has a live window. switch_to_workspace then supplies the URL to an evaluated script, attempts the Slack router and otherwise assigns window.location.href. A non-Slack URL can therefore reach that fallback for an existing window. No native on_navigation allowlist is installed in the reviewed main.rs. A compromised IPC-authorized page could navigate another existing workspace window; javascript: evaluation risk should also be explicitly regression-tested and blocked rather than assumed safe. This is a code-path finding, not a demonstrated live exploit, and requires control of an authorized page/IPC caller—not merely posting a normal Slack message. Fix by parsing URLs at the command boundary on every call and applying native navigation policy. [Creation/lookup](https://github.com/sanguneo/zlack/blob/2b5e3e25c698f9e84fb4b1393c45b4fda295b4d3/src-tauri/src/main.rs#L358-L428), [navigation sink](https://github.com/sanguneo/zlack/blob/2b5e3e25c698f9e84fb4b1393c45b4fda295b4d3/src-tauri/src/main.rs#L477-L537), [command](https://github.com/sanguneo/zlack/blob/2b5e3e25c698f9e84fb4b1393c45b4fda295b4d3/src-tauri/src/main.rs#L742-L748).

Application csp is null; that does not prove Slack's remote response CSP is absent. Injected page interception is a compatibility mechanism, not a security boundary. Executable-adjacent CSS is read and delivered to the page; use trusted CSS only. A sibling fixed WebView2 runtime is executable code and shifts runtime-update responsibility to the operator. [Config](https://github.com/sanguneo/zlack/blob/2b5e3e25c698f9e84fb4b1393c45b4fda295b4d3/src-tauri/tauri.conf.json), [platform handling](https://github.com/sanguneo/zlack/blob/2b5e3e25c698f9e84fb4b1393c45b4fda295b4d3/src-tauri/src/platform.rs).

### Message/file privacy and retention

There is no independent privacy layer or end-to-end encryption implementation. Slack and any identity provider remain network trust dependencies. Zlack observes page requests/responses for unread/workspace/notification behavior; the OS receives notification titles and message bodies. Session data, localStorage workspace metadata, clipboard image copies and attachments are separate persistence surfaces. No application-wide secure erase, configurable retention, profile encryption or account-removal cleanup mechanism was found in the inspected implementation. Signing out must not be assumed to remove Downloads or notification history.

Filename sanitization prevents ordinary path components from choosing arbitrary destinations, but unique_path checks existence separately from std::fs::write and falls back to the original filename after 9,999 collisions. Overwrite avoidance is best-effort, not atomic: concurrent saves or name exhaustion can overwrite. Prefer atomic create_new-style allocation and failure instead of fallback. This edge case and filesystem symlink races were not dynamically exercised. [Filename selection](https://github.com/sanguneo/zlack/blob/2b5e3e25c698f9e84fb4b1393c45b4fda295b4d3/src-tauri/src/downloads.rs#L248-L266).

## Self-Hosting Notes

There is no server to self-host. Desktop packages exist for Windows, macOS and Linux; source builds require Node, Rust and platform Tauri/WebView prerequisites. The configured macOS minimum is not a guarantee Slack's current web client supports that OS/WebKit. Keep the system WebView patched; a fixed Windows runtime needs its own updates.

Startup does a DNS reachability check and can show a local retry page polling Slack every five seconds. That is connection recovery, not offline messaging. Window close normally hides the app; the tray offers quit/restore. Maximized state is explicitly persisted in a small window-state file. Keep a known-good installer and normal supported Slack access as fallback; no in-app rollback or message backup/restore subsystem was found. [Fallback](https://github.com/sanguneo/zlack/blob/2b5e3e25c698f9e84fb4b1393c45b4fda295b4d3/src/index.html), [lifecycle](https://github.com/sanguneo/zlack/blob/2b5e3e25c698f9e84fb4b1393c45b4fda295b4d3/src-tauri/src/main.rs).

The updater checks GitHub Releases on startup and asks before download/install/restart. An embedded public key and release signing configuration are positive, but updater signing does not prove platform code signing/notarization, reproducible builds or successful end-to-end updates. Documentation warns that losing the signing key breaks existing clients' trust in replacement-key updates. [Updater](https://github.com/sanguneo/zlack/blob/2b5e3e25c698f9e84fb4b1393c45b4fda295b4d3/src-tauri/src/main.rs#L827-L848), [operations](https://github.com/sanguneo/zlack/blob/2b5e3e25c698f9e84fb4b1393c45b4fda295b4d3/docs/auto-update.md).

## Maturity, Dependencies and Verification

Public metadata on 2026-11-07: 63 stars, 11 forks, three open issues/PRs combined; created 2026-01-06, last push 2026-10-27. [v1.6.0](https://github.com/sanguneo/zlack/releases/tag/v1.6.0) was published 2026-10-26 UTC and targets this SHA. Popularity is not assurance. [Metadata](https://api.github.com/repos/sanguneo/zlack).

npm and Cargo lockfiles are present. npm has only the Tauri CLI as a direct dev dependency; the native/runtime supply chain is much larger. CI compiles on Ubuntu, Windows and macOS and runs clippy without warnings-as-errors; it does **not** run cargo test or JavaScript suites. Actions use moving version tags; releases download an executable AppImage helper and a GTK plugin from a moving master URL without an explicit digest check. Pin immutable revisions/digests and add test gates. No vulnerability scan, SBOM, binary signature verification or reproducibility comparison was performed. [CI](https://github.com/sanguneo/zlack/blob/2b5e3e25c698f9e84fb4b1393c45b4fda295b4d3/.github/workflows/ci.yml), [release](https://github.com/sanguneo/zlack/blob/2b5e3e25c698f9e84fb4b1393c45b4fda295b4d3/.github/workflows/release.yml).

Executed Node 24.22.1 tests/download-names.test.cjs, tests/notification-bridge.test.cjs, tests/slack-navigation.test.cjs and src-tauri/context-menu-bridge.test.cjs: **33 passed; zero failed/skipped**. Bubblewrap cleared environment variables, exposed runtime files/read-only source, used an ephemeral home and disabled networking. Synthetic tests cover notification ordering/activation, filename resolution, context-menu handling and routing—not Slack itself. Rust security/download/activation tests were inspected but not run. No accounts, application service connections, executable releases, native UI or updates were exercised. Performance, SSO, huddles, cookies at rest and platform behavior remain unverified.

## Comparison

| Option | When it fits | Main tradeoff |
|---|---|---|
| Zlack | Personal experiments with a lighter wrapper and custom CSS | Unofficial bridge maintenance and IPC trust surface |
| Official Slack desktop | Important Slack work and vendor-supported desktop behavior | Bundled runtime and vendor support policy |
| Slack in a supported browser | Least extra client code; normal browser profiles and updates | Less Zlack-specific tray/workspace integration |
| Zulip or Mattermost | Hosting a collaboration backend | Different product and migration/operations project, not a drop-in client |

[Slack's supported systems/browsers](https://slack.com/help/articles/115002037526-System-requirements-for-using-Slack) distinguish huddle browser support; a spoofed Chrome user agent does not turn WebKit into Chrome. [Zulip](https://github.com/zulip/zulip) and [Mattermost](https://github.com/mattermost/mattermost) are category alternatives, not audited deployments in this review.

**Practical gate:** fix the existing-window URL boundary; scope native mutable state by originating window where appropriate; add tests to CI; validate real SSO and notification/download behavior on each platform. Until then, study or cautiously pilot rather than standardize on it.

---

**Attribution:** sanguneo/zlack, MIT, copyright 2026 sanguneo. This review paraphrases public behavior; no upstream implementation is redistributed.
