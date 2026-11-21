# Cook (Leonxlnx/cook)

**Repo:** https://github.com/Leonxlnx/cook
**License:** MIT, copyright 2026 Leon Lin; preserve the copyright and permission notice when redistributing substantial portions. Reference media and generated-project dependencies have separate rights.
**Reviewed:** 2026-11-21 (UTC)
**Revision:** b23cac6fd9439dfddcab61b14808e7bf72549b46 (main); whole tracked repository: skill, five reference documents, two templates, comparison helper, README, LICENSE and ignore rules.
**Verification:** Static source review and unauthenticated public GitHub metadata only. No source execution, installation, agent run, model call, rendering or deployment; no tests run.
**Stack:** Markdown agent instructions; one Node.js ES module using built-ins and an externally installed FFmpeg. Optional documented color-check snippet uses Python, Pillow and NumPy.
**What it is:** A reference-driven visual-production skill for coding agents, not a cooking app, model, renderer or autonomous-agent runtime. It organizes 3D scenes, motion/video and UI work into repeated build–render–critique rounds.

---

## Verdict

⚠️ **Interesting: a useful visual iteration playbook, not a safe unattended execution controller.** Fixed shots, independent critics, explicit evidence and a round ledger are practical ideas. Its near-unreachable quality targets, minimum-time defaults and “never ask again” rule require external permission checks and hard spend/time limits before any real use; Markdown cannot enforce them.

## What It Is

Cook supplies an agent-facing SKILL.md, progressive reference documents, brief/ledger templates and a small image comparison helper. The host agent must build the actual rendering harness, perform project edits, invoke tools, launch critics, send previews and manage continuity. Three.js, WebGL and Remotion are examples of target stacks, not bundled implementations.

The proposed loop captures all intake questions, maps references to fixed shots, scores composition/light/color/materials/detail/motion, fixes the weakest dimension, renders comparisons and repeats. Final long exports require explicit approval of stills; publishing defaults to disallowed. This is a good separation of preview review from expensive export, but the rules are instructions rather than executable gates. [E1–E4]

## Stack

| Layer | Implementation |
|-------|----------------|
| Orchestration | Host coding agent interprets Markdown; no scheduler or agent SDK |
| Persistent state | Project-local cook/ files, stills and comparisons |
| Comparison utility | Node 18+ as documented; child_process.spawnSync + fs; FFmpeg from PATH |
| Optional measurement | Python/Pillow/NumPy snippet for regional HSV saturation/brightness |
| Rendering / inference | Supplied by the user's project, agent harness and chosen model services |
| Auth / server / database | None implemented by Cook |

## Key Features

### Reproducible viewpoints and evidence-led rounds

Fixed camera/viewport presets and reference-matched framing make changes easier to compare. Measured frame times and color deltas are kept separate from subjective scores, and the ledger records what was not checked. This is stronger than a single “looks good” completion claim. The color example measures saturation and brightness, not perceptual similarity, layout or semantic fidelity. [E2, E3, E5]

### Critics with less builder-context bias

The playbook asks for at least two fresh-context critics, median dimension scores, another critic on large disagreements and calibration against user feedback. Different models are optional; independence is not guaranteed, and no benchmark establishes calibration quality. The documented 99.9% target is explicitly a motivational stretch, not a validated accuracy metric. The fallback permits self-scoring when a fresh session is unavailable, weakening the otherwise independent stop criterion. [E2, E3]

### A readable handoff ledger

BRIEF, SHOTS and recent ROUNDS entries support context-reset handoff. Still/comparison directories are organized by round, a “best so far” pointer supports rollback, and local commits are recommended after each round. These are sensible conventions, not implemented transactional persistence or automatic recovery. [E1, E3, E7]

## Architecture and Implementation

The executable surface is only scripts/side-by-side.mjs (75 lines). It parses output path, height, aspect and alternating reference/render paths; checks inputs are files; probes FFmpeg; then constructs scale/pad, horizontal-stack and vertical-stack filters. All cells are letterboxed, output is one frame, and FFmpeg failures produce a nonzero exit. Argument-array spawning avoids shell interpolation of filenames. [E6]

Important static edge cases:

- The aspect regex accepts zero components: 16:0 yields an invalid infinite computed width and 0:9 produces zero width. Minimum height is checked, but there is no upper bound on dimensions, pairs, decoded media size or process duration.
- FFmpeg is resolved from PATH and inherits the process environment and current user's permissions. No sandbox, protocol whitelist, resource ceiling or timeout is applied.
- Input existence checks reduce accidental URL input but do not validate format or restrict FFmpeg demuxers. Malicious media/playlist handling and indirect network access remain FFmpeg-dependent, not prevented by Cook.
- Output is unrestricted and passed to FFmpeg with overwrite enabled (-y). There is no project-root confinement, output protocol restriction, parent-directory creation or atomic temporary-output replacement. Arbitrary local paths and FFmpeg-supported output destinations are a host-policy concern.

These are trust-boundary limitations in a small local helper, not demonstrated remote exploits. Its normal use is on trusted local media with a trusted FFmpeg binary. No executable rendering harness, screenshot capture, color-check program file or critic runner is included. [E5, E6]

## Execution, Permissions and Privacy

**Good intent:** intake records download/push/publish permissions; the default is prepare locally without publishing; work is scoped in prose to the project folder; final costly exports need still approval; source guidance warns against publishing keys, tokens or private data. [E1, E4, E8]

**Missing enforcement:** after intake the skill repeatedly says never ask questions and to continue refining while awaiting approval. That is unsuitable as an override of host authorization, budget stops or newly discovered sensitive actions. Even a hard cap is described as finishing the round before stopping, so it is not a precise kill deadline. No approval tokens, tool allowlists, spending ceilings, cancellation implementation or network isolation exist here. The user's harness must impose these independently. Broad triggers such as “cook” and “99%” also make explicit activation preferable to accidental matching. [E1–E3]

**Credentials and egress:** Cook has no API client, credential store, login server or explicit telemetry implementation. Inference credentials and request routing belong to the host agents, and FFmpeg inherits environment variables. References, source code, prompts and critic images may go to their model providers; preview messages go through the host's messaging tools. Instructions additionally contemplate image generation, reference research, licensed-audio downloads and opt-in Git publication. “Zero external assets” is not an offline/no-egress promise. No provider retention policy or data-flow audit is supplied. [E1–E6, E8]

**Persistent sensitive content:** copied references, original filenames, verbatim user feedback, prompt text and renders accumulate under cook/. The publishing guide recommends reconstructing the real prompt into docs/PROMPT.md and a manual secret scan, making explicit redaction review essential. The supplied .gitignore does not ignore cook/, .env or frame caches, despite the guide advising generated projects to cover sensitive/cache files. git grep alone omits untracked files and historical commits and is not a complete secret scanner. Avoid treating a permission to publish code as blanket consent to publish conversation-derived material. [E4, E7–E9]

Reference ownership and media licenses must be checked separately. The instruction not to name third-party clips publicly does not itself grant derivative-use rights or remove attribution duties. [E4, E5]

## Supply Chain and Installation

The README recommends an unversioned npx skills add operation against this repository, or copying into an agent's skill directory. Installation was not performed. The former delegates code retrieval/execution to an external npm-distributed skills CLI and a mutable repository revision; neither that CLI nor its transitive supply chain was audited here. Manual copying still makes persistent instructions available to the agent across projects, depending on host loading rules. [E8]

There is no package manifest, dependency lockfile, lifecycle install script, bundled model or binary in the reviewed tree. That keeps Cook's own dependency surface small, but Node, FFmpeg, optional Python packages, the agent client and all generated-project dependencies remain separate trust decisions. Pin the reviewed revision and trusted tool versions if evaluating later; do not interpret the absence of npm dependencies as a complete supply-chain guarantee.

## Persistence, Recovery and Cost

On resume the agent is told to read the brief, shots and last two round entries; shipped runs move to cook-archive/date/. This has no locking, schema validation, collision policy or automated consistency checks. Frame-by-frame output with “skip existing frames” is only a suggested renderer design; no checksum/settings validation prevents resuming incompatible or partially written frames. Disk retention, archiving cleanup and rollback mechanics are not implemented. [E1, E3, E4]

The skill is MIT and has no stated Cook service fee, but inference, critics, image generation, subscriptions, storage and rendering compute can cost substantially. Default demo effort is an eight-hour floor; the guidance targets roughly 99% of a five-hour usage window. Neither is a monetary budget. More critics and parallel builders multiply calls, while waiting for approval can continue consuming resources. [E1, E3]

The README's Athenaion example reports about 45 hours, 55 subagents, 11 million output tokens and $1.8k–$2.3k API-equivalent cost on a subscription plan, plus a roughly 13-hour GPU render in the shipping guide. These are upstream self-reported example figures, not verified invoices, benchmark results, current model availability or a prediction for another project. No paid services or models were used for this review. [E4, E8]

## Maturity and Verification

Unauthenticated GitHub metadata on 2026-11-21 confirmed public accessibility, creation and last push on 2026-10-31, 780 stars, 59 forks and zero open issues/PRs in the aggregate open_issues_count field. Releases and tags endpoints both returned empty lists. Popularity is not evidence of safety or reproducibility. [E10]

The checked-out commit is the “Add cook skill” revision dated 2026-10-31. The tracked tree contains no test suite, CI workflow, manifest or lockfile. Review covered all 11 content files plus ignore rules; no source was executed and no agent behavior, media-decoding edge case, render quality, cost, recovery or demo claim was reproduced. Public demos were not independently audited. A shallow checkout does not establish full historical activity.

Publication artifacts were checked separately for provenance, task-only diff, standalone template structure, unchanged trusted JavaScript, escaped content, safe links and unresolved tokens. Those checks are not tests of Cook.

## Comparison

| Option | Better fit | Tradeoff relative to Cook |
|--------|------------|--------------------------|
| Explicit project checklist + normal coding-agent approvals | Small, budget-capped UI/scene work | Less packaged critique/handoff discipline, but no need to adopt an eight-hour autonomy default |
| Playwright screenshot assertions | Repeatable UI regression checks | Machine-enforced visual baselines, not an art-direction or 3D-production loop; baseline approval still matters |
| Blender or an existing project-native renderer + FFmpeg | Controlled scene/video production | Actual render tooling and established pipelines, but no bundled agent critique workflow |

These are scope comparisons, not performance benchmarks or newly audited alternatives. Cook can complement rather than replace existing renderers and UI test tools. The high-value transferable idea is fixed-shot evidence plus a calibrated round ledger, not maximizing elapsed time.

## Self-Hosting Notes

There is no Cook service to deploy and no listening port or server-side authentication surface. A future evaluation would load the skill into an already configured agent and provide rendering tools. Keep it in a disposable project with trusted references, restricted filesystem/network access, explicit permission gates and externally enforced spend/time/concurrency limits. Require human review before exposing references, publishing prompt-derived files or starting large exports. No installation or adoption is recommended by this review without those controls.

## Evidence

All source links below are pinned to the reviewed commit.

- **E1:** [SKILL.md](https://github.com/Leonxlnx/cook/blob/b23cac6fd9439dfddcab61b14808e7bf72549b46/SKILL.md): state, intake, loop, gate, stop criteria.
- **E2:** [Target and bar](https://github.com/Leonxlnx/cook/blob/b23cac6fd9439dfddcab61b14808e7bf72549b46/references/target-and-bar.md): rubric, stretch targets, calibration and measurement snippet.
- **E3:** [Loop and critics](https://github.com/Leonxlnx/cook/blob/b23cac6fd9439dfddcab61b14808e7bf72549b46/references/loop-and-critics.md): critic isolation, pacing, feedback, recovery recommendations.
- **E4:** [Ship](https://github.com/Leonxlnx/cook/blob/b23cac6fd9439dfddcab61b14808e7bf72549b46/references/ship.md): export approval, restart advice, prompt publication and privacy scan.
- **E5:** [Rules](https://github.com/Leonxlnx/cook/blob/b23cac6fd9439dfddcab61b14808e7bf72549b46/references/rules.md): assets, rendering and workspace scope.
- **E6:** [Comparison helper](https://github.com/Leonxlnx/cook/blob/b23cac6fd9439dfddcab61b14808e7bf72549b46/scripts/side-by-side.mjs): complete executable implementation.
- **E7:** [Round template](https://github.com/Leonxlnx/cook/blob/b23cac6fd9439dfddcab61b14808e7bf72549b46/templates/ROUNDS.md) and [brief template](https://github.com/Leonxlnx/cook/blob/b23cac6fd9439dfddcab61b14808e7bf72549b46/templates/brief.md).
- **E8:** [README](https://github.com/Leonxlnx/cook/blob/b23cac6fd9439dfddcab61b14808e7bf72549b46/README.md) and [intake](https://github.com/Leonxlnx/cook/blob/b23cac6fd9439dfddcab61b14808e7bf72549b46/references/intake.md): install, demos, defaults and permissions.
- **E9:** [License](https://github.com/Leonxlnx/cook/blob/b23cac6fd9439dfddcab61b14808e7bf72549b46/LICENSE) and [.gitignore](https://github.com/Leonxlnx/cook/blob/b23cac6fd9439dfddcab61b14808e7bf72549b46/.gitignore).
- **E10:** Public [repository metadata](https://api.github.com/repos/Leonxlnx/cook), [releases](https://api.github.com/repos/Leonxlnx/cook/releases) and [tags](https://api.github.com/repos/Leonxlnx/cook/tags), retrieved 2026-11-21 UTC; mutable snapshots.

---

**Attribution:** Leon Lin / Leonxlnx/cook, MIT. Independent analysis; no upstream code extracted or installed.
