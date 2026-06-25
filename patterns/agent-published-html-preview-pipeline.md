# Agent-Published HTML Preview Pipeline

**Source:** [utsengar/htmlbin-cli](https://github.com/utsengar/htmlbin-cli)
**License:** MIT
**Reviewed:** 2026-06-25

## Pattern

Let agents or CI jobs produce a single self-contained HTML artifact, then publish that artifact through a small CLI that returns a stable URL and machine-readable result.

The important split:

1. The build or agent creates `preview.html`.
2. The publish CLI validates and uploads exactly that artifact.
3. The CLI returns structured output for automation.
4. CI comments the URL back on the PR, issue, chat thread, or task.

This keeps artifact generation separate from artifact distribution. The publisher does not invent content; it gives generated HTML a controlled delivery path.

## Why It Matters

Coding agents increasingly create useful HTML artifacts: PR explainers, visual diffs, plan reviews, decision memos, architecture maps, dashboards, and recaps. Local files are awkward to share, while ad hoc hosting usually loses auth, retention, or update semantics.

A dedicated preview publisher gives teams a repeatable contract:

- one command publishes the artifact;
- output is parseable by agents and CI;
- URLs can stay stable across updates;
- private backends can sit behind existing SSO;
- cleanup can be automated.

## Implementation Shape

```text
source change / plan / thread
        |
        v
build step or coding agent writes preview.html
        |
        v
html publish CLI
        |
        +--> public hosted drop
        +--> GitHub Pages branch
        +--> Cloudflare Pages + Access
        |
        v
JSON result: { url, slug, backend, matched? }
        |
        v
sticky PR comment / chat reply / task artifact
```

## Key Design Rules

- **Single artifact in.** Start with one self-contained HTML file. Multi-file site publishing is a different product.
- **Backend abstraction.** Keep the CLI contract stable while supporting public cloud, GitHub Pages, or Cloudflare Pages.
- **Structured output for agents.** Auto-detect agent environments or require `--output json`; never force agents to scrape prose.
- **Stable update semantics.** Support deterministic slugs or metadata-based upserts so revisions update the same URL.
- **Explicit trust boundary.** Public cloud for public previews; GitHub Pages or Cloudflare Access for internal previews.
- **Scoped credentials.** Use environment tokens in CI and project-local token files for local dev, with tight file permissions when possible.
- **Pattern before publishing.** If an agent authors the HTML, route it through a pattern/brief before generation, not after upload.

## Minimal CLI Contract

```bash
previewer publish ./preview.html --output json
previewer publish ./preview.html --slug pr-42 --to gh-pages
previewer publish ./preview.html --upsert --metadata repo=owner/repo --metadata pr=42
previewer delete pr-42
previewer url pr-42
```

Return values should be small and stable:

```json
{"url":"https://example/p/aB3xK7g","slug":"aB3xK7g","backend":"cloud"}
```

Errors should also be structured in agent/CI mode:

```json
{"error":{"code":"auth_required","message":"No token found","hint":"Run login or set token env var"}}
```

## Security Notes

- Treat generated HTML as untrusted if it includes script.
- Do not expose local agent-generation servers or preview publishers on public interfaces.
- Keep raw upstream response bodies out of normal CI logs; reserve them for explicit debug mode.
- Validate slugs before writing to path-like backends.
- Keep backend-specific flags honest. If a backend cannot support metadata or Access controls, reject those flags instead of silently ignoring them.

## Good Fit

- Pull-request previews for repos that do not already have a web deploy.
- Agent-generated visual diffs and architecture explainers.
- Shareable plan/spec memos.
- Internal demos behind GitHub or Cloudflare identity.
- Research or incident brief artifacts where a local HTML file needs a temporary URL.

## Poor Fit

- Multi-file apps with assets, routing, and build-time static generation.
- Long-lived public documentation sites.
- Sensitive artifacts where generated HTML cannot be safely sanitized or access-gated.
- Workflows that need comments, collaboration, or live editing inside the published artifact.

## Source Files

- `src/backend.ts`
- `src/bin.ts`
- `src/backends/cloud.ts`
- `src/backends/gh-pages.ts`
- `src/backends/cloudflare.ts`
- `skills/htmlbin-publish/SKILL.md`
- `examples/agent-preview-workflow.yml`
