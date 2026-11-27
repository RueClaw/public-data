# MLightCAD (mlightcad/cad-viewer)

**Repo:** https://github.com/mlightcad/cad-viewer
**License:** MIT core; opt-in LibreDWG DWG path GPL-3.0; proprietary DWG alternative has separate commercial terms. Dependencies and assets retain their own terms.
**Reviewed:** 2026-11-27 (UTC)
**Revision:** d89b4e384a1055964e7191200aa77a5ad59e3281 on main, committed 2026-11-26; scope: repository manifests, viewer/document lifecycle, rendering, converter integration, SVG conversion, export packaging, LLM configuration, tests and CI. External parser implementations were not audited.
**Verification:** Static review only; no installation, source execution, drawing uploads, live application probes, paid calls or benchmark runs. Anonymous GitHub API and HTTPS Git access verified.
**Stack:** TypeScript, Vue 3 editor UI, Three.js/WebGL, pnpm/Nx/Vite, Jest and Playwright; external data-model and optional LibreDWG/WASM.
**What it is:** A browser CAD viewing and 2D editing toolkit with a framework-independent viewer, fuller editor, conversion plugins and portable HTML snapshots.

---

## Verdict

⚠️ **Interesting — credible browser-first CAD, not a fidelity or privacy guarantee.** The modular renderer and single-file sharing are useful engineering, and current CI reports success. Pilot it for bounded viewing and review workflows; qualify representative drawings, DWG licensing, resource limits and export fidelity before treating it as an authoritative CAD editor or confidential-document service.

## What It Is

MLightCAD combines local drawing ingestion, a CAD database abstraction, geometry conversion, a Three.js scene and AutoCAD-style commands. The monorepo has grown beyond its viewer name: editing, measurement, diff viewing, PDF/SVG/HTML export, cloud-drive integrations, AI plugins and headless tooling coexist. These are distinct deployment choices, not one uniform security boundary. [E1–E4]

The README's “first in the world” and “complete privacy” language is not independently established. Local file processing is supported by the inspected code, but optional remote services and default asset downloads prevent equating “no parsing backend required” with “no network.” [E1, E5, E6]

## Stack

| Layer | Tech / boundary |
|-------|-----------------|
| Viewer | TypeScript cad-simple-viewer; UI-independent core |
| Editor | Vue 3 cad-editor and demo host |
| CAD database / DXF | External @mlightcad/data-model 1.16.5; parser implementation absent from this checkout |
| DWG | Host-registered @mlightcad/libredwg-converter 3.16.5 in editor demo; worker + WASM |
| Rendering | Three.js 0.186.x, custom batches, line materials, glyph handling and spatial indexing |
| Build / checks | pnpm 10.33.4, Node >=24, Nx, Vite, TypeScript, Jest, Playwright |
| Server / storage | Not required for ordinary local viewing; cloud, CLI/MCP and server prerender paths are separate integrations |

## Key Features

### Format support is layered, not universal

- **DXF:** passed to the external data-model database reader; the repository documents a built-in MIT DXF parser. No direct parser audit or exhaustive version/entity coverage verification was possible within this checkout.
- **DWG:** not enabled by merely importing cad-simple-viewer. The demo explicitly registers the LibreDWG converter with worker execution. Its README acknowledges limited entity coverage, larger payloads, memory pressure and potential out-of-memory failures. “R12–Latest” is a roadmap claim, not an independently tested compatibility matrix.
- **SVG:** a real import converter accepts a practical subset; curves become polylines, unsupported elements are skipped, and text/style/unit semantics have documented losses. Local picker acceptance includes .svg, but converter registration remains a host responsibility.
- **PDF:** a dedicated plugin contains import and export commands; this is not evidence of lossless PDF-to-CAD reconstruction. HTML export is a display snapshot. DWF/DWFx/XPS appear in a linked community integration, not proof of those formats in the reviewed core. Three.js does not imply full 3D CAD/B-rep support. [E1–E4, E7]

### Useful rendering decomposition

The viewer delegates file interpretation to AcDbDatabase, while its document manager owns opening, sessions, progress, font preparation and view activation. Three-renderer groups mesh, point and line geometry, shares batches and material metadata, and handles highlight/visibility separately. This is a valuable separation for embedding or replacing the ingestion layer without rebuilding the UI. [E3, E4, E8]

### Portable sharing, with a semantic boundary

The HTML packager embeds a compressed snapshot and viewer runtime; it also has a different package mode that references a manifest and chunks. A single-file snapshot is useful for offline review, but neither it nor PDF/SVG is a substitute for the original editable drawing database. The packager escapes titles and script terminators, a positive output-safety detail rather than proof that all renderer inputs are safe. [E9]

## Architecture

Local File/FileReader → whole ArrayBuffer → AcApDocument → external AcDbDatabase/converter → database entities → Three-renderer batches → interactive view. URI loading is delegated to the database's openUri path. The editor demo opts into LibreDWG via AcDbDatabaseConverterManager; SVG conversion is available in this repository, but the core DXF reader and LibreDWG converter are external packages. Claims about their parsing bounds, binary correctness or full licensing contents require a separate dependency audit. [E2–E4, E7]

The distinction matters for performance: progressive entity conversion and cooperative yields can improve responsiveness without bounding memory. The inspected local-open paths still materialize the complete file. SVG first parses a full text/model and builds an entity array before chunked appends; it defaults to main-thread processing. “Streaming / incremental loading” should therefore not be read as a guarantee of constant-memory ingestion. [E3, E7]

## Security, Privacy and Untrusted Drawings

**Local processing:** the inspected local file path reads bytes into browser memory and calls the database reader; no drawing upload appears in that path. No telemetry sender was identified in the inspected viewer/document-manager and demo paths, but there was no runtime network capture or full transitive-dependency audit. This is not a blanket no-telemetry certification.

**Remote assets and integrations:** AcApDocManager defaults its asset base to a jsDelivr cad-data main-branch URL and uses it for fonts and new-drawing templates. Remote drawing URLs, Drive/OneDrive plugins and optional LLM providers introduce additional recipients and authentication scopes. Serving an application from another party also trusts that party's JavaScript. Pin and self-host assets when confidentiality/offline operation matters; review each enabled plugin's actual data flow. [E5, E6]

**AI credentials:** the optional LLM configuration stores encrypted API keys in localStorage, but its AES key derives from the public page origin and a fixed source-code salt. This is reversible obfuscation against someone with the stored blob and origin, not a user-secret-backed vault or protection from same-origin script. Avoid long-lived privileged keys in a shared or untrusted host. No credential values were collected or published. [E6b, E6c]

**Resource bounds:** no file-size rejection was found before the inspected local FileReader/arrayBuffer calls. Extension filtering is not content validation. Workers, error codes, font deadlines and cooperative yields help availability, but are not an overall CPU/heap/entity/recursion budget. SVG use references have cycle detection, a welcome narrow safeguard; that does not cap all nested or expanded drawing complexity. Deploy with explicit size/entity/time budgets, isolated document origins and a malformed-file corpus. No exploit or sandbox escape is claimed. [E3, E7, E10]

**Recovery is not completeness:** the manager contains a partial-open recovery path that activates extents after some failures; newly created failed sessions can also be closed by the caller. The exact outcome depends on the open/session path. Never interpret visible geometry after a failed or partial parse as proof of a complete drawing, and surface incompleteness before export. [E10]

## Editing, Export Fidelity and Durability

The command surface includes creation, transformations, undo and measurement. The inspected script save implementation calls database.dxfOut and downloads a Blob, or hands it to an MCP host outbox. This verifies a DXF export route, not lossless DWG round-trip or a DWG writer. Unsupported entities, proxies, fonts, layouts and extended data need corpus-level comparison in an independent CAD reader. SVG import explicitly approximates curves and drops several constructs. [E7, E11]

The README leaves IndexedDB persistence, file versioning and multi-user access control unfinished. Undo is not crash recovery; a browser download request is not verified durable archival. Preserve originals, keep explicit versioned exports, and reopen outputs before accepting edits. Overlay loading separately documents skipped block expansion, dimensions and viewports, another reason not to extrapolate fidelity from one display mode to all modes. [E1, E10, E11]

## License and Dependency Boundaries

The root MIT license permits reuse with its notice retained. The viewer manifest does not depend on LibreDWG, while the editor demo does: copying the demo is not equivalent to distributing an MIT-only DXF viewer. The project's documentation identifies the opt-in LibreDWG stack as GPL-3.0; assess obligations against the actual shipped dependency graph and distribution model, not a shorthand “GPL propagation” slogan. This review did not inspect external package license files and is not legal advice. [E2, E12]

The proprietary DWG option is not open source: its public terms describe compiled packages without source, a perpetual delivered-version license, separate later upgrade fees and a prohibition on redistribution as a standalone parsing SDK. Its compatibility, memory and large-file claims were not verified; it is a separate commercial option, not a recommendation to spend. Fonts, WASM and other assets also need their own redistribution review. [E12]

## Maturity, Tests and Performance

At retrieval the public API reported **1,289 stars, 259 forks and 8 open issues**, with last push on 2026-11-26. These are activity metadata, not quality scores. Latest listed prerelease was **v1.8.0-preview.6**, published 2026-11-22, peeled commit **39d0a825fd26035876bab2da93de7eea59143a92**. Latest stable endpoint reported **v1.7.8**, published 2026-11-02, peeled commit **c6c14f90e46bedbe9d6e6cf7faa7851d3f3490ad**. The reviewed main SHA is newer than both; package version strings alone do not identify the reviewed tree. [M1–M3]

The checkout contains hundreds of files under package __tests__ directories and browser fixtures/tests for layers, clipboard, drawing, PDF, properties and smoke flows. CI installs a frozen lockfile, lints, builds, runs Jest and runs Playwright on Chrome. The public API reports **CI completed successfully for the exact reviewed SHA** ([run 45803957419](https://github.com/mlightcad/cad-viewer/actions/runs/45803957419)). This review did not rerun those jobs, inspect every assertion or prove exhaustive format compatibility. Workflow actions are version-tag referenced rather than commit-SHA pinned, and workflow-level write permissions are broader than a read-only validation job needs. [E13]

README claims include smooth 60+ FPS and a canteen.dwg memory comparison of 33 MB for view-only HTML / 56 MB for measure mode versus 320 MB for AutoCAD 2020 and 246 MB for GstarCAD Viewer. Batching provides a plausible optimization mechanism, but the displayed comparison does not establish a controlled cross-product benchmark: hardware/browser, accounting method, repeated trials and equivalent functionality matter. A prerendered display snapshot also excludes work performed during conversion. No throughput, cold-open, peak-heap, mobile or fidelity benchmark was reproduced. [E1, E8]

## Comparison

| Option | Prefer it when | Tradeoff |
|--------|----------------|----------|
| MLightCAD | Browser embedding, bounded 2D review/editing and portable snapshots | External parser boundary; DWG licensing; qualify fidelity and resource limits |
| [vagran/dxf-viewer](https://github.com/vagran/dxf-viewer) | A narrower browser DXF viewing component is sufficient | Less reason to adopt a full editor/plugin suite; not a DWG replacement |
| [LibreCAD](https://github.com/LibreCAD/LibreCAD) | An established desktop 2D CAD workflow is acceptable | Desktop distribution rather than a browser-embedded viewer |
| [LibreDWG](https://github.com/LibreDWG/libredwg) | You need an open DWG parsing/conversion building block | Parser/library rather than a complete browser application; GPL considerations remain |

These are workflow alternatives, not benchmark winners; their current releases were not independently reviewed here. The existing [MutinyBIM review](mutinybim.md) covers a different, BIM-oriented browser workflow rather than DWG/DXF parity.

## Self-Hosting Notes

1. Start with a pinned DXF-only viewer build if that meets the requirement; deliberately choose and audit any DWG converter.
2. Bundle workers/WASM and mirror fonts/templates with compatible licenses; replace mutable CDN defaults and verify offline behavior rather than assuming it.
3. Disable unneeded cloud/AI/script plugins, use a dedicated document origin and a restrictive network policy. Do not treat a read-only UI mode as a server authorization boundary.
4. Establish size/time/entity budgets, failure notices and repeatable representative/malformed-file tests. Check fonts, units, dimensions, blocks, layouts and unsupported objects.
5. Keep original files and versioned DXF exports; validate exported drawings in another reader. Use HTML as a review artifact, not the only engineering archive.

## Evidence and Verification Limits

All E-links below are pinned to the reviewed source commit. Metadata endpoints are mutable retrieval evidence dated 2026-11-27 UTC. No private drawings, proprietary package, live demo, application runtime, dependency install or paid endpoint was accessed. Static code inspection cannot certify absence of vulnerabilities, uploads, telemetry or data loss in other configurations.

- **E1:** [README claims, performance and roadmap](https://github.com/mlightcad/cad-viewer/blob/d89b4e384a1055964e7191200aa77a5ad59e3281/README.md)
- **E2:** [Viewer manifest](https://github.com/mlightcad/cad-viewer/blob/d89b4e384a1055964e7191200aa77a5ad59e3281/packages/cad-simple-viewer/package.json)
- **E3:** [Local file source](https://github.com/mlightcad/cad-viewer/blob/d89b4e384a1055964e7191200aa77a5ad59e3281/packages/cad-simple-viewer/src/app/dataSource/AcApLocalDataSource.ts)
- **E3b:** [Serialized file-open session](https://github.com/mlightcad/cad-viewer/blob/d89b4e384a1055964e7191200aa77a5ad59e3281/packages/cad-simple-viewer/src/ui/AcUiFileOpenSession.ts)
- **E4:** [Document database delegation](https://github.com/mlightcad/cad-viewer/blob/d89b4e384a1055964e7191200aa77a5ad59e3281/packages/cad-simple-viewer/src/app/AcApDocument.ts)
- **E4b:** [Demo DWG registration](https://github.com/mlightcad/cad-viewer/blob/d89b4e384a1055964e7191200aa77a5ad59e3281/packages/cad-editor-demo/src/registerLibreDwg.ts)
- **E4c:** [Demo dependency manifest](https://github.com/mlightcad/cad-viewer/blob/d89b4e384a1055964e7191200aa77a5ad59e3281/packages/cad-editor-demo/package.json)
- **E5:** [Asset defaults, fonts and lifecycle](https://github.com/mlightcad/cad-viewer/blob/d89b4e384a1055964e7191200aa77a5ad59e3281/packages/cad-simple-viewer/src/app/AcApDocManager.ts)
- **E6:** [Optional provider catalog](https://github.com/mlightcad/cad-viewer/blob/d89b4e384a1055964e7191200aa77a5ad59e3281/packages/cad-llm-plugin/src/storage/AcApLlmModelCatalog.ts)
- **E6b:** [Persisted provider settings](https://github.com/mlightcad/cad-viewer/blob/d89b4e384a1055964e7191200aa77a5ad59e3281/packages/cad-llm-plugin/src/storage/AcApLlmConfigStore.ts)
- **E6c:** [Origin-derived API-key encryption](https://github.com/mlightcad/cad-viewer/blob/d89b4e384a1055964e7191200aa77a5ad59e3281/packages/cad-llm-plugin/src/storage/apiKeyCrypto.ts)
- **E7:** [SVG support and losses](https://github.com/mlightcad/cad-viewer/blob/d89b4e384a1055964e7191200aa77a5ad59e3281/packages/cad-svg-converter/README.md)
- **E7b:** [SVG whole-model conversion](https://github.com/mlightcad/cad-viewer/blob/d89b4e384a1055964e7191200aa77a5ad59e3281/packages/cad-svg-converter/src/AcDbSvgConverter.ts)
- **E7c:** [SVG reference-cycle handling](https://github.com/mlightcad/cad-viewer/blob/d89b4e384a1055964e7191200aa77a5ad59e3281/packages/cad-svg-converter/src/svgParse.ts)
- **E7d:** [PDF import command](https://github.com/mlightcad/cad-viewer/blob/d89b4e384a1055964e7191200aa77a5ad59e3281/packages/cad-pdf-plugin/src/AcApImportPdfCmd.ts)
- **E8:** [Geometry batching](https://github.com/mlightcad/cad-viewer/blob/d89b4e384a1055964e7191200aa77a5ad59e3281/packages/three-renderer/src/batch/AcTrBatchedGroup.ts)
- **E9:** [HTML snapshot packaging](https://github.com/mlightcad/cad-viewer/blob/d89b4e384a1055964e7191200aa77a5ad59e3281/packages/cad-html-core/src/AcExHtmlPackager.ts)
- **E10:** [Open and partial recovery](https://github.com/mlightcad/cad-viewer/blob/d89b4e384a1055964e7191200aa77a5ad59e3281/packages/cad-simple-viewer/src/app/AcApDocManager.ts)
- **E11:** [DXF serialization and delivery](https://github.com/mlightcad/cad-viewer/blob/d89b4e384a1055964e7191200aa77a5ad59e3281/packages/cad-script-core/src/script/saveDxf.ts)
- **E12:** [Root MIT license](https://github.com/mlightcad/cad-viewer/blob/d89b4e384a1055964e7191200aa77a5ad59e3281/LICENSE)
- **E12b:** [Public proprietary parser terms](https://github.com/mlightcad/cad-viewer/blob/d89b4e384a1055964e7191200aa77a5ad59e3281/PROPRIETARY-PARSER.md)
- **E13:** [CI workflow](https://github.com/mlightcad/cad-viewer/blob/d89b4e384a1055964e7191200aa77a5ad59e3281/.github/workflows/ci.yml)
- **E13b:** [E2E smoke assertions](https://github.com/mlightcad/cad-viewer/blob/d89b4e384a1055964e7191200aa77a5ad59e3281/packages/cad-editor-demo/e2e/tests/smoke.spec.ts)
- **M1:** [Public repository metadata](https://api.github.com/repos/mlightcad/cad-viewer).
- **M2:** [Prerelease v1.8.0-preview.6](https://github.com/mlightcad/cad-viewer/releases/tag/v1.8.0-preview.6).
- **M3:** [Stable v1.7.8](https://github.com/mlightcad/cad-viewer/releases/tag/v1.7.8).

---

**Attribution:** mlightcad/cad-viewer and its contributors; MIT core, separate DWG/parser/dependency terms as described above. This review is independent analysis; no source-code extraction is included.
