# X Research Skill Pattern

> **Source:** [xBenJamminx/x-research-skill](https://github.com/xBenJamminx/x-research-skill)  
> **Original:** [rohunvora/x-research-skill](https://github.com/rohunvora/x-research-skill)
> **License:** No explicit license (educational use only)
> **Description:** X/Twitter research agent with zero API cost via Composio. Search, thread following, profile analysis, and watchlist monitoring.

## Overview

Wraps the X API (via Composio) into a fast CLI for agentic research. Search tweets, follow threads, deep-dive profiles, monitor accounts — all at zero API cost.

## CLI Commands

### Search

```bash
bun run x-search.ts search "<query>" [options]
```

Options:
- `--sort likes|impressions|retweets|recent` — Sort order
- `--since 1h|3h|12h|1d|7d` — Time filter
- `--min-likes N` — Filter by minimum likes
- `--pages N` — Pages to fetch (1-5, 100 tweets/page)
- `--no-replies` — Exclude replies
- `--save` — Save to drafts folder
- `--json` | `--markdown` — Output format

### Profile

```bash
bun run x-search.ts profile <username> [--count N] [--replies]
```

Fetches recent tweets from a specific user.

### Thread

```bash
bun run x-search.ts thread <tweet_id> [--pages N]
```

Fetches full conversation thread by root tweet ID.

### Watchlist

```bash
bun run x-search.ts watchlist add <user> [note]
bun run x-search.ts watchlist check
```

Monitor specific accounts for new activity.

## Agentic Research Loop

### 1. Decompose the Question

Turn research questions into keyword queries using X operators:

- **Core query**: Direct keywords for the topic
- **Expert voices**: `from:` specific known experts
- **Pain points**: `(broken OR bug OR issue OR migration)`
- **Positive signal**: `(shipped OR love OR fast OR benchmark)`
- **Links**: `url:github.com` or specific domains

### 2. Search and Extract

Run each query. After each, assess:
- Signal or noise? Adjust operators
- Key voices worth `from:` specifically?
- Threads worth following?
- Linked resources worth deep-diving?

### 3. Follow Threads

When a tweet has high engagement or is a thread starter:
```bash
bun run x-search.ts thread <tweet_id>
```

### 4. Synthesize

Group findings by theme, not by query. Include:
- Engagement data
- Direct links
- Key quotes

### 5. Save

Use `--save` flag or save to:
```
~/clawd/drafts/x-research-{topic-slug}-{YYYY-MM-DD}.md
```

## Architecture

```
skills/x-research/
├── SKILL.md           # Skill definition
├── x-search.ts        # CLI entry point
├── lib/
│   ├── api.ts         # Composio API wrapper
│   ├── cache.ts       # File-based cache (15min TTL)
│   └── format.ts      # Telegram + markdown formatters
├── data/
│   ├── watchlist.json # Accounts to monitor
│   └── cache/         # Auto-managed
└── references/
    └── x-api.md       # API endpoint reference
```

## Zero-Cost via Composio

Original skill uses X API directly ($0.005 per tweet read).  
This fork routes through Composio's free tier (20K calls/month).

| | Direct X API | Via Composio |
|---|---|---|
| **Cost** | ~$0.50/search page | $0 |
| **Rate limit** | X API limits | 20K calls/month free |
| **Data** | Same | Same |

## Key Design Principles

- **Operator-based queries** — Use X search operators for precision
- **Iterative refinement** — Assess each query, adjust operators
- **Thread following** — Don't miss the full conversation
- **Theme-based synthesis** — Group by topic, not by query
- **Cache to avoid waste** — 15-minute TTL prevents redundant calls
