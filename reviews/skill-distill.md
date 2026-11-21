# skill-distill (sybil-solutions/skill-distill)

**Repo:** https://github.com/sybil-solutions/skill-distill
**License:** MIT; preserve Sybil Solutions' copyright and permission notice in substantial reuse. Input sessions, generated code, dependencies and model weights have separate rights.
**Reviewed:** 2026-11-21 (UTC)
**Revision:** `4c3b307096aea36ecd6cffddf52d1b415cf63d68` (main snapshot; entire tracked tree). Last commit 2026-11-21T03:48:00Z. No release/tag available.
**Verification:** Static review of all 14 tracked files; no source execution, installations, model calls, private transcripts or live application probes.
**Stack:** Python standard library, Bash, Git, tmux, Perl; external coding-agent CLIs; optional Playwright, Pillow and Chromium.
**What it is:** A teacher-agent workflow that converts one successful coding session into task-, model- and harness-specific instructions, then repeatedly replays the task. This is prompt/procedure distillation, not weight training.

## Verdict

📚 **Study — useful replay discipline, not a safe autonomous distillation service.** Frozen skill versions, repeated trials, first-divergence analysis and a human quality veto are worthwhile ideas. However, same-task replay is not evidence of generalization, execution deliberately bypasses important agent safeguards, and privacy, acceptance and budget rules mostly depend on the teacher obeying prose. Study or adapt in a disposable environment rather than install on a credential-bearing workstation.

## What It Is

The operator is a skill for Claude Code or Codex. A user selects a successful reference session and a student harness/model. The teacher extracts the session, writes acceptance criteria and a student skill, launches three student trials from a Git starting point, inspects their outputs and repairs the instructions. It repeats until matches or a stated stopping rule, then asks the user to accept the result. The final artifact is a skill directory, not a trained model or a generally validated capability.

The source recommends the first user message as the task, and a timestamp-derived Git commit as the initial state. Neither reconstructs later user clarifications, pre-existing dirty files, external services, installed dependencies or hidden environment state automatically. The operator must resolve these ambiguities before interpreting differences as model failures. [E1, E2]

## Stack

| Layer | Implementation |
|---|---|
| Control plane | Teacher follows Markdown; Python CLI does bookkeeping |
| Trial execution | Git clone/checkout, generated Bash script, tmux window, Perl alarm |
| Model access | Installed omp, pi, Codex, Claude Code or opencode CLI and its configured provider |
| Evidence | JSONL parsers, optional checks.sh, Playwright screenshots, Pillow blank-frame heuristic |
| Persistence | Plain files: run.json, frozen skills, workspaces, traces, verdict JSON, append-only ledger, HTML report |

## Key Features

- **Versioned replay:** each iteration snapshots the skill and each trial gets a new starting workspace. Removing the clone's origin reduces accidental pushes, but does not sandbox it or remove Git history. [E2]
- **First-divergence repair:** inspect the earliest meaningful error instead of polishing the final symptom. The workflow correctly says student claims of success are not evidence. [E1]
- **Reference-calibrated checks and user veto:** run the same checks on the reference and trials; compare full-resolution craft and intermediate states, not just features or thumbnail similarity. These are good methodological cautions, not automatic correctness guarantees. [E1]
- **Portable adapters:** the adapter contract is small and readable. README labels omp tested, Codex tested as teacher, and pi/opencode untested; that is author-reported compatibility, not independently reproduced here. [E3]

## Architecture and Implementation

The dataflow is session log → extracted reference → teacher-authored skill/checks → frozen iteration → Git workspace plus skill pointer → harness → trace and evidence → teacher verdict → user decision → final skill. The original prompt is preserved except trailing whitespace removal and an appended skill-pointer instruction; the student does not intentionally receive the complete reference transcript. [E2]

The manager is 373 lines; extraction 291; web capture 107. No packaged service, database or independent evaluator exists. Session detection supports Claude, Codex rollout, Codex exec and omp/pi formats; opencode has no parser. Extraction skips malformed JSON lines and clips tool text, so traces are lossy and tool-error counts are not uniform across formats. Reference extraction failure is printed but does not prevent run initialization. [E2, E4]

### Selection, distillation and evaluation validity

1. **Selection bias:** one user-selected successful session is the entire reference set. There is no representative corpus selection, deduplication, train/validation/test split or held-out task suite.
2. **Repeated adaptation to the same task:** three trials help reveal variability, but repeated prompt revisions against the same reference can overfit. No no-skill baseline, blinded independent grading, seed control, confidence interval or transfer study is supplied.
3. **Answer leakage is discouraged, not checked:** the instruction bans the finished solution while permitting short snippets and scripts. There is no similarity detector or provenance audit proving the resulting skill teaches rather than embeds the answer.
4. **A successful reference is not ground truth:** the rule that a failed reference check must be wrong can excuse defects in the reference itself. Independently justified requirements still matter.
5. **Acceptance is a record, not an enforced gate:** CLI verdict scores are free floats despite help saying 0–10. Acceptance copies the selected frozen skill without requiring completed trials, three matches, passing checks, an independent identity or secret scanning. It cannot authenticate that a human actually approved. [E1, E2]
6. **Capture exit status is weaker than interaction success:** action exceptions are recorded with a `step ` prefix and excluded from the errors used to compute `ok`. A nonblank first screenshot and no page errors can therefore yield exit 0 despite a failed click/key/JS/screenshot action or a bad later state. Console errors are also logged separately, not a blanket failure condition. The caller must assert outcomes explicitly. [E5]

The README lists an examples directory, but none is tracked at this revision. The skill narrates pilot scores and visual-detail percentages, including a user's rejection of superficially passing trials; no published run artifacts substantiate a reproducible benchmark here. [E1, E3]

## Security, Permissions and Privacy

### Fresh folders are not isolation

Codex uses `--dangerously-bypass-approvals-and-sandbox`; Claude uses `--dangerously-skip-permissions`; omp uses `--auto-approve`. Context suppression varies by adapter and is not a filesystem or network permission boundary. Trials inherit the host/tmux environment, can read outside their workspace, and can run tools with the invoking user's authority. Setup and checks execute shell commands; checks also execute against the reference workspace, which is not a frozen read-only copy. [E2, E3]

Shell generation uses JSON double-quoting for exported values rather than shell-safe quoting, leaves several generated paths unquoted, and accepts unchecked environment names. Shell expansion such as dollar substitution can still occur inside double quotes. Treat all run settings, names, paths, setup commands and generated scripts as trusted executable configuration; do not pipe model- or transcript-derived strings into them unchecked. Extra student arguments undergo shell word splitting/globbing. These are static code findings, not live exploit tests. [E2]

### Credentials and egress

No provider SDK or central credential vault is implemented. Credentials are supplied through harness configuration or environment; Claude's adapter explicitly documents endpoint/token variables. Explicit `--env` values and student arguments are serialized into run.json and generated run.sh, potentially persisting secrets in plaintext. No secret scanning, permission-hardening or environment allowlist is implemented. [E2, E3]

The helper scripts are largely local, but the workflow is not automatically local-only: teacher prompts/reference content go wherever the teacher model runs; student prompts, repository content and tool results go to its provider; setup/package tools, generated programs and browser pages can access the network. Web capture binds its default static server to loopback, but has no browser request allowlist; custom start commands can choose other exposure. Open weights do not imply local hosting. No telemetry uploader was found in these files, but harness/provider telemetry and retention were not audited. [E3, E5]

### Transcript and prompt-injection boundaries

Removing known system/context wrappers is **not redaction or injection defense**. User content, assistant answers, tool inputs/results, file paths and final answers remain; the task and final answer are not clipped. There is no credential/PII detector. Source files, tool output or malicious reference text can influence the teacher's generated instructions and later become a durable skill followed by an approval-bypassing student. The operator does not establish a robust data-versus-instruction boundary or quarantine generated scripts. [E1, E4]

The instruction to check final output for secrets and install only if the user wants it is sensible, but manual. Acceptance only copies to final/; global installation is a separate optional teacher action. Require an explicit review of the exact skill and bundled scripts before adoption, with versioning and a removable installation. [E1, E2]

### Retention and recovery

The ignored runs directory is a publication precaution, not encryption or access control, and an arbitrary run directory outside that repository does not inherit its ignore policy. Traces, summaries, prompt, screenshots, logs, provider arguments and reports remain on disk indefinitely; no TTL, purge or backup policy exists. Reports HTML-escape textual content, but still contain the task, skill, logs, workspace paths and screenshots and have no authentication mechanism. Do not expose a run directory as a public report. [E2, E4, E6]

Frozen iterations and the ledger aid diagnosis. They are not tamper-evident, atomic transactional storage or immutable evidence: same-user agents can reach parent directories, verdicts can be overwritten while ledger entries accumulate, and reference results/checks can change. A partial trial launch leaves an iteration that cannot simply be relaunched under the same number. Status trusts marker files rather than confirming process liveness. The Perl timeout does not establish a process-group cleanup guarantee for all descendants; tmux windows intentionally linger. Accepting a new final deletes the previous final copy, although older iteration snapshots remain. [E2]

## Costs, Supply Chain and Maturity

Default trials last up to 90 minutes, three per iteration. The prose suggests stopping at eight iterations or three without improvement: up to 24 student trials and 36 aggregate student-hours at the default timeout, excluding teacher work, setup and checks. This is an illustration, not a hard cap: CLI values and further iterations are unrestricted, and no token, dollar, GPU or concurrency budget meter is implemented. Provider pricing and local inference hardware determine actual cost. No paid calls were made for this review. [E1, E2]

At retrieval, public GitHub metadata reported creation on 2026-11-21, last push 2026-11-21T03:48:01Z, 293 stars, 23 forks and zero open issues; tags and releases were empty. Popularity on the first day is not reliability evidence. The exact tree has no CI workflow, automated test suite, dependency manifest or lockfile. Install instructions clone the moving default branch and optionally install unpinned Playwright/Pillow plus Chromium; harness versions and model/provider configurations are external. Python helpers are small and mostly standard-library, but the effective supply chain includes the CLI harnesses, their tools, browser binaries, task dependencies and generated code. [E3, E7]

## Comparison

| Option | Better fit | Tradeoff |
|---|---|---|
| Manual skill authoring plus version-controlled regression fixtures | A small number of known workflows | Less automated replay, easier to constrain permissions and review changes |
| [DSPy](https://github.com/stanfordnlp/dspy) | Programmatic LM pipeline optimization against datasets and metrics | Requires formalizing the program and evaluation; not this interactive end-of-session harness workflow |
| [promptfoo](https://github.com/promptfoo/promptfoo) | Versioned prompt/model test matrices and regression comparisons | Not a replacement for a coding agent's workspace execution or human craft assessment |

These are capability-level alternatives, not head-to-head benchmarks or a fresh audit of those projects. The strongest idea to retain is the frozen-skill/first-divergence/evidence ledger pattern, augmented with held-out tasks, an unskilled baseline and a separate safety gate.

## Self-Hosting Notes

No server deployment is necessary. Any evaluation should use a disposable VM/container with a sanitized repository snapshot, no host home directory or production credentials, explicit egress limits and externally enforced time/spend limits. Pin the source, harness, model and dependencies. Review checks and scripts before executing them, keep reference evidence immutable, make interaction failures fatal, and require a separate manual promotion gate for generated skills. These are recommendations, not features present in the project. No installation or adoption was performed.

## Evidence and Verification Limits

Pinned source evidence (all at the reviewed SHA):

- **E1:** [Operator workflow](https://github.com/sybil-solutions/skill-distill/blob/4c3b307096aea36ecd6cffddf52d1b415cf63d68/skills/skill-distill/SKILL.md): selection, evaluation, stopping rules, user acceptance and delivery.
- **E2:** [Run manager](https://github.com/sybil-solutions/skill-distill/blob/4c3b307096aea36ecd6cffddf52d1b415cf63d68/skills/skill-distill/scripts/distill.py): workspace setup (64–84), initialization (87–121), trial shell generation (124–162), collection, reporting and acceptance.
- **E3:** [README](https://github.com/sybil-solutions/skill-distill/blob/4c3b307096aea36ecd6cffddf52d1b415cf63d68/README.md) and [adapters](https://github.com/sybil-solutions/skill-distill/tree/4c3b307096aea36ecd6cffddf52d1b415cf63d68/skills/skill-distill/adapters): claims, compatibility, permissions and installation.
- **E4:** [Session extractor](https://github.com/sybil-solutions/skill-distill/blob/4c3b307096aea36ecd6cffddf52d1b415cf63d68/skills/skill-distill/scripts/extract_session.py): filters, formats, truncation and retained fields.
- **E5:** [Web capture](https://github.com/sybil-solutions/skill-distill/blob/4c3b307096aea36ecd6cffddf52d1b415cf63d68/skills/skill-distill/scripts/capture_web.py#L58-L103): server/network behavior, actions and success predicate.
- **E6:** [Ignore rules](https://github.com/sybil-solutions/skill-distill/blob/4c3b307096aea36ecd6cffddf52d1b415cf63d68/.gitignore) and [license](https://github.com/sybil-solutions/skill-distill/blob/4c3b307096aea36ecd6cffddf52d1b415cf63d68/LICENSE).
- **E7:** [Public repository metadata](https://api.github.com/repos/sybil-solutions/skill-distill), [releases](https://api.github.com/repos/sybil-solutions/skill-distill/releases), [tags](https://api.github.com/repos/sybil-solutions/skill-distill/tags), retrieved 2026-11-21; metadata is mutable.

All tracked source and documentation were read statically. No project tests, harness trials, capture sessions, model downloads or generated-skill executions were run. No private session logs were accessed. Reported bugs are code-path analysis, not runtime exploit demonstrations. Model quality, real costs, provider retention, adapter compatibility and pilot claims remain unverified. Publication checks cover artifact consistency, links, template integrity and public-only content, not product correctness.

---

**Attribution:** Sybil Solutions, [sybil-solutions/skill-distill](https://github.com/sybil-solutions/skill-distill), MIT. Review contains analysis rather than extracted implementation.
