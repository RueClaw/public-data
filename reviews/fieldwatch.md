# Fieldwatch (OffGridPete/Fieldwatch)

**Repo:** https://github.com/OffGridPete/Fieldwatch
**License:** MIT source; third-party tables, map data, dependencies and trademark rights have separate terms.
**Reviewed:** 2026-11-21 (UTC)
**Revision:** a7d9e6a5d9883a6bfe986e59915ef706551ff930; default-branch snapshot, repository-wide static sampling. App version 1.2.1, versionCode 56. Latest release v1.2.1 was published 2026-11-20; its annotated tag resolves to baddc62019aa4ae5f4ee378198f072d4cf2bfb72, not this later update-notes commit.
**Verification:** Static source review and catalog JSON count only. No build, app execution, hardware, RF collection, transmission, deployment or model download. Upstream CI success is reported separately below.
**Stack:** Kotlin 2.0.21, Android 10+, Jetpack Compose, Android radio/location APIs, coroutines/StateFlow, kotlinx.serialization, local files.
**What it is:** An Android radio-observation and field-notebook app, not an SDR, an AI detection model or a proven surveillance detector.

---

## Verdict

⚠️ **Interesting — unusually broad phone-local observation tooling, not a source of verified identities or threat attribution.** Fieldwatch combines readable Wi-Fi/BLE observations, extensible signatures, paths and session reports with substantial protocol-specific code and explicit uncertainty warnings. Its strongest fit is informed exploration on a controlled Android device; use independent corroboration before treating an alert as a tracker, hostile cell, jammer, camera or aircraft identification. Location-bearing exports, optional network features and non-atomic session persistence deserve more attention than the “no backend” headline.

## What It Is

Fieldwatch observes what Android exposes: access-point scan results, BLE advertisements, the phone's GNSS behavior and serving-cell context. It organizes them into live lists, maps, watchlists, signal-strength hunting and saved observation sessions called “sits.” It does not provide monitor-mode Wi-Fi client capture, Bluetooth Classic inquiry, arbitrary spectrum analysis or direction finding. The README's older “not cellular” bullet should be read alongside the newer serving-cell monitor: it is not a general cellular scanner. [E1, E2]

The README describes it as entirely passive. That is reasonable shorthand for not joining target devices or attacking them, but **not a radio-silence guarantee**: WifiRadio explicitly calls Android's startScan(), and BLE uses the platform scanner without establishing a guaranteed passive-only RF mode. Firmware and OS scanning behavior remain outside this app's control. No RF behavior was measured here. [E2]

## Stack

| Layer | Technology / boundary |
|---|---|
| App / UI | Single Android app, Kotlin, Compose, ViewModel and StateFlow |
| Acquisition | Foreground ScanService; Wi-Fi, BLE, GNSS and cell wrappers |
| Classification | Deterministic SignatureEngine, protocol decoders, catalogs and anomaly heuristics |
| Storage | In-memory live store; JSON settings/sits, rotating logs, local map cache |
| Networking | GitHub update/catalog fetches; optional map/geocoder/sensor-list retrieval and TAK UDP feed |
| Authentication | Android device/app sandbox; no Fieldwatch account or server-side login |
| Build | Java 17, AGP 8.7.3, Gradle 8.11.1; Google/Maven Central/Gradle plugin repositories |

## Key Features

### A practical observation pipeline

Wi-Fi scanning has quota tracking and retry backoff; BLE handles failures, scan intensity and vendor-specific behavior. DeviceStore bounds the live list (400 steady-state target, 900 hard ceiling), keeps short signal histories and avoids repeatedly matching unchanged identities. SignatureEngine indexes OUI prefixes and compiles rules rather than walking every catalog prefix per refresh. These are credible implementation details, not proof of reliable background scanning across OEM phones. [E2, E3]

### Signatures and Radio Signature Interchange

The bundled RSI file parses as format radio-signatures, formatVersion 1, publisher fieldwatch, catalogVersion 114, with **328 fleet entries** counted independently. Entries are not 328 independently validated device identities. Matching uses names/globs, MAC/OUI prefixes, manufacturer data, service UUIDs, vendor information elements and clustering. Special-case suppression rules address overlapping product classifications. Shared identifiers and spoofable broadcast names remain ambiguous. [E3, E4]

[Radio Signature Interchange](https://github.com/OffGridPete/radio-signature-interchange) is the related format/specification project; Fieldwatch is a consuming/producing application and catalog publisher, not the specification itself. SignatureExchange supports RSI exports, older Fieldwatch/Spectre formats, unknown-field tolerance and preservation of foreign rule data. SignatureEngine excludes unknown rules from execution and blocks an all-rules match when an enabled foreign rule is present. Unsupported decode sources can be skipped while the understood signatures still import. This is pragmatic forward compatibility, not evidence of complete cross-application conformance. No independent interoperability suite was run. [E4]

### Alerts are hypotheses, not authenticated measurements of intent

GNSS monitoring detects changes from a phone-local baseline; a problem present at startup may not trigger it, and benign conditions can resemble interference. CellWatch learns serving cells at places; a changed cell or generation downgrade does not establish an IMSI catcher. Tracker, pairing-flood, trusted-network and Remote ID swarm/perimeter logic combine thresholds and broadcast data, not a trained detector with published sensitivity/specificity. RSSI heat clouds show where the phone heard a signal more strongly, not a triangulated source location. [E1, E5]

Remote ID parsing can expose advertised aircraft positions, but RemoteIdAuth stores authentication-message metadata rather than verifying signatures. The changelog explicitly says verification is not performed. A message claiming authentication is not an authenticated aircraft. The map's ordinary observation coordinates are the phone at hear-time, not the observed transmitter; decoded broadcast locations and imported sensor-map points are different evidence classes. Camera lists are external records, not detections of currently functioning cameras. [E1, E5, E6]

### Reports without an embedded AI service

Sits support paths, debriefs, comparisons and shareable exports, including AI-oriented text. “AI Export” is prepared evidence/prompt material, not proof of an onboard model or automatic cloud inference. If passed to an external assistant, radio names and other broadcast strings remain untrusted data and the exported location history becomes that recipient's data. [E1, E7]

## Architecture

Android acquisition wrappers feed observations into DeviceStore and pure-Kotlin domain logic; ScanService owns foreground collection, while the UI exposes observable state. Distinct domain modules cover protocol parsing, signatures, geospatial representation, anomaly rules and report construction. ConfigStore, SitStore and LogStore handle separate persistence concerns rather than a transactional database. The pure-domain separation enables JVM tests; the large feature surface and central app/UI coordination still make changes cross-cutting. [E2, E3, E7]

### Persistence and recovery

Sits flush on a 10-second loop, cap radios at 6,000 and path points at 16,000, and retain only ten closed sessions. SitStore writes directly to the destination JSON file; loading skips malformed files and chooses the newest open sit, deleting extra open-session files. A crash or disk failure during overwrite can therefore lose a session, not merely the last ten seconds. There is no transactional journal or demonstrated crash-recovery test result in this review. [E7]

Logs rotate through twelve files using a configurable size threshold (initially 1 MiB); default settings enable logging. Rotation is a capacity policy, not a time-based privacy retention guarantee. ConfigStore and MapKeyStore use temporary-file rename with a non-atomic direct-write fallback; map tiles are retained until cleared or pruned above 512 MiB. Android backup is disabled. Export signatures/settings before destructive reinstall, but those exports are not a complete backup of logs and GPS history. [E1, E7, E8]

## Security, Privacy and Deployment Boundaries

- **Local authority:** no web service to expose, no server CORS or login to harden. Protection primarily comes from Android's sandbox and the device lock. The scan service and FileProvider are non-exported; the launcher activity is exported. No root requirement appears in the reviewed build/manifest. Location, nearby radios, foreground service, wake-lock, notification, activity-recognition and battery-optimization exemptions are meaningful permissions, not decorative install prompts. [E8]
- **Privacy mode is not erasure:** the README explicitly warns that full coordinates remain in logs even when screens/reports are masked. Reports, raw logs, radio detail and AI exports may carry location and observed identifiers off-device. Local files and map keys are not app-level encrypted stores in the inspected implementations; rely on OS storage protection, not a claimed application encryption layer. [E1, E7, E8]
- **Offline-capable is not network-isolated:** opening the app online checks GitHub for update metadata. Catalog and sensor-list downloads contact public hosts; optional geocoding uses the system provider, and map tile requests can disclose viewed areas to tile providers. MapKeyStore excludes keys from settings export, a useful boundary, but stores accepted tokens as local JSON. No Fieldwatch backend is necessary for these disclosures. [E6, E8, E9]
- **TAK is an outbound sharing boundary:** TakPublisher emits UDP unicast/multicast/loopback CoT traffic, not authenticated TLS transport. Privacy mode pauses the feed. Use only an explicitly trusted network/recipient; do not assume recipients, network observers or retained exports honor later deletion. [E8]
- **Imports remain untrusted:** ImportFiles caps signature packs at 8 MiB, settings at 2 MiB and trusted-network files at 1 MiB. Those limits reduce simple memory exhaustion, but do not establish parser fuzzing, bounded semantic expansion, catalog authenticity or correct classifications. Review imported signatures before using their alerts. [E4, E8]

## Installation and Supply Chain

Sideloading is the documented distribution path; Android 10 is the minimum and target/compile SDK is 35. The app requests permission to install packages for updates. AppUpdateClient uses fixed GitHub main-branch URLs rather than letting update metadata choose an arbitrary APK URL; it bounds downloads, checks ZIP magic and cleans partial files. AppUpdateInstall then checks package name, exact advertised version, newer version code and signer correspondence with the installed application before opening Android's confirmation UI. This is significantly stronger than a download-and-open updater. [E9]

The first install is still a bootstrap trust decision. No APK signature or source-to-binary reproducibility verification was performed here. A mutable main-branch APK URL is not an immutable release artifact; use a deliberately chosen release and independently verify its publisher fingerprint. CI builds a debug artifact, not proof that the checked-in release APK was built from the same source. The project documents a historical certificate migration requiring uninstall (and loss of app data without export). [E1, E9, E10]

Dependencies have explicit versions/BOM, but the inspected wrapper lacks distributionSha256Sum and CI actions use mutable major-version tags rather than full commit pins. The build downloads SDK/packages and plugins; this review did not run Gradle or install anything. Those are supply-chain hardening opportunities, not evidence of malicious code. [E10]

## Maturity and Verification

Public unauthenticated GitHub metadata on 2026-11-21 showed 4,753 stars, 548 forks and 12 open issue/PR items; last push was 2026-11-20. Popularity is not validation. Release v1.2.1 and the detailed changelog show active iteration and corrections to privacy wording, decoder assumptions and device classification. The author describes it as a hobby project. [E1, E10]

There are **81 files under app/src/test** covering decoders, signatures, privacy formatting, storage behavior and domain rules. The checked-in workflow runs JVM unit tests before building a debug APK. GitHub reported [CI run 44784320906](https://github.com/OffGridPete/Fieldwatch/actions/runs/44784320906) successful for the exact reviewed SHA; this is an upstream result, not a local rerun or device test. No independently labeled detection corpus, field accuracy benchmark, broad handset validation or adversarial security audit was established by this review. We did not verify the APK, PDFs in depth, all catalog entries, RF behavior, battery lifetime or crash durability. [E10]

## Comparison

| Need | Fieldwatch | Alternative / tradeoff |
|---|---|---|
| Portable phone-local radio notebook | Broad integrated signatures, maps and reports | [WiFiAnalyzer](https://github.com/VREMSoftwareDevelopment/WiFiAnalyzer) is narrower Wi-Fi channel/AP tooling, with less combined inference |
| BLE engineering inspection | Readable classification and advertised fields | [nRF Connect for Mobile](https://www.nordicsemi.com/Products/Development-tools/nRF-Connect-for-mobile) focuses on BLE inspection and interaction, not the same field-notebook workflow |
| Rich wireless capture / sensor infrastructure | Limited to Android APIs, no dongle | [Kismet](https://www.kismetwireless.net/) fits capable capture hardware and deeper wireless monitoring, with more infrastructure and operational complexity |
| Shared signature libraries | Consumer and producer of RSI | Radio Signature Interchange supplies a format, not acquisition, identity validation or a deployment substitute |

These are functional alternatives, not benchmark winners; their current releases were not independently reviewed here.

## Self-Hosting Notes

There is no server stack to self-host. Evaluate a pinned build on a dedicated Android device, grant only features you intend to use, keep location and outbound sharing deliberate, and export important sessions before pruning/reinstall. Require handset-specific validation, trusted APK provenance and a clear retention/backup policy before relying on it in consequential field work. Do not interpret the lack of alerts as evidence that an area is safe or unmonitored.

## Evidence

All source links below are pinned to the reviewed SHA; GitHub metadata and linked external alternatives are time-varying.

- **E1:** [README](https://github.com/OffGridPete/Fieldwatch/blob/a7d9e6a5d9883a6bfe986e59915ef706551ff930/README.md), [changelog](https://github.com/OffGridPete/Fieldwatch/blob/a7d9e6a5d9883a6bfe986e59915ef706551ff930/CHANGELOG.md).
- **E2:** [Wi-Fi acquisition](https://github.com/OffGridPete/Fieldwatch/blob/a7d9e6a5d9883a6bfe986e59915ef706551ff930/app/src/main/java/app/fieldwatch/radio/WifiRadio.kt), [BLE acquisition](https://github.com/OffGridPete/Fieldwatch/blob/a7d9e6a5d9883a6bfe986e59915ef706551ff930/app/src/main/java/app/fieldwatch/radio/BleRadio.kt), [ScanService](https://github.com/OffGridPete/Fieldwatch/blob/a7d9e6a5d9883a6bfe986e59915ef706551ff930/app/src/main/java/app/fieldwatch/radio/ScanService.kt).
- **E3:** [SignatureEngine](https://github.com/OffGridPete/Fieldwatch/blob/a7d9e6a5d9883a6bfe986e59915ef706551ff930/app/src/main/java/app/fieldwatch/domain/SignatureEngine.kt), [DeviceStore](https://github.com/OffGridPete/Fieldwatch/blob/a7d9e6a5d9883a6bfe986e59915ef706551ff930/app/src/main/java/app/fieldwatch/data/DeviceStore.kt).
- **E4:** [RSI catalog](https://github.com/OffGridPete/Fieldwatch/blob/a7d9e6a5d9883a6bfe986e59915ef706551ff930/dist/fieldwatch-signatures.rsi), [SignatureExchange](https://github.com/OffGridPete/Fieldwatch/blob/a7d9e6a5d9883a6bfe986e59915ef706551ff930/app/src/main/java/app/fieldwatch/domain/SignatureExchange.kt), [ImportFiles](https://github.com/OffGridPete/Fieldwatch/blob/a7d9e6a5d9883a6bfe986e59915ef706551ff930/app/src/main/java/app/fieldwatch/data/ImportFiles.kt).
- **E5:** [GNSS heuristics](https://github.com/OffGridPete/Fieldwatch/blob/a7d9e6a5d9883a6bfe986e59915ef706551ff930/app/src/main/java/app/fieldwatch/domain/GnssInterference.kt), [CellWatch](https://github.com/OffGridPete/Fieldwatch/blob/a7d9e6a5d9883a6bfe986e59915ef706551ff930/app/src/main/java/app/fieldwatch/domain/CellWatch.kt), [RemoteIdAuth](https://github.com/OffGridPete/Fieldwatch/blob/a7d9e6a5d9883a6bfe986e59915ef706551ff930/app/src/main/java/app/fieldwatch/domain/RemoteIdAuth.kt).
- **E6:** [Sensor download sources](https://github.com/OffGridPete/Fieldwatch/blob/a7d9e6a5d9883a6bfe986e59915ef706551ff930/app/src/main/java/app/fieldwatch/data/FlockFiles.kt), [OSM attribution](https://github.com/OffGridPete/Fieldwatch/blob/a7d9e6a5d9883a6bfe986e59915ef706551ff930/dist/fieldwatch-sensors.txt).
- **E7:** [Sit constants](https://github.com/OffGridPete/Fieldwatch/blob/a7d9e6a5d9883a6bfe986e59915ef706551ff930/app/src/main/java/app/fieldwatch/domain/Sit.kt), [SitStore](https://github.com/OffGridPete/Fieldwatch/blob/a7d9e6a5d9883a6bfe986e59915ef706551ff930/app/src/main/java/app/fieldwatch/data/SitStore.kt), [LogStore](https://github.com/OffGridPete/Fieldwatch/blob/a7d9e6a5d9883a6bfe986e59915ef706551ff930/app/src/main/java/app/fieldwatch/data/LogStore.kt), [settings defaults](https://github.com/OffGridPete/Fieldwatch/blob/a7d9e6a5d9883a6bfe986e59915ef706551ff930/app/src/main/java/app/fieldwatch/domain/Models.kt).
- **E8:** [Manifest](https://github.com/OffGridPete/Fieldwatch/blob/a7d9e6a5d9883a6bfe986e59915ef706551ff930/app/src/main/AndroidManifest.xml), [MapKeyStore](https://github.com/OffGridPete/Fieldwatch/blob/a7d9e6a5d9883a6bfe986e59915ef706551ff930/app/src/main/java/app/fieldwatch/data/MapKeyStore.kt), [PathTiles](https://github.com/OffGridPete/Fieldwatch/blob/a7d9e6a5d9883a6bfe986e59915ef706551ff930/app/src/main/java/app/fieldwatch/data/PathTiles.kt), [PlaceLookup](https://github.com/OffGridPete/Fieldwatch/blob/a7d9e6a5d9883a6bfe986e59915ef706551ff930/app/src/main/java/app/fieldwatch/data/PlaceLookup.kt), [TAK publisher](https://github.com/OffGridPete/Fieldwatch/blob/a7d9e6a5d9883a6bfe986e59915ef706551ff930/app/src/main/java/app/fieldwatch/radio/TakPublisher.kt), [ConfigStore](https://github.com/OffGridPete/Fieldwatch/blob/a7d9e6a5d9883a6bfe986e59915ef706551ff930/app/src/main/java/app/fieldwatch/data/ConfigStore.kt).
- **E9:** [Update download](https://github.com/OffGridPete/Fieldwatch/blob/a7d9e6a5d9883a6bfe986e59915ef706551ff930/app/src/main/java/app/fieldwatch/data/AppUpdateClient.kt), [install verification](https://github.com/OffGridPete/Fieldwatch/blob/a7d9e6a5d9883a6bfe986e59915ef706551ff930/app/src/main/java/app/fieldwatch/data/AppUpdateInstall.kt), [catalog download](https://github.com/OffGridPete/Fieldwatch/blob/a7d9e6a5d9883a6bfe986e59915ef706551ff930/app/src/main/java/app/fieldwatch/data/CatalogRemote.kt).
- **E10:** [App build](https://github.com/OffGridPete/Fieldwatch/blob/a7d9e6a5d9883a6bfe986e59915ef706551ff930/app/build.gradle.kts), [CI workflow](https://github.com/OffGridPete/Fieldwatch/blob/a7d9e6a5d9883a6bfe986e59915ef706551ff930/.github/workflows/android.yml), [wrapper](https://github.com/OffGridPete/Fieldwatch/blob/a7d9e6a5d9883a6bfe986e59915ef706551ff930/gradle/wrapper/gradle-wrapper.properties), [tests](https://github.com/OffGridPete/Fieldwatch/tree/a7d9e6a5d9883a6bfe986e59915ef706551ff930/app/src/test), [release](https://github.com/OffGridPete/Fieldwatch/releases/tag/v1.2.1).
- **E11:** [LICENSE](https://github.com/OffGridPete/Fieldwatch/blob/a7d9e6a5d9883a6bfe986e59915ef706551ff930/LICENSE), [NOTICE](https://github.com/OffGridPete/Fieldwatch/blob/a7d9e6a5d9883a6bfe986e59915ef706551ff930/NOTICE).

**Attribution:** OffGridPete/Fieldwatch, copyright 2026 Off Grid Pete LLC, MIT source. Preserve MIT notices when reusing code; AndroidX/Kotlin and related dependencies have their own terms. IEEE/Bluetooth SIG tables and Fast Pair names are not relicensed as MIT by this repository; OSM sensor data is ODbL 1.0. Fieldwatch trademark rights are separate. No source code or datasets were extracted. [E11, E6]
