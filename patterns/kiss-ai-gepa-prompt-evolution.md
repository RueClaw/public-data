# GEPA: Genetic-Pareto Prompt Evolution Pattern

> Extracted from [KISS AI](https://github.com/ksenxx/kiss_ai) by Koushik Sen (Apache-2.0)
> Based on paper: ["GEPA: Reflective Prompt Evolution Can Outperform Reinforcement Learning"](https://arxiv.org/pdf/2507.19457)

## Core Idea

Evolve prompts using natural language reflection instead of gradient-based optimization. Maintain a Pareto frontier of prompts where each prompt is "best" for at least one validation instance.

## Algorithm

```
1. Split training data into dev (feedback) and val (selection) sets
2. Initialize population with the starting prompt
3. For each generation:
   a. SELECT parent prompt (weighted by number of val instance wins)
   b. EVALUATE parent on dev minibatch, collect agent trajectories
   c. SKIP mutation if parent achieves perfect score on minibatch
   d. REFLECT: Ask LLM to propose improved prompt based on:
      - The current prompt
      - Dev scores and agent trajectories (tool calls, reasoning steps)
   e. GATE: Only accept mutation if it doesn't degrade on dev minibatch
   f. EVALUATE on val set for selection
   g. UPDATE instance-level Pareto frontier
   h. MERGE (optional): 3-way structural merge of complementary Pareto prompts
      - Find pairs with common ancestor + sufficient val overlap
      - Score complementarity (pairs excelling on different instances)
      - Use ancestry to determine merge (prefer changed prompts, resolve conflicts by score)
      - Accept if merged prompt doesn't degrade (5% tolerance)
```

## Key Design Decisions

1. **Dev/Val split prevents overfitting** — feedback comes from dev, selection from val
2. **Instance-level Pareto** — not just "best overall" but "best for each specific case"
3. **Trajectory-based reflection** — the LLM sees tool calls and reasoning, not just scores
4. **Mutation gating** — conservative: never accept a prompt that's worse on the minibatch
5. **Structural 3-way merge** — combines complementary prompts (one good at task A, another at task B) using ancestry tracking to resolve conflicts

## Why This Matters

Most prompt optimization is manual trial-and-error or simple hill climbing. GEPA introduces:
- **Population diversity** via Pareto frontier (not just one "best" prompt)
- **Principled combination** via structural merge
- **Overfitting protection** via dev/val split
- **Rich feedback** via trajectory analysis

The paper claims this outperforms RL-based prompt optimization while being simpler and more interpretable.

## Usage Pattern

```python
# Define: how to run your agent with a prompt
def agent_wrapper(prompt_template, arguments):
    agent = KISSAgent(name="My Agent")
    result = agent.run(model_name="gpt-4o-mini", prompt_template=prompt_template, arguments=arguments)
    return result, json.loads(agent.get_trajectory())

# Define: how to score the result
def evaluate(result):
    return {"success": 1.0 if meets_criteria(result) else 0.0}

# Evolve
gepa = GEPA(agent_wrapper=agent_wrapper, initial_prompt_template="...", evaluation_fn=evaluate)
best = gepa.optimize(train_examples=[...])
```
