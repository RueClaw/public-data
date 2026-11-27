# Blender Skills (arjun988/blender-skills)

**Repo:** https://github.com/arjun988/blender-skills
**License:** MIT for the skill pack; retain copyright and permission notices when reusing substantial material. Blender, the external MCP bridge, downloaded assets and generation services have separate terms.
**Reviewed:** 2026-11-27 (UTC)
**Revision:** 904f095d8f36a6e72adaebb08d07f884a074743d; repository-wide inventory, with detailed inspection of manifests, setup, director, shared execution/validation references, rendering, QA and website privacy policy.
**Verification:** Static review only. Anonymous GitHub API and HTTPS source access succeeded. No skills installed, source code executed, Blender launched, renders generated or paid services called.
**Stack:** Markdown skill instructions, JSON MCP/plugin manifests, external Python/bpy BlenderMCP integration; separate Next.js 14 / React 18 / TypeScript / Tailwind documentation site.
**What it is:** A broad technical-art instruction library for coding agents controlling Blender through a separately installed MCP bridge—not a modeling engine or a bundled Blender add-on.

## Verdict

⚠️ **Interesting: useful production checklists, not a verified autonomous art team.** The camera-first reference workflow, explicit budgets and screenshot-backed QA are sensible scaffolding. Actual results and safety depend on the model, client permissions, external BlenderMCP version and Blender environment. Use selected skills in a disposable project with human review; do not treat the pack as a security boundary or proof of game-ready output.

## What It Is

The source advertises 94 specialized skills for Claude Code, Cursor, Kiro and Codex. File inventory confirms **94 SKILL.md files and 175 reference Markdown files** in the Claude tree; byte comparison found the Cursor mirror identical. The director routes a brief through modeling, materials, UVs, rigging, animation, rendering, optimization and export specialists. Additional packs cover genres, moods, art styles, worlds and character archetypes. Reference-image matching is a **shared reference document**, despite being presented like a routable skill in some examples. [S1][S2][S4]

These are model-consumed instructions, not 94 executable tools. The pack documents scene queries, viewport screenshots, object/material operations and arbitrary Python execution supplied by **ahujasid/blender-mcp**. It explicitly says live MCP schemas are authoritative: the catalog does not prove a named tool exists in every bridge version. [S5][S6]

## Stack

| Layer | Technology / boundary |
|---|---|
| Agent behavior | Markdown skills, specialist references and director routing |
| Client registration | Claude plugin manifests; project MCP JSON; mirrored Cursor skill tree |
| Execution | External uvx-launched blender-mcp and separately downloaded Blender add-on |
| Scene API | Blender Python bpy through execute_blender_code where dedicated tools are unavailable |
| Documentation | Separate Next.js/React site; not the modeling runtime |
| Authorization | Host client, OS and external add-on controls; no enforcement implementation in this pack |

The two MCP configs invoke Windows **cmd /c uvx --python 3.11 blender-mcp**, select localhost port 9876, request managed Python and set DISABLE_TELEMETRY=true. These are not portable Linux/macOS launch commands as written. Neither the bridge package nor the add-on download from upstream main is pinned to an exact release/hash. Pinning Python 3.11 does not pin the bridge or its dependencies. [S3][S5]

## Key Features

### Planning before scene edits

The director requests a production brief with target engine, style, triangle/texture budgets, pivot, export format and ordered operations. Naming and collections separate references, blockouts, high/low-poly meshes and export objects. This is useful coordination, but a written brief is not an enforced human approval checkpoint. [S4][S6]

### Camera-first visual iteration

Reference matching orders analysis and camera alignment before fine geometry, then materials, lighting and screenshot comparisons, capped at three iterations. QA asks for evidence and explicit SHIP / SHIP WITH NOTES / NO-SHIP results. These are better prompts than an unqualified “looks good” completion. [S4][S7][S8]

### Export and production coverage

Specialists cover Unity, Unreal and Godot delivery, LODs, collision proxies, UVs and texture baking. The shared validation checklist includes target-engine pivot/scale verification, topology, material and triangle budgets. It is a human/agent checklist rather than an automated validator or demonstrated engine round-trip suite. [S1][S9]

## Architecture and Permission Boundaries

The runtime path is **agent client → external MCP process → Blender add-on → Blender scene / bpy**. No bridge server implementation is bundled here. This review therefore does not certify socket authentication, binding behavior, request validation or upstream sandboxing. Localhost in the client configuration is a destination, not proof of the server's security configuration. [S3][S5][S6]

The setup guide explicitly warns that execute_blender_code runs arbitrary Python in Blender. It should be treated as code execution with the Blender process's OS privileges, not scene-only permission. Save, export, render and asset operations can write files; unrestricted Python can potentially read other accessible files, access the network or start processes unless external controls prevent it. The pack supplies no filesystem allowlist, network egress policy or capability sandbox. This is a trust-boundary assessment, not a demonstrated exploit. [S5][S6]

Instructions prefer execution over UI guidance and ask for backups before destructive operations. They do not implement per-action consent for deletion, overwriting exports, uploads, external asset retrieval or paid generation. Client approvals and OS isolation must supply those boundaries. Recommended operating policy: separate inspection from mutation, explicitly approve destructive writes and outbound/paid calls, scope writable project directories, deny unnecessary secrets and keep the bridge local. Do not automatically execute instructions embedded in imported assets or reference material. [S4][S5][S6]

## Asset Provenance and License

The MIT license covers the repository's software/documentation under its stated terms; it does not grant rights to reference images, recognizable logos, franchise designs, downloaded models or generated outputs. The tool catalog recommends verifying Poly Haven's CC0 status for shipping assets; the setup also mentions Sketchfab, Hyper3D and Hunyuan3D. Keep per-asset origin, actual license, attribution and modification records rather than assuming every download is CC0. No per-asset clearance ledger or provenance enforcement is supplied. [S5][S6][S10]

Style/franchise references and the visual checklist's request to reproduce decals/logos are artistic directions, not a rights clearance. Obtain permission for supplied reference images and review trademark/copyright risks before distribution. The reviewed repository contains branding images, not a reproducible collection of licensed benchmark scenes. No source material was extracted into a separate reusable component for this review. [S1][S7]

## Evaluation, Render Quality and Maturity

“Senior Technical Art team,” “AAA” and “game-ready” are positioning and target outcomes, not verified capabilities. No tracked automated test suite, CI workflow, benchmark scenes, golden renders or model/version-specific evaluation results were found. The documentation site's package scripts contain dev/build/start/export, not a test command. No source test or site build was run. [S1][S4][S11]

There is a concrete rubric defect: the visual-match checklist requires **at least 8/10 categories** rated Match or Close, but its report table enumerates only **six categories** (camera, silhouette, depth, materials, lighting and grading). The pass denominator is underspecified. This weakens reproducibility even before considering subjective agent scoring. [S7]

The rendering skill gives Cycles sampling ranges, denoising, engine selection and pass guidance, but mixes legacy Eevee-style settings with Blender 4+ guidance. Setup says Blender 3.0+, while references discuss AgX and Eevee Next. Without a version matrix or runtime checks, compatibility and render quality must be verified for the actual Blender release. Production sampling ranges do not guarantee quality or establish rendering cost. [S5][S12]

Public metadata at retrieval: **5,063 stars, 466 forks, 6 open issues/PRs combined**; latest push 2026-11-06. These are activity indicators, not quality evidence. version.json and plugin metadata declare **1.3.0**, dated 2026-07-10; anonymous releases and tags endpoints returned empty lists. This review pins the commit, not an independently published release. Commit time is 2026-11-06T08:42:29Z. [S2][S13]

## Cost and Privacy

The pack is MIT and has no bundled paid runtime requirement, but the overall workflow may incur agent subscription/token charges, GPU/CPU rendering time, asset purchases and generation API charges. Repeated screenshot loops and high-sample rendering can be expensive. No cost accounting or enforced budget limiter was found; approve provider use and spending explicitly. [S5][S12]

The website privacy page says the local files collect no data and claims no data leaves the system through Blender MCP, while also acknowledging agent-platform prompt processing. The broader no-egress wording should **not** be read as an end-to-end guarantee: this same repository documents remote asset downloads and optional generation APIs, and screenshot/reference/scene content may be supplied to a hosted agent. DISABLE_TELEMETRY=true is configuration intent, not verified absence of collection across the external bridge, providers or clients. No network trace or provider-retention audit was performed. [S3][S5][S14]

## Recovery and Operational Fit

Positive guidance includes saving the .blend file before code execution, hidden backup collections, incremental operations, scene re-querying after phases and smaller operations after timeouts. Fallback mode provides planning and bpy scripts when MCP is unavailable. [S5][S6]

Recovery is procedural, not transactional: no durable job log, automatic rollback, idempotency keys or tested restore flow is implemented in this pack. Setup's suggestion to retry a failed first command can duplicate or compound a mutation if the first call succeeded before timing out. Inspect scene state before retrying, use versioned project copies and retain external backups; a hidden collection does not recover overwritten external files. [S5][S6]

## Comparison

| Approach | Strength | Tradeoff |
|---|---|---|
| Blender Skills | Reusable discipline prompts, routing and QA structure | Depends on model judgment; no runtime or enforced gates |
| Direct BlenderMCP | The actual live Blender tool bridge | Still needs workflow planning, approval and validation policies |
| Reviewed bpy scripts / manual Blender workflow | Explicit operations and artist-controlled acceptance | More up-front scripting or hands-on work; no automatic broad specialist routing |

For a narrow repeatable production operation, a reviewed version-specific script and fixture tests are easier to verify than a broad agent persona. This pack is more useful as an editable art-production reference library than as an unattended deployment recommendation.

## Verification and Limitations

Completed: anonymous source/API access, exact SHA and metadata capture, canonical-source deduplication, file inventory/counts, byte-for-byte mirror comparison, manifest parsing and targeted source inspection. Publication artifacts were checked for citation targets, safe links, template-only CSS/JS, unresolved tokens, public-only content and scoped changes. No Blender/MCP sessions, installs, renders, provider calls, engine imports, visual-quality measurements or dependency vulnerability audit were performed. External bridge behavior was assessed only as documented here, not independently audited.

## Evidence

All source-file citations below are pinned to the reviewed commit. Repository API observations are retrieval-time metadata, not immutable evidence.

[S1]: https://github.com/arjun988/blender-skills/blob/904f095d8f36a6e72adaebb08d07f884a074743d/README.md
[S2]: https://github.com/arjun988/blender-skills/blob/904f095d8f36a6e72adaebb08d07f884a074743d/version.json
[S3]: https://github.com/arjun988/blender-skills/blob/904f095d8f36a6e72adaebb08d07f884a074743d/.mcp.json
[S4]: https://github.com/arjun988/blender-skills/blob/904f095d8f36a6e72adaebb08d07f884a074743d/.claude/skills/blender-director/SKILL.md
[S5]: https://github.com/arjun988/blender-skills/blob/904f095d8f36a6e72adaebb08d07f884a074743d/docs/BLENDER_MCP_SETUP.md
[S6]: https://github.com/arjun988/blender-skills/tree/904f095d8f36a6e72adaebb08d07f884a074743d/.claude/skills/references
[S7]: https://github.com/arjun988/blender-skills/blob/904f095d8f36a6e72adaebb08d07f884a074743d/.claude/skills/references/visual-match-checklist.md
[S8]: https://github.com/arjun988/blender-skills/blob/904f095d8f36a6e72adaebb08d07f884a074743d/.claude/skills/qa-review/SKILL.md
[S9]: https://github.com/arjun988/blender-skills/blob/904f095d8f36a6e72adaebb08d07f884a074743d/.claude/skills/references/validation-checklist.md
[S10]: https://github.com/arjun988/blender-skills/blob/904f095d8f36a6e72adaebb08d07f884a074743d/LICENSE
[S11]: https://github.com/arjun988/blender-skills/blob/904f095d8f36a6e72adaebb08d07f884a074743d/site/package.json
[S12]: https://github.com/arjun988/blender-skills/blob/904f095d8f36a6e72adaebb08d07f884a074743d/.claude/skills/rendering/SKILL.md
[S13]: https://api.github.com/repos/arjun988/blender-skills
[S14]: https://github.com/arjun988/blender-skills/blob/904f095d8f36a6e72adaebb08d07f884a074743d/site/src/app/privacy/page.tsx

**Attribution:** arjun988/blender-skills and blender-skills contributors; MIT. External bridge credited by the source: ahujasid/blender-mcp. Analysis is independent; upstream claims are not endorsements.
