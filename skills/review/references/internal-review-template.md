# Internal Review Template

This is the format for reviews written to `Research/repo-reviews/<name>.md`.
These are INTERNAL — include project relevance, internal notes, comparisons to our stack.

## For Code Repositories

```markdown
# <Repo Name> (<org/repo>)

**Date:** <YYYY-MM-DD>
**Repo:** <URL>
**License:** <type> <implication>
**Stars:** <N> | **Forks:** <N> | **Active:** <last push date or "pushed today">
**Pitch:** "<tagline from README or your summary>"

---

## Verdict

**<One-line verdict>.** <2-4 sentences expanding. Be specific. Compare to things we know.>

---

## What It Is

<Product description. Use cases. Target audience. 2-3 paragraphs.>

---

## Stack

| Layer | Tech |
|-------|------|
| Backend | ... |
| Frontend | ... |
| Database | ... |
| ... | ... |

Key dependency callouts go here if notable (e.g., "first project I've seen shipping MCP as first-class").

---

## Standout Features

### 1. <Feature Name>
<Detail. Code snippets if they illustrate the point. Why this matters.>

### 2. <Feature Name>
...

Include as many sections as warranted. Don't pad — if there are only 2 notable features, write 2.

---

## Architecture Patterns Worth Borrowing

<Specific patterns with code examples where useful. These should be concrete enough to implement.>

### <Pattern Name>
```<language>
// relevant code snippet
```
<Why this pattern is good. Where we'd use it.>

---

## Relevance Assessment

This section is what makes the internal review different from the public one.
Assess against our active projects and interests:

### High Relevance
- **<pattern/feature>** — <why it matters to us, which project it applies to>

### Medium Relevance
- **<pattern/feature>** — <connection, but not urgent>

### Considerations
- <Caveats, risks, things that would need adaptation>

Use only project context explicitly authorized in the private session; this public template intentionally contains no private project inventory.

---

## Comparison

Compare to similar tools already reviewed. Reference files in Research/repo-reviews/.

| Aspect | This | <Similar A> | <Similar B> |
|--------|------|-------------|-------------|
| ... | ... | ... | ... |

---

## Extracted Patterns

Briefly list patterns worth extracting to public-data, with source file paths.

### <Pattern Name>
<Description>. Source: `<file path in repo>`.

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
**Topic:** <categorization>

---

## Verdict

<emoji> **<One-line verdict>.** <Expansion.>

---

## Summary

<Core thesis, arguments, evidence. 3-5 paragraphs.>

## Key Claims

<Bulleted claims with evidence assessment.>

## Strengths

<Specifics.>

## Gaps & Limitations

<Counterarguments, missing context, overstated claims.>

---

## Relevance Assessment

### High Relevance
- **<claim/finding>** — <how it applies to our work>

### Medium Relevance
- **<claim/finding>** — <tangential connection>

### Action Items
- <Anything we should do based on this article>

---

**Attribution:** <author>, <publication>, <URL>
```

## Research Index Row Format

When updating the explicitly configured private research index, add a row:

```markdown
| <org/repo-or-title> | <emoji> <verdict text> | <YYYY-MM-DD> | <brief notes> |
```
