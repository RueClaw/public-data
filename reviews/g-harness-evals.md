# harness-evals (garrytan/g-harness-evals)

**Repo:** https://github.com/garrytan/g-harness-evals
**Author:** Garry Tan
**License:** MIT own code; CC BY 4.0 findings, docs and data; third-party exceptions, including proprietary Claude Code material.
**Reviewed:** 2026-11-14 (UTC)
**Revision:** `edacaa87a81f4cbf431c17650174cdd225cb875b` (public main; commit dated 2026-11-13T20:41:19Z), package 0.0.136.
**Scope:** public README, principal coding/multi-user reports and corrections, runner/grader/statistics/proxy/ledger, adapters, task-validation tests, CI, provenance and custody documentation. Not an exhaustive audit of every experiment.
**Verification:** static source inspection plus an independent, read-only JSON recount of the committed frontier trial records. No source tests, model evaluations, installs, containers, provider calls or dataset/model downloads were run.
**Stack:** TypeScript/Bun 1.4.3, Python/Harbor, Docker/Compose, SQLite, MCP, Zod; shell/cloud orchestration.
**What it is:** an author-run comparative laboratory for agent harnesses, their prompts, skills and memory—not a new agent, a general model benchmark, or an independent certification service.

## Verdict

⚠️ **Interesting: excellent audit material, conditional evidence—not a universal harness ranking.** The unusually detailed corrections, trial records, cost ledger and task-clustered analysis make this worth studying and adapting. However, public development tasks, unequal multi-user effort/network settings, mutable grading/accounting interpretations and outage-sensitive decisions prevent a clean causal claim that one harness is generally best. Use it to design your own matched evaluation, not to choose a production agent from a rank alone.

## Identity and maturity

The canonical accessible source is **garrytan/g-harness-evals**. Its README calls the project **harness-evals**, while package metadata points to a separate upstream repository; public-export commits and verification documentation explain that this is a filtered public copy. Do not confuse its public commit history with the original experiment chronology. The public GitHub metadata at retrieval showed creation on November 5, last push November 13, 56 stars, 4 forks and 5 open issues/PRs combined; the releases endpoint returned none. These are discovery/maturity signals, not quality measures. The suite contains 256 top-level TypeScript test files, but file count is not a passing-test count. [Manifest](https://github.com/garrytan/g-harness-evals/blob/edacaa87a81f4cbf431c17650174cdd225cb875b/package.json), [verification contract](https://github.com/garrytan/g-harness-evals/blob/edacaa87a81f4cbf431c17650174cdd225cb875b/docs/verify.md).

## What is actually evaluated

Two headline workloads answer different questions:

- **Coding:** 52 selected public Terminal-Bench 2.1 tasks, two attempts per cell, eight core harness/model cells; eight additional easy tasks per cell are kept separate. Harbor 0.24.0 supplies task execution/verifiers. Claude Code is the Opus baseline and Codex the Sol baseline; comparing those two directly would confound model and harness. Pi is a standalone coding harness here, not the same treatment as QM's embedded Pi loop.
- **Multi-user work:** 20 public v0.3 tasks, normally four attempts each, in a synthetic company with chat, files, mail/calendar and access boundaries. These test scoped recall, corrections, synthesis and approval behavior, not arbitrary enterprise productivity. Spending caps leave OpenClaw's last-task coverage incomplete.

The repository also studies gstack skill following, gbrain access rules and prompt ablations. These are separate experiments, not features present in every ranked cell. Garry Tan discloses ownership of gstack/gbrain and relationships involving QM, Hermes and other participants. This transparency is useful; it does not create independent replication. [README/disclosures](https://github.com/garrytan/g-harness-evals/blob/edacaa87a81f4cbf431c17650174cdd225cb875b/README.md), [coding preregistration](https://github.com/garrytan/g-harness-evals/blob/edacaa87a81f4cbf431c17650174cdd225cb875b/docs/benchmarks/2026-11-07-frontier-harness/PREREGISTRATION.md), [multi-user report](https://github.com/garrytan/g-harness-evals/blob/edacaa87a81f4cbf431c17650174cdd225cb875b/docs/benchmarks/2026-11-04-matrix-mu/report.md).

## Architecture and useful engineering

| Layer | Implementation and consequence |
|---|---|
| Experiment control | Preregistrations, manifests, pinned adapter/image evidence and per-trial state make interventions inspectable. |
| Execution | Docker harness adapters or Compose sidecars; Harbor for terminal tasks; simulated-world HTTP/MCP services for conversational tasks. |
| Grading | Task TOML declares required/secondary predicates and forbidden effects; evidence is replies, world state and event history. |
| Accounting | Proxy-bound trial slots and a durable SQLite reservation ledger separate provider authority from agent credentials. |
| Analysis | Trial validity rules, per-task aggregation, seeded task bootstrap, paired comparisons, multiplicity corrections and cost ratios. |
| Publication | Committed receipts, correction overlays, analysis recipes and generated scoreboard blocks; filtered public exports. |

Especially worth borrowing are **oracle-plus-mutation grader tests**, **recorded infra/agent failure distinctions**, **adapter provenance gates**, and **explicit sensitivity analyses**. Provenance compares checkout-owned image files with source hashes and records image identity, but does not byte-verify every installed runtime; pins and hashes are provenance aids, not proof that a model endpoint behaved identically across time. [Trial provenance](https://github.com/garrytan/g-harness-evals/blob/edacaa87a81f4cbf431c17650174cdd225cb875b/runner/trial/provenance.ts), [task tests](https://github.com/garrytan/g-harness-evals/blob/edacaa87a81f4cbf431c17650174cdd225cb875b/tests/task-matrix.test.ts).

## Grader correctness: good controls, consequential historical failures

The multi-user grade requires every required predicate to pass and no declared forbidden effect. Secondary predicates are recorded without deciding the grade. Effects are inspected across event history, so reverting a prohibited write does not erase it. Missing required predicates and evaluation exceptions fail closed. All turns ending in selected failure exit codes yield n/a at the grading layer; analysis subsequently applies termination eligibility. [Grade entry point](https://github.com/garrytan/g-harness-evals/blob/edacaa87a81f4cbf431c17650174cdd225cb875b/runner/grade/index.ts).

These are primarily deterministic **regex/event graders**, not a calibrated independent LLM judge. A reply can satisfy a regex without being semantically correct; a paraphrased disclosure can escape a literal hidden-fact check. Finance detection is limited to declared patterns and simulated channels/recipients, not all real-world leakage. Oracle scripts and one-mutation-per-predicate tests validate specified behavior, not completeness against arbitrary agent outputs. Custom predicate modules are dynamically imported by path in the grader process: task packs are executable trusted inputs, not inert data. [Predicate implementation](https://github.com/garrytan/g-harness-evals/blob/edacaa87a81f4cbf431c17650174cdd225cb875b/runner/grade/predicates.ts), [task schema](https://github.com/garrytan/g-harness-evals/blob/edacaa87a81f4cbf431c17650174cdd225cb875b/runner/grade/task.ts).

The authors' November 9 correction is central evidence, not a footnote to skip:

- Runner-injected closing narration was being treated as an agent's chat reply.
- v0.3 excuse/not-retracted regexes rejected correct responses.
- Approval-relay expectations contradicted the old DM-privacy preamble; obeying the instruction could fail the task.
- Stream reservation charges were represented as measured cost.

Combined corrections move OpenClaw/Opus multi-user performance from **60/78, 76.3% task-mean** to **67/78, 86.3% task-mean**; Claude Code moves from 61/80 to 64/80. The difference between raw share and task-mean is intentional when coverage is uneven. The corrected differences still do not change the preregistered primary calls, but ten percentage points of score movement demonstrates grader sensitivity. Old and corrected figures coexist; the README's ranking ratios use corrections while several displayed estimates retain historical values. There is also editorial drift: the older correction page's rank commentary does not describe the README's later paired-ratio ranking scheme. Read the current method, correction overlay and original report together. [Correction evidence](https://github.com/garrytan/g-harness-evals/blob/edacaa87a81f4cbf431c17650174cdd225cb875b/docs/corrections/2026-11-09/README.md).

## Fairness, configuration and budget parity

Coding cells use the same model within a comparison, shared task order and nominal effort high, checked from requests. That is much better than comparing unrelated model defaults. It still does not enforce identical token consumption, tool availability, context windows or housekeeping models. Claude Code's small-fast model is pinned to the cell model; Codex caps the Sol context window at 872,000 tokens. Hermes web tools remained available while hosted search was off for other adapters. These are product-configuration comparisons, not an isolated system-prompt experiment.

Multi-user cells explicitly use **different thinking configurations**: Opus medium for Claude Code/OpenClaw, low for QM, and no thinking for Hermes. QM adds Haiku housekeeping and ran outside the internal-network topology; its primary pairs were not tested. Consequently, “same frontier model” does not mean equal inference effort or an identical execution environment. The shipped-default question is useful, but distinct from harness efficiency at a fixed compute budget.

Leases constrain aggregate provider spend, not equal dollars per attempt. Caps stopped remaining trials and some reruns; missingness can depend on cost, task order and infrastructure. Four concurrent coding trials per VM also make time figures contended, while multi-user elapsed time includes rig startup. List-price model cost is not total ownership cost: host/VM time, setup, maintenance and human review remain separate. [Coding report/settings](https://github.com/garrytan/g-harness-evals/blob/edacaa87a81f4cbf431c17650174cdd225cb875b/docs/benchmarks/2026-11-07-frontier-harness/report.md), [README configuration notes](https://github.com/garrytan/g-harness-evals/blob/edacaa87a81f4cbf431c17650174cdd225cb875b/README.md).

## Statistics and what the claims support

The statistical implementation has real substance: task-level bootstrap prevents treating repeated attempts as independent tasks; paired comparisons preserve shared task structure; missing cells are declared; seeded draws support reproducibility; undefined cost-ratio draws are counted and intervals withheld when too many are undefined. Coding uses task-level sign flips and Holm adjustments in separate difference/non-inferiority families. [Task aggregation](https://github.com/garrytan/g-harness-evals/blob/edacaa87a81f4cbf431c17650174cdd225cb875b/runner/stats/task-means.ts), [frontier statistics](https://github.com/garrytan/g-harness-evals/blob/edacaa87a81f4cbf431c17650174cdd225cb875b/runner/stats/frontier.ts), [analysis rules](https://github.com/garrytan/g-harness-evals/blob/edacaa87a81f4cbf431c17650174cdd225cb875b/scripts/frontier-harbor/analyze.ts).

Important qualifications:

1. **52 tasks with two attempts are 52 task clusters, not roughly 104 independent tasks.** Multi-user inference has only 20 task clusters. Coding's reported minimum detectable differences are roughly 7.5–13.3 points; multi-user roughly 7.7–14.2. Failure to reject a difference is not equality.
2. **Within 15 percentage points is a generous non-inferiority margin.** It can coexist with an interval wholly below zero. Five of six passing that test is not evidence that the harnesses perform identically.
3. **Cost ranks are descriptive, post-hoc paired bootstrap rankings.** They are not the preregistered accuracy tests or a simultaneous confidence guarantee across all possible ranks. Pair-specific missing tasks can make the “cheapest” label differ from the lowest overall row estimate.
4. **95% confidence intervals are not a literal 95% posterior probability that this fixed unknown lies inside this realized interval.** The README's plain-language “true number is very likely inside” is an intuitive simplification, and generalization remains conditional on the task selection and experiment.
5. **Outage handling materially changes decisions.** Of 896 core-plus-kept trial records, the report says 353 were hit during grading and 351 replaced. Widening the outage rule after earlier rerun outcomes existed changes three of six pair labels relative to amendment 4 alone. This is defensible repair with disclosed sensitivity, not pristine preregistration.

OpenClaw/Opus's reported -12.5-point coding gap and adjusted p=0.037 become inconclusive under alternative disclosed outage/refusal treatments. The report's categorical “do not pick” advice is stronger than this fragile development-set evidence warrants. Conversely, measured cost differences are useful hypotheses for local replication even when no universal winner follows. [Full results and sensitivities](https://github.com/garrytan/g-harness-evals/blob/edacaa87a81f4cbf431c17650174cdd225cb875b/docs/benchmarks/2026-11-07-frontier-harness/report.md).

## Selection bias, contamination and held-out claims

The 52 coding tasks were chosen using DeepSeek-V4.1-Flash results pooled over five high-performing harnesses. Tasks at or above 95% were removed; OpenClaw and Codex were not in that selection group. The preregistration itself notes this can pull comparisons toward no difference. The eight easy tasks are a diagnostic sample, not a cure for selection bias. Opus's baseline also hit a near-ceiling stage-0 result; the original stop rule and later amendments matter when interpreting continued testing.

All headline tasks are public development tasks. Same-model pairing may reduce common memorization effects but cannot cancel harness-specific retrieval, prompting or memorized-answer elicitation. This is observed rather than hypothetical: the contamination review identified **four Hermes answer-key exposures**, including two core Sol trials; those originally passing attempts are scored as failures. A host blocklist did not prevent web tools or delegated retrieval returning copies. Known fingerprints/canaries cannot prove absence of unrecognized leakage, and one subagent's internal steps were not visible. [Preregistration/task selection](https://github.com/garrytan/g-harness-evals/blob/edacaa87a81f4cbf431c17650174cdd225cb875b/docs/benchmarks/2026-11-07-frontier-harness/PREREGISTRATION.md), [report contamination section](https://github.com/garrytan/g-harness-evals/blob/edacaa87a81f4cbf431c17650174cdd225cb875b/docs/benchmarks/2026-11-07-frontier-harness/report.md).

Sealed-task machinery is more serious than simply labelling a folder “heldout”: encryption, commitments, opening budgets and release procedures exist. However, the project explicitly calls it **procedural custody**, and older plaintext sets are spent. It does not retroactively make these headline dev runs held out. Public exports cannot independently establish every original preregistration timestamp or hidden-task access event. [Custody protocol](https://github.com/garrytan/g-harness-evals/blob/edacaa87a81f4cbf431c17650174cdd225cb875b/docs/sealed-custody.md).

## Independent verification performed here

A reviewer-authored standard-library JSON reader—not repository executable code—read the frontier merged record file and contamination override list. It found **896 records with 896 unique trial IDs**. Applying the documented model/infra/exam exclusions, harness-error failures, consent checks and answer-key overrides reproduced the following core point estimates:

| Cell | Scored attempts | Task clusters | Passes | Task-mean pass rate |
|---|---:|---:|---:|---:|
| Opus / Claude Code | 103 | 52 | 91 | 88.462% |
| Opus / Hermes | 104 | 52 | 85 | 81.731% |
| Opus / OpenClaw | 104 | 52 | 79 | 75.962% |
| Opus / Pi | 102 | 51 | 83 | 81.373% |
| Sol / Codex | 104 | 52 | 87 | 83.654% |
| Sol / Hermes | 103 | 52 | 88 | 85.577% |
| Sol / OpenClaw | 104 | 52 | 79 | 75.962% |
| Sol / Pi | 102 | 51 | 82 | 80.392% |

These round to the report's headline pass rates. **This independently checks arithmetic on author-supplied records, not the truth of provider responses, grading outcomes, independence of trials, cost invoices, confidence intervals or p-values.** No live result was independently replicated. Sources: [merged records](https://github.com/garrytan/g-harness-evals/blob/edacaa87a81f4cbf431c17650174cdd225cb875b/docs/benchmarks/2026-11-07-frontier-harness/results/merged/trials.jsonl), [lookup overrides](https://github.com/garrytan/g-harness-evals/blob/edacaa87a81f4cbf431c17650174cdd225cb875b/docs/benchmarks/2026-11-07-frontier-harness/results/lookup-fails.json), [trial-value rule](https://github.com/garrytan/g-harness-evals/blob/edacaa87a81f4cbf431c17650174cdd225cb875b/scripts/matrix-analysis.ts).

## Reproducibility and log provenance

A frozen Bun lockfile, pinned Harbor requirements, task/source/image digests, adapter hashes, captured effort settings and committed trial JSONL make this markedly more inspectable than a chart-only benchmark. The verify pipeline rebuilds analysis in scratch space and compares receipt hashes. Its documentation correctly distinguishes MATCH, KNOWN, CAN'T REBUILD and UNAVAILABLE, and says prose is not generally verified.

The public copy deliberately omits some inputs, runtime captures and original-history commits. A green public verification result can therefore coexist with unavailable runs and skipped original-commit checks. Today's analysis scripts are used rather than necessarily the original scripts. These are explicit reproducibility boundaries, not reasons to dismiss the supplied records—but “everything reproduced” would be inaccurate. A shallow source checkout was used here; full-history verification and the dependency-requiring source test suite were not run. [Verification limitations](https://github.com/garrytan/g-harness-evals/blob/edacaa87a81f4cbf431c17650174cdd225cb875b/docs/verify.md).

## Execution, secrets, network and retention

- **Strong provider boundary:** the metering proxy owns real provider keys; bound per-trial slots, model restrictions, header handling and reservations limit agent access. SQLite WAL/full-sync transactions reserve before forwarding and retain worst-case reservations when usage cannot be settled. Good spend safety is not exact billing measurement—the historical corrections demonstrate why reservation and actual usage need separate columns. [Proxy](https://github.com/garrytan/g-harness-evals/blob/edacaa87a81f4cbf431c17650174cdd225cb875b/runner/proxy/metering-proxy.ts), [ledger](https://github.com/garrytan/g-harness-evals/blob/edacaa87a81f4cbf431c17650174cdd225cb875b/runner/ledger/budget-ledger.ts).
- **Not a hostile-code sandbox guarantee:** the in-container runner uses a non-root UID and scoped writable trial mounts, but the argument builder does not add a read-only root filesystem, capability drop, explicit memory/CPU/PID limits or no-new-privileges. Internal Docker networking disables off-machine routing and inter-container traffic, but host services remain part of the trust boundary. Process mode is even broader. [Docker runner](https://github.com/garrytan/g-harness-evals/blob/edacaa87a81f4cbf431c17650174cdd225cb875b/runner/trial/docker.ts).
- **QM is a stronger authority exception:** its core shares host networking and mounts the Docker socket to create its own sandboxes. Treat that core as host-authority software and isolate the whole evaluation machine, not just the task container. [QM Compose](https://github.com/garrytan/g-harness-evals/blob/edacaa87a81f4cbf431c17650174cdd225cb875b/harnesses/qm/compose.yaml).
- **Coding tasks intentionally have network access:** the Harbor extension requires its blocklist sidecar or refuses startup, but public egress with a denylist is not default-deny isolation. External verifier downloads caused the recorded outage, and web-mediated answers bypassed benchmark-host blocking. [Egress implementation](https://github.com/garrytan/g-harness-evals/blob/edacaa87a81f4cbf431c17650174cdd225cb875b/scripts/frontier-harbor/egress.py).
- **Capture is sensitive:** request bodies, transcripts, world events and harness state may contain prompts, task data and outputs. Optional request capture is hash-chained and size capped (256 MiB by default), without headers/query strings; omission of auth headers is not general secret redaction inside message bodies. The marker sanitizer detects known strings/Unicode escapes, not arbitrary private data. Public committed receipts are durable Git history, not expiring telemetry. No general public-artifact TTL was established in this review. Use synthetic inputs and review/redact exports; do not feed real work into a public-receipt workflow. [Capture controls](https://github.com/garrytan/g-harness-evals/blob/edacaa87a81f4cbf431c17650174cdd225cb875b/runner/proxy/capture.ts), [marker tripwire](https://github.com/garrytan/g-harness-evals/blob/edacaa87a81f4cbf431c17650174cdd225cb875b/runner/proxy/sanitize.ts).

For an authorized future replication, use a disposable secret-minimized host, reviewed task/grader code, constrained egress, narrowly scoped provider credentials and an explicit total-cost budget. Do not treat “keyless” as automatically sandboxed: custom graders and analysis commands still execute code.

## Tests, CI and reuse

CI definitions pin actions to SHAs, use read-only repository permissions, typecheck/test/documentation checks, preregistration-order checks and a dedicated analysis rebuild job. This is a meaningful engineering signal. The public Actions snapshot inspected here showed a successful scheduled admission-watch run at the reviewed SHA, **not proof that every test/verify job passed**; no such blanket claim is made. The test inventory includes statistical edge cases, record validation, proxy/ledger controls, task mutations and sealed-publication checks. [CI](https://github.com/garrytan/g-harness-evals/blob/edacaa87a81f4cbf431c17650174cdd225cb875b/.github/workflows/ci.yml), [tests](https://github.com/garrytan/g-harness-evals/blob/edacaa87a81f4cbf431c17650174cdd225cb875b/tests/task-matrix.test.ts).

Reuse the project's MIT code with its copyright/license notices; its own findings/docs/data are expressly CC BY 4.0, requiring attribution and indication of changes. Upstream harness material retains its own terms; Codex includes Apache notices, Claude Code is proprietary, and Terminal-Bench/SWE-bench task materials have separate upstream/project terms. Built harness images are not published. A root MIT badge is not permission to redistribute every prompt, dataset or binary. No source components were extracted for this review. [License](https://github.com/garrytan/g-harness-evals/blob/edacaa87a81f4cbf431c17650174cdd225cb875b/LICENSE), [third-party/data terms](https://github.com/garrytan/g-harness-evals/blob/edacaa87a81f4cbf431c17650174cdd225cb875b/THIRD_PARTY_NOTICES.md).

## Alternatives and practical fit

- **[Harbor](https://github.com/harbor-framework/harbor) / [Terminal-Bench 2.1](https://github.com/harbor-framework/terminal-bench-2-1):** use the underlying task-execution ecosystem when you need terminal benchmark compatibility rather than this project's particular harness comparison and synthetic company.
- **[Inspect AI](https://github.com/UKGovernmentBEIS/inspect_ai):** a broader task/solver/scorer/logging framework for building an application-specific evaluation; see the [existing review](inspect-ai.md). It still needs suitable tasks and sandbox configuration.
- **[Harness Leaderboard](https://huggingface.co/spaces/joelniklaus/harness-leaderboard):** relevant complementary harness/noise methodology and the source of this run's selection data—not independent replication of these closed-model results.

**Use this repository as an audit corpus and experiment-design reference.** Before relying on its ordering, freeze a corrected task/preamble/grader version; decide shipped-default versus equal-effort comparisons; align tool/network access; precommit missingness, outage and all-spend rules; use a fresh held-out sample; repeat enough independent task clusters; and report cost, success and safety jointly. The most valuable conclusion is that harness plumbing and measurement policy can move results substantially—not that a single table settles the harness question.

---
**Attribution:** Garry Tan, garrytan/g-harness-evals; MIT code, CC BY 4.0 own documentation/data and separately licensed third-party materials. Benchmark figures above are author-run results unless explicitly identified as the reviewer's arithmetic check.
