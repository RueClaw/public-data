# Omarchy Canary (shaggyrs6-netizen/omarchy-canary)

**Repo:** https://github.com/shaggyrs6-netizen/omarchy-canary
**License:** MIT; copyright 2026 Lee Shand. Preserve copyright and permission notices when reusing code.
**Reviewed:** 2026-11-22 (UTC)
**Revision:** 42709a6a65011ca413caf3ec5c23972905500ce4 — main and peeled v0.2.0; entire small source tree, especially Python helper, QML UI, manifest and tests.
**Verification:** Static review plus all 11 upstream synthetic unit tests passing in a network-isolated, secret-free Bubblewrap sandbox (0.543 seconds). No installation, live feed/probe requests, notifications, shell restart or desktop integration testing.
**Stack:** Python 3 standard library; Qt Quick/QML; Quickshell; Omarchy shell UI components; notify-send.
**What it is:** A third-party Omarchy bar widget aggregating public service incidents and provider links with optional desktop alerts. It is not an Omarchy prerelease channel, system updater or intrusion-detection canary.

## Verdict

⚠️ **Interesting — a thoughtfully defensive desktop convenience, not authoritative monitoring.** Explicit recovery semantics, bounded fetches and custom-feed address restrictions are stronger than a typical status-widget prototype. The project is extremely young, trusts code loaded into the desktop session, and has no durable notification delivery or documented full rollback/uninstall path. Consider a controlled evaluation only after checking shell compatibility; do not use it as the sole incident detector.

## What It Is

The repository belongs to **shaggyrs6-netizen**; the manifest names its author “Lee” and the MIT notice names Lee Shand. No inspected source establishes official Omarchy ownership, endorsement or affiliation. “Official” describes the upstream provider status feeds, not the plugin's institutional status. GitHub reports a public non-fork repository. [E1–E3]

Opening the panel checks fifteen built-in service feeds, including GitHub, OpenAI, Claude, Cloudflare and cloud-provider notices. A country directory provides links rather than scraping account-specific ISP/power outages. Bundled local suggestions cover the US, UK, Canada and Australia; other countries can use global feeds and custom entries. Unsupported custom services become browser shortcuts, not monitored services. [E1, E4]

Favourites, alert subscriptions and polling are separate controls. Background polling and reachability probes default off; subscribing controls alerts and the bar indicator, **not which built-in feeds are fetched**. All fifteen built-ins are due on an ordinary refresh, subject to backoff. Opening the panel therefore causes third-party network traffic even without subscriptions. [E4, E5]

## Stack

| Layer | Technology and boundary |
|---|---|
| Desktop | BarWidget.qml loads Dashboard.qml into the existing Omarchy/Quickshell session |
| Worker | Argument-array invocation of python3 outages.py; JSON stdout and diagnostic stderr |
| Networking | urllib for built-ins; explicit TLS sockets/http.client for custom Statuspage feeds |
| Persistence | JSON state, advisory flock, same-directory temporary file plus os.replace |
| Alerts | notify-send argument array to the local desktop notification service |
| Auth | No plugin account, API key, inbound HTTP server or application login; desktop-session trust |

## Key Features and Claim Checks

### Conservative incident state

The first successful feed check establishes a quiet baseline. New incidents, increased severity/component scope and explicit resolutions can notify. Missing incidents remain cached rather than turning into false recoveries; AWS/Azure are notices, not health assertions. UI freshness uses a fifteen-minute window and distinguishes unknown status and cached incidents. A green indicator means no reported active incidents among selected, currently known feeds—not proven uptime. Amber/red count affected selected services, not outage severity. Fixtures support the lifecycle and failure-retention claims. [E4–E6]

### Bounded failure isolation

Fetch bodies are limited to 4 MiB. Built-in requests have five-second socket timeouts; the refresh batch has an eighteen-second deadline with daemon worker threads. Failed feeds back off from five to thirty minutes, retaining prior incidents. Custom-feed detection has a seven-second outer deadline. These are useful bounds, but there is no global custom-service count or worker-pool limit: many selected custom entries spawn many concurrent threads. [E4]

### Alerts are best-effort, not a queue

Quiet hours (22:00–08:00) and one-hour snooze suppress notifications while state still advances. There is no later replay of those transitions. State is saved before notify-send, whose ordinary nonzero result is ignored; a failed notification therefore is not retried. The test-alert path does report success/failure and intentionally bypasses pause/subscription settings. This is acceptable convenience behavior, not guaranteed alert delivery. [E4, E6]

## Architecture

BarWidget draws the bird and loads Dashboard. Dashboard holds the view model, navigation and timers, delegates work to one Python process at a time, and parses its JSON output. Background polling runs every five minutes only while the bar exists. With background disabled, an open panel's minute timer requests visits, while Python normally rate-limits refreshes to 270 seconds. A startup poll loads/saves local state even when background network work is disabled. [E4, E5]

The helper normalizes RSS, Statuspage, Google and Slack incidents into one schema, merges against prior state, computes changes and renders a JSON view. State locking waits at most two seconds; network work can hold that lock for longer, so competing instances can fail rather than wait indefinitely. QML's busy guard drops overlapping requested actions rather than queuing them. Local Quickshell IPC exposes status/indicator JSON and show/hide/preview functions; this is desktop IPC, not an internet service or separately authenticated API. [E4, E5]

## Security, Privacy and Supply Chain

- **Good URL boundary for custom feeds:** only recognized HTTPS Statuspage paths on port 443 qualify. DNS answers must all be public; private/mixed answers, multicast and disallowed IPv6 ranges are rejected. The checked address is connected directly, preserving hostname TLS verification without a second DNS lookup. No proxies or redirects are used on this path. Tests verify private/mixed-address rejection, not the complete real TLS flow. [E4, E6]
- **Different browser boundary:** custom shortcut validation allows HTTP/HTTPS, including private destinations, query strings and fragments; credentials in URL authority and other schemes are rejected. These shortcuts open only on user action through the default browser, where browser cookies, login and tracking rules apply. Do not paste sensitive signed/query-token URLs: the URL is retained in local state. Backend public-address restrictions do not make browser navigation safe or private. [E4, E5]
- **Built-ins differ:** their fixed HTTPS URLs use urllib, disallow redirects and retain standard certificate checks, but inherit normal proxy behavior; the custom-feed DNS/proxy policy does not cover this fetch path. Optional Google/Cloudflare connectivity requests reveal the normal client IP/request metadata, as do provider feed requests. A successful feed also suffices for the refresh's “reachable” result; this is not a comprehensive connectivity diagnosis. [E4]
- **No observed telemetry collector or credential store:** local state contains country, favourites, custom names/URLs, alert settings and cached public incidents. Providers receive requests; clicked provider pages may separately require accounts or location information. Diagnostics emit feed ID and error type/HTTP code rather than response bodies. Notifications can expose service names and incident transitions to the desktop notification history. [E4–E6]
- **Execution trust remains broad:** QML and Python run as the desktop user, without a repository-defined sandbox or permission manifest. There is no observed sudo, system-service installation, shell-interpolated command construction or downloaded executable execution in this tree. Plain-text QML rendering and label cleaning reduce markup injection; subprocess arguments are arrays, with notify-send's option terminator. Installing/updating the plugin still trusts repository code with session access. [E2, E4, E5]
- **Small dependency surface, not reproducible supply-chain proof:** Python uses only its standard library and there are no pip/npm dependencies or lockfiles. Host Python, Qt/Quickshell, Omarchy components and notify-send determine runtime compatibility. v0.2.0 has no uploaded release assets; no CI workflow, SBOM, build attestation or project-enforced signature verification was found. Tag/commit identity was checked, not cryptographic signer authenticity. [E2, E7]

## Installation, Update, Persistence and Recovery

The README delegates installation/enabling and Git-managed updates to Omarchy's plugin manager using ID **shaggyrs6.service-outages**. Its advertised commands add/enable this repository, update that ID, optionally restart the shell for refreshed controls, or disable the widget. **None was executed.** The plugin-manager implementation is outside this review: exact manager config/file changes and update-ref behavior are not established by this repository. No independent installer, package hook, cron job or systemd unit appears in the source tree. [E1, E2]

The helper creates **$XDG_STATE_HOME/omarchy-service-outages**, falling back to **~/.local/state/omarchy-service-outages**, with state.json and a lock file. A newly created state directory requests mode 0700; temporary state files use tempfile's restrictive defaults. Existing directory modes are not repaired. Same-directory replacement protects the old JSON against a failed serialization, which the tests verify; it is not fsync-backed power-loss durability, versioned backup or encryption. [E4, E6]

Malformed state JSON is not quarantined or automatically repaired: loading it raises an error. There is no schema migration/version, previous-state copy or code rollback mechanism. Updates reuse the state; backward compatibility is unproven. A careful operator should keep a separate state backup and known-good source revision before evaluation. Recovery may require disabling the widget, restoring a validated state backup or starting a new state directory, losing preferences/history. This is operational advice, not a tested recovery procedure. [E4]

Disabling stops widget operation but is not documented as deleting state or removing plugin files. Removing a custom entry explicitly clears its subscription and incident history; unpinning does not. The README does not supply a complete uninstall/data-purge or release-rollback procedure. Confirm those steps in the installed Omarchy manager before adoption rather than assuming disable is uninstall. [E1, E4]

## Maturity and Verification

Public GitHub metadata retrieved 2026-11-22: created 2026-11-20, last push 2026-11-21T11:45:52Z, 5 stars, 0 forks and 0 open issues. These are snapshot activity signals, not quality evidence. The only release returned was v0.2.0, published 2026-11-21T11:46:08Z; its annotated tag peels to the reviewed SHA. Its release notes claim eleven tests and Omarchy plugin validation; we reproduced the eleven Python tests, **not** plugin validation or screenshot behavior. [E3, E7]

The suite covers parser/lifecycle behavior, missing incidents, bad and stalled feeds, bounded subprocess exit, failed serialization, custom entry persistence/removal, private-DNS rejection and mocked notification arguments. It ran with an empty environment, read-only source/system runtime, isolated temporary storage and no network or host home/session sockets. No source installation occurred. QML rendering, IPC access, supported Omarchy version, TLS endpoint compatibility, provider feed accuracy, notification delivery, update/uninstall and long-running polling remain unverified. No CI configuration or QML integration tests were present in the reviewed tree. [E6]

## Comparison

| Option | Best fit | Tradeoff relative to Canary |
|---|---|---|
| Provider status-page subscriptions or RSS reader | Follow selected upstream announcements | Less desktop integration, but avoids loading a plugin into the shell; provider notice latency remains |
| [Uptime Kuma](https://github.com/louislam/uptime-kuma) | Independently probe endpoints you operate | Separate hosted monitoring and maintenance; detects your checks rather than just aggregating provider notices |
| [Gatus](https://github.com/TwiN/gatus) | Declarative endpoint conditions and monitoring | Service configuration and hosting overhead; not a ready-made Omarchy provider directory |

These are scope comparisons, not comparative benchmarks or fresh audits of the alternatives. Canary's differentiator is a small, native-feeling status directory with cautious incident caching, not comprehensive monitoring. Prefer provider subscriptions for minimal desktop trust; use an independent monitor when actual endpoint availability matters.

## Evidence

All code citations below are pinned to the reviewed revision. Public accessibility was checked without account authentication; canonical URL and existing review/index entries were checked for duplication.

- **E1:** [README and advertised operational behavior](https://github.com/shaggyrs6-netizen/omarchy-canary/blob/42709a6a65011ca413caf3ec5c23972905500ce4/README.md).
- **E2:** [Manifest](https://github.com/shaggyrs6-netizen/omarchy-canary/blob/42709a6a65011ca413caf3ec5c23972905500ce4/manifest.json) and [MIT license](https://github.com/shaggyrs6-netizen/omarchy-canary/blob/42709a6a65011ca413caf3ec5c23972905500ce4/LICENSE).
- **E3:** [Public repository metadata](https://api.github.com/repos/shaggyrs6-netizen/omarchy-canary) (mutable snapshot).
- **E4:** [Python helper](https://github.com/shaggyrs6-netizen/omarchy-canary/blob/42709a6a65011ca413caf3ec5c23972905500ce4/outages.py): SOURCES, fetch, service_url, fetch_custom_feed, completed_checks, merge, refresh, save and main.
- **E5:** [Dashboard](https://github.com/shaggyrs6-netizen/omarchy-canary/blob/42709a6a65011ca413caf3ec5c23972905500ce4/Dashboard.qml) and [bar widget](https://github.com/shaggyrs6-netizen/omarchy-canary/blob/42709a6a65011ca413caf3ec5c23972905500ce4/BarWidget.qml).
- **E6:** [Eleven fixture tests](https://github.com/shaggyrs6-netizen/omarchy-canary/blob/42709a6a65011ca413caf3ec5c23972905500ce4/tests/test_outages.py).
- **E7:** [v0.2.0 release](https://github.com/shaggyrs6-netizen/omarchy-canary/releases/tag/v0.2.0) (author claims) and [reviewed tree](https://github.com/shaggyrs6-netizen/omarchy-canary/tree/42709a6a65011ca413caf3ec5c23972905500ce4).

---

**Attribution:** shaggyrs6-netizen/omarchy-canary; manifest author Lee; copyright Lee Shand; MIT. Independent review; no official affiliation implied.
