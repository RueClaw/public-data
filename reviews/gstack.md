# gstack (garrytan/gstack)

*Review #267 | Source: https://github.com/garrytan/gstack | License: MIT | Author: Garry Tan (CEO, Y Combinator) | Reviewed: 2026-03-26*

## Rating: 🔥🔥🔥🔥🔥

---

## What It Is

A complete virtual engineering team as Claude Code slash commands, built and open-sourced by the CEO of Y Combinator. 28 skills covering the full sprint lifecycle: ideation → planning → architecture → implementation → review → security audit → QA → deploy → retrospective.

The headline number: Garry claims **600K+ lines of production code in 60 days, part-time, while running YC full-time.** 140K lines added in a single week across 3 projects. This is what he uses.

MIT. No premium tier. No waitlist.

---

## The Roster

Each skill is a specialist persona with a defined role and scope:

| Phase | Skill | Role |
|-------|-------|------|
| **Think** | `/office-hours` | YC Office Hours — six forcing questions that reframe your product before you write code |
| **Plan** | `/plan-ceo-review` | CEO — find the 10-star product inside the request, challenge scope |
| **Plan** | `/plan-eng-review` | Eng Manager — ASCII diagrams, data flow, edge cases, test matrix |
| **Plan** | `/plan-design-review` | Senior Designer — 0-10 ratings per design dimension, AI slop detection |
| **Plan** | `/design-consultation` | Design Partner — full design system from scratch, realistic mockups |
| **Plan** | `/autoplan` | Runs CEO → design → eng review automatically, surfaces only taste decisions |
| **Build** | `/review` | Staff Engineer — bugs that pass CI but blow up in production |
| **Build** | `/investigate` | Debugger — Iron Law: no fixes without root cause, stops after 3 failed hypotheses |
| **Build** | `/design-review` | Designer Who Codes — audits and fixes |
| **Build** | `/cso` | Chief Security Officer — OWASP Top 10 + STRIDE, 17 false positive exclusions, 8/10+ confidence gate |
| **Test** | `/qa` | QA Lead — real browser, clicks through flows, fixes bugs with atomic commits, generates regression tests |
| **Test** | `/qa-only` | QA Reporter — same methodology, report only |
| **Test** | `/benchmark` | Performance Engineer — Core Web Vitals baseline, before/after per PR |
| **Ship** | `/ship` | Release Engineer — sync, test, coverage audit, PR |
| **Ship** | `/land-and-deploy` | Merge → CI → deploy → production health verification |
| **Ship** | `/canary` | SRE — post-deploy monitoring, console errors, perf regressions |
| **Ship** | `/document-release` | Technical Writer — updates all project docs to match what shipped |
| **Reflect** | `/retro` | Weekly retro — per-person, per-project, shipping streaks, test health |
| **Safety** | `/careful` | Warns before destructive commands |
| **Safety** | `/freeze` | Locks edits to one directory while debugging |
| **Safety** | `/guard` | `/careful` + `/freeze` together |
| **Second opinion** | `/codex` | Independent review from OpenAI Codex — pass/fail gate, adversarial mode, cross-model analysis |
| **Browser** | `/browse` | Real Chromium daemon, persistent state, ~100ms/command |

---

## Architecture Highlights

### The Browser Daemon

This is the hardest technical piece and they did it right. Problem: AI agent + browser needs sub-second latency and persistent state. Cold-starting Chromium per command = 2-3s per call, loses cookies/sessions. Solution: long-lived Chromium daemon, localhost HTTP, compiled Bun binary.

```
Claude → CLI binary → POST localhost:PORT → Bun.serve() → CDP → Chromium
```

First call: ~3s (starts everything). Every subsequent call: ~100-200ms. Random port (10K-60K) means parallel Conductor workspaces don't conflict. State file at `.gstack/browse.json` (atomic write, 0o600). Server auto-shuts after 30min idle. Version mismatch auto-restarts the server.

**`$B connect`** — headed mode. Launches your actual Chrome as a visible window. You watch Claude click in real time. Green shimmer at the top edge marks the controlled window. Chrome extension Side Panel shows live activity feed + chat sidebar.

**`$B handoff`** — CAPTCHA/auth wall rescue. Opens a visible Chrome at the exact same page with all cookies. You solve it, Claude resumes.

### Bun for Distribution
`bun build --compile` → single ~58MB executable. No `node_modules` at runtime, no `npx`, no PATH config. Native SQLite (cookie decryption from Chromium's DB), native TypeScript, built-in HTTP server. The right choice for a tool that installs into `~/.claude/skills/`.

### The ETHOS.md Injection
Every workflow skill's preamble includes `ETHOS.md` — the builder philosophy. This isn't decoration. It contains a compression ratio table (boilerplate 100x, feature implementation 30x, architecture 5x, research 3x), the "Boil the Lake" principle (completeness is cheap — if approach A is 70 lines more and is complete, choose A), and "Three Layers of Knowledge" (tried-and-true, new-and-popular, first principles). This gets injected into every skill context.

### Skill Discovery
Works across Claude Code (`~/.claude/skills/`), Codex (`~/.codex/skills/`), Gemini CLI, Cursor. Skills in `.agents/skills/` discovered automatically. `setup --host auto` detects installed agents. `setup --host codex` handles both repo-local and user-global installs.

### The `/codex` Second Opinion Pattern
Cross-model review: `/review` (Claude) + `/codex` (OpenAI Codex CLI) on the same diff → overlap analysis. What both models flag = probably real. What only one flags = investigate. This is the right way to use multiple models — not as alternatives, but as independent reviewers whose disagreement is signal.

---

## The `/office-hours` Skill

Worth calling out specifically because it's the most original. It doesn't generate features — it challenges your premise. Six forcing questions designed to surface what you're actually building vs. what you said you're building.

From the README demo:
> "I want to build a daily briefing app." → Claude: "I'm going to push back on the framing. What you actually described is a personal chief of staff AI." [Extracts 5 capabilities, challenges 4 premises, generates 3 implementation approaches]

YC office hours are famous for exactly this — founders come in saying one thing and leave with a different and better understanding of their product. Garry encoded that into a skill.

---

## What's Good

- **The scope is complete.** Most developer tool collections cover one phase. gstack covers the whole sprint. The skills feed each other — `/office-hours` writes a design doc that `/plan-ceo-review` reads. `/plan-eng-review` writes a test plan that `/qa` uses. Nothing falls through the cracks because each step knows what came before.
- **Serious E2E test harness.** `test/` directory has fixtures with real ground-truth JSON (`qa-eval-ground-truth.json`), LLM-as-judge helpers (`llm-judge.ts`), session runners for Claude/Codex/Gemini, eval stores. This isn't vibe-tested — they actually measure skill quality.
- **Opt-in telemetry done right.** Schema in the repo. Supabase edge functions with explicit allowlists. Nothing sent by default. Local analytics always available.
- **The compression table in ETHOS.md is a useful mental model.** Boilerplate 100x, test writing 50x, feature implementation 30x, bug fix 20x, architecture 5x, research 3x. Worth internalizing even if you don't use gstack.

## What to Watch

- **`/qa` requires a staging URL.** Works best if you have real browser-accessible staging. Less useful for CLI tools, services without UIs.
- **`/codex` requires Codex CLI installed.** Additional auth/setup if you don't already use it.
- **Scale.** Garry's 10-15 parallel sprints setup uses [Conductor](https://conductor.build) for workspace isolation. Without that, the parallel workflow is manual.
- **No license check needed** — it's MIT.

## Relevance

**Install immediately.** `git clone https://github.com/garrytan/gstack.git ~/.claude/skills/gstack && cd ~/.claude/skills/gstack && ./setup`

**For ODR specifically:** `/cso` with STRIDE and 17 false-positive exclusions is directly applicable. `/review` with production-bug focus would catch things our current review misses. `/retro` with per-contributor breakdown is worth running weekly.

**The ETHOS.md pattern** — injecting builder philosophy into every skill preamble — is directly stealable for any skill-based agent workflow.

**The `/codex` cross-model pattern** is worth adapting: run Claude review + a second model on the same diff, use disagreement as a signal, not just the findings themselves.
