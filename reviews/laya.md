# Laya (NandhaKishorM/laya)

**Repo:** https://github.com/NandhaKishorM/laya
**Author:** Convai Innovations / NandhaKishorM
**License:** Apache-2.0 source; retain license and applicable notices, mark modifications, and check separately distributed checkpoint/dependency terms.
**Reviewed:** 2026-10-18 (UTC)
**Revision:** d74e8be46ef5241e4ba2b16cd25e896f24f71373 (v0.4.11 package; latest commit 2026-10-17). Scope: Python inference, routing, serving, MCP remote transport, model construction, benchmark documentation/results layout, manifests and CI; other language SDKs inspected at manifest/workflow level, not exhaustively audited.
**Verification:** Static source review and unauthenticated public GitHub metadata. No source tests, inference, benchmarks, downloads of weights, training, paid APIs or deployment were run.
**Stack:** Python 3.10+, PyTorch, Transformers, safetensors, Hugging Face Hub, NumPy; optional FastAPI/Uvicorn, MCP, ONNX Runtime and TileLang.
**What it is:** A locally runnable, non-autoregressive decision-model library for classifying text into caller-specified choices, ordinal scores and yes/no probabilities, with checkpoint routing and agent-framework adapters.

## Verdict

⚠️ **Interesting — pilot for bounded classification, not a security authority.** Laya offers a substantive open alternative to using a generative model for every routing or triage decision: typed results, local inference, explicit checkpoint routing, calibration utilities and multiple serving surfaces. But type correctness is not decision correctness, the strongest headline comparisons are not matched independent experiments, and the project's own evidence shows weak moderation and indirect-injection detection. Adopt only after a domain-specific held-out evaluation and calibrated abstention/fallback policy.

## What It Is

Applications supply a state (text, email, ticket or JSON) plus natural-language questions and options. Laya scores those options without generating prose. The three advertised checkpoints are English ModernBERT-large (421M parameters, default 512-token context), multilingual mmBERT-base (322M, default 1,024, configurable to 8,192), and English typed-decisions (421M, default 1,024). These are upstream specifications, not independently measured here. [README](https://github.com/NandhaKishorM/laya/blob/d74e8be46ef5241e4ba2b16cd25e896f24f71373/README.md)

This is a decision component, not a general autonomous-agent runtime or an authorization system. A chosen tool label or action probability does not grant permission to execute that tool. The host still owns validation, authorization, side effects, retries and human escalation. The useful audience is developers with repeated classification workloads and enough labelled examples to measure their actual error costs.

## Stack

| Layer | Technology / role |
|---|---|
| Core inference | PyTorch encoder and typed decision head; NumPy probability decoding |
| Model assets | Hugging Face snapshots, JSON/tokenizer configs, safetensors weights |
| Routing | Python script/language heuristics plus explicit model/task/language overrides |
| Services | FastAPI/Uvicorn Jev-style HTTP API; MCP local or remote transport |
| Optional acceleration | ONNX Runtime, compiler backends and TileLang; hardware-dependent |
| Integrations | LangChain/LangGraph, LlamaIndex, CrewAI, Agno; structured Pydantic decisions |
| Other clients/runtimes | TypeScript local ONNX runtime and separate HTTP SDKs; Rust/Go/Java/.NET trees/workflows |

The Python manifest uses broad lower bounds (for example torch>=2.0 and transformers>=4.48), not a universally reproducible environment. Optional integrations widen compatibility risk; the macOS Intel ONNX extra contains a platform-specific NumPy cap. A production deployment should lock its tested full dependency graph rather than treating the README's current-version installation discussion as the resolver contract. [Manifest](https://github.com/NandhaKishorM/laya/blob/d74e8be46ef5241e4ba2b16cd25e896f24f71373/pyproject.toml), [TypeScript manifest](https://github.com/NandhaKishorM/laya/blob/d74e8be46ef5241e4ba2b16cd25e896f24f71373/laya-ts/package.json)

## Key Features

### Typed decisions without generated JSON

Choice returns a known option key and probabilities; score returns the expected **index** over ordinal levels; noul returns the probability of yes. In particular a score of 0.82 on four levels is not an 82% risk probability. This removes free-form parsing problems, not classification errors. The README's “nothing to hallucinate” wording is too broad if read as a reliability guarantee. [Decoder](https://github.com/NandhaKishorM/laya/blob/d74e8be46ef5241e4ba2b16cd25e896f24f71373/laya/agent.py#L1332-L1408)

### Routing before inference

Routing precedence is explicit model, explicit task, opt-in workflow matching, language override, caller hint, then script/language detection and fallback. Unidentified language defaults to multilingual in the current code. Loading is lazy and the router manages resident checkpoints, eviction and revisions. Routing matters because the English model can be confidently wrong outside English; short or code-switched text still warrants explicit testing or trusted language hints. [Router](https://github.com/NandhaKishorM/laya/blob/d74e8be46ef5241e4ba2b16cd25e896f24f71373/laya/router.py#L1203-L1299)

### Calibration is usable, but fields differ

For choice/score, legacy confidence is normalized entropy; noul confidence is max probability. answer_confidence is the cross-type field intended for calibrated answer gating, with optional fitted binning. The HTTP compatibility layer adds x_jev_confidence unless strict mode is selected. Do not transfer Jev thresholds or treat entropy as empirical accuracy. Fit on a separate calibration set and evaluate coverage/error tradeoffs on held-out traffic. [Decoder](https://github.com/NandhaKishorM/laya/blob/d74e8be46ef5241e4ba2b16cd25e896f24f71373/laya/agent.py#L1332-L1408), [Server](https://github.com/NandhaKishorM/laya/blob/d74e8be46ef5241e4ba2b16cd25e896f24f71373/laya/serve.py), [Calibration](https://github.com/NandhaKishorM/laya/blob/d74e8be46ef5241e4ba2b16cd25e896f24f71373/laya/calibrate.py)

### Long input and large option sets are explicit tradeoffs

Default context limits truncate; multilingual 8,192-token support requires an override and can be missed if an English document routes to the English checkpoint. Long-document scanning and option tournaments add multiple passes, so “single forward pass” does not describe every operation. The benchmark discussion reports a large-label banking77 weakness and advises small option sets. More context or tournament stages are not free accuracy guarantees. [README](https://github.com/NandhaKishorM/laya/blob/d74e8be46ef5241e4ba2b16cd25e896f24f71373/README.md), [Benchmarks](https://github.com/NandhaKishorM/laya/blob/d74e8be46ef5241e4ba2b16cd25e896f24f71373/BENCHMARKS.md), [Agent scanning](https://github.com/NandhaKishorM/laya/blob/d74e8be46ef5241e4ba2b16cd25e896f24f71373/laya/agent.py#L1601)

## Architecture

1. The router chooses a checkpoint using request controls and text heuristics, without model inference for the routing step.
2. The sequence builder combines question instructions/options and state into a bounded sequence per question. Batched questions are rows, not cost-free extra questions over one shared state embedding.
3. A bidirectional encoder produces contextual states; type embeddings and a transformer decision head score option markers. An auxiliary action head is a prediction, not an executor.
4. Temperature-scaled logits become probabilities and typed answers. Hooks can observe/alter pipeline behavior; trusted application code owns those callbacks.
5. HTTP, MCP and framework wrappers expose the same component, while ONNX and other SDKs add compatibility surfaces requiring parity checks.

[Sequence/model construction](https://github.com/NandhaKishorM/laya/blob/d74e8be46ef5241e4ba2b16cd25e896f24f71373/laya/common.py#L157), [DecisionModel](https://github.com/NandhaKishorM/laya/blob/d74e8be46ef5241e4ba2b16cd25e896f24f71373/laya/common.py#L575-L637), [Agent](https://github.com/NandhaKishorM/laya/blob/d74e8be46ef5241e4ba2b16cd25e896f24f71373/laya/agent.py), [Hooks](https://github.com/NandhaKishorM/laya/blob/d74e8be46ef5241e4ba2b16cd25e896f24f71373/laya/hooks.py)

The useful design pattern is separating deterministic output shape, probabilistic content, and host-owned execution. The cost is a substantial compatibility matrix: checkpoint layouts, contexts, precision/backends, calibration formats and SDK versions can disagree even when the API shape matches.

## Claims and Evidence

| Claim / attraction | What the public source supports | Review assessment |
|---|---|---|
| 33 ms, one forward pass | README quotes T4 single-question latency; benchmark page gives 32.8 ms p50 | Hardware/workload-specific author measurement, not cold-start or service p99 |
| 100+ languages | Multilingual checkpoint claim; reported MASSIVE sweep covers 51 languages | Language availability is not uniform task accuracy |
| Strong multilingual decisions | Refreshed 51-language 20-option MASSIVE macro accuracy 0.4008, macro ECE 0.3911 | Useful above random, far from universal high-confidence correctness |
| Fine-tuned typed-decisions accuracy 0.766 | Benchmark page explicitly says no committed result file behind this headline yet | Treat as reported, not independently reproducible from a complete result artifact |
| Better than Jev | Jev numbers are third-party published, not measured in the same harness | Not a controlled head-to-head; prompts and sample sizes differ |
| Guardrails/moderation | Application table reports toxicity accuracy about 0.53; indirect-injection page reports misses and false positives | Not a sole blocking/allowing security layer |

The benchmark documentation is unusually candid: it preserves superseded results, identifies a non-reproducing multilingual run, and distinguishes training-mix applications from held-out tasks. That transparency is a strength, not grounds to relabel historical numbers as current validation. The 0.993 spam/phishing figures come from domains included in the training mix; they do not establish production readiness on a new distribution. [BENCHMARKS](https://github.com/NandhaKishorM/laya/blob/d74e8be46ef5241e4ba2b16cd25e896f24f71373/BENCHMARKS.md), [Result directory](https://github.com/NandhaKishorM/laya/blob/d74e8be46ef5241e4ba2b16cd25e896f24f71373/research/results)

The guardrail limitation page attributes a 53-case synthetic report to issue #781 on older 0.3.21/0.3.22 packages and a pinned model revision. It reports full-rule recall 0.76 and false-positive rate 0.29, with document-shaped attacks slipping through. This is a concrete warning, **not** a fresh test of v0.4.11; no fix was demonstrated by this review. [Limitations](https://github.com/NandhaKishorM/laya/blob/d74e8be46ef5241e4ba2b16cd25e896f24f71373/docs/guardrail-limitations.md)

## Security, Privacy and Trust Boundaries

- **Local inference is possible, not automatic network isolation.** Initial loading fetches public model assets from Hugging Face. The loader passes an explicit token or HF_TOKEN when present. Provision reviewed assets separately and use a verified offline configuration if network isolation matters. The reviewed core path computes on local tensors; that observation is not an exhaustive no-telemetry certification. [Loader](https://github.com/NandhaKishorM/laya/blob/d74e8be46ef5241e4ba2b16cd25e896f24f71373/laya/agent.py#L575-L632)
- **Remote MCP changes the privacy boundary.** LAYA_BASE_URL selects a remote server; RemoteRouter posts the state/questions and optionally a bearer key. HTTP is accepted as well as HTTPS. Use HTTPS for non-local transport and trust the endpoint with the entire supplied text. Hooks and tracing exporters are additional application-controlled disclosure paths. [Remote transport](https://github.com/NandhaKishorM/laya/blob/d74e8be46ef5241e4ba2b16cd25e896f24f71373/laya/mcp/remote.py)
- **HTTP authentication is opt-in.** Bare laya-serve defaults to 0.0.0.0:8000 and no API key. When configured, bearer comparison uses hmac.compare_digest; unauthenticated health exposes only liveness in keyed mode. This is not per-user authorization or tenant isolation. Do not expose a keyless service publicly. No explicit CORS middleware was found in the reviewed serve module; that is not a substitute for authentication. [Server](https://github.com/NandhaKishorM/laya/blob/d74e8be46ef5241e4ba2b16cd25e896f24f71373/laya/serve.py)
- **Resource controls are real but not a latency guarantee.** The server caps body size (2 MiB), state characters (50,000), questions (64), batch states (64), concurrency (16 by default), and token budgets. Batch chunking bounds each forward pass, not the total time a request holds the single inference worker. Its default row-width estimate is 512 tokens and the source documents undercounting multilingual default width by 2x. Add edge rate limits, deadlines and load testing. [Server limits](https://github.com/NandhaKishorM/laya/blob/d74e8be46ef5241e4ba2b16cd25e896f24f71373/laya/serve.py#L105-L164)
- **Weights and configuration are trusted inputs.** The primary load path uses safetensors, verifies configured digests before parsing, and the inspected model construction does not enable trust_remote_code. Those are good boundaries, not blanket protection from malicious assets or native-runtime vulnerabilities. Revision pins and SHA-256 maps are opt-in; unspecified files/checkpoints remain unchecked. The tokenizer-config normalization can rewrite a parsed file, which the recommended digest map intentionally omits. [Security documentation](https://github.com/NandhaKishorM/laya/blob/d74e8be46ef5241e4ba2b16cd25e896f24f71373/docs/security.md), [Model builder](https://github.com/NandhaKishorM/laya/blob/d74e8be46ef5241e4ba2b16cd25e896f24f71373/laya/common.py#L695-L716)
- **Prediction is not execution approval.** HTTP explicitly refuses callable hook controls from request bodies. Installed hooks/framework code still executes with the host process's authority. Treat classifier outputs as untrusted suggestions and retain independent allowlists, argument checks and approvals for consequential tool calls. [Server controls](https://github.com/NandhaKishorM/laya/blob/d74e8be46ef5241e4ba2b16cd25e896f24f71373/laya/serve.py#L166-L198)

## Maturity and Verification

Public GitHub metadata on 2026-10-18 showed creation on 2026-09-18, last push on 2026-10-17, 33,342 stars, 2,993 forks and 85 open issue/PR items (GitHub's combined open_issues_count). Latest release was v0.4.11, published 2026-10-17. This is a roughly one-month-old, rapidly evolving beta despite substantial adoption; popularity is not assurance. [Repository metadata](https://api.github.com/repos/NandhaKishorM/laya), [Release](https://github.com/NandhaKishorM/laya/releases/tag/v0.4.11)

There are 105 files under tests in the inspected tree, not 105 claimed passing tests. CI config includes Python 3.10–3.13, Windows, TypeScript, package checks, weight-free ONNX export tests, SDK packaging/transport tests and dedicated language workflows. Actions are SHA-pinned in the inspected CI workflow. Real checkpoint regression/parity lives in a separate scheduled/release workflow; its release trigger is **published**, so its presence alone is not evidence of a prepublication gate. [CI](https://github.com/NandhaKishorM/laya/blob/d74e8be46ef5241e4ba2b16cd25e896f24f71373/.github/workflows/ci.yml), [Evals workflow](https://github.com/NandhaKishorM/laya/blob/d74e8be46ef5241e4ba2b16cd25e896f24f71373/.github/workflows/evals.yml)

An unauthenticated API sample of the ten latest workflow runs for the exact source SHA reported success for Go, Java, .NET, Rust, Release, Docs, Docker and Security entries (including duplicate language runs). That sample is not a complete all-checks certification and did not establish current benchmark quality. [Example Release run](https://github.com/NandhaKishorM/laya/actions/runs/39051696214)

**Review limits:** No repository code was executed or installed. No weights/model cards were exhaustively audited, no inference/parity/latency or adversarial tests were reproduced, and no dependency vulnerability scan or live deployment audit was performed. Documentation and committed result artifacts are author evidence; workflow statuses are GitHub-reported evidence. The review is not a security certification.

## Comparison

| Option | Better fit | Tradeoff versus Laya |
|---|---|---|
| TypeSafe Jev | Managed typed-decision API | Less local infrastructure, but hosted trust/cost boundary; Laya compatibility does not imply identical probabilities |
| SetFit | A small fixed label taxonomy with representative training examples | More task-specific training, less arbitrary question/schema flexibility; compare on the same held-out data |
| Rules or a conventional supervised classifier | Stable low-complexity categories, strict deterministic constraints | Less flexible language understanding, but easier to reason about and often cheaper |
| Generative LLM with constrained output | Tasks genuinely needing richer reasoning or extraction | More decoding/cost and still needs validation; constrained JSON does not guarantee semantic truth either |
| laya-mlx | Apple-Silicon-specific experimentation | Independent implementation and parity/version burden; see the separately scoped [MLX review](laya-mlx.md) |

These are architectural comparisons, not newly measured performance rankings. Also see the older, separately scoped [Unsloth integration review](unsloth-decision-api.md); it must not be read as verification of current upstream Laya defaults. Reference alternatives: [SetFit](https://github.com/huggingface/setfit), [TypeSafe](https://typesafe.ai/).

## Self-Hosting Notes

Start with one pinned checkpoint and representative shadow traffic, not every optional backend. Match explicit model/language and context budgets to the task. Pre-download assets in a controlled environment, record revision and calibration provenance, lock dependencies, and confirm actual compute device via authenticated health after a checkpoint has loaded. Preloading affects startup latency and RAM; a resident-model cap smaller than the routed set can induce reload churn.

Bind loopback or a private network, enable LAYA_API_KEY before remote access, terminate TLS, and apply request-rate and time limits outside the worker. Keep sensitive state out of hooks/log exporters unless deliberately authorized. Calibrate on separate data, measure false positives/negatives by language and input length, and preserve a deterministic fallback or human review path. Avoid using low guard scores as evidence that embedded instructions are safe.

**Practical decision:** Worth a bounded triage/routing pilot where errors are recoverable and measured. Do not deploy as an autonomous security gate, a universal 100-language classifier, or a drop-in replacement whose confidence thresholds are assumed equivalent to another API.

---

**Attribution:** NandhaKishorM/laya, Convai Innovations, Apache-2.0. This review is independent analysis of public sources; no source code or model weights are redistributed here.
