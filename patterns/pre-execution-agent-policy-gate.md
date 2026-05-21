# Pre-Execution Agent Policy Gate

**Source:** microsoft/agent-governance-toolkit
**Repo:** https://github.com/microsoft/agent-governance-toolkit
**License:** MIT
**Reviewed:** 2026-05-20

## Pattern

Put a deterministic policy decision between an agent and every side effect. The agent can propose a tool call, resource access, inter-agent message, or workflow step, but the runtime checks a structured context against policy before execution.

This is stronger than prompt-only safety. The model can be asked to follow rules, but the runtime still owns enforcement.

## Shape

1. Convert the pending action into structured context.
2. Evaluate context against priority-ordered policy rules.
3. Fail closed on policy engine errors.
4. Emit an audit entry containing policy, rule, action, context snapshot, and timestamp.
5. Execute only when the policy decision allows it.

AGT's Agent OS policy evaluator implements this shape with YAML/JSON policy documents, priority sorting, folder-scoped policy discovery, and optional OPA/Rego or Cedar backends.

## Why It Matters

Agents often fail at the boundary where language becomes action: shell commands, file writes, network calls, database access, tool invocation, and delegation. Prompt rules are advisory at that boundary. Policy gates are enforceable.

The useful abstraction is the context object. Instead of hard-coding one-off checks into tools, the runtime can evaluate a consistent record such as:

- agent identity
- tool/action name
- target resource
- requested arguments
- trust score or delegation depth
- environment
- human approval state
- data classification

## Good Uses

- Blocking dangerous tools for low-trust agents.
- Requiring approval for high-impact actions.
- Enforcing read-only behavior in sensitive paths.
- Preventing untrusted MCP tools from receiving secrets.
- Recording governance evidence for audit and incident review.

## Caveats

Policy languages are easy to overbuild. Start with a small allow/deny surface and a few high-impact rules. Add OPA, Cedar, trust scoring, or compliance mapping only when the simple policy gate is already working.

Policy gates also need tests. A rule that looks correct but fails open is worse than no rule because it creates false confidence.

---

**Attribution:** microsoft/agent-governance-toolkit, MIT
