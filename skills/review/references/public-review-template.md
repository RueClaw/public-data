# Public Review Template

This is the format for reviews written to `public-data/reviews/<name>.md`.
These are PUBLIC — no internal project references, no PII, no secrets.

## For Code Repositories

```markdown
# <Repo Name> (<org/repo>)

**Repo:** <URL>
**License:** <type> <brief implication note>
**Reviewed:** <YYYY-MM-DD>
**Stack:** <primary language>, <framework>, <key deps>
**What it is:** <1-2 sentence description of what it does and for whom>

---

## Verdict

<emoji> **<one-line verdict>.** <2-3 sentences expanding on why. Be specific about what's good or bad.>

---

## What It Is

<2-3 paragraphs. What problem does it solve? Who is the target user? How does it work at a high level?>

## Stack

| Layer | Tech |
|-------|------|
| Backend | ... |
| Frontend | ... |
| Database | ... |
| Auth | ... |
| ... | ... |

## Key Features

### <Feature 1>
<What it does, why it matters. Include code snippets if they illustrate the point.>

### <Feature 2>
...

## Architecture

<Key patterns, interesting design decisions, code organization. Include diagrams or code if helpful.>

## Comparison

<How does this compare to similar tools? Reference by name. Be specific about tradeoffs.>

| Aspect | This Tool | Alternative A | Alternative B |
|--------|-----------|---------------|---------------|
| ... | ... | ... | ... |

## Self-Hosting Notes

<If applicable: how to deploy, compose stack, dependencies, gotchas.>

---

**Attribution:** <org/repo>, <License>
```

## For Articles / Documents

```markdown
# <Title>

**Source:** <URL>
**Author:** <name / publication>
**Date:** <publication date>
**Reviewed:** <YYYY-MM-DD>
**Topic:** <brief topic categorization>

---

## Verdict

<emoji> **<one-line verdict>.** <2-3 sentences on whether this is worth reading and for whom.>

---

## Summary

<3-5 paragraphs. Core thesis, key arguments, evidence presented, conclusions drawn.>

## Key Claims

<Bullet the main claims with brief evidence assessment for each.>

## Strengths

<What the piece does well. Specific examples.>

## Gaps & Limitations

<What's missing, overstated, or needs verification. Counterarguments.>

---

**Attribution:** <author>, <publication>, <URL>
```

## README Index Row Format

When updating `public-data/README.md`, add a row to the reviews table:

```markdown
| [name.md](reviews/name.md) | [org/repo](repo-url) | License | <emoji> Rating | One-line description |
```

For articles:
```markdown
| [name.md](reviews/name.md) | [Title](url) | N/A | <emoji> Rating | One-line description |
```
