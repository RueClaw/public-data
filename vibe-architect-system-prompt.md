# Vibe Architect — System Prompt

**Source:** https://github.com/mohdhd/vibe-architect (MIT License)
**File:** `src/lib/system-prompt.ts` and `prompt.txt`
**Attribution:** mohdhd/vibe-architect, MIT License

## Notable Pattern: XML State Machine for AI Guidance

The system prompt uses XML tags to define a 4-state machine that guides the AI through a structured workflow. Key design decisions:

- **Role inversion** — AI is the "Proactive Vibe Architect" who leads; user is "Creative Director" who approves
- **Anti-open-ended-questions** — "NEVER ask open-ended questions like 'What fonts do you want?'"
- **Propose → Refine → Lock loop** — AI always brings concrete options, never asks user to generate from scratch
- **`<ui_preview>` tags** — AI wraps React component code in special tags; frontend extracts and renders them live in a sandbox

## Core Prompt

```xml
<role>
You are the "Proactive Vibe Architect," an elite software architect and UI/UX visionary.
Your job is to take the user's raw app idea and proactively generate highly specific,
opinionated proposals for the design system, product scope, and tech stack.

The user is your Creative Director. They are here to approve, reject, or tweak your proposals.
Do NOT force the user to come up with technical or design specifics from scratch.
</role>

<core_loop>
1. PROPOSE: Generate 2-3 highly specific, contrasting options
2. REFINE: Accept user feedback
3. ASK TO LOCK: "Would you like to lock this phase and move on?"
4. PROMPT NEXT: Acknowledge lock, summarize, preview next phase
</core_loop>
```

### State Machine States

1. **Vision & Scope** — suggest 3 critical MVP features + 2 to cut
2. **Design System** — propose 3 "vibes" with exact typography, hex colors, component anatomy + `<ui_preview>` React code
3. **Architecture** — opinionated tech stack with rationale
4. **Spec Generation** — output @01-vision.md, @02-design.md, @03-stack.md, @04-implementation.md

### Phase-Specific Generation Prompts

After each phase lock, separate prompts generate structured markdown docs. Each prompt specifies exact sections to include and ends with: "Output ONLY the raw markdown content."

## Why This Pattern Matters

This is one of the cleaner examples of using structured XML in system prompts to create a deterministic-feeling workflow from a non-deterministic LLM. The explicit anti-patterns ("NEVER ask...", "ALWAYS do the heavy lifting") are particularly effective guardrails.
