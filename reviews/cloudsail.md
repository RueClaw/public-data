# Cloudsail (nkzw-tech/cloudsail)

**Repo:** https://github.com/nkzw-tech/cloudsail
**License:** MIT
**Reviewed:** 2026-05-23
**Stack:** TypeScript, Node 23+, pnpm, Cloudflare Workers, Durable Objects, Containers, Sandboxes, Wrangler, Octokit, Zod, Vite Plus, Codex CLI, OpenCode
**What it is:** Cloudsail is a self-hosted CLI and Cloudflare Worker control plane for creating isolated remote coding-agent sandboxes with Worker-owned credential injection, controlled egress, git helpers, terminals, dev-server previews, checkpoints, and PR workflows.

---

## Verdict

✅ **Deploy candidate for alpha evaluation.** Cloudsail is early, but the shape is excellent: small MIT codebase, Cloudflare-native architecture, sensible credential boundaries, explicit egress policy, cost controls, and clean verification. Treat it as an alpha sandbox system rather than a mature hosted development platform: it has one initial commit, no release yet, and depends on new Cloudflare Sandbox/Containers infrastructure.

---

## What It Is

Cloudsail gives coding agents a remote Linux workspace on Cloudflare. The user deploys a Worker and custom sandbox container, then uses the cs CLI to create project sandboxes, clone GitHub repos or PRs, open terminals, run Codex/OpenCode, start dev servers, expose authenticated preview URLs, inspect diffs, commit, push, open PRs, and destroy or checkpoint workspaces.

The core design is security-driven. Real GitHub and OpenAI credentials stay in Worker secrets, not inside the sandbox container. The container receives a placeholder OpenAI key, and outbound HTTP/S traffic is intercepted by the Worker. GitHub credential injection is scoped to the checked-out repo, OpenAI API calls are injected at the edge, project-added docs hosts are read-only, and the default internet path is blocked.

This makes Cloudsail more interesting than a generic remote dev container wrapper. It is an edge-brokered execution environment for coding agents: the sandbox can run normal local-style tools, but credentials, egress, previews, lifecycle, and policy live in a separate Worker/Durable Object control plane.

## Stack

| Layer | Tech |
|-------|------|
| CLI | Node ESM executable, local config in user config dir, Wrangler integration |
| Control plane | Cloudflare Worker, Project Durable Object registry/state |
| Execution | Cloudflare Sandboxes/Containers using cloudflare/sandbox opencode image |
| Agent tools | OpenAI Codex, OpenCode, pnpm, Vite Plus |
| GitHub | Octokit REST, GitHub PAT or GitHub App installation token |
| Validation | Zod request schemas, typed shared API |
| Security | Worker-side secrets, outbound interception, host allowlist, one-time terminal tickets, preview cookies |
| Tooling | pnpm, TypeScript native preview, Vite Plus, Vitest/Wrangler dry-run |

## Key Features

### Remote Coding Sandboxes

The CLI supports creating named sandboxes, checking out GitHub repos or pull requests, opening an interactive shell, running one-off commands, syncing a local worktree, and invoking Codex or OpenCode inside the remote workspace. Each project maps to its own sandbox Durable Object and project state.

### Worker-Brokered Credentials

Cloudsail keeps provider secrets in the Worker. The sandbox gets a placeholder OpenAI key, while the outbound Worker injects the real OpenAI key only for api.openai.com. GitHub auth is injected only when the outbound request matches the configured repository on GitHub, codeload, raw GitHub content, or GitHub API repo paths.

### Controlled Egress

Default egress includes development-critical hosts such as GitHub, OpenAI/ChatGPT, npm/yarn registries, GitHub asset hosts, and Node/package hosts. Users can add project-specific documentation hosts with cs allow, but non-default added hosts are read-only: GET, HEAD, and OPTIONS only.

### Terminal and Preview Tickets

Terminal WebSocket sessions use short-lived one-time tickets. Preview URLs use short-lived browser tickets that are exchanged for an HTTP-only SameSite cookie; raw preview URLs return unauthorized without bearer auth or a valid ticket/cookie.

### Git Workflow Helpers

Cloudsail wraps common git flows: diff, structured changes, commit, push, and PR creation. The sandbox can still use normal git commands, but the CLI provides repeatable actions for agent outputs.

## Architecture

The Worker exposes a small HTTP API. All API calls except terminal WebSocket ticket redemption require CLOUDSAIL_AUTH_TOKEN bearer auth. Project state lives in a Project Durable Object; a registry DO tracks projects, egress policy lookup by sandbox ID, and preview tickets. The sandbox classes extend Cloudflare's Sandbox class, disable default internet, enable HTTPS interception, and configure environment variables needed for the Cloudflare container CA and placeholder OpenAI auth.

Important safety choices:

- allowedHosts = * is paired with enableInternet = false and custom outbound interception, so policy is enforced by the Worker path rather than by a static host list alone.
- User-added egress hosts reject localhost, private IP ranges, .local, parent-domain wildcard leakage, and invalid hostnames.
- Shell command construction uses single-quote escaping for generated git/agent commands.
- Agent transcripts are byte-capped before storage.
- Active project count and projected idle cost limits can be configured with environment variables.

## Comparison

| Aspect | Cloudsail | Generic remote dev container | Local coding agent |
|--------|-----------|------------------------------|-------------------|
| Execution location | Cloudflare Sandbox/Container | VM/container provider | User machine |
| Credential model | Worker-owned edge injection | Often env vars inside container | Local env/keychain |
| Egress model | Default allowlist plus read-only docs hosts | Usually broad outbound internet | Local network/browser access |
| Agent UX | Codex/OpenCode inside sandbox | Depends on image | Native local CLI |
| Maturity | Alpha, one initial commit | Varies | Mature tooling, weaker isolation |

## Verification Notes

Checks performed:

- Cloned current main at commit 51ac109 from 2026-05-22.
- GitHub metadata: 65 stars, 3 forks, no release, MIT license, pushed 2026-05-22.
- Inspected README, license, security policy, docs, CLI, Worker/Durable Object implementation, Dockerfile, Wrangler config, GitHub workflow, request schemas, and security tests.
- Installed dependencies with pnpm 11.0.6.
- Ran pnpm check: format, lint, and type checks passed.
- Ran pnpm test: 1 file and 4 tests passed.
- Ran pnpm build: Wrangler deploy dry-run passed and showed Worker/Durable Object/container bindings.
- Ran pnpm audit:prod: no known production vulnerabilities.
- Ran pnpm pack:check: package dry-run succeeded with 18 files and about 190 KB unpacked.
- Ran a targeted secret-string scan: no obvious committed secrets.

## Deployment Notes

- Requires Cloudflare Workers, Durable Objects, Containers, and Sandboxes access.
- Requires Docker or a Docker-compatible daemon for cs deploy.
- Use a GitHub App installation over a long-lived PAT for serious use.
- Set CLOUDSAIL_MAX_ACTIVE_PROJECTS and CLOUDSAIL_MAX_MONTHLY_USD before letting agents create many sandboxes.
- Treat live sandbox files and processes as non-durable; commit/push or checkpoint before sleep/restart.
- Run this as an alpha with non-critical repos first.

---

**Attribution:** nkzw-tech/cloudsail, MIT License.
