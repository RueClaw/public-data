# Multi-AI Debate & Consensus Pattern

> **Source:** [claude-octopus](https://github.com/nyldn/claude-octopus) — skill-debate.md (adapted from AI Debate Hub by wolverin0)
> **License:** MIT
> **Extracted:** 2026-02-10

## Pattern

Pit multiple AI providers against each other in structured debate rounds, with one AI acting as both participant and moderator. The moderator synthesizes all perspectives into an actionable recommendation.

## Structure

```
     User Question
           │
     ┌─────▼──────┐
     │  ROUND N    │  (repeat 1-10 times)
     ├─────────────┤
     │ Provider A  │  independent analysis
     │ Provider B  │  independent analysis
     │ Moderator   │  independent analysis + moderation
     └─────┬──────┘
           │
     ┌─────▼──────┐
     │  SYNTHESIS  │
     │  Areas of agreement
     │  Areas of disagreement
     │  Recommended path forward
     └────────────┘
```

## Debate Styles

| Style | Default Rounds | Character |
|-------|---------------|-----------|
| quick | 1 | Fast first-pass |
| thorough | 3 | Deep exploration |
| adversarial | 3 | Providers challenge each other |
| collaborative | 2 | Build on each other's ideas |

## Quality Gates

Score each response (0-100) before proceeding:

| Metric | Weight | Criteria |
|--------|--------|---------|
| Length | 25 | 50-1000 words (substantive but concise) |
| Citations | 25 | References or sources present |
| Code Examples | 25 | Technical examples included |
| Engagement | 25 | Addresses other participants' specific points |

- **≥75**: Proceed
- **50-74**: Proceed with warning
- **<50**: Re-prompt for elaboration

## Synthesis Template

```markdown
# Final Synthesis: [Question]

## Perspectives
### Provider A: [Key points across all rounds]
### Provider B: [Key points across all rounds]
### Moderator: [Key points across all rounds]

## Areas of Agreement
[Where all participants converged]

## Areas of Disagreement
[Key points of contention and why]

## Recommended Path Forward
[Actionable recommendation based on all perspectives]

## Next Steps
[Concrete action items]
```

## When to Use

- **Architecture decisions** — get genuinely different reasoning styles
- **Security reviews** — adversarial style catches what one model misses
- **Technology selection** — each provider may have different training biases
- **Code review** — multiple perspectives find more issues

## Implementation Notes

- Store rounds as files (`rounds/r001_providerA.md`) for auditability
- Each provider gets the full context of previous rounds (not just summaries)
- The moderator writes their own analysis *before* synthesizing — they're a participant, not just an orchestrator
- Track costs per debate since multi-provider calls add up fast
