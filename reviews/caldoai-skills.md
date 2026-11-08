# Caldo Skills (caldoai/skills)

**Repo:** https://github.com/caldoai/skills
**License:** MIT; copyright 2026 Maze. Preserve the copyright and permission notice in copies or substantial adaptations.
**Reviewed:** 2026-11-08 (UTC)
**Revision:** f3cf47774975a7d9fca45730babf4ff7ad765ada, main; entire tracked tree (four files).
**Verification:** Static review of every tracked file, manifest JSON/path consistency checks, and public GitHub metadata. No installation, source execution, agent refactor, or end-to-end integration tests.
**Stack:** Markdown agent instructions; JSON Claude Code marketplace manifest; external agent runtime.
**What it is:** One whole-codebase refactoring prompt, not a code analyzer, agent platform, or hosted Caldo service.

---

## Verdict

📚 **Study — a useful architectural review lens, not an unattended refactoring policy.** The “hidden links / needless links / surplus” taxonomy and decision log are clear and portable. Fixing everything until subagents find nothing worth fixing, without a mandatory approved plan, test baseline, rollback protocol, or budget, is too broad for automatic use on a valuable repository. Use its questions in a bounded, human-reviewed refactor rather than adopting its execution authority wholesale.

## What It Is

The canonical repository is **caldoai/skills**, branded **Caldo Skills**, with marketplace name **caldo-skills** and owner label **Maze**. Its only skill is **untangle-codebase**. The generic name “skills” should not be confused with the separate Vercel skills installer linked in the README. The owner-qualified review slug is **caldoai-skills**.

The skill asks an agent to map coupling, propose a redesign, fix the entire problem list, and delegate repeated reviews. Claimed benefits are fewer tokens per change, fewer unnoticed breaks, better output, and faster debugging. These are plausible goals, not measured results: there is no benchmark, evaluation set, token accounting, or before/after case study. [Skill, lines 1–17](https://github.com/caldoai/skills/blob/f3cf47774975a7d9fca45730babf4ff7ad765ada/skills/untangle-codebase/SKILL.md#L1-L17).

## Stack and Inventory

| Layer | Evidence |
|---|---|
| Instructions | One 142-line Markdown SKILL.md with front matter |
| Discovery | .claude-plugin/marketplace.json, one plugin pointing at ./skills/untangle-codebase |
| Installation documentation | External npx skills CLI, Claude Code marketplace commands, or manual folder copy |
| Runtime | User's coding agent; subagent and shell capabilities assumed |
| Bundled code/dependencies | No scripts, executable entry points, package manifests, lockfiles, MCP servers, hooks, CI workflows, or test fixtures in the tracked tree |

[README](https://github.com/caldoai/skills/blob/f3cf47774975a7d9fca45730babf4ff7ad765ada/README.md), [marketplace manifest](https://github.com/caldoai/skills/blob/f3cf47774975a7d9fca45730babf4ff7ad765ada/.claude-plugin/marketplace.json), [license](https://github.com/caldoai/skills/blob/f3cf47774975a7d9fca45730babf4ff7ad765ada/LICENSE).

## Key Features

### Change-together reasoning

The strongest idea is to ask whether pieces should change together. Hidden links cover duplicated logic and implicit order; needless links cover leaked internals and volatile dependencies; surplus covers pass-through wrappers, unused extension points, and dead code. This organizes design review, but is not a machine-checkable definition of correctness. [Lines 30–68](https://github.com/caldoai/skills/blob/f3cf47774975a7d9fca45730babf4ff7ad765ada/skills/untangle-codebase/SKILL.md#L30-L68).

### A decision log connecting causes to fixes

The example groups concrete file/line observations beneath broader changes: dialog focus restoration, a payment-provider interface, and a common command registry. It makes reasoning auditable and preserves context through compaction. The application paths are illustrative examples, not real implementations or integrations in this repository. [Lines 109–142](https://github.com/caldoai/skills/blob/f3cf47774975a7d9fca45730babf4ff7ad765ada/skills/untangle-codebase/SKILL.md#L109-L142).

### Explicit opt-in for comments and test pruning

The agent must ask whether to remove redundant comments and prune or rewrite weak tests; those additions are optional. Test cleanup is deferred until after structural work, acknowledging the regression safety net. Distinguishing implementation-coupled tests from behavioral tests is useful, but whether a test catches a real bug remains a judgment call. A mistaken deletion can conceal a regression. [Lines 19–28](https://github.com/caldoai/skills/blob/f3cf47774975a7d9fca45730babf4ff7ad765ada/skills/untangle-codebase/SKILL.md#L19-L28), [76–86](https://github.com/caldoai/skills/blob/f3cf47774975a7d9fca45730babf4ff7ad765ada/skills/untangle-codebase/SKILL.md#L76-L86).

## Architecture, Authority, and Safety

**Prompt-only does not mean effect-free.** There is no bundled executable: effects come from an agent translating natural language into tool calls. Front matter sets **disable-model-invocation: true**, expressing an invocation restriction for supporting hosts, not a sandbox or permission boundary. No allowed-tools list or permission enforcement exists here. Claude Code, Cursor, Codex, and other-agent compatibility is a README installation claim, not verified equivalence of permissions or front-matter behavior.

**Consent is partial.** Step 2 says not to change anything while cataloging problems. After redesign, the next step is “Fix everything on the list”; there is no mandatory user approval of that list. The initial question concerns optional comment/test cleanup, not a second authorization gate for the core refactor. Separate consent for deleting dead code, modifying public interfaces, or invoking project commands is not specified. [Lines 19–32](https://github.com/caldoai/skills/blob/f3cf47774975a7d9fca45730babf4ff7ad765ada/skills/untangle-codebase/SKILL.md#L19-L32), [64–98](https://github.com/caldoai/skills/blob/f3cf47774975a7d9fca45730babf4ff7ad765ada/skills/untangle-codebase/SKILL.md#L64-L98).

**Stopping and correctness are underspecified.** “Do not stop until there is nothing worth fixing left” relies on subagent judgment; there is no iteration, token, cost, or time cap. Behavior must be preserved except bugs fixed along the way, with testing at the end. No pre-change test baseline, per-change regression check, branch/checkpoint, rollback, dirty-worktree protection, or failure escalation is required. Incidental bug fixes also complicate a behavior-preserving comparison. [Lines 88–107](https://github.com/caldoai/skills/blob/f3cf47774975a7d9fca45730babf4ff7ad765ada/skills/untangle-codebase/SKILL.md#L88-L107).

**Heuristics need domain constraints.** Necessary special cases may remain, but counting them is called the best measure of progress. Retries, sleeps, provider exceptions, or unusual comments may encode real distributed-system or business constraints. Removing them needs operational evidence, not just cleaner dependencies. The tip to “script away the function bodies” does not specify a disposable copy or read-only representation; treat that as an analysis transformation, never erasure of working sources. [Lines 56–74](https://github.com/caldoai/skills/blob/f3cf47774975a7d9fca45730babf4ff7ad765ada/skills/untangle-codebase/SKILL.md#L56-L74), [94–107](https://github.com/caldoai/skills/blob/f3cf47774975a7d9fca45730babf4ff7ad765ada/skills/untangle-codebase/SKILL.md#L94-L107).

**No outbound automation is prescribed.** There are no instructions to push commits, open PRs, send messages, deploy, or contact a Caldo API. There is also no embedded protection against untrusted instructions encountered in the target repository. The host agent must preserve its own trust boundaries and approval controls.

## Credentials, Privacy, and Supply Chain

- No API keys, credential readers, network endpoints, telemetry clients, provider SDKs, or authentication flows are present. Stripe and PayPal appear only in the example.
- Real use reads the target codebase and possibly Git history, generates summaries, and passes context to subagents. What leaves the machine depends on the agent/model provider and its logging/retention settings; this prompt establishes no privacy guarantee, redaction policy, or local-only requirement.
- The README's unversioned **npx skills add caldoai/skills** invokes an external npm-distributed installer and retrieves skill content. Neither installer version nor source revision is pinned in that example. Marketplace/manual-copy routes differ mechanically, but all expose instructions to an agent. No installer or transitive dependency audit was performed.
- The marketplace uses local source **./** with **strict: false**; that manifest setting is not an approval boundary. No installation verification, uninstall/recovery procedure, signed release policy, or locked distribution is supplied. Inspect and pin skill and installer independently if adopting them.

## Maturity and Verification

The anonymous public GitHub API reported **884 stars, 16 forks**, creation **2026-10-25**, and last push **2026-11-05T19:07:22Z** at retrieval on 2026-11-08. The commits endpoint returned three commits, beginning with the October 29 initial commit; the latest merge adds installation instructions. The releases endpoint returned an empty list. Popularity is not evidence of reliability.

Three open entries were PRs, not three confirmed bug issues. [PR #2](https://github.com/caldoai/skills/pull/2) proposes optional approval checkpoints, a baseline, branches, per-fix commits, and revert-on-regression. [PR #4](https://github.com/caldoai/skills/pull/4) proposes flagging untested changes and reports a regression found in a separate review. [PR #3](https://github.com/caldoai/skills/pull/3) fixes a typo. These are contributor reports and unmerged proposals at this snapshot, not reproduced failures or protections present in main.

Verification: all four tracked files inspected; JSON parsed; the sole skill path checked against tracked content; no extra runtime files or test/CI definitions found. Source was treated strictly as data. No npx, plugin installation, project test commands, delegated refactoring, paid inference, accounts, or service connections were used. Benefits, host compatibility, skill loading, and behavior preservation were not runtime-tested. No executable test suite is supplied; synthetic tests of prose would not establish safe agent behavior.

Metadata: [repository](https://api.github.com/repos/caldoai/skills), [commits](https://api.github.com/repos/caldoai/skills/commits), [releases](https://api.github.com/repos/caldoai/skills/releases), [open issues/PRs](https://api.github.com/repos/caldoai/skills/issues?state=open).

## Comparison and Practical Fit

| Option | Better fit | Tradeoff |
|---|---|---|
| Caldo untangle-codebase | Architectural diagnosis and explanatory decision logs | Broad write scope; no built-in correctness enforcement |
| IDE/LSP rename and extract operations | Bounded, language-aware transformations | Narrower reasoning; still need tests |
| jscodeshift or OpenRewrite recipes | Repeatable migrations across many files | Ecosystem-specific recipes and validation required |
| Project-owned checklist plus baseline tests | Team-specific approval, compatibility and rollback requirements | More setup, but explicit constraints instead of “fix everything” |

These are workflow alternatives, not benchmarked competitors. No alternative was installed or tested.

## Self-Hosting Notes

There is no service, database, or deployment configuration. Integration means loading instructions into a coding agent. A safer adaptation first produces a read-only decision log, agrees a small change budget, preserves baseline tests and existing work, isolates changes on a branch, validates each fix, prohibits unapproved test deletion, and stops for missing coverage or ambiguity. These are recommendations, **not features of this revision**.

---

**Attribution:** Caldo / caldoai/skills; marketplace owner and MIT copyright holder Maze. This review analyzes public source without installing or adopting its instructions.
