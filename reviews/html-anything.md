# HTML Anything Review

- **Source:** https://github.com/nexu-io/html-anything
- **Author:** nexu-io
- **License:** Apache-2.0
- **Reviewed:** 2026-05-19
- **Verdict:** ⚠️ Interesting

## Summary

HTML Anything is a local-first Next.js app for turning draft content into designed, single-file HTML artifacts by delegating generation to a locally installed coding-agent CLI. The user writes or uploads content, chooses one of many skill templates, picks an available CLI such as Claude Code, Codex, Cursor Agent, Gemini CLI, Copilot CLI, OpenCode, Qwen, or Aider, then streams the generated HTML into a sandboxed preview and exports it to HTML, PNG, WeChat, Zhihu, X/social cards, decks, or Hyperframes/Remotion-style outputs.

The project is not just a markdown converter. It is an agent orchestration surface for visual publishing: a template catalog, local CLI adapter layer, streaming preview, sandboxed iframe renderer, export adapters, draft generation, deploy-to-Vercel helper, and a broad set of skill prompts for different output surfaces.

The strongest reusable idea is the split between content drafting and final artifact generation: Markdown or raw data is treated as source material, while the agent writes the actual reader-facing HTML.

## What It Does

- Detects locally installed coding-agent CLIs from PATH plus common tool directories.
- Invokes the chosen agent with a skill-specific prompt and streams output over SSE.
- Parses agent stdout formats into deltas, HTML replacements, metadata, stderr, raw lines, done, and error events.
- Renders generated HTML in an iframe preview.
- Ships 75-ish skill templates across prototypes, decks, posters, social cards, office docs, data reports, résumé layouts, and video frames.
- Supports edit-from-existing-HTML flows that ask the agent to preserve layout and make minimal content changes.
- Exports to standalone HTML, high-DPI image, WeChat-friendly inlined HTML, Zhihu math placeholders, Remotion/Hyperframes zip, and other social surfaces.
- Stores deployment tokens locally for Vercel preview deployment, masking tokens in API responses and writing config files with chmod 600.

## Architecture Notes

The repo is a small pnpm workspace:

- `next/` is the Next.js app.
- `e2e/` holds Playwright tests.
- `scripts/guard.ts` checks workspace/package invariants.

Important modules:

- `next/src/app/api/convert/route.ts` assembles prompts, invokes an agent, and streams SSE events.
- `next/src/app/api/draft/route.ts` uses the same local-agent invocation path for markdown draft generation.
- `next/src/lib/agents/argv.ts` defines per-agent command-line protocols and output parsers.
- `next/src/lib/agents/invoke.ts` resolves binaries, spawns child processes, pipes prompts, parses output, and handles aborts.
- `next/src/components/preview-pane.tsx` renders streamed HTML, source, logs, and deck mode.
- `next/src/lib/extract-html.ts` rescues HTML from chatty or fenced model output.
- `next/src/lib/export/` contains platform-specific export adapters.
- `next/src/lib/templates/skills/` contains the skill prompt catalog.
- `next/src/lib/deploy/` handles local deploy config and Vercel deployment.

## Strong Patterns

### Local Agent CLI Adapter Layer

HTML Anything treats agent CLIs as interchangeable local render engines. Each adapter defines:

- detection binary and fallbacks;
- optional environment override;
- invocation protocol;
- model options;
- argv construction;
- stdout parser;
- unsupported-protocol messaging when detection exists before invocation support.

This lets the UI stay provider-agnostic while the local machine's existing logins do the actual model work.

### Skill-Template Artifact Generation

The template catalog follows a skill-like shape: metadata plus strong prompt constraints. Each skill defines mode, scenario, aspect hint, examples, and output rules. The app can then offer a visual picker while the agent receives a concrete production brief.

See extracted pattern: [`patterns/agentic-html-surface-pipeline.md`](../patterns/agentic-html-surface-pipeline.md).

### Streaming Preview

The convert route streams agent output as server-sent events, while the preview pane debounces iframe `srcDoc` updates during generation. This gives the user a live artifact forming in the browser rather than a long blank wait.

### Export Adapters

The export layer treats each destination as a different rendering constraint:

- standalone HTML download;
- image capture through browser rendering;
- WeChat HTML with CSS inlined by `juice`;
- Zhihu-specific equation handling;
- deck/PPT and Remotion/Hyperframes formats.

That is a good pattern for agent-generated design tools because "HTML" is only the intermediate representation; the actual target is often a platform with quirks.

## Risks

HTML Anything intentionally runs local agent CLIs from a web app. That is powerful, but it should be treated as a local developer tool, not a public multi-tenant service.

Key risks:

- `/api/convert` and `/api/draft` can spawn local CLI tools. Do not expose this server on an untrusted network.
- User-provided `binOverride` and `cwd` are useful for local UX but raise the blast radius if the API is reachable by others.
- Generated HTML is rendered in a sandboxed iframe, but the sandbox includes scripts and same-origin. That is convenient for Tailwind/scripts, but still deserves caution.
- Deployment tokens are stored locally in plaintext JSON with chmod 600. Reasonable for a local developer tool, not enough for shared hosting.
- The project accepts Excel via `xlsx`, and `pnpm audit --prod` reports high-severity SheetJS advisories with no patched npm version listed.
- Next/Turbopack reports an NFT tracing warning indicating the project may be tracing too broad a filesystem scope due to dynamic filesystem/path usage in the agent invocation route.

## Verification

Local verification on 2026-05-19:

- `pnpm install --frozen-lockfile` passed.
- `pnpm exec tsx scripts/guard.ts` passed.
- `pnpm -F @html-anything/next typecheck` passed.
- `pnpm -F @html-anything/next test` passed: 5 files, 59 tests.
- `pnpm -F @html-anything/next build` passed with a Turbopack NFT tracing warning.
- `pnpm -F @html-anything/e2e typecheck` passed.
- `pnpm -F @html-anything/e2e test` passed after installing Playwright Chromium: 4 tests passed.
- `pnpm audit --prod` reported 3 advisories: 2 high-severity `xlsx` advisories and 1 moderate `postcss` advisory via Next.

## Recommendation

Use HTML Anything as a strong study target and a controlled local tool, especially for agent-driven publishing workflows. It is not a deploy-it-anywhere web app.

It is valuable for:

- Studying local agent CLI orchestration from a web UI.
- Harvesting the skill-template artifact generation pattern.
- Studying live streaming preview for model-generated HTML.
- Studying export adapters for platform-specific publishing surfaces.
- Exploring HTML-as-final-artifact workflows instead of Markdown-as-final-doc.

Before wider use:

- Keep the server bound to local/private interfaces.
- Fix or replace `xlsx` if Excel upload is important.
- Tighten the generated HTML sandbox where possible.
- Document the trust boundary around CLI spawning and deploy-token storage.
- Address the Turbopack tracing warning so production bundles do not accidentally include too broad a filesystem scope.

The implementation is coherent and verified well locally, but the shell boundary and dependency advisories keep the verdict at ⚠️ Interesting.
