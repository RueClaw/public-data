# MiroFish (666ghj/MiroFish)

**Repo:** https://github.com/666ghj/MiroFish
**License:** AGPL-3.0 (self-host freely; summarize only — no code reuse without copyleft)
**Reviewed:** 2026-10-05
**Stack:** Python 3.11/3.12 Flask backend (~28K lines), Vue 3 frontend, CAMEL-AI OASIS simulation engine, Zep Cloud knowledge graph, any OpenAI-compatible LLM
**What it is:** A multi-agent "swarm intelligence" simulation engine: upload seed documents (news, reports, fiction), and it builds a knowledge graph, generates thousands of persona agents, runs a social-media simulation on dual platforms, and produces a "prediction report."

---

## Verdict

📚 **Study — a well-packaged social-simulation pipeline, but "predicting anything" is marketing.** MiroFish is the polished consumer face of CAMEL-AI's OASIS simulator: seed → GraphRAG (Zep) → persona generation → parallel social simulation → ReAct-style report agent with full tracing. The engineering of the pipeline is real (18 backend test files, ~3.4K lines, covering Zep contracts and simulation lifecycle), and the workflow decomposition is worth studying. But there is zero validation of predictive accuracy anywhere in the repo — no backtesting, no benchmarks, no evaluation harness; the word doesn't appear in either README. What it actually produces is elaborate LLM role-play over a document-derived knowledge graph, which can be genuinely useful for scenario exploration and narrative rehearsal, but should never be mistaken for forecasting. Add the operational caveats: hard dependency on hosted Zep Cloud (no local graph option), wide-open CORS (`origins: "*"`), a hardcoded default Flask secret key, and AGPL-3.0.

---

## What It Is

MiroFish (from a Shanda Group-incubated team, Chinese-first with English docs) wraps a five-stage pipeline in a web UI:

1. **Graph building** — extract entities/relations from seed documents into a Zep Cloud knowledge graph, injecting "individual and collective memory."
2. **Environment setup** — persona generation (`oasis_profile_generator.py`, 1.2K lines) and agent configuration from the graph.
3. **Simulation** — OASIS dual-platform (Twitter-like + Reddit-like) parallel simulation; agents with personas and memory post, reply, and evolve; temporal memory updates flow back to Zep; variables can be injected mid-run from a "God's-eye view."
4. **Report generation** — a ReportAgent (2.6K lines) with a toolset queries the post-simulation graph and writes a sectioned report via a ReAct loop, with per-section planning, thought/tool/LLM-response logging.
5. **Deep interaction** — chat with any simulated agent or with the ReportAgent.

The demo materials tell you the actual use cases: simulating public-opinion dynamics around a Chinese university controversy, and deducing the lost ending of *Dream of the Red Chamber*. Scenario rehearsal and creative fiction — not forecasting.

## Stack

| Layer | Tech |
|-------|------|
| Backend | Python 3.11–3.12, Flask, threading + subprocess simulation runner |
| Simulation | camel-oasis 0.2.5 (CAMEL-AI OASIS social simulation) |
| Knowledge graph | Zep Cloud (hosted only; `zep-cloud==3.25.0`) |
| LLM | Any OpenAI-compatible endpoint; defaults to Alibaba Qwen-plus |
| Frontend | Vue 3, 16 views/components |
| Infra | Docker compose; npm-driven dev orchestration |
| Tests | 18 backend test files (~3.4K lines): Zep contracts, ontology, profiles, report sanitizer, simulation lifecycle |

## Key Features

### Pipeline decomposition

The seed→graph→personas→simulate→report staging is clean and each stage is a separate service module with its own tests. The temporal memory update loop (simulation events written back into the graph as agent memories) is the architecturally interesting part — agents accumulate history as the world evolves.

### Simulation lifecycle management

`simulation_runner.py` (2K lines) runs OASIS as a monitored subprocess with an explicit state machine (idle/starting/running/paused/stopping/stopped/completed/failed), IPC command channel, cross-platform signal handling, and bounded graph-ingestion finalization on stop. More disciplined than most academic simulation wrappers.

### Report agent observability

The ReportAgent logs everything: planning context, outline, per-section ReAct thoughts, tool calls and results, raw LLM responses, section completions, and timing. Simulation transcripts are first-class artifacts.

### Test coverage of external contracts

Zep client contracts, retry behavior, edge paging, graph lifecycle, and simulation/report barriers all have dedicated tests — the failure-prone seams are where the tests live.

## Architecture

Flask API (`graph`, `simulation`, `report` blueprints) → services layer (graph_builder, ontology_generator, oasis_profile_generator, simulation_config_generator, simulation_runner/manager/ipc, zep_* modules, report_agent) → OASIS subprocess + Zep Cloud + LLM endpoint. Simulation runs out-of-process with IPC; the web UI polls status. Single-user localhost design: no auth, CORS `*`, default `SECRET_KEY = 'mirofish-secret-key'` when unset.

## Comparison

| Aspect | MiroFish | OASIS (camel-ai) raw | Generative Agents (Stanford) |
|--------|----------|----------------------|------------------------------|
| What it is | Packaged product on OASIS | Research simulation framework | Research paper + reference code |
| Memory | Zep Cloud graph | Configurable | Local retrieval stream |
| Output | Interactive world + report | Simulation data | Observation logs |
| Validation | None | Research evals in papers | Qualitative |
| Deploy | Docker compose, two API keys | Library | Research code |

If you want the capability without the AGPL license or Zep dependency, use OASIS (Apache-2.0, per its repo) directly — MiroFish's added value is packaging, persona/report generation, and the UI.

## Self-Hosting Notes

Docker compose or source (Node 18+, Python 3.11–3.12, uv). Requires two external accounts: an OpenAI-compatible LLM (Qwen-plus recommended; README warns about token consumption — keep simulations under 40 rounds initially) and Zep Cloud (free tier covers light use). Not safe to expose beyond localhost without adding auth and fixing CORS/secret defaults.

---

**Attribution:** 666ghj/MiroFish, AGPL-3.0; simulation engine by CAMEL-AI (OASIS)
