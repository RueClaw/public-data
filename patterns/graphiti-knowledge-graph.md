# Graphiti Knowledge Graph Pattern

> **Source:** [getzep/graphiti](https://github.com/getzep/graphiti)
> **License:** Apache 2.0
> **Description:** Build real-time knowledge graphs for AI agents. Temporally-aware, incrementally updated, suitable for dynamic environments.

## Overview

Graphiti is a framework for building and querying temporally-aware knowledge graphs, specifically tailored for AI agents operating in dynamic environments.

Unlike traditional RAG methods, Graphiti:
- Continuously integrates user interactions and data
- Supports incremental updates without full recomputation
- Enables precise historical queries
- Provides multiple search methods (semantic, keyword, graph-based)

## Key Capabilities

### Continuous Integration

```python
# Add episodes (conversations, events) incrementally
await graphiti.add_episode(
    name="user_interaction",
    episode_body=conversation_text,
    source="slack",
    timestamp=datetime.now()
)
```

### Multi-Modal Search

```python
# Semantic search
results = await graphiti.search(
    query="What do we know about Project X?",
    search_type="semantic"
)

# Hybrid search (semantic + keyword)
results = await graphiti.search(
    query="Project X timeline",
    search_type="hybrid"
)

# Graph traversal
results = await graphiti.search(
    query="people connected to Project X",
    search_type="graph"
)
```

### Temporal Queries

```python
# Query state at a specific point in time
results = await graphiti.search(
    query="What was the project status?",
    as_of=datetime(2024, 1, 15)
)
```

## Architecture

### Nodes

Entities extracted from episodes:
- People, organizations, projects
- Concepts, events, locations
- Custom entity types

### Edges

Relationships with temporal metadata:
- Type (e.g., "works_on", "reported_to")
- Valid_from / valid_to timestamps
- Source episode reference

### Episodes

Input data with context:
- Conversation transcripts
- Document content
- Event logs
- Any structured or unstructured data

## MCP Server Integration

Graphiti provides an MCP server for Claude, Cursor, and other MCP clients:

```json
{
  "mcpServers": {
    "graphiti": {
      "command": "uvx",
      "args": ["graphiti-mcp"]
    }
  }
}
```

Available tools:
- `graphiti_add_episode` — Add new information
- `graphiti_search` — Query the knowledge graph
- `graphiti_get_entity` — Retrieve specific entity
- `graphiti_get_relationships` — Get entity connections

## Use Cases

### Agentic Memory

Give agents persistent, queryable memory:
```python
# Agent remembers past interactions
context = await graphiti.search(
    query=f"What do I know about {user_name}?"
)
```

### Business Context

Integrate enterprise data:
- User interactions and preferences
- Project status and relationships
- Team structures and responsibilities

### State-Based Reasoning

Enable complex reasoning:
```python
# Query evolution over time
history = await graphiti.search(
    query="How has the project scope changed?",
    include_history=True
)
```

## Key Design Principles

- **Incremental by design** — No full recomputation on updates
- **Temporal awareness** — First-class support for time-based queries
- **Multi-modal retrieval** — Semantic, keyword, and graph search
- **Agent-first** — Built for AI agent memory and reasoning
- **MCP-native** — Easy integration with Claude and other assistants
