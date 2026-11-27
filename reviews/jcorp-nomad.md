# Jcorp Nomad (Jstudner/jcorp-nomad)

**Repo:** https://github.com/Jstudner/jcorp-nomad
**Author:** Jackson Studner / Jcorp Tech
**License:** GPL-3.0-or-later code/docs, CC BY-SA 4.0 case models; trademarks, photos and third-party components have separate terms.
**Reviewed:** 2026-11-27 (UTC)
**Revision:** `9fad8cab4d96d36701c056b09fd448f494ee5773`, main; firmware, SD-card web interface, licensing, tooling and documentation. Source commit dated 2026-11-23.
**Verification:** Static review only. Anonymous GitHub API and HTTPS source retrieval succeeded. No builds, source execution, installs, device flashing, hardware access, accounts or live device probes; tests were not run.
**Stack:** ESP32-S3, Arduino/C++, FreeRTOS, SdFat, ESP Async WebServer, LVGL, browser JavaScript and bundled browser libraries.
**What it is:** A USB-powered, microSD-backed pocket offline media/library server and Wi-Fi hotspot. This is not HashiCorp Nomad, a workload scheduler, or another similarly named offline-computing product. [1]

---

## Verdict

⚠️ **Interesting — unusually capable pocket library, not a secure multi-user server.** The hardware-aware streaming path, rich browser clients and concrete recovery mechanisms make it worth a controlled hobbyist trial. Optional admin authentication, HTTP transport, guest file mutations and a writable card carrying both content and executable UI make trusted networks and non-sensitive media essential. Performance and recovery remain source claims rather than independently reproduced results. [1] [2] [3] [4] [5] [6] [7] [15] [8]

## What It Is

Nomad creates its own hotspot or joins an existing network, serving media directly to browsers and DLNA clients. Its primary target is inexpensive, portable sharing for travel, camping and small groups, not an always-on account-based home media service. It is built specifically for Waveshare's ESP32-S3 1.47-inch LCD USB-A/USB-C boards; the README recommends the separate Nomad Lite project for other ESP32 boards. [1]

The browser does much of the feature work: playback, readers, games, map rendering and translation. ZIM archives, map packs and translation packs need advance preparation using the separately maintained Nomad Tools. Supported filename extensions are not a guarantee of browser codec support; this firmware is not an on-device video transcoder. [1] [9]

## Stack

| Layer | Tech |
|-------|------|
| Firmware | Arduino-ESP32 3.3.3; large Arduino sketch plus C++/header modules and FreeRTOS tasks |
| Networking | AsyncTCP 3.6.0; vendored, patched ESP Async WebServer 3.12.1; DNS/captive portal, DLNA |
| Storage | SdFat 2.3.0; microSD FAT/exFAT; JSON settings and generated indexes, no database server |
| Device screen | LVGL 8.3.10; generated UI and status assets |
| Browser | HTML/CSS/JavaScript; PDF.js, epub.js, Plyr, MapLibre/PMTiles, EmulatorJS and others |
| Authentication | Optional shared admin password, challenge-response login, bearer sessions; no per-viewer account model |

Versions above follow README requirements; the notices list LVGL more broadly as 8.3. This is manual dependency alignment, not a demonstrated reproducible whole-system build. [1] [2] [3] [9]

## Key Features

### Shared media and reading
Movies/shows, music queues, books/comics, subtitles, gallery/files, OPDS and DLNA provide unusually broad direct-play coverage. Watch Together, local multiplayer and chat add shared activities rather than isolated playback. Browser compatibility and aggregate Wi-Fi bandwidth constrain the experience. [1] [9]

### Prepared offline knowledge
ZIM browsing, vector maps with routing, installed translation pairs, recipes and 3D-model previews extend the device beyond a media stick. The preparation tools and acquired content are separate operational dependencies; this review did not inspect or run their distribution archives. Offline use requires loading the necessary data and browser assets beforehand. [1] [9]

### Administration and recovery
The admin interface exposes page/upload controls, indexing, activity, storage health, themes, network configuration and updates. Firmware OTA verifies a signed image and uses an inactive slot with a boot-proving/rollback sequence; interface updates are a different, hash-checked file replacement mechanism. [4] [5]

## Architecture

The 8,816-line `JcorpNomadProject.ino` owns startup, HTTP route registration, media streaming, settings, indexing and file operations. Smaller modules separate path policy, auth, OTA, SD access, health, DNS, DLNA and display concerns; `NomadMain.cpp` is the LCD main-screen module, not the application entry point. This is hardware-specific embedded software, not a containerized service. [2]

HTTP range responses read from microSD. An aligned internal DMA buffer feeds per-response PSRAM read-ahead caches, reducing small SD transactions on the network task. Mutexes, queues and worker tasks coordinate card writes and longer operations. These are useful constrained-memory patterns, but global state and a large central sketch raise maintenance and integration-test costs. [2] [6]

The card root is also the web root. Firmware middleware canonicalizes paths to account for FAT case/spacing aliases, URL decoding and protected locations; upload handlers apply checks before writing body chunks. Content, UI scripts, generated indexes and private settings thus share a physical medium but have distinct web-access policies. [7] [15]

## Security, Permissions and Privacy

- **Configure admin auth before sharing.** The default admin password is empty, and `checkAdminAuth()` then returns true for everyone. The README also publishes a common factory hotspot credential. Change the hotspot credential and set a strong separate admin password before joining a shared LAN. This is a deliberate default, not evidence of an authentication bypass. [1] [2] [3]
- **Authentication is not transport encryption.** Login uses PBKDF2-HMAC-SHA256 (10,000 default iterations), single-use expiring nonces and HMAC proofs; sessions use random tokens and store their hashes on the card. Non-remembered sessions idle out after an hour; remembered sessions survive restarts until revoked/password change. The server listens on HTTP port 80, and browser-held tokens go in `X-Admin-Token`. Challenge-response does not prevent a network attacker from stealing bearer tokens or replacing HTTP-delivered JavaScript. The stored PBKDF2 key can itself generate valid challenge proofs if the card is stolen; it is a credential-equivalent, not merely a harmless password hash. [2] [3] [10]
- **Guest writes are broader than uploads.** With guest writes enabled, ordinary content paths may be created, renamed, saved or deleted; protected UI/active-content/root paths require admin status, and config paths are forbidden through file routes. The upload switch also gates ordinary mutations, but community paths are exempt. This is not per-user ownership or role-based authorization. Disable guest writes for curated libraries and still keep backups. [7] [15]
- **Real defensive work is present.** Middleware rejects cross-site mutation requests based on Origin/Fetch Metadata, protects config reads, covers route suffix matching, and treats active content and FAT short-name aliases specially for writes. Login throttling is per address plus a global burst cap. These are inspected controls, not proof that every route/parser is vulnerability-free; clients without Origin are not automatically rejected. Permissive CORS appears on media/read responses and is not an authorization boundary. [2] [7] [15]
- **Offline does not mean private from peers or the operator.** Browsing is generally shared without viewer accounts. The admin can see device/file activity and stop streams; usage totals and popular-file counts persist locally. Browser localStorage retains resume/bookmark state and optionally an admin token. Settings serialize hotspot/LAN credentials onto the removable card; no at-rest encryption was established. Protect the card and backup copies. [2] [8] [10]
- **Network mode introduces egress.** In Wi-Fi mode the admin browser checks/downloads UI updates from the flasher service; firmware can pull updates too. Firmware pull explicitly uses `setInsecure()`, so TLS certificate validation is disabled there, although image signature verification remains a separate defense against unauthorized firmware. UI updates validate size and SHA-256 supplied through the update flow, not the firmware's ECDSA signature scheme. Treat the update service/browser and card UI as trusted code sources; do not describe this as an air-gapped system in network mode. [4] [5] [16]

## Persistence, Backup and Recovery

Settings, sessions, usage and shared state live on the SD card; firmware update status also uses ESP32 Preferences/NVS. The settings writer uses temporary/backup files and boot-time JSON recovery. Index construction stages data and checks read-back before publishing; failed scans can retain the previous index. A 32 MiB reserve protects configuration space from uploads. These are concrete mitigations, not guarantees against card wear, filesystem corruption or sudden power loss. [2] [3] [4] [5] [8]

OTA writes an inactive partition, checks SHA-256, signature, board and version, then requires startup health and 60 seconds of successful running with a 120-second deadline. It depends on a compatible partition/bootloader layout; code reports that devices without a spare slot need USB flashing first. USB recovery and owner-built firmware remain possible, whereas stock OTA trusts the shipped public key. None of these recovery paths was exercised. [4]

UI updates swap individual files with staging/old suffixes; that is not an atomic transaction across the entire interface. Keep a known-good matching firmware/card-interface pair and an offline full-card backup, including hidden files and config. Stop writes before copying, retain browser state separately if important, and test restore on a spare card before relying on the device. Backups containing settings are sensitive. Rebuilding indexes is not restoration of deleted media. [2] [5] [10]

## Maturity, Tests and Performance Evidence

Anonymous metadata on 2026-11-27 reported **1,391 stars, 67 forks and 2 open issues** (GitHub's open-issues count can include pull requests), with last push 2026-11-23. These indicate attention/activity, not safety or reliability. [14]

Main presents **Mk5 / firmware 5.0**, but the newest published release returned by the releases API is **mk4**, published 2026-11-23, explicitly a backfilled pre-Mk5 release. Its annotated tag object is `b3b9d89f4761b27a018bd475a67a2e364e9bda33`, peeling to `4e2c5448fda6a1a0d888f05a07da5d4d59efa20c`. The release says firmware 4.6 and CC BY-NC-SA 4.0, with no uploaded release assets. Do not equate that release/license with reviewed main. The source update-channel default remains `experimental` unless overridden, despite the README's stable branding. [1] [5] [11]

A host C++ path-policy suite exists at `tools/guardtest`; it compiles the real guard header against a String stand-in and exercises malformed/encoded paths and access rules. Conditional benchmark endpoints and failure-injection hooks also exist. No checked-in GitHub Actions workflows were found at the reviewed tree. No tests, builds, source scripts or benchmarks were executed for this review. A narrow unit harness is not end-to-end evidence for HTTP auth, media behavior or recovery. [6] [7] [15] [12]

The author reports aggregate **8–9 Mbit/s** in a less congested environment, roughly four higher-quality films or eight at the stated 480p preset, and an OPDS improvement from about nine seconds to half a second. Read-ahead comments report network-task SD-read time dropping from 12.3 to 1.4 seconds per 30 seconds with eight downloads. These are useful, specific author measurements, but the inspected material did not supply an independently reproduced benchmark dataset or a complete controlled methodology. Radio contention, card behavior, encoded bitrate and client browser matter; do not plan capacity from the star count or a “stable” badge. [1] [6]

## Dependencies and Licensing

The licensing document grants GPL-3.0-or-later for project code/docs and an additional linking permission for Espressif SDK/binary-only components. Case STL models use CC BY-SA 4.0; names/logos and product photos are excluded from the general license. Preserve notices and satisfy corresponding-source obligations when distributing firmware or derivatives; follow branding restrictions for renamed/sold builds. Do not substitute the README's simplified licensing summary for the actual terms. [13]

Third-party notices list LGPL libraries, MIT/BSD/Apache browser components, fonts and media with separate terms, plus UnRAR's extraction-only restriction. Emulator/game cores, ROMs, acquired maps, ZIMs and translation datasets require their own rights review; the project license does not grant rights to arbitrary content. No exhaustive transitive-license, CVE, binary-provenance or dependency-reproducibility audit was performed. No source/assets were extracted into this review. [9] [13]

## Comparison

These are fit comparisons, not comparative benchmarks; alternative implementations were not audited in this review.

| Aspect | Jcorp Nomad | Alternative |
|--------|-------------|-------------|
| Small ESP32 portable media server | Broad UI, tightly coupled to supported LCD boards | [Nomad Lite](https://github.com/Jstudner/jcorp-nomad-lite): suggested by the author for other ESP32 boards and simpler media use |
| Full home media service | Direct-play, shared viewers, small resource budget | [Jellyfin](https://jellyfin.org): better fit for accounts, library management and capable-host transcoding; requires more hardware/operations |
| Offline reference appliance | Many entertainment and library features; ZIM preparation step | [Kiwix Hotspot](https://kiwix.org/en/applications/): consider for a primarily offline educational/reference hotspot rather than a tiny general media gadget |

## Self-Hosting Notes

This is a hardware build/flash workflow, not Docker deployment. Use the specified board, adequate USB power, a reliable card and the pinned Arduino/library versions, or independently verify the prebuilt flasher's firmware provenance. Match USB-A versus USB-C display wiring and keep firmware/interface versions aligned. Populate and index the card before travel; test real client browsers and codecs, expected simultaneous streams, map/translation packs, power-loss recovery and backup restore. [1]

Keep the device off the public internet and on a trusted or isolated network; do not port-forward it. Set credentials, restrict guest mutations, avoid confidential content and untrusted executable card files, and use a separate low-privilege network credential in station mode. A controlled trial is reasonable; replacing a private account-based media server or relying on it as the only copy of a library is not.

## Evidence and Scope

All code links below are pinned to the reviewed source commit. Metadata/release links are mutable snapshots retrieved on the review date. Inspection covered representative control/streaming paths, not every bundled minified dependency, archive, media file, alternate branch or external flasher/tool service.

[1]: https://github.com/Jstudner/jcorp-nomad/blob/9fad8cab4d96d36701c056b09fd448f494ee5773/README.md
[2]: https://github.com/Jstudner/jcorp-nomad/blob/9fad8cab4d96d36701c056b09fd448f494ee5773/firmware/JcorpNomadProject/JcorpNomadProject.ino
[3]: https://github.com/Jstudner/jcorp-nomad/blob/9fad8cab4d96d36701c056b09fd448f494ee5773/firmware/JcorpNomadProject/NomadAuth.h
[4]: https://github.com/Jstudner/jcorp-nomad/blob/9fad8cab4d96d36701c056b09fd448f494ee5773/firmware/JcorpNomadProject/NomadFirmware.h
[5]: https://github.com/Jstudner/jcorp-nomad/blob/9fad8cab4d96d36701c056b09fd448f494ee5773/firmware/JcorpNomadProject/NomadUpdate.h
[6]: https://github.com/Jstudner/jcorp-nomad/blob/9fad8cab4d96d36701c056b09fd448f494ee5773/firmware/JcorpNomadProject/NomadReadAhead.h
[7]: https://github.com/Jstudner/jcorp-nomad/tree/9fad8cab4d96d36701c056b09fd448f494ee5773/firmware/JcorpNomadProject
[8]: https://github.com/Jstudner/jcorp-nomad/blob/9fad8cab4d96d36701c056b09fd448f494ee5773/firmware/JcorpNomadProject/NomadUsage.h
[9]: https://github.com/Jstudner/jcorp-nomad/blob/9fad8cab4d96d36701c056b09fd448f494ee5773/THIRD-PARTY-NOTICES.md
[10]: https://github.com/Jstudner/jcorp-nomad/blob/9fad8cab4d96d36701c056b09fd448f494ee5773/SD_Card_Template/nomad-utils.js
[11]: https://github.com/Jstudner/jcorp-nomad/releases/tag/mk4
[12]: https://github.com/Jstudner/jcorp-nomad/tree/9fad8cab4d96d36701c056b09fd448f494ee5773/tools/guardtest
[13]: https://github.com/Jstudner/jcorp-nomad/blob/9fad8cab4d96d36701c056b09fd448f494ee5773/LICENSING.md

[14]: https://api.github.com/repos/Jstudner/jcorp-nomad
[15]: https://github.com/Jstudner/jcorp-nomad/blob/9fad8cab4d96d36701c056b09fd448f494ee5773/firmware/JcorpNomadProject/NomadGuardWeb.h
[16]: https://github.com/Jstudner/jcorp-nomad/blob/9fad8cab4d96d36701c056b09fd448f494ee5773/SD_Card_Template/admin.js

**Attribution:** Jackson Studner / Jcorp Tech, Jstudner/jcorp-nomad. GPL-3.0-or-later project with the component and asset exceptions described above. Independent static analysis; no affiliation or endorsement.
