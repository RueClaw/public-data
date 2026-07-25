# Tiny Tool-Call Model Finetune Loop

**Source:** [cactus-compute/needle](https://github.com/cactus-compute/needle)
**License:** MIT
**Extracted:** 2026-07-25

## Problem

Large LLMs are often wasteful when the task is only "choose the right tool and fill the arguments." Edge devices, mobile assistants, wearables, smart home nodes, and privacy-sensitive local agents need a much smaller component that can route commands without calling a cloud model for every simple action.

## Pattern

Train and wrap a tiny, narrow model for function calling only:

1. **Constrain the task.** The model emits JSON function calls, not free-form chat.
2. **Use a compact tool schema dialect.** Keep tool names, descriptions, argument keys, types, and required flags easy to serialize and easy to generate from.
3. **Build a small encoder-decoder around tool alignment.** Encode the query plus tool definitions, then decode only the call object.
4. **Spend parameters on attention.** For routing/copying tasks, prioritize query-to-tool and query-to-argument alignment over broad language capacity.
5. **Normalize tool names internally.** Convert tool names to a model-friendly format, then restore original names after generation.
6. **Mask constrained spans.** During decoding, constrain tool names and argument keys to known schema values while leaving argument values open.
7. **Generate per-tool examples.** Use synthetic or curated JSONL examples with fields like `query`, `tools`, and `answers`.
8. **Split per tool.** Keep train/validation/test examples for each tool so improvements are visible by tool, not only globally.
9. **Bundle artifacts.** Package checkpoint, tools, train/val/test data, and eval report together so a finetuned model can be audited later.

## Why It Works

Function calling is narrower than general reasoning. The model mostly has to match the user's request to a tool name, identify required arguments, copy or normalize values, and produce valid JSON. A tiny model can learn that local mapping if the schema surface is compact and the eval set is specific to the deployed tools.

Constrained decoding handles the part where small models are brittle: exact tool names and exact argument keys. That lets the model spend capacity on choosing tools and filling values while deterministic logic guards the schema boundary.

## Minimal Version

```text
tools = [
  { name, description, parameters: { arg_name: { type, description, required } } }
]

example = {
  query: "turn on the porch lights",
  tools: json.dumps(tools),
  answers: json.dumps([
    { name: "set_light", arguments: { room: "porch", enabled: true } }
  ])
}

train:
  split examples per tool
  finetune tiny encoder-decoder
  evaluate parse rate, call F1, name F1, exact match, args accuracy

inference:
  encode query + tools
  greedily decode JSON
  constrain tool names and argument keys
```

## Implementation Notes

- Treat checkpoint files as code if the serialization format can execute on load.
- Keep the schema dialect explicit. If callers use JSON Schema `properties`, convert it before constrained decoding.
- Report per-tool metrics; aggregate accuracy can hide a rarely used but high-risk tool failing.
- Keep side-effecting tools behind an outer approval or policy layer. A correct function call is not the same thing as permission to execute it.
- Use the tiny model as a router, not as the whole assistant. Let larger models or deterministic policy handle ambiguous, risky, or conversational turns.
- Preserve the generated training data and held-out test examples with the checkpoint for later regression checks.

## Good Fits

- wearable or mobile command routing
- smart home commands
- local voice assistant tool selection
- offline personal automation
- low-latency first-pass routing before a larger model
- user-specific custom tool packs

## Poor Fits

- open-ended chat
- multi-step planning without an outer controller
- high-risk actions without approval gates
- arbitrary untrusted tool schemas
- deployments that cannot sandbox model checkpoints

---

**Attribution:** cactus-compute/needle, MIT License.
