# Self-Evolving Agent Pattern

> Extracted from [KISS AI](https://github.com/ksenxx/kiss_ai) by Koushik Sen (Apache-2.0)

## Core Idea

An agent that can **rewrite its own source code** through evolutionary optimization. The agent's implementation file is treated as a "code variant" that gets mutated, evaluated, and selected — Darwin applied to software agents.

## Architecture

```
AgentEvolver
├── Loads base agent source code (e.g., multi_agent.py)
├── Uses KISSEvolve (evolutionary algorithm framework)
│   ├── LLM-guided mutation: "improve this code for efficiency"
│   ├── LLM-guided crossover: combine two variants
│   ├── Island-based evolution (isolated subpopulations)
│   └── Novelty rejection sampling (avoid duplicates)
├── Evaluation suite: run variants against benchmark tasks
│   ├── Simple: fibonacci generation
│   ├── Medium: data pipeline
│   └── Long-horizon: full e-commerce backend, ML pipeline
└── Fitness = f(correctness, efficiency, budget_used)
```

## How It Works

1. **Load** the agent's source code as the initial "genome"
2. **Generate population** of code variants via LLM mutation
3. **Evaluate** each variant by actually running it against benchmark tasks in Docker
4. **Select** based on fitness (fewer LLM calls, lower budget, correct output)
5. **Evolve** through mutation and crossover for N generations
6. **Save** the best-performing variant back as the agent's source

## Key Design Decisions

- **Real execution evaluation**: Variants run actual tasks, not just static analysis
- **Docker isolation**: Evolved code runs in containers (safety)
- **Multi-dimensional fitness**: Balances correctness vs efficiency vs cost
- **Island model**: Multiple isolated subpopulations prevent premature convergence
- **Novelty rejection**: RAG-based similarity check prevents generating near-duplicate variants

## The "Relentless" Continuation Pattern

The RelentlessCodingAgent uses a complementary pattern for long-horizon tasks:

```
Sub-session 1: Work on task → hit step limit → report progress as JSON
  {"done": ["created db.sh with set/get/delete"], "next": ["add tests", "add docs"]}

Sub-session 2: Load progress → scan existing files → continue where left off
  - Deduplicates completed items
  - Adaptive step thresholds (more steps for sessions showing progress)
  - Auto-truncates long tool outputs to manage context

Sub-session N: Eventually completes or exhausts budget
```

This enables theoretically infinite-horizon tasks through structured handoff between bounded sessions.

## Why This Matters

Most agent frameworks treat the agent code as fixed. This pattern treats it as evolvable:
- Prompts evolve (via GEPA)
- Architecture evolves (via KISSEvolve on source code)
- Tool creation evolves (dynamic tool creation at runtime)

It's agents all the way down — LLMs improving LLM-based agents.

## Practical Considerations

- **Cost**: Evolution requires many evaluation runs (each running real tasks)
- **Safety**: Docker isolation is essential — evolved code could do anything
- **Convergence**: No guarantee the evolved agent is better; fitness function design is critical
- **Reproducibility**: LLM-based mutation is inherently stochastic
