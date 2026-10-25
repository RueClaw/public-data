# OmarchyTV (piermark/omarchytv)

**Repo:** https://gitlab.com/piermark/omarchytv
**License:** MIT; bundled font and media exceptions
**Reviewed:** 2026-10-25 (UTC)
**Revision:** 19ef80351b91b3aef7b0e5b4cf9b3c44771d32c5; sampled repository-wide architecture, documentation, manifests, security boundaries and tests listed below.
**Verification:** Static source review only. No source execution, installs, device operations, deployments or paid calls.
**Stack:** Java / Android, Python, Gradle, Media3
**What it is:** Omarchy-style Android TV launcher with paired desktop control, MCP and an AI CLI bridge.

---

## Verdict

⚠️ **Interesting.** Interesting beta for a spare Android TV, not a turnkey privacy appliance. The launcher is real, but the new network and desktop-agent surfaces materially enlarge the trust boundary.

## What It Is

Omarchy-style Android TV launcher with paired desktop control, MCP and an AI CLI bridge. Five TV workspaces, theme and wallpaper control, app shelves, casting and a dedicated screensaver process are implemented in the Android launcher. The PC plugin adds telemetry and assistant bridging; a separate phone companion handles installation and control.

## Stack

| Layer | Technology |
|---|---|
| Implementation | Java / Android, Python, Gradle, Media3 |
| Runtime and deployment | See platform constraints below; no deployment was performed. |

## Key Features

### Functionality

Five TV workspaces, theme and wallpaper control, app shelves, casting and a dedicated screensaver process are implemented in the Android launcher. The PC plugin adds telemetry and assistant bridging; a separate phone companion handles installation and control.

### Boundaries and recovery

The watchdog records repeated crashes and tries to restore stock Home after three crashes in five minutes. It falls back to the system picker without the required local ADB setup; this is a conditional recovery mechanism, not guaranteed rollback.

### Integration and evidence

MCP is a bounded TV-control interface rather than a general TV shell. Its actual tool list includes tv_status, so README naming should not substitute for protocol discovery.

## Architecture

The native launcher separates main UI, web apps, screensaver and watchdog responsibilities. link/LinkServer.java implements a socket HTTP service, pairing, signed requests and MCP dispatch; LinkStore and LinkCrypto hold the pairing/authentication layer. Python PC tools wrap that service and authenticated desktop CLIs. This is an Android application and companion suite, not Linux or Hyprland installed on the TV.

## Security and Privacy

The source distinguishes signed requests and sealed events; do not equate all LAN traffic with encrypted transport. In LinkServer.authenticate, the MCP Bearer branch accepts a paired token before timestamp/nonce checks used by OTV1. A captured bearer is therefore reusable while valid; use a trusted isolated LAN, not public exposure. The nonce map also stops recording new entries at 20,000 until entries expire; this deserves saturation testing, not an unqualified replay-proof claim. AI bridge prompts reach the selected desktop CLI/provider; web apps retain cookies/storage. A signed-in CLI is not a guarantee of free or offline inference.

## Platform and Self-Hosting Notes

The current Gradle source declares minSdk 26, contradicting the README download row claiming 24. Treat Android 8/API 26 as the source-build floor until the release APK is independently inspected. Android/Google TV is the main target; webOS is explicitly testing, and Tizen/VIDAA browser surfaces are not native launcher parity. Preserve stock Home and a known recovery route before experimenting.

## Evidence, Tests and Limitations

JVM JUnit configuration, PC crypto/MCP/update tests and mobile ADB protocol tests are present. No tests, APK installation, signature verification or device recovery were run. No GitHub workflow directory was present; that alone does not establish absence of GitLab CI.

This is a sampled static assessment, not a certification or exhaustive security audit. Source claims about hardware, performance and operational recovery remain unverified unless explicitly identified otherwise. Dependency advisories and released-binary provenance were not audited.

## Maturity and Releases

README identifies 2.12.0-beta, dated 2026-10-25. GitLab API: created 2026-10-22, last activity 2026-10-25, 19 stars, 4 forks; open-issue count unavailable.

Popularity and issue counts are discovery signals, not evidence of safety or test success. Mutable metadata was retrieved anonymously on the review date; conclusions refer to the exact source revision above.

## Comparison

CleanYourTV is the simpler Android cleanup/launcher baseline; FLauncher is a narrower launcher alternative. An external HDMI computer avoids modifying the TV. Choose OmarchyTV specifically for its desktop-link aesthetic and integrations, not to root Tizen.

## License and Reuse

The root MIT terms permit reuse with copyright and permission notices retained. Bundled dependencies, fonts, media and external services retain their own terms; the stated exceptions must not be flattened into MIT-only redistribution. No upstream code was extracted in this review.

## Source Evidence

- [README.md](https://gitlab.com/piermark/omarchytv/-/blob/19ef80351b91b3aef7b0e5b4cf9b3c44771d32c5/README.md)
- [LICENSE](https://gitlab.com/piermark/omarchytv/-/blob/19ef80351b91b3aef7b0e5b4cf9b3c44771d32c5/LICENSE)
- [THIRD-PARTY.md](https://gitlab.com/piermark/omarchytv/-/blob/19ef80351b91b3aef7b0e5b4cf9b3c44771d32c5/THIRD-PARTY.md)
- [launcher/app/build.gradle](https://gitlab.com/piermark/omarchytv/-/blob/19ef80351b91b3aef7b0e5b4cf9b3c44771d32c5/launcher/app/build.gradle)
- [launcher/app/src/main/java/com/omarchytv/home/link/LinkServer.java](https://gitlab.com/piermark/omarchytv/-/blob/19ef80351b91b3aef7b0e5b4cf9b3c44771d32c5/launcher/app/src/main/java/com/omarchytv/home/link/LinkServer.java)
- [launcher/app/src/main/java/com/omarchytv/home/Watchdog.java](https://gitlab.com/piermark/omarchytv/-/blob/19ef80351b91b3aef7b0e5b4cf9b3c44771d32c5/launcher/app/src/main/java/com/omarchytv/home/Watchdog.java)
- [pc-plugin/omarchy-tv/tests/test_mcp.py](https://gitlab.com/piermark/omarchytv/-/blob/19ef80351b91b3aef7b0e5b4cf9b3c44771d32c5/pc-plugin/omarchy-tv/tests/test_mcp.py)

---

**Attribution:** piermark/omarchytv; MIT; bundled font and media exceptions. Analysis based only on public source.
