# Personal_AI_Infrastructure (danielmiessler/Personal_AI_Infrastructure)

*Review #286 | Source: https://github.com/danielmiessler/Personal_AI_Infrastructure | License: MIT | Author: Daniel Miessler (Fabric author) | Reviewed: 2026-03-29 | Stars: 10,698*

## Rating: 🔥🔥🔥🔥🔥

---

## What It Is

Daniel Miessler's (author of [Fabric](https://github.com/danielmiessler/fabric)) personal AI infrastructure, open-sourced as a reference and community platform. v4.0.3. 10,698 stars, MIT. Built on Claude Code as the agent runtime, TypeScript + Bun.

The mission is unusually explicit: "activate as many people as possible" by making the quality of AI infrastructure accessible beyond the technical elite. This isn't framework philosophy — it's the design constraint. Every decision (AI-assisted installation, no manual config, comprehensive skill library, community contributions welcome) flows from it.

The pitch: most agentic systems are tool harnesses that execute commands and forget. PAI is built around the user — persistent goals, preferences, history — and learns from feedback over time.

487MB repo (includes full Next.js templates, fonts, images). Cloned to `~/src/Personal_AI_Infrastructure`.

---

## Architecture

**Two top-level directories:**

```
~/.claude/PAI/
├── SYSTEM/     ← PAI infrastructure (updated on upgrades, don't touch)
│   ├── skills/
│   ├── hooks/
│   └── core/
└── USER/       ← Your customizations (upgrade-safe, portable)
    ├── TELOS/  ← 10 files capturing who you are
    ├── SKILLCUSTOMIZATIONS/
    ├── PREFERENCES/
    └── IDENTITY/
```

User/System separation is a hard architectural principle. When PAI upgrades, your files are untouched. Portable identity.

**Six customization layers:** Identity (name, voice, personality) → Preferences (tech stack, tools) → Workflows (how skills execute) → Skills (capabilities) → Hooks (lifecycle events) → Memory (what gets captured).

**Stack:** Claude Code as agent runtime, TypeScript + Bun, local voice server (port 8888), LaunchAgents on macOS / systemd on Linux.

---

## TELOS (The Core Differentiator)

10 markdown files at `~/.claude/PAI/USER/TELOS/` that capture who you are:

```
MISSION.md      — Core purpose and direction
GOALS.md        — Current goals across life domains
PROJECTS.md     — Active projects and status
BELIEFS.md      — Foundational beliefs and principles
MODELS.md       — Mental models you use
STRATEGIES.md   — Active strategies for reaching goals
NARRATIVES.md   — Key narratives about your life/work
LEARNED.md      — Lessons learned, things you were wrong about
CHALLENGES.md   — Current challenges and problems
IDEAS.md        — Idea capture
```

These files are injected as context for every interaction. The AI knows what you're working toward because it's documented. No re-explaining goals each session.

The **Telos pack** extends this: TELOS can be pointed at a project directory, where it scans all `.md` and `.csv` files, discovers entity relationships, traces dependency chains (PROBLEMS → GOALS → STRATEGIES → PROJECTS), detects bottlenecks, and generates slide-ready narrative bullet points or full McKinsey-style reports as running Next.js applications (not static PDFs). The dashboard template is complete (Next.js + shadcn/ui + Aceternity), not a wireframe.

---

## The 11 Skill Packs

| Pack | Description |
|------|-------------|
| **Telos** | Life OS + project analysis, McKinsey reports, dependency mapping |
| **Thinking** | 7 distinct thinking modes (see below) |
| **Research** | 1–12 parallel research agents, URL verification protocol |
| **Security** | Recon, web assessment, prompt injection testing, security news |
| **Agents** | Agent management and coordination |
| **ContentAnalysis** | Content analysis workflows |
| **ContextSearch** | Search across context |
| **Investigation** | Deep investigation workflows |
| **Media** | Media processing |
| **Scraping** | Web scraping |
| **USMetrics** | US economic/political metrics |
| **Utilities** | General utilities |

Each pack follows the same structure: `README.md`, `INSTALL.md`, `VERIFY.md`, `src/SKILL.md`, `src/Workflows/`, optional TypeScript tools and Next.js templates.

---

## Thinking Pack (7 Distinct Modes)

The most intellectually interesting component. The premise: thinking is not one skill. Seven distinct cognitive modes, each with its own methodology:

1. **FirstPrinciples** — Decompose to fundamental axioms, challenge inherited assumptions, reconstruct from verified truths. Three workflows: Deconstruct, Challenge, Reconstruct.

2. **IterativeDepth** — Multi-lens exploration: technical, economic, social, historical, etc. Grounded in scientific foundations for progressive structured investigation.

3. **BeCreative** — Divergent idea generation. Six workflows: StandardCreativity, MaximumCreativity, TreeOfThoughts, IdeaGeneration, DomainSpecific, TechnicalCreativityGemini3 (uses Gemini for technical + creative cross-pollination).

4. **Council** — Multi-agent collaborative-adversarial debate. Visible transcripts, agents responding to each other. Two modes: full Debate and Quick consensus. (This is a different, simpler take than council-of-high-intelligence reviewed yesterday — no 3-round protocol, no anti-convergence enforcement, but integrated into the broader PAI skill ecosystem.)

5. **RedTeam** — Adversarial validation. Two workflows: AdversarialValidation (devil's advocate attack) and ParallelAnalysis (simultaneous multi-angle critique). Distinct from Council: purely adversarial, not collaborative.

6. **WorldThreatModelHarness** — Tests ideas against world models across configurable time horizons. Three workflows: TestIdea, UpdateModels, ViewModels. The BELIEFS.md file in TELOS feeds these world models.

7. **Science** — Hypothesis-test-analyze cycles. Nine workflows covering the full scientific method: DefineGoal, GenerateHypotheses, DesignExperiment, MeasureResults, AnalyzeResults, Iterate, FullCycle, QuickDiagnosis, StructuredInvestigation. Described as the meta-skill governing all others.

---

## Research Pack (Multi-Agent Parallel Research)

Mandatory trigger: any message containing "research" in any form.

| Request | Mode | Agents |
|---------|------|--------|
| "quick research" | Quick | 1 |
| "research" / "do research" | Standard | 3 |
| "extensive research" / "deep research" | Extensive | 12 |
| "deep investigation" / "map the X landscape" | Deep Investigation | Iterative |

Each agent gets a sub-domain of the research question. Runs in parallel. URL verification is a mandatory step — "Research agents hallucinate URLs. A single broken link is a catastrophic failure."

The Research skill's opening line: `**When user says "research" (in any form), ALWAYS invoke this skill.**`

---

## Security Pack (PromptInjection Sub-Skill)

Five sub-domains:
- **Recon** — Passive recon, OSINT, DNS, WHOIS, ASN, subdomain enumeration
- **WebAssessment** — OWASP, ffuf, Playwright-based app security testing
- **PromptInjection** — Tests for direct injection, indirect injection, multi-stage attacks, jailbreaks, guardrail bypass
- **SECUpdates** — Security news monitoring, tldrsec, breach tracking
- **AnnualReports** — Threat landscape and vendor report analysis

The PromptInjection sub-skill is notable: PAI uses Claude Code to test itself and other systems for prompt injection vulnerabilities. Meta.

---

## Learning System + Status Line

PAI captures interaction ratings to `MEMORY/LEARNING/SIGNALS/ratings.jsonl`. Every output can be rated (explicit or implicit). These feed:

1. **The learning system** — Failures analyzed and fixed. Success patterns reinforced.
2. **The status line** — `statusline-command.sh` (500+ lines of shell) renders a Claude Code hook showing:
   - Location + weather (IP geolocation → Open-Meteo free API, cached)
   - Context window usage bar (gradient: green → yellow → orange → red)
   - Git status (branch, age, modified/staged/untracked)
   - Memory stats (work files, ratings, sessions, research)
   - **Sparklines** for rating history across five time windows (15m, 1h, 1d, 1w, 1mo) with ANSI color gradients
   - Four responsive modes: nano (<35 cols), micro (35-54), mini (55-79), normal (80+)

The sparklines are genuinely elegant: each bucket represents a time slice, bar height and color encode the rating (emerald=9-10, lime=8, yellow=7, amber=6, orange=5, red=1-3). This is the kind of quality you don't see in most AI infrastructure projects.

---

## Hook System

8 lifecycle events:
- `session_start` — Load TELOS context, identity, preferences
- `pre_tool_use` — Security validation, command blocking
- `post_tool_use` — Result capture, signal collection
- `task_complete` — Memory update, rating capture
- `notification` — Voice notifications via local TTS server
- `stop` — Session capture
- `pre_compact` — Memory preservation before compaction
- `environment_startup` — System initialization

The mandatory voice notification in every skill invocation is interesting UX: before any skill runs, it POSTs to `localhost:8888/notify` to announce what it's about to do. This creates an ambient audio layer showing what the agent is doing.

---

## 16 PAI Principles

The principles document is worth reading independently:
- **Principle 6:** "Code Before Prompts" — if you can solve it with a bash script, don't use AI
- **Principle 7:** "Spec / Test / Evals First" — write tests before building, measure if the system works
- **Principle 8:** "UNIX Philosophy" — do one thing well, composable tools, text interfaces
- **Principle 11:** "Goal → Code → CLI → Prompts → Agents" — escalation hierarchy
- **Principle 14:** "Agent Personalities" — different work needs different approaches
- **Principle 16:** "Permission to Fail" — explicit permission to say "I don't know" prevents hallucinations

---

## Comparison to Our Setup

**Strongly aligned:**
- TELOS ≈ our SOUL.md + USER.md + MEMORY.md, but more structured and goal-oriented (10 distinct files)
- Research pack's multi-agent parallel research ≈ our sessions_spawn pattern
- Security pack PromptInjection testing is something we don't have
- Thinking pack modes align with things we do ad-hoc (council-of-high-intelligence yesterday covers Council; we have no structured FirstPrinciples or Science workflows)
- Status line sparklines are ahead of anything we have

**Their approach we could adapt:**
- TELOS structure (separate files for beliefs, mental models, learned lessons) is more structured than our flat MEMORY.md
- The ratings.jsonl feedback loop enabling sparkline visualizations of quality over time
- Mandatory URL verification in research workflows
- The `Code → CLI → Prompts → Agents` escalation principle is exactly right and should be in our COMMON_SENSE.md
- WorldThreatModelHarness for stress-testing ideas against world models

**Our setup advantages:**
- Multi-agent infrastructure (Anek, Debbie) — PAI is single-machine
- LCM compaction vs their 200-line hard limit
- Discord/Slack/iMessage integrations
- Market brief and project management skills

---

## Extractable Patterns

1. **TELOS 10-file structure** — Split MEMORY.md into purpose-specific files (BELIEFS.md, GOALS.md, MODELS.md, LEARNED.md) for better query precision and session injection
2. **Goal → Code → CLI → Prompts → Agents escalation hierarchy** — Add to COMMON_SENSE.md
3. **Mandatory URL verification** — research agents hallucinate URLs; every URL gets verified before delivery
4. **Parallel research agent scaling** — 1/3/12 agents based on scope, explicit rules for when to spawn how many
5. **ratings.jsonl** continuous quality feedback loop with sparklines
6. **WorldThreatModelHarness** pattern — test decisions against explicit world models before committing

---

## Caveats

- 487MB on disk (mostly templates, fonts, images in the Next.js apps)
- Heavy Claude Code dependency — doesn't obviously work with other agent runtimes
- The AI-based installation is appealing but means you need a working Claude Code setup before you can use it to install itself
- Some packs (USMetrics) are fairly US/niche-specific
- 10K stars is impressive but the repo is 6 months old; unclear long-term trajectory

---

## Verdict

🔥🔥🔥🔥🔥 — The most comprehensive personal AI infrastructure I've reviewed. The TELOS 10-file life context system, the 7-mode Thinking skill with distinct methodologies, the parallel research agent scaling, the security pack with prompt injection testing, and the ratings sparkline feedback loop are all well-designed. It's also polished in a way most AI infrastructure projects aren't — complete Next.js templates, robust multi-platform support (macOS + Linux), 16 explicit principles, active community.

Daniel Miessler's Fabric approach was "AI augmentation for humans through well-crafted patterns." PAI extends that to full infrastructure. MIT. Cloned to `~/src/Personal_AI_Infrastructure`.
