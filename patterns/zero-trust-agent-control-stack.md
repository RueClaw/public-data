# Zero Trust Agent Control Stack

**Source:** Zero Trust for AI Agents
**URL:** https://cdn.prod.website-files.com/6889473510b50328dbb70ae6/6a1611a04085d7cd3dadc924_Claude-eBook-Zero-Trust-for-AI-Agents-05182026.pdf
**Author:** Anthropic / Claude
**Reviewed:** 2026-05-30

## Pattern

Build agent deployments around hard security boundaries, not prompt-only rules or friction. The control stack starts with verifiable identity, constrains what the agent can do, validates every tool action, records enough trace evidence to reconstruct behavior, and keeps humans responsible for irreversible incident decisions.

The useful design test is simple: does the control make the attack impossible, or just tedious? Prefer controls that remove capability, expire authority, bind credentials, or make paths unreachable.

## Control Stack

1. **Cryptographic agent identity** — Give each agent instance a unique identity backed by keys, certificates, or hardware-bound credentials. Put that identity in logs, access requests, traces, and audit records.
2. **Short-lived credentials** — Use IDP-issued tokens with narrow scopes and automatic expiry. Treat static API keys in files, env vars, or shared service accounts as a known gap.
3. **Least agency** — Define what the agent may do, what it may never do, which tools it may call, how often, against which resources, and when a human must approve.
4. **Tool-side enforcement** — Do not rely on the model to self-police tool calls. Enforce allowlists, authentication, parameter schemas, range checks, and capability caps at the tool or gateway boundary.
5. **Identity-based isolation** — Make receiving services verify specific caller identities. Network segmentation is useful as a backstop, not as the primary boundary.
6. **Sandbox untrusted work** — Run agents that process untrusted input in restricted containers, microVMs, or other execution environments with limited file, process, and network access.
7. **Input and output controls** — Validate schemas and length, delimit untrusted content, detect known prompt-injection patterns, filter sensitive outputs, and require human approval for high-risk actions.
8. **Memory integrity** — Isolate memory by user/session, tag memory with source and conditions, hash stored items, validate integrity on retrieval, expire risky context, and quarantine suspicious memory.
9. **Configuration integrity** — Version agent configs, review changes, sign approved configs where possible, and prefer immutable deployments with rollback.
10. **Traceability and metrics** — Record request IDs, tool calls, decisions, privilege changes, memory reads/writes, and outputs. Measure dwell time from anomaly to human awareness and coverage for alerts investigated.
11. **Human-gated response** — Let models collect evidence, correlate events, draft notes, and prepare postmortems. Keep humans on containment, disclosure, and customer-communication decisions.

## Implementation Checklist

- Every agent has a distinct identity and lifecycle.
- Every credential expires and is scoped to the task.
- Every tool call is validated outside the model.
- Every external input is treated as untrusted.
- Every high-impact action has a defined escalation path.
- Every persisted memory item has source, integrity, and retention metadata.
- Every configuration change is reviewable and reversible.
- Every incident can be reconstructed from immutable logs or traces.
- Every automated defensive action has its own identity, scope, and audit trail.

## Good Uses

- Enterprise agent deployment reviews
- MCP server and plugin security checklists
- Coding-agent runtime hardening
- Browser/file/email tool gateways
- Agent memory and RAG store governance
- Incident-response design for autonomous systems

## Caveats

- This is a control pattern, not a compliance certification.
- Vendor product features should be treated as examples, not requirements.
- Small local deployments may need a lighter version, but the same boundary questions still apply.
- Prompt instructions are not security boundaries. Enforcement belongs in credentials, tools, runtimes, networks, and audit systems.

**Attribution:** Based on Anthropic / Claude, Zero Trust for AI Agents, https://cdn.prod.website-files.com/6889473510b50328dbb70ae6/6a1611a04085d7cd3dadc924_Claude-eBook-Zero-Trust-for-AI-Agents-05182026.pdf
