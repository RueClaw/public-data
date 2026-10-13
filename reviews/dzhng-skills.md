# Skills (dzhng/skills)

**Repo:** https://github.com/dzhng/skills
**License:** MIT, copyright David Zhang; preserve the separate Matt Pocock MIT notice for retro. Executable dependencies have their own terms.
**Reviewed:** 2026-10-13 UTC
**Revision:** ad5f2270a68dd6936e70f9c6386bc13e8457bda7, commit dated 2026-10-12 08:31:57 UTC. Scope: complete catalog inventory, README/licenses/manifests, installer, planning/implementation/review/delegation/authoring/visual procedures, screenshot helper/eval code and auxiliary video project.
**Verification:** Anonymous public-source acquisition and static inspection only. No skills installed, no embedded instructions followed, and no repository code, tests, dependencies or builds executed.
**Stack:** Markdown Agent Skills, Node.js ESM installer/helpers, auxiliary React/Three.js/Remotion video project.
**What it is:** A portable instruction catalog for software planning, research, implementation, review, visual evidence and agent-workflow authoring.

---

## Verdict

⚠️ **Interesting — adopt selected procedures only after a permission-policy review.** The living-spec, experimental research and evidence-preservation patterns are useful. The current pack also recommends bypassing agent permission/sandbox controls and resolving unanswered human sign-off gates autonomously; a dedicated git worktree is not a security sandbox and user silence is not approval.

## Update Notes

Checked 2026-10-13 against the prior review dated **2026-07-05**. The prior review recorded **no exact revision**, so a precise old-to-new commit diff cannot be established from that artifact. This update reuses the existing review rather than creating a duplicate.

Material differences from the older review: the current tree contains **30 skills**, not 16; there is no .claude-plugin/plugin.json; it adds a dependency-free local installer and a separate video project; a screenshot eval harness exists, making the prior blanket “no test suite” wording too strong. The old “only real code” claim is no longer true. The broad Deploy candidate verdict is downgraded because permission and human-approval behavior requires explicit qualification. Existing extracted patterns were not rewritten: the living-spec pattern remains useful, but it must not be interpreted as importing the pack's bypass or silence-as-consent rules.

## What It Is

This is an instruction library, not an autonomous orchestration runtime. A compatible harness must supply models, tools, subagents, persistent goals, permissions and execution. The catalog currently divides into **21 engineering, four visual, three authoring and two graphics skills**.

The strongest theme is decomposing complex work into independently verifiable slices, maintaining current handoff state, and re-slicing when evidence invalidates the plan. Companion procedures cover experimental optimization, tests, performance, architectural choices, visual comparisons and skill evaluation. Portability of Markdown does not imply portability of every helper or CLI flag. [README](https://github.com/dzhng/skills/blob/ad5f2270a68dd6936e70f9c6386bc13e8457bda7/README.md), [catalog](https://github.com/dzhng/skills/tree/ad5f2270a68dd6936e70f9c6386bc13e8457bda7/skills).

## Stack

| Layer | Technology |
|---|---|
| Workflow | Markdown SKILL.md files and reference documents |
| Distribution | Public skill tooling or local Node installer |
| Installer | Node standard library, flattened folders and relative symlinks |
| Visual helper | Node ESM, pngjs and pixelmatch resolved from target project |
| Auxiliary video | React, Three.js, Remotion, separate package-lock.json |
| Enforcement | Supplied by the receiving harness, not this repository |

## Key Features

### Living specs and explicit decisions

write-spec and implement-spec describe named seams, independently verifiable work, maintained handoffs and iterative cleanup. audit-choices makes architectural decisions visible rather than leaving the user to infer them from a large diff. These are worth studying even without installing the pack. [write-spec](https://github.com/dzhng/skills/blob/ad5f2270a68dd6936e70f9c6386bc13e8457bda7/skills/engineering/write-spec/SKILL.md), [implement-spec](https://github.com/dzhng/skills/blob/ad5f2270a68dd6936e70f9c6386bc13e8457bda7/skills/engineering/implement-spec/SKILL.md), [audit-choices](https://github.com/dzhng/skills/blob/ad5f2270a68dd6936e70f9c6386bc13e8457bda7/skills/engineering/audit-choices/SKILL.md).

### Research and visual proof, not just completion claims

auto-research distinguishes correctness from optimization and preserves baselines, failed experiments and tradeoffs. Visual comparison treats difference metrics as diagnostics rather than declaring that lower pixel error always means better design. eval-skills separates blind runners from judging. These are well-chosen procedures, but their presence is not evidence that every skill reliably follows them in every model/harness. [Research](https://github.com/dzhng/skills/blob/ad5f2270a68dd6936e70f9c6386bc13e8457bda7/skills/engineering/auto-research/SKILL.md), [visual comparison](https://github.com/dzhng/skills/blob/ad5f2270a68dd6936e70f9c6386bc13e8457bda7/skills/visual/compare-screenshots/SKILL.md), [skill evaluation](https://github.com/dzhng/skills/blob/ad5f2270a68dd6936e70f9c6386bc13e8457bda7/skills/authoring/eval-skills/SKILL.md).

### The installer is transparent but overwrites

The local installer discovers skills, rejects flattened-name collisions, copies into the target's .agents/skills tree, rewrites cross-category Markdown links, and creates relative .claude links. It supports selection, listing and dry-run. Root package.json has no runtime dependency list, so this installer is materially smaller than an opaque bootstrapper.

However, the non-dry-run path recursively removes each destination before copying, without a transactional backup/rollback. Local modifications to matching .agents skills can be lost. Existing real .claude skill directories are preserved, potentially leaving different content visible through the two harness locations. It also trusts the destination's filesystem topology rather than treating parent symlinks as a containment boundary. Review the destination and back up selected folders first. [Installer](https://github.com/dzhng/skills/blob/ad5f2270a68dd6936e70f9c6386bc13e8457bda7/scripts/install-skills.mjs), [manifest](https://github.com/dzhng/skills/blob/ad5f2270a68dd6936e70f9c6386bc13e8457bda7/package.json).

## Security and Trust Boundaries

### Explicit permission bypass recommendations

The Codex skill recommends --dangerously-bypass-approvals-and-sandbox for browser verification/dev servers/full tests, qualified by a dedicated worktree, self-authored prompt and later diff review. The Claude skill similarly permits --dangerously-skip-permissions for broad autonomous work. Those qualifications improve task separation but do not prevent access to host credentials, arbitrary files or network destinations. Post-hoc diff review cannot undo exfiltration or external side effects. Do not import those defaults into a privileged environment. [Codex](https://github.com/dzhng/skills/blob/ad5f2270a68dd6936e70f9c6386bc13e8457bda7/skills/engineering/codex/SKILL.md), [Claude](https://github.com/dzhng/skills/blob/ad5f2270a68dd6936e70f9c6386bc13e8457bda7/skills/engineering/claude/SKILL.md).

The Claude read/review example also includes Bash: a tool allowlist that contains a general shell is not itself an OS read-only boundary. The actual harness permission configuration still matters.

### Human checkpoints are not enforced gates

implement-spec explicitly says human checkpoints never block, gives the user approximately five minutes, then lets the agent decide and continue without an answer. This may fit pre-authorized reversible work, but is unacceptable as a general rule for spending, publication, destructive operations, security changes or explicit sign-off requirements. Replace that behavior with actual approval gates in any adopted copy. [Checkpoint text](https://github.com/dzhng/skills/blob/ad5f2270a68dd6936e70f9c6386bc13e8457bda7/skills/engineering/implement-spec/SKILL.md#L191-L200).

### Helpers execute with host authority

The screenshot helper resolves pngjs/pixelmatch using the caller's project/web package context; the root manifest does not pin or supply them. That is a reproducibility and dependency-trust issue, and open PRs address dependency/import portability. The auxiliary video directory is a separate dependency-bearing project, not required merely to read the skills. Treat project scripts and all downloaded skill instructions as active content. This is not a network service, so HTTP auth/CORS are not the main risks; execution permissions and outbound model access are. [Helper](https://github.com/dzhng/skills/blob/ad5f2270a68dd6936e70f9c6386bc13e8457bda7/skills/visual/compare-screenshots/scripts/visual-parity-diff.mjs), [eval harness](https://github.com/dzhng/skills/blob/ad5f2270a68dd6936e70f9c6386bc13e8457bda7/skills/visual/compare-screenshots/scripts/visual-parity-diff.eval.mjs), [video manifest](https://github.com/dzhng/skills/blob/ad5f2270a68dd6936e70f9c6386bc13e8457bda7/video/package.json).

## Maturity and Verification

Unauthenticated metadata snapshot: **1,270 stars, 75 forks**, created **2026-07-02**, last pushed **2026-10-12 08:31:58 UTC**. The three open API issue objects were all PRs; release and tag lists were empty, and Actions returned zero runs. Stars and an author's screenshot of a multi-day autonomous run are not independent quality or success-rate evidence. [Metadata](https://api.github.com/repos/dzhng/skills), [PRs](https://github.com/dzhng/skills/pulls).

The screenshot eval harness exists and was inspected, but no evals were run. No repository workflow files were found at this revision. No benchmark establishes improved coding quality or safety relative to another workflow, and model/harness compatibility remains untested here.

## Comparison

| Alternative | Tradeoff |
|---|---|
| [Superpowers](https://github.com/obra/superpowers) | A broader coding methodology and harness integration surface; compare its explicit workflow gates and audit it separately rather than assuming another skills pack is safe. |
| A small project-local AGENTS.md plus selected procedures | Less installation and instruction overlap; loses the breadth of ready-made research/visual workflows but makes authority easier to review. |
| Existing public [living-spec pattern](../patterns/living-slice-graph-spec-loop.md) | Study the conceptual decomposition/handoff approach without adopting all execution defaults. |

These are qualitative adoption choices, not evaluated performance rankings.

## Self-Hosting Notes

No server is needed. Begin with a pinned revision and manually reviewed, narrowly selected skills in a disposable secret-free environment. Preserve MIT notices and remove any permission-bypass or silence-as-consent rule that conflicts with required approvals. Check name collisions before enabling the catalog: generic names such as review can overlap a harness's existing workflows. Keep helper dependencies pinned in a dedicated project and do not install the entire pack merely to borrow a planning pattern.

## License and Attribution

The actual [LICENSE](https://github.com/dzhng/skills/blob/ad5f2270a68dd6936e70f9c6386bc13e8457bda7/LICENSE) is MIT, copyright 2026 David Zhang. The copied retro skill retains [Matt Pocock's MIT notice](https://github.com/dzhng/skills/blob/ad5f2270a68dd6936e70f9c6386bc13e8457bda7/skills/engineering/retro/LICENSE), which must be preserved when reusing that material. The repository's MIT grant does not relicense third-party Remotion or other dependency code, fonts or external services; check their terms for the intended use. No full transitive-license audit was performed.

**Attribution:** David Zhang (dzhng/skills); retro material attributed separately to Matt Pocock. MIT notices apply.
