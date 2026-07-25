# ADHD (UditAkhourii/adhd)

**Repo:** https://github.com/UditAkhourii/adhd
**License:** MIT, suitable for reuse with attribution.
**Reviewed:** 2026-07-25
**Stack:** TypeScript, Node.js, Claude Agent SDK, Zod, p-limit
**What it is:** A coding-agent skill, CLI, and TypeScript library for running isolated divergent ideation branches under different cognitive frames, then scoring, clustering, pruning traps, and deepening the strongest options.

---

## Verdict

✅ **Deploy candidate for deliberate high-uncertainty ideation, not routine answering.** ADHD has a clean load-bearing mechanism: isolated generator calls first, a separate critic later, and structured outputs throughout. The method is expensive and still lightly evaluated, but the implementation is small, MIT-licensed, documented honestly, and useful enough to install where creative architecture, naming, API design, or fuzzy debugging decisions need more than the default three obvious answers.

---

## What It Is

ADHD targets premature convergence in LLM reasoning. The core claim is that asking one model to "give alternatives" still happens inside one shared context, so the first emitted option anchors the later ones. ADHD instead varies the generator: each divergent branch gets the same problem but a different cognitive frame, and branches do not see each other until the critic pass.

The repo ships three surfaces. The primary artifact is `skills/adhd/SKILL.md`, a portable agent skill with clear trigger guidance and a pre-flight gate. The npm package `adhd-agent` exposes a CLI and library that run the same pattern through the Claude Agent SDK. The docs include a preprint-style site, installation guides, frame descriptions, API docs, and a small eval harness.

This is best treated as a decision-point tool. The repo is explicit that a default run is roughly ten model calls and can cost 5-10x a single answer, more when used inside a large agent context. That honesty is one of the stronger maturity signals.

## Stack

| Layer | Tech |
|-------|------|
| Runtime | Node.js >=18, ESM TypeScript |
| Agent calls | `@anthropic-ai/claude-agent-sdk` |
| CLI | `adhd` binary from `dist/cli.js` |
| Structured parsing | Zod schemas over JSON model outputs |
| Concurrency | `p-limit` semaphore, default concurrency 4 |
| Tests | Node test runner with `tsx` |
| Distribution | npm package plus portable `skills/adhd/SKILL.md` |

## Key Features

### Isolated Divergence

Each branch is a fresh Agent SDK `query()` call with tools disabled. The frame prompt changes the vantage point, but no branch can read another branch during generation. That is the main distinction from in-context chain-of-thought or tree-of-thought prompting.

### Explicit Critic Pass

After divergence, the critic scores every idea on novelty, viability, and fit; flags traps with reasons; clusters by underlying angle; and deepens top non-trap ideas. The weighting is simple but clear: viability is the gatekeeper, novelty is the purpose, and fit keeps the result tied to the original problem.

### Anchor Stripping

Before divergence, ADHD can reframe the problem by stripping incidental anchors such as the current stack or implementation detail while preserving real constraints. That is a useful pre-pass because every divergent branch otherwise inherits the same hidden narrowing language.

### Usable Skill Packaging

The skill file is self-contained, has a short catalog description, includes a pre-flight cost gate, and names when not to use it. That makes it practical as a portable skill rather than just an essay.

## Architecture

The code is intentionally small:

- `src/engine.ts` owns the full loop: reframe, select frames, fan out, score, cluster, shortlist, deepen, and render provocation.
- `src/llm.ts` wraps the Claude Agent SDK and disables tools for generation-only calls.
- `src/frames.ts` defines the frame library and selection logic.
- `src/render.ts` turns the structured `RunResult` into readable output.
- `bench/` contains baseline-vs-ADHD eval scripts and committed result data.

The best design choice is keeping generator and critic prompts mechanically separate. The weakest implementation seam is also in the docs: `documentation/how-it-works.md` refers to split source files such as `src/diverge.ts`, `src/score.ts`, and `src/cluster.ts`, but the current implementation has those functions consolidated in `src/engine.ts`. That does not break runtime behavior, but it is stale documentation.

## Comparison

| Aspect | ADHD | Council-style deliberation | Generic "list alternatives" prompting |
|--------|------|----------------------------|---------------------------------------|
| Divergence boundary | Separate isolated calls per frame | Blind/anonymized rounds can preserve disagreement | One shared context, high anchoring risk |
| Output shape | Ideas, scores, clusters, traps, deepened branches | Stances, critiques, confidence, minority reports | Usually prose bullets |
| Best fit | Engineering ideation and fuzzy diagnosis | Decisions with tradeoffs and disagreement | Low-stakes brainstorming |
| Cost | High | Medium to high | Low |
| Maturity | Small but packaged as skill, CLI, library, docs, evals | Depends on implementation | Prompt-only |

## Self-Hosting Notes

For the CLI/library path:

```bash
npm install -g adhd-agent
adhd "design a rate limiter that survives leader election"
```

Authentication depends on the Claude Agent SDK environment, usually `ANTHROPIC_API_KEY` or a local Claude Code auth path. Production use should cap branch count, context size, and concurrency, and should log the generated ideas because the tool is inherently non-deterministic.

For agent-skill use, install the skill only in contexts where the agent can spend the token budget. It is a poor default for simple implementation tasks.

## Verification

Local verification on 2026-07-25:

- `npm ci` passed.
- `npm test` passed: 1/1 test.
- `npm run typecheck` passed.
- `npm audit --omit=dev` found 0 production vulnerabilities.
- Full `npm audit` reports one low-severity dev advisory in `esbuild` affecting Windows development server arbitrary file read.

---

**Attribution:** UditAkhourii/adhd, MIT License.
