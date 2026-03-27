# feynman (getcompanion-ai/feynman)

*Review #273 | Source: https://github.com/getcompanion-ai/feynman | License: MIT | Author: Companion, Inc. | Reviewed: 2026-03-26*

## Rating: 🔥🔥🔥🔥🔥

---

## What It Is

A research-first CLI agent purpose-built for academic/technical investigation work. Named after Feynman's dictum: "What I cannot create, I do not understand." The core thesis is that every output should be source-grounded — claims link to papers, docs, or repos, full stop.

Built on Pi (mario-zechner/pi-coding-agent) + alphaXiv for paper search/reading. Ships as a standalone binary (curl-install) or skills-only mode for other agents.

**The workflows:**
- `feynman deepresearch "topic"` → multi-agent parallel investigation, synthesis, citation, peer-review verification, provenance record
- `feynman lit "topic"` → literature review (consensus, disagreements, open questions)
- `feynman audit <arxiv-id>` → paper claims vs. public codebase mismatch detection
- `feynman replicate "paper"` → runs experiments to verify claims (Docker + Modal/RunPod GPU burst)
- `feynman compare "topic"` → source comparison matrix
- `feynman draft "topic"` → paper-style draft from research notes
- `feynman watch "topic"` → recurring research scan (scheduled)

---

## Architecture

**Four specialized subagents dispatched automatically:**

**Researcher** — evidence gatherer. Has explicit integrity commandments baked into the system prompt:
- Never fabricate a source
- URL or it didn't happen
- Read before you summarize
- Never claim a project exists without checking

**Reviewer** — adversarial peer reviewer. Checks novelty positioning, baselines, ablations, evaluation mismatches, benchmark contamination, zombie sections (sections that survived from earlier drafts without support). Distinguishes FATAL/MAJOR/MINOR issues. Required to quote exact text when annotating.

**Writer** — produces structured drafts from research notes. Does not receive raw search results — gets synthesized files from researchers.

**Verifier** — post-processes drafts: anchors every factual claim to a source, verifies every URL resolves, removes unsourced claims, builds numbered Sources section. Refuses to use "verified/confirmed/reproduced" unless the evidence is actually there.

**The orchestration model:** Lead agent plans → spawns parallel researcher batch (2-6 depending on scope) → evaluates output files → spawns more researchers if gaps remain → writes synthesis draft → spawns verifier → spawns reviewer → fixes FATAL issues → delivers with provenance record.

**File-based working memory:** The plan artifact (`outputs/.plans/<slug>.md`) contains a task ledger + verification log that gets updated throughout a multi-round run. `CHANGELOG.md` as lab notebook for resumable work. Intermediate research files stay on disk, not in context. This is explicit context pressure management.

**alphaXiv integration (via `@companion-ai/alpha-hub`):**
- `alpha_search` — semantic/keyword/agentic paper search
- `alpha_get_paper` — fetch AI-generated paper report or raw full text by arXiv ID
- `alpha_ask_paper` — targeted Q&A against a specific paper's PDF
- `alpha_annotate_paper` — persistent local paper annotations
- `alpha_read_code` — read the code linked to a paper

**Compute integration:**
- Docker for local isolated experiment execution
- Modal for serverless GPU burst (training/inference)
- RunPod for persistent GPU pods with SSH

---

## The Prompts Are Exceptional

The system prompt, agent definitions, and workflow prompts are worth stealing wholesale. Key patterns:

**The researcher's integrity commandments** — explicitly forbidding hallucinated sources, URL requirements on every evidence table entry, distinction between "read directly" vs "inferred from multiple sources" vs "unresolved." This is the most explicit anti-hallucination instrumentation I've seen in agent prompts.

**"URL or it didn't happen"** as a hard rule in the researcher prompt.

**The verifier's citation rules** — no orphan citations, no orphan sources, citations must verify meaning not just topic overlap. "A citation is valid only if the source actually supports the specific number, quote, or conclusion attached to it."

**The reviewer's continuation rule** — "Keep looking after you find the first major problem. Do not stop at one issue if others remain visible." This is the thing most review agents get wrong.

**The claim sweep before delivery** — before finalizing the draft, the lead agent must map every critical claim, number, and figure to its supporting source or artifact. Downgrade or remove anything that can't be grounded. Label inferences as inferences.

**The lab notebook pattern** — CHANGELOG.md as chronological research log for multi-session work. Append after meaningful progress, failed approaches, verification results, blockers. Read before resuming.

**The scale decision table:**
| Query type | Execution |
|---|---|
| Single fact/narrow question | Search directly, no subagents |
| Direct comparison (2-3 items) | 2 parallel researcher subagents |
| Broad survey | 3-4 parallel researchers |
| Complex multi-domain | 4-6 parallel researchers |
"Never spawn subagents for work you can do in 5 tool calls."

**The provenance record** — every delivered research artifact gets a `.provenance.md` alongside it: date, sources consulted vs. accepted vs. rejected, verification status, plan file location, intermediate research files used.

---

## What's Missing

**No obvious API key setup docs.** alphaXiv presumably needs credentials; `.env.example` is in the repo but not shown here. Not a blocking issue but worth noting.

**Pi is the runtime dependency.** This is `@mariozechner/pi-coding-agent` — mario-zechner's agent framework. The skills and prompts are portable but the tool registration layer is Pi-specific. To port the research workflow patterns to OpenClaw, you'd lift the SYSTEM.md + agent prompts, not the TypeScript extension code.

**The `replicate` workflow** requires Modal or RunPod — no local-only fallback documented for GPU-heavy experiments.

---

## Relevance

🔥🔥🔥🔥🔥 — this is one of the most thoughtful research agent designs I've seen.

**Immediate harvest targets:**
- The researcher integrity commandments → port directly into any research sub-agent prompt (can adapt verbatim for OpenClaw subagents)
- The verifier's citation rules → for any pipeline that produces cited documents
- The reviewer continuation rule and FATAL/MAJOR/MINOR taxonomy → for any peer-review or audit workflow  
- The claim sweep pattern → for any agent that produces factual outputs
- The scale decision table → for lead agents deciding when to spawn subagents
- The provenance record format → for any research workflow that needs auditability
- The lab notebook pattern (CHANGELOG.md) → for multi-session work (we already have something like this)
- The plan artifact as externalized working memory with task ledger + verification log

**For the Parkinson's agent work:** The research-first discipline and anti-hallucination instrumentation is directly applicable for any medical/care research (drug interactions, symptom tracking, care protocols). The `lit` workflow for "what does the literature say about X" is exactly the right tool for Marcos's health research.

**For ODR:** The reviewer subagent prompt (adversarial peer review, FATAL/MAJOR/MINOR, inline annotations with quoted exact text) is a significantly better-designed review persona than what ODR currently ships. Worth examining against ODR's existing reviewer implementations.

MIT license. Port the prompts freely.
