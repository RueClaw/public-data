# 12-Factor Agents

**Source:** https://github.com/humanlayer/12-factor-agents  
**Reviewed:** 2026-05-23  
**License:** Apache-2.0 code, CC BY-SA 4.0 content per README badges  
**Verdict:** 📚 Study

12-Factor Agents is a principles guide for building reliable LLM-powered software. It argues against treating agents as opaque framework loops and instead frames production agents as mostly normal software: owned prompts, owned context, structured outputs, durable state, explicit control flow, small focused agents, simple launch/resume APIs, and human contact as a tool boundary.

## What It Is

The main artifact is a Markdown guide with diagrams and workshop material. It is closer to a design handbook than an application. The repo includes:

- `README.md` with the full 12-factor overview.
- `content/` with individual factor writeups.
- `workshops/` with TypeScript/BAML and Python notebook examples.
- `packages/walkthroughgen/`, a small TypeScript walkthrough generator with Jest tests.
- `drafts/a2h-spec.md`, an early Agent-to-Human protocol sketch.

## The 12 Factors

1. Natural language to tool calls.
2. Own your prompts.
3. Own your context window.
4. Tools are just structured outputs.
5. Unify execution state and business state.
6. Launch, pause, and resume with simple APIs.
7. Contact humans with tool calls.
8. Own your control flow.
9. Compact errors into the context window.
10. Use small, focused agents.
11. Trigger from anywhere.
12. Make the agent a stateless reducer.

The strongest through-line is control. The guide repeatedly pushes agent builders to own the thread format, prompt templates, structured outputs, execution transitions, and persistence model instead of hiding them inside a framework.

## Good Patterns

- Treat tool calls as structured model outputs that deterministic code may interpret, validate, route, delay, or refuse.
- Make the agent thread the core state record, so pause/resume/debug/fork operations are ordinary state operations.
- Compact noisy errors before returning them to the model.
- Split complex systems into small agents with narrow state and narrow authority.
- Model human approval/contact as a first-class tool, not an out-of-band exception.
- Keep triggers external: UI, webhooks, cron, queues, and other agents should all be able to resume the same run model.

## Caveats

- This is guidance, not a library or runtime.
- Some one-line duplicate factor files exist beside the canonical zero-padded content files.
- Workshop examples require provider credentials for full execution.
- The README includes a Scarf tracking pixel.
- The workshop/generator dependency trees need hygiene before reuse in production examples.

## Verification

Checked at commit `d20c728368bf9c189d6d7aab704744decb6ec0cc`.

- `packages/walkthroughgen`: `npm install` and `npm test -- --runInBand` passed: 20 tests.
- `packages/walkthroughgen`: `npm audit --audit-level moderate` reported 5 vulnerabilities: 1 low, 2 moderate, 2 high.
- `workshops/2025-07-16`: `uv sync --all-extras --dev` passed and `uv run python -m compileall -q .` passed.
- `workshops/2025-07-16/test_notebook_colab_sim.sh workshop_final.ipynb` failed at the live OpenAI/BAML call because no valid API key was available.
- `workshops/2025-07-16`: `pip-audit` reported 47 known vulnerabilities across 14 packages.

## Reuse

This is one of the clearer public writeups on production agent architecture. The best reuse is conceptual: turn the 12 factors into design-review criteria for agent features before choosing frameworks or adding autonomous loops.

See also: [12-factor-agent-architecture.md](../patterns/12-factor-agent-architecture.md).

