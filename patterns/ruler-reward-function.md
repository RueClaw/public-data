# Pattern: RULER — Zero-Shot Reward Functions via LLM-as-Judge

**Source:** [OpenPipe/ART](https://github.com/OpenPipe/ART) (MIT)
**Component:** `src/art/rewards/ruler.py`

## Core Idea

Instead of writing hand-crafted reward functions for RL training, use an LLM judge to rank multiple agent trajectories *relative to each other*. GRPO only needs relative scores within a group, so absolute scoring accuracy doesn't matter.

## How It Works

1. Run N agent trajectories for the same task
2. Extract common prefix (save tokens)
3. Pass all trajectories to LLM judge with rubric
4. Judge returns relative scores (0-1) for each trajectory
5. Scores feed into GRPO as rewards

## Default Rubric

```
- A trajectory that achieves its goal should always get a significantly 
  higher score than one that does not.
- More efficient goal achievement → higher score.
- Small differences → small score gaps. Large differences → large gaps.
- Partial credit for progress toward goal without completion.
```

## Why This Works

- Relative scoring is easier than absolute scoring for LLMs
- Judge extracts task understanding from system prompts in the trajectories
- No labeled data or domain expertise needed
- Works for any task describable in a system prompt

## Implementation Notes

- Uses `litellm.acompletion` for model-agnostic judge calls
- Default judge: `openai/o3` (most capable but expensive)
- Fast alternative: `openai/gpt-4o-mini`
- Response format: Pydantic model with trajectory_id, explanation, score
- Common prefix extraction reduces token cost significantly
