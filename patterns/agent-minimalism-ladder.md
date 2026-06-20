# Agent Minimalism Ladder

**Source:** DietrichGebert/ponytail  
**Repo:** https://github.com/DietrichGebert/ponytail  
**License:** MIT  
**Reviewed:** 2026-06-20

## Pattern

Before a coding agent writes custom code, force it through a fixed ladder:

1. Does this need to exist?
2. Does the standard library already do it?
3. Does the native platform already do it?
4. Does an installed dependency already do it?
5. Can the change be one line?
6. Only then, write the minimum custom implementation.

The useful part is the boundary condition: minimalism must not remove trust-boundary validation, data-loss handling, security, accessibility, hardware calibration, or explicit user requirements. Non-trivial logic still leaves one small runnable check behind.

## Why It Works

Most agent overbuild comes from reaching for custom abstractions too early. The ladder makes "do nothing," "use the stdlib," and "use the platform" first-class solutions instead of afterthoughts.

The safety clause matters. A bare "prefer one-liners" instruction can cut guards. Ponytail's benchmark docs show this explicitly: the shortest prompt arm dropped a path-traversal guard once, while the full ladder kept the validation.

## Reuse

Use this as a compact preflight for coding-agent prompts, review skills, and implementation playbooks:

```text
Before adding code: skip unnecessary work, prefer stdlib, prefer native platform features, use existing deps, then write the smallest custom code that preserves security, validation, data-loss handling, accessibility, and explicit requirements.
```

For durable agent configs, keep this rule in one canonical file and verify generated host-specific copies. The rule is easy to copy; the hard part is preventing drift.

## Source Files

- `skills/ponytail/SKILL.md`
- `AGENTS.md`
- `hooks/ponytail-instructions.js`
- `benchmarks/agentic/README.md`

---

**Attribution:** DietrichGebert/ponytail, MIT License
