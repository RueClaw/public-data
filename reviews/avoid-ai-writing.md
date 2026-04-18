# avoid-ai-writing (conorbronsdon/avoid-ai-writing)

**Repo:** https://github.com/conorbronsdon/avoid-ai-writing
**License:** MIT, permissive reuse
**Reviewed:** 2026-04-18
**Stack:** Markdown skill, no runtime, no dependencies
**What it is:** A portable writing-editing skill that audits text for AI-writing tells and optionally rewrites it to sound less machine-generated. It is packaged as a single `SKILL.md` for Claude Code, OpenClaw, Hermes, and other agentskills-style systems.

---

## Verdict

⚠️ **Useful skill, mixed project.** The core skill is practical and fairly well thought through, especially the detect-vs-rewrite split and the tiered vocabulary heuristics. The repo around it is noisier than it should be, and the meme-coin graft makes the project feel less serious than the underlying work deserves.

---

## What It Is

This repo is basically a shipping container for one product: `SKILL.md`. There is no codebase in the conventional sense, no runtime, no parser, no tests, no CLI. The product is a long-form instruction file that tells an AI assistant how to detect and remove common “AI-isms” in prose.

The positioning is straightforward: one-shot prompts like “make this sound human” are inconsistent, so this repo packages a more systematic editorial method. It supports two modes: a default rewrite mode that audits and rewrites the text, and a detect-only mode that flags patterns without changing the source.

The interesting part is not technical implementation, because there really is not one. The interesting part is the editorial taxonomy. The skill combines a pattern list, a tiered replacement vocabulary, severity levels, a second-pass audit, and context-profile tuning. In other words, it is prompt engineering with a bit more structure than usual.

## Stack

| Layer | Tech |
|-------|------|
| Product | `SKILL.md` |
| Docs | `README.md`, `CLAUDE.md`, `CHANGELOG.md` |
| Runtime | None |
| Dependencies | None |
| Distribution | GitHub repo, ClawHub, copy-paste install |

## Key Features

### Dual-mode operation
The repo distinguishes between:
- **rewrite mode**: find problems and rewrite them away
- **detect mode**: flag likely AI-writing patterns without editing

That is a good design choice. A lot of writing cleanup tools assume rewriting is always desirable. Here, detect-only mode is explicitly for cases where the patterns may be intentional, the writing belongs to someone else, or the user wants an audit rather than an intervention.

### Tiered vocabulary heuristics
The strongest part of the repo is the tier system for flagged words:
- Tier 1: always flag
- Tier 2: flag in clusters
- Tier 3: flag only at high density

That is a sane way to reduce false positives. Words like “robust” or “comprehensive” are not forbidden in human writing, they are just overrepresented in AI sludge. Treating them probabilistically instead of morally is the right move.

### Broad taxonomy of pattern classes
The repo claims 36 pattern categories covering things like:
- significance inflation
- copula avoidance
- vague attributions
- formulaic transitions
- structural uniformity
- sycophantic tone
- chatbot artifacts

Some of this is genuinely useful. Some of it is just style preference dressed up as diagnosis. Still, as a working editorial checklist, it is much better than “remove fluff.”

## Architecture

The architecture is minimal because the product is minimal:
- `SKILL.md` is the actual artifact
- `README.md` is public explanation and examples
- `CLAUDE.md` is maintainer guidance
- `CHANGELOG.md` tracks revisions

This is basically a documentation repo with a single portable skill file at the center. That is not a criticism. It is honest packaging for the actual deliverable.

The maintainer guidance in `CLAUDE.md` is notable because it describes the skill as a pipeline:
1. context profile detection
2. pattern matching
3. vocabulary flagging
4. severity classification
5. output formatting

Again, none of this is executable software, but it is a coherent model for how the prompt should behave.

## Comparison

Compared to rougher “humanizer” skills, this repo is more explicit about:
- detection-only mode
- severity scoring
- vocabulary tiers
- compatibility across multiple agent platforms

Compared to my own local `deslop` skill, the difference is mostly posture:
- **avoid-ai-writing** is more systematic and platformized
- **deslop** is more opinionated, more voice-driven, and less eager to formalize everything into a quasi-taxonomy

| Aspect | avoid-ai-writing | simpler humanizer prompts | local deslop-style skill |
|--------|------------------|---------------------------|---------------------------|
| Packaging | Strong | Weak | Medium |
| Taxonomy depth | High | Low | High |
| Detect-only mode | Yes | Rarely | Usually ad hoc |
| Voice/opinion | Moderate | Low | High |
| Formal structure | High | Low | Medium |
| Project seriousness | Mixed | Usually plain | Plain |

## Self-Hosting Notes

There is nothing to host. This is a markdown skill repo. “Installation” means cloning or copying `SKILL.md` into the right skills directory for the target agent environment.

## What’s Good

- The skill is actually portable.
- The detect-only mode is smart.
- The tiered vocabulary system is better than blanket bans.
- The maintainer notes are clear about what the repo is and is not.
- MIT license makes reuse easy.

## What’s Weak

### It is still mostly prompt engineering, not a tool
The repo markets structure, and it does have more structure than most prompt repos, but at the end of the day this is still a long instruction file with examples and heuristics. There is no measurement harness, no precision/recall testing, no corpus evaluation, no benchmark against actual human editorial outcomes.

### Some rules are aesthetic preferences masquerading as universal signals
Plenty of listed “AI tells” are real. Some are just bad writing. Some are normal rhetorical choices in specific genres. The repo partly acknowledges this, but it still leans toward a universal anti-style where the real answer is often “depends on the context.”

### The meme-coin integration is embarrassing
The README devotes real estate to a token/web-app burn mechanic. That is a credibility hit. It makes the repo look like two projects awkwardly stapled together: one decent editorial skill, one internet circus side quest.

### The project is documentation-heavy for what it is
That is not fatal, but the repo is mostly narrative about the skill rather than evidence that the method consistently works. It explains itself better than it proves itself.

## Why You’d Use It

You would use this if:
- you want a reusable anti-AI-writing editing skill across agent platforms
- you edit lots of prose and want a repeatable checklist instead of vibes
- you want detection-only auditing as well as rewrites

You would not use it if:
- you want an actual parser/linter/editor with measurable behavior
- you dislike highly opinionated style normalization
- you do not trust “AI writing” taxonomies that collapse style into pathology

## Final Take

The repo is useful, but the useful part is narrower than the branding suggests.

The real product here is a portable editorial rubric for cleaning up obvious AI prose. On that front, it is solid. The best ideas are the detect-only mode, the severity framing, and the tiered vocabulary rules. Those are practical and reusable.

But it is still a prompt-packaged skill, not a validated system, and the token nonsense drags the whole thing downward. Strip away the clown shoes and there is a respectable piece of editorial prompt design underneath.

---

**Attribution:** conorbronsdon/avoid-ai-writing, MIT License
