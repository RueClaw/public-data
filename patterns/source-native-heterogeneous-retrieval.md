# Source-Native Heterogeneous Retrieval

**Source:** https://github.com/JinheonBaek/OmniRetrieval
**License:** MIT
**Reviewed:** 2026-06-07

## Pattern

When a knowledge system spans structurally different sources, route each user query to the appropriate backend and execute native queries instead of flattening everything into one shared vector index.

The core loop:

1. classify the query into one or more source/backend candidates;
2. load source-specific context such as corpus description, SQL schema, RDF relation hints, or graph schema;
3. generate a native query for that source;
4. execute through the native engine;
5. select evidence across candidate executions.

## Shape

```text
Natural-language question
  -> route candidates: (backend, kb_id)
  -> per-source context loader
  -> query generator
       SEARCH -> dense query / HyDE passage
       SQL    -> SQL
       SPARQL -> SPARQL
       CYPHER -> Cypher
  -> native execution adapters
  -> candidate evidence set
  -> selector / judge
```

## Why It Works

Different sources have different affordances:

- text corpora need lexical/dense retrieval;
- relational databases need joins, filters, grouping, and schema grounding;
- RDF graphs need entity/relation semantics and ontology-aware paths;
- property graphs need traversal patterns and node/edge properties.

Flattening all of these into text chunks makes the system simpler, but it hides the structure that made those sources valuable. Source-native retrieval keeps the control plane unified while leaving execution specialized.

## Implementation Notes

Useful implementation boundaries:

- Use a shared sample/schema object for evaluation and run logs.
- Keep source selection separate from query formulation.
- Keep query formulation separate from execution.
- Cache expensive external executions, especially SPARQL and remote graph queries.
- Score each backend with backend-aware metrics, not one universal string metric.
- Allow top-k routes and evidence selection so ambiguous questions can try multiple sources.

## Best Fit

This pattern fits research assistants, enterprise knowledge systems, scientific data workbenches, and agent tools that need to retrieve from documents, tables, semantic graphs, and property graphs without erasing the differences between them.

It is overkill for a single document corpus or a small app database. Start with ordinary search or text-to-SQL there.

---

**Attribution:** JinheonBaek/OmniRetrieval, MIT. Paper: Baek et al., "OmniRetrieval: Unified Retrieval across Heterogeneous Knowledge Sources," arXiv:2605.29250.
