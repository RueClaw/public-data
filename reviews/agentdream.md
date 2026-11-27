# AgentDream (mvplab-ai/agentdream)

**Repo:** https://github.com/mvplab-ai/agentdream
**License:** MIT; copyright 2026 systemagents-ai. Preserve the notice when redistributing substantial code. Provider/model and optional adapter terms remain separate.
**Reviewed:** 2026-11-27 (UTC)
**Revision:** `b0e9aacde64da57b9025307d8bf2fd32448a28a5` (main); repository-wide static review, focused on pipeline, engines, backends, adapters, jobs/review, integrations, benchmark and CI.
**Release:** Latest public release observed: v0.1.1, published 2026-11-27T19:08:14Z; tag resolves to `b03d2ffc8aecb291656c6de5c796026c5063d406`, not the reviewed main commit. Package version: 0.1.1.
**Verification:** Anonymous public GitHub metadata and HTTPS clone verified. Static inspection only: no installation, source execution, tests, benchmark, training, inference, model downloads, private transcript access or paid calls. Upstream CI observations are not locally reproduced results.
**Stack:** Python ≥3.10; standard-library core; Markdown/JSON/SQLite stores; optional stancelog; urllib model APIs; Claude Code subprocess; stdio MCP.
**What it is:** A batch memory-maintenance library and CLI for agents: consolidate notes, compare them with session transcripts, propose corrections and insights, then review and optionally apply a staged store. It is not a model-training system.

---

## Verdict

⚠️ **Interesting — unusually inspectable memory hygiene, not demonstrated autonomous learning.** The deterministic default, reviewable operations, backups and synthetic controls are useful engineering choices. Pilot on copies with manual acceptance: semantic correctness, provider privacy, CLI isolation and hard-crash durability remain operator responsibilities. The published benchmark measures synthetic store cleanup, not improved real-agent task performance.

## What It Is

AgentDream runs between agent sessions rather than replacing the agent runtime. Markdown folders, JSON/JSONL stores, generic SQLite and an optional stancelog adapter become normalized memory entries; transcript loaders support Claude Code, OpenAI-style exports, JSONL and text. Its outputs are a new store, a diff and evidence-bearing operations, not updated model weights. [E1–E4]

“Learning” here means persistent external-memory editing. The offline deterministic engine uses text normalization, token overlap, typed value slots, recency and repeated-session cues. An optional LLM can propose more semantic merges and corrections. There is no embedding/vector database requirement, gradient update, reinforcement-learning loop or independent task verifier in the inspected pipeline. Later benefit depends on another agent actually consuming the accepted notes. [E2–E4]

## Stack

| Layer | Tech |
|-------|------|
| Runtime | Python ≥3.10, standard-library-only core; hatchling build backend |
| Entry points | CLI, Python API, stdio MCP, scheduler, Claude Code hook |
| Storage | Markdown, JSON/JSONL, SQLite; optional externally installed stancelog |
| Analysis | Deterministic heuristics or chunked LLM proposals with deterministic reduction |
| Providers | Anthropic and OpenAI-compatible HTTP APIs, local-server aliases, Claude CLI |
| Tests/tooling | pytest, Hypothesis, coverage, Ruff, mypy; GitHub Actions |
| Authority | Local process/filesystem permissions and host MCP-client approval policy |

## Key Features

### Staging is the useful abstraction

The default pipeline loads, redacts, limits, consolidates, verifies, extracts insights and writes a separate output. Operations carry IDs, targets, reasons, before/after text, evidence and dependencies. Partial acceptance follows dependencies; input hashes reject changed stores unless forced. This is more auditable than silently replacing a memory summary. CLI apply flags, hook auto-apply and MCP `accept` deliberately cross that boundary; “dry run” still writes local job artifacts and can call a provider. [E2, E5, E6]

### Two distinct engines, neither a truth oracle

The deterministic engine uses inverted indexes/blocking rather than naive all-pairs comparison, and includes checks against merging similarly worded notes about different entities. LLM phases plan bounded chunks, parse JSON-like responses, validate operation types/targets and reduce conflicting proposals. Failed or capped model work can fall back to heuristics, so inspect warnings rather than attributing every result to the selected model. [E3, E4]

The prompt explicitly treats transcripts as ground truth. A transcript can itself contain speculation, tool errors, stale claims or adversarial text. Citation validation establishes traceability, not factual entailment: for a known citation with an invalid quote, `validate_evidence` warns but substitutes the full message as supporting evidence. Corrections are downgraded only when no evidence remains; a surviving citation is not proof of the new claim. Model confidence is self-reported and heuristics use assigned scores, not calibrated probabilities. The hook’s `--safe` policy (merge/replace, confidence ≥0.75) is an operation filter, not a semantic safety guarantee. [E4, E6]

### A real, limited benchmark rather than just model self-grading

The benchmark generates labeled facts and transcripts, then uses code probes against known truth to score the before/after store. It includes unchanged controls and unrelated notes, a substantial improvement over judging only compression or asking the proposing model to grade itself. The documentation reports deterministic “answered” facts improving 50/80 → 80/80 with all changes, but only 60/80 under safe auto-apply; clean facts reach 70/80 and paraphrase cleanup remains 0/10. A single Claude CLI run reports 80/80 clean facts. These are **upstream-reported**, not reproduced here. [E7]

There is no held-out real-task evaluation in the inspected benchmark. Seeds vary template instances, not an independently withheld task distribution; the authors explicitly say the deterministic engine was fixed against this workload. “Answered” means probe-recognized values agree with truth, not an agent successfully answered a question or completed work. Regex/presence probes can miss assertions outside recognized wording. The model run uses the local login’s default model without a precise immutable model revision, repeated-run uncertainty or dollar accounting. Do not convert these numbers into claims of general intelligence improvement, long-term retention or production precision. A credible next step is frozen held-out transcripts/tasks, before/after agent runs, blinded human fact checking, false-edit rates and measured cost. [E7]

## Architecture

`entry point → DreamConfig → DreamJob → pipeline → adapter/engine → staged store + report → accept/restore`

`DreamContext` maintains a redacted working view and original entries, tracks operations and updates the view between phases. Chunked LLM calls are reduced deterministically: duplicate proposals coalesce, overlapping merges combine, and conflicts are ranked using evidence count, confidence and operation type. These are consistency rules, not an independent semantic evaluator. Config resolution and backend entry-point loading are trusted local code/configuration surfaces. [E2–E5, E8]

### Execution, approval and sandbox boundaries

- The core is a local library, not a sandbox or multi-tenant service. MCP is stdio; it supplies no separate user authentication, path allowlist or mandatory human-confirmation ceremony for `accept`. Clients must gate destructive tools themselves. [E6]
- HTTP backends request text/JSON and do not expose an internal tool executor. However, the Claude CLI backend launches `claude -p --output-format json`, inherits the process environment/current directory and permits extra arguments. It does not explicitly disable tools, isolate the filesystem, restrict credentials or impose its own permission mode. Actual Claude behavior depends on installed CLI policy; do not equate headless invocation with containment. [E8]
- Markdown loading checks outward symlinks and preserves them without reading their contents. JSON directory loading instead selects `is_file()` matches then reads bytes without the same containment check. Use trusted input directories; do not assume uniform adapter confinement. This is static code observation, not an exploitation test. [E9]
- Untrusted transcript instructions can influence proposed durable memory. Human review, least-privilege paths and independent evidence are still necessary even when JSON structure validates. [E4]

### Secrets, privacy, egress and budgets

Redaction runs on analyzed content and final model prompts, with provider-key patterns, assignment rules, entropy detection, cards and configurable patterns; email redaction is off by default. This is a useful defense, not comprehensive anonymization: prose, names, paths and business facts may still leave the machine. Turning on a hosted backend sends selected memory/transcript content to its configured endpoint; custom base URLs and inherited provider environment variables are operator-trusted. The deterministic default requires no model network request; local OpenAI-compatible servers can avoid hosted inference when separately configured. No telemetry call was identified in the inspected core, but that is not a dependency or external-CLI privacy audit. [E2, E8, E10]

Local artifacts also matter. `snapshot.json` deliberately stores original, unredacted entries; staged stores and backups preserve original sensitive content. Job configuration serializes `backend_options`, while `_shown_config` specifically scrubs instructions/session paths rather than all backend options: avoid passing literal API keys there. Redacted reports are not permission to publish entire job directories. Atomic JSON/text files use `mkstemp`, but not every directory, copied store, log or backup is covered by that file-creation path; use a private job directory, restrictive account permissions, encryption/retention policy and environment-based credentials. [E2, E5, E10]

Defaults cap input estimates at 400,000 tokens, 100 sessions, 20,000 entries and 2 MB per transcript; LLM planning allows 64 chunks per phase at an estimated 60,000 tokens each, with two retries. These are approximate work limits, not a dollar budget or exact tokenizer accounting. Anthropic has an output-token setting; the OpenAI request shown has no explicit output-token limit. No global spend ledger, provider quota enforcement or total-job monetary ceiling was found. Apply independent provider budgets and conservative call limits before automation. [E8, E11]

### Persistence and recovery

Jobs persist state, operations, original snapshots, input hashes and reports; dead worker detection marks interrupted jobs failed rather than presenting partial reports as complete. Acceptance backs up the target, writes a sibling replacement, and swaps paths with rollback on caught failures. Restore is available. This supports recoverability, but is not a transactional guarantee across all failure modes. [E5]

The swap uses multiple renames; abrupt process death between them cannot execute Python exception rollback. The target can temporarily be absent, and sidecars complicate SQLite replacement. Accept locks live under the chosen jobs directory and key on an absolute path, so different job roots/path aliases do not necessarily coordinate the same target. `restore` does not use the same target-lock wrapper. Single-writer operation, retained backups and a tested recovery procedure are prudent; no automatic mid-phase resume or power-loss proof was established. Existing crash tests cover injected exceptions and killed workers, but were not run for this review. [E5, E12]

## Maturity, Dependencies and License

The manifest labels the project Alpha. At retrieval, public metadata reported 18 stars, 3 forks, 2 open issues (GitHub’s combined issue/PR count) and last push 2026-11-27T19:36:37Z. Popularity is not reliability evidence. One release, v0.1.1, was returned by the releases endpoint. [E1, E13]

There are 41 `test*.py` files, including edge suites for permissions, traversal, malformed/model output, concurrency, limits and crash recovery. CI specifies Ubuntu Python 3.10–3.13, best-effort macOS jobs, Ruff, mypy, examples and smoke tests; coverage is non-branch with a 94% threshold, not proof of semantic safety. Anonymous GitHub observation showed CI and Dream example successful for the exact reviewed SHA. This confirms upstream run status, not every optional/live path: live tests are opt-in, and no local test or benchmark was run. [E1, E12, E14]

The empty core dependency list reduces SDK footprint. Build/dev requirements use lower bounds, CI installs stancelog from an unpinned Git URL, and Actions use major-version tags rather than commit pins. No dependency lockfile was found. Optional adapters, installed backend entry points, external Claude CLI and model/server packages expand the trust and licensing boundary. MIT covers this repository’s code, not provider services, third-party code or model weights; the stancelog repository’s license was not independently audited here. No source extraction accompanies this review. [E1, E8, E14]

## Comparison

| Aspect | AgentDream | Versioned Markdown + manual review | Letta / Mem0-style memory systems |
|--------|------------|------------------------------------|----------------------------------|
| Primary fit | Offline consolidation of existing stores | Maximum edit control, minimal machinery | Broader agent-memory lifecycle or retrieval integration |
| Memory mechanism | Heuristic/LLM edit proposals | Explicit human-authored diffs | Product-specific structured/retrieval-backed memory |
| Operational cost | Offline default; optional inference | Human attention; no required inference | More integration/service/storage decisions |
| Safety decision | Review every semantic edit; control auto-apply | Reviewer owns each change | Evaluate each product’s authorization and persistence separately |

Start with a versioned copy and manual diffs if memory volume is small. AgentDream becomes interesting when repeated cleanup warrants a batch pipeline but a new agent platform or retrieval service does not. [Letta](https://github.com/letta-ai/letta) and [Mem0](https://github.com/mem0ai/mem0) are architectural alternatives, not independently audited or benchmarked equivalents in this review.

## Self-Hosting Notes

1. Pin a reviewed revision and use a dedicated unprivileged environment; do not attach real private transcripts merely to test installation. Start with synthetic copies and deterministic analysis.
2. Keep source stores, jobs, backups and credentials separate. Restrict input/output paths and keep one writer per store. Explicitly exclude job artifacts from publication or shared backup destinations.
3. Review diff, evidence, fallback warnings and proposed deletions before acceptance. Disable hook auto-apply initially; do not expose MCP `accept` to an agent without host-side approval.
4. For LLM use, approve the destination and data handling first, set independent budgets and minimize selected sessions. Prefer direct text APIs or separately constrained local inference over assuming a CLI is sandboxed.
5. Test backup/restore on disposable copies, including process interruption and concurrent edits. Measure held-out false merges and real task outcomes before enabling unattended consolidation.

## Evidence and Verification Ledger

All code links pin the reviewed SHA; mutable metadata and workflow observations were retrieved anonymously on 2026-11-27 UTC.

- **E1:** [README](https://github.com/mvplab-ai/agentdream/blob/b0e9aacde64da57b9025307d8bf2fd32448a28a5/README.md), [manifest](https://github.com/mvplab-ai/agentdream/blob/b0e9aacde64da57b9025307d8bf2fd32448a28a5/pyproject.toml), [MIT license](https://github.com/mvplab-ai/agentdream/blob/b0e9aacde64da57b9025307d8bf2fd32448a28a5/LICENSE).
- **E2:** [Pipeline](https://github.com/mvplab-ai/agentdream/blob/b0e9aacde64da57b9025307d8bf2fd32448a28a5/src/agentdream/pipeline.py).
- **E3:** [Deterministic engine](https://github.com/mvplab-ai/agentdream/blob/b0e9aacde64da57b9025307d8bf2fd32448a28a5/src/agentdream/engine/deterministic.py), [engine dispatch/fallback](https://github.com/mvplab-ai/agentdream/blob/b0e9aacde64da57b9025307d8bf2fd32448a28a5/src/agentdream/engine/__init__.py).
- **E4:** [LLM prompts, evidence validation, planning and reduction](https://github.com/mvplab-ai/agentdream/blob/b0e9aacde64da57b9025307d8bf2fd32448a28a5/src/agentdream/engine/llm.py).
- **E5:** [Jobs](https://github.com/mvplab-ai/agentdream/blob/b0e9aacde64da57b9025307d8bf2fd32448a28a5/src/agentdream/jobs.py), [accept/restore](https://github.com/mvplab-ai/agentdream/blob/b0e9aacde64da57b9025307d8bf2fd32448a28a5/src/agentdream/review.py), [atomic writes](https://github.com/mvplab-ai/agentdream/blob/b0e9aacde64da57b9025307d8bf2fd32448a28a5/src/agentdream/util.py).
- **E6:** [MCP authority](https://github.com/mvplab-ai/agentdream/blob/b0e9aacde64da57b9025307d8bf2fd32448a28a5/src/agentdream/mcp_server.py), [CLI policies](https://github.com/mvplab-ai/agentdream/blob/b0e9aacde64da57b9025307d8bf2fd32448a28a5/src/agentdream/cli.py).
- **E7:** [Benchmark methodology/results](https://github.com/mvplab-ai/agentdream/blob/b0e9aacde64da57b9025307d8bf2fd32448a28a5/docs/BENCHMARK.md), [generator/scorer](https://github.com/mvplab-ai/agentdream/blob/b0e9aacde64da57b9025307d8bf2fd32448a28a5/src/agentdream/bench.py).
- **E8:** [Provider and subprocess implementations](https://github.com/mvplab-ai/agentdream/blob/b0e9aacde64da57b9025307d8bf2fd32448a28a5/src/agentdream/backends/builtin.py), [backend entry points/aliases](https://github.com/mvplab-ai/agentdream/blob/b0e9aacde64da57b9025307d8bf2fd32448a28a5/src/agentdream/backends/__init__.py).
- **E9:** [Markdown paths](https://github.com/mvplab-ai/agentdream/blob/b0e9aacde64da57b9025307d8bf2fd32448a28a5/src/agentdream/adapters/markdown.py), [JSON paths](https://github.com/mvplab-ai/agentdream/blob/b0e9aacde64da57b9025307d8bf2fd32448a28a5/src/agentdream/adapters/jsonstore.py).
- **E10:** [Redaction behavior/exemptions](https://github.com/mvplab-ai/agentdream/blob/b0e9aacde64da57b9025307d8bf2fd32448a28a5/src/agentdream/redact.py).
- **E11:** [Configuration defaults](https://github.com/mvplab-ai/agentdream/blob/b0e9aacde64da57b9025307d8bf2fd32448a28a5/src/agentdream/context.py).
- **E12:** [Crash-recovery tests](https://github.com/mvplab-ai/agentdream/blob/b0e9aacde64da57b9025307d8bf2fd32448a28a5/tests/edge/test_crash_recovery.py), [test tree](https://github.com/mvplab-ai/agentdream/tree/b0e9aacde64da57b9025307d8bf2fd32448a28a5/tests).
- **E13:** [Public repository metadata](https://api.github.com/repos/mvplab-ai/agentdream), [releases](https://api.github.com/repos/mvplab-ai/agentdream/releases), [v0.1.1](https://github.com/mvplab-ai/agentdream/releases/tag/v0.1.1).
- **E14:** [CI definition](https://github.com/mvplab-ai/agentdream/blob/b0e9aacde64da57b9025307d8bf2fd32448a28a5/.github/workflows/ci.yml), [observed CI run](https://github.com/mvplab-ai/agentdream/actions/runs/46057913856), [observed dry-run example](https://github.com/mvplab-ai/agentdream/actions/runs/46057913870).

**Limitations:** Static, bounded review; no exploit validation, complete dependency-license audit, provider-policy audit, runtime integration test or independently reproduced improvement. Public source instructions were treated as data. Findings identify deployment boundaries, not a certification of safety or an assertion of observed exploitation.

---

**Attribution:** mvplab-ai/agentdream; MIT; copyright 2026 systemagents-ai. Independent public-source analysis; no project code copied.
