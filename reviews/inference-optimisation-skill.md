# Inference Optimisation Skill (sybil-solutions/inference-optimisation-skill)

**Repo:** https://github.com/sybil-solutions/inference-optimisation-skill
**License:** MIT, copyright 2026 Sybil Solutions contributors; preserve the notice in substantial reuse. Engine, model-weight and dataset licenses remain separate.
**Reviewed:** 2026-11-26 (UTC)
**Revision:** fda968e7fc1996aa23c67139c755fe541c9d4be0 (main; all 17 tracked files). Commit dated 2026-11-16T18:40:03Z.
**Verification:** Static inspection and independent arithmetic only. No source execution, installation, inference, GPU work, model/data downloads or paid calls.
**Stack:** Markdown agent skill, Python standard library, Bash; external OpenAI-compatible server, optional Docker/Linux memory tooling.
**What it is:** A procedure and small benchmark harness for an agent or engineer tuning a local model server. It is not an inference engine or an automatically enforced qualification system.

## Verdict

📚 **Study — strong experimental habits, materially incomplete executable safeguards.** Interleaved controls, negative-result logs, workload-specific speculation and pinned clean-build qualification are valuable. But the shipped ceiling calculator double-counts concurrency, the benchmark can mark failed retrieval or looping output successful, and the watchdog/queue are not fail-closed. Use the method as a checklist; do not treat this revision as an autonomous tuning controller or its output as a release certificate.

## What It Is

The skill inventories hardware and model state, estimates throughput ceilings, measures a baseline, changes one lever and compares against neighboring controls. It asks the operator to retain PLAN.md, THEORY.md, configs, a JSONL ledger and a best configuration, then qualify a clean pinned build. The standalone PROMPT.md gives similar instructions to any coding agent. None of those instructions were adopted or executed in this review. [S1, S2]

Its practical advantage is accumulated failure knowledge: speculative acceptance is not throughput, graph-off profiles are not graph-on timing, unified-memory accounting misses driver residency, and kernel changes need numerical checks. The repository distinguishes general versus stack-specific levers and labels INT8/FP8 prefill as potentially lossy. [S6]

## Stack

| Layer | Implementation |
|---|---|
| Control plane | Agent follows SKILL.md/PROMPT.md; no autonomous optimizer implementation |
| Benchmark | Python urllib streaming client and ThreadPoolExecutor; no third-party Python dependencies |
| Theory | Small JSON-driven roofline approximation |
| Queue | Bash, flock, one advisory lock, sequential config names |
| Memory | Docker PIDs, Linux cgroups/DRM fdinfo or nvidia-smi |
| State | Working-directory ledger and per-config logs; manually maintained plan/best config |

## Key Features

- **Controlled experiments:** six fixed prompts by default, median single-stream decode, candidate between two controls, and explicit rejection of noisy improvements. The comparison and regression decision are instructions, not implemented code. [S2–S4]
- **Useful measurement distinctions:** server usage tokens rather than SSE chunk count; cold unique prefill documents; concurrent total completions divided by wall time; gate metrics kept separate from hill-climb metrics. [S3, S6]
- **Qualification discipline:** pinned weights/images/kernels, clean builds, six acceptance gates, concurrent full-context soak, output equivalence and comparison against the best build. This is a documented protocol, not a supplied six-gate runner. [S7]
- **Negative results:** failed fusion, too-deep speculation and cache/precision regressions are first-class evidence rather than discarded trials. These are scoped author observations, not universal optimization laws. [S6]

## Architecture and Static Findings

### The advertised ceiling has an extra concurrency factor

In ceiling.py, verify already represents the bytes for all N streams: shared dense/head weights, a union of expert rows and per-stream KV. Dividing those bytes by accepted_length × N gives bytes per emitted token. The return expression then multiplies bandwidth / bytes_per_token by N **again**. Aggregate throughput is therefore inflated by a factor of N relative to this very model; N=1 is unaffected. [S5]

Independent arithmetic, without running the source: for a dense-only example with 100 GB/s, 1 GB total target bytes, no draft/KV and accepted_length=1, N=4 emits four tokens per shared read. The model implies 400 tok/s, while the implemented expression yields 1,600. This is dimensional/code-path analysis, not a GPU measurement. Open issue #1 and PRs #3/#4 also discuss the concurrency error; proposed fixes are not in the reviewed SHA. [M2]

Even after that fix, the calculator is a conditional approximation: routing independence, effective bandwidth, batch compute limits and KV reuse are assumptions. Draft bytes are multiplied by N despite possible batched reuse; recurrent-state reads in the reference formula are absent from the implementation. The utility prints decode/prefill and KV bytes per 256K stream, not a complete TTFT/startup/capacity model. A 50% MFU factor is a heuristic, not a rigorous physical ceiling. [S5, S6]

### A completed request is not a passing correctness gate

bench.py records long retrieval as a substring count such as 0/3, then sets ok=true regardless of that count. LOOP is only a flag, not a failed run. Missing usage can produce null single-stream metrics or zero concurrent throughput without failing the run. Finish reasons, stop completion, semantic correctness, served-model identity and true concurrent scheduling are not asserted. [S3]

The long test is one generated approximate-length document, not automatically half/full context or a concurrent full-KV soak. There is no greedy-equivalence runner, logits/KL comparison, tool round trip or six-gate implementation here. The fixed 1.6-tokens-per-word estimate contradicts the reference's advice to size with the real tokenizer: reporting actual prompt_tokens is useful, but does not ensure the requested target context was tested. Retrieval of three strings is a smoke test, not broad quality preservation. [S3, S6, S7]

### Streaming accounting still has a coalescing trap

Using usage counts fixes the crude chunks-as-tokens mistake, but timing starts at the first content/reasoning chunk and subtracts only one token. If that chunk contains multiple speculative tokens, or most content arrives at once, the numerator and measured interval do not align. Final usage/trailer latency also enters the denominator. There is no token-arrival validation, finish-reason check or rejection of nearly instantaneous/coalesced samples. Open PR #9 discusses this problem; it is not a landed correction. [S3, M2]

Prefill prompt_tokens/TTFT includes HTTP, scheduling, tokenization and first-generation costs rather than isolated kernel throughput. cN correctly uses total wall time but includes prefill and provides no latency percentiles, offered-load sweep or SLO goodput. Medians across six different prompts mix content effects with repeatability; a stronger design repeats paired prompts and estimates uncertainty. The prose's bootstrap interval and neighboring-control acceptance rule are not implemented. [S3, S6]

### Memory and environment controls fail open

The watchdog silently skips probe exceptions, treats empty output as zero and does not check subprocess return codes. A missing/failed sudo probe can thus leave a seemingly tiny memory peak. On a cap breach it calls the configured stop command once; if absent or ineffective, it does not itself cancel the benchmark or ensure the server stops. Probe sampling starts only after launch returns; blocking foreground launch commands never reach health polling or watchdog start. There is no timeout on launch/stop. [S3]

mem.sh is specifically Docker/Linux-oriented, not a portable Apple memory implementation. It assumes particular cgroup paths, returns zero for absent anonymous-memory data, skips unreadable DRM entries and interprets all residency values as KiB without checking their units. Driver residency plus anonymous memory is useful but not a universally exact non-overlapping total; privileges, driver semantics and container layouts require validation. NVIDIA queries are repeated per PID rather than one atomic snapshot. [S4]

AC checks accept absent Linux online files or exceptions; no performance-profile, thermal, host-idleness or other-GPU-job guard is implemented. The existing-server example supplies neither memory watchdog nor AC requirement. A changed-and-restored power state during a run can evade start/end checks. The Docker example binds its published port to loopback, but stopping uses abort request → fixed five-second sleep → docker stop → forced removal, not verified draining. [S3, S8]

### Queue success and restartability are overstated

queue.sh serializes only callers honoring the same advisory lock. Direct bench.py calls and other GPU jobs bypass it; flock is not a standard macOS utility. Lock acquisition is unchecked, so a missing/failing flock does not prevent continuing. The script lacks fail-fast handling, prints done for failed benchmarks and ends with QUEUE_DONE. bench.py likewise does not turn a returned ok=false into a nonzero CLI status. [S3, S4]

Detaching is a suggested shell invocation, not a durable scheduler. Per-name run logs are overwritten on repeat while ledger rows append, with no run UUID/config hash, atomic checkpoint, resumable queue cursor or process-group cleanup. The ledger omits the full config, source/model/driver revisions and output text; a mutable config name is not reproducible provenance. Launch failures and initial unreachable-server exits occur outside the benchmark exception block and can leave no ledger row. A malformed/truncated JSONL line breaks show. Best-server restoration, power-profile rollback and cleanup are operator responsibilities. [S2–S4]

## Performance Evidence: Better Than Headlines, Still Author Measurements

The README claims B390 c1 43.6→53 tok/s, c4 84.7→103, 256K prefill 297→628 and startup 113→43 seconds, plus results on B70, RTX 3090 and H200. Those are previous tuning campaigns, not an evaluation showing this generic skill independently produces those gains. [S1]

A meaningful supporting trail exists. Public local-ai-registry PR #453 is merged; its pinned merge tree contains a hill-climb archive and qualification evidence. The inspected hill-climb README labels 53 tok/s a median of eight runs and explicitly labels the 256K figures single cold runs. Its INT8 prefill, attention, chunking and kernel changes are a bundle, not one isolated cause. The inspected lab-run.json records all six gate booleans, a launch hash, 41.0 tok/s and 667 prefill. Its prefill denominator is the whole context request, not exactly the generic harness's TTFT. These differences explain why 41 and 53 are not contradictory or interchangeable. [P1–P3]

The B70 trellis-serve README corroborates the reported 91.2/365.2 prose numbers but also says c16 is KV-bound, with roughly ten of sixteen long-reasoning streams fitting. This does not prove sixteen full-window users. Its INT8 prefill discussion reports an NLL increase, so speed is not free quality equivalence. The recipe archive also documents long cold prefill starving concurrent decoders. [P4]

**Independent arithmetic only:** 53/43.6≈1.216×, 103/84.7≈1.216×, 628/297≈2.114×, and 113→43 seconds is about a 62% startup reduction. The attribution and arithmetic are plausible; performance, quality and cross-hardware transfer were not independently reproduced. The full raw corpus, external engine patches and every RTX/H200 result were not audited.

## Authority, Privacy, Supply Chain and Cost

This is a local client, not an authenticated service; server auth/CORS are the chosen engine's responsibility. The client provides no dedicated bearer-token/header configuration and accepts arbitrary base_url plus arbitrary extra_body overrides, including core request fields. A nonlocal endpoint receives prompts; urllib and subprocesses inherit the invoking environment. There is no egress allowlist, scheme restriction or sandbox. Config launch/stop/probe arrays are executable authority even without shell=True; the supplied stop example explicitly invokes bash -c. Only trusted, reviewed configs should be executed. [S3, S8]

No automatic credential harvesting or telemetry uploader was found. However, installing this as a coding-agent skill authorizes nothing by itself: hardware changes, root/sudo, Docker control, production restarts, downloads and publication need separately scoped operator consent. PROMPT.md suggests a mode-600 credential file; that is plaintext storage, not a managed vault, expiry or least-privilege policy. A broadly writable privileged probe would be dangerous; do not grant unrestricted sudo merely to satisfy the example. [S2, S4]

Generated benchmark prompts are synthetic, but an optimizing agent can send inspected configs, source and logs to its own model provider. Endpoint hosting and the agent provider determine disclosure/retention, not the word local. Errors can persist endpoint details in ledger/logs; configs and manually recorded launch environments can contain secrets. Gitignore excludes ledger and run logs only when those rules apply to the actual experiment directory. No encryption, retention TTL, sanitization or automatic secret scanning exists; publishing.md's grep step is manual. [S3, S7]

The stdlib client requires no paid provider, but repeated long prompts, concurrent 512-token generations, engine compilation and hardware rental/energy can be expensive. Hosted compatible endpoints may bill every trial; the optimizing agent can incur separate model charges. Requests allow very long timeouts, and the keep-going instruction has no enforced token/dollar/GPU-time ceiling. There is no automatic budget, rate-limit backoff or spend meter. All such execution was excluded from this review.

## Maturity and Licensing

Anonymous GitHub metadata on 2026-11-26 reported 2,796 stars, 255 forks, 26 open issue/PR items and last push 2026-11-16T18:40:08Z. Releases and tags were empty. The 17-file main snapshot has no CI workflow, automated tests, package manifest or dependency lockfile. Public proposed changes address ceilings, queue portability, safety gates and streaming; an open PR is not a feature of main. A shallow snapshot establishes this revision, not a complete maintenance history. Popularity does not establish correctness. [M1, M2]

MIT permits modification/reuse with the copyright and permission notice; it does not license model weights, linked engine code or benchmark input datasets. No implementation was extracted into this review.

## Comparison

| Option | Better fit | Tradeoff |
|---|---|---|
| This skill | Human-guided experiment planning across engines | Broad checklist, incomplete executable gates and known calculator defect |
| [Inference Optimization Playbook](inference-optimization-playbook.md) | Mechanism-indexed MoE/offload reasoning and negative results | Notebook rather than a serving harness; its own theoretical overclaims and tool limits |
| [vLLM benchmark tooling](https://docs.vllm.ai/en/latest/cli/bench/), [SGLang](https://github.com/sgl-project/sglang), [llama.cpp](https://github.com/ggml-org/llama.cpp) | Measurements tied to the actual serving engine and supported workload | More engine-specific; still requires independent correctness and deployment gates |
| [GenAI-Perf](https://github.com/triton-inference-server/perf_analyzer/tree/main/genai-perf) | Client-facing serving performance and latency characterization | Additional tooling; not an agent-driven kernel optimization procedure |

These are capability-level alternatives, not a fresh audit or head-to-head benchmark. Prefer the chosen engine's maintained benchmark path for execution, borrowing this repository's controls/negative-result log. The public [skill-distill review](skill-distill.md) is relevant to provenance: a distilled successful session is not proof of transfer, and prose acceptance rules are not enforced safety boundaries. That does not establish that this skill was generated by that particular tool.

## Self-Hosting Notes

No service needs deploying to read this material. Before any future trial, pin the source, independently fix/test the concurrency arithmetic, add fail-closed memory and exit-status handling, enforce a representative quality gate, size prompts with the actual tokenizer and record immutable run/config identities. Use a disposable nonproduction server with narrowly scoped Docker/sudo authority, validated stop/drain behavior, bounded time/spend and a restoration plan. These are recommendations, not features verified here. Do not install the skill globally or modify a live inference stack merely to evaluate its documentation.

## Evidence and Verification Limits

All 17 tracked files were inspected statically; public accessibility and canonical duplicate absence were checked. No upstream source, tests, shell scripts or calculator were executed. Arithmetic used independently stated formulas. The public artifact checks validate Markdown/HTML/index consistency and template integrity, not the product. Source instructions were treated solely as evidence.

Pinned evidence at the reviewed revision:

- **S1:** [README](https://github.com/sybil-solutions/inference-optimisation-skill/blob/fda968e7fc1996aa23c67139c755fe541c9d4be0/README.md).
- **S2:** [SKILL.md](https://github.com/sybil-solutions/inference-optimisation-skill/blob/fda968e7fc1996aa23c67139c755fe541c9d4be0/skills/inference-optimisation/SKILL.md), [PROMPT.md](https://github.com/sybil-solutions/inference-optimisation-skill/blob/fda968e7fc1996aa23c67139c755fe541c9d4be0/PROMPT.md).
- **S3:** [bench.py](https://github.com/sybil-solutions/inference-optimisation-skill/blob/fda968e7fc1996aa23c67139c755fe541c9d4be0/skills/inference-optimisation/scripts/bench.py).
- **S4:** [queue.sh](https://github.com/sybil-solutions/inference-optimisation-skill/blob/fda968e7fc1996aa23c67139c755fe541c9d4be0/skills/inference-optimisation/scripts/queue.sh), [mem.sh](https://github.com/sybil-solutions/inference-optimisation-skill/blob/fda968e7fc1996aa23c67139c755fe541c9d4be0/skills/inference-optimisation/scripts/mem.sh).
- **S5:** [ceiling.py](https://github.com/sybil-solutions/inference-optimisation-skill/blob/fda968e7fc1996aa23c67139c755fe541c9d4be0/skills/inference-optimisation/scripts/ceiling.py).
- **S6:** [ceilings](https://github.com/sybil-solutions/inference-optimisation-skill/blob/fda968e7fc1996aa23c67139c755fe541c9d4be0/skills/inference-optimisation/references/ceilings.md), [methodology](https://github.com/sybil-solutions/inference-optimisation-skill/blob/fda968e7fc1996aa23c67139c755fe541c9d4be0/skills/inference-optimisation/references/methodology.md), [levers](https://github.com/sybil-solutions/inference-optimisation-skill/blob/fda968e7fc1996aa23c67139c755fe541c9d4be0/skills/inference-optimisation/references/levers.md), [gotchas](https://github.com/sybil-solutions/inference-optimisation-skill/blob/fda968e7fc1996aa23c67139c755fe541c9d4be0/skills/inference-optimisation/references/gotchas.md).
- **S7:** [Publishing protocol](https://github.com/sybil-solutions/inference-optimisation-skill/blob/fda968e7fc1996aa23c67139c755fe541c9d4be0/skills/inference-optimisation/references/publishing.md).
- **S8:** [Examples](https://github.com/sybil-solutions/inference-optimisation-skill/tree/fda968e7fc1996aa23c67139c755fe541c9d4be0/skills/inference-optimisation/examples), [LICENSE](https://github.com/sybil-solutions/inference-optimisation-skill/blob/fda968e7fc1996aa23c67139c755fe541c9d4be0/LICENSE), [.gitignore](https://github.com/sybil-solutions/inference-optimisation-skill/blob/fda968e7fc1996aa23c67139c755fe541c9d4be0/.gitignore).
- **M1:** [Metadata](https://api.github.com/repos/sybil-solutions/inference-optimisation-skill), [releases](https://api.github.com/repos/sybil-solutions/inference-optimisation-skill/releases), [tags](https://api.github.com/repos/sybil-solutions/inference-optimisation-skill/tags), observed 2026-11-26.
- **M2:** [Open issues and proposals](https://github.com/sybil-solutions/inference-optimisation-skill/issues), including [#1](https://github.com/sybil-solutions/inference-optimisation-skill/issues/1), [#4](https://github.com/sybil-solutions/inference-optimisation-skill/pull/4), [#9](https://github.com/sybil-solutions/inference-optimisation-skill/pull/9); titles/status checked, proposals not adopted.
- **P1:** [Registry PR #453](https://github.com/sybil-solutions/local-ai-registry/pull/453), merged as 7ef2a3b7c0460692da8aa8fa2253ebbcee237e4a.
- **P2:** [Pinned hill-climb summary](https://github.com/sybil-solutions/local-ai-registry/blob/7ef2a3b7c0460692da8aa8fa2253ebbcee237e4a/data/sources/ornith-b390-exl3/hillclimb-2026-11-16/README.md).
- **P3:** [Pinned lab-run evidence](https://github.com/sybil-solutions/local-ai-registry/blob/7ef2a3b7c0460692da8aa8fa2253ebbcee237e4a/data/sources/ornith-b390-exl3/evidence/lab-run.json); evidence directories listed, not exhaustively audited.
- **P4:** [trellis-serve XPU README](https://github.com/sybil-solutions/trellis-serve/blob/main/xpu/README.md), moving main retrieved 2026-11-26; selected results/methodology inspected only.

---

**Attribution:** Sybil Solutions contributors, MIT. Performance and quality figures are author reports unless explicitly marked as independent arithmetic; this review does not certify the linked engines or hardware configurations.
