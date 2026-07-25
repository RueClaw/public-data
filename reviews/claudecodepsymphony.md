# ClaudeCodePSymphony (gherghett/ClaudeCodePSymphony)

**Repo:** https://github.com/gherghett/ClaudeCodePSymphony
**License:** package.json declares ISC; no root LICENSE file and GitHub reports no detected license.
**Reviewed:** 2026-07-25
**Stack:** TypeScript, Node.js, GitHub CLI, Claude Code CLI, Liquid templates, YAML workflow config
**What it is:** A small fork of OpenAI Symphony that swaps Codex/Linear for Claude Code in `claude --print` mode and GitHub Issues with `symphony/*` labels.

---

## Verdict

📚 **Study the GitHub-label adaptation, do not deploy this as-is.** The repo is a compact and readable sketch of how to run issue-driven coding agents from GitHub Issues, but it is intentionally high-trust: raw shell hooks, GitHub tokens, autonomous `bypassPermissions`, and issue text rendered straight into prompts. It builds cleanly, but the project is a one-commit prototype with no tests, no CI, no license file, and current dependency audit findings.

---

## What It Is

ClaudeCodePSymphony is a "SLOP-fork" of OpenAI's Symphony specification and service shape. Upstream Symphony is designed around Codex and Linear; this fork uses GitHub Issues as the tracker and Claude Code as the coding-agent subprocess.

The workflow is simple:

1. Poll GitHub Issues for `symphony/todo` or `symphony/rework`.
2. Claim an issue by switching it to `symphony/in-progress`.
3. Create or reuse a per-issue workspace.
4. Run workspace hooks from `WORKFLOW.md`.
5. Render the issue into a Liquid prompt.
6. Launch `claude --print` in the workspace.
7. Expect the agent to create a branch, commit, push, open a PR, comment on the issue, and move the issue to `symphony/human-review`.

There is no database. Runtime state is in memory, and recovery is based on GitHub labels plus persistent workspace directories.

## Stack

| Layer | Tech |
|-------|------|
| Runtime | Node.js ESM, TypeScript |
| Tracker | GitHub CLI via `gh issue list/view/edit` |
| Agent | Claude Code CLI in `--print` mode |
| Prompting | LiquidJS templates |
| Config | YAML front matter in `WORKFLOW.md` |
| Workspace | Per-issue directories under a configured root |
| Observability | Structured console logs and per-issue `.logs/*.log` files |

## Key Features

### GitHub Label State Machine

The best part is the mapping of tracker states to GitHub labels:

- `symphony/todo`
- `symphony/in-progress`
- `symphony/human-review`
- `symphony/rework`
- `symphony/done`

That is a practical way to recreate Linear-style workflow states without adding a database or a custom service.

### Repo-Owned Workflow Contract

`WORKFLOW.md` carries both YAML runtime config and the prompt body. This follows the Symphony idea that the target repository should own its agent policy, hooks, concurrency, tracker config, and completion instructions.

### Per-Issue Workspace Isolation

Issue identifiers are sanitized into workspace keys, and each agent run gets a separate working directory. Hooks can clone the target repo, check out an issue branch, and prepare the workspace before Claude starts.

### Claude Code Print-Mode Runner

`src/agent-runner.ts` wraps `claude --print`, supports `--continue`/`--resume`, parses `stream-json` output for progress messages, and enforces a per-turn timeout. It is small enough to read end to end.

### Operator Peek

The CLI has `--peek` support that tails per-issue logs. This is crude, but useful for long-running autonomous coding workers.

## Architecture

The code follows the Symphony spec layers closely:

- `workflow-loader.ts` reads YAML front matter plus prompt body.
- `config.ts` resolves `$ENV` variables, defaults, and typed settings.
- `github-tracker.ts` normalizes GitHub Issues into a stable issue model and manages `symphony/*` labels.
- `workspace.ts` creates per-issue workspaces and runs shell hooks.
- `prompt.ts` renders Liquid templates with issue context.
- `agent-runner.ts` launches Claude Code and streams updates.
- `orchestrator.ts` owns polling, dispatch, retries, reconciliation, and status snapshots.

The shape is good. The hardening is not there yet.

## Security and Maturity Notes

- `permission_mode` defaults to `bypassPermissions`, which is full autonomy for Claude Code.
- Workflow hooks are raw shell scripts executed with `bash -lc`.
- Issue bodies and titles are rendered into prompts. Treat public or low-trust issue trackers as prompt-injection surfaces.
- The agent receives enough environment to use `gh`; a GitHub token is part of the expected deployment model.
- Label claiming is not atomic across multiple orchestrator instances.
- There is no visible test suite or CI workflow.
- `npm audit --omit=dev` reports a high-severity `js-yaml` advisory and critical `liquidjs` advisories in production dependencies.
- GitHub reports no detected license, despite `package.json` declaring ISC.

## Comparison

| Aspect | ClaudeCodePSymphony | OpenAI Symphony | Heavier agent platforms |
|--------|---------------------|-----------------|-------------------------|
| Tracker | GitHub labels | Linear in the original spec direction | Usually database/control-plane backed |
| Agent runtime | Claude Code `--print` | Codex-oriented | Mixed, often configurable |
| Persistence | GitHub labels plus workspaces | Spec allows restart recovery | Often durable DB/event log |
| Safety posture | High-trust prototype | Spec-level boundary, implementation-dependent | Usually more policy/approval machinery |
| Best use | Pattern study | Reference architecture | Real deployments |

## Self-Hosting Notes

Only run this against repositories and issues you trust. A safer pilot would use:

- a disposable GitHub repo
- a narrowly scoped fine-grained GitHub token
- a temporary workspace root
- reduced `max_concurrent_agents`
- explicit `allowed_tools` / `disallowed_tools` if the installed Claude Code version supports them
- workflow hooks reviewed like deployment scripts

## Verification

Local verification on 2026-07-25:

- `npm ci` passed.
- `npm run build` passed.
- No tests or GitHub Actions workflow files were found.
- `npm audit --omit=dev` reported 2 production vulnerabilities: 1 high (`js-yaml`) and 1 critical (`liquidjs`).
- Full `npm audit` reported 3 vulnerabilities including a low-severity dev `esbuild` advisory.

---

**Attribution:** gherghett/ClaudeCodePSymphony, package.json declares ISC but no root license file was present.
