# Introducing Clairic, a new System One class of extraction models

**Source:** https://blog.cloudflare.com/clairic-extraction-model/
**Authors:** Alex Reneau, Michelle Chen and Kevin Flansburg / Cloudflare Blog (byline confirmed through the public author archive).
**Date:** Published 2026-10-19 17:48:26.614 UTC; modified 2026-10-19 18:31:52.038 UTC, per article structured metadata.
**Reviewed:** 2026-10-20 (UTC)
**Retrieved:** 2026-10-20 14:48:40.490 UTC; full server-provided Markdown acquired, including the portion beyond the fetch preview. SHA-256 of the captured fetch text, including its tool provenance wrapper: 018b74222f83e3271587bdf03149adf4925c84da445c95b15d73f6588cd7f1a1.
**Verification:** Static public-document review of the full article, model reference, input schema, conceptual documentation, author archive and service data policy. No paid inference, model download, source execution or independent accuracy/latency benchmark. Documentation agreement is not independent performance validation.
**Topic:** Typed extraction, regression, uncertainty and short-horizon forecasting.
**Availability / license:** Hosted preview; open weights promised, not released in the reviewed sources. No downloadable implementation, weights license or reproducible training/evaluation release linked there. Hosted service terms are not a source-code or weights license.

---

## Verdict

⚠️ **Interesting but verify: a useful extraction interface, not yet a demonstrated general accuracy breakthrough.** Read this for a practical alternative to repeatedly generating JSON with large reasoning models. Trial it on low-risk, measured workloads; do not treat type validity, confidence scores or a small vendor demo as evidence that payments, estimates or forecasts are correct.

## Summary

Cloudflare introduces **Clairic**, served as `@cf/cloudflare/clairic` on Workers AI. It is not Clef, a classifier over enumerated choices, and not a general text-generating assistant. Its advertised single-forward-pass design predicts text spans, typed scalar/list values, bounded estimates and forecast sequences from text and up to four images. “System One” is the authors' product taxonomy, not a disclosed architecture specification or proof of a new general ML capability. Parameter count, backbone, training recipe and detailed prediction-head design are not provided in the reviewed material.

The strongest idea is the output contract: source offsets for extracted text, explicit nullability, confidence, and p10–p90 intervals for predictions. These make routing and auditing easier than parsing free-form prose. Extraction, arithmetic and prediction remain different problems: an invoice identifier may be copied from the source; a total must be computed correctly; repair cost is an uncertain outcome rather than a fact waiting to be extracted.

Evidence consists principally of worked email, receipt and property examples, a 21-day TSA forecasting exercise, and a three-stage customer-support comparison. The headline claims of higher accuracy, lower latency and lower cost are vendor claims, with concrete numbers only for limited demonstrations—not a broad extraction benchmark. The article usefully acknowledges weak multi-step arithmetic, table aggregation, unfamiliar-domain calibration and basic forecasting.

Operationally, this is a hosted preview with a documented $0.10 per million input tokens and no output-token charge. Its near-term value is reducing unnecessary generation in narrow pipelines. Reproducible model evaluation, self-hosting rights and broad accuracy comparisons remain unresolved.

## Key Claims

| Claim | Evidence and assessment |
|---|---|
| Typed answers prevent LLM-like hallucination | Types and spans restrict the answer space, not semantic error. A copied span can be the wrong identifier; computed values can be wrong; estimates can be unsupported. The conceptual docs explicitly say estimates and forecasts still return predictions with little information. |
| Every field is answered in one parallel pass | Architectural claim, not independently inspected. The reference explicitly splits fields into parallel passes; its sample reports three passes. “One pass” is not a guarantee that an entire API request has one forward pass. |
| More accurate than traditional LLMs | No named extraction test suite, aggregate exact-match/F1, sample counts by task, or statistical uncertainty establishing this generalization. The support example reports both GLM pipelines correct in every run. |
| Faster and cheaper | The vendor cascade reports 19.3 seconds versus 61.7 seconds and $6,032 versus $11,740 per million claims. Those imply approximately 69% lower latency and 49% lower cost, but are pipeline-specific extrapolations, not measured million-request results. |
| Calibrated 80% intervals | The TSA illustration reports 17/21 covered outcomes (~81%) and 3.3% average error. Small, correlated daily samples cannot establish general calibration; the error formula is not specified. |
| Unlimited fields cost about the same | No field-count ceiling is documented, but schema tokens, repeated state and parallel passes matter. Unlimited field count is not unlimited context, flat pricing or constant resource consumption. |

## Benchmark and methodology audit

### Extraction and estimation

The article shows one support email, one photographed receipt and a small comparable-property table. There is no released representative corpus, split manifest, annotation policy, missing-field prevalence, OCR breakdown, language coverage, long-document test or numerical tolerance definition. A receipt demonstration does not quantify performance on scans, multi-page forms or ambiguous layouts. The property estimate lacks a realized sale price against which to score it. Its prose also mentions days-on-market intervals absent from the shown request/response, a presentation inconsistency rather than extra evidence.

The support task names GLM-5.3 as the full-pipeline baseline. Gemma 4 and Qwen failures are described without sufficient variants, settings or per-case outputs. Inability to infer a repair price from a sparse email is not itself failed extraction: that price is not present as a fact. A stable repeated estimate demonstrates repeatability on that example, not accuracy against actual repair invoices.

There are no comparisons with schema-constrained non-reasoning generation, specialized span extractors, OCR plus deterministic parsers, or direct arithmetic after extraction. The implication that LLM outputs necessarily lack schema guarantees overlooks constrained-output approaches. Such approaches do not guarantee truth either; their omission makes a categorical superiority argument too broad.

### Pipeline speed and cost

The cascade uses Clairic → Clef → GLM-5.3, versus GLM-5.3 at all three stages. Reported extraction is 0.46 versus 16.1 seconds; decision is 0.22 versus 21.9; final writing is 18.6 versus 16.4. Final generation dominates the faster pipeline. Stage times sum to approximately 19.28 and 54.4 seconds; the stated all-LLM end-to-end total is 61.7 seconds. The unexplained 7.3-second gap could reflect overhead or aggregation, but the article does not reconcile it.

The article mentions three repair estimates, but supplies no complete run logs, trial count for each metric, hardware/region, warm-up, concurrency, caching, tokenization/reasoning settings, tail latencies or uncertainty bands. The cost table itemizes input/output charges, which is helpful; it does not establish production throughput, SLA or total operating cost. Compare against one combined extraction/decision call and ordinary policy code as well as the intentionally three-call baseline.

### Forecasting, baselines and leakage

The TSA example describes sequential next-day forecasts using prior observed counts for 21 days, with one shown target of October 14, 2026. Three of four interval misses occur over Columbus Day weekend. That is a useful failure case: recent numeric history need not encode calendar events. The public TSA data link supplies a potential ground-truth source, not a reproducible experiment bundle; this review did not independently reconstruct those daily observations.

No complete dated predictions, model checkpoint, training cutoff, series selection rationale, full scoring script or frozen pre-outcome forecast log is provided. Thus actual prospective forecasting versus retrospective replay cannot be independently established, and training/test contamination cannot be ruled in or out. There is no evidence here that leakage happened. A seasonal-naive same-weekday baseline, simple statistical forecast and a specialist time-series model are missing. Report interval width and proper probabilistic scores as well as coverage; arbitrarily wide intervals can cover well without being useful. Test rolling origins, multiple series, holidays and longer horizons, with time-based splits and leakage controls.

## Strengths

- Concrete typed API with offsets, nulls and uncertainty is easier to integrate and audit than free-form answers.
- Clear separation between extracting facts, predicting unknowns and generating language helps avoid paying for generation everywhere.
- Public schema and pricing allow preliminary integration planning without buying access.
- The preview section explicitly admits arithmetic, calibration and forecasting weaknesses; these caveats are more defensible than the opening comparative claims.

## Deployment, cost, privacy and practical limits

**Integration:** Workers AI binding or authenticated REST, with application-side validation and review gates. The input schema requires `model` and fields, although the blog's binding examples omit the model property; the model reference includes it. Confirm actual binding behavior rather than assuming snippets are interchangeable.

**Context ambiguity:** The model-info table says 65,536 tokens, while both the field description and input schema refer to an 8,192-token pass. The relationship is not explained. The response exposes a truncation flag and pass/token accounting. Confirm effective state limits and fail closed on truncation before trusting long-document results.

**Images and forecasts:** The schema permits four embedded PNG/JPEG/WebP images, 4 MiB each, 8 MiB decoded total and a 16 MiB request body; remote image URLs are not accepted. Forecast horizon is 1–64 steps. This is not documented PDF ingestion. Image-to-span provenance deserves testing rather than assuming offsets reference original image geometry.

**Pricing:** At the listed $0.10/M input tokens, one million requests billed at 1,000 input tokens each would cost $100 for Clairic inference alone—illustrative arithmetic, not a measured workload. Count schemas, image tokens, pass duplication, retries, Workers/Gateway/storage and downstream models. The reference example reports 61 state tokens, 472 schema tokens, 655 total input tokens and three passes, illustrating why source-text length alone is insufficient.

**Privacy:** The Workers AI data policy states no training on Customer Content and zero retention for standard stateless inference after processing/delivery, subject to legal/security exceptions. Stateful services and enabled Gateway/application logging or caching can retain content; operational metadata can also remain. These are provider commitments, not independently audited findings. Hosted processing still sends document content to Cloudflare. Verify contracts, residency needs and logging settings for invoices or sensitive records; no local-only deployment is established by an unreleased weights promise.

**Safety:** Source spans can contain adversarial text, and a typed scalar can authorize the wrong action. Separating the final LLM from the original email reduces exposure but does not prove prompt-injection resistance. Use deterministic policy checks, allowlisted actions, verified identifiers and human approval for consequential operations. Never substitute a returned guess for a null value. The example cascade dereferences values with methods such as toFixed/join without showing null handling; it is a demonstration, not production-safe error handling.

**Availability and rights:** Reviewed model terms describe service access as AS IS/AS AVAILABLE, permit withdrawal, and disclaim guarantees/indemnification. “Open weights soon” is future intent, not present permission to download, redistribute or modify weights. No source or weights license is established. This review summarizes rather than republishes model code or article assets.

## Recommended evaluation before adoption

Build a consented, representative held-out set with exact field labels, difficult negatives, OCR corruption, multilingual text and malicious instructions. Measure per-field correctness, null precision/recall, numerical tolerance, list completeness, confidence reliability and accuracy-versus-abstention. Recompute totals and dates in code. For estimates, require actual outcomes and evaluate bias, coverage and interval sharpness across domains. Compare suitable cheap baselines at matched quality, then record p50/p95 latency, pass/token usage and total successful-document cost. Pin a checkpoint if available and monitor changes to the preview endpoint.

## Gaps & limitations of this review

All performance numbers above originate with Cloudflare; none were independently reproduced. Public documents establish what the provider advertises and documents, not that the service always implements it. The full article body was read, but receipt pixels and graph data were not independently scored. No credentials, paid API calls, model binaries or demo inference were used. Code/weights availability conclusions are scoped to the reviewed primary sources, not an exhaustive registry search. A preview can change after this retrieval.

## Sources

1. [Article and embedded publication metadata](https://blog.cloudflare.com/clairic-extraction-model/).
2. [Public author archive confirming the three-person byline](https://blog.cloudflare.com/author/michelle/).
3. [Clairic model reference, pricing and hosted terms](https://developers.cloudflare.com/workers-ai/models/clairic/).
4. [Raw input schema](https://developers.cloudflare.com/workers-ai/models/clairic/schema-input.json).
5. [Extraction-model concepts and limitations](https://developers.cloudflare.com/workers-ai/concepts/extraction-models/).
6. [Workers AI data usage policy](https://developers.cloudflare.com/workers-ai/platform/data-usage/).
7. [TSA passenger volumes](https://www.tsa.gov/travel/passenger-volumes), linked by the article; underlying observations not independently reconstructed here.

---

**Attribution:** Alex Reneau, Michelle Chen and Kevin Flansburg, Cloudflare Blog. Independent critical analysis of the public article and documentation, not an endorsement or reproduced benchmark.
