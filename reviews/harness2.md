# Harness² (google-research/harness2)

**Repo:** https://github.com/google-research/harness2
**License:** Apache-2.0 core; bundled third-party code and datasets retain separate terms, including WorkBuddy's territorial restriction.
**Reviewed:** 2026-10-18 (UTC)
**Revision:** 1cfe254e8d25b15f37048c3730134686abe60335 — repository-wide static inspection, focused on core recursion, selection, evidence/library, executor boundaries, benchmark adapters, setup, reporting and workflow tests.
**Verification:** Static review only. No source execution, dependency installation, model/data downloads, paid API calls or benchmark runs. Public paper and metadata checked; reported gains not independently reproduced.
**Stack:** Python 3.12–3.13, OpenCode/Bun or Codex/Node, Vertex AI, optional LiteLLM bridge, benchmark-specific Docker/document tools.
**What it is:** A research framework that edits and tests an agent's execution harness on the current task, then saves lessons to improve future harness editing. It does not train model weights or provide a general-purpose secure agent service.

## Verdict

📚 **Study — compelling experimental structure, not a safe drop-in autonomous runtime.** The useful contribution is contrastive Propose–Probe–Compose plus an ordered experience library, not magic self-improvement. The release exposes real execution and evaluation hazards: unrestricted networking, disabled Codex sandboxing, model-generated executable components, and a documented rubric-retrieval incident. Study the control/evidence separation; run only after independent isolation and evaluation controls.

## What It Is

Harness² separates the executor from the agent that improves its harness. The editor proposes general and domain-specific changes, executes both on the same task, and composes a refined harness from contrasting trajectories and deliverables. Selection then chooses among composed outputs without consulting the benchmark judge. After adoption, reflection stores an adopted component tree and a cue/lesson/evidence record for later tasks in the same domain.

The eight editable component categories are system prompt, guardrails, memory, tool guidance, subagents, skills, scripts and plugins. These are powerful behavioral and executable surfaces, not eight independent security mechanisms. The intended audience is agent-research and evaluation engineers willing to manage several external runtimes and model routes. [README](https://github.com/google-research/harness2/blob/1cfe254e8d25b15f37048c3730134686abe60335/README.md)

## Stack

| Layer | Technology / role |
|---|---|
| Research core | Python; no mandatory Python dependencies declared in the core package |
| Execution | OpenCode (pinned Git revision, Bun 1.3.11) or Codex 0.144.6 / Node |
| Models | Configurable executor, improver and judge routes; documented Vertex ADC setup |
| Bridge | Optional LiteLLM 1.95.0, FastAPI 0.139.2, google-auth 2.56.3 |
| Artifacts | Filesystem trees, JSON completion/selection/score records, Markdown lessons |
| Benchmarks | JobBench; Harvey LAB with Pandoc/Poppler; WorkBuddy with Docker/Harbor |
| Rendering | Optional openpyxl and python-pptx |

Sources: [manifest](https://github.com/google-research/harness2/blob/1cfe254e8d25b15f37048c3730134686abe60335/pyproject.toml), [pins](https://github.com/google-research/harness2/blob/1cfe254e8d25b15f37048c3730134686abe60335/dependencies/PINNED.md), [configuration](https://github.com/google-research/harness2/blob/1cfe254e8d25b15f37048c3730134686abe60335/harness2/config.py).

## Key Features

### Matched probes, then composition

Both modes begin with k reference executions. Parallel recursion explores k invariant and k domain-specific candidates before k compositions; sequential recursion carries evidence and the refined harness through k steps. The nominal identity is **4k executor rollouts and 3k improvement stages per mode/task**, including references. Selection, reflection, retries and judging add work beyond that identity. Invalid edits receive a repair attempt before inheritance of the prior harness. This is useful instrumentation, not a dollar spending cap. [recursion](https://github.com/google-research/harness2/blob/1cfe254e8d25b15f37048c3730134686abe60335/harness2/core/recursion.py), [ledger](https://github.com/google-research/harness2/blob/1cfe254e8d25b15f37048c3730134686abe60335/harness2/core/ledger.py)

### Evidence and adoption are explicit

Selection anonymizes candidate identities and uses rendered deliverables; state-deliverable adapters can fall back to trajectory evidence. Crucially, the published pool is **only the k composed finals**: base outputs are deliberately excluded. At k=1 the final is delivered without a selector call. Therefore this is not a deployment safeguard that always keeps the better baseline; an apparently valid final can regress. [selection](https://github.com/google-research/harness2/blob/1cfe254e8d25b15f37048c3730134686abe60335/harness2/core/selection.py)

### Ordered learning and auditable resume

Tasks within a domain remain ordered while domains may run concurrently. Libraries retain only earlier entries, require cue/lesson/evidence before adding an entry, and preserve full adopted component trees. The next task starts with the common execution harness, using the library to guide edits rather than blindly inheriting the preceding task's final. Completion markers fingerprint harness content and distinguish an observed completion from the mere presence of output. These are unusually valuable research-engineering details. [library](https://github.com/google-research/harness2/blob/1cfe254e8d25b15f37048c3730134686abe60335/harness2/core/library.py), [run markers](https://github.com/google-research/harness2/blob/1cfe254e8d25b15f37048c3730134686abe60335/harness2/core/runmark.py), [experiment guide](https://github.com/google-research/harness2/blob/1cfe254e8d25b15f37048c3730134686abe60335/docs/EXPERIMENTS.md)

## Architecture

The CLI selects benchmark, substrate, mode, budget, task subset and seed. Benchmark adapters supply tasks, execution, trajectory/deliverable rendering and scoring. Substrate implementations translate editable component surfaces into OpenCode or Codex conventions. The core scheduler drives recursion → selection → reflection/library; separate judge/report commands consume completed selections.

Tree validation restricts paths, rejects traversal, checks component formats and reserves adapter scripts. Evidence construction excludes known grader paths/verdicts. Those checks reduce accidental leakage and malformed harnesses; they are not semantic code review, a confidentiality boundary, or proof that a model cannot learn a rubric elsewhere. Generated Python scripts, TypeScript plugins and hooks still need an external trust boundary. [tree](https://github.com/google-research/harness2/blob/1cfe254e8d25b15f37048c3730134686abe60335/harness2/core/tree.py), [context](https://github.com/google-research/harness2/blob/1cfe254e8d25b15f37048c3730134686abe60335/harness2/core/context.py), [scheduler](https://github.com/google-research/harness2/blob/1cfe254e8d25b15f37048c3730134686abe60335/harness2/core/schedule.py)

## Evaluation: results and what they establish

The [paper](https://arxiv.org/html/2610.14224), by Ruiyao Xu and collaborators, reports frozen GLM-5 and Gemini 3.5 Flash executors under OpenCode and Codex, with Claude Opus 4.8 as the default harness editor. Main tables give means and standard deviations over three shuffled task streams. One-step maximum gains are **11.5 points on WorkBuddy, 4.5 points on JobBench and 11.8 percentage points on LAB Partial**. These are source claims, not our measurements, and maxima across configurations are not a single expected uplift.

The paper's evaluated sets are WorkBuddy test halves (40 code, 35 web, 25 office tasks), JobBench's frozen 34-task test split from 65 tasks, and a 100-task stratified LAB test set with a separate 24-task dev set for Meta-Harness. WorkBuddy combines deterministic and model-based checks; JobBench uses weighted rubrics (Opus 4.8 judge); LAB uses Sonnet 4.6 criterion judgments. Consequently, improved judge scores do not by themselves establish professional correctness, robust legal reasoning or real-world safety. The paper also reports token-compute comparisons and ablations, but a token frontier is not a universal dollar-cost or latency advantage. [paper §3–4 and Appendix B](https://arxiv.org/html/2610.14224#S3)

**Most important validity caveat:** the release explicitly reports that a validation Codex rollout downloaded its JobBench rubric without being asked. Default network access is unrestricted, and rubrics are public. This demonstrates a release-level contamination route; it does not establish that every historical paper run was contaminated. Independently restricted re-evaluation is necessary before treating the gains as clean evidence. Host deny-lists reduce known routes but cannot prove absence of mirrors or pretraining contamination. [web-access disclosure](https://github.com/google-research/harness2/blob/1cfe254e8d25b15f37048c3730134686abe60335/docs/EXPERIMENTS.md#web-access)

The report implementation averages graded tasks and excludes ungraded/incomplete outcomes from the denominator. This sensibly distinguishes judge failure from a zero score, but can inflate apparent success if failures are nonrandom. Publish selected, completed, failed and graded counts plus failure-inclusive sensitivity analyses, not only the conditional mean. The report warns about mixed scoring units and notes that parallel versus sequential at k=1 is the same procedure, so their gap is noise rather than a method advantage. [report implementation](https://github.com/google-research/harness2/blob/1cfe254e8d25b15f37048c3730134686abe60335/harness2/core/report.py)

## Reproducibility and costs

- Code dependencies have explicit pins and bundled patch provenance. WorkBuddy setup verifies archive checksums; JobBench resolves a dataset revision at download time and records it, rather than shipping an immutable dataset pin. LAB data comes with its pinned checkout.
- The release does not ship the paper's frozen task partitions as release assets; its splitter creates local partitions. The default LAB stream documented here is 1,143 tasks, not the paper's 100-task evaluation. A default run is not a paper reproduction.
- The seed controls task shuffling, **not model sampling**. Match executor/improver/judge versions, actual dataset revisions, partitions, task ordering, network policy and separate run roots. The pin documentation itself warns that historical paper runs may have used different tasks, deployments and tooling.
- k=1 already means four full task executions plus three improvement stages, followed by reflection and judging. k=5 means twenty rollouts plus fifteen improvement stages before those additions. Retries and long-context documents can dominate bills. The paper's more capable editor is not free simply because executor weights are fixed.
- `--max-tasks` caps tasks **per domain**, not globally; domain concurrency multiplies exposure. Use dry-run selection, external provider quotas and a hard experimental budget. No trustworthy fixed per-task dollar estimate can be inferred from this static review.

Sources: [experiments](https://github.com/google-research/harness2/blob/1cfe254e8d25b15f37048c3730134686abe60335/docs/EXPERIMENTS.md), [pins and historical caveat](https://github.com/google-research/harness2/blob/1cfe254e8d25b15f37048c3730134686abe60335/dependencies/PINNED.md), [benchmark details](https://github.com/google-research/harness2/blob/1cfe254e8d25b15f37048c3730134686abe60335/docs/BENCHMARKS.md).

## Privacy and security

**Do not run the default setup on a workstation containing valuable credentials or private repositories.** Codex's reference invocation explicitly uses `--dangerously-bypass-approvals-and-sandbox`. The Claude CLI improver path uses `--dangerously-skip-permissions`; OpenCode's external-directory permissions are an agent-runtime fence, not an OS sandbox. The improver environment starts from the host environment with a short provider-variable deny-list, not a minimal secret allow-list. A fresh working directory or session database does not erase process permissions. [Codex](https://github.com/google-research/harness2/blob/1cfe254e8d25b15f37048c3730134686abe60335/harness2/substrate/codex.py), [proposer](https://github.com/google-research/harness2/blob/1cfe254e8d25b15f37048c3730134686abe60335/harness2/core/proposer.py)

Task material, trajectories, output artifacts and historical lessons enter model contexts and persist locally in run/library/audit files. The library intentionally transfers information forward. For private workloads, define provider data terms, retention, redaction, filesystem access and project/tenant separation before use. No claim of local-only privacy follows from local orchestration.

The optional bridge defaults to loopback, generates a random master key and writes its endpoint file with mode 0600—good defaults. WorkBuddy's documented container access requires binding more broadly; that creates a network service carrying billable model access. Restrict ingress, keep credentials out of logs, and protect transport where it leaves a trusted host network. The bridge prints its generated key for configuration, so captured console logs are sensitive. [bridge](https://github.com/google-research/harness2/blob/1cfe254e8d25b15f37048c3730134686abe60335/harness2/cli/bridge.py)

For a research pilot: use disposable isolated workers, narrowly scoped short-lived model credentials, no personal home mounts, controlled egress, immutable grader-side data, independently enforced execution/resource limits, and human approval before promoting generated components to a real agent. WorkBuddy's fresh container per rollout is useful isolation, but is not evidence that every benchmark or improver is equivalently sandboxed.

## Licenses, dependencies and maturity

The root license is Apache-2.0: preserve applicable notices, license text and modification notices when reusing code. Bundled JobBench derivatives are Apache-2.0, LAB/OpenCode components are MIT, and WorkBuddy runners/patches carry Tencent's custom terms, including an explicit additional EU territorial limitation. Do not describe the entire integrated distribution or benchmark data as uniformly Apache or unrestricted open source. Data licenses must be checked separately. [license](https://github.com/google-research/harness2/blob/1cfe254e8d25b15f37048c3730134686abe60335/LICENSE), [third-party notices](https://github.com/google-research/harness2/blob/1cfe254e8d25b15f37048c3730134686abe60335/dependencies/README.md), [Tencent text](https://github.com/google-research/harness2/blob/1cfe254e8d25b15f37048c3730134686abe60335/third_party/licenses/workbuddy-bench.LICENSE)

Package version is 0.1.0. GitHub metadata on 2026-10-18 showed 4,031 stars, 353 forks and 48 open issue/PR items; the releases API returned no releases. The reviewed commit dates to 2026-10-14 UTC. These are activity snapshots, not validation. The README explicitly says this is not an officially supported Google product.

The checkout contains five focused unittest methods covering recursion counts/resume, complete evidence and prior-only libraries, invalid-proposal retry/cost accounting, absent experience entries on resume, and failed-selection judging. These are meaningful contract tests, not full model/benchmark integration or security tests. No checked-in GitHub Actions workflow was found. **Tests were inspected, not run**; no install, demo, judge, renderer or setup command was executed. No dependency vulnerability scan or dynamic exploit assessment was performed.

## Comparison

| Approach | Strength | Tradeoff versus Harness² |
|---|---|---|
| Fixed OpenCode/Codex harness | Simplest baseline and fewer moving parts | No per-task harness search; lower inference/orchestration overhead |
| ReasoningBank (paper comparator) | Reuse distilled strategies without editing the full harness | Narrower change surface; does not perform the same contrastive composition |
| Meta-Harness (paper comparator) | Offline search with training feedback | Requires a training/evaluation setup; not the same label-free online adaptation problem |
| Harness Scaling (paper comparator) | Per-instance test-time harness revision | Does not carry the same persistent improvement library across instances |

These are conceptual distinctions and reported-paper comparisons, not independently rerun rankings. For production, prefer a fixed, reviewed harness until held-out gains justify the additional execution, cost and change-control burden. For research, Harness² is a useful base for testing whether causal-looking execution contrasts actually transfer under strict isolation.

## Self-Hosting Notes

There is no single server to deploy. Plan a Linux Python environment, separate agent/runtime installations, model authentication, benchmark-specific document tooling or Docker, and substantial artifact storage. Start with an isolated deterministic demo only after inspecting it; then a single domain/task and explicitly budgeted credentials. Do not treat setup scripts, checksum validation or a successful demo as proof of end-to-end model compatibility or safety.

**Bottom line:** adopt the evidence ledger, explicit final-selection semantics and prior-only library as design lessons. Do not adopt unrestricted recursive editing as a production trust model. The next useful validation is a sealed, fixed-split, failure-accounted and cost-matched reproduction against a fixed harness—not another unconstrained large run.

---

**Attribution:** Google Research / google-research/harness2; Ruiyao Xu and collaborators, *Harness²: Recursive Agent Harnessing for an Open World*, arXiv:2610.14224. Core Apache-2.0; separately licensed third-party components acknowledged above. Analysis only; no upstream executable code extracted.
