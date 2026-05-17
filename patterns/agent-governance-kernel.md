# Agent Governance Kernel Pattern

**Source:** DecapodLabs/decapod  
**License:** MIT  
**Reviewed:** 2026-05-17  
**Use case:** Coding agents that need explicit intent capture, context shaping, boundary enforcement, and proof-backed completion.

---

## Pattern

Treat governance as a local callable kernel around an AI agent, not as a replacement agent.

The loop:

1. User gives intent to an agent.
2. Agent calls the governance kernel to clarify intent, choose context, and determine gates.
3. Agent performs model inference with shaped context.
4. Agent calls the governance kernel before touching risky areas or declaring completion.
5. Kernel emits validation results, proof artifacts, or a required next pass.

This separates model reasoning from project governance. The model can still generate plans and code, but a deterministic local tool owns the boundaries and evidence.

## Repo-Native State

Keep governance state in the repository:

    .governance/
      config.toml
      override.md
      generated/
        specs/
        context/
        artifacts/

The exact directory name is tool-specific. Decapod uses .decapod. The important property is that humans can inspect the files, review them in pull requests, and carry them across agent sessions.

## Why It Matters

Chat history is a weak control plane. It is hard to review, easy to lose, and difficult to enforce. A local governance kernel gives agents a stable source of truth for:

- what the user asked for
- what context is relevant
- which files or actions are protected
- which checks must pass
- what evidence proves completion

## Implementation Notes

- Make the kernel daemonless where possible. A CLI is easier to audit and run in CI than a hidden background service.
- Provide machine-readable APIs for agents, such as capabilities, preflight, impact, and rpc.
- Keep generated specs concise. Large constitutions or policy corpora need precise retrieval and citations.
- Treat proof artifacts as review material, not decorative logs.
- Fail closed around protected paths and external side effects.

## Related Tools

- **Decapod** — broad repo-local governance kernel.
- **Gait** — policy enforcement at the tool-call boundary.
- **Spec Kit** — spec-driven development scaffolding.
- **Citadel** — campaign persistence and orchestration for Claude Code.

---

**Attribution:** Pattern derived from DecapodLabs/decapod, MIT.
