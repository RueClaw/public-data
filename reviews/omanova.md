# OMANOVA (shaggyrs6-netizen/omanova)

**Repo:** https://github.com/shaggyrs6-netizen/omanova
**License:** MIT for original code/documentation; bundled COBS comet observations retain CC BY-NC-SA 4.0, and other provider data retain their terms.
**Reviewed:** 2026-11-10 (UTC)
**Revision:** ab4d12d3ef06c62d223deffb6a6b86688e0b0fbf, tag v0.1.1; whole-repository static review, focused on runtime, predictions, feeds, persistence, launchers and tests.
**Verification:** Source and public GitHub metadata inspected; no source execution, dependency installation, ephemeris download, GUI smoke test or live-feed probe. Tests were not run.
**Stack:** QML / Qt Quick / Quickshell, Bash, Python, Skyfield, SGP4, NumPy, jplephem, certifi; JPL DE440s ephemeris.
**What it is:** A local astronomy Observatory and satellite-pass bar widget for Omarchy Quattro—not a general desktop distribution, installer or AI assistant.

## Verdict

⚠️ **Interesting: thoughtful astronomy integration, not yet a low-maintenance deployment.** The implementation separates orbital geometry from actual visibility, exposes stale/uncertain inputs, and offers useful local-first safeguards. Its one-day-old public history, exact desktop coupling, manually supervised worker, short-lived catalogues and split plugin/runtime lifecycle make it better suited to an interested Omarchy user willing to maintain it than an unattended observing system.

## What It Is

OMANOVA is the renamed Omasky project. The plugin ID now ends in `omanova`; runtime state and environment variables intentionally retain `omasky` / `OMASKY_` names. The bar opens a standalone Observatory, with a compact panel fallback. Users enter a location manually; this is not a geolocation service.

It combines ISS/Tiangong predictions, weather context, orbit tracks, Moon/planet calculations, meteor/eclipses/comet views, launch schedules, experimental plume/Starlink screens, NOAA aurora guidance, a regional dark-site catalogue, and a local observing log. Breadth does not imply uniform validation: the station predictor has a specific independent trajectory regression; many other views are approximate geometry or dated source snapshots.

## Stack

| Layer | Implementation |
|---|---|
| Desktop | Omarchy Quattro, Hyprland, Wayland, Qt Quick and Quickshell |
| UI bridge | QML FileView watches JSON; Process invokes Python with argument arrays |
| Computation | Skyfield 1.55, sgp4 2.27, numpy 2.5.4, jplephem 2.24 |
| Transport | Python urllib with certifi 2026.10.23; bounded HTTPS reads, no redirects |
| Persistence | Private JSON files, advisory file locks, atomic replacement; no database/server |
| Setup | Bash, Git, curl, uv, system Python 3.12+ with compatible wheels; jq/flock and optional notify-send |

## Key Features and Evidence

### Geometry is not a sighting guarantee

[astronomy.py](https://github.com/shaggyrs6-netizen/omanova/blob/ab4d12d3ef06c62d223deffb6a6b86688e0b0fbf/astronomy.py) predicts passes locally, samples approximately every two seconds, and requires a sunlit station, at least 10° elevation and Sun altitude no higher than −6°. Windows must last at least ten seconds. Elements older than 72 hours at the pass are labelled stale and kept off the bar; over seven days are excluded. [conditions.py](https://github.com/shaggyrs6-netizen/omanova/blob/ab4d12d3ef06c62d223deffb6a6b86688e0b0fbf/conditions.py) grades weather over the viewing interval and excludes poor conditions from bar candidates. Terrain, brightness and real cloud breaks are not modelled.

### Useful restraint in speculative views

[plumes.py](https://github.com/shaggyrs6-netizen/omanova/blob/ab4d12d3ef06c62d223deffb6a6b86688e0b0fbf/observatory/plumes/plumes.py) requires fresh schedule data, a sufficiently precise go-for-launch time and matching sourced timed ascent samples. No real verified trajectory file is bundled, so this is infrastructure for a future capability, not a working catalogue of guaranteed plume sightings. Starlink trains test compact group geometry rather than apparent magnitude; NOAA sightlines are not a calibrated local aurora probability.

The comet positions expire at 2026-11-17 00:00 UTC. Meteor entries cover a limited November 2026–April 2027 selection; dark-sky sites are five regional examples, not a worldwide location-aware directory. These constraints are stated in the [README](https://github.com/shaggyrs6-netizen/omanova/blob/ab4d12d3ef06c62d223deffb6a6b86688e0b0fbf/README.md).

### Privacy controls are per feed, not a global offline switch

Orbital downloads, weather and notifications default off. Weather additionally requires orbital/network refresh enabled and transmits coordinates rounded to two decimals to Open-Meteo. CelesTrak calls do not include observer coordinates. But the live Observatory fetches Launch Library 2 when opened and the aurora view fetches NOAA separately: turning off orbital/weather switches does **not** make the live UI fully offline. Providers still see ordinary connection metadata such as the public IP. Clicking source/map/webcast links opens an external browser.

Evidence: [worker.py](https://github.com/shaggyrs6-netizen/omanova/blob/ab4d12d3ef06c62d223deffb6a6b86688e0b0fbf/worker.py), [preview-observatory](https://github.com/shaggyrs6-netizen/omanova/blob/ab4d12d3ef06c62d223deffb6a6b86688e0b0fbf/preview-observatory), [aurora.py](https://github.com/shaggyrs6-netizen/omanova/blob/ab4d12d3ef06c62d223deffb6a6b86688e0b0fbf/observatory/aurora/aurora.py).

## Architecture

The small bar plugin is only one component. [SkyState.qml](https://github.com/shaggyrs6-netizen/omanova/blob/ab4d12d3ef06c62d223deffb6a6b86688e0b0fbf/SkyState.qml) watches the snapshot, retains the last parsable version and invokes a separate Python runtime for settings changes. The runtime is a permanent checkout reached via a data-directory symlink. [worker.py](https://github.com/shaggyrs6-netizen/omanova/blob/ab4d12d3ef06c62d223deffb6a6b86688e0b0fbf/worker.py) serializes refreshes/settings mutations under flock, computes predictions, writes snapshots and, in watch mode, checks alerts once per minute.

Standalone QML pages launch focused Python modules on demand. Live launch/weather/orbit state is split between the user data directory and checkout-local .preview caches; some page outputs go into a freshly created temporary runtime directory. This modularity makes fixture previews convenient, but cache ownership and lifecycle are more complex than a single packaged application.

The worker downloads at most once per station query per two hours; HTTP errors can latch an orbital source into a blocked state until explicitly resumed. Cached data survive fetch failures and freshness is surfaced. The UI's live snapshot staleness indicator does not restart a failed worker.

## Security and Privacy Boundaries

- **Same-user desktop code, not sandboxed plugin code.** QML can spawn processes, the launcher invokes Bash and Hyprland control commands, and Python reads/writes local files. No privileged daemon, network listener, authentication server, API key or account requirement was found in the reviewed paths. Installing the plugin/runtime grants normal user-process authority; a benign-looking manifest is not a permission sandbox.
- **Good transport limits.** The shared JSON fetcher uses certificate validation, a ten-second timeout, response-size limits and a redirect-denying handler. Network/cache data receive purpose-specific validation. User locations are range/finite-value checked; log input has length limits.
- **No obvious shell interpolation of user settings.** The UI uses process argument arrays; notifications use subprocess arguments with a separator and escaped body text. This is positive evidence, not a claim of a complete security audit.
- **Link validation is narrower than a public-destination policy.** Launch webcast normalization accepts credential-free HTTPS URLs with a hostname, but does not enforce a domain allowlist or reject private/loopback IPs. These links are user-clicked, not automatically fetched by that helper; still treat third-party links as untrusted. See [launches.py](https://github.com/shaggyrs6-netizen/omanova/blob/ab4d12d3ef06c62d223deffb6a6b86688e0b0fbf/observatory/events/launches.py).
- **Local does not mean encrypted.** Coordinates, notes and alert history are plaintext JSON. The CLI sets umask 077 and new state directories use mode 0700; it does not repair permissions on pre-existing directories. Backup/access discipline still matters.

## Installation, Updates and Removal

[setup-runtime](https://github.com/shaggyrs6-netizen/omanova/blob/ab4d12d3ef06c62d223deffb6a6b86688e0b0fbf/setup-runtime) creates a checkout-local virtualenv using system Python, installs exact package versions, downloads DE440s via HTTPS and verifies a hard-coded SHA-256. It refuses to replace an existing runtime symlink pointing elsewhere. It does not install a service, timer or autostart, and does not rewrite desktop configuration itself.

Important limits:

1. Version pins are not a hash-locked Python supply chain. The requirements have no wheel hashes, and compatible wheel availability was not checked. Setup can leave a partly prepared checkout after failure; it is not an atomic release transaction.
2. Runtime and plugin are installed separately. The README pins the runtime checkout to v0.1.1 but gives an unqualified repository URL to the plugin installer. Without validating Omarchy's installer resolution, matching plugin/runtime revisions cannot be assumed. Keep both aligned when updating.
3. Omarchy Quattro APIs, Quickshell and the launcher's Hyprland `hyprctl eval`/hl interface are specific dependencies, not a generic Linux desktop promise. No compatibility matrix or exact desktop version bounds were found.
4. A foreground watch process must remain alive for periodic updates and alerts. There is no supervisor/restart policy. Alerts also require fresh favourable weather, so merely enabling alerts without usable opted-in weather is insufficient.
5. The documented migration disables the old plugin, preserves the existing runtime location, changes to the renamed repository/tag and reruns setup. State intentionally remains under the old name. No general schema migration or automatic downgrade path was found.

Before a real upgrade, stop the worker, back up profiles/logs and relevant caches, record both revisions, and use a clean checkout. A source checkout rollback alone does not roll back the virtualenv, plugin copy or JSON schema. Recreate a matching dependency environment and restore data only deliberately. These are recommendations, not operations performed in this review.

Removal is documented as stopping the worker/window and removing the plugin; it deliberately keeps user data. Retiring the runtime additionally requires verifying and unlinking its pointer and moving the checkout. Checkout-local caches and temporary runtime directories are separate from retained logs. The preview launcher creates a temporary runtime directory and execs Quickshell without an explicit cleanup trap; cleanup is not a complete uninstall workflow. See [README](https://github.com/shaggyrs6-netizen/omanova/blob/ab4d12d3ef06c62d223deffb6a6b86688e0b0fbf/README.md) and [preview-observatory](https://github.com/shaggyrs6-netizen/omanova/blob/ab4d12d3ef06c62d223deffb6a6b86688e0b0fbf/preview-observatory).

## Persistence and Recovery

Writes use a temporary file, flush/fsync and atomic replacement under locks. This reduces partial JSON reads and concurrent edits, but the parent directory is not fsynced and no backup/version history is provided. Settings/cache reads can fall back to defaults on malformed JSON; malformed persisted settings may therefore appear lost or be replaced by later edits. Existing observing logs instead reject invalid formats rather than silently reinitializing them; the entire log is loaded and rewritten on append, without a total-entry cap. See [observing_log.py](https://github.com/shaggyrs6-netizen/omanova/blob/ab4d12d3ef06c62d223deffb6a6b86688e0b0fbf/observatory/observing-log/observing_log.py).

The notification ledger is updated after successful notify-send, so a crash between delivery and ledger persistence can cause a duplicate: this is best-effort deduplication, not exactly-once delivery. A deleted ledger similarly loses deduplication history. Orbital HTTP blocks need explicit recovery; optional watchlist/train recovery currently involves closing the UI and backing up/moving the relevant cache.

## Tests, Maturity and Claims

There are 43 test methods across 14 Python test files. [test_astronomy.py](https://github.com/shaggyrs6-netizen/omanova/blob/ab4d12d3ef06c62d223deffb6a6b86688e0b0fbf/tests/test_astronomy.py) compares one ISS pass against interpolated NASA/JSC trajectory samples with 15-second timing, 1° elevation and 3° bearing tolerances. That is stronger evidence than comparing only against the same propagator. The Tiangong comparison uses a dense scan of the same published elements/model, so it is a consistency check, not an independent orbit validation. Other tests cover opt-in/rate limits, stale inputs, weather boundaries, log persistence and feature fixtures.

The README reports Wayland and live-session smoke tests; those are author claims, not reproduced here. No CI workflow, dependency lock with hashes, or automated GUI compatibility coverage was found in the snapshot. Unit tests need the external DE440s asset and installed dependencies. None were run during this static review.

Public GitHub metadata checked on 2026-11-10: repository created 2026-11-09, last pushed 2026-11-09, 4 stars, 1 fork, 0 open issues. Tags v0.1.0 and v0.1.1 exist; v0.1.1 resolves to the reviewed SHA and its release was published 2026-11-09. These are maturity context, not quality guarantees. Only a shallow checkout was acquired; earlier development history and release binaries were not audited.

## License and Reuse

[LICENSE](https://github.com/shaggyrs6-netizen/omanova/blob/ab4d12d3ef06c62d223deffb6a6b86688e0b0fbf/LICENSE) is MIT, copyright 2026 Lee Shand: preserve its notice in code reuse. [DATA-SOURCES.md](https://github.com/shaggyrs6-netizen/omanova/blob/ab4d12d3ef06c62d223deffb6a6b86688e0b0fbf/DATA-SOURCES.md) explicitly separates provider rights: the COBS-derived catalogue includes CC BY-NC-SA 4.0 data, and Open-Meteo's free hosted API is non-commercial. The whole repository is therefore not an unrestricted MIT-only data bundle. Natural Earth is identified as public domain; other sources retain their usage/attribution obligations. No source code or datasets were extracted for reuse in this review.

## Comparison

| Alternative | Better fit | OMANOVA distinction |
|---|---|---|
| [Stellarium](https://stellarium.org/) | Broad interactive planetarium and sky exploration | Native Omarchy bar, local alerts and unified small dashboards |
| [Gpredict](https://oz9aec.dk/gpredict/) | Dedicated satellite tracking on supported desktops | Station/weather integration plus Moon/events/log views |
| [Skyfield](https://rhodesmill.org/skyfield/) | Custom, scriptable numerical astronomy | Ready-made QML presentation and operational glue |
| [NASA Spot the Station](https://www.nasa.gov/spot-the-station/) | Simple authoritative ISS sighting information without maintaining this runtime | Local multi-source dashboard and broader celestial scope |

These are scope comparisons, not comparative benchmarks or fresh audits of those alternatives.

## Bottom Line

A promising specialist desktop project with unusually explicit uncertainty handling and fixture provenance. Evaluate it in an isolated matching Omarchy environment if the integrated experience matters. Prefer a dedicated mature tool or authoritative web source when broad platform support, maintenance-free operation or stronger independent validation matters more. Do not rely on it for solar-viewing safety, guaranteed visibility or unattended alerts.

**Attribution:** Lee Shand / shaggyrs6-netizen/omanova; original code MIT, provider data separately licensed.
