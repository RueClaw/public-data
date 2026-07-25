# Harper (Automattic/harper)

**Repo:** https://github.com/Automattic/harper
**License:** Apache-2.0, suitable for reuse with attribution.
**Reviewed:** 2026-07-25
**Stack:** Rust, WebAssembly, TypeScript, Svelte/SvelteKit, Language Server Protocol, Tauri
**What it is:** An offline, privacy-first English grammar and spell checker with a Rust core, LSP/CLI/WASM surfaces, browser and editor integrations, and a desktop app.

---

## Verdict

✅ **Deploy candidate for local grammar checking and editor integration.** Harper is mature, fast, actively maintained, Apache-2.0 licensed, and built around the right privacy boundary: lint locally, send nothing for normal checking. The main caveat is ecosystem sprawl: the Rust core is strong, but the web/browser/WordPress/desktop surfaces add a large dependency and permission footprint that should be adopted selectively.

---

## What It Is

Harper is a local English linter. It tokenizes text, applies spelling and grammar/style rules, and returns diagnostics plus suggested corrections. The project positions itself as a privacy-first alternative to server-backed tools like Grammarly and a lighter, faster alternative to LanguageTool.

The repo is a large monorepo rather than a single binary. `harper-core` is the Rust engine. `harper-ls` exposes that engine through the Language Server Protocol for Neovim, Helix, Emacs, Zed, Sublime Text, and VS Code. `harper-wasm` and `harper.js` make the same engine usable in browsers and JavaScript runtimes. There are also Chrome/Firefox, Obsidian, VS Code, WordPress, website/demo, CLI, and Tauri desktop surfaces.

Harper currently targets English only, with multiple dialect settings. It is especially strong for developer writing: Markdown, source-code comments, commit messages, documentation, and editor workflows.

## Stack

| Layer | Tech |
|-------|------|
| Core engine | Rust crate `harper-core` |
| Rule system | Rust linters plus Weir rule language/weirpacks |
| Parsing/extraction | Markdown, Org, comments, HTML, TeX, Typst, AsciiDoc, tree-sitter-backed code/comment parsers |
| Spell/POS | Curated dictionary, FST dictionary, Brill/POS support crates |
| Editor protocol | `harper-ls` over LSP |
| CLI | `harper-cli` |
| Browser/JS | `harper-wasm`, `harper.js`, web worker linter |
| Frontend/apps | Svelte/SvelteKit packages, Chrome/Firefox extension, Obsidian plugin, VS Code extension |
| Desktop | Tauri v2, SvelteKit SPA, native overlay highlighter |
| Release/checks | GitHub Actions, Cargo, pnpm, Playwright, workspace `just` tasks |

## Key Features

### Local-First Grammar Engine

Normal linting happens on-device. The project ships a Rust core and compiles it to WASM for browser/editor integrations, which is the right architecture for private writing feedback. The browser extension does allow outbound connections to `writewithharper.com` for version checks/reporting, but the core correction path is local.

### Broad Editor Surface

Harper is available as an LSP, VS Code extension, Obsidian plugin, browser extension, JavaScript package, CLI, and desktop app. That breadth matters because grammar checking is only useful when it follows the user into the writing surface.

### Code-Aware Text Extraction

The repo includes dedicated packages for comments and markup: `harper-comments`, `harper-html`, `harper-typst`, `harper-tex`, `harper-asciidoc`, `harper-python`, `harper-git-commit`, and more. This is better than running a prose checker blindly over source files.

### Rule Authoring Path

Most rules live as individual Rust linters, but Harper also has Weir, an expression language for custom writing rules and style-guide enforcement. That is a good bridge between hardcoded grammar logic and user/team-specific language policy.

### Serious Test Posture

The core crate has thousands of tests, including rule behavior, parser behavior, POS/tagging, doc tests, and regression fixtures. Comment parsing also has broad language fixture coverage.

## Architecture

Harper has a clean center and a large perimeter:

- `harper-core` owns `Document`, `Parser`, `Linter`, `Lint`, dictionary, rule, token, spellcheck, and Weir logic.
- `harper-ls` wraps the core as a language server.
- `harper-comments` and related parser crates translate code/markup into lintable English token streams while masking non-prose.
- `harper-wasm` exposes the engine to JavaScript.
- `packages/harper.js` loads and manages the WASM module, including worker-based linting.
- `packages/lint-framework` handles DOM/editor highlighting and suggestion UI.
- Product integrations layer on top of that: browser extension, Obsidian plugin, VS Code extension, website/demo, WordPress plugin, and Tauri desktop.

The strongest pattern is the reusable core boundary. The same grammar engine serves CLI, LSP, browser, Obsidian, and desktop contexts instead of duplicating rule logic per integration.

## Comparison

| Aspect | Harper | LanguageTool | Grammarly |
|--------|--------|--------------|-----------|
| Privacy model | Local/on-device normal linting | Can be local but heavier; common use often server-backed | Proprietary/server-backed |
| License | Apache-2.0 | LGPL and related ecosystem licenses | Proprietary |
| Runtime footprint | Rust/WASM, lightweight | JVM plus optional large n-gram data | Hosted app/service |
| Editor fit | LSP plus first-party extensions | LSP via ltex-ls and plugins | Mostly app/browser/editor extensions |
| Languages | English today | Multilingual | English-focused product, broader writing service |
| Extensibility | Rust linters plus Weir rules | Rule ecosystem, XML/pattern rules | Closed |

## Self-Hosting Notes

For editor usage, the lowest-risk path is `harper-ls` through the editor integration. For app integration, use `harper-core` in Rust or `harper.js` in JavaScript/WASM.

Practical caveats:

- Browser extensions necessarily request broad content-script coverage because they need to read editable text across pages.
- The Tauri desktop app has native accessibility and overlay behavior, especially on macOS; treat it as a higher-trust install than the CLI/LSP.
- The WordPress plugin is explicitly work-in-progress.
- JavaScript audit output is currently noisy across web/WordPress/SvelteKit/webpack dependency trees; evaluate the exact package you deploy rather than assuming the whole monorepo has the same risk.

## Verification

Local verification on 2026-07-25:

- `cargo test -p harper-core` passed: 5674 passed, 289 ignored, plus integration/doc tests.
- `cargo test -p harper-comments -p harper-cli -p harper-ls` passed: CLI output tests, 39 comment language-support fixtures, and LSP position-conversion tests.
- `just --list` could not run because `just` is not installed on this machine.
- `cargo audit` could not run because `cargo-audit` is not installed.
- `pnpm audit --prod` reported 126 JavaScript vulnerabilities in the monorepo lockfile: 2 critical, 54 high, 53 moderate, 17 low. Many paths run through web/WordPress/dev-server/SvelteKit tooling; this is a real packaging caveat, not a blocker for `harper-core` or `harper-ls`.

---

**Attribution:** Automattic/harper, Apache-2.0 License.
