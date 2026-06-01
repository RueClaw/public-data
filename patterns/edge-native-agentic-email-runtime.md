# Edge-Native Agentic Email Runtime

**Source:** cloudflare/agentic-inbox  
**Repo:** https://github.com/cloudflare/agentic-inbox  
**License:** Apache-2.0  
**Reviewed:** 2026-05-31

## Pattern

Build an AI email client as a single edge-native runtime: inbound email, outbound delivery, mailbox state, attachment storage, user interface, agent chat, and MCP tools all live on the same serverless platform.

## Shape

```text
Email Routing
  -> Worker email handler
  -> mailbox Durable Object
  -> SQLite email/thread/folder state
  -> R2 attachment blobs
  -> React email UI
  -> mailbox-scoped AI agent
  -> shared email tools
  -> MCP endpoint
  -> Email Service send path
```

## Why It Works

Email is naturally partitioned by mailbox. A stateful object per mailbox gives the system a simple place to serialize writes, keep local SQLite state, enforce rate limits, store thread metadata, and attach an agent that can reason over the same mailbox.

The useful implementation details are:

- put all production traffic behind a platform identity layer before API, agent, or MCP routes;
- map each mailbox to a named stateful object rather than one shared database table;
- store attachment bytes in object storage and keep only metadata in mailbox state;
- centralize list/read/search/draft/send/move/delete operations in shared tool functions;
- expose the shared tool functions to both the in-app agent and MCP server;
- make the default agent draft-first and require a separate confirmation path for sending;
- render untrusted email HTML inside a sandboxed iframe and sanitize before injection;
- convert quoted original messages into escaped plain text before inserting them into compose views;
- scan untrusted email bodies and thread context before auto-drafting;
- keep custom mailbox prompts in settings, but treat them as privileged configuration.

## Implementation Notes

The most important design boundary is mailbox authorization. A shared access policy is enough for a single trusted operator or a demo, but multi-user use needs a mailbox-level permission check on every UI, API, agent, and MCP operation.

MCP needs special care because it often connects powerful external agents to the mail store. Draft tools are much safer than send tools. If send tools are exposed, require explicit confirmation, scoped credentials, logging, and a policy layer outside the model prompt.

## Caveats

Do not treat "draft-first" prompt instructions as a security boundary. Agent prompts, tool descriptions, and model behavior are advisory. Sending, deletion, mailbox enumeration, and prompt customization need code-level policy.

Dependency hygiene matters more than usual in an email client because stored messages and attachments are attacker-controlled input. Keep HTML sanitizers, routers, database libraries, and parsing dependencies current.

---

**Attribution:** Pattern extracted from cloudflare/agentic-inbox, Apache-2.0.
