# Running a Software Factory Efficiently at Uber Scale

**Source:** https://www.uber.com/us/en/blog/efficient-software-factory/
**Author:** Uday Kiran Medisetty, Uber Engineering
**Date:** August 27, 2026
**Reviewed:** 2026-08-28
**Topic:** Agentic software engineering economics, model routing, context optimization, developer productivity infrastructure

---

## Verdict

✅ **Act on this.** This is one of the more concrete public writeups on running agentic coding at large-company scale because it decomposes cost into measurable drivers instead of treating AI spend as a vague procurement problem. The most useful parts are the cost model, model-evaluation discipline, MCP/tool-schema reduction, code-mode batching, prompt-cache TTL tuning, and live session cost visibility.

---

## Summary

Uber frames agentic software development as a "software factory" whose economics have to be engineered like any other production system. The central argument is that rising usage does not have to imply runaway cost if teams track the full cost equation: users, sessions, turns, requests, tokens, and price per token. Adoption and engagement are growth signals; requests, tokens, and model prices are optimization surfaces.

The article gives useful operating numbers. Uber says more than 70% of pull requests are attributed to local or cloud agents, engineers have built more than 3,600 agent skills, and those skills run more than 30,000 times per day. From February to August 2026, weekly active users across agentic offerings grew 7x and weekly agentic requests grew 9.4x, while total AI spend stabilized after April through optimization work. Holding one model fixed from February through July, Uber reports cost per 1,000 model requests fell almost 34% from peak and cost per session fell 52% from the June peak.

The strongest operational idea is measuring unit economics weekly and monthly rather than only tracking total spend. Uber tracks portfolio cost and usage, cost per user, requests per user, cost per 1,000 requests, token mix per request, cost per million tokens, cost per 1,000 sessions, active session-hour cost, prompt-cache hit rate, and model-level cost/request share. For managed agents, it shifts toward outcome-denominated metrics such as cost per merged PR, review, alert, or cleanup, paired with quality signals like revert rate, F1, and MTTR.

The optimization playbook is practical: benchmark models on real work and choose Pareto-efficient defaults; cap context and default reasoning effort; tune prompt-cache TTLs by workload shape; avoid preloading huge MCP tool catalogs; route tools through searchable catalogs or CLI-resolved commands; batch noisy tool loops in code-mode subprocesses; ground agents in an internal context graph; and show live cost counters in the developer harness. The strategic direction is also clear: interactive terminal sessions are harder to control than managed agents with explicit benchmarks, model routing, and outcome metrics.

## Key Claims

- **Agentic software engineering cost can be decomposed and actively optimized.** Evidence is credible for Uber's environment: the article gives concrete measurements, driver categories, and before/after cost trends, though the underlying dashboards and datasets are not public.
- **Model routing should be benchmark-driven, not taste-driven.** The uReview and SWE benchmark examples are strong because they use real PRs and score quality, cost, latency, timeouts, and noise instead of only model preference.
- **Tool schema/context bloat is a major hidden cost.** The article's MCP examples are persuasive: large tool catalogs can add tens of thousands of tokens to initial prompts and get resent repeatedly unless discovery is made dynamic.
- **Code-mode batching can radically reduce tool-loop tokens.** The SQL examples show large savings, especially for wide result sets, because intermediate polling and raw payloads stay outside the model transcript.
- **Managed agents scale better than individual interactive sessions.** This is plausible and well argued: managed environments let platform teams own model defaults, harnesses, evaluations, and spend tiers, while user-local sessions are harder to standardize.

## Strengths

The cost equation is simple enough to operationalize. It separates adoption from waste and gives teams a shared vocabulary for deciding whether to optimize model price, token volume, request loops, or workflow shape.

The article is unusually specific about agent platform plumbing. The sections on MCP gateway routing, tool search, CLI-based tool resolution, code-mode execution, prompt-cache TTLs, context caps, and live spend counters are much more useful than generic "use AI responsibly" guidance.

The benchmark advice is grounded in software-engineering outcomes. The code-review example tracks F1, precision/recall, cost per review, latency, timeouts, and noise, which is the right shape for choosing models in production workflows.

The managed-agent section correctly moves the discussion from "cost per token" to "cost per useful outcome." For real deployments, cost per merged PR, cost per triaged alert, and revert/quality rates matter more than raw request counts.

## Gaps & Limitations

The article is a company blog post, not a reproducible paper. It shares enough numbers to be useful, but not enough raw data, dashboard definitions, or harness details for independent verification.

The approach assumes substantial platform capacity: central gateways, real-work benchmarks, context graphs, cost dashboards, policy tiers, and agent harness ownership. Smaller teams can borrow the patterns, but should not expect the same implementation surface.

Several recommendations depend on provider-specific pricing and feature behavior. Prompt-cache economics, reasoning-effort controls, context windows, and model price/performance frontiers shift quickly, so the exact defaults are perishable.

The piece focuses on economic efficiency more than security, privacy, or organizational failure modes. Tool gateways and managed agents also need strong authority boundaries, data handling rules, and incident response paths.

---

**Attribution:** Uday Kiran Medisetty, Uber Engineering, https://www.uber.com/us/en/blog/efficient-software-factory/
