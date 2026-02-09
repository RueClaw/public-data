# Pattern: Subconscious Innovation Loop

> **Source:** [ImTheMars/koda](https://github.com/ImTheMars/koda) (MIT License)

## The Idea

An autonomous background loop that periodically prompts the agent to run small experiments, research new techniques, or optimize itself — without user initiation.

## How It Works

1. A timer fires at random intervals (30-60 min) to avoid predictable resource spikes
2. Reads `SUBCONSCIOUS.md` — a persistent file tracking past experiments and findings
3. Injects a synthetic message into the agent's message bus
4. The agent processes it with full tool access (search, filesystem, memory, sub-agents)
5. Results are appended to SUBCONSCIOUS.md
6. Subconscious content is only injected into the system prompt when the user's query relates to ideas/improvements (keyword detection), keeping normal conversations lean

## The Prompts

**Empty subconscious (first run):**
```
[SUBCONSCIOUS SURFACING]

Your subconscious is empty. It's time to innovate.

Perform one small experiment or optimization. Ideas:
- research a new technique or tool that could help the user
- analyze your own recent performance and identify an improvement
- explore a creative idea and document your findings
- review your skills and suggest a new one to create

Update your SUBCONSCIOUS.md with the result using the updateSubconscious tool.
```

**With existing context:**
```
[SUBCONSCIOUS SURFACING]

Based on your current subconscious memory:
---
${memory}
---

Choose one innovation, lesson, or experiment to act upon right now.
Complete the task and update your subconscious with new findings using the updateSubconscious tool.
```

## Why This Is Interesting

- Agents typically only act when prompted. This gives them a form of "idle curiosity"
- Random intervals prevent bursty resource usage
- The persistent file creates cumulative learning across sessions
- Conditional injection keeps it from bloating every conversation
- Could be extended with quality scoring to prune low-value experiments over time

## Considerations

- Cost control is important — each trigger consumes tokens
- The 60-second initial delay lets the system stabilize before the first trigger
- Focus mode integration: subconscious triggers are held during focus periods
