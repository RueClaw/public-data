# Agentic Software Factory Cost Equation

**Source:** Uber Engineering, "Running a Software Factory Efficiently at Uber Scale"
**URL:** https://www.uber.com/us/en/blog/efficient-software-factory/
**Author:** Uday Kiran Medisetty
**Reviewed:** 2026-08-28
**License:** Source article copyright belongs to Uber; this file summarizes the public pattern with attribution.

---

## Pattern

Treat agentic software-development spend as a production cost equation rather than a flat AI bill:

```text
total cost = users
  x sessions per user
  x turns per session
  x model requests per turn
  x tokens per request
  x price per token
```

Use the first two terms as adoption and engagement signals. Optimize the middle and final terms through model routing, context controls, tool-loop reduction, prompt caching, and price/performance benchmarking.

## Why It Matters

Agent adoption can grow faster than budgets if every agent session loads large tool catalogs, repeats bulky context, calls expensive models for routine work, or loops through tool polling in the transcript. A decomposed cost model makes waste visible. It also keeps teams from overcorrecting by simply downgrading models when the real issue is context bloat, poor cache behavior, excessive tool calls, or missing workflow benchmarks.

## Operating Metrics

Track these weekly or monthly:

- Total attributed cost, active users, and spend share by agent or tool.
- Cost per user, requests per user, cost per 1,000 requests, cost per 1,000 sessions, and cost per active session hour.
- Input, output, and total tokens per request.
- Cost per million tokens and prompt-cache hit rate.
- Model-level cost share, request share, cost per 1,000 requests, and cost per million tokens.
- Driver decomposition: user growth, requests per user, input tokens per request, output tokens per request, and model price.

For managed agents, also track outcome-denominated cost:

- Cost per merged PR, reviewed PR, triaged alert, migration, cleanup, or other completed workflow.
- Quality signals such as revert rate, precision/recall/F1, MTTR, latency, timeout rate, and false-positive or noise rate.

## Optimization Levers

Use real-work benchmarks to choose Pareto-efficient model defaults. Compare quality, reliability, latency, and cost per completed task instead of choosing models by headline capability alone.

Cap effective context even when providers offer larger windows. A large context window can be a fallback, not the default operating size.

Default routine sub-work to cheaper models when the primary agent can decompose, supervise, and verify the result.

Tune prompt-cache TTLs to session shape. Interactive sessions may need longer cache lifetimes because humans pause; short-lived subagents often do better with shorter-lived cache entries.

Avoid loading every tool schema into every session. Route broad tool catalogs through dynamic search, CLI-style tool resolution, or a gateway that exposes only the tools needed for the current job.

Batch noisy tool loops outside the model transcript. For example, a code-mode subprocess can poll, query, retry, aggregate, and return a compact result while preserving raw evidence elsewhere.

Ground agents in structured organizational context so they ask fewer speculative questions, spawn fewer unnecessary subagents, and make fewer dead-end tool calls.

Show live cost and session-usage feedback in the agent harness. Users and managers should be able to see spend while work is happening, not only after invoices arrive.

## Adoption Checklist

- Define the cost equation for each agent surface.
- Instrument session, turn, request, token, model, cache, and outcome metrics.
- Build small real-work benchmarks for the highest-spend workflows.
- Pick model defaults from cost-quality Pareto frontiers.
- Set context caps and cache TTLs by workflow type.
- Replace all-tools-loaded-by-default with on-demand tool discovery.
- Add a session analyzer that flags context bloat, model mismatch, cache misses, and costly loops.
- Report managed-agent cost per useful outcome, not only request volume.

---

**Attribution:** Pattern summarized from Uday Kiran Medisetty, Uber Engineering, "Running a Software Factory Efficiently at Uber Scale," https://www.uber.com/us/en/blog/efficient-software-factory/
