---
name: review
description: >
  Autonomous review of code repositories, articles, documents, and tools. Triggers whenever a GitHub URL, repo link,
  article URL, or document is shared for review — even with zero additional context. If the user pastes a GitHub repo
  URL with no other instructions, run this skill immediately. Also triggers on phrases like "review this", "check this
  out", "what do you think of this repo/article/project", "take a look at", or any shared link to a codebase or
  technical article. Covers repos, blog posts, research papers, technical writeups, and tools. Three outputs every time:
  chat summary, public review (pushed to public-data), and internal vault review with project relevance.
---

# Review Skill

Autonomous review pipeline. No clarifying questions. No "what do you want me to look at?" Just do the review.

## When This Triggers

- A GitHub/GitLab/etc. repo URL is pasted (with or without any other context)
- An article, blog post, or technical document URL is shared
- A document or file is shared for review
- The user says "review this", "check this out", "take a look at", etc.
- Any unreviewed URL appears in conversation

If a GitHub repo URL is shared with no additional context, that IS the instruction. Run the full pipeline.

## The Pipeline

### Step 0: Detect Content Type

Determine whether the input is a **code repository** or a **document/article**. This affects which sections appear in the review, but all three outputs are always produced.

- **Code repository**: GitHub/GitLab URL, local repo path, or anything with a codebase
- **Document/article**: Blog post, research paper, technical writeup, news article, PDF

### Step 1: Acquire the Source

**For repos:**
1. Clone to `/tmp/<repo-name>` (shallow clone: `git clone --depth 1`)
2. If clone fails due to mount locks, try `/tmp` directly
3. Read: README, LICENSE, package manifests, key config files, directory structure
4. Scan architecture: entry points, core modules, key patterns, dependencies, CI config
5. Check GitHub API for stars, forks, last push date, open issues count

**For articles/documents:**
1. Fetch the URL content (use WebFetch or read the provided file)
2. Extract: title, author, publication date, key claims, methodology
3. Note the source credibility and any obvious biases

### Step 2: Analyze

**For repos — evaluate these dimensions:**
- **What it is**: One-paragraph product description. What problem does it solve?
- **Stack**: Language, framework, database, infrastructure, key dependencies
- **License**: Type and implications (MIT/Apache = free extraction; AGPL/GPL = summarize only; none = educational use only)
- **Architecture**: Key patterns, interesting design decisions, code quality signals
- **Features**: Standout capabilities, what's novel or well-executed
- **Security**: Any obvious issues (scan for hardcoded secrets, CORS, auth gaps, input validation)
- **Maturity**: Stars, forks, commit frequency, documentation quality, test coverage
- **Verdict**: Classification using the rating system (see below)

**For articles — evaluate these dimensions:**
- **What it claims**: Core thesis and key arguments
- **Evidence quality**: Data, citations, methodology, reproducibility
- **Relevance**: Who should read this and why
- **Gaps**: What's missing, what's overstated, counterarguments
- **Verdict**: Worth reading, worth sharing, worth acting on?

### Step 3: Write Three Outputs

Every review produces exactly three outputs. No exceptions.

#### Output 1: Chat Summary

Short, direct, returned in the conversation. Format:

```
**[Name]** — [one-line description]
Stack: [key technologies]
License: [type]
Verdict: [emoji + classification + 1-2 sentences why]

Key points:
- [2-4 bullets of what matters most]
```

For articles, replace Stack/License with Source/Author/Date.

#### Output 2: Public Review

Written to `Zob-notes-1/public-data/reviews/<name>.md`

This is PUBLIC. No internal project references, no PII, no secrets. Include attribution.

**Critical: Public/Internal Separation**

The public review must be completely context-free — it reads as if written by someone with no affiliation to any specific organization or project. Before writing public-review.md, mentally scrub ALL of the following:

- Organization names: Bluesun-Networks, RueClaw, etc.
- Project names: Marcos care agent, VOS, GeoGuard, MarineChat, agent event bus, etc.
- Infrastructure references: homelab, fleet, specific server names, IP addresses
- Personal names: Jon, Rue, any family/team members

If a feature is relevant to one of our projects, describe it generically in the public review ("useful for healthcare coordination apps", "good fit for self-hosted deployments") and save the specific project mapping for the internal review only.

This separation matters because public-data is a published repo. Internal context leaking into it is a data hygiene failure.

Read `references/public-review-template.md` for the exact format.

After writing:
- Update the reviews table in `Zob-notes-1/public-data/README.md`
- Stage, commit with message: `review: <repo-or-article-name>`
- Push to origin

**Git operations for public-data:**
- The repo is at `Zob-notes-1/public-data/` (it's a git repo nested in the vault)
- Remote: `git@github.com-rue:ruenakatomi-clawdbot/public-data.git`
- Branch: `main`
- If git push fails (SSH key not loaded), note it in chat and move on. Don't block the review.

#### Output 3: Internal Vault Review

Written to `Zob-notes-1/Research/repo-reviews/<name>.md`

This is the detailed internal review with project relevance. Read `references/internal-review-template.md` for the exact format.

The internal review includes everything the public review has PLUS:
- **Relevance Assessment** section: How does this relate to our active projects? (marcos care agent, homelab infrastructure, agent event bus, VOS, Bluesun-Networks repos, fleet management, vault tools, etc.)
- **Patterns Worth Borrowing** section: Specific code patterns, architecture decisions, or approaches we should adopt
- **Comparison** with similar tools we've already reviewed (reference existing reviews in Research/repo-reviews/)

After writing, update the research index at `Homelab/lobsters/rue/workspace/research.md` with a new row in the table.

### Step 4: Extract Valuable Content

If the reviewed source contains reusable content worth extracting (prompts, patterns, agent configs, tools, scripts), extract them to the appropriate public-data directory with attribution:

- `public-data/prompts/` — System prompts, prompt templates
- `public-data/patterns/` — Architectural patterns, design approaches
- `public-data/agents/` — Agent definitions, orchestration configs
- `public-data/tools/` — Useful scripts and utilities

Only extract if genuinely valuable. Don't extract for the sake of extracting.

## Rating System

Use these verdict classifications:

| Emoji | Rating | Meaning |
|-------|--------|---------|
| ✅ | Deploy candidate | Worth deploying or forking for active use |
| ⚠️ | Interesting | Useful ideas but partial overlap or limitations |
| 📚 | Study | Learn from the patterns, don't deploy directly |
| 🔧 | Harvest | Specific components worth extracting |
| ❌ | Pass | Not worth further investment |

For articles, adapt: ✅ = act on this, ⚠️ = interesting but verify, 📚 = good reference, ❌ = skip.

## Writing Style

Follow the BATHROOM_MIRROR rules — no significance inflation, no filler, no hedge-everything-to-death.
Direct. Technical. Opinionated. If something is bad, say so. If something is good, say what specifically is good and why.

Specificity > enthusiasm. Facts > inflation. Silence > filler.

Compare against things we've already reviewed when relevant. Cross-reference existing reviews in Research/repo-reviews/.

## File Naming

- Repo reviews: use the repo name, lowercased, hyphenated. `probo.md`, `ciso-assistant-community.md`, `agent-orchestrator.md`
- Article reviews: use a descriptive slug. `openai-reasoning-paper.md`, `aws-graviton4-benchmarks.md`
- If the name would collide with an existing file, append a disambiguator.

## Error Handling

- If clone fails: try alternative clone methods, or review from GitHub's web API
- If git push to public-data fails: write the files, note the push failure in chat, move on
- Never block the entire review because one output failed. Produce what you can.

**Source unreachable (404, timeout, blocked):**
When the source URL cannot be fetched or cloned after reasonable attempts:
1. Produce **only** the chat summary explaining the failure, what you tried, and any related resources found via search
2. Do NOT write public-review.md, internal-review.md, or index rows — there's nothing substantive to review
3. If search turns up the content elsewhere (mirror, archive, different URL), use that and proceed normally
