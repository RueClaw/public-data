# Pattern: Importance-Scored History Trimming

> **Source:** [ImTheMars/koda](https://github.com/ImTheMars/koda) (MIT License)

## Problem

When conversation history exceeds the context window, naively dropping the oldest messages loses important decisions, preferences, and context while keeping trivial "ok" / "thanks" exchanges.

## Solution

Score each message by importance heuristics, keep the highest-value messages within budget, then re-sort to chronological order.

## Scoring Rules

| Signal | Score Modifier |
|--------|---------------|
| System messages (summaries) | +0.5 |
| Messages with tool usage | +0.3 |
| Decision/preference language ("decided", "let's go with", "I prefer") | +0.2 |
| Concrete facts (names, dates, numbers, dollar amounts) | +0.1 |
| Substantive content (>200 chars) | +0.1 |
| Last 5 messages (recency bonus) | +0.3 |
| Short acknowledgments ("ok", "thanks", "cool") | -0.3 |
| Base score | 0.5 |

All scores clamped to [0, 1].

## Algorithm

```
1. Score all messages using heuristics above
2. Sort by score descending (original index as tiebreaker)
3. Greedily select highest-scored messages until token budget filled
4. Re-sort selected messages back to chronological order
5. Return trimmed history
```

## Token Estimation

Uses 4-chars-per-token heuristic (avoids adding a tokenizer dependency). Good enough for budget allocation purposes.

## Context Window Budget Allocation

```
System prompt: 15%
Memory:        10%
Skills:        10%
History:       50%
Reserve:       15%  (response headroom)
```

## Why This Works

- Important context (decisions, facts, tool results) survives trimming
- Trivial exchanges are dropped first
- Recent messages always preserved (recency bonus)
- Summaries from prior compressions get highest priority
- Chronological order is restored after selection, so the LLM sees a coherent conversation
