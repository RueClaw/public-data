# tstack (t3dotgg/tstack)

**Repo:** https://github.com/t3dotgg/tstack
**Author:** Theo Browne (t3dotgg)
**License:** MIT; retain the copyright and permission notice in copies or substantial portions.
**Reviewed:** 2026-11-07 (UTC)
**Revision:** `1085050f3baed1ac724caa4a8166145fb2ac88af`, full tracked tree; source commit dated 2026-10-28 UTC.
**Verification:** Static review only. Read all nine skills, all four agent metadata files, the complete 556-line Python helper, README and LICENSE. No source execution, installs, model calls, authenticated PR operations or runtime tests.
**Stack:** Markdown Agent Skills, YAML discovery metadata, Python standard library, GitHub CLI, external coding-agent harnesses.
**What it is:** A compact collection of coding-agent procedures for reviewing changes, filing and babysitting GitHub PRs, taking over work and optionally merging it. It is not an application framework, Git worktree manager or self-contained multi-model runtime.

## Verdict

⚠️ **Interesting — selectively adopt the procedures, not unattended merge authority.** The strongest parts are evidence-first delivery, bounded single-reviewer loops, preservation of existing work and explicit human handoff. Its actual enforcement remains the agent harness and GitHub branch protection: the bundled watcher is useful notification plumbing, not a complete merge gate, and several readiness/recovery edge cases deserve tests before automation depends on it.

## What It Is

The [README](https://github.com/t3dotgg/tstack/blob/1085050f3baed1ac724caa4a8166145fb2ac88af/README.md) describes skills used by the author in Claude Code and Codex, with optional T3 Code tools and native fallbacks. Nine directories provide full-send, full-stop, council, sol-loop, file-pr, takeover, babysit-pr, modernize and leaving-pr-comments. Installation is a recursive copy into a harness's skills directory, not a package manager, daemon or service deployment.

The entry points are natural-language triggers and SKILL.md front matter. The host model interprets the instructions, invokes its own tools and owns the task. Only babysit-pr supplies executable implementation: pr-wait reads GitHub state and emits compact events. Dependencies between skills are documented, not automatically resolved. Four openai.yaml files provide display names and default prompts; they do not implement runtime isolation or orchestration.

## Stack

| Layer | Technology and boundary |
|---|---|
| Workflow | Nine Markdown skills interpreted by a coding agent |
| Discovery | Four YAML interface descriptors |
| Watcher | Python standard library, POSIX fcntl locking |
| Forge | Authenticated gh; REST and GraphQL reads in the helper |
| Review models | Host-provided delegates; council requests three providers, sol-loop requires GPT Sol |
| Persistence | Local per-PR JSON/lock files; GitHub PR state; harness-owned session history |

## Key Features

### Proof before delivery

[full-send](https://github.com/t3dotgg/tstack/blob/1085050f3baed1ac724caa4a8166145fb2ac88af/skills/full-send/SKILL.md) requires observed evidence, fresh checks and review on the latest diff before merging. It explicitly disallows administrator bypasses and requires questions when proof or authority is missing. [full-stop](https://github.com/t3dotgg/tstack/blob/1085050f3baed1ac724caa4a8166145fb2ac88af/skills/full-stop/SKILL.md) instead forbids merging, queue entry and default-branch pushes, and checks existing auto-merge settings. This distinction is useful, but both are prompt contracts rather than executable authorization policy.

### Review without endless scope growth

[sol-loop](https://github.com/t3dotgg/tstack/blob/1085050f3baed1ac724caa4a8166145fb2ac88af/skills/sol-loop/SKILL.md) sets three rounds by default, at most five for specified high-risk concerns, one reviewer, a stable finding ledger and current-diff approval. It refuses model substitution and treats missing replies as non-approval. [council](https://github.com/t3dotgg/tstack/blob/1085050f3baed1ac724caa4a8166145fb2ac88af/skills/council/SKILL.md) requests three different providers and exposes disagreements/scores. Unlike sol-loop, council has no fixed round, time or spend cap; agreement is not independent empirical proof of correctness.

### Respect existing work and contributors

[modernize](https://github.com/t3dotgg/tstack/blob/1085050f3baed1ac724caa4a8166145fb2ac88af/skills/modernize/SKILL.md) distinguishes modernizing, reworking and closing an obsolete PR; prescribes disposable worktrees, range-diff and an observed-head force-with-lease. [takeover](https://github.com/t3dotgg/tstack/blob/1085050f3baed1ac724caa4a8166145fb2ac88af/skills/takeover/SKILL.md) preserves original commits, authorship and verified co-author credit. [file-pr](https://github.com/t3dotgg/tstack/blob/1085050f3baed1ac724caa4a8166145fb2ac88af/skills/file-pr/SKILL.md) checks for an existing PR and calls for secret review before publication. [leaving-pr-comments](https://github.com/t3dotgg/tstack/blob/1085050f3baed1ac724caa4a8166145fb2ac88af/skills/leaving-pr-comments/SKILL.md) requires agent attribution and successful post verification before resolving a thread.

## Architecture

The composition is full-send → sol-loop → file-pr → babysit-pr → a model-decided merge gate; full-stop wraps that flow without merge permission. T3 Code supplies capability discovery, delegates and PR watch wakeups. Other environments must provide equivalent subagents and monitoring. Nothing in this repository implements those host services.

The [pr-wait helper](https://github.com/t3dotgg/tstack/blob/1085050f3baed1ac724caa4a8166145fb2ac88af/skills/babysit-pr/scripts/pr-wait) invokes gh through an argument list without a shell. It validates repository/PR input, retrieves PR metadata and review threads with GraphQL, reads checks through gh, discovers required-check names through REST, and compares base commits for file overlap. Duplicate check names collapse to the worst result. Two identical check snapshots reduce premature completion while checks register. Notifications are deduplicated across restarts; one POSIX file lock prevents another local watcher of the same PR.

### Readiness is not merge authorization

Static inspection identifies concrete limitations:

- **Human changes-requested and non-ready merge states are not full gates.** The script reports human reviews but does not reject readiness merely because a human requested changes. The ready branch rejects DIRTY earlier and BEHIND at completion, but does not require a positive mergeable state; UNKNOWN or BLOCKED can reach readiness when other conditions hold. The skills' merge rules are stricter, so callers must re-read live approvals, draft state, protection and mergeability. See [poll and termination](https://github.com/t3dotgg/tstack/blob/1085050f3baed1ac724caa4a8166145fb2ac88af/skills/babysit-pr/scripts/pr-wait#L350-L515).
- **Bot completion is not bot approval.** Recognized bot checks are considered done once non-pending, including failed/cancelled checks. Unless those check names are in the required gate, a recognized bot's failed check can satisfy reviewed. Bot identity is substring matching on login/check name, not a verified app identity. Treat output as notification, never an attestation.
- **Empty CI can wait forever.** gate_done requires a nonempty gate. With no required checks and no non-review-bot CI checks, neither green nor ready completes for an open PR. Default ready also needs Greptile or Macroscope; the skill documents green for repositories without them, but that does not fix empty CI.
- **Snapshot freshness is incomplete.** PR and check reads are separate API calls. The two-poll snapshot includes check names/buckets, not the head SHA, and required-check names are cached for the whole process. A push, base change or protection change therefore needs independent final validation rather than assuming a transactional head-bound result.
- **Large conversations are truncated.** GraphQL asks for the last 100 comments/reviews/threads and first 100 comments per thread without pagination. Older unresolved threads or replies outside those windows can be missed. API errors in required-check discovery are logged but do not prevent proceeding with a partial or empty set. See [query and discovery](https://github.com/t3dotgg/tstack/blob/1085050f3baed1ac724caa4a8166145fb2ac88af/skills/babysit-pr/scripts/pr-wait#L81-L242).

These are code-path observations, not reproduced runtime failures or claims that GitHub branch protection can be bypassed.

## Safety, Privacy and Execution Boundaries

The watcher itself performs reads, not git checkout, push or merge. It has no direct model SDK, custom credential vault, listening web service, CORS configuration or telemetry endpoint. It inherits gh authentication, PATH and environment, so its actual account/host/token authority comes from the operator's environment. It does not scope tokens itself. Its small argv-based subprocess boundary avoids shell interpolation of PR text, but does not sandbox gh or the agent.

The surrounding skills intentionally authorize substantial effects: executing project tests, browser/device testing, rebasing, branch pushes, comments, changes to auto-merge settings and, for full-send, merging. Full-send and full-stop text explicitly interprets the trigger as overriding project-level ask-first testing rules while retaining harness/system approvals. Full-stop even advertises triggering on ordinary closing emphasis, “Full stop.” That is too broad for sensitive workflows: require an unambiguous explicit invocation and enforce hard tool-side limits. None of the source text changes the authority of the reviewer reading it.

PR bodies, bot comments, code and repository-specific bot rules are untrusted material entering agent context. HTML stripping and truncation in snippets improve presentation but are not prompt-injection defenses or robust terminal-control sanitization. The host must prevent source content from granting tool access. Running project tests can execute arbitrary dependency hooks and code: use disposable secret-free environments, not a privileged developer session.

Council and sol-loop send relevant code/context to external model providers via the host. There is no built-in redaction, provider allowlist, retention policy or paid-call budget. Public comments, PR descriptions and screenshots are further outbound boundaries. The posting skills ask for secret checks, but that is model behavior, not deterministic data-loss prevention. Account access, enterprise policies and provider contracts remain separate obligations.

## Persistence and Recovery

The helper stores event IDs, summary hashes, base OID and merge state in a per-PR JSON file under its documented user state directory. Writes use a temporary file plus replace, and the OS releases the per-PR lock on process exit. It does not persist full comment bodies or credentials in that JSON. No explicit private file mode, schema version, fsync, retention pruning or validated-state migration is implemented. Syntax-corrupt JSON is ignored; syntactically valid unexpected state shapes may still raise uncaught errors.

State older than six hours is discarded as a baseline. A first run likewise suppresses historical events, so “nothing that arrived in between is lost” is only qualified by the freshness window and API pagination. This is not an append-only audit log. A crash after stdout emission but before saving can replay an event on restart.

Transient gh errors receive five attempts with exponential sleeps, and the main loop stops after ten transient failed polls. However subprocess.run has no explicit timeout, there is no Retry-After/reset-aware account-wide limiter, and multiple PRs each poll independently. The default interval is 20 seconds with a five-second minimum. A hung gh process can bypass the intended failure bound; ordinary waiting has no deadline. sol-loop bounds rounds, not wall-clock wait time. Open [PR #17](https://github.com/t3dotgg/tstack/pull/17) proposes a wait-timeout fix; [PR #16](https://github.com/t3dotgg/tstack/pull/16) proposes no-gating-bot readiness behavior. Both were open at retrieval and are not part of this reviewed SHA; their reports are not independent verification.

## Maturity, License and Evidence

The complete tracked tree contains 16 files: README, MIT LICENSE, nine skills, four YAML descriptors and one Python script. No test suite, CI workflow, package manifest, lockfile or release automation is present at this revision. There is no executable regression evidence for readiness, recovery, host compatibility or improved code quality. The only third-party executable dependency of the helper is gh, but the real workflow also depends on Git, agent harnesses, provider accounts and whatever the target project's tests execute. No dependency vulnerability scan was run.

The [public repository API](https://api.github.com/repos/t3dotgg/tstack), retrieved 2026-11-07, reported creation on 2026-10-24, last push 2026-10-28, 3,223 stars, 241 forks and 15 open issues/PRs combined. The [release endpoint](https://api.github.com/repos/t3dotgg/tstack/releases) returned an empty list. This is a young, popular public bundle, not a demonstrated production reliability record. A shallow checkout establishes the reviewed tip, not a full historical audit.

The [actual MIT license](https://github.com/t3dotgg/tstack/blob/1085050f3baed1ac724caa4a8166145fb2ac88af/LICENSE) names Theo Browne, copyright 2026, and permits reuse with notice preservation and no warranty. No code was extracted into a separate tool or pattern artifact. External harnesses, providers and tools retain their own terms.

## Comparison

| Option | Best fit | Tradeoff versus tstack |
|---|---|---|
| GitHub required checks, branch protection and merge queues | Enforce review/check policy at the forge | Deterministic authority boundary; does not perform agent review or code fixes |
| gh pr checks --watch | Wait for CI only | Smaller operational surface; lacks tstack's review-thread and base-overlap reporting |
| [Superpowers](superpowers.md) | Broader planning, TDD and structured implementation method | More process; tstack is smaller and PR-delivery focused |
| [Compound Engineering](compound-engineering-plugin.md) | Broader cross-harness workflow and packaging | More integration machinery; tstack is easy to inspect but leaves adaptation to users |

Do not add another agent workflow if existing branch protection plus a human-reviewed PR checklist solves the need. The useful transferable ideas are scope-limited review ledgers, latest-diff proof, explicit non-merge handoffs and notification deduplication—not treating model consensus as authority.

## Self-Hosting / Adoption Notes

There is no service to deploy. Start with reviewed, revision-pinned individual skills in a disposable project, preserve existing same-named skills rather than blindly applying the README's recursive copy, and keep local overrides versioned. Use full-stop/manual merge initially; harden its trigger and testing authority before installing it globally.

The helper imports POSIX fcntl, so native Windows Python is not supported as written; Linux/macOS or a suitable Unix environment is the practical target. README only says python3 and does not declare a tested minimum Python or gh version. Claude Code/Codex support is claimed, but multi-provider subagent availability, model names and wakeup behavior depend on the actual harness. GitHub Enterprise URLs are not accepted by the URL parser, and state keys lack a hostname dimension.

Before unattended adoption, add synthetic regressions for empty CI, changing heads, bot failures, human change requests, UNKNOWN/BLOCKED merge state, truncated threads, protection lookup failures, state corruption and hung subprocesses. Keep mandatory approvals and branch protection external to the model, bound time/spend, and verify final live state independently. No installation or deployment was performed for this review.

---

**Attribution:** [t3dotgg/tstack](https://github.com/t3dotgg/tstack), Theo Browne, MIT. All repository-specific findings above refer to the exact revision recorded here; linked open proposals may change later.
