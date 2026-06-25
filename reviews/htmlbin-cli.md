# htmlbin-cli (utsengar/htmlbin-cli)

**Repo:** https://github.com/utsengar/htmlbin-cli
**License:** MIT License - permissive reuse with attribution
**Reviewed:** 2026-06-25
**Stack:** TypeScript, Node.js 20+, Commander, undici, Octokit, Cloudflare Pages API, Vitest, tsup, Agent Skill Markdown
**What it is:** `@htmlbin/cli` publishes a single HTML file and returns a URL, with a public hosted backend by default and opt-in GitHub Pages or Cloudflare Pages backends for organization-internal previews.

---

## Verdict

⚠️ **Interesting, close to deploy-candidate after dependency and typecheck cleanup.** The product idea is sharp: coding agents increasingly generate local HTML artifacts, and this CLI turns those artifacts into shareable URLs with agent-friendly JSON output, stable metadata upserts, and SSO-capable preview backends. The implementation is coherent and well tested at runtime, but `npm run typecheck` currently fails in the e2e helper typing and production `npm audit` flags a direct vulnerable `undici` range.

---

## What It Is

`htmlbin-cli` is a small publishing tool for single-file HTML artifacts. The default `cloud` backend posts HTML to `htmlbin.dev` and returns a public URL. Two alternative backends target organization previews: `gh-pages` commits `slug/index.html` to a Pages branch, while `cloudflare` deploys the HTML through Cloudflare Pages Direct Upload and can provision a Cloudflare Access app.

The repo is agent-aware. It auto-detects common coding-agent environment variables and switches default output to one-line JSON, exposes deterministic exit codes, ships a `htmlbin-publish` Agent Skill, and includes a pattern catalog that agents are supposed to read before authoring the HTML. That last piece matters: it treats the published page as a shaped artifact, not just a dumped transcript.

The strongest workflow is PR preview publishing. A build or agent produces `preview.html`, `htmlbin publish` returns a stable URL, and CI posts it back to the pull request. For cloud drops, metadata tags and `--upsert` keep URLs stable across republished revisions.

## Stack

| Layer | Tech |
|-------|------|
| CLI | Node.js 20+, TypeScript, Commander |
| Build | tsup, TypeScript declarations |
| Tests | Vitest, e2e CLI tests |
| Cloud HTTP | undici |
| GitHub Pages | Octokit Git Data API |
| Cloudflare | Pages Direct Upload, Access APIs |
| Agent support | Auto JSON mode, exit code contract, bundled Agent Skill |
| Pattern catalog | Markdown pattern files with front matter |

## Key Features

### Three Publishing Backends

The CLI abstracts three destinations behind one backend interface:

- `cloud`: public htmlbin.dev drops authenticated by `hb_*` token.
- `gh-pages`: commits a single HTML file to `slug/index.html` on a Pages branch.
- `cloudflare`: creates or reuses a Pages project, uploads the file, and publishes an alias/subdomain.

That split is practical. Public previews can be cheap and hosted; organization previews can stay behind GitHub or Cloudflare identity controls.

### Agent-Friendly Output Contract

`src/bin.ts` detects agent runtimes such as Claude Code, Codex, OpenCode, Cursor, Aider, Cline, Windsurf, Devin, and others. In those contexts, output defaults to JSON so a runner can parse `{ "url": "...", "slug": "...", "backend": "..." }` instead of scraping prose.

Errors also serialize as JSON in agent mode and map to documented exit codes: auth failure, forbidden, not found, rate limit, size limit, invalid argument, network/server error.

### Stable Upsert Metadata

The cloud backend supports flat metadata tags and `publish --upsert`. A workflow can tag a drop with `repo` and `pr`, then reuse the same URL across pushes. That avoids the common preview-spam problem where every commit creates a new public URL.

### Pattern Library Before Publishing

The bundled Agent Skill requires agents to list installed patterns, select a matching pattern, read it, author the HTML, and only then publish. The included patterns cover plan/spec explainers, PR explainers, and summary roundups.

This is the right ordering. A pattern is useful before the artifact exists; after publishing, it is just a post-hoc label.

### Security-Conscious Defaults

Several details are good:

- Cloud login writes project-local tokens under `./.htmlbin/token` with best-effort `0700` directory and `0600` file permissions.
- Debug mode is off by default so raw upstream HTTP response bodies are not dumped into public CI logs.
- GitHub Pages slugs are constrained to safe path segments.
- Cloudflare Access setup requires explicit `--idp`, `--email-domain`, or `--email` flags before creating an allow policy; otherwise it prints next steps.
- Non-default backends reject metadata flags instead of silently ignoring them.

## Architecture

The architecture is straightforward:

- `src/bin.ts` owns CLI parsing, output mode, command wiring, and error serialization.
- `src/backend.ts` defines the backend interface.
- `src/backends/cloud.ts`, `gh-pages.ts`, and `cloudflare.ts` implement destination-specific behavior.
- `src/cloud/`, `src/gh/`, and `src/cf/` isolate API clients and setup helpers.
- `src/load.ts` centralizes file loading, size limits, and helpful missing-build-output hints.
- `src/patterns/` manages local/global pattern installation and catalog updates.
- `skills/htmlbin-publish/SKILL.md` teaches agents the publish workflow.

The GitHub Pages backend uses the Git Data API instead of shelling out to `git`: get branch head, create blobs, create tree, create commit, update ref. That is a clean CI-friendly primitive.

Local validation performed:

- `npm ci` passed.
- `npm test` passed: 17 files passed, 1 skipped; 162 tests passed, 6 skipped.
- `npm run build` passed, including ESM/CJS bundles and declarations.
- `npm run typecheck` failed in `test/e2e/helpers.ts` because `Parameters<typeof execa>[2]` no longer matches the installed `execa` call signature.
- `npm audit --omit=dev --json` reported one direct production vulnerability group: `undici` 7.25.0 is below the fixed 7.28.0 range and carries high/moderate advisories.
- Full `npm audit` reported 6 advisories: 3 moderate, 2 high, 1 critical, mostly dev-toolchain `vitest`/`vite` plus the production `undici` issue.
- GitHub metadata on 2026-06-25: 5 stars, 0 forks, 0 open issues, latest push 2026-06-22.

## Comparison

| Aspect | htmlbin-cli | HTML Anything | visual-explainer |
|--------|-------------|---------------|------------------|
| Primary fit | Publish an existing single-file HTML artifact to a URL | Generate/edit/export HTML through a local web UI | Teach agents to create local explanatory HTML pages |
| Runtime | CLI and optional hosted/Pages backends | Next.js app spawning local agent CLIs | Mostly skill/templates, plus small Pi renderer |
| Agent contract | JSON output, exit codes, skill, patterns | Local agent CLI adapters and streaming preview | Skill routing and visual templates |
| Best pattern | Stable preview URL pipeline with backend abstraction | Live preview and export adapters | Medium selection and HTML artifact discipline |
| Main caveat | Typecheck failure and vulnerable `undici` range | Shell boundary if exposed beyond localhost | Prompt-dependent output quality |

## Self-Hosting Notes

The default cloud backend is not self-hosted; it posts to `htmlbin.dev`. For private/internal usage, prefer the `gh-pages` backend with private Pages or the `cloudflare` backend with Access configured.

Before broad use, patch `undici` to a fixed release, fix the e2e helper typecheck failure, and keep tokens scoped. The Cloudflare backend should use account-specific tokens with only Pages and Access permissions required for the chosen account.

---

**Attribution:** utsengar/htmlbin-cli, MIT License.
