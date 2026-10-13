# RustGIS (opengeos/RustGIS)

**Repo:** https://github.com/opengeos/RustGIS
**License:** Apache-2.0; preserve notices and applicable attribution. Bundled data/fonts and external tools have separate terms.
**Reviewed:** 2026-10-13 UTC
**Revision:** `2ad494e31e3b085a4c6a6f4a1da2c6f51cbd99f9` (2026-10-13 04:21:52 UTC). Scope: workspace/manifests, desktop/web/CLI entry points, engine, analysis, assistant/MCP, plugins, GeoLibre integration, representative data/render modules, tests and CI.
**Verification:** Anonymous public-source acquisition and static inspection only. No application, builds, installers, dependencies or tests executed; no scientific-accuracy or performance validation.
**Stack:** Rust 2024, egui/eframe, wgpu, WebAssembly, wasmi, Cargo workspace.
**What it is:** A command-driven desktop and browser GIS with a CLI, AI assistant, geoprocessing and WebAssembly plugins.

---

## Verdict

⚠️ **Interesting — evaluate on disposable datasets, not as a production GIS replacement yet.** The implementation is substantial and its shared command engine is genuinely useful for reproducible automation. The unusually young public repository, approximate analysis choices and broad plugin/AI/native-runner trust surface call for controlled validation rather than accepting headline feature parity.

## What It Is

RustGIS combines familiar layers, tables, styling, layouts and map navigation with a command registry that can be driven by the GUI, CLI, automation and assistant. Native desktop and browser builds share much of the interface and engine. This is not merely a wrapper around an LLM: geometry, rendering, providers, analysis and project state are implemented in separate Rust crates.

The advertised 1,000-plus GeoLibre/Whitebox tools are external-suite integrations, not 1,000 independently reviewed built-in algorithms. Desktop use involves an optional native runner; browser integration has a separate adapter. Do not assume the two execution environments have identical capabilities or trust boundaries.

## Stack

| Layer | Technology |
|---|---|
| UI | egui/eframe shared desktop/browser interface |
| Rendering | wgpu and map/render/tiles crates |
| Domain | geometry, data, analysis and engine crates |
| Automation | command registry, rustgis-cli, stdio MCP |
| Extensibility | wasmi-interpreted WebAssembly; optional GeoLibre executable |
| Build | Rust 2024, declared Rust 1.90 minimum, Cargo.lock |

## Key Features

### Shared commands instead of separate automation implementations

The layered workspace and engine expose the same command concepts to multiple interfaces. That is a strong foundation for repeatable map manipulation and integration tests, but a command being available does not establish that its numerical result is suitable for a particular scientific or surveying purpose. [Workspace](https://github.com/opengeos/RustGIS/blob/2ad494e31e3b085a4c6a6f4a1da2c6f51cbd99f9/Cargo.toml), [engine](https://github.com/opengeos/RustGIS/tree/2ad494e31e3b085a4c6a6f4a1da2c6f51cbd99f9/crates/engine), [CLI](https://github.com/opengeos/RustGIS/blob/2ad494e31e3b085a4c6a6f4a1da2c6f51cbd99f9/apps/rustgis-cli/src/main.rs).

### Plugins have real containment, with remaining host-side limits

The plugin runtime rejects imports other than three RustGIS host functions, creates fresh instances and applies fuel, memory and table limits. The instance memory ceiling is 512 MiB, and inbound messages are capped at 128 MiB. This is meaningfully stronger than importing arbitrary native code.

However, host calls run outside WebAssembly instruction metering. The inspected reply path serializes a host result before assigning it to the reply buffer and does not apply the same explicit MAX_MESSAGE check there. Thus guest memory/fuel limits should not be described as a complete host-memory/latency bound. Tools also run on the command/UI thread; the source itself describes a runaway tool consuming roughly 15 seconds of release-build time. These are static resource-exhaustion concerns, not demonstrated exploits. [Runtime](https://github.com/opengeos/RustGIS/blob/2ad494e31e3b085a4c6a6f4a1da2c6f51cbd99f9/crates/plugins/src/runtime.rs).

### Useful AI/MCP boundaries, not automatic privacy

The stdio MCP server denies file/network access by default, reserves user automation and plugin management, bounds batches, and limits map-image dimensions. Broad access can be enabled explicitly. Existing web-tile layers may still generate network traffic, as the source documents: default-denied commands do not mean a fully offline session. This is a local stdio service, not a reviewed HTTP deployment with authentication/CORS. [MCP policy](https://github.com/opengeos/RustGIS/blob/2ad494e31e3b085a4c6a6f4a1da2c6f51cbd99f9/crates/assistant/src/mcp.rs).

Assistant provider configuration permits HTTPS and selected local HTTP endpoints. Model use sends prompts and accessed data to the selected provider. The optional “remember key” setting stores keys unencrypted in application preferences/browser storage, and the UI explicitly warns about that. Prefer session-only keys or carefully controlled environments; local-first does not mean that an enabled assistant keeps data local. [Provider](https://github.com/opengeos/RustGIS/blob/2ad494e31e3b085a4c6a6f4a1da2c6f51cbd99f9/crates/assistant/src/provider.rs), [key storage UI](https://github.com/opengeos/RustGIS/blob/2ad494e31e3b085a4c6a6f4a1da2c6f51cbd99f9/crates/ui-egui/src/assistantpane.rs).

## Architecture and Accuracy

The workspace separates geometry/data, analysis/rendering, engine, plugins/assistant and GUI/application adapters. A layering check is present in CI. This is an appropriate way to keep the GIS domain independent from the presentation shell.

The analysis module explicitly describes work in Web Mercator with per-feature latitude scale corrections, giving approximately ground-distance buffers. That is not a substitute for validating geodesic behavior, high-latitude results, antimeridian cases and topology against established tools. The native GeoLibre runner is a trusted executable with user-level filesystem access, unlike sandboxed WebAssembly plugins. [Analysis](https://github.com/opengeos/RustGIS/blob/2ad494e31e3b085a4c6a6f4a1da2c6f51cbd99f9/crates/analysis/src/lib.rs), [GeoLibre boundary](https://github.com/opengeos/RustGIS/blob/2ad494e31e3b085a4c6a6f4a1da2c6f51cbd99f9/crates/geolibre/src/lib.rs), [browser adapter](https://github.com/opengeos/RustGIS/blob/2ad494e31e3b085a4c6a6f4a1da2c6f51cbd99f9/apps/rustgis-web/src/geolibre.rs).

## Maturity and Verification

Public API snapshot on review date: **320 stars, 45 forks**, created **2026-10-10**, pushed **2026-10-13 04:33:54 UTC**; four open API issue objects comprised three issues and one PR. The latest observed release was [v0.2.0](https://github.com/opengeos/RustGIS/releases/tag/v0.2.0), published 2026-10-13 02:55:16 UTC. Main's reviewed SHA is not asserted to be that release's exact source. Public repository age does not prove when all its code was authored. [Metadata](https://api.github.com/repos/opengeos/RustGIS).

CI defines linting, a wasm build, workspace tests and native release builds on Linux/macOS/Windows, plus a layering check. The inspected revision's [CI run](https://github.com/opengeos/RustGIS/actions/runs/38346084147) was still in progress when checked; no green result is claimed. Representative tests were read, not run. Release assets/checksums were listed but not downloaded or verified. [Workflow](https://github.com/opengeos/RustGIS/blob/2ad494e31e3b085a4c6a6f4a1da2c6f51cbd99f9/.github/workflows/ci.yml).

## Comparison

| Alternative | When to prefer it |
|---|---|
| [QGIS](https://qgis.org/) | Established professional GIS workflows, mature interoperability and a wider validation history. RustGIS is more interesting when a compact command-first Rust application is the objective. |
| [GDAL](https://gdal.org/) | Repeatable conversion and raster/vector processing without needing an integrated GUI or assistant. |
| [GRASS GIS](https://grass.osgeo.org/) | Established analytical workflows where validated methods matter more than a fresh UI. |

These are operational comparisons, not head-to-head benchmarks conducted here.

## Self-Hosting Notes

There is no required backend for the native application. Evaluate a pinned release using copies of data; compare representative projections, buffer areas, exports and project reloads with a trusted reference. Test desktop and web separately. Keep assistant/provider access and native runners disabled until needed; inspect plugin permissions, and do not expose the CLI through an unauthenticated network wrapper.

## License and Attribution

The [LICENSE](https://github.com/opengeos/RustGIS/blob/2ad494e31e3b085a4c6a6f4a1da2c6f51cbd99f9/LICENSE) contains Apache-2.0 terms. [ATTRIBUTION.md](https://github.com/opengeos/RustGIS/blob/2ad494e31e3b085a4c6a6f4a1da2c6f51cbd99f9/ATTRIBUTION.md) separately identifies Natural Earth public-domain data, CC0 CRS definitions and the Ubuntu Font Licence. External components and transitive dependencies need their own license review. No full dependency-license audit was performed.

**Attribution:** opengeos/RustGIS and its contributors, Apache-2.0.
