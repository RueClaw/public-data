# IDE-Wired Agent Harness

**Source:** https://github.com/can1357/oh-my-pi
**Reviewed:** 2026-06-06
**License context:** Oh My Pi is MIT licensed. This pattern is a clean-room architecture summary with attribution.

## Pattern

Treat a coding agent as a real development-environment client, not a chat model with a shell.

The harness exposes narrow, typed tools for the operations developers already rely on: language-server diagnostics and renames, debugger sessions, snapshot-anchored edits, AST rewrites, structured subagent delegation, persistent eval kernels, browser control, internal documentation/resource URLs, and local memory. The model can still use a shell, but the shell is not the only path to every action.

## Why It Matters

Coding agents fail in predictable places: stale text patches, weak file moves, blind search, over-broad shell commands, noisy tool output, missing IDE context, repeated codebase rediscovery, and unstructured worker handoffs.

An IDE-wired harness moves those brittle actions into explicit interfaces. The agent asks for "rename this symbol" instead of simulating a rename through string edits. It asks DAP for variables instead of inserting print statements. It applies hash-anchored edits instead of trusting a stale text block. It delegates work to subagents that return structured outputs instead of dumping conversational summaries.

## Building Blocks

### Semantic Code Operations

Expose LSP actions such as diagnostics, definitions, references, hover, symbols, rename, file rename, code actions, capabilities, and raw requests. Route file moves through language-server rename hooks when available.

### Debugger As A Tool

Expose DAP launch/attach, breakpoints, stepping, stack frames, scopes, variables, expression evaluation, memory reads, and output. Keep mutating/debugger-control actions separated from read-only inspection actions for approval and audit.

### Snapshot-Anchored Edits

Require edits to reference the version of the file the model saw. Reject or recover when the live file no longer matches the snapshot, and preflight multi-file batches before writing partial changes.

### Preview Then Apply

For structural rewrites and other broad changes, produce a preview artifact first and require an explicit resolve/apply step. This gives the model and user a chance to inspect replacement counts and affected files.

### Filesystem-Shaped Resources

Let the same read/search interface handle local files, archives, docs, memory, PRs, issues, skills, rules, conflict markers, and subagent outputs. A smaller conceptual tool surface is easier for models to use correctly.

### Structured Subagent Results

Subagents should return schema-validated results that the parent can address by field/path. This avoids parsing informal prose when combining parallel work.

### Heuristic Local Memory

Inject memory as bounded, project-scoped guidance with instructions to verify against current repo state. Store durable memory locally and expose it through a read-only resource path before adding mutation tools.

## Good Fit

- Local coding-agent CLIs and editor-integrated agents.
- Agent platforms that need better reliability on code edits and refactors.
- Repositories where agents repeatedly need diagnostics, references, and debugger inspection.
- Multi-agent coding workflows that need structured delegation rather than chat summaries.

## Poor Fit

- Very small one-off scripts where shell/read/write is enough.
- Hosted agents that cannot run local LSP/DAP servers or native helpers.
- Environments where all tool calls must remain purely stateless.
- Highly locked-down deployments that cannot tolerate broad local execution capability.

## Review Checklist

- Are semantic operations exposed through LSP/DAP or equivalent APIs where possible?
- Are broad edits previewed or snapshot-anchored before disk mutation?
- Can stale file context be detected before applying a patch?
- Are internal resources addressable through a small number of familiar tool shapes?
- Are mutating actions separated from read-only inspection for approvals and logging?
- Do subagents return structured data instead of only prose?
- Does memory come with freshness warnings and current-state verification requirements?
- Are shell, browser, credential, and network capabilities clearly gated?

---

**Attribution:** Pattern derived from the public architecture of can1357/oh-my-pi.
