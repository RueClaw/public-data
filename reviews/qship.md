# qship (3awny/qship)

**Repo:** https://github.com/3awny/qship
**License:** MIT
**Reviewed:** 2026-06-07
**Stack:** Bash, Claude Code plugin metadata, Agent Skills, Codex CLI integration, jq, envsubst, GitHub CLI, shell hooks, LLM-as-judge eval scaffolding
**What it is:** A ticket-to-production-PR agent skill pipeline for Claude Code and Codex CLI, with 21 rendered skills, Bash hook gates, state files, installer/configurator, Codex routing, and smoke/eval/leak-check tooling.

---

## Verdict

✅ **Deploy candidate for sandboxed pilots.** qship is fresh and not battle-tested, but it has a unusually concrete shape: installable skills, hook-enforced phase gates, temp-home smoke tests, placeholder validation, leak checks, CI, docs, and explicit warnings around unattended autonomy. The caveat is big: its fully unattended path uses broad agent permissions, headless model subprocesses, GitHub operations, and local E2E execution, so it belongs in isolated worktrees, containers, or VMs before any sensitive production use.

---

## What It Is

qship packages a long-form software delivery workflow as an agent skill catalog. The core pipeline starts from a ticket or pasted spec, detects affected repos, creates branches, writes a plan, implements with TDD, runs multiple review/bug-hunt passes, performs live E2E evidence capture, opens a PR, watches CI, attempts CI fixes, and performs a final PR review.

The repo is distributed as a bootstrapper. Installing the plugin gives the user a configurator skill, then `setup.sh` renders the full template catalog into `~/.claude/skills/` and optionally symlinks it into `~/.codex/skills/`. The rendered skills are customized from `config.example.json` / `config.schema.json` values such as repo list, tracker mode, GitHub org, state root, local DB details, and Codex integration.

Its core design is a three-layer enforcement model: skill prose for instructions, Bash hook gates that block dangerous or premature tool calls, and an outer persistence loop that re-runs until a completion check passes. State lives on disk under a configured state root, which is meant to survive context compaction and agent restarts.

## Stack

| Layer | Tech |
|-------|------|
| Skill runtime | Claude Code Agent Skills |
| Optional second engine | Codex CLI skills via symlinks |
| Installer | POSIX Bash, `jq`, `envsubst` |
| Hook gates | Bash scripts registered in Claude settings |
| PR operations | `gh`, `git` |
| Config | JSON schema + example config |
| Eval | Markdown fixtures + LLM-as-judge scaffold |
| CI | GitHub Actions, placeholder checks, dry-run installs, gitleaks scan |

## Key Features

### 21-Skill Pipeline

The repo ships exactly the skill catalog the pipeline expects: planning, directory checks, cleanup, code review, test review, bug hunting, validation, E2E checks, memory capture, migration checks, auth trailing-slash checks, ticket shipping, epic shipping, and phase/completion checks.

### Hook-Enforced Phase Gates

qship includes `PreToolUse`, `Stop`, and `SubagentStop` hook templates. They are designed to block PR creation, pushes, comments, and termination attempts when evidence files, test-pass flags, or progress files are missing or stale. This turns "do not skip Phase 3" from prompt prose into a shell-enforced gate.

### State-On-Disk Persistence

The pipeline writes progress files such as `phase2-progress.md`, `phase3-evidence.md`, `trd-coverage.json`, `pipeline-context.json`, and Codex JSONL review outputs. This is the right shape for long agent workflows because the context window is not the source of truth.

### Codex/Claude Model Diversification

`provider=codex` routes implementation to Codex CLI, while `reviewer=codex` routes review/bug-hunt work to Codex. The docs recommend mixed-family implementation/review instead of same-family self-review, which is a sensible design principle.

### Install and Contributor Safety

The repo has a better-than-average OSS hygiene layer: MIT license, security policy, code of conduct, contributor docs, issue/PR templates, placeholder validation, local leak check, smoke install, and CI dry-run installs for single-repo, multi-repo, tracker-none, and Codex-linking cases.

## Validation

Local checks performed:

- `bash scripts/validate-placeholders.sh` passed; it warned about config keys unused in templates.
- `bash scripts/eval.sh --check` passed: 3 fixtures and rubric present.
- `bash scripts/smoke-test.sh` passed: 6 checks, exactly 21 skills installed in a throwaway home, no unfilled placeholders, valid `repos.json`, uninstall clean.
- `bash scripts/check-no-local-leak.sh` passed as a no-op because no local answers file exists.
- `find . -name '*.sh' -print0 | xargs -0 -n1 bash -n` passed.
- Lightweight secret-pattern scan found no obvious live secrets; `gitleaks` was not installed locally.

The smoke test intentionally does not run a real ticket through Claude/Codex. Runtime quality still needs field testing.

## Architecture

qship is organized around templates rather than installed output:

- `templates/skills/` contains the 21 skill directories.
- `templates/skills/qship/hooks/` contains the phase gate, evidence, persistence, and watchdog scripts.
- `templates/skills/qshipmaster/hooks/` contains epic orchestration scripts.
- `templates/hooks-settings/qship-hooks.json` defines the hook registrations.
- `templates/agents/qship-worker.md` defines the implementation worker agent.
- `setup.sh` renders templates, merges hooks into Claude settings, writes `repos.json`, and links Codex skills when enabled.
- `scripts/` contains validation, smoke, leak, eval, and GitHub repo-setup helpers.

The strongest architectural idea is that the agent does not get to decide whether it is done. The filesystem and hook layer decide based on artifacts.

## Comparison

| Aspect | qship | agent_coding / malvin | Webwright | Defending Code Harness |
|--------|-------|------------------------|-----------|------------------------|
| Main focus | Full ticket-to-PR delivery | Implement/review loop | Browser task replay | Security patch finding/fixing |
| Enforcement | Bash hooks + state files + persistence loop | Exact `LGTM` review gate | Scripts/logs/screenshots | Container verification |
| Runtime | Claude Code plus optional Codex CLI | Cursor Agent | Python Playwright | Claude Code + Docker/gVisor |
| Best fit | Long delivery workflows | Local coding loop discipline | Web automation tasks | Vulnerability workflows |
| Main risk | Broad unattended autonomy | Cursor coupling/no license | Browser/shell safety | Heavy sandbox runtime |

## Self-Hosting Notes

Pilot it in an isolated environment:

1. Use a throwaway repo or git worktree.
2. Run in a container or VM if using unattended mode.
3. Install required companion Claude plugins first.
4. Run `bash setup.sh --check`.
5. Start with `tracker=none` and a local markdown spec before connecting Jira.
6. Review every diff and every generated PR before merge.

Do not run the unattended `--dangerously-skip-permissions` path on a primary machine with broad credentials.

---

**Attribution:** 3awny/qship, MIT License.
