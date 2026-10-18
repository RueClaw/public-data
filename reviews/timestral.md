# Timestral (mistralai/timestral)

**Repo:** https://github.com/mistralai/timestral
**License:** Apache-2.0 code; separately licensed, revenue-restricted Modified MIT weights (not ordinary MIT).
**Reviewed:** 2026-10-18 (UTC)
**Revision:** a534bdbd244d64f3d9d743f46c7bf6fc330ed4ff; entire inference package, tests, manifests, README and contribution policy. Source commit dated 2026-10-15.
**Model metadata:** Timestral-209M Hub revision 9874d252ab0aae16f7f7c999f98f98d6ad7d8365; config and license inspected, weights not downloaded.
**Verification:** Static review only. No source execution, installation, model downloads, inference, benchmarks or tests run. Public documentation and metadata retrieved 2026-10-18.
**Stack:** Python ≥3.10, PyTorch ≥2.4, NumPy, safetensors, huggingface_hub.
**What it is:** Mistral AI's standalone local inference library for a family of probabilistic time-series foundation models, not an LLM wrapper, training framework or monitoring service.

---

## Verdict

⚠️ **Interesting — a strong forecasting evaluation candidate, not yet a verified production recommendation.** The compact implementation exposes real multivariate conditioning, known-future covariates and ordered quantiles, with useful CPU-sized checkpoints. Benchmark leadership remains publisher-reported, training-data exclusion is not auditable from this release, and the weights' actual license has a material revenue gate that the name “Modified MIT” understates.

## What It Is

Timestral forecasts numeric arrays for demand, telemetry and other regularly aligned time-series workloads without per-dataset training. Four advertised sizes span 5M, 28M, 123M and 209M parameters. Inputs are series × variates × time, with optional numeric and categorical covariates; outputs are 21 quantiles per target and forecast step. It accepts up to 32,768 context steps by default and rolls beyond a 1,024-step decode block using predicted medians. [README](https://github.com/mistralai/timestral/blob/a534bdbd244d64f3d9d743f46c7bf6fc330ed4ff/README.md)

The repository contains inference and small synthetic tests. It does not contain the training pipeline, synthetic-data generator, training corpus, benchmark runner or a complete anomaly-detection application. The launch article's industrial agent workflows and Forge adaptation offering are broader product descriptions, not features implemented here. [Launch article](https://mistral.ai/news/timestral/)

## Stack

| Layer | Technology / boundary |
|---|---|
| Public API | TimestralForecaster.from_pretrained and forecast; Forecast container |
| Network | PyTorch SDPA, RMSNorm, SwiGLU, partial rotary time positions |
| Data preparation | Tensor shape checks, NaN masks, NumPy category encoding |
| Checkpoints | JSON config plus safetensors; Hub cache or local directory |
| Packaging | setuptools, version 1.0.0; uv.lock; pytest dev dependency |
| Serving / storage | None supplied; no HTTP server, database, authentication or CORS layer |

The four direct runtime dependencies have lower bounds rather than strict package constraints; the checked-in lockfile offers a more reproducible environment than the unpinned Git install example. A short dependency list is not a security audit. [Manifest](https://github.com/mistralai/timestral/blob/a534bdbd244d64f3d9d743f46c7bf6fc330ed4ff/pyproject.toml)

## Key Features

### Genuine multivariate and covariate routing

Attention can mix target variates within each series. Target, past-only covariate and known-future covariate roles drive attention masks. Known-future rows have bidirectional context/horizon visibility; covariates cannot read targets, and bidirectional rows cannot read causal rows. These are concrete information-flow safeguards, not proof that a caller's supplied future covariates were actually available at forecast time. [Masks](https://github.com/mistralai/timestral/blob/a534bdbd244d64f3d9d743f46c7bf6fc330ed4ff/src/timestral/masks.py)

### Ordered quantiles, not guaranteed calibrated uncertainty

The head expands upward/downward from a free median through positive softplus increments weighted by quantile spacing. This enforces ordering in the model head. It does not establish empirical interval coverage, a calibrated joint distribution across variables, coherent scenario samples, or decision-risk guarantees. Median feedback between blocks discards trajectory uncertainty; longer horizons need separate coverage checks. [Model](https://github.com/mistralai/timestral/blob/a534bdbd244d64f3d9d743f46c7bf6fc330ed4ff/src/timestral/model.py)

### Defaults matter to accuracy and speed

The forecaster runs both the original and negated inputs and averages reflected quantiles by default. This is two-pass test-time augmentation, even though the launch article describes a single checkpoint “without ensembling.” It also clips forecasts to zero when the observed context is entirely nonnegative, caps extreme quantiles relative to context statistics and replaces extreme feedback medians. Disable or evaluate these heuristics explicitly for signed targets and regime changes; do not equate one checkpoint with one network pass. [Forecaster](https://github.com/mistralai/timestral/blob/a534bdbd244d64f3d9d743f46c7bf6fc330ed4ff/src/timestral/forecaster.py)

### Categorical support has a multivariate caveat

Univariate targets get smoothed target-mean encoding against the forward-filled context, with unseen categories mapped to the series mean. Multivariate targets instead receive raw numeric category codes. Thus category relabeling can matter for multivariate inputs; this is not universal category-order invariance. Refit encodings inside each rolling-origin cutoff, never on held-out target values. [Encoding](https://github.com/mistralai/timestral/blob/a534bdbd244d64f3d9d743f46c7bf6fc330ed4ff/src/timestral/covariate_encoding.py), [forecaster](https://github.com/mistralai/timestral/blob/a534bdbd244d64f3d9d743f46c7bf6fc330ed4ff/src/timestral/forecaster.py)

## Architecture

1. The loader resolves a local directory or downloads only config.json and model.safetensors, constructs the configured network, loads its state strictly, and defaults to CPU float32.
2. The forecaster validates array shapes, creates observation masks, prepares covariates, forward-fills target values while retaining masks, truncates context and pads to patches.
3. Patch embeddings combine values and missing indicators. Causal patch statistics and optional asinh scaling stabilize numeric ranges; known-future covariates deliberately use whole-row statistics because their horizon is available.
4. Decoupled Horizon Forecasting separates observed encoder patches from learned prediction-query tokens. Time and variate attention use role-aware masks, gated SDPA and residual MLPs. The 209M config specifies 24 blocks, width 768, 12 heads, patch size 32 and time-plus-variate attention every fourth block.
5. Quantile outputs are denormalized and refined into advancing frames using prior predicted medians. Longer horizons rerun blocks with median feedback and a rolling context.

Sources: [config](https://huggingface.co/mistralai/Timestral-209M/blob/9874d252ab0aae16f7f7c999f98f98d6ad7d8365/config.json), [layers](https://github.com/mistralai/timestral/blob/a534bdbd244d64f3d9d743f46c7bf6fc330ed4ff/src/timestral/layers.py), [model](https://github.com/mistralai/timestral/blob/a534bdbd244d64f3d9d743f46c7bf6fc330ed4ff/src/timestral/model.py), [scaler](https://github.com/mistralai/timestral/blob/a534bdbd244d64f3d9d743f46c7bf6fc330ed4ff/src/timestral/scaler.py), [loading](https://github.com/mistralai/timestral/blob/a534bdbd244d64f3d9d743f46c7bf6fc330ed4ff/src/timestral/loading.py).

A scalability caveat is visible in the implementation: rows from the whole batch are packed together, and variate attention builds dense row-by-row masks, even though cross-series attention is forbidden. Memory can therefore grow quadratically in total packed rows, not just variates in one series. Time masks also grow quadratically in patch sequence length. Microbatching and bounding covariate count are important; parameter count alone does not describe runtime cost.

## Benchmark Evidence and Leakage Boundaries

The following are **publisher-reported model-card results, not reproduced measurements**:

| Benchmark | Timestral-209M | Closest listed comparison |
|---|---|---|
| GIFT-Eval | MASE 0.658; CRPS 0.446 | t0-gamma: 0.661; 0.452 |
| TIME | MASE 0.626; CRPS 0.522 | t0-gamma: 0.637; 0.534 |
| fev-bench | SQL skill 50.39; MASE skill 39.49 | t0-gamma: 49.42; 37.99 |

The [model card](https://huggingface.co/mistralai/Timestral-209M/blob/9874d252ab0aae16f7f7c999f98f98d6ad7d8365/README.md) also compares TimesFM-3, Toto-2.0-2.5B and Chronos-2. Lower is better for the first two benchmarks; higher is better for the reported skill scores. These are different metrics/aggregations, not directly interchangeable scores. The launch article says results were submitted to GIFT-Eval and TIME; this review did not independently audit leaderboard runs or establish the current ranking.

The README specifies 97 GIFT-Eval configurations using past dynamic-real covariates, 100 fev-bench tasks using past/known covariates and target encoding, and 98 TIME tasks without covariates. It uses forecaster defaults and full history capped at 32,768 steps. That is useful protocol disclosure, but there are no bundled benchmark adapters, per-task predictions, rerun scripts, confidence intervals or matched hardware traces in this checkout. Context length, covariate access, test-time augmentation and preprocessing must be matched before interpreting small aggregate margins as model superiority. The card's GIFT MASE advantage over t0-gamma is only 0.003.

The [launch article](https://mistral.ai/news/timestral/) describes synthetic-only pretraining at 8,192 context, followed by mixed real/synthetic post-training at four times that context, with pinball loss over 21 quantiles. A technical report is still promised. The inspected material does not provide the real-data inventory, per-dataset cutoffs or test-window exclusion audit needed to independently verify contamination-free zero-shot evaluation. [Issue #3](https://github.com/mistralai/timestral/issues/3) asks those questions and had no comments at review time. **This is an evidence gap, not a finding that leakage occurred.**

Architecture-level causality and corpus-level contamination are different questions. Known-future weather should mean an archived forecast available at the origin, not realized future weather; revised business data and target encoding can leak even with correct attention masks. Require rolling-origin evaluation with as-of covariates, seasonal-naive and local statistical baselines, matched foundation-model baselines, interval coverage by horizon/subgroup, and latency/peak-memory measurements before adoption.

## Licenses and Reuse

- **Code:** [Apache-2.0](https://github.com/mistralai/timestral/blob/a534bdbd244d64f3d9d743f46c7bf6fc330ed4ff/LICENSE), covering the package and tests. Commercial reuse is allowed subject to applicable license/notice and modification requirements; the code license does not grant rights to separately distributed weights or datasets.
- **Weights:** the actual [209M Modified MIT license](https://huggingface.co/mistralai/Timestral-209M/blob/9874d252ab0aae16f7f7c999f98f98d6ad7d8365/LICENSE) preserves attribution and permission notices, but denies exercise of license rights when the company's **or employer's global consolidated revenue exceeds US$20 million in the preceding month**. It explicitly extends the restriction to derivatives, modifications and combined works. A separate commercial license may be requested at the publisher's discretion. This is not ordinary MIT and should not be represented as unrestricted open-source weights. The README links separate licenses for all four checkpoints; only the 209M license was independently inspected here.
- **Training/evaluation data:** no training corpus or dataset license grant is bundled. “Synthetic-first” does not establish rights for the real-data portion. Evaluation datasets and downstream inputs retain their own terms. Model-card usage language also warns against third-party-rights violations.

## Security and Privacy

The inspected inference path runs tensors locally, with no apparent forecast-upload or telemetry call. The network boundary is checkpoint acquisition through huggingface_hub; offline use is supported after provisioning. Pin both source SHA and Hub revision, use a vetted local checkpoint or local_files_only/HF_HUB_OFFLINE, and set token=False when anonymous downloading is intended rather than inheriting cached Hub authentication.

Safetensors avoids the usual Python-pickle checkpoint execution path; no trust_remote_code or dynamic Hub Python import is required. Strict state loading and rejection of unknown config keys help detect incompatibility. They do not make arbitrary files safe: JSON dimensions can trigger large allocations, several validations use assertions removable with optimized Python, and PyTorch/native dependencies remain part of the trust boundary. Do not allow untrusted callers to choose model paths, revisions or unbounded tensor sizes. Cap request dimensions/horizons, validate finite numeric inputs, isolate workers and keep dependencies patched. [Loader](https://github.com/mistralai/timestral/blob/a534bdbd244d64f3d9d743f46c7bf6fc330ed4ff/src/timestral/loading.py), [configuration](https://github.com/mistralai/timestral/blob/a534bdbd244d64f3d9d743f46c7bf6fc330ed4ff/src/timestral/config.py)

There is no hosted service to audit for auth or CORS here. Any serving wrapper must supply authentication, quotas, request isolation, data-retention rules and secure checkpoint/cache permissions. Bug reports should use synthetic/redacted inputs rather than private telemetry. No exploit testing or dependency vulnerability scan was performed.

## Tests, CI and Maturity

The single 102-line test module has four test functions, one parametrized over three cases: shapes/finite and ordered outputs, reflected-forecast symmetry with covariates, category-encoding equivalence, and local/mocked-Hub loading. These use tiny random-weight models, not released checkpoints. There are no explicit tests here for causal leakage, batch isolation, future-covariate availability, calibration, hardware parity or benchmark reproduction. No tracked GitHub Actions workflow was found. **Tests were inspected, not run.** [Tests](https://github.com/mistralai/timestral/blob/a534bdbd244d64f3d9d743f46c7bf6fc330ed4ff/tests/test_forecaster.py)

Public metadata on 2026-10-18 showed 332 stars, 24 forks, four open issues, last push 2026-10-15, and no GitHub releases; the package says 1.0.0. These are a young release's metadata, not production validation. [Repository metadata](https://api.github.com/repos/mistralai/timestral), [releases](https://api.github.com/repos/mistralai/timestral/releases). The shallow checkout establishes the reviewed snapshot, not a full historical maintenance audit.

The [contribution policy](https://github.com/mistralai/timestral/blob/a534bdbd244d64f3d9d743f46c7bf6fc330ed4ff/CONTRIBUTING.md) declines pull requests, offers best-effort issue responses and commits to fixing major bugs/security vulnerabilities. That gives a clear owner but limits community repair throughput. [Issue #4](https://github.com/mistralai/timestral/issues/4) raises MPS support; the code's float64 statistics are an additional reason not to assume “GPU” implies Apple MPS compatibility.

## Comparison

| Option | Why compare | Tradeoff / evidence boundary |
|---|---|---|
| Timestral | Compact joint multivariate inference with role-aware covariates | Revenue-gated weights; young inference-only release |
| Chronos-2 / TimesFM-3 / Toto | Foundation-model baselines listed in publisher comparisons | Rerun with matched context, covariates, augmentation and hardware; no independent winner established here |
| Seasonal naive / StatsForecast ARIMA or ETS | Cheap, understandable local baselines | May miss cross-series nonlinear structure; often strong on stable seasonal series |
| AutoGluon TimeSeries / fev | Broader forecasting workflow or evaluation harness | More orchestration/dependencies; better fit when backtesting and model selection are the main missing pieces |

Alternatives: [Chronos](https://github.com/amazon-science/chronos-forecasting), [TimesFM](https://github.com/google-research/timesfm), [Toto](https://github.com/DataDog/toto), [StatsForecast](https://github.com/Nixtla/statsforecast), [AutoGluon](https://github.com/autogluon/autogluon), [fev](https://github.com/autogluon/fev). Their current releases/licenses were not audited in this review.

## Self-Hosting Notes

No paid API is necessary for the inference library. Start with a license-eligible, pinned small checkpoint in an isolated environment. CPU float32 is the default and the loader says inference was validated in float32; reduced precision should be tested rather than assumed equivalent. The README lists fp32 weight files of 21, 111, 490 and 837 MB, which are **not** peak RAM/VRAM estimates. Model construction, checkpoint loading, masks, activations and outputs add overhead; GPU loading also stages on CPU.

The publisher reports 10 ms for 5M and 140 ms for 209M on an eight-thread server CPU for one day ahead from three weeks of 15-minute history. This is a specific workload claim, not measured here or a guarantee for 32K contexts, many variates or large batches. There is no validated minimum RAM/VRAM or universal throughput figure in this review. Long horizons recompute blocks, and symmetric averaging adds a second forecast pass.

Production gating should include frozen artifacts and provenance, leakage-safe backtests, domain-specific calibration, category-relabeling checks for multivariate inputs, memory/latency profiling, drift monitoring and a fallback forecast. Nothing was deployed or executed for this review.

---

**Attribution:** Mistral AI, [mistralai/timestral](https://github.com/mistralai/timestral), Apache-2.0 code; separately licensed Timestral-209M metadata and weights. This review contains independent analysis, not redistributed model weights or training data.
