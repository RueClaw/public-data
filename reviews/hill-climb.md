# Hill Climb (Bil0000/Hill-Climb)

**Repo:** https://github.com/Bil0000/Hill-Climb

**License:** MIT; retain the copyright and permission notice when reusing substantial code.

**Reviewed:** 2026-11-15 (UTC)

**Revision:** `84b95909383379d4a84ad02ecadf928aba6b3b9b` (main; plugin version 1.1.0). Whole repository: skill, both Python scripts, check recipes, tests, demo, manifests, CI and assets.

**Verification:** 44 upstream tests passed in 5.793 seconds, plus the synthetic demo passed, in a network-isolated, secret-free Linux sandbox. No agent/provider calls or installations.

**Stack:** Python 3.9+ standard library, Git, POSIX shell; optional Claude Code/Codex judge CLIs.

**What it is:** A coding-agent skill and local scorekeeper that accepts or discards small Git changes against a numeric check and regression guards. Not a game, model-training library, or standalone autonomous agent.

## Verdict

⚠️ **Interesting — a useful experiment controller, not an incorruptible evaluator.** The exact-tree snapshot/commit design, regression guards, disposable-step rollback and disk-backed trail are unusually concrete for a skill. Use it for bounded, independently checked experiments in dedicated worktrees; do not equate a better scalar score with completed requirements, secure isolation, or a trustworthy benchmark speedup.

The current paired benchmark does not synchronize random inputs; an open upstream proposal documents inflated gains. Holdouts remain readable and run after a winning commit, not as an acceptance gate. Those distinctions materially qualify “makes it prove done.”

## What It Is

An outer coding agent reads SKILL.md, builds the evaluator, edits the target project, and invokes climb.py. The controller has no model client or autonomous scheduling loop: it measures commands, compares scores, manipulates Git, and records results. It fits bug-fixing campaigns, performance experiments, ports and narrowly specified feature work where a meaningful scalar and independent correctness guards already exist.

The skill recommends a human-approved “card” for larger goals, fresh-input checks, separate passing-test guards, blocker reviews, final whole-branch review and reusable evaluation kits. Small goals skip the card and holdout. These are agent instructions, not independently enforced authorization controls. The broader instruction to acquire tools/compute and keep working must remain subordinate to the host's approval and spending policy. [S1, S2]

## Stack

| Layer | Implementation |
|---|---|
| Orchestration | SKILL.md and references/checks.md interpreted by the host agent |
| Experiment controller | 1,073-line climb.py; argparse, subprocess, statistics, hashing, tarfile, fcntl |
| Change boundary | Git branches, private indexes, tree objects, reset/clean and commits |
| State | Repository-local JSON card, JSONL log, text outputs and notes; user-level compressed kits |
| Optional subjective evaluation | 149-line judge.py dispatching Claude and Codex CLI processes |
| Packaging | Claude marketplace/plugin JSON; manual copy into skill directories |
| Validation | unittest integration fixtures and Bash demo; Ubuntu/macOS CI |

## Key Features and Architecture

### 1. Commit the scored tree, not whatever happens to be staged later

init rejects unrelated dirty files, permits new locked check files, runs a baseline and guards, then creates climb/<name> branches (unless --here). try fingerprints selected locked paths, snapshots each checkout through a private Git index, and scores the candidate. Multiple check commands run concurrently; repeated measurements use a median, with a discarded warm-up when runs > 1. Winning candidates must pass sequential guards. The controller detects check/guard writes and moved HEADs, removes generated untracked outputs, then commits the recorded tree. [S3]

This is real executable enforcement against common accidental evaluator edits, not just a prompt asking the agent to behave. Tests exercise staging/committing during checks, modifications to the old side of paired runs, generated reports, ignored-file preservation, guard failures and multi-repository rollback. Version 1.1.0 specifically strengthens these boundaries. [S5, S8]

### 2. Numeric checks are flexible, but their contract is permissive

Without --score, a successful check must print a bare number on its final stdout line. With --score, the parser sums captures on the last matching line of combined stdout/stderr; a successful command with no match scores zero. A nonzero exit can still produce a valid score if a matching line exists, allowing failing-test counts to improve gradually. Several checks' scores are simply added. [S3]

Consequences: output-format drift can become a false zero, a partial test crash can look like fewer failures, and a summed score can hide deterioration in one component. The documentation warns about crashes and recommends guards; use machine-readable completeness checks, explicit per-component floors and a fixed test inventory where correctness matters. A passing unrelated guard does not prove the scoring suite actually ran in full. --fix intentionally allows equal-score repairs, so not every kept change strictly improves the score. [S2, S4]

### 3. Durable context helps resumption, but does not make a transaction journal

The card records commands, limits, locks, baseline/best score and Git metadata; log.jsonl records steps and reasons. last.txt and best.txt preserve check output, while notes carry human/agent context. State is excluded through Git's info/exclude, so ordinary repository clones/backups of tracked files do not capture it. [S3]

Paired mode writes a pending-tree marker before switching old/new trees. An interrupted step is refused with explicit restore instructions. A per-primary-checkout flock prevents simultaneous mutating controller commands; secondary repos do not receive a jointly held multi-repo lock. Multi-repo commit failures roll earlier commits back with soft resets, but branch creation, commits, card writes and log appends are separate operations. There is no atomic replace/fsync protocol or crash reconciliation across them: abrupt termination can leave partial state and requires comparing cards/logs with actual Git heads. Independent writers can still race or lose work. [S3]

Kits are bounded on creation (512,000 bytes per file, 2 MB compressed archive); new commits reject files over 10 MB and state over 200 MB triggers a warning, not a quota. Reuse rejects unsafe archive paths, nonregular entries, destination symlinks and differing existing files. Import does not impose an analogous decompressed-size budget. Kit names group by repository basename, not globally unique owner/repository identity. Treat kits as trusted local executable evaluation material, not safe arbitrary downloads. [S3, S5]

## Claims, Evidence and Evaluation Methodology

| Claim | What the reviewed revision supports |
|---|---|
| “The check is locked” | Selected path hashes are checked before/after acceptance. No protection from an agent able to edit the controller/card, invoke relock, read holdouts or bypass the tool. |
| “Every change scores better” | Ordinary try requires strict gain above min-gain; --fix can keep equal scores. Score validity depends on evaluator completeness. |
| “A holdout check the agent never sees” | A behavioral instruction only. Files live in the accessible checkout; no read-denial boundary. |
| “Undo is automatic and complete” | Git-tracked changes and nonignored untracked files are reset/removed. Ignored data, external filesystem writes, network calls and other side effects are not rolled back. |
| “Same code that was scored” | Strong snapshot/tree enforcement for observed Git content; not proof of identical environment, ignored caches, external state or absence of hostile concurrent mutation. |
| About 290× faster user lookup | README labels its runs small examples, not a benchmark. No independently reproduced performance result here. |

### Paired timing needs an independent final measurement

paired alternates candidate/baseline order, takes separate medians and computes new stored score = previous best score × candidate median / baseline median. It does not supply a shared input seed at this SHA. Random input size/content can therefore differ between sides, and repeated selection of only apparent wins can compound optimistic noise. Medians, balanced order and a minimum gain help, but are not significance tests or a correction for repeated selection. The stored trajectory is a chained estimate, not a direct final runtime. [S3, S4]

Open PR #11 proposes a shared HILL_CLIMB_SEED and fixed workload sizes. Its author reports a 190× estimated gain versus a directly timed 46× gain in one experiment, plus residual error after proposed fixes. Those are upstream self-reports, not our replicated findings, and the proposed seed code is **not** in the reviewed commit. Compare final and original commits directly on identical workloads, with repeated timings and correctness checks, before reporting a speedup. [S9]

### Holdout feedback is not a keep/reject gate

run_holdout only measures and appends a score. At the bar it runs **after** commit, best-card update and kept-log append; no comparison automatically rejects a worsening holdout. The skill tells the agent to stop when holdout and visible scores disagree, but try does not enforce that stop or automatically reverse the commit. Manual holdout invocation also lacks the ordinary try snapshot/mutation checks. A holdout failure may therefore occur after a kept step. Issue #12 explicitly recognizes readable holdouts; moving files elsewhere under the same user's access would still not create genuine evaluator isolation. [S2, S3, S10]

For a true hidden evaluation, use a separately controlled runner/data boundary. Predefine final acceptance and preserve a never-used final test set; repeated holdout feedback can itself become optimization feedback. Human review remains necessary for unmeasured APIs, accessibility, regressions and semantic requirements.

## Security, Permissions and Privacy

- **Local command authority:** check, guard and holdout strings run with shell=True, inherited environment and current-user authority. No built-in filesystem/network sandbox, credential stripping, application authentication, or egress allowlist exists. Even init runs supplied code. There is no listening service, so CORS/server authentication are not applicable. [S3]
- **Destructive Git scope:** undo uses reset --hard and clean -fdq across registered checkouts. Snapshot uses add -A; unrelated nonignored files present at the candidate snapshot may be committed or deleted. Use dedicated worktrees for every participating repo, not a shared working directory. --here removes the default separate-branch safeguard. Commits use --no-verify, bypassing pre-commit/commit-msg hooks; do not depend on those for secret or policy checks. [S3]
- **Process control is not isolation:** check commands get a new session and process-group kill after completion/timeout, reducing late background writes. Escaped process groups and external effects are not a transactional sandbox. Timeout is per command/run, not a whole-step deadline; outputs are buffered without a byte cap. [S3]
- **Tamper boundary:** card, score history, lock fingerprint, controller and agent share filesystem authority. relock intentionally changes the evaluator and resets best. Lock coverage is opt-in; test runner config and transitive inputs must be selected by the operator. Existing ignored-file contents are represented as an ignored marker rather than hashed bytes. This is an accident-resistant workflow, not a security boundary against a malicious agent. [S3]
- **Optional judges introduce provider egress:** judge.py sends the rubric and candidate/reference paths to configured CLI processes, which read content for model evaluation. Claude is restricted to Read with strict MCP config and no session persistence; Codex uses read-only sandbox and ephemeral mode. Those reduce writes/history but do not make the target files the exclusive readable surface or neutralize all host configuration. Provider routing, authentication and retention follow the installed CLIs. No API keys are managed by this repository. [S6]
- **Untrusted judging inputs:** the prompt explicitly labels candidate content as data, but that is not a robust injection boundary. Recursive candidate enumeration has no hidden-file exclusion, content-volume cap or secret filtering. Scope input directories tightly. Majority-answer requirement and 0–10 validation catch malformed/missing scores, not bias or correlated judges. [S6]
- **Retention:** local cards, logs, check output, notes and kits may contain sensitive command arguments, results, rubric/reference files or paths. They are not encrypted/redacted; ignored is not private or backed up. “No session persistence” is not a claim about remote provider retention. [S3, S6]

## Costs and Operational Fit

The scorekeeper itself has no packages, service subscription, account or direct HTTP client. Its target commands can still install packages or use paid APIs; the outer coding agent and optional judge CLIs carry their own credentials and charges. No token or currency accounting is implemented.

Default judge panel is Claude plus Codex, one round each. Nonpaired scoring with runs=3 calls the check four times including warm-up; a two-judge/two-round check therefore launches 16 judge jobs for one measurement. Paired runs=3 rounds up to four turns, two sides each: eight checks, or 32 judge jobs at that panel setting, before guards/holdouts. Init and final/milestone evaluations add more. Use deterministic checks where possible and explicitly authorize paid judging. [S3, S6]

The skill defaults to no budget; optional step/hour limits are soft while recent gains continue unless --hard is set. Hard limits are checked before try, not as a kill deadline for the whole step. BAR REACHED and STUCK are reporting/instruction states rather than unconditional CLI refusal to attempt more changes. Set host-level spend/runtime boundaries rather than assuming the card enforces a financial cap. [S2, S3]

## Installation, Compatibility and Update Risks

This is a local development tool, not a self-hosted server. The documented paths are Claude marketplace installation or cloning/copying the skill directory for Claude Code/Codex. No installation was performed in this review. The Python scripts use only stdlib, but Git and the selected project's tools are required; optional judging needs separately installed, authenticated CLIs. [S1, S7]

Python 3.9+ is plausible from the APIs used, and CI targets Python 3.9/3.13 on Ubuntu 24.04 and macOS. Native Windows is not supported as written: unconditional fcntl import and POSIX killpg/session/shell behavior require a Unix-like environment. WSL may be suitable but was not tested; neither live macOS execution nor actual harness plugin compatibility was verified here. [S3, S7]

Manual copy updates can drift; documented marketplace updates require an explicit update/restart unless auto-update is enabled. Pin and inspect a reviewed revision, and finish/checkpoint active climbs before changing controller semantics. Release 1.1.0 claims existing 1.0.0 climbs carry on; there is lightweight compatibility normalization for older check/score fields but no explicit versioned migration framework or authenticated evaluator manifest. CI actions use version tags rather than immutable commit pins, though workflow permissions are read-only and checkout disables persisted credentials. [S3, S7, S8]

## Licensing, Assets and Maturity

Root LICENSE is MIT, copyright 2026 Bil0000. Plugin metadata agrees. The two bundled SVGs are explanatory diagram/demo assets; no separate asset-license file or third-party exception was found in this small tree. This review does not redistribute them or extract source code. Target repositories, host CLIs and providers retain their separate terms. [S7]

Public GitHub metadata retrieved 2026-11-15: created 2026-11-02; last push 2026-11-12; 136 stars, six forks, three open issue/PR entries (one issue and two PRs in the retrieved list). Latest release v1.1.0 was published 2026-11-12. These indicate a very young, actively corrected project, not long-term operational validation. The exact reviewed SHA has a successful push CI run; a newer successful PR run is not evidence that its proposed changes are merged. [S8–S11]

## Verification and Limits

- Read all core implementation, skill/check recipes, test file, demo, manifests and CI; checked actual license and asset structure.
- Ran the 44-test upstream suite and Bash demo using a read-only source mount, disposable writable home/temp, cleared environment and an isolated network namespace. No host credentials, target projects, models, datasets, packages or device access were involved.
- Tests passed; demo reached 4 → 0, kept three steps, undid an equal-score step and a guard regression, and refused a changed locked test. This proves those synthetic paths, not general safety or performance.
- Judges were mocked by the test suite. No real Claude/Codex call, install/update, GUI exercise, real-project climb, crash injection, adversarial penetration test or performance claim reproduction was performed. GitHub CI status was observed, not independently rerun on its full platform matrix.

## Comparison and Practical Recommendation

| Alternative | Better fit / tradeoff |
|---|---|
| Plain tests + Git worktree + CI | Less automatic experimentation, but straightforward human-reviewed commits and independently enforced merge gates. Prefer for feature work that cannot honestly collapse to one score. |
| pytest-benchmark / pyperf | Better focus on repeatable performance measurement and baseline comparison; no coding-agent editing loop or multi-repo rollback. Can supply stronger measurements to a climb. |
| Anthropic eval-design/hillclimbing guidance ([existing review](claude-eval-design-hillclimbing.md)) | More emphasis on evaluator calibration, train/test separation and noise/headroom. Hill Climb supplies a compact local Git step controller; neither removes the need for independent evaluation. |
| Inspect AI ([existing review](inspect-ai.md)) | Structured model/agent evaluation with richer datasets, logs and sandbox integrations; substantially more framework than this local scorekeeper. |

**Adopt selectively:** start with deterministic failure counts or operation counts, complete-suite guards, a pinned controller, explicit lock coverage, dedicated worktrees and a separately verified final diff. Keep hidden evaluations outside the agent's authority. Recheck PR #11's eventual merge/revision before relying on noisy paired timing. This is worthwhile workflow infrastructure for a careful operator, not permission to let an agent optimize its own proof indefinitely.

## Sources

All code links below are pinned to the reviewed commit; issue/release/metadata links are time-sensitive public observations.

- [S1 — README and claims](https://github.com/Bil0000/Hill-Climb/blob/84b95909383379d4a84ad02ecadf928aba6b3b9b/README.md)
- [S2 — Agent workflow](https://github.com/Bil0000/Hill-Climb/blob/84b95909383379d4a84ad02ecadf928aba6b3b9b/skills/hill-climb/SKILL.md)
- [S3 — Controller: run/read_score/paired/fingerprint, snapshot/commit, init/try, holdout/relock and persistence](https://github.com/Bil0000/Hill-Climb/blob/84b95909383379d4a84ad02ecadf928aba6b3b9b/skills/hill-climb/scripts/climb.py)
- [S4 — Check methodology and recipes](https://github.com/Bil0000/Hill-Climb/blob/84b95909383379d4a84ad02ecadf928aba6b3b9b/skills/hill-climb/references/checks.md)
- [S5 — Synthetic tests](https://github.com/Bil0000/Hill-Climb/blob/84b95909383379d4a84ad02ecadf928aba6b3b9b/tests/test_hill_climb.py) and [demo](https://github.com/Bil0000/Hill-Climb/blob/84b95909383379d4a84ad02ecadf928aba6b3b9b/examples/demo.sh)
- [S6 — Optional judges](https://github.com/Bil0000/Hill-Climb/blob/84b95909383379d4a84ad02ecadf928aba6b3b9b/skills/hill-climb/scripts/judge.py)
- [S7 — Source tree / manifests / license](https://github.com/Bil0000/Hill-Climb/tree/84b95909383379d4a84ad02ecadf928aba6b3b9b) and [CI matrix](https://github.com/Bil0000/Hill-Climb/blob/84b95909383379d4a84ad02ecadf928aba6b3b9b/.github/workflows/test.yml)
- [S8 — v1.1.0 release](https://github.com/Bil0000/Hill-Climb/releases/tag/v1.1.0)
- [S9 — Open paired-input proposal #11](https://github.com/Bil0000/Hill-Climb/pull/11)
- [S10 — Readable holdout issue #12](https://github.com/Bil0000/Hill-Climb/issues/12)
- [S11 — Exact-revision CI run](https://github.com/Bil0000/Hill-Climb/actions/runs/43307012152) and [public repository metadata](https://api.github.com/repos/Bil0000/Hill-Climb)

---

**Attribution:** Bil0000/Hill-Climb, MIT. Independent technical review; upstream performance reports are identified as such.
