# Cheyenne (MJCruickshank/cheyenne)

**Repo:** https://github.com/MJCruickshank/cheyenne
**License:** No project license specified. Public visibility is not a general grant to reuse or redistribute the original code; obtain permission. Bundled dependencies have separate licenses.
**Reviewed:** 2026-11-28 (UTC)
**Revision:** b6074a52ddc38551086e06e332f24fb69c133dba (main); root README, all file inventory, Python service boundaries and persistence, browser analysis modules and vendored license notices. Targeted static inspection, not an exhaustive audit.
**Verification:** Anonymous GitHub metadata and HTTPS clone succeeded. Static source review only; no application, tests, installation, accounts, paid API calls, imagery downloads or live scientific probes were run.
**Stack:** Python standard-library HTTP service, SQLite, plain JavaScript ES modules, MapLibre GL JS, satellite.js; optional anthropic and websockets.
**What it is:** A local earth-observation investigation board combining satellite passes, imagery, maritime positions, fire detections and public Telegram reports, with exploratory image analyses and exportable cards.

---

## Verdict

⚠️ **Interesting — an unusually integrated investigation workbench, not a validated detection system.** The implementation goes well beyond a map demo: real data adapters, range readers, analysis code and retention logic are present. Keep it local and treat detections as leads; missing project licensing, absent shipped tests/CI, heuristic outputs and optional provider billing prevent a general deployment or reuse recommendation.

## What It Is

Cheyenne is aimed at open-source investigators following disasters, humanitarian crises and conflict. A browser globe combines orbital predictions with actual archive footprints, operator acquisition plans and optional live overlays. It distinguishes predicted imaging opportunities from confirmed tasking; commercial satellite visibility does not establish that an image will be taken. [README](https://github.com/MJCruickshank/cheyenne/blob/b6074a52ddc38551086e06e332f24fb69c133dba/README.md)

Its distinctive feature is composition: inspect the same place through optical/radar imagery, time-lapses, fire detections, recorded AIS and source-linked reports, then export imagery, annotations or a presentation card. The board does not independently corroborate Telegram reports or infer the cause of radar change. These are analytic aids, not evidence certification.

## Stack

| Layer | Tech |
|-------|------|
| Service | Python ThreadingHTTPServer / SimpleHTTPRequestHandler; loopback by default |
| UI | Plain ES modules, MapLibre GL JS 5.24.1; no bundler |
| Orbits / exports | satellite.js 5.0.0; gifenc 1.0.3; browser canvases |
| Persistence | SQLite WAL for Intel and AIS archives; JSON/file caches; browser localStorage for annotations |
| Imagery | Planetary Computer, ASF/NISAR, Vantor/Maxar/Planet catalogues; browser COG reader |
| Optional packages | anthropic>=2.8 and websockets>=14, without a lockfile |
| Authentication | No board accounts/access control; optional upstream keys/tokens in environment |

Sources: [service](https://github.com/MJCruickshank/cheyenne/blob/b6074a52ddc38551086e06e332f24fb69c133dba/server.py#L791-L814), [requirements](https://github.com/MJCruickshank/cheyenne/blob/b6074a52ddc38551086e06e332f24fb69c133dba/requirements.txt), [boot wiring](https://github.com/MJCruickshank/cheyenne/blob/b6074a52ddc38551086e06e332f24fb69c133dba/web/js/main.js), [vendor notices](https://github.com/MJCruickshank/cheyenne/tree/b6074a52ddc38551086e06e332f24fb69c133dba/web/vendor/licenses).

## Key Features

### Satellite and imagery context, not just tracking

CelesTrak elements, ESA plans, scene catalogues and map layers are distinct inputs. Browser modules handle propagation, scene browsing and visualization; Python handles caching, selected proxy downloads and catalogue indexing. A three-hour TLE cache returns stale elements with an explicit stale flag when refresh fails instead of silently inventing fresh data. [tracker](https://github.com/MJCruickshank/cheyenne/blob/b6074a52ddc38551086e06e332f24fb69c133dba/web/js/tracker.js), [archive](https://github.com/MJCruickshank/cheyenne/blob/b6074a52ddc38551086e06e332f24fb69c133dba/web/js/archive.js), [TLE recovery](https://github.com/MJCruickshank/cheyenne/blob/b6074a52ddc38551086e06e332f24fb69c133dba/server.py#L137-L180)

### Ship detection with explicit uncertainty classes

The browser performs adaptive bright-target detection on Sentinel-1 radar over a land-masked area, then matches AIS and checks earlier passes for persistent objects. Classification distinguishes matched, dark candidate, near-shore, persistent and not-compared results. Crucially, the AIS archive tests recording sessions and at least two ships in a recording area within ±30 minutes; this avoids equating every empty feed with a dark vessel. However, the coverage test is area-level and checks the query centre, not reception at each detection. Sparse reception can still yield misleading confidence. Neither the README nor checked files supply a labelled validation benchmark. [detector and classification](https://github.com/MJCruickshank/cheyenne/blob/b6074a52ddc38551086e06e332f24fb69c133dba/web/js/ships.js#L453-L505), [coverage heuristic](https://github.com/MJCruickshank/cheyenne/blob/b6074a52ddc38551086e06e332f24fb69c133dba/aisarchive.py#L178-L200)

### Burn scars and coherent change are implemented, but not validated here

Burn mapping applies fixed dNBR thresholds with reflectance and scene-classification filters; it is not a trained classifier. NISAR uses a custom HDF5 range reader and browser windowed complex coherence, optionally comparing an earlier reference pair. The code contains the stated stable-coherence (0.5) and loss (0.3) thresholds. These are meaningful algorithms, not proof of accuracy: crop cycles, weather, water, alignment and scene selection matter, and coherence loss cannot identify a strike or its actor. The README explicitly acknowledges unvalidated ship/burn detections and limited NISAR product coverage. Reported timings and the Kyiv example remain author claims, not reproduced results. [burn rules](https://github.com/MJCruickshank/cheyenne/blob/b6074a52ddc38551086e06e332f24fb69c133dba/web/js/burns.js#L1-L45), [coherence implementation](https://github.com/MJCruickshank/cheyenne/blob/b6074a52ddc38551086e06e332f24fb69c133dba/web/js/ccd.js#L178-L195), [HDF5 scope](https://github.com/MJCruickshank/cheyenne/blob/b6074a52ddc38551086e06e332f24fb69c133dba/h5lite.py#L1-L15), [limitations](https://github.com/MJCruickshank/cheyenne/blob/b6074a52ddc38551086e06e332f24fb69c133dba/README.md#limitations)

### Geolocated reports with a real privacy and spending boundary

Intel scrapes public Telegram previews, extracts written coordinates or sends post text and channel titles to Anthropic, and resolves place names through GeoNames with model-coordinate fallback. Approximate placement is not independent corroboration. Untrusted post text is placed directly in model input; structured output limits shape, not factual manipulation or prompt injection. The reviewed call is extraction-only, with no model tools or shell capability. [resolution](https://github.com/MJCruickshank/cheyenne/blob/b6074a52ddc38551086e06e332f24fb69c133dba/intel.py#L485-L515), [model request](https://github.com/MJCruickshank/cheyenne/blob/b6074a52ddc38551086e06e332f24fb69c133dba/intel.py#L780-L855)

## Architecture

The repository has seven Python modules and a substantial browser module set rather than a framework-backed application. server.py routes local APIs, serves only the web directory, and coordinates Intel, AIS, NISAR and open-data managers. intel.py and ais.py own polling/feed threads and state; aisarchive.py stores positions; nisar.py uses h5lite.py to fetch only needed product chunks. The browser performs the heavy scientific and rendering work. Shared state/events and a small DOM helper connect modules. [service routes](https://github.com/MJCruickshank/cheyenne/blob/b6074a52ddc38551086e06e332f24fb69c133dba/server.py#L571-L788), [state](https://github.com/MJCruickshank/cheyenne/blob/b6074a52ddc38551086e06e332f24fb69c133dba/web/js/state.js), [COG reader](https://github.com/MJCruickshank/cheyenne/blob/b6074a52ddc38551086e06e332f24fb69c133dba/web/js/cog.js)

The dependency-light design is attractive for inspection and setup. Its tradeoff is ownership of custom TIFF/HDF5 handling, projections, remote API compatibility and image-processing correctness. HDF5 support is intentionally partial and NISAR only supports UTM grids. Large typed-array analyses and concurrent downloads can consume substantial RAM and bandwidth. In particular, NISAR allows 36 million pixels; if an upstream ignores Range, Remote._get reads the entire response before slicing it. A nominally small window is therefore not a strict network or memory bound. [NISAR transport](https://github.com/MJCruickshank/cheyenne/blob/b6074a52ddc38551086e06e332f24fb69c133dba/nisar.py#L30-L140), [window cap](https://github.com/MJCruickshank/cheyenne/blob/b6074a52ddc38551086e06e332f24fb69c133dba/nisar.py#L288-L342)

## Security, Permissions and Privacy

- **Local-only is an actual boundary.** The default bind is 127.0.0.1 and there are no user accounts. Do not expose --host 0.0.0.0 to untrusted users. same_site checks Fetch Metadata and Origin for Intel/AIS/NISAR APIs; POST requires JSON and a body below 16 KiB. These are useful browser protections, not authentication: non-browser clients can omit those headers. No explicit allowed-Host list is present, so this is not a complete DNS-rebinding defense. No exploit was attempted. [handler](https://github.com/MJCruickshank/cheyenne/blob/b6074a52ddc38551086e06e332f24fb69c133dba/server.py#L630-L734)
- **Not an unrestricted URL proxy.** Planetary Computer downloads constrain collection and identifier formats and check blob host suffixes; NISAR requires HTTPS, its specific ASF hostname and an .h5 path. Initial destination restrictions are good, but redirects remain trusted upstream behavior rather than a comprehensive redirect/destination policy. [asset signing](https://github.com/MJCruickshank/cheyenne/blob/b6074a52ddc38551086e06e332f24fb69c133dba/server.py#L556-L568), [NISAR product gate](https://github.com/MJCruickshank/cheyenne/blob/b6074a52ddc38551086e06e332f24fb69c133dba/nisar.py#L266-L286)
- **Keys remain server-side in the reviewed flows.** Optional feed keys and the Earthdata token are environment inputs; NISAR status exposes a boolean. First-hop bearer authorization is separated from signed redirect requests. This does not establish absence of leaks across all dependencies or logs. Avoid copying the README's shell-profile key-storage example into shared environments.
- **Local UI does not mean offline or private.** Upstream imagery, basemap, search and feed providers can observe requests, IP addresses and areas of interest. Telegram sees channel-page requests; Anthropic receives text/channel context when enabled. Browser annotations and local databases can themselves reveal an investigation; protect exports and backups. [data sources and privacy](https://github.com/MJCruickshank/cheyenne/blob/b6074a52ddc38551086e06e332f24fb69c133dba/README.md#data-sources), [annotations](https://github.com/MJCruickshank/cheyenne/blob/b6074a52ddc38551086e06e332f24fb69c133dba/web/js/annotations.js#L1-L29)
- **The daily Intel budget is a soft estimate, not a hard provider cap.** The code uses hard-coded prices and checks recorded spend before a batch. Costs are accounted after responses; recursive splits can make more calls without rechecking budget. Failed/retried requests may further diverge from local accounting. The configured model string claude-haiku-5-5, SDK requirements, prices and claimed per-post cost were not independently verified against the provider. Use a provider-side limit and keep Intel disabled until explicitly approved. [pricing constants](https://github.com/MJCruickshank/cheyenne/blob/b6074a52ddc38551086e06e332f24fb69c133dba/intel.py#L37-L43), [accounting and extraction](https://github.com/MJCruickshank/cheyenne/blob/b6074a52ddc38551086e06e332f24fb69c133dba/intel.py#L780-L895)

## Recovery and Operations

There are useful small-scale recovery patterns: atomic replacement of TLE and catalogue caches, AIS reconnect backoff, NISAR transient retries and signed-URL renewal, and resetting interrupted Intel busy rows to new at startup. SQLite uses WAL. These mechanisms improve resilience but are not a documented transactional job system or tested disaster-recovery plan. [AIS reconnect](https://github.com/MJCruickshank/cheyenne/blob/b6074a52ddc38551086e06e332f24fb69c133dba/ais.py#L140-L170), [catalogue cache](https://github.com/MJCruickshank/cheyenne/blob/b6074a52ddc38551086e06e332f24fb69c133dba/opendata.py), [Intel startup](https://github.com/MJCruickshank/cheyenne/blob/b6074a52ddc38551086e06e332f24fb69c133dba/intel.py#L542-L570), [NISAR retry](https://github.com/MJCruickshank/cheyenne/blob/b6074a52ddc38551086e06e332f24fb69c133dba/nisar.py#L84-L109)

The Active Processes bar is browser in-memory state with cancel callbacks, not a durable server queue. Reloading does not resume an analysis. Aborting a fetch does not guarantee the server stops an already-running NISAR computation. Annotations require explicit GeoJSON export to survive browser-storage loss. Preserve data with a consistent SQLite backup or a stopped-server backup; regenerable .cache files are different from investigation records. [jobs](https://github.com/MJCruickshank/cheyenne/blob/b6074a52ddc38551086e06e332f24fb69c133dba/web/js/jobs.js), [annotation export](https://github.com/MJCruickshank/cheyenne/blob/b6074a52ddc38551086e06e332f24fb69c133dba/web/js/annotations.js#L198-L235)

AIS recording areas deliberately keep feeds running without an open browser; Intel normally stops polling after three minutes without a watching client. Seven-day retention is not comprehensive erasure: AIS pruning deletes old positions and sessions but not the ships identity table or area definitions, and SQLite deletion does not itself guarantee physical byte removal. [archive storage/pruning](https://github.com/MJCruickshank/cheyenne/blob/b6074a52ddc38551086e06e332f24fb69c133dba/aisarchive.py#L32-L65), [pruning](https://github.com/MJCruickshank/cheyenne/blob/b6074a52ddc38551086e06e332f24fb69c133dba/aisarchive.py#L132-L156), [Intel activity](https://github.com/MJCruickshank/cheyenne/blob/b6074a52ddc38551086e06e332f24fb69c133dba/intel.py#L589-L620)

## Maturity, License and Evidence

Anonymous GitHub metadata on 2026-11-28 reported 62 stars, 2 forks and 0 open issues, with last push 2026-11-28T16:15:19Z. Releases and tags endpoints both returned empty arrays. The five commits returned by the recent-commits API show a sequence from initial board to AIS, Intel/time-lapse, share cards and the reviewed detection additions; this is activity evidence, not stability evidence. [repository metadata](https://api.github.com/repos/MJCruickshank/cheyenne), [releases](https://api.github.com/repos/MJCruickshank/cheyenne/releases), [tags](https://api.github.com/repos/MJCruickshank/cheyenne/tags)

The 73-file tracked inventory contains no shipped test suite or GitHub Actions workflow. No lockfile or project-level license was found. The README mentions NISAR checks on real and synthetic files, but those fixtures/results are not shipped as a reproducible suite. No CI result, scientific accuracy, model availability, live provider access, browser rendering, installation or performance is established by this review. Screenshots demonstrate the author's intended UI, not independently verified runtime behavior.

Third-party notices are present for MapLibre (BSD-3-Clause), satellite.js and gifenc (MIT), and two fonts (OFL-1.1). Those notices do not license Cheyenne's original code. Imagery and feed terms are separate: the README identifies non-commercial restrictions for Vantor/Planet releases and some AIS feeds, and warns that Pelyr disallows third-party proxying. Verify the actual dataset/service terms for each intended export; a card credit is not blanket reuse permission. No source components were extracted or redistributed in this review. [credits](https://github.com/MJCruickshank/cheyenne/blob/b6074a52ddc38551086e06e332f24fb69c133dba/README.md#credits-and-licences), [notices](https://github.com/MJCruickshank/cheyenne/tree/b6074a52ddc38551086e06e332f24fb69c133dba/web/vendor/licenses)

## Comparison

| Aspect | Cheyenne | Alternative |
|--------|----------|-------------|
| Integrated investigative context | One local board with AIS, reports and imagery | [QGIS](https://qgis.org/) offers a broader established GIS workflow, but assembling these live feeds takes work |
| Radar analysis | Lightweight browser heuristics and partial custom HDF5 reader | [ESA SNAP](https://step.esa.int/main/toolboxes/snap/) is the stronger starting point for dedicated SAR processing; heavier setup and less social/live-feed integration |
| Authoritative scene discovery | Convenient combined UI with bespoke adapters | [Copernicus Browser](https://browser.dataspace.copernicus.eu/) and [ASF Vertex](https://search.asf.alaska.edu/) keep discovery closer to the providers, without this combined investigation board |

These are workflow comparisons, not head-to-head benchmarks. Prefer existing GIS/SAR tools for reproducible quantitative analysis; Cheyenne's strongest niche is exploratory context gathering and presentation.

## Self-Hosting Notes

This is a desktop-local service, not a multi-tenant hosted platform. The documented core needs Python 3.9+ and a WebGL browser; optional extras require Python 3.10+. run.sh only selects an existing virtual environment or system Python. Keep the default loopback bind, use a dedicated environment, review upstream terms, and leave paid analysis off until approved. Budget disk, memory and bandwidth for large scenes, and export annotation/data records before upgrades. Validate known scenes, empty/sparse AIS coverage, imagery range failures and interrupted jobs before trusting operational outputs. [launcher](https://github.com/MJCruickshank/cheyenne/blob/b6074a52ddc38551086e06e332f24fb69c133dba/run.sh), [installation](https://github.com/MJCruickshank/cheyenne/blob/b6074a52ddc38551086e06e332f24fb69c133dba/README.md#installation)

**Priority improvements:** clarify original-code licensing; ship deterministic detector/coherence/parser fixtures and CI; pin dependencies; add hard request/billing limits and stronger host checks; document consistent backup, cancellation and retention semantics.

---

**Attribution:** MJCruickshank/cheyenne and its public contributors. No project license specified; dependency and data licenses remain separate. This review is independent analysis of public source, not an endorsement or scientific validation.
