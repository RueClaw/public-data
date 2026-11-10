# Grok Bot ↔ Telegram bridge (eladb/grokbot-telegram-bridge)

**Repo:** https://github.com/eladb/grokbot-telegram-bridge
**Author:** Elad Ben-Israel (eladb)
**License:** MIT; preserve copyright and permission notices when reusing substantial source.
**Reviewed:** 2026-11-10 (UTC)
**Revision:** 9aba89e59fe42ab807c0d2932c553752b5200e4b; entire repository: README.md, SKILL.md, relay.py, LICENSE.
**Verification:** Static review only; no source execution, dependencies installed, Telegram/provider calls, accounts, secrets, deployment, or integration tests.
**Stack:** Python 3 standard library; Telegram Bot API; externally supplied Grok Bot webhook and scheduled routines.
**What it is:** A 26-line inbound relay plus an agent setup recipe, not a self-contained AI bot or an xAI model client.

---

## Verdict

📚 **Study — clear transport workaround, insufficient boundaries for unattended group use.** Long polling solves the documented inability to attach a routine's Bearer header to Telegram webhooks. The repository leaves sender authorization, conversation isolation, action approval, durable delivery, and lifecycle management to prompts or an external runtime. Study the topology, not the default deployment posture.

## What It Is

The relay pulls Telegram updates and forwards their complete JSON to one configured webhook with a Bearer key. An external Grok Bot routine reads the update and sends replies directly using Telegram's API. The relay itself does not call a language model, execute incoming commands, download attachments, or send substantive replies. A separate thread sends typing notifications until a marker file appears or 60 seconds elapse.

The supplied skill describes bot creation, masked secret collection, a webhook prompt, background launch, and a periodic restart routine. These are instructions for a particular agent environment, not implemented provisioning or an independently reproducible hosted service. References to secret requests, automation_status, app-chat mirroring, and Auto-review depend on that environment; their behavior and protections are not present here. [README](https://github.com/eladb/grokbot-telegram-bridge/blob/9aba89e59fe42ab807c0d2932c553752b5200e4b/README.md), [setup recipe](https://github.com/eladb/grokbot-telegram-bridge/blob/9aba89e59fe42ab807c0d2932c553752b5200e4b/SKILL.md#L12-L31).

## Stack

| Layer | Implementation |
|---|---|
| Inbound | Telegram getUpdates, 50-second long poll |
| Forwarding | urllib.request POST of original update, Bearer authentication |
| Outbound | Agent instructed to call sendMessage/sendDocument/sendPhoto |
| State | In-memory offset; local reply-marker files; redirected text log |
| Execution | Python 3, JSON, threading, urllib; no third-party dependencies |
| Lifecycle | nohup plus an externally created scheduled agent routine |

## Key Features

- **Small, auditable transport:** complete relay fits in 26 lines; no package ecosystem or installer to trust. Compactness also omits nearly all production controls.
- **Typing handshake:** chat/message marker files stop repeated typing calls; timeout prevents indefinite notification loops, but not a blocked HTTP request from outlasting that window.
- **Operational notes:** the recipe explains BotFather privacy and supergroup ID migration, and suggests acknowledgement/progress responses. These are agent instructions rather than tested protocol implementations.

## Architecture and Security

### Authentication is not sender authorization

The webhook Bearer key authenticates the relay to the external routine. It does not authorize the Telegram sender. The only relay-side sender filter skips messages whose from.is_bot is true; there is no chat-ID allowlist, numeric sender-ID allowlist, command gate, mention requirement, private-chat restriction, or rate limit. Every delivered message or edited_message from other senders can wake the agent, including service messages that the prompt later asks it to ignore. Disabling BotFather privacy or granting admin broadens what the relay can receive. [relay.py lines 14–24](https://github.com/eladb/grokbot-telegram-bridge/blob/9aba89e59fe42ab807c0d2932c553752b5200e4b/relay.py#L14-L24), [SKILL.md lines 12–26](https://github.com/eladb/grokbot-telegram-bridge/blob/9aba89e59fe42ab807c0d2932c553752b5200e4b/SKILL.md#L12-L26).

The recipe maps handles to people but implements no stable-ID identity check. Its “never message other chats” instruction is useful intent, not an outbound authorization boundary. The script does not validate the configured webhook URL's HTTPS scheme or host; deployment must supply a trusted destination. No inbound HTTP listener is implemented, so CORS and inbound webhook-signature verification are not applicable to this process.

### Group, thread, and model-action isolation are external

Every accepted update targets the same webhook. The JSON retains chat, sender and any thread fields, but no per-chat/per-user/per-topic agent session is created here. The reply recipe uses reply_to_message_id and does not explicitly specify message_thread_id. Correct topic routing and memory separation therefore remain unverified external-runtime responsibilities, not guaranteed isolation.

Incoming text and captions are untrusted prompt material. The recipe tells the agent to read them and reply, with no explicit prompt-injection separation, tool allowlist, or confirmation rule for consequential actions. The Python relay has no shell-execution or model-tool dispatcher, so this is not a demonstrated relay remote-code-execution flaw. The risk is handing unfiltered group content to whatever filesystem, command, network, or account tools the downstream bot possesses. Auto-review is mentioned but not implemented or documented sufficiently to establish protection. Require enforced numeric-ID authorization, session keys and outbound destination checks outside the model, plus approval for privileged actions before real use.

### Privacy, secrets, and retention

The entire update is sent to the configured routine, not a minimized text-only projection: sender/chat metadata, text, captions, and attachment references can cross that boundary. The relay does not fetch attachment bytes. Optional mirroring copies incoming exchanges and replies into the user's app chat, expanding the audience and retention surface; participants should know before it is enabled. No redaction, consent flow, retention TTL, deletion propagation, or provider retention policy is supplied. [forwarding](https://github.com/eladb/grokbot-telegram-bridge/blob/9aba89e59fe42ab807c0d2932c553752b5200e4b/relay.py#L19-L24), [mirroring](https://github.com/eladb/grokbot-telegram-bridge/blob/9aba89e59fe42ab807c0d2932c553752b5200e4b/SKILL.md#L19-L28).

Three secrets come from environment variables: bot token, webhook URL, and webhook key. The recipe requests masked secret fields; there is no committed credential value, Telegram user-login session, session database, or local secret-file implementation in the four-file source tree. Environment inheritance and the external secret store remain deployment concerns. Telegram requests put the token in the URL path as required by its API, so request diagnostics/proxies must redact URLs. The source logs statuses and exception strings, not intentionally full payloads, but implements no log redaction, rotation, or access-permission policy. Reply marker files and redirected logs have no cleanup; agent memory and optional mirrored conversation retention are outside this repository. The README's “only live in environment variables” claim is not end-to-end proof about the external secret store.

## Reliability and Recovery

1. **Loss after forwarding failure:** off advances before the webhook POST. A caught timeout or HTTP error merely prints post err; the next poll uses the advanced offset. There is no retry queue or dead-letter store, so the failed update can be acknowledged to Telegram without a successful agent handoff. [lines 17–24](https://github.com/eladb/grokbot-telegram-bridge/blob/9aba89e59fe42ab807c0d2932c553752b5200e4b/relay.py#L17-L24).
2. **Duplicate/ambiguous delivery:** the offset is not persisted; restart begins at zero and may re-receive updates not yet confirmed by a later poll. A webhook may process a request whose response times out. No update-ID idempotency key/store, acknowledgement reconciliation, or exactly-once reply safeguard exists.
3. **Edits are new work:** edited_message is forwarded and uses the same chat/message marker path as the original. A prior marker can immediately suppress typing for the edit. No edit-to-existing-response policy or marker expiry exists.
4. **Startup changes bot-wide state:** deleteWebhook is unconditional and outside the retry loop. It removes any existing webhook for that bot and startup failure exits the script. This requires an exclusively assigned bot; no multi-instance lock or competing-consumer protection is supplied.
5. **Limited recovery:** poll exceptions sleep a fixed five seconds; posts have a 30-second timeout, Telegram calls 70 seconds. No exponential backoff, Retry-After handling, bounded worker pool, queue-depth metric, readiness check, or graceful shutdown is present. Every accepted message spawns a daemon typing thread, with no concurrency bound.
6. **Keep-alive is a recipe:** a suggested ten-minute scheduled agent routine checks/restarts the process. Its definition, singleton enforcement, health detection and reboot behavior are not supplied. A live but stuck process is not covered by a presence check. A posted HTTP status is not proof a reply was sent.

These findings follow control flow, not fault-injection experiments. The skill's statement that a read timeout is merely harmless idle polling is too broad: network faults also time out, and webhook timeout delivery is ambiguous.

## Provider Flow and Costs

Telegram → local relay → external routine → Grok Bot tools → Telegram is the supported topology. No xAI API endpoint, model identifier, model SDK, local inference, model download, API pricing or subscription requirement is implemented. Runtime access, routine quotas, tool permissions, model billing and retention must be established with the chosen Grok Bot environment. There are no spending caps or token budgets here. Unfiltered messages/edits, progress replies, optional mirroring and scheduled supervision can generate additional runtime work; the exact bill is unknown. MIT licensing is not a guarantee that the external service is free.

## Self-Hosting Notes

Python 3 and outbound HTTPS to Telegram and the configured webhook suffice for the relay; the setup recipe additionally assumes a Unix-like shell with nohup, a writable relay directory, environment injection and a runtime able to create webhook/scheduled routines. The recipe's “PID 1 is tini; no systemd or cron” describes its assumed box, not a universal platform requirement. No Python minimum version, container image, supported-platform matrix, installer, automatic update mechanism, release pinning, rollback or migration tooling is provided. The Python snippet is duplicated in SKILL.md, so copied installations can drift from relay.py.

Before adapting it: retain Telegram privacy where feasible; enforce sender/chat/topic rules before waking a model; isolate sessions; restrict downstream tools; validate reply destinations; persist queued updates and deduplicate by update_id; retry with bounded backoff; supervise a single process; rotate logs and markers; and document provider/mirroring consent and retention. Do not share a bot token with another webhook or polling consumer.

## Maturity, License, and Verification

The reviewed tree has exactly four tracked files and no automated tests, CI, dependency manifest/lockfile, changelog, or packaging. Only Python's standard library is imported. Public GitHub metadata retrieved 2026-11-10 reports 0 stars, 0 forks, 0 open issues, creation and last push on 2026-10-14. The public commits endpoint returns one root commit; releases and all-state issues endpoints return empty lists. These indicate a small published recipe, not evidence of safety or service compatibility. [metadata](https://api.github.com/repos/eladb/grokbot-telegram-bridge), [releases](https://github.com/eladb/grokbot-telegram-bridge/releases), [history](https://github.com/eladb/grokbot-telegram-bridge/commits/main/).

The actual LICENSE is MIT, copyright 2026 Elad Ben-Israel; notices must accompany substantial copied code. No source was extracted for redistribution in this review. Static inspection covered every tracked source/document file and public metadata. No runtime test, network fault injection, Telegram behavior, external Grok Bot implementation, secret-store security, model behavior, or live end-to-end delivery was verified.

## Comparison

| Option | Better fit | Trade-off |
|---|---|---|
| This recipe | Understanding the Telegram-to-authenticated-webhook workaround | Authorization, durable queues and bot behavior remain outside the relay |
| [python-telegram-bot](https://github.com/python-telegram-bot/python-telegram-bot) | Building a Python Telegram application with explicit handlers and managed application lifecycle | More dependencies; developers still must implement access policy, model integration and durable business delivery |
| [grammY](https://github.com/grammyjs/grammY) | Building a typed JavaScript/TypeScript Telegram bot with routing middleware | Different stack; not a drop-in Grok Bot integration or an automatic AI safety boundary |
| Native Telegram connector in the chosen agent runtime | Avoiding an extra relay when the runtime supports the required authentication and isolation | Verify actual allowlists, session keys, tool approvals and recovery rather than assuming feature equivalence |

The framework comparisons are architectural choices, not fresh audits of those projects. The most useful idea here is keeping transport authentication separate from agent response generation. Production users should choose a maintained connector or implement the missing enforced boundaries rather than treating the setup prompt as a security policy.

---

**Attribution:** [eladb/grokbot-telegram-bridge](https://github.com/eladb/grokbot-telegram-bridge), Elad Ben-Israel, MIT.
