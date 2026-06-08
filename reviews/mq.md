# mq (harehare/mq)

**Repo:** https://github.com/harehare/mq
**License:** MIT
**Reviewed:** 2026-06-07
**Stack:** Rust, Markdown AST processing, jq-like query language, CLI, formatter, type checker, LSP, REPL, DAP, WASM/web API, editor extensions, Agent Skill
**What it is:** A jq-like command-line language for querying, transforming, and updating Markdown as structured data.

---

## Verdict

✅ **Deploy candidate for Markdown automation.** mq is one of the cleaner answers to a recurring problem: Markdown is treated as prose until an agent or script needs to edit it reliably, then everyone reaches for brittle regex. mq gives Markdown a query language, selector model, formatter, checker, LSP, CLI, update mode, multi-format IO, and even a bundled Agent Skill. It is still a 0.x language with a broad surface, but the repo has real docs, releases, CI, tests, and active maintenance.

---

## What It Is

mq is a Rust workspace centered on a Markdown query language. Its surface feels intentionally familiar to jq users: selectors, pipes, mapping, filtering, functions, modules, and output formatting. Instead of JSON objects, the primary target is Markdown parsed into nodes such as headings, lists, tables, links, blockquotes, code blocks, frontmatter, and text.

The CLI can read Markdown, MDX, HTML, raw text, JSON, YAML, TOML, CSV/TSV/PSV, XML, HCL, CBOR, TOON, and bytes. It can output Markdown, HTML, text, JSON, table, grep, raw, or nothing, and it supports in-place updates, aggregation, streaming, module loading, raw file inputs, shell-ish external subcommands named `mq-*`, and a REPL.

The project is broader than a single binary. It includes a core language crate, Markdown parsing/manipulation crate, HIR/type-checking/formatting/LSP crates, debugger and REPL crates, FFI/WASM/web API packages, editor integrations, docs, a website/playground, and an Agent Skill that teaches agents when and how to use mq.

## Stack

| Layer | Tech |
|-------|------|
| Core language | Rust `mq-lang`, `mq-hir`, optimizer, parser, evaluator |
| Markdown layer | `mq-markdown`, HTML-to-Markdown conversion, table handling |
| CLI | `mq-run`, Clap, multiple input/output formats, update/stream modes |
| Developer tooling | formatter, type checker, LSP, REPL, DAP |
| Distribution | Cargo, binaries, Homebrew, Docker, VS Code/Open VSX, Neovim, Zed |
| Web/runtime | WASM, web API, Node/web packages |
| Agent packaging | `skills/processing-markdown` Agent Skill |

## Key Features

### Structured Markdown Selection

mq exposes Markdown structure directly, so commands can target headings, list items, code fences, links, tables, footnotes, frontmatter, and text nodes without rebuilding a parser in every script.

### Transform and Update Mode

The CLI is not only a reader. `--update` lets mq rewrite files after transformations, which makes it relevant for documentation cleanup, vault maintenance, generated docs, and agent-side patching.

### Agent-Readable Operating Manual

The included `skills/processing-markdown` package is unusually important. It tells agents which selectors and functions exist, gives common command patterns, and names cases where mq should not be used. That turns the tool from "a CLI an agent might hallucinate around" into a documented action surface.

### Language Tooling Beyond the CLI

The project invests in a formatter, checker, LSP, REPL, experimental debugger, editor extensions, and web playground. That is the right direction for a query language because scripts become easier to debug and share.

### Fresh Release Momentum

The latest inspected release, `v0.6.0` published 2026-06-07, adds dict merge support, `min_by`/`max_by`, selector aliases, `pick`, `omit`, `frontmatter()`, GFM/math HTML support, optimizer work, type-checker improvements, semver helpers, WASM print/stderr changes, and web API exports.

## Validation

Local checks performed on commit `10353a33a3ae01b9f12f6522b3c7d53a9ebe9d61`:

- `cargo fmt --all -- --check` passed.
- `cargo test -q --workspace` passed across the workspace, including thousands of unit and doctests.
- `cargo clippy --all-targets --all-features --workspace -- -D clippy::all` passed.
- CLI smoke test passed: extracting README headings with `cargo run -q -p mq-run -- '.h | to_text()' README.md`.

CI uses `just`/nextest-oriented commands, cargo deny, docs checks, RustSec audit workflow, CodeQL, and zizmor. The exact `just test-all` path was not run locally because the standard Cargo workspace test already covered the repo heavily.

## Architecture

The workspace split is healthy:

- `mq-lang` owns parsing, optimization, modules, and evaluation.
- `mq-markdown` owns Markdown/HTML parsing and conversion.
- `mq-run` owns CLI input/output and external command behavior.
- `mq-hir`, `mq-check`, and `mq-formatter` separate language representation, checking, and formatting.
- `mq-lsp`, `mq-repl`, and `mq-dap` expose developer-facing workflows.
- `mq-ffi`, `mq-wasm`, and `mq-web-api` broaden integration points without stuffing everything into the CLI.

This separation matters because Markdown automation tools often become one giant command script. mq is closer to a small language ecosystem.

## Caveats

- It is still a young 0.x language, so query syntax and semantics may shift.
- The surface area is large: CLI, language, Markdown conversion, LSP, DAP, WASM, web packages, editor extensions, and install scripts all have separate security and maintenance profiles.
- Install scripts and prebuilt binaries should be pinned or audited before sensitive automation.
- Markdown dialect edge cases are endless. Even with strong tests, pilot it on representative vault/docs files before bulk rewrites.
- Some dependencies are necessarily broad because the tool supports many input formats and web/editor runtimes.

## Best Uses

- Querying and cleaning large Markdown docs or vaults.
- Extracting headings, links, tables, frontmatter, and code fences for LLM context.
- Agent workflows that need reliable Markdown mutation instead of regex.
- Documentation lint/fix scripts that should preserve structure.
- Multi-format ingest where Markdown is the central output format.

## Pattern Worth Borrowing

The reusable pattern is a structured Markdown query layer for agents and docs automation. Extracted to `public-data/patterns/structured-markdown-query-language.md`.

---

**Attribution:** harehare/mq, MIT License.
