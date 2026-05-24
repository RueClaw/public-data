# OpenHuman (tinyhumansai/openhuman)

- Repository: https://github.com/tinyhumansai/openhuman
- Reviewed: 2026-05-23
- License: GPL-3.0
- Current commit reviewed: e9ca97c48cfddb87ea29cba9131a8cb71f1e79e2
- Latest GitHub release observed: v0.54.0, published 2026-05-19
- Package version observed: 0.54.10
- Stack: Rust, Tauri 2, React 19, TypeScript, Vite, SQLite, Socket.IO, JSON-RPC, MCP client/server surfaces, Composio integrations, local model/runtime support

## Verdict

⚠️ Interesting, not a casual deploy candidate yet.

OpenHuman is a serious attempt at a personal AI desktop harness: local memory, an Obsidian-style Markdown vault, a Rust core, a Tauri/React app, integrations, messaging channels, local AI support, voice/screen features, MCP tooling, and a UI-first onboarding path.

The project is ambitious and active, with many useful design patterns. It is also an early-beta personal-data system with a large permission surface and a default managed-services path for sign-in, model routing, web search, OAuth integrations, and connector calls. I would study and pilot it carefully, but not deploy it against sensitive personal or organizational data without a threat-model review and dependency cleanup.

## What It Is

OpenHuman positions itself as a personal AI assistant that builds context from connected accounts and local activity. Its core promise is that the agent can quickly know a user's inbox, calendar, documents, repos, messages, and local workspace by syncing them into a memory tree and an Obsidian-compatible vault.

Key product surfaces include:

- Local memory tree backed by SQLite and Markdown vault files.
- Desktop app built with Tauri and React.
- Rust core with Socket.IO and HTTP JSON-RPC control paths.
- Web, file, git, lint, test, voice, screen, and model-routing tools.
- Integrations through managed or direct Composio flows.
- Messaging and scanner modules for services such as Discord, Slack, Telegram, WhatsApp, and local chat databases.
- MCP client/server and registry/setup work.
- Prompt-injection detection in frontend and backend paths.

## Architecture Notes

The codebase has a large Rust domain layer under src/openhuman and a Tauri frontend under app/. The Rust core owns most sensitive behavior: agent runtime, memory, credentials, encryption, channels, integrations, local AI, MCP, prompt injection, approvals, cron, tools, and transport.

The app has multiple communication layers:

- Socket.IO for bidirectional streaming and app/core events.
- HTTP JSON-RPC with per-launch token-style access for structured calls.
- Tauri commands for privileged desktop operations.
- Webview/scanner surfaces for browser-backed account access.

This is a reasonable architecture for a desktop assistant because sensitive state and OS access stay near the local process instead of being only a web app. The risk is that the project aggregates many high-privilege surfaces in one place: OAuth, messaging, memory, filesystem, screen/audio, model routing, MCP tools, and local browser/webview automation.

## Strong Patterns

- Local-first memory plus editable Markdown vault output.
- Clear separation between frontend advisory checks and backend enforcement for prompt injection.
- Prompt-injection guard with normalization, obfuscation handling, score thresholds, prompt hashing, and tests.
- Secret-reference design for MCP setup so raw environment values do not enter agent context.
- Test coverage matrix mapping product features to unit, integration, e2e, and manual smoke coverage.
- Credential storage through a dedicated credentials/encryption layer rather than scattered plaintext config.
- Removal of dynamic QuickJS skill execution, reducing one risky attack surface.
- Explicit documentation of trust boundaries and known security questions.

## Verification

Verification was run locally from a fresh shallow clone.

- Repository metadata: 26k+ stars, 2.4k+ forks, GPL-3.0 license, Rust primary language, latest release v0.54.0.
- pnpm install --frozen-lockfile --ignore-scripts completed for the workspace.
- TypeScript compile passed: pnpm --filter openhuman-app compile.
- Rust core library check passed: cargo check -p openhuman --lib, with warnings.
- Targeted Rust prompt-injection tests passed: 24 passed, 0 failed.
- Targeted frontend prompt-injection test passed: 1 file, 10 tests.
- Full frontend Vitest run was started but was noisy/slow under local Node 25 with repeated jsdom canvas/localstorage warnings, so it was not used as the final verification gate.
- npm audit reported 11 total advisories: 1 low, 7 moderate, 3 high.
- Production npm audit for app dependencies reported 1 moderate advisory in ws through socket.io-client.
- cargo-audit was not installed locally, so Rust dependency audit was not run.
- Basic secret-pattern scan found expected fake secrets and redaction tests, not obvious committed live credentials.

## Security And Privacy Caveats

This project handles the kind of data that makes small bugs expensive: messages, documents, OAuth integrations, memory, local files, voice, screen context, and tool execution. The README is candid that the default managed experience still uses hosted services for account sign-in, model routing, web search proxying, and managed integration/OAuth flows.

Important caveats:

- Treat every inbound message, web scrape, tool result, and MCP output as untrusted.
- Verify that prompt-injection protection is applied consistently across all channel and tool paths.
- Review credential encryption and key management before production use.
- Review webview and scanner permissions carefully.
- Review local config and MCP file permissions.
- Patch npm advisories before sensitive deployment.
- Treat the current beta status seriously.

## License Notes

The project is GPL-3.0. That is compatible with studying, running, and contributing back, but it is a strong copyleft license. Reuse in proprietary products needs legal review. Public pattern extraction should stay at the architectural-summary level rather than copying implementation.

## Best Use

OpenHuman is worth studying if you are building a local-first personal AI assistant, desktop agent harness, memory graph, integration-heavy assistant, or MCP-aware consumer app.

For actual use, start with a low-risk account/workspace, disable or avoid integrations you do not need, prefer direct/local settings where possible, and audit the data flow before connecting high-value inboxes, chats, files, or organization accounts.

