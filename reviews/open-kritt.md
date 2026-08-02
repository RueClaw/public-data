# open-kritt (Kritt-ai/open-kritt)

**Repo:** https://github.com/Kritt-ai/open-kritt
**License:** AGPL-3.0-only; network use of modified versions carries source-sharing obligations
**Reviewed:** 2026-08-02
**Stack:** JavaScript/Node, Express, Prisma/Postgres, React/Vite, Python engine, Docker Compose, Codex/Claude/OpenRouter harnesses
**What it is:** Self-hosted security research platform that orchestrates AI coding agents over repositories to produce deduplicated, ranked vulnerability findings and post-script validations.

---

## Verdict

⚠️ **Interesting authorized-security lab tool, not a casual deploy.** open-kritt is unusually honest about its threat model and has a real workflow engine for focused vulnerability research, but it intentionally gives tool-enabled agents root inside disposable containers, direct internet access, and a privileged engine with Docker-socket control. Use it only on a dedicated host or VM, only against code you are authorized to test, and treat the AGPL license as a real constraint.

---

## What It Is

open-kritt is a self-hosted platform for running structured AI vulnerability research. Instead of asking one model to inspect an entire repository, it lets operators build multi-step workflows, run them across Codex or Claude Code agents, collect structured outputs, deduplicate findings, apply severity rankers, and run post-scripts for validation/enrichment.

The product is made for security researchers and security-minded developers who want control over prompts, workflows, model providers, and infrastructure. It supports remote GitHub repositories, local repositories, dependencies, reusable agent skills, model-provider accounts, natural-language workflow/post-script generation, scan management, and vulnerability review.

The repository is not pretending to be a safe SaaS-by-default app. The README and threat model say the backend has no built-in application auth, defaults should stay bound to localhost, scans send code to configured model providers, and the engine should run on a dedicated Docker host because scan agents can execute tools against untrusted code.

## Stack

| Layer | Tech |
|-------|------|
| Frontend | React 18, Vite, React Router, Vitest |
| Backend | Express 5, Prisma, Postgres, Pino, Node test runner |
| Engine | Python 3.10+, pytest, psycopg, JSON Schema, subprocess/Docker orchestration |
| Data | Postgres with SQL init/migration files and Prisma schema mapping |
| Runners | Codex, Claude Code, OpenRouter-backed Codex/Claude-style harnesses |
| Deployment | Docker Compose with frontend, backend, engine, executor-view, and Postgres |
| CI | Version sync, CLI tests, docs link checks, frontend build/tests, backend tests/Prisma validation, DB migration idempotence |

## Key Features

### Workflow-Based Security Research

The core abstraction is a workflow: ordered prompt steps with declared output schemas, depth, multi-output behavior, and optional consume-all behavior. The queue builder expands workflow state into pending jobs while preserving lineage through previous step outputs.

This is a better shape than a single giant "find vulnerabilities" prompt. It encourages narrower questions, repeatable playbooks, and structured outputs that can be deduplicated or ranked.

### Agent Harness Orchestration

The Python engine prepares per-job workspaces, provider homes, Codex/Claude configuration, selected agent skills, repository checkouts, dependency snapshots, and model-provider environment. It supports Codex, Claude Code, and OpenRouter-based configurations, with explicit handling for rate limits, quota exhaustion, model access errors, invalid structured output, and provider safety blocks.

### Post-Scripts and Severity Rankers

Post-scripts run after findings to validate, enrich, or produce proof/report material. Severity rankers are reusable rule sets concatenated into the scan at creation time. That gives teams a way to encode domain-specific triage policy instead of leaving every result as a raw model claim.

### Repository Handling

Repository normalization accepts GitHub owner/repo or GitHub HTTPS URLs. Private-repo tokens are passed through an askpass flow, command/error text is redacted, local repositories are mounted read-only into services, and scans work from snapshots/copies rather than mutating the source.

### Threat Model Documentation

`docs/threat-model.md` is a standout artifact. It explicitly calls out unauthenticated API exposure, model-provider data egress, root scan runners, direct internet access, Docker-socket control, secrets in `.env`, and the need for a dedicated VM/Docker host. That level of candor is a maturity signal even though it describes a dangerous tool shape.

## Architecture

The app is split into five Compose services:

- `frontend`: Vite/React UI, bound to localhost by default.
- `backend`: Express/Prisma REST API, no built-in auth, CORS disabled by default unless configured.
- `engine`: Python worker that claims scans/generation jobs, prepares workspaces, runs harnesses, and controls nested Docker runners through the host Docker socket.
- `executor-view`: read-only view of executor state/accounts.
- `db`: Postgres with SQL init/migration files.

The Postgres schema separates workflows, steps, scans, generated drafts, agent skills, severity rankers, step results, vulnerabilities, enrichments, model catalogs, and account/provider state. `workflows.step_results` is partitioned by scan/depth lineage, which fits the product's branchy workflow execution model.

The biggest architectural risk is also the point: the engine is privileged enough to launch scan containers, and the scan containers are designed to run tooling as root with internet access. The project tries to contain this with per-job workspaces, dedicated Docker networks, no Docker socket inside job containers, no database or `.env` mounts in job containers, schema-constrained output, and private job directories. That reduces blast radius but does not make untrusted code safe.

## Comparison

| Aspect | open-kritt | Wallbreaker | Generic coding agent |
|--------|------------|-------------|----------------------|
| Primary use | Repository vulnerability research | LLM red-team/jailbreak campaigns | General code tasks |
| Output shape | Structured findings, dedupe, rankers, post-scripts | Campaign reports and judge outcomes | Free-form patches/analysis |
| Safety posture | Honest threat model, dedicated-host requirement | Authorized-lab framing | Depends on harness |
| Deployment risk | High if exposed or co-located | Medium/high depending targets | Varies |
| License | AGPL-3.0-only | AGPL-3.0-or-later | Varies |

## Self-Hosting Notes

The quickstart is simple, but the deployment is intentionally high-trust. Keep it bound to localhost or behind a real auth proxy. Run it on a dedicated VM or Docker host. Use narrow, short-lived GitHub tokens. Use model-provider accounts whose data handling is acceptable for the scanned code. Add host-level egress controls if direct internet from scan runners is not acceptable.

CI is useful but not yet fully strict. Frontend/backend lint and format checks are currently advisory, and engine tests are disabled in CI because several assume a writable `/root` home and one assertion is stale. That is a meaningful gap for a security automation project.

---

**Attribution:** Kritt-ai/open-kritt, AGPL-3.0-only
