# MutinyBIM (permitzip/mutinybim)

**Repo:** https://github.com/permitzip/mutinybim
**License:** Apache-2.0 code; trademarks/artwork excluded; third-party terms apply.
**Reviewed:** 2026-11-12 (UTC)
**Revision:** `94513ba243fac72359573ee472481c4f33f949da`, main snapshot; repository-wide architecture with sampled kernel, IFC, script/MCP, web host, model authority, tests and CI.
**Verification:** Static review only. No installation, source execution, model/API calls, deployment, private drawings or live service probes. Public GitHub CI metadata checked separately.
**Stack:** TypeScript, Node >=22.13, React 19, Three.js, manifold-3d, web-ifc, MCP SDK, SQLite and optional PostgreSQL.
**What it is:** A browser-based collaborative building-model engine with trade add-ons and a shared command interface for people and AI agents—not merely a BIM viewer or a prompt-to-picture demo.

## Verdict

⚠️ **Interesting — pilot the shared engine, not an unqualified replacement for production BIM.** The common command kernel, typed units, registry-driven IFC mappings and server-side sequencing are substantive engineering. However, editable IFC conversion is deliberately partial, deployment modes have materially different durability and security, and neither cited calculations nor a convincing viewport prove engineering compliance. Qualify a pinned revision with synthetic exchange and recovery cases before using project data.

## What It Is

PermitZIP maintains MutinyBIM and says it uses the engine in its engineering work. That is a maintainer claim, not independently verified production evidence. Its public repository was created on 2026-11-09; the inspected source is much larger than a three-day toy, but public operating history is very short. The README explicitly calls it early and distinguishes the engine from a complete hosted product. [S1]

The workspace includes architecture, structural, civil, site, development, electrical, mechanical and plumbing/gas packages, a first-party bundle including fire protection, sheet/PDF tooling, and plan/3D editing. Some editor screens require host services and are unavailable in the local demo. A separate open web app adds accounts, sharing, saved models, external-assistant authorization and browser BYOK AI; do not assume all hosts have identical capabilities. [S1, S7]

## Stack

| Layer | Implementation |
|---|---|
| Foundations | Typed quantities and conversion; formula language; manifold-3d solid programs and mesh cache |
| Model | Trade-neutral kernel, intent commands, registries, changesets and add-on contract |
| Collaboration | Shared sync protocol and sequencer; lease-owning PostgreSQL authority or in-memory hosts |
| UI / output | React, Three.js, plan/editor components, PDF sheets, STEP/IFC 4.3 export |
| Agent surface | MCP stdio/HTTP, small core plus tool packs, script preview/landing, host approval hooks |
| Open web host | Node HTTP server, node:sqlite account records, per-model JSON snapshot files |

## Key Features and Architecture

### One semantic editing path

Clients preview intent commands, while the authority re-executes against the current model and publishes changesets. The database store guards writes with revision, epoch and lease ownership/generation; idempotent outcomes help reconcile lost answers rather than blindly replaying edits. This is stronger than letting an agent directly rewrite a scene JSON file. The guarantee depends on the chosen store/host, not just the shared UI. [S2]

### Trade extension contract

Add-ons contribute domain classes and services through a versioned contract. The kernel is meant to remain trade-neutral; import-layer, cycle and boundary checks appear in CI. Typed quantities and explicit unit conversions are a useful defense against silent dimensional mistakes, but cannot establish that the input, selected method or jurisdiction is correct. Calculation outputs distinguish code, design criteria and method citations and carry versioned inputs/results. [S1, S3, S10]

### Scripts with preview and approval

The local MCP host defaults to elicitation approval and refuses clients unable to ask. There is also an explicit auto-approval demo mode. The generic host-decided gate returns approval and trusts the embedding application to have obtained it already. Thus “nothing lands until a person approves” is a host configuration/implementation obligation, not an unconditional property of every deployment. Hosted external-assistant approvals have database-backed pending records and a 30-minute decision window. [S4, S7]

## BIM / CAD Interoperability and Fidelity

**IFC is implemented, but interchange is not synonymous with lossless authoring.** Export builds STEP Part 21 / IFC 4.3 data from class registries, units, spatial structure and properties. Missing/invalid IFC class hints fall back to `IfcBuildingElementProxy` with a diagnostic; some kinds are explicitly skipped. Consumers must read the export report, not just check that a file opens. Stable GUID and synthetic export tests are present. [S5]

Geometry output uses extrusions and triangulated face sets; mesh vertices round to 0.01 mm, and elements without stated size can have placement without a body. That rounding is an implementation choice, not an accuracy certification. Core coordinates are millimetres, x east/y north/z up; non-length properties convert to appropriate coherent SI project units. Unknown/unmapped units can become plain IFC real values without unit metadata. [S5]

Import reads neutral products and plans conversion through rules/registries. The geometry reader supports selected local placements, extruded rectangle/circle/polyline profiles, mapped items, bounding boxes and mesh bounds; a standard steel section may be represented by its bounding rectangle. Unsupported shapes are reported and retained on the linked reference rather than magically converted into fully editable solids. Conversion-based feet/inches and SI prefixes are recognized; absent/unrecognized length assignment falls back to 1000 mm per unit, so malformed files require explicit scale checks. A linked IFC viewport is therefore not proof that native editable semantics survived. [S6]

The geometry package also exposes OBJ/glTF mesh-body readers. These are not equivalent to parametric CAD history, fabrication tolerances or native Revit-family round trips. No end-to-end native RVT/DWG fidelity was established. Before adoption, test known-size metric/imperial fixtures, rotated/nested placements, slopes, openings, space boundaries, GUIDs, classifications, properties, quantities and unsupported-element reports in an independent receiving application. Validate georeferencing and drawing/PDF scale separately. No such runtime exchange tests were performed here.

## Engineering Authority: More Than Visualization, Less Than Certification

This is an editing/calculation engine, not only visualization. Nevertheless, deterministic calculations, citations, clash lint and typed units do not make a permit-ready design. The README explicitly assigns responsibility to a licensed professional, notes values/formulas needing checks, and excludes licensed fitting-loss databases. Confirm adopted code edition, local amendments, manufacturer data, coefficient provenance, load cases and discipline review. A valid mesh or successful IFC export proves none of those. [S1, S3]

## Security, Permissions and Privacy

- **Local versus hosted script execution:** LocalScriptRunner creates a fresh capped Node child with empty environment and filesystem/process restrictions, but explicitly warns that Node permissions do not seal sockets. Its VM context is not a hostile-code security boundary. Hosted scripts instead have a Linux bubblewrap path with separate network/user/process namespaces, read-only runner files, dropped capabilities, prlimit controls, bounded concurrency and a fail-closed availability check. These are inspected controls, not penetration-tested guarantees; the JavaScript heap cap is not a total-process/cgroup memory limit. [S4, S7]
- **Local MCP is not a public service:** HTTP defaults to loopback, limits request bodies and enables SDK DNS-rebinding protection. No account authentication is implemented in that local transport. Do not expose it by changing the bind address or placing an unauthenticated proxy in front of it. The local Compose sign-in intentionally trusts anyone who reaches it; published ports are loopback-only. [S4, S9]
- **Hosted identity:** Passwords use scrypt; session/reset/assistant tokens are stored as digests. The web host has membership checks, same-site/origin defenses and separate assistant bearer/OAuth flows; the model authority verifies issuer/audience through configured JWKS sources. These paths are not interchangeable with the demo identity. Linked-host passes use AES-256-GCM with current/previous key support; encryption-key custody remains the operator's responsibility. [S7, S8]
- **Outbound metadata hardening needs another pass:** Assistant client metadata rejects private DNS answers and redirects, but then performs an ordinary hostname fetch rather than pinning the validated address. DNS re-resolution remains a security-review concern. The claimed 5 KB document limit is checked after `response.text()`, not as a streaming byte cap. These are static code observations, not demonstrated exploits. Configured OAuth/linked-host endpoints are trusted operator-controlled network destinations. [S7]
- **BYOK means browser-retained, not secret-free:** `client/ai.ts` stores provider settings including the key in localStorage and calls Anthropic/OpenAI/xAI or an HTTPS compatible endpoint directly. The model request sends system text and the question; connected assistants also receive tool/model data according to access. Same-origin script compromise or an exposed browser profile can disclose the key. Forgetting settings removes that local entry, not provider logs or previously transmitted content. Review model-data confidentiality and provider retention before enabling AI. [S8]

## Persistence, Retention and Recovery

There are three materially different storage stories:

1. **Demo/local memory:** stopping the server loses unsaved model state. Local MCP script library/previews are also process memory.
2. **Open web app:** account/access records are SQLite; model history, branches and versions live in JSON snapshots. Changes schedule a save after 750 ms, using a temporary file and rename. Save failure is logged and retried on the next change. Atomic replacement reduces torn-file risk but is not synchronous commit durability; a crash can lose acknowledged recent edits, and there is no fsync in the inspected persistence path. Deletion renames a snapshot with a deleted timestamp rather than erasing it, so recovery and retention/privacy policies must account for these retained files.
3. **Model authority:** PostgreSQL provides durable fenced commits, lease renewal and outcome reconciliation. That architecture is stronger for shared use but still needs tested backups, migrations, restore and authorization configuration. A branch/version is not an independent disaster-recovery backup. [S2, S7, S9]

Back up accounts/access records and model files together, preserve linked-host key material separately, and test full restore and permission revocation. Removing a Compose volume deletes its stored models. No crash drill, restore exercise or retention-erasure verification was run for this review.

## Self-Hosting, Costs and Update Risks

The declared minimum is Node 22.13. The simple demo needs no Docker; the full local authority stack uses Compose v2 and PostgreSQL 17. Browser 3D requires suitable graphics support/resources. The hosted sealed-script path specifically requires Linux, bubblewrap/prlimit, a compatible namespace configuration and its prebuilt runner; generic Node portability does not imply sandbox portability. [S1, S7, S9]

The engine does not require a paid AI provider. BYOK calls and external assistant subscriptions/API usage are separate costs; “free hosted app” does not mean free inference. The browser adapter has no aggregate spend ledger/budget enforcement in the inspected file, and the OpenAI-compatible request does not set an explicit output-token cap. Also budget RAM/CPU, database storage, backups and operations; synthetic 250k-element perf gates are not guarantees for every real model or hardware configuration. [S8, S10]

Root dependency versions and a lockfile are present, but npm installation runs a substantial tool/native/WASM dependency supply chain. Docker base-image tags and GitHub Action major-version tags are not immutable digests. Pin the reviewed revision, inspect release/migration differences, back up before upgrades and qualify exports after changes. No installs, package audit or dependency vulnerability scan were performed.

## License, Tests and Maturity

Apache-2.0 allows commercial reuse subject to its terms, including notices and the patent conditions; it does not grant the MutinyBIM trademarks/artwork. NOTICE identifies OFL fonts, MIT shadcn components and unmodified MPL-2.0 dependencies including web-ifc/resvg/lightningcss. The generated dependency inventory also lists LGPL-3.0-or-later sharp-libvips platform artifacts: a redistributed bundle needs its own actual dependency/license inventory, not an “everything is Apache” assumption. No upstream code was extracted into this review. [S11]

At retrieval, GitHub reported **72 stars, 8 forks, 37 open issues/PRs combined**, a last push of 2026-11-11T23:23:14Z and latest published release **v0.2.18** (2026-11-11T23:23:18Z). The inspected root manifest still says 0.2.0; use the SHA rather than treating package metadata as the release identity. Popularity and rapid release count are not quality evidence.

Static inventory found **857 files named *.test.ts** (not a test-case/pass count). Tests cover GUIDs, exports/import reports, units, geometry and architecture boundaries among many other areas. CI defines lint/license checks, typechecking, sharded Jest, authority typecheck/Docker build and secret scanning; a separate perf gate and optional million-element workflow exist. Public GitHub metadata reported successful [CI](https://github.com/permitzip/mutinybim/actions/runs/43118201151), [Perf gate](https://github.com/permitzip/mutinybim/actions/runs/43118201192) and [Release](https://github.com/permitzip/mutinybim/actions/runs/43119246054) runs for the exact reviewed SHA. This is upstream execution evidence, not locally reproduced test, benchmark or engineering validation. [S10]

## Comparison and Practical Fit

| Option | Prefer it when | Trade-off relative to MutinyBIM |
|---|---|---|
| [Bonsai / IfcOpenShell](https://bonsaibim.org/) | IFC-native authoring, inspection and exchange are central | More established IFC-oriented ecosystem; different desktop workflow rather than this shared browser/agent kernel |
| [FreeCAD](https://www.freecad.org/) | Parametric geometry and desktop CAD/BIM workflows matter most | Different collaboration/automation model; evaluate BIM exchange separately |
| [That Open](https://github.com/ThatOpen/engine_components) | Building a browser IFC viewer/coordination application | Viewer components are not a complete authoritative multidisciplinary model editor |
| Existing qualified BIM authoring workflow | Contractual deliverables/native interchange are non-negotiable | Retain established project validation; test MutinyBIM as a bounded companion rather than replacing it on appearance alone |

The existing [text-to-cad review](text-to-cad.md) covers an agent-oriented CAD workflow, not equivalent BIM semantics or collaboration. No comparative benchmark or alternative installation was conducted.

**Recommended acceptance gate:** use synthetic models only at first; inspect export diagnostics and independent IFC validation; verify calculations with licensed discipline reviewers; prove concurrent edit/conflict handling and recovery on the selected store; test approval/revocation boundaries; and explicitly consent to provider data egress. Promote only the capabilities that pass. No extraction is needed merely to demonstrate value—the shared command/host boundary is already the useful architectural lesson.

## Evidence and Limitations

All source links below are pinned to the reviewed revision. Public source and metadata only; no private project context. Sampling is not an exhaustive security audit, code-compliance certification, performance measurement or BIM conformance assessment. UI rendering, installation/update compatibility, OAuth interoperability, native exports, provider behavior and recovery remain unverified locally.

- **S1:** [README and scope](https://github.com/permitzip/mutinybim/blob/94513ba243fac72359573ee472481c4f33f949da/README.md)
- **S2:** [Fenced PostgreSQL store](https://github.com/permitzip/mutinybim/blob/94513ba243fac72359573ee472481c4f33f949da/services/bim-authority/src/pg-store.ts)
- **S3:** [Calculation contract](https://github.com/permitzip/mutinybim/blob/94513ba243fac72359573ee472481c4f33f949da/packages/bim-calc/src/types.ts)
- **S4:** [Approval gates](https://github.com/permitzip/mutinybim/blob/94513ba243fac72359573ee472481c4f33f949da/packages/bim-mcp/src/approvals.ts)
- **S5:** [IFC export](https://github.com/permitzip/mutinybim/blob/94513ba243fac72359573ee472481c4f33f949da/packages/bim-ifc/src/export.ts)
- **S6:** [Partial editable import](https://github.com/permitzip/mutinybim/blob/94513ba243fac72359573ee472481c4f33f949da/packages/bim-ifc/src/import/geometry.ts)
- **S7:** [Web host](https://github.com/permitzip/mutinybim/blob/94513ba243fac72359573ee472481c4f33f949da/apps/mutinybim-web/src/app.ts)
- **S8:** [Browser AI](https://github.com/permitzip/mutinybim/blob/94513ba243fac72359573ee472481c4f33f949da/apps/mutinybim-web/client/ai.ts)
- **S9:** [Local stack](https://github.com/permitzip/mutinybim/blob/94513ba243fac72359573ee472481c4f33f949da/docker-compose.yml)
- **S10:** [CI](https://github.com/permitzip/mutinybim/blob/94513ba243fac72359573ee472481c4f33f949da/.github/workflows/ci.yml)
- **S11:** [License notices](https://github.com/permitzip/mutinybim/blob/94513ba243fac72359573ee472481c4f33f949da/NOTICE)

Additional implementation evidence: [IFC units](https://github.com/permitzip/mutinybim/blob/94513ba243fac72359573ee472481c4f33f949da/packages/bim-ifc/src/units.ts), [geometry export](https://github.com/permitzip/mutinybim/blob/94513ba243fac72359573ee472481c4f33f949da/packages/bim-ifc/src/geometry.ts), [IFC class fallback](https://github.com/permitzip/mutinybim/blob/94513ba243fac72359573ee472481c4f33f949da/packages/bim-ifc/src/mapping.ts), [import units](https://github.com/permitzip/mutinybim/blob/94513ba243fac72359573ee472481c4f33f949da/packages/bim-ifc/src/import/read-products.ts), [local runner](https://github.com/permitzip/mutinybim/blob/94513ba243fac72359573ee472481c4f33f949da/packages/bim-script-runner/src/local.ts), [HTTP transport](https://github.com/permitzip/mutinybim/blob/94513ba243fac72359573ee472481c4f33f949da/packages/bim-mcp/src/transports.ts), [hosted sandbox](https://github.com/permitzip/mutinybim/blob/94513ba243fac72359573ee472481c4f33f949da/apps/mutinybim-web/src/script-sandbox.ts), [snapshots](https://github.com/permitzip/mutinybim/blob/94513ba243fac72359573ee472481c4f33f949da/apps/mutinybim-web/src/models.ts), [metadata fetching](https://github.com/permitzip/mutinybim/blob/94513ba243fac72359573ee472481c4f33f949da/apps/mutinybim-web/src/assistant-auth.ts), [linked-host encryption](https://github.com/permitzip/mutinybim/blob/94513ba243fac72359573ee472481c4f33f949da/apps/mutinybim-web/src/linked-hosts.ts), [dependency inventory](https://github.com/permitzip/mutinybim/blob/94513ba243fac72359573ee472481c4f33f949da/THIRD_PARTY_LICENSES.md), [public repository metadata](https://api.github.com/repos/permitzip/mutinybim).

---
**Attribution:** PermitZIP / permitzip/mutinybim; Apache-2.0 code and separately noted third-party/asset terms. Review is independent analysis.
