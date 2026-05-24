# Inbox Zero (elie222/inbox-zero)

**Repo:** https://github.com/elie222/inbox-zero
**License:** AGPL-3.0 with additional commercial and enterprise-use restrictions. Treat as source-available for reuse decisions; summarize patterns rather than copying code into closed products.
**Reviewed:** 2026-05-23
**Stack:** TypeScript, Next.js 16, React 19, Prisma 7, Postgres, Redis/Upstash, BullMQ/Vercel Queue, Better Auth, Google APIs, Microsoft Graph, Slack/Teams/Telegram adapters, AI SDK providers, Docker, Turborepo
**What it is:** Inbox Zero is an AI personal assistant for email: it connects to Gmail/Microsoft accounts, triages inboxes, drafts replies, runs automation rules, manages meetings and reminders, files attachments, and exposes assistant chat plus messaging-channel workflows.

---

## Verdict

⚠️ **Interesting and technically strong, but deploy cautiously.** Inbox Zero is a full mailbox automation product with broad provider support, real self-hosting docs, mature tests, and unusually explicit AI safety work. The caveats are significant: it touches private email/calendar/drive data, the license adds commercial and enterprise restrictions, and dependency audit currently reports 10 moderate-or-higher advisories including one high SAML SSO issue.

---

## What It Is

Inbox Zero is an open-source-ish AI email assistant aimed at people who want more than a mail client. It can clean and categorize inboxes, bulk archive or unsubscribe senders, generate drafts, track conversations, create meeting briefs, summarize activity, run recurring automation jobs, and route notifications or draft approvals through Slack, Teams, or Telegram.

The repo is a production SaaS/self-host monorepo rather than a demo. It includes the web app, worker package, image proxy services, API and CLI packages, docs, Helm/Docker/Copilot deployment paths, Playwright smoke flows, AI regression/eval tests, provider emulators, and repo-local agent instructions for development.

The most reusable idea is the way it treats AI as a constrained action generator. Email content is untrusted input; model output is merged only into allowed template fields; higher-risk assistant actions require explicit confirmation; server actions are bound to authenticated email-account ownership; cron and queue entry points use shared secrets or queue callbacks.

## Stack

| Layer | Tech |
|-------|------|
| Web app | Next.js 16, React 19, TypeScript 6, Tailwind, shadcn/Radix-style UI, TipTap, Recharts |
| Data | Prisma 7, Postgres, encrypted token fields, audit Prisma extension |
| Queues/cache | Redis/Upstash, BullMQ, QStash/Vercel Queue |
| Auth | Better Auth, OAuth for Google/Microsoft/Slack/Teams/Telegram, SSO/SCIM options |
| Mail/calendar | Google Gmail/Calendar/Drive APIs, Microsoft Graph/Outlook/Calendar/Drive |
| AI | Vercel AI SDK, Anthropic, OpenAI, Azure, Google/Vertex, Bedrock, Groq, Perplexity, OpenRouter, Ollama/openai-compatible providers |
| Deployment | Docker Compose, Helm chart, AWS Copilot, Vercel, CLI setup helpers |
| Testing | Vitest, Playwright, AI eval suites, provider emulators, smoke and E2E flows |

## Key Features

### AI Mailbox Assistant

The assistant can search mail, answer questions over inbox context, draft replies, manage labels/folders, create rules, preserve user memory, and act through inline cards. The codebase separates pending assistant tool output from confirmed side effects, so actions like send/reply/forward are confirmed through dedicated server actions rather than executed simply because the model produced text.

### Rule Engine With Action Boundaries

Rules can classify messages, archive, label, draft, reply, forward, send, notify, move folders, call webhooks, digest, and interact with messaging channels. The safer design point is template containment: AI-generated arguments are merged into fields that were explicitly templated, while static fields like recipients and subjects stay fixed.

### Multi-Provider Private Data Integrations

Inbox Zero has serious breadth: Gmail, Outlook, Google Calendar, Microsoft Calendar, Google Drive, Microsoft Drive, Slack, Teams, Telegram, SSO/SCIM, webhooks, subscription billing, mobile review sign-in, public booking links, meeting briefs, and MCP/automation integrations.

### Self-Hosting Path

The docs include quick-start CLI commands and deployment guides for Docker/VPS, Vercel, AWS, image proxy setup, Google OAuth/PubSub, Microsoft OAuth, Slack, Teams, Telegram, and AI providers. The Docker stack includes Postgres, Redis, HTTP Redis compatibility, web, worker, and cron services.

## Architecture

The monorepo uses pnpm workspaces and Turborepo. The main app lives under apps/web, with packages for API, CLI, image proxies, scheduling, email templates, analytics, and integrations. The Prisma schema models users, linked accounts, email accounts, rules, executed rules, action items, chats, memories, calendar/drive/messaging connections, MCP connections, booking links, billing, and audit-related state.

Security-relevant architecture is more deliberate than in most AI email tools:

- OAuth/account tokens, messaging tokens, MCP secrets, user AI keys, and webhook secrets are transparently encrypted at rest through a Prisma extension.
- Server actions use an action client that authenticates the user and verifies ownership of the bound email account before executing.
- API keys are hashed and scoped.
- Cron routes require configured secrets, and queue handlers validate payloads.
- AI prompts have explicit untrusted-content hardening helpers for read-only and side-effecting paths.
- Tests cover prompt hardening, static-field protection, server-action boundary exports, phishing-style rule creation, and security pipeline behavior.

## Comparison

| Aspect | Inbox Zero | Mail client extensions | Generic agent inbox scripts |
|--------|------------|------------------------|-----------------------------|
| Scope | Full email assistant product | Usually UI add-ons or provider-specific helpers | Usually narrow automation scripts |
| Provider support | Gmail, Outlook, calendars, drive, messaging channels | Often one provider | Varies, often brittle |
| Safety model | Confirmed actions, scoped server actions, encrypted tokens, AI hardening tests | Depends on extension | Often prompt-only |
| Deployment | SaaS-style monorepo plus Docker/Helm/Vercel/AWS paths | Browser/client install | Local script/server |
| Reuse risk | License and private-data surface require review | Smaller operational surface | Lower maturity, less guardrail depth |

## Verification Notes

Checks performed:

- Cloned current main at commit 6044fde from 2026-05-21.
- GitHub metadata: 10,822 stars, 1,335 forks, latest release v2.30.0, pushed 2026-05-23.
- Inspected README, custom license, package manifests, docs, Docker/Helm/Copilot deployment files, env examples, Prisma schema, auth/action boundaries, AI rule/action code, audit hooks, and security tests.
- Installed dependencies with pnpm 11.1.2. Install completed, but local Node was v25.9.0 while the repo declares Node 24.x.
- Ran lint: passed with one Biome warning for an unused suppression.
- Ran package tests for API, CLI, image proxy, and AWS image proxy: 10 files and 101 tests passed.
- Ran targeted security tests: 3 files and 52 tests passed.
- Ran web build with placeholder required env vars: Next.js build completed successfully.
- Ran pnpm audit at moderate level: 10 vulnerabilities, 9 moderate and 1 high. The high advisory is samlify via @better-auth/sso; moderate advisories include Mermaid, brace-expansion, ws, protobufjs, uuid, and qs.
- Ran a targeted secret-string scan. Hits were placeholders or test tokens, not obvious committed live credentials.

## Deployment Notes

- Review the custom license before commercial, SaaS, or 5+ user business deployment.
- Rotate and protect all OAuth, encryption, queue, cron, webhook, and provider secrets. The app correctly expects many secrets; misconfiguration is the main practical risk.
- Disable or restrict risky features such as outgoing email sending, webhook actions, auto-drafting, SSO, and public booking links until the deployment has real monitoring and access review.
- Patch dependency advisories before using SSO or exposing untrusted Markdown/Mermaid rendering paths.
- Use a Node 24 runtime for production and CI parity.

---

**Attribution:** elie222/inbox-zero, AGPL-3.0 with additional commercial and enterprise-use restrictions.
