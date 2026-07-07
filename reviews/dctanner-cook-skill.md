# dctanner cook Skill

**Source:** https://gist.github.com/dctanner/54c57da4a94a24e71df6281f487f51e1
**Author:** dctanner / Damien Tanner
**Date:** 2026-07-06, updated 2026-07-07
**Reviewed:** 2026-07-06
**Topic:** Agent skill / coding workflow orchestration

---

## Verdict

⚠️ **Useful orchestration instinct, unsafe skill as written.** The gist captures a good high-level pattern: separate planning, implementation, review, and smoke testing across independent agents. But the actual instruction hardcodes privileged execution, non-existent or environment-specific model names, broad commit/push authority, and no sandbox or verification protocol, so it should not be installed verbatim.

---

## Summary

This public gist contains a single `SKILL.md` for a skill named `cook`. Its stated purpose is to code in an Opus session, use a Fable subagent for planning, delegate implementation to Codex, then run review and smoke testing before committing and pushing.

The core workflow is reasonable: write a plan, ask for human approval, implement from the plan, review the result with another model/agent, smoke test the feature, then commit. That is a useful shape for higher-risk coding work because it separates proposal, execution, and verification.

The problem is that the operational details are too blunt. It instructs the agent to run:

```sh
codex --yolo exec -c model="gpt-5.5" -c model_reasoning_effort="high" < plan.md
```

That normalizes privileged execution as the implementation path. It also assumes a specific model string, allows long-running sessions, asks the agent to run `pnpm dev` and make real requests, and then commit and push before moving on. There is no scoping rule for the repository, branch, environment, credentials, network access, destructive commands, or user approval at the commit/push stage.

The best idea in the gist is the reminder that every subagent or Codex session is independent and must receive full context. That is a real source of failures in delegated agent workflows, and the gist calls it out plainly.

## Key Claims

- **Plan before implementation.** Strong pattern. Requiring approval before implementation is the safest part of the skill.
- **Use different agents for plan, code, review, and smoke testing.** Good separation of concerns, but the skill does not define crisp input/output contracts for those agents.
- **Delegate code writing to Codex from `plan.md`.** Reasonable if done in a controlled workspace. Unsafe when paired with `--yolo` as the default.
- **Run real smoke tests before commit/push.** Good intent, but "real requests" can be dangerous without environment and data boundaries.
- **Give every subagent complete context.** Correct and important.

## Strengths

- Compact and easy to understand.
- Encodes an approval gate before implementation.
- Avoids one-agent-does-everything by separating planning, coding, review, and testing.
- Explicitly mentions subagent context isolation, which is easy to forget.

## Gaps & Limitations

- No license is specified, so the text should be treated as reference-only.
- `--yolo` privileged execution is unsafe as a default.
- The model and agent names are environment-specific and may not resolve elsewhere.
- No branch/worktree isolation is required.
- No rules for secrets, external network calls, test data, destructive commands, or production services.
- No required diff review before commit.
- No explicit second human approval before push.
- No artifact format for the plan, review, smoke-test evidence, or final summary.
- No timeout/cancellation/recovery behavior beyond a loose 20-minute allowance.

## Safer Adaptation

A stronger version of this skill would keep the same structure but change the execution contract:

- planning agent produces a structured plan with files, risks, tests, and rollback notes;
- user approval is required before implementation;
- implementation runs in a disposable branch or worktree with least-privilege tools;
- no privileged execution flags by default;
- reviewer receives the final diff plus the approved plan;
- smoke tests use local fixtures or explicitly approved endpoints;
- commit and push require a separate approval gate;
- the final report includes changed files, commands run, failures, and residual risks.

---

**Attribution:** dctanner gist, no license specified.
