# Use Codex Skill

**Source:** https://public.my-agent-04eee268.sandbox.dev/skills/use-codex.md  
**Author:** Public sandbox skill document  
**Date:** Not specified  
**Reviewed:** 2026-07-03  
**Topic:** Agent skill for delegating context-heavy work to OpenAI Codex CLI subagents

---

## Verdict

⚠️ **Useful delegation pattern, risky defaults.** The core idea is good: use Codex CLI as an external subagent for large, context-heavy coding work, then have the parent agent synthesize the result instead of dumping it. The operational guidance is too aggressive for a reusable skill because it normalizes broad shell execution flags, fixed temp-file paths, and very wide trigger conditions without enough isolation, timeout, or validation discipline.

---

## Summary

The document defines a `use-codex` skill for a parent Claude-style agent. Its main thesis is that when a task would add thousands of tokens of intermediate work to the parent context, the parent should spawn one or more Codex CLI subagents, let them burn their own context, and receive only their final outputs.

The skill gives a practical workflow: clarify the user's intent, select a reasoning tier, pipe a detailed prompt into `codex exec`, capture output to a file, monitor completion, and synthesize the subagent's findings for the user. It includes prompt-writing guidance for research, docs lookup, and API discovery, plus patterns for parallel and sequential subagents.

The best part is the parent/subagent boundary. The document repeatedly says subagent output is input for synthesis, not something to paste verbatim. It also stresses that the parent should keep driving sequential work by reading each result and deciding the next step. That is the right mental model for multi-agent delegation.

The weak part is execution hygiene. The examples use powerful Codex CLI flags and generic `/tmp` output paths, assume a specific model name and reasoning setting, and do not define enough controls around repository state, timeouts, worktree isolation, file clobbering, prompt injection in subagent output, or verification of the returned claims. For a local personal workflow this may be fine. As a reusable built-in skill, it needs harder guardrails.

## Key Claims

- **Claim: subagents keep the parent context clean.** Strong claim. Delegating noisy exploration to another process and returning a summary is a legitimate context-management pattern.
- **Claim: 3,000+ tokens of intermediate work should trigger a subagent.** Reasonable heuristic, but too broad. Some work needs parent continuity more than token savings.
- **Claim: multiple Codex subagents can compare approaches in parallel.** Useful, especially for independent design alternatives or fresh review passes.
- **Claim: the parent should synthesize rather than dump subagent output.** Correct and important. Cross-agent output needs validation and editorial judgment.
- **Claim: large coding tasks should automatically use Codex.** Overbroad. Delegation should depend on risk, repo state, availability of tools, and whether parallelism actually helps.

## Strengths

- Clear distinction between parent orchestration and subagent execution.
- Good prompt template: context, objectives, constraints, output format, success criteria.
- Practical reminder to pipe prompts through stdin for quoting safety.
- Parallel and sequential examples capture two genuinely useful delegation modes.
- Explicit instruction that the parent remains responsible for quality, retries, and synthesis.

## Gaps & Limitations

- Uses broad execution flags in examples without enough discussion of sandbox, approval, or repository risk.
- No timeout, cancellation, or resource-budget pattern for long-running CLI agents.
- Generic `/tmp` output paths can collide between parallel runs unless made unique.
- No explicit rule to validate subagent claims against source before reporting them.
- No isolation guidance for dirty worktrees, destructive edits, network access, or external side effects.
- The model/version guidance is brittle; agent skills should usually phrase this as a configurable default rather than a hardcoded assumption.
- Trigger conditions are too expansive. "Use whenever a user asks for a large coding task" can waste time and create coordination overhead on tasks a single agent can handle cleanly.

## Recommendation

Treat this as a good pattern sketch, not a drop-in skill. Keep the context-offload idea, the prompt structure, and the parent-synthesizes-result rule. Replace the execution defaults with unique run directories, explicit timeouts, sandbox/approval policy, read-only review mode by default, clear edit permissions, and a required validation pass before surfacing claims.

---

**Attribution:** Public sandbox skill document, https://public.my-agent-04eee268.sandbox.dev/skills/use-codex.md
