# Worktrunk (max-sixty/worktrunk)

**Repo:** https://github.com/max-sixty/worktrunk

**Author:** Maximilian Roos (max-sixty) and contributors

**License:** MIT OR Apache-2.0; choose either, retaining the applicable notices and conditions. The combined LICENSE is authoritative despite GitHub's generic “Other” classification.

**Reviewed:** 2026-10-31 (UTC)

**Revision:** `2c04fb3704275aab69237db0bc322e33b3775b6a`, repository-wide architectural review with targeted CLI, Git, hooks, shell, copy, LLM and test inspection. Commit dated 2026-10-31 UTC.

**Verification:** Static source review only. No builds, application tests, installations, shell edits, agent launches, provider calls or real-repository mutations.

**Stack:** Rust 2024, Git subprocesses, clap, serde/TOML, MiniJinja, rayon, skim/ratatui, shell wrappers.

**What it is:** A local Git-worktree lifecycle CLI, primarily for developers running several coding agents or feature branches at once. It is not an agent runtime or a security sandbox.

---

## Verdict

✅ **Deploy candidate for trusted local development, not agent containment.** Worktrunk substantially improves everyday worktree creation, navigation, inspection and cleanup, with unusually explicit Git preservation and approval machinery. Adopt incrementally: begin with switch/list, review project hooks, keep human-controlled integration, and test destructive workflows on disposable repositories before relying on them. Its defaults are convenient but consequential: merge stages all changes and rewrites history, remove destroys working directories, and optional AI summaries transmit diffs through your chosen command.

## What It Is

The canonical project is **max-sixty/worktrunk**, distributed as **wt** (also git-wt), with documentation at [worktrunk.dev](https://worktrunk.dev). It wraps Git's linked worktrees rather than replacing Git storage. Each branch can have its own working directory and index while sharing the object database and refs. That avoids agents overwriting each other's ordinary working files, without granting separate OS identities or restricting filesystem/network access.

The central workflow is branch-addressed creation/navigation, rich status inspection, then either ordinary PR delivery or local integration and cleanup. Hooks can install dependencies, copy caches, start servers and run checks. Agent plugins add activity markers; lifecycle integration differs by harness. The current documentation lists worktree lifecycle integration for Claude Code and OpenCode, while other supported agents use explicit CLI operations. This is workflow automation, not a durable multi-agent scheduler or policy-enforcing supervisor. [E1, E8]

## Stack

| Layer | Technology / responsibility |
|---|---|
| CLI | clap parsing in src/main.rs and src/cli; command orchestration in src/commands |
| Git | Repository/WorkingTree abstractions invoke installed Git; refs and files remain native Git state |
| Config / trust | serde/TOML user and project config; MiniJinja templates; separate persistent approvals |
| Terminal | skim/ratatui picker, crossterm, JSON outputs, streaming status and previews |
| Filesystem / parallelism | rayon, reflink-copy, renamore, fs2, rustix; platform-specific handling |
| Optional AI / forge | User-configured shell command over stdin; forge CLIs such as gh |
| Storage | Git refs/reflogs plus local .git/wt caches, state, logs and transient trash; no service database |

The manifest declares version 0.81.0 and Rust 1.98 minimum. Git 2.43+ is explicitly enforced. CLI dependencies are feature-gated so library consumers can omit the picker/UI; the library itself explicitly disclaims a stable API. Cargo.lock is present. This is a substantive dependency graph, not a dependency-free wrapper. No dependency advisory scan or full transitive-license audit was run. [E2, E9]

## Key Features

### Branch-first worktree lifecycle

Switch resolves branches or worktree paths, creates branches/worktrees, computes configurable paths, and can execute a supplied agent command. The source separates planning/validation from execution. Existing-path clobbering uses a move-aside backup rather than an unconditional recursive deletion; the dependency notes describe atomic no-overwrite renames. The optional parent-shell wrapper performs the actual directory change. List/picker surfaces branch status, changes, integration state and optional forge information. These are useful affordances even without AI. [E1, E3]

### Merge is an opinionated local pipeline

Unlike git merge's familiar direction, wt merge integrates the source branch into a target, defaulting to the default branch. The documented default pipeline stages **all** ordinary untracked and unstaged changes, squashes, rebases, runs pre-merge checks, advances the target, then removes the source worktree/branch. It does not fetch and does not publish to a remote. A successful local merge does not prove remote integration, CI approval or code review. [E4]

Important controls are --stage=tracked or --stage=none, --no-squash, --no-remove, and --no-commit **together with** --no-rebase when the exact prepared graph must survive. --no-commit alone still permits a rebase. A rebase conflict remains open in the source worktree for resolution/abort. Later failure does not undo every earlier pipeline effect; this is not an all-or-nothing transaction.

Before a squash absorbs staged changes, the implementation writes a backup commit and `refs/wt-backup/<branch>` reflog. The backup contains the index and has the prior HEAD as parent; it is **not a complete filesystem snapshot**, and does not capture remaining unstaged/untracked/ignored files. Default staging may first move ordinary untracked changes into that index. This is valuable recovery machinery, not a reason to skip backups. [E5]

### Preservation is deliberate, but bounded

Target advancement uses an expected-old-SHA update-ref, then read-tree -m -u to synchronize a checked-out target. Nonoverlapping dirty/staged paths are preserved; overlapping ordinary modifications/untracked paths are refused. A failed sync attempts a compare-and-swap ref rollback. The code also checks for a target moving during sync and warns. It explicitly acknowledges partial filesystem writes on I/O failure and concurrency windows: do not let multiple agents integrate into the same target simultaneously. [E6]

**Ignored files are an important exception:** an incoming tracked path may overwrite an ignored target file, matching Git's own semantics. Keep valuable local databases, generated credentials and unique artifacts outside disposable worktrees or independently backed up. Native Git safety is not universal data preservation.

### Removal has separate worktree and branch force controls

Normal removal gates dirty worktrees and locked/nested/foreign-worktree cases. --force permits discarding staged, modified and ordinary untracked files; -D separately permits deleting an unmerged branch. --no-delete-branch retains the branch, not its uncommitted files. Integration detection includes identical commits, ancestry, empty diffs, matching trees, simulated merge and a bounded patch-id fallback for squash workflows. Content equivalence is not preservation of every original commit identity. [E7]

Branch deletion uses expected-SHA compare-and-swap protection against concurrent writers. Removal normally renames into .git/wt/trash and drains it asynchronously; a rename failure can fall back to direct Git removal. **This trash is a deletion staging area, not a user recovery bin.** Ignored files are not protected by the ordinary clean-status gate. For automation, use foreground completion and inspect the structured branch outcome rather than interpreting an immediate return or deferred result as proof of deletion. The symlink-safe directory walker avoids following links/junctions outside the tree, but cleanup errors can leave residue. Experimental --reap kills qualifying detached processes by working directory on Unix; it is not a general agent shutdown protocol. [E7]

## Architecture and Trust Boundaries

### Approvals bind command text, not the entire execution environment

Project .config/wt.toml commands require approval; user hooks are trusted configuration. Approvals live separately from portable config, indexed by project identity and normalized command template. Command changes require fresh approval, and explicit wildcard entries can widen scope. --yes bypasses prompting. Critically, declining skips project commands and continues the operation: declining a test hook is **not** a merge-denial policy. --no-hooks likewise removes checks. Keep mandatory integration gates outside discretionary local hooks. [E10]

A standout design is ApprovedHookPlan: operation-driven hook selections are frozen at the approval boundary, then rendered/executed from that plan after Git mutations. This addresses the risk of a rebase or checkout replacing approved config with different commands. Template values are shell-escaped. These controls are meaningful, but approving npm test or a repository script does not freeze its subsequently modified implementation, dependencies, executable resolution or input data. Hooks and aliases still run arbitrary code with the invoking user's authority. [E10]

Pre-hooks block; post-hooks run in the background. Concurrent hook-table entries can race on files or Git operations; ordered pipeline blocks are required for dependencies. A launched post-hook is not a passed check. Logs may contain paths, command arguments, build output or secrets printed by child tools.

### Shell integration is not stdout evaluation

The wrapper uses a temporary directive file for a raw destination path and a quoted builtin cd, instead of evaluating arbitrary command output. The Bash template also preserves prompt/trap behavior; its internal eval usage for shell bookkeeping is distinct from interpreting the destination as code. Security tests explicitly exercise directive-like branch names, messages and errors. Nevertheless shell initialization executes trusted generated wrapper code, and installers modify startup/profile or function files. Review those edits and pin the executable you trust. No integration was installed in this review. [E11]

### Parallel working copies are not isolation

Agents share OS privileges, repository refs/objects/config and potentially caches, environment credentials, ports and external services. A process can still reach sibling worktrees. Copy-on-write caches reduce storage/copy cost on supporting filesystems; they do not isolate secrets or resource contention. copy-ignored copies **all ignored files without a .worktreeinclude**, so it can copy .env files as well as node_modules. Use an explicit include list and --require-include when absence must mean “copy nothing.” Reflinks fall back to ordinary copying where unsupported, and copied symlinks may retain external targets. Port hashing is a convenience, not guaranteed collision-free allocation. Use containers/VMs or separate restricted identities when agents are untrusted. [E8, E12]

## Privacy, Providers and Credentials

The core workflow is local and does not require an LLM account. Without generation configuration, commit messages have deterministic fallbacks. AI commits and opt-in branch summaries construct prompts containing diffs, repository/branch context and commit information, then pipe them to a configured external command. Provider credentials/authentication remain the responsibility of that command and its environment; Worktrunk is not a secret broker or an egress/redaction boundary. Costs and retention follow the selected provider. Do not send sensitive diffs merely because the top-level tool is local. [E13]

The supplied Claude recipe disables tools and uses safe mode/user-only settings while retaining normal authentication; the Codex recipe disables several capabilities and uses a read-only sandbox. These are version-sensitive recipes, not guarantees for arbitrary commands. Project prompt append fragments also have an approval gate, but diff contents remain untrusted model input. Review generated messages. Verbose subprocess logging and cached summaries deserve retention/access controls; no claim of universal secret redaction is warranted.

Forge status/previews use external CLIs (the GitHub implementation invokes gh for PRs/checks/comments), inheriting those tools' authentication and contacting their configured services. Git remote operations likewise use Git transport credentials. Hooks can contact anything the host can. There is no exposed web server, multi-user authentication or CORS layer to assess in this CLI deployment model. No network privacy trace was performed. [E13, E14]

## Maturity, Tests and Platform Constraints

Public GitHub metadata on 2026-10-31 reported 9,665 stars, 344 forks and 62 open issues/PRs combined; repository creation was 2025-10-17 and latest push was 2026-10-31. The latest release endpoint reported **v0.81.0, published 2026-10-20**, targeting a different commit from this reviewed main SHA. Those numbers indicate adoption/activity, not correctness. This review is of main, not a proof that every behavior described is in the packaged release.

There are substantial integration and snapshot suites for merge, removal, approvals, security, shell wrappers, foreground jobs, copying, PR status and documentation synchronization. Inspected tests cover moved-ref deletion, dirty target preservation, foreign-repository refusal, force removal and shell directive injection. CI defines Linux, macOS and Windows test legs, feature-boundary checks, lockfile/doctest/rustdoc checks and clean-working-tree checks after tests. Nightly includes minimum-Git coverage. Many Actions references use version tags rather than immutable SHAs. These are **checked-in testing mechanisms**, not independently observed passing results at this revision. [E15]

Bash, Zsh, Fish, PowerShell and experimental Nushell integration are documented; Nushell requires 0.113+. Windows has a wt name collision with Windows Terminal, and shell commands use Git Bash there. Some process-management features are Unix-only. Copy-on-write gains depend on filesystem capabilities. Rust 1.98 and optional tree-sitter C compilation matter for source builds. Benchmark/demo claims were not reproduced. This is mature-looking pre-1.0 tooling with an explicitly unstable library API; validate the exact release and shell/platform combination you adopt.

## Comparison

| Option | Best fit | Tradeoff against Worktrunk |
|---|---|---|
| [Native git worktree](https://git-scm.com/docs/git-worktree) | Few parallel branches; explicit, minimal tooling | More path/cleanup bookkeeping; no Worktrunk hook/summary/picker layer |
| [git-worktree.nvim](https://github.com/ThePrimeagen/git-worktree.nvim) | Neovim-centered navigation | Editor-local workflow rather than a cross-shell lifecycle CLI |
| [git-town](https://github.com/git-town/git-town) | Branch/stack and delivery-workflow automation | Broader branch workflow emphasis; evaluate integration semantics separately |
| [Orca](stablyai-orca.md) | Desktop view of parallel agents, terminals and review | Larger application/control-plane surface; Worktrunk is more composable for terminal users |
| Containers or VMs plus Git | Untrusted code/agent execution | Real isolation controls require additional setup; not replaced by a worktree manager |

These are positioning comparisons, not head-to-head executed benchmarks. Use native Git if worktree friction is small; use Worktrunk when repeated lifecycle work dominates. It complements rather than replaces a sandbox, code review, remote CI or agent orchestrator.

## Local Adoption Notes

No server or hosted deployment is required. Start with trusted repositories and switch/list before enabling hooks or automatic merging. Review project commands and their called scripts, avoid blanket --yes for unfamiliar repositories, restrict copied ignored files, and keep secrets outside disposable trees. Separate agent branches and serialize target integration. For automation, prefer explicit stage/history options, structured output and foreground removal, then verify refs/files and required checks. Treat background logs and backup refs as sensitive local artifacts. No source code was extracted in this review.

## Evidence and Verification Limits

All source links below are pinned to the reviewed SHA. Documentation describes intent; implementation and test inspection support the specific findings, but were not executed. No vulnerability-free claim, production certification, measured speedup or exhaustive concurrency audit is made.

- **E1:** [README.md](https://github.com/max-sixty/worktrunk/blob/2c04fb3704275aab69237db0bc322e33b3775b6a/README.md)
- **E2:** [Cargo.toml](https://github.com/max-sixty/worktrunk/blob/2c04fb3704275aab69237db0bc322e33b3775b6a/Cargo.toml); [LICENSE](https://github.com/max-sixty/worktrunk/blob/2c04fb3704275aab69237db0bc322e33b3775b6a/LICENSE); [src/lib.rs](https://github.com/max-sixty/worktrunk/blob/2c04fb3704275aab69237db0bc322e33b3775b6a/src/lib.rs)
- **E3:** [src/commands/worktree/switch.rs](https://github.com/max-sixty/worktrunk/blob/2c04fb3704275aab69237db0bc322e33b3775b6a/src/commands/worktree/switch.rs); [src/commands/backup.rs](https://github.com/max-sixty/worktrunk/blob/2c04fb3704275aab69237db0bc322e33b3775b6a/src/commands/backup.rs)
- **E4:** [docs/src/content/docs/merge.md](https://github.com/max-sixty/worktrunk/blob/2c04fb3704275aab69237db0bc322e33b3775b6a/docs/src/content/docs/merge.md); [src/commands/merge.rs](https://github.com/max-sixty/worktrunk/blob/2c04fb3704275aab69237db0bc322e33b3775b6a/src/commands/merge.rs)
- **E5:** [src/commands/step/squash.rs](https://github.com/max-sixty/worktrunk/blob/2c04fb3704275aab69237db0bc322e33b3775b6a/src/commands/step/squash.rs); [src/git/repository/working_tree.rs](https://github.com/max-sixty/worktrunk/blob/2c04fb3704275aab69237db0bc322e33b3775b6a/src/git/repository/working_tree.rs)
- **E6:** [src/commands/worktree/push.rs](https://github.com/max-sixty/worktrunk/blob/2c04fb3704275aab69237db0bc322e33b3775b6a/src/commands/worktree/push.rs)
- **E7:** [docs/src/content/docs/remove.md](https://github.com/max-sixty/worktrunk/blob/2c04fb3704275aab69237db0bc322e33b3775b6a/docs/src/content/docs/remove.md); [src/git/remove.rs](https://github.com/max-sixty/worktrunk/blob/2c04fb3704275aab69237db0bc322e33b3775b6a/src/git/remove.rs); [src/git/ref_deletion.rs](https://github.com/max-sixty/worktrunk/blob/2c04fb3704275aab69237db0bc322e33b3775b6a/src/git/ref_deletion.rs); [src/remove_dir.rs](https://github.com/max-sixty/worktrunk/blob/2c04fb3704275aab69237db0bc322e33b3775b6a/src/remove_dir.rs)
- **E8:** [docs/src/content/docs/claude-code.md](https://github.com/max-sixty/worktrunk/blob/2c04fb3704275aab69237db0bc322e33b3775b6a/docs/src/content/docs/claude-code.md)
- **E9:** [src/git/version.rs](https://github.com/max-sixty/worktrunk/blob/2c04fb3704275aab69237db0bc322e33b3775b6a/src/git/version.rs)
- **E10:** [src/config/approvals.rs](https://github.com/max-sixty/worktrunk/blob/2c04fb3704275aab69237db0bc322e33b3775b6a/src/config/approvals.rs); [src/commands/hook_plan.rs](https://github.com/max-sixty/worktrunk/blob/2c04fb3704275aab69237db0bc322e33b3775b6a/src/commands/hook_plan.rs); [docs/src/content/docs/hook.md](https://github.com/max-sixty/worktrunk/blob/2c04fb3704275aab69237db0bc322e33b3775b6a/docs/src/content/docs/hook.md)
- **E11:** [templates/bash.sh](https://github.com/max-sixty/worktrunk/blob/2c04fb3704275aab69237db0bc322e33b3775b6a/templates/bash.sh); [docs/src/content/docs/shell-integration.md](https://github.com/max-sixty/worktrunk/blob/2c04fb3704275aab69237db0bc322e33b3775b6a/docs/src/content/docs/shell-integration.md); [tests/integration_tests/security.rs](https://github.com/max-sixty/worktrunk/blob/2c04fb3704275aab69237db0bc322e33b3775b6a/tests/integration_tests/security.rs)
- **E12:** [src/commands/step/copy_ignored.rs](https://github.com/max-sixty/worktrunk/blob/2c04fb3704275aab69237db0bc322e33b3775b6a/src/commands/step/copy_ignored.rs); [src/copy.rs](https://github.com/max-sixty/worktrunk/blob/2c04fb3704275aab69237db0bc322e33b3775b6a/src/copy.rs)
- **E13:** [docs/src/content/docs/llm-commits.md](https://github.com/max-sixty/worktrunk/blob/2c04fb3704275aab69237db0bc322e33b3775b6a/docs/src/content/docs/llm-commits.md); [src/llm.rs](https://github.com/max-sixty/worktrunk/blob/2c04fb3704275aab69237db0bc322e33b3775b6a/src/llm.rs); [src/config/project.rs](https://github.com/max-sixty/worktrunk/blob/2c04fb3704275aab69237db0bc322e33b3775b6a/src/config/project.rs)
- **E14:** [src/commands/list/ci_status/github.rs](https://github.com/max-sixty/worktrunk/blob/2c04fb3704275aab69237db0bc322e33b3775b6a/src/commands/list/ci_status/github.rs)
- **E15:** [.github/workflows/ci.yaml](https://github.com/max-sixty/worktrunk/blob/2c04fb3704275aab69237db0bc322e33b3775b6a/.github/workflows/ci.yaml); [.github/workflows/nightly.yaml](https://github.com/max-sixty/worktrunk/blob/2c04fb3704275aab69237db0bc322e33b3775b6a/.github/workflows/nightly.yaml); [tests/integration_tests/remove.rs](https://github.com/max-sixty/worktrunk/blob/2c04fb3704275aab69237db0bc322e33b3775b6a/tests/integration_tests/remove.rs); [tests/integration_tests/approvals.rs](https://github.com/max-sixty/worktrunk/blob/2c04fb3704275aab69237db0bc322e33b3775b6a/tests/integration_tests/approvals.rs)
- **Public metadata:** [repository API](https://api.github.com/repos/max-sixty/worktrunk), [latest release](https://github.com/max-sixty/worktrunk/releases/tag/v0.81.0), retrieved 2026-10-31 UTC.

---

**Attribution:** max-sixty/worktrunk, Maximilian Roos and contributors; MIT OR Apache-2.0. Independent analysis, no upstream code extraction.
