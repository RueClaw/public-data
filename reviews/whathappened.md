# whathappened (kunchenguid/whathappened)

**Repo:** https://github.com/kunchenguid/whathappened  
**License:** MIT; permissive reuse with attribution  
**Reviewed:** 2026-07-16  
**Stack:** Agent Skill markdown, Grok Build native X tools, `npx skills` package layout  
**What it is:** A Grok Build-only Agent Skill for producing short neutral briefings from public X/Twitter conversation around a named topic, launch, person, product, or controversy.

---

## Verdict

⚠️ **Interesting, with a useful X-native briefing pattern.** The skill is small and sharp: it refuses to fake sentiment without native X tools, uses adaptive recency windows, separates event facts from opinion clusters, and requires receipts. It is not portable to generic coding agents because it depends on Grok Build's X tool stack, but the workflow is worth studying or adapting for any trusted social-search environment.

---

## What It Is

`whathappened` is an Agent Skill packaged under `skills/whathappened/SKILL.md`. The target use case is a user asking "what happened with X?" or "what are people on X saying about Y?" The skill turns that into a structured briefing: what happened, where the conversation is, rough opinion camps, live debates, notable posts, and gaps.

The README is unusually explicit about the boundary: this is "Grok Build only." It requires native X tools: `x_keyword_search`, `x_semantic_search`, `x_thread_fetch`, and `x_user_search`. If those tools are missing, the skill should stop instead of using web search to synthesize fake social sentiment.

The skill also has a good information-discipline rule: web lookup is allowed at most once, only to resolve entity identity. All event and sentiment claims must come from X tool results. That is the right posture for a social briefing tool where hallucinated consensus would be worse than a refusal.

## Stack

| Layer | Tech |
|-------|------|
| Package format | Agent Skills directory layout |
| Runtime target | Grok Build |
| Required tools | `x_keyword_search`, `x_semantic_search`, `x_thread_fetch`, `x_user_search` |
| Optional lookup | One `web_search` or `web_fetch` call for entity resolution only |
| References | Query-pattern and failure-mode markdown playbooks |
| Distribution | `npx skills add kunchenguid/whathappened` |

## Key Features

### Hard Refusal When X Tools Are Missing

The host requirement is not buried. The skill says to stop if the X tools are unavailable. That keeps it from becoming a generic web-summary prompt pretending to know what public X thinks.

### Adaptive Recency Window

The pipeline starts with a cheap Latest search to measure velocity, then commits to Breaking, Same-day, Story, or Background mode. This avoids the common failure where a fresh launch gets mixed with stale discourse or an older controversy is forced into a fake breaking-news frame.

### Search Lattice

The skill asks for multiple lanes: Top, Latest, Semantic, first-party, and debate. That is a good way to counterbalance pure engagement ranking. Top posts catch consensus and viral frames; Latest catches developing facts; semantic search catches paraphrases; first-party search anchors the event; debate queries expose disagreement.

### Opinion Map With Caveats

The output template requires rough camp shares, representative voices, and explicit caveats that the shares are qualitative sample judgments, not polling. This is a useful guard against false precision.

### Failure-Mode Playbook

The two reference files are practical. `query-patterns.md` gives advanced X query recipes and entity-hygiene rules. `failure-modes.md` names the predictable traps: no topic, missing tools, entity collision, thin sample, bot noise, official silence, origin outside the current window, web leakage, over-long windows, fabricated quotes, single-camp tunnel vision, and percentage overprecision.

## Architecture

The repo is intentionally minimal:

```text
README.md
LICENSE
skills/whathappened/SKILL.md
skills/whathappened/references/query-patterns.md
skills/whathappened/references/failure-modes.md
```

There is no application code and no package manifest. The install surface is the `npx skills` package layout, which can discover the skill directly from the repository. A local smoke test with `npx skills add ./ --list` found the `whathappened` skill successfully.

Security and reliability are mostly about information hygiene rather than code execution. The skill has no shell scripts and no secret-handling code. Its main risks are social-data risks: entity collision, bot amplification, fake consensus, unverified first-party claims, and the temptation to treat public X as ground truth. The skill addresses those risks directly in the instructions.

## Comparison

| Aspect | whathappened | xint | Generic web search summary |
|--------|--------------|------|----------------------------|
| Primary goal | Brief "what happened" and opinion map from X | X/Twitter intelligence CLI and MCP server | Summarize web results |
| Runtime | Grok Build only | Bun/TypeScript CLI/MCP server | Any browser/search environment |
| Data discipline | X-only sentiment, one web resolve only | Programmatic X API workflows | Often mixes sources |
| Output | Human briefing | Search/export/analyze tooling | Narrative summary |
| Portability | Low | Medium, if API access exists | High |

## Self-Hosting Notes

There is nothing to self-host. Installation is via Agent Skills packaging:

```bash
npx skills add kunchenguid/whathappened -g
```

or by copying `skills/whathappened` into Grok's skills directory. The skill should only be used in a host that exposes the required X tools. In other hosts, it should refuse rather than degrade to web-only sentiment.

---

**Attribution:** kunchenguid/whathappened, MIT
