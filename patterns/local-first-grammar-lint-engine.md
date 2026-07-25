# Local-First Grammar Lint Engine

**Source:** [Automattic/harper](https://github.com/Automattic/harper)
**License:** Apache-2.0
**Extracted:** 2026-07-25

## Problem

Writing feedback is useful only when it is fast, close to where writing happens, and private enough for sensitive drafts. Server-backed grammar checking adds network latency and sends user text outside the local environment. Single-surface tools also fail because writing happens across editors, browsers, docs, notes, commit messages, and code comments.

## Pattern

Build one local grammar engine and wrap it for many surfaces:

1. **Keep the rule engine central.** Put tokenization, dictionaries, grammar rules, spelling, and suggestions in one reusable core library.
2. **Represent text as documents and spans.** Every lint should point to exact source spans and carry suggested replacements.
3. **Extract prose per format.** Do not blindly lint source files. Use parsers/maskers for Markdown, comments, HTML, TeX, Typst, commit messages, and other mixed-code formats.
4. **Expose an editor protocol.** Wrap the core with LSP so multiple editors can share the same diagnostics and code actions.
5. **Compile to WASM for browser surfaces.** Browser and JavaScript integrations should call the same engine locally rather than a server.
6. **Run browser linting in a worker.** Keep grammar checks off the UI thread and make the worker boundary explicit.
7. **Separate highlighting from linting.** The DOM/editor layer should only read text, render highlights, and apply suggestions; it should not own grammar logic.
8. **Make rules configurable.** Support dialects, per-rule toggles, ignored lints, custom dictionaries, and style-guide packs.
9. **Treat reports as opt-in telemetry.** Normal linting stays local; user-reported false positives can be sent deliberately for maintainer feedback loops.

## Why It Works

The core engine can be tested deeply once, then reused everywhere. LSP covers developer editors; WASM covers browsers and embedded app surfaces; format-specific parsers prevent code syntax from becoming false positives. Keeping the correction path local preserves both privacy and latency.

## Minimal Version

```text
core:
  Document(source, parser)
  Linter.lint(document) -> [Lint { span, message, suggestions }]

adapters:
  CLI: read file/stdin -> print lints
  LSP: publish diagnostics + code actions
  WASM: expose lint(text, config) to JS

parsers:
  Plain text
  Markdown
  Source-code comments
```

## Implementation Notes

- Make spans stable across Unicode and editor coordinate systems.
- Mask code, links, math, markup, and generated syntax rather than linting everything.
- Keep dictionaries and user dictionaries in the same document construction path; otherwise spelling metadata and linter state drift apart.
- Separate production extension permissions from development-only CSP/HMR permissions.
- Browser extensions need extra review because broad content scripts can read arbitrary editable page text.
- A desktop overlay or accessibility integration is higher trust than an LSP or CLI and needs a tighter security review.

## Good Fits

- local writing assistants
- Markdown/Obsidian linting
- source-code comment and documentation checks
- commit-message linting
- style-guide enforcement
- privacy-sensitive browser/editor extensions

## Poor Fits

- multilingual grammar checking unless the core language resources exist
- semantic editing that needs document understanding beyond grammar/style
- cloud-only collaborative writing where server-side policy enforcement is mandatory
- high-trust browser/desktop installs without a permissions review

---

**Attribution:** Automattic/harper, Apache-2.0 License.
