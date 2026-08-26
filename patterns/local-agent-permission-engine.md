# Local Agent Permission Engine

**Source:** andrewyng/openworker
**License:** MIT
**Reviewed:** 2026-08-26
**Pattern Type:** Agent runtime safety architecture

## Pattern

Model-callable tools should carry an intrinsic risk class before user/session policy is applied. The runtime can then evaluate actions in a stable order:

1. Refuse hard safety floors.
2. Enforce read-only modes.
3. Scope filesystem writes to writable roots.
4. Route persistent authority to a human.
5. Apply carefully bounded allowlists and standing rules.
6. Ask the user or reviewer for anything else.

OpenWorker's useful split is:

```python
class RiskClass(str, Enum):
    READ = "read"
    EGRESS = "egress"
    WRITE_LOCAL = "write_local"
    EXEC = "exec"
    EXTERNAL = "external"
```

That taxonomy keeps very different hazards from collapsing into a single "write" bucket. A web search is egress even if it only returns text. A local file patch is not the same as sending mail. A scheduled-task update is dangerous because it persists authority beyond the current session.

## Why It Matters

Agent runtimes often start with a simple rule: reads are allowed, writes need approval, shell needs approval. That breaks down quickly once the agent can call SaaS tools, browse websites, schedule future work, edit its own config, or receive broad "always allow" clicks.

The stronger pattern is to treat permission as a layered policy engine:

- **Risk classification** says what a tool can do.
- **Mode** says what the current session allows.
- **Scope checks** say where filesystem actions may land.
- **Human-only floors** say which actions no reviewer/auto-mode may clear.
- **Standing rules** grant exact, task-owned external targets rather than broad connector authority.

## Borrowable Details

- Classify model-chosen web fetch/search as egress, not read.
- Treat connector writes as external side effects even when the connector implementation is local.
- Resolve every write target before auto-allowing; if the path cannot be located, fail closed to a human.
- Protect files that execute later, such as CI workflows and Git hooks, from auto-approve paths.
- Treat skill saving, scheduled-task creation, and scheduled-task mutation as persistent authority.
- Bind standing automation grants to exact connector targets like recipient, channel, or calendar, not to the whole connector.
- In auto-approve mode, let a reviewer clear routine approval cards, but keep persistent/deferred authority human-only.

## Caveats

This pattern is only as good as the tool metadata. Unknown MCP/plugin tools need conservative defaults, and risk overrides must not be able to relax built-in floors. The user interface also has to explain the grant precisely; otherwise exact-target rules become invisible ambient authority.

---

**Attribution:** andrewyng/openworker, MIT
