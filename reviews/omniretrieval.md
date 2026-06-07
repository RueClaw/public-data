# OmniRetrieval (JinheonBaek/OmniRetrieval)

**Repo:** https://github.com/JinheonBaek/OmniRetrieval
**License:** MIT
**Reviewed:** 2026-06-07
**Stack:** Python, OpenAI/Anthropic/Google/vLLM clients, SentenceTransformers, BEIR, SQLite, SPARQLWrapper, Neo4j, PyTorch
**What it is:** Research code for OmniRetrieval, a framework and benchmark for routing natural-language questions across heterogeneous knowledge sources while preserving each source's native query/execution model.

---

## Verdict

📚 **Study for the source-native retrieval pattern.** OmniRetrieval is useful because it refuses to flatten every knowledge source into one vector index. It routes a question to the right backend and knowledge base, generates a native query for that source, executes it, then selects evidence across candidates. Treat the repo as research code: it is fresh, small, has no visible tests or CI, depends on large datasets and external endpoints, and is not a turnkey RAG platform.

---

## What It Is

OmniRetrieval addresses a real weakness in many RAG systems: unstructured text, relational databases, RDF knowledge graphs, and property graphs are structurally different, but common retrieval stacks often collapse them into a shared embedding/search layer. The paper argues that this loses the expressive power of source-native schemas, ontologies, joins, graph traversals, and query languages.

The implementation follows that premise. A natural-language question goes through four stages:

1. source selection: choose the backend and knowledge base;
2. query formulation: generate the appropriate search query, SQL, SPARQL, or Cypher;
3. execution: run the query against its native engine;
4. evidence selection: choose the candidate result that best answers the question.

The benchmark spans 13 datasets and 309 knowledge bases across BEIR text corpora, Spider/BIRD SQL databases, Wikidata-backed SPARQL datasets, and Neo4j Text2Cypher property graphs.

## Stack

| Layer | Tech |
|-------|------|
| Language | Python 3.10+ |
| LLM backends | OpenAI, Anthropic, Google Gemini, local vLLM |
| Dense retrieval | SentenceTransformers, PyTorch |
| Text benchmarks | BEIR corpora |
| SQL execution | SQLite databases from Spider and BIRD |
| RDF graph execution | SPARQLWrapper against Wikidata/QLever-style endpoints |
| Property graph execution | Neo4j driver against demo DB aliases |
| Evaluation | Route/source accuracy, query EM/F1, NDCG@K, execution match, selector accuracy, optional LLM judge |

## Key Features

### Source-Native Query Dispatch

The central pattern is simple and strong: do not make every source behave like text search. The pipeline stores a route decision with a `RouteType` and knowledge-base id, loads source-specific schema/context, generates a native query, and executes it through the appropriate adapter.

That preserves useful structure. SQL keeps joins and table constraints. SPARQL keeps entity/relation semantics. Cypher keeps property-graph traversals. Text search keeps dense retrieval over document corpora.

### Unified Benchmark Over Heterogeneous Backends

The dataset registry covers:

- BEIR: NFCorpus, SciFact, FiQA, MS MARCO, FEVER, NQ, HotpotQA;
- SQL: Spider, BIRD;
- SPARQL: LC-QuAD 2.0, QALD-10, SimpleQuestions;
- Cypher: Text2Cypher.

This makes the repo more interesting as an evaluation harness than as a production app.

### Candidate Evidence Selection

The CLI can run multiple route candidates with `--top-k-routes`, execute each, and select the best candidate. That is a useful step beyond "route once and hope," especially when a user question could plausibly map to more than one backend.

### Local and Hosted Model Options

The `LLMClient` supports OpenAI, Anthropic, Google, and vLLM. That makes the experiments portable across hosted APIs and local open-weight backbones, though vLLM is a heavyweight dependency.

## Architecture

The repo is intentionally compact:

- `main.py` runs the end-to-end pipeline and writes run artifacts.
- `evaluate.py` re-scores saved runs.
- `src/data/` defines the unified sample schema, dataset registry, and per-backend corpus metadata.
- `src/model/llm_client.py` wraps provider calls.
- `src/model/retrieval.py` owns routing, query generation, execution, and selection.
- `src/evaluation/metrics.py` implements backend-aware metrics.
- `src/utils.py` handles SQL, SPARQL, Cypher, Wikidata labels, caches, and run I/O.
- `scripts/data/` downloads and preprocesses supported datasets.

The main caveat is that the code assumes prepared data exists under `data/processed`. Even `python main.py --demo` needs the processed corpus/database folders. This is normal for a research benchmark, but it means the README quickstart is not "clone and instantly run."

## Comparison

| Aspect | OmniRetrieval | Typical Vector RAG | Text-to-SQL-only System |
|--------|---------------|--------------------|-------------------------|
| Source types | Text, SQL, SPARQL, Cypher | Usually text chunks | Relational databases |
| Query style | Native per source | Similarity search | SQL |
| Core problem | Route + formulate + execute + select | Retrieve + generate | NL to SQL |
| Best use | Research/eval pattern | Production document QA | Database QA |
| Main weakness | Heavy setup, no tests/CI, research maturity | Loses source structure | Narrow backend scope |

## Self-Hosting Notes

This is not a service. To reproduce experiments, expect to:

- install a heavy Python stack, including PyTorch, SentenceTransformers, BEIR, Neo4j driver, and vLLM;
- download and preprocess the benchmark datasets;
- cache SPARQL/Cypher gold executions to avoid repeated endpoint calls;
- configure hosted model API keys or run a local vLLM model;
- keep generated runs under `runs/`.

Validation performed for this review was limited to static compilation with `python3 -m compileall -q /tmp/OmniRetrieval`. There is no visible test suite in the repo, and full benchmark execution requires prepared data and external services.

---

**Attribution:** JinheonBaek/OmniRetrieval, MIT. Paper: Baek et al., "OmniRetrieval: Unified Retrieval across Heterogeneous Knowledge Sources," arXiv:2605.29250.
