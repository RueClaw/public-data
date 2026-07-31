# Trajectory-Aware Model Routing

**Source:** codejunkie99/sageroute  
**Repo:** https://github.com/codejunkie99/sageroute  
**License:** MIT  
**Reviewed:** 2026-07-30  

## Pattern

Route agent sessions by execution trajectory rather than prompt-time difficulty guesses. Start on a low-cost model, recover factual evidence from tool calls and tool outputs, compute deterministic stuck/progress signals, and escalate to a stronger model only when the run proves it needs more capability.

The router should observe what the agent did:

- tool calls issued
- tool outputs received
- explicit success flags when available
- failed command/test output
- repeated error classes
- write/test/write/test cycles
- loops and ping-pong actions
- successful verification steps
- cost and budget burn

It should not trust raw assistant narration as progress evidence.

## Core Structure

1. Accept requests through the same wire an agent harness already uses.
2. Recover a stable session id from an explicit conversation key, parent-thread header, or task digest.
3. Pair tool calls and outputs by call id.
4. Reduce arguments and outputs to bounded previews, hashes, success flags, and error classes.
5. Compute deterministic signals before any model/judge call.
6. Consult an external or local decision policy only at configured checkpoints.
7. Apply a one-way ladder: continue, switch to stronger model, clean restart, or human escalation.
8. Rewrite only the concrete upstream model before dispatch.
9. Meter actual token usage after the response completes, including streaming final-usage frames.
10. Return routing headers or operator-visible state so decisions are auditable.

## Design Rules

Separate the pure routing core from the proxy shell. Evidence extraction, signal computation, policy, and session state should be testable without HTTP, credentials, live providers, or network calls.

Use transparent local guardrails around the judge. Budget hard stops, max switches, max restarts, hysteresis, and no-demotion rules should be deterministic policy, not delegated to a model.

Prefer capability before retry. If a run is failing on the cheap tier and a clean restart is proposed, first switch to a stronger model unless the switch budget is exhausted. A weak model with fresh context is still a weak model.

Trim polluted context carefully. On restart, drop assistant narration and provider-specific reasoning blobs, but preserve the user task, tool calls, and real tool outputs so the next model inherits facts rather than stale self-talk.

Expose decisions on the wire. Headers such as selected model, tier, action, session id, checkpoint status, decision source, and intervention probability make routing debuggable without log access.

## Why It Works

Agent task difficulty is often invisible from the initial prompt. Easy-looking tasks can reveal deep dependency or architecture problems after the first test run, while scary prompts sometimes resolve with one targeted edit.

The request body already carries the agent's execution history in many modern harnesses. A proxy can use that history without requiring SDK callbacks or harness-specific plugins. That makes trajectory-aware routing deployable as an endpoint rather than a framework rewrite.

## Caveats

The signal layer is only as good as the tool-call history it receives. Chat formats that flatten or drop tool outputs cannot support the same routing quality.

Text-based failure classification is useful but imperfect. Prefer explicit tool success fields when the client provides them, and keep the heuristics inspectable.

This pattern is not a sandbox. A model router can reduce cost and recover stuck runs, but it does not constrain what tools the agent may call or what secrets the proxy can forward.

External judge dependencies need fail-open or fail-closed policy chosen deliberately. For coding-agent productivity, fail-open may be acceptable; for regulated or high-cost workloads, fail-closed may be safer.

---

**Attribution:** Based on codejunkie99/sageroute, MIT License.
