# Three Scope Map (songsummer920-dazzle/three-scope-map-skill)

**Repo:** https://github.com/songsummer920-dazzle/three-scope-map-skill
**Author:** 宋夏天Dazzle (songsummer920-dazzle)
**License:** Summer Platform Restriction License 1.1, source-available; separate dependency and asset terms. Not OSI open source and not a current GPL dual-license.
**Reviewed:** 2026-11-12 (UTC)
**Revision:** f8c93697c010801e203c9b9f49f6ef2e889ee6fb; repository-wide inventory, with focused inspection of the portable skill, scripts, Vue/FUI renderer, React generator, geography, manifests and licensing.
**Verification:** Static review; independent SHA-256 inventory checks passed for 63 classic, 156 FUI and 34 React files. No source scripts, builds, application tests, installs, browser/GPU rendering or live provider probes were run.
**Stack:** Python standard-library tooling; TypeScript, Vue 3/native React, Vite, Three.js, MapLibre GL, GSAP, PMTiles and polygon-clipping.
**What it is:** A geographic-visualization skill plus substantial runnable frontend templates—not a conceptual “three scopes” analysis method or a dashboard data service.

---

## Verdict

⚠️ **Interesting — strong geographic rendering scaffold, not a turnkey commercial map bundle.** The real value is complete renderer families, coordinated Earth-to-map transitions, shared administrative navigation and practical QA contracts. Before production use, resolve the bundled geography/image rights, normalize coordinate provenance, restrict provider credential destinations and reproduce rendering on target devices. Paid reusable map platforms require separate author permission.

## What It Is

A coding agent receives a desired framework, region, style, primary color and rendering mode, then copies or integrates an existing template rather than inventing an approximate map. The default is a photographic/entity Earth entrance followed by a textured-glass China map; hologram and classic styles are separate families. Vue is the default; native React output combines maintained TSX hosts with shared renderer/data assets.

The output is a project or application integration with source, textures, geographic data, legal notices and developer checks. It is not an autonomous hosted AI service, a GIS analysis engine, a business dashboard with real metrics, or an authoritative global boundary database. Geographic scopes are world/country/province/city/district; the default three-view control is 3D, 2D and a geographic 2D+3D overlay. Those are different concepts.

Evidence: [README](https://github.com/songsummer920-dazzle/three-scope-map-skill/blob/f8c93697c010801e203c9b9f49f6ef2e889ee6fb/README.md), [skill contract](https://github.com/songsummer920-dazzle/three-scope-map-skill/blob/f8c93697c010801e203c9b9f49f6ef2e889ee6fb/three-scope-map/SKILL.md), [project generator](https://github.com/songsummer920-dazzle/three-scope-map-skill/blob/f8c93697c010801e203c9b9f49f6ef2e889ee6fb/three-scope-map/scripts/create_map_project.py).

## Stack

| Layer | Technology / boundary |
|---|---|
| Agent interface | SKILL.md, focused references, OpenAI agent metadata; host supplies all model/tool authority |
| Project tooling | Python 3.9+ standard library; copy, install, theme, GeoJSON preprocessing and static checkers |
| Frontend | Vue 3 or native React TSX; TypeScript/Vite; Node ^20.19.0 or >=22.12.0 |
| Rendering | Three.js 0.176 family, MapLibre GL 6.3 family, GSAP; custom shaders, workers and caches |
| Data | Bundled world/China/Zhejiang geography, textures; DataV drilldown; OpenFreeMap default basemap |
| Persistence | In-memory geography/pending-request caches; optional camera-preset localStorage; no application database/auth backend |

The FUI Vue manifest includes a lockfile, a typecheck/build command and a cache-check prebuild gate. React generation removes the Vue lockfile and uses version ranges for React dependencies, requiring a fresh install and retained React lockfile. It also removes Vue test/QA directories and test/build:regression scripts; repository-level React tests are not equivalent to a generated React project shipping the Vue regression suite. [Manifest](https://github.com/songsummer920-dazzle/three-scope-map-skill/blob/f8c93697c010801e203c9b9f49f6ef2e889ee6fb/three-scope-map/assets/templates/fui-earth-vue/package.json), [generator](https://github.com/songsummer920-dazzle/three-scope-map-skill/blob/f8c93697c010801e203c9b9f49f6ef2e889ee6fb/three-scope-map/scripts/create_map_project.py).

## Key Features

### Complete, coherent renderer families

The skill distinguishes classic, photographic/entity and hologram styles while treating color, material, animation and rendering composition as independent choices. It explicitly preserves the user's existing framework and unrelated application content. This is more useful than an unstructured prompt to “make a 3D map.”

### Shared navigation without pretending all cameras are identical

The map navigation module models an explicit administrative path and terminal district scope. The geographic overlay uses MapLibre's camera/context rather than independently controlled stacked canvases. Overlay diagnostics explicitly call extrusion “display-extrusion-not-DEM,” a valuable distinction between visual height and measured terrain. [Navigation](https://github.com/songsummer920-dazzle/three-scope-map-skill/blob/f8c93697c010801e203c9b9f49f6ef2e889ee6fb/three-scope-map/assets/templates/fui-earth-vue/src/components/map/mapNavigation.ts), [overlay](https://github.com/songsummer920-dazzle/three-scope-map-skill/blob/f8c93697c010801e203c9b9f49f6ef2e889ee6fb/three-scope-map/assets/templates/fui-earth-vue/src/components/map/vectorMap3dLayer.ts).

### Rendering lifecycle is treated as engineering, not decoration

The references require first-frame and intro-complete gates, one continuous render-loop owner during handoff, sliced construction and real browser verification. The sampled runtime rejects stale/disposed navigation continuations; FuiRendererJobs drains pending compilation before disposing GPU owners. These are concrete design strengths, not proof of smooth performance on every GPU. [Renderer jobs](https://github.com/songsummer920-dazzle/three-scope-map-skill/blob/f8c93697c010801e203c9b9f49f6ef2e889ee6fb/three-scope-map/assets/templates/fui-earth-vue/src/components/map/fuiRendererJobs.ts), [visual QA](https://github.com/songsummer920-dazzle/three-scope-map-skill/blob/f8c93697c010801e203c9b9f49f6ef2e889ee6fb/three-scope-map/references/visual-qa.md).

## Architecture and Scope Methodology

1. Select framework, style and renderer mode; preserve an existing project's choices.
2. Resolve a correctly subdivided geographic dataset, not merely rescale the old geometry.
3. Swap boundaries, label levels, points/routes, texture extent, projection bounds, contour and camera together.
4. Maintain a drilldown/back path; load missing administrative data through a cache/pending-request adapter.
5. Check template identity and project structure, build, then inspect actual WebGL output and interaction.

This is a useful scope-migration methodology. However, resolve_map_data.py infers subdivisions from feature counts, geographic extent and Chinese name suffixes. Its checks are heuristics, not topology validation or authoritative administrative classification. World-to-country navigation still needs national datasets/registries; the bundled runtime starts in China and its fallback loader is DataV-specific. A world globe is not evidence of complete worldwide drilldown support.

The offline simplifier uses stride-based ring sampling rather than topology-preserving simplification. Its simplify_ring function can drop the repeated closing coordinate of an already closed ring when that last index is not sampled: the append branch only runs when the original first and last points differ. That is a static code-path finding, not a reproduced renderer failure. Add ring closure, polygon validity and shared-border tests before using this output for accurate boundaries. Neither visual extrusion nor arbitrary material height should be presented as survey-quality elevation.

Coordinate provenance needs particular care: the third-party notices identify bundled Zhejiang as GeoJSON.CN 1.6.3 data whose documentation specifies GCJ-02. The runtime adapter imports it directly; the provider projection helpers assume input WGS84 and perform forward conversion to GCJ-02/BD09. No normalization is visible in that loading path. This creates a credible alignment risk; no numerical offset or visual failure was measured here. Verify each source CRS and normalize before provider projection. Boundary depiction also follows supplied datasets and the author's China-specific inset rules; review geographic/legal presentation for the intended audience rather than treating it as neutral authority.

Evidence: [scope switching](https://github.com/songsummer920-dazzle/three-scope-map-skill/blob/f8c93697c010801e203c9b9f49f6ef2e889ee6fb/three-scope-map/references/map-scope-switching.md), [resolver](https://github.com/songsummer920-dazzle/three-scope-map-skill/blob/f8c93697c010801e203c9b9f49f6ef2e889ee6fb/three-scope-map/scripts/resolve_map_data.py), [preprocessor](https://github.com/songsummer920-dazzle/three-scope-map-skill/blob/f8c93697c010801e203c9b9f49f6ef2e889ee6fb/three-scope-map/scripts/preprocess_map_data.py), [data adapter](https://github.com/songsummer920-dazzle/three-scope-map-skill/blob/f8c93697c010801e203c9b9f49f6ef2e889ee6fb/three-scope-map/assets/templates/fui-earth-vue/src/components/map/mapDataAdapter.ts), [provider](https://github.com/songsummer920-dazzle/three-scope-map-skill/blob/f8c93697c010801e203c9b9f49f6ef2e889ee6fb/three-scope-map/assets/templates/fui-earth-vue/src/components/map/vectorMapProvider.ts).

## Security, Privacy and Authority

### Skill text is not a security boundary

The inspected skill is task-oriented; no request to exfiltrate secrets or override the reviewing host's policy was identified. Nevertheless, installation makes its commands available to an agent with whatever permissions the host grants. Prompts to download data, run npm, edit files and inspect a browser require ordinary host authorization. Treat project documents, feature names, external styles and fetched metadata as untrusted data, not instructions. There is no demonstrated adversarial prompt-injection evaluation or capability sandbox in this package.

The install script is substantially safer than a merge-copy recipe: it rejects symlink paths, overlapping paths and unrelated nonempty targets, validates release data, backs up the complete old skill outside the installation root, stages a replacement and attempts rollback. The project generator rejects nonempty destinations and does not execute npm. These are real safeguards, not permission to install automatically. Upgrade replacement does not merge local customizations. Theme application edits project files; the skill's example uses --no-backup even though the script supports backups. Use version control and narrowly approved destinations. [Installer](https://github.com/songsummer920-dazzle/three-scope-map-skill/blob/f8c93697c010801e203c9b9f49f6ef2e889ee6fb/three-scope-map/scripts/install_skill.py), [theme tool](https://github.com/songsummer920-dazzle/three-scope-map-skill/blob/f8c93697c010801e203c9b9f49f6ef2e889ee6fb/three-scope-map/scripts/apply_map_theme.py).

### External requests are part of normal operation

OpenFreeMap styles/tiles/glyphs/sprites and DataV administrative requests leave the browser; providers can observe IP address, request metadata and requested geography. China and Zhejiang are bundled, but other drilldown levels are fetched, so the default is not fully offline. Camera persistence is local browser state, not a server-side privacy guarantee. No model API, account creation or AI credential is required by the renderer itself; an agent host's model data handling is separate.

The provider request transform attaches configured query parameters and headers to transformed resource URLs without an origin allowlist. Style documents and TileJSON can introduce additional resource destinations. If a deployment adds a sensitive provider token, this broad transform can send it to unintended origins; browser CORS is not a substitute for credential scoping, especially for query tokens. Use public browser-scoped keys, trusted styles, explicit allowed origins and a controlled proxy for genuine secrets. This is a static conditional risk, not a demonstrated leak; the default provider does not require a key.

The Python resolver accepts a caller-supplied --url through urllib.request.urlopen, with a timeout but without a public-HTTPS/redirect allowlist or response-size cap. Its output path is caller-controlled. Do not expose it as an unrestricted remote service or let untrusted source text supply URLs and filesystem targets. The browser data adapter casts fetched JSON to its type and caches it without runtime schema, size, topology or CRS validation. Add bounded parsing and validation for custom/untrusted datasets.

### Dependency and deployment boundary

npm installation executes a dependency toolchain; lockfile hashes improve reproducibility, not trustworthiness. No dependency install or advisory audit was performed. Development scripts bind Vite to loopback, a sensible default. The project is frontend code, not a multi-tenant authenticated backend; business-data authorization, deployment CSP, provider CORS and any proxy access control belong to the integrating application.

## Licensing and Asset Provenance

[LICENSE](https://github.com/songsummer920-dazzle/three-scope-map-skill/blob/f8c93697c010801e203c9b9f49f6ef2e889ee6fb/LICENSE) explicitly calls the current author-owned grant source-available, not GPL or OSI open source. Ordinary internal/business use and client-specific delivery are permitted subject to its terms. Paid reusable map capabilities in SaaS, agent platforms, APIs, plugins, SDKs or template/resource offerings require prior written author permission, including relevant hosted/bundled/free-tier arrangements. Required source attribution and distribution notices must remain; UI watermarks are not mandatory. Archived GPL and license-1.0 texts preserve historical grants, not a new alternative license for this revision.

The more immediate deployment concern is asset rights. [THIRD_PARTY_NOTICES.md](https://github.com/songsummer920-dazzle/three-scope-map-skill/blob/f8c93697c010801e203c9b9f49f6ef2e889ee6fb/THIRD_PARTY_NOTICES.md) says DataV/AMap geography is learning/exchange-limited, GeoJSON.CN data is learning/research-limited, and legacy China height/normal image provenance remains unresolved. It explicitly does not confirm unresolved bundle redistribution rights. Natural Earth, NASA-derived images, Poly Haven textures and dependencies have separate terms/credits. Hash/source receipts prove byte identity, not legal clearance. Resolve or replace affected assets before commercial deployment or redistribution; the author's code license alone cannot clear them. No source code or media is extracted into this review.

## Maturity and Verification

Public GitHub metadata retrieved 2026-11-12 reported 715 stars, 102 forks, zero open issues, creation on 2026-05-19 and last push on 2026-11-12. These are discovery signals, not quality evidence. A v3.0.0 release exists; release.json declares 3.0.0, while template package versions remain 1.0.0. The inspected commit is dated 2026-11-12T05:01:43Z. A shallow checkout does not establish the full history or compatibility of older releases.

The repository contains Python packaging/handoff/theme/checker tests and FUI TypeScript/Node tests for materials, geometry workers, cache, overlays, camera and lifecycle behavior, plus browser QA pages. No tracked GitHub Actions workflow was found at this revision. The changelog links three-scope-map/validation/3.0.0/record.json as exact-distribution evidence, but that path is absent from the tracked checkout. Thus its historical installation/build/browser claims could not be independently inspected from that referenced artifact.

Independent read-only hashing compared every file against the three shipped manifests: classic 63/63, FUI 156/156, React 34/34, with no hash mismatches or unlisted files in those trees. This is internal consistency only; the manifests are shipped by the same source and are not independent authenticity signatures. All source execution, application test suites, dependency installs, builds, screenshots, GPU performance, accessibility, offline behavior and live provider compatibility remain unverified. The review's own Markdown/HTML/index checks are publication checks, not application tests.

## Comparison

| Option | Prefer it when | Tradeoff |
|---|---|---|
| Three Scope Map | The specific stylized Earth/administrative-map look and agent-ready workflow are the objective | Fast visual starting point; custom license, asset clearance and China-centered defaults |
| [MapLibre GL JS](https://github.com/maplibre/maplibre-gl-js) directly | The requirement is a standard interactive web map | Less preset spectacle, more direct provider/control ownership; data rights still separate |
| [deck.gl](https://github.com/visgl/deck.gl) | Data-driven geospatial overlays and analytical layers dominate | Build the presentation/navigation yourself rather than inherit this exact style |
| [CesiumJS](https://github.com/CesiumGS/cesium) | A globe, terrain and geospatial/3D Tiles workflows are central | Different integration/data-service tradeoffs; do not assume this template is equivalent GIS infrastructure |

For a general code-driven graphics catalog rather than maps, see the existing [ThreeUI review](threeui.md); it addresses a different problem.

## Self-Hosting Notes

There is no required application server or hosted account in the core template. A production pilot should pin the reviewed revision, use a clean generated project, retain all notices, clear/replace restricted assets, normalize source coordinate systems, lock React dependencies if applicable, and rerun unit/build/browser checks. For offline use, host not just a style JSON but all tiles, glyphs, sprites and required administrative levels; remove remote fallbacks and verify the network boundary. Test repeated switching, drilldown/back, resize, low-end/mobile GPU behavior and context loss before attaching real business data.

**Practical call:** study or pilot the rendering architecture in a controlled environment. Adopt for a compatible ordinary application only after the data/license and validation work; do not bundle it into a paid reusable mapping/agent product under an assumption of permissive open-source rights.

---

**Attribution:** 宋夏天Dazzle / songsummer920-dazzle, Three Scope Map. Current author-owned material: Summer Platform Restriction License 1.1; third-party material retains its separate terms. Analysis only, no affiliation or endorsement.
