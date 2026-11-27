# Ripple (simoncirstoiu/Ripple)

**Repo:** https://github.com/simoncirstoiu/Ripple
**Author:** Simon Cîrstoiu
**License:** PolyForm Noncommercial 1.0.0; source-available, not unrestricted open source. Third-party MIT/Apache-2.0 notices also apply.
**Reviewed:** 2026-11-27 (UTC)
**Revision:** `dbbadb1b8eb377d4d903e54efe6548dd0f1733ab`; main and v1.0.41. Scope: README, licensing, integration Python, frontend, board table, firmware packaging, tests and repository automation.
**Latest release:** v1.0.41, published 2026-11-26 14:27:24 UTC; bundled device firmware is separately versioned 5.0.6.
**Verification:** Static review only. Anonymous GitHub metadata, HTTPS checkout, release/tag agreement and source inspection; no installation, imports, tests, flashing, accounts or live-device probes.
**Stack:** Python/Home Assistant, JavaScript Web Component, ZHA/zigpy or Zigbee2MQTT/MQTT, Jinja2, bundled TLSR8258 firmware binary.
**What it is:** A Home Assistant integration that configures compatible reflashed Zigbee routers as radio-link motion sensors, groups them into rooms and manages firmware installation.

---

## Verdict

⚠️ **Interesting — a credible hobby experiment, not a verified replacement for presence sensors.** The host integration has thoughtful write gates, backend adapters, calibration and OTA orchestration. But its central sensing firmware is distributed here as a binary without corresponding firmware implementation/build sources, the documented daily-use hardware set is only three boards, and a stationary occupant is not continuously detected. Treat flashing, household occupancy data and commercial licensing as material decisions, not incidental setup details. [1] [2] [3] [4] [5]

## What It Is

This is Simon Cîrstoiu's **Ripple for Home Assistant**, not Ripple/XRP payments, a UI ripple effect or another same-named software project. The identity is the canonical owner/repository and integration domain `ripple_presence`. It targets owners of compatible mains-powered Telink TLSR8258 Zigbee router devices; it is not a universal software upgrade for any Zigbee device. [1] [2]

The claimed detector runs on the switches, observing RSSI changes along sender–receiver links. Home Assistant discovers devices, chooses links and rooms, displays occupancy and tunes configuration. The README describes a median reference, weighted 16-sample rule, relay-edge suppression and bounded self-tuning. Those are **documented algorithm claims**, not independently audited firmware behavior: this tree contains the firmware binary and host protocol implementation, not the detector's C implementation. [1] [3] [6]

The README distinguishes 123 board-table entries from three boards used daily: Tuya TS0001, Indual TS0002 and BSEED TS0003 variants. “Supported” includes “mostly supported” and “in progress” entries. Its own physical-limit section says still people are held by timers, links need useful geometry, and weak/noisy links reduce coverage. No measured false-positive/false-negative dataset or independent room-scale validation was found in the reviewed material. [1]

## Stack

| Layer | Tech |
|-------|------|
| Home Assistant integration | Python config entry, entities, repairs, storage, WebSocket API |
| Panel | Local JavaScript Web Component; snapshot/delta and live subscriptions |
| ZHA adapter | Home Assistant/zigpy and generated custom quirk |
| Zigbee2MQTT adapter | HA MQTT integration, bridge requests, generated external JavaScript converter |
| Device | TLSR8258, bundled Ripple-v5.0.6.bin; detector implementation not included |
| Persistence | HA Store settings/history plus local board overrides and OTA cache |
| Dependencies | No extra pip requirements declared; relies on HA-provided libraries and backend compatibility |

The empty manifest `requirements` list means no additional pip installation declared by the integration, **not zero dependencies**. Python imports include voluptuous and Jinja2; the backends depend on HA/ZHA or Zigbee2MQTT internals. No dependency lockfile or reproducible firmware build was found. [2] [6] [7] [8]

## Key Features

### Room-level control and feedback

The engine manages discovery, device/API compatibility, rooms, per-line sensitivity, calibration and pending synchronization. Entity platforms expose occupancy and controls; the panel receives snapshots/deltas rather than continuously fetching a complete UI state. Separation into engine, transport, adapters, persistence and UI is a useful maintainability pattern, although the engine and panel remain substantial modules. [4] [7] [9]

### Guarded writes and conservative network handling

Sensing transport defaults to writes off, refuses protected/non-Ripple targets, rejects incompatible firmware writes and serializes work with spacing and exponential backoff (15–900 seconds). This is stronger than a UI-only checkbox. Firmware installation has its **own** allow-writes/protected-device/router/config checks because converting stock devices necessarily falls outside the ordinary Ripple-only write path. Do not interpret the README's “single guarded path” as one universal mechanism covering every operation. [4] [5]

### Firmware orchestration, not firmware authenticity

The installer selects the newest filename version from bundled/local binaries, builds a device-specific OTA wrapper and caches it using CRC32. It queues one install at a time, waits for reboot, verifies the reported board model and re-interviews the device. Those are meaningful operational checks, but CRC32 and matching a model string do not authenticate firmware or prove correct electrical pin mapping. No signature verification or trusted-digest allowlist appears in this host-side selection/wrapping path. Local overrides win on equal version and are trusted code inputs. [5]

## Architecture

`HA config entry → RippleRuntime → Engine + HaStore/HaHistory → guarded Zigbee transport → HassCore or Z2MCore → devices`

In parallel, `PanelPush/WebSocket → local panel` displays state and sends admin mutations. A separate Flasher/Z2MFlasher converts firmware, writes board configuration and checks post-reboot identity. ZHA setup writes its generated quirk into the configured custom-quirk directory; Z2M setup publishes a converter-save bridge request containing JavaScript. This runs within existing trusted automation processes, not an isolated sensing service. [5] [7] [8] [9] [10]

### Authentication, permissions and privacy

- **HA is the authentication boundary.** The panel is registered admin-only and mutation WebSocket handlers use `require_admin`. However, state, room, panel snapshot/subscription and history handlers lack that decorator. An authenticated non-admin HA connection is therefore not excluded by these handlers from the corresponding household data. This is not evidence of anonymous Internet access; the mismatch is between admin-only navigation and broader authenticated API reads. Verify and tighten this if household users should not see occupancy history. [9] [10]
- **“Writes off” is not a no-side-effects sandbox.** Startup still installs a local ZHA quirk or saves an external Z2M converter; device discovery/reads continue. Enabling external JavaScript delegates executable-code trust to the integration and broker access. Restrict MQTT bridge topic permissions and protect HA configuration storage. [7] [8] [10]
- **Local-first is useful, but not anonymity.** No direct cloud telemetry or remote inference call was found in the inspected runtime/frontend. Operational data flows through HA, Zigbee and optionally MQTT; installations/updates may contact GitHub or an installation service. Broker authentication/TLS and HA HTTPS/CORS are inherited deployment controls, not configured by Ripple. RF privacy and spoof resistance could not be verified from the firmware binary. [2] [7] [8] [9] [10]
- **Diagnostics need manual review before sharing.** Only `protected_devices` options are explicitly redacted. The diagnostic payload also includes room/device details, recent writes and nearly all stored settings. That can reveal household names, device identifiers, topology and activity context. [11]
- **Board overrides are trusted input.** Validation checks shape and byte lengths, not a complete hardware pin contract. The converter template places the model directly inside a quoted JavaScript string, while descriptions use JSON escaping. Do not accept untrusted board files as inert data; this is a local configuration trust boundary, not a demonstrated remote exploit. The panel itself generally creates DOM text nodes rather than inserting device text as raw HTML. [12]

### Persistence and recovery

Settings use HA storage with a two-second delayed save; detection history uses a 30-second delayed save. History is pruned on load/add to seven days and 50,000 events; this is not a strict timer-driven erasure guarantee while idle. HA recorder/backups may retain separate copies longer. An abrupt termination can lose recent buffered changes. Schema migration retains/converts some older layouts but explicitly starts empty for unsupported formats (including version 2). Backups matter before upgrades. [13]

OTA jobs and their task dictionary are in memory; unload cancels them. There is no persisted install journal or automatic rollback demonstrated here. A successful host backup does not restore a failed physical-device flash. Stock-device conversion renews permit-join every 20 seconds for 60-second windows while waiting, for up to 30 minutes; the reviewed wait path does not explicitly close joining on exit. Plan the joining window and do not interrupt power. Post-flash model checks and bounded re-interview retries help detect partial success but are not transactional recovery. [5] [7]

## Claims, Evidence and Maturity

| Claim or signal | Evidence and interpretation |
|----------------|-----------------------------|
| Existing Zigbee devices become motion sensors | Host configuration and bundled binary exist; compatible router/chip/board and flashing are required, not all existing devices |
| No additional sensors needed | Plausible for suitable existing hardware/geometry; not equivalent to reliable stationary-presence detection |
| Up to 100 switches; about 0.5% airtime per switch | README estimates, not a reviewed load benchmark; aggregate contention/interference requires measurement |
| Firmware integer algorithm, relay suppression, self-tuning | README/protocol descriptions, not independently verified implementation |
| Software tests | 19 Python test files plus JavaScript panel/converter checks; synthetic fixtures/fake cores and a fake MQTT broker cover host logic |
| CI | No checked-in workflow under .github/workflows; public Actions API returned zero workflow runs at retrieval |
| Release activity | v1.0.41 fixes wildcard OTA image type 0xFFFF handling for Z2M; tag resolves to reviewed SHA |
| Popularity | Anonymous metadata: 141 stars, 2 forks, 0 open issues/PRs in the combined GitHub field; last push 2026-11-26. Not a safety signal |

Tests were inspected, **not run**. Their fake-device coverage is valuable for regression design but cannot establish RF detection accuracy, electrical safety, OTA recovery on actual devices, or compatibility with every claimed HA/Z2M version. No explicit non-admin authorization test was located by a targeted test search. The Docker test definition uses Python 3.13 and an unpinned pytest-homeassistant-custom-component with a pinned frontend package, so future rebuilds can drift. [14] [15] [16]

## License and Reuse

The root license is **PolyForm Noncommercial 1.0.0**, with required author and commercial-contact notices. Noncommercial/personal purposes and the specifically listed organizations are covered according to its wording; ordinary commercial use must not be assumed permitted. Redistribution must carry the license terms/URL and required notices. This restriction means it should not be advertised as OSI-style unrestricted open source. [17]

Third-party notices identify romasku/tuya-zigbee-switch (MIT) and Telink Zigbee SDK 3.7.2.0 (Apache-2.0), whose terms remain applicable to their portions. The contribution agreement grants broad relicensing rights, including commercial/incompatible licenses; contributors retain ownership but should read it before submitting. These notices do not establish a reproducible mapping from the shipped binary to complete firmware source. No code was extracted for reuse in this review. [17] [18]

## Comparison

| Aspect | Ripple | Conventional Zigbee PIR / dedicated mmWave | ESPectre |
|--------|--------|-------------------------------------------|----------|
| Main approach | RSSI changes between compatible reflashed routers | Dedicated motion/presence hardware | Wi-Fi CSI sensing on ESP32 |
| Hardware tradeoff | Can reuse suitable switches; firmware-conversion risk | Purchase/place sensors; avoids reflashing mains switches | Requires suitable ESP32 hardware and Wi-Fi setup |
| Still occupants | README explicitly relies on hold timers | PIR also misses still people; appropriate mmWave devices target finer motion | Different radio signal/method; do not assume equivalent performance |
| Best fit | Noncommercial experimentation with supported devices | Prefer for routine automation when predictable behavior matters | Alternative radio-sensing research path |

These are architectural comparisons, not a head-to-head accuracy benchmark. Home Assistant's ZHA documentation provides context for conventional supported devices; ESPectre's public repository identifies its CSI approach. Neither was installed or fully audited here. Ripple's README also names Philips Hue MotionAware, but its commercial eligibility and performance were not independently checked, so it is not treated as a validated recommendation. [1] [19] [20]

## Self-Hosting Notes

This is an integration inside an existing HA installation, not a standalone Docker service. The README requires HA 2025.1+ and either a configured ZHA custom-quirk path or Z2M 2.x with HA MQTT and external JavaScript enabled. Its newer Marketplace installation instructions were not live-verified. [1]

For a cautious evaluation: back up HA and Z2M state, verify the exact physical board/chip, begin with writes off and protected devices configured, review generated-code and broker permissions, then use a noncritical supported device. Keep an independent motion sensor as a reference and measure false triggers, misses, still-occupant timeout and interference before using occupancy to control anything consequential. Resolve commercial rights and obtain a credible device-recovery plan before wider rollout. Do not infer that a firmware filename, board-table match or successful OTA progress bar proves safety.

## Verification Record and Limitations

Anonymous public acquisition succeeded; canonical owner/repository normalization removed the submitted .git suffix. No prior matching review/index entry was found, so this is a new review. Exact main/tag agreement was checked, along with public latest-release metadata. The reviewed binary's SHA-256 is `ce8f9bb57c27efa12226f5fd70e17b63f38038ba353ec9a1549b6d823c89d858`; that is an identification hash, not a security endorsement.

Inspection covered the named host modules, test scaffolding, notices and binary packaging. Source code was not executed, and no firmware disassembly, radio capture, vulnerability exploitation, dependency audit service, hardware testing or account interaction was performed. Absence-of-telemetry/CI/source findings are scoped to this revision and the public metadata inspected, not all historical or external projects. Artifact validation checks markup, citations, template integrity and public-only content; it does not test Ripple itself.

## Evidence

All repository file citations below are pinned to the reviewed commit.

[1]: https://github.com/simoncirstoiu/Ripple/blob/dbbadb1b8eb377d4d903e54efe6548dd0f1733ab/README.md
[2]: https://github.com/simoncirstoiu/Ripple/blob/dbbadb1b8eb377d4d903e54efe6548dd0f1733ab/custom_components/ripple_presence/manifest.json
[3]: https://github.com/simoncirstoiu/Ripple/tree/dbbadb1b8eb377d4d903e54efe6548dd0f1733ab/custom_components/ripple_presence/firmware
[4]: https://github.com/simoncirstoiu/Ripple/blob/dbbadb1b8eb377d4d903e54efe6548dd0f1733ab/custom_components/ripple_presence/zigbee.py
[5]: https://github.com/simoncirstoiu/Ripple/blob/dbbadb1b8eb377d4d903e54efe6548dd0f1733ab/custom_components/ripple_presence/flasher.py
[6]: https://github.com/simoncirstoiu/Ripple/blob/dbbadb1b8eb377d4d903e54efe6548dd0f1733ab/custom_components/ripple_presence/v5.py
[7]: https://github.com/simoncirstoiu/Ripple/blob/dbbadb1b8eb377d4d903e54efe6548dd0f1733ab/custom_components/ripple_presence/runtime.py
[8]: https://github.com/simoncirstoiu/Ripple/blob/dbbadb1b8eb377d4d903e54efe6548dd0f1733ab/custom_components/ripple_presence/z2mcore.py
[9]: https://github.com/simoncirstoiu/Ripple/blob/dbbadb1b8eb377d4d903e54efe6548dd0f1733ab/custom_components/ripple_presence/websocket.py
[10]: https://github.com/simoncirstoiu/Ripple/blob/dbbadb1b8eb377d4d903e54efe6548dd0f1733ab/custom_components/ripple_presence/__init__.py
[11]: https://github.com/simoncirstoiu/Ripple/blob/dbbadb1b8eb377d4d903e54efe6548dd0f1733ab/custom_components/ripple_presence/diagnostics.py
[12]: https://github.com/simoncirstoiu/Ripple/blob/dbbadb1b8eb377d4d903e54efe6548dd0f1733ab/custom_components/ripple_presence/z2m/converter.js.jinja
[13]: https://github.com/simoncirstoiu/Ripple/blob/dbbadb1b8eb377d4d903e54efe6548dd0f1733ab/custom_components/ripple_presence/store.py
[14]: https://github.com/simoncirstoiu/Ripple/tree/dbbadb1b8eb377d4d903e54efe6548dd0f1733ab/tests
[15]: https://github.com/simoncirstoiu/Ripple/blob/dbbadb1b8eb377d4d903e54efe6548dd0f1733ab/tests/Dockerfile
[16]: https://github.com/simoncirstoiu/Ripple/releases/tag/v1.0.41
[17]: https://github.com/simoncirstoiu/Ripple/blob/dbbadb1b8eb377d4d903e54efe6548dd0f1733ab/LICENSE
[18]: https://github.com/simoncirstoiu/Ripple/blob/dbbadb1b8eb377d4d903e54efe6548dd0f1733ab/THIRD_PARTY_NOTICES.md
[19]: https://www.home-assistant.io/integrations/zha/
[20]: https://github.com/francescopace/espectre

Additional pinned evidence: [history retention](https://github.com/simoncirstoiu/Ripple/blob/dbbadb1b8eb377d4d903e54efe6548dd0f1733ab/custom_components/ripple_presence/history.py), [board validation](https://github.com/simoncirstoiu/Ripple/blob/dbbadb1b8eb377d4d903e54efe6548dd0f1733ab/custom_components/ripple_presence/boards.py), [engine](https://github.com/simoncirstoiu/Ripple/blob/dbbadb1b8eb377d4d903e54efe6548dd0f1733ab/custom_components/ripple_presence/engine.py), [panel](https://github.com/simoncirstoiu/Ripple/blob/dbbadb1b8eb377d4d903e54efe6548dd0f1733ab/custom_components/ripple_presence/frontend/ripple-panel.js), [quirk installation](https://github.com/simoncirstoiu/Ripple/blob/dbbadb1b8eb377d4d903e54efe6548dd0f1733ab/custom_components/ripple_presence/quirk.py), [CLA](https://github.com/simoncirstoiu/Ripple/blob/dbbadb1b8eb377d4d903e54efe6548dd0f1733ab/CONTRIBUTING.md). Mutable metadata: [repository API](https://api.github.com/repos/simoncirstoiu/Ripple), [Actions runs](https://api.github.com/repos/simoncirstoiu/Ripple/actions/runs), [latest release](https://api.github.com/repos/simoncirstoiu/Ripple/releases/latest), retrieved 2026-11-27 UTC.

---

**Attribution:** Simon Cîrstoiu / simoncirstoiu/Ripple. PolyForm Noncommercial 1.0.0; third-party MIT and Apache-2.0 notices. Independent analysis, not an endorsement or legal advice.
