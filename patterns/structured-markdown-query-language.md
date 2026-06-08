# Structured Markdown Query Language

**Source:** https://github.com/harehare/mq
**License:** MIT
**Extracted:** 2026-06-07

## Pattern

Treat Markdown as a structured document tree with a query/update language, not as line-oriented text. Give agents and scripts selectors, typed functions, formatting, checking, and in-place update mode so they can inspect and transform documents without brittle regex.

## Why It Matters

Markdown is the default substrate for docs, notes, prompts, skills, research logs, and LLM context bundles. Most automation still handles it with ad hoc line scans. That works for small edits, then fails around nested lists, tables, code fences, frontmatter, links, and mixed Markdown/HTML.

A query language creates a stable bridge between prose documents and programmatic workflows. It lets agents ask for "all second-level headings", "all links under this section", "all tables", or "the frontmatter field" using document structure rather than guessed text positions.

## Minimal Shape

1. Parse Markdown into an AST with stable node types and positions.
2. Expose node selectors for headings, text, lists, links, tables, code blocks, blockquotes, frontmatter, and comments.
3. Support pipes, maps, filters, projections, and reusable functions.
4. Offer both read-only extraction and in-place update modes.
5. Provide output modes for Markdown, text, JSON, HTML, tables, grep-like lines, and raw values.
6. Add a formatter and checker so saved queries can be maintained like code.
7. Ship examples and an agent-facing skill/reference that states when to use the tool and when not to.
8. Keep parsing/conversion separate from CLI orchestration so editor, web, FFI, and agent integrations can reuse the same core.

## Design Notes

- Position metadata is valuable for diagnostics, diffs, and patch-style edits.
- Table, frontmatter, code-fence, and HTML handling should have explicit tests because these are where regex approaches often break.
- Agent docs should include negative guidance. A Markdown query language should not replace `cat`, `jq`, `yq`, or a real parser for unrelated formats.
- In-place rewrites need a dry-run or diff-friendly workflow before bulk operation.
- A language server or formatter pays off once queries become shared automation rather than one-off commands.

## When To Use

- Vault maintenance and research-note indexing.
- Documentation cleanup and migration scripts.
- Extracting stable LLM context from Markdown sources.
- Agent skills that need reliable Markdown inspection or mutation.
- Release-note, changelog, README, and prompt-library automation.

## Caveats

- Markdown dialect compatibility will always be a source of edge cases.
- Bulk update mode can damage documents if queries are too broad.
- Tool adoption depends heavily on clear examples; a query language without recipes is a tax.
- Broad input/output support increases dependency and security-review surface.

---

**Attribution:** Inspired by harehare/mq, MIT License.
