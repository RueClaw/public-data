# Laya (NandhaKishorM/laya)

**Repo:** https://github.com/NandhaKishorM/laya
**Author:** Convai Innovations / NandhaKishorM
**License:** Apache-2.0 source; preserve license/notices and mark modifications. Reader weights, dependencies and hosted services have separate terms.
**Reviewed:** 2026-11-21 (UTC)
**Revision:** e150aa92a0d4059ac621875b39b620847cf1b88a, v0.5.2; release published 2026-11-21T19:24:04Z.
**Scope:** Python engine dispatch, classic inference/routing, Vega adapter, learning facade, policy persistence, HTTP/MCP transports, media decoding, manifests, selected tests and CI. Not an audit of the separately resolved vegaml implementation, every SDK, or model weights.
**Verification:** Static public-source review; no source code/tests, inference, training, installs, model downloads, paid calls or live service probes executed.
**Stack:** Python 3.10+, PyTorch, Transformers, safetensors, Hugging Face Hub, NumPy, vegaml>=0.18.0, cryptography; optional FastAPI/Uvicorn, MCP, ONNX, media libraries and ffmpeg.
**What it is:** A typed-decision library for classification, routing and triage. Version 0.5 defaults the basic Agent to a frozen-reader Vega engine, while retaining classic non-autoregressive encoder checkpoints and adding a facade for continuous learning and teacher escalation.

## Verdict

⚠️ **Interesting — a bounded classification pilot, not an authorization or security gate.** The useful idea is typed predictions with explicit review routing, fitted heads and recoverable learning state. The new default materially changes model, dependency, resource and privacy assumptions; teacher agreement and calibrated routing are not independent correctness guarantees. Pin the actual engine and assets, evaluate on your own held-out data, and keep consequential execution under deterministic host policy.

## Update Notes

The previous review covered v0.4.11 at d74e8be46ef5241e4ba2b16cd25e896f24f71373 on 2026-10-18. This refresh reuses the canonical review rather than creating another entry. Material changes include the Vega default, multimodal/long-input routing, mandatory vegaml and cryptography dependencies, signed policy loading, continuous-learning/teacher facades, additional HTTP hardening and expanded tests. The prior encoder-only description and benchmark framing no longer describe the whole product. Rating remains Interesting. [S1], [S2], [S3], [S4], [S5], [S6], [S7], [S8]

## What It Is

Applications supply state and typed questions: choice among supplied labels, ordinal score, or yes/no (noul). Classic models encode a state/question row and score option markers without generating prose. The new Vega path instead delegates to a frozen reader plus a small decision engine, exposing conformal prediction sets, abstention, off-distribution signals and fitted heads. Neither output format nor a field named route grants permission to act. [S1], [S2], [S3], [S4]

This is not a desktop controller or a general autonomous agent. Its tool selector maps a classified choice back to caller-supplied tool metadata/objects; the surrounding application remains responsible for argument validation, authorization, execution and compensation. Hooks are trusted in-process callbacks, not sandboxed plugins. [S9]

## Stack

| Layer | Implementation and boundary |
|---|---|
| Default Agent | VegaAgent delegates loading/inference to separately installed vegaml |
| Classic inference | ModernBERT/mmBERT-family encoder, typed decision head, local tensors |
| Router | Explicit model/task overrides; Vega lane for media, fitted questions or long text; classic language/workflow routing otherwise |
| Learning | Learner, Escalator and vllm_teacher are lazy facades over vegaml.learn |
| Policy artifacts | NPZ arrays with pickle disabled, JSON, SHA-256 manifest, optional Ed25519 signature |
| Serving | FastAPI/Uvicorn HTTP; MCP local or remote; optional framework adapters |
| Media | Vision/audio dependencies; video invokes local ffmpeg/ffprobe subprocesses |
| Packaging | Broad dependency lower bounds; multi-language clients/runtimes also present |

## Key Features

### The same constructor can now select a different engine

Since 0.5.0, an unnamed Agent/load call normally chooses Vega if vegaml is available. Naming a checkpoint, explicitly setting vegaml=False, or supplying a classic-only option keeps the encoder path. Missing vegaml falls back with a warning. Notably, expected_sha256 is a classic-only dispatch option: adding what looks like a security control can also change the selected engine. Be explicit about backend and test configuration, rather than assuming old performance or digest controls carry over. [S2]

Router is different from bare Agent: it retains classic routing and adds an automatically available Vega lane. Explicit model/task wins; otherwise media, matching fitted heads and estimated text beyond 8,192 tokens can select Vega. The inspected Vega construction branch forwards device/token but not the router's classic revision/digest configuration. Do not assume those settings pin every lane; attach an explicitly configured Vega agent or disable the lane until its assets are controlled. This is a source-level observation, not a reproduced deployment failure. [S3]

### Review routing is useful, not a safety proof

VegaAgent translates schemas and applies calibration itself. Without a fitted band, abstention or a multi-option prediction set requests review; with a band, a fitted precision target drives routing. Changed options and policy novelty can also trigger review. The unbound signal alone no longer routes in this adapter: upstream reports it fired on 71% of ordinary banking77 rows. Escalator's documented rules do include unbound, so these interfaces do not have identical gating semantics. Nominal risk/precision targets depend on calibration and distribution assumptions, not universal guarantees on arbitrary traffic. [S4], [S5]

### Continuous learning introduces a new trust relationship

Laya's learning module is a small forwarding facade, not the learner implementation. Documentation says feedback refits a head every 50 confirmed answers, holds strongly disagreeing batches, supports accept/discard/undo and state following, and escalates uncertain answers plus a 5% audit sample to a teacher. Teacher agreement cannot detect a consistently wrong teacher. Documentation also says failed/unusable teacher responses fall back to the learner's answer: a host needing fail-closed behavior must check the result and enforce that policy separately. Dependency internals, crash safety and these guarantees were not independently verified here. [S5]

### Multimodal is not joint video understanding

The video adapter selects speech transcription when meaningful speech exists; otherwise it samples frames into a contact sheet for vision. It does not establish that spoken and visual evidence were jointly evaluated. The source marks image-path results uncalibrated. Video decoding invokes subprocesses with argument lists rather than a shell, but its common subprocess helper has no timeout and captures output in memory. Treat uploaded media as an untrusted codec/resource workload and isolate it with size, duration, memory and time limits. Raw-byte videos are written to temporary files. [S10]

## Architecture

1. Select an engine explicitly or via dispatch/routing. Classic and Vega paths have different context, confidence, model and persistence behavior.
2. Normalize state/questions and build bounded model inputs. Classic questions form separate rows; more questions, scanning and tournaments are not free single-pass work.
3. Run the chosen model and decode typed answers. Classic score is expected ordinal index, not an arbitrary percentage probability.
4. Apply calibration, abstention/review controls and trusted hooks. The host decides whether and how to act.
5. Optionally collect feedback or call a teacher, changing future fitted-head behavior; persist the resulting model/calibration state with provenance.

The pattern worth studying is separation of output shape, probabilistic decision, learned policy artifact and host execution. The operational burden is keeping those contracts aligned across two engines, multiple readers, calibration versions and serving adapters. [S2], [S3], [S4], [S5], [S9]

## Security, Permissions, Credentials and Egress

- **HTTP remains opt-in auth.** Bare laya-serve binds 0.0.0.0:8000 and accepts requests without a key unless LAYA_API_KEY is set. With a key, byte-wise constant-time bearer comparison is used; unauthenticated health is liveness-only and interactive API docs are disabled. This is shared-key authentication, not per-user authorization or tenant isolation. No CORS middleware was found in the reviewed serve module; that is not access control. [S6]
- **Resource defenses improved, but do not bound total inference time.** Limits include 2 MiB body, 50,000 state characters, 64 questions, 64 batch states, default 16 admitted concurrent requests, option/token budgets and a 10-second body-read timeout. Batch chunking limits a forward pass, not total time occupying inference. The code still documents a 512-token default width estimate undercounting classic multilingual width by 2×. Add gateway rate limits and measured deadlines. [S6]
- **Local is a deployment choice.** Classic loaders fetch Hugging Face assets and can use an explicit token or HF_TOKEN. Vega loading crosses into a separately installed dependency. Remote MCP sends supplied state/questions and optional bearer credentials to LAYA_BASE_URL; HTTP as well as HTTPS is accepted. Its request path uses urllib's default opener, whereas the tool-selector remote adapter explicitly rejects cross-origin/downgrade redirects. Do not assume equivalent transport protection across adapters; avoid redirects and require trusted HTTPS endpoints. No live redirect test was run. [S2], [S7], [S9]
- **Teachers see real records.** The local/no-per-call-cost wording for vllm_teacher assumes a model you actually operate locally. The facade forwards arguments; it does not enforce a network-isolation boundary. Teacher callbacks, hosted Studio workflows, remote inference, hooks and logging need separate data authorization. No Studio account/service or dependency telemetry behavior was audited. [S5]
- **No classifier output authorizes execution.** Request bodies cannot supply callable hooks to the HTTP service. Application-installed callbacks and media subprocesses run with process authority; there is no general OS sandbox. Keep permissions minimal and require independent checks for destructive actions. [S6], [S9], [S10]

## Persistence, Integrity and Recovery

Classic models use disk caches with optional revision pins and digest maps. The security guide explicitly says unlisted files are unchecked and its suggested digest map omits mutable tokenizer configuration. Safetensors and the absence of trust_remote_code in inspected classic construction are useful controls, not proof of safe dependencies or every reader. [S2], [S11]

VegaAgent saves heads.npz, calibration JSON and a manifest. Loading can check hashes, recognized Ed25519 signatures and engine identity; NPZ uses allow_pickle=False. However, default verify=True also accepts legacy manifestless artifacts as unverified and unsigned manifests as integrity-only. Only verify="signed" requires a signature. Engine comparison is skipped when either digest is unavailable, reported as not checked. Require the verification state your application actually needs; a signature establishes an accepted signer, not model quality. ZIP members are read without extraction, but the policy reader has no explicit decompressed-size budget. [S4], [S8]

The save method writes multiple files directly into an existing directory, not as an atomic directory transaction. A crash can leave mismatched state, and reusing a directory can retain an older calibration file if the current agent has none. The loader installs heads incrementally before all later calibration parsing finishes. These are static recovery cautions: use fresh versioned directories, validate before switching a serving process, keep backups, and exercise interrupted-save/corrupt-load recovery before deployment. [S4]

Learner workdir version retention, resume, undo, read-only followers and portable bundles are documented but implemented in vegaml. Treat stored examples, labels, features and bundles as potentially sensitive; validate actual retention, encryption, concurrent-writer behavior and rollback in the resolved dependency. No durable job queue or exactly-once external side-effect guarantee is established by these APIs. [S5]

## Supply Chain, License and Costs

The package is Apache-2.0 and declares beta status. Core dependencies now include vegaml>=0.18.0 and cryptography>=41 in addition to broad Torch/Transformers/Hub/NumPy minimums. A Laya source SHA therefore does not identify the full installed engine or weights. Lock the dependency graph, separately pin reader/engine assets, inspect licenses and use controlled artifact provisioning. Selected CI actions are full-SHA pinned; this does not pin arbitrary pip resolution. Other SDKs and their transitive dependencies were not exhaustively reviewed. [S1], [S12]

There is no required Laya API subscription for local use, but compute, storage, downloads, evaluation and operations are real costs. README's 73,728-token context and 0.8B–27B reader claims are not equivalent-cost modes, and its classic 33 ms headline is not a latency guarantee for the new default. Its CPU learning example reports 6.4 GB RAM and 34 seconds for 300 answers; these are author measurements, not a capacity estimate reproduced here. Optional hosted teachers/Studio can introduce separate costs and data terms; no paid service is recommended or priced by this review. [S1], [S5]

## Claims, Maturity and Verification

| Evidence | What it supports / limitation |
|---|---|
| New README learning table | Author reports 84.7% to 96.0% after 120 confirmations across 14 templates/31 questions, using generated initial examples and 60 held-out rows per template; not independent production validation |
| New streaming/reader tables | Reported 4B banking77 and typed-decisions results and a 50,676-record reader comparison; methodology/artifact chain not fully reproduced or audited here |
| Classic BENCHMARKS.md | Explicitly says its Jev figures are third-party/unmatched and the 0.766 headline lacks a committed result file; do not apply that caveat indiscriminately to the newer README comparisons |
| Classic multilingual rerun | Reports 0.4008 macro accuracy and 0.3911 ECE for 51-language/20-option MASSIVE; stronger than random, not universal multilingual reliability |
| Security use | README acknowledges prompt-injection weaknesses; older guardrail limitation reports are not a fresh adversarial test of v0.5.2 |
| Test inventory | 116 files beneath tests, including policy, Vega and router-Vega tests; file count is not passing-test count |
| CI metadata | Exact-SHA ten-run sample included successful CI, Release, Go, Java and C++ runs, while Rust and .NET entries were pending; not all checks certified |

Public unauthenticated GitHub metadata on 2026-11-21 showed 35,776 stars, 3,208 forks, 103 open issue/PR items and last push 2026-11-21T18:11:03Z. Latest release was v0.5.2. These are mutable popularity/activity observations, not assurance. The project remains young (created September 2026) and changed substantially since the October review. [S13]

CI declares Python 3.10–3.13, TypeScript and additional platform/language checks. Selected policy tests use synthetic signing keys without models; Vega adapter tests exist. Real checkpoint evaluation remains a separate scheduled/manual/release workflow whose release trigger is published, not proof of a pre-release gate. We did not execute these tests or download their dependencies. [S12]

**Limits:** Static review only, with exact source/previous-ref comparison and public release/CI metadata. No installed dependency audit, model-card/weight audit, benchmark reproduction, training, inference, adversarial experiment, load test, vulnerability scan, deployment, hardware or desktop access. New learning guarantees are explicitly dependency/documentation claims. This review is not a security certification.

## Comparison

| Alternative | Better fit | Tradeoff |
|---|---|---|
| Rules / conventional classifier | Stable narrow labels and deterministic constraints | Less flexible, easier to audit; establish this baseline first |
| SetFit | Representative labelled examples and a fixed taxonomy | More task-specific fitting, fewer arbitrary-question features |
| TypeSafe Jev | Managed typed decisions without local inference operations | Hosted privacy/cost boundary; confidence semantics and thresholds are not interchangeable |
| Constrained-output generative model | Rich extraction/reasoning | More decoding and validation work, but different task capability |
| Direct vegaml | Specifically adopting the new reader/learner | Avoids mistaking a Laya facade for an independently implemented engine; requires its own review |
| laya-mlx | Apple-Silicon classic-model experimentation | Separate implementation/version/parity burden; not a substitute for verifying the new Vega default |

These are architectural alternatives, not newly measured rankings. References: [SetFit](https://github.com/huggingface/setfit), [TypeSafe](https://typesafe.ai/), [vegaml](https://github.com/NandhaKishorM/vegaml), and the separately scoped [Laya-MLX review](laya-mlx.md). The older [Unsloth integration review](unsloth-decision-api.md) must not be read as verification of current upstream defaults.

## Self-Hosting Notes

For a pilot, explicitly choose classic versus Vega, one pinned model and a frozen evaluation set. Start in shadow mode with recoverable routing decisions; measure error/coverage by label, language, length and distribution shift. Teacher evaluation must include truth labels independent of teacher agreement. Test failure behavior, including missing model assets, teacher outage and corrupt policy state.

Keep service binding private, enable authentication before remote access, terminate TLS and add edge resource limits. Disable unused routing lanes and media paths. Separate asset provisioning from inference and verify offline operation if privacy requires it. Back up versioned policy/calibration/feedback state, validate restores, and retain host-owned approvals for consequential actions. No install or deployment was performed for this review.

## Sources

All source links below pin the reviewed revision; external metadata and alternative projects are separately identified.

[S1]: https://github.com/NandhaKishorM/laya/blob/e150aa92a0d4059ac621875b39b620847cf1b88a/README.md
[S2]: https://github.com/NandhaKishorM/laya/blob/e150aa92a0d4059ac621875b39b620847cf1b88a/laya/agent.py
[S3]: https://github.com/NandhaKishorM/laya/blob/e150aa92a0d4059ac621875b39b620847cf1b88a/laya/router.py
[S4]: https://github.com/NandhaKishorM/laya/blob/e150aa92a0d4059ac621875b39b620847cf1b88a/laya/vega.py
[S5]: https://github.com/NandhaKishorM/laya/blob/e150aa92a0d4059ac621875b39b620847cf1b88a/docs/vegaml.md
[S6]: https://github.com/NandhaKishorM/laya/blob/e150aa92a0d4059ac621875b39b620847cf1b88a/laya/serve.py
[S7]: https://github.com/NandhaKishorM/laya/blob/e150aa92a0d4059ac621875b39b620847cf1b88a/laya/mcp/remote.py
[S8]: https://github.com/NandhaKishorM/laya/blob/e150aa92a0d4059ac621875b39b620847cf1b88a/laya/policy.py
[S9]: https://github.com/NandhaKishorM/laya/blob/e150aa92a0d4059ac621875b39b620847cf1b88a/laya/integrations/tools.py
[S10]: https://github.com/NandhaKishorM/laya/blob/e150aa92a0d4059ac621875b39b620847cf1b88a/laya/video.py
[S11]: https://github.com/NandhaKishorM/laya/blob/e150aa92a0d4059ac621875b39b620847cf1b88a/docs/security.md
[S12]: https://github.com/NandhaKishorM/laya/tree/e150aa92a0d4059ac621875b39b620847cf1b88a/.github/workflows
[S13]: https://api.github.com/repos/NandhaKishorM/laya

- [Learning facade](https://github.com/NandhaKishorM/laya/blob/e150aa92a0d4059ac621875b39b620847cf1b88a/laya/learn.py)
- [Manifest](https://github.com/NandhaKishorM/laya/blob/e150aa92a0d4059ac621875b39b620847cf1b88a/pyproject.toml), [license](https://github.com/NandhaKishorM/laya/blob/e150aa92a0d4059ac621875b39b620847cf1b88a/LICENSE)
- [Classic benchmarks](https://github.com/NandhaKishorM/laya/blob/e150aa92a0d4059ac621875b39b620847cf1b88a/BENCHMARKS.md), [guardrail limits](https://github.com/NandhaKishorM/laya/blob/e150aa92a0d4059ac621875b39b620847cf1b88a/docs/guardrail-limitations.md)
- [Tests](https://github.com/NandhaKishorM/laya/tree/e150aa92a0d4059ac621875b39b620847cf1b88a/tests), [observed CI run](https://github.com/NandhaKishorM/laya/actions/runs/44934087375), [release](https://github.com/NandhaKishorM/laya/releases/tag/v0.5.2)

---

**Attribution:** NandhaKishorM/laya, Convai Innovations, Apache-2.0. Independent analysis of public sources; no source code or model weights redistributed.
