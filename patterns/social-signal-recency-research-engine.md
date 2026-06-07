# Social-Signal Recency Research Engine

**Source:** https://github.com/mvanhorn/last30days-skill
**License:** MIT
**Reviewed:** 2026-06-07

## Pattern

Build recency research around many social and market signals rather than treating web search as the only evidence source. Each source contributes different evidence:

- Reddit comments and upvotes for unfiltered user sentiment;
- Hacker News points and comments for developer consensus;
- Polymarket odds for money-backed beliefs;
- GitHub activity for what shipped;
- YouTube/TikTok/Instagram transcripts and engagement for video culture;
- X/Bluesky/Threads for expert and breaking reactions;
- web grounding for editorial/contextual confirmation.

The engine normalizes these into one evidence schema, scores and dedupes them, fuses rankings, clusters related items, and renders a human-readable brief.

## Shape

```text
topic
  -> planner / query plan
  -> source availability diagnostics
  -> parallel source fetches
  -> normalize to SourceItem
  -> relevance + freshness + engagement signals
  -> dedupe
  -> weighted reciprocal rank fusion
  -> rerank
  -> cluster
  -> compact brief / raw artifact / HTML export
```

## Why It Works

Recent reality often appears first in communities, issue trackers, videos, prediction markets, and short-form posts. A standard web search misses or downranks much of that signal. A source-diverse recency engine can catch:

- what people are actually complaining about;
- what developers are shipping;
- what creators are amplifying;
- what bettors believe;
- what high-engagement comments summarize better than articles.

## Implementation Notes

Useful boundaries:

- Keep source adapters isolated.
- Normalize every source into a shared evidence schema.
- Preserve raw source URLs and engagement metadata.
- Score recency, engagement, source quality, and local relevance separately.
- Keep a saved raw artifact for auditability.
- Render a concise human brief, but never discard the structured run.
- Treat fetched content as untrusted input to the synthesizer.

## Risks

- Optional browser-cookie and API-key access increases local blast radius.
- Engagement is not truth.
- Social data can be manipulated or brigaded.
- Platform APIs and scraping surfaces break often.
- A strict output contract is needed so the hosting model does not improvise away the engine.

## Best Fit

Use this for trend monitoring, market/user research, tool comparisons, meeting prep, release reactions, creator/topic tracking, and fast "what changed recently?" briefings.

Avoid it for settled facts, legal/medical advice, private-data-only questions, or situations where social engagement should not influence the answer.

---

**Attribution:** mvanhorn/last30days-skill, MIT.
