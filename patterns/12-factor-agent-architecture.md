# 12-Factor Agent Architecture

**Inspired by:** humanlayer/12-factor-agents  
**Use when:** designing an LLM feature that must be reliable enough for production users.

## Pattern

Build agents as explicit software systems, not as opaque prompt-plus-tools loops.

The practical checklist:

1. Translate user intent into typed next-step objects.
2. Own the prompt templates in source control.
3. Own the context format instead of blindly appending chat messages.
4. Treat tools as structured outputs that deterministic code validates and routes.
5. Store execution history and business state in one inspectable thread where practical.
6. Expose launch, pause, resume, and inspect APIs.
7. Make human contact and approval normal tool calls.
8. Keep control flow in application code when reliability matters.
9. Compress errors before returning them to the model.
10. Prefer small, focused agents over one broad agent.
11. Let external triggers resume the same run model.
12. Make each agent step a stateless reducer over current state.

## Why It Works

Opaque agent frameworks make the first demo easy and the last reliability gap hard. This pattern keeps the production-critical parts visible: prompts, state, control flow, validation, recovery, and handoff points.

## Design Review Questions

- Can the full run be replayed from stored state?
- Can a human inspect why the agent chose the next action?
- Is every tool call validated before side effects?
- Can the workflow pause for approval and resume from an external event?
- Are model-facing errors short, relevant, and actionable?
- Is this one agent doing too many unrelated jobs?

Use these questions before adding a framework. If the answer is no, the framework will usually hide the problem rather than solve it.

