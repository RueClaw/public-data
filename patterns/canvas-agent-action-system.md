# Canvas Agent Action System

**Source:** https://github.com/tldraw/tldraw
**Reviewed:** 2026-05-23
**License context:** The tldraw SDK is source-available under the tldraw license; several starter templates are MIT. This is a clean-room pattern summary with attribution, not copied implementation.

## Pattern

Give an AI agent a structured way to see and manipulate a visual canvas: collect both visual and structured context, expose a typed action vocabulary, validate and sanitize streamed model output before applying it, separate agent modes by capability, keep state managers focused, and render partial progress live so users can watch and interrupt work.

The important move is that the model does not directly mutate arbitrary canvas internals. It proposes typed actions, and the application translates those actions into safe editor operations.

## Why It Matters

Visual work needs both spatial understanding and exact object state. Screenshots alone give layout but lose IDs, text, relationships, and coordinates. Raw object JSON gives precision but misses visual gestalt. Combining both lets an agent understand diagrams, sketches, annotations, and UI mockups more reliably.

Typed actions then keep the write path controllable. The agent can create, update, delete, align, distribute, stack, resize, draw, count, inspect, or move the viewport, but only through operations the host application has intentionally exposed.

## Building Blocks

### Context Parts

Represent each kind of agent-visible context as a small provider: user message, selected shapes, viewport screenshot, simplified shape records, outside-viewport clusters, recent actions, lints, and chat/task history. Each context part should have a priority and serializer so prompt assembly is deterministic.

### Action Utilities

Represent each model-writeable operation as a typed action utility with an action schema, model-facing title/description, streaming behavior, validation, sanitization, apply function, and chat/activity presentation. Common sanitizers include fixing nonexistent IDs, generating unique IDs, normalizing coordinates, bounding sizes, and refusing unsafe external operations.

### Modes

Define modes as sets of enabled context parts and actions. A working mode may have broad write access, while critique, planning, and cleanup modes can narrow the agent to safer capabilities.

### State Managers

Split agent state into focused managers: chat history, model/provider, contextual shapes, todo list, mode state, pending streamed actions, and cancellation/retry state.

## Safety Notes

- Keep the action schema smaller than the full editor API.
- Validate all shape IDs and coordinates before applying model output.
- Keep external API calls behind explicit action types and app-owned server routes.
- Prefer read-only context modes for review/analysis tasks.
- Make cancellation visible and fast.
- Record enough history to undo or replay the agent changes.

## Good Fit

- Diagram generators and reviewers.
- UI mockup tools.
- Visual programming/workflow builders.
- Whiteboard assistants.
- Canvas-backed chat and research tools.
- Spatial planning or annotation interfaces.

## Poor Fit

- Simple forms or CRUD apps where a canvas adds unnecessary complexity.
- High-stakes editing without undo/review gates.
- Apps that cannot safely expose a deterministic action subset.

---

**Attribution:** Pattern derived from tldraw public docs, templates, and agent/MCP architecture.
