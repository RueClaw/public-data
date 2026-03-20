# local-deep-researcher (langchain-ai/local-deep-researcher)

**Rating:** 🔥🔥🔥  
**License:** MIT  
**Source:** https://github.com/langchain-ai/local-deep-researcher  
**Reviewed:** 2026-03-20  
**Author:** LangChain AI (official)

## What It Is

Fully local iterative web research agent. Give it a topic → generates a search query → fetches web results → summarizes → reflects on knowledge gaps → generates a new query → repeats N times → final markdown report with citations. All LLM inference via Ollama or LMStudio, no cloud required.

## Architecture

LangGraph graph, 5 nodes:

```
generate_query → web_research → summarize_sources → reflect_on_summary
                                                           ↓ (loop < max)
                                                     web_research
                                                           ↓ (loop >= max)
                                                     finalize_summary → END
```

Inspired by **IterDRAG** — iterative retrieval where each search builds on the previous answer's gaps, not just the original query. The `reflect_on_summary` node asks the LLM "what's missing from this summary?" and turns the gap into the next search query.

## Key Code (~300 lines of real logic)

```
src/ollama_deep_researcher/
├── graph.py          # 5 nodes + routing logic
├── configuration.py  # Pydantic config, env var overrides
├── state.py          # SummaryState (research_topic, running_summary, sources, loop_count)
├── prompts.py        # query_writer, summarizer, reflection instructions
└── utils.py          # search backends (tavily, duckduckgo, perplexity, searxng)
```

## Configuration

All overridable via env vars or LangGraph Studio UI:

| Field | Default | Notes |
|-------|---------|-------|
| `max_web_research_loops` | 3 | Research depth |
| `local_llm` | `llama3.2` | Any Ollama model name |
| `llm_provider` | `ollama` | `ollama` or `lmstudio` |
| `search_api` | `duckduckgo` | No API key needed |
| `fetch_full_page` | `true` | Full page vs. snippets |
| `strip_thinking_tokens` | `true` | Strips `<think>` from reasoning models |
| `use_tool_calling` | `false` | Tool calling vs. JSON mode |

## Search Backends

- **DuckDuckGo** (default) — zero API cost, no key
- **Tavily** — best quality, requires key
- **Perplexity** — requires key
- **SearXNG** — self-hosted option

## Structured Output

Two modes for query generation and reflection:
- **JSON mode** (default) — `format="json"` passed to Ollama
- **Tool calling** (`use_tool_calling=True`) — required for gpt-oss models that don't support JSON mode

Graceful fallback if model fails to produce valid JSON.

## Running

```bash
cd local-deep-researcher
cp .env.example .env
# Edit .env: LLM_PROVIDER=ollama, LOCAL_LLM=deepseek-r1:32b, SEARCH_API=duckduckgo
uvx --from "langgraph-cli[inmem]" --with-editable . --python 3.11 langgraph dev
# Open: https://smith.langchain.com/studio/?baseUrl=http://127.0.0.1:2024
```

## Compared to DeerFlow

DeerFlow is more ambitious (multi-agent, specialist roles, MCP, Tavily required). Local-deep-researcher is simpler and works out of the box with DuckDuckGo. Good replacement for lightweight research tasks while DeerFlow is broken.

## Relevance

- Runs today on Rue with `deepseek-r1:32b` or `qwen3-coder-next` + DuckDuckGo, zero API cost
- Pattern reference: clean IterDRAG loop, LangGraph graph structure, reflection-driven query generation
- Practical use: trigger from heartbeat when a research topic is dropped in Discord, drop result to vault
- The longevity research brief that ran as a subagent — this would do that locally
