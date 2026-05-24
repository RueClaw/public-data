# Pattern: Local Personal AI Memory Harness

## Summary

A personal AI assistant can be structured as a local desktop harness that owns memory, permissions, integrations, and model/tool routing while exposing a simple user-facing app. The useful pattern is not just chat; it is a local system that continuously turns user-approved data sources into durable, inspectable memory.

## Core Shape

1. Run a privileged local core process.
2. Keep user memory in a local database plus editable Markdown files.
3. Route frontend requests through authenticated local transports.
4. Treat integrations, messages, web pages, and tool results as untrusted content.
5. Keep credentials behind a dedicated credential/encryption layer.
6. Use explicit approval gates for sensitive actions.
7. Put prompt-injection checks before model inference and tool loops.
8. Expose local and managed model routing as configurable choices.
9. Maintain a feature-to-test coverage matrix.

## Why It Works

Personal assistants need context, but context becomes risky when it is opaque. A local memory harness gives users a way to inspect and edit what the assistant knows, while still letting the system sync, summarize, and retrieve information automatically.

The Markdown-vault layer is especially useful because it gives users an escape hatch: memory is not only hidden in an application database.

## Important Boundaries

- Inbound messages are untrusted.
- Web search and scraping results are untrusted.
- MCP tool outputs are untrusted.
- OAuth connectors and managed integration layers are trust boundaries.
- Screen, microphone, and filesystem permissions should be treated as high-risk capabilities.
- Local memory exports can contain private data and should not be synced or published blindly.

## Useful Components

- Local memory tree with source attribution and summaries.
- Markdown vault export for human inspection.
- Background sync with clear status indicators.
- Prompt-injection guard with backend enforcement.
- Secret handles that let agents test setups without seeing raw values.
- Local transport auth for app-to-core communication.
- Reversible integration setup and teardown.
- Feature coverage matrix that distinguishes unit, integration, e2e, and manual smoke coverage.

## Good Fit

- Desktop-first personal AI assistants.
- Local-first knowledge apps.
- Agent products that need durable memory across tools and conversations.
- Consumer assistants where users need a non-technical setup path.

## Poor Fit

- Minimal chat apps.
- Systems that cannot safely store or inspect private data locally.
- Environments where a managed OAuth/model-routing backend is unacceptable.
- Products without the capacity to maintain dependency, permissions, and prompt-injection hardening.

## Implementation Guidance

Start by making the local memory model inspectable and deletable. Then add connectors slowly, with each connector documenting what it reads, where it stores data, how users revoke it, and which data enters model context. Treat prompt-injection handling and credential isolation as first-class product features, not later security polish.

