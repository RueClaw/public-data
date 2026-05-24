# Agent-Safe Social API CLI

**Source:** https://github.com/xdevplatform/xurl
**License:** MIT
**Extracted:** 2026-05-24

## Pattern

Expose social-media APIs to agents through a local CLI that separates credential setup from agent execution, returns structured output, and makes unsafe actions explicit.

The reusable structure:

1. Store credentials and tokens locally outside LLM context.
2. Provide a status command that reports configured auth without printing secrets.
3. Use shortcut commands for common actions so agents do not construct raw HTTP for routine tasks.
4. Keep raw API access available for advanced users, but route most agent workflows through safer verbs.
5. Mark secret-bearing flags as human-only setup paths, not agent-executable commands.
6. Avoid verbose request logging in agent sessions because it can expose Authorization headers.
7. Require human confirmation for posting, replying, DMs, follow/block/mute actions, and media uploads.

## Why It Matters

Social APIs are not just data sources. They can publish, delete, DM, follow, block, mute, bookmark, and upload media. A useful agent integration needs a stronger boundary than "the CLI can do it."

xurl's bundled skill demonstrates a good shape: it documents normal commands while explicitly forbidding the agent from reading the token store, asking for pasted credentials, using inline secret flags, or enabling verbose output.

## Implementation Notes

- Keep token storage file permissions restrictive.
- Make credential bootstrap a human/manual step.
- Prefer stable JSON output for every command.
- Include a read-only health/status command.
- Split commands by risk class: read/search, draft/prepare, publish/mutate.
- In agent-facing docs, list forbidden flags and forbidden files explicitly.
- Treat verbose/debug output as sensitive because it may include request headers.

## Non-Goals

This pattern does not make autonomous social posting safe by itself. It provides a tool boundary that still needs policy, approval, logging, and account-level scope controls.

---

**Attribution:** xdevplatform/xurl, MIT License.
