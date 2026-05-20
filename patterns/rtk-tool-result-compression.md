# RTK Tool Result Compression

- **Source:** https://github.com/decolua/9router
- **Author:** decolua and contributors
- **License:** MIT
- **Extracted from:** `open-sse/rtk/`
- **Reviewed:** 2026-05-19

## Pattern

Compress noisy coding-tool outputs before forwarding an LLM request upstream.

Agentic coding sessions often include large tool results: git diffs, grep hits, file listings, tree output, test logs, build output, repeated console logs, and search results. Much of that text is useful as evidence but wasteful as raw context. A local gateway can reduce token usage by detecting known output shapes and replacing them with smaller summaries before provider translation and routing.

9Router calls this layer RTK. The useful design is provider-agnostic: apply compression at the request-body level before translating to any target provider format.

## Where It Fits

Place the compression step before provider-specific translation:

1. Receive a local client request.
2. Detect tool-result content across supported message formats.
3. Skip error traces and unsupported shapes.
4. Apply a format-specific compressor when confidently detected.
5. Keep the original if compression fails, empties content, or grows the payload.
6. Continue with provider translation and routing.

This keeps the optimization local and reversible. Clients do not need to know which upstream model or provider will receive the final request.

## Message Shapes To Handle

At minimum, support the common agent/tool-result shapes:

- Claude-style content blocks with `type: "tool_result"`.
- OpenAI chat tool messages with `role: "tool"` and string content.
- OpenAI chat tool messages with array content blocks.
- OpenAI Responses `function_call_output` items.
- Tool-result arrays in client-specific formats, such as Kiro-style `conversationState`.

For each shape, only compress string text fields. Preserve unknown content blocks as-is.

## Filter Types

Useful compressors are specialized, not generic:

- **Git diff:** keep file names, hunk summaries, changed symbols, and representative lines.
- **Git status:** keep branch, dirty paths, staged/unstaged grouping, and conflict states.
- **Grep/search:** deduplicate paths and keep the most relevant matches.
- **File listings / tree:** collapse huge directory listings while keeping structure and important paths.
- **Find output:** group by directory or extension and cap long result sets.
- **Build/test logs:** keep failing sections, stack traces, summary counts, and warnings; trim repetitive passing output.
- **Repeated logs:** collapse duplicate lines with counts.
- **Numbered reads:** keep line-number anchors and requested regions.

The key is to preserve actionability, not to summarize everything into prose.

## Safety Rules

RTK's most important implementation choices are safety guards:

- Do not compress tool results marked as errors.
- Do not return an empty string.
- Do not replace the original if the compressed output is larger.
- Do not process tiny payloads where savings do not matter.
- Cap raw payload sizes to avoid expensive local processing on pathological inputs.
- Use auto-detection so unrecognized text passes through unchanged.
- Track bytes before/after and log which filters were used.

These rules make compression a conservative optimization rather than a hidden source of context loss.

## Minimal Pseudocode

```js
function maybeCompressToolText(text, stats) {
  if (text.length < MIN_COMPRESS_SIZE) return text;
  if (text.length > RAW_CAP) return text;

  const filter = autoDetectFilter(text);
  if (!filter) return text;

  const compressed = safeApply(filter, text);
  if (!compressed) return text;
  if (compressed.length === 0) return text;
  if (compressed.length >= text.length) return text;

  stats.saved += text.length - compressed.length;
  stats.filters.add(filter.name);
  return compressed;
}
```

## Why It Matters

Tool-result compression is more useful than generic conversation summarization for coding agents because it acts on structured, high-volume evidence at the point where waste enters the prompt. It can reduce cost and context pressure while preserving the raw information classes the model needs: failing lines, changed files, commands, paths, stack traces, and search hits.

This pattern is especially useful in:

- Local AI gateways.
- Multi-provider agent routers.
- Coding tools with expensive long-context models.
- Systems that replay tool-heavy transcripts across fallback providers.
- Background agents that frequently inspect large repos.

## Implementation Notes

Keep the compression layer boring and auditable. Each filter should be deterministic, testable, and explainable. Avoid model-generated summaries inside the compression path; they add latency, cost, and another failure mode. The gateway should be able to log exactly what class of reducer changed the request and how much it saved.

Do not use this for security redaction. Compression and redaction have different guarantees. Sensitive data handling should happen in a separate policy layer.
