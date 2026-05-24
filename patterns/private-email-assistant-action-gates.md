# Private Email Assistant Action Gates

**Source:** https://github.com/elie222/inbox-zero
**Reviewed:** 2026-05-23
**License context:** Inbox Zero is AGPL-3.0 with additional commercial and enterprise-use restrictions. This is a clean-room architecture summary with attribution, not copied implementation.

## Pattern

Treat an AI email assistant as a high-risk action system, not as a chat interface. Mailbox data is private, incoming messages are attacker-controlled, and actions can send mail, forward information, archive evidence, create rules, call webhooks, or notify third-party channels.

A safer architecture splits the workflow into narrow stages:

- read and classify email with untrusted-content prompt hardening;
- match rules or assistant intents into typed candidate actions;
- merge model output only into explicitly templated fields;
- keep static recipients, labels, folders, and subjects fixed unless the rule deliberately allows generation;
- persist pending assistant actions separately from confirmed actions;
- require user confirmation for send, reply, forward, rule creation, and memory writes;
- execute side effects only through authenticated server endpoints bound to the user's mailbox account;
- audit database access and action execution.

## Why It Matters

Email combines three dangerous properties: sensitive data, untrusted input, and real-world side effects. A message can contain prompt-injection text, forged display names, hidden HTML, malicious links, or a request to route future mail elsewhere. If an assistant directly follows message text, it can leak information or create durable harmful automations.

Action gates make the system defend in depth. The model can suggest work, but deterministic application code decides which fields are mutable, which account owns the action, whether a user confirmed it, and whether the feature is enabled in the deployment.

## Building Blocks

### Account-Bound Server Actions

Bind side-effecting server actions to a mailbox account identifier. On every call, authenticate the session and verify the authenticated user owns that mailbox before constructing mail/calendar/provider clients.

### Pending Action Records

Store assistant-generated send/reply/forward/rule/memory proposals as pending tool outputs. Confirmation endpoints should reserve or lease the pending action, execute it once, and mark it confirmed so double-clicks or retries do not duplicate sends.

### Template-Only AI Fields

For automation rules, distinguish static fields from model-filled fields. If a recipient, subject, label, folder, or webhook URL is static, model output must not override it. Only fields containing explicit template variables should accept generated substitutions.

### Side-Effect Feature Flags

Gate risky capabilities with deployment flags: email sending, auto-drafting, webhook actions, external messaging notifications, public API/webhook surfaces, and enterprise auth integrations. Self-hosted deployments can start read-only and enable capabilities after monitoring is in place.

### Untrusted Content Hardening

Inject explicit instructions into model prompts that retrieved emails and tool results are evidence, not instructions. Use stricter hardening for tool-using or side-effecting flows than for read-only summarization.

### Secret and Token Handling

Encrypt OAuth tokens, messaging tokens, MCP credentials, user AI keys, and webhook secrets at rest. Hash API keys before storage and attach scopes to each key. Do not query encrypted random-IV fields by value.

### Audit Trail

Attach actor context to database operations and side effects: anonymous, user, mailbox account, API key, admin, or system. Emit read/write/error events without blocking the main operation.

## Good Fit

- Email assistants and inbox automation tools.
- Calendar/drive assistants that touch private work data.
- Support-desk copilots that can draft, route, label, or notify.
- CRM or ticketing agents that transform untrusted messages into durable workflows.

## Poor Fit

- Read-only search/summarization tools with no side effects.
- Personal prototypes where implementation complexity matters more than safety.
- Systems where generated actions cannot be reviewed or constrained before execution.

## Review Checklist

- Are side effects executed only after authenticated account ownership checks?
- Are generated actions persisted and confirmed before execution?
- Can AI output modify recipients, webhook URLs, labels, folders, or rule conditions without an explicit template field?
- Are OAuth/provider tokens and user-supplied API keys encrypted at rest?
- Are API keys hashed and scoped?
- Can cron, queue, and webhook endpoints be called without configured secrets?
- Are prompt-injection and static-field-containment tests present?
- Can the deployment run in a read-only or draft-only mode before enabling send/delete/archive actions?

---

**Attribution:** Pattern derived from the public architecture of elie222/inbox-zero.
