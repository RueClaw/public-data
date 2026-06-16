# Oz for OSS (warpdotdev/oz-for-oss)

**Repo:** https://github.com/warpdotdev/oz-for-oss
**License:** MIT, permissive reuse with attribution
**Reviewed:** 2026-06-16
**Stack:** Python 3.12, Vercel serverless functions, Vercel KV/Upstash Redis, PyGithub, httpx, PyJWT, Oz Agent SDK, GitHub webhooks
**What it is:** A webhook control plane and skill bundle for running Oz agents against open-source GitHub repositories. It handles issue triage, spec generation, implementation PRs, PR review, PR-comment response, and verification.

---

## Verdict

⚠️ **Interesting, especially as a reference implementation for agent delivery plumbing.** The useful part is not the brand-specific agent runtime; it is the shape of the system: strict webhook routing, short synchronous GitHub mutations, async agent runs, persisted run state, cron-side result application, and a suite of repo-local skills. It is too tied to Warp/Oz cloud agents to deploy directly unless you are already in that ecosystem.

---

## What It Is

`oz-for-oss` is an open-source automation platform for GitHub projects that want agent assistance without wiring every workflow through GitHub Actions. A GitHub App sends webhooks to a Vercel control plane, the control plane decides which workflow should run, and Oz cloud agents do the high-context work.

The repo supports common maintainer flows: triaging new issues, creating product and tech specs, implementing approved issues, reviewing pull requests, responding to `@oz-agent` comments, and verifying PR changes. The agent behavior lives in `.agents/skills/`; the Python code mostly handles trusted event routing, prompt construction, state, artifact handoff, and GitHub mutations.

This is not a generic autonomous-coding framework. It assumes GitHub, a GitHub App, Vercel, Vercel KV, and the Oz Agent SDK. That narrowness makes the code easier to understand and gives the system a clearer operational boundary.

## Stack

| Layer | Tech |
|-------|------|
| Runtime | Python serverless functions on Vercel |
| Event source | GitHub App webhooks |
| State | Vercel KV backed by Upstash Redis |
| Agent runtime | Oz Agent SDK / Warp-hosted Oz cloud agents |
| GitHub API | PyGithub plus direct `httpx` calls for App token exchange |
| Security | GitHub HMAC-SHA256 webhook verification, cron bearer secret, GitHub App installation tokens |
| Configuration | `.github/oz/config.yml`, `.github/issue-triage/config.json`, `.github/STAKEHOLDERS` |
| Agent behavior | Markdown `SKILL.md` files under `.agents/skills/` |
| Tests | 436 pytest tests plus 67 subtests |

## Key Features

### Webhook-First Agent Runtime

The architecture is centered on `api/webhook.py`, `core/routing.py`, and `api/cron.py`. The webhook validates the delivery, routes it, starts an agent run, stores `RunState`, and returns `202`. A one-minute cron drains in-flight runs and applies results back to GitHub.

That split is a good pattern for GitHub automation. It keeps webhook latency predictable, avoids long-running GitHub deliveries, and makes the agent run id the durable identity for progress comments and later result handling.

### Explicit Workflow Router

`core/routing.py` is long, but it is also readable. It enumerates exactly which GitHub events become which workflows: PR open/reopen/review request, `/oz-review`, `/oz-verify`, `@oz-agent` mentions, issue assignment, lifecycle labels, `plan-approved`, and ready-issue announcements.

This is better than hiding behavior in scattered action triggers. Maintainers can audit the bot's activation surface in one place.

### Skill-Backed Behavior

The repository includes a concrete skill catalog for triage, duplicate detection, spec writing, implementation, PR review, security review, verification, and self-improvement loops. The skills are not decorative documentation; prompt builders reference them as the behavior contract for cloud agents.

The repo-local companion-skill pattern is the most portable idea here. Shared workflows stay stable, while consuming repositories can add local `review-pr-local`, `triage-issue-local`, or `dedupe-issue-local` guidance.

### Trusted Context Boundaries

The prompt builders repeatedly label issue bodies, comments, PR text, and fetched GitHub context as untrusted data. They tell agents not to obey instructions from user-controlled GitHub content and require structured artifacts such as `review.json` or `pr-metadata.json` for handoff.

That does not solve prompt injection by itself, but it is the right baseline posture for agent systems that read issue and PR text from arbitrary contributors.

### Strong Test Posture

The repository has broad tests around routing, signature verification, dispatch, cron draining, PR review application, prompt construction, issue-state enforcement, artifact validation, workflow config, and ownership parsing. The full suite passed locally at review time: `436 passed, 67 subtests passed`.

## Architecture

The core loop is:

1. GitHub sends a webhook to `/api/webhook`.
2. The handler verifies `X-Hub-Signature-256`.
3. The router maps the event payload to a workflow decision.
4. Workflow-specific builders gather GitHub context and construct prompts.
5. `core/dispatch.py` starts an Oz cloud run and saves run state in KV.
6. A progress comment is created or updated with the Oz run id.
7. `/api/cron` polls in-flight runs and invokes workflow-specific result appliers.

The code is separated into `api/` entrypoints, `core/` workflow control logic, `core/workflows/` concrete workflows, `oz/` helper modules, `.agents/skills/` agent procedures, and `tests/`.

The main architectural tradeoff is coupling. The event-control design is reusable; the implementation is tightly bound to Oz cloud agents and GitHub App permissions. Forking it for another agent runtime would mean replacing the dispatch, artifact, skill-spec, and prompt-contract pieces while keeping much of the routing and state-machine shape.

## Comparison

| Aspect | Oz for OSS | qship | agent-scripts |
|--------|------------|-------|---------------|
| Primary value | Webhook-delivered GitHub agent control plane | Ticket-to-PR automation flow | Canonical agent ops repo and skill library |
| Runtime | Vercel + Oz cloud agents | GitHub/CLI-oriented workflow automation | Mostly local docs and helper scripts |
| Best reuse | Routing/state/artifact handoff patterns | Delivery-gate ideas | Skill organization and validation |
| Coupling | High to Oz/Warp | Medium to its workflow assumptions | Low, mostly prose/scripts |
| Maturity signal | Broad tests, young repo, active development | Project-specific | Mature personal toolkit |

## Self-Hosting Notes

Self-hosting requires a GitHub App, a Vercel deployment, Vercel KV, and Warp/Oz credentials. The documented environment variables include webhook secret, GitHub App ID/private key, Warp API settings, environment IDs, cron secret, optional GitHub Enterprise API base URL, and optional trusted organization checks.

The security posture is reasonable for an OSS bot: webhook signatures are mandatory, cron auth fails closed by default, GitHub App tokens are minted per installation, and bot-authored issues are skipped unless explicitly allowlisted. The main operational risks are cost/control-plane coupling to the Oz runtime and the usual risk of giving an automation app write access to issues, PRs, and contents.

---

**Attribution:** warpdotdev/oz-for-oss, MIT License.
