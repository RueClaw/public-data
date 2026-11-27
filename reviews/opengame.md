# OpenGame (nexu-io/opengame)

**Repo:** https://github.com/nexu-io/opengame
**License:** Apache-2.0 for repository code; preserve notices and check separate dependency, generated-media and third-party asset rights.
**Reviewed:** 2026-11-27 (UTC)
**Revision:** f17151f3cc7838ddbe13d9b94392e0f983fc341b, main; targeted review of entry points, Game Studio, game service, agent adapters, provider settings, tracking, deployment, templates and CI.
**Verification:** Static source and anonymous GitHub metadata inspection only. No dependency installation, application execution, tests, accounts, model calls or live application probes.
**Stack:** TypeScript/Node.js, React/Vite, MCP, browser HTML/JavaScript, Puppeteer/Chromium, Hyperframes and FFmpeg.
**What it is:** A local AI-assisted browser-game creation workbench built on the wider OpenMotion/OpenDesign runtime, with editable templates, coding-agent integration, media generation, verification and export.

---

## Verdict

⚠️ **Interesting — useful local prototyping infrastructure, not a proven autonomous AAA engine.** The shared project model, explicit game checks, isolated preview origin and rollback-aware writes are substantial engineering. Treat generated code and attached coding agents as trusted local execution, disable unwanted telemetry, and validate export/licensing before shipping; neither commercial success nor hostile-code containment follows from the marketing.

## What It Is

OpenGame connects a game gallery and source viewer to a selected coding agent. HTTP and MCP work on the same owned files; creating a draft does not itself run the agent or finish a game. It is a browser-game toolchain, not an implementation of Unity or Unreal. The repository retains OpenMotion package names, media/video/design modules and `openmotion_game_*` tools. [E1], [E2], [E3]

The README advertises 25 playable templates and 22 agents, while the architecture document mentions 29 client definitions. A static count found **277 game.json files**, all declaring published and none declaring external, at this revision. That is a metadata count, not 277 independently verified games. The documentation and current tree are not synchronized enough to use headline counts as acceptance evidence. [E1], [E2], [E10]

## Stack

| Layer | Tech |
|---|---|
| Service and MCP | Node.js ≥22.18, TypeScript, Node HTTP, MCP SDK; preview.ts / server.ts / mcp.ts |
| UI | React, Vite, Tailwind, Zustand; GameStudio.tsx |
| Game runtime | HTML/CSS/JavaScript; optional deterministic logic.js; some Three.js games |
| Persistence | Workspace directories, JSON metadata, source files and versioned asset library; not a central game SQL database |
| Verification/media | Acorn, Node vm, Puppeteer/Chromium; Hyperframes and FFmpeg for trailers |
| Optional distribution | Electron desktop, Docker, web publishing and platform-specific integration modules |

Manifest versions and lockfiles are evidence of dependency selection, not a vulnerability audit. [E2], [E3]

## Key Features

### Shared editable projects and remixing

Studio and an external MCP agent can manipulate the same game workspace. Remix creates an owned copy rather than editing the bundled template. Twelve game tools cover creation, inspection, writes, metadata, covers, validation, simulation, playtesting, trailers, readiness and local publication. Gallery status is not proof of playability. [E2], [E4]

### Verification with observable artifacts

The game service includes deterministic rule simulation, scripted browser input, console/request error collection, assertions and screenshots. The browser harness uses fresh profiles/contexts and blocks page requests outside its temporary local origin (apart from data/blob URLs). This is materially better than declaring success because HTML exists; it still cannot establish fun, visual polish, platform approval or revenue. [E4]

### Portable delivery, with separate publication meanings

ZIP export is implemented, including an offline serving helper and a 64 MiB export limit. Local publication registers a game in the local catalog; web sharing creates a hosted static snapshot, and later edits do not automatically change that snapshot. Platform packaging and store submission remain separate operations: the README explicitly lists several distribution/monetization features as roadmap items, despite its broad introductory claims. [E1], [E2], [E4], [E12]

## Architecture

The practical flow is **Studio or MCP → shared GameProjects service → workspace files → browser preview/checks → export or hosting**. Provider and asset services sit alongside it; the selected coding agent is another execution authority, not merely a text generator. [E2], [E3], [E4]

### Generated-code and execution isolation

- **Browser preview:** a separate loopback server accepts GET requests only for a game-specific hashed localhost hostname and play path. Studio adds iframe sandbox flags; game responses add CSP. The isolated-origin path permits same-origin scripting within that distinct origin. The normal preview CSP permits inline/eval scripts, selected CDNs, assets and game connections; it is not a no-network sandbox. External gallery entries have a different iframe allowance. [E5]
- **Server logic:** GameRuntime parses source, rejects imports/require and nondeterministic APIs, removes Date/Math.random, disables string/Wasm code generation, uses JSON exchange and a 50 ms vm execution timeout. These are meaningful controls, but **Node vm is not a security boundary**. No per-game OS process or heap quota is established by this implementation; CPU timeouts do not prevent all memory exhaustion. Do not feed adversarial code to a privileged service. This is a design-risk assessment, not a demonstrated escape. [E4], [E13]
- **Coding agents:** adapters spawn local agent processes. Auto permission modes can add dangerous-skip-permissions flags. Browser isolation does not constrain the filesystem, network or credential access of those separate agent processes. Keep approval mode restrictive and use a disposable OS/container boundary for untrusted projects. [E6]

### Auth, secrets, network and privacy

The default service binds loopback; the supplied local Compose configuration publishes only to loopback and explicitly warns that Studio has no sign-in. Host checks and same-host Origin checks protect browser mutation paths, with explicit credentialed bridge/webhook exceptions. They are not user authentication against local programs. HTTP MCP has its own bearer-token machinery and mode-dependent authentication, which must not be mistaken for blanket Studio authorization. Do not expose the local configuration as a multi-user internet service. [E7]

Provider API keys are persisted in JSON secret files using atomic writes, directory mode 0700 and file mode 0600—not demonstrated encryption at rest. Custom-provider origin changes require re-entering an existing key, a useful protection against accidentally forwarding it to a new endpoint. Backups of the application data directory can contain credentials; keep them private and separate from source exports. [E8]

“Local” does not mean offline or private by default. Templates may hydrate through LFS or version-pinned hosted bundles; media prompts/references go to configured providers, web publication sends a bundle to hosting, and analytics are **on by default**, including local builds. Tracking documents a persistent opt-out and launch-time `DO_NOT_TRACK=1` / `OPENMOTION_TELEMETRY=0` controls. The receiver's retention/IP handling was not independently audited. [E9], [E11], [E12]

### Cost boundaries

Open-source code does not make coding-agent subscriptions, image/audio/video/3D generation or hosting free. The game handoff instructions actively prefer multimodal generation and describe subscription/top-up paths; spend-consent guidance is conditional on host/Studio settings. Treat that as workflow guidance, not a verified global spending cap. Configure explicit provider budgets and require approval before generation or publishing. No pricing or account entitlement was tested. [media/spend handoff](https://github.com/nexu-io/opengame/blob/f17151f3cc7838ddbe13d9b94392e0f983fc341b/shared/game-contract.ts#L316)

### Persistence, export and recovery

Owned games live under the chosen data directory. File writes reject unsafe paths/symlinks, constrain allowed text files and batch size, stage backups, write metadata last and attempt rollback; failed rollback preserves recovery backups. This is helpful exception recovery, **not demonstrated power-loss durability or full version history**. Mutations are serialized within the service instance; that alone does not prove cross-process transactional safety. [E4]

Template hydration verifies length/SHA-256 and archive entries before atomic installation. These hashes protect integrity relative to the pinned index, not the trustworthiness of its publisher. Export/remix paths exclude local publish records. Keep separate backups of projects/assets and sensitive configuration, rehearse restoration and inspect every output bundle for private data and unresolved external resources. Deleting the Compose data volume deletes the projects/settings it contains. No restore drill or export round trip was run. [E4], [E7], [E11]

## License and Asset Provenance

The root LICENSE is Apache-2.0: reuse code with its notice/attribution obligations and applicable patent terms; it does not grant trademark rights or magically clear third-party content. Dependency licenses need their own inventory. [E14]

Tidebreaker's DESIGN.md claims original generated art and no external runtime dependencies, but also explicitly says browser acceptance was unverified. Its description is pseudo-3D projected rendering, more modest than the README's Three.js framing. The sampled game has no design/assets.csv, despite the README describing that structured inventory broadly. Generated-asset statements and template availability are not a complete chain of rights for all 277 manifests. Before commercial redistribution, inventory art/audio/fonts/models and provider output terms per game; do not assume screenshots, community references or familiar IP are reusable. No source assets were copied into this review. [E1], [E10]

## Maturity, Tests and Claim Evidence

Anonymous GitHub metadata at review time reported **2,097 stars, 343 forks and 73 open issues/PRs combined**, with last push **2026-11-27T16:47:33Z**. The reviewed commit timestamp is **2026-11-27T16:47:30Z**. The releases API returned an empty array and tag enumeration returned no tags; package.json reports private package version 0.0.1. None of this establishes the status of separately hosted packages or release artifacts. [E3], [E15]

There is extensive test source (Node tests, Vitest and browser scripts), including game projects, hosted templates, isolated previews and WeChat integration. CI includes backend/frontend typechecks, Studio tests, deployment and security-scanner steps. **The public “OpenGame checks” workflow for this exact SHA was completed with failure**, while Native device identity succeeded and DSH integration was skipped. Job metadata narrows failures to Transcript workflow browser regression and Video review comments and annotation regression, plus the aggregate gate. Source checks, both Studio shards, runtime/rendering lanes and macOS/Windows workspace reliability passed. These are reported CI outcomes, not locally reproduced defects. [E16]

| Claim | Evidence assessment |
|---|---|
| AAA-grade / AI Unreal or Unity | Marketing; no independent fidelity, performance or production-scale benchmark verified |
| Shared files and editable remix | Supported by domain service and architecture |
| Automated verification | Implemented checks/harnesses; not proof every template passed or that the game is enjoyable |
| 25 templates / 22 agents | README figures conflict with broader current tree/documentation; avoid treating them as exact inventory |
| Monetization-ready | Export and publishing plumbing exist; revenue, store approval and ad-network compliance unverified |
| Offline/local | Cached or bundled content can be local; hydration, providers, telemetry and hosting remain network boundaries |

**Verification limits:** no installs, source execution, tests, browser gameplay, generated media, log-in, paid calls, adversarial probes or performance/security testing. LFS was unavailable during initial checkout; text checkout was recovered without hydrating media, so binary assets and downloadable templates were not validated. Public metadata is a point-in-time observation, and this large repository received a targeted—not exhaustive—static review.

## Comparison

| Aspect | OpenGame | Godot | GDevelop / Phaser |
|---|---|---|---|
| Primary fit | Agent-assisted browser prototypes and media workflow | Conventional engine/editor development for deeper game systems | GDevelop: event-based authoring; Phaser: code-first web games |
| AI dependency | Bring an agent/provider for generation; local source remains editable | AI is optional to core engine workflow | AI optional to conventional event/code workflow |
| Tradeoff | Fast template remix plus integrated QA, but broad execution/service trust | More manual authoring and engine learning; clearer conventional runtime ownership | Less integrated multimodal orchestration; narrower established browser-game focus |

Prefer [Godot](https://godotengine.org/) for substantial engine-led work, [GDevelop](https://github.com/4ian/GDevelop) for visual/event authoring, or [Phaser](https://github.com/phaserjs/phaser) for a focused browser codebase. These are fit comparisons, not benchmark results or current license audits of the alternatives. OpenGame is most compelling when agent-assisted remix and asset orchestration are the actual requirement.

## Self-Hosting Notes

Start with a disposable single-user environment, loopback binding, telemetry disabled if unwanted, a dedicated data directory outside the checkout and narrowly scoped provider credentials. Docker is a useful host boundary, not proof that different games inside it are mutually isolated. Back up the persistent volume without publishing its secret files. Confirm the selected agent's permission behavior, establish a spend budget, inspect generated code, then perform real-browser/mobile tests and export/restore checks before sharing. Do not upgrade a local setup into public hosting merely by changing its bind address. [E6], [E7], [E8], [E9]

## Evidence

All repository citations below are pinned to the reviewed SHA; external documentation and GitHub metadata are point-in-time sources.

[E1]: https://github.com/nexu-io/opengame/blob/f17151f3cc7838ddbe13d9b94392e0f983fc341b/README.md
[E2]: https://github.com/nexu-io/opengame/blob/f17151f3cc7838ddbe13d9b94392e0f983fc341b/docs/opengame-architecture.md
[E3]: https://github.com/nexu-io/opengame/blob/f17151f3cc7838ddbe13d9b94392e0f983fc341b/package.json
[E4]: https://github.com/nexu-io/opengame/blob/f17151f3cc7838ddbe13d9b94392e0f983fc341b/game-projects.ts
[E5]: https://github.com/nexu-io/opengame/blob/f17151f3cc7838ddbe13d9b94392e0f983fc341b/gateway/local-game-preview.ts
[E6]: https://github.com/nexu-io/opengame/blob/f17151f3cc7838ddbe13d9b94392e0f983fc341b/gateway/super-agent-adapters.ts
[E7]: https://github.com/nexu-io/opengame/blob/f17151f3cc7838ddbe13d9b94392e0f983fc341b/deploy/README.md
[E8]: https://github.com/nexu-io/opengame/blob/f17151f3cc7838ddbe13d9b94392e0f983fc341b/gateway/connections.ts
[E9]: https://github.com/nexu-io/opengame/blob/f17151f3cc7838ddbe13d9b94392e0f983fc341b/tracking/README.md
[E10]: https://github.com/nexu-io/opengame/blob/f17151f3cc7838ddbe13d9b94392e0f983fc341b/templates/games/tidebreaker/DESIGN.md
[E11]: https://github.com/nexu-io/opengame/blob/f17151f3cc7838ddbe13d9b94392e0f983fc341b/shared/hosted-game-templates.ts
[E12]: https://github.com/nexu-io/opengame/blob/f17151f3cc7838ddbe13d9b94392e0f983fc341b/gateway/web-publish.ts
[E13]: https://nodejs.org/api/vm.html
[E14]: https://github.com/nexu-io/opengame/blob/f17151f3cc7838ddbe13d9b94392e0f983fc341b/LICENSE
[E15]: https://api.github.com/repos/nexu-io/opengame
[E16]: https://github.com/nexu-io/opengame/actions/runs/46036570106

Additional implementation evidence: [preview iframe](https://github.com/nexu-io/opengame/blob/f17151f3cc7838ddbe13d9b94392e0f983fc341b/studio/src/motion/game/GameStudio.tsx#L619), [HTTP guards](https://github.com/nexu-io/opengame/blob/f17151f3cc7838ddbe13d9b94392e0f983fc341b/server.ts#L503-L565), [MCP auth](https://github.com/nexu-io/opengame/blob/f17151f3cc7838ddbe13d9b94392e0f983fc341b/gateway/mcp-http.ts), [secret file permissions](https://github.com/nexu-io/opengame/blob/f17151f3cc7838ddbe13d9b94392e0f983fc341b/gateway/settings-storage.ts), [media/spend handoff](https://github.com/nexu-io/opengame/blob/f17151f3cc7838ddbe13d9b94392e0f983fc341b/shared/game-contract.ts#L316), [template tree](https://github.com/nexu-io/opengame/tree/f17151f3cc7838ddbe13d9b94392e0f983fc341b/templates/games), [CI definition](https://github.com/nexu-io/opengame/blob/f17151f3cc7838ddbe13d9b94392e0f983fc341b/.github/workflows/ci.yml), [releases API](https://api.github.com/repos/nexu-io/opengame/releases).

---

**Attribution:** nexu-io/opengame and its contributors; Apache-2.0. Independent public-source analysis; no affiliation implied.
