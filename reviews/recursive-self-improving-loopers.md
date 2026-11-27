# Recursive Self-Improving Loopers (eelbaz/Recursive-Self-Improving-Loopers)

**Repo:** https://github.com/eelbaz/Recursive-Self-Improving-Loopers
**License:** No license found in the reviewed tree or package metadata. Public visibility is not a general grant to reuse or redistribute code; model and dataset rights require separate review.
**Reviewed:** 2026-11-27 (UTC)
**Revision:** `765453d13878804c49876a656f39b57a4384dca4`, main; full eight-module package, eight test files, manifest, README, six result JSON files, web-report text and four-page paper.
**Source date:** Paper dated 2026-11-26; commit timestamp 2026-11-27 00:17:54 UTC.
**Verification:** Static review only. Independently parsed 16 Python files with Python AST and six JSON files; checked reported generation arithmetic against the written acceptance rule. No source imported, tests run, dependencies installed, model downloaded, GPU job launched or paid service called.
**Stack:** Python ≥3.11, PyTorch, safetensors, NumPy; runtime Transformers integration and CUDA/NCCL.
**What it is:** A model-specific weight-editing and reinforcement-learning experiment for extending a looped mixture-of-experts transformer's inference depth, not a general-purpose autonomous coding agent.

---

## Verdict

📚 **Study the local-editing idea; do not treat this as a reproduced or deployment-ready self-improvement system.** The small mathematical core, bounded tensor edits and explicit multi-regime evaluation are useful research patterns. However, missing runtime/data prerequisites, an unused resume flag, an unwired final merge, and result logs inconsistent with the shipped acceptance rule prevent the claimed end-to-end recipe from being independently established by this repository.

## What It Is

Eric E. / Tensorbend.ai Research describe repairing forced four-pass inference in Inkling-2-Mini, whose middle layers normally execute three times. Stage one aligns later-pass activations to earlier-pass targets without labels or backpropagation. Stage two samples model answers, grades against supplied gold answers, updates a subset of weights, and accepts candidates using a fixed validation set. This is weight-space adaptation, not recursive rewriting of the training program.

The author reports default-three-pass gains on small public benchmark slices and explicitly acknowledges no independent reproduction. Anonymous GitHub metadata at retrieval showed a public repository, 17 stars, 2 forks, zero open issues, and no releases; the manifest says 1.0.0. These are a dated activity snapshot, not quality evidence. The canonical URL was checked against the public review index before creating this review.

## Stack

| Layer | Tech |
|-------|------|
| Package / CLI | setuptools; rse-looper → pipeline.main |
| Numerical core | torch ≥2.4, numpy ≥1.26, safetensors ≥0.4 |
| Model integration | Transformers Inkling2LoopForCausalLM and internal masking/cache APIs; not declared in dependencies |
| Parallel training | torch multiprocessing, NCCL gradient all-reduce, AdamW |
| Persistence | JSONL rollouts/gates, torch tensor deltas, copied safetensors checkpoints |
| Tests / automation | pytest ≥8; eight test files; no checked-in CI workflow or dependency lockfile found |

## Key Features

### 1. Local activation repair is concrete, but not a convergence proof

The [FP-Solve module][fp] collects pass-three outputs and earlier-pass preservation inputs, then edits 14 submodules across layers 6–17: 168 matrices. A ridge objective penalizes changes on preserved activations and caps each relative Frobenius-norm edit. The actual implementation uses `torch.linalg.solve`, despite prose calling it a Cholesky solve. The preservation term is a soft penalty, not an exact null-space projection. Pass-to-pass cosine similarity and finite calibration samples do not establish a global contraction bound or Banach fixed-point guarantee. Nor does mathematical “alignment” here imply behavioral safety alignment.

### 2. Self-generated answers still need external correctness labels

[GSPO][gs] samples two solutions in each of R3, R4 and damped RK2 modes, retains mixed-success groups, and gives a 0.35 bonus for deeper-mode successes when R3 failed. Its sequence-average log-probability objective uses asymmetric clipping, manual distributed gradient averaging, gradient clipping and a 5% per-generation weight-delta cap. “No external teacher” is narrower than “no supervision”: both training and gate JSONL files must contain gold answers.

### 3. Export guards are valuable but scoped

[Checkpoint mapping][cp] forbids expert, vision, embedding, output-head and scale names during export; verifies target shapes and floating dtypes; and writes an edit report. Synthetic round-trip tests cover unchanged expert and vision tensors. However, the general in-memory `apply_weight_deltas` helper does not enforce that allowlist, and the exporter copies ancillary files before checking edits. These controls restrict model edits, not operating-system permissions, semantic regressions or adversarial model behavior.

## Architecture

[Pipeline][pl] performs preflight then launches the FP-Solve and GSPO Python modules as fixed argument-list subprocesses. [Looping][lo] monkey-patches the model's forward method to change recurrence depth and uses cache snapshots/restores for damped substeps. It is tightly coupled to named Transformers internals and specific checkpoint layouts, rather than a generic transformer training backend.

The GSPO driver loads training and gate rows, runs a baseline gate, generates search shards, trains a delta, evaluates scales 1.0 and 0.6, exports an accepted generation and repeats. Generation and step limits plus rejection patience bound iterations. The final return points at the last accepted checkpoint. A separately tested `merge_generation_deltas` helper exists in pipeline.py, but neither driver calls it: the advertised automatic top-generation merge is not wired into this path.

### Correctness gates, holdouts and reward hacking

- The gate uses the first 64 rows of a supplied file repeatedly for candidate selection. It is validation feedback, not an independent final holdout. No train/gate disjointness check, immutable split manifest, benchmark item-ID list or contamination audit was found. The claimed separate “locked” test results are not reconstructible from aggregate JSON alone.
- Acceptance allows up to two lost correct answers per regime and bounded repetition. It accepts either higher total correctness **or unchanged correctness with at least four more completed outputs**. Thus “only strict gains” does not mean strictly improved accuracy in every regime.
- The same [math grader][gr] supplies rewards and gate scores. It extracts the last boxed answer or falls back to the last number; it checks simple string/numeric equivalence, not the validity of the reasoning. Completion requires a nonempty final segment but not EOS. These choices can reward answer/format exploitation and do not constitute independent verification. No adaptive exploit is demonstrated here.
- Gate aggregation counts `correct` separately from repetition, unlike training's win predicate. An answer with detected repetition can still add correctness while repetition is checked only through a separate aggregate threshold.
- The [reported GSPO sequence][results] cannot be the straightforward accepted trajectory of the default shipped rule. Generation 0's selected candidate has RK2 38/64; generation 1's selected candidate has 34/64, exceeding the permitted two-answer drop. Generation 3 is marked accepted although total correctness falls from generation 2's 118/192 to 114/192. The file contains five accepted entries numbered 0–4, while README/paper describe four generations. A different historical procedure could explain this, but no reconciled provenance is supplied.

### Evidence versus claims

| Source-reported observation | What it supports / does not support |
|-------|------|
| DeepScaleR R3 32/64 → 44/64; edited R4 45/64 | Promising aggregate result against the normal baseline; not independently reproduced |
| LiveCodeBench R3 11/32 → 13/32 | Two additional solved tasks; too small a slice for broad capability claims without paired records and uncertainty |
| MMLU 235/285 → 238/285 | Three additional answers; neither significant improvement nor generalization is established by totals alone |
| WinoGrande R3 206/300 → 201/300 for GSPO | Some skills regress; selective highlights must not imply universal gains |
| Terminal-Bench Core 0/10 → 6/10; newer suite 0/10 → 0/10 | Distinct reported suites; more shell commands / fewer JSON errors are not successful task completion |
| Integrity JSON says zero expert/vision changes | Author-supplied assertion; the integrity test reads that JSON rather than comparing downloaded real checkpoints |

The README correctly distinguishes default-three-pass Base from deliberately forced four-pass collapse. Terminal-Bench comparisons, however, use the forced four-pass baseline and must not be advertised as gains over normal default deployment. The checked-in results are summaries, not per-item outputs, container transcripts, exact slice manifests or a full benchmark runner. Bootstrap/permutation helpers exist, but supplied aggregate files cannot reconstruct paired outcomes or validate those significance calculations. See [general results][general], [terminal results][terminal] and [integrity tests][tests].

## Execution, Privacy and Cost Boundaries

This is a local Python/GPU process with the invoking user's filesystem, environment and network privileges. There is no application sandbox, human approval step or enforced network-denial policy. The inspected training path does not execute model-generated shell commands; Terminal-Bench's claimed Docker execution is separate reported evidence, not a bundled isolation boundary for this package. Fixed subprocess argument lists avoid shell interpolation in the pipeline, but do not restrict what dependencies can do.

Model/tokenizer loading uses Hugging Face-style identifiers without pinned revisions. It can contact a model host and use the runtime's configured cache/authentication. No hosted inference-provider integration or per-call API billing was found in the inspected modules; that does not make GPU compute, storage, downloads or cloud rental free. Search creates six completions per problem, gate evaluations are repeated across modes and scales, and training scores truncated sequences; the cited approximately 140-second update time is not the entire generation's cost. There is no dollar ceiling, wall-clock timeout, disk quota or provider spend guard. Preflight checks CUDA/kernel availability, not affordable memory capacity or model compatibility.

Search JSONL stores full problems, gold answers and raw generated text; checkpoint export copies ancillary contents from the base directory. No application-level encryption, redaction, retention or secure deletion policy is present. Use only approved non-sensitive datasets and isolated model directories. A few token-prefix checks in tests are not a comprehensive secret/privacy audit.

## Persistence, Recovery and Operational Gaps

- `--resume` is parsed and forwarded but never read by the GSPO runner. Restart reinitializes from the requested model and generation zero; it does not restore accepted-generation counters, optimizer state or a transactional journal.
- JSONL/delta/checkpoint outputs provide useful intermediate evidence, but writes are not atomic transactions and existing output directories are reused. Interrupted exports or reruns can leave partial/overwritten artifacts; backups and unique output paths remain operator responsibilities.
- The exporter expects a local directory with a specific single safetensors filename. The documented default is a hub model ID, and this code does not resolve that ID to a local export source directory. Sharded or differently named layouts are not handled generically.
- GSPO expects train_math.jsonl and gate_math.jsonl under data/, which is absent. The top-level CLI exposes neither dataset path. Transformers is missing from the manifest despite mandatory runtime imports, and no exact compatible build is pinned.
- One or two GPU IDs pass configuration validation, but gate aggregation always reads R3, R4 and RK2 shard files: fewer than three workers cannot produce all of them. Dry-run tests for two GPUs do not exercise this failure path.
- An empty frontier produces no training examples, yet update sampling falls back to index zero rather than skipping gracefully. No end-to-end test demonstrates these orchestration edges.

## Maturity and Verification

The eight test files cover numerical helpers, parsing, gates, synthetic checkpoint mapping, caches, preflight and CLI dry runs. This is useful unit-test structure; it is not evidence of a successful complete run. No checked-in CI, locked environment, packaged training/gate data, real-checkpoint integration test or independent reproduction was found in the pinned tree. A shallow checkout establishes the reviewed snapshot, not a comprehensive development-history audit.

Checks actually performed: anonymous GitHub metadata/releases retrieval; source and destination canonical identity checks; static module/test inspection; AST parsing of all 16 Python files; JSON parsing of all six result files; arithmetic comparison of declared accepted generations to the source gate. All syntax/JSON parsing passed. The arithmetic check exposed the trajectory mismatch above. Tests, numerical execution, downloads, hardware performance and checkpoint integrity were **not** run or independently verified. The external model and paper reference bibliography were not independently validated; no compatibility, availability or licensing claim about those external assets is made.

## Comparison

| Aspect | This project | Alternative approach |
|--------|--------------|----------------------|
| Need working inference | Experimental recurrence edits with orchestration gaps | Start with the model's supported default-depth inference; establish a reproducible baseline first |
| RL training infrastructure | Small model-specific GSPO driver | [Hugging Face TRL](https://github.com/huggingface/trl) offers a broader trainer ecosystem; custom recurrence still needs integration |
| Independent evaluation | Reused gate and aggregate result files | [lm-evaluation-harness](https://github.com/EleutherAI/lm-evaluation-harness) provides a separate evaluation framework; freeze datasets and keep final tests outside selection |
| Want an autonomous coding loop | Not this project's implemented purpose | Use a task agent with explicit tool permissions and isolated execution; model-weight adaptation is a different problem |

These are workflow comparisons, not fresh audits or guarantees about alternatives. For research, preserve the idea of small allowed weight updates and multi-regime regression checks, but first demand exact dataset/model/environment provenance, an independently held-out test, reconciled accepted-generation logs, complete merge/recovery wiring and explicit licenses.

## Self-Hosting Notes

Not recommended as a copy-and-run deployment. Before any separately authorized experiment: resolve code/model/data rights; pin a compatible Transformers/model revision; supply documented disjoint datasets; repair local-checkpoint export and resume/merge behavior; test one complete generation in a disposable, credential-free environment; enforce external GPU/time/disk budgets and re-evaluate the exported final artifact independently. Do not infer safety from a dry-run preflight or unchanged expert tensors.

---

**Attribution:** eelbaz/Recursive-Self-Improving-Loopers; paper by Eric E., Tensorbend.ai Research, dated November 26, 2026. No repository license found. This review contains independent analysis, not copied implementation code.

[fp]: https://github.com/eelbaz/Recursive-Self-Improving-Loopers/blob/765453d13878804c49876a656f39b57a4384dca4/rse_looper/fpsolve.py
[gs]: https://github.com/eelbaz/Recursive-Self-Improving-Loopers/blob/765453d13878804c49876a656f39b57a4384dca4/rse_looper/gspo.py
[cp]: https://github.com/eelbaz/Recursive-Self-Improving-Loopers/blob/765453d13878804c49876a656f39b57a4384dca4/rse_looper/checkpoint.py
[pl]: https://github.com/eelbaz/Recursive-Self-Improving-Loopers/blob/765453d13878804c49876a656f39b57a4384dca4/rse_looper/pipeline.py
[lo]: https://github.com/eelbaz/Recursive-Self-Improving-Loopers/blob/765453d13878804c49876a656f39b57a4384dca4/rse_looper/looping.py
[gr]: https://github.com/eelbaz/Recursive-Self-Improving-Loopers/blob/765453d13878804c49876a656f39b57a4384dca4/rse_looper/grader.py
[results]: https://github.com/eelbaz/Recursive-Self-Improving-Loopers/blob/765453d13878804c49876a656f39b57a4384dca4/results/gspo_results.json
[general]: https://github.com/eelbaz/Recursive-Self-Improving-Loopers/blob/765453d13878804c49876a656f39b57a4384dca4/results/general_skills.json
[terminal]: https://github.com/eelbaz/Recursive-Self-Improving-Loopers/blob/765453d13878804c49876a656f39b57a4384dca4/results/terminal_bench.json
[tests]: https://github.com/eelbaz/Recursive-Self-Improving-Loopers/blob/765453d13878804c49876a656f39b57a4384dca4/tests/test_integrity.py
