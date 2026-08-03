# Time to First Token (patchy631/time-to-first-token)

**Repo:** https://github.com/patchy631/time-to-first-token  
**License:** Apache-2.0 repository license; README content states CC BY 4.0. Permissive reuse with attribution and license preservation.  
**Reviewed:** 2026-08-03  
**Stack:** Markdown, static HTML/CSS/JavaScript, browser localStorage, vLLM, SGLang, GuideLLM, genai-perf, Prometheus, Grafana, Kubernetes/KEDA  
**What it is:** A 10-week, 30-minutes-a-day curriculum for learning LLM inference serving by iteratively building one OpenAI-compatible service, instrumenting it, benchmarking it, and tuning it.

---

## Verdict

📚 **Study this as a practical inference-serving syllabus.** The repo is not an inference framework; it is a carefully sequenced roadmap with a static progress tracker. Its value is the ordering: mental model, deployable service, measurement, load testing, optimization, disaggregation, economics, then publishing a reproducible benchmark.

---

## What It Is

Time to First Token is a learning resource for engineers who understand Python and transformer basics but have not yet operated LLM inference in production. Instead of asking the reader to run disconnected experiments, it centers the whole curriculum on one artifact: an OpenAI-compatible inference service that grows over ten weeks.

The roadmap moves from first-principles performance reasoning into vLLM, SGLang, Prometheus/Grafana, load testing, quantization, speculative decoding, KV eviction, disaggregated serving, Kubernetes autoscaling, and cost-aware routing. The strongest part is that each week has a concrete deliverable, so the reading is supposed to collapse back into a service, a dashboard, a benchmark harness, or a router.

The repo also includes a single-file browser progress tracker and a GitHub issue template. Progress is stored in localStorage, with export/import and sync-link support. That is the right amount of state for a personal curriculum: no account system, no hosted database, no backend maintenance burden.

## Stack

| Layer | Tech |
|-------|------|
| Content | Markdown roadmap, references, benchmark checklist |
| Web tracker | Static `index.html`, CSS, vanilla JavaScript, browser localStorage |
| Serving engines covered | vLLM, SGLang |
| Measurement covered | Prometheus, Grafana, GuideLLM, `vllm bench serve`, genai-perf |
| Optimization topics | PagedAttention, continuous batching, quantization, speculative decoding, KV eviction |
| Operations topics | GPU rental, Kubernetes, vLLM production stack, queue-depth autoscaling with KEDA |
| Economics topics | GPU utilization, cost per million tokens, cost/latency/quality routing |

## Key Features

### One Growing Artifact

The roadmap's core design choice is to avoid "seventeen disconnected experiments." Every session feeds one service: deploy it, instrument it, benchmark it, optimize it, route around it, and publish the result. That makes the curriculum more useful than a list of papers because the reader keeps returning to an operational system.

### Measurement Before Optimization

Instrumentation lands in week 3 and load testing in week 5, before the quantization and speculative-decoding weeks. That sequencing is exactly right. Without TTFT, inter-token latency, queue depth, throughput, and cost per request, most inference optimization work becomes anecdote.

### Benchmark Hygiene Checklist

The "Before you publish a benchmark" section is the most reusable part of the repo. It calls out common benchmark failures: single concurrency points, missing token lengths, mean-only latency reporting, collapsing TTFT and inter-token latency, measuring at saturation, uniform synthetic traffic, tokenizer mismatches, and unpinned versions.

### Minimal Progress Tracking

The static tracker is intentionally boring in a good way. It stores completion state locally, supports export/import, and avoids adding accounts or server storage to a project whose main artifact is a reading/build plan.

## Architecture

There is no backend application architecture to evaluate. The repository has four meaningful files:

- `README.md` carries the full roadmap, reference list, benchmark checklist, and decision points.
- `index.html` implements the interactive static tracker.
- `progress.md` is a GitHub issue template for durable checkbox tracking.
- `LICENSE` contains Apache-2.0, while the README says roadmap content is CC BY 4.0.

The architecture of the curriculum is more important than the code architecture:

```text
performance mental model
  -> vLLM service
  -> metrics dashboard
  -> SGLang comparison
  -> load-test harness
  -> quantization / speculative decoding / KV eviction variants
  -> disaggregated serving and queue-depth autoscaling
  -> cost-aware router
  -> published reproducible benchmark
```

## Comparison

| Aspect | Time to First Token | vLLM Docs | SGLang Docs | LMCache / Dynamo-style repos |
|--------|---------------------|-----------|-------------|------------------------------|
| Purpose | Guided learning plan | Engine documentation | Engine documentation | Infrastructure implementation |
| Artifact | One service plus benchmark writeup | Engine-specific deployment knowledge | Engine-specific deployment knowledge | Production/runtime components |
| Strength | Sequencing and benchmark discipline | Authoritative vLLM details | Prefix-reuse and serving details | Real serving machinery |
| Caveat | No runnable serving code included | Not a full curriculum | Not a full curriculum | Too heavy for first learning pass |

This repo is best treated as a map through the inference-serving ecosystem, not as a replacement for the underlying engine docs or papers.

## Self-Hosting Notes

The tracker is a static HTML file. It can be opened locally or served through GitHub Pages without a backend. The roadmap itself assumes the learner will rent GPUs for selected sessions and will shut them down between runs. A 24GB GPU is enough for the main 7-8B-model exercises; the roadmap calls out exactly two H100-class sessions if the reader wants to reproduce the high-concurrency and disaggregation exercises.

Operationally, the main caution is cost drift. GPU prices, engine versions, docs URLs, and benchmark tools move quickly. The roadmap is useful because of its method, but every command and cost figure still needs to be pinned and revalidated at run time.

---

**Attribution:** patchy631/time-to-first-token, Apache-2.0 repository license; roadmap content marked CC BY 4.0 in README, https://github.com/patchy631/time-to-first-token
