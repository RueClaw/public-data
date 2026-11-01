# RustXNG (sahenjp/RustXNG)

**Repo:** https://github.com/sahenjp/RustXNG

**License:** AGPL-3.0-or-later; SearXNG-derived behavior/data, with upstream attribution in NOTICE. Modified network services have corresponding-source obligations. Dependencies retain their own terms.

**Reviewed:** 2026-11-01 (UTC)

**Revision:** fef998b69cc1882a9258a7f2cba59bf77793d729 (package 0.26.0); whole-repository static review, with targeted inspection of server, aggregation, network, extraction, configuration, crawler, database adapter, tests and benchmark paths. Source commit dated 2026-11-01.

**Verification:** Static source inspection; independently parsed settings and recomputed six committed benchmark summaries from stored ranks. No source code, builds, tests, searches, crawler, containers or models executed.

**Stack:** Rust 2024, Axum, Tokio, reqwest/rustls, Askama, scraper, Tantivy; optional database drivers and Redis/Valkey cache.

**What it is:** A self-hosted metasearch server and page-text retrieval layer for agents, ported from SearXNG, with a browser UI, compatible HTTP search shapes, optional local indexing and research synthesis. It is not an independent general-web index by default.

---

## Verdict

⚠️ **Interesting — a promising local retrieval sidecar, not a hardened public search service yet.** The aggregation, engine-state handling, compact JSON and combined search/text interface are useful. However, the reviewed code contradicts the strongest privacy and SSRF claims; unbounded response buffering and an unguarded research route make public exposure particularly premature. Pilot only behind explicit access and egress controls, and measure quality on unseen queries from the intended network.

## What It Is

A request selects category-appropriate engine adapters, dispatches network or database searches, merges and reranks results, and optionally fetches top-result pages. The JSON interface can limit result count and filter domains; HTML, CSV and RSS output coexist with the agent-oriented path. No LLM is required for ordinary search or page extraction.

Optional layers add a Tantivy BM25 corpus, an OpenAI-compatible embedding endpoint and a research flow that plans subqueries, gathers sources and optionally synthesizes a cited report. These are separate trust and cost boundaries, not evidence that every default search is local or keyless. A native MCP server is requested in [issue #30](https://github.com/sahenjp/RustXNG/issues/30), not present in the inspected CLI/router.

## Stack

| Layer | Technology and role |
|---|---|
| Server | Axum/Tokio; HTTP routes and graceful shutdown/idle sidecar exit |
| Upstream retrieval | reqwest with rustls, rotating user agents, timeouts, retries and configurable proxies |
| Parsing/UI | scraper, quick-xml, Askama templates and embedded assets |
| Ranking | Position fusion, term relevance, canonical-domain/identifier heuristics; optional embeddings |
| State | Memory TTL cache by default; optional Redis/Valkey; persistent per-process engine suspension |
| Local corpus | Tantivy index and separate rustxng-index crawler/search executable |
| Auth | No application-wide authentication in inspected routes; external access control needed |

## Key Features

### Search and readable text in one interface

/search supports max_results, include_domains, exclude_domains and include_raw_content. The latter fetches five pages by default; the actual settings default caps each at 8,000 characters, despite older documentation saying 4,000. Extraction takes the first nonempty article/main/role-main/body candidate and normalizes its text: it is not a full readability engine, JavaScript renderer, factuality check or prompt-injection defense. More characters do not establish better grounding. [S2, S4]

### Resilience and explicit tradeoffs

Parallel searches share an overall deadline; staged mode starts smaller tiers and can stop once enough results arrive. Per-engine state suspends failures and persistently empty responses. This is useful degradation rather than all-or-nothing search. Staged mode can sacrifice recall and is not universally faster: the project's own 20-question comparison reports it slower and less accurate in that run. The fixed 700 ms retry for HTTP 429 is not Retry-After-aware. [S2, S3, S7]

### Broad adapters, not proven universal coverage

The README advertises 226 types, 352 entries and 180 enabled defaults. An independent TOML parse of this revision finds **284 entries, 243 distinct engine strings and 171 entries not marked disabled**. These are configuration counts, not working-engine counts; initialization can skip adapters and category selection means a normal query does not hit every enabled entry.

There are genuine web, image, news, scholarly, package and configured-service adapters. DuckDuckGo submits query text to its HTML service; Yahoo! JAPAN sends it as a search parameter. Some integrations require keys or operator-hosted backends. Google is explicitly described upstream as unavailable in this build. Fixture tests show parsers handle fixtures, not that providers accept requests today. COVERAGE still calls database adapters stubs, but PostgreSQL contains real parameterized query execution; this is documentation drift, not absence of implementation. [S1, S2, S8, S9]

## Architecture

The principal path is main → Settings/EngineRegistry/Network/Cache → Axum router → Searcher → engine outcomes → ResultContainer → plugins/reranking/domain filters → optional raw-page attachment → response formatting. Engine-specific code is kept in separate modules, while declarative adapters cover recurring JSON/XPath/MediaWiki patterns.

The design is easy to inspect, but shared lower layers matter. Network caches responses by method, URL and body, **not headers, cookies or per-engine identity**. Identical requests with different authorization/representation headers can therefore collide in a shared cache configuration; isolation should be explicit before mixing credentialed engines or tenants. This is a static design concern, not a demonstrated cross-user exploit. [S2, S3, S10]

The local crawler has worker/page/depth controls, host delays, robots handling and optional sitemap discovery. It uses separate blocking HTTP clients, not a comprehensive public-egress enforcement layer. Treat seed lists, sitemaps and discovered links as untrusted inputs, restrict crawl destinations externally, and budget corpus refresh/storage. [S11]

## Security, Privacy and Configuration Boundaries

### 1. “Search terms never leave” is false for normal metasearch

The README says search terms never leave the machine. The adapter request builders and network client show the opposite: external engines receive queries and the server's outbound IP. Default autocomplete is DuckDuckGo; embeddings and research synthesis add further destinations when configured. Self-hosting removes a mandatory search SaaS intermediary, not upstream disclosure. Ordinary web metasearch cannot be treated as offline confidential search. [S1–S3, S8]

Debug logging deserves special attention: main defaults to info,rustxng=debug, and network cache-hit/retry logs include request URLs; per-engine proxy debug logs include the configured proxy string. Queries in URLs and credentials embedded in proxy URLs can therefore enter logs. Protect logs and set a deliberate production logging policy; this review did not encounter or publish live credentials. [S3, S5]

### 2. The SSRF guard is lexical, not end-to-end

is_public_url rejects some literal local/private IPv4 addresses and names, but accepts ordinary DNS names without resolving or pinning addresses. Its IPv6 branch rejects only loopback and unspecified addresses, not all internal/special-use ranges. Network follows redirects using a count-only policy without rechecking destination addresses. The same guard gates fetched result pages and signed image/favicon paths. Consequently, hostname resolution, rebinding and redirect destinations remain unprotected by the claimed boundary. These are source-confirmed omissions, not a runtime exploit test. [S3, S4]

HMAC signatures are useful authorization for image URLs, but do not make the target safe. The bundled signing secret is a public default and image proxying is off; replace that default before enabling signed proxy features. Use firewall/proxy enforcement denying internal and special-use egress, resolve-and-pin checks, and redirect-by-redirect validation before accepting “SSRF-hardened.”

### 3. Response size limits are too late or absent

Network::send reads response.bytes() in full and copies the result before returning it. The image proxy's 8 MiB check happens afterward. Page-text character truncation also happens only after fetching and parsing. The documented response-size defense therefore does not bound upstream allocation in this path; timeouts and cache budgets do not substitute for streaming byte/decompression limits. [S3, S4]

### 4. Public exposure and research costs need independent gates

The native default binds loopback, but Docker runs on 0.0.0.0 and the README publishes port 8888 without a host-loopback restriction. There is no global auth layer; default rate limiting is disabled. /research does not call the search handler's limiter and still gathers evidence when research.enabled is false: that flag controls LLM use, not route availability. With LLM credentials configured, reachable callers can trigger paid planning/synthesis. Parameter clamps bound subqueries/sources per call, not aggregate concurrent load or billing. [S5, S6]

No permissive CORS middleware was found, but absence of CORS is not authentication or protection against non-browser callers and cross-site request side effects. Put authentication, TLS, request/concurrency budgets and route restrictions in front of any non-loopback exposure. Hide operational/configuration metadata too. Issue #21 independently requests safer Docker port documentation.

### 5. Operator config is privileged

Settings can select proxies, disable TLS verification, point to embedding/LLM/database services and carry credentials. PostgreSQL binds the search string as a parameter, which is a good boundary, but configured SQL is trusted and its connection uses NoTls. A SELECT prefix check is not a substitute for least-privilege database accounts or encrypted transport. Keep configuration read-only to the service and do not expose it as user-editable input. [S1, S3, S9]

## Benchmark Evidence Versus Claims

The repository includes a 100-question English/Japanese known-URL set, scripts and per-question output, which is considerably better than headline-only marketing. Our independent data-only check recomputed hit@1, hit@5 and MRR@10 from saved ranks and matched all six committed evaluation summaries:

| Stored artifact | hit@1 | hit@5 | MRR@10 | Reported median |
|---|---:|---:|---:|---:|
| eval-100-final.json | 70 | 82 | 0.757 | 2,926.6 ms |
| eval-100-localmerge.json | 83 | 96 | 0.888 | 1,469.2 ms |
| eval-100-localmerge-b.json | 83 | 96 | 0.889 | 832.4 ms |
| eval-100-sitemapindex.json | 81 | 93 | 0.871 | 1,609.3 ms |
| eval-100-13k.json | 80 | 93 | 0.863 | 1,417.2 ms |
| eval-100-127k.json | 82 | 94 | 0.876 | 1,434.5 ms |

This verifies arithmetic, not original retrieval, gold-label validity or applicability to today's default build. The strongest 83/96 values are explicitly tied to local-index merge experiments, while local_index_path is empty by default. JSON records do not provide a complete source-SHA/config/hardware manifest. The README's range should not be read as a clean default-versus-default service benchmark. [S7]

Additional limits:

- The suite is dominated by documentation, Wikipedia and official-page navigation (65 English/35 Japanese questions), not broad research, freshness, ambiguity or downstream answer correctness.
- The scorer uses URL-prefix matching and normalizes version-number path segments into wildcards. That is permissive URL retrieval scoring, not evidence that the exact page/version answers the question.
- Ranking rules and weights were repeatedly tuned on these questions. No independent held-out evaluation is demonstrated in the inspected materials.
- Documentation juxtaposes changing historical claims, including both “cannot catch Exa without APIs” and “outperforms Exa.” Provider/IP blocks, suspension resets, corpus choice and warm caches change the conditions.
- The 0.01-second repeat-query figure is cached, not cold retrieval plus page extraction. Commercial comparisons are author-reported; no paid calls or matched-service reproduction were performed here.
- The nightly acceptance floor is 50 hit@1, not the advertised 79–83 range. A green benchmark run is a regression signal, not validation of the headline.

## Maturity and License

Public metadata checked on the review date: repository created 2026-10-18, latest reported push 2026-11-01, 290 stars, 20 forks, and 11 open issues/PRs combined. Latest release was v0.26.0 on 2026-11-01. Popularity is not an assurance argument.

For the exact reviewed SHA, the public API reported successful [CI](https://github.com/sahenjp/RustXNG/actions/runs/41300817630) and [nightly benchmark](https://github.com/sahenjp/RustXNG/actions/runs/41352850459). CI declares Linux/macOS/Windows formatting, Clippy and tests, plus slim-build and Docker smoke jobs. We did not rerun them or inspect every job log. Later listed CI runs on other SHAs were failing; those are not failures of this reviewed revision.

SECURITY.md says its known ctutils advisory is absent from the default build. That does not agree with Cargo.toml: default features enable db-engines, including postgres; Cargo.lock contains ctutils 0.4.2 on the documented crypto dependency chain. Compilation inclusion is distinct from exploitability, but the “default unaffected” rationale needs correction and a fresh feature-aware audit. No independent vulnerability scan was run. [S1, S12]

LICENSE contains AGPLv3; Cargo/NOTICE specify or-later and attribute the SearXNG/searx lineage. Preserve notices and review network-source obligations before distributing modifications or linking this library into another product. Using its HTTP API as a separate service is a different integration model; do not assume that makes all combinations license-exempt. No source-code extraction accompanies this review.

## Comparison

| Alternative | Prefer it when | RustXNG tradeoff |
|---|---|---|
| [SearXNG](https://github.com/searxng/searxng) | Established metasearch ecosystem and compatibility are priorities | RustXNG offers a compact Rust sidecar and combined page text, but port counts do not prove behavioral/live-provider parity |
| [Exa](https://exa.ai/) / [Tavily](https://www.tavily.com/) | Managed agent retrieval reduces scraper maintenance | Keyless defaults avoid mandatory usage fees, but operations, upstream blocking and security hardening remain yours; claimed quality superiority is not independently established |
| Local corpus search, e.g. [Tantivy](https://github.com/quickwit-oss/tantivy) | Confidential, bounded, offline retrieval is the real requirement | RustXNG's optional corpus can supplement retrieval, but its ordinary metasearch path still sends queries externally |

These are architectural fit comparisons, not new head-to-head measurements or current price quotations.

## Self-Hosting Notes

A binary can run without Redis, a database server, GPU or model downloads. A source build declares Rust 1.85+ and a C toolchain, but we did not establish actual lockfile MSRV compatibility; Docker uses Rust 1.99.1. The default database feature set is broader than a minimal metasearch deployment; a no-default-features build is documented and CI-covered. The Docker image runs as non-root and copies the server, not the optional index executable.

Historical author measurements report 13 MiB RSS and 17–27 MB binary sizes. Treat those as old measurements, not sizing promises for v0.26.0 under concurrency: the configured cache alone allows 32 MiB, upstream buffers are currently unbounded, and Tantivy corpus/workers add memory and disk. “$0” means no mandatory API charge for selected keyless engines, not zero hosting, bandwidth, electricity or maintenance cost. Optional commercial engines, embeddings and research models have their own charges and privacy terms.

Before a pilot: pin and verify a release; keep the host port loopback-only; use a small explicit engine set suited to the workload; enforce network egress and upstream size limits; disable unnecessary routes/features; protect credentials/logs; monitor blocked-engine rates; and run an unseen, repeatable quality/latency suite from the actual host. Do not send confidential queries to public engines.

## Verification and Limits

Completed: anonymous public acquisition and exact-SHA verification; README/license/manifests/config/CI inspection; targeted code tracing; static configuration counts; independent arithmetic checks of six stored rank arrays; public release/issues and revision-specific CI metadata checks. No installation, deployment, model download, upstream search, paid API call, dynamic SSRF test, build or test suite execution occurred. This is a scoped static review, not a comprehensive security audit. Benchmark timings are source reports, never our measurements.

## Evidence Map

All source links below are pinned to the reviewed commit.

- **S1:** [README](https://github.com/sahenjp/RustXNG/blob/fef998b69cc1882a9258a7f2cba59bf77793d729/README.md), [Cargo.toml](https://github.com/sahenjp/RustXNG/blob/fef998b69cc1882a9258a7f2cba59bf77793d729/Cargo.toml), [settings.toml](https://github.com/sahenjp/RustXNG/blob/fef998b69cc1882a9258a7f2cba59bf77793d729/settings.toml), [settings defaults](https://github.com/sahenjp/RustXNG/blob/fef998b69cc1882a9258a7f2cba59bf77793d729/src/settings.rs).
- **S2:** [aggregator](https://github.com/sahenjp/RustXNG/blob/fef998b69cc1882a9258a7f2cba59bf77793d729/src/aggregator.rs), [ranking/results](https://github.com/sahenjp/RustXNG/blob/fef998b69cc1882a9258a7f2cba59bf77793d729/src/results.rs), [engine state](https://github.com/sahenjp/RustXNG/blob/fef998b69cc1882a9258a7f2cba59bf77793d729/src/engine/state.rs), [quality heuristics](https://github.com/sahenjp/RustXNG/blob/fef998b69cc1882a9258a7f2cba59bf77793d729/src/quality.rs).
- **S3:** [network client, redirects, logs and buffering](https://github.com/sahenjp/RustXNG/blob/fef998b69cc1882a9258a7f2cba59bf77793d729/src/network.rs).
- **S4:** [URL guard and image proxy](https://github.com/sahenjp/RustXNG/blob/fef998b69cc1882a9258a7f2cba59bf77793d729/src/web/image_proxy.rs), [favicon proxy](https://github.com/sahenjp/RustXNG/blob/fef998b69cc1882a9258a7f2cba59bf77793d729/src/web/favicons.rs), [text extractor](https://github.com/sahenjp/RustXNG/blob/fef998b69cc1882a9258a7f2cba59bf77793d729/src/content.rs).
- **S5:** [entry point](https://github.com/sahenjp/RustXNG/blob/fef998b69cc1882a9258a7f2cba59bf77793d729/src/main.rs), [router](https://github.com/sahenjp/RustXNG/blob/fef998b69cc1882a9258a7f2cba59bf77793d729/src/web/mod.rs), [Dockerfile](https://github.com/sahenjp/RustXNG/blob/fef998b69cc1882a9258a7f2cba59bf77793d729/Dockerfile).
- **S6:** [HTTP handlers](https://github.com/sahenjp/RustXNG/blob/fef998b69cc1882a9258a7f2cba59bf77793d729/src/web/handlers.rs), [research pipeline](https://github.com/sahenjp/RustXNG/blob/fef998b69cc1882a9258a7f2cba59bf77793d729/src/deep_research.rs), [limiter](https://github.com/sahenjp/RustXNG/blob/fef998b69cc1882a9258a7f2cba59bf77793d729/src/web/limiter.rs).
- **S7:** [benchmark history](https://github.com/sahenjp/RustXNG/blob/fef998b69cc1882a9258a7f2cba59bf77793d729/docs/BENCHMARK.md), [evaluation script](https://github.com/sahenjp/RustXNG/blob/fef998b69cc1882a9258a7f2cba59bf77793d729/tools/eval_quality.py), [saved experiments](https://github.com/sahenjp/RustXNG/tree/fef998b69cc1882a9258a7f2cba59bf77793d729/bench), [nightly workflow](https://github.com/sahenjp/RustXNG/blob/fef998b69cc1882a9258a7f2cba59bf77793d729/.github/workflows/nightly-bench.yml).
- **S8:** [DuckDuckGo adapter](https://github.com/sahenjp/RustXNG/blob/fef998b69cc1882a9258a7f2cba59bf77793d729/src/engines/duckduckgo.rs), [Yahoo! JAPAN adapter](https://github.com/sahenjp/RustXNG/blob/fef998b69cc1882a9258a7f2cba59bf77793d729/src/engines/yahoo_japan.rs), [coverage](https://github.com/sahenjp/RustXNG/blob/fef998b69cc1882a9258a7f2cba59bf77793d729/docs/COVERAGE.md), [compatibility](https://github.com/sahenjp/RustXNG/blob/fef998b69cc1882a9258a7f2cba59bf77793d729/docs/COMPATIBILITY.md).
- **S9:** [PostgreSQL adapter](https://github.com/sahenjp/RustXNG/blob/fef998b69cc1882a9258a7f2cba59bf77793d729/src/engines/postgresql.rs).
- **S10:** [cache keys/backends](https://github.com/sahenjp/RustXNG/blob/fef998b69cc1882a9258a7f2cba59bf77793d729/src/cache.rs).
- **S11:** [crawler](https://github.com/sahenjp/RustXNG/blob/fef998b69cc1882a9258a7f2cba59bf77793d729/src/bin/rustxng-index.rs), [local index](https://github.com/sahenjp/RustXNG/blob/fef998b69cc1882a9258a7f2cba59bf77793d729/src/localindex.rs).
- **S12:** [security claims](https://github.com/sahenjp/RustXNG/blob/fef998b69cc1882a9258a7f2cba59bf77793d729/SECURITY.md), [lockfile](https://github.com/sahenjp/RustXNG/blob/fef998b69cc1882a9258a7f2cba59bf77793d729/Cargo.lock), [CI definition](https://github.com/sahenjp/RustXNG/blob/fef998b69cc1882a9258a7f2cba59bf77793d729/.github/workflows/ci.yml), [LICENSE](https://github.com/sahenjp/RustXNG/blob/fef998b69cc1882a9258a7f2cba59bf77793d729/LICENSE), [NOTICE](https://github.com/sahenjp/RustXNG/blob/fef998b69cc1882a9258a7f2cba59bf77793d729/NOTICE).

---

**Attribution:** sahenjp/RustXNG and its credited SearXNG/searx upstreams; AGPL-3.0-or-later. Independent analysis; benchmark claims attributed to the project.
