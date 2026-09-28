# Jev Ecosystem Roundup (10 projects built on TypeSafe's Jev)

**Source:** https://x.com/3three_AI/status/2102295582387961913 (a Chinese-language X thread, "Jev is blowing up; got an API key but don't know what to do with it? Copy this list")  
**License:** n/a for the thread. The listed repos are MIT except json-render (Apache-2.0) and blink (**no license file**, so all rights reserved).  
**Reviewed:** 2026-09-28 (GitHub metadata and READMEs for all 10 repos; json-render source checked at HEAD)  
**Stack:** TypeSafe Jev (a hosted "System One" decision model) plus Python / TypeScript / Go / JavaScript clients  
**What it is:** A curated list of ten open-source projects that use Jev, TypeSafe AI's model that answers typed questions (Choice / Score / Noul) with probabilities and confidence instead of generating text. The projects cover browser agents, context compaction, generative UI, MCP connectors, a CLI, model routing, code review, and codebase search.

---

## Verdict

📚 **Good reference. A useful map of what people are building on a new decision-model API, but it's a hype list. Every entry except json-render was created in the same 48 hours (2026-09-16/17), and the whole category depends on one closed, early-access hosted model.**

The underlying idea is sound and worth knowing: stop coercing a text generator into returning booleans and enums. Ask a model trained to return calibrated probabilities over typed options, many questions per call, in a few hundred ms, and branch in code. The strongest entries treat Jev as a cheap **gate** in front of an expensive model: dropping stale tool output before it enters context, screening diffs before a frontier-model review, and routing each turn to the cheapest adequate model.

What to discount: the thread's one-line claims are vendor or author demos, not benchmarks ("Google Flights in 7 seconds" is a single recorded run). Star counts are launch-week numbers (20.9k for a 12-day-old repo). One entry is already archived and one is unlicensed. Two of the ten (system-one-connector, winnow) have a non-Jev fallback, which matters if TypeSafe access or pricing changes.

---

## What It Claims

The thread claims Jev is hot and lists ten ways to use an API key. It says Jev makes "what to do / which element" decisions, handles compaction, UI composition, routing, review triage, and navigation, and that a small model only generates text where text is actually needed.

TypeSafe's own docs (docs.typesafe.ai) describe Jev as the first "System One" model. It evaluates typed questions against a state in one request, in parallel and in isolation. It returns `choice`/`score` with probabilities and confidence, or `noul` (a 0–1 truth probability). The docs recommend decomposing any judgment that needs reasoning into atomic gut-check questions and combining them in code.

## The Ten Projects

| # | Repo | License | ★ (at review) | Created | What it actually is | Notes |
|---|------|---------|---------------|---------|---------------------|-------|
| 1 | browser-use/jev-ultrafast | MIT | 20,879 | 09-16 | Python browser agent. Each step builds an indexed element table; Jev picks operation (`CLICK`, `TYPE_TEXT`, `SELECT`, `SCROLL_*`, `WAIT`, `DONE`, `BLOCKED`) and target in one request. A small LLM writes text only for `TYPE_TEXT` | "7.1 s Zürich→London on Google Flights" is one demo run with a measurements doc. The README leads with a cloud waitlist |
| 2 | tamaratran/fast-jev-compaction | MIT | 7,037 | 09-17 | Claude Code plugin plus npm library that replaces summary-based compaction. Pairs each `tool_use`/`tool_result`, sends the whole conversation (results replaced by size notes) to Jev, and drops or truncates stale calls. Everything kept stays verbatim | The most interesting design here: deletion instead of lossy summarization, with pinned first/recent messages and a staged fit to a 25k-token state |
| 3 | vercel-labs/json-render | Apache-2.0 | 18,346 | 01-14 | Existing generative-UI framework. The Jev part is `experimental_composeSpec` / `experimental_createEvaluator` in `@json-render/core`: the app supplies atomic component candidates and Jev selects inclusion, order, and placement into a flat `Spec` | **Unreleased/experimental**, source build only. The API is model-neutral (Gateway model ID), with Jev as the tested example. Jev can't invent props or data. A full review of the framework is already in this repo (json-render.md) |
| 4 | itsmostafa/typesafe-mcp → **system-one-connector** | MIT | 324 | 09-17 | Go MCP connector (`evaluate`) for Claude Code/Desktop, Codex, Hermes, pi. Returns probabilities and options an agent can branch on | Renamed since the thread. Also runs self-hosted open System One models (CLM-v0.1-8B, Laya), so it's the least lock-in of the list |
| 5 | jkudish/jev-mcp | MIT | 428 | 09-17 | JS MCP server with 11 tools: verify, screen, noul, find, rerank, classify, decide, compare, extract (regex plus judgment), review, gate | Has CI. Claims ~150–500 ms per judgment for "a fraction of a cent" (author-reported) |
| 6 | sharziki/semdecide | MIT | 69 | 09-16 | Python CLI: "`grep` for meaning, `jq` for judgment". `semdecide is '<proposition>'` returns TRUE/FALSE with probability and threshold, plus routing, scoring, and filtering over JSONL, with stable exit codes for CI | Not on PyPI; installs from signed release wheels. A clean fit for shell pipelines |
| 7 | 0xNatoshi/jev-codex-router | MIT | 275 | 09-17 | Per-call model and reasoning-effort routing for Codex. Embeds a Codex Router fork and sends `jev/auto` through LiteLLM | **Archived** (2026-09-22). Its own README calls the "≈ −60% vs full" figure a historical simulation on 237 turns, not measured savings. Credit for the honesty |
| 8 | GhalebDweikat/winnow | MIT | 95 | 09-16 | Claude Code hook that splits large Read/Bash/Grep results into ~25-line blocks, asks "is block N needed?" per block, and replaces confident-no blocks with a stub, summary, and restore key | Has tests CI. Ships a fallback judge (TypeSafe's `system-one-adapter` prompting Claude Haiku 4.5, which it says is uncalibrated) so it runs without Jev access |
| 9 | devagrawal09/jev-review | MIT | 628 | 09-16 | Staged code review: Noul risk matrix → Choice/Score file profiles → evidence selection → mechanism classification → severity → conditional reviewer routing, with a local dashboard | Orchestration and thresholds live in code. Dashboard binds to 127.0.0.1 and never serves env files (per README). Node 24+ |
| 10 | ellipsis-dev/blink | **none** | 88 | 09-16 | Bun CLI for codebase search: an ensemble of "walkers" asks Jev at each directory level which child is most relevant and reports a distribution over files | No license, so it isn't reusable as-is. It's a small demo |

(Stars, creation dates, archive status, and license come from the GitHub API on 2026-09-28. Descriptions come from each repo's README; only json-render's source was inspected.)

## Evidence Quality

- **Performance claims:** all are author- or vendor-reported single demos or simulations. None were reproduced here. The only project that labels its number's limits clearly is jev-codex-router, and it's archived.
- **Launch clustering:** 9 of 10 repos were created 09-16 or 09-17, which suggests a coordinated early-access launch or hackathon. Commit counts are small for several (jev-ultrafast shows 3 commits, jev-review 5, blink 7, semdecide 7). Treat them as demos until they show sustained maintenance.
- **Dependency:** every project except system-one-connector (self-hosted CLM/Laya) and winnow (Haiku-backed adapter) needs a `TYPESAFE_API_KEY` for an early-access hosted model. Latency, price, and calibration are all TypeSafe's claims.
- **Thread accuracy:** mostly accurate one-liners. It misses that #4 was renamed, #7 was archived within days, #3's Jev support is unreleased and experimental, and #10 has no license.

## Gaps

- No independent calibration data. "Calibrated probabilities" is the core value proposition, and none of the listed projects publishes a reliability curve on their own task.
- No cost comparison against the obvious baseline, a small open model with constrained decoding or logprob-based classification, which also returns probabilities over fixed options.
- Privacy is unaddressed in the thread. Compaction, winnow, and review tools send whole conversations, tool output, or diffs to a third-party API.

## Who Should Read This

Anyone building agent harnesses who pays frontier-model prices for yes/no, pick-one, or rank decisions. The pattern (typed decision model as a gate or router, with orchestration in code) is portable even if you never use Jev. Start with fast-jev-compaction and winnow for context hygiene, jev-review for staged triage, and system-one-connector if you want the pattern without a single-vendor dependency.

## Reusable Patterns

- **Delete, don't summarize:** compaction that removes tool results judged stale and keeps everything else verbatim avoids the lossy-summary failure (lost paths, errors, constraints).
- **Stub with restore key:** replace low-relevance output with a short stub and a key to fetch the full text on demand, so nothing is irrecoverable.
- **Decision-model gate before an expensive model:** cheap parallel typed questions filter what reaches the costly reviewer or context.
- **Indexed action space for browser agents:** give the decider an enumerated element table and a closed operation set, and generate text only when the chosen operation requires it.
- **Decompose into atomic questions, weight in code:** tune behaviour by changing coefficients, not prompts.

---

**Attribution:** Thread by @3three_AI on X. Projects by their respective authors as listed; licenses per repo (MIT, json-render Apache-2.0, blink unlicensed).
