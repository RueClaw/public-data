# Symphony (openai/symphony)

**Repo:** https://github.com/openai/symphony
**License:** Apache-2.0, suitable for reuse with attribution.
**Reviewed:** 2026-07-25
**Stack:** Elixir/OTP, Phoenix LiveView, Codex app-server, tracker adapters for Linear/GitHub/Jira/Asana/GitLab, Burrito releases
**What it is:** A specification and experimental reference implementation for running coding agents as isolated, issue-tracker-driven implementation workers.

---

## Verdict

✅ **Deploy candidate for trusted engineering-preview pilots.** Symphony is not a polished hosted product, and the README says so directly. But the architecture is serious: issue tracker as work queue, per-issue workspaces, repo-owned `WORKFLOW.md`, Codex app-server sessions, host-side tracker tools, sandbox defaults, dashboard/API observability, tests, CI, and release artifacts. Use it in trusted repos first, then harden the workflow and credentials before broader unattended use.

---

## What It Is

Symphony turns project work into autonomous implementation runs. A long-running service polls a configured tracker, creates or reuses a workspace for each eligible issue, starts a Codex app-server session in that workspace, and keeps the agent working until the tracker item reaches a handoff or terminal state.

The repo has two layers:

1. `SPEC.md` — a language-agnostic service specification for tracker-driven coding-agent orchestration.
2. `elixir/` — the current experimental Elixir/OTP reference implementation.

The implementation supports Linear, GitHub Issues, Jira Cloud, Asana, and GitLab. Each adapter normalizes tracker items into a common issue model and can expose provider-native tools to Codex, such as `linear_graphql`, `github_api`, `jira_rest`, `asana_api`, and `gitlab_api`.

## Stack

| Layer | Tech |
|-------|------|
| Runtime | Elixir/OTP GenServer supervision |
| Agent protocol | Codex app-server over JSON-RPC/stdin/stdout |
| Trackers | Linear, GitHub Issues, Jira Cloud, Asana, GitLab |
| Workflow contract | Markdown `WORKFLOW.md` with YAML front matter plus prompt body |
| Web UI | Phoenix, LiveView, Bandit |
| Packaging | Mix escript and Burrito self-contained releases |
| Tests/CI | ExUnit, Credo, spec checks, PR body lint, GitHub Actions |

## Key Features

### Issue Tracker as Work Queue

Symphony treats tracker state as the source of truth. It polls active states, dispatches work with bounded concurrency, reconciles running work against fresh tracker state, retries failures with backoff, and cleans workspaces when issues reach terminal states.

This is the right abstraction for coding-agent operations: engineers manage the board, not individual model turns.

### Repo-Owned Workflow Contract

`WORKFLOW.md` contains both runtime config and the prompt. The front matter configures tracker kind, active/terminal states, workspace root, hooks, concurrency, Codex command, approval policy, sandbox policy, and optional dashboard settings. The Markdown body becomes the task prompt rendered with issue context.

This makes agent behavior versioned with the target repo rather than hidden inside a daemon.

### Codex App-Server Integration

The reference implementation launches `codex app-server`, initializes a thread, starts turns, streams messages, handles tool calls, tracks token usage, and stops sessions cleanly. It supports continuation turns when the issue remains active after a normal turn.

### Host-Side Tracker Tools

Tracker credentials can stay in Symphony's host process. The Codex child gets provider-native dynamic tools, but declared tracker token environment variables are removed from the child environment. Tool calls execute host-side through the selected tracker adapter.

That is a meaningful trust boundary: the agent can work with tracker APIs without needing raw tracker tokens in its shell.

### Observability

The Elixir implementation includes structured runtime state, token accounting, blocked/input-required state, retry queues, per-issue logs, a JSON API, and a Phoenix LiveView dashboard. This matters because unattended agent work without observability becomes guesswork quickly.

### Release and CI Posture

The repo has GitHub Actions for `make all`, PR description linting, and Burrito release builds across Linux/macOS ARM/x86 targets. Recent workflow runs were green, and releases `v0.0.1` and `v0.0.2` are published.

## Architecture

The implementation maps cleanly onto the spec:

- `Workflow` and `Config.Schema` parse and validate `WORKFLOW.md`.
- `Tracker` and adapter modules normalize Linear/GitHub/Jira/Asana/GitLab issues.
- `Workspace` owns per-issue directories, hooks, path safety, cleanup, and SSH worker execution.
- `Orchestrator` owns polling, dispatch, reconciliation, blocked state, retries, and runtime totals.
- `AgentRunner` creates workspaces and runs Codex turns.
- `Codex.AppServer` handles the JSON-RPC protocol, sandbox/approval settings, dynamic tools, timeouts, and token accounting.
- `SymphonyElixirWeb` exposes dashboard and JSON observability surfaces.

The most important design choice is the separation between orchestration and task policy. Symphony schedules and supervises; the repository's workflow prompt defines how work should be done and handed off.

## Comparison

| Aspect | Symphony | Simple GitHub-label runners | Managed coding-agent platforms |
|--------|----------|-----------------------------|--------------------------------|
| Scope | Spec plus reference implementation | Narrow queue/runner | Full product/control plane |
| Trackers | Linear, GitHub, Jira, Asana, GitLab | Usually GitHub only | Varies |
| Agent protocol | Codex app-server | CLI subprocesses | Varies |
| Policy location | Repo-owned `WORKFLOW.md` | Often script/config-local | Often platform config |
| Observability | Logs, dashboard, JSON API, token accounting | Usually logs only | Usually richer |
| Best fit | Trusted pilots and implementation reference | Prototypes | Production teams needing hosted ops |

## Self-Hosting Notes

The reference implementation is intentionally labeled prototype software. Sensible first-use constraints:

- start with a private, non-critical repository
- use narrow tracker credentials
- keep `thread_sandbox` and turn sandbox policies conservative
- review workspace hooks like deployment scripts
- bind the dashboard to loopback unless deliberately exposing it
- treat tracker-native tools as powerful because they can mutate whatever the configured token can reach
- expect to adapt `WORKFLOW.md` heavily for the target repo

## Verification

Local verification on 2026-07-25:

- Reviewed README, `SPEC.md`, Elixir README, workflow example, package metadata, core orchestrator, agent runner, Codex app-server client, workspace/path safety, config schema, tracker adapters, dashboard docs, and CI workflows.
- GitHub metadata showed Apache-2.0 license, 26,220 stars, 2,653 forks, and last push on 2026-07-24. GitHub Issues are disabled; the repository currently has open PRs.
- GitHub releases list showed `v0.0.1` and `v0.0.2`.
- Recent GitHub Actions `make-all` and PR-lint runs were green on the latest commit.
- I could not run local tests because `elixir`, `mix`, and `mise` are not installed on this machine.

---

**Attribution:** openai/symphony, Apache-2.0 License.
