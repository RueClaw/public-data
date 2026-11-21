# Appllama Skills (Appllama/appllama-skills)

**Repo:** https://github.com/Appllama/appllama-skills
**License:** MIT; preserve copyright and permission notices when reusing substantial material. Branding and third-party screen rights are separate.
**Reviewed:** 2026-11-21 (UTC)
**Revision:** dd5caaec3d5d50ad7fc0324da238119c6b7c3707 — entire tracked tree: 18 files, including both skills, eight references, plugin/MCP manifests and license.
**Verification:** Static review only. All four JSON manifests parsed; tracked-file inventory and local reference links checked. No source commands, installs, model calls, simulator/device sessions or live MCP requests executed.
**Stack:** Markdown agent instructions; JSON plugin/MCP configuration; YAML tool declaration; Expo/React Native/TypeScript implementation guidance.
**What it is:** A vendor-authored pair of agent playbooks for researching commercial mobile interfaces and building more convincing Expo/React Native screens. It is not an app generator executable, UI component library, MCP server implementation, or security boundary.

## Verdict

⚠️ **Interesting — strong mobile QA discipline, not a turnkey trusted agent extension.** The separation between reference research and implementation quality is useful, particularly its navigation-state checks and full-flow motion verification. Start with the design checklist as a bounded, project-specific reference; connecting the research half adds a paid remote dependency, private-board access and a weak tool-output trust rule. Neither visual quality nor safe autonomous operation has been demonstrated by this review.

## What It Is

Appllama supplies two independently installable skills. `appllama-usage` describes a hosted design-library MCP tool map and research workflows; `appllama-app-design-skill` describes native-feeling mobile implementation and acceptance criteria. The README explicitly allows using the design skill without MCP. The intended audience is coding agents and developers shipping mobile UI, especially iOS-oriented Expo projects—not native Swift teams or people seeking a self-hostable screen dataset. [E1, E2, E3]

The workflow turns commercial references into a local board, derives a screen/navigation specification, implements it, and checks the result in a simulator. Revenue rankings are treated as discovery signals, but do not establish usability or causation. The research reference itself cautions that revenue is context, not truth; its more enthusiastic paywall language should be read in that light. [E4]

## Stack

| Layer | Actual contents / role |
|---|---|
| Instruction entry points | Two SKILL.md files, descriptive triggers, MIT metadata; usage version 1.1.0 and design version 1.3.0 |
| Research transport | Remote HTTPS MCP at mcp.appllama.io/mcp; duplicated client config and an OpenAI tool dependency declaration |
| Plugin discovery | Claude and Cursor JSON manifests, both version 1.0.0; Cursor references mcp.json and a remote logo |
| Suggested app stack | Expo Router, React Native, TypeScript, Reanimated, gesture handler, FlashList, expo-image; TanStack Query and Zustand/Jotai patterns |
| Runtime/backend | None implemented here; auth, hosted dataset, billing and server enforcement are external |
| Tests/build | No package manifest, lockfile, runnable test suite, CI workflow, installer script or executable tracked file in this revision |

The last row is an inventory finding, not a claim that instructions cannot cause execution. The README delegates installation to a mutable third-party CLI, and the prose supplies shell commands and TS/TSX examples. [E1, E5, E6]

## Key Features and Skill Coverage

### Research: app, screen, flow, element and personal-board discovery

The 11-tool map covers credits, app search/detail, sequential screen pagination, keyword/semantic screen search, single-screen similarity, flow taxonomy/examples, element taxonomy/examples and member-owned boards. Durable screen IDs, roughly one-hour media links, cursor/query coupling and rate-limit waits are operationally useful details, but remain vendor-documented contracts rather than live-tested API behavior. Research notes and downloaded images persist under a local research directory. [E2]

The three playbooks have distinct scopes: a new app studies every screen of five shortlisted apps, revisits decisive flows in three, specifies the app and builds it; screen improvement starts with three diagnosed deficits and roughly 60 references; flow/element research asks a named question and stops at saturation. These are real methods, not just a catalogue of aesthetic adjectives. They also create variable cost and a potentially very large context/download budget. [E4, E7, E8]

### Design: native controls, visual system, state and navigation

The design prompt covers semantic light/dark colors, native controls, platform iconography, typography, safe areas, consistent accents/radii and complete empty/loading/error states. Navigation guidance distinguishes push, replace, modal, sheet and overlay, preserves the user's place around contextual sign-in/paywalls, and checks that back cannot re-enter completed one-way states. State is separated into server, client and ephemeral layers. These are useful review questions; client navigation guards are not backend authorization or purchase validation. [E3]

The native-controls reference maps requirements to packages, includes destructive-action confirmation, labels/autofill, keyboard handling and platform navigation. It is guidance rather than a tested dependency matrix. Absolutes such as using FlashList for every list, never using effect-plus-fetch, and preferring uncontrolled text fields need project-specific judgment rather than blanket enforcement. [E3, E9]

### Motion and performance

The strongest theme is to remove unnecessary animation, preserve gesture velocity, keep animation work off the JS thread and honor Reduce Motion. Performance guidance calls for baseline/optimize/re-measure, release-device FPS, startup time and typing latency rather than speculative memoization. [E3, E10, E11]

There is a concrete example caveat: the gesture snippet schedules onClose immediately after starting the dismissal spring. If the consumer's callback unmounts or navigates away, the exit animation can be cut short; it is not a complete reusable dismiss controller. The main prompt forbids entering animations on recycled rows, while the motion reference suggests staggered list entrances without reiterating that exception. Integrators must reconcile these scopes and check installed Expo/Reanimated APIs; no versions or compiled examples establish compatibility. [E3, E10]

### Image assets and simulator acceptance

The asset reference specifies a shared style system, several generated candidates, downscaling, background inspection, theme testing and file-size targets. It explicitly permits whatever image tool is available, including Higgsfield MCP/CLI, at the highest quality. That is an instruction capable of causing paid external generation, not an included local image pipeline. [E12]

Simulator verification includes complete recordings, frame-by-frame review, bad input/offline/interruption paths, Dynamic Type, contrast, Reduce Motion, rapid taps and a device matrix. It suggests Maestro if available but ships no Maestro flows or fixtures. The quality loop is unusually concrete, yet “until flawless” has no iteration/time/spend ceiling and cannot guarantee absence of defects. Screen-reader semantics and comprehensive accessibility auditing are not supplied by the visual checklist. [E3, E7, E13]

## Architecture and Execution Authority

The repository is a layered prompt bundle: client loads a skill → agent chooses a playbook/reference → agent calls its existing MCP, shell, file, image and simulator tools. There is no permission broker, sandbox, capability allowlist or local service here. The manifests declare one remote MCP endpoint, not a local subprocess command. JSON/YAML contain no embedded credential value; account approval is delegated to the client's connection flow. Actual token storage, OAuth scopes, server authorization, CORS and retention cannot be assessed because their implementations are absent. [E1, E5, E6]

The README's installation routes are an unpinned npx skills@latest invocation or a clone/copy into agent skill directories, optionally user-wide. No bundled shell installer or hook exists, but the external installer can execute code and user-wide copying broadens activation scope. Metadata versions are not a release pin; even a pinned skill revision does not freeze the hosted MCP behavior. Prefer a reviewed, pinned, project-local copy if adopting later, and review the installer separately. No install was performed here. [E1]

## Security, Privacy and Supply Chain

| Boundary | Finding and practical consequence |
|---|---|
| Remote output → agent authority | Usage ground rule 7 says “Errors are instructions.” Its examples are benign cursor/credit recovery, but it supplies no boundary excluding arbitrary text in errors, metadata, boards or images from becoming instructions. Treat all such content as untrusted data; recovery should follow local allowlisted rules, never remote demands to run commands or disclose secrets. [E2] |
| Credential and account access | Account connection and member boards are part of normal use. No source evidence shows environment/SSH-key scraping or an explicit secret-upload routine; absence of server/client auth code prevents auditing credential custody. Board contents may be private even when the source repository is public. [E1, E2, E6] |
| Network egress | Queries/filters and board identifiers go to Appllama; media downloads use returned, expiring URLs whose host/redirect validation is unspecified. Generated-asset prompts go to whichever provider the agent selects; provider-dependent uploads are not defined here. README imagery and the Cursor logo add public asset requests when rendered. The repository does not instruct uploading the whole codebase to Appllama. [E1, E2, E5, E12] |
| Local data | Notes, downloaded competitor screens and simulator captures persist locally. No retention, redaction or access-control policy is supplied. Captures can contain test-account/user data; keep them out of public commits and use synthetic fixtures. [E2, E13] |
| Spending and autonomy | README says Pro MCP access is paid and every non-credit-check call costs a credit; usage claims 1,500 monthly credits. Full journeys, repeated search, max-quality image variants and unbounded polish loops lack a consent/budget gate. Confirm current pricing independently and set limits before use. [E1, E2, E7, E12] |
| Dependency trust | Mutable installer, recommended unpinned app packages, agent harness, remote MCP and image provider are separate trust dependencies. No lockfile, integrity manifest, pinned integration test or server source is present to make this a reproducible deployment. [E1, E5, E6] |

This is a prompt-injection exposure and governance gap, not a demonstrated exploit or evidence of malicious intent. A capable host can impose approvals, secret isolation, download URL validation and spending limits independently. The skill itself must never be treated as authorization to install packages, operate devices, spend credits or override the user's scope.

## License and Rights

The actual MIT license names Antmind Ventures Private Limited (2026), permits reuse with the copyright and permission notice, and disclaims warranty. README separately reserves the Appllama name, llama and logo as trademarks. MIT coverage of these prompts does not license the commercial screen library, competitor branding/screens, or generated assets under another provider's terms. The prompts discourage one-to-one copying and dataset harvesting; those statements are not a substitute for reviewing service/content rights. No source code or asset extraction accompanies this review. [E1, E14]

## Maturity and Evidence Quality

Public GitHub metadata observed on 2026-11-21 reported 5,457 stars, 272 forks and two open issues; repository creation was 2026-08-13 and last push 2026-09-06. No tags or releases were returned. The five most recent public commits include plugin/MCP configuration and design/navigation/motion revisions; the reviewed head is dated 2026-09-06. Open issues include native Swift support and AutoClaw feedback. These are a dated activity snapshot, not independent evidence of quality or compatibility. [E15]

Readable, small, deliberately separated reference files make auditing easy. There is no checked-in generated app, before/after benchmark, behavioral evaluation of agents, prompt-injection suite or automated compatibility proof. Claims about top-grossing apps producing better designs and achieving flawless simulator output remain methodology/marketing, not validated outcomes. The hosted dataset, credit accounting, media expiry, client discovery and real-device FPS were not independently verified.

## Comparison

| Option | Better fit | Tradeoff |
|---|---|---|
| Appllama design skill alone | Structured mobile design/code-review checklist without the vendor MCP | Still opinionated and agent/tool dependent; no executable test harness |
| Apple Human Interface Guidelines + official Expo/React Native docs | Primary platform semantics and current API compatibility | More manual synthesis; no curated commercial screen research workflow |
| Local, rights-cleared reference board + project-specific checklist | Confidential work and a predictable research budget | Manual curation; no hosted revenue/similarity catalogue |
| Maestro + project-owned UI assertions | Repeatable interaction/regression testing | Does not supply design taste, prove performance or replace accessibility/device review |

Primary alternatives: [Apple HIG](https://developer.apple.com/design/human-interface-guidelines/), [Expo docs](https://docs.expo.dev/), [React Native docs](https://reactnative.dev/docs/getting-started), [Maestro](https://github.com/mobile-dev-inc/Maestro). These are fit comparisons, not head-to-head tests or paid-service recommendations.

## Self-Hosting / Adoption Notes

There is no server to self-host in this repository. The design text can be used offline; the research half depends on the hosted service. Before any deployment: pin and review the desired skill only; reconcile APIs against the project's versions; keep external outputs below instruction authority; approve each integration; cap research calls, generation candidates and iteration time; use disposable test accounts; keep boards/captures private; and turn acceptance criteria into project-owned regression tests. Prefer a small trial of the design checklist over wholesale user-wide adoption.

## Verification and Limits

Read all 18 tracked files (1,368 lines), including all eight reference documents and all manifests. Static checks covered JSON syntax, documented local Markdown link targets and tracked file modes; there are no executable tracked files or symlinks. Review publication checks cover pinned evidence paths/ranges, template script identity, markup/fragment/link safety, one index row, redaction and task-only diff. These are document checks, not upstream behavioral tests.

No install, dependency download, source snippet execution, paid call, MCP authentication/request, image generation, model download, desktop/device operation, simulator launch, app build or benchmark was attempted. Server security, pricing enforcement, instruction adherence and API compatibility remain untested.

## Pinned Evidence

All E1–E14 links refer to revision dd5caaec3d5d50ad7fc0324da238119c6b7c3707; ranges point to the inspected text rather than floating branches.

- **E1:** [README.md, lines 39–133](https://github.com/Appllama/appllama-skills/blob/dd5caaec3d5d50ad7fc0324da238119c6b7c3707/README.md#L39-L133)
- **E2:** [skills/appllama-usage/SKILL.md, lines 20–101](https://github.com/Appllama/appllama-skills/blob/dd5caaec3d5d50ad7fc0324da238119c6b7c3707/skills/appllama-usage/SKILL.md#L20-L101)
- **E3:** [skills/appllama-app-design-skill/SKILL.md, lines 16–333](https://github.com/Appllama/appllama-skills/blob/dd5caaec3d5d50ad7fc0324da238119c6b7c3707/skills/appllama-app-design-skill/SKILL.md#L16-L333)
- **E4:** [skills/appllama-usage/references/research-methods.md, lines 1–69](https://github.com/Appllama/appllama-skills/blob/dd5caaec3d5d50ad7fc0324da238119c6b7c3707/skills/appllama-usage/references/research-methods.md#L1-L69)
- **E5:** [.cursor-plugin/plugin.json, lines 1–29](https://github.com/Appllama/appllama-skills/blob/dd5caaec3d5d50ad7fc0324da238119c6b7c3707/.cursor-plugin/plugin.json#L1-L29)
- **E6:** [.mcp.json, lines 1–8](https://github.com/Appllama/appllama-skills/blob/dd5caaec3d5d50ad7fc0324da238119c6b7c3707/.mcp.json#L1-L8)
- **E7:** [skills/appllama-usage/references/build-from-scratch.md, lines 1–99](https://github.com/Appllama/appllama-skills/blob/dd5caaec3d5d50ad7fc0324da238119c6b7c3707/skills/appllama-usage/references/build-from-scratch.md#L1-L99)
- **E8:** [skills/appllama-usage/references/improve-a-screen.md, lines 1–67](https://github.com/Appllama/appllama-skills/blob/dd5caaec3d5d50ad7fc0324da238119c6b7c3707/skills/appllama-usage/references/improve-a-screen.md#L1-L67)
- **E9:** [skills/appllama-app-design-skill/references/native-controls.md, lines 1–90](https://github.com/Appllama/appllama-skills/blob/dd5caaec3d5d50ad7fc0324da238119c6b7c3707/skills/appllama-app-design-skill/references/native-controls.md#L1-L90)
- **E10:** [skills/appllama-app-design-skill/references/motion.md, lines 17–113](https://github.com/Appllama/appllama-skills/blob/dd5caaec3d5d50ad7fc0324da238119c6b7c3707/skills/appllama-app-design-skill/references/motion.md#L17-L113)
- **E11:** [skills/appllama-app-design-skill/references/performance.md, lines 1–75](https://github.com/Appllama/appllama-skills/blob/dd5caaec3d5d50ad7fc0324da238119c6b7c3707/skills/appllama-app-design-skill/references/performance.md#L1-L75)
- **E12:** [skills/appllama-app-design-skill/references/image-assets.md, lines 1–82](https://github.com/Appllama/appllama-skills/blob/dd5caaec3d5d50ad7fc0324da238119c6b7c3707/skills/appllama-app-design-skill/references/image-assets.md#L1-L82)
- **E13:** [skills/appllama-app-design-skill/references/simulator-loop.md, lines 1–83](https://github.com/Appllama/appllama-skills/blob/dd5caaec3d5d50ad7fc0324da238119c6b7c3707/skills/appllama-app-design-skill/references/simulator-loop.md#L1-L83)
- **E14:** [LICENSE, lines 1–21](https://github.com/Appllama/appllama-skills/blob/dd5caaec3d5d50ad7fc0324da238119c6b7c3707/LICENSE#L1-L21)
- **E15:** Public GitHub API observations: [repository](https://api.github.com/repos/Appllama/appllama-skills), [releases](https://api.github.com/repos/Appllama/appllama-skills/releases), [tags](https://api.github.com/repos/Appllama/appllama-skills/tags), [recent commits](https://api.github.com/repos/Appllama/appllama-skills/commits?per_page=5), [issues](https://api.github.com/repos/Appllama/appllama-skills/issues?state=all&per_page=5). Mutable metadata observed 2026-11-21, not pinned source evidence. Additional pinned declarations: [.claude-plugin/plugin.json](https://github.com/Appllama/appllama-skills/blob/dd5caaec3d5d50ad7fc0324da238119c6b7c3707/.claude-plugin/plugin.json), [mcp.json](https://github.com/Appllama/appllama-skills/blob/dd5caaec3d5d50ad7fc0324da238119c6b7c3707/mcp.json), [skills/appllama-usage/agents/openai.yaml](https://github.com/Appllama/appllama-skills/blob/dd5caaec3d5d50ad7fc0324da238119c6b7c3707/skills/appllama-usage/agents/openai.yaml).

**Attribution:** Appllama/appllama-skills, by Appllama / Antmind Ventures Private Limited; MIT source documentation, with separate trademark and third-party content rights.
