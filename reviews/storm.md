# STORM (stanford-oval/storm)

**Repo:** https://github.com/stanford-oval/storm
**License:** MIT. Code and patterns are reusable with attribution.
**Reviewed:** 2026-06-18
**Stack:** Python, DSPy, LiteLLM, Qdrant/LangChain retrieval adapters, Streamlit demo
**What it is:** STORM is a research-oriented knowledge curation engine that researches a topic through retrieval-grounded multi-perspective questioning, drafts an outline, and writes a cited long-form report. Co-STORM extends that flow into collaborative human/AI discourse with expert agents, moderator turns, and a mind-map-like knowledge base.

---

## Verdict

📚 **Study the architecture; do not treat it as a turnkey production research agent.** The core ideas are strong: split research from outline and article generation, use multiple LMs for different cost/quality roles, and make retrieval adapters first-class. The repo is popular and useful, but its automated test posture is thin, the demo has at least one stale API call, and the package version metadata is currently inconsistent.

---

## What It Is

STORM stands for Synthesis of Topic Outlines through Retrieval and Multi-perspective Question Asking. Its target workflow is pre-writing: gather source-grounded information, discover useful perspectives, build an outline, then generate a Wikipedia-like article with citations. The README is explicit that the output is not publication-ready and is meant to help experienced editors and researchers in the pre-writing stage.

The repository ships two related engines. `STORMWikiRunner` is the batch pipeline: research, outline, article draft, and optional polishing. `CoStormRunner` is the collaborative variant: it runs expert agents, a moderator, user turns, and a dynamic knowledge base to support exploratory discourse before report generation.

The most reusable part is the system shape. It treats research as a staged process with durable artifacts such as conversation logs, raw search results, outlines, generated articles, references, run configs, and LLM call history. That is much better than a single opaque "deep research" prompt.

## Stack

| Layer | Tech |
|-------|------|
| Core orchestration | Python classes around DSPy modules |
| Language models | LiteLLM plus custom wrappers for OpenAI, Anthropic, DeepSeek, Groq, Together, Google, VLLM/TGI/Ollama-style endpoints |
| Retrieval | You.com, Bing, Serper, Brave, SearXNG, DuckDuckGo, Tavily, Google, Azure AI Search, Qdrant vector retrieval |
| Local corpus | CSV-to-Qdrant vector store examples through LangChain/Hugging Face embeddings |
| UI | Minimal Streamlit demo |
| Packaging | `setup.py`, `requirements.txt`, PyPI workflow |
| CI | Black formatting check on PRs; manual package build/publish workflow |

## Key Features

### Perspective-Guided Question Asking

STORM does not ask one generic research query and summarize the web. It generates personas/perspectives, simulates a Wikipedia writer interviewing an expert, turns questions into search queries, retrieves evidence, and uses the accumulated dialogue to build an outline.

That pattern is the main reason to study the repo. It gives the research phase a shape that can be inspected, paused, and improved.

### Staged Runner API

`STORMWikiRunner.run(...)` exposes separate switches for research, outline generation, article generation, and polishing. Each stage can write and reload intermediate artifacts. That makes the pipeline more debuggable than a monolithic agent loop.

### Retrieval Adapter Surface

The retriever layer supports multiple web search providers plus `VectorRM` for user-provided documents. The adapters return a common `Information` shape with URL, title, description, snippets, metadata, and citation IDs. This makes it possible to swap public web search for a private corpus without changing the whole article pipeline.

### Co-STORM Collaboration Model

Co-STORM adds expert agents, moderator intervention, turn policies, unused-information discovery, and a knowledge base with hierarchical nodes. The moderator pattern is especially interesting: it tries to surface unused retrieved evidence instead of only continuing the current conversational groove.

## Architecture

The repository is organized around a small set of framework concepts:

- `knowledge_storm/interface.py` defines base concepts such as engines, retrievers, information records, and article structures.
- `knowledge_storm/storm_wiki/engine.py` wires the batch STORM pipeline.
- `knowledge_storm/storm_wiki/modules/` contains persona generation, knowledge curation, outline generation, article generation, and article polishing.
- `knowledge_storm/collaborative_storm/engine.py` wires the collaborative Co-STORM pipeline.
- `knowledge_storm/collaborative_storm/modules/` contains expert generation, grounded QA, moderator question generation, warm start, knowledge-base summarization, and simulated-user pieces.
- `knowledge_storm/rm.py` holds retriever implementations.
- `examples/` demonstrates provider and retriever combinations.
- `frontend/demo_light/` is a small Streamlit UI.

The design is closer to a research library than an application framework. It gives you concrete abstractions and example scripts, but you still own model choice, retrieval provider setup, cost controls, deployment, and output validation.

## Quality And Maturity

The repo has strong adoption signals: about 28.6k GitHub stars and 2.6k forks as of 2026-06-18. The latest commit in the reviewed checkout is `fb951af` from 2025-09-30, and GitHub reports 100 open issues.

The caveats are real:

- No automated test suite was visible in the checkout.
- CI only checks Black formatting on pull requests; package publishing is manual.
- `setup.py` declares version `1.1.1`, while `knowledge_storm/__init__.py` declares `1.1.0`; the publish workflow explicitly checks for this mismatch.
- The Streamlit demo calls `STORMWikiLMConfigs.init_openai_model(...)` without the required `azure_api_key` positional argument, so that path appears stale against the current engine signature.
- The dependency list is unpinned beyond `dspy_ai==2.4.9`, which is fragile for a research pipeline sitting on fast-moving LLM, search, embedding, and vector-store libraries.

## Security And Trust Notes

No hardcoded production secrets were found in a static scan. The examples and demo use environment variables or `secrets.toml`.

The more important trust issue is content flow: web pages or private-corpus snippets are retrieved, chunked, and fed into LMs that generate cited prose. Treat generated articles as drafts with provenance, not as verified truth. The code also includes generic pickle load/dump helpers; do not use `load_pickle` on untrusted files.

## Comparison

| Aspect | STORM | NotebookLM-style tools | General deep-research agents |
|--------|-------|------------------------|------------------------------|
| Primary goal | Generate cited long-form topic reports | Chat/summarize over chosen sources | Broad autonomous research |
| Research shape | Perspective-guided simulated interviews | Source-grounded QA/synthesis | Often planner/search/summarize loops |
| Source model | Web search or custom vector corpus | Usually uploaded/source-selected docs | Web plus tools |
| Best use | Studying and adapting a staged research pipeline | Private document understanding | One-off investigative tasks |
| Main caveat | Research-code maturity and stale edges | Product/runtime lock-in | Harder to inspect process quality |

## Self-Hosting Notes

For library use, `pip install knowledge-storm` is the intended path. Source installs use Python 3.10 or 3.11 and `pip install -r requirements.txt`. Most useful runs require at least one LLM provider key and one retrieval provider key, unless using local model endpoints plus local/search alternatives.

For private-corpus work, start with the `VectorRM` examples and keep generated artifacts in a controlled output directory. For web research, budget and rate limits matter because STORM can fan out queries across perspectives, turns, and article sections.

---

**Attribution:** stanford-oval/storm, MIT License.
