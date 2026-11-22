# OSIRIS (simplifaisoul/osiris)

**Repo:** https://github.com/simplifaisoul/osiris
**License:** MIT; preserve copyright and permission notice when reusing code. Bundled components and upstream data have separate terms.
**Reviewed:** 2026-11-22 (UTC)
**Revision:** c1342f27cfa1a6d0152a348d79e83af08fe44e08, public master snapshot; application, API handlers, OI libraries, representative feed/cache code, manifests, containers and CI. Not an exhaustive audit of every feed.
**Verification:** Static review only; no installation, application execution, live feed/scanner probes, model inference or independently run tests. Public GitHub metadata and upstream CI status checked anonymously.
**Stack:** TypeScript, Next.js 16.4.3, React 19.2.4, MapLibre GL 6.7.0, Node 22, Express, ONNX Runtime Web.
**What it is:** A map-centric OSINT situational-awareness dashboard combining public feeds, camera catalogs, reconnaissance lookups and bring-your-own-key AI assistance/forecasting—not a general-purpose agent operating system.

---

## Verdict

⚠️ **Interesting — substantial public-data visualization, not a drop-in governed intelligence platform.** OSIRIS has real feed adapters, caching, tests and a surprisingly developed forecast workflow. Its public-by-design APIs, link-readable forecasts, provider/analytics egress and process-local state need explicit operational boundaries; “production-grade,” “Palantir alternative” and calibrated forecasting should not be treated as independently established guarantees.

## What It Is

The project aggregates aviation, maritime, CCTV, seismic, weather, news, sanctions and cyber information into a WebGL map. Its strongest fit is exploratory situational awareness and public-source research. Coverage is heterogeneous: conflict severities are hand-curated, maritime includes static ports plus optional live AIS, and camera availability depends on external operators. A plotted point is not independent verification of an event or an identity. The README itself distinguishes curated conflict zones from geocoded news. [E1]

OI Assist turns natural-language requests into validated map actions and OSINT requests. OI Forecast researches a question, constructs a world model and actors, simulates several worlds, and asks a report model to synthesize an answer using source links, markets and a statistical baseline where available. It exposes REST/SSE and stateless Streamable HTTP MCP interfaces. This is implemented code, not just a conceptual README; its accuracy remains a separate question. [E2–E4]

## Stack

| Layer | Tech / implementation |
|-------|-----------------------|
| UI and mapping | Next.js App Router, React, TypeScript, Tailwind, MapLibre, Three.js, charting and HLS |
| API and feeds | Next route handlers; HTTP/RSS/WebSocket adapters; shared source cache |
| Entity enrichment | Express intel service, in-memory sanctions index and Wikidata lookups |
| AI | Fixed provider adapters; browser-held API keys passed through server; multi-world OI engine |
| Camera analysis | Bundled YOLOX-nano ONNX model, browser/server runtime and optional remote model identification |
| State | Process-local maps, browser storage, camera catalog disk snapshot; nginx tile-cache volume |
| Packaging | npm lockfiles, Node 22 Alpine multi-stage non-root image; Compose with app, nginx and intel |

See [E2], [E5–E7]. The top-level package version is 0.1.0, whereas the public releases API reports v5.0.0 (2026-09-28). This review is of the newer exact commit, not that release artifact.

## Key Features

### Broad feed integration with useful degradation handling

Adapters cover many camera regions, aviation, disasters and other public sources. Source caching deduplicates in-flight requests, caps keys and retains last-good data on errors. Camera catalogs merge partial results and retry missing regions with bounded backoff. Catalog snapshots use temporary-file-plus-rename writes and can seed the next process. These are useful engineering patterns, but stale-on-error improves availability, not freshness. Verify timestamps and upstream attribution before operational use. [E5]

### Forecasts with inspectable machinery, not proven calibration

OI keeps source-linked context, dated simulation periods, multiple worlds, event traces and report generation. The quantitative module really implements historical price-level backtesting, Brier scores and calibration bins; it explicitly notes overlapping windows are not independent. This tests a price baseline, not the reliability of the full LLM report or geopolitical forecasts. Prompting a model to be calibrated and linking a source do not establish statistical calibration or claim entailment. No independent end-to-end forecasting evaluation was located in the inspected scope. [E3]

The depth configuration implies approximately **34 / 88 / 132 model calls** for quick / standard / deep runs with research, before retries and follow-up questions. User text can reach 100,000 characters; panel mode repeats a bounded portion across actors. Call estimates are not a dollar cap. [E4]

### Reconnaissance is not uniformly active scanning

The README describes TCP scanning, but the inspected portscan route queries Shodan or its keyless InternetDB record; it does not itself establish fresh TCP connections to the target. Separately, the scanner proxy delegates allowed operations to a configured backend, including quick, TLS, headers and vulnerability operations. Target validation and rate limits are meaningful controls, but do not establish target-owner consent. The external scanner implementation is not provided by that route and was not audited. [E8]

## Architecture

Browser map and panels call Next API routes, which aggregate third-party data or proxy selected services. The Express intel sidecar enriches entities from a cached sanctions list and Wikidata. OI REST and MCP reuse a service layer; the run manager starts an asynchronous engine, folds stamped events into state, and exposes replay/live SSE. The page assistant uses a bounded action bridge (layers, camera movement, panels, forecasts, terrain and reconnaissance), rather than an arbitrary shell executor in the inspected path. [E2–E7]

### Permissions, authentication and execution boundaries

- **No general workspace/tenant authentication boundary was found in the inspected dashboard and feed paths.** Middleware performs analytics, not login. OI's provider bearer/key header pays for model calls; it is not an application-user role system. MCP checks browser Origin, supports configured origins and local clients, and allows requests without Origin; this is not account authentication. [E6, E9]
- **Read access and mutation access differ.** A forecast's random UUID is its shareable read capability. A separate random token, compared in constant time, protects injection/cancellation. Anyone given a run link can read the run; do not treat it as a private case file. [E4]
- **SDK ingestion is fail-closed on a configured key, but SDK streaming is not protected by that ingest key.** The stream handler returns current normalized entities without an authorization check. Do not ingest confidential operational tracks into an exposed instance. GitHub webhook forwarding separately requires configuration and HMAC verification. [E10]
- **Public-target filtering is defense in depth, not a network sandbox.** The shared guard resolves targets and checks redirect hops; it explicitly documents that socket-level IP pinning is absent. The scanner forwards the original target to a separate consumer. Use egress restrictions and authorized target scope rather than assuming validation fully eliminates rebinding or downstream behavior risk. No exploit was attempted. [E8]
- **Rate limits depend on deployment trust.** They are in-memory and identify clients from proxy/platform headers. Directly exposing the application while accepting those headers is not equivalent to a trusted edge overwriting them. Compose publishes application and cache ports broadly, and nginx does not constitute an account/consent gate. [E7–E9]
- Next headers include HSTS, nosniff, framing and permissions policies, but the CSP permits broad HTTPS sources, inline code and eval. Browser location and microphone are allowed for self; camera, USB and screen capture are denied by the configured policy. These controls should not be confused with protection from every same-origin script accessing browser-held keys. [E11]

### Credentials, privacy and egress

OI keys default to sessionStorage and can be remembered in localStorage. They are sent in request headers to the OSIRIS server, retained in the active run's chat closure, and used against fixed provider endpoints. “Never stored on the server” is best read as no durable key field in the inspected run store—not that the server never receives the key. Same-origin scripts, the hosting operator and infrastructure logging remain part of the trust boundary. The scanner backend key is sent in a query string, so backend/proxy URL logging deserves special attention. [E4, E8, E12]

Questions, uploaded/pasted context, public research text and optional camera images can be sent to the selected model provider. Lookup targets and research queries also leave for feed/enrichment/search services. Some camera media is fetched directly by browsers. Public-source status does not remove privacy, redistribution or surveillance obligations. Treat article text, feed text and model responses as untrusted; action validation is not proof of prompt-injection immunity. [E1–E3, E12]

The middleware makes two best-effort Umami calls per matched page, including an explicit IP event plus page/referrer/user-agent metadata. It targets an internal production service name and the Compose file assumes an external analytics network. This is actual telemetry code, not evidence that every self-host deployment successfully transmits it; DNS/network availability determines that. Remove or deliberately configure it before claiming a private self-host. [E6–E7]

### Persistence and recovery

OI runs live on globalThis in one process. Defaults include two active runs per address, 24 globally, a 20-minute deadline, 150 retained runs and a three-hour completed-run TTL. SSE event replay supports reconnecting to a still-present run, not recovery after process loss. Browser history retains 25 entries and run mutation tokens live in sessionStorage; history entries do not restore the server engine. Multiple independent workers will not automatically share run state. SDK entities and intel indexes are also process-local. [E4, E6, E10, E12]

Camera catalogs have a real disk snapshot, and nginx has a persistent tile-cache volume. However, stock Compose does not mount an application catalog volume; container replacement need not preserve that snapshot. Atomic cache writes and last-good sanctions retention are useful resilience measures, not a database, audit trail, backup plan or durable workflow queue. [E5–E7]

## Claims and Evidence

| Claim | Assessment |
|-------|------------|
| “Production-grade” / Palantir alternative | Broad map and enrichment functionality is real; no equivalent governed multi-user case-management, fine-grained permissions or durable audit system was established in reviewed paths. |
| 60fps and 75% fewer edge requests | README claims; no independent benchmark run, hardware profile or reproducible comparison established here. |
| 17,000+ cameras / live intelligence | Many real adapters exist; catalog size is not live reachability, synchronized freshness or verified event truth. No camera endpoints probed. |
| Calibrated AI forecast | Source-linked simulation and price-baseline backtest exist; full forecasting calibration remains unverified. |
| “Every other layer works out of the box” without scanner keys | Overbroad: upstream uptime/limits, optional AIS/provider keys, external Compose network and service configuration matter. Port lookup can work without the scanner backend. |

## Maturity, Tests and Supply Chain

Anonymous GitHub metadata on 2026-11-22 reported 11,836 stars, 2,467 forks and 33 open issues (GitHub's combined issue/PR counter), repository creation 2026-05-12 and last push 2026-11-22T01:51:05Z. These are popularity/activity snapshots, not quality scores. The reviewed commit timestamp is 2026-11-21T03:10:40Z. Latest returned release: [v5.0.0](https://github.com/simplifaisoul/osiris/releases/tag/v5.0.0).

There are **174 tracked .test.ts files**. Vitest covers src and intel; live-network cases are documented as opt-in. CI declares npm ci, type-checking, Vitest and production npm audit. The public API reported successful [CI](https://github.com/simplifaisoul/osiris/actions/runs/44859752748) and [Docker publication](https://github.com/simplifaisoul/osiris/actions/runs/44859752791) for this exact SHA. Those statuses are upstream evidence, not locally reproduced results or a complete security audit. [E13]

Importantly, Docker publication triggers independently on master pushes: the YAML does **not** depend on successful CI completion, despite CI comments saying checks precede the image. Images/base images and Actions use mutable tags rather than immutable digests/commit pins. Lockfiles and non-root runners are positives; lifecycle preparation copies/prunes bundled MapLibre workers. The tree also tracks 589 files beneath intel/node_modules and Python bytecode under engine/__pycache__ without corresponding engine Python source in that directory. These complicate provenance and review; the inspected running web/forecast path is TypeScript, not an inferred Python service. No binaries, vendored modules or model weights were executed or independently authenticated. [E2, E7, E13]

## Comparison

| Need | OSIRIS | Better-focused alternative to evaluate |
|------|--------|---------------------------------------|
| Public live map with many feeds | Integrated exploration and AI assistance | [World Monitor](https://github.com/koala73/worldmonitor), for another global dashboard approach |
| Reproducible geographic analysis | Interactive situational display and terrain tools | [QGIS](https://qgis.org/), for desktop GIS workflows and explicit datasets |
| Threat-intelligence knowledge management | Public-source enrichment and map overlays | [OpenCTI](https://github.com/OpenCTI-Platform/opencti), for a dedicated threat-intelligence knowledge platform |

These are scope comparisons, not fresh audits or claims that alternatives are safer. OSIRIS is attractive when the integrated public-data map is the goal; it is not evidence that a governed enterprise intelligence stack can be replaced without additional engineering.

## Self-Hosting Notes

Do not adopt the README quick-start as a production security recipe. First decide whether all data may be public, put private instances behind authenticated access, restrict direct app exposure, normalize trusted proxy headers, set egress policy and isolate any scanner. Configure HTTPS before transmitting BYOK credentials; secure headers alone do not terminate TLS. Disable OI if unwanted, and set provider-side spend limits rather than relying on call estimates. No setup or deployment was performed for this review.

Budget for server CPU/memory, map/video bandwidth and caching, API limits, optional commercial lookup access and model tokens. The code is MIT, not an entitlement to free upstream services. Compose currently requires an existing external analytics network and introduces nginx and intel in addition to the main app; its advertised one-command simplicity is conditional. Plan snapshot storage separately and assume in-flight forecasts are lost at restart. [E4, E7]

The [MIT license](https://github.com/simplifaisoul/osiris/blob/c1342f27cfa1a6d0152a348d79e83af08fe44e08/LICENSE) names simplifaisoul (2026). Preserve dependency notices, including bundled YOLOX's Apache-2.0 license and MapLibre notices. The README labels an OpenSanctions source CC-BY 4.0; that statement is not an independent verification of every dataset's current terms or commercial-use rights. Camera operators, broadcasters, tiles and enrichment providers retain their own access/attribution/licensing rules. SECURITY.md requests defensive, authorized use; policy text does not technically enforce target consent.

## Evidence and Verification Limits

Pinned source references (all at the reviewed SHA):

- **E1:** [README.md](https://github.com/simplifaisoul/osiris/blob/c1342f27cfa1a6d0152a348d79e83af08fe44e08/README.md); [src/app/api/conflicts/route.ts](https://github.com/simplifaisoul/osiris/blob/c1342f27cfa1a6d0152a348d79e83af08fe44e08/src/app/api/conflicts/route.ts); [src/app/api/maritime/route.ts](https://github.com/simplifaisoul/osiris/blob/c1342f27cfa1a6d0152a348d79e83af08fe44e08/src/app/api/maritime/route.ts).
- **E2:** [package.json](https://github.com/simplifaisoul/osiris/blob/c1342f27cfa1a6d0152a348d79e83af08fe44e08/package.json); [src/lib/oi/assist/tools.ts](https://github.com/simplifaisoul/osiris/blob/c1342f27cfa1a6d0152a348d79e83af08fe44e08/src/lib/oi/assist/tools.ts); [src/lib/oi/assist/recon.ts](https://github.com/simplifaisoul/osiris/blob/c1342f27cfa1a6d0152a348d79e83af08fe44e08/src/lib/oi/assist/recon.ts).
- **E3:** [src/lib/oi/engine.ts](https://github.com/simplifaisoul/osiris/blob/c1342f27cfa1a6d0152a348d79e83af08fe44e08/src/lib/oi/engine.ts); [src/lib/oi/web.ts](https://github.com/simplifaisoul/osiris/blob/c1342f27cfa1a6d0152a348d79e83af08fe44e08/src/lib/oi/web.ts); [src/lib/oi/prompts.ts](https://github.com/simplifaisoul/osiris/blob/c1342f27cfa1a6d0152a348d79e83af08fe44e08/src/lib/oi/prompts.ts); [src/lib/oi/quant.ts](https://github.com/simplifaisoul/osiris/blob/c1342f27cfa1a6d0152a348d79e83af08fe44e08/src/lib/oi/quant.ts).
- **E4:** [src/lib/oi/runs.ts](https://github.com/simplifaisoul/osiris/blob/c1342f27cfa1a6d0152a348d79e83af08fe44e08/src/lib/oi/runs.ts); [src/lib/oi/depths.ts](https://github.com/simplifaisoul/osiris/blob/c1342f27cfa1a6d0152a348d79e83af08fe44e08/src/lib/oi/depths.ts); [src/lib/oi/service.ts](https://github.com/simplifaisoul/osiris/blob/c1342f27cfa1a6d0152a348d79e83af08fe44e08/src/lib/oi/service.ts).
- **E5:** [src/lib/sourceCache.ts](https://github.com/simplifaisoul/osiris/blob/c1342f27cfa1a6d0152a348d79e83af08fe44e08/src/lib/sourceCache.ts); [src/lib/camera-catalog.ts](https://github.com/simplifaisoul/osiris/blob/c1342f27cfa1a6d0152a348d79e83af08fe44e08/src/lib/camera-catalog.ts); [src/lib/cctv-snapshot.ts](https://github.com/simplifaisoul/osiris/blob/c1342f27cfa1a6d0152a348d79e83af08fe44e08/src/lib/cctv-snapshot.ts).
- **E6:** [src/middleware.ts](https://github.com/simplifaisoul/osiris/blob/c1342f27cfa1a6d0152a348d79e83af08fe44e08/src/middleware.ts); [intel/server.js](https://github.com/simplifaisoul/osiris/blob/c1342f27cfa1a6d0152a348d79e83af08fe44e08/intel/server.js).
- **E7:** [docker-compose.yml](https://github.com/simplifaisoul/osiris/blob/c1342f27cfa1a6d0152a348d79e83af08fe44e08/docker-compose.yml); [Dockerfile](https://github.com/simplifaisoul/osiris/blob/c1342f27cfa1a6d0152a348d79e83af08fe44e08/Dockerfile); [intel/Dockerfile](https://github.com/simplifaisoul/osiris/blob/c1342f27cfa1a6d0152a348d79e83af08fe44e08/intel/Dockerfile); [nginx/nginx.conf](https://github.com/simplifaisoul/osiris/blob/c1342f27cfa1a6d0152a348d79e83af08fe44e08/nginx/nginx.conf).
- **E8:** [src/app/api/scanner/route.ts](https://github.com/simplifaisoul/osiris/blob/c1342f27cfa1a6d0152a348d79e83af08fe44e08/src/app/api/scanner/route.ts); [src/app/api/osint/portscan/route.ts](https://github.com/simplifaisoul/osiris/blob/c1342f27cfa1a6d0152a348d79e83af08fe44e08/src/app/api/osint/portscan/route.ts); [src/lib/ssrf-guard.ts](https://github.com/simplifaisoul/osiris/blob/c1342f27cfa1a6d0152a348d79e83af08fe44e08/src/lib/ssrf-guard.ts).
- **E9:** [src/app/api/mcp/route.ts](https://github.com/simplifaisoul/osiris/blob/c1342f27cfa1a6d0152a348d79e83af08fe44e08/src/app/api/mcp/route.ts).
- **E10:** [src/app/api/sdk/ingest/route.ts](https://github.com/simplifaisoul/osiris/blob/c1342f27cfa1a6d0152a348d79e83af08fe44e08/src/app/api/sdk/ingest/route.ts); [src/app/api/sdk/stream/route.ts](https://github.com/simplifaisoul/osiris/blob/c1342f27cfa1a6d0152a348d79e83af08fe44e08/src/app/api/sdk/stream/route.ts); [src/app/api/github-webhook/route.ts](https://github.com/simplifaisoul/osiris/blob/c1342f27cfa1a6d0152a348d79e83af08fe44e08/src/app/api/github-webhook/route.ts).
- **E11:** [next.config.ts](https://github.com/simplifaisoul/osiris/blob/c1342f27cfa1a6d0152a348d79e83af08fe44e08/next.config.ts).
- **E12:** [src/lib/oi/client.ts](https://github.com/simplifaisoul/osiris/blob/c1342f27cfa1a6d0152a348d79e83af08fe44e08/src/lib/oi/client.ts); [src/lib/oi/providers.ts](https://github.com/simplifaisoul/osiris/blob/c1342f27cfa1a6d0152a348d79e83af08fe44e08/src/lib/oi/providers.ts); [src/lib/vision/store.ts](https://github.com/simplifaisoul/osiris/blob/c1342f27cfa1a6d0152a348d79e83af08fe44e08/src/lib/vision/store.ts); [src/lib/vision/detect.ts](https://github.com/simplifaisoul/osiris/blob/c1342f27cfa1a6d0152a348d79e83af08fe44e08/src/lib/vision/detect.ts).
- **E13:** [.github/workflows/ci.yml](https://github.com/simplifaisoul/osiris/blob/c1342f27cfa1a6d0152a348d79e83af08fe44e08/.github/workflows/ci.yml); [.github/workflows/docker-publish.yml](https://github.com/simplifaisoul/osiris/blob/c1342f27cfa1a6d0152a348d79e83af08fe44e08/.github/workflows/docker-publish.yml); [vitest.config.ts](https://github.com/simplifaisoul/osiris/blob/c1342f27cfa1a6d0152a348d79e83af08fe44e08/vitest.config.ts); [tools/prepare-map-worker.mjs](https://github.com/simplifaisoul/osiris/blob/c1342f27cfa1a6d0152a348d79e83af08fe44e08/tools/prepare-map-worker.mjs).

Public accessibility and canonical identity were verified without private account access. Existing public review/index entries were checked for the canonical repository before creating this review. Static inspection and source inventory only: no dependency install, test suite, build, live target scan, demo session, model inference or hardware access. Upstream test success, service availability, throughput, forecast accuracy and exploitability were not independently reproduced. The standalone review page and index were checked separately as publication artifacts.

---

**Attribution:** simplifaisoul/osiris, MIT; dependency and data-provider terms remain separate. No source code extraction included.
