# Idégeneratorn / Idea Generator (fltman/idea-generator-2)

**Repo:** https://github.com/fltman/idea-generator-2
**Author:** Anders Bjarby (fltman)
**License:** MIT; preserve copyright and permission notices when reusing code. Dependencies and model/service terms remain separate.
**Reviewed:** 2026-11-07 (UTC)
**Revision:** f3f29b443db6e1db916af03c7b49942cacd681d8, main; root documentation, manifests, server, browser modules, calibration tool and six test files.
**Verification:** Static source review only. No install, source execution, application tests, model downloads, paid calls or deployment performed.
**Stack:** TypeScript / Node.js >=25, built-in HTTP and SQLite, vanilla browser JavaScript, Anthropic SDK and HTTP provider adapters.
**What it is:** A local visual brainstorming board that branches and crosses ideas, scores them with an LLM, and optionally evolves the board and writes coding-project briefs.

---

## Verdict

⚠️ **Interesting as a supervised ideation workbench, not a validated invention engine.** The lineage graph, deterministic medals, source-filtered scouts and compact architecture are substantive implementations. But “jury” means one model call per idea, evolution optimizes that model's scores rather than demonstrated usefulness, and the advertised budgets are not hard spending limits. Keep it local, start in manual mode, disable automatic project creation, and independently investigate shortlisted ideas.

## What It Is

The canonical public repository is fltman/idea-generator-2; its displayed name is Idégeneratorn / Idea Generator. It is not a startup-market research service or an autonomous coding agent. Designers, facilitators and founders can create goal-specific boards, paste short thoughts or longer text/URLs, expand ideas into up to three children, cross two parents into one child, and inspect ancestry on a pan/zoom canvas. Boards have editable generation prompts, judge guidance and role-specific model overrides. Swedish and English interfaces are included. [1–4]

The server can continue breeding automatic boards without an open browser. Guest ideas can be announced to other boards and rejudged against their goals; spin-offs create a new manual board. Summaries, model-assigned keyword trends and cross-board reports help navigate accumulated material. These are organization and synthesis features, not independent demand or scientific evidence. [2–5]

## Stack

| Layer | Implementation |
|---|---|
| Runtime | Node >=25 runs TypeScript directly; no build step |
| API | Built-in node:http, regex routes, JSON and server-sent events |
| Persistence | node:sqlite DatabaseSync; boards, ideas, edges, leads, keywords, reports and daily spend |
| UI | Vanilla ES modules, custom canvas/graph behavior and DOM helpers |
| Models | OpenRouter, Anthropic, OpenAI, Azure; Ollama, MLX, LM Studio, custom OpenAI-compatible endpoints |
| Dependencies | One direct dependency, @anthropic-ai/sdk ^1.3.0; lockfile pins 1.3.0 plus seven transitive packages |
| Tests | node:test, injected fake chat/fetch, in-memory SQLite and temporary project directories |

## Key Features

### Goal-directed branching and lineage

Generation prompts ask for concrete mechanisms rather than buzzwords. Default expansion requests a close variation, a borrowed mechanism and a bold leap; crossover requests a genuinely fused concept. Existing titles (only the last 40) are supplied as a non-repetition prompt. There is no semantic novelty index or prior-art check. The graph preserves parent relationships, generations and guest origins. [2–4]

### A transparent score, but not a panel of judges

The judge returns originality, feasibility and impact, each clamped to 1–5, a short reason and keywords. Code sums the dimensions and assigns bronze at 9, silver at 11, gold at 13. Human medal overrides win both for display and breeding, mapping to fitness values 6/10/12/14. This separates presentation thresholds from model output, a useful design choice. Nevertheless, one selected model produces all dimensions in one call; the default generator and judge use the same configured model family. A short explanation is a rationale, not a verified proof. [3,6]

### Evolution is real selection, not measured progress

The pure nextMove function uses tournaments of size three, nominal 20% expansion/mutation, and excludes repeated combined pairs and direct parent-child pairs. Small populations expand first. It does not establish semantic diversity, exclude all distant relatives, or measure real-world success. The displayed first/latest fitness windows exclude seeds and guests, avoiding one obvious inflated-gain baseline, but still measure the same endogenous judge reward. The windows can overlap for small populations. Increasing scores could reflect better phrasing or judge preference rather than better ideas. [6]

### Scouts constrain references, not truth

X leads must have an HTTP(S) X/Twitter URL matching a normalized URL in provider-returned search annotations; invented uncited URLs are dropped. Research leads must match IDs from Hugging Face daily/search results, with ID deduplication and original paper metadata. This is stronger than trusting model-written citations alone. However, citation membership does not establish that the generated summary/hook is supported, that an X URL is specifically a post, or that an idea is novel. Research selection sees shortened summaries (preferring ai_summary), not full papers. The one-year filter applies to searched papers, not the daily feed. Scouts feed seeds; they do not automatically fact-check each evolved candidate. [7]

### Gold writes briefs, not functioning products

Gold can trigger another model call and a fresh folder containing CLAUDE.md, README.md, idea.json and a gitignored notes directory, followed by git init. Automatic project creation defaults to true, even on a manual board when its background judge awards gold. Names are sanitized and existing folders are not overwritten. No Claude process is started and no generated implementation is executed. The separate “reveal” operation invokes the macOS open command; portability of that convenience action is limited. [2,4,8]

## Architecture

The flow is browser → app.ts routes → engine.ts operations → llm.ts prompts/provider adapter → SQLite → per-board event bus/SSE. index.ts starts the database, engine, in-memory runtime settings and one-second autopilot timer. Generation, persistence and HTTP handlers are separated sufficiently to inject fakes in tests. Pure scoring/evolution modules are shared between browser and server. [2–6,9]

Background manual-operation judging has a three-active-call queue. Autopilot performs its own judgments and can run boards concurrently, so that queue is not a global provider concurrency cap. State for hourly steps, backoff and pacing is in memory, while dollar spend is persisted. Restarting resets the rate/backoff history. A seed may persist before its background judgment fails, and an auto-created project may fail after judgment succeeds: those are deliberately separate stages, not one atomic operation. [2,5]

## Methodology and Evidence

The calibration tool contains six author-labelled weak examples (largely bare topics/vague proposals), five detailed strong examples, two runs each, and an empty board goal: 22 judge calls. It fails if any weak example reaches 9 or if the strong-minus-weak mean gap is below 3. It prints run spread and strong gold counts, but neither is a pass/fail gate. It is a prompt sanity check, not statistical calibration of probability, a held-out novelty benchmark or independent expert validation. Detail level is confounded with the weak/strong labels. [10]

The reviewed tree contains no committed calibration-result dataset, blinded human evaluation, comparison against a same-budget single-prompt baseline, customer experiment, patent/literature novelty search, or measured downstream project outcomes. Source comments report small provider timing/cost observations; these were not independently reproduced. The open feedback issue also discusses semantic-plausibility loops, but its anecdote is not an evaluation dataset. [10,12]

To test usefulness, freeze goals/constraints and budgets; compare manual brainstorming and one-shot generation with evolution; hide method and model score from independent domain raters; check prior art and failure modes; and measure shortlist diversity plus real prototype/customer outcomes. Keep that evaluator out of the selection loop.

## Privacy, Security and Execution Boundaries

- **Local is not offline.** Ideas, goals, source text, selected ancestry and summaries are sent to whichever provider each role chooses. Hugging Face search receives the goal/focus query; X scouting sends it through OpenRouter/search. Role overrides can silently change the recipient relative to app-wide settings. Local-only models do not make enabled scouts local. [2,3,7,9]
- **Keys persist in the browser.** localStorage holds API keys, models and endpoint settings; the server receives them in memory, with environment-key fallback. “Never writes keys to disk” is only a server-storage claim: the browser profile persists them. Any compromised same-origin script/browser profile is therefore sensitive. The API reports key sources rather than returning raw keys. [9,11]
- **Loopback is a default, not an enforced boundary.** HOST can override 127.0.0.1. There is no login, Host/Origin validation or CSRF token in the inspected handler. No permissive CORS header is emitted, which limits ordinary cross-origin reads, but is not equivalent to origin/host enforcement; JSON parsing also does not require a JSON Content-Type. Do not expose this service or assume browser-origin attacks are handled. No exploit was executed. [9]
- **URL ingestion is an SSRF surface.** asUrl accepts HTTP(S), including private destinations, and fetchPage follows redirects without destination/IP checks. Extracted content is sent to the distillation provider. The nominal two-megabyte cap slices only after arrayBuffer has read the whole response, so it is not a streaming download-memory limit. Add private-address/redirect/DNS checks and streamed byte bounds before accepting untrusted links. [13]
- **Endpoint settings are authority-bearing.** Configurable base URLs are not allowlisted. OpenAI-compatible adapters attach the configured/fallback provider credential to the chosen endpoint, so an endpoint change can redirect sensitive data and credentials. Only trusted operators should control runtime settings. [9]
- **Generated text crosses into agent instructions.** Source text, goals and model briefs can contain prompt injection. The browser's text-node DOM helpers are a positive XSS defense, but exporting that text into CLAUDE.md is a separate trust boundary. Review generated instructions before opening them with a coding agent. File writes run with server-user permissions under the configured absolute project root, not an OS sandbox. git init uses execFile rather than a model-authored shell command; its callback ignores errors, so a returned project path does not prove Git initialization succeeded. [8,11]
- **Backups/exports are sensitive.** SQLite and generated idea.json/briefs contain ideas and lineage in plaintext. Ignoring a notes folder in Git is not encryption and does not protect the other project files from later publication. Static file serving includes a lexical traversal guard; request bodies are bounded to one megabyte. These controls do not make the app multi-tenant. [8,9]

## Costs and Self-Hosting Notes

The default configuration is manual mode, 10-second autopilot pace, 60 steps/hour, $1/day per board and $5/day globally. These are source defaults, not a cost forecast. One expansion commonly means one generation plus up to three judge calls, and each gold may add a brief call. Hosted model/search charges depend on the selected service; local inference still costs hardware, memory and electricity. [2,4,5]

**The budget limiter is a soft autopilot throttle.** It checks recorded spend before a step, not before each API call, reserves no funds for in-flight work, and does not gate manual operations, background judging or project creation. Multiple boards can begin against the same spend snapshot. A zero-dollar limit allows work while recorded spend is zero—including a first paid call. OpenAI-compatible cost is usage.cost or zero; unknown Anthropic model prices also map to zero. Failed/invalid responses and retries can incur costs that never reach the successful-call ledger. Thus zero recorded spend is not proof of free operation and dollar caps can be exceeded. Use provider-side hard limits and an explicit human budget. [2,5,9]

A trial needs Node >=25, the locked npm dependency tree, a browser and a working selected model endpoint; Git is required for actual project initialization. Claude Code is separate and only needed to pursue generated briefs. The source contains a lockfile but no container deployment or service hardening. Verify model availability and pricing rather than treating hardcoded names/prices or README provider-history statements as independently established facts. Start with synthetic/nonconfidential material, all boards manual, automatic projects disabled, trusted endpoints and restricted egress. Back up SQLite and inspect generated folders. No install was performed for this review.

## Maturity and Verification

Public GitHub metadata retrieved 2026-11-07: created 2026-11-02, last push 2026-11-04, 33 stars, 12 forks, one open feedback issue and no published releases. The inspected package is 0.1.0. These are time-sensitive activity facts, not quality guarantees. No tracked GitHub Actions workflow was present. [1,12]

There are exactly 50 top-level test declarations across six files, matching the README count: API 15, autopilot 4, extraction 5, leads/project 5, providers 11 and scoring/evolution 10. Tests exercise meaningful seams: fake-provider failures, model routing, citation filtering, SSE, goal-specific guests, traversal, export, medal overrides, selection, pacing and project name collisions. They cannot establish live-model quality or current provider compatibility. Tests were inspected, not executed; no dependency audit, browser interaction, security exploit or paid calibration was run. No performance/quality result is claimed. [14]

## Comparison

| Option | Better fit | Trade-off |
|---|---|---|
| This repository | Visual ongoing idea families, cross-board recombination and brief export | Endogenous scores, soft cost controls, local trust only |
| [ADHD](https://github.com/UditAkhourii/adhd) | Bounded divergent ideation with isolated frames and a separate critic | CLI/skill workflow rather than a live visual breeding board; model critique still needs external validation |
| [STORM](https://github.com/stanford-oval/storm) | Retrieval-led research and citation-oriented reports | Not an evolutionary idea canvas; source quality and claim support still need checking |
| Plain whiteboard + manual source research | Low-cost exploration with explicit human prioritization | No automated lineage/scoring/scouting; more manual organization |

See the existing [ADHD review](adhd.md) and [STORM review](storm.md) for separately dated assessments; neither alternative was freshly benchmarked here. The useful differentiator is the integrated interaction loop, not demonstrated superiority at invention. A supervised experiment is warranted; unattended confidential or budget-critical operation is not.

## Evidence Map

All source-code links below pin the reviewed revision.

1. [README](https://github.com/fltman/idea-generator-2/blob/f3f29b443db6e1db916af03c7b49942cacd681d8/README.md), [manifest](https://github.com/fltman/idea-generator-2/blob/f3f29b443db6e1db916af03c7b49942cacd681d8/package.json), [lockfile](https://github.com/fltman/idea-generator-2/blob/f3f29b443db6e1db916af03c7b49942cacd681d8/package-lock.json), [MIT license](https://github.com/fltman/idea-generator-2/blob/f3f29b443db6e1db916af03c7b49942cacd681d8/LICENSE).
2. [Engine: calls, judging, generation, cross-board operations, projects and autoStep](https://github.com/fltman/idea-generator-2/blob/f3f29b443db6e1db916af03c7b49942cacd681d8/server/engine.ts).
3. [Generation/judging prompts and normalization](https://github.com/fltman/idea-generator-2/blob/f3f29b443db6e1db916af03c7b49942cacd681d8/server/llm.ts).
4. [Database schema, default config and templates](https://github.com/fltman/idea-generator-2/blob/f3f29b443db6e1db916af03c7b49942cacd681d8/server/db.ts).
5. [Autopilot pacing, spend checks and in-memory state](https://github.com/fltman/idea-generator-2/blob/f3f29b443db6e1db916af03c7b49942cacd681d8/server/autopilot.ts).
6. [Scoring](https://github.com/fltman/idea-generator-2/blob/f3f29b443db6e1db916af03c7b49942cacd681d8/public/js/score.js), [evolution selection/statistics](https://github.com/fltman/idea-generator-2/blob/f3f29b443db6e1db916af03c7b49942cacd681d8/public/js/evolve.js).
7. [X citation and research paper filters](https://github.com/fltman/idea-generator-2/blob/f3f29b443db6e1db916af03c7b49942cacd681d8/server/leads.ts).
8. [Project rendering and filesystem/subprocess effects](https://github.com/fltman/idea-generator-2/blob/f3f29b443db6e1db916af03c7b49942cacd681d8/server/project.ts).
9. [Startup binding](https://github.com/fltman/idea-generator-2/blob/f3f29b443db6e1db916af03c7b49942cacd681d8/server/index.ts), [HTTP/settings routes](https://github.com/fltman/idea-generator-2/blob/f3f29b443db6e1db916af03c7b49942cacd681d8/server/app.ts), [provider transport and costs](https://github.com/fltman/idea-generator-2/blob/f3f29b443db6e1db916af03c7b49942cacd681d8/server/providers.ts).
10. [Calibration fixtures and acceptance criteria](https://github.com/fltman/idea-generator-2/blob/f3f29b443db6e1db916af03c7b49942cacd681d8/tools/calibrate-judge.ts).
11. [Browser settings](https://github.com/fltman/idea-generator-2/blob/f3f29b443db6e1db916af03c7b49942cacd681d8/public/js/settings.js), [text-node DOM helper](https://github.com/fltman/idea-generator-2/blob/f3f29b443db6e1db916af03c7b49942cacd681d8/public/js/dom.js), [UI operations](https://github.com/fltman/idea-generator-2/blob/f3f29b443db6e1db916af03c7b49942cacd681d8/public/js/app.js).
12. [Public repository metadata](https://api.github.com/repos/fltman/idea-generator-2), [releases](https://github.com/fltman/idea-generator-2/releases), [feedback issue](https://github.com/fltman/idea-generator-2/issues/1); retrieved 2026-11-07.
13. [URL parsing, redirects and extraction limits](https://github.com/fltman/idea-generator-2/blob/f3f29b443db6e1db916af03c7b49942cacd681d8/server/extract.ts).
14. [Test tree](https://github.com/fltman/idea-generator-2/tree/f3f29b443db6e1db916af03c7b49942cacd681d8/test).

---

**Attribution:** Anders Bjarby / fltman/idea-generator-2, MIT License. Independent static analysis; no source code extracted.
