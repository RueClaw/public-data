# Skykeep (YashwanthKamireddi/Skykeep)

**Repo:** https://github.com/YashwanthKamireddi/Skykeep
**License:** GPL-3.0-only in workspace metadata, with GPL v3 LICENSE; dependency and media-codec terms remain separate. Distribution of derivatives requires GPL compliance, not permissive copying.
**Reviewed:** 2026-11-14 (UTC)
**Revision:** `b0570a64e1d2eea963b0fde610bcc074ff746eef`, main, source version 0.1.24. Scope: root documentation/manifests, Rust auth/core/sync and selected desktop boundaries, Android architecture, packaging and CI.
**Verification:** Static review only. No source execution, builds, installs, accounts, device access or live iCloud probes. Public GitHub metadata and two completed platform checks inspected; no independent test-pass or performance claim.
**Stack:** Rust, SQLite/WAL/FTS5, Tauri 2, React 18/TypeScript/Vite, ProseMirror; Kotlin/Compose and UniFFI on Android.
**What it is:** An independent iCloud client for Notes, Reminders, Calendar, Contacts, Drive and Photos on Linux, Windows and Android—not a generic cloud-storage server or bookmark manager.

## Verdict

⚠️ **Interesting — unusually thoughtful local-first engineering, but pilot before trusting a primary iCloud library.** The durable outbox, account ownership checks, network-client separation and explicit local-file grants are substantial implementation, not merely README promises. However, this young client has broad account authority, retains an Apple password for reauthentication, stores readable local content, and depends on unofficial Apple web protocols. Keep independent backups and verify round trips on disposable content before routine editing.

## What It Is

Skykeep gives non-Apple devices native shells around a shared Rust synchronization engine. Desktop screens read a local SQLite library; background workers talk to Apple's services. Android combines dedicated screens with system Contacts/Calendar providers and a Drive DocumentsProvider. Internal `quince-*` names are the project's earlier working name, not a separate upstream product. [README](https://github.com/YashwanthKamireddi/Skykeep/blob/b0570a64e1d2eea963b0fde610bcc074ff746eef/README.md), [architecture](https://github.com/YashwanthKamireddi/Skykeep/blob/b0570a64e1d2eea963b0fde610bcc074ff746eef/ARCHITECTURE.md).

This is not self-hosted iCloud: there is no replacement Apple backend to deploy. Apple remains the service and trust dependency. Optional CalDAV/Nextcloud calendars coexist with iCloud, rather than moving Notes or Photos to an independent server.

## Stack

| Layer | Implementation |
|---|---|
| Local data | SQLite with WAL readers, migrations, FTS5 and persistent outbox |
| Protocols | reqwest/rustls, Apple SRP/2FA, CloudKit and web-service adapters, CalDAV |
| Desktop | Tauri command boundary, React/TypeScript, ProseMirror notes editor |
| Mobile | Kotlin Compose, UniFFI Rust bridge, Android providers and WorkManager |
| Files/media | Linux FUSE, Windows Cloud Files, HEIC/GStreamer/native codecs |

## Key Features and Architecture

### Durable writes rather than optimistic UI alone

Notes, Reminders, Contacts, Calendar and Photos flags combine local changes and queue insertion transactionally. A worker drains per service, preserves ordering on transient failure, and retains refused edits for Retry/Discard. The inspected `drain_as` path checks account ownership before taking each change, and serializes sending with the service's sync pass. Protocol/conflict errors become refusals after five attempts; network/reauthentication failures remain retryable. This is a good practical design for intermittent connections. [queue.rs](https://github.com/YashwanthKamireddi/Skykeep/blob/b0570a64e1d2eea963b0fde610bcc074ff746eef/crates/quince-sync/src/queue.rs), [outbox.rs](https://github.com/YashwanthKamireddi/Skykeep/blob/b0570a64e1d2eea963b0fde610bcc074ff746eef/crates/quince-core/src/outbox.rs).

Do not generalize this to every operation: Drive rename/move/delete and some Photos metadata are direct network writes; mounted-file writes have their own disk journal. Offline browsing is not proof that every edit works offline. Notes' CRDT and merge logic are interesting, but “nothing is lost” and universal idempotence are guarantees requiring much broader fault testing than this review performed. [architecture writing section](https://github.com/YashwanthKamireddi/Skykeep/blob/b0570a64e1d2eea963b0fde610bcc074ff746eef/ARCHITECTURE.md#writing).

### Account separation is meaningful, but not tenant security

The library records a SHA-256-derived account tag. Switching accounts sets whole libraries aside, including caches and unsent changes; sync passes and queue drains validate ownership. That reduces accidental cross-account synchronization. It is a single-user native application, not a hosted multi-tenant service with RBAC. All authorized application windows and the native process remain powerful, and a hash of an account identifier is not encryption. [main.rs, claim_library](https://github.com/YashwanthKamireddi/Skykeep/blob/b0570a64e1d2eea963b0fde610bcc074ff746eef/src-tauri/src/main.rs#L1464), [queue ownership](https://github.com/YashwanthKamireddi/Skykeep/blob/b0570a64e1d2eea963b0fde610bcc074ff746eef/crates/quince-sync/src/queue.rs).

### Network policy and local authority

Four client builders separate Apple services, public calendar subscriptions, explicitly added CalDAV accounts and GitHub release updates. Apple requests require permitted domain suffixes and TLS; loopback is a test/feature exception, not the normal shipping allowance. Regional Apple domains are enabled for regional accounts. Public subscription resolution filters private/reserved addresses; account clients deliberately permit user-selected private servers. Environment proxies are supported, so these controls should not be described as an OS firewall or an independently verified guarantee about every proxy-resolved destination. [auth client builders](https://github.com/YashwanthKamireddi/Skykeep/blob/b0570a64e1d2eea963b0fde610bcc074ff746eef/crates/quince-auth/src/lib.rs#L2080), [release client](https://github.com/YashwanthKamireddi/Skykeep/blob/b0570a64e1d2eea963b0fde610bcc074ff746eef/crates/quince-auth/src/releases.rs).

The bundled desktop page's CSP blocks general network connections and grants only narrow Tauri plugin permissions. Custom application commands still carry substantial library/account authority. For filesystem access, `grants.rs` canonicalizes paths, expires grants after ten minutes and consumes save grants once; directory read grants include descendants. This protects against a renderer inventing arbitrary file paths, but is not a sandbox against compromised native code or another process running as the user. [CSP](https://github.com/YashwanthKamireddi/Skykeep/blob/b0570a64e1d2eea963b0fde610bcc074ff746eef/src-tauri/tauri.conf.json), [capability](https://github.com/YashwanthKamireddi/Skykeep/blob/b0570a64e1d2eea963b0fde610bcc074ff746eef/src-tauri/capabilities/default.json), [file grants](https://github.com/YashwanthKamireddi/Skykeep/blob/b0570a64e1d2eea963b0fde610bcc074ff746eef/src-tauri/src/grants.rs).

Video playback uses a loopback HTTP server with a fresh UUID secret, exact Host validation and rejection of non-app Origins, without CORS grants. Those are useful browser/DNS-rebinding defenses, not protection from a same-user attacker able to inspect the application's memory or files. [video gate](https://github.com/YashwanthKamireddi/Skykeep/blob/b0570a64e1d2eea963b0fde610bcc074ff746eef/src-tauri/src/video.rs#L156).

## Credentials, Privacy and Data Flows

SRP avoids transmitting the raw Apple password as the login proof; it does **not** mean Skykeep never receives or retains that password. The documented design keeps password plus session in the OS keyring for automatic reauthentication. Cookies are AES-256-GCM sealed with a separate keyring key. The local library, opened files and image caches are not encrypted by Skykeep; full-disk encryption and a trustworthy logged-in session matter. The security document explicitly acknowledges same-user keyring access. [credential/session policy](https://github.com/YashwanthKamireddi/Skykeep/blob/b0570a64e1d2eea963b0fde610bcc074ff746eef/SECURITY.md), [sealed cookies](https://github.com/YashwanthKamireddi/Skykeep/blob/b0570a64e1d2eea963b0fde610bcc074ff746eef/crates/quince-auth/src/sealed.rs).

Content normally goes device ↔ Apple. A user-added calendar server receives its own calendar data/credentials; subscription hosts receive fetches; update-capable packages contact GitHub. Browser-opened links and Android system-provider integration create additional user-selected trust boundaries. No model provider or AI inference is needed, and no Skykeep telemetry backend was identified in the inspected architecture. Do not translate that into “no network requests” or a universal anonymity claim.

Advanced Data Protection still requires enabling Apple's web-data access and approving a temporary session from a trusted device. The local readable copy remains after the approval expires; queued protected-service edits wait for renewed approval. This is a conscious expansion of endpoint access, not a bypass of ADP or access to iCloud Keychain/Health. [ADP policy](https://github.com/YashwanthKamireddi/Skykeep/blob/b0570a64e1d2eea963b0fde610bcc074ff746eef/SECURITY.md#advanced-data-protection).

Costs are ordinary iCloud storage, bandwidth, local disk and optional CalDAV hosting—not token fees. Backing up a large photo library can consume substantial bandwidth and disk; no spend cap or storage quota should be inferred.

## Persistence, Retention, Export and Recovery

- **Local continuity:** SQLite/WAL and durable queued writes survive restart. Corruption recovery sets the damaged database aside and attempts salvage, including outbox records, rather than overwriting the evidence. Salvage is best effort, not guaranteed recovery of every unsent edit. [library recovery](https://github.com/YashwanthKamireddi/Skykeep/blob/b0570a64e1d2eea963b0fde610bcc074ff746eef/crates/quince-core/src/lib.rs#L187).
- **Sign-out is a policy choice:** users can keep the library; otherwise the code removes library files, sidecars/corrupt copies and caches. Deferred keyring cleanup handles an unavailable keyring. Other account archives, user-created exports, downloaded files and backups need their own retention decisions. File deletion does not prove forensic erasure from SSDs, snapshots or external backup media. [sign-out](https://github.com/YashwanthKamireddi/Skykeep/blob/b0570a64e1d2eea963b0fde610bcc074ff746eef/src-tauri/src/main.rs#L2024), [security retention policy](https://github.com/YashwanthKamireddi/Skykeep/blob/b0570a64e1d2eea963b0fde610bcc074ff746eef/SECURITY.md).
- **Export is local, not a complete cloud backup:** Markdown, iCalendar, vCard and CSV plus cached media are written through a partial-directory/rename scheme. Unopened photos and undownloaded Drive content are listed instead of fetched. A successful export can therefore omit original bytes. [export implementation](https://github.com/YashwanthKamireddi/Skykeep/blob/b0570a64e1d2eea963b0fde610bcc074ff746eef/src-tauri/src/export.rs#L1).
- **Backup is a separate feature:** Photos originals and Drive files are copied to a chosen destination; changed Drive files keep earlier versions and cloud deletion is not mirrored as backup deletion. That is valuable protection from accidental cloud removal, but intentionally retains deleted personal data and grows storage. It is not a one-click restore of the entire iCloud account or all six applications. Recently Deleted items are not copied. [backup implementation](https://github.com/YashwanthKamireddi/Skykeep/blob/b0570a64e1d2eea963b0fde610bcc074ff746eef/src-tauri/src/backup.rs).

Before adoption, test interruption/retry, simultaneous-device note edits, account switching with pending writes, deleting/recovering a disposable record, disk-full behavior and restoring a sampled export/backup. Keep at least one independent offline copy; synchronization alone is not backup.

## Maturity, Build and Update Risks

Public GitHub metadata retrieved on the review date showed creation on 2026-10-20, last push 2026-11-14, 391 stars, 23 forks and two open issues/PRs combined. These are activity signals, not reliability evidence. Source manifests say 0.1.24; the latest published release endpoint returned **v0.1.23**, published 2026-11-12. Do not assume a downloaded release contains every reviewed source fix. [metadata](https://api.github.com/repos/YashwanthKamireddi/Skykeep), [releases](https://github.com/YashwanthKamireddi/Skykeep/releases).

CI defines formatting, clippy, Rust tests, cargo-deny advisory/license checks, Android builds/tests and frontend model/browser smoke checks. Lockfiles exist and sampled GitHub Actions references are commit-pinned. Linux checks [43626915224](https://github.com/YashwanthKamireddi/Skykeep/actions/runs/43626915224) and Windows checks [43626914882](https://github.com/YashwanthKamireddi/Skykeep/actions/runs/43626914882) reported success at the reviewed SHA. This review did not inspect every job/log, rerun the claimed 1,300+ tests, validate every distributed package, or measure the advertised sub-0.1%-CPU idle figure. [CI definition](https://github.com/YashwanthKamireddi/Skykeep/blob/b0570a64e1d2eea963b0fde610bcc074ff746eef/.github/workflows/ci.yml).

The build spans Rust/npm, GTK/WebKit, platform APIs, codecs, and Android Gradle/NDK. Native parsers and OS integrations enlarge the maintenance surface. There is no evidence here that a lockfile or cargo-deny makes the full dependency graph vulnerability-free. Package channels also differ: .deb/.rpm updates are manual, while installer/AppImage builds have a GitHub updater. The config requires signed versions and a pinned update verification key; store distribution has separate trust/update paths. Signing authenticates a release, not its behavior or reproducible correspondence to source. [manifest](https://github.com/YashwanthKamireddi/Skykeep/blob/b0570a64e1d2eea963b0fde610bcc074ff746eef/Cargo.toml), [desktop dependencies](https://github.com/YashwanthKamireddi/Skykeep/blob/b0570a64e1d2eea963b0fde610bcc074ff746eef/src-tauri/Cargo.toml), [updater](https://github.com/YashwanthKamireddi/Skykeep/blob/b0570a64e1d2eea963b0fde610bcc074ff746eef/src-tauri/src/updates.rs).

## Comparison

| Need | Prefer / consider | Tradeoff |
|---|---|---|
| Official occasional access | Apple's iCloud web UI | Less local/offline integration, but no additional third-party native password holder |
| Windows Drive/Photos integration | Apple's iCloud for Windows | Official client; not the same six-app Notes/Reminders experience |
| Photo archival automation | [icloudpd](https://github.com/icloud-photos-downloader/icloud_photos_downloader) | Narrower purpose; still tied to Apple's unofficial interfaces |
| Independent calendar service | Nextcloud/CalDAV with established clients | Self-hostable calendar infrastructure, not a replacement for Apple Notes/Photos compatibility |
| Six-service Linux desktop workflow | Skykeep pilot | Cohesive local-first experience with broader native/account trust and young protocol support |

These are fit comparisons, not fresh security audits of the alternatives.

## Self-Hosting Notes

There is no Skykeep server to host. Evaluate an official package on a supported platform only after reviewing its permissions and release provenance. Linux needs functioning secret storage and native media/filesystem libraries; Android exposes synchronized data through platform permissions. Avoid live probe examples for routine verification: they are integration tools, not evidence that static review was exercised safely. Maintain independent backups and plan for Apple protocol changes or session expiry.

## Verification Limits

The reviewed implementation supports the core architecture and several concrete security controls. It does not establish end-to-end protocol compatibility, complete command-grant coverage, race-free account switching, full restore fidelity, performance, binary provenance or freedom from vulnerabilities. No Apple login, paid call, source build, device interaction or executable test was performed. No GPL source was extracted into reusable components.

**Attribution:** Yashwanth Kamireddi and contributors, [YashwanthKamireddi/Skykeep](https://github.com/YashwanthKamireddi/Skykeep), GPL-3.0-only workspace declaration; third-party terms separate.
