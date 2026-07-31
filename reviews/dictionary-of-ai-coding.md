# AI Coding Dictionary (mattpocock/dictionary-of-ai-coding)

**Repo:** https://github.com/mattpocock/dictionary-of-ai-coding
**License:** No license specified; educational/personal reference only, do not copy entries wholesale.
**Reviewed:** 2026-07-31
**Stack:** Markdown content, TypeScript README generator, Node 22, GitHub Actions
**What it is:** A public glossary of AI coding terms, written in plain English and generated from individual Markdown entries into a single README/site source.

---

## Verdict

📚 **Study this as vocabulary infrastructure, not as reusable code.** The writing is unusually clear about model, harness, context, token, and agent terminology, and the repo structure makes the glossary easy to maintain. The missing license blocks direct reuse of the text, and the committed README is currently stale relative to the generator/template, so treat it as a reference to read and link rather than material to lift.

---

## What It Is

AI Coding Dictionary is a glossary for developers who use AI coding tools and need precise language for the systems around them. It defines terms like model, harness, session, context window, tool call, MCP, AGENTS.md, progressive disclosure, handoff, AX, and vibe coding.

The repo is mostly content. Each term lives as a Markdown file under `dictionary/`, the curriculum file defines section order, and a small TypeScript generator combines the template, table of contents, and entries into the top-level `README.md`. The public-facing value is editorial, not technical infrastructure.

The best entries avoid hype and name practical failure modes: context degradation, billing surprises, hallucination sources, agent handoff loss, always-loaded instruction cost, and the difference between a model and a harness.

## Stack

| Layer | Tech |
|-------|------|
| Content | Markdown files in `dictionary/` |
| Build script | TypeScript via `tsx` |
| Runtime | Node 22 for generation/checks |
| CI | GitHub Actions README freshness check and webhook notification |
| Dependencies | TypeScript, tsx, Prettier, Husky, lint-staged |

## Key Features

### Source-first glossary

The generated `README.md` is explicitly not the source of truth. Entries live as separate Markdown files, and `internal/Curriculum.md` controls the section structure. That makes the repo easier to review and edit than a single giant glossary document.

### Plain-English technical boundaries

The strongest content separates words that are often blurred together: model versus harness, context versus context window versus session, tool call versus tool result, primary source versus secondary source. This is the real value of the project. It gives teams a shared vocabulary for diagnosing agent behavior instead of arguing from fuzzy labels.

### Agent-facing contribution rules

`CLAUDE.md` tells agents how to add entries: update `dictionary/`, place the term in `internal/Curriculum.md`, keep descriptions short, link only first occurrences, and write in a flat, de-hyped register. That is a good example of making editorial taste operational for coding agents.

### Generated README guard

The CI workflow typechecks the generator, regenerates `README.md`, and fails when the generated file is out of sync. That is the right shape for generated documentation. At the reviewed commit, a local `npm run generate` changed the hero URL/image block in `README.md`, so the committed generated file appears stale.

## Architecture

The architecture is intentionally small:

1. `dictionary/*.md` stores one entry per concept.
2. `internal/Curriculum.md` defines section order and required entries.
3. `internal/README.template.md` stores the page shell.
4. `internal/generate-readme.ts` validates curriculum shape, checks for missing/orphan entries, rewrites local entry links into README anchors, and writes `README.md`.

The generator does useful validation without becoming a framework. It enforces the curriculum grammar, rejects duplicate terms, fails on missing entry files, and fails on orphan dictionary entries that are not placed in the curriculum.

## Comparison

| Aspect | AI Coding Dictionary | 12 Factor Agents | Agent Skills / Superpowers |
|--------|----------------------|------------------|----------------------------|
| Primary value | Shared vocabulary | Production-agent principles | Agent workflow execution |
| Format | Glossary | Principles guide | Skills/plugins |
| Best use | Link when terms are fuzzy | Use as design rubric | Install or adapt workflows |
| Reuse constraint | No license, summarize/link only | Apache-2.0 / CC BY-SA | Varies by repo |

AI Coding Dictionary sits closer to a field guide than a tool. It complements agent workflow repos because it names the concepts those workflows rely on, but it does not provide an executable process.

## Self-Hosting Notes

There is nothing substantial to self-host unless you want a local copy of the generated README. The repo can be checked with:

```bash
npm ci
npm run generate
git diff --exit-code README.md
```

Local verification on 2026-07-31 found:

- `npm ci` completed.
- `npm run generate` completed.
- `git diff --exit-code README.md` failed because generation updated the hero URL and image URLs.
- `npm audit --omit=dev` reported zero production vulnerabilities.
- Full `npm audit` reported one low-severity dev advisory in `esbuild`.

---

**Attribution:** mattpocock/dictionary-of-ai-coding, no license specified
