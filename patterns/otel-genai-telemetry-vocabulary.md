# OpenTelemetry GenAI Telemetry Vocabulary

**Source:** open-telemetry/semantic-conventions-genai  
**License:** Apache-2.0  
**Review:** [semantic-conventions-genai.md](../reviews/semantic-conventions-genai.md)

## Pattern

Model GenAI observability as a layered OpenTelemetry vocabulary instead of a single "LLM call" span.

Use separate signal families for:

- model/client operations: inference, embeddings, retrieval, response fetch, memory
- agent operations: create agent, invoke agent, plan, invoke workflow, execute tool
- token and latency metrics: usage, duration, time to first chunk/token, time per chunk/token
- tool and workflow metrics: calls, duration, inference calls per agent invocation
- rich content events and attributes: messages, system instructions, tool definitions, tool arguments/results, retrieval documents, memory records
- provider overlays: provider-specific attributes that refine the common GenAI shape
- MCP transport semantics: JSON-RPC method/session/resource attributes plus W3C trace context propagation through request metadata

## Why It Works

Agent systems are made of multiple observable layers. A useful trace needs to show when an app invoked a model, when an agent planned, when it called a tool, when it retrieved or wrote memory, and when a workflow wrapped several of those actions. Flattening that into one span loses the parts operators actually debug.

The OpenTelemetry GenAI repo also separates sensitive content from default telemetry. High-risk values such as prompts, outputs, system instructions, tool definitions, tool arguments, retrieval documents, and memory records should be opt-in, filterable, and clearly marked as sensitive.

## Implementation Shape

```text
application request
  -> gen_ai.invoke_agent.* span
    -> gen_ai.plan.internal span
    -> gen_ai.inference.client span(s)
    -> gen_ai.retrieval.client span(s)
    -> gen_ai.execute_tool.internal span(s)
    -> gen_ai.memory.client span(s)
  -> gen_ai.invoke_agent.duration metric
  -> gen_ai.invoke_agent.inference_calls metric
  -> gen_ai.invoke_agent.tool_calls metric
  -> opt-in content events/attributes only when explicitly enabled
```

For MCP, propagate W3C context inside JSON-RPC request metadata and avoid treating the underlying HTTP request as the whole logical operation:

```json
{
  "jsonrpc": "2.0",
  "method": "tools/call",
  "params": {
    "name": "get-weather",
    "_meta": {
      "traceparent": "00-4bf92f3577b34da6a3ce929d0e0e4736-00f067aa0ba902b7-01"
    }
  },
  "id": 1
}
```

## Borrowing Notes

- Treat `gen_ai.provider.name`, `gen_ai.operation.name`, model names, server address/port, and agent names as sampling-relevant fields that should be available early.
- Never synthesize fake conversation IDs from trace IDs or content hashes; leave `gen_ai.conversation.id` unset when no real conversation identifier exists.
- Report billable token counts when providers expose both consumed and billed token units.
- Keep content capture off by default and make truncation/redaction policy explicit.
- For MCP tool calls, add MCP attributes to an existing GenAI tool span when reliable detection is possible instead of double-spanning the same tool execution.

---

**Attribution:** open-telemetry/semantic-conventions-genai, Apache-2.0
