# improve (shadcn/improve)

**Repo:** https://github.com/shadcn/improve
**License:** MIT © 2026 shadcn; retain copyright and permission notices when redistributing substantial material.
**Reviewed:** 2026-11-10 (UTC)
**Revision:** `cac56e1ebd3c279aa9153616cfeac7b174ab90f9` (main; commit dated 2026-09-12). Scope: all 10 tracked files, including skill, three references, example, plugin metadata, README, license and funding metadata.
**Verification:** Static source review only. No skill invocation, source commands, installations, model calls, dependency audits or target-repository tests were executed.
**Stack:** Markdown Agent Skill; JSON Claude plugin/marketplace metadata; host-provided agents, Git and optional GitHub CLI.
**What it is:** An advisor workflow that audits codebases, vets findings, writes bounded implementation plans, and optionally dispatches a separate executor and reviews its work. It is not a UI library, code-analysis engine or standalone security sandbox.

## Verdict

⚠️ **Interesting: strong planning contract, insufficient enforcement for unattended execution.** The commit-stamped, evidence-backed handoff format is worth adopting for supervised code maintenance. Treat read-only, isolation and scope promises as model instructions, not security guarantees; the documented review command can miss committed executor changes, and worktrees do not isolate credentials or network access.

## Update Notes

Refresh of the 2026-06-20 review, reusing `improve.md`. The prior review recorded no source SHA, so a reliable old-to-new source diff cannot be established from it. This refresh adds exact provenance, execution/approval analysis, concrete Git review and lifecycle gaps, installation trust boundaries, and a standalone HTML companion. The rating changes from ✅ Deploy candidate to ⚠️ Interesting based on closer inspection, not a claim that every issue was newly introduced upstream. The existing public advisor/executor pattern remains relevant; it is not duplicated here.

## What It Is

The [README](https://github.com/shadcn/improve/blob/cac56e1ebd3c279aa9153616cfeac7b174ab90f9/README.md#L3-L45) describes a capable advisor doing reconnaissance and prioritization, then handing self-contained Markdown plans to cheaper executors. The actual implementation is instruction text: no CLI, application runtime, parser, hooks or enforcement service ships in this tree. Nine audit categories include correctness, security, performance, tests and product direction. Quick/standard/deep modes set coverage and subagent concurrency; hosts without audit subagents can work serially.

The economic claim—that expensive planning plus cheaper execution saves money without losing quality—is plausible but not measured here. The single [example](https://github.com/shadcn/improve/blob/cac56e1ebd3c279aa9153616cfeac7b174ab90f9/examples/001-extract-shadow-config-resolution.md#L1-L17) is explicitly historical sample output against shadcn/ui commit `1994caba0`, not a benchmark or a passing execution transcript. It says not to execute the stale example.

## Stack

| Layer | Implementation / requirement |
|---|---|
| Workflow | `skills/improve/SKILL.md` and three Markdown reference files |
| Packaging | Claude plugin and marketplace JSON; declared version 1.0.0 |
| Planning persistence | `plans/` or fallback `advisor-plans/`, with Markdown index/statuses |
| Execution | Host must support isolated Git-worktree subagents; otherwise manual handoff |
| Optional outbound publishing | Authenticated `gh` plus GitHub remote and explicit `--issues` |
| Runtime dependencies | None declared in this repository; installer, model host and target-project tools are separate dependencies |

## Key Features

### Evidence before plans

[SKILL.md lines 43–103](https://github.com/shadcn/improve/blob/cac56e1ebd3c279aa9153616cfeac7b174ab90f9/skills/improve/SKILL.md#L43-L103) requires explicit child briefing, direct rereads of cited source, uncertainty/effort/risk labels, deduplication of rejected findings, and user selection before planning. Noninteractive runs default to the top 3–5 plans, so invocation can write a backlog without a second selection prompt. Source instructions are explicitly untrusted data, and child auditors receive secret-redaction and prompt-injection rules.

### A portable handoff contract

The [plan template](https://github.com/shadcn/improve/blob/cac56e1ebd3c279aa9153616cfeac7b174ab90f9/skills/improve/references/plan-template.md#L18-L146) carries scope, excerpts, commands, expected outcomes, dependencies, a planned-at commit and STOP conditions. This is more useful than findings trapped in a chat transcript. Its promise that executors need not judge success is overstated: expected outputs and tests can be inadequate, and the review instructions correctly require reading test assertions rather than trusting green checks.

### Human-owned integration

The [execution reference](https://github.com/shadcn/improve/blob/cac56e1ebd3c279aa9153616cfeac7b174ab90f9/skills/improve/references/closing-the-loop.md#L11-L69) requires existing plans, dependency completion and drift checks before dispatch. A separate executor may commit inside its worktree; the advisor must not merge, push or commit to the user's branch. Revisions are limited to two rounds. This is a useful process boundary, but tool permissions are not implemented by the package.

## Architecture and Safety Findings

### 1. Committed diffs can evade the documented scope check

The executor is told to **commit its work**, while the reviewer is shown `git -C <worktree> diff --stat` ([closing-the-loop lines 26–55](https://github.com/shadcn/improve/blob/cac56e1ebd3c279aa9153616cfeac7b174ab90f9/skills/improve/references/closing-the-loop.md#L26-L55)). Plain `git diff` compares unstaged changes with the index; a clean, committed worktree can therefore yield an empty result, and staged/untracked changes also need separate inspection. The following instruction to read the full diff does not specify a baseline either. The plan's own `git status` scope gate likewise does not enumerate already committed changes.

A host integration should capture the pre-dispatch base SHA, review base-to-executor-HEAD changes and separately inspect staged, unstaged and untracked files. This finding follows documented Git semantics and static inspection; no synthetic execution test was run.

### 2. A worktree is not a sandbox

The reference explicitly expects dependency installation/builds in the executor worktree and says verification there is fine because it is isolated/disposable ([lines 50–69](https://github.com/shadcn/improve/blob/cac56e1ebd3c279aa9153616cfeac7b174ab90f9/skills/improve/references/closing-the-loop.md#L50-L69)). Git worktrees isolate checked-out files, not processes, environment credentials, home directories, network or shared Git metadata. Installation hooks and project tests remain arbitrary code. There is no credential scrubber, network allowlist, command validator or filesystem permission boundary here.

Even audit mode permits nominally read-only typecheck/lint/tests and dependency audits ([SKILL.md lines 18–23](https://github.com/shadcn/improve/blob/cac56e1ebd3c279aa9153616cfeac7b174ab90f9/skills/improve/SKILL.md#L18-L23)); those names do not prove the underlying scripts are safe, and registry audit commands may transmit dependency information. Inspect scripts and enforce host-side sandboxing/approval before executing unfamiliar repositories.

### 3. Secret redaction is useful, but not data isolation

The instructions prohibit copying secret values and recommend rotation, with explicit propagation to audit children. However, the host still reads repository content, and plans intentionally inline code and design context. Model-provider retention, context sharing, credentials and local access remain host responsibilities. The executor preamble does not repeat the audit-child secret/injection safeguards; do not assume every delegated session inherits them.

Issue publication is gated by an explicit flag, GitHub authentication/remote checks, a visibility lookup, and additional confirmation for sensitive findings in public repositories ([closing-the-loop lines 86–96](https://github.com/shadcn/improve/blob/cac56e1ebd3c279aa9153616cfeac7b174ab90f9/skills/improve/references/closing-the-loop.md#L86-L96)). This is a meaningful safeguard, not automatic redaction: code excerpts, credential locations and vulnerability details can still be sensitive. Plans and issues need audience review. There is no bundled telemetry or network client; network effects arise through host/model services, installation, audits, or optional GitHub commands.

### 4. Persistence is readable, recovery is manual

Plan numbering, rejected findings and status updates avoid repetitive audits. Reconcile refreshes drifted TODOs, investigates BLOCKED items and flags stale IN PROGRESS entries. It retains historical plans rather than deleting them.

But APPROVE marks a plan DONE **before the user merges**, while reconcile checks DONE against the current HEAD. Dependencies can thus appear complete even when code is only in a separate branch. Integrations should distinguish reviewed from merged and record the implementation commit. There is no durable job runner, worktree cleanup routine, lock for concurrent index writes, transactional rollback or issue-create retry/deduplication protocol. A crash after issue creation but before saving its URL could require manual reconciliation.

The commit-to-HEAD drift command ignores dirty/untracked state and files outside the declared paths. The historical example's drift list also omits `config.test.ts` despite listing it in scope ([example lines 14 and 97–101](https://github.com/shadcn/improve/blob/cac56e1ebd3c279aa9153616cfeac7b174ab90f9/examples/001-extract-shadow-config-resolution.md#L14-L101)). Recheck real scope and a clean baseline rather than trusting generated commands mechanically. Worktree disposal can discard proposed file changes, but cannot undo outbound requests, installation side effects or already published issues.

## Installation, Platforms and Supply Chain

The README recommends `npx skills add shadcn/improve`. That is an instruction to execute a separately distributed npm CLI and obtain a repository skill, not an installer implemented or audited in this repository. The documented command pins neither installer version nor source revision. No lockfile, integrity-verification procedure or update/rollback policy is provided here. Inspect and pin both tool and skill revision through the chosen host; review future changes as new instructions with tool access.

Plain Markdown plans are portable. The strongest compatibility claim (“any” Agent Skills host) exceeds the evidence: execution names Claude-style general-purpose agents, worktree isolation, Sonnet defaults and SendMessage. Git, package managers, shell commands and optional `gh` must exist in the host environment; no tested OS/version matrix is supplied. There is no server to deploy or database to configure.

## Maturity and Verification

At retrieval on 2026-11-10, the unauthenticated [GitHub API](https://api.github.com/repos/shadcn/improve) reported a public, nonarchived repository created 2026-06-10, last pushed 2026-09-12, with 10,063 stars, 422 forks and 17 open issues/PRs combined. The [releases endpoint](https://api.github.com/repos/shadcn/improve/releases) returned no releases; plugin metadata declares 1.0.0. Popularity is not correctness evidence. A bounded open-issue metadata fetch was attempted but truncated, so issue health and resolution rates were not assessed.

All tracked source files were inspected. There are no executable scripts, package manifests, lockfiles, tests, automated skill evaluations or CI workflows in this revision; `.github/` only contains funding metadata. The source demonstrates deliberate instruction design but provides no empirical accuracy, prompt-injection resistance, cost, cross-host or executor-success evaluation. No installation or live execution was performed, and the example's target repository was not separately audited.

## Comparison

| Option | Better fit | Tradeoff |
|---|---|---|
| improve | Evidence-backed audits translated into bounded plans | Flexible but model-dependent; process constraints need host enforcement |
| Human review plus ordinary issues/PR templates | Explicit ownership, approvals and existing review controls | More manual synthesis; less automated handoff preparation |
| Semgrep / CodeQL | Repeatable supported static-analysis rules and CI findings | Narrower than architectural/product advice; not substitutes for plan authorship |
| [Superpowers](superpowers.md) | A broader agent development workflow to evaluate | Wider scope than improve's advisor-first contract; compare host permissions separately |

## Practical Adoption

Start with planning-only use on a non-sensitive repository, verify every finding, and keep plans local. For execution, require a secret-free sandbox, explicit command/network policy, recorded base and result SHAs, full committed plus dirty-state diff review, and a separate merged status before dependent dispatch. Keep issue publishing off until contents and destination are reviewed. These are recommended host controls, not features implemented by improve.

**Attribution:** [shadcn/improve](https://github.com/shadcn/improve), [MIT License](https://github.com/shadcn/improve/blob/cac56e1ebd3c279aa9153616cfeac7b174ab90f9/LICENSE.md). Analysis references public source only.
