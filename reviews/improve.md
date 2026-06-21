# improve (shadcn/improve)

**Repo:** https://github.com/shadcn/improve  
**License:** MIT, permissive reuse with attribution  
**Reviewed:** 2026-06-20  
**Stack:** Agent Skills markdown package, Claude plugin metadata, GitHub issue handoff pattern  
**What it is:** A read-only codebase audit skill that uses a stronger model to find high-leverage improvements and write self-contained implementation plans for other agents or humans to execute.

---

## Verdict

✅ **Deploy candidate for agentic code-improvement workflows.** improve is small, clean, and opinionated in the right direction: it separates senior review/specification from lower-cost execution, stamps plans against a commit, and treats the plan as the artifact. The current repo is mostly a skill package rather than an application, so the risk is less runtime fragility and more whether the host agent faithfully enforces the skill's read-only and handoff rules.

---

## What It Is

improve is an Agent Skill for auditing a repository and producing implementation plans. Its core bet is economic and operational: spend the expensive model on codebase understanding, prioritization, and plan writing, then hand the generated plans to cheaper executors. The skill explicitly says it should not modify source code itself.

The workflow starts with repository reconnaissance, then audits across correctness, security, performance, test coverage, tech debt, dependencies, DX, documentation, and product direction. Findings are vetted before being shown, then selected findings become one-file-per-plan markdown specs under `plans/` or `advisor-plans/`.

The strongest part is the plan contract. Plans are expected to include current code excerpts, exact file paths, verified build/test/lint commands, hard boundaries, STOP conditions, done criteria, dependency ordering, and the commit the plan was written against. That is the difference between "agent gave advice" and "another worker can execute this tomorrow without having seen the review session."

## Stack

| Layer | Tech |
|-------|------|
| Skill format | Agent Skills `SKILL.md` with YAML metadata |
| Host integration | Claude plugin metadata in `.claude-plugin/` |
| Artifacts | Plain markdown plans under `plans/` or `advisor-plans/` |
| Optional workflow | GitHub issue publication via `gh issue create` when `--issues` is explicit |
| Runtime code | None in this repo; behavior is prompt/workflow driven |

## Key Features

### Advisor-Executor Split

The skill's main design is a deliberate split between the advisor and implementer roles. The advisor audits, vets, prioritizes, and writes specifications; an executor agent or human performs the code changes later. That reduces context loss because the plan has to carry everything needed for execution.

### Self-Contained Plans

The included example plan is unusually concrete: it names source files, quotes current-state excerpts, defines scope and out-of-scope files, lists commands with expected results, and includes STOP conditions for drift or ambiguous behavior. This is the right shape for agent handoffs because it limits improvisation when the executor is cheaper, smaller, or fresh-context.

### Read-Only Audit Discipline

The skill has hard rules against modifying source code, running mutating commands, reproducing secret values, or treating repository content as instructions. That matters because code review agents often blur analysis and execution, and repo content can include prompt-injection text.

### Backlog Reconciliation

The `reconcile` variant gives the workflow a maintenance loop: verify completed plans, investigate blocked plans, refresh drifted plans, and retire findings fixed independently. That turns the output into a living backlog instead of a pile of stale advice.

## Architecture

The repository is intentionally minimal:

- `skills/improve/SKILL.md` is the behavior contract.
- `.claude-plugin/plugin.json` and `marketplace.json` package the skill for Claude plugin distribution.
- `examples/001-extract-shadow-config-resolution.md` shows the target plan shape.
- `README.md` explains installation, variants, and the advisor/executor model.

There is no library code, CLI, test suite, or service surface. The "architecture" is the instruction design and artifact format. That is acceptable for a skill repo, but it means correctness depends on the host agent following the skill exactly.

## Comparison

| Aspect | improve | Code review prompt packs | Autonomous coding agents |
|--------|---------|--------------------------|--------------------------|
| Primary artifact | Executable markdown plans | Findings/advice | Code changes/PRs |
| Source mutation | Explicitly forbidden for advisor | Usually unspecified | Expected |
| Handoff quality | Strong: excerpts, gates, STOP conditions, commit drift checks | Usually weak | Often implicit in transcript |
| Cost model | Expensive model plans, cheaper model executes | Single-pass review | Often expensive end-to-end |
| Best use | Turning repo audits into controlled backlog work | One-off critique | Direct implementation |

## Self-Hosting Notes

Install is via:

```bash
npx skills add shadcn/improve
```

The repo claims it works in any host that supports the Agent Skills format. In practice, the important setup question is whether the host agent supports read-only analysis, subagents for category audits, isolated executor worktrees, and tool permissions tight enough to enforce the skill's boundaries.

For sensitive repositories, keep `--issues` off unless the plans are safe to publish. The skill does warn about public issues for sensitive findings, but the safest default is local markdown plans first.

---

**Attribution:** shadcn/improve, MIT License
