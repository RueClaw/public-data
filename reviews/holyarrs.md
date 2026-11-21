# HolyArrs (HolyArrs/HolyArrs)

**Repo:** https://github.com/HolyArrs/HolyArrs
**License:** AGPL-3.0-only (package and image declarations; root AGPL v3 text). Network copyleft and distribution obligations apply; commercial licensing is offered separately.
**Reviewed:** 2026-11-21 (UTC)
**Revision:** 4b0349ea890d01e26668466cbfdbb7cc22f80eaf (main); targeted scope: app/, deploy/, docs/, .github/, root manifests/license.
**Verification:** Static source review only; no application tests, builds, installation, live-service probes or media downloads. Review-artifact checks are separate from product validation.
**Stack:** Go 1.27.4, Svelte 5 / SvelteKit 3 / TypeScript, modernc SQLite, embedded static UI, scratch Docker image.
**What it is:** A consolidated media-request and library-automation application, not a downloader or a playback server. It targets home-server operators who want one interface instead of several Arr applications.

---

## Verdict

⚠️ **Interesting — pilot with disposable media before replacing a working stack.** The modular single-process design, encrypted integration secrets and explicit recovery machinery are substantial. However, this very young public repository has important documentation-versus-code discrepancies around backup-off rollback and plugin network confinement, plus a default hosted metadata dependency. Keep existing automation and independently backed-up media until import, permission and recovery behavior are proven.

## What It Is

HolyArrs combines requests, movie/show/music management, release scoring, indexer searches, downloader orchestration, import/rename workflows, subtitles, notifications and media-server refreshes. External qBittorrent/SABnzbd-style downloaders and Plex/Jellyfin/Emby-style playback servers remain separate. Its “six apps become one” pitch is about the automation/control plane, not every component of a media server. README size/RAM comparisons are upstream measurements, not reproduced benchmarks. [1]

Imports can read existing Arr services or backup archives. The documented migration scope excludes custom formats, tags and history; do not assume lossless replacement. Read-only migration from another app does not mean HolyArrs is read-only afterward: normal automation writes media and download folders. Use only content and sources you are entitled to access. [1]

## Stack

| Layer | Tech |
|---|---|
| Server | Go standard-library HTTP, domain modules, background jobs |
| Frontend | Svelte/SvelteKit static build embedded in the Go executable |
| Storage | Main and events SQLite databases via modernc.org/sqlite |
| Authentication | Local Argon2id passwords, sessions, API keys; optional external sign-in |
| Integration | Torznab/Newznab sources, download clients, media servers, alerts, metadata service |
| Distribution | Multi-stage Docker build to scratch; portable/native/NAS packaging also present |

## Key Features

### One pipeline, fewer integration seams

The request → approval → source search → release scoring → download → import → media-server notification path is wired in one program. Module layering, module-owned SQL and injected interfaces are documented and have dedicated structure-check code. Shared jobs, events, secrets and outbound networking reduce repeated plumbing. This simplifies operations but concentrates failure and compromise impact into one process. [2]

### Security mechanisms are real, not just a README checkbox

Password hashing uses Argon2id with 19 MiB, two passes and one lane. Default minimum password length is eight bytes, but owners can lower it to four: leave it stronger. Session cookies are HttpOnly/SameSite=Lax; Secure follows direct TLS or a trusted HTTPS proxy. Browser mutations check origin/host and CSRF tokens; API credentials use a distinct path. Optional LAN sign-in skipping exists and is off unless configured. These are positive implementation signals, not proof against all authentication bypasses. [3]

Integration secrets use AES-256-GCM with random nonces and record-bound associated data. The 32-byte master key is generated in a mode-0600 file separate from the database, with optional external key-file configuration. This protects a database-only leak, not theft of the whole config volume or compromise of the running process. Library/history databases themselves are not thereby encrypted. [4]

### Recovery is useful, but one advertised guarantee is contradicted

Scheduled/manual backups and versioned pre-update copies are implemented. Restore checks database/key compatibility, stages work for restart and preserves displaced databases. **Do not rely on the docs saying pre-update backups survive with backups Off:** the implementation removes pre-update database copies made and successfully checked during that startup when the preset is Off. The explicit `TestOffMakesNoBackupOnUpdate` expects no retained backup, while `TestOffKeepsACopyNotCheckedThisStart` preserves an unchecked leftover. This directly contradicts the backup/update guides, which promise pre-update retention even when Off. Keep an independent manual pre-update backup and the matching key; do not infer downgrade safety from a successful migration. [5, 6]

## Architecture

The executable entry/wiring lives in `app/backend/cmd/holyarrs`; `app/backend/internal` contains accounts, requests, movies, shows, music, sources, downloads, mediafiles, importer, metadata, backups and other modules. Core packages supply database migrations, jobs, filesystem helpers, web routing, secrets and outbound calls. Two SQLite files separate primary state from trimmable event history. The frontend is built separately then embedded; there is no Node service in the final container. [2, 7]

Outbound dialing checks resolved addresses, including cloud-metadata and special-address ranges. Public-only and LAN-capable policies differ deliberately because local download/media servers are normal integrations. This is useful SSRF defense, but configured integrations still confer intentional network authority. Treat administrator-controlled endpoints, proxy rules and API keys as privileged settings. [8]

MCP/AI-app connectivity is feature-gated by `ai_apps` in the reviewed code. Do not describe a held-back integration as a default installed agent, or assume that “connect apps” means permission-free access. [9]

## Deployment Authority, Authentication and Exposure

- The documented Compose example publishes port 6262 without a host-address restriction, normally exposing it on host interfaces. Initial owner creation has no setup code; the first accepted setup request wins. Initialize on a restricted network before allowing other clients. Origin/host checks are not an out-of-band ownership proof. [1, 3]
- The scratch image has no shell, but starts as root for config ownership handling and then switches to PUID/PGID (default 1000:1000). A fixed container user can avoid that startup privilege. No privileged mode or Docker socket is requested in the standard example. Media/download mounts are writable and give file-changing authority; a shell-free image does not make that authority harmless. [7]
- Keep it behind a VPN or HTTPS reverse proxy, explicitly configure trusted proxies/allowed hosts, and avoid direct router port-forwarding. Plain HTTP does not protect passwords or cookies in transit. Prefer narrow mounts and a read-only root filesystem with required writable paths. [1, 3]
- Proxmox scripts are a separate high-authority installation path: they create containers, install packages, fetch release artifacts and manage systemd. Review those scripts independently rather than treating the container quick start as proof of their safety. No installer was executed here. [10]
- **Plugin confinement is overstated in the manual.** It says plugins reach only listed websites. The Linux sandbox source explicitly says “no network allowlist”; filesystem Landlock restrictions and no-new-privileges do not enforce destination allowlists. CPU/memory/process caps require usable delegated cgroups. Signed plugins remain trusted code, not fully network-confined code. Documentation currently says no plugins are available, so this is a framework/documentation boundary finding, not a demonstrated malicious-plugin exploit. [11]

## Data Privacy

Default metadata lookups use `https://api.holyarrs.com` and register an installation credential. Requests carry an install token and lookup information; documentation enumerates search terms, media IDs, language/region and the public IP. “Count this install” is on unless disabled; opting out signals the server through a header, rather than hiding the IP or eliminating lookups. The server can therefore correlate requests with an installation. Its logging/retention practices were not independently audited. [12]

“Your own keys” and “Off” metadata modes are important escape hatches, with feature tradeoffs. **Setting only a TMDB key does not disconnect the HolyArrs service:** music, extra metadata and other lookups may still use it. The outside-address documentation also lists browser-side images/video, optional provider sign-ins, watchlists, alerts and update checks. Browser egress is not stopped by a server-only firewall. Automatic trailers and country counting deserve explicit opt-in decisions. [12]

Stored requests, user records, library paths/history, downloaded backup zips and logs are sensitive household data. Secret masking is not whole-record anonymization. Backups exclude media, artwork, logs and the master key; use separate encrypted off-host storage and a separately protected key kit. Removing a container does not erase any of those retained copies or third-party service records. [4, 5]

## Supply Chain, License and Maturity

The Dockerfile pins Node and Go base images by digest, uses the npm lockfile with install scripts disabled during dependency installation, and produces a scratch image. Go modules have checksums. Build/release actions inspected are SHA-pinned. Trivy is configured to fail on fixable HIGH/CRITICAL image findings; this intentionally excludes unfixed findings. CodeQL and separate cosign/provenance/SBOM workflows exist. Their presence is not verification that this revision's runs passed, or that a downloaded artifact matches source. No images/signatures were downloaded or verified. Pin an accepted image digest instead of the README's moving `latest`. [7, 13]

The root license is AGPL v3 and package/image labels say AGPL-3.0-only. Preserve notices and meet corresponding-source obligations when distributing or offering modified covered software over a network. The contributor agreement permits the maintainer to offer additional commercial/proprietary licenses while keeping included public contributions AGPL for that release. Media, artwork, metadata and third-party dependency rights remain separate. No source components were extracted by this review. [14]

Public GitHub metadata at retrieval (2026-11-21 UTC): repository created 2026-11-09, last push 2026-11-20T19:49:10Z, 2,571 stars, 165 forks and 244 open issues/PRs combined. These are activity indicators, not security evidence. HEAD is dated 2026-11-19T23:22:05Z. Latest published release observed: **1.2.0**, published 2026-11-17T21:33:45Z; tag resolves to **d63e43f36a3a2babf475624f61b0a11021fd98fc**. The reviewed HEAD is different even though VERSION still says 1.2.0. Findings here describe HEAD, not a verified release binary. [15]

Static inventory found **1,481 Go test files**, **308 TypeScript unit-test files** and **70 Playwright spec files** under app. Tests include authentication, outbound policies, backup restoration and downloader contracts. File counts are not test results or coverage. A material documentation gap: the testing guide says CI runs full Go/frontend/race suites, but the checked-in workflows inspected mainly build/scan, vet/cross-compile, package, sign and run CodeQL; the advertised full application test jobs were not found. Require actual test-run evidence before trusting that claim. [16]

A sampled open issue, #624, questions “Subtitled” history totals. Source inspection confirms the filter matches `subtitle_*` rather than only successful saves. The reported counts were not reproduced. This is a useful example of why a polished dashboard is not a substitute for checking actual completed side effects. [17]

## Comparison

| Option | Better fit | Tradeoff |
|---|---|---|
| HolyArrs | A consolidated interface and smaller operational surface for an experimental home stack | Young public history; shared failure domain; metadata dependency and migration gaps |
| Sonarr + Radarr + Lidarr + Prowlarr + Bazarr + Seerr | Existing installations that depend on mature, specialized workflows and separately replaceable components | More services, credentials and configuration seams |
| Jellyfin/Plex with manual library management | Playback-focused households that do not need automated acquisition | Not substitutes for request/search/download orchestration; less automation authority |

These are functional alternatives, not a fresh benchmark or security audit of each project. Public starting points: [Sonarr](https://github.com/Sonarr/Sonarr), [Radarr](https://github.com/Radarr/Radarr), [Prowlarr](https://github.com/Prowlarr/Prowlarr), [Seerr](https://github.com/seerr-team/seerr), [Jellyfin](https://github.com/jellyfin/jellyfin).

## Self-Hosting Notes

Before any pilot, pin a release/digest; restrict first-run access; use a fixed low-privilege UID, minimal mounts and separate test media. Keep config/SQLite on local storage. A common parent mount for downloads and library enables same-filesystem operations; separate mounts may force copies. Do not let two automation systems simultaneously rename or delete the same production media. [1, 7]

Keep backups enabled, manually export a pre-change snapshot, and separately save the matching key. Test a restore on an isolated copy before changing a production schema. To roll back, restore compatible pre-update data **and** select the older image; an older binary alone cannot undo schema changes. Restored databases do not undo filesystem moves/deletions or downloader-side effects. Do not assume the backup-off path retains a rollback snapshot. [5, 6]

For uninstall, stop/remove the deployment while initially retaining its config and media, revoke integration/API credentials and remove proxy exposure. Only after validating retention needs should config, logs, backups, plugin state and key copies be deliberately deleted. Native packages/Proxmox deployments also require removing their service/package/container resources. No universal destructive uninstall procedure was validated; container removal is neither complete erasure nor migration rollback.

## Verification and Limits

- Public unauthenticated GitHub API and HTTPS source access succeeded; normalized canonical source is the repo URL above. No prior matching canonical review was found in the public index/reviews.
- Reviewed README/license/manifests, Dockerfile/workflows, architecture/testing/privacy/recovery docs and selected auth, secret, outbound, plugin, backup and frontend-history implementations. This is targeted static analysis, not exhaustive code audit.
- No source execution, build, dependency installation, product tests, deployment, live endpoint probing, account creation, signature verification or media retrieval. Availability, performance, integration compatibility, restore atomicity and runtime exploitability remain unverified.
- Review Markdown/HTML/index consistency, source-link paths, trusted-template script identity, placeholder/redaction scans and task-only Git diff are validated separately.

## Evidence

All source links below are pinned to the reviewed HEAD unless explicitly marked live metadata.

1. [README.md](https://github.com/HolyArrs/HolyArrs/blob/4b0349ea890d01e26668466cbfdbb7cc22f80eaf/README.md)
2. [docs/dev/architecture.md](https://github.com/HolyArrs/HolyArrs/blob/4b0349ea890d01e26668466cbfdbb7cc22f80eaf/docs/dev/architecture.md); [app/backend/cmd/holyarrs/wiring.go](https://github.com/HolyArrs/HolyArrs/blob/4b0349ea890d01e26668466cbfdbb7cc22f80eaf/app/backend/cmd/holyarrs/wiring.go); [go.mod](https://github.com/HolyArrs/HolyArrs/blob/4b0349ea890d01e26668466cbfdbb7cc22f80eaf/go.mod); [app/frontend/package.json](https://github.com/HolyArrs/HolyArrs/blob/4b0349ea890d01e26668466cbfdbb7cc22f80eaf/app/frontend/package.json)
3. [app/backend/internal/accounts/password.go](https://github.com/HolyArrs/HolyArrs/blob/4b0349ea890d01e26668466cbfdbb7cc22f80eaf/app/backend/internal/accounts/password.go); [app/backend/internal/accounts/middleware.go](https://github.com/HolyArrs/HolyArrs/blob/4b0349ea890d01e26668466cbfdbb7cc22f80eaf/app/backend/internal/accounts/middleware.go); [app/backend/internal/accounts/signin.go](https://github.com/HolyArrs/HolyArrs/blob/4b0349ea890d01e26668466cbfdbb7cc22f80eaf/app/backend/internal/accounts/signin.go); [app/backend/internal/accounts/service.go](https://github.com/HolyArrs/HolyArrs/blob/4b0349ea890d01e26668466cbfdbb7cc22f80eaf/app/backend/internal/accounts/service.go); [app/backend/internal/accounts/setup_owner.go](https://github.com/HolyArrs/HolyArrs/blob/4b0349ea890d01e26668466cbfdbb7cc22f80eaf/app/backend/internal/accounts/setup_owner.go)
4. [app/backend/internal/core/secrets/secrets.go](https://github.com/HolyArrs/HolyArrs/blob/4b0349ea890d01e26668466cbfdbb7cc22f80eaf/app/backend/internal/core/secrets/secrets.go)
5. [docs/run/backups.md](https://github.com/HolyArrs/HolyArrs/blob/4b0349ea890d01e26668466cbfdbb7cc22f80eaf/docs/run/backups.md); [app/backend/internal/backups/make.go](https://github.com/HolyArrs/HolyArrs/blob/4b0349ea890d01e26668466cbfdbb7cc22f80eaf/app/backend/internal/backups/make.go); [app/backend/internal/backups/open.go](https://github.com/HolyArrs/HolyArrs/blob/4b0349ea890d01e26668466cbfdbb7cc22f80eaf/app/backend/internal/backups/open.go)
6. [docs/run/updates.md](https://github.com/HolyArrs/HolyArrs/blob/4b0349ea890d01e26668466cbfdbb7cc22f80eaf/docs/run/updates.md); [app/backend/internal/backups/restore.go](https://github.com/HolyArrs/HolyArrs/blob/4b0349ea890d01e26668466cbfdbb7cc22f80eaf/app/backend/internal/backups/restore.go); [app/backend/internal/backups/off_update_test.go](https://github.com/HolyArrs/HolyArrs/blob/4b0349ea890d01e26668466cbfdbb7cc22f80eaf/app/backend/internal/backups/off_update_test.go); [app/backend/internal/backups/restore_pre_update_test.go](https://github.com/HolyArrs/HolyArrs/blob/4b0349ea890d01e26668466cbfdbb7cc22f80eaf/app/backend/internal/backups/restore_pre_update_test.go)
7. [deploy/Dockerfile](https://github.com/HolyArrs/HolyArrs/blob/4b0349ea890d01e26668466cbfdbb7cc22f80eaf/deploy/Dockerfile); [app/backend/internal/core/startup/runas_linux.go](https://github.com/HolyArrs/HolyArrs/blob/4b0349ea890d01e26668466cbfdbb7cc22f80eaf/app/backend/internal/core/startup/runas_linux.go)
8. [app/backend/internal/core/outbound/dial.go](https://github.com/HolyArrs/HolyArrs/blob/4b0349ea890d01e26668466cbfdbb7cc22f80eaf/app/backend/internal/core/outbound/dial.go)
9. [app/backend/internal/core/startup/held_features.go](https://github.com/HolyArrs/HolyArrs/blob/4b0349ea890d01e26668466cbfdbb7cc22f80eaf/app/backend/internal/core/startup/held_features.go)
10. [deploy/proxmox/holyarrs-lxc.sh](https://github.com/HolyArrs/HolyArrs/blob/4b0349ea890d01e26668466cbfdbb7cc22f80eaf/deploy/proxmox/holyarrs-lxc.sh); [deploy/proxmox/holyarrs-install.sh](https://github.com/HolyArrs/HolyArrs/blob/4b0349ea890d01e26668466cbfdbb7cc22f80eaf/deploy/proxmox/holyarrs-install.sh)
11. [docs/run/plugins.md](https://github.com/HolyArrs/HolyArrs/blob/4b0349ea890d01e26668466cbfdbb7cc22f80eaf/docs/run/plugins.md); [app/backend/internal/plugins/sandbox_linux.go](https://github.com/HolyArrs/HolyArrs/blob/4b0349ea890d01e26668466cbfdbb7cc22f80eaf/app/backend/internal/plugins/sandbox_linux.go)
12. [docs/library/metadata.md](https://github.com/HolyArrs/HolyArrs/blob/4b0349ea890d01e26668466cbfdbb7cc22f80eaf/docs/library/metadata.md); [docs/run/outside-hosts.md](https://github.com/HolyArrs/HolyArrs/blob/4b0349ea890d01e26668466cbfdbb7cc22f80eaf/docs/run/outside-hosts.md); [app/backend/internal/metadata/hosted.go](https://github.com/HolyArrs/HolyArrs/blob/4b0349ea890d01e26668466cbfdbb7cc22f80eaf/app/backend/internal/metadata/hosted.go); [app/backend/internal/health/count_install.go](https://github.com/HolyArrs/HolyArrs/blob/4b0349ea890d01e26668466cbfdbb7cc22f80eaf/app/backend/internal/health/count_install.go)
13. [.github/workflows/build.yml](https://github.com/HolyArrs/HolyArrs/blob/4b0349ea890d01e26668466cbfdbb7cc22f80eaf/.github/workflows/build.yml); [.github/workflows/release.yml](https://github.com/HolyArrs/HolyArrs/blob/4b0349ea890d01e26668466cbfdbb7cc22f80eaf/.github/workflows/release.yml); [.github/workflows/sign.yml](https://github.com/HolyArrs/HolyArrs/blob/4b0349ea890d01e26668466cbfdbb7cc22f80eaf/.github/workflows/sign.yml); [.github/workflows/codeql.yml](https://github.com/HolyArrs/HolyArrs/blob/4b0349ea890d01e26668466cbfdbb7cc22f80eaf/.github/workflows/codeql.yml)
14. [LICENSE](https://github.com/HolyArrs/HolyArrs/blob/4b0349ea890d01e26668466cbfdbb7cc22f80eaf/LICENSE); [.github/CLA.md](https://github.com/HolyArrs/HolyArrs/blob/4b0349ea890d01e26668466cbfdbb7cc22f80eaf/.github/CLA.md); [app/frontend/package.json](https://github.com/HolyArrs/HolyArrs/blob/4b0349ea890d01e26668466cbfdbb7cc22f80eaf/app/frontend/package.json)
15. [Live repository metadata](https://api.github.com/repos/HolyArrs/HolyArrs); [release 1.2.0](https://github.com/HolyArrs/HolyArrs/releases/tag/1.2.0); [reviewed commit](https://github.com/HolyArrs/HolyArrs/commit/4b0349ea890d01e26668466cbfdbb7cc22f80eaf).
16. [docs/dev/testing.md](https://github.com/HolyArrs/HolyArrs/blob/4b0349ea890d01e26668466cbfdbb7cc22f80eaf/docs/dev/testing.md); [.github/workflows](https://github.com/HolyArrs/HolyArrs/tree/4b0349ea890d01e26668466cbfdbb7cc22f80eaf/.github/workflows); [Makefile](https://github.com/HolyArrs/HolyArrs/blob/4b0349ea890d01e26668466cbfdbb7cc22f80eaf/Makefile); [app/tests](https://github.com/HolyArrs/HolyArrs/tree/4b0349ea890d01e26668466cbfdbb7cc22f80eaf/app/tests)
17. [app/frontend/src/lib/downloads/history-search.ts](https://github.com/HolyArrs/HolyArrs/blob/4b0349ea890d01e26668466cbfdbb7cc22f80eaf/app/frontend/src/lib/downloads/history-search.ts); [public issue #624](https://github.com/HolyArrs/HolyArrs/issues/624).

---

**Attribution:** HolyArrs/HolyArrs, maintained by CoderLuii; AGPL-3.0-only declarations and root GNU AGPL v3 license. Independent review; no affiliation implied.
