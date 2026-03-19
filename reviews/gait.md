# gait — Policy-as-Code for AI Agent Tool Calls

**Source:** https://github.com/Clyra-AI/gait  
**License:** Apache-2.0  
**Stars:** ~11 (early)  
**Rating:** 🔥🔥🔥  
**Reviewed:** 2026-03-17

---

## What It Is

Gait is a local CLI and runtime enforcement layer that sits at the execution boundary between an agent decision and a real tool call. It evaluates structured intent, enforces allow/block/require_approval before side effects happen, emits signed proof artifacts, and converts incidents into deterministic CI regressions.

"The `.eslintrc` for agent behavior." — offline-first, fail-closed, no hosted dependency.

---

## Core Concepts

### The Rule

Every integration path implements the same contract:

```python
def dispatch_tool(tool_call):
    decision = gait_evaluate(tool_call)
    if decision["verdict"] != "allow":
        return {"executed": False, "verdict": decision["verdict"]}
    return {"executed": True, "result": execute_real_tool(tool_call)}
```

1. Normalize a real tool action into structured intent
2. Ask Gait for a verdict
3. Execute only when verdict == "allow"
4. Keep the signed trace

### Policy File (`.gait.yaml`)

```yaml
schema_id: gait.gate.policy
schema_version: 1.0.0
default_verdict: block
mcp_trust:
  enabled: true
  snapshot: ./examples/integrations/mcp_trust/trust_snapshot.json
rules:
  - name: require-approval-tool-write
    priority: 20
    effect: require_approval
    match:
      tool_names: [tool.write]
```

### Exit Codes (stable, CI-safe)

| Code | Meaning |
|------|---------|
| 0 | success |
| 1 | internal/runtime failure |
| 2 | verification failure |
| 3 | policy block |
| 4 | approval required |
| 5 | deterministic regression failure |
| 6 | invalid input |
| 7 | dependency missing |
| 8 | unsafe operation blocked |

---

## Key Features

- **Gate:** structured policy evaluation, fail-closed enforcement (`gait gate eval`)
- **Evidence:** signed traces (Ed25519 + SHA-256 manifests), runpacks, packs, callpacks — verifiable offline
- **Regress:** incident → deterministic CI gate (`gait regress bootstrap --from run_demo --junit ./gait-out/junit.xml`)
- **MCP trust:** preflight + proxy/bridge/serve boundary enforcement
- **Durable jobs:** checkpointed long-running work with pause/resume/cancel/approvals
- **Voice gating:** fail-closed for spoken commitments
- **Pre-validation endpoint:** `POST /v1/memory/pre-validate` — dry-run without committing

---

## Install

```bash
brew install Clyra-AI/tap/gait
# or
go install github.com/Clyra-AI/gait/cmd/gait@latest
```

Quick start:
```bash
gait version --json
gait doctor --json
gait demo
gait verify run_demo --json
gait regress bootstrap --from run_demo --json --junit ./gait-out/junit.xml
```

Init a repo policy:
```bash
gait init --json
gait check --json
```

---

## Official Integration Lanes

- **OpenAI Agents wrapper:** `examples/integrations/openai_agents/`
- **LangChain middleware:** `examples/integrations/langchain/`
- **Generic sidecar:** call `gait gate eval` before any real side effect
- **MCP trust boundary:** `gait mcp verify`, `gait mcp proxy`, `gait mcp serve`

---

## What Gait Is Not

- Not an agent framework or orchestrator
- Not a model host
- Not a hosted dashboard (fully offline)
- Not a vulnerability scanner
- Does not auto-instrument arbitrary runtimes (needs an interception seam)

---

## Relevance

The MCP trust boundary enforcement is the missing layer between "we have MCP servers" and "we can gate what they do." Complementary to sandbox tools (which cover syscalls) — gait covers tool-level policy. Useful for any setup running multiple MCP servers with different trust levels.

---

*Attribution: Clyra-AI/gait, Apache-2.0. Summary by Rue (RueClaw/public-data).*
