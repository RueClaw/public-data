# RuView (ruvnet/RuView)

- Repository: https://github.com/ruvnet/RuView
- Reviewed: 2026-05-23
- License: MIT at repository root; v2 Rust workspace packages declare MIT OR Apache-2.0; npm tool packages declare Apache-2.0
- Current commit reviewed: be4efecbcd9a8f357df07dcc654f363fc774f8fb
- Latest GitHub release observed: v1235, published 2026-05-24
- Stack: Rust workspace, ESP32 firmware, Python ML/signal-processing scripts, TypeScript MCP/CLI packages, Vite/Lit dashboard, Docker, Home Assistant/MQTT/Matter integration docs

## Verdict

📚 Study, not a deploy candidate as-is.

RuView is an ambitious WiFi Channel State Information sensing project: presence, vital signs, people counting, pose inference, Home Assistant/Matter integration, ESP32 firmware, edge modules, and agent-facing MCP/CLI tooling. It is packed with useful ideas, but the repo reads more like a fast-moving research/product incubator than a clean deployable system.

The strongest parts are architectural: CSI ingestion, local edge inference, privacy-preserving camera-free sensing, Home Assistant integration, witness/attestation ideas, MCP/CLI adapters, and clear documentation of some known gaps. The weakest part is validation confidence: many claims require hardware, pretrained model, and environment-specific testing, and the local verification found uneven test and dependency health.

## What It Is

RuView aims to turn commodity WiFi signals into spatial intelligence. The claimed pipeline uses ESP32 or research NIC CSI data, signal processing, lightweight models, and edge modules to infer presence, motion, breathing, heart rate, sleep/activity states, multi-person count, and sometimes pose-like structure without cameras.

Major surfaces include:

- v2 Rust workspace for core types, signal processing, hardware parsing, sensing server, vitals, training, CLI, WASM, point cloud, and edge cogs.
- ESP32 firmware and provisioning scripts.
- Python scripts for benchmarking, training, CSI recording, and simulation.
- Dashboard built with Vite and Lit.
- TypeScript RuView CLI and MCP server.
- Home Assistant / MQTT / Matter-oriented docs and examples.
- Vendor/reference materials and archived prototypes.

## Architecture Notes

The repo is broad rather than tidy. The main implementation center appears to be v2/, with a Rust workspace covering the sensing pipeline and related cogs. The root also contains older Python packaging, scripts, firmware, reference assets, dashboard code, and agent scaffolding.

The interesting architecture is:

1. Capture CSI from ESP32/research hardware or replay data.
2. Normalize and process RF phase/amplitude signals.
3. Run heuristic or model-backed inference for presence, vitals, pose/counting, or environmental events.
4. Publish outputs to dashboards, MQTT/Home Assistant, Matter scaffolding, or MCP/CLI tools.
5. Keep some modules small enough for edge deployment.

That is a good pattern for camera-free sensing, but it also crosses into sensitive domains. Presence, sleep, heart/breathing, falls, distress, and elderly inactivity are safety-relevant signals and should not be treated as medically reliable without controlled validation.

## Verification

Verification was run locally from a fresh shallow clone.

- GitHub metadata: 64k+ stars, 8.5k+ forks, MIT license, Rust primary language, latest release v1235.
- v2 Rust workspace resolved with cargo metadata.
- Rust core crate tests passed: wifi-densepose-core, 28 tests.
- Attempted wifi-densepose-signal tests failed before tests ran because openblas-src could not link libgfortran in the local macOS toolchain.
- Dashboard npm install and production build passed.
- Dashboard default npm test failed because Vitest collected a Playwright a11y spec; no tests ran in that suite.
- Dashboard npm audit reported 11 advisories: 8 moderate, 3 high.
- TypeScript RuView MCP package installed, built, audited cleanly, and passed tests: 2 suites, 16 tests.
- TypeScript RuView CLI package installed, built, and audited cleanly.
- Basic secret-pattern scan found a redaction script and public research links, not obvious live credentials.

## Strengths

- Large amount of documented research and architecture.
- Clear awareness of hardware limitations and pending validation phases in parts of the README.
- Useful edge-sensing shape: local CSI capture, local inference, local integrations.
- MCP and CLI packages are small, clean, and verified locally.
- Home Assistant/MQTT integration is a practical deployment direction for non-camera occupancy sensors.
- Security audit docs for the WASM edge crate are unusually direct about known issues.
- MIT/Apache-style licensing is friendly for studying and reuse, subject to checking subcomponents and vendor assets.

## Caveats

- The README is extremely broad and mixes implemented features, future work, research claims, hardware-gated paths, and product claims. Treat it as a map, not as proof.
- Some sensing claims need real-world validation with known hardware, ground truth, and environment diversity.
- The repo includes many generated/agent-workflow artifacts and vendor/reference materials, so the clean implementation boundary is not always obvious.
- Dashboard test wiring is currently rough.
- Dashboard dependencies need audit cleanup.
- Rust signal tests depend on native OpenBLAS/gfortran availability, which makes verification fragile on a clean macOS environment.
- Any use for health, safety, fall detection, distress, elder monitoring, or occupancy decisions needs regulatory and liability review.

## Best Use

Study RuView for patterns in local RF sensing, ESP32 CSI ingestion, edge inference, Home Assistant exposure, MCP tool wrapping, and privacy-oriented non-camera occupancy sensing.

Do not treat the repo as a turnkey safety or medical monitoring system. A serious deployment should start with a narrow target such as presence detection, collect site-specific ground truth, run false-positive/false-negative testing, and keep the output advisory rather than authoritative.

