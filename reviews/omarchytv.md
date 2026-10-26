# OmarchyTV (piermark/omarchytv)

**Repo:** https://github.com/piermark/omarchytv · synchronized GitLab: https://gitlab.com/piermark/omarchytv
**License:** MIT; bundled font and media exceptions
**Reviewed:** 2026-10-26 (UTC)
**Revision:** 9a18ce5fa188d9d1e88a6c4eee06658bbf6ed3dc; sampled repository-wide architecture, documentation, manifests, security boundaries and tests listed below.
**Verification:** Static source review only. No source execution, installs, device operations, deployments or paid calls.
**Stack:** Java / Android, Python, Gradle, Media3
**What it is:** Omarchy-style Android TV launcher with paired desktop control, MCP and an AI CLI bridge.

---

## Update Notes — 2026-10-26 (UTC)

Previous review: 2026-10-25 at 19ef80351b91b3aef7b0e5b4cf9b3c44771d32c5. Current GitHub source: 9a18ce5fa188d9d1e88a6c4eee06658bbf6ed3dc; GitLab HEAD: 08d8524e910e7242ff9c7e3b1febad8bd7991ff2.

- **Same project, synchronized repositories, not a replacement inferred from names.** README explicitly links both as official synchronized repositories; THIRD-PARTY.md attributes both to Marco Porro. The prior reviewed commit is an ancestor of GitHub HEAD. Both independently fetched heads have identical Git tree 5a474bbc7d0099dd5ac2cb8abb4ce8d871c19d32; GitHub HEAD merges GitLab history. Reuse this review rather than create a duplicate.
- **Material source changes, unchanged version label:** 28 files changed since the prior revision. PC pairing retries HTTP 429 once after a bounded 1–5 second Retry-After delay, with a new mock regression test. Android adds LAN HTTP web apps, configured clock locale, and Philips/TP Vision Live TV plus HDMI/tuner fallbacks. webOS adds Chrome-38-era polyfills, layout/remote-key compatibility and a fallback screensaver. These are source changes, not verified new release binaries.
- **Security boundary changed:** Android now permits cleartext app-wide and relies on application guards. MCP bearer authentication, nonce-cache saturation behavior and conditional watchdog recovery remain unchanged. The API 24/26 documentation discrepancy remains unresolved.
- **Verdict unchanged: ⚠️ Interesting.** Useful spare-device experimentation; not a production-hardened or universally recoverable TV replacement.

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

The watchdog records repeated crashes and tries to restore stock Home after three crashes in five minutes. It falls back to the system picker without the required local ADB setup; this is a conditional recovery mechanism, not guaranteed rollback. `Originale` hardcodes `com.google.android.tvlauncher`, requires authorized local network debugging, and does not verify the stock-home result after `toOriginal`; the picker itself can fail silently. This is not universal OEM recovery.

### Integration and evidence

MCP is a bounded TV-control interface rather than a general TV shell. Its actual tool list includes tv_status, so README naming should not substitute for protocol discovery.

## Architecture

The native launcher separates main UI, web apps, screensaver and watchdog responsibilities. link/LinkServer.java implements a socket HTTP service, pairing, signed requests and MCP dispatch; LinkStore and LinkCrypto hold the pairing/authentication layer. Python PC tools wrap that service and authenticated desktop CLIs. This is an Android application and companion suite, not Linux or Hyprland installed on the TV.

## Security and Privacy

The source distinguishes signed requests and sealed events; do not equate all LAN traffic with encrypted transport. In LinkServer.authenticate, the MCP Bearer branch accepts a paired token before timestamp/nonce checks used by OTV1. A captured bearer is therefore reusable while valid; use a trusted isolated LAN, not public exposure. The nonce map also stops recording new entries at 20,000 until entries expire; this deserves saturation testing, not an unqualified replay-proof claim. AI bridge prompts reach the selected desktop CLI/provider; web apps retain cookies/storage. A signed-in CLI is not a guarantee of free or offline inference.

The LAN-web-app change sets `cleartextTrafficPermitted="true"` in the base network-security configuration. `WebAppActivity.shouldInterceptRequest` rejects HTTP requests whose destination is not a literal private/link-local address; `CastViewActivity.fetch` also checks that gate and disables redirects for HTTP. This is application-level filtering, not Android enforcing a LAN-only policy. WebView redirect/subresource interception coverage needs device testing; do not treat the callback as a proven complete egress boundary. LAN HTTP remains unencrypted, including credentials entered into such apps.

## Platform and Self-Hosting Notes

The current Gradle source declares minSdk 26, contradicting the README download row claiming 24. Treat Android 8/API 26 as the source-build floor until the release APK is independently inspected. Android/Google TV is the main target; webOS is explicitly testing, and Tizen/VIDAA browser surfaces are not native launcher parity. Preserve stock Home and a known recovery route before experimenting.

## Evidence, Tests and Limitations

JVM JUnit configuration, PC crypto/MCP/update tests and mobile ADB protocol tests are present. No tests, APK installation, signature verification or device recovery were run. The current tree has GitHub issue templates but no GitHub workflows or root GitLab CI configuration. The new pairing regression was inspected, not executed.

This is a sampled static assessment, not a certification or exhaustive security audit. Source claims about hardware, performance and operational recovery remain unverified unless explicitly identified otherwise. Dependency advisories and released-binary provenance were not audited.

## Maturity and Releases

README still identifies 2.12.0-beta (versionCode 20), dated 2026-10-25. GitHub published the matching release on 2026-10-26; its tag resolves to `989e068d5134a3961ba7b8179ac2d8b2726c46c6`, not reviewed HEAD. Release metadata marks it non-prerelease despite the beta name. The webOS release remains 2.11.0-testing; its GitHub IPK asset is 1,024,436 bytes while the README row says 124 KB, another reason to inspect actual artifacts before installation. No release payload was downloaded or verified.

Anonymous GitHub API snapshot on 2026-10-26: created 2026-10-26, last push 2026-10-26, 105 stars, 8 forks, 2 open issues/PRs (combined API counter). This is the new GitHub hosting record, not the project creation date.

Popularity and issue counts are discovery signals, not evidence of safety or test success. Mutable metadata was retrieved anonymously on the review date; conclusions refer to the exact source revision above.

## Comparison

CleanYourTV is the simpler Android cleanup/launcher baseline; FLauncher is a narrower launcher alternative. An external HDMI computer avoids modifying the TV. Choose OmarchyTV specifically for its desktop-link aesthetic and integrations, not to root Tizen.

## License and Reuse

The root MIT terms permit reuse with copyright and permission notices retained. Bundled dependencies, fonts, media and external services retain their own terms; the stated exceptions must not be flattened into MIT-only redistribution. No upstream code was extracted in this review.

## Source Evidence

- [README.md](https://github.com/piermark/omarchytv/blob/9a18ce5fa188d9d1e88a6c4eee06658bbf6ed3dc/README.md)
- [LICENSE](https://github.com/piermark/omarchytv/blob/9a18ce5fa188d9d1e88a6c4eee06658bbf6ed3dc/LICENSE)
- [THIRD-PARTY.md](https://github.com/piermark/omarchytv/blob/9a18ce5fa188d9d1e88a6c4eee06658bbf6ed3dc/THIRD-PARTY.md)
- [launcher/app/build.gradle](https://github.com/piermark/omarchytv/blob/9a18ce5fa188d9d1e88a6c4eee06658bbf6ed3dc/launcher/app/build.gradle)
- [launcher/app/src/main/java/com/omarchytv/home/link/LinkServer.java](https://github.com/piermark/omarchytv/blob/9a18ce5fa188d9d1e88a6c4eee06658bbf6ed3dc/launcher/app/src/main/java/com/omarchytv/home/link/LinkServer.java)
- [launcher/app/src/main/java/com/omarchytv/home/Watchdog.java](https://github.com/piermark/omarchytv/blob/9a18ce5fa188d9d1e88a6c4eee06658bbf6ed3dc/launcher/app/src/main/java/com/omarchytv/home/Watchdog.java)
- [pc-plugin/omarchy-tv/tests/test_mcp.py](https://github.com/piermark/omarchytv/blob/9a18ce5fa188d9d1e88a6c4eee06658bbf6ed3dc/pc-plugin/omarchy-tv/tests/test_mcp.py)

- [launcher/app/src/main/java/com/omarchytv/home/Originale.java](https://github.com/piermark/omarchytv/blob/9a18ce5fa188d9d1e88a6c4eee06658bbf6ed3dc/launcher/app/src/main/java/com/omarchytv/home/Originale.java)
- [launcher/app/src/main/java/com/omarchytv/home/WebAppActivity.java](https://github.com/piermark/omarchytv/blob/9a18ce5fa188d9d1e88a6c4eee06658bbf6ed3dc/launcher/app/src/main/java/com/omarchytv/home/WebAppActivity.java)
- [launcher/app/src/main/java/com/omarchytv/home/CastViewActivity.java](https://github.com/piermark/omarchytv/blob/9a18ce5fa188d9d1e88a6c4eee06658bbf6ed3dc/launcher/app/src/main/java/com/omarchytv/home/CastViewActivity.java)
- [launcher/app/src/main/res/xml/network_security_config.xml](https://github.com/piermark/omarchytv/blob/9a18ce5fa188d9d1e88a6c4eee06658bbf6ed3dc/launcher/app/src/main/res/xml/network_security_config.xml)
- [launcher/app/src/main/java/com/omarchytv/home/MainActivity.java](https://github.com/piermark/omarchytv/blob/9a18ce5fa188d9d1e88a6c4eee06658bbf6ed3dc/launcher/app/src/main/java/com/omarchytv/home/MainActivity.java)
- [pc-plugin/omarchy-link/lib/omarchy_link/client.py](https://github.com/piermark/omarchytv/blob/9a18ce5fa188d9d1e88a6c4eee06658bbf6ed3dc/pc-plugin/omarchy-link/lib/omarchy_link/client.py)
- [pc-plugin/omarchy-link/tests/test_e2e.py](https://github.com/piermark/omarchytv/blob/9a18ce5fa188d9d1e88a6c4eee06658bbf6ed3dc/pc-plugin/omarchy-link/tests/test_e2e.py)
- [webos/app/compat.js](https://github.com/piermark/omarchytv/blob/9a18ce5fa188d9d1e88a6c4eee06658bbf6ed3dc/webos/app/compat.js)
- [Release metadata](https://api.github.com/repos/piermark/omarchytv/releases)

---

**Attribution:** piermark/omarchytv; MIT; bundled font and media exceptions. Analysis based only on public source.
